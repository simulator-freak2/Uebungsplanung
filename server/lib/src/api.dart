import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'store.dart';

const serverVersion = '1.0.0';

/// HTTP-Schnittstelle des Servers (`/api/v1/...`).
class Api {
  Api(this.store, {this.name = 'Übungsplaner-Server'});
  final Store store;
  final String name;

  /// Fehlversuche je Benutzername (Schutz gegen Passwort-Raten).
  final _failures = <String, (int, DateTime)>{};

  static Response _json(Object? body, {int status = 200}) =>
      Response(status, body: jsonEncode(body), headers: {'content-type': 'application/json; charset=utf-8'});

  static Response _error(int status, String message) => _json({'error': message}, status: status);

  static Future<Map<String, Object?>> _body(Request r) async {
    final text = await r.readAsString();
    if (text.isEmpty) return {};
    final j = jsonDecode(text);
    if (j is! Map) throw const FormatException('JSON-Objekt erwartet');
    return j.cast<String, Object?>();
  }

  User? _auth(Request r) {
    final h = r.headers['authorization'];
    if (h == null || !h.startsWith('Bearer ')) return null;
    return store.userForToken(h.substring(7).trim());
  }

  Handler get handler {
    final router = Router()
      ..get('/api/v1/status', (Request r) => _json({'name': name, 'version': serverVersion, 'needsSetup': store.needsSetup, 'seq': store.seq}))
      ..post('/api/v1/setup', _setup)
      ..post('/api/v1/login', _login)
      ..post('/api/v1/logout', (Request r) {
        final h = r.headers['authorization'];
        if (h != null && h.startsWith('Bearer ')) store.logout(h.substring(7).trim());
        return _json({'ok': true});
      })
      ..get('/api/v1/me', (Request r) => _withUser(r, (u) => _json(u.toJson())))
      ..get('/api/v1/users', (Request r) => _withAdmin(r, (u) => _json([for (final x in store.users()) x.toJson()])))
      ..post('/api/v1/users', _createUser)
      ..patch('/api/v1/users/<id|[0-9]+>', _updateUser)
      ..get('/api/v1/sync', (Request r) => _withUser(r, (u) {
            final since = int.tryParse(r.url.queryParameters['since'] ?? '0') ?? 0;
            final p = store.pull(since);
            return _json({'rows': p.rows, 'settings': p.settings, 'seq': p.seq});
          }))
      ..post('/api/v1/sync', _push)
      ..put('/api/v1/settings', _settings);

    return const Pipeline().addMiddleware(_errors).addHandler(router.call);
  }

  Middleware get _errors => (inner) => (request) async {
        try {
          return await inner(request);
        } on FormatException catch (e) {
          return _error(400, 'Ungültige Anfrage: ${e.message}');
        } on ArgumentError catch (e) {
          return _error(400, '${e.message}');
        }
      };

  Future<Response> _withUser(Request r, FutureOr<Response> Function(User) f) async {
    final u = _auth(r);
    return u == null ? _error(401, 'Bitte anmelden') : await f(u);
  }

  Future<Response> _withAdmin(Request r, FutureOr<Response> Function(User) f) => _withUser(
        r,
        (u) async => u.role == Roles.admin ? await f(u) : _error(403, 'Nur für Administratoren'),
      );

  Future<Response> _setup(Request r) async {
    if (!store.needsSetup) return _error(409, 'Der Server ist bereits eingerichtet');
    final b = await _body(r);
    final pw = '${b['password'] ?? ''}';
    final problem = Store.checkPassword(pw);
    if (problem != null) return _error(400, problem);
    final user = store.createUser(
      username: '${b['username'] ?? 'admin'}',
      displayName: '${b['displayName'] ?? 'Administrator'}',
      password: pw,
      role: Roles.admin,
    );
    for (final e in ((b['settings'] as Map?) ?? const {}).entries) {
      if (sharedSettings.contains(e.key)) store.setSetting('${e.key}', '${e.value}');
    }
    store.audit(user.username, 'setup');
    final (token, _) = store.login(user.username, pw, device: '${b['device'] ?? ''}')!;
    return _json({'token': token, 'user': user.toJson()});
  }

  Future<Response> _login(Request r) async {
    final b = await _body(r);
    final name = '${b['username'] ?? ''}'.trim().toLowerCase();
    final f = _failures[name];
    if (f != null && f.$1 >= 5 && DateTime.now().difference(f.$2) < const Duration(minutes: 1)) {
      return _error(429, 'Zu viele Fehlversuche. Bitte eine Minute warten.');
    }
    final result = store.login(name, '${b['password'] ?? ''}', device: '${b['device'] ?? ''}');
    if (result == null) {
      _failures[name] = ((f?.$1 ?? 0) + 1, DateTime.now());
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _error(401, 'Benutzername oder Passwort falsch');
    }
    _failures.remove(name);
    store.audit(result.$2.username, 'login');
    return _json({'token': result.$1, 'user': result.$2.toJson()});
  }

  Future<Response> _createUser(Request r) => _withAdmin(r, (admin) async {
        final b = await _body(r);
        final pw = '${b['password'] ?? ''}';
        final problem = Store.checkPassword(pw);
        if (problem != null) return _error(400, problem);
        final username = '${b['username'] ?? ''}'.trim();
        if (username.isEmpty) return _error(400, 'Benutzername fehlt');
        if (store.users().any((u) => u.username.toLowerCase() == username.toLowerCase())) {
          return _error(409, 'Den Benutzernamen gibt es schon');
        }
        final u = store.createUser(username: username, displayName: '${b['displayName'] ?? username}', password: pw, role: '${b['role'] ?? Roles.planner}');
        store.audit(admin.username, 'user+ ${u.username}');
        return _json(u.toJson(), status: 201);
      });

  Future<Response> _updateUser(Request r, String id) => _withAdmin(r, (admin) async {
        final b = await _body(r);
        final target = store.userById(int.parse(id));
        if (target == null) return _error(404, 'Benutzer nicht gefunden');
        final role = b['role'] as String?;
        final active = b['active'] as bool?;
        // Der letzte aktive Administrator darf nicht verloren gehen.
        final losesAdmin = target.role == Roles.admin && target.active && ((role != null && role != Roles.admin) || active == false);
        if (losesAdmin && store.activeAdmins() <= 1) return _error(409, 'Es muss mindestens ein aktiver Administrator bleiben');
        final pw = b['password'] as String?;
        if (pw != null) {
          final problem = Store.checkPassword(pw);
          if (problem != null) return _error(400, problem);
        }
        store.updateUser(target.id, displayName: b['displayName'] as String?, role: role, active: active, password: pw);
        store.audit(admin.username, 'user~ ${target.username}');
        return _json(store.userById(target.id)!.toJson());
      });

  Future<Response> _push(Request r) => _withUser(r, (u) async {
        final b = await _body(r);
        final rows = [for (final x in (b['rows'] as List? ?? const [])) (x as Map).cast<String, Object?>()];
        final result = store.push(u, rows);
        return _json({'accepted': result.accepted, 'rejected': result.rejected, 'seq': result.seq});
      });

  Future<Response> _settings(Request r) => _withAdmin(r, (u) async {
        final b = await _body(r);
        for (final e in b.entries) {
          store.setSetting(e.key, '${e.value}');
        }
        return _json(store.settings());
      });
}
