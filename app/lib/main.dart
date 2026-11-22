import 'package:material_ui/material_ui.dart';

import 'data/database.dart';
import 'data/repositories.dart';
import 'features/setup_page.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(UebungsplanerApp(repo: Repositories(AppDatabase.open())));
}

class UebungsplanerApp extends StatelessWidget {
  const UebungsplanerApp({super.key, required this.repo});
  final Repositories repo;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repo: repo,
      child: MaterialApp(
        title: 'Übungsplaner',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: StreamBuilder<String?>(
          stream: repo.settings.watch(SettingsRepository.orgName),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return snap.data == null ? const SetupPage() : const AppShell();
          },
        ),
      ),
    );
  }
}
