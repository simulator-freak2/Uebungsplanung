import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../map/sketch.dart';
import '../../ui/widgets.dart';

/// Einstellungen für Karten (gerätebezogen, nicht abgeglichen).
abstract final class MapKeys {
  static const mode = 'map_mode'; // online | offline | beides
  static const mbtiles = 'map_mbtiles';
}

const _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'de.uebungsplaner.uebungsplaner';

enum _Tool { none, symbol, line, area, text, move }

/// Lageskizze: Karte mit taktischen Zeichen, Linien, Flächen und Text.
///
/// Im Bearbeiten-Modus lassen sich alle eingezeichneten Elemente – auf der
/// Karte oder in der Liste – auswählen, ändern und gemeinsam löschen.
class MapTab extends StatefulWidget {
  const MapTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  late final Repositories repo = AppScope.of(context);
  final _map = MapController();
  final _boundary = GlobalKey();
  final _focus = FocusNode();
  final LayerHitNotifier<int> _lineHits = ValueNotifier(null);
  final LayerHitNotifier<int> _areaHits = ValueNotifier(null);
  late List<SketchItem> _items = decodeSketch(widget.detail.exercise.sketch);
  SymbolCatalog? _catalog;
  _Tool _tool = _Tool.none;
  String? _symbol;
  String _organisation = Organisation.feuerwehr.id;
  final List<(double, double)> _draft = [];

  /// Bearbeiten-Modus: Elemente auswählen, ändern, löschen.
  bool _editing = false;
  final Set<int> _selection = {};

  Timer? _viewSave;
  TileProvider? _tiles;
  String _tileInfo = 'OpenStreetMap (online)';
  String _attribution = '© OpenStreetMap-Mitwirkende';
  bool _capturing = false;

