import 'package:flutter_test/flutter_test.dart';
import 'package:uebungsplaner/util/time.dart';

void main() {
  const start = 19 * 60; // 19:00

  test('Uhrzeit und relativ formatieren', () {
    expect(clock(start + 15), '19:15');
    expect(clock(23 * 60 + 90), '00:30');
    expect(relative(0), 'Beginn');
    expect(relative(15), '+15 Min.');
    expect(relative(-5), '−5 Min.');
    expect(relative(90), '+1:30 Std.');
    expect(relative(120), '+2 Std.');
    expect(formatOffset(25, start: start, relativeMode: false), '19:25');
    expect(formatOffset(25, start: start, relativeMode: true), '+25 Min.');
  });

  test('Eingaben lesen: Uhrzeit oder Minuten ab Beginn', () {
    expect(parseOffset('19:15', start: start), 15);
    expect(parseOffset('19.40', start: start), 40);
    expect(parseOffset('2030', start: start), 90);
    expect(parseOffset('+15', start: start), 15);
    expect(parseOffset('15', start: start), 15);
    expect(parseOffset('-5', start: start), -5);
    expect(parseOffset('+20 min', start: start), 20);
    expect(parseOffset('18:50', start: start), -10);
    expect(parseOffset('abc', start: start), isNull);
    expect(parseOffset('25:00', start: start), isNull);
  });

  test('Übung über Mitternacht', () {
    expect(parseOffset('00:30', start: 23 * 60), 90);
  });
}
