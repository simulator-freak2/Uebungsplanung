import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/documents_repository.dart';
import '../../data/exercise_repository.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;

const _stageColors = [AppColors.yellow, AppColors.warn, AppColors.red];
Color stageColor(int i) => _stageColors[i.clamp(0, _stageColors.length - 1)];

/// Rollenkarten für Mimen bzw. Darsteller.
class RolesTab extends StatelessWidget {
  const RolesTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Die Eskalationsstufen erscheinen auch auf dem Beobachtungsbogen und in der Beobachter-Ansicht.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            FilledButton.tonalIcon(
              key: const Key('role-add'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => RoleDialog(detail: d),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Rollenkarte'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (d.roles.isEmpty)
          const EmptyHint(
            icon: Icons.badge_outlined,
            text: 'Noch keine Rollenkarten.\nJede Mime bekommt eine Karte mit Lage, Verletzungen und Verhalten.',
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final r in d.roles)
                RoleCardView(
                  role: r,
                  exerciseDate: d.exercise.date,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => RoleDialog(detail: d, existing: r),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class RoleCardView extends StatelessWidget {
  const RoleCardView({super.key, required this.role, required this.exerciseDate, this.onTap, this.width = 460});
  final RoleCard role;
  final DateTime exerciseDate;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final r = role;
    final age = ageOn(r, exerciseDate);
    final stages = decodeEscalation(r.escalation);
    Widget field(String label, String? value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: c.onSurfaceVariant),
          ),
          Text(value ?? '–'),
        ],
      ),
    );
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.onSurface, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field('Name', r.name)),
                    Text(
                      '${r.number}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.red, height: 1),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field('Geburtsdatum', r.birthDate == null ? null : t.date(r.birthDate!))),
                    Expanded(child: field('Alter', age == null ? null : '$age Jahre')),
                    Expanded(child: field('Vorerkrankungen', r.preExisting)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field('Erkrankungen', r.illnesses)),
                    Expanded(child: field('Symptome', r.symptoms)),
                    Expanded(child: field('Verletzungen', r.injuries)),
                  ],
                ),
                field('Story – was ist passiert?', r.story),
                if (stages.isNotEmpty) ...[
                  Text(
                    'ESKALATIONSSTUFEN',
                    style: TextStyle(fontSize: 10.5, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: c.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < stages.length; i++) EscalationRow(stage: stages[i], index: i),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EscalationRow extends StatelessWidget {
  const EscalationRow({super.key, required this.stage, required this.index, this.large = false});
  final EscalationStage stage;
  final int index;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(left: BorderSide(color: stageColor(index), width: 4)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: large ? 170 : 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.label,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: large ? 16 : 13),
                ),
                if (stage.trigger.isNotEmpty)
                  Text(
                    stage.trigger,
                    style: TextStyle(fontSize: large ? 13 : 11, color: c.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(stage.behavior, style: TextStyle(fontSize: large ? 16 : 14)),
          ),
        ],
      ),
    );
  }
}

class RoleDialog extends StatefulWidget {
  const RoleDialog({super.key, required this.detail, this.existing});
  final ExerciseDetail detail;
  final RoleCard? existing;

