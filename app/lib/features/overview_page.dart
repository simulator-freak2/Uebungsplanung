import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/documents_repository.dart';
import '../data/exercise_repository.dart';
import '../ui/theme.dart';
import '../util/time.dart' as t;
import '../ui/widgets.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const PageHeader(title: 'Übersicht', subtitle: 'Stand der Stammdaten'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(label: 'Personen', icon: Icons.groups_outlined, stream: repo.persons.watchAll().map((l) => l.length)),
              _Stat(label: 'Fahrzeuge & Boote', icon: Icons.local_shipping_outlined, stream: repo.vehicles.watchAll().map((l) => l.length)),
              _Stat(label: 'Alarmstichworte', icon: Icons.notifications_active_outlined, stream: repo.keywords.watchAll().map((l) => l.length)),
              _Stat(label: 'Qualifikationen', icon: Icons.workspace_premium_outlined, stream: repo.qualifications.watchAll().map((l) => l.length)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SectionCard(
            title: 'Nächste Übungen',
            child: StreamBuilder<List<Exercise>>(
              stream: repo.exercises.watchAll(),
              builder: (context, s) {
                final today = DateTime.now();
                final next = (s.data ?? const <Exercise>[])
                    .where((e) => !e.date.isBefore(DateTime(today.year, today.month, today.day)))
                    .take(5)
                    .toList();
                if (next.isEmpty) return const Text('Keine anstehenden Übungen. Neue Übungen legt ihr unter „Übungen“ an.');
                return Column(children: [
                  for (final e in next)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text(e.title),
                      subtitle: Text('${t.dateLong(e.date)} · ${t.clock(e.startMinutes)} Uhr${e.unit == null ? '' : ' · ${e.unit}'}'),
                      trailing: Text(ExerciseStatus.label(e.status, approvalRequired: true)),
                    ),
                ]);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: _OpenLessons()),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionCard(
            title: 'Erste Schritte',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step('Personal anlegen oder aus einer Excel-Liste importieren', 'Personal'),
                _Step('Fahrzeuge aus Vorlagen anlegen und Besetzungsmuster prüfen', 'Fahrzeuge & Funktionen'),
                _Step('Führungs- und Sonderfunktionen ergänzen', 'Fahrzeuge & Funktionen'),
                _Step('Alarmstichworte importieren (z. B. Tabelle Rheinland-Pfalz)', 'Alarmstichworte'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.text, this.where);
  final String text;
  final String where;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.arrow_forward, size: 20, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(child: Text.rich(TextSpan(text: '$text  ', children: [
              TextSpan(text: '→ $where', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]))),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.icon, required this.stream});
  final String label;
  final IconData icon;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<int>(
                      stream: stream,
                      builder: (_, s) => Text('${s.data ?? '–'}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    ),
                    Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Offene Erkenntnisse aus Nachbesprechungen – Grundlage für die weitere
/// Übungsplanung. „In Übung übernehmen“ fügt sie einer kommenden Übung als
/// Lernziel hinzu.
class _OpenLessons extends StatelessWidget {
  const _OpenLessons();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return SectionCard(
      title: 'Erkenntnisse aus Nachbesprechungen',
      subtitle: 'Offene und eingeplante Maßnahmen',
      child: StreamBuilder<List<LessonWithSource>>(
        stream: repo.documents.watchOpenLessons(),
        builder: (context, s) {
          final list = s.data ?? const <LessonWithSource>[];
          if (list.isEmpty) return const Text('Keine offenen Maßnahmen.');
          return Column(children: [
            for (final l in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Tag(lessonStatus[l.lesson.status] ?? l.lesson.status,
                    color: l.lesson.status == 'offen' ? AppColors.warn.withValues(alpha: 0.18) : AppColors.ok.withValues(alpha: 0.15),
                    textColor: l.lesson.status == 'offen' ? AppColors.warn : AppColors.ok),
                title: Text(l.lesson.description),
                subtitle: Text('aus: ${l.exercise.title}, ${t.date(l.exercise.date)}${l.lesson.responsible == null ? '' : ' · ${l.lesson.responsible}'}'),
                trailing: Wrap(children: [
                  if (l.lesson.status == 'offen')
                    TextButton(onPressed: () => _plan(context, l), child: const Text('In Übung übernehmen')),
                  IconButton(
                    tooltip: 'Als erledigt markieren',
                    icon: const Icon(Icons.check),
                    onPressed: () => repo.documents.setLessonStatus(l.lesson.id, 'erledigt', plannedIn: l.lesson.plannedInExerciseId),
                  ),
                ]),
              ),
          ]);
        },
      ),
    );
  }

  Future<void> _plan(BuildContext context, LessonWithSource l) async {
    final repo = AppScope.of(context);
    final today = DateTime.now();
    final upcoming = (await repo.exercises.watchAll().first).where((e) => !e.date.isBefore(DateTime(today.year, today.month, today.day))).toList();
    if (!context.mounted) return;
    if (upcoming.isEmpty) {
      showMessage(context, 'Es gibt keine anstehende Übung. Legt zuerst eine Übung an.');
      return;
    }
    final target = await showDialog<Exercise>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('In welche Übung übernehmen?'),
        children: [
          for (final e in upcoming)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e), child: Text('${t.date(e.date)}  ${e.title}')),
        ],
      ),
    );
    if (target == null) return;
    final d = await repo.exercises.detail(target.id);
    await repo.exercises.setGoals(target.id, [...?d?.goals, l.lesson.description]);
    await repo.documents.setLessonStatus(l.lesson.id, 'eingeplant', plannedIn: target.id);
    if (context.mounted) showMessage(context, 'Als Lernziel in „${target.title}“ übernommen');
  }
}
