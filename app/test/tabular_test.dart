import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uebungsplaner/import/importers.dart';
import 'package:uebungsplaner/import/tabular.dart';

void main() {
  group('CSV', () {
    test('erkennt Semikolon, Anführungszeichen und Zeilenumbrüche', () {
      final rows = parseCsv('Name;Bemerkung\r\n"Becker; Jonas";"sagt ""Hallo""\nzweite Zeile"\r\nWolf;x\r\n');
      expect(rows, [
        ['Name', 'Bemerkung'],
        ['Becker; Jonas', 'sagt "Hallo"\nzweite Zeile'],
        ['Wolf', 'x'],
      ]);
    });

    test('erkennt Komma als Trennzeichen', () {
      expect(parseCsv('a,b,c\n1,2,3'), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('liest Windows-1252 (Umlaute aus deutschem Excel)', () {
      final bytes = Uint8List.fromList(latin1.encode('Nachname;Qualifikation\nMüller;Truppführer'));
      final t = readTable(bytes, 'liste.csv');
      expect(t.headers, ['Nachname', 'Qualifikation']);
      expect(t.rows.single, ['Müller', 'Truppführer']);
    });

    test('schreibt CSV, das wieder gelesen werden kann', () {
      final bytes = writeCsv([
        ['Stichwort', 'Beschreibung'],
        ['B 2', 'Brand; Wohnung "klein"'],
      ]);
      final t = readTable(bytes, 'x.csv');
      expect(t.rows.single, ['B 2', 'Brand; Wohnung "klein"']);
    });
  });

  group('Spaltenzuordnung', () {
    test('ordnet typische Überschriften zu', () {
      final m = guessMapping(['Pers.-Nr.', 'Name', 'Vorname', 'Lehrgänge'], personFields);
      expect(m['personnelNo'], 0);
      expect(m['lastName'], 1);
      expect(m['firstName'], 2);
      expect(m['qualifications'], 3);
      expect(m['fullName'], isNull);
    });

    test('Stichworttabelle', () {
      final m = guessMapping(['Einsatzstichwort', 'Meldebild', 'Einsatzmittel', 'Sondersignal'], keywordFields);
      expect(m, {'code': 0, 'category': null, 'description': 1, 'resources': 2, 'specialRights': 3});
    });
  });

  test('Personen: „Name“ wird in Nach- und Vorname geteilt', () {
    final t = ImportTable(['Name', 'Qualifikationen', 'JF'], [
      ['Becker, Jonas', 'AGT; Maschinist', ''],
      ['Lena Schulz', 'Truppführer', 'x'],
      ['', '', ''],
    ]);
    final rows = mapPersons(t, {'fullName': 0, 'qualifications': 1, 'youth': 2});
    expect(rows.length, 2);
    expect(rows[0].lastName, 'Becker');
    expect(rows[0].firstName, 'Jonas');
    expect(rows[0].qualifications, ['AGT', 'Maschinist']);
    expect(rows[1].lastName, 'Schulz');
    expect(rows[1].firstName, 'Lena');
    expect(rows[1].youth, isTrue);
  });

  test('Ja/Nein-Werte', () {
    expect(parseYesNo('Ja'), isTrue);
    expect(parseYesNo('x'), isTrue);
    expect(parseYesNo('nein'), isFalse);
    expect(parseYesNo(''), isNull);
  });
}
