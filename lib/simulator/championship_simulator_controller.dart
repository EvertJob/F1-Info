import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:f1/utils/driver_name_utils.dart';

import 'package:f1/simulator/championship_points.dart';
import 'package:f1/simulator/hub_prediction_scoring.dart';
import 'package:f1/simulator/prediction_scoring_engine.dart';
import 'package:f1/simulator/simulator_grid_config.dart';
import 'package:f1/simulator/simulator_models.dart';
import 'package:f1/simulator/simulator_prediction_payload.dart';
import 'package:f1/simulator/simulator_sync_service.dart';

const _kDraftKeyV1 = 'championship_simulator_draft_v1';
/// v2: completed rounds are never restored from disk (avoids stale 0% accuracy).
const _kDraftKeyV2 = 'championship_simulator_draft_v2';

class _UndoFrame {
  _UndoFrame({
    required this.podiums,
    required this.penalties,
    required this.dnf,
    required this.gpOrders,
    required this.sprintOrders,
    required this.raceDns,
    required this.raceDsq,
    required this.sprintDnf,
    required this.sprintDns,
    required this.sprintDsq,
    required this.gpCompletionLockedUtc,
    required this.sprintCompletionLockedUtc,
  });

  final Map<String, List<String>> podiums;
  final Map<String, Map<String, int>> penalties;
  final Map<String, Set<String>> dnf;
  final Map<String, List<String>> gpOrders;
  final Map<String, List<String>> sprintOrders;
  final Map<String, Set<String>> raceDns;
  final Map<String, Set<String>> raceDsq;
  final Map<String, Set<String>> sprintDnf;
  final Map<String, Set<String>> sprintDns;
  final Map<String, Set<String>> sprintDsq;
  final Map<String, DateTime?> gpCompletionLockedUtc;
  final Map<String, DateTime?> sprintCompletionLockedUtc;
}

/// Hybrid state: actual results when present, else user podium + steward grid.
class ChampionshipSimulatorController extends ChangeNotifier {
  ChampionshipSimulatorController({
    required List<SimulatorRoundInput> rounds,
    required List<SimulatorDriverRef> drivers,
    bool readOnly = false,
    /// Own (non–read-only) simulator: rounds [1..kStarterBonusRoundCount] count as
    /// max weekend score in [seasonPredictionPointsTotal] (including before results),
    /// and 100% on accuracy metrics once results exist (fair entry mid-season).
    /// [readOnly] shared views must pass `false` so scores reflect real picks.
    bool starterBonusFirstThreeRounds = false,
  })  : _readOnly = readOnly,
        _starterBonusFirstThreeRounds = starterBonusFirstThreeRounds,
        _rounds = List<SimulatorRoundInput>.from(rounds),
        _drivers = List<SimulatorDriverRef>.from(drivers) {
    _initPredictionsFromActual();
    _initRaceOrdersForAllCircuits();
    _initStewardStateForAllCircuits();
  }

  /// First N championship rounds (1-based [roundIndex]) get max score / 100% accuracy
  /// when [starterBonusFirstThreeRounds] is enabled.
  static const int kStarterBonusRoundCount = 3;

  final List<SimulatorRoundInput> _rounds;
  final List<SimulatorDriverRef> _drivers;
  bool _readOnly;
  bool get readOnly => _readOnly;

  bool _starterBonusFirstThreeRounds;
  bool get starterBonusFirstThreeRounds => _starterBonusFirstThreeRounds;

  /// Keeps controller in sync when [ChampionshipSimulatorPage.readOnly] changes on the host.
  void applyHostReadOnly(bool value) {
    final starter = !value;
    if (_readOnly == value && _starterBonusFirstThreeRounds == starter) return;
    _readOnly = value;
    _starterBonusFirstThreeRounds = starter;
    notifyListeners();
  }

  final Map<String, List<String>> _predictionPodiums = {};
  final Map<String, Map<String, int>> _penaltySeconds = {};
  final Map<String, Set<String>> _dnfDrivers = {};
  final Map<String, Map<String, int>> _circuitBaseMicros = {};
  final Map<String, List<String>> _gpRaceOrder = {};
  final Map<String, List<String>> _sprintRaceOrder = {};
  final Map<String, Set<String>> _raceDns = {};
  final Map<String, Set<String>> _raceDsq = {};
  final Map<String, Set<String>> _sprintDnf = {};
  final Map<String, Set<String>> _sprintDns = {};
  final Map<String, Set<String>> _sprintDsq = {};
  /// Server UTC when a full GP grid was saved while still editable (before GP T−15).
  final Map<String, DateTime?> _gpCompletionLockedUtc = {};
  /// Server UTC when a full sprint grid was saved while still editable (before sprint T−15).
  final Map<String, DateTime?> _sprintCompletionLockedUtc = {};

  int _selectedRoundIndex = 0;
  final List<_UndoFrame> _undoStack = [];
  static const int _maxUndo = 40;

  Timer? _cloudSyncDebounce;
  static const Duration _kCloudSyncDelay = Duration(milliseconds: 450);

  /// Batches rapid edits into one Supabase upsert (still automatic, no manual button).
  void _scheduleCloudSync() {
    if (readOnly) return;
    if (Supabase.instance.client.auth.currentUser == null) return;
    _cloudSyncDebounce?.cancel();
    _cloudSyncDebounce = Timer(_kCloudSyncDelay, () {
      _cloudSyncDebounce = null;
      unawaited(_pushRemoteBestEffort());
    });
  }

  List<SimulatorRoundInput> get rounds => List.unmodifiable(_rounds);
  List<SimulatorDriverRef> get drivers => List.unmodifiable(_drivers);
  int get selectedRoundIndex => _selectedRoundIndex;

  SimulatorRoundInput get selectedRound => _rounds[_selectedRoundIndex];

  String get selectedCircuitId => selectedRound.circuitId;

  /// Switching rounds is allowed in [readOnly] (e.g. shared /#/s/… links); only edits are blocked.
  void selectRound(int index) {
    if (index < 0 || index >= _rounds.length) return;
    _selectedRoundIndex = index;
    notifyListeners();
  }

  void _initPredictionsFromActual() {
    for (final r in _rounds) {
      if (r.hasActualResults) {
        _predictionPodiums[r.circuitId] = _topThreeDriverNames(r.actualRows);
      } else {
        _predictionPodiums[r.circuitId] = _defaultPodiumGuess();
      }
    }
  }

  List<String> _defaultFullGridOrder() {
    return _drivers
        .map((d) => d.name)
        .take(kSimulatorGridSize)
        .toList(growable: false);
  }

