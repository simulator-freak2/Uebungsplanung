import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

/// Ein Element der Lageskizze.
///
/// * `symbol`: taktisches Zeichen an einem Punkt (`symbol` = Asset-Pfad,
///   `organisation` = Organisationsfarbe nach DV 102)
/// * `line`: Linie, z. B. Absperrung oder Schlauchleitung
/// * `area`: Fläche, z. B. Gefahrenbereich oder Suchabschnitt
/// * `text`: Beschriftung an einem Punkt
class SketchItem {
  SketchItem({required this.type, required this.points, this.symbol, this.organisation, this.label = '', this.color = 'rot'});

  final String type;
  final List<(double, double)> points; // (lat, lon)
  final String? symbol;
  final String? organisation;
  final String label;
  final String color;

  static const colors = {'rot': Color(0xFFC8102E), 'blau': Color(0xFF1565C0), 'gelb': Color(0xFFE0A800), 'schwarz': Color(0xFF222222), 'gruen': Color(0xFF1F7A45)};
  Color get flutterColor => colors[color] ?? colors['rot']!;

  SketchItem copyWith({List<(double, double)>? points, String? symbol, String? organisation, String? label, String? color}) => SketchItem(
        type: type,
        points: points ?? this.points,
        symbol: symbol ?? this.symbol,
        organisation: organisation ?? this.organisation,
        label: label ?? this.label,
        color: color ?? this.color,
      );

  Map<String, Object?> toJson() => {
        'typ': type,
        'punkte': [for (final p in points) [p.$1, p.$2]],
        'zeichen': ?symbol,
        'organisation': ?organisation,
        if (label.isNotEmpty) 'text': label,
        'farbe': color,
      };

