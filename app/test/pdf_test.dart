import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uebungsplaner/pdf/alarm_pdf.dart';

void main() {
  test('Alarmmeldung als PDF mit Umlauten und Übungskennzeichnung', () async {
    final fonts = PdfFonts(
      pw.Font.ttf((await File('assets/fonts/DejaVuSans.ttf').readAsBytes()).buffer.asByteData()),
      pw.Font.ttf((await File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytes()).buffer.asByteData()),
    );
    final bytes = await buildAlarmPdf(
      AlarmSheet(
        organisation: 'Freiwillige Feuerwehr Musterstadt',
        exerciseTitle: 'THL: Verkehrsunfall mit eingeklemmter Person',
        date: DateTime(2027, 3, 4),
        alarmTime: '19:15',
        keyword: 'TH 2 – VU P eingeklemmt',
        keywordDescription: 'Verkehrsunfall, Person eingeklemmt',
        address: 'Industriestraße 12, 12345 Musterstadt (Bauhof)',
        specialRights: true,
        reporter: 'Übungsleitung – Zeuge auf der Straße',
        vehicles: 'HLF 20 (Florian Musterstadt 1/46-1), RW (Florian Musterstadt 1/52-1)',
      ),
      fonts: fonts,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
