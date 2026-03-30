import 'package:f1/simulator/simulator_grid_config.dart';
import 'package:f1/simulator/simulator_models.dart';

/// 2026 F1 Hub prediction game — per-session scoring (GP + optional Sprint).
const int kHubMaxGpSessionScore = 175;
const int kHubMaxSprintSessionScore = 75;

const List<int> _kGpTop10 = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
const List<int> _kSprintTop8 = [8, 7, 6, 5, 4, 3, 2, 1];

const int _kGpP11to22Pts = 2;
const int _kSprintP9to22Pts = 1;
const int _kStatusBonus = 5;

const int _kGpFullGridBonus = 25;
const int _kGpTop10CompletionBonus = 10;
const int _kGpPerfectPodiumBonus = 15;

const int _kSprintFullGridBonus = 15;
const int _kSprintTop8CompletionBonus = 5;
const int _kSprintPerfectPodiumBonus = 5;

/// Canonical finishing order: index `i` = driver at P(i+1), or null.
List<String?> hubClassificationSlots(
  List<SimulatorResultRowLite> rows,
  List<SimulatorDriverRef> roster,
) {
  final byPos = <int, String>{};
  for (final row in rows) {
    final pf = parseFinishField(row.finish);
    if (pf.status != SimulatorRaceStatus.classified || pf.position == null) continue;
    final p = pf.position!;
    if (p < 1 || p > kSimulatorGridSize) continue;
    final name = canonicalSimulatorDriverName(row.driver, roster);
    byPos.putIfAbsent(p, () => name);
  }
  return List<String?>.generate(
    kSimulatorGridSize,
    (i) => byPos[i + 1],
    growable: false,
  );
}

Map<String, SimulatorRaceStatus> hubActualStatusesByDriver(
  List<SimulatorResultRowLite> rows,
  List<SimulatorDriverRef> roster,
) {
  final m = <String, SimulatorRaceStatus>{};
  for (final row in rows) {
    final pf = parseFinishField(row.finish);
    final key = canonicalSimulatorDriverName(row.driver, roster);
    m[key] = pf.status;
  }
  return m;
}

SimulatorRaceStatus? _predictedOutcomeForDriver(
  String canon,
  Set<String> dnf,
  Set<String> dns,
  Set<String> dsq,
) {
  if (dsq.contains(canon)) return SimulatorRaceStatus.dsq;
  if (dns.contains(canon)) return SimulatorRaceStatus.dns;
  if (dnf.contains(canon)) return SimulatorRaceStatus.dnf;
  return null;
}

bool _slotsTopNFilled(List<String?> slots, int n) {
  if (slots.length < n) return false;
  for (var i = 0; i < n; i++) {
    final s = slots[i];
    if (s == null || s.trim().isEmpty) return false;
  }
  return true;
}

bool hubGpGridFullyCommitted(List<String?> gpSlots) =>
    _slotsTopNFilled(gpSlots, kSimulatorGridSize);

bool hubSprintGridFullyCommitted(List<String?> sprintSlots) =>
    _slotsTopNFilled(sprintSlots, kSimulatorGridSize);

class HubSessionScore {
  const HubSessionScore({
    required this.positionPoints,
    required this.statusBonus,
    required this.fullGridBonus,
    required this.sliceCompletionBonus,
    required this.perfectPodiumBonus,
  });

  final int positionPoints;
  final int statusBonus;
  final int fullGridBonus;
  final int sliceCompletionBonus;
  final int perfectPodiumBonus;

  int get total =>
      positionPoints +
      statusBonus +
      fullGridBonus +
      sliceCompletionBonus +
      perfectPodiumBonus;
}

HubSessionScore scoreHubGrandPrixSession({
  required List<String?> predictedSlots,
  required Set<String> predDnf,
  required Set<String> predDns,
  required Set<String> predDsq,
  required List<SimulatorResultRowLite> actualRows,
  required List<SimulatorDriverRef> roster,
  required bool applyCompletionBonuses,
}) {
  final actualSlots = hubClassificationSlots(actualRows, roster);
  final actualByDriver = hubActualStatusesByDriver(actualRows, roster);

  var positionPts = 0;
  for (var i = 0; i < kSimulatorGridSize; i++) {
    final p = i < predictedSlots.length ? predictedSlots[i] : null;
    final a = actualSlots[i];
    if (p == null || p.trim().isEmpty || a == null || a.trim().isEmpty) continue;
    if (!simulatorDriverNamesMatch(p, a, roster)) continue;
    if (i < 10) {
      positionPts += _kGpTop10[i];
    } else {
      positionPts += _kGpP11to22Pts;
    }
  }

  var statusPts = 0;
  for (final d in roster) {
    final canon = d.name;
    final pred = _predictedOutcomeForDriver(canon, predDnf, predDns, predDsq);
    if (pred == null ||
        (pred != SimulatorRaceStatus.dnf &&
            pred != SimulatorRaceStatus.dns &&
            pred != SimulatorRaceStatus.dsq)) {
      continue;
    }
    final act = actualByDriver[canon];
    if (act == pred) {
      statusPts += _kStatusBonus;
    }
  }

  var fullB = 0;
  var sliceB = 0;
  var podB = 0;
  if (applyCompletionBonuses) {
    if (hubGpGridFullyCommitted(predictedSlots)) {
      fullB = _kGpFullGridBonus;
    }
    if (_slotsTopNFilled(predictedSlots, 10)) {
      sliceB = _kGpTop10CompletionBonus;
    }
    final ok = predictedSlots.length >= 3 &&
        actualSlots.length >= 3 &&
        predictedSlots[0] != null &&
        predictedSlots[1] != null &&
        predictedSlots[2] != null &&
        actualSlots[0] != null &&
        actualSlots[1] != null &&
        actualSlots[2] != null &&
        simulatorDriverNamesMatch(predictedSlots[0]!, actualSlots[0]!, roster) &&
        simulatorDriverNamesMatch(predictedSlots[1]!, actualSlots[1]!, roster) &&
        simulatorDriverNamesMatch(predictedSlots[2]!, actualSlots[2]!, roster);
    if (ok) podB = _kGpPerfectPodiumBonus;
  }

  return HubSessionScore(
    positionPoints: positionPts,
    statusBonus: statusPts,
    fullGridBonus: fullB,
    sliceCompletionBonus: sliceB,
    perfectPodiumBonus: podB,
  );
}

