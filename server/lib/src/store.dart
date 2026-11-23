import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

/// Rollen im Übungsplaner.
abstract final class Roles {
  static const admin = 'admin';
  static const tl = 'tl'; // TL / Wehrführer: darf freigeben
  static const planner = 'planer';
  static const observer = 'beobachter'; // nur lesen (z. B. Tablet)
  static const all = [admin, tl, planner, observer];

  static bool canWrite(String role) => role != observer;
  static bool canApprove(String role) => role == admin || role == tl;
}

/// Tabellen, die zwischen den Geräten abgeglichen werden (SQL-Namen der App).
const syncTables = {
  'qualifications',
  'persons',
  'person_qualifications',
  'vehicles',
  'crew_functions',
  'crew_patterns',
  'crew_pattern_functions',
  'keywords',
  'exercises',
  'exercise_phases',
  'exercise_safety_checks',
  'exercise_vehicles',
  'exercise_assignments',
  'alarm_plan_entries',
  'radio_entries',
  'role_cards',
  'material_items',
  'observation_items',
  'observation_templates',
  'lessons',
};

/// Einstellungen, die für alle Geräte gelten.
const sharedSettings = {'org_name', 'profile_id', 'approval_required', 'mk_reservations'};

class User {
  User(this.id, this.username, this.displayName, this.role, this.active);
  final int id;
  final String username;
  final String displayName;
  final String role;
  final bool active;

  Map<String, Object?> toJson() => {'id': id, 'username': username, 'displayName': displayName, 'role': role, 'active': active};
}

class PushResult {
  PushResult(this.accepted, this.rejected, this.seq);
  final int accepted;
  final List<Map<String, String>> rejected;
  final int seq;
}

