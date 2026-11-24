import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';
import 'exercise_repository.dart';
import 'lead_functions.dart';
import 'repositories.dart';

/// Austauschformat für Vorlagen (`.uebung.json`).
///
/// Personen werden nie exportiert. Fahrzeuge, Besetzungsmuster und das
/// Alarmstichwort werden über ihre Namen beschrieben und beim Import den
/// eigenen Stammdaten zugeordnet; was es dort nicht gibt, wird übersprungen.
const templateFormat = 'uebungsplaner-vorlage';
const templateVersion = 1;

Future<String> exportTemplate(Repositories repo, String exerciseId) async {
  final d = (await repo.exercises.detail(exerciseId))!;
  final e = d.exercise;
  final vehicles = await repo.vehicles.watchAllDetails().first;
  String? vehicleName(String? id) => id == null ? null : vehicles[id]?.vehicle?.name;
  String? patternName(String vehicleId, String? patternId) =>
      vehicles[vehicleId]?.patterns.where((p) => p.id == patternId).firstOrNull?.name;

  final quals = {for (final q in await repo.qualifications.all()) q.id: q.name};
  final leadIndex = {for (var i = 0; i < d.leads.length; i++) d.leads[i].id: i};
  final radio = {for (final r in d.radio) r.id: r.callSign};
  final json = {
    'format': templateFormat,
    'version': templateVersion,
    'titel': e.title,
    'kategorie': e.category,
    'beginn': e.startMinutes,
    'ende': e.endMinutes,
    'ort': e.location,
    'einheit': e.unit,
    'thema': e.topic,
    'stichwort': d.keyword?.code,
    'lernziele': d.goals,
    'lage': e.scenario,
    'zeitanzeige': e.timeMode,
    'alarm': {'adresse': e.alarmAddress, 'melder': e.alarmReporter, 'sonderrechte': e.alarmSpecialRights, 'fahrzeuge': e.alarmVehicles},
    'ablauf': [for (final p in d.phases) {'minuten': p.offsetMinutes, 'text': p.description}],
    'sicherheit': [for (final c in d.checks) c.description],
    'fahrzeuge': [
      for (final v in d.vehicles)
        if (vehicleName(v.vehicleId) != null) {'name': vehicleName(v.vehicleId), 'muster': patternName(v.vehicleId, v.patternId)},
    ],
    'alarmierungsplan': [
      for (final a in d.alarmPlan)
        {
          'einheit': a.label,
          'art': a.kind,
          'fahrzeug': vehicleName(a.vehicleId),
          'alarm': a.alarmOffset,
          'ausruecken': a.departOffset,
          'ankunft': a.arriveOffset,
          'hinweis': a.note,
        },
    ],
    'funkplan': [
      for (final r in d.radio) {'rufname': r.callSign, 'geraet': r.device, 'netz': r.network, 'kanal': r.channel, 'aufgabe': r.task},
    ],
    'fuehrung': [
      for (final l in d.leads)
        {
          'funktion': l.name,
          'qualifikation': quals[l.requiredQualificationId],
          'unterstellt': leadIndex[l.parentId],
          'fahrzeug': vehicleName(l.vehicleId),
          'rufname': radio[l.radioEntryId],
        },
    ],
    'rollenkarten': [
      for (final r in d.roles)
        {
          'nr': r.number,
          'name': r.name,
          'geburtsdatum': r.birthDate?.toIso8601String().substring(0, 10),
          'alter': r.age,
          'vorerkrankungen': r.preExisting,
          'erkrankungen': r.illnesses,
          'symptome': r.symptoms,
          'verletzungen': r.injuries,
          'story': r.story,
          'eskalation': jsonDecode(r.escalation),
        },
    ],
    'material': [for (final m in d.material) {'name': m.name, 'standort': m.location, 'menge': m.quantity}],
    'karte': {'lat': e.mapLat, 'lon': e.mapLon, 'zoom': e.mapZoom},
    'lageskizze': jsonDecode(e.sketch),
    'beobachtung': [for (final o in d.observations) o.description],
  };
  return const JsonEncoder.withIndent('  ').convert(json);
}

