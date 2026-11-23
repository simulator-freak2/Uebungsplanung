import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../data/demo_data.dart';
import '../data/profile.dart';
import '../data/repositories.dart';
import '../map/map_settings.dart';
import '../sync/sync_ui.dart';
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
  late final _approval = repo.settings.watchBool(SettingsRepository.approvalRequired, fallback: true);

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
    final session = AppScope.sessionOf(context);
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
                        if (n != null) await session.setShared(SettingsRepository.orgName, n);
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
                title: 'Abläufe',
                child: StreamBuilder<bool>(
                  stream: _approval,
                  builder: (context, s) => SwitchListTile(
                    key: const Key('setting-approval'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Freigabe von Übungen erforderlich'),
                    subtitle: const Text('Übungen werden zur Freigabe vorgelegt und von TL / Wehrführer freigegeben. '
                        'Im Serverbetrieb dürfen nur Benutzer mit der Rolle TL / Wehrführer oder Administrator freigeben.'),
                    value: s.data ?? true,
                    onChanged: session.isAdmin ? (v) => session.setShared(SettingsRepository.approvalRequired, '$v') : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const ServerSettingsSection(),
              const SizedBox(height: 16),
              const MapSettingsCard(),
              const SizedBox(height: 16),
              FutureBuilder<bool>(
                future: canLoadDemo(repo),
                builder: (context, s) => s.data != true
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SectionCard(
                          title: 'Ausprobieren',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Beispieldaten laden'),
                            subtitle: const Text('Fiktives Personal, Fahrzeuge, Stichworte, Dienstplan und eine vollständig ausgearbeitete Übung. '
                                'Nur möglich, solange noch kein Personal und keine Übungen angelegt sind.'),
                            trailing: FilledButton.tonal(
                              key: const Key('demo-load'),
                              onPressed: () async {
                                final id = await repo.settings.get(SettingsRepository.profileId);
                                await loadDemoData(repo, await OrgProfile.load(id ?? 'feuerwehr'));
                                if (context.mounted) {
                                  showMessage(context, 'Beispieldaten geladen');
                                  setState(() {});
                                }
                              },
                              child: const Text('Laden'),
                            ),
                          ),
                        ),
                      ),
              ),
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
                  'Taktische Zeichen: Jonas Köritz, taktisches-zeichen.de (CC0 / CC BY 4.0), '
                  'github.com/jonas-koeritz/Taktische-Zeichen. Kartendaten: © OpenStreetMap-Mitwirkende (ODbL).',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
