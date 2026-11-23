import 'package:material_ui/material_ui.dart';

import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;
import 'exercise_actions.dart';
import 'exercises_page.dart';
import 'observer_view.dart';
import 'tab_alarm.dart';
import 'tab_alarmplan.dart';
import 'tab_crew.dart';
import 'tab_map.dart';
import 'tab_observation.dart';
import 'tab_plan.dart';
import 'tab_radio_material.dart';
import 'tab_roles.dart';

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
              length: 10,
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
                              if (e.isTemplate) const Tag('Vorlage'),
                              Text('${e.isTemplate ? '' : '${t.dateLong(e.date)} · '}${t.clock(e.startMinutes)}${e.endMinutes == null ? '' : '–${t.clock(e.endMinutes!)}'} Uhr'
                                  '${e.unit == null ? '' : ' · ${e.unit}'}'),
                              if (!e.isTemplate) StatusTag(status: e.status, approvalRequired: approval),
                              if (e.status == ExerciseStatus.approved && e.approvedBy != null)
                                Text('freigegeben von ${e.approvedBy}${e.approvedAt == null ? '' : ' am ${t.date(e.approvedAt!.toLocal())}'}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        if (!e.isTemplate) ...[
                          OutlinedButton.icon(
                            key: const Key('exercise-map'),
                            onPressed: () => showExerciseMapDialog(context, d),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Übungsmappe'),
                          ),
                          const SizedBox(width: 8),
                          _StatusActions(detail: d, approvalRequired: approval),
                        ] else
                          FilledButton.icon(
                            key: const Key('template-use'),
                            onPressed: () async {
                              final id = await copyAsNewExercise(context, e.id, title: e.title, heading: 'Übung aus Vorlage anlegen');
                              if (id != null && context.mounted) {
                                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseId: id)));
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Übung daraus anlegen'),
                          ),
                        PopupMenuButton<String>(
                          tooltip: 'Weitere Aktionen',
                          onSelected: (v) async {
                            switch (v) {
                              case 'observer':
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObserverView(exerciseId: e.id)));
                              case 'template':
                                await saveAsTemplate(context, d);
                              case 'copy':
                                final id = await copyAsNewExercise(context, e.id, title: e.title);
                                if (id != null && context.mounted) {
                                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseId: id)));
                                }
                              case 'delete':
                                if (await confirmDelete(context, e.title) && context.mounted) {
                                  await repo.exercises.delete(e.id);
                                  if (context.mounted) Navigator.of(context).maybePop();
                                }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'observer', child: ListTile(leading: Icon(Icons.tablet_outlined), title: Text('Beobachter-Ansicht'))),
                            if (!e.isTemplate)
                              const PopupMenuItem(value: 'template', child: ListTile(leading: Icon(Icons.library_add_outlined), title: Text('Als Vorlage speichern'))),
                            if (!e.isTemplate)
                              const PopupMenuItem(value: 'copy', child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Übung kopieren'))),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(e.isTemplate ? 'Vorlage löschen' : 'Übung löschen')),
                            ),
                          ],
                        ),
                      ]),
                    ),
                    const TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'Übungsplan'),
                        Tab(text: 'Lageskizze'),
                        Tab(text: 'Besetzung'),
                        Tab(text: 'Alarmplan'),
                        Tab(text: 'Alarmmeldung'),
                        Tab(text: 'Funk'),
                        Tab(text: 'Rollenkarten'),
                        Tab(text: 'Material'),
                        Tab(text: 'Beobachtung'),
                        Tab(text: 'Nachbesprechung'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(children: [
                        PlanTab(detail: d, approvalRequired: approval),
                        MapTab(detail: d),
                        CrewTab(detail: d),
                        AlarmPlanTab(detail: d),
                        AlarmTab(detail: d),
                        RadioTab(detail: d),
                        RolesTab(detail: d),
                        MaterialTab(detail: d),
                        ObservationTab(detail: d),
                        DebriefTab(detail: d),
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
    final session = AppScope.sessionOf(context);
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
          if (!session.canApprove)
            const Tooltip(
              message: 'Freigeben dürfen nur TL / Wehrführer und Administratoren',
              child: FilledButton(onPressed: null, child: Text('Wartet auf Freigabe')),
            )
          else
            gated('Freigeben', Icons.verified_outlined, () async {
              String? name;
              if (session.networked) {
                // Angemeldet: Freigabe mit dem eigenen Namen.
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Übung freigeben?'),
                    content: Text('Freigabe durch ${session.user?.displayName}.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Freigeben')),
                    ],
                  ),
                );
                if (ok == true) name = session.user?.displayName;
              } else {
                name = await askText(context, title: 'Übung freigeben', label: 'Name TL / Wehrführer', confirm: 'Freigeben');
              }
              if (name != null) await repo.exercises.setStatus(e.id, ExerciseStatus.approved, approvedBy: name);
            }, key: const Key('exercise-approve')),
        ]);
      default:
        final mayReset = !approvalRequired || session.canApprove;
        return Tooltip(
          message: mayReset ? '' : 'Nur TL / Wehrführer und Administratoren',
          child: OutlinedButton.icon(
            onPressed: mayReset ? () => repo.exercises.setStatus(e.id, ExerciseStatus.draft) : null,
            icon: const Icon(Icons.undo),
            label: Text(approvalRequired ? 'Freigabe aufheben' : 'Wieder bearbeiten'),
          ),
        );
    }
  }
}
