import 'package:material_ui/material_ui.dart';

import '../ui/theme.dart';
import '../ui/widgets.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const PageHeader(title: 'Übersicht', subtitle: 'Stand der Stammdaten'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(label: 'Personen', icon: Icons.groups_outlined, stream: repo.persons.watchAll().map((l) => l.length)),
              _Stat(label: 'Fahrzeuge & Boote', icon: Icons.local_shipping_outlined, stream: repo.vehicles.watchAll().map((l) => l.length)),
              _Stat(label: 'Alarmstichworte', icon: Icons.notifications_active_outlined, stream: repo.keywords.watchAll().map((l) => l.length)),
              _Stat(label: 'Qualifikationen', icon: Icons.workspace_premium_outlined, stream: repo.qualifications.watchAll().map((l) => l.length)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SectionCard(
            title: 'Erste Schritte',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step('Personal anlegen oder aus einer Excel-Liste importieren', 'Personal'),
                _Step('Fahrzeuge aus Vorlagen anlegen und Besetzungsmuster prüfen', 'Fahrzeuge & Funktionen'),
                _Step('Führungs- und Sonderfunktionen ergänzen', 'Fahrzeuge & Funktionen'),
                _Step('Alarmstichworte importieren (z. B. Tabelle Rheinland-Pfalz)', 'Alarmstichworte'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.text, this.where);
  final String text;
  final String where;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.arrow_forward, size: 20, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(child: Text.rich(TextSpan(text: '$text  ', children: [
              TextSpan(text: '→ $where', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]))),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.icon, required this.stream});
  final String label;
  final IconData icon;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<int>(
                      stream: stream,
                      builder: (_, s) => Text('${s.data ?? '–'}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    ),
                    Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
