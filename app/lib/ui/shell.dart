import 'package:material_ui/material_ui.dart';

import '../data/repositories.dart';
import '../features/exercises/exercises_page.dart';
import '../features/keywords_page.dart';
import '../features/overview_page.dart';
import '../features/personal_page.dart';
import '../features/placeholder_page.dart';
import '../features/settings_page.dart';
import '../features/vehicles_page.dart';
import 'theme.dart';
import 'widgets.dart';

class _Dest {
  const _Dest(this.label, this.icon, this.builder, {this.group});
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final String? group;
}

final _destinations = <_Dest>[
  _Dest('Übersicht', Icons.home_outlined, (_) => const OverviewPage(), group: 'Planung'),
  _Dest('Dienstplan', Icons.calendar_month_outlined,
      (_) => const PlaceholderPage(title: 'Jahresdienstplan', stage: 'Etappe 4', icon: Icons.calendar_month_outlined)),
  _Dest('Übungen', Icons.description_outlined, (_) => const ExercisesSection()),
  _Dest('Vorlagen', Icons.library_books_outlined,
      (_) => const PlaceholderPage(title: 'Vorlagen', stage: 'Etappe 4', icon: Icons.library_books_outlined)),
  _Dest('Fahrzeuge & Funktionen', Icons.local_shipping_outlined, (_) => const VehiclesPage(), group: 'Stammdaten'),
  _Dest('Alarmstichworte', Icons.notifications_active_outlined, (_) => const KeywordsPage()),
  _Dest('Personal', Icons.groups_outlined, (_) => const PersonalPage()),
  _Dest('Einstellungen', Icons.settings_outlined, (_) => const SettingsPage(), group: 'System'),
];

/// Grundgerüst: Seitenleiste auf breiten Bildschirmen, Menü auf schmalen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final page = KeyedSubtree(key: ValueKey(_index), child: _destinations[_index].builder(context));
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 248, child: _Sidebar(selected: _index, onSelect: _select)),
            const VerticalDivider(width: 1),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_destinations[_index].label)),
      drawer: Drawer(
        child: _Sidebar(
          selected: _index,
          onSelect: (i) {
            Navigator.pop(context);
            _select(i);
          },
        ),
      ),
      body: page,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final repo = AppScope.of(context);
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF221C1B) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.fact_check_outlined, color: AppColors.yellow),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Übungsplaner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        StreamBuilder<String?>(
                          stream: repo.settings.watch(SettingsRepository.orgName),
                          builder: (_, s) => Text(s.data ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (var i = 0; i < _destinations.length; i++) ...[
                    if (_destinations[i].group != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 8, 4),
                        child: Text(_destinations[i].group!.toUpperCase(),
                            style: TextStyle(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: c.onSurfaceVariant)),
                      ),
                    ListTile(
                      dense: true,
                      leading: Icon(_destinations[i].icon),
                      title: Text(_destinations[i].label),
                      selected: selected == i,
                      selectedColor: c.primary,
                      selectedTileColor: c.primary.withValues(alpha: 0.10),
                      shape: const StadiumBorder(),
                      onTap: () => onSelect(i),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 9, color: AppColors.ok),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Nur lokal · Daten auf diesem Gerät', style: TextStyle(fontSize: 12, color: c.onSurfaceVariant))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
