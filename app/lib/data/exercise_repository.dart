import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Status einer Übung.
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
  });

  final Exercise exercise;
  final List<ExercisePhase> phases;
  final List<ExerciseSafetyCheck> checks;
  final List<ExerciseVehicle> vehicles;
  final List<ExerciseAssignment> assignments;
  final List<AlarmPlanEntry> alarmPlan;
  final Keyword? keyword;

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
  });

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
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.date), (t) => OrderingTerm(expression: t.startMinutes)]))
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
    return ExerciseDetail(
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
            ));
        for (var i = 0; i < safetyChecklist.length; i++) {
          await db.into(db.exerciseSafetyChecks).insert(ExerciseSafetyChecksCompanion.insert(
                exerciseId: row.id,
                description: safetyChecklist[i],
                sortOrder: Value(i),
              ));
        }
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