class TemplateImportResult {
  TemplateImportResult(this.exerciseId, this.skipped);
  final String exerciseId;

  /// Hinweise auf nicht zugeordnete Fahrzeuge, Muster oder Stichworte.
  final List<String> skipped;
}

/// Legt aus einer Vorlagendatei eine neue Vorlage an.
Future<TemplateImportResult> importTemplate(Repositories repo, String text) async {
  final j = jsonDecode(text) as Map<String, dynamic>;
  if (j['format'] != templateFormat) throw const FormatException('Keine Übungsplaner-Vorlage');
  final db = repo.db;
  final skipped = <String>[];
  final vehicles = await repo.vehicles.watchAllDetails().first;
  String norm(Object? s) => '${s ?? ''}'.trim().toLowerCase();
  VehicleDetail? findVehicle(Object? name) =>
      vehicles.values.where((v) => v.vehicle != null && norm(v.vehicle!.name) == norm(name)).firstOrNull;
  final keywords = await repo.keywords.all();
  final kw = j['stichwort'] == null ? null : keywords.where((k) => norm(k.code) == norm(j['stichwort'])).firstOrNull;
  if (j['stichwort'] != null && kw == null) skipped.add('Alarmstichwort „${j['stichwort']}“');
  List<Map<String, dynamic>> list(String key) => [for (final x in (j[key] as List? ?? const [])) x as Map<String, dynamic>];
  String? s(Object? v) => v == null || '$v'.trim().isEmpty ? null : '$v';

  final id = await db.transaction(() async {
    final alarm = (j['alarm'] as Map<String, dynamic>?) ?? const {};
    final row = await db.into(db.exercises).insertReturning(ExercisesCompanion.insert(
          title: '${j['titel'] ?? 'Vorlage'}',
          date: DateTime.now(),
          startMinutes: Value((j['beginn'] as num?)?.toInt() ?? 19 * 60),
          endMinutes: Value((j['ende'] as num?)?.toInt()),
          location: Value(s(j['ort'])),
          unit: Value(s(j['einheit'])),
          topic: Value(s(j['thema'])),
          keywordId: Value(kw?.id),
          goals: Value(jsonEncode(j['lernziele'] ?? const [])),
          scenario: Value(s(j['lage'])),
          timeMode: Value(j['zeitanzeige'] == 'relativ' ? 'relativ' : 'uhrzeit'),
          alarmAddress: Value(s(alarm['adresse'])),
          alarmReporter: Value(s(alarm['melder'])),
          alarmSpecialRights: Value(alarm['sonderrechte'] as bool?),
          alarmVehicles: Value(s(alarm['fahrzeuge'])),
          category: Value(s(j['kategorie']) ?? 'praxis'),
          isTemplate: const Value(true),
          mapLat: Value(((j['karte'] as Map?)?['lat'] as num?)?.toDouble()),
          mapLon: Value(((j['karte'] as Map?)?['lon'] as num?)?.toDouble()),
          mapZoom: Value(((j['karte'] as Map?)?['zoom'] as num?)?.toDouble()),
          sketch: Value(jsonEncode(j['lageskizze'] ?? const [])),
        ));
    final id = row.id;
    final ex = repo.exercises;
    for (final p in list('ablauf')) {
      await ex.savePhase(id, offset: (p['minuten'] as num?)?.toInt() ?? 0, text: '${p['text'] ?? ''}');
    }
    for (final c in (j['sicherheit'] as List? ?? const [])) {
      await ex.addCheck(id, '$c');
    }
    for (final v in list('fahrzeuge')) {
      final vd = findVehicle(v['name']);
      if (vd == null) {
        skipped.add('Fahrzeug „${v['name']}“');
        continue;
      }
      final pattern = vd.patterns.where((p) => norm(p.name) == norm(v['muster'])).firstOrNull;
      if (v['muster'] != null && pattern == null) skipped.add('Besetzungsmuster „${v['muster']}“ bei ${vd.vehicle!.name}');
      await ex.addVehicle(id, vd.vehicle!.id, patternId: pattern?.id ?? vd.patterns.firstOrNull?.id);
    }
    for (final a in list('alarmierungsplan')) {
      await ex.saveAlarmEntry(
        id,
        AlarmEntryInput(
          label: '${a['einheit'] ?? ''}',
          kind: s(a['art']) ?? 'fahrzeug',
          vehicleId: findVehicle(a['fahrzeug'])?.vehicle?.id,
          alarmOffset: (a['alarm'] as num?)?.toInt() ?? 0,
          departOffset: (a['ausruecken'] as num?)?.toInt(),
          arriveOffset: (a['ankunft'] as num?)?.toInt(),
          note: s(a['hinweis']),
        ),
      );
    }
    final docs = repo.documents;
    for (final r in list('funkplan')) {
      await docs.saveRadio(id, callSign: '${r['rufname'] ?? ''}', device: s(r['geraet']), network: s(r['netz']) ?? 'bos_digital', channel: s(r['kanal']), task: s(r['aufgabe']));
    }
    // Führungsstruktur; ältere Dateien ohne Angabe bekommen die Vorgabe.
    final leads = list('fuehrung');
    if (j['fuehrung'] == null) await ex.ensureDefaultLead(id);
    final leadIds = <int, String>{};
    for (var i = 0; i < leads.length; i++) {
      final l = leads[i];
      final qual = s(l['qualifikation']);
      final vehicle = l['fahrzeug'] == null ? null : findVehicle(l['fahrzeug']);
      if (l['fahrzeug'] != null && vehicle == null) skipped.add('Fahrzeug „${l['fahrzeug']}“ bei ${l['funktion']}');
      leadIds[i] = await ex.saveLead(
        id,
        LeadInput(
          name: s(l['funktion']) ?? defaultLeadName,
          qualificationId: qual == null ? null : await repo.qualifications.ensure(qual),
          vehicleId: vehicle?.vehicle?.id,
          callSign: s(l['rufname']),
        ),
      );
    }
    // Unterstellung erst danach, weil Vorgesetzte auch später in der Liste stehen dürfen.
    for (var i = 0; i < leads.length; i++) {
      final parent = leadIds[(leads[i]['unterstellt'] as num?)?.toInt()];
      if (parent != null) await ex.setLeadParent(id, leadIds[i]!, parent);
    }
    for (final r in list('rollenkarten')) {
      await db.into(db.roleCards).insert(RoleCardsCompanion.insert(
            exerciseId: id,
            number: Value((r['nr'] as num?)?.toInt() ?? 1),
            name: '${r['name'] ?? ''}',
            birthDate: Value(r['geburtsdatum'] == null ? null : DateTime.tryParse('${r['geburtsdatum']}')),
            age: Value((r['alter'] as num?)?.toInt()),
            preExisting: Value(s(r['vorerkrankungen'])),
            illnesses: Value(s(r['erkrankungen'])),
            symptoms: Value(s(r['symptome'])),
            injuries: Value(s(r['verletzungen'])),
            story: Value(s(r['story'])),
            escalation: Value(jsonEncode(r['eskalation'] ?? const [])),
          ));
    }
    for (final m in list('material')) {
      await docs.saveMaterial(id, name: '${m['name'] ?? ''}', location: s(m['standort']), quantity: s(m['menge']));
    }
    for (final o in (j['beobachtung'] as List? ?? const [])) {
      await docs.addObservation(id, '$o');
    }
    return id;
  });
  return TemplateImportResult(id, skipped);
}
