import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import 'server_client.dart';

/// Schlüssel der lokalen Einstellungen für den Serverbetrieb (werden nicht
/// abgeglichen).
abstract final class SyncKeys {
  static const mode = 'mode'; // lokal | netz
  static const url = 'server_url';
  static const token = 'server_token';
  static const user = 'server_user';
  static const seq = 'sync_seq';
  static const pushedAt = 'sync_pushed_at';
}

/// Einstellungen, die für alle Geräte gelten und vom Server kommen.
const sharedSettingKeys = {SettingsRepository.orgName, SettingsRepository.profileId, SettingsRepository.approvalRequired, 'mk_reservations'};

enum SyncState { local, idle, syncing, offline, error, loggedOut }

/// Anmeldung am Server und Abgleich der Daten.
///
/// Offline-first: Gearbeitet wird immer in der lokalen Datenbank. Der
/// Abgleich läuft im Hintergrund (alle 30 Sekunden und kurz nach jeder
/// Änderung). Konflikte löst der Server: die jüngere Änderung gilt.
class Session extends ChangeNotifier {
  Session(this.repo);
  final Repositories repo;
  AppDatabase get db => repo.db;

  ServerClient? client;
  ServerUser? user;
  SyncState state = SyncState.local;
  String? message;
  DateTime? lastSync;
  List<Map<String, dynamic>> lastRejected = const [];

  Timer? _timer;
  Timer? _debounce;
  StreamSubscription<Set<TableUpdate>>? _changes;
  bool _running = false;
  bool _again = false;

  bool get networked => client != null;

  /// Tablets und Beobachter sehen die Daten nur.
  bool get readOnly => user?.role == 'beobachter' || isMobilePlatform;
  bool get canApprove => !networked || user?.role == 'admin' || user?.role == 'tl';
  bool get isAdmin => !networked || user?.role == 'admin';
  String get roleLabel => networked ? (roleLabels[user?.role] ?? user?.role ?? '') : 'lokal';

  static bool get isMobilePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Liest die gespeicherte Verbindung beim App-Start.
  Future<void> restore() async {
    final s = repo.settings;
    if (await s.get(SyncKeys.mode) != 'netz') {
      state = SyncState.local;
      notifyListeners();
      return;
    }
    final url = await s.get(SyncKeys.url);
    final token = await s.get(SyncKeys.token);
    final userJson = await s.get(SyncKeys.user);
    if (url == null) return;
    client = ServerClient(url, token: token);
    user = userJson == null ? null : ServerUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    if (token == null || user == null) {
      state = SyncState.loggedOut;
    } else {
      state = SyncState.idle;
      _start();
      unawaited(syncNow());
    }
    notifyListeners();
  }

  /// Verbindet mit einem Server: richtet ihn bei Bedarf ein (erster Admin)
  /// oder meldet sich an. Lokale Daten werden anschließend hochgeladen.
  Future<void> connect({
    required String url,
    required String username,
    required String password,
    String? displayName,
    bool setup = false,
  }) async {
    final c = ServerClient(url);
    final device = Platform.localHostname;
    if (setup) {
      final settings = <String, String>{};
      for (final k in sharedSettingKeys) {
        final v = await repo.settings.get(k);
        if (v != null) settings[k] = v;
      }
      user = await c.setup(username: username, displayName: displayName ?? username, password: password, settings: settings, device: device);
    } else {
      user = await c.login(username, password, device: device);
    }
    client = c;
    final s = repo.settings;
    await s.set(SyncKeys.mode, 'netz');
    await s.set(SyncKeys.url, c.baseUrl);
    await s.set(SyncKeys.token, c.token!);
    await s.set(SyncKeys.user, jsonEncode(user!.toJson()));
    // Neue Verbindung: alles abholen und alle lokalen Daten anbieten.
    await s.set(SyncKeys.seq, '0');
    await s.set(SyncKeys.pushedAt, '0');
    state = SyncState.idle;
    notifyListeners();
    await syncNow();
    _start();
  }

  /// Neu anmelden (z. B. nach Ablauf oder Sperre).
  Future<void> login(String username, String password) async {
    final c = client!;
    user = await c.login(username, password, device: Platform.localHostname);
    await repo.settings.set(SyncKeys.token, c.token!);
    await repo.settings.set(SyncKeys.user, jsonEncode(user!.toJson()));
    state = SyncState.idle;
    notifyListeners();
    await syncNow();
    _start();
  }

  Future<void> logout() async {
    _stop();
    await client?.logout();
    await (db.delete(db.settings)..where((t) => t.key.isIn([SyncKeys.token, SyncKeys.user]))).go();
    user = null;
    state = SyncState.loggedOut;
    notifyListeners();
  }

