import 'dart:convert';

import 'database.dart';

/// Ein Funkrufname eines Fahrzeugs in einem bestimmten Funknetz.
///
/// Ein Fahrzeug kann mehrere haben, z. B. BOS digital, BOS analog und zwei
/// im DLRG-Betriebsfunk. [label] unterscheidet mehrere Rufnamen im selben
/// Netz (z. B. „Bootsführer“, „Strömungsretter“).
class VehicleCallSign {
  const VehicleCallSign({required this.network, required this.callSign, this.label});

  /// Schlüssel aus `radioNetworks` (`bos_digital`, `bos_analog`, `dlrg_betriebsfunk`).
  final String network;
  final String callSign;
  final String? label;

  Map<String, String> toJson() => {'netz': network, 'rufname': callSign, 'bezeichnung': ?label};

  static VehicleCallSign? fromJson(Object? j) {
    if (j is! Map) return null;
    final call = '${j['rufname'] ?? ''}'.trim();
    if (call.isEmpty) return null;
    final label = '${j['bezeichnung'] ?? ''}'.trim();
    return VehicleCallSign(network: '${j['netz'] ?? 'bos_digital'}', callSign: call, label: label.isEmpty ? null : label);
  }

  static List<VehicleCallSign> decode(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json);
      if (list is! List) return const [];
      return [for (final e in list) ?fromJson(e)];
    } on FormatException {
      return const [];
    }
  }

  static String encode(Iterable<VehicleCallSign> list) => jsonEncode([for (final c in list) c.toJson()]);

  @override
  bool operator ==(Object other) =>
      other is VehicleCallSign && other.network == network && other.callSign == callSign && other.label == label;

  @override
  int get hashCode => Object.hash(network, callSign, label);
}

extension VehicleCallSigns on Vehicle {
  /// Alle Funkrufnamen. Ältere Datensätze haben nur [Vehicle.callSign];
  /// dieser gilt dann als Rufname im BOS-Digitalfunk.
  List<VehicleCallSign> get allCallSigns {
    final list = VehicleCallSign.decode(callSigns);
    if (list.isNotEmpty) return list;
    return callSign == null ? const [] : [VehicleCallSign(network: 'bos_digital', callSign: callSign!)];
  }
}
