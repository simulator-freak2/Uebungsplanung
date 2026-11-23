import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/profile.dart';
import '../data/repositories.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'call_sign_editor.dart';

const vehicleStatus = {
  'einsatzbereit': 'einsatzbereit',
  'bedingt_einsatzbereit': 'bedingt einsatzbereit',
  'ausser_dienst': 'außer Dienst',
  'werkstatt': 'in Werkstatt',
};
const vehicleKinds = {'fahrzeug': 'Fahrzeug', 'boot': 'Boot', 'anhaenger': 'Anhänger'};

/// Auswahl in der Liste: `null` = Führungs- und Sonderfunktionen.
class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  String? _selected;
  bool _leadSelected = true;
  late final _vehicles = AppScope.of(context).vehicles.watchAll();

  void _select(String? id) => setState(() {
        _selected = id;
        _leadSelected = id == null;
      });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamView<List<Vehicle>>(
        stream: _vehicles,
        builder: (context, vehicles) {
          if (_selected != null && !vehicles.any((v) => v.id == _selected)) {
            _selected = null;
            _leadSelected = true;
          }
          final list = _VehicleList(
            vehicles: vehicles,
            selected: _leadSelected ? null : _selected,
            leadSelected: _leadSelected,
            onSelect: (id) {
              _select(id);
              if (!wide) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(id == null ? 'Führungs- und Sonderfunktionen' : vehicles.firstWhere((v) => v.id == id).name)),
                    body: VehicleDetailView(vehicleId: id),
                  ),
                ));
              }
            },
            onCreated: _select,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Fahrzeuge & Funktionen',
                subtitle: 'Fahrzeuge zentral definieren: Funktionen, nötige Qualifikationen und Besetzungsmuster',
              ),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: list),
                          Expanded(child: VehicleDetailView(key: ValueKey(_leadSelected ? 'lead' : _selected), vehicleId: _leadSelected ? null : _selected)),
                        ],
                      )
                    : list,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VehicleList extends StatelessWidget {
  const _VehicleList({required this.vehicles, required this.selected, required this.leadSelected, required this.onSelect, required this.onCreated});
  final List<Vehicle> vehicles;
  final String? selected;
  final bool leadSelected;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onCreated;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget item({required bool sel, required Widget title, Widget? subtitle, Widget? trailing, required VoidCallback onTap, Key? key}) => Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: sel ? c.primary.withValues(alpha: 0.08) : Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: sel ? c.primary : c.outlineVariant),
            ),
            child: ListTile(title: title, subtitle: subtitle, trailing: trailing, onTap: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 12, 24),
      children: [
        item(
          sel: leadSelected,
          title: const Text('Führungs- und Sonderfunktionen', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Einsatzleiter, Übungsleitung, Beobachter …'),
          onTap: () => onSelect(null),
        ),
        const SizedBox(height: 8),
        for (final v in vehicles)
          item(
            key: ValueKey(v.id),
            sel: v.id == selected,
            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text([
              if (v.type != null && v.type != v.name) v.type!,
              if (v.callSign != null) v.callSign!,
              if (v.allCallSigns.length > 1) '+${v.allCallSigns.length - 1} Rufnamen',
            ].join(' · ')),
            trailing: v.status == 'einsatzbereit' ? null : Tag(vehicleStatus[v.status] ?? v.status, color: const Color(0x33A85D00)),
            onTap: () => onSelect(v.id),
          ),
        if (vehicles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Noch keine Fahrzeuge. Am einfachsten aus einer Vorlage anlegen.', style: TextStyle(color: c.onSurfaceVariant)),
          ),
        const SizedBox(height: 4),
        FilledButton.icon(
          key: const Key('vehicle-add'),
          onPressed: () async {
            final id = await showDialog<String>(context: context, builder: (_) => const _NewVehicleDialog());
            if (id != null) onCreated(id);
          },
          icon: const Icon(Icons.add),
          label: const Text('Fahrzeug / Boot'),
        ),
      ],
    );
  }
}

class _NewVehicleDialog extends StatefulWidget {
  const _NewVehicleDialog();

  @override
  State<_NewVehicleDialog> createState() => _NewVehicleDialogState();
}

class _NewVehicleDialogState extends State<_NewVehicleDialog> {
  List<VehicleTemplate> _templates = const [];
  VehicleTemplate? _template;
  final _name = TextEditingController();
  final _callSigns = CallSignEditController(const []);

