import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../data/database.dart';
import '../data/exercise_repository.dart';
import '../data/repositories.dart';

/// Einstellungen der Anbindung (gerätebezogen; die Freischaltung der
/// Reservierung ist eine gemeinsame Einstellung der Admins).
abstract final class MkKeys {
  static const url = 'mk_url';
  static const apiKey = 'mk_api_key';
  static const lastSync = 'mk_last_sync';
  static const reservations = 'mk_reservations'; // „true“ = Planer dürfen reservieren
}

const reservationStatus = {
  'angefragt': 'Reservierung angefragt',
  'bestaetigt': 'Reservierung bestätigt',
  'abgelehnt': 'Reservierung abgelehnt',
  'storniert': 'Reservierung storniert',
};

const mkVehicleStatus = {
  'einsatzbereit': 'einsatzbereit',
  'bedingt_einsatzbereit': 'bedingt_einsatzbereit',
  'ausser_dienst': 'ausser_dienst',
  'werkstatt': 'werkstatt',
};

class MkException implements Exception {
  MkException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}

/// Zugriff auf die Materialkompass-Schnittstelle (`/api/v1`), siehe
/// `docs/SCHNITTSTELLE_MATERIALKOMPASS.md`.
class MkClient {
  MkClient(String baseUrl, this.apiKey, {http.Client? client})
      : baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), ''),
        _http = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? q]) {
    final base = baseUrl.endsWith('/api/v1') ? baseUrl : '$baseUrl/api/v1';
    return Uri.parse('$base/$path').replace(queryParameters: q == null || q.isEmpty ? null : q);
  }

  Map<String, String> _headers([Map<String, String> extra = const {}]) =>
      {'authorization': 'Bearer $apiKey', 'content-type': 'application/json; charset=utf-8', 'accept': 'application/json', ...extra};

  Future<dynamic> _send(Future<http.Response> req) async {
    final http.Response r;
    try {
      r = await req.timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw MkException(0, 'Materialkompass nicht erreichbar: $e');
    }
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) {
      final msg = body is Map ? (body['detail'] ?? body['title'] ?? body['error']) : null;
      throw MkException(r.statusCode, '${msg ?? 'Fehler ${r.statusCode}'}');
    }
    return body;
  }

  Future<String> status() async {
    final j = await _send(_http.get(_uri('status'), headers: _headers())) as Map<String, dynamic>;
    final org = (j['organisation'] as Map?)?['name'];
    return '${org ?? 'Materialkompass'} (API ${j['version'] ?? '?'})';
  }

  /// Alle Seiten einer Liste abholen (`geaendert_seit`, `cursor`).
  Future<(List<Map<String, dynamic>>, String?)> _list(String path, {String? since}) async {
    final out = <Map<String, dynamic>>[];
    String? cursor;
    String? serverTime;
    do {
      final j = await _send(_http.get(
        _uri(path, {'limit': '500', 'geaendert_seit': ?since, 'cursor': ?cursor}),
        headers: _headers(),
      )) as Map<String, dynamic>;
      out.addAll([for (final e in j['daten'] as List) (e as Map).cast<String, dynamic>()]);
      cursor = j['naechster_cursor'] as String?;
      serverTime = j['server_zeit'] as String? ?? serverTime;
    } while (cursor != null);
    return (out, serverTime);
  }

  Future<(List<Map<String, dynamic>>, String?)> vehicles({String? since}) => _list('fahrzeuge', since: since);
  Future<(List<Map<String, dynamic>>, String?)> material({String? since}) => _list('material', since: since);

  Future<bool> available(String vehicleId, DateTime from, DateTime to) async {
    final j = await _send(_http.get(
      _uri('fahrzeuge/$vehicleId/verfuegbarkeit', {'von': from.toIso8601String(), 'bis': to.toIso8601String()}),
      headers: _headers(),
    )) as Map<String, dynamic>;
    return j['verfuegbar'] == true;
  }

  static String _idempotencyKey() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<Map<String, dynamic>> reserve({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
    required String purpose,
    required String reference,
    String? user,
    String? idempotencyKey,
  }) async =>
      (await _send(_http.post(
        _uri('reservierungen'),
        headers: _headers({'idempotency-key': idempotencyKey ?? _idempotencyKey()}),
        body: jsonEncode({
          'fahrzeug_id': vehicleId,
          'von': from.toIso8601String(),
          'bis': to.toIso8601String(),
          'zweck': purpose,
          'referenz': reference,
          'angelegt_von': ?user,
        }),
      )) as Map).cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> reservations(String reference) async {
    final j = await _send(_http.get(_uri('reservierungen', {'referenz': reference}), headers: _headers()));
    final list = j is Map ? j['daten'] as List : j as List;
    return [for (final e in list) (e as Map).cast<String, dynamic>()];
  }

  Future<void> cancel(String reservationId) => _send(_http.delete(_uri('reservierungen/$reservationId'), headers: _headers()));
}

