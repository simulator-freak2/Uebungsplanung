import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/documents_repository.dart';
import '../../data/exercise_repository.dart';
import '../../data/radio_overview.dart';
import '../../materialkompass/mk_ui.dart';
import '../../ui/widgets.dart';

/// Funkplan: Rufname, Gerät, Funknetz, Gruppe/Kanal, Aufgabe –
/// als Tabelle oder als grafische Übersicht (Kommunikationsskizze).
class RadioTab extends StatefulWidget {
  const RadioTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  State<RadioTab> createState() => _RadioTabState();
}

class _RadioTabState extends State<RadioTab> {
  bool _graphic = false;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final d = widget.detail;
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
            if (d.radio.isNotEmpty)
              SegmentedButton<bool>(
                key: const Key('radio-view'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.table_rows_outlined), label: Text('Tabelle')),
                  ButtonSegment(value: true, icon: Icon(Icons.account_tree_outlined), label: Text('Grafik')),
                ],
                selected: {_graphic},
                onSelectionChanged: (v) => setState(() => _graphic = v.first),
              ),
            FilledButton.tonalIcon(key: const Key('radio-add'), onPressed: edit, icon: const Icon(Icons.add), label: const Text('Eintrag')),
          ],
          child: d.radio.isEmpty
              ? const Text('Noch kein Funkplan. Legt Rufnamen, Funknetz und Gesprächsgruppe bzw. Kanal fest.')
              : _graphic
              ? RadioOverviewGraphic(overview: RadioOverview.from(d.radio), onTap: edit)
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
                            DataCell(Text(r.callSign, style: const TextStyle(fontWeight: FontWeight.w600))),
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

/// Farbe eines Funknetzes (Hintergrund, Vordergrund).
(Color, Color) radioNetworkColors(ColorScheme c, String network) => switch (network) {
      'bos_digital' => (c.primaryContainer, c.onPrimaryContainer),
      'bos_analog' => (c.tertiaryContainer, c.onTertiaryContainer),
      'dlrg_betriebsfunk' => (c.secondaryContainer, c.onSecondaryContainer),
      _ => (c.surfaceContainerHighest, c.onSurface),
    };

/// Grafische Übersicht des Funkplans: je Funknetz die Gesprächsgruppen bzw.
/// Kanäle mit den Stellen darin. Stellen in mehreren Gruppen sind markiert.
class RadioOverviewGraphic extends StatelessWidget {
  const RadioOverviewGraphic({super.key, required this.overview, this.onTap});
  final RadioOverview overview;
  final void Function(RadioEntry)? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final links = overview.linkingStations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in overview.networks.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(children: [
              Icon(Icons.cell_tower, size: 18, color: radioNetworkColors(c, n.key).$2),
              const SizedBox(width: 6),
              Text(radioNetworks[n.key] ?? n.key, style: t.titleSmall),
              const SizedBox(width: 8),
              Text('${n.value.length} ${n.value.length == 1 ? 'Gruppe' : 'Gruppen'}', style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            ]),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final g in n.value) _GroupCard(overview: overview, group: g, onTap: onTap)],
          ),
          const SizedBox(height: 12),
        ],
        if (links.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.link, size: 18, color: c.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Verbindungsstellen (in mehreren Gruppen): ${links.join(', ')}', style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
              ),
            ]),
          ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.overview, required this.group, this.onTap});
  final RadioOverview overview;
  final RadioGroupNode group;
  final void Function(RadioEntry)? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final (bg, fg) = radioNetworkColors(c, group.network);
    final line = BorderSide(color: fg.withValues(alpha: 0.5), width: 2);
    return Container(
      width: 300,
      decoration: BoxDecoration(border: Border.all(color: bg, width: 2), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(Icons.settings_input_antenna, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(group.label, style: t.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
              ),
              Text('${group.entries.length}', style: t.labelMedium?.copyWith(color: fg)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(border: Border(left: line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final r in group.entries)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Container(width: 12, decoration: BoxDecoration(border: Border(top: line))),
                        Expanded(child: _station(context, r)),
                      ]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _station(BuildContext context, RadioEntry r) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final others = overview.otherGroups(r, group);
    final info = [r.device, r.task].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return Material(
      color: c.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: others.isEmpty ? c.outlineVariant : c.primary, width: others.isEmpty ? 1 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap == null ? null : () => onTap!(r),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.callSign, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (info.isNotEmpty) Text(info, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            if (others.isNotEmpty)
              Row(children: [
                Icon(Icons.link, size: 14, color: c.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('auch in ${others.map((g) => g.network == group.network ? g.label : g.fullLabel).join(', ')}',
                      style: t.bodySmall?.copyWith(color: c.primary)),
                ),
              ]),
          ]),
        ),
      ),
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
