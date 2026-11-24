import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/documents_repository.dart';
import '../../data/exercise_repository.dart';
import '../../materialkompass/mk_ui.dart';
import '../../ui/widgets.dart';

/// Funkplan: Rufname, Gerät, Funknetz, Gruppe/Kanal, Aufgabe.
class RadioTab extends StatelessWidget {
  const RadioTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final d = detail;
    final c = Theme.of(context).colorScheme;

    Future<void> edit([RadioEntry? r]) async {
      final call = TextEditingController(text: r?.callSign);
      final device = TextEditingController(text: r?.device);
      final channel = TextEditingController(text: r?.channel);
      final task = TextEditingController(text: r?.task);
      var net = r?.network ?? 'bos_digital';
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(r == null ? 'Funkplan-Eintrag' : 'Eintrag bearbeiten'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('radio-call'),
                    controller: call,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Rufname *', hintText: 'z. B. Florian Musterstadt 1/46-1'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: device,
                          decoration: const InputDecoration(labelText: 'Einheit / Gerät', hintText: 'z. B. HLF 20, Handfunkgerät'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: net,
                          decoration: const InputDecoration(labelText: 'Funknetz'),
                          items: [for (final e in radioNetworks.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                          onChanged: (v) => setS(() => net = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: channel,
                    decoration: InputDecoration(
                      labelText: net == 'bos_digital' ? 'Gesprächsgruppe (TMO/DMO)' : 'Kanal',
                      hintText: net == 'bos_digital' ? 'z. B. DMO 307' : 'z. B. Kanal 34',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: task,
                    decoration: const InputDecoration(labelText: 'Aufgabe', hintText: 'z. B. Einsatzabschnitt Rettung'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
              FilledButton(
                key: const Key('radio-save'),
                onPressed: () => Navigator.pop(ctx, call.text.trim().isNotEmpty),
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),
      );
      if (ok == true) {
        await repo.documents.saveRadio(
          d.exercise.id,
          id: r?.id,
          callSign: call.text,
          device: device.text,
          network: net,
          channel: channel.text,
          task: task.text,
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        SectionCard(
          title: 'Funkplan / Kommunikationsplan',
          subtitle: 'BOS digital (TMO/DMO), BOS analog und DLRG-Betriebsfunk',
          actions: [
            FilledButton.tonalIcon(key: const Key('radio-add'), onPressed: edit, icon: const Icon(Icons.add), label: const Text('Eintrag')),
          ],
          child: d.radio.isEmpty
              ? const Text('Noch kein Funkplan. Legt Rufnamen, Funknetz und Gesprächsgruppe bzw. Kanal fest.')
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Rufname')),
                      DataColumn(label: Text('Einheit / Gerät')),
                      DataColumn(label: Text('Funknetz')),
                      DataColumn(label: Text('Gruppe / Kanal')),
                      DataColumn(label: Text('Aufgabe')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final r in d.radio)
                        DataRow(
                          onSelectChanged: (_) => edit(r),
                          cells: [
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(r.callSign, style: const TextStyle(fontWeight: FontWeight.w600)),
                              for (final l in d.leads.where((l) => l.radioEntryId == r.id)) ...[
                                const SizedBox(width: 6),
                                Tooltip(message: 'Funkrufname der Führungsfunktion (Organigramm)', child: Tag(l.name, color: c.tertiaryContainer)),
                              ],
                            ])),
                            DataCell(Text(r.device ?? '')),
                            DataCell(
                              Tag(
                                radioNetworks[r.network] ?? r.network,
                                color: r.network == 'bos_digital'
                                    ? c.primaryContainer
                                    : (r.network == 'bos_analog' ? c.tertiaryContainer : null),
                              ),
                            ),
                            DataCell(Text(r.channel ?? '')),
                            DataCell(Text(r.task ?? '')),
                            DataCell(
                              IconButton(
                                tooltip: 'Löschen',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => repo.documents.deleteRadio(r.id),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Materialliste (später zusätzlich aus Materialkompass).
class MaterialTab extends StatelessWidget {
  const MaterialTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final d = detail;

    Future<void> edit([MaterialItem? m]) async {
      final name = TextEditingController(text: m?.name);
      final loc = TextEditingController(text: m?.location);
      final qty = TextEditingController(text: m?.quantity);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(m == null ? 'Material hinzufügen' : 'Material bearbeiten'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('material-name'),
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Material *', hintText: 'z. B. Hydraulischer Rettungssatz'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: loc,
                        decoration: const InputDecoration(labelText: 'Standort / verlastet auf', hintText: 'z. B. RW'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: qty,
                        decoration: const InputDecoration(labelText: 'Menge', hintText: 'z. B. 2 Sack'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(
              key: const Key('material-save'),
              onPressed: () => Navigator.pop(ctx, name.text.trim().isNotEmpty),
              child: const Text('Speichern'),
            ),
          ],
        ),
      );
      if (ok == true) await repo.documents.saveMaterial(d.exercise.id, id: m?.id, name: name.text, location: loc.text, quantity: qty.text);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        SectionCard(
          title: 'Materialliste',
          subtitle: 'Manuell oder aus Materialkompass (Einstellungen → Materialkompass)',
          actions: [
            OutlinedButton.icon(
              onPressed: () => pickMkMaterial(context, d.exercise.id),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Aus Materialkompass'),
            ),
            FilledButton.tonalIcon(
              key: const Key('material-add'),
              onPressed: edit,
              icon: const Icon(Icons.add),
              label: const Text('Material'),
            ),
          ],
          child: d.material.isEmpty
              ? const Text('Noch kein Material eingetragen.')
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('Standort / verlastet auf')),
                      DataColumn(label: Text('Menge')),
                      DataColumn(label: Text('Quelle')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final m in d.material)
                        DataRow(
                          onSelectChanged: (_) => edit(m),
                          cells: [
                            DataCell(Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(m.location ?? '')),
                            DataCell(Text(m.quantity ?? '')),
                            DataCell(m.source == 'materialkompass' ? const Tag('Materialkompass') : const Text('manuell')),
                            DataCell(
                              IconButton(
                                tooltip: 'Löschen',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => repo.documents.deleteMaterial(m.id),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
