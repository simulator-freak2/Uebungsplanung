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
        final slipping = d.alarmPlan.any((e) => d.towOf(e) != null);
        final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
        Widget twoLines(String a, String? b) => Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(a),
              if (b != null && b.isNotEmpty) Text(b, style: small),
            ]);
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
              const EmptyHint(icon: Icons.timeline, text: 'Noch kein Alarmierungsplan.\nLegt fest, wann welches Fahrzeug oder welcher Trupp alarmiert wird, ausrückt und eintrifft.\nBoote können auf dem Anhänger eines Fahrzeugs zu einer Slipstelle gebracht werden.')
            else ...[
              SectionCard(
                title: 'Zeitleiste',
                actions: [_Legend(slipping: slipping)],
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
                    dataRowMaxHeight: 64,
                    columns: [
                      const DataColumn(label: Text('Einheit')),
                      const DataColumn(label: Text('Art')),
                      const DataColumn(label: Text('Alarmierung / Abruf')),
                      const DataColumn(label: Text('Ausrücken')),
                      if (slipping) const DataColumn(label: Text('Slipstelle')),
                      const DataColumn(label: Text('Am Ziel / Einsatz ab')),
                      const DataColumn(label: Text('Ziel / Aufgabe')),
                      const DataColumn(label: Text('Auslöser / Hinweis')),
                      const DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final e in d.alarmPlan)
                        () {
                          final tow = d.towOf(e);
                          final boats = d.towedBy(e);
                          return DataRow(
                            key: ValueKey('alarm-row-${e.id}'),
                            onSelectChanged: (_) => _edit(vehicles, existing: e),
                            cells: [
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                if (tow != null) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.subdirectory_arrow_right, size: 18, color: small?.color)),
                                Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ])),
                              DataCell(twoLines(
                                alarmKinds[e.kind] ?? e.kind,
                                tow != null
                                    ? 'auf Anhänger von ${tow.label}'
                                    : (boats.isEmpty ? null : 'mit ${boats.map((b) => b.label).join(', ')} auf Anhänger'),
                              )),
                              DataCell(Text(fmt(e.alarmOffset))),
                              DataCell(twoLines(fmt(d.departOf(e)), tow != null ? 'mit ${tow.label}' : null)),
                              if (slipping)
                                DataCell(tow != null
                                    ? twoLines('${e.slipLocation ?? 'Slipstelle'} · an ${fmt(e.slipOffset)}', 'im Wasser / ablegen ${fmt(e.departOffset)}')
                                    : boats.isEmpty
                                        ? const Text('')
                                        : twoLines(boats.map((b) => '${b.slipLocation ?? 'Slipstelle'} · an ${fmt(b.slipOffset)}').toSet().join('\n'), 'danach eigenes Ziel')),
                              DataCell(Text(fmt(e.arriveOffset))),
                              DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: twoLines(e.destination ?? '–', e.task))),
                              DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: Text(e.note ?? ''))),
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                if (e.kind == 'fahrzeug')
                                  IconButton(
                                    key: ValueKey('alarm-tow-${e.id}'),
                                    tooltip: 'Boot auf Anhänger mitnehmen (Slippen)',
                                    icon: const Icon(Icons.directions_boat_outlined),
                                    onPressed: () => _edit(vehicles, towFor: e),
                                  ),
                                IconButton(
                                  tooltip: 'Löschen',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => repo.exercises.deleteAlarmEntry(e.id),
                                ),
                              ])),
                            ],
                          );
                        }(),
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

  Future<void> _edit(List<Vehicle> vehicles, {AlarmPlanEntry? existing, AlarmPlanEntry? towFor}) async {
    final inExercise = [for (final ev in d.vehicles) ...vehicles.where((v) => v.id == ev.vehicleId)];
    await showDialog<void>(
      context: context,
      builder: (_) => _EntryDialog(detail: d, vehicles: inExercise, existing: existing, towFor: towFor, repo: repo),
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.detail, required this.vehicles, required this.repo, this.existing, this.towFor});
  final ExerciseDetail detail;
  final List<Vehicle> vehicles;
  final Repositories repo;
  final AlarmPlanEntry? existing;

  /// Neues Boot, das dieses Fahrzeug auf dem Anhänger mitnimmt.
  final AlarmPlanEntry? towFor;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  ExerciseDetail get d => widget.detail;
  late final e = widget.existing;
  late String? _vehicleId = e?.vehicleId;
  late String _kind = e?.kind ?? (widget.towFor != null ? 'boot' : 'fahrzeug');
  late String? _towId = e?.towedById ?? widget.towFor?.id;
  late bool _slip = _towId != null;
  late final _label = TextEditingController(text: e?.label);
  late final _alarm = TextEditingController(text: _show(e?.alarmOffset ?? d.firstAlarm ?? 15));
  late final _depart = TextEditingController(text: _show(e?.departOffset));
  late final _arrive = TextEditingController(text: _show(e?.arriveOffset));
  late final _slipAt = TextEditingController(text: _show(e?.slipOffset ?? widget.towFor?.arriveOffset));
  late final _slipLocation = TextEditingController(text: e?.slipLocation);
  late final _destination = TextEditingController(text: e?.destination);
  late final _task = TextEditingController(text: e?.task);
  late final _note = TextEditingController(text: e?.note);

  /// Fahrzeuge im Alarmierungsplan, die ein Boot ziehen können.
  List<AlarmPlanEntry> get _towCandidates => [for (final x in d.alarmPlan) if (x.kind == 'fahrzeug' && x.id != e?.id) x];
  AlarmPlanEntry? get _tow => _towCandidates.where((x) => x.id == _towId).firstOrNull;
  bool get _towed => _kind == 'boot' && _slip;

  String _show(int? off) => off == null ? '' : (d.relativeTimes ? (off >= 0 ? '+$off' : '$off') : t.clock(d.start + off));
  int? _parse(TextEditingController c) => c.text.trim().isEmpty ? null : t.parseOffset(c.text, start: d.start);
  bool _bad(TextEditingController c) => c.text.trim().isNotEmpty && _parse(c) == null;
  bool get _valid =>
      _label.text.trim().isNotEmpty &&
      !_bad(_depart) &&
      !_bad(_arrive) &&
      (_towed ? (_tow != null && _parse(_slipAt) != null) : _parse(_alarm) != null);

  /// Hinweise, wenn die Reihenfolge der Zeiten nicht stimmt.
  List<String> get _orderWarnings {
    final w = <String>[];
    if (_towed) {
      final tow = _tow;
      final slip = _parse(_slipAt), water = _parse(_depart), arrive = _parse(_arrive);
      final towDepart = tow?.departOffset ?? tow?.alarmOffset;
      if (towDepart != null && slip != null && slip < towDepart) w.add('Das Zugfahrzeug ist vor dem Ausrücken an der Slipstelle.');
      if (slip != null && water != null && water < slip) w.add('Das Boot ist im Wasser, bevor es an der Slipstelle ist.');
      if (arrive != null && (water ?? slip) != null && arrive < (water ?? slip)!) w.add('Das Boot ist am Ziel, bevor es im Wasser ist.');
    } else {
      final alarm = _parse(_alarm), depart = _parse(_depart), arrive = _parse(_arrive);
      if (alarm != null && depart != null && depart < alarm) w.add('Ausrücken liegt vor der Alarmierung.');
      if (arrive != null && (depart ?? alarm) != null && arrive < (depart ?? alarm)!) w.add('Die Ankunft liegt vor dem Ausrücken.');
      for (final b in e == null ? const <AlarmPlanEntry>[] : d.towedBy(e!)) {
        if (arrive != null && b.slipOffset != null && arrive < b.slipOffset!) w.add('Die Ankunft am Ziel liegt vor dem Slippen von ${b.label}.');
      }
    }
    return w;
  }

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

  String _fmt(int? off) => off == null ? '–' : t.formatOffset(off, start: d.start, relativeMode: d.relativeTimes);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final boats = e == null ? const <AlarmPlanEntry>[] : d.towedBy(e!);
    final warnings = _orderWarnings;
    Widget info(IconData icon, String s) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: AppColors.water),
            const SizedBox(width: 10),
            Expanded(child: Text(s, style: text.bodyMedium)),
          ]),
        );
    return AlertDialog(
      title: Text(e == null ? (widget.towFor != null ? 'Boot auf Anhänger von ${widget.towFor!.label}' : 'Eintrag im Alarmierungsplan') : 'Eintrag bearbeiten'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.vehicles.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: widget.vehicles.any((v) => v.id == _vehicleId) ? _vehicleId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Eingeplantes Fahrzeug / Boot'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('– kein Fahrzeug (z. B. Trupp) –')),
                  for (final v in widget.vehicles.where((v) => widget.towFor == null || v.kind == 'boot')) DropdownMenuItem(value: v.id, child: Text(v.name)),
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
                  decoration: InputDecoration(labelText: 'Einheit *', hintText: _kind == 'boot' ? 'z. B. MRB 1' : 'z. B. HLF 20 oder Angriffstrupp'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('kind-$_kind'),
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: [for (final k in alarmKinds.entries) DropdownMenuItem(value: k.key, child: Text(k.value))],
                  onChanged: (k) => setState(() => _kind = k!),
                ),
              ),
            ]),
            if (_kind == 'boot') ...[
              const SizedBox(height: 16),
              Text('Anfahrt', style: text.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                key: const Key('alarm-slip-mode'),
                segments: const [
                  ButtonSegment(value: false, label: Text('Eigenständig'), icon: Icon(Icons.directions_boat_outlined)),
                  ButtonSegment(value: true, label: Text('Auf Anhänger, Slippen'), icon: Icon(Icons.rv_hookup)),
                ],
                selected: {_slip},
                onSelectionChanged: (s) => setState(() {
                  _slip = s.first;
                  if (_slip && _tow == null && _towCandidates.length == 1) _towId = _towCandidates.first.id;
                }),
              ),
            ],
            const SizedBox(height: 12),
            if (_towed) ...[
              if (_towCandidates.isEmpty)
                info(Icons.info_outline, 'Legt zuerst das Zugfahrzeug als Fahrzeug im Alarmierungsplan an. Das Boot fährt dann bis zur Slipstelle mit ihm.')
              else ...[
                DropdownButtonFormField<String>(
                  key: const Key('alarm-tow'),
                  initialValue: _tow?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Zugfahrzeug *', helperText: 'Alarmierung und Ausrücken gemeinsam mit diesem Fahrzeug'),
                  items: [for (final x in _towCandidates) DropdownMenuItem(value: x.id, child: Text('${x.label}  ·  Alarm ${_fmt(x.alarmOffset)}, Ausrücken ${_fmt(x.departOffset)}'))],
                  onChanged: (id) => setState(() => _towId = id),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('alarm-slip-location'),
                  controller: _slipLocation,
                  decoration: const InputDecoration(labelText: 'Slipstelle', hintText: 'z. B. Slipanlage Yachthafen, Südufer'),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _timeField('An der Slipstelle *', _slipAt, key: const Key('alarm-slip-time'))),
                  const SizedBox(width: 12),
                  Expanded(child: _timeField('Im Wasser / ablegen', _depart, key: const Key('alarm-water-time'))),
                  const SizedBox(width: 12),
                  Expanded(child: _timeField('Am Ziel', _arrive, key: const Key('alarm-arrive-time'))),
                ]),
                const SizedBox(height: 8),
                Text('Ab der Slipstelle sind Boot und Zugfahrzeug getrennt: Ziel, Aufgabe und Ankunft hier gelten nur für das Boot.', style: text.bodySmall?.copyWith(color: c.onSurfaceVariant)),
              ],
            ] else ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _timeField(_kind == 'trupp' ? 'Abruf *' : 'Alarmierung *', _alarm, key: const Key('alarm-time'))),
                const SizedBox(width: 12),
                Expanded(child: _timeField('Ausrücken', _depart, key: const Key('alarm-depart-time'))),
                const SizedBox(width: 12),
                Expanded(child: _timeField(_kind == 'trupp' ? 'Einsatz ab' : (boats.isEmpty ? 'Am Ziel' : 'Am Ziel (nach dem Slippen)'), _arrive, key: const Key('alarm-arrive-time'))),
              ]),
              if (boats.isNotEmpty) ...[
                const SizedBox(height: 8),
                info(
                  Icons.rv_hookup,
                  [
                    for (final b in boats) 'Bringt ${b.label} zur ${b.slipLocation ?? 'Slipstelle'} (an ${_fmt(b.slipOffset)}).',
                    'Danach fährt das Fahrzeug eigenständig weiter zu seinem Ziel.',
                  ].join('\n'),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  key: const Key('alarm-destination'),
                  controller: _destination,
                  decoration: InputDecoration(labelText: 'Ziel / Einsatzort', hintText: _kind == 'boot' ? 'z. B. Suchgebiet Nordufer' : 'leer = Übungsort'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('alarm-task'),
                  controller: _task,
                  decoration: InputDecoration(labelText: 'Aufgabe', hintText: _kind == 'boot' ? 'z. B. Wassersuche' : 'z. B. Bereitstellung, Uferabsicherung'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Auslöser / Hinweis', hintText: 'z. B. Nachalarmierung durch Einsatzleiter'),
            ),
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Icon(Icons.warning_amber, size: 18, color: AppColors.warn),
                  const SizedBox(width: 6),
                  Expanded(child: Text(w, style: text.bodySmall?.copyWith(color: AppColors.warn))),
                ]),
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
                  final tow = _towed ? _tow : null;
                  await widget.repo.exercises.saveAlarmEntry(
                    d.exercise.id,
                    AlarmEntryInput(
                      id: e?.id,
                      label: _label.text,
                      kind: _kind,
                      vehicleId: _vehicleId,
                      alarmOffset: tow?.alarmOffset ?? _parse(_alarm)!,
                      departOffset: _parse(_depart),
                      arriveOffset: _parse(_arrive),
                      note: _note.text,
                      destination: _destination.text,
                      task: _task.text,
                      towedById: tow?.id,
                      slipLocation: tow == null ? null : _slipLocation.text,
                      slipOffset: tow == null ? null : _parse(_slipAt),
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
  const _Legend({this.slipping = false});
  final bool slipping;

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String text, {double w = 14}) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: w, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ]);
    return Wrap(spacing: 14, runSpacing: 4, children: [
      item(AppColors.yellow, 'Alarmierung bis Ausrücken'),
      item(AppColors.red, 'Anfahrt'),
      if (slipping) ...[
        item(Theme.of(context).colorScheme.outline, 'Boot auf Anhänger'),
        item(AppColors.slip, 'Slippen'),
        item(AppColors.water, 'Fahrt auf dem Wasser'),
      ],
      item(Theme.of(context).colorScheme.onSurface, 'Am Ziel / Einsatz ab', w: 3),
    ]);
  }
}

