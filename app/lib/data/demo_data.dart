import 'documents_repository.dart';
import 'exercise_repository.dart';
import 'lead_functions.dart';
import 'profile.dart';
import 'repositories.dart';

/// Ob Beispieldaten angeboten werden: nur bei leerem Bestand.
/// Beispieldaten gibt es für die Profile Feuerwehr und DLRG.
Future<bool> canLoadDemo(Repositories repo) async =>
    const {'feuerwehr', 'dlrg', null}.contains(await repo.settings.get(SettingsRepository.profileId)) &&
    (await repo.persons.all()).isEmpty &&
    (await repo.exercises.watchAll().first).isEmpty;

/// Fiktive Beispieldaten zum Ausprobieren (Personal, Fahrzeuge, Stichworte,
/// Dienstplan und eine vollständig ausgearbeitete Übung).
Future<void> loadDemoData(Repositories repo, OrgProfile profile) async {
  final fw = profile.id == 'feuerwehr';
  final q = repo.qualifications.ensure;
  final year = DateTime.now().year + (DateTime.now().month >= 11 ? 1 : 0);

  // Personal
  final people = fw
      ? [
          ('Hahn', 'Felix', 'FW-0003', ['Zugführer', 'Gruppenführer', 'Truppführer']),
          ('Becker', 'Jonas', 'FW-0012', ['Gruppenführer', 'Truppführer', 'Atemschutzgeräteträger', 'Maschinist']),
          ('Schulz', 'Lena', 'FW-0031', ['Truppführer', 'Atemschutzgeräteträger', 'Sprechfunker']),
          ('Wagner', 'Tim', 'FW-0044', ['Truppmann', 'Atemschutzgeräteträger']),
          ('Hoffmann', 'Mia', 'FW-0052', ['Truppführer', 'Maschinist', 'Technische Hilfeleistung']),
          ('Klein', 'David', 'FW-0060', ['Truppmann', 'Sprechfunker']),
          ('Wolf', 'Sara', 'FW-0071', ['Truppführer', 'Atemschutzgeräteträger', 'Technische Hilfeleistung']),
          ('Neumann', 'Paul', 'FW-0083', ['Truppmann']),
          ('Krüger', 'Emma', 'FW-0090', ['Truppführer', 'Sprechfunker']),
          ('Jung', 'Laura', 'FW-0101', ['Truppmann', 'Sanitäter']),
          ('Braun', 'Leon', 'JF-0007', ['Jugendflamme 2']),
        ]
      : [
          ('Lange', 'Ella', 'D-1177', ['Gruppenführer Wasserrettung', 'DRSA Silber', 'Sprechfunker']),
          ('Fischer', 'Anna', 'D-1103', ['DRSA Silber', 'Wasserretter', 'Bootsführer A', 'Strömungsretter 2']),
          ('Meyer', 'Lukas', 'D-1120', ['DRSA Silber', 'Bootsführer A', 'Sprechfunker']),
          ('Schmitt', 'Jana', 'D-1134', ['DRSA Gold', 'Wasserretter', 'Sanitäter']),
          ('Weber', 'Noah', 'D-1141', ['DRSA Silber', 'Strömungsretter 1']),
          ('Richter', 'Pia', 'D-1158', ['DRSA Silber', 'Wasserretter', 'Einsatztaucher']),
          ('Koch', 'Ben', 'D-1162', ['DRSA Bronze']),
          ('Zimmer', 'Finn', 'J-0021', ['Juniorretter']),
        ];
  final personIds = <String, String>{};
  for (final (last, first, no, quals) in people) {
    personIds[last] = await repo.persons.save(PersonInput(
      lastName: last,
      firstName: first,
      personnelNo: no,
      youth: no.startsWith('J'),
      qualificationIds: {for (final x in quals) await q(x)},
    ));
  }

  // Fahrzeuge aus den Vorlagen
  final vehicles = <String, String>{};
  final wanted = fw ? {'HLF 20': '1/46-1', 'RW': '1/52-1', 'ELW 1': '1/10', 'LF 10': '2/44-1'} : {'Motorrettungsboot (MRB)': '87/1', 'GW-Wasserrettung': '87/2'};
  for (final tpl in profile.vehicleTemplates.where((t) => wanted.containsKey(t.type))) {
    final name = tpl.type == 'Motorrettungsboot (MRB)' ? 'MRB Musterstadt 1' : tpl.type;
    vehicles[tpl.type] = await repo.vehicles.createFromTemplate(
      tpl,
      name: name,
      callSign: '${fw ? 'Florian' : 'Pelikan'} Musterstadt ${wanted[tpl.type]}',
      ensureQualification: q,
    );
  }

  // Alarmstichworte (fiktive Beispiele)
  final keywords = fw
      ? [
          KeywordInput(code: 'B 1', category: 'Brand', description: 'Kleinbrand', resources: 'HLF'),
          KeywordInput(code: 'B 2', category: 'Brand', description: 'Mittelbrand, z. B. Wohnung', resources: 'HLF, DLK, ELW 1'),
          KeywordInput(code: 'TH 1', category: 'Hilfeleistung', description: 'Kleine technische Hilfe', resources: 'HLF', specialRights: false),
          KeywordInput(code: 'TH 2 – VU P eingeklemmt', category: 'Hilfeleistung', description: 'Verkehrsunfall, Person eingeklemmt', resources: 'HLF, RW, ELW 1'),
          KeywordInput(code: 'ABC 1', category: 'Gefahrgut', description: 'Austritt geringer Mengen', resources: 'HLF'),
        ]
      : [
          KeywordInput(code: 'WASS 1', category: 'Wasserrettung', description: 'Person im Wasser, Ort bekannt', resources: 'GW-WR, MRB'),
          KeywordInput(code: 'WASS 2 – Person vermisst', category: 'Wasserrettung', description: 'Person im Wasser vermisst', resources: 'GW-WR, MRB, Taucher'),
          KeywordInput(code: 'EIS 1', category: 'Eisrettung', description: 'Person im Eis eingebrochen', resources: 'GW-WR'),
        ];
  final kwIds = <String>[];
  for (final k in keywords) {
    kwIds.add(await repo.keywords.save(k));
  }

  // Beobachtungskatalog
  await repo.documents.importCatalog(fw
      ? [
          ('Absicherung der Einsatzstelle', 'Technische Hilfeleistung'),
          ('Erkundung und Lagemeldung innerhalb von 5 Minuten', 'Führung'),
          ('Betreuung der Patienten', 'Patient'),
          ('Funkdisziplin', 'Kommunikation'),
          ('Eigensicherung', 'Sicherheit'),
        ]
      : [
          ('Uferposten eingerichtet und mit Funk besetzt', 'Organisation'),
          ('Suchmuster abgesprochen und eingehalten', 'Suche'),
          ('Kommunikation Boot – Ufer', 'Kommunikation'),
          ('Eigensicherung im Wasser', 'Sicherheit'),
          ('Übergabe an den Rettungsdienst', 'Patient'),
        ]);

  // Dienstplan
  final plan = fw
      ? [
          (1, 13, 'Unterweisung UVV & Jahresplanung', 'theorie'),
          (2, 10, 'Funkübung BOS digital und analog', 'praxis'),
          (4, 7, 'Absturzsicherung', 'praxis'),
          (5, 19, 'JF: Leistungsspange Vorbereitung', 'jugend'),
          (6, 16, 'Gemeinsame Übung mit DLRG: Wasserrettung', 'sonderdienst'),
          (9, 8, 'Atemschutz: Menschenrettung', 'praxis'),
          (11, 3, 'Theorie: FwDV 3', 'theorie'),
        ]
      : [
          (1, 15, 'Jahresplanung & Unterweisung', 'theorie'),
          (3, 12, 'Funkausbildung BOS & Betriebsfunk', 'theorie'),
          (4, 16, 'Bootsdienst: Manöver & Anlegen', 'praxis'),
          (6, 16, 'Gemeinsame Übung mit Feuerwehr: Wasserrettung', 'sonderdienst'),
          (10, 14, 'Jugend: Rettungsschwimmen spielerisch', 'jugend'),
        ];
  final checks = profile.safetyChecklist;
  for (final (m, d, title, cat) in plan) {
    await repo.exercises.create(ExerciseInput(title: title, date: DateTime(year, m, d), startMinutes: 19 * 60, endMinutes: 21 * 60 + 30, category: cat), safetyChecklist: checks);
  }

  // Vollständig ausgearbeitete Übung
  final ex = repo.exercises, docs = repo.documents;
  final id = await ex.create(
    ExerciseInput(
      title: fw ? 'THL: Verkehrsunfall mit eingeklemmter Person' : 'Vermisstensuche Badesee',
      date: DateTime(year, 3, fw ? 10 : 24),
      startMinutes: fw ? 19 * 60 : 18 * 60,
      endMinutes: fw ? 21 * 60 + 30 : 21 * 60,
      location: fw ? 'Übungsgelände Bauhof, Industriestraße 12, Musterstadt' : 'Badesee Musterstadt, Nordufer Steg 2',
      unit: fw ? 'Löschzug 1' : 'Wasserrettungszug',
      topic: fw ? 'Technische Hilfeleistung' : 'Wasserrettung / Suche',
      keywordId: fw ? kwIds[3] : kwIds[1],
    ),
    safetyChecklist: checks,
  );
  await ex.setGoals(
      id,
      fw
          ? ['Sicheres Absichern der Einsatzstelle', 'Patientengerechte Rettung', 'Lagemeldung über Funk innerhalb von 5 Minuten']
          : ['Strukturierte Oberflächensuche mit Boot und Wasserrettern', 'Uferposten mit Funk einrichten', 'Übergabe an den Rettungsdienst']);
  await ex.setScenario(
      id,
      fw
          ? 'PKW ist frontal gegen einen Baum geprallt. Fahrer eingeklemmt, Beifahrerin läuft verwirrt umher. Auslaufende Betriebsstoffe. Dunkelheit, leichter Regen.'
          : 'Zeugen melden ein Kind, das zuletzt vor ca. 10 Minuten an der Badeinsel gesehen wurde. Mutter am Ufer aufgelöst. Sicht im Wasser ca. 1 m.');
  for (final (off, text) in fw
      ? [(0, 'Begrüßung, Sicherheitseinweisung, Ausgabe Rollenkarten'), (15, 'Übungsalarm'), (25, 'Erkundung, Absicherung, Brandschutz'), (60, 'Rettung'), (105, 'Rückbau, Gerätepflege'), (120, 'Nachbesprechung')]
      : [(0, 'Einweisung, Sicherheit, Ausgabe Rollenkarten'), (20, 'Übungsalarm'), (45, 'Oberflächensuche nach Suchmuster'), (90, 'Fund, Rettung, Übergabe'), (160, 'Nachbesprechung')]) {
    await ex.savePhase(id, offset: off, text: text);
  }
  // Besetzung
  final all = await repo.vehicles.watchAllDetails().first;
  Future<void> crew(String type, String pattern, Map<String, String> who) async {
    final vd = all[vehicles[type]];
    if (vd == null) return;
    final p = vd.patterns.where((x) => x.name == pattern).firstOrNull;
    await ex.addVehicle(id, vd.vehicle!.id, patternId: p?.id);
    for (final e in who.entries) {
      final f = vd.functions.where((x) => x.name == e.key).firstOrNull;
      if (f != null && personIds[e.value] != null) await ex.assign(id, functionId: f.id, personId: personIds[e.value]!);
    }
  }

  if (fw) {
    await crew('HLF 20', 'Staffel (1/5)', {'Gruppenführer': 'Becker', 'Maschinist': 'Hoffmann', 'Angriffstruppführer': 'Schulz', 'Angriffstruppmann': 'Wagner', 'Wassertruppführer': 'Wolf', 'Wassertruppmann': 'Neumann'});
    await crew('RW', 'Trupp (1/2)', {'Fahrzeugführer': 'Krüger', 'Maschinist': 'Klein'});
  } else {
    await crew('Motorrettungsboot (MRB)', 'Bootsbesatzung (1/2)', {'Bootsführer': 'Meyer', 'Bootsgast': 'Koch', 'Wasserretter': 'Fischer'});
    await crew('GW-Wasserrettung', 'Wasserrettungstrupp (1/2)', {'Gruppenführer': 'Lange', 'Sanitäter': 'Schmitt'});
  }
  // Führungsstruktur: Einsatzleiter (Vorgabe jeder Übung) und Unterstellte.
  final el = defaultLeadId(id);
  await ex.saveLead(id, LeadInput(id: el, name: defaultLeadName, qualificationId: await repo.qualifications.ensure(fw ? 'Zugführer' : 'Gruppenführer Wasserrettung'), callSign: fw ? 'Florian Musterstadt 1/10-1' : 'Pelikan Musterstadt 87/0'));
  await ex.assign(id, functionId: el, personId: personIds[fw ? 'Hahn' : 'Lange']!);
  Future<void> lead(String name, String? person, {String? vehicle, String? qual}) async {
    final lid = await ex.saveLead(id, LeadInput(name: name, parentId: el, vehicleId: vehicle == null ? null : vehicles[vehicle], qualificationId: qual == null ? null : await repo.qualifications.ensure(qual)));
    if (person != null) await ex.assign(id, functionId: lid, personId: personIds[person]!);
  }

  if (fw) {
    await lead('Gruppenführer', 'Becker', qual: 'Gruppenführer');
    await lead('Fahrzeugführer', 'Krüger', vehicle: 'RW');
  } else {
    await lead('Abschnittsleiter Wasser', 'Meyer', vehicle: 'Motorrettungsboot (MRB)', qual: 'Bootsführer A');
    await lead('Uferposten', null);
  }

  // Übungsdurchführung: Vorgaben besetzen, zweiter Beobachter.
  await ex.assign(id, functionId: runDefaultId(id, 'mime'), personId: personIds[fw ? 'Jung' : 'Schmitt']!);
  await ex.assign(id, functionId: runDefaultId(id, 'ul'), personId: personIds[fw ? 'Wolf' : 'Richter']!);
  await ex.assign(id, functionId: runDefaultId(id, 'beo'), personId: personIds[fw ? 'Hoffmann' : 'Weber']!);
  final beo2 = await ex.saveLead(id, LeadInput(name: 'Übungsbeobachter', kind: LeadKind.run));
  await ex.assign(id, functionId: beo2, personId: personIds[fw ? 'Klein' : 'Koch']!);

  // Alarmierungsplan
  if (fw) {
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'HLF 20', vehicleId: vehicles['HLF 20'], alarmOffset: 15, departOffset: 20, arriveOffset: 25, note: 'Erstalarm'));
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'RW', vehicleId: vehicles['RW'], alarmOffset: 15, departOffset: 22, arriveOffset: 28, note: 'Erstalarm'));
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'Angriffstrupp (HLF)', kind: 'trupp', alarmOffset: 26, arriveOffset: 32, note: 'Einsatz nach Absicherung'));
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'LF 10', vehicleId: vehicles['LF 10'], alarmOffset: 40, departOffset: 46, arriveOffset: 55, note: 'Nachalarmierung durch Einsatzleiter: Ausleuchtung'));
  } else {
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'GW-Wasserrettung', vehicleId: vehicles['GW-Wasserrettung'], alarmOffset: 20, departOffset: 26, arriveOffset: 32, note: 'Erstalarm'));
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'MRB Musterstadt 1', kind: 'boot', vehicleId: vehicles['Motorrettungsboot (MRB)'], alarmOffset: 20, departOffset: 35, arriveOffset: 45));
    await ex.saveAlarmEntry(id, AlarmEntryInput(label: 'Uferposten Nord', kind: 'trupp', alarmOffset: 35, arriveOffset: 42, note: 'Abruf durch Einsatzleiter'));
  }
  await ex.setAlarm(id, address: fw ? 'Industriestraße 12, Musterstadt (Bauhof)' : 'Badesee Musterstadt, Nordufer Steg 2', reporter: fw ? 'Zeuge auf der Straße' : 'Badegast');

  // Funkplan
  if (fw) {
    await docs.saveRadio(id, callSign: 'Florian Musterstadt 1/46-1', device: 'HLF 20', network: 'bos_digital', channel: 'DMO 307', task: 'Einsatzabschnitt Rettung');
    await docs.saveRadio(id, callSign: 'Florian Musterstadt 1/52-1', device: 'RW', network: 'bos_digital', channel: 'DMO 307', task: 'Technik');
    await docs.saveRadio(id, callSign: 'Angriffstrupp', device: 'Handfunkgerät', network: 'bos_analog', channel: 'Kanal 34', task: 'Truppfunk');
  } else {
    await docs.saveRadio(id, callSign: 'Pelikan Musterstadt 87/1', device: 'MRB 1', network: 'bos_digital', channel: 'DMO 315', task: 'Suche auf dem Wasser');
    await docs.saveRadio(id, callSign: 'Pelikan Musterstadt 87/2', device: 'GW-WR', network: 'bos_digital', channel: 'DMO 315', task: 'Einsatzleitung');
    await docs.saveRadio(id, callSign: 'Uferposten Nord', device: 'Handfunkgerät', network: 'dlrg_betriebsfunk', channel: 'Kanal 3', task: 'Beobachtung');
  }

  // Rollenkarten
  if (fw) {
    await docs.saveRole(id, RoleCardInput(
      number: 1,
      name: 'Thomas Berger',
      birthDate: DateTime(1981, 5, 14),
      preExisting: 'Bluthochdruck',
      illnesses: 'Diabetes Typ 2',
      symptoms: 'Starke Schmerzen rechtes Bein, Schwindel, Schweißausbruch',
      injuries: 'Unterschenkelfraktur rechts, Platzwunde Stirn',
      story: 'Auf dem Heimweg von der Spätschicht kurz eingenickt und von der Fahrbahn abgekommen. Ehefrau saß auf dem Beifahrersitz.',
      escalation: const [
        EscalationStage(label: 'Stufe 1', trigger: 'Beginn', behavior: 'Ansprechbar, stöhnt, fragt nach seiner Frau'),
        EscalationStage(label: 'Stufe 2', trigger: 'ohne Betreuung > 5 Min.', behavior: 'Wird panisch, versucht selbst auszusteigen'),
        EscalationStage(label: 'Stufe 3', trigger: 'auf Zeichen der Übungsleitung', behavior: 'Wird schläfrig, antwortet verlangsamt (Unterzuckerung)'),
      ],
    ));
    await docs.saveRole(id, RoleCardInput(
      number: 2,
      name: 'Sabine Berger',
      birthDate: DateTime(1985, 9, 2),
      preExisting: 'keine',
      illnesses: 'Asthma',
      symptoms: 'Schmerzen beim Atmen, Zittern',
      injuries: 'Prellung Brustkorb (Gurtmarke)',
      story: 'Beifahrerin. Konnte selbst aussteigen. Steht unter Schock.',
      escalation: const [
        EscalationStage(label: 'Stufe 1', trigger: 'Beginn', behavior: 'Läuft verwirrt um das Fahrzeug, will zu ihrem Mann'),
        EscalationStage(label: 'Stufe 2', trigger: 'wenn niemand sie betreut', behavior: 'Atemnot, sucht ihr Asthmaspray'),
      ],
    ));
  } else {
    await docs.saveRole(id, RoleCardInput(
      number: 1,
      name: 'Katrin Vogel',
      birthDate: DateTime(1989, 11, 11),
      preExisting: 'keine',
      symptoms: 'Hyperventilation, Kribbeln in den Händen',
      story: 'Ihr Sohn Max (8) wollte zur Badeinsel schwimmen. Sie hat ihn beim Telefonieren aus den Augen verloren.',
      escalation: const [
        EscalationStage(label: 'Stufe 1', trigger: 'Beginn', behavior: 'Aufgelöst, zeigt auf wechselnde Stellen im See'),
        EscalationStage(label: 'Stufe 2', trigger: 'ohne Betreuung > 3 Min.', behavior: 'Will selbst ins Wasser, muss zurückgehalten werden'),
        EscalationStage(label: 'Stufe 3', trigger: 'auf Zeichen der Übungsleitung', behavior: 'Hyperventiliert, braucht Betreuung durch Sanitäter'),
      ],
    ));
  }

  // Material
  for (final (name, loc, qty) in fw
      ? [('Hydraulischer Rettungssatz', 'RW', '1'), ('Unterbaumaterial / Stab-Fast', 'HLF 20', '1'), ('Glasmanagement-Set', 'HLF 20', '1'), ('Übungs-PKW (Schrott)', 'Bauhof', '1'), ('Kunstblut, Schminkset', 'Übungskiste', '1')]
      : [('Rettungsbrett', 'GW-WR', '2'), ('Wurfsack', 'GW-WR', '4'), ('Schwimmwesten 150 N', 'GW-WR', '8'), ('Übungspuppe (Kind)', 'Lager', '1')]) {
    await docs.saveMaterial(id, name: name, location: loc, quantity: qty);
  }
  // Beobachtungspunkte aus dem Katalog
  for (final c in await docs.catalog()) {
    await docs.addObservation(id, c.description);
  }
}
