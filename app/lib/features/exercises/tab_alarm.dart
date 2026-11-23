import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import '../../data/database.dart';
import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../pdf/alarm_pdf.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;

String _vehicleText(Iterable<AlarmPlanEntry> entries, Map<String, Vehicle> byId) {
  final labels = {for (final e in entries) e.id: e.label};
  return entries.map((e) {
    final v = e.vehicleId == null ? null : byId[e.vehicleId];
    final name = v?.callSign == null ? e.label : '${e.label} (${v!.callSign})';
    final tow = labels[e.towedById];
    return tow == null ? name : '$name auf Anhänger von $tow';
  }).join(', ');
}

/// Fahrzeuge der ersten Alarmierung, z. B. „HLF 20 (Florian … 1/46-1), RW“.
String defaultAlarmVehicles(ExerciseDetail d, List<Vehicle> vehicles) {
  final groups = d.alarmGroups;
  if (groups.isEmpty) return '';
  return _vehicleText(groups.first.entries, {for (final v in vehicles) v.id: v});
}

/// Eine Alarmmeldung je Alarmierungszeitpunkt. Stichwort, Adresse, Melder
/// und Sonderrechte gelten für alle; die eingetragenen Fahrzeuge der
/// Alarmmeldung ersetzen nur die des Erstalarms.
List<AlarmSheet> alarmSheetsFor(ExerciseDetail d, List<Vehicle> vehicles, String organisation) {
  final e = d.exercise;
  final byId = {for (final v in vehicles) v.id: v};
  final groups = d.alarmGroups;
  AlarmSheet sheet({int? offset, String? label, required String fz, String? note}) => AlarmSheet(
        organisation: organisation,
        exerciseTitle: e.title,
        date: e.date,
        alarmTime: offset == null ? null : t.clock(d.start + offset),
        keyword: d.keyword?.code ?? 'Übungsalarm',
        keywordDescription: d.keyword?.description,
        address: e.alarmAddress ?? e.location ?? '',
        specialRights: d.specialRights,
        reporter: e.alarmReporter ?? '',
        vehicles: fz,
        alarmLabel: label,
        note: note,
      );
  if (groups.isEmpty) return [sheet(fz: e.alarmVehicles ?? '')];
  return [
    for (final g in groups)
      sheet(
        offset: g.offset,
        label: groups.length > 1 ? '${g.title} (${g.index + 1} von ${groups.length})' : null,
        fz: g.isFirst && e.alarmVehicles != null ? e.alarmVehicles! : _vehicleText(g.entries, byId),
        note: g.isFirst ? null : g.entries.map((x) => x.note).whereType<String>().toSet().join(' · '),
      ),
  ];
}

/// Erste Alarmmeldung (Kompatibilität für Tests).
AlarmSheet alarmSheetFor(ExerciseDetail d, List<Vehicle> vehicles, String organisation) => alarmSheetsFor(d, vehicles, organisation).first;

/// Alarmmeldung zum Ausdrucken. Die Auslösung in Divera macht der TL.
class AlarmTab extends StatefulWidget {
  const AlarmTab({super.key, required this.detail});
  final ExerciseDetail detail;

  @override
  State<AlarmTab> createState() => _AlarmTabState();
}

class _AlarmTabState extends State<AlarmTab> {
  late final repo = AppScope.of(context);
  late final _vehicles = repo.vehicles.watchAll();
  late final _org = repo.settings.watch(SettingsRepository.orgName);

  ExerciseDetail get d => widget.detail;