  static SketchItem fromJson(Map<String, dynamic> j) => SketchItem(
        type: '${j['typ']}',
        points: [for (final p in (j['punkte'] as List? ?? const [])) (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
        symbol: j['zeichen'] as String?,
        organisation: j['organisation'] as String?,
        label: '${j['text'] ?? ''}',
        color: '${j['farbe'] ?? 'rot'}',
      );
}

/// Organisationsfarben nach DV 102 „Taktische Zeichen“.
///
/// Die Zeichen sind für alle Organisationen gleich; die Zugehörigkeit zeigt
/// die Farbe des Grundzeichens. Auf dunklem Grund werden Schrift und
/// Symbole weiß, auf hellem Grund schwarz dargestellt.
class Organisation {
  const Organisation(this.id, this.name, this.grund, this.inhalt, {this.hint = ''});

  final String id;
  final String name;
  final Color grund;
  final Color inhalt;
  final String hint;

  static const feuerwehr = Organisation('feuerwehr', 'Feuerwehr', Color(0xFFFF0000), Color(0xFFFFFFFF));
  static const thw = Organisation('thw', 'THW', Color(0xFF003399), Color(0xFFFFFFFF));
  static const hilfsorganisation =
      Organisation('hilfsorganisation', 'Hilfsorganisationen', Color(0xFFFFFFFF), Color(0xFF000000), hint: 'DLRG, DRK, Wasserwacht, ASB, JUH, MHD – Rettungsdienst, Sanitätsdienst, Betreuung, Wasserrettung');
  static const polizei = Organisation('polizei', 'Polizei', Color(0xFF13A538), Color(0xFFFFFFFF));
  static const fuehrung = Organisation('fuehrung', 'Führung / Behörden', Color(0xFFFFFF00), Color(0xFF000000), hint: 'Einsatzleitung, Stäbe, Katastrophenschutzbehörde');

  static const all = [feuerwehr, thw, hilfsorganisation, polizei, fuehrung];

  static Organisation byId(String? id) => all.firstWhere((o) => o.id == id, orElse: () => hilfsorganisation);

  /// Vorgabe für neue Zeichen je nach Organisationsprofil der App.
  static String forProfile(String? profileId) => switch (profileId) {
        null || 'feuerwehr' => feuerwehr.id,
        'thw' => thw.id,
        _ => hilfsorganisation.id,
      };

  /// Platzhalter in den Zeichen-Dateien (siehe `tool/zeichen_dv102.py`).
  static const grundPlatzhalter = '#FEFEFE';
  static const inhaltPlatzhalter = '#010101';

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Färbt ein Zeichen (SVG-Text) in den Farben dieser Organisation ein.
  String apply(String svg) => svg.replaceAll(grundPlatzhalter, _hex(grund)).replaceAll(inhaltPlatzhalter, _hex(inhalt));
}

List<SketchItem> decodeSketch(String json) {
  try {
    return [for (final e in jsonDecode(json) as List) SketchItem.fromJson(e as Map<String, dynamic>)];
  } catch (_) {
    return const [];
  }
}

String encodeSketch(List<SketchItem> items) => jsonEncode([for (final i in items) i.toJson()]);

/// Eintrag im Zeichenkatalog. [grund] ist gesetzt, wenn das Zeichen nach
/// Organisation eingefärbt werden kann (Vorgabe-Organisation).
typedef SymbolEntry = ({String name, String asset, String? grund});

/// Katalog der taktischen Zeichen (Assets aus `assets/zeichen`).
class SymbolCatalog {
  SymbolCatalog(this.categories, {this.moves = const {}});
  final List<(String, List<SymbolEntry>)> categories;

  /// Alte Dateipfade (vor der Umstellung auf DV 102) → (neuer Pfad, Organisation).
  final Map<String, (String, String)> moves;

  late final Map<String, SymbolEntry> _byAsset = {
    for (final (_, items) in categories)
      for (final e in items) e.asset: e,
  };

  static SymbolCatalog? _cache;
  static final Map<String, String> _svgCache = {};

  static Future<SymbolCatalog> load() async {
    if (_cache != null) return _cache!;
    final j = jsonDecode(await rootBundle.loadString('assets/zeichen/index.json')) as List;
    final m = jsonDecode(await rootBundle.loadString('assets/zeichen/umzug.json')) as Map<String, dynamic>;
    return _cache = SymbolCatalog(
      [
        for (final c in j)
          (
            '${c['kategorie']}',
            [
              for (final z in c['zeichen'] as List) (name: '${z['name']}', asset: 'assets/zeichen/${z['datei']}', grund: z['grund'] as String?),
            ],
          ),
      ],
      moves: {for (final e in m.entries) e.key: ('${e.value['datei']}', '${e.value['organisation']}')},
    );
  }

  /// Aktueller Pfad eines (evtl. alten) Zeichens.
  String resolve(String asset) => moves[asset]?.$1 ?? asset;

  /// Kann das Zeichen nach Organisation eingefärbt werden?
  bool isColorable(String? asset) => asset != null && _byAsset[resolve(asset)]?.grund != null;

  /// Organisation eines Zeichens: gespeichert oder Vorgabe des Zeichens.
  String organisationOf(SketchItem item) => item.organisation ?? moves[item.symbol]?.$2 ?? _byAsset[resolve(item.symbol ?? '')]?.grund ?? Organisation.hilfsorganisation.id;

  String nameOf(String asset) {
    final e = _byAsset[resolve(asset)];
    if (e != null) return e.name;
    return asset.split('/').last.replaceAll('.svg', '').replaceAll('_', ' ');
  }

  /// Stellt Zeichen alter Skizzen auf die neuen, organisationsneutralen
  /// Dateien um. Gibt `null` zurück, wenn nichts zu ändern war.
  List<SketchItem>? migrate(List<SketchItem> items) {
    var changed = false;
    final out = <SketchItem>[];
    for (final i in items) {
      final move = i.type == 'symbol' ? moves[i.symbol] : null;
      if (move == null) {
        out.add(i);
        continue;
      }
      changed = true;
      out.add(i.copyWith(symbol: move.$1, organisation: i.organisation ?? move.$2));
    }
    return changed ? out : null;
  }

  /// SVG-Text des Zeichens in den Farben der Organisation, falls schon geladen.
  String? cachedSvg(String asset, String? organisation) => _svgCache['${resolve(asset)}|${organisation ?? ''}'];

  /// SVG-Text des Zeichens in den Farben der Organisation.
  Future<String> svg(String asset, String? organisation) async {
    final path = resolve(asset);
    final key = '$path|${organisation ?? ''}';
    final hit = _svgCache[key];
    if (hit != null) return hit;
    final raw = await rootBundle.loadString(path);
    final colored = _byAsset[path]?.grund != null ? Organisation.byId(organisation ?? _byAsset[path]!.grund).apply(raw) : raw;
    return _svgCache[key] = colored;
  }
}

/// Liest Kartenkacheln aus einer MBTiles-Datei (Raster, z. B. PNG/JPG) für
/// den Offline-Betrieb. Fehlt eine Kachel, wird – wenn erlaubt – online
/// nachgeladen.
class MbTilesProvider extends TileProvider {
  MbTilesProvider(String path, {this.fallback}) : _db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);

  final sql.Database _db;
  final TileProvider? fallback;

  static bool isValid(String path) {
    if (!File(path).existsSync()) return false;
    try {
      final db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
      final ok = db.select("SELECT name FROM sqlite_master WHERE name IN ('tiles')").isNotEmpty;
      db.close();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Quellenangabe aus den Metadaten der Datei (MBTiles-Feld `attribution`).
  static String? attribution(String path) {
    try {
      final db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
      final r = db.select("SELECT value FROM metadata WHERE name = 'attribution'");
      db.close();
      return r.isEmpty ? null : (r.first['value'] as String).replaceAll(RegExp(r'<[^>]*>'), '');
    } catch (_) {
      return null;
    }
  }

  /// Bereich der Datei (Name, Zoomstufen) für die Anzeige.
  static String describe(String path) {
    final db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
    try {
      final meta = {for (final r in db.select('SELECT name, value FROM metadata')) r['name']: r['value']};
      final z = db.select('SELECT MIN(zoom_level) AS a, MAX(zoom_level) AS b, COUNT(*) AS n FROM tiles').first;
      return '${meta['name'] ?? File(path).uri.pathSegments.last} · Zoom ${z['a']}–${z['b']} · ${z['n']} Kacheln';
    } catch (_) {
      return File(path).uri.pathSegments.last;
    } finally {
      db.close();
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final c = coordinates;
    // MBTiles nutzt das TMS-Schema: die y-Achse ist gespiegelt.
    final y = (1 << c.z) - 1 - c.y;
    final r = _db.select('SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1', [c.z, c.x, y]);
    if (r.isNotEmpty) return MemoryImage(r.first['tile_data'] as Uint8List);
    if (fallback != null) return fallback!.getImage(c, options);
    return MemoryImage(_transparent);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  static final _transparent = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
}

/// Taktisches Zeichen in den Farben einer Organisation (DV 102).
class TacticalSymbol extends StatefulWidget {
  const TacticalSymbol({super.key, required this.asset, this.organisation, this.size = 64});

  final String asset;
  final String? organisation;
  final double size;

  @override
  State<TacticalSymbol> createState() => _TacticalSymbolState();
}

class _TacticalSymbolState extends State<TacticalSymbol> {
  String? _svg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TacticalSymbol old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset || old.organisation != widget.organisation) _load();
  }

  void _load() {
    final asset = widget.asset, org = widget.organisation;
    _svg = SymbolCatalog._cache?.cachedSvg(asset, org);
    if (_svg != null) return;
    SymbolCatalog.load().then((c) => c.svg(asset, org)).then((s) {
      if (mounted && asset == widget.asset && org == widget.organisation) setState(() => _svg = s);
    }).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svg;
    if (svg == null) return SizedBox(width: widget.size, height: widget.size);
    return SvgPicture.string(svg, width: widget.size, height: widget.size);
  }
}