  @override
  void dispose() {
    _name.dispose();
    _callSigns.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templates.isNotEmpty) return;
    final repo = AppScope.of(context);
    repo.settings.get(SettingsRepository.profileId).then((id) => OrgProfile.load(id ?? 'feuerwehr')).then((p) {
      if (mounted) setState(() => _templates = p.vehicleTemplates);
    });
  }

  Future<void> _create() async {
    final repo = AppScope.of(context);
    final name = _name.text.trim();
    final t = _template;
    final id = t == null
        ? await repo.vehicles.save(VehicleInput(name: name, callSigns: _callSigns.value))
        : await repo.vehicles.createFromTemplate(t, name: name, callSigns: _callSigns.value, ensureQualification: repo.qualifications.ensure);
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fahrzeug oder Boot anlegen'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<VehicleTemplate?>(
              key: const Key('vehicle-template'),
              initialValue: _template,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Vorlage'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Leer (ohne Funktionen)')),
                for (final t in _templates)
                  DropdownMenuItem(value: t, child: Text('${t.type} – ${t.functions.length} Funktionen, ${t.patterns.length} Besetzungsmuster', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (t) => setState(() {
                _template = t;
                if (t != null && (_name.text.isEmpty || _templates.any((x) => x.type == _name.text))) _name.text = t.type;
              }),
            ),
            const SizedBox(height: 12),
            TextField(key: const Key('vehicle-name'), controller: _name, decoration: const InputDecoration(labelText: 'Bezeichnung *', hintText: 'z. B. HLF 20'), onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            CallSignEditor(controller: _callSigns),
          ],
        )),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(key: const Key('vehicle-create'), onPressed: _name.text.trim().isEmpty ? null : _create, child: const Text('Anlegen')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detailansicht
// ---------------------------------------------------------------------------

class VehicleDetailView extends StatefulWidget {
  const VehicleDetailView({super.key, required this.vehicleId});

  /// `null` = Führungs- und Sonderfunktionen.
  final String? vehicleId;

  @override
  State<VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends State<VehicleDetailView> {
  late final repo = AppScope.of(context);
  late final _detail = repo.vehicles.watchDetail(widget.vehicleId);
  late final _quals = repo.qualifications.watchAll();

  @override
  Widget build(BuildContext context) {
    return StreamView<VehicleDetail>(
      stream: _detail,
      builder: (context, d) => StreamView<List<Qualification>>(
        stream: _quals,
        builder: (context, quals) {
          final qName = {for (final q in quals) q.id: q.name};
          final v = d.vehicle;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 24, 24),
            children: [
              if (v != null) ...[_header(v), const SizedBox(height: 16)],
              _functions(d, quals, qName),
              if (v != null) ...[const SizedBox(height: 16), _patterns(d)],
            ],
          );
        },
      ),
    );
  }

  Widget _header(Vehicle v) {
    final ok = v.status == 'einsatzbereit';
    return SectionCard(
      title: v.name,
      subtitle: [vehicleKinds[v.kind] ?? v.kind, if (v.type != null) v.type!].join(' · '),
      actions: [
        OutlinedButton.icon(onPressed: () => _editVehicle(v), icon: const Icon(Icons.edit_outlined), label: const Text('Bearbeiten')),
        OutlinedButton.icon(
          onPressed: () async {
            if (await confirmDelete(context, v.name, details: 'Funktionen und Besetzungsmuster dieses Fahrzeugs werden mit gelöscht.')) {
              await repo.vehicles.delete(v.id);
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Löschen'),
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: [
          Tag(vehicleStatus[v.status] ?? v.status,
              color: ok ? AppColors.ok.withValues(alpha: 0.15) : AppColors.warn.withValues(alpha: 0.18),
              textColor: ok ? AppColors.ok : AppColors.warn),
          const Tag('Stammdaten lokal · Anbindung an Materialkompass in Vorbereitung'),
        ]),
        if (v.allCallSigns.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in v.allCallSigns) Tag(callSignLabel(c), color: Theme.of(context).colorScheme.primaryContainer),
          ]),
        ],
      ]),
    );
  }

  Future<void> _editVehicle(Vehicle v) async {
    final name = TextEditingController(text: v.name);
    final type = TextEditingController(text: v.type);
    final calls = CallSignEditController(v.allCallSigns);
    var kind = v.kind;
    var status = v.status;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Fahrzeug bearbeiten'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Bezeichnung *')),
              const SizedBox(height: 12),
              TextField(controller: type, decoration: const InputDecoration(labelText: 'Typ', hintText: 'z. B. HLF 20')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Art'),
                items: [for (final e in vehicleKinds.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (x) => setS(() => kind = x!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [for (final e in vehicleStatus.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (x) => setS(() => status = x!),
              ),
              const SizedBox(height: 16),
              CallSignEditor(controller: calls),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(ctx, name.text.trim().isNotEmpty), child: const Text('Speichern')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await repo.vehicles.save(VehicleInput(id: v.id, name: name.text, type: type.text, kind: kind, callSigns: calls.value, status: status));
    }
  }

  Widget _functions(VehicleDetail d, List<Qualification> quals, Map<String, String> qName) {
    final lead = d.vehicle == null;
    return SectionCard(
      title: lead ? 'Führungs- und Sonderfunktionen' : 'Funktionen',
      subtitle: lead
          ? 'Gelten für alle Übungen, unabhängig vom Fahrzeug. Eine Person darf mehrere Funktionen haben.'
          : 'Reihenfolge per Ziehen am Griff ändern',
      actions: [
        FilledButton.tonalIcon(
          key: const Key('function-add'),
          onPressed: () => _editFunction(d, quals),
          icon: const Icon(Icons.add),
          label: const Text('Funktion'),
        ),
      ],
      child: d.functions.isEmpty
          ? const Padding(padding: EdgeInsets.all(8), child: Text('Noch keine Funktionen.'))
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: d.functions.length,
              onReorderItem: (from, to) {
                final ids = d.functions.map((f) => f.id).toList();
                ids.insert(to, ids.removeAt(from));
                repo.vehicles.reorderFunctions(ids);
              },
              itemBuilder: (context, i) {
                final f = d.functions[i];
                final need = f.requiredQualificationId == null ? null : qName[f.requiredQualificationId];
                return ListTile(
                  key: ValueKey(f.id),
                  dense: true,
                  leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                  title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Align(
                    alignment: Alignment.centerLeft,
                    child: need == null ? const Text('keine Qualifikation nötig') : Tag('benötigt: $need'),
                  ),
                  trailing: Wrap(children: [
                    IconButton(tooltip: 'Bearbeiten', icon: const Icon(Icons.edit_outlined), onPressed: () => _editFunction(d, quals, existing: f)),
                    IconButton(
                      tooltip: 'Löschen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirmDelete(context, f.name)) await repo.vehicles.deleteFunction(f.id);
                      },
                    ),
                  ]),
                );
              },
            ),
    );
  }

  Future<void> _editFunction(VehicleDetail d, List<Qualification> quals, {CrewFunction? existing}) async {
    final name = TextEditingController(text: existing?.name);
    String? qual = existing?.requiredQualificationId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Funktion anlegen' : 'Funktion bearbeiten'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                key: const Key('function-name'),
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Funktion *', hintText: 'z. B. Angriffstruppführer'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: qual,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Benötigte Qualifikation'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('– keine –')),
                  for (final q in quals) DropdownMenuItem(value: q.id, child: Text(q.name)),
                ],
                onChanged: (x) => setS(() => qual = x),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(key: const Key('function-save'), onPressed: () => Navigator.pop(ctx, name.text.trim().isNotEmpty), child: const Text('Speichern')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (existing == null) {
      await repo.vehicles.addFunction(d.vehicle?.id, name.text, qual);
    } else {
      await repo.vehicles.updateFunction(existing.id, name: name.text, qualificationId: qual);
    }
  }

  Widget _patterns(VehicleDetail d) {
    final c = Theme.of(context).colorScheme;
    return SectionCard(
      title: 'Besetzungsmuster',
      subtitle: 'Welche Funktionen bei welcher Besetzung (z. B. Gruppe, Staffel, Trupp) besetzt werden',
      actions: [
        FilledButton.tonalIcon(
          key: const Key('pattern-add'),
          onPressed: () async {
            final name = await askText(context, title: 'Besetzungsmuster anlegen', label: 'Name', initial: '');
            if (name == null) return;
            final pid = await repo.vehicles.addPattern(d.vehicle!.id, name);
            for (final f in d.functions) {
              await repo.vehicles.setPatternFunction(pid, f.id, true);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Besetzungsmuster'),
        ),
      ],
      child: d.patterns.isEmpty
          ? const Padding(padding: EdgeInsets.all(8), child: Text('Noch keine Besetzungsmuster. Ein neues Muster enthält zunächst alle Funktionen.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 64,
                columns: [
                  const DataColumn(label: Text('Funktion')),
                  for (final p in d.patterns)
                    DataColumn(
                      label: Row(children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        PopupMenuButton<String>(
                          tooltip: 'Besetzungsmuster bearbeiten',
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (a) async {
                            if (a == 'rename') {
                              final n = await askText(context, title: 'Besetzungsmuster umbenennen', initial: p.name);
                              if (n != null) await repo.vehicles.renamePattern(p.id, n);
                            } else if (await confirmDelete(context, p.name)) {
                              await repo.vehicles.deletePattern(p.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'rename', child: Text('Umbenennen')),
                            PopupMenuItem(value: 'delete', child: Text('Löschen')),
                          ],
                        ),
                      ]),
                    ),
                ],
                rows: [
                  for (final f in d.functions)
                    DataRow(cells: [
                      DataCell(Text(f.name)),
                      for (final p in d.patterns)
                        DataCell(Center(
                          child: Checkbox(
                            value: d.contains(p.id, f.id),
                            onChanged: (on) => repo.vehicles.setPatternFunction(p.id, f.id, on ?? false),
                          ),
                        )),
                    ]),
                  DataRow(
                    color: WidgetStatePropertyAll(c.surfaceContainerHighest.withValues(alpha: 0.5)),
                    cells: [
                      const DataCell(Text('Sitzplätze', style: TextStyle(fontWeight: FontWeight.w600))),
                      for (final p in d.patterns)
                        DataCell(Center(child: Text('${d.matrix[p.id]?.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)))),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
