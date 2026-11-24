import 'database.dart';
import 'documents_repository.dart';

/// Eine Gesprächsgruppe bzw. ein Kanal in der grafischen Funkplan-Übersicht.
class RadioGroupNode {
  RadioGroupNode({required this.network, required this.channel, required this.entries});

  /// Schlüssel aus [radioNetworks].
  final String network;

  /// Gesprächsgruppe / Kanal; `null`, wenn im Funkplan nichts eingetragen ist.
  final String? channel;
  final List<RadioEntry> entries;

  String get networkLabel => radioNetworks[network] ?? network;
  String get label => channel ?? 'ohne Gruppe / Kanal';

  /// Vollständige Bezeichnung, z. B. „BOS digital · DMO 307“.
  String get fullLabel => '$networkLabel · $label';
}

/// Funkplan, gruppiert nach Funknetz und Gesprächsgruppe/Kanal.
///
/// Stellen, die in mehreren Gruppen eingetragen sind (gleicher Rufname),
/// sind Verbindungsstellen – z. B. ein ELW, der in zwei Gruppen hört.
class RadioOverview {
  RadioOverview._(this.networks, this._groupsByCallSign);

  /// Funknetz → Gruppen, in der Reihenfolge von [radioNetworks]
  /// (unbekannte Netze am Ende), Gruppen in der Reihenfolge des Funkplans.
  final Map<String, List<RadioGroupNode>> networks;
  final Map<String, List<RadioGroupNode>> _groupsByCallSign;

  factory RadioOverview.from(List<RadioEntry> radio) {
    final groups = <String, RadioGroupNode>{};
    for (final r in radio) {
      final channel = r.channel?.trim();
      final ch = channel == null || channel.isEmpty ? null : channel;
      final key = '${r.network}\u0000${ch?.toLowerCase() ?? ''}';
      groups.putIfAbsent(key, () => RadioGroupNode(network: r.network, channel: ch, entries: [])).entries.add(r);
    }
    final order = [...radioNetworks.keys];
    final networks = <String, List<RadioGroupNode>>{};
    for (final g in groups.values) {
      if (!order.contains(g.network)) order.add(g.network);
    }
    for (final n in order) {
      final list = [for (final g in groups.values) if (g.network == n) g];
      if (list.isNotEmpty) networks[n] = list;
    }
    final byCall = <String, List<RadioGroupNode>>{};
    for (final g in networks.values.expand((l) => l)) {
      for (final r in g.entries) {
        final list = byCall.putIfAbsent(_norm(r.callSign), () => []);
        if (!list.contains(g)) list.add(g);
      }
    }
    return RadioOverview._(networks, byCall);
  }

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Iterable<RadioGroupNode> get groups => networks.values.expand((g) => g);
  bool get isEmpty => networks.isEmpty;

  /// Andere Gruppen, in denen dieselbe Stelle (Rufname) ebenfalls eingetragen ist.
  List<RadioGroupNode> otherGroups(RadioEntry r, RadioGroupNode current) =>
      [for (final g in _groupsByCallSign[_norm(r.callSign)] ?? const <RadioGroupNode>[]) if (g != current) g];

  /// Rufnamen, die in mehr als einer Gruppe eingetragen sind.
  List<String> get linkingStations => [
        for (final e in _groupsByCallSign.entries)
          if (e.value.length > 1) e.value.first.entries.firstWhere((r) => _norm(r.callSign) == e.key).callSign,
      ];
}
