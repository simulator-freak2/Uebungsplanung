import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

String? _clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
Value<DateTime> _now() => Value(AppDatabase.now());

/// Funknetze für den Funkplan.
const radioNetworks = {
  'bos_digital': 'BOS digital',
  'bos_analog': 'BOS analog',
  'dlrg_betriebsfunk': 'DLRG-Betriebsfunk',
};

/// Bewertungsstufen im Beobachtungsbogen.
const ratings = {'++': 'sehr gut', '+': 'gut', 'o': 'ausreichend', '-': 'Verbesserung nötig'};

/// Status einer Erkenntnis aus der Nachbesprechung.
const lessonStatus = {'offen': 'offen', 'eingeplant': 'in Übung eingeplant', 'erledigt': 'erledigt'};

/// Eine Eskalationsstufe auf der Rollenkarte.
class EscalationStage {
  const EscalationStage({required this.label, this.trigger = '', required this.behavior});
  final String label;
  final String trigger;
  final String behavior;

  Map<String, String> toJson() => {'stufe': label, 'ausloeser': trigger, 'verhalten': behavior};
  static EscalationStage fromJson(Map<String, dynamic> j) =>
      EscalationStage(label: '${j['stufe'] ?? ''}', trigger: '${j['ausloeser'] ?? ''}', behavior: '${j['verhalten'] ?? ''}');
}

List<EscalationStage> decodeEscalation(String json) {
  try {
    return [for (final e in jsonDecode(json) as List) EscalationStage.fromJson(e as Map<String, dynamic>)];
  } catch (_) {
    return const [];
  }
}

String encodeEscalation(List<EscalationStage> stages) =>
    jsonEncode([for (final s in stages) if (s.behavior.trim().isNotEmpty) s.toJson()]);

/// Alter am Übungstag aus dem Geburtsdatum, sonst die angegebene Zahl.
int? ageOn(RoleCard r, DateTime day) {
  final b = r.birthDate;
  if (b == null) return r.age;
  var a = day.year - b.year;
  if (day.month < b.month || (day.month == b.month && day.day < b.day)) a--;
  return a;
}

class RoleCardInput {
  RoleCardInput({
    this.id,
    required this.number,
    required this.name,
    this.birthDate,
    this.age,
    this.preExisting,
    this.illnesses,
    this.symptoms,
    this.injuries,
    this.story,
    this.escalation = const [],
  });
  final String? id;
  final int number;
  final String name;
  final DateTime? birthDate;
  final int? age;
  final String? preExisting;
  final String? illnesses;
  final String? symptoms;
  final String? injuries;
  final String? story;
  final List<EscalationStage> escalation;
}

/// Lesson mit dem Titel der Übung, aus der sie stammt.
class LessonWithSource {
  LessonWithSource(this.lesson, this.exercise);
  final Lesson lesson;
  final Exercise exercise;
}

/// Funkplan, Rollenkarten, Material, Beobachtung und Nachbesprechung.
class DocumentsRepository {
  DocumentsRepository(this.db);
  final AppDatabase db;

  Future<int> _count(TableInfo t, GeneratedColumn<String> exerciseCol, String exerciseId) async =>
      (await (db.selectOnly(t)..addColumns([exerciseCol])..where(exerciseCol.equals(exerciseId))).get()).length;

  // ------------------------------------------------------------------ Funk

  Future<void> saveRadio(String exerciseId, {String? id, required String callSign, String? device, required String network, String? channel, String? task}) async {
    if (id == null) {
      await db.into(db.radioEntries).insert(RadioEntriesCompanion.insert(
            exerciseId: exerciseId,
            callSign: callSign.trim(),
            device: Value(_clean(device)),
            network: Value(network),
            channel: Value(_clean(channel)),
            task: Value(_clean(task)),
            sortOrder: Value(await _count(db.radioEntries, db.radioEntries.exerciseId, exerciseId)),
          ));
    } else {
      await (db.update(db.radioEntries)..where((t) => t.id.equals(id))).write(RadioEntriesCompanion(
            callSign: Value(callSign.trim()),
            device: Value(_clean(device)),
            network: Value(network),
            channel: Value(_clean(channel)),
            task: Value(_clean(task)),
            updatedAt: _now(),
          ));
    }
  }

