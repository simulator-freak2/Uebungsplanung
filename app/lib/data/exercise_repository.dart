import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'lead_functions.dart';

/// Status einer Übung.
/// Kategorien im Dienstplan.
const exerciseCategories = {
  'praxis': 'Praxis',
  'theorie': 'Theorie / Unterricht',
  'sonderdienst': 'Sonderdienst / gemeinsame Übung',
  'jugend': 'Jugend',
};

abstract final class ExerciseStatus {
  static const draft = 'entwurf';
  static const submitted = 'zur_freigabe';
  static const approved = 'freigegeben';

  static String label(String s, {required bool approvalRequired}) => switch (s) {
        submitted => 'Freigabe ausstehend',
        approved => approvalRequired ? 'Freigegeben' : 'Fertig',
        _ => 'Entwurf',
      };
}

/// Alles, was zu einer Übung gehört.
class ExerciseDetail {
  ExerciseDetail({
    required this.exercise,
    required this.phases,
    required this.checks,
    required this.vehicles,
    required this.assignments,
    required this.alarmPlan,
    required this.keyword,
    this.radio = const [],
    this.roles = const [],
    this.material = const [],
    this.observations = const [],
    this.lessons = const [],
    this.leads = const [],
  });

  final Exercise exercise;
  final List<ExercisePhase> phases;
  final List<ExerciseSafetyCheck> checks;
  final List<ExerciseVehicle> vehicles;
  final List<ExerciseAssignment> assignments;
  final List<AlarmPlanEntry> alarmPlan;
  final Keyword? keyword;
  final List<RadioEntry> radio;
  final List<RoleCard> roles;
  final List<MaterialItem> material;
  final List<ObservationItem> observations;
  final List<Lesson> lessons;

  /// Führungs- und Sonderfunktionen dieser Übung (nach Reihenfolge).
  final List<ExerciseLeadFunction> leads;

  List<String> get debriefGood => decodeGoals(exercise.debriefGood);
  List<String> get debriefBad => decodeGoals(exercise.debriefBad);

  /// Alarmierungen gruppiert nach Zeitpunkt (ohne Trupps, die abgerufen
  /// werden). Jede Gruppe ergibt eine eigene Alarmmeldung.
  List<AlarmGroup> get alarmGroups {
    final byTime = <int, List<AlarmPlanEntry>>{};
    for (final e in alarmPlan.where((e) => e.kind != 'trupp')) {
      byTime.putIfAbsent(e.alarmOffset, () => []).add(e);
    }
    final times = byTime.keys.toList()..sort();
    return [for (var i = 0; i < times.length; i++) AlarmGroup(index: i, offset: times[i], entries: byTime[times[i]]!)];
  }

  List<String> get goals => decodeGoals(exercise.goals);
  bool get safetyComplete => checks.isNotEmpty && checks.every((c) => c.checked);
  int get start => exercise.startMinutes;
  bool get relativeTimes => exercise.timeMode == 'relativ';

  /// Personen je Funktion (functionId → personIds).
  Map<String, List<String>> get personsByFunction {
    final m = <String, List<String>>{};
    for (final a in assignments) {
      m.putIfAbsent(a.functionId, () => []).add(a.personId);
    }
    return m;
  }

  /// Sonderrechte: Eintrag der Übung, sonst Vorgabe des Stichworts, sonst ja.
  bool get specialRights => exercise.alarmSpecialRights ?? keyword?.specialRights ?? true;

  /// Erster Alarmierungszeitpunkt (relativ), falls ein Alarmierungsplan existiert.
  int? get firstAlarm => alarmPlan.isEmpty ? null : alarmPlan.map((e) => e.alarmOffset).reduce((a, b) => a < b ? a : b);
}

class AlarmGroup {
  AlarmGroup({required this.index, required this.offset, required this.entries});
  final int index;
  final int offset;
  final List<AlarmPlanEntry> entries;

