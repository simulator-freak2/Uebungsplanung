import 'package:material_ui/material_ui.dart';

import '../ui/widgets.dart';

/// Platzhalter für Bereiche, die in einer späteren Etappe kommen.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.stage, required this.icon});
  final String title;
  final String stage;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: title),
        Expanded(child: EmptyHint(icon: icon, text: 'Dieser Bereich folgt in $stage.\nDie Stammdaten aus Etappe 1 sind die Grundlage dafür.')),
      ],
    );
  }
}
