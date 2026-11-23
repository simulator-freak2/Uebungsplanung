import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../features/exercises/tab_map.dart' show MapKeys;
import '../ui/widgets.dart';
import 'sketch.dart';

/// Einstellungen: Kartenquelle und Offline-Karte (MBTiles) für dieses Gerät.
class MapSettingsCard extends StatefulWidget {
  const MapSettingsCard({super.key});

  @override
  State<MapSettingsCard> createState() => _MapSettingsCardState();
}

class _MapSettingsCardState extends State<MapSettingsCard> {
  late final repo = AppScope.of(context);
  late final _mode = repo.settings.watch(MapKeys.mode);
  late final _file = repo.settings.watch(MapKeys.mbtiles);

  Future<void> _pick() async {
    final f = await FilePicker.pickFile(dialogTitle: 'Offline-Karte wählen', type: FileType.custom, allowedExtensions: const ['mbtiles']);
    if (f?.path == null) return;
    if (!MbTilesProvider.isValid(f!.path!)) {
      if (mounted) showMessage(context, 'Die Datei ist keine gültige MBTiles-Karte.');
      return;
    }
    // In den Anwendungsordner kopieren, damit die Karte erhalten bleibt.
    final dir = Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}karten')..createSync(recursive: true);
    final target = '${dir.path}${Platform.pathSeparator}offline.mbtiles';
    await File(f.path!).copy(target);
    await repo.settings.set(MapKeys.mbtiles, target);
    if (mounted) showMessage(context, 'Offline-Karte eingerichtet');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Karten (Lageskizze)',
      subtitle: 'Gilt nur für dieses Gerät',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        StreamBuilder<String?>(
          stream: _mode,
          builder: (context, s) => Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'online', label: Text('Online')),
                ButtonSegment(value: 'offline', label: Text('Offline')),
                ButtonSegment(value: 'beides', label: Text('Offline, sonst online')),
              ],
              selected: {s.data ?? 'beides'},
              onSelectionChanged: (v) => repo.settings.set(MapKeys.mode, v.first),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<String?>(
          stream: _file,
          builder: (context, s) {
            final path = s.data;
            final ok = path != null && MbTilesProvider.isValid(path);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.map_outlined),
              title: Text(ok ? MbTilesProvider.describe(path) : 'Keine Offline-Karte'),
              subtitle: const Text('MBTiles-Datei eures Landkreises, z. B. in QGIS aus den amtlichen Geobasisdaten erzeugt (siehe Anleitung).'),
              trailing: Wrap(spacing: 8, children: [
                OutlinedButton(onPressed: _pick, child: Text(ok ? 'Ersetzen' : 'Datei wählen')),
                if (ok)
                  IconButton(
                    tooltip: 'Entfernen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await (repo.db.delete(repo.db.settings)..where((t) => t.key.equals(MapKeys.mbtiles))).go();
                      setState(() {});
                    },
                  ),
              ]),
            );
          },
        ),
      ]),
    );
  }
}
