import 'package:material_ui/material_ui.dart';

import '../data/repositories.dart';

/// Stellt die Repositories für alle Seiten bereit.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.repo, required super.child});
  final Repositories repo;

  static Repositories of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.repo;

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.repo != repo;
}

/// Überschrift einer Seite mit optionalen Aktionen rechts.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        runSpacing: 12,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: t.headlineSmall),
              if (subtitle != null)
                Text(subtitle!, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

/// Karte mit Titelzeile.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, this.subtitle, this.actions = const [], required this.child});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.titleLarge),
                      if (subtitle != null)
                        Text(subtitle!, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // Aktionen nehmen nur so viel Platz wie nötig (höchstens 60 %).
                  _Actions(actions: actions),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.35),
        child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
      );
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: c.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: c.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Kleines farbiges Etikett.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.textColor});
  final String text;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: color ?? c.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? c.onSurface)),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String what, {String? details}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('„$what“ löschen?'),
      content: details == null ? null : Text(details),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> askText(BuildContext context, {required String title, String label = 'Name', String initial = '', String confirm = 'Speichern'}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
      }

      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            onSubmitted: (_) => submit(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: submit, child: Text(confirm)),
        ],
      );
    },
  );
}

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Baut ein Widget aus einem Stream und zeigt währenddessen einen Ladekreis.
class StreamView<T> extends StatelessWidget {
  const StreamView({super.key, required this.stream, required this.builder});
  final Stream<T> stream;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
        stream: stream,
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Fehler: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return builder(ctx, snap.data as T);
        },
      );
}
