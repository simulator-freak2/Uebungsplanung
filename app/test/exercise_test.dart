import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/lead_functions.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/features/exercises/tab_alarm.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Repositories repo;
  setUp(() => repo = Repositories(AppDatabase(NativeDatabase.memory())));
  tearDown(() => repo.db.close());

  Future<String> newExercise() => repo.exercises.create(
        ExerciseInput(title: 'VU eingeklemmt', date: DateTime(2027, 3, 4), startMinutes: 19 * 60, location: 'Bauhof'),
        safetyChecklist: ['GBU erstellt', 'Sicherheitsbeauftragter benannt'],
      );

  test('Neue Übung übernimmt die Sicherheits-Checkliste', () async {
    final id = await newExercise();
    final d = (await repo.exercises.detail(id))!;
    expect(d.checks.map((c) => c.description), ['GBU erstellt', 'Sicherheitsbeauftragter benannt']);
    expect(d.safetyComplete, isFalse);
    for (final c in d.checks) {
      await repo.exercises.setCheck(c.id, true);
    }
    expect((await repo.exercises.detail(id))!.safetyComplete, isTrue);
  });

  test('Freigabe setzt Name und Zeitpunkt, Zurücksetzen löscht sie', () async {
    final id = await newExercise();
    await repo.exercises.setStatus(id, ExerciseStatus.submitted);
    await repo.exercises.setStatus(id, ExerciseStatus.approved, approvedBy: 'Hahn, Felix');
    var e = (await repo.exercises.detail(id))!.exercise;
    expect(e.status, ExerciseStatus.approved);
    expect(e.approvedBy, 'Hahn, Felix');
    expect(e.approvedAt, isNotNull);
    await repo.exercises.setStatus(id, ExerciseStatus.draft);
    e = (await repo.exercises.detail(id))!.exercise;
    expect(e.approvedBy, isNull);
  });

  test('Ablauf und Lernziele', () async {
    final id = await newExercise();
    await repo.exercises.savePhase(id, offset: 30, text: 'Rettung');
    await repo.exercises.savePhase(id, offset: 0, text: 'Einweisung');
    await repo.exercises.setGoals(id, ['Absichern', ' ', 'Retten']);
    final d = (await repo.exercises.detail(id))!;
    expect(d.phases.map((p) => p.description), ['Einweisung', 'Rettung']);
    expect(d.goals, ['Absichern', 'Retten']);
  });

  test('Besetzung: setzen, tauschen, mehrere Funktionen je Person', () async {
    final id = await newExercise();
    final vid = await repo.vehicles.save(VehicleInput(name: 'HLF 20'));
    final gf = await repo.vehicles.addFunction(vid, 'Gruppenführer', null);
    final ma = await repo.vehicles.addFunction(vid, 'Maschinist', null);
    final el = defaultLeadId(id);
    final a = await repo.persons.save(PersonInput(lastName: 'A'));
    final b = await repo.persons.save(PersonInput(lastName: 'B'));
    await repo.exercises.addVehicle(id, vid);
    await repo.exercises.addVehicle(id, vid); // doppelt wird ignoriert

    await repo.exercises.assign(id, functionId: gf, personId: a);
    await repo.exercises.assign(id, functionId: ma, personId: b);
    await repo.exercises.assign(id, functionId: el, personId: a); // A hat zwei Funktionen
    var d = (await repo.exercises.detail(id))!;
    expect(d.vehicles.length, 1);
    expect(d.personsByFunction, {gf: [a], ma: [b], el: [a]});

    // A von Gruppenführer auf Maschinist ziehen → B wechselt auf Gruppenführer
    await repo.exercises.assign(id, functionId: ma, personId: a, fromFunctionId: gf);
    d = (await repo.exercises.detail(id))!;
    expect(d.personsByFunction[gf], [b]);
    expect(d.personsByFunction[ma], [a]);

    // Aus der Personalliste auf eine besetzte Funktion → ersetzt
    final c = await repo.persons.save(PersonInput(lastName: 'C'));
    await repo.exercises.assign(id, functionId: ma, personId: c);
    d = (await repo.exercises.detail(id))!;
    expect(d.personsByFunction[ma], [c]);

    await repo.exercises.unassign(id, gf);
    await repo.exercises.removeVehicle(id, d.vehicles.single, [gf, ma]);
    d = (await repo.exercises.detail(id))!;
    expect(d.vehicles, isEmpty);
    expect(d.personsByFunction, {el: [a]});
  });

  test('Alarmierungsplan und Alarmmeldung', () async {
    final id = await newExercise();
    final kw = await repo.keywords.save(KeywordInput(code: 'TH 2', description: 'VU P eingeklemmt', specialRights: true));
    final d0 = (await repo.exercises.detail(id))!.exercise;
    await repo.exercises.update(ExerciseInput(id: id, title: d0.title, date: d0.date, startMinutes: d0.startMinutes, location: d0.location, keywordId: kw));
    final hlf = await repo.vehicles.save(VehicleInput(name: 'HLF 20', callSign: 'Florian 1/46-1'));
    await repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'HLF 20', vehicleId: hlf, alarmOffset: 15, departOffset: 20, arriveOffset: 25));
    await repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'RW', alarmOffset: 15));
    await repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'Angriffstrupp', kind: 'trupp', alarmOffset: 15));
    await repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'LF 10', alarmOffset: 40, note: 'Nachalarmierung'));

    var d = (await repo.exercises.detail(id))!;
    expect(d.firstAlarm, 15);
    final vehicles = await repo.vehicles.watchAll().first;
    var sheet = alarmSheetFor(d, vehicles, 'FF Musterstadt');
    expect(sheet.keyword, 'TH 2');
    expect(sheet.alarmTime, '19:15');
    expect(sheet.address, 'Bauhof');
    expect(sheet.vehicles, 'HLF 20 (Florian 1/46-1), RW');
    expect(sheet.specialRights, isTrue);

    // Zwei Alarmierungszeitpunkte → zwei Alarmmeldungen (Trupps zählen nicht)
    final sheets = alarmSheetsFor(d, vehicles, 'FF Musterstadt');
    expect(sheets.length, 2);
    expect(sheets[1].alarmTime, '19:40');
    expect(sheets[1].vehicles, 'LF 10');
    expect(sheets[1].note, 'Nachalarmierung');
    expect(sheets[1].alarmLabel, '2. Alarmierung (2 von 2)');

    await repo.exercises.setAlarm(id, address: 'Industriestraße 12', reporter: 'Zeuge', specialRights: false, vehicles: null);
    d = (await repo.exercises.detail(id))!;
    sheet = alarmSheetFor(d, vehicles, 'FF Musterstadt');
    expect(sheet.address, 'Industriestraße 12');
    expect(sheet.reporter, 'Zeuge');
    expect(sheet.specialRights, isFalse);
  });

  test('Migration von Version 1 legt die Übungstabellen an', () async {
    // Version 1 simulieren: Übungstabellen löschen und user_version zurücksetzen.
    final raw = NativeDatabase.memory(setup: (db) {
      db.execute('CREATE TABLE settings ("key" TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
      db.execute('CREATE TABLE crew_functions (id TEXT NOT NULL PRIMARY KEY, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, '
          'vehicle_id TEXT NULL, name TEXT NOT NULL, required_qualification_id TEXT NULL, sort_order INTEGER NOT NULL DEFAULT 0)');
      db.execute('PRAGMA user_version = 1');
    });
    final db = AppDatabase(raw);
    final r = Repositories(db);
    final id = await r.exercises.create(ExerciseInput(title: 'Test', date: DateTime(2027), startMinutes: 1140));
    final d = (await r.exercises.detail(id))!;
    expect(d.exercise.title, 'Test');
    expect(d.leads.single.name, defaultLeadName);
    await db.close();
  });
}
