import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/documents_repository.dart';
import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../materialkompass/mk_ui.dart';
import '../../ui/widgets.dart';
import '../call_sign_editor.dart';

/// Funkplan: Rufname, Gerät, Funknetz, Gruppe/Kanal, Aufgabe.
class RadioTab extends StatelessWidget {
  const RadioTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final d = detail;
    final c = Theme.of(context).colorScheme;

    /// Fahrzeuge der Übung zuerst, danach alle übrigen.
    Future<List<Vehicle>> loadVehicles() async {
      final all = await repo.vehicles.watchAll().first;
      final planned = {for (final ev in d.vehicles) ev.vehicleId};
      return [...all.where((v) => planned.contains(v.id)), ...all.where((v) => !planned.contains(v.id))];
    }

    Future<void> edit([RadioEntry? r]) async {
      final vehicles = await loadVehicles();
      if (!context.mounted) return;
      final planned = {for (final ev in d.vehicles) ev.vehicleId};
      final call = TextEditingController(text: r?.callSign);
      final device = TextEditingController(text: r?.device);
      final channel = TextEditingController(text: r?.channel);
      final task = TextEditingController(text: r?.task);
      var net = r?.network ?? 'bos_digital';
      // Beim Bearbeiten das Fahrzeug über die Einheit bzw. den Rufnamen wiederfinden.
      Vehicle? vehicle = r == null
          ? null
          : vehicles.where((v) => v.name == r.device).firstOrNull ??
              vehicles.where((v) => v.allCallSigns.any((c) => c.callSign == r.callSign)).firstOrNull;
      VehicleCallSign? picked = vehicle?.allCallSigns.where((c) => c.callSign == r?.callSign).firstOrNull;

      void pickCallSign(VehicleCallSign? c, void Function(void Function()) setS) => setS(() {
            picked = c;
            if (c != null) {
              call.text = c.callSign;
              if (radioNetworks.containsKey(c.network)) net = c.network;
            }
          });
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
                  DropdownButtonFormField<String?>(
                    key: const Key('radio-vehicle'),
                    initialValue: vehicle?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Fahrzeug', helperText: 'Übernimmt Einheit und Funkrufname aus den Fahrzeugdaten'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('– kein Fahrzeug (freie Eingabe) –')),
                      for (final v in vehicles)
                        DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            [v.name, if (v.callSign != null) v.callSign!, if (planned.contains(v.id)) 'in der Übung'].join('  ·  '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      final v = vehicles.where((x) => x.id == id).firstOrNull;
                      setS(() {
                        vehicle = v;
                        if (v != null) device.text = v.name;
                      });
                      if (v != null) {
                        final calls = v.allCallSigns;
                        pickCallSign(calls.where((c) => c.network == net).firstOrNull ?? calls.firstOrNull, setS);
                      } else {
                        setS(() => picked = null);
                      }
                    },
                  ),
                  if (vehicle != null && vehicle!.allCallSigns.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VehicleCallSign>(
                      key: ValueKey('radio-vehicle-call-${vehicle!.id}'),
                      initialValue: vehicle!.allCallSigns.contains(picked) ? picked : null,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Funkrufname des Fahrzeugs'),
                      items: [
                        for (final c in vehicle!.allCallSigns)
                          DropdownMenuItem(value: c, child: Text(callSignLabel(c), overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (c) => pickCallSign(c, setS),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('radio-call'),
                    controller: call,
                    autofocus: r == null && vehicles.isEmpty,
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
                          key: ValueKey('radio-net-$net'),
                          initialValue: net,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Funknetz'),
                          items: [for (final e in radioNetworks.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
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

    /// Übernimmt alle Funkrufnamen der eingeplanten Fahrzeuge, die noch fehlen.
    Future<void> fromVehicles() async {
      final vehicles = await loadVehicles();
      final planned = {for (final ev in d.vehicles) ev.vehicleId};
      final existing = {for (final r in d.radio) '${r.network}|${r.callSign}'};
      var added = 0;
      for (final v in vehicles.where((v) => planned.contains(v.id))) {
        for (final c in v.allCallSigns) {
          final net = radioNetworks.containsKey(c.network) ? c.network : 'bos_digital';
          if (!existing.add('$net|${c.callSign}')) continue;
          await repo.documents.saveRadio(d.exercise.id, callSign: c.callSign, device: v.name, network: net, task: c.label);
          added++;
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(planned.isEmpty
              ? 'Noch keine Fahrzeuge eingeplant (Reiter „Besetzung“).'
              : added == 0
                  ? 'Alle Funkrufnamen der eingeplanten Fahrzeuge stehen schon im Funkplan.'
                  : '$added Funkrufname${added == 1 ? '' : 'n'} übernommen.'),
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        SectionCard(
          title: 'Funkplan / Kommunikationsplan',
          subtitle: 'BOS digital (TMO/DMO), BOS analog und DLRG-Betriebsfunk',
          actions: [
            OutlinedButton.icon(
              key: const Key('radio-from-vehicles'),
              onPressed: fromVehicles,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Aus Fahrzeugen'),
            ),
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
