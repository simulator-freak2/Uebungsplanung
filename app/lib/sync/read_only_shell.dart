import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../features/exercises/exercise_actions.dart';
import '../features/exercises/observer_view.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../util/time.dart' as t;
import 'sync_ui.dart';

/// Oberfläche für Tablets und Beobachter: Übungen ansehen, Mappe drucken,
/// nichts ändern.
class ReadOnlyShell extends StatefulWidget {
  const ReadOnlyShell({super.key});

  @override
  State<ReadOnlyShell> createState() => _ReadOnlyShellState();
}

class _ReadOnlyShellState extends State<ReadOnlyShell> {
  late final repo = AppScope.of(context);
  late final _all = repo.exercises.watchAll();
  bool _past = false;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übungsplaner'),
        actions: [
          IconButton(tooltip: 'Jetzt abgleichen', onPressed: session.syncNow, icon: const Icon(Icons.sync)),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'logout' ? session.logout() : session.disconnect(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Abmelden')),
              PopupMenuItem(value: 'disconnect', child: Text('Verbindung trennen')),
            ],
          ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: const Row(children: [
            Icon(Icons.visibility_outlined, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Nur ansehen – geplant und bearbeitet wird am PC.')),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: const SyncStatusLine()),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Anstehend')), ButtonSegment(value: true, label: Text('Vergangen'))],
            selected: {_past},
            onSelectionChanged: (s) => setState(() => _past = s.first),
          ),
        ),
        Expanded(
          child: StreamView<List<Exercise>>(
            stream: _all,
            builder: (context, all) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final list = _past ? all.where((e) => e.date.isBefore(today)).toList().reversed.toList() : all.where((e) => !e.date.isBefore(today)).toList();
              if (list.isEmpty) return const EmptyHint(icon: Icons.event_busy_outlined, text: 'Keine Übungen.');
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final e = list[i];
                  return ListTile(
                    leading: Container(width: 6, height: 40, color: e.status == 'freigegeben' ? AppColors.ok : AppColors.red),
                    title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.dateLong(e.date)} · ${t.clock(e.startMinutes)} Uhr${e.location == null ? '' : ' · ${e.location}'}'),
                    trailing: IconButton(
                      tooltip: 'Übungsmappe',
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      onPressed: () async {
                        final d = await repo.exercises.detail(e.id);
                        if (d != null && context.mounted) await showExerciseMapDialog(context, d);
                      },
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObserverView(exerciseId: e.id))),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
