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
  int get schemaVersion => 1;

  static DateTime now() => DateTime.now().toUtc();
}
