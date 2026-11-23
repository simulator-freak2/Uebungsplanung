import 'package:drift/drift.dart';

import 'call_signs.dart';
import 'database.dart';
import 'documents_repository.dart';
import 'exercise_repository.dart';

export 'call_signs.dart';

/// Zugriff auf alle Stammdaten. Gelöschte Datensätze werden nur markiert
/// (siehe [SyncColumns]) und hier ausgefiltert.
class Repositories {
  Repositories(this.db)
      : settings = SettingsRepository(db),
        qualifications = QualificationRepository(db),
        persons = PersonRepository(db),
        vehicles = VehicleRepository(db),
        keywords = KeywordRepository(db),
        exercises = ExerciseRepository(db),
        documents = DocumentsRepository(db);

  final AppDatabase db;
  final SettingsRepository settings;
  final QualificationRepository qualifications;
  final PersonRepository persons;
  final VehicleRepository vehicles;
  final KeywordRepository keywords;
  final ExerciseRepository exercises;
  final DocumentsRepository documents;
}

String _norm(String s) => s.trim().toLowerCase();

// ---------------------------------------------------------------------------
// Einstellungen
// ---------------------------------------------------------------------------

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDatabase db;

  static const orgName = 'org_name';
  static const profileId = 'profile_id';

  /// „true“/„false“: Übungen müssen von TL/Wehrführer freigegeben werden.
  static const approvalRequired = 'approval_required';

  Stream<bool> watchBool(String key, {bool fallback = false}) => watch(key).map((v) => v == null ? fallback : v == 'true');

  Future<String?> get(String key) async {
    final row = await (db.select(db.settings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watch(String key) =>
      (db.select(db.settings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  Future<void> set(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}

// ---------------------------------------------------------------------------
// Qualifikationen
// ---------------------------------------------------------------------------

class QualificationRepository {
  QualificationRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$QualificationsTable, Qualification> _active() =>
      db.select(db.qualifications)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.name)]);

  Stream<List<Qualification>> watchAll() => _active().watch();
  Future<List<Qualification>> all() => _active().get();

  Future<String> add(String name) async {
    final list = await all();
    final maxSort = list.fold<int>(-1, (m, q) => q.sortOrder > m ? q.sortOrder : m);
    final row = await db.into(db.qualifications).insertReturning(
        QualificationsCompanion.insert(name: name.trim(), sortOrder: Value(maxSort + 1)));
    return row.id;
  }

  /// Liefert die ID der Qualifikation mit diesem Namen und legt sie an,
  /// falls es sie noch nicht gibt (Groß-/Kleinschreibung egal).
  Future<String> ensure(String name) async {
    final existing = (await all()).where((q) => _norm(q.name) == _norm(name));
    if (existing.isNotEmpty) return existing.first.id;
    return add(name);
  }

  Future<void> rename(String id, String name) =>
      (db.update(db.qualifications)..where((t) => t.id.equals(id))).write(
          QualificationsCompanion(name: Value(name.trim()), updatedAt: Value(AppDatabase.now())));

  Future<void> reorder(List<String> ids) => db.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          await (db.update(db.qualifications)..where((t) => t.id.equals(ids[i]))).write(
              QualificationsCompanion(sortOrder: Value(i), updatedAt: Value(AppDatabase.now())));
        }
      });

  /// Löscht die Qualifikation, entfernt sie bei allen Personen und als
  /// Voraussetzung bei allen Funktionen.
  Future<void> delete(String id) => db.transaction(() async {
        final now = Value(AppDatabase.now());
        await (db.update(db.qualifications)..where((t) => t.id.equals(id)))
            .write(QualificationsCompanion(deleted: const Value(true), updatedAt: now));
        await (db.update(db.personQualifications)
              ..where((t) => t.qualificationId.equals(id) & t.deleted.equals(false)))
            .write(PersonQualificationsCompanion(deleted: const Value(true), updatedAt: now));
        await (db.update(db.crewFunctions)
              ..where((t) => t.requiredQualificationId.equals(id)))
            .write(CrewFunctionsCompanion(requiredQualificationId: const Value(null), updatedAt: now));
      });

  /// Anzahl Personen je Qualifikation.
  Stream<Map<String, int>> watchUsage() {
    final q = db.selectOnly(db.personQualifications)
      ..addColumns([db.personQualifications.qualificationId, db.personQualifications.id.count()])
      ..where(db.personQualifications.deleted.equals(false))
      ..groupBy([db.personQualifications.qualificationId]);
    return q.watch().map((rows) => {
          for (final r in rows)
            r.read(db.personQualifications.qualificationId)!:
                r.read(db.personQualifications.id.count()) ?? 0,
        });
  }
}

