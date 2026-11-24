import 'package:drift/drift.dart';

import 'database.dart';
import 'exercise_repository.dart';
import 'repositories.dart';

/// Vorgabe, mit der jede Übung beginnt.
const defaultLeadName = 'Einsatzleiter / Einheitsführer';

/// Feste ID der Vorgabe-Führungsfunktion einer Übung. Weil sie aus der
/// Übungs-ID entsteht, legen mehrere Geräte bei der Umstellung denselben
/// Datensatz an – beim Abgleich entstehen keine doppelten Einsatzleiter.
String defaultLeadId(String exerciseId) => '$exerciseId-el';

/// Ist das ein Name für die oberste Führung (Einsatzleiter, Einheitsführer)?
bool isTopLeadName(String name) {
  final n = name.toLowerCase();
  return n.contains('einsatzleit') || n.contains('einheitsführer') || n.contains('einheitsfuehrer');
}

/// Rubriken der Funktionen einer Übung.
abstract final class LeadKind {
  /// Führungsstruktur, erscheint im Organigramm.
  static const command = 'fuehrung';

  /// Übungsdurchführung: Übungsleitung, Beobachter, Mimenbetreuung …
  static const run = 'durchfuehrung';

  static String label(String kind) => kind == run ? 'Übungsdurchführung' : 'Führungs- und Sonderfunktionen';
}

/// Vorgaben der Übungsdurchführung: (ID-Endung, Name, Erkennungsmerkmal).
/// Das Merkmal ordnet gleichnamige Funktionen aus den Stammdaten zu.
const runDefaults = [
  ('ul', 'Übungsleitung', 'übungsleit'),
  ('beo', 'Übungsbeobachter', 'beobacht'),
  ('mime', 'Mimenbetreuung', 'mime'),
  ('sb', 'Sicherheitsbeauftragter', 'sicherheit'),
];

/// Gehört eine Funktion mit diesem Namen zur Übungsdurchführung?
bool isRunName(String name) {
  final n = name.toLowerCase();
  return runDefaults.any((d) => n.contains(d.$3)) || n.contains('darsteller') || n.contains('schiedsrichter');
}

/// Feste ID einer Vorgabe der Übungsdurchführung.
String runDefaultId(String exerciseId, String suffix) => '$exerciseId-$suffix';