  String get _id => widget.detail.exercise.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTiles();
      _loadSymbols();
    });
  }

  @override
  void didUpdateWidget(MapTab old) {
    super.didUpdateWidget(old);
    // Änderungen von anderen Geräten übernehmen, solange hier nicht gezeichnet oder bearbeitet wird.
    if (old.detail.exercise.sketch != widget.detail.exercise.sketch && _tool == _Tool.none && !_editing) {
      final items = decodeSketch(widget.detail.exercise.sketch);
      _items = _catalog?.migrate(items) ?? items;
    }
  }

  @override
  void dispose() {
    _viewSave?.cancel();
    _tiles?.dispose();
    _focus.dispose();
    _lineHits.dispose();
    _areaHits.dispose();
    super.dispose();
  }

  Future<void> _loadSymbols() async {
    final profile = await repo.settings.get(SettingsRepository.profileId);
    final catalog = await SymbolCatalog.load();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _organisation = Organisation.forProfile(profile);
    });
    // Skizzen mit Zeichen aus früheren Versionen auf die DV-102-Zeichen umstellen.
    final migrated = catalog.migrate(_items);
    if (migrated != null) {
      setState(() => _items = migrated);
      _save();
    }
  }

  Future<void> _loadTiles() async {
    final mode = await repo.settings.get(MapKeys.mode) ?? 'beides';
    final path = await repo.settings.get(MapKeys.mbtiles);
    final online = NetworkTileProvider();
    TileProvider provider = online;
    var info = 'OpenStreetMap (online)';
    if (mode != 'online' && path != null && MbTilesProvider.isValid(path)) {
      provider = MbTilesProvider(path, fallback: mode == 'beides' ? online : null);
      info = mode == 'beides' ? 'Offline-Karte, fehlende Bereiche online' : 'Offline-Karte';
      final a = MbTilesProvider.attribution(path);
      if (a != null) _attribution = mode == 'beides' ? '$a · © OpenStreetMap-Mitwirkende' : a;
    } else if (mode == 'offline') {
      info = 'Keine Offline-Karte eingerichtet (Einstellungen)';
    }
    if (mounted) {
      setState(() {
        _tiles = provider;
        _tileInfo = info;
      });
    }
  }

  Future<void> _save() async {
    await repo.exercises.setSketch(_id, encodeSketch(_items));
  }

  // ------------------------------------------------------------- Auswahl

  void _startEditing([int? select]) {
    setState(() {
      _editing = true;
      _tool = _Tool.none;
      _draft.clear();
      if (select != null) _selection.add(select);
    });
    _focus.requestFocus();
  }

  void _stopEditing() => setState(() {
        _editing = false;
        _selection.clear();
        if (_tool == _Tool.move) _tool = _Tool.none;
      });

  /// Antippen eines Elements: Bearbeiten beginnen bzw. Auswahl umschalten.
  void _toggle(int i) {
    if (_tool != _Tool.none) return;
    if (!_editing) return _startEditing(i);
    setState(() => _selection.contains(i) ? _selection.remove(i) : _selection.add(i));
  }

  void _selectAll() => setState(() {
        if (_selection.length == _items.length) {
          _selection.clear();
        } else {
          _selection
            ..clear()
            ..addAll(List.generate(_items.length, (i) => i));
        }
      });

  Future<void> _deleteSelection() async {
    if (_selection.isEmpty) return;
    final n = _selection.length;
    if (n > 1) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(n == _items.length ? 'Alle $n Elemente löschen?' : '$n Elemente löschen?'),
          content: const Text('Die ausgewählten Zeichen, Linien, Flächen und Texte werden aus der Lageskizze entfernt.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(key: const Key('map-delete-confirm'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final before = [..._items];
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (!_selection.contains(i)) _items[i],
      ];
      _selection.clear();
      if (_tool == _Tool.move) _tool = _Tool.none;
    });
    _save();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(n == 1 ? 'Element gelöscht' : '$n Elemente gelöscht'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _items = before;
              _selection.clear();
            });
            _save();
          },
        ),
      ));
  }

  void _updateSelected(SketchItem Function(SketchItem) change) {
    setState(() {
      for (final i in _selection) {
        _items[i] = change(_items[i]);
      }
    });
    _save();
  }

  // ------------------------------------------------------------- Zeichnen

  void _onTap(LatLng p) {
    final pt = (p.latitude, p.longitude);
    switch (_tool) {
      case _Tool.symbol:
        setState(() {
          _items.add(SketchItem(type: 'symbol', points: [pt], symbol: _symbol, organisation: _catalog?.isColorable(_symbol) == true ? _organisation : null));
          _tool = _Tool.none;
        });
        _save();
      case _Tool.text:
        _addText(pt);
      case _Tool.line:
      case _Tool.area:
        setState(() => _draft.add(pt));
      case _Tool.move:
        if (_selection.length == 1) {
          final i = _selection.single;
          setState(() {
            _items[i] = _items[i].copyWith(points: [pt]);
            _tool = _Tool.none;
          });
          _save();
        }
      case _Tool.none:
        // Linien liegen über Flächen und haben daher Vorrang.
        final hit = _lineHits.value?.hitValues ?? _areaHits.value?.hitValues;
        if (hit != null && hit.isNotEmpty) _toggle(hit.first);
    }
  }

  Future<void> _addText((double, double) pt) async {
    final text = await askText(context, title: 'Beschriftung', label: 'Text');
    setState(() => _tool = _Tool.none);
    if (text == null) return;
    setState(() => _items.add(SketchItem(type: 'text', points: [pt], label: text, color: 'schwarz')));
    _save();
  }

  void _finishDraft() {
    final min = _tool == _Tool.area ? 3 : 2;
    if (_draft.length >= min) {
      _items.add(SketchItem(type: _tool == _Tool.area ? 'area' : 'line', points: [..._draft], color: _tool == _Tool.area ? 'gelb' : 'rot'));
      _save();
    }
    setState(() {
      _draft.clear();
      _tool = _Tool.none;
    });
  }

  Future<void> _pickSymbol() async {
    final catalog = _catalog ?? await SymbolCatalog.load();
    if (!mounted) return;
    final picked = await showDialog<(String, String)>(context: context, builder: (_) => _SymbolPicker(catalog: catalog, organisation: _organisation));
    if (picked != null) {
      setState(() {
        _symbol = picked.$1;
        _organisation = picked.$2;
        _tool = _Tool.symbol;
        _editing = false;
        _selection.clear();
      });
    }
  }

  void _startTool(_Tool tool) => setState(() {
        _tool = tool;
        _editing = false;
        _selection.clear();
      });

  Future<void> _search() async {
    final q = await askText(context, title: 'Ort suchen', label: 'Adresse oder Ort', initial: widget.detail.exercise.location ?? '', confirm: 'Suchen');
    if (q == null) return;
    try {
      final r = await http.get(
        Uri.https('nominatim.openstreetmap.org', '/search', {'q': q, 'format': 'json', 'limit': '1', 'countrycodes': 'de'}),
        headers: {'User-Agent': 'Uebungsplaner/1.0 (Open-Source-Uebungsplanung)'},
      ).timeout(const Duration(seconds: 10));
      final list = jsonDecode(r.body) as List;
      if (list.isEmpty) {
        if (mounted) showMessage(context, 'Nichts gefunden.');
        return;
      }
      final hit = list.first as Map<String, dynamic>;
      _map.move(LatLng(double.parse('${hit['lat']}'), double.parse('${hit['lon']}')), 17);
    } catch (e) {
      if (mounted) showMessage(context, 'Suche nicht möglich (ohne Internet bitte die Karte von Hand verschieben).');
    }
  }

  /// Speichert ein Bild der Skizze für die Übungsmappe.
  Future<void> _capture() async {
    setState(() => _capturing = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await repo.exercises.setSketchPng(_id, base64Encode(png!.buffer.asUint8List()));
      if (mounted) showMessage(context, 'Lageskizze für die Übungsmappe übernommen');
    } catch (e) {
      if (mounted) showMessage(context, 'Bild konnte nicht erstellt werden: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ------------------------------------------------------------- Oberfläche

  Widget _toolbar() {
    final drawing = _tool == _Tool.line || _tool == _Tool.area;
    final hint = switch (_tool) {
      _Tool.symbol => 'Auf die Karte tippen, um das Zeichen zu setzen',
      _Tool.text => 'Auf die Karte tippen, wo der Text stehen soll',
      _Tool.line => 'Punkte der Linie antippen, dann „Fertig“ (${_draft.length} Punkte)',
      _Tool.area => 'Eckpunkte der Fläche antippen, dann „Fertig“ (${_draft.length} Punkte)',
      _Tool.move => 'Neue Position antippen',
      _Tool.none => null,
    };
    if (_tool != _Tool.none) {
      return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (hint != null) Text(hint, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (drawing) FilledButton(onPressed: _finishDraft, child: const Text('Fertig')),
        TextButton(
          onPressed: () => setState(() {
            _draft.clear();
            _tool = _Tool.none;
          }),
          child: const Text('Abbrechen'),
        ),
      ]);
    }
    if (_editing) {
      final all = _items.isNotEmpty && _selection.length == _items.length;
      return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text('Bearbeiten: ${_selection.length} von ${_items.length} ausgewählt', style: const TextStyle(fontWeight: FontWeight.w700)),
        OutlinedButton.icon(
          key: const Key('map-select-all'),
          onPressed: _items.isEmpty ? null : _selectAll,
          icon: Icon(all ? Icons.deselect : Icons.select_all),
          label: Text(all ? 'Auswahl aufheben' : 'Alle auswählen'),
        ),
        FilledButton.icon(
          key: const Key('map-delete'),
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
          onPressed: _selection.isEmpty ? null : _deleteSelection,
          icon: const Icon(Icons.delete_outline),
          label: Text(_selection.length > 1 ? '${_selection.length} löschen' : 'Löschen'),
        ),
        FilledButton.tonalIcon(key: const Key('map-edit-done'), onPressed: _stopEditing, icon: const Icon(Icons.check), label: const Text('Fertig')),
      ]);
    }
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      FilledButton.tonalIcon(key: const Key('map-symbol'), onPressed: _pickSymbol, icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Taktisches Zeichen')),
      OutlinedButton.icon(onPressed: () => _startTool(_Tool.line), icon: const Icon(Icons.timeline), label: const Text('Linie')),
      OutlinedButton.icon(onPressed: () => _startTool(_Tool.area), icon: const Icon(Icons.pentagon_outlined), label: const Text('Fläche')),
      OutlinedButton.icon(onPressed: () => _startTool(_Tool.text), icon: const Icon(Icons.text_fields), label: const Text('Text')),
      OutlinedButton.icon(key: const Key('map-edit'), onPressed: _items.isEmpty ? null : _startEditing, icon: const Icon(Icons.edit_outlined), label: const Text('Bearbeiten')),
      OutlinedButton.icon(onPressed: _search, icon: const Icon(Icons.search), label: const Text('Ort suchen')),
      FilledButton.icon(key: const Key('map-capture'), onPressed: _capture, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Für Übungsmappe übernehmen')),
    ]);
  }

  /// Eigenschaften der ausgewählten Elemente (Beschriftung, Farbe, Organisation, Position).
  Widget _propertiesBar() {
    final c = Theme.of(context).colorScheme;
    final selected = [for (final i in _selection) _items[i]];
    final single = selected.length == 1 ? selected.single : null;
    final colorable = selected.where((i) => i.type == 'symbol' && (_catalog?.isColorable(i.symbol) ?? false)).toList();
    final drawn = selected.where((i) => i.type != 'symbol').toList();
    Widget dot(Color color, bool active, VoidCallback onTap, String tooltip) => Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: active ? c.primary : Colors.black54, width: active ? 3 : 1),
              ),
            ),
          ),
        );
    return Material(
      color: c.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (single != null) ...[
            Text(_typeName(single), style: const TextStyle(fontWeight: FontWeight.w700)),
            OutlinedButton.icon(
              onPressed: () async {
                final text = await askText(context, title: 'Beschriftung', label: 'Text', initial: single.label);
                if (text == null) return;
                _updateSelected((i) => i.copyWith(label: text));
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(single.label.isEmpty ? 'Beschriften' : single.label),
            ),
          ],
          if (colorable.isNotEmpty) ...[
            const Text('Organisation:'),
            for (final o in Organisation.all)
              dot(o.grund, colorable.every((i) => _catalog!.organisationOf(i) == o.id), () => _updateSelected((i) => colorable.contains(i) ? i.copyWith(organisation: o.id) : i), o.name),
          ],
          if (drawn.isNotEmpty) ...[
            const Text('Farbe:'),
            for (final e in SketchItem.colors.entries)
              dot(e.value, drawn.every((i) => i.color == e.key), () => _updateSelected((i) => i.type != 'symbol' ? i.copyWith(color: e.key) : i), e.key),
          ],
          if (single != null && single.points.length == 1)
            OutlinedButton.icon(onPressed: () => setState(() => _tool = _Tool.move), icon: const Icon(Icons.open_with), label: const Text('Verschieben')),
        ]),
      ),
    );
  }

  String _typeName(SketchItem it) => switch (it.type) {
        'symbol' => _catalog?.nameOf(it.symbol ?? '') ?? 'Zeichen',
        'line' => 'Linie',
        'area' => 'Fläche',
        _ => 'Text',
      };

  /// Liste aller Elemente der Skizze zum Auswählen.
  Widget _elementList() {
    final c = Theme.of(context).colorScheme;
    return Material(
      color: c.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text('Elemente der Lageskizze (${_items.length})', style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('Noch nichts eingezeichnet.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    final Widget lead = switch (it.type) {
                      'symbol' => TacticalSymbol(asset: it.symbol ?? '', organisation: _catalog?.organisationOf(it) ?? it.organisation, size: 36),
                      'line' => Icon(Icons.timeline, color: it.flutterColor),
                      'area' => Icon(Icons.pentagon, color: it.flutterColor),
                      _ => Icon(Icons.text_fields, color: it.flutterColor),
                    };
                    final org = it.type == 'symbol' && (_catalog?.isColorable(it.symbol) ?? false) ? Organisation.byId(_catalog!.organisationOf(it)).name : null;
                    return CheckboxListTile(
                      key: Key('map-item-$i'),
                      dense: true,
                      value: _selection.contains(i),
                      onChanged: (_) => _toggle(i),
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: SizedBox(width: 36, height: 36, child: Center(child: lead)),
                      title: Text(it.type == 'text' ? it.label : _typeName(it), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [if (it.type != 'text' && it.label.isNotEmpty) '„${it.label}“', ?org, if (it.type == 'line' || it.type == 'area') '${it.points.length} Punkte'].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  LatLng _ll((double, double) p) => LatLng(p.$1, p.$2);

  Widget _mapView() {
    final e = widget.detail.exercise;
    final c = Theme.of(context).colorScheme;
    final center = e.mapLat != null ? LatLng(e.mapLat!, e.mapLon!) : const LatLng(50.0, 7.6);
    bool sel(int i) => !_capturing && _selection.contains(i);
    final markers = <Marker>[];
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.type != 'symbol' && it.type != 'text') continue;
      markers.add(Marker(
        point: _ll(it.points.first),
        width: it.type == 'symbol' ? 140 : 220,
        height: it.type == 'symbol' ? 96 : 40,
        child: GestureDetector(
          onTap: () => _toggle(i),
          child: it.type == 'symbol'
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    decoration: sel(i) ? BoxDecoration(color: c.primary.withValues(alpha: 0.15), border: Border.all(color: c.primary, width: 3)) : null,
                    child: TacticalSymbol(asset: it.symbol ?? '', organisation: _catalog?.organisationOf(it) ?? it.organisation),
                  ),
                  if (it.label.isNotEmpty)
                    Container(
                      color: Colors.white.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                ])
              : Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), border: Border.all(color: sel(i) ? c.primary : it.flutterColor, width: sel(i) ? 3 : 1)),
                    child: Text(it.label, style: TextStyle(fontWeight: FontWeight.w700, color: it.flutterColor)),
                  ),
                ),
        ),
      ));
    }
    for (final p in _draft) {
      markers.add(Marker(point: _ll(p), width: 12, height: 12, child: Container(decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))));
    }
    // Eckpunkte ausgewählter Linien und Flächen hervorheben.
    for (final i in _selection) {
      if (_capturing || i >= _items.length || _items[i].type == 'symbol' || _items[i].type == 'text') continue;
      for (final p in _items[i].points) {
        markers.add(Marker(
          point: _ll(p),
          width: 12,
          height: 12,
          child: IgnorePointer(child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: c.primary, width: 3)))),
        ));
      }
    }
    final lines = [
      for (var i = 0; i < _items.length; i++)
        if (_items[i].type == 'line')
          Polyline<int>(
            points: [for (final p in _items[i].points) _ll(p)],
            color: _items[i].flutterColor,
            strokeWidth: sel(i) ? 7 : 4,
            borderColor: sel(i) ? c.primary : Colors.transparent,
            borderStrokeWidth: sel(i) ? 3 : 0,
            pattern: StrokePattern.dashed(segments: const [14, 8]),
            hitValue: i,
          ),
      if (_tool == _Tool.line && _draft.length > 1) Polyline<int>(points: [for (final p in _draft) _ll(p)], color: c.primary, strokeWidth: 3),
    ];
    final areas = [
      for (var i = 0; i < _items.length; i++)
        if (_items[i].type == 'area')
          Polygon<int>(
            points: [for (final p in _items[i].points) _ll(p)],
            color: _items[i].flutterColor.withValues(alpha: sel(i) ? 0.4 : 0.25),
            borderColor: sel(i) ? c.primary : _items[i].flutterColor,
            borderStrokeWidth: sel(i) ? 5 : 3,
            label: _items[i].label.isEmpty ? null : _items[i].label,
            labelStyle: TextStyle(color: _items[i].flutterColor, fontWeight: FontWeight.w700),
            hitValue: i,
          ),
      if (_tool == _Tool.area && _draft.length > 2)
        Polygon<int>(points: [for (final p in _draft) _ll(p)], color: c.primary.withValues(alpha: 0.15), borderColor: c.primary, borderStrokeWidth: 2),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RepaintBoundary(
        key: _boundary,
        child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: center,
            initialZoom: e.mapZoom ?? (e.mapLat != null ? 17 : 7),
            onTap: (_, p) => _onTap(p),
            onPositionChanged: (cam, gesture) {
              if (!gesture) return;
              _viewSave?.cancel();
              _viewSave = Timer(const Duration(seconds: 2), () => repo.exercises.setMapView(_id, cam.center.latitude, cam.center.longitude, cam.zoom));
            },
          ),
          children: [
            if (_tiles != null) TileLayer(urlTemplate: _osmUrl, userAgentPackageName: _userAgent, tileProvider: _tiles, maxNativeZoom: 19),
            PolygonLayer<int>(polygons: areas, hitNotifier: _areaHits),
            PolylineLayer<int>(polylines: lines, hitNotifier: _lineHits, minimumHitbox: 14),
            MarkerLayer(markers: markers),
            if (!_capturing) RichAttributionWidget(attributions: [TextSourceAttribution(_attribution, prependCopyright: false)], showFlutterMapAttribution: false),
            if (_capturing)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(_attribution, style: const TextStyle(fontSize: 10, color: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.detail.exercise;
    _selection.removeWhere((i) => i >= _items.length);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): _deleteSelection,
        const SingleActivator(LogicalKeyboardKey.backspace): _deleteSelection,
        const SingleActivator(LogicalKeyboardKey.escape): () => _editing ? _stopEditing() : null,
      },
      child: Focus(
        focusNode: _focus,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _toolbar(),
            const SizedBox(height: 8),
            if (_editing && _selection.isNotEmpty) ...[_propertiesBar(), const SizedBox(height: 8)],
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                if (!_editing) return _mapView();
                if (box.maxWidth >= 900) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: _mapView()),
                    const SizedBox(width: 12),
                    SizedBox(width: 320, child: _elementList()),
                  ]);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _mapView()),
                  const SizedBox(height: 8),
                  SizedBox(height: (box.maxHeight * 0.4).clamp(140, 280), child: _elementList()),
                ]);
              }),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text('Karte: $_tileInfo', style: Theme.of(context).textTheme.bodySmall)),
              if (e.sketchPng != null) Text('Bild für die Übungsmappe vorhanden', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _SymbolPicker extends StatefulWidget {
  const _SymbolPicker({required this.catalog, required this.organisation});
  final SymbolCatalog catalog;
  final String organisation;

  @override
  State<_SymbolPicker> createState() => _SymbolPickerState();
}

class _SymbolPickerState extends State<_SymbolPicker> {
  String _query = '';
  int _cat = 0;
  late String _org = widget.organisation;

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = q.isEmpty
        ? widget.catalog.categories[_cat].$2
        : [for (final (_, list) in widget.catalog.categories) ...list.where((x) => x.name.toLowerCase().contains(q))];
    final org = Organisation.byId(_org);
    return AlertDialog(
      title: const Text('Taktisches Zeichen wählen'),
      content: SizedBox(
        width: 760,
        height: 560,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'z. B. Löschgruppe, Boot, Gefahr, Person', isDense: true),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Text('Organisation (Farbe nach DV 102)', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final o in Organisation.all)
              ChoiceChip(
                key: Key('org-${o.id}'),
                avatar: Container(width: 16, height: 16, decoration: BoxDecoration(color: o.grund, border: Border.all(color: Colors.black54))),
                label: Text(o.name),
                tooltip: o.hint.isEmpty ? null : o.hint,
                selected: _org == o.id,
                onSelected: (_) => setState(() => _org = o.id),
              ),
          ]),
          if (org.hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(org.hint, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 8),
          if (q.isEmpty)
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < widget.catalog.categories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(label: Text(widget.catalog.categories[i].$1), selected: _cat == i, onSelected: (_) => setState(() => _cat = i)),
                  ),
              ]),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.extent(
              maxCrossAxisExtent: 120,
              childAspectRatio: 0.85,
              children: [
                for (final z in items)
                  InkWell(
                    onTap: () => Navigator.pop(context, (z.asset, _org)),
                    child: Column(children: [
                      TacticalSymbol(asset: z.asset, organisation: z.grund == null ? null : _org, size: 72),
                      Text(z.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ]),
                  ),
              ],
            ),
          ),
          Text('Zeichen nach DV 102: Jonas Köritz, taktisches-zeichen.de (CC0 / CC BY 4.0)', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen'))],
    );
  }
}
