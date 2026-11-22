import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/exercise_repository.dart';
import '../data/template_io.dart';
import '../ui/widgets.dart';
import 'exercises/exercise_actions.dart';
import 'exercises/exercise_detail_page.dart';
import 'exercises/exercises_page.dart';

/// Bereich mit eigenem Navigator (Seitenleiste bleibt sichtbar).
class SectionNavigator extends StatelessWidget {
  const SectionNavigator({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child));
}

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  late final repo = AppScope.of(context);
  late final _templates = repo.exercises.watchTemplates();

  void _open(String id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseId: id)));

  Future<void> _import() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Vorlage importieren', type: FileType.custom, allowedExtensions: const ['json']);
    if (file == null) return;
    try {
      final result = await importTemplate(repo, utf8.decode(await file.readAsBytes()));
      if (!mounted) return;
      showMessage(
        context,
        result.skipped.isEmpty ? 'Vorlage importiert' : 'Vorlage importiert. Nicht zugeordnet: ${result.skipped.join(', ')}',
      );
      _open(result.exerciseId);
    } catch (e) {
      if (mounted) showMessage(context, 'Die Datei ist keine gültige Vorlage: $e');
    }
  }

  Future<void> _export(Exercise e) async {
    final text = await exportTemplate(repo, e.id);
    final uri = await FilePicker.saveFile(
      fileName: '${safeFileName(e.title)}.uebung.json',
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: 'application/json',
    );
    if (uri != null && mounted) showMessage(context, 'Vorlage exportiert');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'template-add',
        onPressed: () async {
          final id = await showExerciseDialog(context, asTemplate: true);
          if (id != null) _open(id);
        },
        icon: const Icon(Icons.add),
        label: const Text('Neue Vorlage'),
      ),
      body: StreamView<List<Exercise>>(
        stream: _templates,
        builder: (context, list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Vorlagen',
              subtitle: 'Übungen einmal ausarbeiten und immer wieder verwenden – auch mit anderen Wehren und Ortsgruppen teilen',
              actions: [OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Vorlage importieren'))],
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyHint(
                      icon: Icons.library_books_outlined,
                      text: 'Noch keine Vorlagen.\nIn einer Übung über das Menü (⋮) „Als Vorlage speichern“ wählen oder eine Vorlagendatei importieren.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                      children: [
                        Wrap(spacing: 16, runSpacing: 16, children: [
                          for (final e in list)
                            SizedBox(
                              width: 380,
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _open(e.id),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text((exerciseCategories[e.category] ?? e.category).toUpperCase(),
                                          style: TextStyle(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                      const SizedBox(height: 4),
                                      Text(e.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      if (e.topic != null) Text(e.topic!),
                                      const SizedBox(height: 12),
                                      Wrap(spacing: 8, runSpacing: 8, children: [
                                        FilledButton.icon(
                                          onPressed: () async {
                                            final id = await copyAsNewExercise(context, e.id, title: e.title, heading: 'Übung aus Vorlage anlegen');
                                            if (id != null && context.mounted) {
                                              showMessage(context, 'Übung angelegt – zu finden unter „Übungen“');
                                              _open(id);
                                            }
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Übung anlegen'),
                                        ),
                                        OutlinedButton.icon(onPressed: () => _export(e), icon: const Icon(Icons.download), label: const Text('Exportieren')),
                                      ]),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