  bool get isFirst => index == 0;
  String get title => isFirst ? 'Erstalarm' : '${index + 1}. Alarmierung';
}

List<String> decodeGoals(String json) {
  try {
    return [for (final g in jsonDecode(json) as List) g.toString()];
  } catch (_) {
    return const [];
  }
}

class ExerciseInput {
  ExerciseInput({
    this.id,
    required this.title,
    required this.date,
    required this.startMinutes,
    this.endMinutes,
    this.location,
    this.unit,
    this.topic,
    this.keywordId,
    this.category = 'praxis',
    this.isTemplate = false,
  });

  final bool isTemplate;

  final String category;
  final String? id;
  final String title;
  final DateTime date;
  final int startMinutes;
  final int? endMinutes;
  final String? location;
  final String? unit;
  final String? topic;
  final String? keywordId;
}

class AlarmEntryInput {
  AlarmEntryInput({this.id, required this.label, this.kind = 'fahrzeug', this.vehicleId, required this.alarmOffset, this.departOffset, this.arriveOffset, this.note});
  final String? id;
  final String label;
  final String kind;
  final String? vehicleId;
  final int alarmOffset;
  final int? departOffset;
  final int? arriveOffset;
  final String? note;
}

String? _clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
Value<DateTime> _now() => Value(AppDatabase.now());

class ExerciseRepository {
  ExerciseRepository(this.db);
  final AppDatabase db;

  // ------------------------------------------------------------------ Liste

