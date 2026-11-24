import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../data/lead_functions.dart';
import '../../data/repositories.dart';
import '../../pdf/exercise_pdf.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'exercise_actions.dart';

/// Organigramm der Führungsstruktur: oben der Einsatzleiter, darunter die
/// unterstellten Führungskräfte – je mit Funkrufname, Funktion, Person und
/// Fahrzeug. Die Angaben kommen live aus Besetzung und Funkplan.
class OrgTab extends StatefulWidget {
  const OrgTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  State<OrgTab> createState() => _OrgTabState();
}

class _OrgTabState extends State<OrgTab> {
  late final repo = AppScope.of(context);
  late final _persons = repo.persons.watchAll();
  late final _vehicles = repo.vehicles.watchAllDetails();
  late final _quals = repo.qualifications.watchAll();

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    return StreamView<List<PersonWithQualifications>>(
      stream: _persons,
      builder: (context, persons) => StreamView<Map<String?, VehicleDetail>>(
        stream: _vehicles,
        builder: (context, vehicles) => StreamView<List<Qualification>>(
          stream: _quals,
          builder: (context, quals) {
            final roots = buildOrgChart(
              d,
              vehicles: vehicles,
              persons: {for (final p in persons) p.person.id: p},
              qualificationNames: {for (final q in quals) q.id: q.name},
            );
            Future<void> edit([ExerciseLeadFunction? l, String? parentId]) =>
                showLeadDialog(context, d, vehicles: vehicles, quals: quals, lead: l, parentId: parentId);
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                SectionCard(
                  title: 'Organigramm',
                  subtitle: 'Führungsstruktur aus Besetzung und Funkplan. Person, Fahrzeug und Funkrufname werden automatisch übernommen.',
                  actions: [
                    OutlinedButton.icon(
                      key: const Key('org-print'),
                      onPressed: d.leads.isEmpty ? null : () => showExerciseMapDialog(context, d, sections: {MapSection.orgChart}),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Drucken / PDF'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      key: const Key('org-add'),
                      onPressed: () => edit(null, roots.isEmpty ? null : roots.first.function.id),
                      icon: const Icon(Icons.add),
                      label: const Text('Führungsfunktion'),
                    ),
                  ],
                  child: roots.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                            const Text('Noch keine Führungsfunktionen.'),
                            OutlinedButton(
                              onPressed: () => repo.exercises.saveLead(d.exercise.id, LeadInput(name: defaultLeadName)),
                              child: const Text('Einsatzleiter / Einheitsführer anlegen'),
                            ),
                          ]),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final r in roots)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: OrgChart(node: r, onTap: (n) => edit(n.function), onAdd: (n) => edit(null, n.function.id)),
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tipp: Personen werden in der „Besetzung“ eingeteilt. Ist kein Fahrzeug fest zugeordnet, gilt das Fahrzeug, '
                  'auf dem die Person eingeteilt ist. Der Funkrufname steht im Funkplan – Änderungen dort erscheinen hier sofort.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Baum aus Kästchen mit Verbindungslinien.
class OrgChart extends StatelessWidget {
  const OrgChart({super.key, required this.node, this.onTap, this.onAdd});
  final OrgNode node;
  final void Function(OrgNode)? onTap;
  final void Function(OrgNode)? onAdd;

  static const _gap = 22.0;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outline;
    final box = OrgBox(node: node, onTap: onTap == null ? null : () => onTap!(node), onAdd: onAdd == null ? null : () => onAdd!(node));
    if (node.children.isEmpty) return box;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
        Container(width: 2, height: _gap, color: line),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < node.children.length; i++)
              CustomPaint(
                painter: _Connector(color: line, first: i == 0, last: i == node.children.length - 1, height: _gap),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, _gap, 8, 0),
                  child: OrgChart(node: node.children[i], onTap: onTap, onAdd: onAdd),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Connector extends CustomPainter {
  _Connector({required this.color, required this.first, required this.last, required this.height});
  final Color color;
  final bool first;
  final bool last;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    final mid = size.width / 2;
    if (!(first && last)) canvas.drawLine(Offset(first ? mid : 0, 1), Offset(last ? mid : size.width, 1), p);
    canvas.drawLine(Offset(mid, 0), Offset(mid, height), p);
  }

  @override
  bool shouldRepaint(_Connector old) => old.color != color || old.first != first || old.last != last;
}

/// Ein Kästchen: Funkrufname, Funktion, Person, Fahrzeug.
class OrgBox extends StatelessWidget {
  const OrgBox({super.key, required this.node, this.onTap, this.onAdd});
  final OrgNode node;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final top = node.function.parentId == null;
    final head = top ? AppColors.red : c.inverseSurface;
    final onHead = top ? Colors.white : c.onInverseSurface;
    final muted = TextStyle(fontSize: 12, color: c.onSurfaceVariant);
    return SizedBox(
      width: 210,
      child: Material(
        key: ValueKey('org-${node.function.id}'),
        color: Theme.of(context).cardTheme.color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: node.qualificationMissing ? AppColors.warn : c.outlineVariant, width: node.qualificationMissing ? 1.5 : 1)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: head,
                padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        node.callSign ?? 'kein Funkrufname',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: onHead.withValues(alpha: node.callSign == null ? 0.7 : 1), fontWeight: FontWeight.w700, fontSize: 12.5, fontStyle: node.callSign == null ? FontStyle.italic : null),
                      ),
                    ]),
                  ),
                  if (onAdd != null)
                    IconButton(
                      tooltip: 'Unterstellte Funktion hinzufügen',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      color: onHead,
                      icon: const Icon(Icons.add),
                      onPressed: onAdd,
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(node.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(node.personName ?? 'nicht besetzt', style: node.personName == null ? muted.copyWith(fontStyle: FontStyle.italic) : const TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.local_shipping_outlined, size: 15, color: c.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        node.vehicleName == null ? 'ohne Fahrzeug' : '${node.vehicleName}${node.vehicleFromCrew ? ' (Besetzung)' : ''}',
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  if (node.qualificationMissing)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('fehlt: ${node.qualificationName ?? 'Qualifikation'}', style: const TextStyle(fontSize: 11, color: AppColors.warn)),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Name einer Führungsfunktion, bei gleichen Namen mit Zusatz (Person bzw.
/// laufende Nummer), damit sie in Auswahllisten unterscheidbar bleiben.
Map<String, String> leadLabels(ExerciseDetail d, Map<String, String> personNames) {
  final count = <String, int>{};
  for (final l in d.leads) {
    count[l.name] = (count[l.name] ?? 0) + 1;
  }
  final seen = <String, int>{};
  final byFn = d.personsByFunction;
  return {
    for (final l in d.leads)
      l.id: () {
        if ((count[l.name] ?? 0) < 2) return l.name;
        final n = seen[l.name] = (seen[l.name] ?? 0) + 1;
        final p = byFn[l.id]?.first;
        return '${l.name} ${p != null && personNames[p] != null ? '(${personNames[p]})' : '$n'}';
      }(),
  };
}

/// Dialog zum Anlegen oder Bearbeiten einer Führungsfunktion der Übung.
Future<void> showLeadDialog(
  BuildContext context,
  ExerciseDetail d, {
  required Map<String?, VehicleDetail> vehicles,
  required List<Qualification> quals,
  ExerciseLeadFunction? lead,
  String? parentId,
  String? presetName,
  String? presetQualificationId,
}) async {
  final repo = AppScope.of(context);
  final persons = {for (final p in await repo.persons.all()) p.person.id: p.displayName};
  if (!context.mounted) return;
  final name = TextEditingController(text: lead?.name ?? presetName ?? '');
  final linked = lead?.radioEntryId == null ? null : d.radio.where((r) => r.id == lead!.radioEntryId).firstOrNull;
  final call = TextEditingController(text: linked?.callSign ?? '');
  var qual = lead?.requiredQualificationId ?? presetQualificationId;
  if (!quals.any((q) => q.id == qual)) qual = null;
  var parent = lead?.parentId ?? parentId;
  var vehicle = lead?.vehicleId;
  final excluded = lead == null ? <String>{} : {lead.id, ...descendantsOf(lead.id, d.leads)};
  final labels = leadLabels(d, persons);
  final parents = [for (final (l, depth) in leadsInTreeOrder(d.leads)) if (!excluded.contains(l.id)) (l, depth)];
  if (!parents.any((p) => p.$1.id == parent)) parent = null;
  final inExercise = [for (final ev in d.vehicles) ?vehicles[ev.vehicleId]?.vehicle];
  if (vehicle != null && !inExercise.any((v) => v.id == vehicle)) vehicle = null;
  final catalog = vehicles[null]?.functions ?? const <CrewFunction>[];

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(lead == null ? 'Führungsfunktion hinzufügen' : 'Führungsfunktion bearbeiten'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Autocomplete<String>(
                initialValue: name.value,
                optionsBuilder: (v) => {
                  for (final f in catalog)
                    if (f.name.toLowerCase().contains(v.text.toLowerCase())) f.name,
                  for (final n in const ['Zugführer', 'Gruppenführer', 'Staffelführer', 'Abschnittsleiter', 'Führungsassistent', 'Sicherheitsbeauftragter'])
                    if (n.toLowerCase().contains(v.text.toLowerCase())) n,
                },
                onSelected: (v) {
                  name.text = v;
                  final f = catalog.where((x) => x.name == v).firstOrNull;
                  if (f?.requiredQualificationId != null && quals.any((q) => q.id == f!.requiredQualificationId)) setS(() => qual = f!.requiredQualificationId);
                },
                fieldViewBuilder: (context, ctrl, focus, submit) {
                  ctrl.addListener(() => name.text = ctrl.text);
                  return TextField(
                    key: const Key('lead-name'),
                    controller: ctrl,
                    focusNode: focus,
                    autofocus: lead == null,
                    decoration: const InputDecoration(labelText: 'Funktion *', hintText: 'z. B. Zugführer, Gruppenführer, Abschnittsleiter'),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('lead-parent'),
                initialValue: parent,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unterstellt'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('– oberste Ebene –')),
                  for (final (l, depth) in parents) DropdownMenuItem(value: l.id, child: Text('${'   ' * depth}${labels[l.id]}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setS(() => parent = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('lead-vehicle'),
                initialValue: vehicle,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Fahrzeug'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('aus der Besetzung übernehmen')),
                  for (final v in inExercise) DropdownMenuItem(value: v.id, child: Text('${v.name}${v.callSign == null ? '' : ' · ${v.callSign}'}')),
                ],
                onChanged: (v) => setS(() => vehicle = v),
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                initialValue: call.value,
                optionsBuilder: (v) => [for (final r in d.radio) if (r.callSign.toLowerCase().contains(v.text.toLowerCase())) r.callSign],
                onSelected: (v) => call.text = v,
                fieldViewBuilder: (context, ctrl, focus, submit) {
                  ctrl.addListener(() => call.text = ctrl.text);
                  return TextField(
                    key: const Key('lead-call'),
                    controller: ctrl,
                    focusNode: focus,
                    decoration: const InputDecoration(
                      labelText: 'Funkrufname',
                      hintText: 'leer = vom Fahrzeug übernehmen',
                      helperText: 'Wird im Funkplan geführt: vorhandener Eintrag wird verknüpft, sonst neu angelegt.',
                      helperMaxLines: 2,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: qual,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'benötigte Qualifikation'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('keine')),
                  for (final q in quals) DropdownMenuItem(value: q.id, child: Text(q.name)),
                ],
                onChanged: (v) => setS(() => qual = v),
              ),
            ]),
          ),
        ),
        actions: [
          if (lead != null)
            TextButton.icon(
              key: const Key('lead-delete'),
              onPressed: () => Navigator.pop(ctx, 'delete'),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Löschen'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            key: const Key('lead-save'),
            onPressed: () => Navigator.pop(ctx, name.text.trim().isEmpty ? null : 'save'),
            child: const Text('Speichern'),
          ),
        ],
      ),
    ),
  );
  if (result == 'delete' && lead != null && context.mounted) {
    if (await confirmDelete(context, lead.name, details: 'Die Besetzung dieser Funktion wird gelöscht. Unterstellte rücken eine Ebene nach oben.')) {
      await repo.exercises.deleteLead(d.exercise.id, lead.id);
    }
  } else if (result == 'save') {
    await repo.exercises.saveLead(
      d.exercise.id,
      LeadInput(id: lead?.id, name: name.text, qualificationId: qual, parentId: parent, vehicleId: vehicle, callSign: call.text),
    );
  }
}