  List<String> _gridFromResultRows(List<SimulatorResultRowLite> rows) {
    final cls = classificationFromRows(rows, _drivers);
    final taken = <String>{};
    final list = <String>[];
    for (final n in cls) {
      if (n == null || n.isEmpty) continue;
      final c = canonicalSimulatorDriverName(n, _drivers);
      if (taken.contains(c)) continue;
      taken.add(c);
      list.add(c);
    }
    for (final d in _drivers) {
      if (list.length >= kSimulatorGridSize) break;
      if (!taken.contains(d.name)) {
        taken.add(d.name);
        list.add(d.name);
      }
    }
    while (list.length < kSimulatorGridSize) {
      list.add(_drivers[list.length % _drivers.length].name);
    }
    return list.take(kSimulatorGridSize).toList(growable: false);
  }

  /// Extends a saved `gp` / `sprint` list (e.g. 20 names) to [kSimulatorGridSize] like result rows.
  List<String> _normalizePartialGridOrder(List<String> partial) {
    final taken = <String>{};
    final list = <String>[];
    for (final raw in partial) {
      if (raw.trim().isEmpty) continue;
      final c = canonicalSimulatorDriverName(raw, _drivers);
      if (taken.contains(c)) continue;
      taken.add(c);
      list.add(c);
    }
    for (final d in _drivers) {
      if (list.length >= kSimulatorGridSize) break;
      if (!taken.contains(d.name)) {
        taken.add(d.name);
        list.add(d.name);
      }
    }
    while (list.length < kSimulatorGridSize) {
      list.add(_drivers[list.length % _drivers.length].name);
    }
    return list.take(kSimulatorGridSize).toList(growable: false);
  }

  void _ensureDnsDsqMaps(String circuitId) {
    _raceDns.putIfAbsent(circuitId, () => {});
    _raceDsq.putIfAbsent(circuitId, () => {});
    _sprintDnf.putIfAbsent(circuitId, () => {});
    _sprintDns.putIfAbsent(circuitId, () => {});
    _sprintDsq.putIfAbsent(circuitId, () => {});
  }

  void _initRaceOrdersForAllCircuits() {
    for (final r in _rounds) {
      final cid = r.circuitId;
      _ensureDnsDsqMaps(cid);
      if (r.hasActualResults) {
        _gpRaceOrder[cid] = _gridFromResultRows(r.actualRows);
        if (r.hasSprint && r.sprintActualRows.isNotEmpty) {
          _sprintRaceOrder[cid] = _gridFromResultRows(r.sprintActualRows);
        } else {
          _sprintRaceOrder[cid] = List<String>.from(_gpRaceOrder[cid]!);
        }
      } else {
        _gpRaceOrder[cid] = _defaultFullGridOrder();
        _sprintRaceOrder[cid] = List<String>.from(_gpRaceOrder[cid]!);
        _syncPodiumToGpOrder(cid);
      }
    }
  }

  void _initStewardStateForAllCircuits() {
    for (final r in _rounds) {
      _ensureStewardMaps(r.circuitId);
      _recomputeBaseMicros(r.circuitId);
    }
  }

  void _ensureStewardMaps(String circuitId) {
    _penaltySeconds.putIfAbsent(circuitId, () => {});
    _dnfDrivers.putIfAbsent(circuitId, () => {});
    _circuitBaseMicros.putIfAbsent(circuitId, () => {});
    _ensureDnsDsqMaps(circuitId);
  }

  List<String> _defaultPodiumGuess() {
    return _drivers.take(3).map((d) => d.name).toList(growable: false);
  }

  List<String> _topThreeDriverNames(List<SimulatorResultRowLite> rows) {
    final scored = <({String name, int pos})>[];
    for (final row in rows) {
      final pf = parseFinishField(row.finish);
      if (pf.position != null) {
        scored.add((name: row.driver, pos: pf.position!));
      }
    }
    scored.sort((a, b) => a.pos.compareTo(b.pos));
    final names = scored
        .map((e) => canonicalSimulatorDriverName(e.name, _drivers))
        .take(3)
        .toList();
    while (names.length < 3) {
      final next = _drivers
          .map((d) => d.name)
          .firstWhere((n) => !names.contains(n), orElse: () => '');
      if (next.isEmpty) break;
      names.add(next);
    }
    return names.take(3).toList();
  }

  List<String> podiumForCircuit(String circuitId) =>
      List<String>.from(_predictionPodiums[circuitId] ?? _defaultPodiumGuess());

  List<String> gpRaceOrderForCircuit(String circuitId) {
    final g = _gpRaceOrder[circuitId];
    if (g != null && g.length >= kSimulatorGridSize) {
      return List<String>.from(g.take(kSimulatorGridSize));
    }
    return _defaultFullGridOrder();
  }

  List<String> sprintRaceOrderForCircuit(String circuitId) {
    final s = _sprintRaceOrder[circuitId];
    if (s != null && s.length >= kSimulatorGridSize) {
      return List<String>.from(s.take(kSimulatorGridSize));
    }
    return List<String>.from(gpRaceOrderForCircuit(circuitId));
  }

  void _syncGpOrderToPodium(String circuitId) {
    final o = gpRaceOrderForCircuit(circuitId);
    _predictionPodiums[circuitId] = o.take(3).toList();
  }

  void _syncPodiumToGpOrder(String circuitId) {
    final pod = _predictionPodiums[circuitId] ?? _defaultPodiumGuess();
    final top = <String>[];
    for (final p in pod.take(3)) {
      if (p.isNotEmpty) {
        top.add(canonicalSimulatorDriverName(p, _drivers));
      }
    }
    var order = List<String>.from(_gpRaceOrder[circuitId] ?? _defaultFullGridOrder());
    for (final n in top) {
      order.remove(n);
    }
    for (final d in _drivers) {
      if (top.length + order.length >= kSimulatorGridSize) break;
      if (!top.contains(d.name) && !order.contains(d.name)) {
        order.add(d.name);
      }
    }
    _gpRaceOrder[circuitId] = [...top, ...order].take(kSimulatorGridSize).toList();
  }

  List<SimulatorDriverRef> _refsOrderedForPoints(String cid, {required bool sprint}) {
    final order = sprint ? sprintRaceOrderForCircuit(cid) : gpRaceOrderForCircuit(cid);
    final out = <SimulatorDriverRef>[];
    final seen = <String>{};
    for (final raw in order) {
      if (raw.isEmpty) continue;
      final c = canonicalSimulatorDriverName(raw, _drivers);
      if (seen.contains(c)) continue;
      if (_isNonScoringForSession(cid, c, sprint: sprint)) continue;
      seen.add(c);
      SimulatorDriverRef? match;
      for (final d in _drivers) {
        if (d.name == c) {
          match = d;
          break;
        }
      }
      if (match != null) out.add(match);
    }
    return out;
  }

  bool _isNonScoringForSession(String cid, String canonName, {required bool sprint}) {
    if (!sprint) {
      return _dnfDrivers[cid]?.contains(canonName) == true ||
          _raceDns[cid]?.contains(canonName) == true ||
          _raceDsq[cid]?.contains(canonName) == true;
    }
    return _sprintDnf[cid]?.contains(canonName) == true ||
        _sprintDns[cid]?.contains(canonName) == true ||
        _sprintDsq[cid]?.contains(canonName) == true;
  }

