import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/documents_repository.dart';
import '../../data/exercise_repository.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'tab_roles.dart';

/// Beobachtungsbogen: Beobachtungspunkte mit Bewertung und Notiz, dazu die
/// Eskalationsstufen der Mimen.
class ObservationTab extends StatelessWidget {
  const ObservationTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final d = detail;
    final c = Theme.of(context).colorScheme;

    Future<void> fromCatalog() async {
      final catalog = await repo.documents.catalog();
      if (!context.mounted) return;
      if (catalog.isEmpty) {
        showMessage(context, 'Der Katalog ist leer. Punkte pflegt ihr unter Stammdaten → Beobachtungspunkte.');
        return;
      }
      final have = {for (final o in d.observations) o.description.toLowerCase()};
      final picked = await showDialog<List<ObservationTemplate>>(context: context, builder: (_) => _CatalogPicker(catalog: catalog, existing: have));
      for (final p in picked ?? const <ObservationTemplate>[]) {
        await repo.documents.addObservation(d.exercise.id, p.description);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        SectionCard(
          title: 'Beobachtungsbogen',
          subtitle: 'Bewertung: ++ sehr gut · + gut · o ausreichend · – Verbesserung nötig',
          actions: [
            OutlinedButton.icon(onPressed: fromCatalog, icon: const Icon(Icons.playlist_add), label: const Text('Aus Katalog')),
            FilledButton.tonalIcon(
              key: const Key('observation-add'),
              onPressed: () async {
                final text = await askText(context, title: 'Beobachtungspunkt', label: 'Was wird beobachtet?');
                if (text != null) await repo.documents.addObservation(d.exercise.id, text);
              },
              icon: const Icon(Icons.add),
              label: const Text('Punkt'),
            ),
          ],
          child: d.observations.isEmpty
              ? const Text('Noch keine Beobachtungspunkte. Frei eintragen oder aus dem zentralen Katalog übernehmen.')
              : Column(children: [for (final o in d.observations) _ObservationRow(item: o)]),
        ),
        if (d.roles.any((r) => decodeEscalation(r.escalation).isNotEmpty)) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Eskalationsstufen der Mimen',
            subtitle: 'Zur Orientierung für die Beobachter',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final r in d.roles)
                if (decodeEscalation(r.escalation).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${r.number}  ${r.name}', style: TextStyle(fontWeight: FontWeight.w700, color: c.primary)),
                      const SizedBox(height: 4),
                      for (final (i, s) in decodeEscalation(r.escalation).indexed) EscalationRow(stage: s, index: i),
                    ]),
                  ),
            ]),
          ),
        ],
      ],
    );
  }
}

class _ObservationRow extends StatefulWidget {
  const _ObservationRow({required this.item});
  final ObservationItem item;

  @override
  State<_ObservationRow> createState() => _ObservationRowState();
}

class _ObservationRowState extends State<_ObservationRow> {
  late final _note = TextEditingController(text: widget.item.note);
  late final _focus = FocusNode()..addListener(_saveNote);

  void _saveNote() {
    if (!_focus.hasFocus && (_note.text.trim()) != (widget.item.note ?? '')) {
      AppScope.of(context).documents.updateObservation(widget.item.id, note: _note.text);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final o = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 300, child: Text(o.description, style: const TextStyle(fontWeight: FontWeight.w600))),
        SegmentedButton<String>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [for (final r in ratings.keys) ButtonSegment(value: r, label: Text(r == '-' ? '–' : r), tooltip: ratings[r])],
          selected: {?o.rating},
          onSelectionChanged: (s) => s.isEmpty
              ? repo.documents.updateObservation(o.id, clearRating: true)
              : repo.documents.updateObservation(o.id, rating: s.first),
        ),
        SizedBox(
          width: 320,
          child: TextField(
            controller: _note,
            focusNode: _focus,
            decoration: const InputDecoration(isDense: true, hintText: 'Notiz, Uhrzeit …'),
            onSubmitted: (_) => _saveNote(),
          ),
        ),
        IconButton(tooltip: 'Entfernen', icon: const Icon(Icons.close), onPressed: () => repo.documents.deleteObservation(o.id)),
      ]),
    );
  }
}

class _CatalogPicker extends StatefulWidget {
  const _CatalogPicker({required this.catalog, required this.existing});
  final List<ObservationTemplate> catalog;
  final Set<String> existing;

  @override
  State<_CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<_CatalogPicker> {
  final _picked = <ObservationTemplate>{};

  @override
  Widget build(BuildContext context) {
    final byCat = <String, List<ObservationTemplate>>{};
    for (final c in widget.catalog) {
      byCat.putIfAbsent(c.category ?? 'Allgemein', () => []).add(c);
    }
    return AlertDialog(
      title: const Text('Aus dem Katalog übernehmen'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: ListView(children: [
          for (final e in byCat.entries) ...[
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(e.key, style: Theme.of(context).textTheme.titleSmall)),
            for (final c in e.value)
              CheckboxListTile(
                dense: true,
                value: _picked.contains(c) || widget.existing.contains(c.description.toLowerCase()),
                onChanged: widget.existing.contains(c.description.toLowerCase())
                    ? null
                    : (v) => setState(() => v == true ? _picked.add(c) : _picked.remove(c)),
                title: Text(c.description),
              ),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, _picked.toList()), child: Text('${_picked.length} übernehmen')),
      ],
    );
  }
}

/// Nachbesprechung: Was lief gut, was muss besser werden, Maßnahmen.
class DebriefTab extends StatelessWidget {
  const DebriefTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final d = detail;
    final id = d.exercise.id;