/// Legt die Vorgaben der Übungsdurchführung an, soweit die Übung nicht schon
/// eine passende Funktion hat. Gelöschte Vorgaben bleiben gelöscht.
Future<void> ensureRunDefaults(AppDatabase db, String exerciseId) async {
  final existing = await (db.select(db.exerciseLeadFunctions)..where((t) => t.exerciseId.equals(exerciseId))).get();
  final catalog = await (db.select(db.crewFunctions)..where((t) => t.vehicleId.isNull() & t.deleted.equals(false))).get();
  final order = existing.isEmpty ? 0 : existing.map((l) => l.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  for (var i = 0; i < runDefaults.length; i++) {
    final (suffix, name, match) = runDefaults[i];
    final id = runDefaultId(exerciseId, suffix);
    if (existing.any((l) => l.id == id || (!l.deleted && l.name.toLowerCase().contains(match)))) continue;
    final fromCatalog = catalog.where((f) => f.name.toLowerCase().contains(match)).firstOrNull;
    await db.into(db.exerciseLeadFunctions).insert(
          ExerciseLeadFunctionsCompanion.insert(
            id: Value(id),
            exerciseId: exerciseId,
            name: name,
            kind: const Value(LeadKind.run),
            requiredQualificationId: Value(fromCatalog?.requiredQualificationId),
            sortOrder: Value(order + i),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}

/// Umstellung von Schema-Version 6 auf 7: Funktionen der Übungsdurchführung
/// bekommen ihre eigene Rubrik, fehlende Vorgaben werden ergänzt.
Future<void> migrateRunFunctions(AppDatabase db) async {
  final all = await db.select(db.exerciseLeadFunctions).get();
  for (final l in all.where((l) => isRunName(l.name))) {
    await (db.update(db.exerciseLeadFunctions)..where((t) => t.id.equals(l.id)))
        .write(ExerciseLeadFunctionsCompanion(kind: const Value(LeadKind.run), parentId: const Value(null), updatedAt: Value(AppDatabase.now())));
    await (db.update(db.exerciseLeadFunctions)..where((t) => t.parentId.equals(l.id)))
        .write(ExerciseLeadFunctionsCompanion(parentId: Value(l.parentId), updatedAt: Value(AppDatabase.now())));
  }
  for (final e in await (db.select(db.exercises)..where((t) => t.deleted.equals(false))).get()) {
    await ensureRunDefaults(db, e.id);
  }
}

/// Umstellung auf Schema-Version 6: Bisher galten die Führungsfunktionen aus
/// den Stammdaten für alle Übungen. Jetzt hat jede Übung eigene. Jede Übung
/// bekommt den Einsatzleiter / Einheitsführer; bisher besetzte
/// Führungsfunktionen werden mit ihrer Besetzung in die Übung übernommen und
/// dem Einsatzleiter unterstellt. Die IDs sind fest, damit mehrere Geräte
/// dasselbe Ergebnis erzeugen.
Future<void> migrateLeadFunctions(AppDatabase db) async {
  final catalog = await (db.select(db.crewFunctions)
        ..where((t) => t.vehicleId.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
      .get();
  final byId = {for (final f in catalog) f.id: f};
  final topCatalog = catalog.where((f) => !f.deleted && isTopLeadName(f.name)).firstOrNull;
  final exercises = await (db.select(db.exercises)..where((t) => t.deleted.equals(false))).get();
  final assignments = byId.isEmpty
      ? <ExerciseAssignment>[]
      : await (db.select(db.exerciseAssignments)..where((t) => t.deleted.equals(false) & t.functionId.isIn(byId.keys))).get();
  final now = AppDatabase.now();
  for (final e in exercises) {
    final mine = assignments.where((a) => a.exerciseId == e.id).toList();
    final used = catalog.where((f) => mine.any((a) => a.functionId == f.id)).toList();
    final top = used.where((f) => isTopLeadName(f.name)).firstOrNull;
    final elId = defaultLeadId(e.id);
    await db.into(db.exerciseLeadFunctions).insertOnConflictUpdate(ExerciseLeadFunctionsCompanion.insert(
          id: Value(elId),
          exerciseId: e.id,
          name: top?.name ?? defaultLeadName,
          requiredQualificationId: Value((top ?? topCatalog)?.requiredQualificationId),
          sortOrder: const Value(0),
          updatedAt: Value(now),
        ));
    final newIds = <String, String>{if (top != null) top.id: elId};
    var order = 1;
    final takenDefaults = <String>{};
    for (final f in used.where((f) => f != top)) {
      final run = isRunName(f.name);
      // Erste passende Funktion übernimmt die feste ID der Vorgabe.
      final def = run ? runDefaults.where((d) => f.name.toLowerCase().contains(d.$3) && !takenDefaults.contains(d.$1)).firstOrNull : null;
      if (def != null) takenDefaults.add(def.$1);
      final id = def != null ? runDefaultId(e.id, def.$1) : '${e.id}-${f.id}';
      newIds[f.id] = id;
      await db.into(db.exerciseLeadFunctions).insertOnConflictUpdate(ExerciseLeadFunctionsCompanion.insert(
            id: Value(id),
            exerciseId: e.id,
            name: f.name,
            kind: Value(run ? LeadKind.run : LeadKind.command),
            requiredQualificationId: Value(f.requiredQualificationId),
            parentId: Value(run ? null : elId),
            sortOrder: Value(order++),
            updatedAt: Value(now),
          ));
    }
    for (final a in mine) {
      await (db.update(db.exerciseAssignments)..where((t) => t.id.equals(a.id)))
          .write(ExerciseAssignmentsCompanion(functionId: Value(newIds[a.functionId]!), updatedAt: Value(now)));
    }
    await ensureRunDefaults(db, e.id);
  }
}

/// Eingabe für eine Führungsfunktion der Übung.
class LeadInput {
  LeadInput({this.id, required this.name, this.kind = LeadKind.command, this.qualificationId, this.parentId, this.vehicleId, this.callSign});
  final String? id;

  /// [LeadKind.command] oder [LeadKind.run]. Bei bestehenden Funktionen
  /// ohne Bedeutung (die Rubrik bleibt).
  final String kind;
  final String name;
  final String? qualificationId;
  final String? parentId;
  final String? vehicleId;

  /// Funkrufname. `null` = nicht ändern, leer = Verknüpfung lösen.
  final String? callSign;
}

/// Führungsfunktionen in Baumreihenfolge (Eltern vor Kindern) mit Tiefe.
List<(ExerciseLeadFunction, int)> leadsInTreeOrder(List<ExerciseLeadFunction> leads) {
  final ids = {for (final l in leads) l.id};
  final children = <String?, List<ExerciseLeadFunction>>{};
  for (final l in leads) {
    final p = ids.contains(l.parentId) && l.parentId != l.id ? l.parentId : null;
    children.putIfAbsent(p, () => []).add(l);
  }
  final out = <(ExerciseLeadFunction, int)>[];
  final seen = <String>{};
  void walk(String? parent, int depth) {
    for (final l in children[parent] ?? const <ExerciseLeadFunction>[]) {
      if (!seen.add(l.id)) continue;
      out.add((l, depth));
      walk(l.id, depth + 1);
    }
  }

  walk(null, 0);
  // Ringverweise (A unter B unter A) landen auf der obersten Ebene.
  for (final l in leads) {
    if (!seen.contains(l.id)) {
      seen.add(l.id);
      out.add((l, 0));
      walk(l.id, 1);
    }
  }
  return out;
}

/// IDs aller Führungsfunktionen unterhalb von [id] (für die Auswahl der
/// übergeordneten Funktion: diese dürfen es nicht sein).
Set<String> descendantsOf(String id, List<ExerciseLeadFunction> leads) {
  final out = <String>{};
  var frontier = {id};
  while (frontier.isNotEmpty) {
    final next = {for (final l in leads) if (frontier.contains(l.parentId) && !out.contains(l.id) && l.id != id) l.id};
    out.addAll(next);
    frontier = next;
  }
  return out;
}

/// Ein Kästchen im Organigramm.
class OrgNode {
  OrgNode({
    required this.function,
    required this.personName,
    required this.vehicleName,
    required this.vehicleFromCrew,
    required this.callSign,
    required this.qualificationName,
    required this.qualificationMissing,
    required this.children,
  });
  final ExerciseLeadFunction function;
  final String? personName;
  final String? vehicleName;

  /// Fahrzeug nicht fest zugeordnet, sondern aus der Besetzung abgeleitet.
  final bool vehicleFromCrew;
  final String? callSign;
  final String? qualificationName;
  final bool qualificationMissing;
  final List<OrgNode> children;

  String get name => function.name;

  /// Anzahl der Ebenen dieses Teilbaums.
  int get depth => 1 + children.fold(0, (m, c) => c.depth > m ? c.depth : m);
}

/// Setzt das Organigramm aus Führungsfunktionen, Besetzung und Funkplan
/// zusammen.
///
/// * Person: wer in der Besetzung auf der Führungsfunktion sitzt.
/// * Fahrzeug: fest zugeordnet, sonst das Fahrzeug, auf dem die Person in
///   dieser Übung eingeteilt ist.
/// * Funkrufname: verknüpfter Funkplan-Eintrag, sonst der Funkplan-Eintrag
///   bzw. Funkrufname des Fahrzeugs.
List<OrgNode> buildOrgChart(
  ExerciseDetail d, {
  required Map<String?, VehicleDetail> vehicles,
  required Map<String, PersonWithQualifications> persons,
  Map<String, String> qualificationNames = const {},
}) {
  final byFn = d.personsByFunction;
  final radio = {for (final r in d.radio) r.id: r};
  String norm(String? s) => (s ?? '').trim().toLowerCase();

  // Person → Fahrzeug der Übung, auf dem sie eingeteilt ist.
  final vehicleOfPerson = <String, String>{};
  for (final ev in d.vehicles) {
    final vd = vehicles[ev.vehicleId];
    if (vd == null) continue;
    for (final f in vd.functions) {
      for (final p in byFn[f.id] ?? const <String>[]) {
        vehicleOfPerson.putIfAbsent(p, () => ev.vehicleId);
      }
    }
  }

  String? radioForVehicle(Vehicle v) {
    for (final r in d.radio) {
      if (v.callSign != null && norm(r.callSign) == norm(v.callSign)) return r.callSign;
    }
    for (final r in d.radio) {
      if (norm(r.device) == norm(v.name) || (v.type != null && norm(r.device) == norm(v.type))) return r.callSign;
    }
    return v.callSign;
  }

  OrgNode node(ExerciseLeadFunction l, List<OrgNode> children) {
    final pid = byFn[l.id]?.first;
    final person = pid == null ? null : persons[pid];
    final fromCrew = l.vehicleId == null && pid != null && vehicleOfPerson.containsKey(pid);
    final vid = l.vehicleId ?? (pid == null ? null : vehicleOfPerson[pid]);
    final vehicle = vid == null ? null : vehicles[vid]?.vehicle;
    final linked = l.radioEntryId == null ? null : radio[l.radioEntryId];
    final need = l.requiredQualificationId;
    return OrgNode(
      function: l,
      personName: person?.displayName,
      vehicleName: vehicle?.name,
      vehicleFromCrew: fromCrew && vehicle != null,
      callSign: linked?.callSign ?? (vehicle == null ? null : radioForVehicle(vehicle)),
      qualificationName: need == null ? null : qualificationNames[need],
      qualificationMissing: person != null && need != null && !person.qualificationIds.contains(need),
      children: children,
    );
  }

  final ordered = leadsInTreeOrder(d.commandLeads);
  // Von unten nach oben aufbauen.
  final built = <String, OrgNode>{};
  final childrenOf = <String, List<ExerciseLeadFunction>>{};
  final roots = <ExerciseLeadFunction>[];
  for (var i = 0; i < ordered.length; i++) {
    final (l, depth) = ordered[i];
    if (depth == 0) {
      roots.add(l);
    } else {
      // Elternteil ist der letzte Eintrag davor mit Tiefe - 1.
      for (var j = i - 1; j >= 0; j--) {
        if (ordered[j].$2 == depth - 1) {
          childrenOf.putIfAbsent(ordered[j].$1.id, () => []).add(l);
          break;
        }
      }
    }
  }
  OrgNode build(ExerciseLeadFunction l) =>
      built[l.id] ??= node(l, [for (final c in childrenOf[l.id] ?? const <ExerciseLeadFunction>[]) build(c)]);
  return [for (final r in roots) build(r)];
}