  Future<void> deleteRadio(String id) =>
      (db.update(db.radioEntries)..where((t) => t.id.equals(id))).write(RadioEntriesCompanion(deleted: const Value(true), updatedAt: _now()));

  // ------------------------------------------------------------ Rollenkarten

  Future<void> saveRole(String exerciseId, RoleCardInput r) async {
    final c = RoleCardsCompanion(
      number: Value(r.number),
      name: Value(r.name.trim()),
      birthDate: Value(r.birthDate),
      age: Value(r.age),
      preExisting: Value(_clean(r.preExisting)),
      illnesses: Value(_clean(r.illnesses)),
      symptoms: Value(_clean(r.symptoms)),
      injuries: Value(_clean(r.injuries)),
      story: Value(_clean(r.story)),
      escalation: Value(encodeEscalation(r.escalation)),
    );
    if (r.id == null) {
      await db.into(db.roleCards).insert(c.copyWith(exerciseId: Value(exerciseId)));
    } else {
      await (db.update(db.roleCards)..where((t) => t.id.equals(r.id!))).write(c.copyWith(updatedAt: _now()));
    }
  }

  Future<void> deleteRole(String id) =>
      (db.update(db.roleCards)..where((t) => t.id.equals(id))).write(RoleCardsCompanion(deleted: const Value(true), updatedAt: _now()));

  // ---------------------------------------------------------------- Material

  Future<void> saveMaterial(String exerciseId, {String? id, required String name, String? location, String? quantity}) async {
    if (id == null) {
      await db.into(db.materialItems).insert(MaterialItemsCompanion.insert(
            exerciseId: exerciseId,
            name: name.trim(),
            location: Value(_clean(location)),
            quantity: Value(_clean(quantity)),
            sortOrder: Value(await _count(db.materialItems, db.materialItems.exerciseId, exerciseId)),
          ));
    } else {
      await (db.update(db.materialItems)..where((t) => t.id.equals(id))).write(MaterialItemsCompanion(
            name: Value(name.trim()),
            location: Value(_clean(location)),
            quantity: Value(_clean(quantity)),
            updatedAt: _now(),
          ));
    }
  }

  Future<void> deleteMaterial(String id) =>
      (db.update(db.materialItems)..where((t) => t.id.equals(id))).write(MaterialItemsCompanion(deleted: const Value(true), updatedAt: _now()));

  // -------------------------------------------------------------- Beobachtung

  Future<void> addObservation(String exerciseId, String description) async {
    await db.into(db.observationItems).insert(ObservationItemsCompanion.insert(
          exerciseId: exerciseId,
          description: description.trim(),
          sortOrder: Value(await _count(db.observationItems, db.observationItems.exerciseId, exerciseId)),
        ));
  }

  Future<void> updateObservation(String id, {String? description, String? rating, bool clearRating = false, String? note}) =>
      (db.update(db.observationItems)..where((t) => t.id.equals(id))).write(ObservationItemsCompanion(
            description: description == null ? const Value.absent() : Value(description.trim()),
            rating: clearRating ? const Value(null) : (rating == null ? const Value.absent() : Value(rating)),
            note: note == null ? const Value.absent() : Value(_clean(note)),
            updatedAt: _now(),
          ));

  Future<void> deleteObservation(String id) =>
      (db.update(db.observationItems)..where((t) => t.id.equals(id))).write(ObservationItemsCompanion(deleted: const Value(true), updatedAt: _now()));

