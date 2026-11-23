import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/data/template_io.dart';
import 'package:uebungsplaner/features/exercises/tab_alarm.dart';
import 'package:uebungsplaner/features/exercises/tab_alarmplan.dart';
import 'package:uebungsplaner/sync/sync_service.dart';
import 'package:uebungsplaner/ui/theme.dart';
import 'package:uebungsplaner/ui/widgets.dart';

/// Slippen: Ein Fahrzeug bringt ein Boot auf dem Anhänger zur Slipstelle,
/// danach sind beide getrennt unterwegs.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Repositories repo;
  var widgetTest = false;
  setUp(() => repo = Repositories(AppDatabase(NativeDatabase.memory())));
  tearDown(() async {
    if (!widgetTest) await repo.db.close();
  });

  Future<String> newExercise() => repo.exercises.create(
        ExerciseInput(title: 'Personensuche Badesee', date: DateTime(2027, 6, 4), startMinutes: 19 * 60, location: 'Badesee'),
      );

  /// GW-Wasserrettung zieht das MRB; dazu ein eigenständiges Boot.
  Future<({String id, String gw, String mrb})> plan() async {
    final id = await newExercise();
    final gw = await repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'GW-W', alarmOffset: 20, departOffset: 26, arriveOffset: 40, destination: 'Nordufer'));
    final mrb = await repo.exercises.saveAlarmEntry(
      id,
      AlarmEntryInput(
        label: 'MRB 1',
        kind: 'boot',
        alarmOffset: 99, // wird vom Zugfahrzeug übernommen
        towedById: gw,
        slipLocation: 'Slipanlage Süd',
        slipOffset: 32,
        departOffset: 37,
        arriveOffset: 45,
        destination: 'Seemitte',
        task: 'Wassersuche',
      ),
    );
    await repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'Trupp Ufer', kind: 'trupp', alarmOffset: 10));
    return (id: id, gw: gw, mrb: mrb);
  }

  test('Boot übernimmt Alarmierung und Ausrücken des Zugfahrzeugs, hat aber eigenes Ziel', () async {
    final p = await plan();
    final d = (await repo.exercises.detail(p.id))!;
    final gw = d.alarmPlan.firstWhere((e) => e.id == p.gw);
    final mrb = d.alarmPlan.firstWhere((e) => e.id == p.mrb);
    expect(mrb.alarmOffset, 20);
    expect(d.towOf(mrb)?.id, p.gw);
    expect(d.towedBy(gw).map((e) => e.id), [p.mrb]);
    expect(d.departOf(mrb), 26, reason: 'rückt mit dem Zugfahrzeug aus');
    expect(mrb.departOffset, 37, reason: 'im Wasser / ablegen');
    expect(mrb.slipLocation, 'Slipanlage Süd');
    expect(mrb.slipOffset, 32);
    expect((gw.destination, gw.arriveOffset), ('Nordufer', 40));
    expect((mrb.destination, mrb.task, mrb.arriveOffset), ('Seemitte', 'Wassersuche', 45));
    // Boot steht direkt hinter seinem Zugfahrzeug
    expect(d.alarmPlan.map((e) => e.label), ['Trupp Ufer', 'GW-W', 'MRB 1']);

    // Gleiche Alarmmeldung wie das Zugfahrzeug
    final sheets = alarmSheetsFor(d, const [], 'DLRG Musterstadt');
    expect(sheets.length, 1);
    expect(sheets.single.vehicles, 'GW-W, MRB 1 auf Anhänger von GW-W');
  });

  test('Alarmierung des Zugfahrzeugs verschiebt das Boot mit, Löschen macht es eigenständig', () async {
    final p = await plan();
    await repo.exercises.saveAlarmEntry(p.id, AlarmEntryInput(id: p.gw, label: 'GW-W', alarmOffset: 25, departOffset: 30, arriveOffset: 45));
    var d = (await repo.exercises.detail(p.id))!;
    expect(d.alarmPlan.firstWhere((e) => e.id == p.mrb).alarmOffset, 25);

    await repo.exercises.deleteAlarmEntry(p.gw);
    d = (await repo.exercises.detail(p.id))!;
    final mrb = d.alarmPlan.firstWhere((e) => e.id == p.mrb);
    expect(mrb.towedById, isNull);
    expect(mrb.slipOffset, isNull);
    expect(d.towOf(mrb), isNull);
    expect(mrb.arriveOffset, 45, reason: 'Zeiten bleiben erhalten');
  });

  test('Nur Boote können gezogen werden; ein Zugfahrzeug, das kein Fahrzeug mehr ist, gibt das Boot frei', () async {
    final p = await plan();
    final other = await repo.exercises.saveAlarmEntry(p.id, AlarmEntryInput(label: 'Trupp', kind: 'trupp', alarmOffset: 5, towedById: p.gw));
    var d = (await repo.exercises.detail(p.id))!;
    expect(d.alarmPlan.firstWhere((e) => e.id == other).towedById, isNull);

    await repo.exercises.saveAlarmEntry(p.id, AlarmEntryInput(id: p.gw, label: 'GW-W', kind: 'trupp', alarmOffset: 20));
    d = (await repo.exercises.detail(p.id))!;
    expect(d.alarmPlan.firstWhere((e) => e.id == p.mrb).towedById, isNull);
  });

  test('Kopie und Vorlagendatei behalten das Slippen', () async {
    final p = await plan();
    final copy = await repo.exercises.copy(p.id, asTemplate: true, title: 'Vorlage');
    var d = (await repo.exercises.detail(copy))!;
    var mrb = d.alarmPlan.firstWhere((e) => e.label == 'MRB 1');
    expect(d.towOf(mrb)?.label, 'GW-W');
    expect(mrb.towedById, isNot(p.gw), reason: 'verweist auf die Kopie des Zugfahrzeugs');
    expect((mrb.slipLocation, mrb.slipOffset, mrb.task), ('Slipanlage Süd', 32, 'Wassersuche'));

    final text = await exportTemplate(repo, p.id);
    final other = Repositories(AppDatabase(NativeDatabase.memory()));
    addTearDown(other.db.close);
    final r = await importTemplate(other, text);
    d = (await other.exercises.detail(r.exerciseId))!;
    mrb = d.alarmPlan.firstWhere((e) => e.label == 'MRB 1');
    expect(d.towOf(mrb)?.label, 'GW-W');
    expect((mrb.alarmOffset, mrb.slipOffset, mrb.departOffset, mrb.arriveOffset, mrb.destination), (20, 32, 37, 45, 'Seemitte'));
  });

  /// Streams beenden lassen (drift räumt verzögert auf), dann schließen.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    final closing = repo.db.close();
    await tester.pump(const Duration(seconds: 1));
    await closing;
  }

  test('Migration von Version 5 ergänzt die Spalten im Alarmierungsplan', () async {
    // Tabelle im Stand von Version 5 mit einem alten Eintrag.
    final raw = NativeDatabase.memory(setup: (db) {
      db.execute('CREATE TABLE alarm_plan_entries (id TEXT NOT NULL PRIMARY KEY, updated_at INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0, '
          'exercise_id TEXT NOT NULL, label TEXT NOT NULL, kind TEXT NOT NULL DEFAULT \'fahrzeug\', vehicle_id TEXT, alarm_offset INTEGER NOT NULL, '
          'depart_offset INTEGER, arrive_offset INTEGER, note TEXT, sort_order INTEGER NOT NULL DEFAULT 0)');
      db.execute("INSERT INTO alarm_plan_entries (id, updated_at, exercise_id, label, alarm_offset) VALUES ('a', 0, 'x', 'HLF', 15)");
      db.execute('PRAGMA user_version = 5');
    });
    final db = AppDatabase(raw);
    final rows = await db.select(db.alarmPlanEntries).get();
    expect(rows.single.label, 'HLF');
    expect(rows.single.towedById, isNull);
    await db.close();
  });

  Future<void> pumpTab(WidgetTester tester, String id) async {
    widgetTest = true;
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      repo: repo,
      session: Session(repo),
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: StreamBuilder<ExerciseDetail?>(
            stream: repo.exercises.watchDetail(id),
            builder: (context, s) => s.data == null ? const SizedBox() : AlarmPlanTab(detail: s.data!),
          ),
        ),
      ),
    ));
  }

  Future<void> frames(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> wait(WidgetTester tester, Finder f) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 30));
      if (f.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Nicht gefunden: $f');
  }

  testWidgets('Boot über den Anhänger-Knopf eines Fahrzeugs einplanen', (tester) async {
    final id = (await tester.runAsync(newExercise))!;
    final gw = (await tester.runAsync(() => repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'GW-W', alarmOffset: 20, departOffset: 26, arriveOffset: 40))))!;
    await pumpTab(tester, id);
    await wait(tester, find.byKey(ValueKey('alarm-tow-$gw')));

    await tester.ensureVisible(find.byKey(ValueKey('alarm-tow-$gw')));
    await frames(tester);
    await tester.tap(find.byKey(ValueKey('alarm-tow-$gw')));
    await frames(tester);
    expect(find.text('Boot auf Anhänger von GW-W'), findsOneWidget);
    expect(find.byKey(const Key('alarm-time')), findsNothing, reason: 'Alarmierung kommt vom Zugfahrzeug');

    await tester.enterText(find.byKey(const Key('alarm-label')), 'MRB 1');
    await tester.enterText(find.byKey(const Key('alarm-slip-location')), 'Slipanlage Süd');
    await tester.enterText(find.byKey(const Key('alarm-slip-time')), '19:32');
    await tester.enterText(find.byKey(const Key('alarm-water-time')), '19:37');
    await tester.enterText(find.byKey(const Key('alarm-arrive-time')), '19:45');
    await tester.enterText(find.byKey(const Key('alarm-destination')), 'Seemitte');
    await tester.pump();
    await tester.tap(find.byKey(const Key('alarm-save')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await frames(tester);

    final d = (await tester.runAsync(() => repo.exercises.detail(id)))!;
    final mrb = d.alarmPlan.firstWhere((e) => e.label == 'MRB 1');
    expect((mrb.kind, mrb.towedById, mrb.alarmOffset, mrb.slipOffset, mrb.departOffset, mrb.arriveOffset), ('boot', gw, 20, 32, 37, 45));
    await wait(tester, find.text('Slipanlage Süd · an 19:32'));
    expect(find.text('auf Anhänger von GW-W'), findsOneWidget);
    expect(find.text('Slippen'), findsOneWidget, reason: 'Legende');
    await finish(tester);
  });

  testWidgets('Reihenfolge der Zeiten wird geprüft', (tester) async {
    final id = (await tester.runAsync(newExercise))!;
    final gw = (await tester.runAsync(() => repo.exercises.saveAlarmEntry(id, AlarmEntryInput(label: 'GW-W', alarmOffset: 20, departOffset: 26))))!;
    await pumpTab(tester, id);
    await wait(tester, find.byKey(ValueKey('alarm-tow-$gw')));
    await tester.ensureVisible(find.byKey(ValueKey('alarm-tow-$gw')));
    await frames(tester);
    await tester.tap(find.byKey(ValueKey('alarm-tow-$gw')));
    await frames(tester);
    await tester.enterText(find.byKey(const Key('alarm-label')), 'MRB 1');
    await tester.enterText(find.byKey(const Key('alarm-slip-time')), '19:22');
    await tester.enterText(find.byKey(const Key('alarm-water-time')), '19:20');
    await tester.pump();
    expect(find.text('Das Zugfahrzeug ist vor dem Ausrücken an der Slipstelle.'), findsOneWidget);
    expect(find.text('Das Boot ist im Wasser, bevor es an der Slipstelle ist.'), findsOneWidget);
    await finish(tester);
  });
}
