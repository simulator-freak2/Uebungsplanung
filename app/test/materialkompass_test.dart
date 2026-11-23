import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/materialkompass/materialkompass.dart';

import '../tool/fake_materialkompass.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late HttpServer server;
  late FakeMaterialkompass fake;
  late Repositories repo;
  late MaterialkompassService mk;

  setUp(() async {
    fake = FakeMaterialkompass();
    server = await io.serve(fake.handle, InternetAddress.loopbackIPv4, 0);
    repo = Repositories(AppDatabase(NativeDatabase.memory()));
    await repo.settings.set(MkKeys.url, 'http://127.0.0.1:${server.port}/api/v1');
    await repo.settings.set(MkKeys.apiKey, 'geheim');
    mk = MaterialkompassService(repo);
  });

  tearDown(() async {
    await repo.db.close();
    await server.close(force: true);
  });

  test('Verbindung prüfen, falscher Schlüssel', () async {
    expect(await (await mk.client())!.status(), contains('FF Musterstadt'));
    await repo.settings.set(MkKeys.apiKey, 'falsch');
    expect(() async => (await mk.client())!.status(), throwsA(isA<MkException>().having((e) => e.status, 'status', 401)));
  });

  test('Abgleich: Fahrzeuge zuordnen, Status übernehmen, Material zwischenspeichern', () async {
    final hlf = await repo.vehicles.save(VehicleInput(name: 'hlf 20'));
    final rw = await repo.vehicles.save(VehicleInput(name: 'RW'));
    final r = await mk.sync();
    expect(r.vehiclesUpdated, 2);
    expect(r.unmatched.single['bezeichnung'], 'MTW');
    expect(r.material, 2);
    final vs = {for (final v in await repo.vehicles.watchAll().first) v.id: v};
    expect(vs[hlf]!.externalId, 'mk-hlf');
    expect(vs[hlf]!.callSign, 'Florian 1/46-1');
    expect(vs[rw]!.status, 'werkstatt');
    final mat = await mk.watchMaterial().first;
    expect(mat.map((m) => m.name), ['Bindemittel', 'Hydraulischer Rettungssatz']);
    expect(mat.last.location, 'RW');

    // nicht zugeordnetes Fahrzeug anlegen
    await mk.createVehicle(r.unmatched.single);
    expect((await mk.sync()).unmatched, isEmpty);

    // Material in eine Übung übernehmen
    final ex = await repo.exercises.create(ExerciseInput(title: 'VU', date: DateTime(2027, 3, 1), startMinutes: 1140));
    await mk.addToExercise(ex, mat);
    final d = (await repo.exercises.detail(ex))!;
    expect(d.material.map((m) => '${m.name}|${m.quantity}|${m.source}'), ['Bindemittel|2 Sack|materialkompass', 'Hydraulischer Rettungssatz|1|materialkompass']);
  });

  test('Reservierung: anfragen (nur einmal), Status abfragen, belegt, stornieren', () async {
    final hlfId = await repo.vehicles.save(VehicleInput(name: 'HLF 20'));
    await mk.sync();
    final ex = await repo.exercises.create(ExerciseInput(title: 'VU', date: DateTime(2027, 3, 1), startMinutes: 1140, endMinutes: 1290));
    await repo.exercises.addVehicle(ex, hlfId);
    var d = (await repo.exercises.detail(ex))!;
    final hlf = (await repo.vehicles.watchAll().first).single;

    expect(await mk.reserve(d.exercise, d.vehicles.single, hlf, user: 'j.becker'), 'angefragt');
    // erneut senden (z. B. nach Verbindungsabbruch) → keine zweite Reservierung
    await mk.reserve(d.exercise, d.vehicles.single, hlf);
    expect(fake.reservations.length, 1);
    final res = fake.reservations.values.single;
    expect(res['von'], DateTime(2027, 3, 1, 19).toIso8601String());
    expect(res['bis'], DateTime(2027, 3, 1, 21, 30).toIso8601String());
    expect(res['referenz'], 'uebungsplaner:$ex');

    fake.reservations.values.single['status'] = 'bestaetigt';
    d = (await repo.exercises.detail(ex))!;
    await mk.refresh(d);
    d = (await repo.exercises.detail(ex))!;
    expect(d.vehicles.single.reservationStatus, 'bestaetigt');

    await mk.cancel(d.vehicles.single);
    d = (await repo.exercises.detail(ex))!;
    expect(d.vehicles.single.reservationStatus, 'storniert');

    fake.busy.add('mk-hlf');
    final ex2 = await repo.exercises.create(ExerciseInput(title: 'B', date: DateTime(2027, 3, 1), startMinutes: 1140));
    await repo.exercises.addVehicle(ex2, hlfId);
    final d2 = (await repo.exercises.detail(ex2))!;
    expect(() => mk.reserve(d2.exercise, d2.vehicles.single, hlf), throwsA(isA<MkException>().having((e) => e.message, 'm', contains('belegt'))));
  });

  test('Übung über Mitternacht', () {
    final e = Exercise(
      id: 'x', updatedAt: DateTime(2027), deleted: false, title: 't', date: DateTime(2027, 12, 31), startMinutes: 22 * 60, endMinutes: 60,
      goals: '[]', status: 'entwurf', timeMode: 'uhrzeit', category: 'praxis', isTemplate: false, debriefGood: '[]', debriefBad: '[]', sketch: '[]',
    );
    final (from, to) = MaterialkompassService.window(e);
    expect(from, DateTime(2027, 12, 31, 22));
    expect(to, DateTime(2028, 1, 1, 1));
  });
}