/// Ergebnis eines Abgleichs.
class MkSyncResult {
  MkSyncResult(this.material, this.vehiclesUpdated, this.unmatched);
  final int material;
  final int vehiclesUpdated;

  /// Fahrzeuge aus Materialkompass ohne Gegenstück im Übungsplaner.
  final List<Map<String, dynamic>> unmatched;
}

/// Übernimmt Material und Fahrzeuge und verwaltet Reservierungen.
class MaterialkompassService {
  MaterialkompassService(this.repo, {this.clientFactory});
  final Repositories repo;
  final MkClient Function(String url, String key)? clientFactory;
  AppDatabase get db => repo.db;

  Future<MkClient?> client() async {
    final url = await repo.settings.get(MkKeys.url);
    final key = await repo.settings.get(MkKeys.apiKey);
    if (url == null || url.isEmpty || key == null || key.isEmpty) return null;
    return (clientFactory ?? MkClient.new)(url, key);
  }

  Future<bool> get reservationsEnabled async => await repo.settings.get(MkKeys.reservations) == 'true';

  String _norm(Object? s) => '${s ?? ''}'.trim().toLowerCase();

  /// Holt Material (in den lokalen Zwischenspeicher) und Fahrzeuge (Status,
  /// Funkrufname, Zuordnung über Materialkompass-ID oder Bezeichnung).
  Future<MkSyncResult> sync() async {
    final c = await client();
    if (c == null) throw MkException(0, 'Materialkompass ist nicht eingerichtet (Einstellungen).');
    final (vehicles, _) = await c.vehicles();
    final (material, serverTime) = await c.material();

    // Fahrzeuge
    final local = await (db.select(db.vehicles)..where((t) => t.deleted.equals(false))).get();
    var updated = 0;
    final unmatched = <Map<String, dynamic>>[];
    for (final v in vehicles) {
      if (v['geloescht'] == true) continue;
      final id = '${v['id']}';
      final match = local.where((l) => l.externalId == id).firstOrNull ??
          local.where((l) => l.externalId == null && (_norm(l.name) == _norm(v['bezeichnung']) || (l.callSign != null && _norm(l.callSign) == _norm(v['funkrufname'])))).firstOrNull;
      if (match == null) {
        unmatched.add(v);
        continue;
      }
      await (db.update(db.vehicles)..where((t) => t.id.equals(match.id))).write(VehiclesCompanion(
            externalId: Value(id),
            status: Value(mkVehicleStatus[v['status']] ?? match.status),
            callSign: Value(match.callSign ?? v['funkrufname'] as String?),
            updatedAt: Value(AppDatabase.now()),
          ));
      updated++;
    }

    // Material (vollständig ersetzen; gelöschte entfallen)
    final names = {for (final v in vehicles) '${v['id']}': '${v['bezeichnung']}'};
    await db.transaction(() async {
      await db.delete(db.mkMaterials).go();
      for (final m in material) {
        if (m['geloescht'] == true) continue;
        final vid = m['verlastet_auf_fahrzeug_id'] as String?;
        await db.into(db.mkMaterials).insert(MkMaterialsCompanion.insert(
              id: '${m['id']}',
              name: '${m['bezeichnung']}',
              category: Value(m['kategorie'] as String?),
              inventoryNo: Value(m['inventarnummer'] as String?),
              quantity: Value((m['menge'] as num?)?.toDouble()),
              unit: Value(m['einheit'] as String?),
              vehicleId: Value(vid),
              location: Value(vid != null ? names[vid] : (m['lagerort'] as String?)),
              status: Value(m['status'] as String?),
            ));
      }
    });
    await repo.settings.set(MkKeys.lastSync, serverTime ?? DateTime.now().toIso8601String());
    return MkSyncResult(material.where((m) => m['geloescht'] != true).length, updated, unmatched);
  }

