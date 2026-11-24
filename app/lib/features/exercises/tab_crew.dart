import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../data/lead_functions.dart';
import '../../data/repositories.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../materialkompass/mk_ui.dart';
import '../vehicles_page.dart' show vehicleStatus;
import 'tab_org.dart';

/// Was beim Ziehen transportiert wird: die Person und – wenn sie aus einer
/// Funktion gezogen wird – diese Funktion.
class CrewDrag {
  const CrewDrag(this.personId, [this.fromFunctionId]);
  final String personId;
  final String? fromFunctionId;
}

/// Fahrzeugbesetzung: Personen per Drag & Drop (oder Antippen) auf
/// Funktionen setzen. Eine Person darf mehrere Funktionen haben.
class CrewTab extends StatefulWidget {
  const CrewTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  State<CrewTab> createState() => _CrewTabState();
}

class _CrewTabState extends State<CrewTab> {
  late final repo = AppScope.of(context);
  late final _persons = repo.persons.watchAll();
  late final _vehicles = repo.vehicles.watchAllDetails();
  late final _quals = repo.qualifications.watchAll();

  /// Für die Bedienung ohne Ziehen: zuerst Person antippen, dann Funktion.
  CrewDrag? _picked;
  String _query = '';
  bool _onlyFree = false;

  ExerciseDetail get d => widget.detail;
  String get exerciseId => d.exercise.id;

  void pick(CrewDrag? drag) => setState(() => _picked = drag);

  Future<void> _drop(CrewDrag drag, String functionId) async {
    setState(() => _picked = null);
    await repo.exercises.assign(exerciseId, functionId: functionId, personId: drag.personId, fromFunctionId: drag.fromFunctionId);
  }

  Future<void> _toPool(CrewDrag drag) async {
    setState(() => _picked = null);
    if (drag.fromFunctionId != null) await repo.exercises.unassign(exerciseId, drag.fromFunctionId!);
  }