// ---------------------------------------------------------------------------
// Personal
// ---------------------------------------------------------------------------

class PersonWithQualifications {
  PersonWithQualifications(this.person, this.qualifications);
  final Person person;
  final List<Qualification> qualifications;

  String get displayName =>
      person.firstName.isEmpty ? person.lastName : '${person.lastName}, ${person.firstName}';
  Set<String> get qualificationIds => {for (final q in qualifications) q.id};
}

class PersonInput {
  PersonInput({
    this.id,
    required this.lastName,
    this.firstName = '',
    this.personnelNo,
    this.youth = false,
    this.qualificationIds = const {},
  });

  final String? id;
  final String lastName;
  final String firstName;
  final String? personnelNo;
  final bool youth;
  final Set<String> qualificationIds;
}

class PersonRepository {
  PersonRepository(this.db);
  final AppDatabase db;

  Stream<List<PersonWithQualifications>> watchAll() => db
      .customSelect('SELECT 1',
          readsFrom: {db.persons, db.personQualifications, db.qualifications})
      .watch()
      .asyncMap((_) => all());

  Future<List<PersonWithQualifications>> all() async {
    final persons = await (db.select(db.persons)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.lastName.collate(Collate.noCase)), (t) => OrderingTerm(expression: t.firstName.collate(Collate.noCase))]))
        .get();
    final links = await (db.select(db.personQualifications).join([
      innerJoin(db.qualifications, db.qualifications.id.equalsExp(db.personQualifications.qualificationId)),
    ])
          ..where(db.personQualifications.deleted.equals(false) & db.qualifications.deleted.equals(false))
          ..orderBy([OrderingTerm(expression: db.qualifications.sortOrder)]))
        .get();
    final byPerson = <String, List<Qualification>>{};
    for (final row in links) {
      final link = row.readTable(db.personQualifications);
      byPerson.putIfAbsent(link.personId, () => []).add(row.readTable(db.qualifications));
    }
    return [for (final p in persons) PersonWithQualifications(p, byPerson[p.id] ?? const [])];
  }

  /// Legt eine Person an oder aktualisiert sie. Gibt die ID zurück.
  Future<String> save(PersonInput input) => db.transaction(() async {
        final now = AppDatabase.now();
        final String id;
        final personNo = (input.personnelNo?.trim().isEmpty ?? true) ? null : input.personnelNo!.trim();
        if (input.id == null) {
          final row = await db.into(db.persons).insertReturning(PersonsCompanion.insert(
                lastName: input.lastName.trim(),
                firstName: Value(input.firstName.trim()),
                personnelNo: Value(personNo),
                youth: Value(input.youth),
              ));
          id = row.id;
        } else {
          id = input.id!;
          await (db.update(db.persons)..where((t) => t.id.equals(id))).write(PersonsCompanion(
                lastName: Value(input.lastName.trim()),
                firstName: Value(input.firstName.trim()),
                personnelNo: Value(personNo),
                youth: Value(input.youth),
                updatedAt: Value(now),
              ));
        }
        await _setQualifications(id, input.qualificationIds);
        return id;
      });

  Future<void> _setQualifications(String personId, Set<String> wanted) async {
    final now = Value(AppDatabase.now());
    final current = await (db.select(db.personQualifications)
          ..where((t) => t.personId.equals(personId) & t.deleted.equals(false)))
        .get();
    final have = {for (final l in current) l.qualificationId};
    for (final l in current.where((l) => !wanted.contains(l.qualificationId))) {
      await (db.update(db.personQualifications)..where((t) => t.id.equals(l.id)))
          .write(PersonQualificationsCompanion(deleted: const Value(true), updatedAt: now));
    }
    for (final q in wanted.difference(have)) {
      await db.into(db.personQualifications).insert(
          PersonQualificationsCompanion.insert(personId: personId, qualificationId: q));
    }
  }

  Future<void> delete(String id) => db.transaction(() async {
        final now = Value(AppDatabase.now());
        await (db.update(db.persons)..where((t) => t.id.equals(id)))
            .write(PersonsCompanion(deleted: const Value(true), updatedAt: now));
        await (db.update(db.personQualifications)..where((t) => t.personId.equals(id)))
            .write(PersonQualificationsCompanion(deleted: const Value(true), updatedAt: now));
      });

  /// Sucht eine vorhandene Person: zuerst über die Personalnummer,
  /// sonst über Nach- und Vorname.
  Future<PersonWithQualifications?> find({String? personnelNo, required String lastName, String firstName = ''}) async {
    final list = await all();
    if (personnelNo != null && personnelNo.trim().isNotEmpty) {
      for (final p in list) {
        if (_norm(p.person.personnelNo ?? '') == _norm(personnelNo)) return p;
      }
    }
    for (final p in list) {
      if (_norm(p.person.lastName) == _norm(lastName) && _norm(p.person.firstName) == _norm(firstName)) return p;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Fahrzeuge, Funktionen, Besetzungsmuster
// ---------------------------------------------------------------------------

/// Alles, was zu einem Fahrzeug gehört. Ist [vehicle] `null`, beschreibt das
/// Objekt die fahrzeugunabhängigen Führungs- und Sonderfunktionen.
class VehicleDetail {
  VehicleDetail({required this.vehicle, required this.functions, required this.patterns, required this.matrix});
  final Vehicle? vehicle;
  final List<CrewFunction> functions;
  final List<CrewPattern> patterns;

  /// patternId → enthaltene functionIds
  final Map<String, Set<String>> matrix;

  bool contains(String patternId, String functionId) => matrix[patternId]?.contains(functionId) ?? false;
}

class VehicleInput {
  VehicleInput({this.id, required this.name, this.type, this.kind = 'fahrzeug', this.callSign, this.callSigns, this.status = 'einsatzbereit'});
  final String? id;
  final String name;
  final String? type;
  final String kind;

  /// Einzelner Funkrufname (BOS digital) – nur genutzt, wenn [callSigns] fehlt.
  final String? callSign;

  /// Alle Funkrufnamen; der erste gilt als Haupt-Funkrufname.
  final List<VehicleCallSign>? callSigns;
  final String status;

  List<VehicleCallSign> get resolvedCallSigns {
    if (callSigns != null) {
      return [
        for (final c in callSigns!)
          if (c.callSign.trim().isNotEmpty)
            VehicleCallSign(network: c.network, callSign: c.callSign.trim(), label: (c.label?.trim().isEmpty ?? true) ? null : c.label!.trim()),
      ];
    }
    final c = callSign?.trim() ?? '';
    return c.isEmpty ? const [] : [VehicleCallSign(network: 'bos_digital', callSign: c)];
  }
}

/// Vorlage aus dem Organisationsprofil (z. B. „HLF 20“).
class VehicleTemplate {
  VehicleTemplate({required this.type, required this.kind, required this.functions, required this.patterns});
  final String type;
  final String kind;

  /// (Funktion, benötigte Qualifikation oder null)
  final List<(String, String?)> functions;
  final Map<String, List<String>> patterns;
}

class VehicleRepository {
  VehicleRepository(this.db);
  final AppDatabase db;

  Stream<List<Vehicle>> watchAll() => (db.select(db.vehicles)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.name)]))
      .watch();

  Stream<VehicleDetail> watchDetail(String? vehicleId) => db
      .customSelect('SELECT 1',
          readsFrom: {db.vehicles, db.crewFunctions, db.crewPatterns, db.crewPatternFunctions})
      .watch()
      .asyncMap((_) => detail(vehicleId));

  /// Alle Fahrzeuge mit Funktionen und Mustern; Schlüssel `null` = Führungsfunktionen.
  Stream<Map<String?, VehicleDetail>> watchAllDetails() => db
      .customSelect('SELECT 1',
          readsFrom: {db.vehicles, db.crewFunctions, db.crewPatterns, db.crewPatternFunctions})
      .watch()
      .asyncMap((_) async {
        final ids = (await (db.select(db.vehicles)..where((t) => t.deleted.equals(false))).get()).map((v) => v.id);
        return {null: await detail(null), for (final id in ids) id: await detail(id)};
      });

  Future<VehicleDetail> detail(String? vehicleId) async {
    final vehicle = vehicleId == null
        ? null
        : await (db.select(db.vehicles)..where((t) => t.id.equals(vehicleId))).getSingleOrNull();
    final functions = await (db.select(db.crewFunctions)
          ..where((t) =>
              t.deleted.equals(false) &
              (vehicleId == null ? t.vehicleId.isNull() : t.vehicleId.equals(vehicleId)))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final patterns = vehicleId == null
        ? <CrewPattern>[]
        : await (db.select(db.crewPatterns)
              ..where((t) => t.deleted.equals(false) & t.vehicleId.equals(vehicleId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    final matrix = <String, Set<String>>{for (final p in patterns) p.id: <String>{}};
    if (patterns.isNotEmpty) {
      final links = await (db.select(db.crewPatternFunctions)
            ..where((t) => t.deleted.equals(false) & t.patternId.isIn(matrix.keys)))
          .get();
      for (final l in links) {
        matrix[l.patternId]!.add(l.functionId);
      }
    }
    return VehicleDetail(vehicle: vehicle, functions: functions, patterns: patterns, matrix: matrix);
  }

  Future<String> save(VehicleInput input) async {
    final now = AppDatabase.now();
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final calls = input.resolvedCallSigns;
    if (input.id == null) {
      final count = (await db.select(db.vehicles).get()).length;
      final row = await db.into(db.vehicles).insertReturning(VehiclesCompanion.insert(
            name: input.name.trim(),
            type: Value(clean(input.type)),
            kind: Value(input.kind),
            callSign: Value(calls.firstOrNull?.callSign),
            callSigns: Value(VehicleCallSign.encode(calls)),
            status: Value(input.status),
            sortOrder: Value(count),
          ));
      return row.id;
    }
    await (db.update(db.vehicles)..where((t) => t.id.equals(input.id!))).write(VehiclesCompanion(
          name: Value(input.name.trim()),
          type: Value(clean(input.type)),
          kind: Value(input.kind),
          callSign: Value(calls.firstOrNull?.callSign),
          callSigns: Value(VehicleCallSign.encode(calls)),
          status: Value(input.status),
          updatedAt: Value(now),
        ));
    return input.id!;
  }

  /// Legt ein Fahrzeug mit allen Funktionen und Besetzungsmustern der Vorlage an.
  Future<String> createFromTemplate(VehicleTemplate t,
      {required String name, String? callSign, List<VehicleCallSign>? callSigns, required Future<String> Function(String) ensureQualification}) {
    return db.transaction(() async {
      final vid = await save(VehicleInput(name: name, type: t.type, kind: t.kind, callSign: callSign, callSigns: callSigns));
      final fnIds = <String, String>{};
      for (final (fn, qual) in t.functions) {
        final qid = qual == null ? null : await ensureQualification(qual);
        fnIds[fn] = await addFunction(vid, fn, qid);
      }
      for (final entry in t.patterns.entries) {
        final pid = await addPattern(vid, entry.key);
        for (final fn in entry.value) {
          final fid = fnIds[fn];
          if (fid != null) await setPatternFunction(pid, fid, true);
        }
      }
      return vid;
    });
  }

  Future<void> delete(String vehicleId) => db.transaction(() async {
        final now = Value(AppDatabase.now());
        final d = await detail(vehicleId);
        await (db.update(db.vehicles)..where((t) => t.id.equals(vehicleId)))
            .write(VehiclesCompanion(deleted: const Value(true), updatedAt: now));
        for (final f in d.functions) {
          await deleteFunction(f.id);
        }
        for (final p in d.patterns) {
          await deletePattern(p.id);
        }
      });

  Future<String> addFunction(String? vehicleId, String name, String? qualificationId) async {
    final existing = await (db.select(db.crewFunctions)
          ..where((t) => t.deleted.equals(false) &
              (vehicleId == null ? t.vehicleId.isNull() : t.vehicleId.equals(vehicleId))))
        .get();
    final row = await db.into(db.crewFunctions).insertReturning(CrewFunctionsCompanion.insert(
          vehicleId: Value(vehicleId),
          name: name.trim(),
          requiredQualificationId: Value(qualificationId),
          sortOrder: Value(existing.length),
        ));
    return row.id;
  }

  Future<void> updateFunction(String id, {required String name, String? qualificationId}) =>
      (db.update(db.crewFunctions)..where((t) => t.id.equals(id))).write(CrewFunctionsCompanion(
            name: Value(name.trim()),
            requiredQualificationId: Value(qualificationId),
            updatedAt: Value(AppDatabase.now()),
          ));

  Future<void> reorderFunctions(List<String> ids) => db.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          await (db.update(db.crewFunctions)..where((t) => t.id.equals(ids[i])))
              .write(CrewFunctionsCompanion(sortOrder: Value(i), updatedAt: Value(AppDatabase.now())));
        }
      });

  Future<void> deleteFunction(String id) => db.transaction(() async {
        final now = Value(AppDatabase.now());
        await (db.update(db.crewFunctions)..where((t) => t.id.equals(id)))
            .write(CrewFunctionsCompanion(deleted: const Value(true), updatedAt: now));
        await (db.update(db.crewPatternFunctions)..where((t) => t.functionId.equals(id)))
            .write(CrewPatternFunctionsCompanion(deleted: const Value(true), updatedAt: now));
      });

  Future<String> addPattern(String vehicleId, String name) async {
    final existing = await (db.select(db.crewPatterns)
          ..where((t) => t.deleted.equals(false) & t.vehicleId.equals(vehicleId)))
        .get();
    final row = await db.into(db.crewPatterns).insertReturning(
        CrewPatternsCompanion.insert(vehicleId: vehicleId, name: name.trim(), sortOrder: Value(existing.length)));
    return row.id;
  }

  Future<void> renamePattern(String id, String name) =>
      (db.update(db.crewPatterns)..where((t) => t.id.equals(id)))
          .write(CrewPatternsCompanion(name: Value(name.trim()), updatedAt: Value(AppDatabase.now())));

  Future<void> deletePattern(String id) => db.transaction(() async {
        final now = Value(AppDatabase.now());
        await (db.update(db.crewPatterns)..where((t) => t.id.equals(id)))
            .write(CrewPatternsCompanion(deleted: const Value(true), updatedAt: now));
        await (db.update(db.crewPatternFunctions)..where((t) => t.patternId.equals(id)))
            .write(CrewPatternFunctionsCompanion(deleted: const Value(true), updatedAt: now));
      });

  Future<void> setPatternFunction(String patternId, String functionId, bool included) async {
    final now = Value(AppDatabase.now());
    final existing = await (db.select(db.crewPatternFunctions)
          ..where((t) => t.patternId.equals(patternId) & t.functionId.equals(functionId) & t.deleted.equals(false)))
        .get();
    if (included && existing.isEmpty) {
      await db.into(db.crewPatternFunctions)
          .insert(CrewPatternFunctionsCompanion.insert(patternId: patternId, functionId: functionId));
    } else if (!included) {
      for (final l in existing) {
        await (db.update(db.crewPatternFunctions)..where((t) => t.id.equals(l.id)))
            .write(CrewPatternFunctionsCompanion(deleted: const Value(true), updatedAt: now));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Alarmstichworte
// ---------------------------------------------------------------------------

class KeywordInput {
  KeywordInput({this.id, required this.code, this.category, this.description, this.resources, this.specialRights = true});
  final String? id;
  final String code;
  final String? category;
  final String? description;
  final String? resources;
  final bool specialRights;
}

class KeywordRepository {
  KeywordRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$KeywordsTable, Keyword> _active() => db.select(db.keywords)
    ..where((t) => t.deleted.equals(false))
    ..orderBy([(t) => OrderingTerm(expression: t.code.collate(Collate.noCase))]);

  Stream<List<Keyword>> watchAll() => _active().watch();
  Future<List<Keyword>> all() => _active().get();

  Future<String> save(KeywordInput k) async {
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    if (k.id == null) {
      final row = await db.into(db.keywords).insertReturning(KeywordsCompanion.insert(
            code: k.code.trim(),
            category: Value(clean(k.category)),
            description: Value(clean(k.description)),
            resources: Value(clean(k.resources)),
            specialRights: Value(k.specialRights),
          ));
      return row.id;
    }
    await (db.update(db.keywords)..where((t) => t.id.equals(k.id!))).write(KeywordsCompanion(
          code: Value(k.code.trim()),
          category: Value(clean(k.category)),
          description: Value(clean(k.description)),
          resources: Value(clean(k.resources)),
          specialRights: Value(k.specialRights),
          updatedAt: Value(AppDatabase.now()),
        ));
    return k.id!;
  }

  Future<void> delete(String id) => (db.update(db.keywords)..where((t) => t.id.equals(id)))
      .write(KeywordsCompanion(deleted: const Value(true), updatedAt: Value(AppDatabase.now())));

  /// Übernimmt Stichworte; vorhandene Stichworte (gleiches Kürzel) werden
  /// aktualisiert. Gibt (neu, aktualisiert) zurück.
  Future<(int, int)> upsertAll(List<KeywordInput> items) => db.transaction(() async {
        final existing = {for (final k in await all()) _norm(k.code): k};
        var created = 0, updated = 0;
        for (final item in items) {
          final old = existing[_norm(item.code)];
          await save(KeywordInput(
            id: old?.id,
            code: item.code,
            category: item.category,
            description: item.description,
            resources: item.resources,
            specialRights: item.specialRights,
          ));
          old == null ? created++ : updated++;
        }
        return (created, updated);
      });
}
