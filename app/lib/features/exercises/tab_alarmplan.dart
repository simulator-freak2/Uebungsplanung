import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;

const alarmKinds = {'fahrzeug': 'Fahrzeug', 'boot': 'Boot', 'trupp': 'Trupp'};

/// Alarmierungsplan: wann welches Fahrzeug bzw. welcher Trupp alarmiert oder
/// abgerufen wird, ausrückt und am Einsatzort ist bzw. in den Einsatz geht.
class AlarmPlanTab extends StatefulWidget {
  const AlarmPlanTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  State<AlarmPlanTab> createState() => _AlarmPlanTabState();
}

class _AlarmPlanTabState extends State<AlarmPlanTab> {
  late final repo = AppScope.of(context);
  late final _vehicles = repo.vehicles.watchAll();

  ExerciseDetail get d => widget.detail;
  String fmt(int? off) => off == null ? '–' : t.formatOffset(off, start: d.start, relativeMode: d.relativeTimes);

  /// Legt für jedes eingeplante Fahrzeug ohne Eintrag eine Zeile an
  /// (Alarm zur ersten Alarmierung bzw. +15 Min., Ausrücken +5, Ankunft +10).
  Future<void> _fromVehicles(List<Vehicle> all) async {
    final planned = {for (final e in d.alarmPlan) e.vehicleId};
    final alarm = d.firstAlarm ?? 15;
    for (final ev in d.vehicles) {
      if (planned.contains(ev.vehicleId)) continue;
      final v = all.where((x) => x.id == ev.vehicleId).firstOrNull;
      if (v == null) continue;
      await repo.exercises.saveAlarmEntry(
        d.exercise.id,
        AlarmEntryInput(label: v.name, kind: v.kind == 'boot' ? 'boot' : 'fahrzeug', vehicleId: v.id, alarmOffset: alarm, departOffset: alarm + 5, arriveOffset: alarm + 10, note: 'Erstalarm'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Vehicle>>(
      stream: _vehicles,
      builder: (context, vehicles) {
        final missing = d.vehicles.where((ev) => !d.alarmPlan.any((e) => e.vehicleId == ev.vehicleId)).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Uhrzeit'), icon: Icon(Icons.schedule)),
                  ButtonSegment(value: true, label: Text('ab Übungsbeginn'), icon: Icon(Icons.timer_outlined)),
                ],
                selected: {d.relativeTimes},
                onSelectionChanged: (s) => repo.exercises.setTimeMode(d.exercise.id, s.first),
              ),
              FilledButton.tonalIcon(
                key: const Key('alarm-add'),
                onPressed: () => _edit(vehicles),
                icon: const Icon(Icons.add),
                label: const Text('Eintrag'),
              ),
              if (missing > 0)
                OutlinedButton.icon(
                  onPressed: () => _fromVehicles(vehicles),
                  icon: const Icon(Icons.playlist_add),
                  label: Text('$missing eingeplante${missing == 1 ? 's Fahrzeug' : ' Fahrzeuge'} übernehmen'),
                ),
            ]),
            const SizedBox(height: 16),
            if (d.alarmPlan.isEmpty)
              const EmptyHint(icon: Icons.timeline, text: 'Noch kein Alarmierungsplan.\nLegt fest, wann welches Fahrzeug oder welcher Trupp alarmiert wird, ausrückt und eintrifft.')
            else ...[
              SectionCard(
                title: 'Zeitleiste',
                actions: const [_Legend()],
                child: _Timeline(detail: d),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Einträge',
                subtitle: 'Zeiten sind relativ zum Übungsbeginn gespeichert und verschieben sich mit ihm',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Einheit')),
                      DataColumn(label: Text('Art')),
                      DataColumn(label: Text('Alarmierung / Abruf')),
                      DataColumn(label: Text('Ausrücken')),
                      DataColumn(label: Text('Am Einsatzort / Einsatz ab')),
                      DataColumn(label: Text('Auslöser / Hinweis')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final e in d.alarmPlan)
                        DataRow(
                          onSelectChanged: (_) => _edit(vehicles, existing: e),
                          cells: [
                            DataCell(Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(alarmKinds[e.kind] ?? e.kind)),
                            DataCell(Text(fmt(e.alarmOffset))),
                            DataCell(Text(fmt(e.departOffset))),
                            DataCell(Text(fmt(e.arriveOffset))),
                            DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 280), child: Text(e.note ?? ''))),
                            DataCell(IconButton(
                              tooltip: 'Löschen',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => repo.exercises.deleteAlarmEntry(e.id),
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _edit(List<Vehicle> vehicles, {AlarmPlanEntry? existing}) async {
    final inExercise = [for (final ev in d.vehicles) ...vehicles.where((v) => v.id == ev.vehicleId)];
    await showDialog<void>(
      context: context,
      builder: (_) => _EntryDialog(detail: d, vehicles: inExercise, existing: existing, repo: repo),
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.detail, required this.vehicles, required this.repo, this.existing});
  final ExerciseDetail detail;
  final List<Vehicle> vehicles;
  final Repositories repo;
  final AlarmPlanEntry? existing;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  ExerciseDetail get d => widget.detail;
  late final e = widget.existing;
  late String? _vehicleId = e?.vehicleId;
  late String _kind = e?.kind ?? 'fahrzeug';
  late final _label = TextEditingController(text: e?.label);
  late final _alarm = TextEditingController(text: _show(e?.alarmOffset ?? d.firstAlarm ?? 15));
  late final _depart = TextEditingController(text: _show(e?.departOffset));
  late final _arrive = TextEditingController(text: _show(e?.arriveOffset));
  late final _note = TextEditingController(text: e?.note);

  String _show(int? off) => off == null ? '' : (d.relativeTimes ? (off >= 0 ? '+$off' : '$off') : t.clock(d.start + off));
  int? _parse(TextEditingController c) => c.text.trim().isEmpty ? null : t.parseOffset(c.text, start: d.start);
  bool _bad(TextEditingController c) => c.text.trim().isNotEmpty && _parse(c) == null;
  bool get _valid => _label.text.trim().isNotEmpty && _parse(_alarm) != null && !_bad(_depart) && !_bad(_arrive);

  Widget _timeField(String label, TextEditingController c, {Key? key}) {
    final off = _parse(c);
    return TextField(
      key: key,
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        helperText: off == null ? (d.relativeTimes ? 'z. B. +15' : 'z. B. 19:15') : '${t.clock(d.start + off)} · ${t.relative(off)}',
        errorText: _bad(c) ? 'Uhrzeit oder +Minuten' : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(e == null ? 'Eintrag im Alarmierungsplan' : 'Eintrag bearbeiten'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.vehicles.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: widget.vehicles.any((v) => v.id == _vehicleId) ? _vehicleId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Eingeplantes Fahrzeug'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('– kein Fahrzeug (z. B. Trupp) –')),
                  for (final v in widget.vehicles) DropdownMenuItem(value: v.id, child: Text(v.name)),
                ],
                onChanged: (id) => setState(() {
                  _vehicleId = id;
                  final v = widget.vehicles.where((x) => x.id == id).firstOrNull;
                  if (v != null) {
                    _label.text = v.name;
                    _kind = v.kind == 'boot' ? 'boot' : 'fahrzeug';
                  }
                }),
              ),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  key: const Key('alarm-label'),
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Einheit *', hintText: 'z. B. HLF 20 oder Angriffstrupp'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: [for (final k in alarmKinds.entries) DropdownMenuItem(value: k.key, child: Text(k.value))],
                  onChanged: (k) => setState(() => _kind = k!),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _timeField(_kind == 'trupp' ? 'Abruf *' : 'Alarmierung *', _alarm, key: const Key('alarm-time'))),
              const SizedBox(width: 12),
              Expanded(child: _timeField('Ausrücken', _depart)),
              const SizedBox(width: 12),
              Expanded(child: _timeField(_kind == 'trupp' ? 'Einsatz ab' : 'Am Einsatzort', _arrive)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Auslöser / Hinweis', hintText: 'z. B. Nachalarmierung durch Einsatzleiter'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          key: const Key('alarm-save'),
          onPressed: !_valid
              ? null
              : () async {
                  await widget.repo.exercises.saveAlarmEntry(
                    d.exercise.id,
                    AlarmEntryInput(
                      id: e?.id,
                      label: _label.text,
                      kind: _kind,
                      vehicleId: _vehicleId,
                      alarmOffset: _parse(_alarm)!,
                      departOffset: _parse(_depart),
                      arriveOffset: _parse(_arrive),
                      note: _note.text,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String text, {double w = 14}) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: w, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ]);
    return Wrap(spacing: 14, children: [
      item(AppColors.yellow, 'Alarmierung bis Ausrücken'),
      item(AppColors.red, 'Anfahrt'),
      item(Theme.of(context).colorScheme.onSurface, 'Am Einsatzort / Einsatz ab', w: 3),
    ]);
  }
}

/// Zeitleiste als Balken je Eintrag.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.detail});
  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final c = Theme.of(context).colorScheme;
    final points = [
      for (final e in d.alarmPlan) ...[e.alarmOffset, ?e.departOffset, ?e.arriveOffset],
    ];
    final lo = ((points.reduce(math.min) - 5) / 10).floor() * 10;
    final hi = ((points.reduce(math.max) + 5) / 10).ceil() * 10;
    final span = math.max(hi - lo, 10);
    final step = span > 120 ? 30 : (span > 60 ? 15 : 10);
    const labelW = 190.0;

    return LayoutBuilder(builder: (context, box) {
      final width = math.max(box.maxWidth, 640.0);
      final trackW = width - labelW - 40;
      double x(int off) => (off - lo) / span * trackW;
      final ticks = [for (var m = lo; m <= hi; m += step) m];
      Widget bar(int from, int to, Color color) => Positioned(
            left: x(from),
            width: math.max(x(to) - x(from), 2),
            top: 13,
            height: 18,
            child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(children: [
            SizedBox(
              height: 22,
              child: Stack(children: [
                for (final m in ticks)
                  Positioned(
                    left: labelW + x(m) - 30,
                    width: 60,
                    child: Text(
                      t.formatOffset(m, start: d.start, relativeMode: d.relativeTimes),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: c.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
              ]),
            ),
            for (final e in d.alarmPlan)
              Container(
                height: 44,
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant))),
                child: Row(children: [
                  SizedBox(
                    width: labelW,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(alarmKinds[e.kind] ?? e.kind, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                    ]),
                  ),
                  SizedBox(
                    width: trackW,
                    child: Stack(clipBehavior: Clip.none, children: [
                      for (final m in ticks) Positioned(left: x(m), top: 0, bottom: 0, child: Container(width: 1, color: c.outlineVariant)),
                      if (e.departOffset != null) ...[
                        bar(e.alarmOffset, e.departOffset!, AppColors.yellow),
                        if (e.arriveOffset != null) bar(e.departOffset!, e.arriveOffset!, AppColors.red),
                      ] else if (e.arriveOffset != null)
                        bar(e.alarmOffset, e.arriveOffset!, AppColors.yellow)
                      else
                        Positioned(left: x(e.alarmOffset) - 5, top: 17, child: Icon(Icons.circle, size: 10, color: c.onSurface)),
                      if (e.arriveOffset != null)
                        Positioned(left: x(e.arriveOffset!) - 1.5, top: 8, height: 28, width: 3, child: ColoredBox(color: c.onSurface)),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
      );
    });
  }
}