  @override
  Widget build(BuildContext context) {
    return StreamView<List<PersonWithQualifications>>(
      stream: _persons,
      builder: (context, persons) => StreamView<Map<String?, VehicleDetail>>(
        stream: _vehicles,
        builder: (context, vehicles) => StreamView<List<Qualification>>(
          stream: _quals,
          builder: (context, quals) {
            final ctx = _CrewContext(
              persons: {for (final p in persons) p.person.id: p},
              qualNames: {for (final q in quals) q.id: q.name},
              byFunction: d.personsByFunction,
            );
            final wide = MediaQuery.sizeOf(context).width >= 1100;
            final pool = _pool(persons, ctx, wide);
            final board = _board(vehicles, ctx);
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 290, child: pool),
                      Expanded(child: board),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(height: 210, child: pool),
                      Expanded(child: board),
                    ],
                  );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Personen

  Widget _pool(List<PersonWithQualifications> persons, _CrewContext ctx, bool wide) {
    final c = Theme.of(context).colorScheme;
    final count = <String, int>{};
    for (final ids in ctx.byFunction.values) {
      for (final id in ids) {
        count[id] = (count[id] ?? 0) + 1;
      }
    }
    final q = _query.toLowerCase();
    final list = persons
        .where((p) => !_onlyFree || (count[p.person.id] ?? 0) == 0)
        .where((p) => q.isEmpty || p.displayName.toLowerCase().contains(q) || p.qualifications.any((x) => x.name.toLowerCase().contains(q)))
        .toList();
    final chips = [
      for (final p in list)
        _PersonChip(
          key: ValueKey('pool-${p.person.id}'),
          person: p,
          drag: CrewDrag(p.person.id),
          picked: _picked?.personId == p.person.id && _picked?.fromFunctionId == null,
          badge: count[p.person.id],
          onTap: () => setState(() => _picked = _picked?.personId == p.person.id ? null : CrewDrag(p.person.id)),
        ),
    ];
    return DragTarget<CrewDrag>(
      onWillAcceptWithDetails: (x) => x.data.fromFunctionId != null,
      onAcceptWithDetails: (x) => _toPool(x.data),
      builder: (context, candidates, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
        child: Material(
          color: candidates.isNotEmpty ? c.primary.withValues(alpha: 0.06) : Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: candidates.isNotEmpty ? c.primary : c.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Personal (${persons.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search, size: 20), hintText: 'Name oder Qualifikation'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('nur nicht eingeteilte'),
                  value: _onlyFree,
                  onChanged: (v) => setState(() => _onlyFree = v ?? false),
                ),
                Expanded(
                  child: persons.isEmpty
                      ? const Text('Noch kein Personal angelegt.')
                      : wide
                      ? ListView(
                          children: [for (final ch in chips) Padding(padding: const EdgeInsets.only(bottom: 6), child: ch)],
                        )
                      : SingleChildScrollView(
                          child: Wrap(spacing: 6, runSpacing: 6, children: [for (final ch in chips) SizedBox(width: 200, child: ch)]),
                        ),
                ),
                Text('Ziehen oder antippen. Zum Entfernen hierher zurückziehen.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Fahrzeuge

  Widget _board(Map<String?, VehicleDetail> vehicles, _CrewContext ctx) {
    final inExercise = {for (final ev in d.vehicles) ev.vehicleId};
    final available = vehicles.entries.where((e) => e.key != null && !inExercise.contains(e.key)).map((e) => e.value.vehicle!).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 24, 32),
      children: [
        if (_picked != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.touch_app_outlined),
                title: Text('${ctx.persons[_picked!.personId]?.displayName ?? ''}: jetzt eine Funktion antippen'),
                trailing: TextButton(onPressed: () => setState(() => _picked = null), child: const Text('Abbrechen')),
              ),
            ),
          ),
        _LeadCard(state: this, vehicles: vehicles, ctx: ctx),
        for (final ev in d.vehicles)
          if (vehicles[ev.vehicleId] != null) _VehicleCard(state: this, detail: vehicles[ev.vehicleId]!, ctx: ctx, exerciseVehicle: ev),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: available.isEmpty
              ? Text(vehicles.length <= 1 ? 'Fahrzeuge werden unter „Fahrzeuge & Funktionen“ angelegt.' : 'Alle Fahrzeuge sind eingeplant.')
              : MenuAnchor(
                  builder: (context, controller, _) => FilledButton.tonalIcon(
                    key: const Key('crew-add-vehicle'),
                    onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                    icon: const Icon(Icons.add),
                    label: const Text('Fahrzeug einplanen'),
                  ),
                  menuChildren: [
                    for (final v in available)
                      MenuItemButton(
                        onPressed: () {
                          final patterns = vehicles[v.id]!.patterns;
                          repo.exercises.addVehicle(exerciseId, v.id, patternId: patterns.isEmpty ? null : patterns.first.id);
                        },
                        child: Text('${v.name}${v.callSign == null ? '' : '  ·  ${v.callSign}'}'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CrewContext {
  _CrewContext({required this.persons, required this.qualNames, required this.byFunction});
  final Map<String, PersonWithQualifications> persons;
  final Map<String, String> qualNames;
  final Map<String, List<String>> byFunction;

  String? personOn(String functionId) => byFunction[functionId]?.first;
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.state, required this.detail, required this.ctx, this.exerciseVehicle});
  final _CrewTabState state;
  final VehicleDetail detail;
  final _CrewContext ctx;
  final ExerciseVehicle? exerciseVehicle;

  @override
  Widget build(BuildContext context) {
    final v = detail.vehicle!;
    final ev = exerciseVehicle;
    final patternId = ev?.patternId;
    final inPattern = patternId == null || !detail.matrix.containsKey(patternId) ? detail.functions.map((f) => f.id).toSet() : detail.matrix[patternId]!;
    // Funktionen des Musters plus solche, die außerhalb des Musters besetzt sind.
    final shown = detail.functions.where((f) => inPattern.contains(f.id) || ctx.personOn(f.id) != null).toList();
    final filled = shown.where((f) => ctx.personOn(f.id) != null).length;
    const headerColor = AppColors.red;
    const onHeader = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: headerColor,
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          v.name,
                          style: const TextStyle(color: onHeader, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (v.callSign != null) Text(v.callSign!, style: TextStyle(color: onHeader.withValues(alpha: 0.85), fontSize: 12)),
                        Text('$filled von ${shown.length} besetzt', style: TextStyle(color: onHeader.withValues(alpha: 0.85), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (detail.patterns.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String?>(
                        value: detail.matrix.containsKey(patternId) ? patternId : null,
                        underline: const SizedBox(),
                        isDense: true,
                        items: [
                          for (final p in detail.patterns) DropdownMenuItem(value: p.id, child: Text(p.name)),
                          const DropdownMenuItem(value: null, child: Text('alle Funktionen')),
                        ],
                        onChanged: (p) => state.repo.exercises.setPattern(ev!.id, p),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Aus der Übung nehmen',
                    color: onHeader,
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      if (await confirmDelete(context, v.name, details: 'Das Fahrzeug wird aus dieser Übung genommen, die Besetzung gelöscht.')) {
                        await state.repo.exercises.removeVehicle(state.exerciseId, ev!, detail.functions.map((f) => f.id));
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ReservationControl(detail: state.d, exerciseVehicle: ev!, vehicle: v),
              ),
            ),
            if (v.status != 'einsatzbereit')
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tag('Status: ${vehicleStatus[v.status] ?? v.status}', color: AppColors.warn.withValues(alpha: 0.18), textColor: AppColors.warn),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: shown.isEmpty
                  ? const Text('Dieses Fahrzeug hat noch keine Funktionen.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in shown)
                          _Seat(
                            state: state,
                            functionId: f.id,
                            name: f.name,
                            need: f.requiredQualificationId,
                            ctx: ctx,
                            outsidePattern: !inPattern.contains(f.id),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Führungs- und Sonderfunktionen dieser Übung. Sie werden frei angelegt
/// (Namen dürfen mehrfach vorkommen) und bilden das Organigramm.
class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.state, required this.vehicles, required this.ctx});
  final _CrewTabState state;
  final Map<String?, VehicleDetail> vehicles;
  final _CrewContext ctx;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final d = state.d;
    final leads = leadsInTreeOrder(d.leads);
    final filled = d.leads.where((l) => ctx.personOn(l.id) != null).length;
    final labels = leadLabels(d, {for (final p in ctx.persons.values) p.person.id: p.displayName});
    final catalog = vehicles[null]?.functions ?? const <CrewFunction>[];
    final top = leads.isEmpty ? null : leads.first.$1.id;
    Future<void> edit({ExerciseLeadFunction? lead, String? name, String? qual}) async {
      final quals = await state.repo.qualifications.all();
      if (!context.mounted) return;
      await showLeadDialog(context, d, vehicles: vehicles, quals: quals, lead: lead, parentId: top, presetName: name, presetQualificationId: qual);
    }

    String? info(ExerciseLeadFunction l) {
      final parts = [
        if (l.parentId != null && labels[l.parentId] != null) 'unter ${labels[l.parentId]}',
        if (l.vehicleId != null && vehicles[l.vehicleId]?.vehicle != null) vehicles[l.vehicleId]!.vehicle!.name,
        if (l.radioEntryId != null) ?d.radio.where((r) => r.id == l.radioEntryId).firstOrNull?.callSign,
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: c.inverseSurface,
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Führungs- und Sonderfunktionen',
                          style: TextStyle(color: c.onInverseSurface, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text('$filled von ${d.leads.length} besetzt', style: TextStyle(color: c.onInverseSurface.withValues(alpha: 0.85), fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('crew-org'),
                    style: TextButton.styleFrom(foregroundColor: c.onInverseSurface),
                    onPressed: () => DefaultTabController.maybeOf(context)?.animateTo(3),
                    icon: const Icon(Icons.account_tree_outlined, size: 18),
                    label: const Text('Organigramm'),
                  ),
                  MenuAnchor(
                    builder: (context, controller, _) => TextButton.icon(
                      key: const Key('crew-add-lead'),
                      style: TextButton.styleFrom(foregroundColor: c.onInverseSurface),
                      onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Funktion'),
                    ),
                    menuChildren: [
                      MenuItemButton(
                        key: const Key('crew-add-lead-free'),
                        leadingIcon: const Icon(Icons.edit_outlined),
                        onPressed: () => edit(),
                        child: const Text('Eigene Funktion …'),
                      ),
                      if (d.leads.isEmpty)
                        MenuItemButton(
                          onPressed: () => state.repo.exercises.saveLead(d.exercise.id, LeadInput(name: defaultLeadName)),
                          child: const Text(defaultLeadName),
                        ),
                      for (final f in catalog)
                        MenuItemButton(
                          onPressed: () => edit(name: f.name, qual: f.requiredQualificationId),
                          child: Text(f.name),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: leads.isEmpty
                  ? const Text('Keine Führungsfunktionen. Über „Funktion“ anlegen – z. B. Einsatzleiter, Zugführer, Gruppenführer.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (l, _) in leads)
                          _Seat(
                            state: state,
                            functionId: l.id,
                            name: l.name,
                            need: l.requiredQualificationId,
                            ctx: ctx,
                            info: info(l),
                            onEdit: () => edit(lead: l),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.state,
    required this.functionId,
    required this.name,
    required this.need,
    required this.ctx,
    this.outsidePattern = false,
    this.info,
    this.onEdit,
  });
  final _CrewTabState state;
  final String functionId;
  final String name;
  final String? need;
  final _CrewContext ctx;
  final bool outsidePattern;

  /// Zusatzzeile, z. B. „unter Einsatzleiter · HLF 20“.
  final String? info;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final f = (id: functionId, name: name);
    final personId = ctx.personOn(f.id);
    final person = personId == null ? null : ctx.persons[personId];
    final missing = person != null && need != null && !person.qualificationIds.contains(need);
    final picked = state._picked;

    return DragTarget<CrewDrag>(
      onWillAcceptWithDetails: (x) => x.data.fromFunctionId != f.id,
      onAcceptWithDetails: (x) => state._drop(x.data, f.id),
      builder: (context, candidates, _) {
        final hover = candidates.isNotEmpty;
        return GestureDetector(
          onTap: picked == null ? null : () => state._drop(picked, f.id),
          child: Container(
            key: ValueKey('seat-${f.id}'),
            width: 196,
            constraints: const BoxConstraints(minHeight: 78),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hover
                  ? c.primary.withValues(alpha: 0.10)
                  : missing
                  ? AppColors.warn.withValues(alpha: 0.12)
                  : c.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hover ? c.primary : (missing ? AppColors.warn : (picked != null ? c.primary.withValues(alpha: 0.5) : c.outlineVariant)),
                width: hover || missing ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: f.name.toUpperCase(),
                            children: [
                              if (need != null)
                                TextSpan(
                                  text: ' · ${ctx.qualNames[need] ?? ''}',
                                  style: TextStyle(color: c.primary),
                                ),
                            ],
                          ),
                          style: TextStyle(fontSize: 10.5, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: c.onSurfaceVariant),
                        ),
                      ),
                      if (onEdit != null)
                        InkWell(
                          key: ValueKey('seat-edit-${f.id}'),
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(8),
                          child: Tooltip(
                            message: 'Bearbeiten',
                            child: Icon(Icons.edit_outlined, size: 15, color: c.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
                if (info != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: Text(
                      info!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                    ),
                  ),
                if (person != null)
                  Row(
                    children: [
                      Expanded(
                        child: _PersonChip(
                          person: person,
                          drag: CrewDrag(person.person.id, f.id),
                          picked: picked?.fromFunctionId == f.id,
                          compact: true,
                          onTap: () {
                            // Ist schon jemand ausgewählt, wird er hier eingesetzt;
                            // sonst wird die Person auf dieser Funktion ausgewählt.
                            if (picked != null && picked.fromFunctionId != f.id) {
                              state._drop(picked, f.id);
                            } else {
                              state.pick(picked?.fromFunctionId == f.id ? null : CrewDrag(person.person.id, f.id));
                            }
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Entfernen',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        icon: const Icon(Icons.close),
                        onPressed: () => state.repo.exercises.unassign(state.exerciseId, f.id),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(picked != null ? 'hier einsetzen' : 'hierher ziehen', style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                  ),
                if (missing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text('fehlt: ${ctx.qualNames[need] ?? 'Qualifikation'}', style: const TextStyle(fontSize: 11, color: AppColors.warn)),
                  ),
                if (outsidePattern)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text('nicht im Besetzungsmuster', style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({super.key, required this.person, required this.drag, required this.picked, required this.onTap, this.badge, this.compact = false});
  final PersonWithQualifications person;
  final CrewDrag drag;
  final bool picked;
  final VoidCallback onTap;
  final int? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget chip({bool dragging = false}) => Material(
      color: Theme.of(context).cardTheme.color,
      elevation: dragging ? 6 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: picked ? c.primary : c.outlineVariant, width: picked ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      person.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (!compact && person.qualifications.isNotEmpty)
                      Text(
                        person.qualifications.map((q) => q.name).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (badge != null && badge! > 0) ...[const SizedBox(width: 6), Tooltip(message: '$badge Funktion(en) in dieser Übung', child: Tag('$badge×'))],
            ],
          ),
        ),
      ),
    );
    return Draggable<CrewDrag>(
      data: drag,
      feedback: SizedBox(width: 190, child: chip(dragging: true)),
      childWhenDragging: Opacity(opacity: 0.4, child: chip()),
      child: chip(),
    );
  }
}
