import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Nachbildung der Materialkompass-API nach `docs/SCHNITTSTELLE_MATERIALKOMPASS.md`.
class FakeMaterialkompass {
  final reservations = <String, Map<String, dynamic>>{};
  final idempotency = <String, String>{};
  final busy = <String>{};
  int calls = 0;

  Response _json(Object o, [int s = 200]) => Response(s, body: jsonEncode(o), headers: {'content-type': 'application/json'});

  Future<Response> handle(Request r) async {
    calls++;
    if (r.headers['authorization'] != 'Bearer geheim') return _json({'title': 'Nicht angemeldet'}, 401);
    final p = r.url.path;
    if (p == 'api/v1/status') return _json({'version': '1.0.0', 'organisation': {'id': 'o1', 'name': 'FF Musterstadt'}});
    if (p == 'api/v1/fahrzeuge') {
      // Zwei Seiten, um die Blätterfunktion zu prüfen.
      if (r.url.queryParameters['cursor'] == null) {
        return _json({'daten': [{'id': 'mk-hlf', 'bezeichnung': 'HLF 20', 'typ': 'HLF 20', 'art': 'fahrzeug', 'funkrufname': 'Florian 1/46-1', 'status': 'einsatzbereit'}], 'naechster_cursor': 'seite2', 'server_zeit': '2027-01-01T10:00:00+01:00'});
      }
      return _json({'daten': [
        {'id': 'mk-rw', 'bezeichnung': 'RW', 'typ': 'RW', 'art': 'fahrzeug', 'status': 'werkstatt'},
        {'id': 'mk-mtw', 'bezeichnung': 'MTW', 'typ': 'MTW', 'art': 'fahrzeug', 'status': 'einsatzbereit'},
      ], 'naechster_cursor': null});
    }
    if (p == 'api/v1/material') {
      return _json({'daten': [
        {'id': 'm1', 'bezeichnung': 'Hydraulischer Rettungssatz', 'menge': 1, 'verlastet_auf_fahrzeug_id': 'mk-rw', 'status': 'einsatzbereit'},
        {'id': 'm2', 'bezeichnung': 'Bindemittel', 'menge': 2, 'einheit': 'Sack', 'lagerort': 'Lager', 'status': 'einsatzbereit'},
        {'id': 'm3', 'bezeichnung': 'Alt', 'menge': 1, 'status': 'ausgesondert', 'geloescht': true},
      ], 'naechster_cursor': null, 'server_zeit': '2027-01-01T10:00:00+01:00'});
    }
    final avail = RegExp(r'^api/v1/fahrzeuge/([^/]+)/verfuegbarkeit$').firstMatch(p);
    if (avail != null) return _json({'fahrzeug_id': avail.group(1), 'verfuegbar': !busy.contains(avail.group(1)), 'belegungen': []});
    if (p == 'api/v1/reservierungen' && r.method == 'POST') {
      final key = r.headers['idempotency-key']!;
      if (idempotency.containsKey(key)) return _json(reservations[idempotency[key]]!, 201);
      final b = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
      final id = 'r${reservations.length + 1}';
      reservations[id] = {'id': id, 'status': 'angefragt', ...b};
      idempotency[key] = id;
      return _json(reservations[id]!, 201);
    }
    if (p == 'api/v1/reservierungen' && r.method == 'GET') {
      final ref = r.url.queryParameters['referenz'];
      return _json({'daten': reservations.values.where((x) => x['referenz'] == ref).toList()});
    }
    final one = RegExp(r'^api/v1/reservierungen/([^/]+)$').firstMatch(p);
    if (one != null && r.method == 'DELETE') {
      reservations[one.group(1)]!['status'] = 'storniert';
      return _json(reservations[one.group(1)]!);
    }
    return _json({'title': 'Nicht gefunden'}, 404);
  }
}


/// Startet die Nachbildung auf Port 8098 (API-Schlüssel: „geheim“):
///   dart run tool/fake_materialkompass.dart
Future<void> main() async {
  await io.serve(FakeMaterialkompass().handle, InternetAddress.loopbackIPv4, 8098);
  stdout.writeln('Nachbildung der Materialkompass-Schnittstelle auf http://127.0.0.1:8098/api/v1 (Schlüssel: geheim)');
}
