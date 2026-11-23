import 'package:material_ui/material_ui.dart';

import '../../data/documents_repository.dart';
import '../../data/exercise_repository.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../util/time.dart' as t;
import 'tab_roles.dart';

/// Ansicht für Übungsbeobachter (z. B. auf dem Tablet): nur lesen, große
/// Schrift; Ablauf, Alarmierungsplan, Mimen mit Eskalationsstufen und
/// Beobachtungspunkte.
class ObserverView extends StatefulWidget {
  const ObserverView({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  State<ObserverView> createState() => _ObserverViewState();
}

class _ObserverViewState extends State<ObserverView> {
  late final _detail = AppScope.of(context).exercises.watchDetail(widget.exerciseId);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Beobachter-Ansicht'), actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Tag('nur lesen'))]),
      body: StreamView<ExerciseDetail?>(
        stream: _detail,
        builder: (context, d) {
          if (d == null) return const EmptyHint(icon: Icons.delete_outline, text: 'Diese Übung gibt es nicht mehr.');
          final e = d.exercise;
          Widget section(String title, List<Widget> children) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(title, style: text.headlineSmall),
                  const Divider(),
                  ...children,
                ]),
              );
          final big = text.titleMedium;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.15)),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(e.title, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('${t.dateLong(e.date)} · ${t.clock(e.startMinutes)} Uhr${e.location == null ? '' : ' · ${e.location}'}', style: big),
                const SizedBox(height: 24),
                if (e.scenario != null) section('Lage', [Text(e.scenario!, style: big)]),
                if (d.phases.isNotEmpty)
                  section('Ablauf', [
                    for (final p in d.phases)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 80, child: Text(t.clock(d.start + p.offsetMinutes), style: big?.copyWith(fontWeight: FontWeight.w700))),
                          Expanded(child: Text(p.description, style: big)),
                        ]),
                      ),
                  ]),
                if (d.alarmPlan.isNotEmpty)
                  section('Alarmierungsplan', [
                    for (final a in d.alarmPlan)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${t.clock(d.start + a.alarmOffset)}  ${a.label}'
                          '${d.towOf(a) == null ? '' : ' · auf Anhänger von ${d.towOf(a)!.label}, Slippen ${a.slipLocation ?? ''}${a.slipOffset == null ? '' : ' ${t.clock(d.start + a.slipOffset!)}'}'}'
                          '${a.arriveOffset == null ? '' : ' · ${a.kind == 'trupp' ? 'Einsatz ab' : 'vor Ort'} ${t.clock(d.start + a.arriveOffset!)}'}'
                          '${a.destination == null ? '' : ' · ${a.destination}'}'
                          '${a.task == null ? '' : ' (${a.task})'}'
                          '${a.note == null ? '' : ' · ${a.note}'}',
                          style: big,
                        ),
                      ),
                  ]),
                if (d.roles.isNotEmpty)
                  section('Mimen und Eskalationsstufen', [
                    for (final r in d.roles) ...[
                      Text('${r.number}  ${r.name}', style: text.titleLarge?.copyWith(color: AppColors.red)),
                      if (r.injuries != null) Text('Verletzungen: ${r.injuries}', style: big),
                      if (r.symptoms != null) Text('Symptome: ${r.symptoms}', style: big),
                      const SizedBox(height: 6),
                      for (final (i, s) in decodeEscalation(r.escalation).indexed) EscalationRow(stage: s, index: i, large: true),
                      const SizedBox(height: 16),
                    ],
                  ]),
                if (d.observations.isNotEmpty)
                  section('Beobachtungspunkte', [
                    for (final o in d.observations)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          const Icon(Icons.visibility_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(o.description, style: big)),
                          if (o.rating != null) Tag(o.rating == '-' ? '–' : o.rating!),
                        ]),
                      ),
                  ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