  Future<void> _edit(List<Vehicle> vehicles) async {
    final e = d.exercise;
    final address = TextEditingController(text: e.alarmAddress ?? e.location);
    final reporter = TextEditingController(text: e.alarmReporter);
    final fz = TextEditingController(text: e.alarmVehicles ?? defaultAlarmVehicles(d, vehicles));
    bool? rights = e.alarmSpecialRights;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Alarmmeldung bearbeiten'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Stichwort: ${d.keyword?.code ?? '– (in den Eckdaten wählen)'}'),
                const SizedBox(height: 12),
                TextField(key: const Key('alarm-address'), controller: address, decoration: const InputDecoration(labelText: 'Adresse')),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: rights,
                  decoration: const InputDecoration(labelText: 'Sonderrechte / prioritär'),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('wie Stichwort (${(d.keyword?.specialRights ?? true) ? 'ja' : 'nein'})'),
                    ),
                    const DropdownMenuItem(value: true, child: Text('Ja')),
                    const DropdownMenuItem(value: false, child: Text('Nein')),
                  ],
                  onChanged: (v) => setS(() => rights = v),
                ),
                const SizedBox(height: 12),
                TextField(key: const Key('alarm-reporter'), controller: reporter, decoration: const InputDecoration(labelText: 'Melder', hintText: 'z. B. Zeuge auf der Straße')),
                const SizedBox(height: 12),
                TextField(
                  controller: fz,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alarmierte Fahrzeuge (Erstalarm)',
                    helperText: 'Leer lassen = aus dem Alarmierungsplan übernehmen. Weitere Alarmierungen kommen immer aus dem Plan.',
                  ),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(key: const Key('alarm-sheet-save'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final auto = defaultAlarmVehicles(d, vehicles);
    await repo.exercises.setAlarm(
      e.id,
      address: address.text == (e.location ?? '') ? null : address.text,
      reporter: reporter.text,
      specialRights: rights,
      vehicles: fz.text.trim() == auto ? null : fz.text,
    );
  }

  String _fileName() => 'Alarmmeldung_${t.date(d.exercise.date)}_${d.exercise.title}'.replaceAll(RegExp(r'[^\wäöüÄÖÜß.-]+'), '_');

  Future<void> _print(List<AlarmSheet> sheets) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => buildAlarmPdf(sheets), name: _fileName());
    } catch (e) {
      if (mounted) showMessage(context, 'Drucken nicht möglich: $e. Bitte als PDF speichern.');
    }
  }

  Future<void> _save(List<AlarmSheet> sheets) async {
    final bytes = await buildAlarmPdf(sheets);
    final uri = await FilePicker.saveFile(fileName: '${_fileName()}.pdf', bytes: bytes, mimeType: 'application/pdf');
    if (uri != null && mounted) showMessage(context, 'PDF gespeichert');
  }

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Vehicle>>(
      stream: _vehicles,
      builder: (context, vehicles) => StreamBuilder<String?>(
        stream: _org,
        builder: (context, org) {
          final sheets = alarmSheetsFor(d, vehicles, org.data ?? '');
          final sheet = sheets.first;
          final hints = [
            if (d.keyword == null) 'Kein Alarmstichwort gewählt (Eckdaten).',
            if (sheet.address.isEmpty) 'Keine Adresse.',
            if (sheet.vehicles.isEmpty) 'Keine Fahrzeuge – Alarmierungsplan anlegen oder Fahrzeuge eintragen.',
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: [
                FilledButton.icon(
                  onPressed: () => _print(sheets),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(sheets.length > 1 ? '${sheets.length} Alarmmeldungen drucken' : 'Drucken'),
                ),
                OutlinedButton.icon(onPressed: () => _save(sheets), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Als PDF speichern')),
                OutlinedButton.icon(
                  key: const Key('alarm-sheet-edit'),
                  onPressed: () => _edit(vehicles),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Bearbeiten'),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Nur zum Ausdrucken. Die Auslösung in Divera 24/7 erfolgt durch den TL.', style: Theme.of(context).textTheme.bodySmall),
              for (final h in hints)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.warn),
                    const SizedBox(width: 6),
                    Expanded(child: Text(h)),
                  ]),
                ),
              if (sheets.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Es gibt ${sheets.length} Alarmierungszeitpunkte im Alarmierungsplan, daher ${sheets.length} Alarmmeldungen.'),
                ),
              const SizedBox(height: 16),
              Wrap(spacing: 16, runSpacing: 16, children: [for (final s in sheets) _AlarmPreview(sheet: s)]),
            ],
          );
        },
      ),
    );
  }
}

/// Bildschirmvorschau, angelehnt an den Ausdruck.
class _AlarmPreview extends StatelessWidget {
  const _AlarmPreview({required this.sheet});
  final AlarmSheet sheet;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget banner() => Container(
          color: AppColors.yellow,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          child: const Text('ÜBUNG · ÜBUNG · ÜBUNG',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12, color: Color(0xFF2A2200))),
        );
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 170, child: Text(k, style: TextStyle(color: c.onSurfaceVariant))),
            Expanded(child: Text(v.isEmpty ? '–' : v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          banner(),
          if (sheet.alarmLabel != null)
            Container(
              color: c.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(sheet.alarmLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          Container(
            color: AppColors.red,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Text(sheet.keyword, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
              Text('${t.date(sheet.date)}${sheet.alarmTime == null ? '' : '\n${sheet.alarmTime} Uhr'}',
                  textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              row('Stichwort', sheet.keyword),
              row('Adresse', sheet.address),
              row('Sonderrechte / prioritär', sheet.specialRights ? 'Ja' : 'Nein'),
              row('Melder', sheet.reporter),
              row('Alarmierte Fahrzeuge', sheet.vehicles),
              if (sheet.note != null && sheet.note!.isNotEmpty) row('Hinweis Übungsleitung', sheet.note!),
            ]),
          ),
          banner(),
        ]),
      ),
    );
  }
}
