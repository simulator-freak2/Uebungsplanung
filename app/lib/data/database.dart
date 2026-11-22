import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

/// Gemeinsame Spalten für alle abgleichbaren Datensätze.
///
/// Jeder Datensatz hat eine weltweit eindeutige ID, einen Änderungszeitpunkt
/// und wird beim Löschen nur markiert. So kann später ein Server die Daten
/// zwischen mehreren Geräten abgleichen („letzte Änderung gilt“).
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Einfache Schlüssel/Wert-Einstellungen (Organisationsname, Profil …).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Qualifications extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Persons extends Table with SyncColumns {
  TextColumn get lastName => text()();
  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get personnelNo => text().nullable()();
  BoolColumn get youth => boolean().withDefault(const Constant(false))();
}

class PersonQualifications extends Table with SyncColumns {
  TextColumn get personId => text()();
  TextColumn get qualificationId => text()();
}

class Vehicles extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();

  /// `fahrzeug`, `boot` oder `anhaenger`.
  TextColumn get kind => text().withDefault(const Constant('fahrzeug'))();
  TextColumn get callSign => text().nullable()();

  /// `einsatzbereit`, `bedingt_einsatzbereit`, `ausser_dienst`, `werkstatt`.
  TextColumn get status =>
      text().withDefault(const Constant('einsatzbereit'))();

  /// ID des Fahrzeugs in Materialkompass (später).
  TextColumn get externalId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Funktion auf einem Fahrzeug – oder, wenn [vehicleId] leer ist, eine
/// fahrzeugunabhängige Führungs- bzw. Sonderfunktion (z. B. Einsatzleiter).
class CrewFunctions extends Table with SyncColumns {
  TextColumn get vehicleId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get requiredQualificationId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class CrewPatterns extends Table with SyncColumns {
  TextColumn get vehicleId => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class CrewPatternFunctions extends Table with SyncColumns {
  TextColumn get patternId => text()();
  TextColumn get functionId => text()();
}

/// Alarmstichwort aus der zentralen Stichwortdatenbank.
class Keywords extends Table with SyncColumns {
  TextColumn get code => text()();
  TextColumn get category => text().nullable()();
  TextColumn get description => text().nullable()();

  /// Einsatzmittel laut Alarm- und Ausrückeordnung (AAO), Freitext.
  TextColumn get resources => text().nullable()();
  BoolColumn get specialRights => boolean().withDefault(const Constant(true))();
}

// ---------------------------------------------------------------------------
// Übungen (ab Schema-Version 2)
// ---------------------------------------------------------------------------

class Exercises extends Table with SyncColumns {
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();

  /// Beginn und Ende in Minuten nach Mitternacht (19:00 = 1140).
  IntColumn get startMinutes => integer().withDefault(const Constant(19 * 60))();
  IntColumn get endMinutes => integer().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get topic => text().nullable()();
  TextColumn get keywordId => text().nullable()();

  /// Lernziele als JSON-Liste von Texten.
  TextColumn get goals => text().withDefault(const Constant('[]'))();
  TextColumn get scenario => text().nullable()();

  /// `entwurf`, `zur_freigabe`, `freigegeben`
  TextColumn get status => text().withDefault(const Constant('entwurf'))();
  TextColumn get approvedBy => text().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();

  /// Anzeige der Zeiten im Alarmierungsplan: `uhrzeit` oder `relativ`.
  TextColumn get timeMode => text().withDefault(const Constant('uhrzeit'))();

  // Alarmmeldung (Ausdruck)
  TextColumn get alarmAddress => text().nullable()();
  TextColumn get alarmReporter => text().nullable()();

  /// `null` = Vorgabe aus dem Alarmstichwort übernehmen.
  BoolColumn get alarmSpecialRights => boolean().nullable()();

  /// `null` = aus dem Alarmierungsplan (Erstalarm) übernehmen.
  TextColumn get alarmVehicles => text().nullable()();
}

/// Ablaufphase; Zeit als Minuten relativ zum Übungsbeginn.
class ExercisePhases extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  IntColumn get offsetMinutes => integer().withDefault(const Constant(0))();
  TextColumn get description => text()();
}

class ExerciseSafetyChecks extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get description => text()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Fahrzeug, das an der Übung teilnimmt, mit gewähltem Besetzungsmuster.
class ExerciseVehicles extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get vehicleId => text()();
  TextColumn get patternId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Person auf einer Funktion (Fahrzeugfunktion oder Führungsfunktion).
/// Eine Person darf mehrere Funktionen haben.
class ExerciseAssignments extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get functionId => text()();
  TextColumn get personId => text()();
}

/// Zeile im Alarmierungsplan. Zeiten in Minuten relativ zum Übungsbeginn.
class AlarmPlanEntries extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get label => text()();

  /// `fahrzeug`, `boot` oder `trupp`
  TextColumn get kind => text().withDefault(const Constant('fahrzeug'))();
  TextColumn get vehicleId => text().nullable()();
  IntColumn get alarmOffset => integer()();
  IntColumn get departOffset => integer().nullable()();
  IntColumn get arriveOffset => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [
  Settings,
  Qualifications,
  Persons,
  PersonQualifications,
  Vehicles,
  CrewFunctions,
  CrewPatterns,
  CrewPatternFunctions,
  Keywords,
  Exercises,
  ExercisePhases,
  ExerciseSafetyChecks,
  ExerciseVehicles,
  ExerciseAssignments,
  AlarmPlanEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Öffnet die Datenbankdatei im Anwendungsdatenordner des Benutzers
  /// (Windows: %APPDATA%, macOS: ~/Library/Application Support,
  /// Linux: ~/.local/share).
  factory AppDatabase.open() => AppDatabase(driftDatabase(
        name: 'uebungsplaner',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      ));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            final List<TableInfo<Table, Object?>> added = [exercises, exercisePhases, exerciseSafetyChecks, exerciseVehicles, exerciseAssignments, alarmPlanEntries];
            for (final t in added) {
              await m.createTable(t);
            }
          }
        },
      );

  static DateTime now() => DateTime.now().toUtc();
}