  Stream<List<Exercise>> watchAll() => (db.select(db.exercises)
        ..where((t) => t.deleted.equals(false) & t.isTemplate.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.date), (t) => OrderingTerm(expression: t.startMinutes)]))
      .watch();

  Stream<List<Exercise>> watchTemplates() => (db.select(db.exercises)
        ..where((t) => t.deleted.equals(false) & t.isTemplate.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.title)]))
      .watch();

  // ----------------------------------------------------------------- Detail

  Stream<ExerciseDetail?> watchDetail(String id) => db
      .customSelect('SELECT 1', readsFrom: {
        db.exercises,
        db.exercisePhases,
        db.exerciseSafetyChecks,
        db.exerciseVehicles,
        db.exerciseAssignments,
        db.alarmPlanEntries,
        db.keywords,
        db.radioEntries,
        db.roleCards,
        db.materialItems,
        db.observationItems,
        db.lessons,
        db.exerciseLeadFunctions,
      })
      .watch()
      .asyncMap((_) => detail(id));

  Future<ExerciseDetail?> detail(String id) async {
    final e = await (db.select(db.exercises)..where((t) => t.id.equals(id) & t.deleted.equals(false))).getSingleOrNull();
    if (e == null) return null;
    final phases = await (db.select(db.exercisePhases)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.offsetMinutes)]))
        .get();
    final checks = await (db.select(db.exerciseSafetyChecks)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final vehicles = await (db.select(db.exerciseVehicles)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final assignments = await (db.select(db.exerciseAssignments)..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))).get();
    final plan = await (db.select(db.alarmPlanEntries)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.alarmOffset), (t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final kw = e.keywordId == null ? null : await (db.select(db.keywords)..where((t) => t.id.equals(e.keywordId!))).getSingleOrNull();
    final radio = await (db.select(db.radioEntries)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final roles = await (db.select(db.roleCards)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.number)]))
        .get();
    final material = await (db.select(db.materialItems)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final observations = await (db.select(db.observationItems)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final lessons = await (db.select(db.lessons)..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))).get();
    final leads = await (db.select(db.exerciseLeadFunctions)
          ..where((t) => t.exerciseId.equals(id) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.name)]))
        .get();
    return ExerciseDetail(
      leads: leads,
      radio: radio,
      roles: roles,
      material: material,
      observations: observations,
      lessons: lessons,
      exercise: e,
      phases: phases,
      checks: checks,
      vehicles: vehicles,
      assignments: assignments,
      alarmPlan: plan,
      keyword: kw?.deleted == true ? null : kw,
    );
  }

  // -------------------------------------------------------------- Eckdaten

  /// Legt eine Übung an und übernimmt die Sicherheits-Checkliste.
  Future<String> create(ExerciseInput input, {List<String> safetyChecklist = const []}) => db.transaction(() async {
        final row = await db.into(db.exercises).insertReturning(ExercisesCompanion.insert(
              title: input.title.trim(),
              date: DateTime(input.date.year, input.date.month, input.date.day),
              startMinutes: Value(input.startMinutes),
              endMinutes: Value(input.endMinutes),
              location: Value(_clean(input.location)),
              unit: Value(_clean(input.unit)),
              topic: Value(_clean(input.topic)),
              keywordId: Value(input.keywordId),
              category: Value(input.category),
              isTemplate: Value(input.isTemplate),
            ));
        for (var i = 0; i < safetyChecklist.length; i++) {
          await db.into(db.exerciseSafetyChecks).insert(ExerciseSafetyChecksCompanion.insert(
                exerciseId: row.id,
                description: safetyChecklist[i],
                sortOrder: Value(i),
              ));
        }
        await ensureDefaultLead(row.id);
        return row.id;
      });

  Future<void> update(ExerciseInput input) =>
      (db.update(db.exercises)..where((t) => t.id.equals(input.id!))).write(ExercisesCompanion(
            title: Value(input.title.trim()),
            date: Value(DateTime(input.date.year, input.date.month, input.date.day)),
            startMinutes: Value(input.startMinutes),
            endMinutes: Value(input.endMinutes),
            location: Value(_clean(input.location)),
            unit: Value(_clean(input.unit)),
            topic: Value(_clean(input.topic)),
            keywordId: Value(input.keywordId),
            category: Value(input.category),
            updatedAt: _now(),
          ));

  Future<void> _write(String id, ExercisesCompanion c) =>
      (db.update(db.exercises)..where((t) => t.id.equals(id))).write(c.copyWith(updatedAt: _now()));

  Future<void> setGoals(String id, List<String> goals) =>
      _write(id, ExercisesCompanion(goals: Value(jsonEncode([for (final g in goals) if (g.trim().isNotEmpty) g.trim()]))));

  Future<void> setScenario(String id, String? text) => _write(id, ExercisesCompanion(scenario: Value(_clean(text))));

  Future<void> setTimeMode(String id, bool relative) =>
      _write(id, ExercisesCompanion(timeMode: Value(relative ? 'relativ' : 'uhrzeit')));

  Future<void> setAlarm(String id, {String? address, String? reporter, bool? specialRights, String? vehicles}) =>
      _write(id, ExercisesCompanion(
        alarmAddress: Value(_clean(address)),
        alarmReporter: Value(_clean(reporter)),
        alarmSpecialRights: Value(specialRights),
        alarmVehicles: Value(_clean(vehicles)),
      ));

  Future<void> delete(String id) => _write(id, const ExercisesCompanion(deleted: Value(true)));

  // ----------------------------------------------------------- Lageskizze

  Future<void> setMapView(String id, double lat, double lon, double zoom) =>
      _write(id, ExercisesCompanion(mapLat: Value(lat), mapLon: Value(lon), mapZoom: Value(zoom)));

  Future<void> setSketch(String id, String json) => _write(id, ExercisesCompanion(sketch: Value(json)));

  Future<void> setSketchPng(String id, String? base64Png) => _write(id, ExercisesCompanion(sketchPng: Value(base64Png)));

  /// Kopiert eine Übung mit allen Unterlagen – als Vorlage ([asTemplate])
  /// oder als neue Übung. Nicht übernommen werden Besetzung (Personen),
  /// Bewertungen, Nachbesprechung, Freigabe und abgehakte Prüfpunkte.
  Future<String> copy(String sourceId, {required bool asTemplate, DateTime? date, String? title}) => db.transaction(() async {
        final d = (await detail(sourceId))!;
        final e = d.exercise;
        final row = await db.into(db.exercises).insertReturning(ExercisesCompanion.insert(
              title: (title ?? e.title).trim(),
              date: date ?? e.date,
              startMinutes: Value(e.startMinutes),
              endMinutes: Value(e.endMinutes),
              location: Value(e.location),
              unit: Value(e.unit),
              topic: Value(e.topic),
              keywordId: Value(e.keywordId),
              goals: Value(e.goals),
              scenario: Value(e.scenario),
              timeMode: Value(e.timeMode),
              alarmAddress: Value(e.alarmAddress),
              alarmReporter: Value(e.alarmReporter),
              alarmSpecialRights: Value(e.alarmSpecialRights),
              alarmVehicles: Value(e.alarmVehicles),
              category: Value(e.category),
              isTemplate: Value(asTemplate),
              mapLat: Value(e.mapLat),
              mapLon: Value(e.mapLon),
              mapZoom: Value(e.mapZoom),
              sketch: Value(e.sketch),
              sketchPng: Value(e.sketchPng),
            ));
        final id = row.id;
        for (final p in d.phases) {
          await db.into(db.exercisePhases).insert(ExercisePhasesCompanion.insert(exerciseId: id, offsetMinutes: Value(p.offsetMinutes), description: p.description));
        }
        for (final c in d.checks) {
          await db.into(db.exerciseSafetyChecks).insert(ExerciseSafetyChecksCompanion.insert(exerciseId: id, description: c.description, sortOrder: Value(c.sortOrder)));
        }
        for (final v in d.vehicles) {
          await db.into(db.exerciseVehicles)
              .insert(ExerciseVehiclesCompanion.insert(exerciseId: id, vehicleId: v.vehicleId, patternId: Value(v.patternId), sortOrder: Value(v.sortOrder)));
        }
        for (final a in d.alarmPlan) {
          await db.into(db.alarmPlanEntries).insert(AlarmPlanEntriesCompanion.insert(
                exerciseId: id,
                label: a.label,
                kind: Value(a.kind),
                vehicleId: Value(a.vehicleId),
                alarmOffset: a.alarmOffset,
                departOffset: Value(a.departOffset),
                arriveOffset: Value(a.arriveOffset),
                note: Value(a.note),
                sortOrder: Value(a.sortOrder),
              ));
        }
        final radioIds = <String, String>{};
        for (final r in d.radio) {
          radioIds[r.id] = (await db.into(db.radioEntries).insertReturning(RadioEntriesCompanion.insert(
                exerciseId: id,
                callSign: r.callSign,
                device: Value(r.device),
                network: Value(r.network),
                channel: Value(r.channel),
                task: Value(r.task),
                sortOrder: Value(r.sortOrder),
              )))
              .id;
        }
        // Führungsstruktur ohne Personen übernehmen.
        final leadIds = <String, String>{
          for (final l in d.leads) l.id: l.id == defaultLeadId(sourceId) ? defaultLeadId(id) : const Uuid().v4(),
        };
        for (final l in d.leads) {
          await db.into(db.exerciseLeadFunctions).insert(ExerciseLeadFunctionsCompanion.insert(
                id: Value(leadIds[l.id]!),
                exerciseId: id,
                name: l.name,
                requiredQualificationId: Value(l.requiredQualificationId),
                parentId: Value(leadIds[l.parentId]),
                vehicleId: Value(l.vehicleId),
                radioEntryId: Value(radioIds[l.radioEntryId]),
                sortOrder: Value(l.sortOrder),
              ));
        }
        if (d.leads.isEmpty) await ensureDefaultLead(id);
        for (final r in d.roles) {
          await db.into(db.roleCards).insert(RoleCardsCompanion.insert(
                exerciseId: id,
                number: Value(r.number),
                name: r.name,
                birthDate: Value(r.birthDate),
                age: Value(r.age),
                preExisting: Value(r.preExisting),
                illnesses: Value(r.illnesses),
                symptoms: Value(r.symptoms),
                injuries: Value(r.injuries),
                story: Value(r.story),
                escalation: Value(r.escalation),
              ));
        }
        for (final m in d.material) {
          await db.into(db.materialItems).insert(MaterialItemsCompanion.insert(
                exerciseId: id,
                name: m.name,
                location: Value(m.location),
                quantity: Value(m.quantity),
                source: Value(m.source),
                externalId: Value(m.externalId),
                sortOrder: Value(m.sortOrder),
              ));
        }
        for (final o in d.observations) {
          await db.into(db.observationItems).insert(ObservationItemsCompanion.insert(exerciseId: id, description: o.description, sortOrder: Value(o.sortOrder)));
        }
        return id;
      });

  // ---------------------------------------------------------------- Freigabe

  Future<void> setStatus(String id, String status, {String? approvedBy}) => _write(
        id,
        ExercisesCompanion(
          status: Value(status),
          approvedBy: Value(status == ExerciseStatus.approved ? _clean(approvedBy) : null),
          approvedAt: Value(status == ExerciseStatus.approved ? AppDatabase.now() : null),
        ),
      );

  // ------------------------------------------------------------------ Ablauf

  Future<void> savePhase(String exerciseId, {String? id, required int offset, required String text}) async {
    if (id == null) {
      await db.into(db.exercisePhases).insert(
          ExercisePhasesCompanion.insert(exerciseId: exerciseId, offsetMinutes: Value(offset), description: text.trim()));
    } else {
      await (db.update(db.exercisePhases)..where((t) => t.id.equals(id)))
          .write(ExercisePhasesCompanion(offsetMinutes: Value(offset), description: Value(text.trim()), updatedAt: _now()));
    }
  }

  Future<void> deletePhase(String id) => (db.update(db.exercisePhases)..where((t) => t.id.equals(id)))
      .write(ExercisePhasesCompanion(deleted: const Value(true), updatedAt: _now()));

  // -------------------------------------------------------------- Sicherheit

  Future<void> setCheck(String id, bool checked) => (db.update(db.exerciseSafetyChecks)..where((t) => t.id.equals(id)))
      .write(ExerciseSafetyChecksCompanion(checked: Value(checked), updatedAt: _now()));

  Future<void> addCheck(String exerciseId, String text) async {
    final n = (await (db.select(db.exerciseSafetyChecks)..where((t) => t.exerciseId.equals(exerciseId))).get()).length;
    await db.into(db.exerciseSafetyChecks)
        .insert(ExerciseSafetyChecksCompanion.insert(exerciseId: exerciseId, description: text.trim(), sortOrder: Value(n)));
  }

  Future<void> deleteCheck(String id) => (db.update(db.exerciseSafetyChecks)..where((t) => t.id.equals(id)))
      .write(ExerciseSafetyChecksCompanion(deleted: const Value(true), updatedAt: _now()));

  // ------------------------------------------------------- Fahrzeugbesetzung

  Future<void> addVehicle(String exerciseId, String vehicleId, {String? patternId}) async {
    final existing = await (db.select(db.exerciseVehicles)..where((t) => t.exerciseId.equals(exerciseId) & t.deleted.equals(false))).get();
    if (existing.any((v) => v.vehicleId == vehicleId)) return;
    await db.into(db.exerciseVehicles).insert(ExerciseVehiclesCompanion.insert(
          exerciseId: exerciseId,
          vehicleId: vehicleId,
          patternId: Value(patternId),
          sortOrder: Value(existing.length),
        ));
  }

  Future<void> setPattern(String exerciseVehicleId, String? patternId) =>
      (db.update(db.exerciseVehicles)..where((t) => t.id.equals(exerciseVehicleId)))
          .write(ExerciseVehiclesCompanion(patternId: Value(patternId), updatedAt: _now()));

  /// Entfernt das Fahrzeug aus der Übung samt Besetzung.
  Future<void> removeVehicle(String exerciseId, ExerciseVehicle ev, Iterable<String> functionIds) => db.transaction(() async {
        await (db.update(db.exerciseVehicles)..where((t) => t.id.equals(ev.id)))
            .write(ExerciseVehiclesCompanion(deleted: const Value(true), updatedAt: _now()));
        await (db.update(db.exerciseAssignments)
              ..where((t) => t.exerciseId.equals(exerciseId) & t.functionId.isIn(functionIds) & t.deleted.equals(false)))
            .write(ExerciseAssignmentsCompanion(deleted: const Value(true), updatedAt: _now()));
        await (db.update(db.exerciseLeadFunctions)
              ..where((t) => t.exerciseId.equals(exerciseId) & t.vehicleId.equals(ev.vehicleId) & t.deleted.equals(false)))
            .write(ExerciseLeadFunctionsCompanion(vehicleId: const Value(null), updatedAt: _now()));
      });

  /// Setzt [personId] auf die Funktion [functionId]. Eine Funktion hat höchstens
  /// eine Person. Mit [fromFunctionId] wird die Person verschoben: war die
  /// Zielfunktion besetzt, tauschen die beiden Personen die Plätze.
  Future<void> assign(String exerciseId, {required String functionId, required String personId, String? fromFunctionId}) =>
      db.transaction(() async {
        if (fromFunctionId == functionId) return;
        final target = await _assignmentOf(exerciseId, functionId);
        if (target?.personId == personId) return;
        if (fromFunctionId != null) {
          final source = await _assignmentOf(exerciseId, fromFunctionId);
          if (source != null) await _unassign(source.id);
          if (target != null) {
            await _unassign(target.id);
            await _insertAssignment(exerciseId, fromFunctionId, target.personId);
          }
        } else if (target != null) {
          await _unassign(target.id);
        }
        await _insertAssignment(exerciseId, functionId, personId);
      });

  Future<void> unassign(String exerciseId, String functionId) async {
    final a = await _assignmentOf(exerciseId, functionId);
    if (a != null) await _unassign(a.id);
  }

  Future<ExerciseAssignment?> _assignmentOf(String exerciseId, String functionId) => (db.select(db.exerciseAssignments)
        ..where((t) => t.exerciseId.equals(exerciseId) & t.functionId.equals(functionId) & t.deleted.equals(false))
        ..limit(1))
      .getSingleOrNull();

  Future<void> _unassign(String id) => (db.update(db.exerciseAssignments)..where((t) => t.id.equals(id)))
      .write(ExerciseAssignmentsCompanion(deleted: const Value(true), updatedAt: _now()));

  Future<void> _insertAssignment(String exerciseId, String functionId, String personId) => db
      .into(db.exerciseAssignments)
      .insert(ExerciseAssignmentsCompanion.insert(exerciseId: exerciseId, functionId: functionId, personId: personId));

  // ------------------------------------------------- Führungsfunktionen

  /// Legt den Einsatzleiter / Einheitsführer an, falls die Übung ihn noch nie
  /// hatte. Wurde er gelöscht, bleibt er gelöscht.
  Future<void> ensureDefaultLead(String exerciseId) async {
    final catalog = await (db.select(db.crewFunctions)..where((t) => t.vehicleId.isNull() & t.deleted.equals(false))).get();
    final top = catalog.where((f) => isTopLeadName(f.name)).firstOrNull;
    await db.into(db.exerciseLeadFunctions).insert(
          ExerciseLeadFunctionsCompanion.insert(
            id: Value(defaultLeadId(exerciseId)),
            exerciseId: exerciseId,
            name: defaultLeadName,
            requiredQualificationId: Value(top?.requiredQualificationId),
            sortOrder: const Value(0),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<List<ExerciseLeadFunction>> _leads(String exerciseId) => (db.select(db.exerciseLeadFunctions)
        ..where((t) => t.exerciseId.equals(exerciseId) & t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
      .get();

  /// Legt eine Führungsfunktion an oder ändert sie. Der Funkrufname wird im
  /// Funkplan geführt: Gibt es dort schon einen Eintrag mit diesem Rufnamen,
  /// wird er verknüpft, sonst angelegt. Ändern im Funkplan ändert damit auch
  /// das Organigramm.
  Future<String> saveLead(String exerciseId, LeadInput input) => db.transaction(() async {
        final leads = await _leads(exerciseId);
        final old = input.id == null ? null : leads.where((l) => l.id == input.id).firstOrNull;
        var parent = input.parentId;
        // Keine Ringe: sich selbst oder eigene Unterstellte als Vorgesetzte verbieten.
        if (old != null && (parent == old.id || descendantsOf(old.id, leads).contains(parent))) parent = old.parentId;
        String id;
        if (old == null) {
          final order = leads.isEmpty ? 0 : leads.map((l) => l.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
          id = (await db.into(db.exerciseLeadFunctions).insertReturning(ExerciseLeadFunctionsCompanion.insert(
                    exerciseId: exerciseId,
                    name: input.name.trim(),
                    requiredQualificationId: Value(input.qualificationId),
                    parentId: Value(parent),
                    vehicleId: Value(input.vehicleId),
                    sortOrder: Value(order),
                  )))
              .id;
        } else {
          id = old.id;
          await (db.update(db.exerciseLeadFunctions)..where((t) => t.id.equals(id))).write(ExerciseLeadFunctionsCompanion(
                name: Value(input.name.trim()),
                requiredQualificationId: Value(input.qualificationId),
                parentId: Value(parent),
                vehicleId: Value(input.vehicleId),
                updatedAt: _now(),
              ));
        }
        if (input.callSign != null) await _linkRadio(exerciseId, id, input.name.trim(), input.callSign!, input.vehicleId, old?.radioEntryId);
        return id;
      });

  Future<void> _linkRadio(String exerciseId, String leadId, String leadName, String callSign, String? vehicleId, String? linkedId) async {
    final call = callSign.trim();
    String? radioId;
    if (call.isNotEmpty) {
      final radio = await (db.select(db.radioEntries)
            ..where((t) => t.exerciseId.equals(exerciseId) & t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
      final linked = radio.where((r) => r.id == linkedId).firstOrNull;
      final same = radio.where((r) => r.callSign.trim().toLowerCase() == call.toLowerCase()).firstOrNull;
      if (same != null) {
        radioId = same.id;
      } else if (linked != null) {
        // Rufname geändert: verknüpften Funkplan-Eintrag mitändern.
        radioId = linked.id;
        await (db.update(db.radioEntries)..where((t) => t.id.equals(linked.id)))
            .write(RadioEntriesCompanion(callSign: Value(call), updatedAt: _now()));
      } else {
        final vehicle = vehicleId == null ? null : await (db.select(db.vehicles)..where((t) => t.id.equals(vehicleId))).getSingleOrNull();
        radioId = (await db.into(db.radioEntries).insertReturning(RadioEntriesCompanion.insert(
                  exerciseId: exerciseId,
                  callSign: call,
                  device: Value(vehicle?.name),
                  task: Value(leadName),
                  sortOrder: Value(radio.length),
                )))
            .id;
      }
    }
    await (db.update(db.exerciseLeadFunctions)..where((t) => t.id.equals(leadId)))
        .write(ExerciseLeadFunctionsCompanion(radioEntryId: Value(radioId), updatedAt: _now()));
  }

  /// Löscht eine Führungsfunktion samt Besetzung. Unterstellte rücken eine
  /// Ebene nach oben. Der Funkplan-Eintrag bleibt.
  Future<void> deleteLead(String exerciseId, String id) => db.transaction(() async {
        final leads = await _leads(exerciseId);
        final l = leads.where((x) => x.id == id).firstOrNull;
        if (l == null) return;
        await (db.update(db.exerciseLeadFunctions)..where((t) => t.exerciseId.equals(exerciseId) & t.parentId.equals(id) & t.deleted.equals(false)))
            .write(ExerciseLeadFunctionsCompanion(parentId: Value(l.parentId), updatedAt: _now()));
        await (db.update(db.exerciseLeadFunctions)..where((t) => t.id.equals(id)))
            .write(ExerciseLeadFunctionsCompanion(deleted: const Value(true), updatedAt: _now()));
        await unassign(exerciseId, id);
      });

  /// Unterstellt [id] der Führungsfunktion [parentId] (`null` = oberste Ebene).
  /// Ringe werden verhindert.
  Future<void> setLeadParent(String exerciseId, String id, String? parentId) async {
    final leads = await _leads(exerciseId);
    if (parentId == id || (parentId != null && descendantsOf(id, leads).contains(parentId))) return;
    await (db.update(db.exerciseLeadFunctions)..where((t) => t.id.equals(id)))
        .write(ExerciseLeadFunctionsCompanion(parentId: Value(parentId), updatedAt: _now()));
  }

  /// Verschiebt eine Führungsfunktion in der Reihenfolge um [delta] Plätze.
  Future<void> moveLead(String exerciseId, String id, int delta) => db.transaction(() async {
        final leads = await _leads(exerciseId);
        final i = leads.indexWhere((l) => l.id == id);
        final j = i + delta;
        if (i < 0 || j < 0 || j >= leads.length) return;
        final l = leads.removeAt(i);
        leads.insert(j, l);
        for (var k = 0; k < leads.length; k++) {
          if (leads[k].sortOrder != k) {
            await (db.update(db.exerciseLeadFunctions)..where((t) => t.id.equals(leads[k].id)))
                .write(ExerciseLeadFunctionsCompanion(sortOrder: Value(k), updatedAt: _now()));
          }
        }
      });

  // ---------------------------------------------------------- Alarmierungsplan

  Future<void> saveAlarmEntry(String exerciseId, AlarmEntryInput e) async {
    if (e.id == null) {
      final n = (await (db.select(db.alarmPlanEntries)..where((t) => t.exerciseId.equals(exerciseId))).get()).length;
      await db.into(db.alarmPlanEntries).insert(AlarmPlanEntriesCompanion.insert(
            exerciseId: exerciseId,
            label: e.label.trim(),
            kind: Value(e.kind),
            vehicleId: Value(e.vehicleId),
            alarmOffset: e.alarmOffset,
            departOffset: Value(e.departOffset),
            arriveOffset: Value(e.arriveOffset),
            note: Value(_clean(e.note)),
            sortOrder: Value(n),
          ));
    } else {
      await (db.update(db.alarmPlanEntries)..where((t) => t.id.equals(e.id!))).write(AlarmPlanEntriesCompanion(
            label: Value(e.label.trim()),
            kind: Value(e.kind),
            vehicleId: Value(e.vehicleId),
            alarmOffset: Value(e.alarmOffset),
            departOffset: Value(e.departOffset),
            arriveOffset: Value(e.arriveOffset),
            note: Value(_clean(e.note)),
            updatedAt: _now(),
          ));
    }
  }

  Future<void> deleteAlarmEntry(String id) => (db.update(db.alarmPlanEntries)..where((t) => t.id.equals(id)))
      .write(AlarmPlanEntriesCompanion(deleted: const Value(true), updatedAt: _now()));
}
