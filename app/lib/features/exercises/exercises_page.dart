import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../data/profile.dart';
import '../../data/repositories.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;
import 'exercise_actions.dart';
import 'exercise_detail_page.dart';

/// Bereich „Übungen“ mit eigenem Navigator, damit die Seitenleiste beim
/// Öffnen einer Übung sichtbar bleibt.
class ExercisesSection extends StatelessWidget {
  const ExercisesSection({super.key});

  @override
  Widget build(BuildContext context) => Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const ExercisesPage()));
}

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late final repo = AppScope.of(context);
  late final _list = repo.exercises.watchAll();
  late final _approval = repo.settings.watchBool(SettingsRepository.approvalRequired, fallback: true);
  bool _showPast = false;

  void _open(String id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseId: id)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('exercise-add'),
        heroTag: 'exercise-add',
        onPressed: () async {
          final id = await showExerciseDialog(context);
          if (id != null) _open(id);
        },
        icon: const Icon(Icons.add),
        label: const Text('Neue Übung'),
      ),
      body: StreamView<List<Exercise>>(
        stream: _list,
        builder: (context, all) => StreamBuilder<bool>(
          stream: _approval,
          builder: (context, approvalSnap) {
            final approval = approvalSnap.data ?? true;
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);
            final past = all.where((e) => e.date.isBefore(todayDate)).toList().reversed.toList();
            final upcoming = all.where((e) => !e.date.isBefore(todayDate)).toList();
            final list = _showPast ? past : upcoming;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Übungen',
                  subtitle: 'Übungen ausarbeiten: Ablauf, Sicherheit, Fahrzeugbesetzung, Alarmierung',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final templates = await repo.exercises.watchTemplates().first;
                        if (!context.mounted) return;
                        if (templates.isEmpty) {
                          showMessage(context, 'Noch keine Vorlagen. In einer Übung über ⋮ „Als Vorlage speichern“ wählen.');
                          return;
                        }
                        final tpl = await showDialog<Exercise>(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            title: const Text('Vorlage wählen'),
                            children: [for (final e in templates) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e), child: Text(e.title))],
                          ),
                        );
                        if (tpl == null || !context.mounted) return;
                        final id = await copyAsNewExercise(context, tpl.id, title: tpl.title, heading: 'Übung aus Vorlage anlegen');
                        if (id != null) _open(id);
                      },
                      icon: const Icon(Icons.library_books_outlined),
                      label: const Text('Aus Vorlage'),
                    ),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text('Anstehend (${upcoming.length})')),
                        ButtonSegment(value: true, label: Text('Vergangen (${past.length})')),
                      ],
                      selected: {_showPast},
                      onSelectionChanged: (s) => setState(() => _showPast = s.first),
                    ),
                  ],
                ),
                Expanded(
                  child: list.isEmpty
                      ? EmptyHint(
                          icon: Icons.description_outlined,
                          text: _showPast ? 'Keine vergangenen Übungen.' : 'Noch keine anstehenden Übungen.\nLegt eine neue Übung an.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              ExerciseTile(exercise: list[i], approvalRequired: approval, onTap: () => _open(list[i].id)),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({super.key, required this.exercise, required this.approvalRequired, required this.onTap});
  final Exercise exercise;
  final bool approvalRequired;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final c = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${e.date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1)),
            Text(t.monthShort(e.date).toUpperCase(), style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
          ],
        ),
      ),
      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          '${t.clock(e.startMinutes)}${e.endMinutes == null ? '' : '–${t.clock(e.endMinutes!)}'} Uhr',
          if (e.unit != null) e.unit!,
          if (e.location != null) e.location!,
        ].join(' · '),
      ),
      trailing: StatusTag(status: e.status, approvalRequired: approvalRequired),
    );
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status, required this.approvalRequired});
  final String status;
  final bool approvalRequired;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final label = ExerciseStatus.label(status, approvalRequired: approvalRequired);
    return switch (status) {
      ExerciseStatus.approved => Tag(label, color: const Color(0x261F7A45), textColor: const Color(0xFF1F7A45)),
      ExerciseStatus.submitted => Tag(label, color: c.tertiaryContainer, textColor: c.onTertiaryContainer),
      _ => Tag(label),
    };
  }
}

