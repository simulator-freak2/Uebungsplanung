import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/documents_repository.dart';
import '../data/exercise_repository.dart';
import '../data/repositories.dart';
import '../map/sketch.dart';
import '../util/time.dart' as t;
import 'alarm_pdf.dart';

/// Teile der Übungsmappe.
enum MapSection {
  plan('Übungsplan'),
  sketch('Lageskizze'),
  crew('Fahrzeugbesetzung'),
  alarmPlan('Alarmierungsplan'),
  alarms('Alarmmeldungen'),
  radio('Funkplan'),
  roles('Rollenkarten'),
  material('Materialliste'),
  observation('Beobachtungsbogen'),
  debrief('Nachbesprechungsprotokoll');

  const MapSection(this.label);
  final String label;
}

/// Alles, was für die Übungsmappe gebraucht wird.
class ExerciseMapData {
  ExerciseMapData({
    required this.organisation,
    required this.detail,
    required this.vehicles,
    required this.persons,
    required this.qualificationNames,
    required this.alarmSheets,
    required this.approvalRequired,
    this.symbolNames = const {},
  });

  /// Asset-Pfad → Name der taktischen Zeichen (für die Legende).
  final Map<String?, String> symbolNames;

  final String organisation;
  final ExerciseDetail detail;

  /// Fahrzeugdetails; Schlüssel `null` = Führungsfunktionen.
  final Map<String?, VehicleDetail> vehicles;
  final Map<String, PersonWithQualifications> persons;
  final Map<String, String> qualificationNames;
  final List<AlarmSheet> alarmSheets;
  final bool approvalRequired;
}

const _red = PdfColor.fromInt(0xFFC8102E);
const _yellow = PdfColor.fromInt(0xFFFFCC00);
const _grey = PdfColors.grey700;

