import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/radio_overview.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/features/exercises/exercise_actions.dart';
import 'package:uebungsplaner/features/exercises/tab_radio_material.dart';
import 'package:uebungsplaner/pdf/exercise_pdf.dart';

import 'documents_test.dart' show testFonts;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Repositories repo;
  setUp(() => repo = Repositories(AppDatabase(NativeDatabase.memory())));
  tearDown(() => repo.db.close());

  Future<ExerciseDetail> exercise() async {
    final id = await repo.exercises.create(ExerciseInput(title: 'Funkübung', date: DateTime(2027, 3, 4), startMinutes: 19 * 60));
    final docs = repo.documents;
    await docs.saveRadio(id, callSign: 'Kater 1/11', device: 'ELW 1', network: 'bos_digital', channel: 'DMO 307', task: 'Einsatzleitung');
    await docs.saveRadio(id, callSign: 'Florian 1/46-1', device: 'HLF 20', network: 'bos_digital', channel: 'DMO 307', task: 'Rettung');
    await docs.saveRadio(id, callSign: 'Angriffstrupp', device: 'HFG', network: 'bos_analog', channel: 'Kanal 34');
    await docs.saveRadio(id, callSign: 'kater  1/11', device: 'ELW 1', network: 'bos_digital', channel: 'dmo 308', task: 'Abschnitt Wasser');
    await docs.saveRadio(id, callSign: 'Kater 1/11', network: 'bos_analog', channel: ' Kanal 34 ');
    await docs.saveRadio(id, callSign: 'Melder', network: 'dlrg_betriebsfunk');
    return (await repo.exercises.detail(id))!;
  }

  test('Funkplan wird nach Netz und Gruppe gruppiert, Verbindungsstellen erkannt', () async {
    final o = RadioOverview.from((await exercise()).radio);
    expect(o.networks.keys, ['bos_digital', 'bos_analog', 'dlrg_betriebsfunk']);
    expect(o.networks['bos_digital']!.map((g) => g.label), ['DMO 307', 'dmo 308']);
    expect(o.networks['bos_digital']!.first.entries.length, 2);
    expect(o.networks['bos_analog']!.single.entries.length, 2, reason: 'Leerzeichen am Kanal werden ignoriert');
    expect(o.networks['dlrg_betriebsfunk']!.single.label, 'ohne Gruppe / Kanal');
    final g307 = o.networks['bos_digital']!.first;
    final kater = g307.entries.first;
    expect(o.otherGroups(kater, g307).map((g) => g.fullLabel), ['BOS digital · dmo 308', 'BOS analog · Kanal 34']);
    expect(o.otherGroups(g307.entries.last, g307), isEmpty);
    expect(o.linkingStations, ['Kater 1/11']);
    expect(RadioOverview.from(const []).isEmpty, isTrue);
  });

  test('Übungsmappe mit grafischem Funkplan', () async {
    final d = await exercise();
    final bytes = await buildExerciseMap(await loadMapData(repo, d), {MapSection.radio, MapSection.radioOverview}, fonts: await testFonts());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('Grafischer Funkplan mit vielen Stellen bricht über Seiten um', () async {
    final id = await repo.exercises.create(ExerciseInput(title: 'Groß', date: DateTime(2027, 3, 4), startMinutes: 600));
    for (var i = 0; i < 60; i++) {
      await repo.documents.saveRadio(id, callSign: 'Stelle $i', device: 'HFG', network: i.isEven ? 'bos_digital' : 'bos_analog', channel: 'Gruppe ${i % 7}', task: 'Aufgabe $i');
    }
    final d = (await repo.exercises.detail(id))!;
    final bytes = await buildExerciseMap(await loadMapData(repo, d), {MapSection.radioOverview}, fonts: await testFonts());
    expect(bytes.length, greaterThan(1000));
  });

  testWidgets('Grafische Übersicht zeigt Gruppen und Verbindungsstellen', (tester) async {
    final d = (await tester.runAsync(exercise))!;
    RadioEntry? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: RadioOverviewGraphic(overview: RadioOverview.from(d.radio), onTap: (r) => tapped = r)),
      ),
    ));
    expect(find.text('DMO 307'), findsOneWidget);
    expect(find.text('dmo 308'), findsOneWidget);
    expect(find.text('Kanal 34'), findsOneWidget);
    expect(find.text('ohne Gruppe / Kanal'), findsOneWidget);
    expect(find.text('auch in dmo 308, BOS analog · Kanal 34'), findsOneWidget);
    expect(find.textContaining('Verbindungsstellen'), findsOneWidget);
    await tester.tap(find.text('Florian 1/46-1'));
    expect(tapped?.device, 'HLF 20');
  });
}