/// Dialog für die Eckdaten. Ohne [existing] wird eine neue Übung angelegt und
/// deren ID zurückgegeben.
Future<String?> showExerciseDialog(BuildContext context, {Exercise? existing, bool asTemplate = false, DateTime? date}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _ExerciseDialog(existing: existing, asTemplate: asTemplate, date: date),
    );

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({this.existing, this.asTemplate = false, this.date});
  final Exercise? existing;
  final bool asTemplate;
  final DateTime? date;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final e = widget.existing;
  late final _title = TextEditingController(text: e?.title);
  late final _location = TextEditingController(text: e?.location);
  late final _unit = TextEditingController(text: e?.unit);
  late final _topic = TextEditingController(text: e?.topic);
  late final _start = TextEditingController(text: t.clock(e?.startMinutes ?? 19 * 60));
  late final _end = TextEditingController(text: e?.endMinutes == null ? (e == null ? '21:30' : '') : t.clock(e!.endMinutes!));
  late DateTime _date = e?.date ?? widget.date ?? _nextWeekday(DateTime.now());
  late String _category = e?.category ?? 'praxis';
  bool get _template => e?.isTemplate ?? widget.asTemplate;
  late String? _keywordId = e?.keywordId;
  late final _keywords = AppScope.of(context).keywords.watchAll();

  static DateTime _nextWeekday(DateTime d) => DateTime(d.year, d.month, d.day + 7);

  int? get _startMin => t.parseClock(_start.text);
  int? get _endMin => _end.text.trim().isEmpty ? null : t.parseClock(_end.text);
  bool get _valid => _title.text.trim().isNotEmpty && _startMin != null && (_end.text.trim().isEmpty || _endMin != null);

  Future<void> _save() async {
    final repo = AppScope.of(context);
    final input = ExerciseInput(
      id: e?.id,
      title: _title.text,
      date: _date,
      startMinutes: _startMin!,
      endMinutes: _endMin,
      location: _location.text,
      unit: _unit.text,
      topic: _topic.text,
      keywordId: _keywordId,
      category: _category,
      isTemplate: _template,
    );
    String id;
    if (e == null) {
      final profileId = await repo.settings.get(SettingsRepository.profileId);
      final profile = await OrgProfile.load(profileId ?? 'feuerwehr');
      id = await repo.exercises.create(input, safetyChecklist: profile.safetyChecklist);
    } else {
      await repo.exercises.update(input);
      id = e!.id;
    }
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(e == null ? (_template ? 'Neue Vorlage' : 'Neue Übung') : 'Eckdaten bearbeiten'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('exercise-title'),
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Titel *', hintText: 'z. B. THL: Verkehrsunfall mit eingeklemmter Person'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!_template)
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Datum', suffixIcon: Icon(Icons.calendar_today_outlined)),
                          child: Text(t.dateLong(_date)),
                        ),
                      ),
                    ),
                  if (!_template) const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('exercise-start'),
                      controller: _start,
                      decoration: InputDecoration(labelText: 'Beginn', errorText: _startMin == null ? 'z. B. 19:00' : null),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _end,
                      decoration: InputDecoration(
                        labelText: 'Ende',
                        errorText: _end.text.trim().isNotEmpty && _endMin == null ? 'z. B. 21:30' : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategorie im Dienstplan'),
                items: [for (final c in exerciseCategories.entries) DropdownMenuItem(value: c.key, child: Text(c.value))],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Ort', hintText: 'z. B. Übungsgelände Bauhof, Industriestraße 12'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(labelText: 'Einheit', hintText: 'z. B. Löschzug 1'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _topic,
                      decoration: const InputDecoration(labelText: 'Thema', hintText: 'z. B. Technische Hilfeleistung'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamView<List<Keyword>>(
                stream: _keywords,
                builder: (context, kws) => DropdownButtonFormField<String?>(
                  initialValue: kws.any((k) => k.id == _keywordId) ? _keywordId : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Alarmstichwort',
                    helperText: kws.isEmpty ? 'Stichworte werden unter „Alarmstichworte“ gepflegt.' : null,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('– keins –')),
                    for (final k in kws)
                      DropdownMenuItem(
                        value: k.id,
                        child: Text(k.description == null ? k.code : '${k.code} – ${k.description}', overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _keywordId = v),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(key: const Key('exercise-save'), onPressed: _valid ? _save : null, child: Text(e == null ? 'Anlegen' : 'Speichern')),
      ],
    );
  }
}