  @override
  State<RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<RoleDialog> {
  late final r = widget.existing;
  late final _name = TextEditingController(text: r?.name);
  late final _number = TextEditingController(text: '${r?.number ?? widget.detail.roles.length + 1}');
  late final _birth = TextEditingController(text: r?.birthDate == null ? '' : t.date(r!.birthDate!));
  late final _age = TextEditingController(text: r?.age?.toString());
  late final _pre = TextEditingController(text: r?.preExisting);
  late final _ill = TextEditingController(text: r?.illnesses);
  late final _sym = TextEditingController(text: r?.symptoms);
  late final _inj = TextEditingController(text: r?.injuries);
  late final _story = TextEditingController(text: r?.story);
  late final List<(TextEditingController, TextEditingController, TextEditingController)> _stages = [
    for (final s in (r == null ? _defaultStages : decodeEscalation(r!.escalation)))
      (TextEditingController(text: s.label), TextEditingController(text: s.trigger), TextEditingController(text: s.behavior)),
  ];

  static const _defaultStages = [
    EscalationStage(label: 'Stufe 1', trigger: 'Beginn', behavior: ''),
    EscalationStage(label: 'Stufe 2', trigger: '', behavior: ''),
    EscalationStage(label: 'Stufe 3', trigger: 'auf Zeichen der Übungsleitung', behavior: ''),
  ];

  /// „14.05.1981“ → Datum
  static DateTime? parseDate(String s) {
    final m = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(s.trim());
    if (m == null) return null;
    final d = DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    return d.day == int.parse(m.group(1)!) ? d : null;
  }

  bool get _birthBad => _birth.text.trim().isNotEmpty && parseDate(_birth.text) == null;

  @override
  Widget build(BuildContext context) {
    Widget tf(TextEditingController c, String label, {String? hint, int lines = 1, Key? key}) => TextField(
      key: key,
      controller: c,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
    final birth = parseDate(_birth.text);
    return AlertDialog(
      title: Text(r == null ? 'Rollenkarte anlegen' : 'Rollenkarte bearbeiten'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(width: 80, child: tf(_number, 'Nr.')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: tf(_name, 'Name *', hint: 'z. B. Thomas Berger', key: const Key('role-name')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _birth,
                      decoration: InputDecoration(
                        labelText: 'Geburtsdatum',
                        hintText: 'TT.MM.JJJJ',
                        errorText: _birthBad ? 'z. B. 14.05.1981' : null,
                        helperText: birth == null ? null : 'am Übungstag ${ageOn(_preview(birth), widget.detail.exercise.date)} Jahre',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _age,
                      enabled: birth == null,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Alter', helperText: 'nur ohne Geburtsdatum'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: tf(_pre, 'Vorerkrankungen', hint: 'z. B. Bluthochdruck')),
                  const SizedBox(width: 12),
                  Expanded(child: tf(_ill, 'Erkrankungen', hint: 'z. B. Diabetes Typ 2')),
                ],
              ),
              const SizedBox(height: 12),
              tf(_sym, 'Symptome', hint: 'z. B. starke Schmerzen rechtes Bein, Schwindel', lines: 2),
              const SizedBox(height: 12),
              tf(_inj, 'Verletzungen', hint: 'z. B. Unterschenkelfraktur rechts, Platzwunde Stirn', lines: 2),
              const SizedBox(height: 12),
              tf(_story, 'Story – was ist passiert?', lines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Eskalationsstufen', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _stages.add((
                        TextEditingController(text: 'Stufe ${_stages.length + 1}'),
                        TextEditingController(),
                        TextEditingController(),
                      )),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Stufe'),
                  ),
                ],
              ),
              for (var i = 0; i < _stages.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 4, height: 48, color: stageColor(i)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _stages[i].$1,
                          decoration: const InputDecoration(labelText: 'Stufe', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 170,
                        child: TextField(
                          controller: _stages[i].$2,
                          decoration: const InputDecoration(labelText: 'Auslöser', hintText: 'z. B. nach 5 Min.', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: Key('role-stage-$i'),
                          controller: _stages[i].$3,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Verhalten der Mime', isDense: true),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Stufe entfernen',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _stages.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text('Leere Stufen (ohne Verhalten) werden nicht gespeichert.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
      actions: [
        if (r != null)
          TextButton(
            onPressed: () async {
              if (await confirmDelete(context, r!.name) && context.mounted) {
                await AppScope.of(context).documents.deleteRole(r!.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Löschen'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          key: const Key('role-save'),
          onPressed: () async {
            if (_name.text.trim().isEmpty || _birthBad) return;
            await AppScope.of(context).documents.saveRole(
              widget.detail.exercise.id,
              RoleCardInput(
                id: r?.id,
                number: int.tryParse(_number.text.trim()) ?? 1,
                name: _name.text,
                birthDate: birth,
                age: birth == null ? int.tryParse(_age.text.trim()) : null,
                preExisting: _pre.text,
                illnesses: _ill.text,
                symptoms: _sym.text,
                injuries: _inj.text,
                story: _story.text,
                escalation: [
                  for (final s in _stages) EscalationStage(label: s.$1.text.trim(), trigger: s.$2.text.trim(), behavior: s.$3.text.trim()),
                ],
              ),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  RoleCard _preview(DateTime birth) =>
      RoleCard(id: '', updatedAt: DateTime.now(), deleted: false, exerciseId: '', number: 0, name: '', birthDate: birth, escalation: '[]');
}
