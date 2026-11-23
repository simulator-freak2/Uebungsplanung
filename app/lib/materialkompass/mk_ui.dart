import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../data/exercise_repository.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'materialkompass.dart';

/// Einstellungen → Materialkompass.
class MaterialkompassSettingsCard extends StatefulWidget {
  const MaterialkompassSettingsCard({super.key});

  @override
  State<MaterialkompassSettingsCard> createState() => _MaterialkompassSettingsCardState();
}

class _MaterialkompassSettingsCardState extends State<MaterialkompassSettingsCard> {
  late final repo = AppScope.of(context);
  late final mk = MaterialkompassService(repo);
  final _url = TextEditingController();
  final _key = TextEditingController();
  String? _info;
  bool _busy = false;
  late final _reservations = repo.settings.watch(MkKeys.reservations);
  late final _lastSync = repo.settings.watch(MkKeys.lastSync);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _url.text = await repo.settings.get(MkKeys.url) ?? 'https://materialkompass.org/api/v1';
      _key.text = await repo.settings.get(MkKeys.apiKey) ?? '';
    });
  }

  Future<void> _saveAndCheck() async {
    await repo.settings.set(MkKeys.url, _url.text.trim());
    await repo.settings.set(MkKeys.apiKey, _key.text.trim());
    setState(() => _busy = true);
    try {
      final s = await (await mk.client())!.status();
      setState(() => _info = 'Verbunden: $s');
    } catch (e) {
      setState(() => _info = '$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      final r = await mk.sync();
      setState(
        () => _info =
            '${r.material} Materialpositionen übernommen, ${r.vehiclesUpdated} Fahrzeuge abgeglichen'
            '${r.unmatched.isEmpty ? '' : ', ${r.unmatched.length} Fahrzeug(e) ohne Zuordnung'}',
      );
      if (r.unmatched.isNotEmpty && mounted) await _offerCreate(r.unmatched);
    } catch (e) {
      setState(() => _info = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerCreate(List<Map<String, dynamic>> list) async {
    final chosen = <Map<String, dynamic>>{...list};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Fahrzeuge aus Materialkompass anlegen?'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Diese Fahrzeuge gibt es im Übungsplaner noch nicht (Zuordnung über Bezeichnung oder Funkrufname). '
                  'Neu angelegte Fahrzeuge haben noch keine Funktionen – diese unter „Fahrzeuge & Funktionen“ ergänzen.',
                ),
                for (final v in list)
                  CheckboxListTile(
                    value: chosen.contains(v),
                    title: Text('${v['bezeichnung']}'),
                    subtitle: Text([v['typ'], v['funkrufname']].whereType<String>().join(' · ')),
                    onChanged: (x) => setS(() => x == true ? chosen.add(v) : chosen.remove(v)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nicht anlegen')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anlegen')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    for (final v in chosen) {
      await mk.createVehicle(v);
    }
    if (mounted) showMessage(context, '${chosen.length} Fahrzeug(e) angelegt');
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.sessionOf(context);
    return SectionCard(
      title: 'Materialkompass',
      subtitle: 'Material und Fahrzeuge übernehmen, Fahrzeuge für Übungen reservieren',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'Adresse der Schnittstelle', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _key,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'API-Schlüssel', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Den API-Schlüssel erzeugt ein Administrator in Materialkompass. Er wird nur auf diesem Gerät gespeichert.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(onPressed: _busy ? null : _saveAndCheck, child: const Text('Speichern und prüfen')),
              FilledButton.tonalIcon(onPressed: _busy ? null : _sync, icon: const Icon(Icons.sync), label: const Text('Jetzt abgleichen')),
              if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              StreamBuilder<String?>(
                stream: _lastSync,
                builder: (_, s) => Text(
                  s.data == null ? 'noch nicht abgeglichen' : 'letzter Abgleich: ${s.data!.substring(0, 16).replaceAll('T', ' ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (_info != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_info!)),
          const SizedBox(height: 8),
          StreamBuilder<String?>(
            stream: _reservations,
            builder: (_, s) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Planer dürfen Fahrzeuge reservieren'),
              subtitle: Text(
                session.isAdmin
                    ? 'Reservierungen sind in Materialkompass genehmigungspflichtig.'
                    : 'Nur Administratoren können das ändern.',
              ),
              value: s.data == 'true',
              onChanged: session.isAdmin ? (v) => session.setShared(MkKeys.reservations, '$v') : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Auswahl von Material aus dem Zwischenspeicher.
Future<void> pickMkMaterial(BuildContext context, String exerciseId) async {
  final repo = AppScope.of(context);
  final mk = MaterialkompassService(repo);
  final list = await mk.watchMaterial().first;
  if (!context.mounted) return;
  if (list.isEmpty) {
    showMessage(context, 'Noch kein Material aus Materialkompass. Unter Einstellungen → Materialkompass „Jetzt abgleichen“.');
    return;
  }
  final picked = await showDialog<List<MkMaterial>>(
    context: context,
    builder: (_) => _MaterialPicker(list: list),
  );
  if (picked == null || picked.isEmpty) return;
  await mk.addToExercise(exerciseId, picked);
  if (context.mounted) showMessage(context, '${picked.length} Position(en) übernommen');
}

class _MaterialPicker extends StatefulWidget {
  const _MaterialPicker({required this.list});
  final List<MkMaterial> list;

  @override
  State<_MaterialPicker> createState() => _MaterialPickerState();
}

class _MaterialPickerState extends State<_MaterialPicker> {
  final _picked = <MkMaterial>{};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = widget.list
        .where((m) => q.isEmpty || [m.name, m.category, m.location, m.inventoryNo].any((s) => (s ?? '').toLowerCase().contains(q)))
        .toList();
    return AlertDialog(
      title: const Text('Material aus Materialkompass'),
      content: SizedBox(
        width: 620,
        height: 480,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Bezeichnung, Fahrzeug, Kategorie',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final m in list)
                    CheckboxListTile(
                      dense: true,
                      value: _picked.contains(m),
                      onChanged: (v) => setState(() => v == true ? _picked.add(m) : _picked.remove(m)),
                      title: Text(m.name),
                      subtitle: Text(
                        [
                          m.location ?? '',
                          if (m.quantity != null)
                            '${m.quantity == m.quantity!.roundToDouble() ? m.quantity!.toInt() : m.quantity} ${m.unit ?? ''}'.trim(),
                          m.category ?? '',
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      secondary: m.status == null || m.status == 'einsatzbereit'
                          ? null
                          : Tag(m.status!.replaceAll('_', ' '), color: AppColors.warn.withValues(alpha: 0.18), textColor: AppColors.warn),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, _picked.toList()), child: Text('${_picked.length} übernehmen')),
      ],
    );
  }
}

/// Reservierungsanzeige und -knöpfe für ein Fahrzeug in der Übung.
class ReservationControl extends StatefulWidget {
  const ReservationControl({super.key, required this.detail, required this.exerciseVehicle, required this.vehicle});
  final ExerciseDetail detail;
  final ExerciseVehicle exerciseVehicle;
  final Vehicle vehicle;

  @override
  State<ReservationControl> createState() => _ReservationControlState();
}

class _ReservationControlState extends State<ReservationControl> {
  late final repo = AppScope.of(context);
  late final mk = MaterialkompassService(repo);
  late final _enabled = repo.settings.watch(MkKeys.reservations);
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.exerciseVehicle;
    final status = ev.reservationStatus;
    return StreamBuilder<String?>(
      stream: _enabled,
      builder: (context, s) {
        if (s.data != 'true' || widget.vehicle.externalId == null) return const SizedBox.shrink();
        final notReady = widget.vehicle.status == 'werkstatt' || widget.vehicle.status == 'ausser_dienst';
        if (_busy) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        if (status == null || status == 'storniert' || status == 'abgelehnt') {
          return Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (status != null) Tag(reservationStatus[status]!, color: AppColors.warn.withValues(alpha: 0.18), textColor: AppColors.warn),
              if (status == 'abgelehnt' && ev.reservationNote != null) Text(ev.reservationNote!, style: const TextStyle(fontSize: 12)),
              if (!notReady)
                OutlinedButton.icon(
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  onPressed: () => _run(() async {
                    final user = AppScope.sessionOf(context).user?.username;
                    final st = await mk.reserve(widget.detail.exercise, ev, widget.vehicle, user: user);
                    if (mounted) showMessage(this.context, '${widget.vehicle.name}: ${reservationStatus[st] ?? st}');
                  }),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('In Materialkompass reservieren'),
                ),
            ],
          );
        }
        final ok = status == 'bestaetigt';
        return Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tag(
              reservationStatus[status] ?? status,
              color: ok ? AppColors.ok.withValues(alpha: 0.15) : Theme.of(context).colorScheme.tertiaryContainer,
              textColor: ok ? AppColors.ok : Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            IconButton(
              tooltip: 'Status abfragen',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => _run(() => mk.refresh(widget.detail)),
            ),
            IconButton(
              tooltip: 'Reservierung stornieren',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.event_busy_outlined, size: 18),
              onPressed: () => _run(() => mk.cancel(ev)),
            ),
          ],
        );
      },
    );
  }
}
