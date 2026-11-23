import 'package:material_ui/material_ui.dart';

import '../data/profile.dart';
import '../data/repositories.dart';
import '../sync/sync_ui.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Erster Start: Organisation benennen und Profil wählen.
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _name = TextEditingController();
  String _profile = 'feuerwehr';
  bool _busy = false;

  Future<void> _start() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final repo = AppScope.of(context);
    final session = AppScope.sessionOf(context);
    final profile = await OrgProfile.load(_profile);
    await profile.applyTo(repo);
    await session.setShared(SettingsRepository.profileId, _profile);
    await session.setShared(SettingsRepository.orgName, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.fact_check_outlined, color: AppColors.yellow, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text('Willkommen im Übungsplaner', style: t.headlineSmall)),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Für den Start braucht der Übungsplaner nur den Namen eurer Organisation. '
                        'Das Profil bringt passende Qualifikationen, Führungsfunktionen und Fahrzeugvorlagen mit.'),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('setup-name'),
                      controller: _name,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Name der Organisation', hintText: 'z. B. Freiwillige Feuerwehr Musterstadt'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text('Profil', style: t.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        for (final e in OrgProfile.available.entries) ButtonSegment(value: e.key, label: Text(e.value)),
                      ],
                      selected: {_profile},
                      onSelectionChanged: (s) => setState(() => _profile = s.first),
                    ),
                    const SizedBox(height: 8),
                    Text('Weitere Organisationen (THW, DRK, ASB, Wasserwacht …) folgen als zusätzliche Profile.',
                        style: t.bodySmall),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      key: const Key('setup-server'),
                      onPressed: _busy ? null : () => showConnectDialog(context),
                      icon: const Icon(Icons.cloud_sync_outlined),
                      label: const Text('Mit vorhandenem Übungsplaner-Server verbinden'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const Key('setup-start'),
                      onPressed: _busy || _name.text.trim().isEmpty ? null : _start,
                      icon: _busy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_forward),
                      label: const Text('Loslegen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
