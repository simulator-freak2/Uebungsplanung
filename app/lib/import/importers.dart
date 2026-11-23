import '../data/repositories.dart';
import 'tabular.dart';

// ---------------------------------------------------------------------------
// Personal
// ---------------------------------------------------------------------------

const personFields = [
  ImportField('lastName', 'Nachname', aliases: ['name', 'familienname', 'zuname']),
  ImportField('firstName', 'Vorname', aliases: ['rufname']),
  ImportField('fullName', 'Name (Nachname, Vorname)', aliases: ['vollername', 'mitglied', 'person']),
  ImportField('personnelNo', 'Personalnummer', aliases: ['personalnr', 'persnr', 'pnr', 'mitgliedsnummer', 'mitgliedsnr', 'nummer', 'nr']),
  ImportField('qualifications', 'Qualifikationen', aliases: ['qualifikation', 'lehrgaenge', 'ausbildung', 'ausbildungen', 'funktionen']),
  ImportField('youth', 'Jugend', aliases: ['jugendfeuerwehr', 'jf', 'dlrgjugend']),
];

class PersonImportRow {
  PersonImportRow({required this.lastName, required this.firstName, this.personnelNo, required this.qualifications, required this.youth});
  final String lastName;
  final String firstName;
  final String? personnelNo;
  final List<String> qualifications;
  final bool youth;
}

/// Wandelt Tabellenzeilen in Personen um. Zeilen ohne Namen werden übersprungen.
List<PersonImportRow> mapPersons(ImportTable table, Map<String, int?> m) {
  final result = <PersonImportRow>[];
  for (final row in table.rows) {
    var last = table.cell(row, m['lastName']);
    var first = table.cell(row, m['firstName']);
    final full = table.cell(row, m['fullName']);
    if (last.isEmpty && full.isNotEmpty) {
      if (full.contains(',')) {
        last = full.split(',').first.trim();
        first = full.split(',').skip(1).join(',').trim();
      } else {
        final parts = full.split(RegExp(r'\s+'));
        last = parts.last;
        first = parts.take(parts.length - 1).join(' ');
      }
    }
    if (last.isEmpty) continue;
    final no = table.cell(row, m['personnelNo']);
    result.add(PersonImportRow(
      lastName: last,
      firstName: first,
      personnelNo: no.isEmpty ? null : no,
      qualifications: splitList(table.cell(row, m['qualifications'])),
      youth: parseYesNo(table.cell(row, m['youth'])) ?? false,
    ));
  }
  return result;
}

class ImportResult {
  ImportResult(this.created, this.updated, this.newQualifications);
  final int created;
  final int updated;
  final List<String> newQualifications;
}

/// Übernimmt Personen. Vorhandene Personen (gleiche Personalnummer oder
/// gleicher Name) werden aktualisiert; ihre Qualifikationen werden ergänzt.
/// Unbekannte Qualifikationen werden angelegt.
Future<ImportResult> importPersons(Repositories repo, List<PersonImportRow> rows) async {
  var created = 0, updated = 0;
  final known = {for (final q in await repo.qualifications.all()) q.name.toLowerCase()};
  final newQuals = <String>[];
  await repo.db.transaction(() async {
    for (final r in rows) {
      final qids = <String>{};
      for (final q in r.qualifications) {
        if (!known.contains(q.toLowerCase())) {
          known.add(q.toLowerCase());
          newQuals.add(q);
        }
        qids.add(await repo.qualifications.ensure(q));
      }
      final existing = await repo.persons.find(personnelNo: r.personnelNo, lastName: r.lastName, firstName: r.firstName);
      await repo.persons.save(PersonInput(
        id: existing?.person.id,
        // Schreibweise einer vorhandenen Person behalten, wenn sich nur Groß-/Kleinschreibung unterscheidet.
        lastName: _same(existing?.person.lastName, r.lastName) ? existing!.person.lastName : r.lastName,
        firstName: _same(existing?.person.firstName, r.firstName) ? existing!.person.firstName : r.firstName,
        personnelNo: r.personnelNo ?? existing?.person.personnelNo,
        youth: r.youth || (existing?.person.youth ?? false),
        qualificationIds: {...?existing?.qualificationIds, ...qids},
      ));
      existing == null ? created++ : updated++;
    }
  });
  return ImportResult(created, updated, newQuals);
}

bool _same(String? a, String b) => a != null && a.trim().toLowerCase() == b.trim().toLowerCase();

// ---------------------------------------------------------------------------
// Alarmstichworte
// ---------------------------------------------------------------------------

const keywordFields = [
  ImportField('code', 'Stichwort', required: true, aliases: ['einsatzstichwort', 'alarmstichwort', 'kuerzel', 'code', 'einsatzcode']),
  ImportField('category', 'Kategorie', aliases: ['gruppe', 'art', 'bereich', 'einsatzart']),
  ImportField('description', 'Beschreibung', aliases: ['bezeichnung', 'meldebild', 'text', 'klartext', 'erlaeuterung']),
  ImportField('resources', 'Einsatzmittel (AAO)', aliases: ['einsatzmittel', 'aao', 'fahrzeuge', 'alarmierung', 'kraefte']),
  ImportField('specialRights', 'Sonderrechte', aliases: ['sondersignal', 'prioritaer', 'prio', 'sosi']),
];

List<KeywordInput> mapKeywords(ImportTable table, Map<String, int?> m) => [
      for (final row in table.rows)
        if (table.cell(row, m['code']).isNotEmpty)
          KeywordInput(
            code: table.cell(row, m['code']),
            category: table.cell(row, m['category']),
            description: table.cell(row, m['description']),
            resources: table.cell(row, m['resources']),
            specialRights: parseYesNo(table.cell(row, m['specialRights'])) ?? true,
          ),
    ];

List<List<String>> keywordsToRows(Iterable<({String code, String? category, String? description, String? resources, bool specialRights})> list) => [
      ['Stichwort', 'Kategorie', 'Beschreibung', 'Einsatzmittel (AAO)', 'Sonderrechte'],
      for (final k in list) [k.code, k.category ?? '', k.description ?? '', k.resources ?? '', k.specialRights ? 'ja' : 'nein'],
    ];
