import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:uebungsplaner_server/server.dart';

void main() {
  late Store store;
  late Handler h;

  setUp(() {
    store = Store.memory();
    h = Api(store).handler;
  });

  Future<(int, dynamic)> call(String method, String path, {Object? body, String? token}) async {
    final r = await h(Request(method, Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body), headers: {if (token != null) 'authorization': 'Bearer $token'}));
    final text = await r.readAsString();
    return (r.statusCode, text.isEmpty ? null : jsonDecode(text));
  }

  Future<String> setupAdmin() async {
    final (s, b) = await call('POST', '/api/v1/setup', body: {'username': 'admin', 'password': 'geheim123', 'displayName': 'Admin', 'settings': {'org_name': 'FF Test'}});
    expect(s, 200);
    return b['token'] as String;
  }

  Future<String> user(String admin, String name, String role) async {
    final (s, _) = await call('POST', '/api/v1/users', token: admin, body: {'username': name, 'password': 'passwort1', 'role': role});
    expect(s, 201);
    final (_, b) = await call('POST', '/api/v1/login', body: {'username': name, 'password': 'passwort1'});
    return b['token'] as String;
  }

  Map<String, Object?> exercise(String id, int t, {String status = 'entwurf', String? by}) =>
      {'table': 'exercises', 'data': {'id': id, 'updated_at': t, 'deleted': 0, 'title': 'Übung', 'status': status, 'approved_by': by}};

  test('Einrichtung nur einmal, danach Anmeldung', () async {
    expect((await call('GET', '/api/v1/status')).$2['needsSetup'], isTrue);
    await setupAdmin();
    expect((await call('GET', '/api/v1/status')).$2['needsSetup'], isFalse);
    expect((await call('POST', '/api/v1/setup', body: {'password': 'abcdefgh'})).$1, 409);
    expect((await call('POST', '/api/v1/login', body: {'username': 'admin', 'password': 'falsch'})).$1, 401);
    final (s, b) = await call('POST', '/api/v1/login', body: {'username': 'ADMIN', 'password': 'geheim123'});
    expect(s, 200);
    expect(b['user']['role'], 'admin');
    expect(store.settings()['org_name'], 'FF Test');
  });

  test('Ohne Anmeldung kein Zugriff, kurze Passwörter abgelehnt', () async {
    expect((await call('GET', '/api/v1/sync')).$1, 401);
    expect((await call('POST', '/api/v1/setup', body: {'password': 'kurz'})).$1, 400);
  });

  test('Abgleich: hochladen, abholen, letzte Änderung gewinnt', () async {
    final admin = await setupAdmin();
    final planner = await user(admin, 'planer', 'planer');
    var (s, b) = await call('POST', '/api/v1/sync', token: planner, body: {'rows': [exercise('e1', 100), exercise('e2', 100)]});
    expect(b['accepted'], 2);
    (s, b) = await call('GET', '/api/v1/sync?since=0', token: admin);
    expect((b['rows'] as List).length, 2);
    final seq = b['seq'] as int;

    // ältere Änderung wird abgelehnt, neuere übernommen
    (s, b) = await call('POST', '/api/v1/sync', token: admin, body: {'rows': [exercise('e1', 50), exercise('e2', 200)]});
    expect(b['accepted'], 1);
    expect((b['rejected'] as List).single['id'], 'e1');
    (s, b) = await call('GET', '/api/v1/sync?since=$seq', token: planner);
    expect((b['rows'] as List).single['data']['id'], 'e2');
    expect(b['settings'], isA<Map>());

    // unbekannte Tabelle
    (s, b) = await call('POST', '/api/v1/sync', token: admin, body: {'rows': [{'table': 'users', 'data': {'id': 'x', 'updated_at': 1}}]});
    expect(b['accepted'], 0);
  });

  test('Rollen: Beobachter nur lesen, Freigabe nur TL/Admin', () async {
    final admin = await setupAdmin();
    final planner = await user(admin, 'planer', 'planer');
    final tl = await user(admin, 'wehrfuehrer', 'tl');
    final obs = await user(admin, 'tablet', 'beobachter');

    var (_, b) = await call('POST', '/api/v1/sync', token: obs, body: {'rows': [exercise('e1', 1)]});
    expect(b['accepted'], 0);

    (_, b) = await call('POST', '/api/v1/sync', token: planner, body: {'rows': [exercise('e1', 1, status: 'zur_freigabe')]});
    expect(b['accepted'], 1);
    (_, b) = await call('POST', '/api/v1/sync', token: planner, body: {'rows': [exercise('e1', 2, status: 'freigegeben', by: 'Planer')]});
    expect((b['rejected'] as List).single['reason'], contains('Freigabe'));
    (_, b) = await call('POST', '/api/v1/sync', token: tl, body: {'rows': [exercise('e1', 3, status: 'freigegeben', by: 'Wehrführer')]});
    expect(b['accepted'], 1);
    // Planer darf die Freigabe nicht aufheben, aber andere Felder ändern
    (_, b) = await call('POST', '/api/v1/sync', token: planner, body: {'rows': [exercise('e1', 4, status: 'entwurf')]});
    expect(b['accepted'], 0);
    (_, b) = await call('POST', '/api/v1/sync', token: planner, body: {'rows': [exercise('e1', 5, status: 'freigegeben', by: 'Wehrführer')]});
    expect(b['accepted'], 1);

    // Ohne Freigabepflicht darf der Planer selbst „fertig“ setzen
    store.setSetting('approval_required', 'false');
    (_, b) = await call('POST', '/api/v1/sync', token: planner, body: {'rows': [exercise('e2', 1, status: 'freigegeben')]});
    expect(b['accepted'], 1);

    // Benutzerverwaltung nur für Admin
    expect((await call('GET', '/api/v1/users', token: planner)).$1, 403);
    expect(((await call('GET', '/api/v1/users', token: admin)).$2 as List).length, 4);
  });

  test('Letzter Admin bleibt, Deaktivieren meldet ab', () async {
    final admin = await setupAdmin();
    final (_, users) = await call('GET', '/api/v1/users', token: admin);
    final id = (users as List).single['id'];
    expect((await call('PATCH', '/api/v1/users/$id', token: admin, body: {'role': 'planer'})).$1, 409);
    final planner = await user(admin, 'planer', 'planer');
    final pid = ((await call('GET', '/api/v1/users', token: admin)).$2 as List).firstWhere((u) => u['username'] == 'planer')['id'];
    expect((await call('PATCH', '/api/v1/users/$pid', token: admin, body: {'active': false})).$1, 200);
    expect((await call('GET', '/api/v1/me', token: planner)).$1, 401);
  });

  test('Passwort-Hash ist deterministisch und salzabhängig', () {
    expect(Store.hashPassword('a', 's', iterations: 10), Store.hashPassword('a', 's', iterations: 10));
    expect(Store.hashPassword('a', 's', iterations: 10), isNot(Store.hashPassword('a', 't', iterations: 10)));
  });
}
