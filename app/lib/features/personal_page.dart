import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import '../import/importers.dart';
import '../ui/widgets.dart';
import 'import_dialog.dart';

class PersonalPage extends StatelessWidget {
  const PersonalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Personal & Qualifikationen',
            subtitle: 'Gespeichert werden nur Name, Personalnummer und Qualifikationen',
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [Tab(text: 'Personen'), Tab(text: 'Qualifikationen')],
          ),
          const Expanded(child: TabBarView(children: [_PersonsTab(), _QualificationsTab()])),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Personen
// ---------------------------------------------------------------------------

class _PersonsTab extends StatefulWidget {
  const _PersonsTab();

  @override
  State<_PersonsTab> createState() => _PersonsTabState();
}

class _PersonsTabState extends State<_PersonsTab> {
  String _query = '';
  late final Stream<List<PersonWithQualifications>> _stream = AppScope.of(context).persons.watchAll();

  Future<void> _import() async {
    final repo = AppScope.of(context);
    final picked = await pickAndMapTable(
      context,
      title: 'Personal importieren',
      fields: personFields,
      hint: 'Entweder „Nachname“ (und „Vorname“) oder „Name“ zuordnen. Mehrere Qualifikationen in einer Zelle mit Komma oder Semikolon trennen. '
          'Vorhandene Personen (gleiche Personalnummer oder gleicher Name) werden ergänzt, nicht doppelt angelegt.',
    );
    if (picked == null) return;
    final rows = mapPersons(picked.table, picked.mapping);
    final result = await importPersons(repo, rows);
    if (!mounted) return;
    showMessage(
      context,
      '${result.created} Personen neu, ${result.updated} aktualisiert'
      '${result.newQualifications.isEmpty ? '' : ', neue Qualifikationen: ${result.newQualifications.join(', ')}'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'person-add',
        onPressed: () => showPersonDialog(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Person'),
      ),
      body: StreamView<List<PersonWithQualifications>>(
        stream: _stream,
        builder: (context, all) {
          final q = _query.toLowerCase();
          final list = all
              .where((p) =>
                  q.isEmpty ||
                  p.displayName.toLowerCase().contains(q) ||
                  (p.person.personnelNo ?? '').toLowerCase().contains(q) ||
                  p.qualifications.any((x) => x.name.toLowerCase().contains(q)))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Name, Personalnr. oder Qualifikation', isDense: true),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Excel-/CSV-Import')),
                    Text('${list.length} von ${all.length}'),
                  ],
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? const EmptyHint(icon: Icons.groups_outlined, text: 'Noch keine Personen.\nLegt Personen an oder importiert eine Excel-Liste.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _PersonTile(list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile(this.p);
  final PersonWithQualifications p;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Row(children: [
        Flexible(child: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w600))),
        if (p.person.youth) ...[const SizedBox(width: 8), Tag('Jugend', color: c.tertiaryContainer, textColor: c.onTertiaryContainer)],
      ]),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (p.person.personnelNo != null) Text('Nr. ${p.person.personnelNo}  ', style: TextStyle(color: c.onSurfaceVariant)),
            for (final q in p.qualifications) Tag(q.name),
          ],
        ),
      ),
      onTap: () => showPersonDialog(context, existing: p),
      trailing: IconButton(
        tooltip: 'Löschen',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          if (await confirmDelete(context, p.displayName) && context.mounted) {
            await AppScope.of(context).persons.delete(p.person.id);
          }
        },
      ),
    );
  }
}

Future<void> showPersonDialog(BuildContext context, {PersonWithQualifications? existing}) =>
    showDialog(context: context, builder: (_) => _PersonDialog(existing: existing));

class _PersonDialog extends StatefulWidget {
  const _PersonDialog({this.existing});
  final PersonWithQualifications? existing;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  late final _last = TextEditingController(text: widget.existing?.person.lastName);
  late final _first = TextEditingController(text: widget.existing?.person.firstName);
  late final _no = TextEditingController(text: widget.existing?.person.personnelNo);
  late bool _youth = widget.existing?.person.youth ?? false;
  late final Set<String> _quals = {...?widget.existing?.qualificationIds};
  late final Stream<List<Qualification>> _qualStream = AppScope.of(context).qualifications.watchAll();

  Future<void> _save() async {
    if (_last.text.trim().isEmpty) return;
    await AppScope.of(context).persons.save(PersonInput(
          id: widget.existing?.person.id,
          lastName: _last.text,
          firstName: _first.text,
          personnelNo: _no.text,
          youth: _youth,
          qualificationIds: _quals,
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Person anlegen' : 'Person bearbeiten'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: TextField(key: const Key('person-last'), controller: _last, autofocus: true, decoration: const InputDecoration(labelText: 'Nachname *'), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 12),
                Expanded(child: TextField(key: const Key('person-first'), controller: _first, decoration: const InputDecoration(labelText: 'Vorname'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _no, decoration: const InputDecoration(labelText: 'Personalnummer')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jugend (Jugendfeuerwehr / DLRG-Jugend)'),
                value: _youth,
                onChanged: (v) => setState(() => _youth = v),
              ),
              const SizedBox(height: 4),
              Text('Qualifikationen', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              StreamView<List<Qualification>>(
                stream: _qualStream,
                builder: (context, quals) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final q in quals)
                      FilterChip(
                        label: Text(q.name),
                        selected: _quals.contains(q.id),
                        onSelected: (on) => setState(() => on ? _quals.add(q.id) : _quals.remove(q.id)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(key: const Key('person-save'), onPressed: _last.text.trim().isEmpty ? null : _save, child: const Text('Speichern')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Qualifikationen
// ---------------------------------------------------------------------------

class _QualificationsTab extends StatefulWidget {
  const _QualificationsTab();

  @override
  State<_QualificationsTab> createState() => _QualificationsTabState();
}

class _QualificationsTabState extends State<_QualificationsTab> {
  late final repo = AppScope.of(context);
  late final _quals = repo.qualifications.watchAll();
  late final _usage = repo.qualifications.watchUsage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'qual-add',
        onPressed: () async {
          final name = await askText(context, title: 'Qualifikation anlegen');
          if (name != null) await repo.qualifications.ensure(name);
        },
        icon: const Icon(Icons.add),
        label: const Text('Qualifikation'),
      ),
      body: StreamView<List<Qualification>>(
        stream: _quals,
        builder: (context, quals) => StreamBuilder<Map<String, int>>(
          stream: _usage,
          builder: (context, usage) => ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
            buildDefaultDragHandles: false,
            itemCount: quals.length,
            onReorderItem: (from, to) {
              final ids = quals.map((q) => q.id).toList();
              ids.insert(to, ids.removeAt(from));
              repo.qualifications.reorder(ids);
            },
            itemBuilder: (context, i) {
              final q = quals[i];
              final n = usage.data?[q.id] ?? 0;
              return ListTile(
                key: ValueKey(q.id),
                leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                title: Text(q.name),
                subtitle: Text(n == 1 ? '1 Person' : '$n Personen'),
                trailing: Wrap(children: [
                  IconButton(
                    tooltip: 'Umbenennen',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final name = await askText(context, title: 'Qualifikation umbenennen', initial: q.name);
                      if (name != null) await repo.qualifications.rename(q.id, name);
                    },
                  ),
                  IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirmDelete(context, q.name,
                          details: n > 0 ? 'Die Qualifikation wird bei $n Personen entfernt und als Voraussetzung bei Funktionen gestrichen.' : null)) {
                        await repo.qualifications.delete(q.id);
                      }
                    },
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}
