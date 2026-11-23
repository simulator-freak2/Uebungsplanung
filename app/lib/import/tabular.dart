import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;

/// Eine eingelesene Tabelle: Kopfzeile + Datenzeilen (alles als Text).
class ImportTable {
  ImportTable(this.headers, this.rows);
  final List<String> headers;
  final List<List<String>> rows;

  String cell(List<String> row, int? column) =>
      (column == null || column < 0 || column >= row.length) ? '' : row[column].trim();
}

/// Liest eine Excel- (.xlsx) oder CSV-Datei. Die erste nicht leere Zeile
/// gilt als Kopfzeile.
ImportTable readTable(Uint8List bytes, String fileName) {
  final lower = fileName.toLowerCase();
  final raw = lower.endsWith('.xlsx') ? _readXlsx(bytes) : parseCsv(decodeText(bytes));
  final nonEmpty = raw.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
  if (nonEmpty.isEmpty) return ImportTable(const [], const []);
  final headers = nonEmpty.first.map((h) => h.trim()).toList();
  final width = headers.length;
  final rows = [
    for (final r in nonEmpty.skip(1)) [for (var i = 0; i < width; i++) i < r.length ? r[i] : ''],
  ];
  return ImportTable(headers, rows);
}

List<List<String>> _readXlsx(Uint8List bytes) {
  final book = xl.Excel.decodeBytes(bytes);
  if (book.tables.isEmpty) return const [];
  final sheet = book.tables.values.first;
  return [
    for (final row in sheet.rows) [for (final c in row) _cellText(c?.value)],
  ];
}

String _cellText(xl.CellValue? v) {
  if (v == null) return '';
  if (v is xl.DoubleCellValue) {
    final d = v.value;
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }
  return v.toString();
}

/// Dekodiert Text als UTF-8; scheitert das (typisch für CSV aus einem
/// deutschen Excel), wird Windows-1252/Latin-1 angenommen.
String decodeText(Uint8List bytes) {
  var data = bytes;
  if (data.length >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
    data = data.sublist(3);
  }
  try {
    return utf8.decode(data);
  } on FormatException {
    return latin1.decode(data);
  }
}

/// CSV-Leser mit Anführungszeichen-Unterstützung. Das Trennzeichen
/// (`;`, `,` oder Tab) wird anhand der ersten Zeile erkannt.
List<List<String>> parseCsv(String text, {String? delimiter}) {
  final firstLine = text.split(RegExp(r'\r?\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final sep = delimiter ?? _guessDelimiter(firstLine);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == sep) {
      row.add(field.toString());
      field.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

String _guessDelimiter(String line) {
  int count(String s) => s.allMatches(line).length;
  final candidates = {';': count(';'), ',': count(','), '\t': count('\t')};
  final best = candidates.entries.reduce((a, b) => b.value > a.value ? b : a);
  return best.value == 0 ? ';' : best.key;
}

/// Schreibt CSV mit Semikolon (öffnet sich in deutschem Excel direkt richtig)
/// und UTF-8-BOM.
Uint8List writeCsv(List<List<String>> rows) {
  String esc(String v) =>
      (v.contains(';') || v.contains('"') || v.contains('\n')) ? '"${v.replaceAll('"', '""')}"' : v;
  final text = rows.map((r) => r.map(esc).join(';')).join('\r\n');
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(text)]);
}

/// Ein Feld, das beim Import einer Spalte zugeordnet werden kann.
class ImportField {
  const ImportField(this.key, this.label, {this.required = false, this.aliases = const []});
  final String key;
  final String label;
  final bool required;

  /// Mögliche Spaltenüberschriften (klein geschrieben, ohne Sonderzeichen).
  final List<String> aliases;
}

String _simplify(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Ordnet Felder anhand der Spaltenüberschriften automatisch zu.
Map<String, int?> guessMapping(List<String> headers, List<ImportField> fields) {
  final simple = headers.map(_simplify).toList();
  final used = <int>{};
  final result = <String, int?>{};
  for (final f in fields) {
    int? found;
    final names = [_simplify(f.label), ...f.aliases.map(_simplify)];
    // zuerst exakte Treffer, dann „beginnt mit“
    for (var i = 0; i < simple.length && found == null; i++) {
      if (!used.contains(i) && names.contains(simple[i])) found = i;
    }
    for (var i = 0; i < simple.length && found == null; i++) {
      if (!used.contains(i) && simple[i].isNotEmpty && names.any((n) => simple[i].startsWith(n))) found = i;
    }
    if (found != null) used.add(found);
    result[f.key] = found;
  }
  return result;
}

/// Wertet „ja“, „x“, „1“, „true“ usw. als wahr aus.
bool? parseYesNo(String v) {
  final s = _simplify(v);
  if (s.isEmpty) return null;
  if (const ['ja', 'j', 'x', '1', 'true', 'yes', 'y', 'wahr'].contains(s)) return true;
  if (const ['nein', 'n', '0', 'false', 'no', 'falsch', '-'].contains(s)) return false;
  return null;
}

/// Teilt eine Liste wie „AGT, Maschinist; Truppführer“ auf.
List<String> splitList(String v) =>
    v.split(RegExp(r'[,;/|\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
