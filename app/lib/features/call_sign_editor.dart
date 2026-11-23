import 'package:material_ui/material_ui.dart';

import '../data/call_signs.dart';
import '../data/documents_repository.dart';

class _Row {
  _Row(VehicleCallSign? c)
      : network = c?.network ?? 'bos_digital',
        call = TextEditingController(text: c?.callSign),
        label = TextEditingController(text: c?.label);
  String network;
  final TextEditingController call;
  final TextEditingController label;
}

/// Hält die Eingaben des [CallSignEditor] (Funknetz, Rufname, Bezeichnung).
class CallSignEditController extends ChangeNotifier {
  CallSignEditController(List<VehicleCallSign> initial) {
    _rows.addAll(initial.map(_Row.new));
    if (_rows.isEmpty) _rows.add(_Row(null));
  }

  final _rows = <_Row>[];

  List<VehicleCallSign> get value => [
        for (final r in _rows)
          if (r.call.text.trim().isNotEmpty)
            VehicleCallSign(
              network: r.network,
              callSign: r.call.text.trim(),
              label: r.label.text.trim().isEmpty ? null : r.label.text.trim(),
            ),
      ];

  void add() {
    // Vorschlag: das nächste Funknetz, das noch keinen Rufnamen hat.
    final used = {for (final r in _rows) r.network};
    final next = radioNetworks.keys.firstWhere((k) => !used.contains(k), orElse: () => _rows.isEmpty ? 'bos_digital' : _rows.last.network);
    _rows.add(_Row(VehicleCallSign(network: next, callSign: '')));
    notifyListeners();
  }

  void remove(int i) {
    final r = _rows.removeAt(i);
    r.call.dispose();
    r.label.dispose();
    if (_rows.isEmpty) _rows.add(_Row(null));
    notifyListeners();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.call.dispose();
      r.label.dispose();
    }
    super.dispose();
  }
}

/// Eingabe beliebig vieler Funkrufnamen eines Fahrzeugs, je mit Funknetz,
/// z. B. BOS digital, BOS analog und zwei im DLRG-Betriebsfunk.
class CallSignEditor extends StatelessWidget {
  const CallSignEditor({super.key, required this.controller});
  final CallSignEditController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Funkrufnamen', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Der erste Funkrufname ist der Haupt-Funkrufname.', style: TextStyle(color: c.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          for (final (i, r) in controller._rows.indexed)
            Padding(
              key: ObjectKey(r),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      key: Key('callsign-net-$i'),
                      initialValue: radioNetworks.containsKey(r.network) ? r.network : 'bos_digital',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Funknetz', isDense: true),
                      items: [for (final e in radioNetworks.entries) DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
                      onChanged: (v) => r.network = v!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: Key('callsign-call-$i'),
                      controller: r.call,
                      decoration: InputDecoration(
                        labelText: 'Funkrufname',
                        isDense: true,
                        hintText: r.network == 'dlrg_betriebsfunk' ? 'z. B. Adler Musterstadt 21' : 'z. B. Florian Musterstadt 1/46-1',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      key: Key('callsign-label-$i'),
                      controller: r.label,
                      decoration: const InputDecoration(labelText: 'Bezeichnung', isDense: true, hintText: 'optional'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Funkrufname entfernen',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => controller.remove(i),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('callsign-add'),
              onPressed: controller.add,
              icon: const Icon(Icons.add),
              label: const Text('Weiterer Funkrufname'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kurztext für Listen, z. B. „Florian 1/46-1 (BOS digital)“.
String callSignLabel(VehicleCallSign c) =>
    '${c.callSign} (${[radioNetworks[c.network] ?? c.network, if (c.label != null) c.label!].join(', ')})';
