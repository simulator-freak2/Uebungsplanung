import 'dart:convert';

import 'package:http/http.dart' as http;

/// Angemeldeter Benutzer des Servers.
class ServerUser {
  ServerUser({required this.id, required this.username, required this.displayName, required this.role, this.active = true});
  final int id;
  final String username;
  final String displayName;
  final String role;
  final bool active;

  factory ServerUser.fromJson(Map<String, dynamic> j) => ServerUser(
        id: (j['id'] as num).toInt(),
        username: '${j['username']}',
        displayName: '${j['displayName']}',
        role: '${j['role']}',
        active: j['active'] != false,
      );
  Map<String, Object?> toJson() => {'id': id, 'username': username, 'displayName': displayName, 'role': role, 'active': active};
}

const roleLabels = {
  'admin': 'Administrator',
  'tl': 'TL / Wehrführer',
  'planer': 'Planer / Ausbilder',
  'beobachter': 'Beobachter (nur lesen)',
};

class ServerException implements Exception {
  ServerException(this.status, this.message);
  final int status;
  final String message;
  bool get unauthorized => status == 401;
  @override
  String toString() => message;
}

class ServerStatus {
  ServerStatus(this.name, this.version, this.needsSetup);
  final String name;
  final String version;
  final bool needsSetup;
}

class PullResult {
  PullResult(this.rows, this.settings, this.seq);
  final List<Map<String, dynamic>> rows;
  final Map<String, String> settings;
  final int seq;
}

class PushResponse {
  PushResponse(this.accepted, this.rejected);
  final int accepted;
  final List<Map<String, dynamic>> rejected;
}

/// HTTP-Zugriff auf den Übungsplaner-Server.
class ServerClient {
  ServerClient(String baseUrl, {this.token, http.Client? client})
      : baseUrl = normalizeUrl(baseUrl),
        _http = client ?? http.Client();

  final String baseUrl;
  String? token;
  final http.Client _http;
  static const timeout = Duration(seconds: 20);

  /// „192.168.1.20:8080“ → „http://192.168.1.20:8080“
  static String normalizeUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'http://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Uri _uri(String path, [Map<String, String>? q]) => Uri.parse('$baseUrl/api/v1/$path').replace(queryParameters: q);

  Map<String, String> get _headers => {
        'content-type': 'application/json; charset=utf-8',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Future<dynamic> _send(Future<http.Response> request) async {
    final http.Response r;
    try {
      r = await request.timeout(timeout);
    } on Exception catch (e) {
      throw ServerException(0, 'Server nicht erreichbar ($baseUrl): $e');
    }
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) {
      throw ServerException(r.statusCode, body is Map && body['error'] != null ? '${body['error']}' : 'Fehler ${r.statusCode}');
    }
    return body;
  }

  Future<ServerStatus> status() async {
    final j = await _send(_http.get(_uri('status'))) as Map<String, dynamic>;
    return ServerStatus('${j['name']}', '${j['version']}', j['needsSetup'] == true);
  }

  Future<ServerUser> setup({required String username, required String displayName, required String password, Map<String, String> settings = const {}, String? device}) async {
    final j = await _send(_http.post(_uri('setup'),
        headers: _headers,
        body: jsonEncode({'username': username, 'displayName': displayName, 'password': password, 'settings': settings, 'device': device}))) as Map<String, dynamic>;
    token = '${j['token']}';
    return ServerUser.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<ServerUser> login(String username, String password, {String? device}) async {
    final j = await _send(_http.post(_uri('login'), headers: _headers, body: jsonEncode({'username': username, 'password': password, 'device': device})))
        as Map<String, dynamic>;
    token = '${j['token']}';
    return ServerUser.fromJson(j['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _send(_http.post(_uri('logout'), headers: _headers));
    } catch (_) {}
    token = null;
  }

  Future<ServerUser> me() async => ServerUser.fromJson(await _send(_http.get(_uri('me'), headers: _headers)) as Map<String, dynamic>);

  Future<List<ServerUser>> users() async =>
      [for (final u in await _send(_http.get(_uri('users'), headers: _headers)) as List) ServerUser.fromJson(u as Map<String, dynamic>)];

  Future<ServerUser> createUser({required String username, required String displayName, required String password, required String role}) async =>
      ServerUser.fromJson(await _send(_http.post(_uri('users'),
          headers: _headers, body: jsonEncode({'username': username, 'displayName': displayName, 'password': password, 'role': role}))) as Map<String, dynamic>);

  Future<ServerUser> updateUser(int id, {String? displayName, String? role, bool? active, String? password}) async =>
      ServerUser.fromJson(await _send(_http.patch(_uri('users/$id'),
          headers: _headers,
          body: jsonEncode({
            'displayName': ?displayName,
            'role': ?role,
            'active': ?active,
            'password': ?password,
          }))) as Map<String, dynamic>);

  Future<PullResult> pull(int since) async {
    final j = await _send(_http.get(_uri('sync', {'since': '$since'}), headers: _headers)) as Map<String, dynamic>;
    return PullResult(
      [for (final r in j['rows'] as List) (r as Map).cast<String, dynamic>()],
      {for (final e in ((j['settings'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
      (j['seq'] as num).toInt(),
    );
  }

  Future<PushResponse> push(List<Map<String, Object?>> rows) async {
    final j = await _send(_http.post(_uri('sync'), headers: _headers, body: jsonEncode({'rows': rows}))) as Map<String, dynamic>;
    return PushResponse((j['accepted'] as num).toInt(), [for (final r in j['rejected'] as List) (r as Map).cast<String, dynamic>()]);
  }

  Future<void> putSettings(Map<String, String> settings) => _send(_http.put(_uri('settings'), headers: _headers, body: jsonEncode(settings)));
}