  static DateTime _gpGridLockUtc(SimulatorRoundInput r) =>
      r.grandPrixStartUtc.toUtc().subtract(const Duration(minutes: 15));

  static DateTime? _sprintGridLockUtc(SimulatorRoundInput r) {
    final s = r.sprintRaceStartUtc;
    if (s == null) return null;
    return s.toUtc().subtract(const Duration(minutes: 15));
  }

  /// True when edits are allowed (more than 15 minutes before GP start, server time).
  Future<bool> isGpGridEditable() async {
    if (readOnly) return false;
    final r = selectedRound;
    if (r.isCancelled) return false;
    final server = await SimulatorSyncService.instance.fetchServerUtc();
    if (server == null) return true;
    return server.isBefore(_gpGridLockUtc(r));
  }

  /// Sprint grid editable when sprint exists and not within 15 min of sprint race start.
  Future<bool> isSprintGridEditable() async {
    if (readOnly) return false;
    final r = selectedRound;
    if (r.isCancelled || !r.hasSprint) return false;
    final lockAt = _sprintGridLockUtc(r);
    if (lockAt == null) return true;
    final server = await SimulatorSyncService.instance.fetchServerUtc();
    if (server == null) return true;
    return server.isBefore(lockAt);
  }

  bool _gpCompletionBonusesAllowed(SimulatorRoundInput r, List<String?> gpPred) {
    if (!hubGpGridFullyCommitted(gpPred)) return false;
    // Finished weekends: score full grid + bonuses when all 22 slots are filled.
    // Pre-race commitment (T−15 lock) still gates upcoming rounds.
    if (r.hasActualResults) return true;
    final lock = _gpCompletionLockedUtc[r.circuitId];
    if (lock == null) return false;
    return lock.isBefore(_gpGridLockUtc(r));
  }

  bool _sprintCompletionBonusesAllowed(
    SimulatorRoundInput r,
    List<String?> sprintPred,
  ) {
    if (!hubSprintGridFullyCommitted(sprintPred)) return false;
    final deadline = _sprintGridLockUtc(r);
    if (r.hasActualResults) {
      return r.hasSprint && r.sprintActualRows.isNotEmpty;
    }
    final lock = _sprintCompletionLockedUtc[r.circuitId];
    if (lock == null) return false;
    if (deadline == null) return false;
    return lock.isBefore(deadline);
  }

  /// Records commitment timestamps using [serverUtc] when grids are full and still before T−15.
  /// Invoked automatically before local/remote save; [serverUtc] defaults to `server_utc_now` RPC.
  Future<void> _refreshCommitmentLocksBeforePersist({DateTime? serverUtc}) async {
    if (readOnly) return;
    final server = serverUtc ?? await SimulatorSyncService.instance.fetchServerUtc();
    if (server == null) return;
    for (final r in _rounds) {
      if (r.hasActualResults || r.isCancelled) continue;
      final cid = r.circuitId;
      final gpPred = _nullableGridFromOrder(gpRaceOrderForCircuit(cid));
      if (hubGpGridFullyCommitted(gpPred) && server.isBefore(_gpGridLockUtc(r))) {
        _gpCompletionLockedUtc.putIfAbsent(cid, () => server);
      }
      if (r.hasSprint) {
        final spLock = _sprintGridLockUtc(r);
        if (spLock != null) {
          final spPred = _nullableGridFromOrder(sprintRaceOrderForCircuit(cid));
          if (hubSprintGridFullyCommitted(spPred) && server.isBefore(spLock)) {
            _sprintCompletionLockedUtc.putIfAbsent(cid, () => server);
          }
        }
      }
    }
  }

  List<String> actualTopThree(SimulatorRoundInput round) {
    if (!round.hasActualResults) return const [];
    return _topThreeDriverNames(round.actualRows);
  }

  /// Actual P1 driver name (canonical), or null.
  String? actualP1Name(SimulatorRoundInput round) {
    final t = actualTopThree(round);
    if (t.isEmpty) return null;
    return t.first;
  }

  /// Predicted P1 for a circuit.
  String? predictedP1ForCircuit(String circuitId) {
    final p = podiumForCircuit(circuitId);
    if (p.isEmpty || p.first.isEmpty) return null;
    return p.first;
  }

  bool starterBonusAppliesToRound(SimulatorRoundInput r) {
    return starterBonusFirstThreeRounds &&
        r.roundIndex >= 1 &&
        r.roundIndex <= kStarterBonusRoundCount &&
        r.hasActualResults &&
        !r.isCancelled;
  }

  int _maxWeekendScoreForRound(SimulatorRoundInput r) {
    if (r.isCancelled || !r.hasActualResults) return 0;
    return hubMaxWeekendScore(
      hasSprintResults: r.hasSprint && r.sprintActualRows.isNotEmpty,
    );
  }

  static const HubWeekendScore _kZeroHubWeekend = HubWeekendScore(
    grandPrix: HubSessionScore(
      positionPoints: 0,
      statusBonus: 0,
      fullGridBonus: 0,
      sliceCompletionBonus: 0,
      perfectPodiumBonus: 0,
    ),
    sprint: HubSessionScore(
      positionPoints: 0,
      statusBonus: 0,
      fullGridBonus: 0,
      sliceCompletionBonus: 0,
      perfectPodiumBonus: 0,
    ),
    weekendTotal: 0,
  );

  /// Full hub breakdown without starter-round override (leaderboard / SQL).
  HubWeekendScore hubWeekendScoreForRound(SimulatorRoundInput r) =>
      _rawHubWeekendScore(r);

  HubWeekendScore _rawHubWeekendScore(SimulatorRoundInput r) {
    if (r.isCancelled || !r.hasActualResults) return _kZeroHubWeekend;
    final cid = r.circuitId;
    final gpPred = _nullableGridFromOrder(gpRaceOrderForCircuit(cid));
    final hasSprintData = r.hasSprint && r.sprintActualRows.isNotEmpty;
    final spPred = hasSprintData
        ? _nullableGridFromOrder(sprintRaceOrderForCircuit(cid))
        : List<String?>.filled(kSimulatorGridSize, null);
    return scoreHubWeekend(
      gpPredSlots: gpPred,
      gpPredDnf: _dnfDrivers[cid] ?? {},
      gpPredDns: _raceDns[cid] ?? {},
      gpPredDsq: _raceDsq[cid] ?? {},
      gpActualRows: r.actualRows,
      sprintPredSlots: spPred,
      sprintPredDnf: _sprintDnf[cid] ?? {},
      sprintPredDns: _sprintDns[cid] ?? {},
      sprintPredDsq: _sprintDsq[cid] ?? {},
      sprintActualRows: r.sprintActualRows,
      roster: _drivers,
      hasSprintResults: hasSprintData,
      gpCompletionEligible: _gpCompletionBonusesAllowed(r, gpPred),
      sprintCompletionEligible: hasSprintData &&
          _sprintCompletionBonusesAllowed(r, spPred),
    );
  }

