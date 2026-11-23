import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:uebungsplaner_server/server.dart';

/// Startet den Übungsplaner-Server.
///
///   uebungsplaner_server --port 8080 --data ./daten
///   uebungsplaner_server --cert server.crt --key server.key   (HTTPS)
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: Platform.environment['UEBUNGSPLANER_PORT'] ?? '8080', help: 'Port')
    ..addOption('host', defaultsTo: Platform.environment['UEBUNGSPLANER_HOST'] ?? '0.0.0.0', help: 'Adresse (0.0.0.0 = alle Netzwerke, 127.0.0.1 = nur dieser Rechner)')
    ..addOption('data', abbr: 'd', defaultsTo: Platform.environment['UEBUNGSPLANER_DATA'] ?? 'daten', help: 'Ordner für die Datenbank')
    ..addOption('cert', defaultsTo: Platform.environment['UEBUNGSPLANER_CERT'], help: 'Zertifikat (PEM) für HTTPS')
    ..addOption('key', defaultsTo: Platform.environment['UEBUNGSPLANER_KEY'], help: 'Privater Schlüssel (PEM) für HTTPS')
    ..addOption('name', defaultsTo: Platform.environment['UEBUNGSPLANER_NAME'] ?? 'Übungsplaner-Server', help: 'Anzeigename')
    ..addFlag('help', abbr: 'h', negatable: false);
  final a = parser.parse(args);
  if (a['help'] == true) {
    stdout.writeln('Übungsplaner-Server $serverVersion\n\n${parser.usage}');
    return;
  }

  final dir = Directory(a['data'] as String)..createSync(recursive: true);
  final store = Store.open('${dir.path}${Platform.pathSeparator}uebungsplaner-server.sqlite');
  final api = Api(store, name: a['name'] as String);
  final handler = const Pipeline().addMiddleware(logRequests(logger: (msg, isError) {
    if (isError) stderr.writeln(msg);
  })).addHandler(api.handler);

  SecurityContext? tls;
  if (a['cert'] != null && a['key'] != null) {
    tls = SecurityContext()
      ..useCertificateChain(a['cert'] as String)
      ..usePrivateKey(a['key'] as String);
  }
  final server = await io.serve(handler, a['host'] as String, int.parse(a['port'] as String), securityContext: tls);
  stdout.writeln('Übungsplaner-Server $serverVersion läuft auf ${tls == null ? 'http' : 'https'}://${server.address.host}:${server.port}');
  stdout.writeln('Daten: ${dir.absolute.path}');
  if (store.needsSetup) stdout.writeln('Noch kein Benutzer: Die Einrichtung erfolgt beim ersten Verbinden aus der App.');

  Future<void> stop(ProcessSignal _) async {
    await server.close();
    store.db.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);
}
