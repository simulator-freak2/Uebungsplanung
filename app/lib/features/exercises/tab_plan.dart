import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;
import 'exercises_page.dart';

/// Übungsplan: Eckdaten, Lernziele, Lage, Ablauf, Sicherheit.
class PlanTab extends StatelessWidget {
  const PlanTab({super.key, required this.detail, required this.approvalRequired});
  final ExerciseDetail detail;
  final bool approvalRequired;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    final left = [_Basics(detail), _Goals(detail), _Scenario(detail)];
    final right = [_Phases(detail), _Safety(detail, approvalRequired: approvalRequired)];
    Widget col(List<Widget> w) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final x in w) Padding(padding: const EdgeInsets.only(bottom: 16), child: x)],
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: col(left)),
            const SizedBox(width: 16),
            Expanded(child: col(right)),
          ])
        else
          col([...left, ...right]),
      ],
    );
  }
}

class _Basics extends StatelessWidget {
  const _Basics(this.d);
  final ExerciseDetail d;

  @override
  Widget build(BuildContext context) {
    final e = d.exercise;
    final c = Theme.of(context).colorScheme;
    Widget kv(String k, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 140, child: Text(k, style: TextStyle(color: c.onSurfaceVariant))),
            Expanded(child: v),
          ]),
        );
    return SectionCard(
      title: 'Eckdaten',
      actions: [
        OutlinedButton.icon(
          key: const Key('exercise-edit'),
          onPressed: () => showExerciseDialog(context, existing: e),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Bearbeiten'),
        ),
      ],
      child: Column(children: [
        kv('Datum', Text(t.dateLong(e.date))),
        kv('Zeit', Text('${t.clock(e.startMinutes)}${e.endMinutes == null ? '' : ' – ${t.clock(e.endMinutes!)}'} Uhr')),
        kv('Ort', Text(e.location ?? '–')),
        kv('Einheit', Text(e.unit ?? '–')),
        kv('Thema', Text(e.topic ?? '–')),
        kv(
          'Alarmstichwort',
          Align(
            alignment: Alignment.centerLeft,
            child: d.keyword == null ? const Text('–') : Tag(d.keyword!.code, color: c.primaryContainer, textColor: c.onPrimaryContainer),
          ),
        ),
      ]),
    );
  }
}

class _Goals extends StatelessWidget {
  const _Goals(this.d);
  final ExerciseDetail d;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final goals = d.goals;
    Future<void> edit([int? i]) async {
      final text = await askText(context, title: i == null ? 'Lernziel hinzufügen' : 'Lernziel bearbeiten', label: 'Lernziel', initial: i == null ? '' : goals[i]);
      if (text == null) return;
      final next = [...goals];
      i == null ? next.add(text) : next[i] = text;
      await repo.exercises.setGoals(d.exercise.id, next);
    }

    return SectionCard(
      title: 'Lernziele',
      actions: [FilledButton.tonalIcon(key: const Key('goal-add'), onPressed: edit, icon: const Icon(Icons.add), label: const Text('Lernziel'))],
      child: goals.isEmpty
          ? const Text('Was sollen die Teilnehmenden nach der Übung können?')
          : Column(children: [
              for (var i = 0; i < goals.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined, size: 20),
                  title: Text(goals[i]),
                  onTap: () => edit(i),
                  trailing: IconButton(
                    tooltip: 'Entfernen',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => repo.exercises.setGoals(d.exercise.id, [...goals]..removeAt(i)),
                  ),
                ),
            ]),
    );
  }
}

class _Scenario extends StatelessWidget {
  const _Scenario(this.d);
  final ExerciseDetail d;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return SectionCard(
      title: 'Lage',
      subtitle: 'Was finden die Einsatzkräfte vor?',
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            final ctrl = TextEditingController(text: d.exercise.scenario);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Lage beschreiben'),
                content: SizedBox(
                  width: 560,
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    minLines: 6,
                    maxLines: 14,
                    decoration: const InputDecoration(hintText: 'z. B. PKW frontal gegen Baum, Fahrer eingeklemmt, Beifahrerin läuft verwirrt umher …'),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
                ],
              ),
            );
            if (ok == true) await repo.exercises.setScenario(d.exercise.id, ctrl.text);
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Bearbeiten'),
        ),
      ],
      child: Text(d.exercise.scenario ?? 'Noch keine Lage beschrieben.'),
    );
  }
}

