import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/database.dart';
import '../data/exercise_repository.dart';
import '../data/repositories.dart';
import '../pdf/alarm_pdf.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import '../util/time.dart' as t;
import 'exercises/exercise_detail_page.dart';
import 'exercises/exercises_page.dart';

const monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

Color categoryColor(String c) => switch (c) {
      'theorie' => const Color(0xFF8A7F7B),
      'sonderdienst' => AppColors.yellow,
      'jugend' => const Color(0xFF2E7DB5),
      _ => AppColors.red,
    };

/// Jahresdienstplan: alle Übungen eines Jahres nach Monaten.
class DutyPlanPage extends StatefulWidget {
  const DutyPlanPage({super.key});

  @override
  State<DutyPlanPage> createState() => _DutyPlanPageState();
}

class _DutyPlanPageState extends State<DutyPlanPage> {
  late final repo = AppScope.of(context);
  late final _all = repo.exercises.watchAll();
  /// `null` = automatisch: Jahr der nächsten anstehenden Übung.
  int? _chosenYear;
  int _year = DateTime.now().year;

  void _open(String id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exerciseId: id)));

  Future<void> _new(int month) async {
    final now = DateTime.now();
    final date = (_year == now.year && month == now.month) ? now.add(const Duration(days: 7)) : DateTime(_year, month, 1);
    final id = await showExerciseDialog(context, date: date);
    if (id != null) _open(id);
  }

  Future<pw.Document> _pdf(List<Exercise> list) async {
    final f = await PdfFonts.load();
    final org = await repo.settings.get(SettingsRepository.orgName) ?? '';
    final doc = pw.Document(title: 'Dienstplan $_year', author: org);
    doc.addPage(pw.MultiPage(
      theme: pw.ThemeData.withFont(base: f.regular, bold: f.bold),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(org, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text('Dienstplan $_year', style: pw.TextStyle(font: f.bold, fontSize: 20)),
        pw.SizedBox(height: 8),
      ]),
      footer: (ctx) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Stand ${t.date(DateTime.now())} · Seite ${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8))),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headers: ['Datum', 'Zeit', 'Dienst', 'Einheit', 'Ort'],
          data: [
            for (final e in list)
              [
                '${['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][e.date.weekday - 1]}, ${t.date(e.date)}',
                '${t.clock(e.startMinutes)}${e.endMinutes == null ? '' : '–${t.clock(e.endMinutes!)}'}',
                e.title,
                e.unit ?? '',
                e.location ?? '',
              ],
          ],
          headerStyle: pw.TextStyle(font: f.bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFC8102E)),
          cellStyle: const pw.TextStyle(fontSize: 9),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          columnWidths: {0: const pw.FixedColumnWidth(80), 1: const pw.FixedColumnWidth(60), 2: const pw.FlexColumnWidth(3)},
          cellAlignment: pw.Alignment.topLeft,
        ),
      ],
    ));
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamView<List<Exercise>>(
        stream: _all,
        builder: (context, all) {
          if (_chosenYear == null) {
            final now = DateTime.now();
            final next = all.where((e) => !e.date.isBefore(DateTime(now.year, now.month, now.day))).firstOrNull;
            _year = next?.date.year ?? now.year;
          }
          final list = all.where((e) => e.date.year == _year).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageHeader(
                title: 'Dienstplan $_year',
                subtitle: '${list.length} Termine · Klick auf einen Termin öffnet die Übung',
                actions: [
                  IconButton(tooltip: 'Vorjahr', onPressed: () => setState(() => _chosenYear = --_year), icon: const Icon(Icons.chevron_left)),
                  IconButton(tooltip: 'Folgejahr', onPressed: () => setState(() => _chosenYear = ++_year), icon: const Icon(Icons.chevron_right)),
                  OutlinedButton.icon(
                    onPressed: list.isEmpty
                        ? null
                        : () async {
                            final bytes = await (await _pdf(list)).save();
                            await FilePicker.saveFile(fileName: 'Dienstplan_$_year.pdf', bytes: bytes, mimeType: 'application/pdf');
                          },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF-Aushang'),
                  ),
                  OutlinedButton.icon(
                    onPressed: list.isEmpty
                        ? null
                        : () async {
                            final doc = await _pdf(list);
                            try {
                              await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'Dienstplan $_year');
                            } catch (e) {
                              if (context.mounted) showMessage(context, 'Drucken nicht möglich: $e');
                            }
                          },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Drucken'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(spacing: 14, runSpacing: 6, children: [
                  for (final e in exerciseCategories.entries)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: categoryColor(e.key), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text(e.value, style: Theme.of(context).textTheme.bodySmall),
                    ]),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(builder: (context, box) {
                  final cols = (box.maxWidth / 260).floor().clamp(1, 6);
                  final w = (box.maxWidth - (cols - 1) * 12) / cols;
                  return Wrap(spacing: 12, runSpacing: 12, children: [
                    for (var m = 1; m <= 12; m++)
                      SizedBox(
                        width: w,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 6, 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Row(children: [
                                Expanded(child: Text(monthNames[m - 1], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                                IconButton(
                                  tooltip: 'Termin in ${monthNames[m - 1]} anlegen',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () => _new(m),
                                ),
                              ]),
                              for (final e in list.where((e) => e.date.month == m))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5, right: 6),
                                  child: Material(
                                    color: c.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    child: InkWell(
                                      onTap: () => _open(e.id),
                                      child: Container(
                                        decoration: BoxDecoration(border: Border(left: BorderSide(color: categoryColor(e.category), width: 3))),
                                        padding: const EdgeInsets.fromLTRB(7, 4, 6, 4),
                                        child: Text.rich(
                                          TextSpan(children: [
                                            TextSpan(text: '${t.two(e.date.day)}.${t.two(e.date.month)}. ', style: const TextStyle(fontWeight: FontWeight.w700)),
                                            TextSpan(text: e.title),
                                          ]),
                                          style: const TextStyle(fontSize: 12.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (!list.any((e) => e.date.month == m)) Text('–', style: TextStyle(color: c.onSurfaceVariant)),
                            ]),
                          ),
                        ),
                      ),
                  ]);
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
