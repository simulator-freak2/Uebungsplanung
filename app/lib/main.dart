import 'package:material_ui/material_ui.dart';

import 'data/database.dart';
import 'data/repositories.dart';
import 'features/setup_page.dart';
import 'sync/read_only_shell.dart';
import 'sync/sync_service.dart';
import 'sync/sync_ui.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = Repositories(AppDatabase.open());
  final session = Session(repo);
  await session.restore();
  runApp(UebungsplanerApp(repo: repo, session: session));
}

class UebungsplanerApp extends StatelessWidget {
  const UebungsplanerApp({super.key, required this.repo, required this.session});
  final Repositories repo;
  final Session session;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repo: repo,
      session: session,
      child: MaterialApp(
        title: 'Übungsplaner',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            if (session.state == SyncState.loggedOut) return const LoginPage();
            return StreamBuilder<String?>(
              stream: repo.settings.watch(SettingsRepository.orgName),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (snap.data == null) return const SetupPage();
                return session.readOnly ? const ReadOnlyShell() : const AppShell();
              },
            );
          },
        ),
      ),
    );
  }
}
