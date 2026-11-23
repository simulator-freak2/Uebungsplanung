import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uebungsplaner/data/database.dart';
import 'package:uebungsplaner/data/exercise_repository.dart';
import 'package:uebungsplaner/data/repositories.dart';
import 'package:uebungsplaner/data/template_io.dart';
import 'package:uebungsplaner/map/sketch.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('Lageskizze: JSON hin und zurück', () {
    final items = [
      SketchItem(type: 'symbol', points: [(50.1, 7.6)], symbol: 'assets/zeichen/Feuerwehr_Fahrzeuge/ELW_1.svg', label: 'ELW'),
      SketchItem(type: 'line', points: [(50.1, 7.6), (50.2, 7.7)], color: 'blau'),
      SketchItem(type: 'area', points: [(1, 1), (1, 2), (2, 2)], label: 'Suchabschnitt A', color: 'gelb'),
    ];
    final back = decodeSketch(encodeSketch(items));
    expect(back.length, 3);
    expect(back[0].symbol, items[0].symbol);
    expect(back[1].points, [(50.1, 7.6), (50.2, 7.7)]);
    expect(back[2].label, 'Suchabschnitt A');
    expect(back[2].flutterColor, SketchItem.colors['gelb']);
    expect(decodeSketch('kaputt'), isEmpty);
  });

  test('Alle Zeichen im Katalog existieren als Datei', () async {
    final index = File('assets/zeichen/index.json').readAsStringSync();
    final files = RegExp(r'"datei": "([^"]+)"').allMatches(index).map((m) => m.group(1)!).toList();
    expect(files.length, greaterThan(300));
    for (final f in files) {
      expect(File('assets/zeichen/$f').existsSync(), isTrue, reason: f);
    }
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
}