HubSessionScore scoreHubSprintSession({
  required List<String?> predictedSlots,
  required Set<String> predDnf,
  required Set<String> predDns,
  required Set<String> predDsq,
  required List<SimulatorResultRowLite> actualRows,
  required List<SimulatorDriverRef> roster,
  required bool applyCompletionBonuses,
}) {
  final actualSlots = hubClassificationSlots(actualRows, roster);
  final actualByDriver = hubActualStatusesByDriver(actualRows, roster);

  var positionPts = 0;
  for (var i = 0; i < kSimulatorGridSize; i++) {
    final p = i < predictedSlots.length ? predictedSlots[i] : null;
    final a = actualSlots[i];
    if (p == null || p.trim().isEmpty || a == null || a.trim().isEmpty) continue;
    if (!simulatorDriverNamesMatch(p, a, roster)) continue;
    if (i < 8) {
      positionPts += _kSprintTop8[i];
    } else {
      positionPts += _kSprintP9to22Pts;
    }
  }

  var statusPts = 0;
  for (final d in roster) {
    final canon = d.name;
    final pred = _predictedOutcomeForDriver(canon, predDnf, predDns, predDsq);
    if (pred == null ||
        (pred != SimulatorRaceStatus.dnf &&
            pred != SimulatorRaceStatus.dns &&
            pred != SimulatorRaceStatus.dsq)) {
      continue;
    }
    final act = actualByDriver[canon];
    if (act == pred) {
      statusPts += _kStatusBonus;
    }
  }

  var fullB = 0;
  var sliceB = 0;
  var podB = 0;
  if (applyCompletionBonuses) {
    if (hubSprintGridFullyCommitted(predictedSlots)) {
      fullB = _kSprintFullGridBonus;
    }
    if (_slotsTopNFilled(predictedSlots, 8)) {
      sliceB = _kSprintTop8CompletionBonus;
    }
    final ok = predictedSlots.length >= 3 &&
        actualSlots.length >= 3 &&
        predictedSlots[0] != null &&
        predictedSlots[1] != null &&
        predictedSlots[2] != null &&
        actualSlots[0] != null &&
        actualSlots[1] != null &&
        actualSlots[2] != null &&
        simulatorDriverNamesMatch(predictedSlots[0]!, actualSlots[0]!, roster) &&
        simulatorDriverNamesMatch(predictedSlots[1]!, actualSlots[1]!, roster) &&
        simulatorDriverNamesMatch(predictedSlots[2]!, actualSlots[2]!, roster);
    if (ok) podB = _kSprintPerfectPodiumBonus;
  }

  return HubSessionScore(
    positionPoints: positionPts,
    statusBonus: statusPts,
    fullGridBonus: fullB,
    sliceCompletionBonus: sliceB,
    perfectPodiumBonus: podB,
  );
}

class HubWeekendScore {
  const HubWeekendScore({
    required this.grandPrix,
    required this.sprint,
    required this.weekendTotal,
  });

  final HubSessionScore grandPrix;
  final HubSessionScore sprint;
  final int weekendTotal;
}

HubWeekendScore scoreHubWeekend({
  required List<String?> gpPredSlots,
  required Set<String> gpPredDnf,
  required Set<String> gpPredDns,
  required Set<String> gpPredDsq,
  required List<SimulatorResultRowLite> gpActualRows,
  required List<String?> sprintPredSlots,
  required Set<String> sprintPredDnf,
  required Set<String> sprintPredDns,
  required Set<String> sprintPredDsq,
  required List<SimulatorResultRowLite> sprintActualRows,
  required List<SimulatorDriverRef> roster,
  required bool hasSprintResults,
  required bool gpCompletionEligible,
  required bool sprintCompletionEligible,
}) {
  final gp = scoreHubGrandPrixSession(
    predictedSlots: gpPredSlots,
    predDnf: gpPredDnf,
    predDns: gpPredDns,
    predDsq: gpPredDsq,
    actualRows: gpActualRows,
    roster: roster,
    applyCompletionBonuses: gpCompletionEligible,
  );
  final sp = hasSprintResults
      ? scoreHubSprintSession(
          predictedSlots: sprintPredSlots,
          predDnf: sprintPredDnf,
          predDns: sprintPredDns,
          predDsq: sprintPredDsq,
          actualRows: sprintActualRows,
          roster: roster,
          applyCompletionBonuses: sprintCompletionEligible,
        )
      : const HubSessionScore(
          positionPoints: 0,
          statusBonus: 0,
          fullGridBonus: 0,
          sliceCompletionBonus: 0,
          perfectPodiumBonus: 0,
        );
  return HubWeekendScore(
    grandPrix: gp,
    sprint: sp,
    weekendTotal: gp.total + sp.total,
  );
}

int hubMaxWeekendScore({required bool hasSprintResults}) {
  if (hasSprintResults) {
    return kHubMaxGpSessionScore + kHubMaxSprintSessionScore;
  }
  return kHubMaxGpSessionScore;
}