  /// Same value as the per-weekend total shown in hub stats (includes starter bonus).
  int weekendTotalScore(SimulatorRoundInput r) =>
      weekendPredictionPointsForRound(r);

  /// Sum of per-race scores: exact P1 = 100, predicted P1 finished P2 = 50.
  int seasonP1AccuracyScore() {
    var score = 0;
    for (final r in _rounds) {
      if (!r.hasActualResults || r.isCancelled) continue;
      if (starterBonusAppliesToRound(r)) {
        score += 100;
        continue;
      }
      final actP1 = actualP1Name(r);
      final predP1 = predictedP1ForCircuit(r.circuitId);
      if (actP1 == null || predP1 == null) continue;
      final predPos = _actualFinishPositionForDriver(r, predP1);
      if (predPos == null) continue;
      if (simulatorDriverNamesMatch(actP1, predP1, _drivers)) {
        score += 100;
      } else if (predPos == 2) {
        score += 50;
      }
    }
    return score;
  }

  /// 0–100: score / (100 * racesWithResults).
  double seasonP1AccuracyPercent() {
    var n = 0;
    for (final r in _rounds) {
      if (r.isCancelled) continue;
      if (!r.hasActualResults || actualP1Name(r) == null) continue;
      if (starterBonusAppliesToRound(r)) {
        n++;
        continue;
      }
      if (predictedP1ForCircuit(r.circuitId) == null) continue;
      n++;
    }
    if (n == 0) return 100;
    return (seasonP1AccuracyScore() / (100 * n) * 100).clamp(0, 100);
  }

  int? _actualFinishPositionForDriver(SimulatorRoundInput round, String driverName) {
    final target = normalizeForComparison(canonicalSimulatorDriverName(driverName, _drivers));
    for (final row in round.actualRows) {
      final pf = parseFinishField(row.finish);
      if (pf.position == null) continue;
      final dn = normalizeForComparison(
        canonicalSimulatorDriverName(row.driver, _drivers),
      );
      if (dn == target) return pf.position;
    }
    return null;
  }

  /// Timeline badge: true = predicted P1 matched actual P1.
  bool? p1MatchForRound(SimulatorRoundInput round) {
    if (round.isCancelled) return null;
    if (!round.hasActualResults) return null;
    if (starterBonusAppliesToRound(round)) return true;
    final a = actualP1Name(round);
    final p = predictedP1ForCircuit(round.circuitId);
    if (a == null || p == null) return null;
    return simulatorDriverNamesMatch(a, p, _drivers);
  }

  Map<String, int> penaltyMapForCircuit(String circuitId) =>
      Map<String, int>.from(_penaltySeconds[circuitId] ?? {});

  Set<String> dnfSetForCircuit(String circuitId) =>
      Set<String>.from(_dnfDrivers[circuitId] ?? {});

  void _recomputeBaseMicros(String circuitId) {
    _ensureStewardMaps(circuitId);
    final order = gpRaceOrderForCircuit(circuitId);
    final m = <String, int>{};
    for (var i = 0; i < order.length; i++) {
      final c = canonicalSimulatorDriverName(order[i], _drivers);
      m[c] = (i + 1) * 100;
    }
    for (final d in _drivers) {
      m.putIfAbsent(d.name, () => 500000 + d.number);
    }
    _circuitBaseMicros[circuitId] = m;
  }

  int _virtualScore(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    if (_dnfDrivers[circuitId]?.contains(c) == true) {
      return 1 << 30;
    }
    if (_raceDns[circuitId]?.contains(c) == true ||
        _raceDsq[circuitId]?.contains(c) == true) {
      return 1 << 29;
    }
    final base = _circuitBaseMicros[circuitId]?[c] ?? 500000;
    final pen = _penaltySeconds[circuitId]?[c] ?? 0;
    return base + pen * 1000000;
  }

  /// Grid order + weekend points (GP top 10 from GP order; sprint top 8 from sprint order).
  List<DriverStanding> stewardStandingsForCircuit(String circuitId) {
    final round = _roundForCircuitId(circuitId);
    final hasSprint = round?.hasSprint ?? false;
    final gpClassified = _refsOrderedForPoints(circuitId, sprint: false);
    final spClassified =
        hasSprint ? _refsOrderedForPoints(circuitId, sprint: true) : const <SimulatorDriverRef>[];

    final gpPts = <String, int>{};
    final spPts = <String, int>{};
    for (var i = 0; i < gpClassified.length && i < 10; i++) {
      final n = gpClassified[i].name;
      gpPts[n] = ChampionshipPoints.gpPointsForPosition(i + 1);
    }
    if (hasSprint) {
      for (var i = 0; i < spClassified.length && i < 8; i++) {
        final n = spClassified[i].name;
        spPts[n] = ChampionshipPoints.sprintPointsForPosition(i + 1);
      }
    }

    final displayOrder = <SimulatorDriverRef>[];
    final seen = <String>{};
    for (final raw in gpRaceOrderForCircuit(circuitId)) {
      if (raw.isEmpty) continue;
      final c = canonicalSimulatorDriverName(raw, _drivers);
      if (seen.contains(c)) continue;
      seen.add(c);
      for (final d in _drivers) {
        if (d.name == c) {
          displayOrder.add(d);
          break;
        }
      }
    }
    for (final d in _drivers) {
      if (!seen.contains(d.name)) displayOrder.add(d);
    }

    var rank = 0;
    return [
      for (final d in displayOrder)
        DriverStanding(
          driver: d,
          finishRank: ++rank,
          virtualMillis: _virtualScore(circuitId, d.name),
          penaltySeconds: _penaltySeconds[circuitId]?[d.name] ?? 0,
          isDnf: _dnfDrivers[circuitId]?.contains(d.name) ?? false,
          weekendGpPoints: gpPts[d.name] ?? 0,
          weekendSprintPoints: spPts[d.name] ?? 0,
        ),
    ];
  }

