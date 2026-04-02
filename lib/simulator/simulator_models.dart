import 'package:flutter/foundation.dart';

import 'package:f1/utils/driver_name_utils.dart';

import 'simulator_grid_config.dart';

/// One row from bundled race results JSON.
@immutable
class SimulatorResultRowLite {
  const SimulatorResultRowLite({
    required this.driver,
    required this.finish,
    required this.pointsRaw,
  });

  final String driver;
  final String finish;
  final String pointsRaw;

  int? parsedPoints() => int.tryParse(pointsRaw.trim());
}

@immutable
class SimulatorDriverRef {
  const SimulatorDriverRef({
    required this.number,
    required this.name,
    required this.team,
  });

  final int number;
  final String name;
  final String team;
}

@immutable
class SimulatorRoundInput {
  const SimulatorRoundInput({
    required this.circuitId,
    required this.roundIndex,
    required this.displayName,
    required this.grandPrixName,
    required this.date,
    required this.hasSprint,
    required this.hasActualResults,
    required this.actualRows,
    this.sprintActualRows = const [],
    required this.grandPrixStartUtc,
    this.sprintRaceStartUtc,
    this.isCancelled = false,
  });

  final String circuitId;
  final int roundIndex;
  final String displayName;
  final String grandPrixName;
  final DateTime date;
  final bool hasSprint;
  final bool hasActualResults;
  final List<SimulatorResultRowLite> actualRows;
  /// Bundled/cache sprint race rows (8–1 points) when [hasSprint].
  final List<SimulatorResultRowLite> sprintActualRows;
  /// Official GP session start (UTC) for pre-race lock.
  final DateTime grandPrixStartUtc;
  final DateTime? sprintRaceStartUtc;
  /// Voided / off-calendar — no scoring or editing.
  final bool isCancelled;
}

/// Cumulative constructor points after each completed round (for trend chart).
@immutable
class SimulatorTeamSeriesData {
  const SimulatorTeamSeriesData({
    required this.team,
    required this.cumulativePoints,
  });

  final String team;
  final List<double> cumulativePoints;
}

/// One row in the steward virtual classification for a circuit.
@immutable
class DriverStanding {
  const DriverStanding({
    required this.driver,
    required this.finishRank,
    required this.virtualMillis,
    required this.penaltySeconds,
    required this.isDnf,
    required this.weekendGpPoints,
    required this.weekendSprintPoints,
  });

  final SimulatorDriverRef driver;
  final int finishRank;
  final int virtualMillis;
  final int penaltySeconds;
  final bool isDnf;
  final int weekendGpPoints;
  final int weekendSprintPoints;
}

/// Parsed finish: position, DNF, DSQ, etc.
enum SimulatorRaceStatus { classified, dnf, dsq, dns, unknown }

@immutable
class ParsedFinish {
  const ParsedFinish({this.position, required this.status});

  final int? position;
  final SimulatorRaceStatus status;

  bool get countsForPoints =>
      status == SimulatorRaceStatus.classified &&
      position != null &&
      position! >= 1 &&
      position! <= kSimulatorGridSize;
}

ParsedFinish parseFinishField(String finish) {
  final u = finish.toUpperCase();
  if (u.contains('DSQ')) {
    return const ParsedFinish(status: SimulatorRaceStatus.dsq);
  }
  if (u.contains('DNF') || u.contains('RET')) {
    return const ParsedFinish(status: SimulatorRaceStatus.dnf);
  }
  if (u.contains('DNS') || u.contains('DID NOT START')) {
    return const ParsedFinish(status: SimulatorRaceStatus.dns);
  }
  final m = RegExp(r'P\s*(\d+)').firstMatch(finish);
  if (m != null) {
    final p = int.tryParse(m.group(1)!);
    if (p != null) {
      return ParsedFinish(position: p, status: SimulatorRaceStatus.classified);
    }
  }
  return const ParsedFinish(status: SimulatorRaceStatus.unknown);
}

