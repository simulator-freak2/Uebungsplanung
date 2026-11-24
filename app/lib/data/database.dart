import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'lead_functions.dart';

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

  // ab Schema-Version 3
  /// `praxis`, `theorie`, `sonderdienst`, `jugend`
  TextColumn get category => text().withDefault(const Constant('praxis'))();

  /// Vorlage statt echter Übung (Datum ist dann ohne Bedeutung).
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();

  // Nachbesprechung
  TextColumn get debriefGood => text().withDefault(const Constant('[]'))();
  TextColumn get debriefBad => text().withDefault(const Constant('[]'))();
  TextColumn get debriefNotes => text().nullable()();
  TextColumn get debriefParticipants => text().nullable()();

  // ab Schema-Version 4: Lageskizze
  RealColumn get mapLat => real().nullable()();
  RealColumn get mapLon => real().nullable()();
  RealColumn get mapZoom => real().nullable()();

  /// Eingezeichnete Elemente als JSON (siehe `SketchItem`).
  TextColumn get sketch => text().withDefault(const Constant('[]'))();

  /// Bild der Lageskizze für die Übungsmappe (PNG, Base64).
  TextColumn get sketchPng => text().nullable()();
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

  // ab Schema-Version 5: Reservierung in Materialkompass
  TextColumn get reservationId => text().nullable()();

  /// `angefragt`, `bestaetigt`, `abgelehnt`, `storniert`
  TextColumn get reservationStatus => text().nullable()();
  TextColumn get reservationNote => text().nullable()();
}

/// Zwischenspeicher des Materials aus Materialkompass (nur auf diesem Gerät,
/// wird nicht über den Übungsplaner-Server abgeglichen).
class MkMaterials extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get inventoryNo => text().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get vehicleId => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get status => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Person auf einer Funktion (Fahrzeugfunktion oder Führungsfunktion).
/// Eine Person darf mehrere Funktionen haben.
class ExerciseAssignments extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get functionId => text()();
  TextColumn get personId => text()();
}

/// Führungs- bzw. Sonderfunktion einer Übung (ab Schema-Version 6).
///
/// Jede Übung hat ihre eigenen Führungsfunktionen; Namen dürfen mehrfach
/// vorkommen (z. B. zwei Gruppenführer). Über [parentId] entsteht die
/// Führungsstruktur für das Organigramm. Die Person kommt aus der Besetzung
/// ([ExerciseAssignments] mit dieser ID als `functionId`), der Funkrufname
/// aus dem verknüpften Funkplan-Eintrag ([radioEntryId]).
class ExerciseLeadFunctions extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get name => text()();
  TextColumn get requiredQualificationId => text().nullable()();

  /// Übergeordnete Führungsfunktion; `null` = oberste Ebene (Einsatzleiter).
  TextColumn get parentId => text().nullable()();

  /// Geführtes Fahrzeug (Stammdaten-ID); `null` = aus der Besetzung ableiten.
  TextColumn get vehicleId => text().nullable()();

  /// Verknüpfter Eintrag im Funkplan (Funkrufname).
  TextColumn get radioEntryId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // ab Schema-Version 7
  /// Rubrik: `fuehrung` (Organigramm) oder `durchfuehrung` (Übungsleitung,
  /// Beobachter, Mimenbetreuung …).
  TextColumn get kind => text().withDefault(const Constant('fuehrung'))();
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

// ---------------------------------------------------------------------------
// Übungsunterlagen (ab Schema-Version 3)
// ---------------------------------------------------------------------------

/// Funkplan-Eintrag.
class RadioEntries extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get callSign => text()();
  TextColumn get device => text().nullable()();

  /// `bos_digital`, `bos_analog`, `dlrg_betriebsfunk`
  TextColumn get network => text().withDefault(const Constant('bos_digital'))();
  TextColumn get channel => text().nullable()();
  TextColumn get task => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Rollenkarte für eine Mime / einen Darsteller.
