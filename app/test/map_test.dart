import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqlite3/sqlite3.dart' hide Session;
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/data/template_io.dart';
import 'package:uebungsplaner/features/exercises/tab_map.dart';
import 'package:uebungsplaner/map/sketch.dart';
import 'package:uebungsplaner/sync/sync_service.dart';
import 'package:uebungsplaner/ui/widgets.dart';
import 'dart:convert';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('Lageskizze: JSON hin und zurück', () {
    final items = [
      SketchItem(type: 'symbol', points: [(50.1, 7.6)], symbol: 'assets/zeichen/Fahrzeuge/ELW_1.svg', organisation: 'thw', label: 'ELW'),
      SketchItem(type: 'line', points: [(50.1, 7.6), (50.2, 7.7)], color: 'blau'),
      SketchItem(type: 'area', points: [(1, 1), (1, 2), (2, 2)], label: 'Suchabschnitt A', color: 'gelb'),
    ];
    final back = decodeSketch(encodeSketch(items));
    expect(back.length, 3);
    expect(back[0].symbol, items[0].symbol);
    expect(back[0].organisation, 'thw');
    expect(back[1].points, [(50.1, 7.6), (50.2, 7.7)]);
    expect(back[2].label, 'Suchabschnitt A');
    expect(back[2].flutterColor, SketchItem.colors['gelb']);
    expect(decodeSketch('kaputt'), isEmpty);
  });

  test('Alle Zeichen im Katalog existieren als Datei, alte Pfade sind umgestellt', () async {
    final index = jsonDecode(File('assets/zeichen/index.json').readAsStringSync()) as List;
    final files = [for (final c in index) for (final z in c['zeichen'] as List) '${z['datei']}'];
    expect(files.length, greaterThan(300));
    expect(files.toSet().length, files.length, reason: 'keine doppelten Dateien');
    for (final f in files) {
      expect(File('assets/zeichen/$f').existsSync(), isTrue, reason: f);
    }
    // Nach DV 102 gibt es keine Kategorien je Organisation mehr.
    expect([for (final c in index) c['kategorie']], isNot(contains(startsWith('Feuerwehr'))));
    final moves = jsonDecode(File('assets/zeichen/umzug.json').readAsStringSync()) as Map<String, dynamic>;
    for (final m in moves.values) {
      expect(File('${m['datei']}').existsSync(), isTrue, reason: '${m['datei']}');
      expect(Organisation.all.map((o) => o.id), contains(m['organisation']));
    }
    expect(moves['assets/zeichen/Feuerwehr_Fahrzeuge/HLF.svg'], {'datei': 'assets/zeichen/Fahrzeuge/HLF.svg', 'organisation': 'feuerwehr'});
    expect(moves['assets/zeichen/Rettungswesen_Fahrzeuge/RTW.svg'], {'datei': 'assets/zeichen/Fahrzeuge/RTW.svg', 'organisation': 'hilfsorganisation'});
  });

  test('Zeichen werden in der Farbe der Organisation dargestellt (DV 102)', () {
    final svg = File('assets/zeichen/Einheiten/Loeschgruppe.svg').readAsStringSync();
    expect(svg, contains(Organisation.grundPlatzhalter));
    final thw = Organisation.thw.apply(svg);
    expect(thw, contains('#003399'));
    expect(thw, contains('#FFFFFF'));
    expect(thw, isNot(contains(Organisation.grundPlatzhalter)));
    final dlrg = Organisation.byId(Organisation.forProfile('dlrg')).apply(svg);
    expect(dlrg, isNot(contains('#FF0000')));
    expect(dlrg, contains('fill="#FFFFFF"'));
    expect(Organisation.forProfile('feuerwehr'), 'feuerwehr');
    expect(Organisation.forProfile('thw'), 'thw');
    expect(Organisation.forProfile('wasserwacht'), 'hilfsorganisation');
  });

  test('Alte Skizzen werden auf die organisationsneutralen Zeichen umgestellt', () {
    final catalog = SymbolCatalog(
      [
        ('Fahrzeuge', [(name: 'HLF', asset: 'assets/zeichen/Fahrzeuge/HLF.svg', grund: 'hilfsorganisation')]),
      ],
      moves: {'assets/zeichen/Feuerwehr_Fahrzeuge/HLF.svg': ('assets/zeichen/Fahrzeuge/HLF.svg', 'feuerwehr')},
    );
    final old = [
      SketchItem(type: 'symbol', points: [(1, 1)], symbol: 'assets/zeichen/Feuerwehr_Fahrzeuge/HLF.svg'),
      SketchItem(type: 'line', points: [(1, 1), (2, 2)]),
    ];
    expect(catalog.nameOf('assets/zeichen/Feuerwehr_Fahrzeuge/HLF.svg'), 'HLF');
    final m = catalog.migrate(old)!;
    expect(m[0].symbol, 'assets/zeichen/Fahrzeuge/HLF.svg');
    expect(m[0].organisation, 'feuerwehr');
    expect(catalog.isColorable(m[0].symbol), isTrue);
    expect(m[1], same(old[1]));
    expect(catalog.migrate(m), isNull);
    expect(catalog.organisationOf(SketchItem(type: 'symbol', points: [(1, 1)], symbol: 'assets/zeichen/Fahrzeuge/HLF.svg')), 'hilfsorganisation');
  });

  test('Offline-Karte: Kacheln aus MBTiles (TMS-Zeilen gespiegelt)', () {
    final dir = Directory.systemTemp.createTempSync('mbtiles');
    final path = '${dir.path}/test.mbtiles';
    final db = sqlite3.open(path);
    db.execute('CREATE TABLE metadata(name TEXT, value TEXT); CREATE TABLE tiles(zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);');
    db.execute("INSERT INTO metadata VALUES('name', 'Testkreis')");
    final tile = Uint8List.fromList([1, 2, 3]);
    // XYZ z=2, x=1, y=0  →  TMS row = 2^2 - 1 - 0 = 3
    db.execute('INSERT INTO tiles VALUES(2, 1, 3, ?)', [tile]);
    db.close();

    expect(MbTilesProvider.isValid(path), isTrue);
    expect(MbTilesProvider.describe(path), contains('Testkreis'));
    final p = MbTilesProvider(path);
    final layer = TileLayer(urlTemplate: 'x');
    final img = p.getImage(const TileCoordinates(1, 0, 2), layer) as MemoryImage;
    expect(img.bytes, tile);
    final missing = p.getImage(const TileCoordinates(0, 0, 2), layer) as MemoryImage;
    expect(missing.bytes, isNot(tile));
    p.dispose();
    expect(MbTilesProvider.isValid('${dir.path}/fehlt.mbtiles'), isFalse);
    dir.deleteSync(recursive: true);
  });

  test('Lageskizze wird gespeichert, kopiert und mit der Vorlage exportiert', () async {
    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    final id = await repo.exercises.create(ExerciseInput(title: 'Badesee', date: DateTime(2027, 6, 1), startMinutes: 1080));
    final sketch = encodeSketch([SketchItem(type: 'text', points: [(50.0, 7.0)], label: 'Steg 2')]);
    await repo.exercises.setMapView(id, 50.0, 7.0, 16);
    await repo.exercises.setSketch(id, sketch);
    await repo.exercises.setSketchPng(id, 'iVBORw0KGgo=');
    final copy = await repo.exercises.copy(id, asTemplate: true);
    final c = (await repo.exercises.detail(copy))!.exercise;
    expect(c.sketch, sketch);
    expect(c.mapZoom, 16);
    final text = await exportTemplate(repo, id);
    final other = Repositories(AppDatabase(NativeDatabase.memory()));
    final r = await importTemplate(other, text);
    final imported = (await other.exercises.detail(r.exerciseId))!.exercise;
    expect(decodeSketch(imported.sketch).single.label, 'Steg 2');
    expect(imported.mapLat, 50.0);
    await repo.db.close();
    await other.db.close();
  });

  testWidgets('Lageskizze bearbeiten: alles auswählen, löschen, rückgängig', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = Repositories(AppDatabase(NativeDatabase.memory()));
    late String id;
    await tester.runAsync(() async {
      id = await repo.exercises.create(ExerciseInput(title: 'Badesee', date: DateTime(2027, 6, 1), startMinutes: 1080));
      // Leere Offline-Karte, damit der Test keine Kacheln aus dem Netz lädt.
      final dir = Directory.systemTemp.createTempSync('mbtiles');
      final db = sqlite3.open('${dir.path}/leer.mbtiles');
      db.execute('CREATE TABLE metadata(name TEXT, value TEXT); CREATE TABLE tiles(zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);');
      db.close();
      await repo.settings.set(MapKeys.mode, 'offline');
      await repo.settings.set(MapKeys.mbtiles, '${dir.path}/leer.mbtiles');
      await repo.exercises.setSketch(id, encodeSketch([
        SketchItem(type: 'symbol', points: [(50.0, 7.6)], symbol: 'assets/zeichen/Feuerwehr_Fahrzeuge/HLF.svg', label: 'HLF 1'),
        SketchItem(type: 'line', points: [(50.0, 7.6), (50.001, 7.601)]),
        SketchItem(type: 'area', points: [(50.0, 7.6), (50.001, 7.6), (50.001, 7.601)], label: 'Suchabschnitt'),
        SketchItem(type: 'text', points: [(50.0, 7.6)], label: 'Steg 2'),
      ]));
    });
    Future<List<SketchItem>> stored() async => decodeSketch((await tester.runAsync(() => repo.exercises.detail(id)))!.exercise.sketch);
    final detail = (await tester.runAsync(() => repo.exercises.detail(id)))!;
    await tester.pumpWidget(MaterialApp(
      home: AppScope(repo: repo, session: Session(repo), child: Scaffold(body: MapTab(detail: detail))),
    ));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Das alte Feuerwehr-Zeichen wurde auf das neue Zeichen mit Organisationsfarbe umgestellt.
    final migrated = (await stored()).first;
    expect(migrated.symbol, 'assets/zeichen/Fahrzeuge/HLF.svg');
    expect(migrated.organisation, 'feuerwehr');

    await tester.tap(find.byKey(const Key('map-edit')));
    await tester.pump();
    expect(find.text('Elemente der Lageskizze (4)'), findsOneWidget);
    expect(find.text('Bearbeiten: 0 von 4 ausgewählt'), findsOneWidget);

    // Einzelnes Element in der Liste auswählen und wieder abwählen
    await tester.tap(find.byKey(const Key('map-item-1')));
    await tester.pump();
    expect(find.text('Bearbeiten: 1 von 4 ausgewählt'), findsOneWidget);
    expect(find.text('Farbe:'), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-select-all')));
    await tester.pump();
    expect(find.text('Bearbeiten: 4 von 4 ausgewählt'), findsOneWidget);
    expect(find.text('Organisation:'), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Alle 4 Elemente löschen?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('map-delete-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(await stored(), isEmpty);
    expect(find.text('Elemente der Lageskizze (0)'), findsOneWidget);

    await tester.tap(find.text('Rückgängig'));
    await tester.pump();
    expect((await stored()).length, 4);
    expect(find.text('Elemente der Lageskizze (4)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-edit-done')));
    await tester.pump();
    expect(find.byKey(const Key('map-edit')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => repo.db.close());
  });
}