Future<Uint8List> buildExerciseMap(ExerciseMapData data, Set<MapSection> sections, {PdfFonts? fonts}) async {
  final f = fonts ?? await PdfFonts.load();
  final d = data.detail;
  final e = d.exercise;
  final doc = pw.Document(title: 'Übungsmappe – ${e.title}', author: data.organisation);
  final theme = pw.ThemeData.withFont(base: f.regular, bold: f.bold);
  String time(int? off) => off == null ? '–' : t.formatOffset(off, start: d.start, relativeMode: d.relativeTimes);

  pw.Widget header(pw.Context ctx, String section) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _red, width: 2))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(section.toUpperCase(), style: pw.TextStyle(font: f.bold, fontSize: 9, color: _red, letterSpacing: 1)),
              pw.Text(e.title, style: pw.TextStyle(font: f.bold, fontSize: 14)),
            ]),
          ),
          pw.Text('${data.organisation}\n${t.date(e.date)} · ${t.clock(e.startMinutes)} Uhr',
              textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ]),
      );
  pw.Widget footer(pw.Context ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Seite ${ctx.pageNumber} von ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _grey)),
      );
  pw.Widget h2(String s) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
        child: pw.Text(s, style: pw.TextStyle(font: f.bold, fontSize: 12)),
      );
  pw.Widget kv(String k, String? v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 120, child: pw.Text(k, style: const pw.TextStyle(color: _grey))),
          pw.Expanded(child: pw.Text(v == null || v.isEmpty ? '–' : v)),
        ]),
      );
  pw.Widget table(List<String> head, List<List<String>> rows, {Map<int, pw.TableColumnWidth>? widths}) => pw.TableHelper.fromTextArray(
        headers: head,
        data: rows,
        columnWidths: widths,
        headerStyle: pw.TextStyle(font: f.bold, fontSize: 9, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _red),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.topLeft,
        cellPadding: const pw.EdgeInsets.all(4),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      );
  pw.Widget bullets(List<String> items) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [for (final i in items) pw.Bullet(text: i, style: const pw.TextStyle(fontSize: 10))]);
  void page(String section, List<pw.Widget> Function() body) => doc.addPage(pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 30),
        header: (ctx) => header(ctx, section),
        footer: footer,
        build: (_) => body(),
      ));

  // ------------------------------------------------------------- Übungsplan
  if (sections.contains(MapSection.plan)) {
    page('Übungsplan', () => [
          kv('Datum', t.dateLong(e.date)),
          kv('Zeit', '${t.clock(e.startMinutes)}${e.endMinutes == null ? '' : ' – ${t.clock(e.endMinutes!)}'} Uhr'),
          kv('Ort', e.location),
          kv('Einheit', e.unit),
          kv('Thema', e.topic),
          kv('Alarmstichwort', d.keyword == null ? null : '${d.keyword!.code}${d.keyword!.description == null ? '' : ' – ${d.keyword!.description}'}'),
          kv('Status', '${ExerciseStatus.label(e.status, approvalRequired: data.approvalRequired)}'
              '${e.approvedBy == null ? '' : ', freigegeben von ${e.approvedBy}${e.approvedAt == null ? '' : ' am ${t.date(e.approvedAt!.toLocal())}'}'}'),
          if (d.goals.isNotEmpty) ...[h2('Lernziele'), bullets(d.goals)],
          if (e.scenario != null) ...[h2('Lage'), pw.Text(e.scenario!)],
          if (d.phases.isNotEmpty) ...[
            h2('Ablauf'),
            table(['Zeit', 'Was passiert?'], [for (final p in d.phases) [t.clock(d.start + p.offsetMinutes), p.description]],
                widths: {0: const pw.FixedColumnWidth(50)}),
          ],
          h2('Sicherheit & Gefährdungsbeurteilung'),
          for (final c in d.checks)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  margin: const pw.EdgeInsets.only(right: 6, top: 1),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
                  child: c.checked ? pw.Center(child: pw.Text('✓', style: pw.TextStyle(font: f.bold, fontSize: 8))) : null,
                ),
                pw.Expanded(child: pw.Text(c.description)),
              ]),
            ),
        ]);
  }

  // -------------------------------------------------------------- Lageskizze
  if (sections.contains(MapSection.sketch)) {
    final items = decodeSketch(e.sketch);
    page('Lageskizze', () => [
          if (e.sketchPng == null)
            pw.Text('Noch kein Bild der Lageskizze. In der App unter „Lageskizze“ → „Für Übungsmappe übernehmen“.')
          else
            pw.Center(child: pw.Image(pw.MemoryImage(base64Decode(e.sketchPng!)), fit: pw.BoxFit.contain, height: 480)),
          if (items.any((i) => i.label.isNotEmpty || i.type == 'symbol')) ...[
            h2('Legende'),
            table(['Element', 'Beschriftung'], [
              for (final i in items)
                if (i.type == 'symbol' || i.label.isNotEmpty)
                  [
                    switch (i.type) {
                      'symbol' => data.symbolNames[i.symbol] ?? 'Zeichen',
                      'line' => 'Linie',
                      'area' => 'Fläche',
                      _ => 'Text',
                    },
                    i.label,
                  ],
            ]),
          ],
          pw.SizedBox(height: 6),
          pw.Text('Kartenquelle siehe Vermerk im Bild · Taktische Zeichen: taktisches-zeichen.de', style: const pw.TextStyle(fontSize: 7, color: _grey)),
        ]);
  }

  // ------------------------------------------------------- Fahrzeugbesetzung
  if (sections.contains(MapSection.crew)) {
    final byFn = d.personsByFunction;
    List<List<String>> rows(VehicleDetail vd, Set<String> ids) => [
          for (final fn in vd.functions.where((x) => ids.contains(x.id) || byFn.containsKey(x.id)))
            () {
              final pid = byFn[fn.id]?.first;
              final p = pid == null ? null : data.persons[pid];
              final need = fn.requiredQualificationId;
              final missing = p != null && need != null && !p.qualificationIds.contains(need);
              return [fn.name, p?.displayName ?? '', need == null ? '' : (data.qualificationNames[need] ?? ''), missing ? 'Qualifikation fehlt' : ''];
            }(),
        ];
    page('Fahrzeugbesetzung', () => [
          if (data.vehicles[null] != null) ...[
            h2('Führungs- und Sonderfunktionen'),
            table(['Funktion', 'Person', 'benötigt', 'Hinweis'], rows(data.vehicles[null]!, {for (final x in data.vehicles[null]!.functions) x.id})),
          ],
          for (final ev in d.vehicles)
            if (data.vehicles[ev.vehicleId] != null) ...() {
              final vd = data.vehicles[ev.vehicleId]!;
              final pattern = vd.patterns.where((p) => p.id == ev.patternId).firstOrNull;
              final ids = pattern == null ? {for (final x in vd.functions) x.id} : vd.matrix[pattern.id]!;
              return [
                h2('${vd.vehicle!.name}${vd.vehicle!.callSign == null ? '' : ' · ${vd.vehicle!.callSign}'}${pattern == null ? '' : ' · ${pattern.name}'}'),
                table(['Funktion', 'Person', 'benötigt', 'Hinweis'], rows(vd, ids)),
              ];
            }(),
          if (d.vehicles.isEmpty) pw.Text('Keine Fahrzeuge eingeplant.'),
        ]);
  }

  // -------------------------------------------------------- Alarmierungsplan
  if (sections.contains(MapSection.alarmPlan)) {
    page('Alarmierungsplan', () => [
          if (d.alarmPlan.isEmpty)
            pw.Text('Kein Alarmierungsplan.')
          else
            table(
              ['Einheit', 'Art', 'Alarmierung / Abruf', 'Ausrücken', 'Am Einsatzort / Einsatz ab', 'Auslöser / Hinweis'],
              [
                for (final a in d.alarmPlan)
                  [a.label, a.kind == 'trupp' ? 'Trupp' : (a.kind == 'boot' ? 'Boot' : 'Fahrzeug'), time(a.alarmOffset), time(a.departOffset), time(a.arriveOffset), a.note ?? ''],
              ],
            ),
        ]);
  }

  // ---------------------------------------------------------- Alarmmeldungen
  if (sections.contains(MapSection.alarms)) {
    for (final s in data.alarmSheets) {
      addAlarmPage(doc, s, f);
    }
  }

  // ---------------------------------------------------------------- Funkplan
  if (sections.contains(MapSection.radio)) {
    page('Funkplan', () => [
          if (d.radio.isEmpty)
            pw.Text('Kein Funkplan.')
          else
            table(['Rufname', 'Einheit / Gerät', 'Funknetz', 'Gruppe / Kanal', 'Aufgabe'],
                [for (final r in d.radio) [r.callSign, r.device ?? '', radioNetworks[r.network] ?? r.network, r.channel ?? '', r.task ?? '']]),
        ]);
  }

  // ------------------------------------------------------------ Rollenkarten
  if (sections.contains(MapSection.roles)) {
    for (final r in d.roles) {
      final age = ageOn(r, e.date);
      final stages = decodeEscalation(r.escalation);
      page('Rollenkarte ${r.number}', () => [
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 2), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(children: [
                  pw.Expanded(child: pw.Text(r.name, style: pw.TextStyle(font: f.bold, fontSize: 20))),
                  pw.Text('${r.number}', style: pw.TextStyle(font: f.bold, fontSize: 30, color: _red)),
                ]),
                pw.SizedBox(height: 8),
                kv('Geburtsdatum', r.birthDate == null ? null : t.date(r.birthDate!)),
                kv('Alter', age == null ? null : '$age Jahre'),
                kv('Vorerkrankungen', r.preExisting),
                kv('Erkrankungen', r.illnesses),
                kv('Symptome', r.symptoms),
                kv('Verletzungen', r.injuries),
                h2('Story – was ist passiert?'),
                pw.Text(r.story ?? '–'),
                if (stages.isNotEmpty) ...[
                  h2('Eskalationsstufen'),
                  for (final (i, s) in stages.indexed)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border(left: pw.BorderSide(color: [_yellow, PdfColors.orange, _red][i.clamp(0, 2)], width: 4)),
                      ),
                      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 130,
                          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                            pw.Text(s.label, style: pw.TextStyle(font: f.bold)),
                            if (s.trigger.isNotEmpty) pw.Text(s.trigger, style: const pw.TextStyle(fontSize: 8, color: _grey)),
                          ]),
                        ),
                        pw.Expanded(child: pw.Text(s.behavior)),
                      ]),
                    ),
                ],
              ]),
            ),
          ]);
    }
  }

  // ------------------------------------------------------------ Materialliste
  if (sections.contains(MapSection.material)) {
    page('Materialliste', () => [
          if (d.material.isEmpty)
            pw.Text('Kein Material eingetragen.')
          else
            table(['', 'Material', 'Standort / verlastet auf', 'Menge'], [for (final m in d.material) ['☐', m.name, m.location ?? '', m.quantity ?? '']],
                widths: {0: const pw.FixedColumnWidth(18)}),
        ]);
  }

  // -------------------------------------------------------- Beobachtungsbogen
  if (sections.contains(MapSection.observation)) {
    page('Beobachtungsbogen', () => [
          kv('Beobachter/in', ''),
          pw.SizedBox(height: 6),
          table(
            ['Beobachtungspunkt', '++', '+', 'o', '–', 'Notiz / Uhrzeit'],
            [for (final o in d.observations) [o.description, for (final r in ['++', '+', 'o', '-']) o.rating == r ? '✕' : '', o.note ?? '\n\n']],
            widths: {
              0: const pw.FlexColumnWidth(3),
              for (var i = 1; i <= 4; i++) i: const pw.FixedColumnWidth(22),
              5: const pw.FlexColumnWidth(3),
            },
          ),
          if (d.roles.any((r) => decodeEscalation(r.escalation).isNotEmpty)) ...[
            h2('Eskalationsstufen der Mimen'),
            for (final r in d.roles)
              if (decodeEscalation(r.escalation).isNotEmpty) ...[
                pw.Text('${r.number}  ${r.name}', style: pw.TextStyle(font: f.bold)),
                table(['Stufe', 'Auslöser', 'Verhalten', 'Uhrzeit'], [
                  for (final s in decodeEscalation(r.escalation)) [s.label, s.trigger, s.behavior, ''],
                ], widths: {3: const pw.FixedColumnWidth(50)}),
                pw.SizedBox(height: 6),
              ],
          ],
          h2('Weitere Beobachtungen'),
          pw.Container(height: 120, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400))),
        ]);
  }

  // -------------------------------------------------- Nachbesprechungsprotokoll
  if (sections.contains(MapSection.debrief)) {
    page('Nachbesprechungsprotokoll', () => [
          kv('Teilnehmende', e.debriefParticipants),
          h2('Was lief gut?'),
          d.debriefGood.isEmpty ? pw.Text('–') : bullets(d.debriefGood),
          h2('Was muss besser werden?'),
          d.debriefBad.isEmpty ? pw.Text('–') : bullets(d.debriefBad),
          h2('Maßnahmen für die weitere Übungsplanung'),
          d.lessons.isEmpty
              ? pw.Text('–')
              : table(['Maßnahme', 'Zuständig', 'Status'], [for (final l in d.lessons) [l.description, l.responsible ?? '', lessonStatus[l.status] ?? l.status]]),
          if (d.observations.any((o) => o.rating != null)) ...[
            h2('Ergebnis Beobachtungsbogen'),
            table(['Beobachtungspunkt', 'Bewertung', 'Notiz'],
                [for (final o in d.observations.where((o) => o.rating != null)) [o.description, o.rating == '-' ? '–' : o.rating!, o.note ?? '']]),
          ],
          if (e.debriefNotes != null) ...[h2('Notizen'), pw.Text(e.debriefNotes!)],
        ]);
  }

  if (sections.isEmpty) {
    page('Übungsmappe', () => [pw.Text('Keine Teile ausgewählt.')]);
  }
  return doc.save();
}
