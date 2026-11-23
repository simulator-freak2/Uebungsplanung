import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';
import 'package:uebungsplaner/data/database.dart';
import 'dart:convert';
import 'dart:io';

import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/profile.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/main.dart';
import 'package:uebungsplaner/sync/sync_service.dart';

/// Wartet, bis [finder] etwas findet (Datenbank und Assets arbeiten asynchron).
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  final shown = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(60).join(' | ');
  throw TestFailure('Nicht gefunden: $finder\nAuf dem Bildschirm: $shown');
}

/// Wartet Datenbank und Animationen (z. B. Wechsel der Reiter) ab.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

/// Reiter sichtbar scrollen, antippen und den Wechsel abwarten.
Future<void> openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Zwischengespeicherte Assets eines vorherigen Tests gehören zu dessen
  // Test-Zone und würden hier nie fertig geladen.
  setUp(rootBundle.clear);

  testWidgets('Erster Start, Person anlegen, Fahrzeug aus Vorlage', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    await tester.pumpWidget(UebungsplanerApp(repo: repo, session: Session(repo)));
    await pumpUntil(tester, find.text('Willkommen im Übungsplaner'));

    // Einrichtung
    expect(find.text('Willkommen im Übungsplaner'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('setup-name')), 'FF Musterstadt');
    await tester.pump();
    await tester.tap(find.byKey(const Key('setup-start')));
    await pumpUntil(tester, find.text('Erste Schritte'));
    await tester.pumpAndSettle();
    expect(find.text('Erste Schritte'), findsOneWidget);
    expect(find.text('FF Musterstadt'), findsWidgets);

    // Person anlegen
    await tester.tap(find.text('Personal'));
    await pumpUntil(tester, find.text('Person'));
    await tester.tap(find.text('Person'));
    await pumpUntil(tester, find.widgetWithText(FilterChip, 'Maschinist'));
    await tester.enterText(find.byKey(const Key('person-last')), 'Becker');
    await tester.enterText(find.byKey(const Key('person-first')), 'Jonas');
    await tester.tap(find.widgetWithText(FilterChip, 'Maschinist'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('person-save')));
    await pumpUntil(tester, find.text('Becker, Jonas'));
    expect(find.text('Becker, Jonas'), findsOneWidget);

    // Fahrzeug aus Vorlage
    await tester.tap(find.text('Fahrzeuge & Funktionen'));
    await pumpUntil(tester, find.text('Einsatzleiter'));
    expect(find.text('Einsatzleiter'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vehicle-add')));
    await pumpUntil(tester, find.byKey(const Key('vehicle-template')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('vehicle-template')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('HLF 20 –').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('vehicle-name'))).controller!.text, 'HLF 20');
    await tester.tap(find.byKey(const Key('vehicle-create')));
    await pumpUntil(tester, find.text('Staffel (1/5)'));
    expect(find.text('Besetzungsmuster'), findsWidgets);
    expect(find.text('Staffel (1/5)'), findsOneWidget);
    expect(find.text('Angriffstruppführer'), findsWidgets);

    // Streams beenden lassen (drift räumt verzögert auf), dann schließen.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    final closing = repo.db.close();
    await tester.pump(const Duration(seconds: 1));
    await closing;
  });

  testWidgets('Übung: anlegen, Fahrzeug besetzen (Drag & Drop), Alarmierung, Freigabe', (tester) async {
    tester.view.physicalSize = const Size(1600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    late String hlf;
    await tester.runAsync(() async {
      final profile = OrgProfile.fromJson(jsonDecode(File('assets/profile/feuerwehr.json').readAsStringSync()) as Map<String, dynamic>);
      await profile.applyTo(repo);
      await repo.settings.set(SettingsRepository.profileId, 'feuerwehr');
      await repo.settings.set(SettingsRepository.orgName, 'FF Musterstadt');
      hlf = await repo.vehicles.createFromTemplate(profile.vehicleTemplates.first,
          name: 'HLF 20', callSign: 'Florian 1/46-1', ensureQualification: repo.qualifications.ensure);
      final gf = await repo.qualifications.ensure('Gruppenführer');
      await repo.persons.save(PersonInput(lastName: 'Becker', firstName: 'Jonas', qualificationIds: {gf}));
      await repo.persons.save(PersonInput(lastName: 'Neumann', firstName: 'Paul'));
      await repo.keywords.save(KeywordInput(code: 'TH 2', description: 'VU P eingeklemmt'));
    });

    await tester.pumpWidget(UebungsplanerApp(repo: repo, session: Session(repo)));
    await pumpUntil(tester, find.text('Übungen'));
    await tester.tap(find.text('Übungen'));
    await pumpUntil(tester, find.byKey(const Key('exercise-add')));

    // Übung anlegen
    await tester.tap(find.byKey(const Key('exercise-add')));
    await pumpUntil(tester, find.byKey(const Key('exercise-title')));
    await tester.enterText(find.byKey(const Key('exercise-title')), 'THL: VU eingeklemmt');
    await tester.pump();
    await tester.tap(find.byKey(const Key('exercise-save')));
    await pumpUntil(tester, find.text('Sicherheit & Gefährdungsbeurteilung'));
    expect(find.text('Gefährdungsbeurteilung erstellt und mit allen Beteiligten besprochen'), findsOneWidget);
    final id = (await tester.runAsync(() => repo.exercises.watchAll().first))!.single.id;

    // Fahrzeug einplanen und Person per Drag & Drop setzen
    await openTab(tester, 'Besetzung');
    await pumpUntil(tester, find.byKey(const Key('crew-add-vehicle')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crew-add-vehicle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HLF 20  ·  Florian 1/46-1'));
    await pumpUntil(tester, find.text('0 von 9 besetzt'));

    final gfFunction = (await tester.runAsync(() => repo.vehicles.detail(hlf)))!.functions.first;
    final seat = find.byKey(ValueKey('seat-${gfFunction.id}'));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Neumann, Paul').first));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(seat));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await pumpUntil(tester, find.text('fehlt: Gruppenführer'));
    expect(find.text('1 von 9 besetzt'), findsOneWidget);

    // Bedienung ohne Ziehen: Person antippen, dann Funktion antippen → ersetzt Neumann
    await tester.tap(find.text('Becker, Jonas').first);
    await tester.pump();
    await tester.tap(seat);
    await pumpUntil(tester, find.text('1 von 9 besetzt'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.text('fehlt: Gruppenführer'), findsNothing);
    var d = (await tester.runAsync<ExerciseDetail?>(() => repo.exercises.detail(id)))!;
    final becker = (await tester.runAsync(() => repo.persons.all()))!.firstWhere((p) => p.person.lastName == 'Becker');
    expect(d.personsByFunction[gfFunction.id], [becker.person.id]);

    // Alarmierungsplan aus eingeplanten Fahrzeugen
    await openTab(tester, 'Alarmplan');
    await pumpUntil(tester, find.text('1 eingeplantes Fahrzeug übernehmen'));
    await settle(tester);
    await tester.tap(find.text('1 eingeplantes Fahrzeug übernehmen'));
    await pumpUntil(tester, find.text('Zeitleiste'));
    expect(find.text('19:15'), findsWidgets);
    await tester.tap(find.text('ab Übungsbeginn'));
    await pumpUntil(tester, find.text('+15 Min.'));

    // Alarmmeldung
    await openTab(tester, 'Alarmmeldung');
    await pumpUntil(tester, find.text('HLF 20 (Florian 1/46-1)'));

    // Freigabe erst nach vollständiger Checkliste
    await openTab(tester, 'Übungsplan');
    await pumpUntil(tester, find.byKey(const Key('exercise-submit')));
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('exercise-submit'))).onPressed, isNull);
    // Alle Prüfpunkte in der Oberfläche abhaken
    final checks = find.byType(CheckboxListTile);
    final n = checks.evaluate().length;
    expect(n, 8);
    for (var i = 0; i < n; i++) {
      await tester.tap(checks.at(i));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    await pumpUntil(tester, find.text('vollständig'));
    await tester.tap(find.byKey(const Key('exercise-submit')));
    await pumpUntil(tester, find.text('Freigabe ausstehend'));
    await tester.tap(find.byKey(const Key('exercise-approve')));
    await pumpUntil(tester, find.text('Name TL / Wehrführer'));
    await tester.enterText(find.byType(TextField).last, 'Hahn, Felix');
    await tester.tap(find.text('Freigeben').last);
    await pumpUntil(tester, find.textContaining('freigegeben von Hahn, Felix'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    final closing = repo.db.close();
    await tester.pump(const Duration(seconds: 1));
    await closing;
  });

  testWidgets('Rollenkarte, Nachbesprechung, Übersicht, Beobachter-Ansicht, Vorlage', (tester) async {
    tester.view.physicalSize = const Size(1800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    final today = DateTime.now();
    await tester.runAsync(() async {
      await repo.settings.set(SettingsRepository.profileId, 'feuerwehr');
      await repo.settings.set(SettingsRepository.orgName, 'FF Musterstadt');
      await repo.exercises.create(ExerciseInput(title: 'Atemschutz Innenangriff', date: DateTime(today.year, today.month, today.day + 3), startMinutes: 19 * 60));
    });

    await tester.pumpWidget(UebungsplanerApp(repo: repo, session: Session(repo)));
    await pumpUntil(tester, find.text('Übungen'));
    await tester.tap(find.text('Übungen'));
    await pumpUntil(tester, find.text('Atemschutz Innenangriff'));
    await tester.tap(find.text('Atemschutz Innenangriff'));
    await pumpUntil(tester, find.text('Eckdaten'));
    await settle(tester);

    // Rollenkarte mit Eskalationsstufe
    await openTab(tester, 'Rollenkarten');
    await tester.tap(find.byKey(const Key('role-add')));
    await pumpUntil(tester, find.byKey(const Key('role-name')));
    await tester.enterText(find.byKey(const Key('role-name')), 'Thomas Berger');
    await tester.enterText(find.byKey(const Key('role-stage-0')), 'Stöhnt, fragt nach seiner Frau');
    await tester.tap(find.byKey(const Key('role-save')));
    await pumpUntil(tester, find.text('Thomas Berger'));
    expect(find.text('Stöhnt, fragt nach seiner Frau'), findsOneWidget);

    // Nachbesprechung: Maßnahme
    await openTab(tester, 'Nachbesprechung');
    await tester.tap(find.byKey(const Key('lesson-add')));
    await pumpUntil(tester, find.byKey(const Key('lesson-text')));
    await tester.enterText(find.byKey(const Key('lesson-text')), 'Lagemeldung üben');
    await tester.tap(find.byKey(const Key('lesson-save')));
    await pumpUntil(tester, find.text('Lagemeldung üben'));

    // Beobachter-Ansicht
    await tester.tap(find.byTooltip('Weitere Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beobachter-Ansicht'));
    await pumpUntil(tester, find.text('Mimen und Eskalationsstufen'));
    expect(find.text('Stöhnt, fragt nach seiner Frau'), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück').last);
    await settle(tester);

    // Als Vorlage speichern
    await tester.tap(find.byTooltip('Weitere Aktionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Als Vorlage speichern'));
    await pumpUntil(tester, find.text('Name der Vorlage'));
    await tester.tap(find.text('Speichern').last);
    await settle(tester);
    expect((await tester.runAsync(() => repo.exercises.watchTemplates().first))!.single.title, 'Atemschutz Innenangriff');

    // Übersicht zeigt die offene Maßnahme
    await tester.tap(find.text('Übersicht'));
    await pumpUntil(tester, find.text('Erkenntnisse aus Nachbesprechungen'));
    await pumpUntil(tester, find.text('Lagemeldung üben'));
    expect(find.text('In Übung übernehmen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    final closing = repo.db.close();
    await tester.pump(const Duration(seconds: 1));
    await closing;
  });

  testWidgets('Fahrzeug mit mehreren Funkrufnamen, Auswahl im Funkplan per Dropdown', (tester) async {
    tester.view.physicalSize = const Size(1600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    final today = DateTime.now();
    late String exId;
    await tester.runAsync(() async {
      await repo.settings.set(SettingsRepository.profileId, 'dlrg');
      await repo.settings.set(SettingsRepository.orgName, 'DLRG Musterstadt');
      exId = await repo.exercises.create(ExerciseInput(title: 'Personensuche See', date: DateTime(today.year, today.month, today.day + 3), startMinutes: 19 * 60));
    });

    await tester.pumpWidget(UebungsplanerApp(repo: repo, session: Session(repo)));
    await pumpUntil(tester, find.text('Fahrzeuge & Funktionen'));

    // Boot mit vier Funkrufnamen anlegen
    await tester.tap(find.text('Fahrzeuge & Funktionen'));
    await pumpUntil(tester, find.byKey(const Key('vehicle-add')));
    await tester.tap(find.byKey(const Key('vehicle-add')));
    await pumpUntil(tester, find.byKey(const Key('vehicle-name')));
    await tester.enterText(find.byKey(const Key('vehicle-name')), 'MRB 1');
    await tester.enterText(find.byKey(const Key('callsign-call-0')), 'Pelikan Musterstadt 87/1');
    Future<void> addCall(int i, String net, String call, [String? label]) async {
      await tester.tap(find.byKey(const Key('callsign-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('callsign-net-$i')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(net).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('callsign-call-$i')), call);
      if (label != null) await tester.enterText(find.byKey(Key('callsign-label-$i')), label);
    }

    await addCall(1, 'BOS analog', 'Pelikan Musterstadt 87/1');
    await addCall(2, 'DLRG-Betriebsfunk', 'Adler Musterstadt 21', 'Boot');
    await addCall(3, 'DLRG-Betriebsfunk', 'Adler Musterstadt 21/1', 'Bootsführer');
    await tester.tap(find.byKey(const Key('vehicle-create')));
    await pumpUntil(tester, find.text('Adler Musterstadt 21/1 (DLRG-Betriebsfunk, Bootsführer)'));
    final vehicle = (await tester.runAsync(() => repo.vehicles.watchAll().first))!.single;
    expect(vehicle.allCallSigns.map((c) => c.network), ['bos_digital', 'bos_analog', 'dlrg_betriebsfunk', 'dlrg_betriebsfunk']);
    expect(vehicle.callSign, 'Pelikan Musterstadt 87/1');
    await tester.runAsync(() => repo.exercises.addVehicle(exId, vehicle.id));

    // Funkplan: Fahrzeug und Rufnamen per Dropdown wählen
    await tester.tap(find.text('Übungen'));
    await pumpUntil(tester, find.text('Personensuche See'));
    await tester.tap(find.text('Personensuche See'));
    await pumpUntil(tester, find.text('Eckdaten'));
    await settle(tester);
    await openTab(tester, 'Funk');
    await tester.tap(find.byKey(const Key('radio-add')));
    await pumpUntil(tester, find.byKey(const Key('radio-vehicle')));
    await tester.tap(find.byKey(const Key('radio-vehicle')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('MRB 1').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('radio-call'))).controller!.text, 'Pelikan Musterstadt 87/1');
    await tester.tap(find.byKey(ValueKey('radio-vehicle-call-${vehicle.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adler Musterstadt 21/1 (DLRG-Betriebsfunk, Bootsführer)').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('radio-call'))).controller!.text, 'Adler Musterstadt 21/1');
    await tester.tap(find.byKey(const Key('radio-save')));
    await settle(tester);
    var radio = (await tester.runAsync(() async => (await repo.exercises.detail(exId))!.radio))!;
    expect(radio.single.callSign, 'Adler Musterstadt 21/1');
    expect(radio.single.network, 'dlrg_betriebsfunk');
    expect(radio.single.device, 'MRB 1');

    // Alle übrigen Rufnamen der eingeplanten Fahrzeuge übernehmen
    await tester.tap(find.byKey(const Key('radio-from-vehicles')));
    await settle(tester);
    radio = (await tester.runAsync(() async => (await repo.exercises.detail(exId))!.radio))!;
    expect(radio.length, 4);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    final closing = repo.db.close();
    await tester.pump(const Duration(seconds: 1));
    await closing;
  });
}
