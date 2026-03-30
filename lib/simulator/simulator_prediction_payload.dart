import 'package:f1/simulator/simulator_grid_config.dart';
import 'package:f1/simulator/simulator_models.dart';

DateTime? readIsoUtcFromPayload(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toUtc();
}

({DateTime? gpUtc, DateTime? sprintUtc}) readCommitmentLocksFromPayload(
  Map<String, dynamic> map,
) {
  final gp = readIsoUtcFromPayload(
    map['gpCompletionLockedUtc'] ?? map['gpCompletionLockedAt'],
  );
  final sp = readIsoUtcFromPayload(
    map['sprintCompletionLockedUtc'] ?? map['sprintCompletionLockedAt'],
  );
  return (gpUtc: gp, sprintUtc: sp);
}

Map<String, dynamic> buildSimulatorPayload({
  required List<String> podium,
  required Map<String, int> penalties,
  required Set<String> dnf,
  required List<String> raceOrder,
  required List<String> sprintOrder,
  Set<String>? raceDns,
  Set<String>? raceDsq,
  Set<String>? sprintDnf,
  Set<String>? sprintDns,
  Set<String>? sprintDsq,
  DateTime? gpCompletionLockedUtc,
  DateTime? sprintCompletionLockedUtc,
}) {
  final m = <String, dynamic>{
    'podium': podium,
    'penalties': Map<String, int>.from(penalties),
    'dnf': dnf.toList(),
    'gp': raceOrder,
    'sprint': sprintOrder,
    'raceDns': (raceDns ?? const <String>{}).toList(),
    'raceDsq': (raceDsq ?? const <String>{}).toList(),
    'sprintDnf': (sprintDnf ?? const <String>{}).toList(),
    'sprintDns': (sprintDns ?? const <String>{}).toList(),
    'sprintDsq': (sprintDsq ?? const <String>{}).toList(),
  };
  if (gpCompletionLockedUtc != null) {
    m['gpCompletionLockedUtc'] = gpCompletionLockedUtc.toUtc().toIso8601String();
  }
  if (sprintCompletionLockedUtc != null) {
    m['sprintCompletionLockedUtc'] =
        sprintCompletionLockedUtc.toUtc().toIso8601String();
  }
  return m;
}

List<String> _canonicalDriverList(dynamic raw, List<SimulatorDriverRef> roster) {
  if (raw is! List) return [];
  final out = <String>[];
  for (final x in raw) {
    final s = x.toString();
    if (s.isEmpty) continue;
    out.add(canonicalSimulatorDriverName(s, roster));
  }
  return out;
}

void _readPenalties(
  dynamic raw,
  List<SimulatorDriverRef> roster,
  Map<String, int> out,
) {
  if (raw is! Map) return;
  for (final e in raw.entries) {
    final k = canonicalSimulatorDriverName(e.key.toString(), roster);
    final v = e.value;
    final secs = v is int ? v : int.tryParse(v.toString());
    if (secs != null) out[k] = secs;
  }
}

void _readStringSet(
  dynamic raw,
  List<SimulatorDriverRef> roster,
  Set<String> out,
) {
  if (raw is! List) return;
  for (final x in raw) {
    final s = x.toString();
    if (s.isEmpty) continue;
    out.add(canonicalSimulatorDriverName(s, roster));
  }
}

List<String>? _orderFromPayload(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    final v = map[k];
    if (v is List && v.isNotEmpty) return v.map((x) => x.toString()).toList();
  }
  return null;
}

void applySimulatorPayloadToMaps(
  Map<String, dynamic> map, {
  required List<String> outPodium,
  required Map<String, int> outPenalties,
  required Set<String> outDnf,
  required List<SimulatorDriverRef> roster,
  required List<String> outRaceOrder,
  required List<String> outSprintOrder,
  required Set<String> outRaceDns,
  required Set<String> outRaceDsq,
  required Set<String> outSprintDnf,
  required Set<String> outSprintDns,
  required Set<String> outSprintDsq,
  void Function(DateTime? gpUtc, DateTime? sprintUtc)? onCommitmentLocksRead,
}) {
  outPodium.clear();
  outPenalties.clear();
  outDnf.clear();
  outRaceOrder.clear();
  outSprintOrder.clear();
  outRaceDns.clear();
  outRaceDsq.clear();
  outSprintDnf.clear();
  outSprintDns.clear();
  outSprintDsq.clear();

  final podRaw = map['podium'];
  if (podRaw is List) {
    for (final x in podRaw) {
      final s = x.toString();
      if (s.isEmpty) continue;
      outPodium.add(canonicalSimulatorDriverName(s, roster));
      if (outPodium.length >= 3) break;
    }
  }

  _readPenalties(map['penalties'], roster, outPenalties);
  _readStringSet(map['dnf'], roster, outDnf);

  final gpKeys = _orderFromPayload(map, const ['gp', 'raceOrder', 'gpOrder']);
  if (gpKeys != null) {
    outRaceOrder.addAll(_canonicalDriverList(gpKeys, roster));
  }

  final spKeys = _orderFromPayload(map, const ['sprint', 'sprintOrder']);
  if (spKeys != null) {
    outSprintOrder.addAll(_canonicalDriverList(spKeys, roster));
  }

  _readStringSet(map['raceDns'], roster, outRaceDns);
  _readStringSet(map['raceDsq'], roster, outRaceDsq);
  _readStringSet(map['sprintDnf'], roster, outSprintDnf);
  _readStringSet(map['sprintDns'], roster, outSprintDns);
  _readStringSet(map['sprintDsq'], roster, outSprintDsq);

  if (outRaceOrder.length > kSimulatorGridSize) {
    outRaceOrder.removeRange(kSimulatorGridSize, outRaceOrder.length);
  }
  if (outSprintOrder.length > kSimulatorGridSize) {
    outSprintOrder.removeRange(kSimulatorGridSize, outSprintOrder.length);
  }

  if (onCommitmentLocksRead != null) {
    final locks = readCommitmentLocksFromPayload(map);
    onCommitmentLocksRead(locks.gpUtc, locks.sprintUtc);
  }
}
