import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import '../../data/exercise_repository.dart';
import '../../data/repositories.dart';
import '../../map/sketch.dart';
import '../../pdf/exercise_pdf.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;
import 'tab_alarm.dart';

String safeFileName(String s) => s.replaceAll(RegExp(r'[^\wäöüÄÖÜß.-]+'), '_');

/// Lädt alle Daten für die Übungsmappe.
Future<ExerciseMapData> loadMapData(Repositories repo, ExerciseDetail d) async {
  final vehicles = await repo.vehicles.watchAllDetails().first;
  final persons = await repo.persons.all();
  final quals = await repo.qualifications.all();
  final org = await repo.settings.get(SettingsRepository.orgName) ?? '';
  final approval = (await repo.settings.get(SettingsRepository.approvalRequired)) != 'false';
  return ExerciseMapData(
    organisation: org,
    detail: d,
    vehicles: vehicles,
    persons: {for (final p in persons) p.person.id: p},
    qualificationNames: {for (final q in quals) q.id: q.name},
    alarmSheets: alarmSheetsFor(d, [for (final v in vehicles.values) ?v.vehicle], org),
    approvalRequired: approval,
    symbolNames: await _symbolNames(d),
  );
}

Future<Map<String?, String>> _symbolNames(ExerciseDetail d) async {
  final items = decodeSketch(d.exercise.sketch).where((i) => i.symbol != null);
  if (items.isEmpty) return const {};
  try {
    final c = await SymbolCatalog.load();
    return {for (final i in items) i.symbol: c.nameOf(i.symbol!)};
  } catch (_) {
    return const {};
  }
}

/// Dialog: Teile der Übungsmappe wählen, dann drucken oder als PDF speichern.
Future<void> showExerciseMapDialog(BuildContext context, ExerciseDetail d, {Set<MapSection>? sections}) async {
  final repo = AppScope.of(context);
  final selected = sections != null ? {...sections} : ({...MapSection.values}..remove(MapSection.debrief));
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        Future<Uint8List> build() async => buildExerciseMap(await loadMapData(repo, d), selected);
        final name = safeFileName('Uebungsmappe_${t.date(d.exercise.date)}_${d.exercise.title}');
        return AlertDialog(
          title: const Text('Übungsmappe'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final s in MapSection.values)
                CheckboxListTile(
                  dense: true,
                  value: selected.contains(s),
                  title: Text(s.label),
                  subtitle: switch (s) {
                    MapSection.alarms => Text('${d.alarmGroups.isEmpty ? 1 : d.alarmGroups.length} Seite(n), je Alarmierungszeitpunkt eine'),
                    MapSection.roles => Text('${d.roles.length} Karte(n), je eine Seite zum Austeilen'),
                    MapSection.observation => const Text('mit leeren Feldern zum Ausfüllen'),
                    MapSection.orgChart => const Text('Führungsstruktur mit Funkrufname, Funktion und Fahrzeug (Querformat)'),
                    _ => null,
                  },
                  onChanged: (v) => setS(() => v == true ? selected.add(s) : selected.remove(s)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Schließen')),
            OutlinedButton.icon(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      final bytes = await build();
                      final uri = await FilePicker.saveFile(fileName: '$name.pdf', bytes: bytes, mimeType: 'application/pdf');
                      if (uri != null && ctx.mounted) {
                        Navigator.pop(ctx);
                        showMessage(context, 'Übungsmappe gespeichert');
                      }
                    },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Als PDF speichern'),
            ),
            FilledButton.icon(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      try {
                        await Printing.layoutPdf(onLayout: (_) => build(), name: name);
                      } catch (e) {
                        if (ctx.mounted) showMessage(context, 'Drucken nicht möglich: $e. Bitte als PDF speichern.');
                      }
                    },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Drucken'),
            ),
          ],
        );
      },
    ),
  );
}

/// Speichert die Übung als Vorlage.
Future<void> saveAsTemplate(BuildContext context, ExerciseDetail d) async {
  final repo = AppScope.of(context);
  final name = await askText(context, title: 'Als Vorlage speichern', label: 'Name der Vorlage', initial: d.exercise.title, confirm: 'Speichern');
  if (name == null) return;
  await repo.exercises.copy(d.exercise.id, asTemplate: true, title: name);
  if (context.mounted) {
    showMessage(context, 'Vorlage „$name“ gespeichert. Besetzung, Bewertungen und Nachbesprechung werden nicht übernommen.');
  }
}

/// Fragt Datum (und Titel) ab und legt eine neue Übung als Kopie an.
/// Gibt die ID der neuen Übung zurück.
Future<String?> copyAsNewExercise(BuildContext context, String sourceId, {required String title, String heading = 'Übung kopieren'}) async {
  final repo = AppScope.of(context);
  final ctrl = TextEditingController(text: title);
  var date = DateTime.now().add(const Duration(days: 7));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(heading),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(key: const Key('copy-title'), controller: ctrl, decoration: const InputDecoration(labelText: 'Titel')),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final x = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (x != null) setS(() => date = x);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Datum', suffixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(t.dateLong(date)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Übernommen werden Ablauf, Lernziele, Lage, Sicherheits-Checkliste (nicht abgehakt), Fahrzeuge mit Besetzungsmuster, Führungsstruktur, '
                'Alarmierungsplan, Funkplan, Rollenkarten, Material und Beobachtungspunkte – ohne Personen und Bewertungen.'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(key: const Key('copy-save'), onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isNotEmpty), child: const Text('Anlegen')),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  return repo.exercises.copy(sourceId, asTemplate: false, date: date, title: ctrl.text);
}
