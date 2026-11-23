import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'repositories.dart';

/// Organisationsprofil (Feuerwehr, DLRG …) aus `assets/profile/<id>.json`.
///
/// Enthält nur Katalogdaten: Qualifikationen, Führungsfunktionen und
/// Fahrzeugvorlagen. Weitere Organisationen kommen durch eine neue
/// JSON-Datei hinzu, ohne Programmänderung.
class OrgProfile {
  OrgProfile({required this.id, required this.name, required this.qualifications, required this.leadFunctions, required this.vehicleTemplates, this.safetyChecklist = const []});

  final String id;
  final String name;
  final List<String> qualifications;
  final List<(String, String?)> leadFunctions;
  final List<VehicleTemplate> vehicleTemplates;

  /// Vorgabe für die Sicherheits-Checkliste neuer Übungen.
  final List<String> safetyChecklist;

  static const available = {'feuerwehr': 'Feuerwehr', 'dlrg': 'DLRG', 'thw': 'THW', 'drk': 'DRK', 'wasserwacht': 'Wasserwacht'};

  static Future<OrgProfile> load(String id) async =>
      OrgProfile.fromJson(jsonDecode(await rootBundle.loadString('assets/profile/$id.json')) as Map<String, dynamic>);

  factory OrgProfile.fromJson(Map<String, dynamic> j) {
    (String, String?) pair(dynamic e) => ((e as List)[0] as String, e[1] as String?);
    return OrgProfile(
      id: j['id'] as String,
      name: j['name'] as String,
      qualifications: [for (final q in j['qualifikationen'] as List) q as String],
      leadFunctions: [for (final f in j['fuehrungsfunktionen'] as List) pair(f)],
      safetyChecklist: [for (final c in (j['sicherheitscheck'] as List?) ?? const []) c as String],
      vehicleTemplates: [
        for (final v in j['fahrzeugvorlagen'] as List)
          VehicleTemplate(
            type: v['typ'] as String,
            kind: v['art'] as String? ?? 'fahrzeug',
            functions: [for (final f in v['funktionen'] as List) pair(f)],
            patterns: {
              for (final e in (v['besetzungsmuster'] as Map<String, dynamic>).entries)
                e.key: [for (final f in e.value as List) f as String],
            },
          ),
      ],
    );
  }

  /// Spielt Qualifikationen und Führungsfunktionen ein. Vorhandenes bleibt
  /// erhalten, es wird nur Fehlendes ergänzt.
  Future<void> applyTo(Repositories repo) => repo.db.transaction(() async {
        for (final q in qualifications) {
          await repo.qualifications.ensure(q);
        }
        final existing = (await repo.vehicles.detail(null)).functions.map((f) => f.name.toLowerCase()).toSet();
        for (final (name, qual) in leadFunctions) {
          if (existing.contains(name.toLowerCase())) continue;
          final qid = qual == null ? null : await repo.qualifications.ensure(qual);
          await repo.vehicles.addFunction(null, name, qid);
        }
      });
}
