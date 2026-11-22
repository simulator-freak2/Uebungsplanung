import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../util/time.dart' as t;

/// Inhalt der Alarmmeldung (Aufbau wie die Meldung der Alarm-App).
class AlarmSheet {
  AlarmSheet({
    required this.organisation,
    required this.exerciseTitle,
    required this.date,
    this.alarmTime,
    required this.keyword,
    this.keywordDescription,
    required this.address,
    required this.specialRights,
    required this.reporter,
    required this.vehicles,
  });

  final String organisation;
  final String exerciseTitle;
  final DateTime date;
  final String? alarmTime;
  final String keyword;
  final String? keywordDescription;
  final String address;
  final bool specialRights;
  final String reporter;
  final String vehicles;
}

class PdfFonts {
  PdfFonts(this.regular, this.bold);
  final pw.Font regular;
  final pw.Font bold;

  static PdfFonts? _cache;

  /// DejaVu Sans: enthält Umlaute, ß und Gedankenstriche.
  static Future<PdfFonts> load() async => _cache ??= PdfFonts(
        pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf')),
        pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf')),
      );
}

const _red = PdfColor.fromInt(0xFFC8102E);
const _yellow = PdfColor.fromInt(0xFFFFCC00);

/// Erzeugt die Alarmmeldung als A4-PDF. Sie ist oben und unten deutlich als
/// Übung gekennzeichnet, damit sie nicht mit einer echten Alarmierung
/// verwechselt werden kann.
Future<Uint8List> buildAlarmPdf(AlarmSheet a, {PdfFonts? fonts}) async {
  final f = fonts ?? await PdfFonts.load();
  final doc = pw.Document(title: 'Alarmmeldung (Übung) – ${a.exerciseTitle}', author: a.organisation);

  pw.Widget banner() => pw.Container(
        width: double.infinity,
        color: _yellow,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        alignment: pw.Alignment.center,
        child: pw.Text('ÜBUNG  ·  ÜBUNG  ·  ÜBUNG  ·  KEINE ECHTE ALARMIERUNG',
            style: pw.TextStyle(font: f.bold, fontSize: 13, letterSpacing: 1.5)),
      );

  pw.Widget row(String label, String value, {bool big = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: pw.TextStyle(font: f.regular, fontSize: 11, color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(value.isEmpty ? '–' : value, style: pw.TextStyle(font: f.bold, fontSize: big ? 20 : 14))),
        ]),
      );

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      banner(),
      pw.Container(
        color: _red,
        padding: const pw.EdgeInsets.all(16),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(child: pw.Text(a.keyword, style: pw.TextStyle(font: f.bold, fontSize: 26, color: PdfColors.white))),
          pw.Text('${t.date(a.date)}${a.alarmTime == null ? '' : '\n${a.alarmTime} Uhr'}',
              textAlign: pw.TextAlign.right, style: pw.TextStyle(font: f.bold, fontSize: 13, color: PdfColors.white)),
        ]),
      ),
      pw.SizedBox(height: 12),
      row('Stichwort', a.keyword, big: true),
      if (a.keywordDescription != null) row('Meldebild', a.keywordDescription!),
      pw.Divider(color: PdfColors.grey400),
      row('Adresse', a.address),
      row('Sonderrechte / prioritär', a.specialRights ? 'Ja' : 'Nein'),
      row('Melder', a.reporter),
      row('Alarmierte Fahrzeuge', a.vehicles),
      pw.Spacer(),
      pw.Text('${a.organisation} · Übung: ${a.exerciseTitle}', style: pw.TextStyle(font: f.regular, fontSize: 9, color: PdfColors.grey700)),
      pw.Text('Nur zur Verwendung im Übungsdienst. Die Auslösung in Divera 24/7 erfolgt durch den TL.',
          style: pw.TextStyle(font: f.regular, fontSize: 9, color: PdfColors.grey700)),
      pw.SizedBox(height: 8),
      banner(),
    ]),
  ));
  return doc.save();
}
