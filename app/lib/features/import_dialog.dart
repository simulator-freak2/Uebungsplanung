import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../import/tabular.dart';
import '../ui/widgets.dart';

/// Ergebnis der Dateiauswahl und Spaltenzuordnung.
class MappedImport {
  MappedImport(this.table, this.mapping);
  final ImportTable table;
  final Map<String, int?> mapping;
}

/// Lässt den Benutzer eine Excel- oder CSV-Datei wählen und die Spalten
/// den Feldern zuordnen. Gibt `null` zurück, wenn abgebrochen wurde.
Future<MappedImport?> pickAndMapTable(BuildContext context, {required String title, required List<ImportField> fields, String? hint}) async {
  final file = await FilePicker.pickFile(
    dialogTitle: title,
    type: FileType.custom,
    allowedExtensions: const ['xlsx', 'csv', 'txt'],
  );
  if (file == null || !context.mounted) return null;
  final ImportTable table;
  try {
    table = readTable(await file.readAsBytes(), file.name);
  } catch (e) {
    if (context.mounted) showMessage(context, 'Die Datei konnte nicht gelesen werden: $e');
    return null;
  }
  if (!context.mounted) return null;
  if (table.headers.isEmpty) {
    showMessage(context, 'Die Datei enthält keine Daten.');
    return null;
  }
  final mapping = await showDialog<Map<String, int?>>(
    context: context,
    builder: (_) => _MappingDialog(title: title, table: table, fields: fields, hint: hint, fileName: file.name),
  );
  return mapping == null ? null : MappedImport(table, mapping);
}

class _MappingDialog extends StatefulWidget {
  const _MappingDialog({required this.title, required this.table, required this.fields, required this.fileName, this.hint});
  final String title;
  final ImportTable table;
  final List<ImportField> fields;
  final String fileName;
  final String? hint;

  @override
  State<_MappingDialog> createState() => _MappingDialogState();
}

class _MappingDialogState extends State<_MappingDialog> {
  late final Map<String, int?> _m = guessMapping(widget.table.headers, widget.fields);

  bool get _valid => widget.fields.where((f) => f.required).every((f) => _m[f.key] != null);

  @override
  Widget build(BuildContext context) {
    final t = widget.table;
    final c = Theme.of(context).colorScheme;
    final preview = t.rows.take(3).toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.fileName}: ${t.rows.length} Zeilen. Bitte prüfen, welche Spalte zu welchem Feld gehört.'),
              if (widget.hint != null) ...[
                const SizedBox(height: 6),
                Text(widget.hint!, style: TextStyle(color: c.onSurfaceVariant, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 200, child: Text(f.required ? '${f.label} *' : f.label)),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _m[f.key],
                          isExpanded: true,
                          isDense: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('– nicht vorhanden –')),
                            for (var i = 0; i < t.headers.length; i++)
                              DropdownMenuItem(
                                value: i,
                                child: Text(
                                  '${t.headers[i].isEmpty ? 'Spalte ${i + 1}' : t.headers[i]}'
                                  '${preview.isEmpty ? '' : '  (z. B. ${t.cell(preview.first, i)})'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _m[f.key] = v),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_valid)
                Text('Bitte alle Pflichtfelder (*) zuordnen.', style: TextStyle(color: c.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: _valid ? () => Navigator.pop(context, _m) : null, child: Text('${t.rows.length} Zeilen importieren')),
      ],
    );
  }
}
