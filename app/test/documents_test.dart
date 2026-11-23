import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/demo_data.dart';
import 'package:uebungsplaner/data/profile.dart';
import 'package:uebungsplaner/data/documents_repository.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/data/template_io.dart';
import 'package:uebungsplaner/features/exercises/exercise_actions.dart';
import 'package:uebungsplaner/pdf/alarm_pdf.dart';
import 'package:uebungsplaner/pdf/exercise_pdf.dart';

Future<PdfFonts> testFonts() async => PdfFonts(
      pw.Font.ttf((await File('assets/fonts/DejaVuSans.ttf').readAsBytes()).buffer.asByteData()),
      pw.Font.ttf((await File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytes()).buffer.asByteData()),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Repositories repo;
  setUp(() => repo = Repositories(AppDatabase(NativeDatabase.memory())));
  tearDown(() => repo.db.close());

  /// Vollständig ausgearbeitete Beispielübung.
  Future<String> fullExercise() async {
    final hlf = await repo.vehicles.save(VehicleInput(name: 'HLF 20', callSign: 'Florian 1/46-1'));
    final gf = await repo.vehicles.addFunction(hlf, 'Gruppenführer', null);
    final pattern = await repo.vehicles.addPattern(hlf, 'Staffel (1/5)');
    await repo.vehicles.setPatternFunction(pattern, gf, true);
    final becker = await repo.persons.save(PersonInput(lastName: 'Becker', firstName: 'Jonas'));
    final kw = await repo.keywords.save(KeywordInput(code: 'TH 2', description: 'VU P eingeklemmt'));
    final id = await repo.exercises.create(
      ExerciseInput(title: 'VU eingeklemmt', date: DateTime(2027, 3, 4), startMinutes: 19 * 60, location: 'Bauhof', keywordId: kw, category: 'praxis'),
      safetyChecklist: ['GBU erstellt'],
    );
    final ex = repo.exercises, docs = repo.documents;
    await ex.setGoals(id, ['Absichern', 'Retten']);
    await ex.setScenario(id, 'PKW gegen Baum.');
    await ex.savePhase(id, offset: 0, text: 'Einweisung');
    await ex.addVehicle(id, hlf, patternId: pattern);
    await ex.assign(id, functionId: gf, personId: becker);
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'HLF 20', vehicleId: hlf, alarmOffset: 15, departOffset: 20, arriveOffset: 25));
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'LF 10', alarmOffset: 40, note: 'Nachalarmierung'));
    await docs.saveRadio(id, callSign: 'Florian 1/46-1', device: 'HLF 20', network: 'bos_digital', channel: 'DMO 307', task: 'Rettung');
    await docs.saveRole(id, RoleCardInput(
      number: 1,
      name: 'Thomas Berger',
      birthDate: DateTime(1981, 5, 14),
      injuries: 'Unterschenkelfraktur rechts',
      escalation: const [
        EscalationStage(label: 'Stufe 1', trigger: 'Beginn', behavior: 'Ansprechbar, stöhnt'),
        EscalationStage(label: 'Stufe 2', behavior: ''),
      ],
    ));
    await docs.saveMaterial(id, name: 'Rettungssatz', location: 'RW', quantity: '1');
    await docs.addObservation(id, 'Absicherung der Einsatzstelle');
    final o = (await ex.detail(id))!.observations.single;
    await docs.updateObservation(o.id, rating: '+', note: 'nach 4 Min.');
    await docs.setDebrief(id, good: ['Absicherung schnell'], bad: ['Lagemeldung spät'], participants: '12 Einsatzkräfte');
    await docs.saveLesson(id, description: 'Lagemeldung üben', responsible: 'Krüger');
    return id;
  }

  test('Unterlagen speichern und laden', () async {
    final id = await fullExercise();
    final d = (await repo.exercises.detail(id))!;
    expect(d.radio.single.channel, 'DMO 307');
    expect(d.roles.single.name, 'Thomas Berger');
    expect(ageOn(d.roles.single, d.exercise.date), 45);
    expect(decodeEscalation(d.roles.single.escalation).length, 1, reason: 'leere Stufe wird nicht gespeichert');
    expect(d.material.single.name, 'Rettungssatz');
    expect(d.observations.single.rating, '+');
    expect(d.debriefGood, ['Absicherung schnell']);
    expect(d.lessons.single.status, 'offen');
    expect(d.alarmGroups.map((g) => g.title), ['Erstalarm', '2. Alarmierung']);
  });

  test('Erkenntnisse: offen → eingeplant → erledigt', () async {
    final id = await fullExercise();
    var open = await repo.documents.watchOpenLessons().first;
    expect(open.single.exercise.id, id);
    await repo.documents.setLessonStatus(open.single.lesson.id, 'eingeplant');
    open = await repo.documents.watchOpenLessons().first;
    expect(open.single.lesson.status, 'eingeplant');
    await repo.documents.setLessonStatus(open.single.lesson.id, 'erledigt');
    expect(await repo.documents.watchOpenLessons().first, isEmpty);
  });

  test('Als Vorlage speichern und daraus eine Übung anlegen', () async {
    final id = await fullExercise();
    final tpl = await repo.exercises.copy(id, asTemplate: true, title: 'VU Vorlage');
    expect((await repo.exercises.watchTemplates().first).single.title, 'VU Vorlage');
    expect((await repo.exercises.watchAll().first).length, 1, reason: 'Vorlagen erscheinen nicht in der Übungsliste');

    final neu = await repo.exercises.copy(tpl, asTemplate: false, date: DateTime(2027, 9, 1), title: 'VU Herbst');
    final d = (await repo.exercises.detail(neu))!;
    expect(d.exercise.date, DateTime(2027, 9, 1));
    expect(d.phases.single.description, 'Einweisung');
    expect(d.checks.single.checked, isFalse);
    expect(d.vehicles.single.patternId, isNotNull);
    expect(d.assignments, isEmpty, reason: 'keine Personen');
    expect(d.alarmPlan.length, 2);
    expect(d.radio.length, 1);
    expect(d.roles.single.name, 'Thomas Berger');
    expect(d.observations.single.rating, isNull, reason: 'keine Bewertungen');
    expect(d.lessons, isEmpty);
    expect(d.debriefGood, isEmpty);
  });

  test('Vorlage als Datei exportieren und in andere Installation importieren', () async {
    final id = await fullExercise();
    final text = await exportTemplate(repo, id);
    expect(text, isNot(contains('Becker')), reason: 'keine Personendaten in der Datei');

    final other = Repositories(AppDatabase(NativeDatabase.memory()));
    await other.vehicles.save(VehicleInput(name: 'hlf 20'));
    final result = await importTemplate(other, text);
    final d = (await other.exercises.detail(result.exerciseId))!;
    expect(d.exercise.isTemplate, isTrue);
    expect(d.vehicles.length, 1);
    expect(d.alarmPlan.firstWhere((a) => a.label == 'HLF 20').vehicleId, isNotNull);
    expect(d.roles.single.birthDate, DateTime(1981, 5, 14));
    expect(decodeEscalation(d.roles.single.escalation).single.behavior, 'Ansprechbar, stöhnt');
    expect(result.skipped, containsAll(['Alarmstichwort „TH 2“', 'Besetzungsmuster „Staffel (1/5)“ bei hlf 20']));
    await other.db.close();
  });

  test('Übungsmappe als PDF mit allen Teilen', () async {
    final id = await fullExercise();
    final d = (await repo.exercises.detail(id))!;
    final data = await loadMapData(repo, d);
    expect(data.alarmSheets.length, 2);
    final bytes = await buildExerciseMap(data, MapSection.values.toSet(), fonts: await testFonts());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = Platform.environment['MAP_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  for (final id in ['feuerwehr', 'dlrg']) {
    test('Beispieldaten ($id) laden und Mappe erzeugen', () async {
      final profile = OrgProfile.fromJson(jsonDecode(File('assets/profile/$id.json').readAsStringSync()) as Map<String, dynamic>);
      await profile.applyTo(repo);
      expect(await canLoadDemo(repo), isTrue);
      await loadDemoData(repo, profile);
      expect(await canLoadDemo(repo), isFalse);
      final all = await repo.exercises.watchAll().first;
      final full = all.firstWhere((e) => e.location != null);
      final d = (await repo.exercises.detail(full.id))!;
      expect(d.assignments, isNotEmpty);
      expect(d.roles, isNotEmpty);
      expect(d.observations, isNotEmpty);
      final bytes = await buildExerciseMap(await loadMapData(repo, d), MapSection.values.toSet(), fonts: await testFonts());
      expect(bytes.length, greaterThan(1000));
    });
  }
}