/// Datenhaltung des Servers in einer SQLite-Datei.
///
/// Datensätze der App werden als JSON gespeichert. Jede Änderung bekommt eine
/// fortlaufende Nummer (`seq`); Geräte holen alles ab einer Nummer ab.
/// Konflikte: der Datensatz mit dem jüngeren `updated_at` gewinnt.
class Store {
  Store(this.db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE COLLATE NOCASE,
        display_name TEXT NOT NULL,
        role TEXT NOT NULL,
        salt TEXT NOT NULL,
        hash TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL);
      CREATE TABLE IF NOT EXISTS tokens(
        token TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        expires INTEGER NOT NULL,
        device TEXT);
      CREATE TABLE IF NOT EXISTS rows(
        tbl TEXT NOT NULL,
        id TEXT NOT NULL,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        seq INTEGER NOT NULL,
        PRIMARY KEY(tbl, id));
      CREATE INDEX IF NOT EXISTS rows_seq ON rows(seq);
      CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT NOT NULL, seq INTEGER NOT NULL);
      CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE IF NOT EXISTS audit(at INTEGER NOT NULL, user TEXT, action TEXT NOT NULL);
    ''');
  }

  factory Store.open(String path) => Store(sqlite3.open(path));
  factory Store.memory() => Store(sqlite3.openInMemory());

  final Database db;
  static final _rnd = Random.secure();

  int _now() => DateTime.now().millisecondsSinceEpoch;

  void audit(String? user, String action) => db.execute('INSERT INTO audit VALUES(?,?,?)', [_now(), user, action]);

  // --------------------------------------------------------------- Benutzer

  bool get needsSetup => db.select('SELECT COUNT(*) AS n FROM users').first['n'] == 0;

  static String _token([int bytes = 32]) =>
      base64Url.encode(List<int>.generate(bytes, (_) => _rnd.nextInt(256))).replaceAll('=', '');

  /// PBKDF2-HMAC-SHA256 mit 120 000 Durchläufen.
  static String hashPassword(String password, String salt, {int iterations = 120000}) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final block = Uint8List.fromList([...utf8.encode(salt), 0, 0, 0, 1]);
    var u = hmac.convert(block).bytes;
    final out = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return base64.encode(out);
  }

  static String? checkPassword(String password) =>
      password.length < 8 ? 'Das Passwort muss mindestens 8 Zeichen haben.' : null;

  User _user(Row r) => User(r['id'] as int, r['username'] as String, r['display_name'] as String, r['role'] as String, r['active'] == 1);

  List<User> users() => db.select('SELECT * FROM users ORDER BY display_name').map(_user).toList();

  User? userById(int id) {
    final r = db.select('SELECT * FROM users WHERE id = ?', [id]);
    return r.isEmpty ? null : _user(r.first);
  }

  User createUser({required String username, required String displayName, required String password, required String role}) {
    if (!Roles.all.contains(role)) throw ArgumentError('Unbekannte Rolle: $role');
    final salt = _token(16);
    db.execute('INSERT INTO users(username, display_name, role, salt, hash, created_at) VALUES(?,?,?,?,?,?)',
        [username.trim(), displayName.trim(), role, salt, hashPassword(password, salt), _now()]);
    return userById(db.lastInsertRowId)!;
  }

  void updateUser(int id, {String? displayName, String? role, bool? active, String? password}) {
    if (role != null && !Roles.all.contains(role)) throw ArgumentError('Unbekannte Rolle: $role');
    if (displayName != null) db.execute('UPDATE users SET display_name = ? WHERE id = ?', [displayName.trim(), id]);
    if (role != null) db.execute('UPDATE users SET role = ? WHERE id = ?', [role, id]);
    if (active != null) {
      db.execute('UPDATE users SET active = ? WHERE id = ?', [active ? 1 : 0, id]);
      if (!active) db.execute('DELETE FROM tokens WHERE user_id = ?', [id]);
    }
    if (password != null) {
      final salt = _token(16);
      db.execute('UPDATE users SET salt = ?, hash = ? WHERE id = ?', [salt, hashPassword(password, salt), id]);
      db.execute('DELETE FROM tokens WHERE user_id = ?', [id]);
    }
  }

  int activeAdmins() => db.select("SELECT COUNT(*) AS n FROM users WHERE role = 'admin' AND active = 1").first['n'] as int;

  /// Prüft Benutzername und Passwort und gibt ein Anmelde-Token zurück
  /// (gültig 180 Tage).
  (String, User)? login(String username, String password, {String? device}) {
    final r = db.select('SELECT * FROM users WHERE username = ? AND active = 1', [username.trim()]);
    if (r.isEmpty) return null;
    final row = r.first;
    if (hashPassword(password, row['salt'] as String) != row['hash']) return null;
    final token = _token();
    db.execute('INSERT INTO tokens VALUES(?,?,?,?)', [token, row['id'], _now() + const Duration(days: 180).inMilliseconds, device]);
    return (token, _user(row));
  }

  User? userForToken(String token) {
    final r = db.select('SELECT u.* FROM tokens t JOIN users u ON u.id = t.user_id WHERE t.token = ? AND t.expires > ? AND u.active = 1', [token, _now()]);
    return r.isEmpty ? null : _user(r.first);
  }

  void logout(String token) => db.execute('DELETE FROM tokens WHERE token = ?', [token]);

  // ----------------------------------------------------------------- Abgleich

  int get seq => int.parse((db.select("SELECT value FROM meta WHERE key = 'seq'").firstOrNull?['value'] as String?) ?? '0');

  int _nextSeq() {
    final n = seq + 1;
    db.execute("INSERT INTO meta VALUES('seq', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value", ['$n']);
    return n;
  }

  /// Alle Änderungen nach [since].
  ({List<Map<String, Object?>> rows, Map<String, String> settings, int seq}) pull(int since, {int limit = 5000}) {
    final rows = db.select('SELECT tbl, data, seq FROM rows WHERE seq > ? ORDER BY seq LIMIT ?', [since, limit]);
    final settings = {for (final r in db.select('SELECT key, value FROM settings')) r['key'] as String: r['value'] as String};
    final last = rows.isEmpty ? seq : rows.last['seq'] as int;
    return (
      rows: [for (final r in rows) {'table': r['tbl'], 'data': jsonDecode(r['data'] as String)}],
      settings: settings,
      seq: rows.length == limit ? last : seq,
    );
  }

  /// Übernimmt Änderungen eines Geräts. Prüft Rollenrechte:
  /// Beobachter dürfen nichts ändern; den Freigabe-Status einer Übung dürfen
  /// nur TL/Wehrführer und Admin setzen oder aufheben.
  PushResult push(User user, List<Map<String, Object?>> rows) {
    final rejected = <Map<String, String>>[];
    var accepted = 0;
    if (!Roles.canWrite(user.role)) {
      return PushResult(0, [for (final r in rows) {'table': '${r['table']}', 'id': '${(r['data'] as Map?)?['id']}', 'reason': 'Nur Leserechte'}], seq);
    }
    final approvalRequired = settings()['approval_required'] != 'false';
    db.execute('BEGIN');
    try {
      for (final r in rows) {
        final table = '${r['table']}';
        final data = (r['data'] as Map?)?.cast<String, Object?>();
        final id = data?['id'];
        void reject(String why) => rejected.add({'table': table, 'id': '$id', 'reason': why});
        if (!syncTables.contains(table)) {
          reject('Unbekannte Tabelle');
          continue;
        }
        if (data == null || id is! String || data['updated_at'] is! int) {
          reject('Ungültiger Datensatz');
          continue;
        }
        final existing = db.select('SELECT data, updated_at FROM rows WHERE tbl = ? AND id = ?', [table, id]).firstOrNull;
        if (existing != null && (existing['updated_at'] as int) > (data['updated_at'] as int)) {
          reject('Auf dem Server gibt es eine neuere Änderung');
          continue;
        }
        // Unverändert (z. B. gerade erst abgeholt): nicht erneut verteilen.
        if (existing != null && existing['data'] == jsonEncode(data)) {
          accepted++;
          continue;
        }
        if (table == 'exercises' && !Roles.canApprove(user.role) && approvalRequired) {
          final old = existing == null ? null : jsonDecode(existing['data'] as String) as Map<String, Object?>;
          final wasApproved = old?['status'] == 'freigegeben';
          final isApproved = data['status'] == 'freigegeben';
          if (wasApproved != isApproved || (isApproved && old?['approved_by'] != data['approved_by'])) {
            reject('Freigabe nur durch TL / Wehrführer');
            continue;
          }
        }
        db.execute(
          'INSERT INTO rows VALUES(?,?,?,?,?) ON CONFLICT(tbl, id) DO UPDATE SET data = excluded.data, updated_at = excluded.updated_at, seq = excluded.seq',
          [table, id, jsonEncode(data), data['updated_at'], _nextSeq()],
        );
        accepted++;
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
    if (accepted > 0) audit(user.username, 'push $accepted');
    return PushResult(accepted, rejected, seq);
  }

  Map<String, String> settings() => {for (final r in db.select('SELECT key, value FROM settings')) r['key'] as String: r['value'] as String};

  void setSetting(String key, String value) {
    if (!sharedSettings.contains(key)) throw ArgumentError('Unbekannte Einstellung: $key');
    db.execute('INSERT INTO settings VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value = excluded.value, seq = excluded.seq', [key, value, _nextSeq()]);
  }
}