  void _pushUndo() {
    if (readOnly) return;
    _undoStack.add(
      _UndoFrame(
        podiums: _predictionPodiums.map((k, v) => MapEntry(k, List<String>.from(v))),
        penalties: _penaltySeconds.map(
          (k, v) => MapEntry(k, Map<String, int>.from(v)),
        ),
        dnf: _dnfDrivers.map(
          (k, v) => MapEntry(k, Set<String>.from(v)),
        ),
        gpOrders: _gpRaceOrder.map((k, v) => MapEntry(k, List<String>.from(v))),
        sprintOrders: _sprintRaceOrder.map((k, v) => MapEntry(k, List<String>.from(v))),
        raceDns: _raceDns.map((k, v) => MapEntry(k, Set<String>.from(v))),
        raceDsq: _raceDsq.map((k, v) => MapEntry(k, Set<String>.from(v))),
        sprintDnf: _sprintDnf.map((k, v) => MapEntry(k, Set<String>.from(v))),
        sprintDns: _sprintDns.map((k, v) => MapEntry(k, Set<String>.from(v))),
        sprintDsq: _sprintDsq.map((k, v) => MapEntry(k, Set<String>.from(v))),
        gpCompletionLockedUtc:
            _gpCompletionLockedUtc.map((k, v) => MapEntry(k, v)),
        sprintCompletionLockedUtc:
            _sprintCompletionLockedUtc.map((k, v) => MapEntry(k, v)),
      ),
    );
    while (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
  }

  bool get canUndo => !readOnly && _undoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;
    final prev = _undoStack.removeLast();
    _predictionPodiums
      ..clear()
      ..addAll(prev.podiums.map((k, v) => MapEntry(k, List<String>.from(v))));
    _penaltySeconds
      ..clear()
      ..addAll(prev.penalties.map((k, v) => MapEntry(k, Map<String, int>.from(v))));
    _dnfDrivers
      ..clear()
      ..addAll(prev.dnf.map((k, v) => MapEntry(k, Set<String>.from(v))));
    _gpRaceOrder
      ..clear()
      ..addAll(prev.gpOrders.map((k, v) => MapEntry(k, List<String>.from(v))));
    _sprintRaceOrder
      ..clear()
      ..addAll(prev.sprintOrders.map((k, v) => MapEntry(k, List<String>.from(v))));
    _raceDns
      ..clear()
      ..addAll(prev.raceDns.map((k, v) => MapEntry(k, Set<String>.from(v))));
    _raceDsq
      ..clear()
      ..addAll(prev.raceDsq.map((k, v) => MapEntry(k, Set<String>.from(v))));
    _sprintDnf
      ..clear()
      ..addAll(prev.sprintDnf.map((k, v) => MapEntry(k, Set<String>.from(v))));
    _sprintDns
      ..clear()
      ..addAll(prev.sprintDns.map((k, v) => MapEntry(k, Set<String>.from(v))));
    _sprintDsq
      ..clear()
      ..addAll(prev.sprintDsq.map((k, v) => MapEntry(k, Set<String>.from(v))));
    _gpCompletionLockedUtc
      ..clear()
      ..addAll(
        prev.gpCompletionLockedUtc.map((k, v) => MapEntry(k, v)),
      );
    _sprintCompletionLockedUtc
      ..clear()
      ..addAll(
        prev.sprintCompletionLockedUtc.map((k, v) => MapEntry(k, v)),
      );
    for (final r in _rounds) {
      _recomputeBaseMicros(r.circuitId);
    }
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void assignPodiumSlot(String circuitId, int slotIndex, String driverName) {
    if (readOnly || slotIndex < 0 || slotIndex > 2) return;
    final ro = _roundForCircuitId(circuitId);
    if (ro != null && ro.hasActualResults) return;
    _pushUndo();
    final list = List<String>.from(
      _predictionPodiums[circuitId] ?? _defaultPodiumGuess(),
    );
    while (list.length < 3) {
      list.add('');
    }
    final oldIndex = list.indexOf(driverName);
    if (oldIndex >= 0) {
      list.removeAt(oldIndex);
    }
    list.insert(slotIndex, driverName);
    final compact = <String>[];
    for (final n in list) {
      if (n.isNotEmpty && !compact.contains(n)) compact.add(n);
    }
    for (final d in _drivers.map((e) => e.name)) {
      if (compact.length >= 3) break;
      if (!compact.contains(d)) compact.add(d);
    }
    _predictionPodiums[circuitId] = compact.take(3).toList();
    _syncPodiumToGpOrder(circuitId);
    _recomputeBaseMicros(circuitId);
    notifyListeners();
    HapticFeedback.lightImpact();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void swapPodiumSlots(String circuitId, int a, int b) {
    if (readOnly || a == b) return;
    final ro = _roundForCircuitId(circuitId);
    if (ro != null && ro.hasActualResults) return;
    final list = podiumForCircuit(circuitId);
    if (a < 0 || b < 0 || a > 2 || b > 2) return;
    _pushUndo();
    final copy = List<String>.from(list);
    while (copy.length < 3) {
      copy.add(_drivers[copy.length.clamp(0, _drivers.length - 1)].name);
    }
    final t = copy[a];
    copy[a] = copy[b];
    copy[b] = t;
    _predictionPodiums[circuitId] = copy;
    _syncPodiumToGpOrder(circuitId);
    _recomputeBaseMicros(circuitId);
    notifyListeners();
    HapticFeedback.lightImpact();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void reorderGpRaceOrder(String circuitId, int oldIndex, int newIndex) {
    if (readOnly) return;
    _pushUndo();
    final list = List<String>.from(gpRaceOrderForCircuit(circuitId));
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex >= list.length) {
      return;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _gpRaceOrder[circuitId] = list;
    _syncGpOrderToPodium(circuitId);
    _recomputeBaseMicros(circuitId);
    notifyListeners();
    HapticFeedback.lightImpact();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void reorderSprintRaceOrder(String circuitId, int oldIndex, int newIndex) {
    if (readOnly) return;
    _pushUndo();
    final list = List<String>.from(sprintRaceOrderForCircuit(circuitId));
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex >= list.length) {
      return;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _sprintRaceOrder[circuitId] = list;
    notifyListeners();
    HapticFeedback.lightImpact();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  bool isGpDnf(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    return _dnfDrivers[circuitId]?.contains(c) ?? false;
  }

  bool isGpDns(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    return _raceDns[circuitId]?.contains(c) ?? false;
  }

  bool isGpDsq(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    return _raceDsq[circuitId]?.contains(c) ?? false;
  }

  bool isSprintDnf(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    return _sprintDnf[circuitId]?.contains(c) ?? false;
  }

  bool isSprintDns(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    return _sprintDns[circuitId]?.contains(c) ?? false;
  }

  bool isSprintDsq(String circuitId, String driverName) {
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    return _sprintDsq[circuitId]?.contains(c) ?? false;
  }

  void toggleGpDns(String circuitId, String driverName) {
    if (readOnly) return;
    _pushUndo();
    _ensureDnsDsqMaps(circuitId);
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    final s = _raceDns[circuitId]!;
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
      _raceDsq[circuitId]!.remove(c);
      _dnfDrivers[circuitId]?.remove(c);
    }
    _recomputeBaseMicros(circuitId);
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void toggleGpDsq(String circuitId, String driverName) {
    if (readOnly) return;
    _pushUndo();
    _ensureDnsDsqMaps(circuitId);
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    final s = _raceDsq[circuitId]!;
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
      _raceDns[circuitId]!.remove(c);
      _dnfDrivers[circuitId]?.remove(c);
    }
    _recomputeBaseMicros(circuitId);
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void toggleSprintDnf(String circuitId, String driverName) {
    if (readOnly) return;
    _pushUndo();
    _ensureDnsDsqMaps(circuitId);
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    final s = _sprintDnf[circuitId]!;
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
    }
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void toggleSprintDns(String circuitId, String driverName) {
    if (readOnly) return;
    _pushUndo();
    _ensureDnsDsqMaps(circuitId);
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    final s = _sprintDns[circuitId]!;
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
      _sprintDsq[circuitId]!.remove(c);
      _sprintDnf[circuitId]!.remove(c);
    }
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void toggleSprintDsq(String circuitId, String driverName) {
    if (readOnly) return;
    _pushUndo();
    _ensureDnsDsqMaps(circuitId);
    final c = canonicalSimulatorDriverName(driverName, _drivers);
    final s = _sprintDsq[circuitId]!;
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
      _sprintDns[circuitId]!.remove(c);
      _sprintDnf[circuitId]!.remove(c);
    }
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void togglePenaltySeconds(String circuitId, String driverName, int delta) {
    if (readOnly || delta == 0) return;
    _pushUndo();
    _ensureStewardMaps(circuitId);
    final canon = canonicalSimulatorDriverName(driverName, _drivers);
    final m = _penaltySeconds[circuitId]!;
    final next = (m[canon] ?? 0) + delta;
    if (next <= 0) {
      m.remove(canon);
    } else {
      m[canon] = next;
    }
    notifyListeners();
    HapticFeedback.lightImpact();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void toggleDnf(String circuitId, String driverName) {
    if (readOnly) return;
    _pushUndo();
    _ensureStewardMaps(circuitId);
    final canon = canonicalSimulatorDriverName(driverName, _drivers);
    final s = _dnfDrivers[circuitId]!;
    if (s.contains(canon)) {
      s.remove(canon);
    } else {
      s.add(canon);
      _raceDns[circuitId]?.remove(canon);
      _raceDsq[circuitId]?.remove(canon);
    }
    _recomputeBaseMicros(circuitId);
    notifyListeners();
    HapticFeedback.lightImpact();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void clearStewardForCircuit(String circuitId) {
    if (readOnly) return;
    _pushUndo();
    _penaltySeconds[circuitId]?.clear();
    _dnfDrivers[circuitId]?.clear();
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void _addGrandPrixPoints(
    Map<String, int> totals,
    List<SimulatorResultRowLite> rows,
  ) {
    for (final row in rows) {
      final pf = parseFinishField(row.finish);
      if (!pf.countsForPoints) continue;
      final jsonPts = row.parsedPoints();
      final pts = (jsonPts != null && jsonPts >= 0)
          ? jsonPts
          : ChampionshipPoints.gpPointsForPosition(pf.position!);
      final key = canonicalSimulatorDriverName(row.driver, _drivers);
      totals[key] = (totals[key] ?? 0) + pts;
    }
  }

  void _addSprintPoints(
    Map<String, int> totals,
    List<SimulatorResultRowLite> rows,
  ) {
    for (final row in rows) {
      final pf = parseFinishField(row.finish);
      if (pf.status != SimulatorRaceStatus.classified || pf.position == null) {
        continue;
      }
      final pos = pf.position!;
      if (pos < 1 || pos > 8) continue;
      final jsonPts = row.parsedPoints();
      final pts = (jsonPts != null && jsonPts >= 0)
          ? jsonPts
          : ChampionshipPoints.sprintPointsForPosition(pos);
      final key = canonicalSimulatorDriverName(row.driver, _drivers);
      totals[key] = (totals[key] ?? 0) + pts;
    }
  }

  Map<String, int> championshipActualPoints() {
    final totals = <String, int>{};
    for (final d in _drivers) {
      totals[d.name] = 0;
    }
    for (final round in _rounds) {
      if (!round.hasActualResults || round.isCancelled) continue;
      _addGrandPrixPoints(totals, round.actualRows);
      if (round.hasSprint && round.sprintActualRows.isNotEmpty) {
        _addSprintPoints(totals, round.sprintActualRows);
      }
    }
    return totals;
  }

  Map<String, int> championshipProjectedExtras() {
    final totals = <String, int>{};
    for (final d in _drivers) {
      totals[d.name] = 0;
    }
    for (final round in _rounds) {
      if (round.hasActualResults || round.isCancelled) continue;
      final cid = round.circuitId;
      final gpClassified = _refsOrderedForPoints(cid, sprint: false);
      for (var i = 0; i < gpClassified.length && i < 10; i++) {
        final pts = ChampionshipPoints.gpPointsForPosition(i + 1);
        totals[gpClassified[i].name] = (totals[gpClassified[i].name] ?? 0) + pts;
      }
      if (round.hasSprint) {
        final spClassified = _refsOrderedForPoints(cid, sprint: true);
        for (var i = 0; i < spClassified.length && i < 8; i++) {
          final pts = ChampionshipPoints.sprintPointsForPosition(i + 1);
          totals[spClassified[i].name] = (totals[spClassified[i].name] ?? 0) + pts;
        }
      }
    }
    return totals;
  }

  Map<String, int> combinedStandings() {
    final a = championshipActualPoints();
    final p = championshipProjectedExtras();
    final keys = {...a.keys, ...p.keys, ..._drivers.map((d) => d.name)};
    final out = <String, int>{};
    for (final k in keys) {
      out[k] = (a[k] ?? 0) + (p[k] ?? 0);
    }
    return out;
  }

  List<MapEntry<String, int>> standingsLeaderboard() {
    final m = combinedStandings();
    final list = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<MapEntry<String, int>> seasonStandingsLeaderboard() {
    final m = championshipActualPoints();
    final list = _drivers
        .map((d) => MapEntry(d.name, m[d.name] ?? 0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  int? magicNumberClinchRoundIndex() {
    final board = seasonStandingsLeaderboard();
    if (board.length < 2) return null;
    final gap = board.first.value - board[1].value;
    for (var i = 0; i < _rounds.length; i++) {
      if (_rounds[i].hasActualResults || _rounds[i].isCancelled) continue;
      final futureGpLeft = _rounds
          .skip(i)
          .where((x) => !x.hasActualResults && !x.isCancelled)
          .length;
      if (futureGpLeft == 0) continue;
      final maxCatch = ChampionshipPoints.maxGpPointsRemaining(futureGpLeft);
      if (gap > maxCatch) return i;
    }
    return null;
  }

  List<String?> _nullableGridFromOrder(List<String> order) {
    final o = order.take(kSimulatorGridSize).toList();
    while (o.length < kSimulatorGridSize) {
      o.add('');
    }
    return o
        .map((e) => e.trim().isEmpty ? null : canonicalSimulatorDriverName(e, _drivers))
        .toList(growable: false);
  }

  int weekendPredictionPointsForRound(SimulatorRoundInput r) {
    if (r.isCancelled || !r.hasActualResults) return 0;
    if (starterBonusAppliesToRound(r)) {
      return _maxWeekendScoreForRound(r);
    }
    return _rawHubWeekendScore(r).weekendTotal;
  }

  int seasonPredictionPointsTotal() {
    if (!starterBonusFirstThreeRounds) {
      var s = 0;
      for (final r in _rounds) {
        s += weekendPredictionPointsForRound(r);
      }
      return s;
    }
    var starterBlock = 0;
    for (final r in _rounds) {
      if (r.isCancelled) continue;
      if (r.roundIndex < 1 || r.roundIndex > kStarterBonusRoundCount) continue;
      starterBlock += r.hasActualResults
          ? _maxWeekendScoreForRound(r)
          : hubMaxWeekendScore(hasSprintResults: r.hasSprint);
    }
    var afterStarter = 0;
    for (final r in _rounds) {
      if (r.roundIndex <= kStarterBonusRoundCount) continue;
      afterStarter += weekendPredictionPointsForRound(r);
    }
    return starterBlock + afterStarter;
  }

  double seasonGridAccuracyPercent() {
    var cells = 0;
    var hits = 0;
    for (final r in _rounds) {
      if (!r.hasActualResults || r.isCancelled) continue;
      if (starterBonusAppliesToRound(r)) {
        cells += kSimulatorGridSize;
        hits += kSimulatorGridSize;
        continue;
      }
      final pred = gpRaceOrderForCircuit(r.circuitId);
      final act = classificationFromRows(r.actualRows, _drivers);
      for (var i = 0; i < kSimulatorGridSize; i++) {
        cells++;
        final pRaw = i < pred.length ? pred[i] : '';
        final p = pRaw.trim().isEmpty
            ? null
            : canonicalSimulatorDriverName(pRaw, _drivers);
        final a = i < act.length ? act[i] : null;
        if (p == null && a == null) {
          hits++;
        } else if (p != null &&
            a != null &&
            simulatorDriverNamesMatch(p, a, _drivers)) {
          hits++;
        }
      }
    }
    if (cells == 0) return 100;
    return (100 * hits / cells);
  }

  double predictionAccuracyPercent() {
    var total = 0;
    var hits = 0;
    for (final r in _rounds) {
      if (!r.hasActualResults || r.isCancelled) continue;
      if (starterBonusAppliesToRound(r)) {
        total += 3;
        hits += 3;
        continue;
      }
      final act = actualTopThree(r);
      final pred = podiumForCircuit(r.circuitId);
      for (var i = 0; i < 3 && i < act.length && i < pred.length; i++) {
        total++;
        if (simulatorDriverNamesMatch(act[i], pred[i], _drivers)) hits++;
      }
    }
    if (total == 0) return 100;
    return (100 * hits / total);
  }

  SimulatorRoundInput? _roundForCircuitId(String circuitId) {
    for (final r in _rounds) {
      if (r.circuitId == circuitId) return r;
    }
    return null;
  }

  void resyncCompletedRoundsFromActual() {
    if (readOnly) return;
    _resyncAllCompletedFromActual();
    notifyListeners();
    unawaited(persistDraft());
    _scheduleCloudSync();
  }

  void _applyPayloadMap(String cid, Map<String, dynamic> map) {
    final pod = <String>[];
    final pen = <String, int>{};
    final dnf = <String>{};
    final ro = <String>[];
    final so = <String>[];
    final rdns = <String>{};
    final rdsq = <String>{};
    final sdf = <String>{};
    final sdn = <String>{};
    final sdq = <String>{};
    applySimulatorPayloadToMaps(
      map,
      outPodium: pod,
      outPenalties: pen,
      outDnf: dnf,
      roster: _drivers,
      outRaceOrder: ro,
      outSprintOrder: so,
      outRaceDns: rdns,
      outRaceDsq: rdsq,
      outSprintDnf: sdf,
      outSprintDns: sdn,
      outSprintDsq: sdq,
      onCommitmentLocksRead: (gpUtc, spUtc) {
        if (gpUtc != null) _gpCompletionLockedUtc[cid] = gpUtc;
        if (spUtc != null) _sprintCompletionLockedUtc[cid] = spUtc;
      },
    );
    if (pod.length >= 3) {
      _predictionPodiums[cid] = pod.take(3).toList();
    }
    _penaltySeconds[cid] = pen;
    _dnfDrivers[cid] = dnf;
    _ensureDnsDsqMaps(cid);
    if (ro.length >= kSimulatorGridSize) {
      _gpRaceOrder[cid] = ro.take(kSimulatorGridSize).toList(growable: false);
    } else {
      _syncPodiumToGpOrder(cid);
    }
    if (so.length >= kSimulatorGridSize) {
      _sprintRaceOrder[cid] = so.take(kSimulatorGridSize).toList(growable: false);
    }
    _raceDns[cid] = rdns;
    _raceDsq[cid] = rdsq;
    _sprintDnf[cid] = sdf;
    _sprintDns[cid] = sdn;
    _sprintDsq[cid] = sdq;
    _recomputeBaseMicros(cid);
  }

  /// Apply rows from Supabase RPC / select. Skips completed rounds.
  void applyRemotePredictionRows(List<Map<String, dynamic>> rows) {
    if (readOnly) return;
    for (final row in rows) {
      final cid = row['circuit_id']?.toString();
      final payload = row['payload'];
      if (cid == null || payload is! Map) continue;
      final round = _roundForCircuitId(cid);
      if (round == null || round.hasActualResults || round.isCancelled) continue;

      _applyPayloadMap(cid, Map<String, dynamic>.from(payload));
    }
    notifyListeners();
  }

  /// Shared `/s/:username` view: merge stored payloads for every non-cancelled round.
  void applySharedRemoteRows(List<Map<String, dynamic>> rows) {
    if (!readOnly) return;
    for (final row in rows) {
      final cid = row['circuit_id']?.toString();
      final payload = row['payload'];
      if (cid == null || payload is! Map) continue;
      final round = _roundForCircuitId(cid);
      if (round == null || round.isCancelled) continue;
      _applyPayloadMap(cid, Map<String, dynamic>.from(payload));
    }
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> syncPayloadsForSupabase() {
    final out = <String, Map<String, dynamic>>{};
    for (final r in _rounds) {
      // Upload every non-cancelled round with a valid podium — not only "upcoming"
      // races. Otherwise local result cache can mark rounds as "complete" and
      // nothing would ever sync, or historical picks would never reach Supabase.
      if (r.isCancelled) continue;
      final cid = r.circuitId;
      final pod = podiumForCircuit(cid);
      if (pod.length < 3) continue;
      out[cid] = buildSimulatorPayload(
        podium: List<String>.from(pod),
        penalties: Map<String, int>.from(_penaltySeconds[cid] ?? {}),
        dnf: Set<String>.from(_dnfDrivers[cid] ?? {}),
        raceOrder: gpRaceOrderForCircuit(cid),
        sprintOrder: sprintRaceOrderForCircuit(cid),
        raceDns: _raceDns[cid],
        raceDsq: _raceDsq[cid],
        sprintDnf: _sprintDnf[cid],
        sprintDns: _sprintDns[cid],
        sprintDsq: _sprintDsq[cid],
        gpCompletionLockedUtc: _gpCompletionLockedUtc[cid],
        sprintCompletionLockedUtc: _sprintCompletionLockedUtc[cid],
      );
    }
    return out;
  }

  Future<void> _pushRemoteBestEffort() async {
    if (readOnly) return;
    await _refreshCommitmentLocksBeforePersist();
    final err =
        await SimulatorSyncService.instance.upsertAllPayloads(syncPayloadsForSupabase());
    if (err != null) {
      debugPrint('[ChampionshipSimulator] background cloud sync failed: $err');
    }
    unawaited(_pushHubScoresBestEffort());
  }

  Future<void> _pushHubScoresBestEffort() async {
    if (readOnly) return;
    final rows = hubScoresRowsForSupabase();
    if (rows.isEmpty) return;
    final err = await SimulatorSyncService.instance.upsertUserHubScores(rows);
    if (err != null && kDebugMode) {
      debugPrint('[ChampionshipSimulator] user_scores sync: $err');
    }
  }

  /// Rows for `user_scores` — raw hub totals per finished round (no starter bonus).
  List<Map<String, dynamic>> hubScoresRowsForSupabase() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final out = <Map<String, dynamic>>[];
    for (final r in _rounds) {
      if (!r.hasActualResults || r.isCancelled) continue;
      final w = _rawHubWeekendScore(r);
      out.add({
        'user_id': user.id,
        'circuit_id': r.circuitId,
        'season_year': 2026,
        'gp_score': w.grandPrix.total,
        'sprint_score': w.sprint.total,
        'weekend_total': w.weekendTotal,
      });
    }
    return out;
  }

  /// Call when [SimulatorRoundInput] list is replaced (e.g. official JSON merged).
  void updateRoundsFromHost(List<SimulatorRoundInput> next) {
    if (next.length != _rounds.length) {
      _rounds
        ..clear()
        ..addAll(List<SimulatorRoundInput>.from(next));
    } else {
      for (var i = 0; i < next.length; i++) {
        _rounds[i] = next[i];
      }
    }
    notifyListeners();
    unawaited(_pushHubScoresBestEffort());
  }

  Future<void> loadDraft() async {
    if (readOnly) return;
    final prefs = await SharedPreferences.getInstance();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final remote = await SimulatorSyncService.instance.pullPredictions();
      if (remote.isNotEmpty) {
        applyRemotePredictionRows(remote);
        await persistDraft();
        notifyListeners();
        _scheduleCloudSync();
        return;
      }
    }

    var raw = prefs.getString(_kDraftKeyV2);
    if (raw == null || raw.isEmpty) {
      raw = prefs.getString(_kDraftKeyV1);
    }
    if (raw == null || raw.isEmpty) {
      notifyListeners();
      _scheduleCloudSync();
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final preds = map['predictions'] as Map<String, dynamic>?;
      if (preds == null) {
        notifyListeners();
        _scheduleCloudSync();
        return;
      }
      for (final e in preds.entries) {
        final round = _roundForCircuitId(e.key);
        if (round == null || round.hasActualResults || round.isCancelled) {
          continue;
        }
        final v = e.value;
        if (v is List) {
          final list = v.map((x) => x.toString()).toList();
          if (list.length >= 3) {
            _predictionPodiums[e.key] = list.take(3).toList();
          }
          _syncPodiumToGpOrder(e.key);
          _recomputeBaseMicros(e.key);
        } else if (v is Map) {
          _applyPayloadMap(e.key, Map<String, dynamic>.from(v));
        }
      }
      for (final r in _rounds) {
        _recomputeBaseMicros(r.circuitId);
      }
      await prefs.setString(_kDraftKeyV2, raw);
      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
    _scheduleCloudSync();
  }

  void _resyncAllCompletedFromActual() {
    for (final r in _rounds) {
      if (r.hasActualResults) {
        final cid = r.circuitId;
        _predictionPodiums[cid] = _topThreeDriverNames(r.actualRows);
        _gpRaceOrder[cid] = _gridFromResultRows(r.actualRows);
        if (r.hasSprint && r.sprintActualRows.isNotEmpty) {
          _sprintRaceOrder[cid] = _gridFromResultRows(r.sprintActualRows);
        } else {
          _sprintRaceOrder[cid] = List<String>.from(_gpRaceOrder[cid]!);
        }
        _recomputeBaseMicros(cid);
      }
    }
  }

  Future<void> persistDraft() async {
    if (readOnly) return;
    await _refreshCommitmentLocksBeforePersist();
    final toSave = <String, dynamic>{};
    for (final r in _rounds) {
      if (r.hasActualResults || r.isCancelled) continue;
      final cid = r.circuitId;
      final pod = _predictionPodiums[cid];
      if (pod != null && pod.length >= 3) {
        toSave[cid] = buildSimulatorPayload(
          podium: List<String>.from(pod),
          penalties: Map<String, int>.from(_penaltySeconds[cid] ?? {}),
          dnf: Set<String>.from(_dnfDrivers[cid] ?? {}),
          raceOrder: gpRaceOrderForCircuit(cid),
          sprintOrder: sprintRaceOrderForCircuit(cid),
          raceDns: _raceDns[cid],
          raceDsq: _raceDsq[cid],
          sprintDnf: _sprintDnf[cid],
          sprintDns: _sprintDns[cid],
          sprintDsq: _sprintDsq[cid],
          gpCompletionLockedUtc: _gpCompletionLockedUtc[cid],
          sprintCompletionLockedUtc: _sprintCompletionLockedUtc[cid],
        );
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kDraftKeyV2,
      jsonEncode({'predictions': toSave}),
    );
  }

  /// Returns `null` on success. Otherwise a short reason code or server message.
  Future<String?> syncToSupabase() async {
    if (readOnly) return 'read_only';
    await persistDraft();
    final payloads = syncPayloadsForSupabase();
    if (payloads.isEmpty) {
      unawaited(_pushHubScoresBestEffort());
      return 'empty';
    }
    final err = await SimulatorSyncService.instance.upsertAllPayloads(payloads);
    unawaited(_pushHubScoresBestEffort());
    return err;
  }

  @override
  void dispose() {
    _cloudSyncDebounce?.cancel();
    if (!readOnly && Supabase.instance.client.auth.currentUser != null) {
      unawaited(_pushRemoteBestEffort());
    }
    super.dispose();
  }
}
