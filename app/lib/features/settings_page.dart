import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../data/profile.dart';
import '../data/repositories.dart';
import '../ui/widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final repo = AppScope.of(context);
  late final _name = repo.settings.watch(SettingsRepository.orgName);
  late final _profile = repo.settings.watch(SettingsRepository.profileId);

  /// Erstellt eine vollständige Kopie der Datenbank (SQLite „VACUUM INTO“).
  Future<void> _backup() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '-');
    final file = File('${dir.path}${Platform.pathSeparator}uebungsplaner-$stamp.sqlite');
    if (await file.exists()) await file.delete();
    await repo.db.customStatement('VACUUM INTO ?', [file.path]);
    final uri = await FilePicker.saveFile(fileName: file.uri.pathSegments.last, bytes: await file.readAsBytes());
    await file.delete();
    if (uri != null && mounted) showMessage(context, 'Datensicherung gespeichert');
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const PageHeader(title: 'Einstellungen'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Organisation',
                child: StreamBuilder<String?>(
                  stream: _name,
                  builder: (context, s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.data ?? ''),
                    subtitle: const Text('Name der Organisation'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Ändern',
                      onPressed: () async {
                        final n = await askText(context, title: 'Name der Organisation', initial: s.data ?? '');
                        if (n != null) await repo.settings.set(SettingsRepository.orgName, n);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Organisationsprofil',
                subtitle: 'Qualifikationen, Führungsfunktionen und Fahrzeugvorlagen',
                child: StreamBuilder<String?>(
                  stream: _profile,
                  builder: (context, s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(OrgProfile.available[s.data] ?? s.data ?? ''),
                    subtitle: const Text('Fehlende Katalogeinträge erneut einspielen. Eigene Änderungen bleiben erhalten.'),
                    trailing: OutlinedButton(
                      onPressed: s.data == null
                          ? null
                          : () async {
                              await (await OrgProfile.load(s.data!)).applyTo(repo);
                              if (context.mounted) showMessage(context, 'Katalog eingespielt');
                            },
                      child: const Text('Einspielen'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Betriebsart',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.computer),
                  title: const Text('Nur lokal'),
                  subtitle: Text('Die Daten liegen auf diesem Gerät. Der Abgleich mit einem Server kommt in Etappe 5.',
                      style: TextStyle(color: c.onSurfaceVariant)),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Datensicherung',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Datenbank sichern'),
                  subtitle: const Text('Speichert eine vollständige Kopie aller Daten als Datei.'),
                  trailing: FilledButton.tonalIcon(onPressed: _backup, icon: const Icon(Icons.save_alt), label: const Text('Sichern')),
                ),
              ),
              const SizedBox(height: 16),
              const SectionCard(
                title: 'Über',
                child: Text(
                  'Übungsplaner – Übungsplanung für Feuerwehr, DLRG und weitere Hilfsorganisationen.\n'
                  'Lizenz: EUPL-1.2 (European Union Public Licence).\n'
                  'Taktische Zeichen (ab Etappe 6): Jonas Köritz, taktisches-zeichen.de, '
                  'github.com/jonas-koeritz/Taktische-Zeichen.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
