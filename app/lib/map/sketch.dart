import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

/// Ein Element der Lageskizze.
///
/// * `symbol`: taktisches Zeichen an einem Punkt (`symbol` = Asset-Pfad)
/// * `line`: Linie, z. B. Absperrung oder Schlauchleitung
/// * `area`: Fläche, z. B. Gefahrenbereich oder Suchabschnitt
/// * `text`: Beschriftung an einem Punkt
class SketchItem {
  SketchItem({required this.type, required this.points, this.symbol, this.label = '', this.color = 'rot'});

  final String type;
  final List<(double, double)> points; // (lat, lon)
  final String? symbol;
  final String label;
  final String color;

  static const colors = {'rot': Color(0xFFC8102E), 'blau': Color(0xFF1565C0), 'gelb': Color(0xFFE0A800), 'schwarz': Color(0xFF222222), 'gruen': Color(0xFF1F7A45)};
  Color get flutterColor => colors[color] ?? colors['rot']!;

  SketchItem copyWith({List<(double, double)>? points, String? label, String? color}) =>
      SketchItem(type: type, points: points ?? this.points, symbol: symbol, label: label ?? this.label, color: color ?? this.color);

  Map<String, Object?> toJson() => {
        'typ': type,
        'punkte': [for (final p in points) [p.$1, p.$2]],
        'zeichen': ?symbol,
        if (label.isNotEmpty) 'text': label,
        'farbe': color,
      };

  static SketchItem fromJson(Map<String, dynamic> j) => SketchItem(
        type: '${j['typ']}',
        points: [for (final p in (j['punkte'] as List? ?? const [])) (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
        symbol: j['zeichen'] as String?,
        label: '${j['text'] ?? ''}',
        color: '${j['farbe'] ?? 'rot'}',
      );
}

List<SketchItem> decodeSketch(String json) {
  try {
    return [for (final e in jsonDecode(json) as List) SketchItem.fromJson(e as Map<String, dynamic>)];
  } catch (_) {
    return const [];
  }
}

String encodeSketch(List<SketchItem> items) => jsonEncode([for (final i in items) i.toJson()]);

/// Katalog der taktischen Zeichen (Assets aus `assets/zeichen`).
class SymbolCatalog {
  SymbolCatalog(this.categories);
  final List<(String, List<(String, String)>)> categories; // (Kategorie, [(Name, Asset)])

  static SymbolCatalog? _cache;

  static Future<SymbolCatalog> load() async {
    if (_cache != null) return _cache!;
    final j = jsonDecode(await rootBundle.loadString('assets/zeichen/index.json')) as List;
    return _cache = SymbolCatalog([
      for (final c in j)
        (
          '${c['kategorie']}',
          [for (final z in c['zeichen'] as List) ('${z['name']}', 'assets/zeichen/${z['datei']}')],
        ),
    ]);
  }

  String nameOf(String asset) {
    for (final (_, items) in categories) {
      for (final (n, a) in items) {
        if (a == asset) return n;
      }
    }
    return asset.split('/').last.replaceAll('.svg', '').replaceAll('_', ' ');
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