    Widget list(String title, String hint, List<String> items, Future<void> Function(List<String>) save, {Key? addKey}) => SectionCard(
          title: title,
          actions: [
            IconButton(
              key: addKey,
              tooltip: 'Hinzufügen',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final text = await askText(context, title: title, label: hint);
                if (text != null) await save([...items, text]);
              },
            ),
          ],
          child: items.isEmpty
              ? Text(hint, style: Theme.of(context).textTheme.bodySmall)
              : Column(children: [
                  for (var i = 0; i < items.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle, size: 8),
                      title: Text(items[i]),
                      onTap: () async {
                        final text = await askText(context, title: title, label: hint, initial: items[i]);
                        if (text != null) await save([...items]..[i] = text);
                      },
                      trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => save([...items]..removeAt(i))),
                    ),
                ]),
        );

    Future<void> editLesson([Lesson? l]) async {
      final text = TextEditingController(text: l?.description);
      final who = TextEditingController(text: l?.responsible);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l == null ? 'Maßnahme / Erkenntnis' : 'Maßnahme bearbeiten'),
          content: SizedBox(
            width: 480,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                key: const Key('lesson-text'),
                controller: text,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'Was soll künftig geübt oder geändert werden? *'),
              ),
              const SizedBox(height: 12),
              TextField(controller: who, decoration: const InputDecoration(labelText: 'Zuständig')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(key: const Key('lesson-save'), onPressed: () => Navigator.pop(ctx, text.text.trim().isNotEmpty), child: const Text('Speichern')),
          ],
        ),
      );
      if (ok == true) await repo.documents.saveLesson(id, id: l?.id, description: text.text, responsible: who.text, status: l?.status ?? 'offen');
    }

    final participants = d.exercise.debriefParticipants;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        SectionCard(
          title: 'Teilnehmende der Nachbesprechung',
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final text = await askText(context, title: 'Teilnehmende', label: 'Namen oder Anzahl', initial: participants ?? '');
                if (text != null) await repo.documents.setDebrief(id, participants: text);
              },
            ),
          ],
          child: Text(participants ?? '–'),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 520, child: list('Was lief gut?', 'z. B. Absicherung nach 4 Minuten vollständig', d.debriefGood, (v) => repo.documents.setDebrief(id, good: v), addKey: const Key('debrief-good'))),
          SizedBox(width: 520, child: list('Was muss besser werden?', 'z. B. Lagemeldung kam zu spät', d.debriefBad, (v) => repo.documents.setDebrief(id, bad: v))),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Maßnahmen für die weitere Übungsplanung',
          subtitle: 'Offene Maßnahmen erscheinen in der Übersicht und lassen sich in kommende Übungen übernehmen',
          actions: [FilledButton.tonalIcon(key: const Key('lesson-add'), onPressed: editLesson, icon: const Icon(Icons.add), label: const Text('Maßnahme'))],
          child: d.lessons.isEmpty
              ? const Text('Noch keine Maßnahmen.')
              : Column(children: [
                  for (final l in d.lessons)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.description),
                      subtitle: l.responsible == null ? null : Text('Zuständig: ${l.responsible}'),
                      onTap: () => editLesson(l),
                      trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                        DropdownButton<String>(
                          value: l.status,
                          underline: const SizedBox(),
                          items: [for (final e in lessonStatus.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                          onChanged: (v) => repo.documents.setLessonStatus(l.id, v!, plannedIn: l.plannedInExerciseId),
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => repo.documents.deleteLesson(l.id)),
                      ]),
                    ),
                ]),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Weitere Notizen',
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final ctrl = TextEditingController(text: d.exercise.debriefNotes);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Notizen zur Nachbesprechung'),
                    content: SizedBox(width: 560, child: TextField(controller: ctrl, autofocus: true, minLines: 6, maxLines: 14)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
                    ],
                  ),
                );
                if (ok == true) await repo.documents.setDebrief(id, notes: ctrl.text);
              },
            ),
          ],
          child: Text(d.exercise.debriefNotes ?? '–'),
        ),
        if (d.observations.any((o) => o.rating != null)) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Ergebnis Beobachtungsbogen',
            child: Column(children: [
              for (final o in d.observations.where((o) => o.rating != null))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Tag(o.rating == '-' ? '–' : o.rating!,
                      color: o.rating == '-' ? AppColors.warn.withValues(alpha: 0.18) : AppColors.ok.withValues(alpha: 0.15),
                      textColor: o.rating == '-' ? AppColors.warn : AppColors.ok),
                  title: Text(o.description),
                  subtitle: o.note == null ? null : Text(o.note!),
                ),
            ]),
          ),
        ],
      ],
    );
  }
}