  // Katalog
  Stream<List<ObservationTemplate>> watchCatalog() => (db.select(db.observationTemplates)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.category), (t) => OrderingTerm(expression: t.description)]))
      .watch();

  Future<List<ObservationTemplate>> catalog() => (db.select(db.observationTemplates)..where((t) => t.deleted.equals(false))).get();

  Future<void> saveCatalogItem({String? id, required String description, String? category}) async {
    if (id == null) {
      await db.into(db.observationTemplates)
          .insert(ObservationTemplatesCompanion.insert(description: description.trim(), category: Value(_clean(category))));
    } else {
      await (db.update(db.observationTemplates)..where((t) => t.id.equals(id))).write(ObservationTemplatesCompanion(
            description: Value(description.trim()),
            category: Value(_clean(category)),
            updatedAt: _now(),
          ));
    }
  }

  Future<void> deleteCatalogItem(String id) => (db.update(db.observationTemplates)..where((t) => t.id.equals(id)))
      .write(ObservationTemplatesCompanion(deleted: const Value(true), updatedAt: _now()));

  /// Übernimmt Katalogpunkte (gleicher Text wird nicht doppelt angelegt).
  Future<int> importCatalog(List<(String, String?)> items) => db.transaction(() async {
        final have = {for (final c in await catalog()) c.description.toLowerCase()};
        var n = 0;
        for (final (d, cat) in items) {
          if (d.trim().isEmpty || have.contains(d.trim().toLowerCase())) continue;
          await saveCatalogItem(description: d, category: cat);
          have.add(d.trim().toLowerCase());
          n++;
        }
        return n;
      });

  // ---------------------------------------------------------- Nachbesprechung

  Future<void> setDebrief(String exerciseId, {List<String>? good, List<String>? bad, String? notes, String? participants}) =>
      (db.update(db.exercises)..where((t) => t.id.equals(exerciseId))).write(ExercisesCompanion(
            debriefGood: good == null ? const Value.absent() : Value(jsonEncode([for (final g in good) if (g.trim().isNotEmpty) g.trim()])),
            debriefBad: bad == null ? const Value.absent() : Value(jsonEncode([for (final g in bad) if (g.trim().isNotEmpty) g.trim()])),
            debriefNotes: notes == null ? const Value.absent() : Value(_clean(notes)),
            debriefParticipants: participants == null ? const Value.absent() : Value(_clean(participants)),
            updatedAt: _now(),
          ));

  Future<void> saveLesson(String exerciseId, {String? id, required String description, String? responsible, String status = 'offen'}) async {
    if (id == null) {
      await db.into(db.lessons).insert(LessonsCompanion.insert(
            exerciseId: exerciseId,
            description: description.trim(),
            responsible: Value(_clean(responsible)),
            status: Value(status),
          ));
    } else {
      await (db.update(db.lessons)..where((t) => t.id.equals(id))).write(LessonsCompanion(
            description: Value(description.trim()),
            responsible: Value(_clean(responsible)),
            status: Value(status),
            updatedAt: _now(),
          ));
    }
  }

  Future<void> setLessonStatus(String id, String status, {String? plannedIn}) =>
      (db.update(db.lessons)..where((t) => t.id.equals(id))).write(LessonsCompanion(
            status: Value(status),
            plannedInExerciseId: Value(plannedIn),
            updatedAt: _now(),
          ));

  Future<void> deleteLesson(String id) =>
      (db.update(db.lessons)..where((t) => t.id.equals(id))).write(LessonsCompanion(deleted: const Value(true), updatedAt: _now()));

  /// Noch nicht erledigte Erkenntnisse aus allen Übungen (für die Übersicht).
  Stream<List<LessonWithSource>> watchOpenLessons() {
    final q = db.select(db.lessons).join([innerJoin(db.exercises, db.exercises.id.equalsExp(db.lessons.exerciseId))])
      ..where(db.lessons.deleted.equals(false) &
          db.exercises.deleted.equals(false) &
          db.exercises.isTemplate.equals(false) &
          db.lessons.status.isNotIn(['erledigt']))
      ..orderBy([OrderingTerm(expression: db.exercises.date, mode: OrderingMode.desc)]);
    return q.watch().map((rows) => [for (final r in rows) LessonWithSource(r.readTable(db.lessons), r.readTable(db.exercises))]);
  }
}
