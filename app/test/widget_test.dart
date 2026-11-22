import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/main.dart';

/// Wartet, bis [finder] etwas findet (Datenbank und Assets arbeiten asynchron).
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Nicht gefunden: $finder');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Erster Start, Person anlegen, Fahrzeug aus Vorlage', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    await tester.pumpWidget(UebungsplanerApp(repo: repo));
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
}