class _Phases extends StatelessWidget {
  const _Phases(this.d);
  final ExerciseDetail d;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final c = Theme.of(context).colorScheme;
    return SectionCard(
      title: 'Ablauf',
      subtitle: 'Zeiten verschieben sich mit, wenn sich der Übungsbeginn ändert',
      actions: [
        FilledButton.tonalIcon(
          key: const Key('phase-add'),
          onPressed: () => _editPhase(context, d),
          icon: const Icon(Icons.add),
          label: const Text('Phase'),
        ),
      ],
      child: d.phases.isEmpty
          ? const Text('Noch kein Ablauf. Typisch: Einweisung – Alarmierung – Durchführung – Rückbau – Nachbesprechung.')
          : Column(children: [
              for (final p in d.phases)
                InkWell(
                  onTap: () => _editPhase(context, d, existing: p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        width: 78,
                        child: Text(t.clock(d.start + p.offsetMinutes),
                            style: TextStyle(fontFeatures: const [FontFeature.tabularFigures()], color: c.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: Text(p.description)),
                      IconButton(
                        tooltip: 'Entfernen',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => repo.exercises.deletePhase(p.id),
                      ),
                    ]),
                  ),
                ),
            ]),
    );
  }

  static Future<void> _editPhase(BuildContext context, ExerciseDetail d, {ExercisePhase? existing}) async {
    final repo = AppScope.of(context);
    final last = d.phases.isEmpty ? 0 : d.phases.last.offsetMinutes + 15;
    final time = TextEditingController(text: t.clock(d.start + (existing?.offsetMinutes ?? last)));
    final text = TextEditingController(text: existing?.description);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final off = t.parseOffset(time.text, start: d.start);
          return AlertDialog(
            title: Text(existing == null ? 'Phase hinzufügen' : 'Phase bearbeiten'),
            content: SizedBox(
              width: 480,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  key: const Key('phase-time'),
                  controller: time,
                  decoration: InputDecoration(
                    labelText: 'Zeit',
                    helperText: off == null ? 'Uhrzeit (19:15) oder Minuten ab Beginn (+15)' : '${t.clock(d.start + off)} Uhr · ${t.relative(off)}',
                    errorText: time.text.isNotEmpty && off == null ? 'z. B. 19:15 oder +15' : null,
                  ),
                  onChanged: (_) => setS(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('phase-text'),
                  controller: text,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(labelText: 'Was passiert?', hintText: 'z. B. Begrüßung, Sicherheitseinweisung, Ausgabe Rollenkarten'),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
              FilledButton(
                key: const Key('phase-save'),
                onPressed: off == null ? null : () => Navigator.pop(ctx, text.text.trim().isNotEmpty),
                child: const Text('Speichern'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    await repo.exercises.savePhase(d.exercise.id, id: existing?.id, offset: t.parseOffset(time.text, start: d.start)!, text: text.text);
  }
}

class _Safety extends StatelessWidget {
  const _Safety(this.d, {required this.approvalRequired});
  final ExerciseDetail d;
  final bool approvalRequired;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final done = d.checks.where((c) => c.checked).length;
    final complete = d.safetyComplete;
    return SectionCard(
      title: 'Sicherheit & Gefährdungsbeurteilung',
      subtitle: '$done von ${d.checks.length} erledigt',
      actions: [
        Tag(complete ? 'vollständig' : 'Pflicht',
            color: complete ? AppColors.ok.withValues(alpha: 0.15) : Theme.of(context).colorScheme.primaryContainer,
            textColor: complete ? AppColors.ok : Theme.of(context).colorScheme.onPrimaryContainer),
        IconButton(
          tooltip: 'Punkt hinzufügen',
          icon: const Icon(Icons.add),
          onPressed: () async {
            final text = await askText(context, title: 'Prüfpunkt hinzufügen', label: 'Prüfpunkt');
            if (text != null) await repo.exercises.addCheck(d.exercise.id, text);
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final c in d.checks)
          CheckboxListTile(
            key: ValueKey('check-${c.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: c.checked,
            title: Text(c.description),
            onChanged: (v) => repo.exercises.setCheck(c.id, v ?? false),
            secondary: IconButton(
              tooltip: 'Entfernen',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => repo.exercises.deleteCheck(c.id),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          approvalRequired
              ? 'Erst wenn alle Punkte abgehakt sind, kann die Übung zur Freigabe vorgelegt werden.'
              : 'Erst wenn alle Punkte abgehakt sind, kann die Übung als fertig markiert werden.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}
