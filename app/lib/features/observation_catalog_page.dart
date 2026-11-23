import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../import/tabular.dart';
import '../ui/widgets.dart';
import 'import_dialog.dart';

const _catalogFields = [
  ImportField('description', 'Beobachtungspunkt', required: true, aliases: ['punkt', 'kriterium', 'beobachtung', 'text', 'beschreibung']),
  ImportField('category', 'Kategorie', aliases: ['thema', 'bereich', 'gruppe']),
];

/// Zentraler Katalog von Beobachtungspunkten.
class ObservationCatalogPage extends StatefulWidget {
  const ObservationCatalogPage({super.key});

  @override
  State<ObservationCatalogPage> createState() => _ObservationCatalogPageState();
}

class _ObservationCatalogPageState extends State<ObservationCatalogPage> {
  late final repo = AppScope.of(context);
  late final _catalog = repo.documents.watchCatalog();

  Future<void> _edit([ObservationTemplate? item]) async {
    final desc = TextEditingController(text: item?.description);
    final cat = TextEditingController(text: item?.category);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Beobachtungspunkt' : 'Beobachtungspunkt bearbeiten'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: desc, autofocus: true, decoration: const InputDecoration(labelText: 'Beobachtungspunkt *', hintText: 'z. B. Lagemeldung innerhalb von 5 Minuten')),
            const SizedBox(height: 12),
            TextField(controller: cat, decoration: const InputDecoration(labelText: 'Kategorie', hintText: 'z. B. Führung, Atemschutz, Wasserrettung')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, desc.text.trim().isNotEmpty), child: const Text('Speichern')),
        ],
      ),
    );
    if (ok == true) await repo.documents.saveCatalogItem(id: item?.id, description: desc.text, category: cat.text);
  }

  Future<void> _import() async {
    final picked = await pickAndMapTable(context, title: 'Beobachtungspunkte importieren', fields: _catalogFields);
    if (picked == null) return;
    final t = picked.table;
    final n = await repo.documents.importCatalog([
      for (final r in t.rows) (t.cell(r, picked.mapping['description']), t.cell(r, picked.mapping['category']).isEmpty ? null : t.cell(r, picked.mapping['category'])),
    ]);
    if (mounted) showMessage(context, '$n Beobachtungspunkte übernommen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(heroTag: 'catalog-add', onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Punkt')),
      body: StreamView<List<ObservationTemplate>>(
        stream: _catalog,
        builder: (context, list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Beobachtungspunkte',
              subtitle: 'Zentraler Katalog für Beobachtungsbögen – in jeder Übung mit „Aus Katalog“ übernehmen',
              actions: [OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Import (Excel/CSV)'))],
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyHint(icon: Icons.checklist_outlined, text: 'Noch keine Beobachtungspunkte im Katalog.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final o = list[i];
                        return ListTile(
                          title: Text(o.description),
                          subtitle: o.category == null ? null : Text(o.category!),
                          onTap: () => _edit(o),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirmDelete(context, o.description)) await repo.documents.deleteCatalogItem(o.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