  /// Zurück in den reinen Lokalbetrieb. Die Daten bleiben auf dem Gerät.
  Future<void> disconnect() async {
    _stop();
    await client?.logout();
    await (db.delete(db.settings)..where((t) => t.key.isIn([SyncKeys.url, SyncKeys.token, SyncKeys.user, SyncKeys.seq, SyncKeys.pushedAt]))).go();
    await repo.settings.set(SyncKeys.mode, 'lokal');
    client = null;
    user = null;
    state = SyncState.local;
    notifyListeners();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
    _changes ??= db.tableUpdates().listen((u) {
      if (u.every((t) => t.table == db.settings.actualTableName || t.table == db.mkMaterials.actualTableName)) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 2), syncNow);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _debounce?.cancel();
    _changes?.cancel();
    _changes = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  /// Gleicht sofort ab: erst eigene Änderungen hochladen, dann abholen.
  Future<void> syncNow() async {
    final c = client;
    if (c == null || c.token == null || user == null) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    state = SyncState.syncing;
    notifyListeners();
    try {
      do {
        _again = false;
        await _push(c);
        await _pull(c);
      } while (_again);
      state = SyncState.idle;
      message = null;
      lastSync = DateTime.now();
    } on ServerException catch (e) {
      if (e.unauthorized) {
        state = SyncState.loggedOut;
        message = 'Bitte erneut anmelden';
        _stop();
      } else {
        state = e.status == 0 ? SyncState.offline : SyncState.error;
        message = e.message;
      }
    } catch (e) {
      state = SyncState.error;
      message = '$e';
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  /// Abgeglichen werden alle Tabellen außer Einstellungen und lokalen Zwischenspeichern.
  Iterable<TableInfo> get _tables =>
      db.allTables.where((t) => t.actualTableName != db.settings.actualTableName && t.actualTableName != db.mkMaterials.actualTableName);

  /// Lokale Änderungen seit dem letzten Hochladen (Datensätze als
  /// Spaltenwerte, wie sie in der Datenbank stehen).
  Future<List<Map<String, Object?>>> changedRows(int since) async {
    final rows = <Map<String, Object?>>[];
    for (final t in _tables) {
      final result = await db.customSelect('SELECT * FROM "${t.actualTableName}" WHERE updated_at > ?', variables: [Variable.withInt(since)]).get();
      for (final r in result) {
        rows.add({'table': t.actualTableName, 'data': r.data});
      }
    }
    return rows;
  }

  Future<void> _push(ServerClient c) async {
    if (readOnly) return;
    final since = int.tryParse(await repo.settings.get(SyncKeys.pushedAt) ?? '0') ?? 0;
    // Zeitpunkt vor dem Lesen merken, damit nichts verloren geht.
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 - 1;
    final rows = await changedRows(since);
    for (var i = 0; i < rows.length; i += 500) {
      final r = await c.push(rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500));
      lastRejected = r.rejected;
    }
    await repo.settings.set(SyncKeys.pushedAt, '$now');
  }

  Future<void> _pull(ServerClient c) async {
    var seq = int.tryParse(await repo.settings.get(SyncKeys.seq) ?? '0') ?? 0;
    while (true) {
      final p = await c.pull(seq);
      await applyRows(p.rows);
      for (final e in p.settings.entries) {
        if (sharedSettingKeys.contains(e.key) && await repo.settings.get(e.key) != e.value) {
          await repo.settings.set(e.key, e.value);
        }
      }
      final done = p.seq == seq || p.rows.isEmpty;
      seq = p.seq;
      await repo.settings.set(SyncKeys.seq, '$seq');
      if (done || p.rows.length < 5000) break;
    }
  }

  /// Übernimmt Datensätze vom Server („letzte Änderung gilt“).
  Future<int> applyRows(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return 0;
    final tables = {for (final t in _tables) t.actualTableName: t};
    var applied = 0;
    await db.transaction(() async {
      for (final r in rows) {
        final t = tables[r['table']];
        final data = (r['data'] as Map?)?.cast<String, dynamic>();
        if (t == null || data == null) continue;
        final cols = {for (final c in t.$columns) c.name};
        final keys = data.keys.where(cols.contains).toList();
        if (!keys.contains('id') || !keys.contains('updated_at')) continue;
        final q = keys.map((k) => '"$k"').join(', ');
        final sets = keys.where((k) => k != 'id').map((k) => '"$k" = excluded."$k"').join(', ');
        final name = t.actualTableName;
        await db.customUpdate(
          'INSERT INTO "$name" ($q) VALUES (${List.filled(keys.length, '?').join(', ')}) '
          'ON CONFLICT(id) DO UPDATE SET $sets WHERE excluded.updated_at >= "$name".updated_at',
          variables: [for (final k in keys) _variable(data[k])],
          updates: {t},
          updateKind: UpdateKind.update,
        );
        applied++;
      }
    });
    return applied;
  }

  static Variable<Object> _variable(Object? v) => switch (v) {
        null => const Variable(null),
        int i => Variable.withInt(i),
        double d => Variable.withReal(d),
        bool b => Variable.withInt(b ? 1 : 0),
        _ => Variable.withString('$v'),
      };

  /// Gemeinsame Einstellung ändern (nur Admin; lokal sofort, auf dem Server
  /// beim nächsten Abgleich der anderen Geräte).
  Future<void> setShared(String key, String value) async {
    await repo.settings.set(key, value);
    if (networked && user?.role == 'admin') {
      try {
        await client!.putSettings({key: value});
      } catch (_) {}
    }
  }
}
