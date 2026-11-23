import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  late List<SketchItem> _items = decodeSketch(widget.detail.exercise.sketch);
  _Tool _tool = _Tool.none;
  String? _symbol;
  final List<(double, double)> _draft = [];
  int? _selected;
  Timer? _viewSave;
  TileProvider? _tiles;
  String _tileInfo = 'OpenStreetMap (online)';
  String _attribution = '© OpenStreetMap-Mitwirkende';
  bool _capturing = false;

  String get _id => widget.detail.exercise.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTiles());
  }

  @override
  void didUpdateWidget(MapTab old) {
    super.didUpdateWidget(old);
    // Änderungen von anderen Geräten übernehmen, solange hier nicht gezeichnet wird.
    if (old.detail.exercise.sketch != widget.detail.exercise.sketch && _tool == _Tool.none && _selected == null) {
      _items = decodeSketch(widget.detail.exercise.sketch);
    }
  }

  @override
  void dispose() {
    _viewSave?.cancel();
    _tiles?.dispose();
    super.dispose();
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

  void _onTap(LatLng p) {
    final pt = (p.latitude, p.longitude);
    switch (_tool) {
      case _Tool.symbol:
        setState(() {
          _items.add(SketchItem(type: 'symbol', points: [pt], symbol: _symbol));
          _tool = _Tool.none;
        });
        _save();
      case _Tool.text:
        _addText(pt);
      case _Tool.line:
      case _Tool.area:
        setState(() => _draft.add(pt));
      case _Tool.move:
        if (_selected != null) {
          final i = _selected!;
          setState(() {
            _items[i] = _items[i].copyWith(points: [pt]);
            _tool = _Tool.none;
          });
          _save();
        }
      case _Tool.none:
        setState(() => _selected = null);
    }
  }

  Future<void> _addText(( double, double) pt) async {
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
    final catalog = await SymbolCatalog.load();
    if (!mounted) return;
    final asset = await showDialog<String>(context: context, builder: (_) => _SymbolPicker(catalog: catalog));
    if (asset != null) {
      setState(() {
        _symbol = asset;
        _tool = _Tool.symbol;
        _selected = null;
      });
    }
  }

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
    setState(() {
      _capturing = true;
      _selected = null;
    });
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
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (_tool == _Tool.none) ...[
        FilledButton.tonalIcon(key: const Key('map-symbol'), onPressed: _pickSymbol, icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Taktisches Zeichen')),
        OutlinedButton.icon(onPressed: () => setState(() => _tool = _Tool.line), icon: const Icon(Icons.timeline), label: const Text('Linie')),
        OutlinedButton.icon(onPressed: () => setState(() => _tool = _Tool.area), icon: const Icon(Icons.pentagon_outlined), label: const Text('Fläche')),
        OutlinedButton.icon(onPressed: () => setState(() => _tool = _Tool.text), icon: const Icon(Icons.text_fields), label: const Text('Text')),
        OutlinedButton.icon(onPressed: _search, icon: const Icon(Icons.search), label: const Text('Ort suchen')),
        FilledButton.icon(key: const Key('map-capture'), onPressed: _capture, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Für Übungsmappe übernehmen')),
      ] else ...[
        if (hint != null) Text(hint, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (drawing) FilledButton(onPressed: _finishDraft, child: const Text('Fertig')),
        TextButton(
          onPressed: () => setState(() {
            _draft.clear();
            _tool = _Tool.none;
          }),
          child: const Text('Abbrechen'),
        ),
      ],
    ]);
  }

  Widget _selectionBar() {
    final i = _selected!;
    final item = _items[i];
    final c = Theme.of(context).colorScheme;
    return Material(
      color: c.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(switch (item.type) { 'symbol' => 'Zeichen', 'line' => 'Linie', 'area' => 'Fläche', _ => 'Text' }, style: const TextStyle(fontWeight: FontWeight.w700)),
          OutlinedButton.icon(
            onPressed: () async {
              final text = await askText(context, title: 'Beschriftung', label: 'Text', initial: item.label);
              if (text == null) return;
              setState(() => _items[i] = item.copyWith(label: text));
              _save();
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text(item.label.isEmpty ? 'Beschriften' : item.label),
          ),
          if (item.type != 'symbol')
            for (final e in SketchItem.colors.entries)
              InkWell(
                onTap: () {
                  setState(() => _items[i] = item.copyWith(color: e.key));
                  _save();
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: e.value, shape: BoxShape.circle, border: Border.all(color: item.color == e.key ? c.onSurface : Colors.transparent, width: 2)),
                ),
              ),
          if (item.points.length == 1) OutlinedButton.icon(onPressed: () => setState(() => _tool = _Tool.move), icon: const Icon(Icons.open_with), label: const Text('Verschieben')),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _items.removeAt(i);
                _selected = null;
              });
              _save();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Löschen'),
          ),
          IconButton(onPressed: () => setState(() => _selected = null), icon: const Icon(Icons.close)),
        ]),
      ),
    );
  }

  LatLng _ll((double, double) p) => LatLng(p.$1, p.$2);

  @override
  Widget build(BuildContext context) {
    final e = widget.detail.exercise;
    final c = Theme.of(context).colorScheme;
    final center = e.mapLat != null ? LatLng(e.mapLat!, e.mapLon!) : const LatLng(50.0, 7.6);
    final markers = <Marker>[];
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.type != 'symbol' && it.type != 'text') continue;
      final sel = _selected == i;
      markers.add(Marker(
        point: _ll(it.points.first),
        width: it.type == 'symbol' ? 140 : 220,
        height: it.type == 'symbol' ? 96 : 40,
        child: GestureDetector(
          onTap: () => setState(() => _selected = i),
          child: it.type == 'symbol'
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    decoration: sel ? BoxDecoration(border: Border.all(color: c.primary, width: 2)) : null,
                    child: SvgPicture.asset(it.symbol ?? '', width: 64, height: 64, placeholderBuilder: (_) => const Icon(Icons.location_on, size: 40)),
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
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), border: Border.all(color: sel ? c.primary : it.flutterColor, width: sel ? 2 : 1)),
                    child: Text(it.label, style: TextStyle(fontWeight: FontWeight.w700, color: it.flutterColor)),
                  ),
                ),
        ),
      ));
    }
    for (final p in _draft) {
      markers.add(Marker(point: _ll(p), width: 12, height: 12, child: Container(decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))));
    }
    final lines = [
      for (var i = 0; i < _items.length; i++)
        if (_items[i].type == 'line')
          Polyline(
            points: [for (final p in _items[i].points) _ll(p)],
            color: _items[i].flutterColor,
            strokeWidth: _selected == i ? 7 : 4,
            pattern: StrokePattern.dashed(segments: const [14, 8]),
          ),
      if (_tool == _Tool.line && _draft.length > 1) Polyline(points: [for (final p in _draft) _ll(p)], color: c.primary, strokeWidth: 3),
    ];
    final areas = [
      for (var i = 0; i < _items.length; i++)
        if (_items[i].type == 'area')
          Polygon(
            points: [for (final p in _items[i].points) _ll(p)],
            color: _items[i].flutterColor.withValues(alpha: 0.25),
            borderColor: _items[i].flutterColor,
            borderStrokeWidth: _selected == i ? 5 : 3,
            label: _items[i].label.isEmpty ? null : _items[i].label,
            labelStyle: TextStyle(color: _items[i].flutterColor, fontWeight: FontWeight.w700),
          ),
      if (_tool == _Tool.area && _draft.length > 2)
        Polygon(points: [for (final p in _draft) _ll(p)], color: c.primary.withValues(alpha: 0.15), borderColor: c.primary, borderStrokeWidth: 2),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _toolbar(),
        const SizedBox(height: 8),
        if (_selected != null && _selected! < _items.length) ...[_selectionBar(), const SizedBox(height: 8)],
        Expanded(
          child: ClipRRect(
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
                  if (_tiles != null)
                    TileLayer(urlTemplate: _osmUrl, userAgentPackageName: _userAgent, tileProvider: _tiles, maxNativeZoom: 19),
                  PolygonLayer(polygons: areas),
                  PolylineLayer(polylines: lines),
                  MarkerLayer(markers: markers),
                  if (!_capturing)
                    RichAttributionWidget(attributions: [TextSourceAttribution(_attribution, prependCopyright: false)], showFlutterMapAttribution: false),
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
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Karte: $_tileInfo', style: Theme.of(context).textTheme.bodySmall)),
          if (e.sketchPng != null) Text('Bild für die Übungsmappe vorhanden', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ]),
    );
  }
}

class _SymbolPicker extends StatefulWidget {
  const _SymbolPicker({required this.catalog});
  final SymbolCatalog catalog;

  @override
  State<_SymbolPicker> createState() => _SymbolPickerState();
}

class _SymbolPickerState extends State<_SymbolPicker> {
  String _query = '';
  int _cat = 0;

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = q.isEmpty
        ? widget.catalog.categories[_cat].$2
        : [for (final (_, list) in widget.catalog.categories) ...list.where((x) => x.$1.toLowerCase().contains(q))];
    return AlertDialog(
      title: const Text('Taktisches Zeichen wählen'),
      content: SizedBox(
        width: 760,
        height: 520,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'z. B. HLF, Boot, Gefahr, Person', isDense: true),
            onChanged: (v) => setState(() => _query = v),
          ),
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
                for (final (name, asset) in items)
                  InkWell(
                    onTap: () => Navigator.pop(context, asset),
                    child: Column(children: [
                      SvgPicture.asset(asset, width: 72, height: 72),
                      Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ]),
                  ),
              ],
            ),
          ),
          Text('Zeichen: Jonas Köritz, taktisches-zeichen.de (CC0 / CC BY 4.0)', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen'))],
    );
  }
}