class RoleCards extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  IntColumn get number => integer().withDefault(const Constant(1))();
  TextColumn get name => text()();
  DateTimeColumn get birthDate => dateTime().nullable()();

  /// Alter, falls kein Geburtsdatum angegeben ist.
  IntColumn get age => integer().nullable()();
  TextColumn get preExisting => text().nullable()();
  TextColumn get illnesses => text().nullable()();
  TextColumn get symptoms => text().nullable()();
  TextColumn get injuries => text().nullable()();
  TextColumn get story => text().nullable()();

  /// Eskalationsstufen als JSON-Liste von {"stufe", "ausloeser", "verhalten"}.
  TextColumn get escalation => text().withDefault(const Constant('[]'))();
}

class MaterialItems extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get name => text()();
  TextColumn get location => text().nullable()();
  TextColumn get quantity => text().nullable()();

  /// `manuell` oder später `materialkompass`
  TextColumn get source => text().withDefault(const Constant('manuell'))();
  TextColumn get externalId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Beobachtungspunkt einer Übung mit Bewertung.
class ObservationItems extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get description => text()();

  /// `++`, `+`, `o`, `-` oder leer
  TextColumn get rating => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Zentraler Katalog von Beobachtungspunkten.
class ObservationTemplates extends Table with SyncColumns {
  TextColumn get description => text()();
  TextColumn get category => text().nullable()();
}

/// Maßnahme / Erkenntnis aus der Nachbesprechung.
class Lessons extends Table with SyncColumns {
  TextColumn get exerciseId => text()();
  TextColumn get description => text()();
  TextColumn get responsible => text().nullable()();

  /// `offen`, `eingeplant`, `erledigt`
  TextColumn get status => text().withDefault(const Constant('offen'))();

  /// Übung, in die die Erkenntnis übernommen wurde.
  TextColumn get plannedInExerciseId => text().nullable()();
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
  ExerciseLeadFunctions,
  ExercisePhases,
  ExerciseSafetyChecks,
  ExerciseVehicles,
  ExerciseAssignments,
  AlarmPlanEntries,
  RadioEntries,
  RoleCards,
  MaterialItems,
  ObservationItems,
  ObservationTemplates,
  Lessons,
  MkMaterials,
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
  int get schemaVersion => 7;

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
          if (from < 3) {
            // Bei Version 1 wurde die Übungstabelle eben schon vollständig angelegt.
            for (final c in from < 2 ? const <GeneratedColumn<Object>>[] : <GeneratedColumn<Object>>[
              exercises.category,
              exercises.isTemplate,
              exercises.debriefGood,
              exercises.debriefBad,
              exercises.debriefNotes,
              exercises.debriefParticipants,
            ]) {
              await m.addColumn(exercises, c);
            }
            final List<TableInfo<Table, Object?>> added = [radioEntries, roleCards, materialItems, observationItems, observationTemplates, lessons];
            for (final t in added) {
              await m.createTable(t);
            }
          }
          if (from < 5) {
            await m.createTable(mkMaterials);
          }
          if (from >= 2 && from < 5) {
            for (final c in <GeneratedColumn<Object>>[exerciseVehicles.reservationId, exerciseVehicles.reservationStatus, exerciseVehicles.reservationNote]) {
              await m.addColumn(exerciseVehicles, c);
            }
          }
          if (from >= 2 && from < 4) {
            for (final c in <GeneratedColumn<Object>>[exercises.mapLat, exercises.mapLon, exercises.mapZoom, exercises.sketch, exercises.sketchPng]) {
              await m.addColumn(exercises, c);
            }
          }
          // Zuletzt, weil hier schon mit dem vollständigen Schema gelesen wird.
          if (from < 6) {
            await m.createTable(exerciseLeadFunctions);
            if (from >= 2) await migrateLeadFunctions(this);
          } else if (from < 7) {
            await m.addColumn(exerciseLeadFunctions, exerciseLeadFunctions.kind);
            await migrateRunFunctions(this);
          }
        },
      );

  static DateTime now() => DateTime.now().toUtc();
}
