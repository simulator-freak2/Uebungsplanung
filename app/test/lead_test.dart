import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/lead_functions.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/data/template_io.dart';
import 'package:uebungsplaner/pdf/exercise_pdf.dart';
import 'package:uebungsplaner/sync/sync_service.dart';
import 'package:uebungsplaner_server/server.dart';

import 'documents_test.dart' show testFonts;

/// Führungs- und Sonderfunktionen je Übung und das Organigramm.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Repositories repo;
  setUp(() => repo = Repositories(AppDatabase(NativeDatabase.memory())));
  tearDown(() => repo.db.close());

  Future<String> newExercise() => repo.exercises.create(ExerciseInput(title: 'Großübung', date: DateTime(2027, 5, 1), startMinutes: 1140));
  Future<ExerciseDetail> detail(String id) async => (await repo.exercises.detail(id))!;

  test('Jede Übung beginnt mit Einsatzleiter / Einheitsführer', () async {
    final zf = await repo.qualifications.add('Zugführer');
    await repo.vehicles.addFunction(null, 'Einsatzleiter', zf); // Vorlage aus den Stammdaten
    final id = await newExercise();
    final d = await detail(id);
    expect(d.commandLeads.single.name, defaultLeadName);
    expect(d.commandLeads.single.id, defaultLeadId(id));
    expect(d.commandLeads.single.requiredQualificationId, zf);
    expect(d.commandLeads.single.parentId, isNull);

    // Gelöscht bleibt gelöscht, auch wenn die Vorgabe erneut geprüft wird.
    await repo.exercises.deleteLead(id, defaultLeadId(id));
    await repo.exercises.ensureDefaultLead(id);
    expect((await detail(id)).commandLeads, isEmpty);
  });

  test('Frei anlegen, gleiche Namen, unterstellen, löschen rückt nach oben', () async {
    final id = await newExercise();
    final el = defaultLeadId(id);
    final zf = await repo.exercises.saveLead(id, LeadInput(name: 'Zugführer', parentId: el));
    final gf1 = await repo.exercises.saveLead(id, LeadInput(name: 'Gruppenführer', parentId: zf));
    final gf2 = await repo.exercises.saveLead(id, LeadInput(name: 'Gruppenführer', parentId: zf));
    var d = await detail(id);
    expect(d.leads.where((l) => l.name == 'Gruppenführer').length, 2);
    expect([for (final (l, depth) in leadsInTreeOrder(d.commandLeads)) '$depth ${l.name}'], [
      '0 $defaultLeadName',
      '1 Zugführer',
      '2 Gruppenführer',
      '2 Gruppenführer',
    ]);

    // Kein Ring: Zugführer kann nicht seinem Gruppenführer unterstellt werden.
    await repo.exercises.saveLead(id, LeadInput(id: zf, name: 'Zugführer', parentId: gf1));
    expect((await detail(id)).leads.firstWhere((l) => l.id == zf).parentId, el);
    expect(descendantsOf(el, d.commandLeads), {zf, gf1, gf2});

    final p = await repo.persons.save(PersonInput(lastName: 'Hahn'));
    await repo.exercises.assign(id, functionId: zf, personId: p);
    await repo.exercises.deleteLead(id, zf);
    d = await detail(id);
    expect(d.leads.map((l) => l.id), isNot(contains(zf)));
    expect(d.leads.where((l) => l.name == 'Gruppenführer').every((l) => l.parentId == el), isTrue);
    expect(d.personsByFunction.containsKey(zf), isFalse);
  });

  test('Funkrufname wird im Funkplan geführt und bleibt synchron', () async {
    final id = await newExercise();
    final el = defaultLeadId(id);
    await repo.exercises.saveLead(id, LeadInput(id: el, name: defaultLeadName, callSign: 'Florian Musterstadt 1/10-1'));
    var d = await detail(id);
    final r = d.radio.single;
    expect(r.callSign, 'Florian Musterstadt 1/10-1');
    expect(r.task, defaultLeadName);
    expect(d.commandLeads.single.radioEntryId, r.id);

    // Änderung im Funkplan erscheint im Organigramm.
    await repo.documents.saveRadio(id, id: r.id, callSign: 'Florian Musterstadt 1/10-2', network: 'bos_digital');
    d = await detail(id);
    var org = buildOrgChart(d, vehicles: await repo.vehicles.watchAllDetails().first, persons: const {});
    expect(org.single.callSign, 'Florian Musterstadt 1/10-2');

    // Änderung an der Führungsfunktion ändert den verknüpften Eintrag.
    await repo.exercises.saveLead(id, LeadInput(id: el, name: defaultLeadName, callSign: 'Kater 1'));
    d = await detail(id);
    expect(d.radio.single.callSign, 'Kater 1');

    // Vorhandener Rufname wird verknüpft statt doppelt angelegt.
    await repo.documents.saveRadio(id, callSign: 'Florian Musterstadt 2/46-1', network: 'bos_digital');
    await repo.exercises.saveLead(id, LeadInput(name: 'Gruppenführer', parentId: el, callSign: 'florian musterstadt 2/46-1'));
    d = await detail(id);
    expect(d.radio.length, 2);
  });

  test('Organigramm: Person aus Besetzung, Fahrzeug fest oder aus Besetzung, Funkrufname vom Fahrzeug', () async {
    final gfQ = await repo.qualifications.add('Gruppenführer');
    final hlf = await repo.vehicles.save(VehicleInput(name: 'HLF 20', callSign: 'Florian Musterstadt 1/46-1'));
    final rw = await repo.vehicles.save(VehicleInput(name: 'RW', callSign: 'Florian Musterstadt 1/52-1'));
    final hlfGf = await repo.vehicles.addFunction(hlf, 'Gruppenführer', gfQ);
    final becker = await repo.persons.save(PersonInput(lastName: 'Becker', qualificationIds: {gfQ}));
    final krueger = await repo.persons.save(PersonInput(lastName: 'Krüger'));
    final hahn = await repo.persons.save(PersonInput(lastName: 'Hahn'));
    final id = await newExercise();
    final el = defaultLeadId(id);
    await repo.exercises.addVehicle(id, hlf);
    await repo.exercises.addVehicle(id, rw);
    await repo.documents.saveRadio(id, callSign: 'Florian Musterstadt 1/52-1', device: 'RW', network: 'bos_digital');
    await repo.exercises.saveLead(id, LeadInput(id: el, name: defaultLeadName, callSign: 'Florian Musterstadt 1/10-1'));
    final gf = await repo.exercises.saveLead(id, LeadInput(name: 'Gruppenführer', parentId: el, qualificationId: gfQ));
    final ff = await repo.exercises.saveLead(id, LeadInput(name: 'Fahrzeugführer', parentId: el, vehicleId: rw, qualificationId: gfQ));
    await repo.exercises.assign(id, functionId: el, personId: hahn);
    await repo.exercises.assign(id, functionId: hlfGf, personId: becker); // Besetzung HLF
    await repo.exercises.assign(id, functionId: gf, personId: becker);
    await repo.exercises.assign(id, functionId: ff, personId: krueger);

    final vehicles = await repo.vehicles.watchAllDetails().first;
    final persons = {for (final p in await repo.persons.all()) p.person.id: p};
    final org = buildOrgChart(await detail(id), vehicles: vehicles, persons: persons);
    final top = org.single;
    expect(top.name, defaultLeadName);
    expect(top.personName, 'Hahn');
    expect(top.callSign, 'Florian Musterstadt 1/10-1');
    expect(top.vehicleName, isNull);
    expect(top.depth, 2);
    final (g, f) = (top.children[0], top.children[1]);
    expect(g.personName, 'Becker');
    expect(g.vehicleName, 'HLF 20');
    expect(g.vehicleFromCrew, isTrue);
    expect(g.callSign, 'Florian Musterstadt 1/46-1'); // vom Fahrzeug
    expect(g.qualificationMissing, isFalse);
    expect(f.vehicleName, 'RW');
    expect(f.vehicleFromCrew, isFalse);
    expect(f.callSign, 'Florian Musterstadt 1/52-1'); // aus dem Funkplan
    expect(f.qualificationMissing, isTrue);

    // Fahrzeug aus der Übung nehmen: feste Zuordnung entfällt.
    final d = await detail(id);
    await repo.exercises.removeVehicle(id, d.vehicles.firstWhere((v) => v.vehicleId == rw), const []);
    expect((await detail(id)).leads.firstWhere((l) => l.id == ff).vehicleId, isNull);

    // PDF mit Organigramm lässt sich erzeugen.
    final bytes = await buildExerciseMap(
      ExerciseMapData(
        organisation: 'FF Musterstadt',
        detail: await detail(id),
        vehicles: vehicles,
        persons: persons,
        qualificationNames: const {},
        alarmSheets: const [],
        approvalRequired: false,
      ),
      {MapSection.crew, MapSection.orgChart},
      fonts: await testFonts(),
    );
    expect(bytes.length, greaterThan(1000));
  });

  test('Kopie und Vorlagendatei übernehmen die Führungsstruktur ohne Personen', () async {
    final id = await newExercise();
    final el = defaultLeadId(id);
    await repo.exercises.saveLead(id, LeadInput(id: el, name: defaultLeadName, callSign: 'Kater 1'));
    final zf = await repo.exercises.saveLead(id, LeadInput(name: 'Zugführer', parentId: el));
    await repo.exercises.saveLead(id, LeadInput(name: 'Gruppenführer', parentId: zf));
    await repo.exercises.assign(id, functionId: zf, personId: await repo.persons.save(PersonInput(lastName: 'Hahn')));

    final copy = await repo.exercises.copy(id, asTemplate: true);
    final c = await detail(copy);
    expect(c.commandLeads.length, 3);
    expect(c.runLeads.length, runDefaults.length);
    expect(c.assignments, isEmpty);
    final cz = c.leads.firstWhere((l) => l.name == 'Zugführer');
    expect(cz.parentId, defaultLeadId(copy));
    expect(c.leads.firstWhere((l) => l.name == 'Gruppenführer').parentId, cz.id);
    expect(c.radio.single.id, c.leads.firstWhere((l) => l.id == defaultLeadId(copy)).radioEntryId);

    final other = Repositories(AppDatabase(NativeDatabase.memory()));
    addTearDown(other.db.close);
    final imported = (await importTemplate(other, await exportTemplate(repo, id))).exerciseId;
    final i = (await other.exercises.detail(imported))!;
    expect([for (final (l, depth) in leadsInTreeOrder(i.commandLeads)) '$depth ${l.name}'], ['0 $defaultLeadName', '1 Zugführer', '2 Gruppenführer']);
    expect(i.runLeads.map((l) => l.name), [for (final r in runDefaults) r.$2]);
    expect(i.radio.single.callSign, 'Kater 1');
    expect(i.commandLeads.first.radioEntryId, i.radio.single.id);
  });

  test('Umstellung von Version 5: besetzte Führungsfunktionen wandern in die Übung', () async {
    final dir = await Directory.systemTemp.createTemp('lead');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var r = Repositories(db);
    final zfQ = await r.qualifications.add('Zugführer');
    final elFn = await r.vehicles.addFunction(null, 'Einsatzleiter', zfQ);
    final mime = await r.vehicles.addFunction(null, 'Mimenbetreuung', null);
    await r.vehicles.addFunction(null, 'Übungsleitung', null); // nicht besetzt
    final p = await r.persons.save(PersonInput(lastName: 'Hahn'));
    final id = await r.exercises.create(ExerciseInput(title: 'Alt', date: DateTime(2026), startMinutes: 1140));
    final empty = await r.exercises.create(ExerciseInput(title: 'Leer', date: DateTime(2026), startMinutes: 1140));
    await r.exercises.assign(id, functionId: elFn, personId: p);
    await r.exercises.assign(id, functionId: mime, personId: p);
    // Stand von Version 5 herstellen.
    await db.customStatement('DROP TABLE exercise_lead_functions');
    await db.customStatement('PRAGMA user_version = 5');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    r = Repositories(db);
    final d = (await r.exercises.detail(id))!;
    expect([for (final (l, depth) in leadsInTreeOrder(d.commandLeads)) '$depth ${l.name}'], ['0 Einsatzleiter']);
    expect(d.commandLeads.first.id, defaultLeadId(id));
    expect(d.commandLeads.first.requiredQualificationId, zfQ);
    // Mimenbetreuung landet in der Übungsdurchführung, auf der festen ID der Vorgabe.
    expect(d.runLeads.map((l) => l.name), ['Mimenbetreuung', 'Übungsleitung', 'Übungsbeobachter', 'Sicherheitsbeauftragter']);
    expect(d.personsByFunction, {defaultLeadId(id): [p], runDefaultId(id, 'mime'): [p]});
    expect((await r.exercises.detail(empty))!.commandLeads.single.name, defaultLeadName);
    await db.close();
  });

  test('Führungsfunktionen werden über den Server abgeglichen', () async {
    final server = await io.serve(Api(Store.memory()).handler, InternetAddress.loopbackIPv4, 0);
    final url = 'http://127.0.0.1:${server.port}';
    final b = Repositories(AppDatabase(NativeDatabase.memory()));
    final sa = Session(repo), sb = Session(b);
    addTearDown(() async {
      sa.dispose();
      sb.dispose();
      await b.db.close();
      await server.close(force: true);
    });
    final id = await newExercise();
    await repo.exercises.saveLead(id, LeadInput(name: 'Zugführer', parentId: defaultLeadId(id), callSign: 'Kater 2'));
    await sa.connect(url: url, username: 'admin', password: 'geheim123', displayName: 'Admin', setup: true);
    await sb.connect(url: url, username: 'admin', password: 'geheim123');
    final d = (await b.exercises.detail(id))!;
    expect(d.commandLeads.map((l) => l.name), [defaultLeadName, 'Zugführer']);
    expect(d.commandLeads.last.parentId, defaultLeadId(id));
    expect(d.radio.single.id, d.commandLeads.last.radioEntryId);
    expect(d.runLeads.length, runDefaults.length);
  });

  test('Übungsdurchführung: Vorgaben, mehrere Beobachter, nicht im Organigramm', () async {
    final id = await newExercise();
    var d = await detail(id);
    expect(d.runLeads.map((l) => l.name), ['Übungsleitung', 'Übungsbeobachter', 'Mimenbetreuung', 'Sicherheitsbeauftragter']);
    expect(d.runLeads.every((l) => l.parentId == null), isTrue);

    final beo2 = await repo.exercises.saveLead(id, LeadInput(name: 'Übungsbeobachter', kind: LeadKind.run, parentId: defaultLeadId(id)));
    final foto = await repo.exercises.saveLead(id, LeadInput(name: 'Fotograf', kind: LeadKind.run));
    final a = await repo.persons.save(PersonInput(lastName: 'A'));
    final b = await repo.persons.save(PersonInput(lastName: 'B'));
    await repo.exercises.assign(id, functionId: runDefaultId(id, 'beo'), personId: a);
    await repo.exercises.assign(id, functionId: beo2, personId: b);
    d = await detail(id);
    expect(d.runLeads.where((l) => l.name == 'Übungsbeobachter').length, 2);
    expect(d.runLeads.firstWhere((l) => l.id == beo2).parentId, isNull); // keine Unterstellung
    expect(d.runLeads.map((l) => l.id), contains(foto));
    expect(d.personsByFunction[beo2], [b]);

    // Nicht im Organigramm und nicht als Vorgesetzte wählbar.
    final org = buildOrgChart(d, vehicles: await repo.vehicles.watchAllDetails().first, persons: const {});
    expect(org.single.name, defaultLeadName);
    expect(org.single.children, isEmpty);
    final zf = await repo.exercises.saveLead(id, LeadInput(name: 'Zugführer', parentId: beo2));
    expect((await detail(id)).leads.firstWhere((l) => l.id == zf).parentId, isNull);

    // Gelöschte Vorgabe kommt nicht wieder.
    await repo.exercises.deleteLead(id, runDefaultId(id, 'sb'));
    await ensureRunDefaults(repo.db, id);
    expect((await detail(id)).runLeads.any((l) => l.name == 'Sicherheitsbeauftragter'), isFalse);
  });

  test('Umstellung von Version 6: Durchführungs-Funktionen bekommen ihre Rubrik', () async {
    final id = await newExercise();
    final mime = await repo.exercises.saveLead(id, LeadInput(name: 'Mimenbetreuung', parentId: defaultLeadId(id)));
    // Stand von Version 6 nachbilden: nur Führung, keine Vorgaben der Durchführung.
    for (final r in runDefaults) {
      await repo.db.customStatement("DELETE FROM exercise_lead_functions WHERE id = '${runDefaultId(id, r.$1)}'");
    }
    await migrateRunFunctions(repo.db);
    final d = await detail(id);
    expect(d.commandLeads.map((l) => l.name), [defaultLeadName]);
    expect(d.runLeads.firstWhere((l) => l.id == mime).parentId, isNull);
    expect(d.runLeads.where((l) => l.name == 'Mimenbetreuung').length, 1);
    expect(d.runLeads.length, runDefaults.length);
  });
}