/// Abschnitte eines Balkens in der Zeitleiste.
typedef _Span = ({int from, int to, Color color});

/// Zeitleiste als Balken je Eintrag. Ein geslipptes Boot fährt bis zur
/// Slipstelle auf dem Anhänger seines Zugfahrzeugs mit.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.detail});
  final ExerciseDetail detail;

  List<_Span> _spans(AlarmPlanEntry e, Color trailer) {
    final d = detail;
    final out = <_Span>[];
    void add(int? from, int? to, Color color) {
      if (from != null && to != null && to >= from) out.add((from: from, to: to, color: color));
    }

    final tow = d.towOf(e);
    if (tow != null) {
      final depart = tow.departOffset;
      final slip = e.slipOffset;
      final water = e.departOffset;
      add(e.alarmOffset, depart, AppColors.yellow.withValues(alpha: 0.45));
      add(depart ?? e.alarmOffset, slip, trailer);
      add(slip, water, AppColors.slip);
      add(water ?? slip, e.arriveOffset, AppColors.water);
      return out;
    }
    final slips = [for (final b in d.towedBy(e)) ?b.slipOffset]..sort();
    final depart = e.departOffset;
    if (depart != null) {
      add(e.alarmOffset, depart, AppColors.yellow);
      if (slips.isNotEmpty) {
        add(depart, slips.first, AppColors.red);
        add(slips.first, e.arriveOffset, AppColors.red.withValues(alpha: 0.55));
      } else {
        add(depart, e.arriveOffset, AppColors.red);
      }
    } else if (e.arriveOffset != null) {
      add(e.alarmOffset, e.arriveOffset, AppColors.yellow);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final c = Theme.of(context).colorScheme;
    final points = [
      for (final e in d.alarmPlan) ...[e.alarmOffset, ?d.departOf(e), ?e.departOffset, ?e.arriveOffset, ?e.slipOffset],
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
      Widget bar(_Span s) => Positioned(
            left: x(s.from),
            width: math.max(x(s.to) - x(s.from), 2),
            top: 13,
            height: 18,
            child: DecoratedBox(decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(4))),
          );
      Widget marker(int off, IconData icon, String tip) => Positioned(
            left: x(off) - 9,
            top: -2,
            child: Tooltip(message: tip, child: Icon(icon, size: 16, color: AppColors.water)),
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
              () {
                final tow = d.towOf(e);
                final spans = _spans(e, c.outline);
                final sub = tow != null
                    ? 'Boot · über ${e.slipLocation ?? 'Slipstelle'}'
                    : [alarmKinds[e.kind] ?? e.kind, ?e.destination].join(' · ');
                return Container(
                  height: 44,
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant))),
                  child: Row(children: [
                    SizedBox(
                      width: labelW,
                      child: Padding(
                        padding: EdgeInsets.only(left: tow != null ? 14 : 0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                    SizedBox(
                      width: trackW,
                      child: Stack(clipBehavior: Clip.none, children: [
                        for (final m in ticks) Positioned(left: x(m), top: 0, bottom: 0, child: Container(width: 1, color: c.outlineVariant)),
                        for (final s in spans) bar(s),
                        if (spans.isEmpty) Positioned(left: x(e.alarmOffset) - 5, top: 17, child: Icon(Icons.circle, size: 10, color: c.onSurface)),
                        if (tow != null && e.slipOffset != null) marker(e.slipOffset!, Icons.anchor, 'Slippen: ${e.slipLocation ?? 'Slipstelle'}'),
                        for (final b in d.towedBy(e))
                          if (b.slipOffset != null) marker(b.slipOffset!, Icons.anchor, '${b.label} wird geslippt: ${b.slipLocation ?? 'Slipstelle'}'),
                        if (e.arriveOffset != null)
                          Positioned(left: x(e.arriveOffset!) - 1.5, top: 8, height: 28, width: 3, child: ColoredBox(color: c.onSurface)),
                      ]),
                    ),
                  ]),
                );
              }(),
          ]),
        ),
      );
    });
  }
}