/// File stem for `images/drivers/{slug}.png` — ASCII-folded names (é → e).
String driverPortraitSlugForAsset(String fullName) {
  final folded = normalizeForComparison(fullName.trim());
  final slug = folded.isEmpty
      ? fullName
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '')
      : folded
          .replaceAll(RegExp(r'\s+'), '-')
          .replaceAll(RegExp(r'[^a-z0-9-]'), '')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'na' : slug;
}

/// `images/drivers/george-russell.png` → web serves `/assets/images/drivers/…`.
String driverPortraitAssetPath(String fullName) {
  final slug = driverPortraitSlugForAsset(fullName);
  return 'images/drivers/$slug.png';
}

/// Tries, in order: [images/drivers] (download script default), [assets/images/drivers]
/// (bundled under `assets/images/` in pubspec), then [data/images/drivers] overrides.
List<String> driverPortraitAssetPathCandidates(String fullName) {
  final slug = driverPortraitSlugForAsset(fullName);
  return [
    'images/drivers/$slug.png',
    'assets/images/drivers/$slug.png',
    'data/images/drivers/$slug.png',
  ];
}

/// Portrait path using [canonicalSimulatorDriverName] so API / cloud spellings map to assets.
String simulatorDriverPortraitPath(String raw, List<SimulatorDriverRef> roster) {
  final n = canonicalSimulatorDriverName(raw, roster);
  return driverPortraitAssetPath(n.isEmpty ? raw : n);
}

List<String> simulatorDriverPortraitPathCandidates(
  String raw,
  List<SimulatorDriverRef> roster,
) {
  final n = canonicalSimulatorDriverName(raw, roster);
  return driverPortraitAssetPathCandidates(n.isEmpty ? raw : n);
}

/// Grid size from app config ([kSimulatorGridSize]).
int get simulatorGridSlotCount => kSimulatorGridSize;

/// Maps a results-JSON or UI name onto the grid roster (e.g. "Andrea Kimi Antonelli" → Kimi Antonelli).
String canonicalSimulatorDriverName(String raw, List<SimulatorDriverRef> roster) {
  final trimmed = raw.trim();
  final n = normalizeForComparison(trimmed);
  if (n.isEmpty) return trimmed;

  for (final d in roster) {
    final dn = normalizeForComparison(d.name);
    if (dn.isNotEmpty && n == dn) return d.name;
  }

  // Ergast-style "G RUSSELL" / "K ANTONELLI" vs grid roster names.
  final rawTok = n.split(' ').where((e) => e.isNotEmpty).toList();
  if (rawTok.length == 2 && rawTok[0].length == 1) {
    final ini = rawTok[0];
    final sur = rawTok[1];
    for (final d in roster) {
      final dn = normalizeForComparison(d.name)
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toList();
      if (dn.length >= 2 && dn.last == sur) {
        final hit = dn.where((t) => t.isNotEmpty && t[0] == ini).isNotEmpty;
        if (hit) return d.name;
      }
    }
  }

  SimulatorDriverRef? best;
  var bestLen = 0;
  for (final d in roster) {
    final dn = normalizeForComparison(d.name);
    if (dn.length < 8) continue;
    if (n.contains(dn) && dn.length > bestLen) {
      best = d;
      bestLen = dn.length;
    }
  }
  if (best != null) return best.name;

  for (final d in roster) {
    final dn = normalizeForComparison(d.name);
    if (dn.length < 8 || n.length < 8) continue;
    if (dn.contains(n)) return d.name;
  }

  return trimmed;
}

/// Same driver despite FIA / grid spelling differences.
bool simulatorDriverNamesMatch(
  String a,
  String b,
  List<SimulatorDriverRef> roster,
) {
  final ca = canonicalSimulatorDriverName(a, roster);
  final cb = canonicalSimulatorDriverName(b, roster);
  return normalizeForComparison(ca) == normalizeForComparison(cb);
}