  /// Legt ein Fahrzeug aus Materialkompass im Übungsplaner an.
  Future<String> createVehicle(Map<String, dynamic> v) async {
    final id = await repo.vehicles.save(VehicleInput(
      name: '${v['bezeichnung']}',
      type: v['typ'] as String?,
      kind: v['art'] == 'boot' ? 'boot' : (v['art'] == 'anhaenger' ? 'anhaenger' : 'fahrzeug'),
      callSign: v['funkrufname'] as String?,
      status: mkVehicleStatus[v['status']] ?? 'einsatzbereit',
    ));
    await (db.update(db.vehicles)..where((t) => t.id.equals(id))).write(VehiclesCompanion(externalId: Value('${v['id']}')));
    return id;
  }

  Stream<List<MkMaterial>> watchMaterial() => (db.select(db.mkMaterials)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();

  /// Übernimmt Material aus dem Zwischenspeicher in die Materialliste einer Übung.
  Future<void> addToExercise(String exerciseId, List<MkMaterial> items) => db.transaction(() async {
        var n = (await (db.select(db.materialItems)..where((t) => t.exerciseId.equals(exerciseId))).get()).length;
        for (final m in items) {
          final q = m.quantity == null ? null : '${m.quantity == m.quantity!.roundToDouble() ? m.quantity!.toInt() : m.quantity}${m.unit == null ? '' : ' ${m.unit}'}';
          await db.into(db.materialItems).insert(MaterialItemsCompanion.insert(
                exerciseId: exerciseId,
                name: m.name,
                location: Value(m.location),
                quantity: Value(q),
                source: const Value('materialkompass'),
                externalId: Value(m.id),
                sortOrder: Value(n++),
              ));
        }
      });

  /// Zeitraum einer Übung (lokale Zeit).
  static (DateTime, DateTime) window(Exercise e) {
    final from = DateTime(e.date.year, e.date.month, e.date.day).add(Duration(minutes: e.startMinutes));
    final end = e.endMinutes ?? e.startMinutes + 180;
    var to = DateTime(e.date.year, e.date.month, e.date.day).add(Duration(minutes: end));
    if (!to.isAfter(from)) to = to.add(const Duration(days: 1));
    return (from, to);
  }

  static String reference(String exerciseId) => 'uebungsplaner:$exerciseId';

  /// Fragt eine Reservierung an (genehmigungspflichtig in Materialkompass).
  Future<String> reserve(Exercise e, ExerciseVehicle ev, Vehicle v, {String? user}) async {
    final c = await client();
    if (c == null) throw MkException(0, 'Materialkompass ist nicht eingerichtet.');
    if (v.externalId == null) throw MkException(0, '${v.name} ist keinem Fahrzeug in Materialkompass zugeordnet (Abgleich ausführen).');
    final (from, to) = window(e);
    if (!await c.available(v.externalId!, from, to)) {
      throw MkException(409, '${v.name} ist in diesem Zeitraum bereits belegt.');
    }
    final r = await c.reserve(
      vehicleId: v.externalId!,
      from: from,
      to: to,
      purpose: 'Übung: ${e.title}',
      reference: reference(e.id),
      user: user,
      idempotencyKey: 'uebungsplaner-${ev.id}',
    );
    await _store(ev.id, '${r['id']}', '${r['status'] ?? 'angefragt'}', r['begruendung'] as String?);
    return '${r['status'] ?? 'angefragt'}';
  }

  /// Aktualisiert den Status aller Reservierungen einer Übung.
  Future<void> refresh(ExerciseDetail d) async {
    final c = await client();
    if (c == null) return;
    final list = await c.reservations(reference(d.exercise.id));
    for (final ev in d.vehicles.where((x) => x.reservationId != null)) {
      final r = list.where((x) => '${x['id']}' == ev.reservationId).firstOrNull;
      if (r != null) await _store(ev.id, ev.reservationId!, '${r['status']}', r['begruendung'] as String?);
    }
  }

  Future<void> cancel(ExerciseVehicle ev) async {
    final c = await client();
    if (c == null || ev.reservationId == null) return;
    await c.cancel(ev.reservationId!);
    await _store(ev.id, ev.reservationId!, 'storniert', null);
  }

  Future<void> _store(String exerciseVehicleId, String id, String status, String? note) =>
      (db.update(db.exerciseVehicles)..where((t) => t.id.equals(exerciseVehicleId))).write(ExerciseVehiclesCompanion(
            reservationId: Value(id),
            reservationStatus: Value(status),
            reservationNote: Value(note),
            updatedAt: Value(AppDatabase.now()),
          ));
}
