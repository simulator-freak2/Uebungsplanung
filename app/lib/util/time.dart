/// Zeitangaben in Übungen.
///
/// Gespeichert werden Minuten **relativ zum Übungsbeginn**. Angezeigt und
/// eingegeben werden sie wahlweise als Uhrzeit („19:15“) oder relativ
/// („+15“). Damit verschiebt sich der ganze Plan mit, wenn sich der
/// Übungsbeginn ändert.
library;

String two(int n) => n.toString().padLeft(2, '0');

/// Minuten nach Mitternacht → „19:05“.
String clock(int minutesOfDay) {
  final m = ((minutesOfDay % 1440) + 1440) % 1440;
  return '${two(m ~/ 60)}:${two(m % 60)}';
}

/// Relativer Wert → „+15 Min.“ bzw. „−5 Min.“ bzw. „Beginn“.
String relative(int offset) {
  if (offset == 0) return 'Beginn';
  final sign = offset > 0 ? '+' : '−';
  final a = offset.abs();
  if (a >= 60 && a % 60 == 0) return '$sign${a ~/ 60} Std.';
  if (a >= 60) return '$sign${a ~/ 60}:${two(a % 60)} Std.';
  return '$sign$a Min.';
}

/// Formatiert einen relativen Wert je nach Modus.
String formatOffset(int offset, {required int start, required bool relativeMode}) =>
    relativeMode ? relative(offset) : clock(start + offset);

/// Liest „19:15“, „1915“, „19.15“ (Uhrzeit) oder „+15“, „-5“, „15“ (Minuten
/// relativ). Reine Zahlen bis 3 Stellen gelten als Minuten, sonst als
/// Uhrzeit. Gibt den Wert relativ zum Beginn zurück oder `null`.
int? parseOffset(String input, {required int start}) {
  final s = input.trim().replaceAll(' ', '').replaceAll('−', '-').replaceAll(RegExp(r'(min\.?|minuten)$', caseSensitive: false), '');
  if (s.isEmpty) return null;
  final rel = RegExp(r'^([+-])?(\d{1,3})$').firstMatch(s);
  if (rel != null && !(rel.group(1) == null && s.length == 4)) {
    final v = int.parse(rel.group(2)!);
    return rel.group(1) == '-' ? -v : v;
  }
  final t = parseClock(s);
  if (t == null) return null;
  var off = t - start;
  // Übungen über Mitternacht: 00:30 bei Beginn 23:00 ist +90, nicht −1350.
  if (off < -12 * 60) off += 1440;
  if (off > 12 * 60) off -= 1440;
  return off;
}

/// „19:15“, „19.15“, „1915“, „9“ → Minuten nach Mitternacht.
int? parseClock(String input) {
  final s = input.trim();
  final m = RegExp(r'^(\d{1,2})(?:[:.]?(\d{2}))?$').firstMatch(s);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2) ?? '0');
  if (h > 23 || min > 59) return null;
  return h * 60 + min;
}

const _weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
const _months = ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'];

String date(DateTime d) => '${two(d.day)}.${two(d.month)}.${d.year}';
String dateLong(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day}. ${_months[d.month - 1]} ${d.year}';
String monthShort(DateTime d) => _months[d.month - 1];
