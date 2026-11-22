import 'package:material_ui/material_ui.dart';

import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;
import 'exercises_page.dart';
import 'tab_alarm.dart';
import 'tab_alarmplan.dart';
import 'tab_crew.dart';
import 'tab_plan.dart';

class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late final repo = AppScope.of(context);
  late final _detail = repo.exercises.watchDetail(widget.exerciseId);
  late final _approval = repo.settings.watchBool(SettingsRepository.approvalRequired, fallback: true);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ExerciseDetail?>(
      stream: _detail,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            body: snap.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const EmptyHint(icon: Icons.delete_outline, text: 'Diese Übung gibt es nicht mehr.'),
          );
        }
        final d = snap.data!;
        final e = d.exercise;
        return StreamBuilder<bool>(
          stream: _approval,
          builder: (context, a) {
            final approval = a.data ?? true;
            return DefaultTabController(
              length: 4,
              child: Scaffold(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 24, 0),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        IconButton(tooltip: 'Zurück', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.title, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 4),
                            Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                              Text('${t.dateLong(e.date)} · ${t.clock(e.startMinutes)}${e.endMinutes == null ? '' : '–${t.clock(e.endMinutes!)}'} Uhr'
                                  '${e.unit == null ? '' : ' · ${e.unit}'}'),
                              StatusTag(status: e.status, approvalRequired: approval),
                              if (e.status == ExerciseStatus.approved && e.approvedBy != null)
                                Text('freigegeben von ${e.approvedBy}${e.approvedAt == null ? '' : ' am ${t.date(e.approvedAt!.toLocal())}'}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        _StatusActions(detail: d, approvalRequired: approval),
                        PopupMenuButton<String>(
                          tooltip: 'Weitere Aktionen',
                          onSelected: (v) async {
                            if (v == 'delete' && await confirmDelete(context, e.title) && context.mounted) {
                              await repo.exercises.delete(e.id);
                              if (context.mounted) Navigator.of(context).maybePop();
                            }
                          },
                          itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Übung löschen'))],
                        ),
                      ]),
                    ),
                    const TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'Übungsplan'),
                        Tab(text: 'Fahrzeugbesetzung'),
                        Tab(text: 'Alarmierungsplan'),
                        Tab(text: 'Alarmmeldung'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(children: [
                        PlanTab(detail: d, approvalRequired: approval),
                        CrewTab(detail: d),
                        AlarmPlanTab(detail: d),
                        AlarmTab(detail: d),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Knöpfe für den Freigabe-Ablauf.
///
/// Mit Freigabe: Entwurf → zur Freigabe vorlegen → von TL/Wehrführer
/// freigeben. Ohne Freigabe: Entwurf → als fertig markieren.
/// Voraussetzung ist immer die vollständige Sicherheits-Checkliste.
class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.detail, required this.approvalRequired});
  final ExerciseDetail detail;
  final bool approvalRequired;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final e = detail.exercise;
    final safe = detail.safetyComplete;
    const missing = 'Erst die Sicherheits-Checkliste vollständig abhaken';

    Widget gated(String label, IconData icon, VoidCallback action, {Key? key}) => Tooltip(
          message: safe ? '' : missing,
          child: FilledButton.icon(key: key, onPressed: safe ? action : null, icon: Icon(icon), label: Text(label)),
        );

    switch (e.status) {
      case ExerciseStatus.draft:
        return approvalRequired
            ? gated('Zur Freigabe vorlegen', Icons.send_outlined, () => repo.exercises.setStatus(e.id, ExerciseStatus.submitted), key: const Key('exercise-submit'))
            : gated('Als fertig markieren', Icons.check, () => repo.exercises.setStatus(e.id, ExerciseStatus.approved), key: const Key('exercise-done'));
      case ExerciseStatus.submitted:
        return Wrap(spacing: 8, children: [
          OutlinedButton(onPressed: () => repo.exercises.setStatus(e.id, ExerciseStatus.draft), child: const Text('Zurückziehen')),
          gated('Freigeben', Icons.verified_outlined, () async {
            final name = await askText(context,
                title: 'Übung freigeben',
                label: 'Name TL / Wehrführer',
                confirm: 'Freigeben');
            if (name != null) await repo.exercises.setStatus(e.id, ExerciseStatus.approved, approvedBy: name);
          }, key: const Key('exercise-approve')),
        ]);
      default:
        return OutlinedButton.icon(
          onPressed: () => repo.exercises.setStatus(e.id, ExerciseStatus.draft),
          icon: const Icon(Icons.undo),
          label: Text(approvalRequired ? 'Freigabe aufheben' : 'Wieder bearbeiten'),
        );
    }
  }
}
