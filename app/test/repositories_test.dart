import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/profile.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/import/importers.dart';

OrgProfile loadProfile(String id) =>
    OrgProfile.fromJson(jsonDecode(File('assets/profile/$id.json').readAsStringSync()) as Map<String, dynamic>);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Repositories repo;

  setUp(() => repo = Repositories(AppDatabase(NativeDatabase.memory())));
  tearDown(() => repo.db.close());

  test('Profile sind gültig und vollständig', () {
    for (final id in OrgProfile.available.keys) {
      final p = loadProfile(id);
      expect(p.qualifications, isNotEmpty);
      for (final t in p.vehicleTemplates) {
        final names = t.functions.map((f) => f.$1).toSet();
        for (final pattern in t.patterns.values) {
          expect(names.containsAll(pattern), isTrue, reason: '${t.type}: Muster nennt unbekannte Funktion');
        }
        for (final (_, q) in [...t.functions, ...p.leadFunctions]) {
          if (q != null) expect(p.qualifications, contains(q), reason: '$id: Qualifikation $q fehlt im Katalog');
        }
      }
    }
  });

  test('Profil einspielen ist wiederholbar ohne Dubletten', () async {
    final p = loadProfile('feuerwehr');
    await p.applyTo(repo);
    await p.applyTo(repo);
    expect((await repo.qualifications.all()).length, p.qualifications.length);
    expect((await repo.vehicles.detail(null)).functions.length, p.leadFunctions.length);
  });

  test('Fahrzeug aus Vorlage: Funktionen, Qualifikationen und Besetzungsmuster', () async {
    final p = loadProfile('feuerwehr');
    await p.applyTo(repo);
    final hlf = p.vehicleTemplates.firstWhere((t) => t.type == 'HLF 20');
    final id = await repo.vehicles.createFromTemplate(hlf, name: 'HLF 20', callSign: 'Florian 1/46-1', ensureQualification: repo.qualifications.ensure);
    final d = await repo.vehicles.detail(id);
    expect(d.functions.map((f) => f.name).first, 'Gruppenführer');
    expect(d.functions.length, 9);
    expect(d.patterns.map((x) => x.name), ['Gruppe (1/8)', 'Staffel (1/5)', 'Trupp (1/2)']);
    expect(d.matrix[d.patterns[1].id]!.length, 6);
    final agt = (await repo.qualifications.all()).firstWhere((q) => q.name == 'Atemschutzgeräteträger');
    expect(d.functions.firstWhere((f) => f.name == 'Angriffstruppführer').requiredQualificationId, agt.id);

    // Funktion aus einem Muster nehmen und Funktion löschen
    final melder = d.functions.firstWhere((f) => f.name == 'Melder');
    await repo.vehicles.setPatternFunction(d.patterns.first.id, melder.id, false);
    expect((await repo.vehicles.detail(id)).matrix[d.patterns.first.id]!.length, 8);
    await repo.vehicles.deleteFunction(d.functions.last.id);
    final d2 = await repo.vehicles.detail(id);
    expect(d2.functions.length, 8);
    expect(d2.matrix[d.patterns.first.id]!.length, 7);

    await repo.vehicles.delete(id);
    final left = await repo.vehicles.watchAll().first;
    expect(left, isEmpty);
  });

  test('Personen speichern, Qualifikationen ändern, Qualifikation löschen', () async {
    final agt = await repo.qualifications.add('AGT');
    final ma = await repo.qualifications.add('Maschinist');
    final id = await repo.persons.save(PersonInput(lastName: 'Becker', firstName: 'Jonas', personnelNo: 'FW-12', qualificationIds: {agt, ma}));
    var all = await repo.persons.all();
    expect(all.single.displayName, 'Becker, Jonas');
    expect(all.single.qualifications.map((q) => q.name), ['AGT', 'Maschinist']);

    await repo.persons.save(PersonInput(id: id, lastName: 'Becker', firstName: 'Jonas', qualificationIds: {ma}));
    all = await repo.persons.all();
    expect(all.single.qualifications.map((q) => q.name), ['Maschinist']);
    expect(all.single.person.personnelNo, isNull);

    await repo.qualifications.delete(ma);
    all = await repo.persons.all();
    expect(all.single.qualifications, isEmpty);
  });

  test('Excel-Import ergänzt vorhandene Personen statt Dubletten', () async {
    await repo.persons.save(PersonInput(lastName: 'Wolf', firstName: 'Sara', personnelNo: '71'));
    final r1 = await importPersons(repo, [
      PersonImportRow(lastName: 'Wolf', firstName: 'Sara', personnelNo: '71', qualifications: ['Truppführer'], youth: false),
      PersonImportRow(lastName: 'Braun', firstName: 'Leon', qualifications: ['Jugendflamme 2'], youth: true),
    ]);
    expect((r1.created, r1.updated), (1, 1));
    expect(r1.newQualifications, ['Truppführer', 'Jugendflamme 2']);
    final r2 = await importPersons(repo, [
      PersonImportRow(lastName: 'braun', firstName: 'leon', qualifications: ['AGT'], youth: false),
    ]);
    expect((r2.created, r2.updated), (0, 1));
    final braun = (await repo.persons.all()).firstWhere((p) => p.person.lastName == 'Braun');
    expect(braun.qualifications.map((q) => q.name).toSet(), {'Jugendflamme 2', 'AGT'});
    expect(braun.person.youth, isTrue);
  });

  test('Stichworte: Import aktualisiert vorhandene Kürzel', () async {
    await repo.keywords.save(KeywordInput(code: 'B 1', description: 'alt'));
    final (c, u) = await repo.keywords.upsertAll([
      KeywordInput(code: 'b 1', description: 'Kleinbrand'),
      KeywordInput(code: 'TH 1', specialRights: false),
    ]);
    expect((c, u), (1, 1));
    final all = await repo.keywords.all();
    expect(all.map((k) => k.code), ['b 1', 'TH 1']);
    expect(all.first.description, 'Kleinbrand');
    expect(all.last.specialRights, isFalse);
  });

  test('Gelöschte Datensätze bleiben für den späteren Abgleich erhalten', () async {
    final id = await repo.keywords.save(KeywordInput(code: 'B 1'));
    await repo.keywords.delete(id);
    expect(await repo.keywords.all(), isEmpty);
    final raw = await repo.db.select(repo.db.keywords).get();
    expect(raw.single.deleted, isTrue);
  });

  test('Fahrzeug mit mehreren Funkrufnamen (BOS digital, BOS analog, 2× DLRG-Betriebsfunk)', () async {
    const calls = [
      VehicleCallSign(network: 'bos_digital', callSign: 'Pelikan Musterstadt 87/1'),
      VehicleCallSign(network: 'bos_analog', callSign: 'Pelikan Musterstadt 87/1'),
      VehicleCallSign(network: 'dlrg_betriebsfunk', callSign: 'Adler Musterstadt 21', label: 'Boot'),
      VehicleCallSign(network: 'dlrg_betriebsfunk', callSign: 'Adler Musterstadt 21/1', label: 'Bootsführer'),
    ];
    final id = await repo.vehicles.save(VehicleInput(
      name: 'MRB 1',
      kind: 'boot',
      callSigns: [...calls, const VehicleCallSign(network: 'bos_analog', callSign: '  ')],
    ));
    var v = (await repo.vehicles.watchAll().first).single;
    expect(v.allCallSigns, calls, reason: 'leere Rufnamen werden verworfen');
    expect(v.callSign, 'Pelikan Musterstadt 87/1', reason: 'der erste gilt als Haupt-Funkrufname');

    // Reihenfolge ändern und einen entfernen
    await repo.vehicles.save(VehicleInput(id: id, name: 'MRB 1', kind: 'boot', callSigns: [calls[2], calls[3]]));
    v = (await repo.vehicles.watchAll().first).single;
    expect(v.allCallSigns, [calls[2], calls[3]]);
    expect(v.callSign, 'Adler Musterstadt 21');

    // Alle entfernen
    await repo.vehicles.save(VehicleInput(id: id, name: 'MRB 1', kind: 'boot', callSigns: const []));
    v = (await repo.vehicles.watchAll().first).single;
    expect(v.allCallSigns, isEmpty);
    expect(v.callSign, isNull);

    // Einzelner Rufname wie bisher → BOS digital
    await repo.vehicles.save(VehicleInput(name: 'HLF 20', callSign: 'Florian 1/46-1'));
    final hlf = (await repo.vehicles.watchAll().first).firstWhere((x) => x.name == 'HLF 20');
    expect(hlf.allCallSigns, const [VehicleCallSign(network: 'bos_digital', callSign: 'Florian 1/46-1')]);
  });

  test('Datenbank von Version 5: Funkrufname wird übernommen', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE vehicles (id TEXT NOT NULL PRIMARY KEY, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, '
          "name TEXT NOT NULL, type TEXT NULL, kind TEXT NOT NULL DEFAULT 'fahrzeug', call_sign TEXT NULL, "
          "status TEXT NOT NULL DEFAULT 'einsatzbereit', external_id TEXT NULL, sort_order INTEGER NOT NULL DEFAULT 0)");
      raw.execute("INSERT INTO vehicles (id, updated_at, name, call_sign) VALUES ('a', 0, 'HLF 20', 'Florian 1/46-1'), ('b', 0, 'MTW', NULL)");
      raw.userVersion = 5;
    }));
    addTearDown(old.close);
    final vs = await old.select(old.vehicles).get();
    final hlf = vs.firstWhere((v) => v.id == 'a'), mtw = vs.firstWhere((v) => v.id == 'b');
    expect(hlf.allCallSigns, const [VehicleCallSign(network: 'bos_digital', callSign: 'Florian 1/46-1')]);
    expect(VehicleCallSign.decode(hlf.callSigns), hlf.allCallSigns);
    expect(mtw.callSigns, '[]');
    expect(mtw.allCallSigns, isEmpty);
  });
}
