import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import '../import/importers.dart';
import '../import/tabular.dart';
import '../ui/widgets.dart';
import 'import_dialog.dart';

class KeywordsPage extends StatefulWidget {
  const KeywordsPage({super.key});

  @override
  State<KeywordsPage> createState() => _KeywordsPageState();
}

class _KeywordsPageState extends State<KeywordsPage> {
  late final repo = AppScope.of(context);
  late final _stream = repo.keywords.watchAll();
  String _query = '';

  Future<void> _import() async {
    final picked = await pickAndMapTable(
      context,
      title: 'Alarmstichworte importieren',
      fields: keywordFields,
      hint: 'Zum Beispiel die öffentliche Stichworttabelle Rheinland-Pfalz als Excel- oder CSV-Datei. '
          'Vorhandene Stichworte (gleiches Kürzel) werden aktualisiert.',
    );
    if (picked == null) return;
    final (created, updated) = await repo.keywords.upsertAll(mapKeywords(picked.table, picked.mapping));
    if (mounted) showMessage(context, '$created Stichworte neu, $updated aktualisiert');
  }

  Future<void> _export(List<Keyword> list) async {
    final bytes = writeCsv(keywordsToRows(list.map((k) =>
        (code: k.code, category: k.category, description: k.description, resources: k.resources, specialRights: k.specialRights))));
    final uri = await FilePicker.saveFile(fileName: 'alarmstichworte.csv', bytes: bytes, mimeType: 'text/csv');
    if (uri != null && mounted) showMessage(context, 'Stichworte exportiert');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'kw-add',
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Stichwort'),
      ),
      body: StreamView<List<Keyword>>(
        stream: _stream,
        builder: (context, all) {
          final q = _query.toLowerCase();
          final list = all
              .where((k) => q.isEmpty || [k.code, k.category, k.description, k.resources].any((s) => (s ?? '').toLowerCase().contains(q)))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Alarmstichworte',
                subtitle: 'Zentrale Stichwortdatenbank mit Alarm- und Ausrückeordnung (AAO)',
                actions: [
                  OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Import (Excel/CSV)')),
                  OutlinedButton.icon(onPressed: all.isEmpty ? null : () => _export(all), icon: const Icon(Icons.download), label: const Text('Export CSV')),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Row(children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Stichwort, Kategorie, Einsatzmittel', isDense: true),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${list.length} von ${all.length}'),
                ]),
              ),
              Expanded(
                child: all.isEmpty
                    ? EmptyHint(
                        icon: Icons.notifications_active_outlined,
                        text: 'Noch keine Alarmstichworte.\nImportiert die Stichworttabelle eures Landes oder legt Stichworte einzeln an.',
                        action: FilledButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Tabelle importieren')),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _tile(list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(Keyword k) {
    final c = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Tag(k.code, color: c.primaryContainer, textColor: c.onPrimaryContainer),
        if (k.category != null) Text(k.category!, style: TextStyle(color: c.onSurfaceVariant)),
        if (!k.specialRights) const Tag('ohne Sonderrechte'),
      ]),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (k.description != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(k.description!)),
        if (k.resources != null) Text('AAO: ${k.resources}', style: TextStyle(color: c.onSurfaceVariant)),
      ]),
      onTap: () => _edit(k),
      trailing: IconButton(
        tooltip: 'Löschen',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          if (await confirmDelete(context, k.code)) await repo.keywords.delete(k.id);
        },
      ),
    );
  }

  Future<void> _edit([Keyword? k]) async {
    final code = TextEditingController(text: k?.code);
    final cat = TextEditingController(text: k?.category);
    final desc = TextEditingController(text: k?.description);
    final res = TextEditingController(text: k?.resources);
    var special = k?.specialRights ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(k == null ? 'Stichwort anlegen' : 'Stichwort bearbeiten'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(key: const Key('kw-code'), controller: code, autofocus: true, decoration: const InputDecoration(labelText: 'Stichwort *', hintText: 'z. B. TH 2 – VU P eingeklemmt')),
                const SizedBox(height: 12),
                TextField(controller: cat, decoration: const InputDecoration(labelText: 'Kategorie', hintText: 'z. B. Hilfeleistung')),
                const SizedBox(height: 12),
                TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Beschreibung')),
                const SizedBox(height: 12),
                TextField(controller: res, decoration: const InputDecoration(labelText: 'Einsatzmittel laut AAO', hintText: 'z. B. HLF, RW, ELW 1')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sonderrechte / prioritär'),
                  value: special,
                  onChanged: (v) => setS(() => special = v),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(key: const Key('kw-save'), onPressed: () => Navigator.pop(ctx, code.text.trim().isNotEmpty), child: const Text('Speichern')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await repo.keywords.save(KeywordInput(id: k?.id, code: code.text, category: cat.text, description: desc.text, resources: res.text, specialRights: special));
    }
  }
}
