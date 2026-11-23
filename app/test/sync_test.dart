import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/sync/server_client.dart';
import 'package:uebungsplaner/sync/sync_service.dart';
import 'package:uebungsplaner_server/server.dart';

/// Zwei Geräte gleichen über einen echten Server (im Test gestartet) ab.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late HttpServer server;
  late String url;
  late Repositories a, b;
  late Session sa, sb;

  setUp(() async {
    server = await io.serve(Api(Store.memory()).handler, InternetAddress.loopbackIPv4, 0);
    url = 'http://127.0.0.1:${server.port}';
    a = Repositories(AppDatabase(NativeDatabase.memory()));
    b = Repositories(AppDatabase(NativeDatabase.memory()));
    sa = Session(a);
    sb = Session(b);
  });

  tearDown(() async {
    sa.dispose();
    sb.dispose();
    await a.db.close();
    await b.db.close();
    await server.close(force: true);
  });

  test('Einrichten, Daten übertragen, Änderungen in beide Richtungen', () async {
    await a.settings.set(SettingsRepository.orgName, 'FF Musterstadt');
    final agt = await a.qualifications.add('AGT');
    await a.persons.save(PersonInput(lastName: 'Becker', firstName: 'Jonas', qualificationIds: {agt}));
    final ex = await a.exercises.create(ExerciseInput(title: 'Atemschutz', date: DateTime(2027, 2, 1), startMinutes: 1140), safetyChecklist: ['GBU']);

    // Gerät A richtet den Server ein und lädt seine Daten hoch.
    await sa.connect(url: url, username: 'admin', password: 'geheim123', displayName: 'Admin', setup: true);
    expect(sa.state, SyncState.idle);

    // Admin legt einen Planer an; Gerät B meldet sich an und bekommt alles.
    final planer = await sa.client!.createUser(username: 'planer', displayName: 'Lena Schulz', password: 'passwort1', role: 'planer');
    expect(planer.role, 'planer');
    await sb.connect(url: url, username: 'planer', password: 'passwort1');
    expect(await b.settings.get(SettingsRepository.orgName), 'FF Musterstadt');
    final persons = await b.persons.all();
    expect(persons.single.displayName, 'Becker, Jonas');
    expect(persons.single.qualifications.single.name, 'AGT');
    final d = (await b.exercises.detail(ex))!;
    expect(d.checks.single.description, 'GBU');

    // B ändert, A holt ab.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await b.exercises.setScenario(ex, 'PKW gegen Baum');
    await sb.syncNow();
    await sa.syncNow();
    expect((await a.exercises.detail(ex))!.exercise.scenario, 'PKW gegen Baum');

    // Löschen wird übertragen.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await a.persons.delete(persons.single.person.id);
    await sa.syncNow();
    await sb.syncNow();
    expect(await b.persons.all(), isEmpty);
  });

  test('Planer darf nicht freigeben, TL schon', () async {
    final ex = await a.exercises.create(ExerciseInput(title: 'Übung', date: DateTime(2027, 2, 1), startMinutes: 1140));
    await sa.connect(url: url, username: 'admin', password: 'geheim123', setup: true);
    await sa.client!.createUser(username: 'planer', displayName: 'Planer', password: 'passwort1', role: 'planer');
    await sa.client!.createUser(username: 'wf', displayName: 'Wehrführer', password: 'passwort1', role: 'tl');
    await sb.connect(url: url, username: 'planer', password: 'passwort1');
    expect(sb.canApprove, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await b.exercises.setStatus(ex, ExerciseStatus.approved, approvedBy: 'Planer');
    await sb.syncNow();
    expect(sb.lastRejected.single['reason'], contains('Freigabe'));
    await sa.syncNow();
    expect((await a.exercises.detail(ex))!.exercise.status, ExerciseStatus.draft);

    // Gerät B meldet sich als Wehrführer an und gibt frei.
    await sb.logout();
    await sb.login('wf', 'passwort1');
    expect(sb.canApprove, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await b.exercises.setStatus(ex, ExerciseStatus.approved, approvedBy: 'Wehrführer');
    await sb.syncNow();
    await sa.syncNow();
    expect((await a.exercises.detail(ex))!.exercise.approvedBy, 'Wehrführer');
  });

  test('Falsches Passwort und Server nicht erreichbar', () async {
    await sa.connect(url: url, username: 'admin', password: 'geheim123', setup: true);
    expect(() => sb.connect(url: url, username: 'admin', password: 'falsch'), throwsA(isA<ServerException>()));
    expect(() => ServerClient('127.0.0.1:1').status(), throwsA(isA<ServerException>().having((e) => e.status, 'status', 0)));
  });

  test('Trennen: zurück in den Lokalbetrieb, Daten bleiben', () async {
    await a.persons.save(PersonInput(lastName: 'Wolf'));
    await sa.connect(url: url, username: 'admin', password: 'geheim123', setup: true);
    await sa.disconnect();
    expect(sa.state, SyncState.local);
    expect(sa.networked, isFalse);
    expect((await a.persons.all()).single.person.lastName, 'Wolf');
    final restored = Session(a);
    await restored.restore();
    expect(restored.networked, isFalse);
  });
}
