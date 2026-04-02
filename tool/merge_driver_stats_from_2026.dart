// Merges career stats into assets/data/drivers/*.json for season 2026 using
// assets/data/2026/<event>/*.json. Does NOT modify lib/f1_data.dart.
//
// Idempotent: values = baseline(season < 2026) + aggregate(all 2026 events).
// Running twice yields the same result as long as baseline seasons are unchanged.
//
// Run: dart run tool/merge_driver_stats_from_2026.dart
// Dry run: dart run tool/merge_driver_stats_from_2026.dart --dry-run
//
// Not auto-updated (no reliable signal in session JSON):
// - championships, championship_years (kept from baseline season)
// - laps_led (not in bundled JSON; kept from baseline)
// - dnqs (kept from baseline; DNS in race file increments dnqs — see below)

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _targetYear = 2026;
final _finishRe = RegExp(r'^(\d+)e \(x(\d+)\)\s*$');

// ---------------------------------------------------------------------------
// Parsing / formatting highest_finish & highest_grid (Dutch "Ne (xM)")
// ---------------------------------------------------------------------------

int? _parseTierPlace(String s) {
  final m = _finishRe.firstMatch(s.trim());
  return m == null ? null : int.tryParse(m.group(1)!);
}

int? _parseTierCount(String s) {
  final m = _finishRe.firstMatch(s.trim());
  return m == null ? null : int.tryParse(m.group(2)!);
}

String _formatTier(int place, int count) => '${place}e (x$count)';

int _baselineRaceAtPlace(Map<String, dynamic> baseline, int place) {
  switch (place) {
    case 1:
      return (baseline['wins'] as num?)?.toInt() ?? 0;
    case 2:
      return (baseline['podiums_2nd'] as num?)?.toInt() ?? 0;
    case 3:
      return (baseline['podiums_3rd'] as num?)?.toInt() ?? 0;
    default:
      return 0;
  }
}

/// Grid P1 ≈ poles; P2 ≈ front row minus pole (approximation).
int _baselineGridAtPlace(Map<String, dynamic> baseline, int place) {
  switch (place) {
    case 1:
      return (baseline['poles'] as num?)?.toInt() ?? 0;
    case 2:
      final fr = (baseline['front_row_starts'] as num?)?.toInt() ?? 0;
      final po = (baseline['poles'] as num?)?.toInt() ?? 0;
      return math.max(0, fr - po);
    default:
      return 0;
  }
}

int _countEq(List<int> xs, int v) => xs.where((e) => e == v).length;

/// Merge "Ne (xM)" using [baselineAtPlace] for career counts when best improves.
String mergeTierStat({
  required String baselineString,
  required List<int> seasonPositions,
  required int Function(int place) baselineAtPlace,
}) {
  final oldP = _parseTierPlace(baselineString);
  final oldC = _parseTierCount(baselineString);
  if (oldP == null || oldC == null) return baselineString;
  if (seasonPositions.isEmpty) return baselineString;

  final minS = seasonPositions.reduce(math.min);
  final newBest = math.min(oldP, minS);

  if (newBest == oldP) {
    final add = _countEq(seasonPositions, oldP);
    if (add == 0) return baselineString;
    return _formatTier(oldP, oldC + add);
  }

  final base = baselineAtPlace(newBest);
  final add = _countEq(seasonPositions, newBest);
  final n = base + add;
  return _formatTier(newBest, n < 1 ? math.max(1, add) : n);
}

// ---------------------------------------------------------------------------
// Session file loading
// ---------------------------------------------------------------------------

List<Map<String, dynamic>> _rows(File f) {
  if (!f.existsSync()) return [];
  final dynamic j = json.decode(f.readAsStringSync());
  if (j is! Map) return [];
  final r = j['results'];
  if (r is! List) return [];
  return r.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

double? _minFastestLap(List<Map<String, dynamic>> rows) {
  double? best;
  for (final row in rows) {
    final d = row['fastestLapDuration'];
    if (d is num) {
      final v = d.toDouble();
      best = best == null || v < best ? v : best;
    }
  }
  return best;
}

bool _hasOfficialFastestLap(Map<String, dynamic> row, double? raceBest) {
  if (raceBest == null) return false;
  final d = row['fastestLapDuration'];
  if (d is! num) return false;
  return (d.toDouble() - raceBest).abs() < 1e-6;
}

int _lapsFromStints(Map<String, dynamic> row) {
  final stints = row['tyreStints'];
  if (stints is! List) return 0;
  var sum = 0;
  for (final s in stints) {
    if (s is! Map) continue;
    final a = s['lapStart'];
    final b = s['lapEnd'];
    if (a is int && b is int && b >= a) {
      sum += b - a + 1;
    }
  }
  return sum;
}

bool _isDnf(String? gap) {
  if (gap == null) return false;
  final u = gap.trim().toUpperCase();
  return u == 'DNF' || u == 'RET' || u == 'RETIRED';
}

bool _isDsq(String? gap) {
  if (gap == null) return false;
  return gap.toUpperCase().contains('DSQ');
}

bool _isDns(String? gap) {
  if (gap == null) return false;
  return gap.toUpperCase().contains('DNS');
}

class WeekendAgg {
  WeekendAgg(this.eventSlug);

  final String eventSlug;

  /// Sunday GP race rows by driver number.
  final Map<int, Map<String, dynamic>> gpRaceByNum = {};

  /// Qualifying (GP grid) position by driver number.
  final Map<int, int> gpQualiPos = {};

  /// Sprint race points only (optional).
  double sprintPointsFor(int n) => _sprintPoints[n] ?? 0;
  final Map<int, double> _sprintPoints = {};

  void addGpRace(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final n = row['driverNumber'];
      if (n is int) gpRaceByNum[n] = row;
    }
  }

  void addGpQuali(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final n = row['driverNumber'];
      final p = row['finishPosition'];
      if (n is int && p is int && p >= 1) {
        gpQualiPos[n] = p;
      }
    }
  }

  void addSprintRace(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final n = row['driverNumber'];
      final pts = row['points'];
      if (n is int && pts is num) {
        _sprintPoints[n] = (_sprintPoints[n] ?? 0) + pts.toDouble();
      }
    }
  }
}

/// Discover `assets/data/2026/<event>/` with at least `race_results.json`.
List<WeekendAgg> load2026Weekends(Directory repoRoot) {
  final root = Directory.fromUri(repoRoot.uri.resolve('assets/data/2026/'));
  if (!root.existsSync()) return [];

  final out = <WeekendAgg>[];
  for (final ent in root.listSync(followLinks: false)) {
    if (ent is! Directory) continue;
    final slug = ent.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final raceFile = File('${ent.path}/race_results.json');
    if (!raceFile.existsSync()) continue;

    final w = WeekendAgg(slug);
    w.addGpRace(_rows(raceFile));
    w.addGpQuali(_rows(File('${ent.path}/qualifying_results.json')));
    w.addSprintRace(_rows(File('${ent.path}/sprint_results.json')));
    out.add(w);
  }
  out.sort((a, b) => a.eventSlug.compareTo(b.eventSlug));
  return out;
}

class Season2026Computed {
  int wins = 0;
  int p2 = 0;
  int p3 = 0;
  int podiums = 0;
  int poles = 0;
  int fastestLaps = 0;
  double pointsRace = 0;
  double pointsSprint = 0;
  int starts = 0;
  int dnfs = 0;
  int dsqs = 0;
  int dnqs = 0;
  int lapsRaced = 0;
  int hatTricks = 0;
  final List<int> raceFinishes = [];
  final List<int> qualiPositions = [];

  double get pointsTotal => pointsRace + pointsSprint;
}

Season2026Computed computeForNumber(int n, List<WeekendAgg> weekends) {
  final c = Season2026Computed();
  for (final w in weekends) {
    final row = w.gpRaceByNum[n];
    if (row == null) continue;

    final q = w.gpQualiPos[n];
    if (q != null && q >= 1) {
      c.qualiPositions.add(q);
      if (q == 1) {
        c.poles += 1;
      }
    }

    c.starts += 1;
    c.lapsRaced += _lapsFromStints(row);
    c.pointsSprint += w.sprintPointsFor(n);

    final gap = row['timeOrGap'] as String?;
    if (_isDsq(gap)) {
      c.dsqs += 1;
      continue;
    }
    if (_isDns(gap)) {
      c.dnqs += 1;
      continue;
    }

    final pos = row['finishPosition'];
    final pts = row['points'];
    if (pts is num) {
      c.pointsRace += pts.toDouble();
    }

    final rows = w.gpRaceByNum.values.toList();
    final best = _minFastestLap(rows);

    if (pos is int && pos >= 1) {
      if (pos == 1) {
        c.wins += 1;
      }
      if (pos == 2) {
        c.p2 += 1;
      }
      if (pos == 3) {
        c.p3 += 1;
      }
      if (pos <= 3) {
        c.podiums += 1;
      }
      c.raceFinishes.add(pos);

      if (_hasOfficialFastestLap(row, best)) {
        c.fastestLaps += 1;
      }
      if (q == 1 && pos == 1 && _hasOfficialFastestLap(row, best)) {
        c.hatTricks += 1;
      }
    } else if (_isDnf(gap)) {
      c.dnfs += 1;
    }
  }
  return c;
}

// ---------------------------------------------------------------------------
// Driver JSON
// ---------------------------------------------------------------------------

Map<String, dynamic>? _baselineRecord(List<dynamic> seasons) {
  var bestY = -1;
  Map<String, dynamic>? best;
  for (final s in seasons) {
    if (s is! Map) continue;
    final y = s['season_year'];
    if (y is! int || y >= _targetYear) continue;
    if (y > bestY) {
      bestY = y;
      final r = s['record'];
      if (r is Map) {
        best = Map<String, dynamic>.from(r);
      }
    }
  }
  return best;
}

/// Rijders met alleen 2026 in de export: career vóór 2026 = 0.
Map<String, dynamic> _zeroCareerBaseline() => {
      'wins': 0,
      'podiums_2nd': 0,
      'podiums_3rd': 0,
      'podiums': 0,
      'poles': 0,
      'fastest_laps': 0,
      'total_points': 0.0,
      'championships': 0,
      'championship_years': <dynamic>[],
      'laps_raced': 0,
      'starts': 0,
      'dnfs': 0,
      'dsqs': 0,
      'dnqs': 0,
      'laps_led': 0,
      'front_row_starts': 0,
      'hat_tricks': 0,
      'highest_finish': '99e (x0)',
      'highest_grid': '99e (x0)',
    };

Map<String, dynamic>? _seasonRecordMutable(Map<String, dynamic> doc, int year) {
  final seasons = doc['seasons'];
  if (seasons is! List) return null;
  for (var i = 0; i < seasons.length; i++) {
    final s = seasons[i];
    if (s is! Map) continue;
    if (s['season_year'] == year) {
      final r = s['record'];
      if (r is Map) {
        return Map<String, dynamic>.from(r);
      }
    }
  }
  return null;
}

void _replaceSeasonRecord(
  Map<String, dynamic> doc,
  int year,
  Map<String, dynamic> newRecord,
) {
  final seasons = doc['seasons'];
  if (seasons is! List) return;
  for (var i = 0; i < seasons.length; i++) {
    final s = seasons[i];
    if (s is! Map) continue;
    if (s['season_year'] == year) {
      seasons[i] = {...s, 'record': newRecord};
      return;
    }
  }
}

Map<String, dynamic> _copyPointsPerSeason(Map<String, dynamic> baseline) {
  final m = baseline['points_per_season'];
  if (m is! Map) return <String, dynamic>{};
  return m.map((k, v) => MapEntry(k.toString(), v));
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final repoRoot = Directory.current;
  final driversDir = Directory.fromUri(
    repoRoot.uri.resolve('assets/data/drivers/'),
  );

  final weekends = load2026Weekends(repoRoot);
  if (weekends.isEmpty) {
    stderr.writeln('Geen weekends met race_results.json onder assets/data/2026/.');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    '2026-events: ${weekends.map((w) => w.eventSlug).join(", ")} '
    '(idempotent: baseline = laatste seizoen < $_targetYear)',
  );

  final encoder = JsonEncoder.withIndent('  ');
  var files = 0;
  var touched = 0;

  for (final entity in driversDir.listSync(followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;
    files++;

    final doc = json.decode(entity.readAsStringSync());
    if (doc is! Map<String, dynamic>) continue;

    final seasons = doc['seasons'];
    if (seasons is! List) continue;

    final baselineRaw = _baselineRecord(seasons);
    final baseline =
        baselineRaw ?? _zeroCareerBaseline();
    final usedSyntheticBaseline = baselineRaw == null;

    final rec2026 = _seasonRecordMutable(doc, _targetYear);
    if (rec2026 == null) {
      continue;
    }

    final number = (rec2026['number'] as num?)?.toInt();
    if (number == null) continue;

    final c = computeForNumber(number, weekends);

    final bWins = (baseline['wins'] as num?)?.toInt() ?? 0;
    final bP2 = (baseline['podiums_2nd'] as num?)?.toInt() ?? 0;
    final bP3 = (baseline['podiums_3rd'] as num?)?.toInt() ?? 0;
    final bPod = (baseline['podiums'] as num?)?.toInt() ?? 0;
    final bPoles = (baseline['poles'] as num?)?.toInt() ?? 0;
    final bFl = (baseline['fastest_laps'] as num?)?.toInt() ?? 0;
    final bPts = (baseline['total_points'] as num?)?.toDouble() ?? 0;
    final bLaps = (baseline['laps_raced'] as num?)?.toInt() ?? 0;
    final bStarts = (baseline['starts'] as num?)?.toInt() ?? 0;
    final bDnf = (baseline['dnfs'] as num?)?.toInt() ?? 0;
    final bDsq = (baseline['dsqs'] as num?)?.toInt() ?? 0;
    final bDnq = (baseline['dnqs'] as num?)?.toInt() ?? 0;
    final bHt = (baseline['hat_tricks'] as num?)?.toInt() ?? 0;

    final hfBase =
        baseline['highest_finish'] is String
            ? baseline['highest_finish'] as String
            : '99e (x0)';
    final hgBase =
        baseline['highest_grid'] is String
            ? baseline['highest_grid'] as String
            : '99e (x0)';

    final out = Map<String, dynamic>.from(rec2026);
    out['wins'] = bWins + c.wins;
    out['podiums_2nd'] = bP2 + c.p2;
    out['podiums_3rd'] = bP3 + c.p3;
    out['podiums'] = bPod + c.podiums;
    out['poles'] = bPoles + c.poles;
    out['fastest_laps'] = bFl + c.fastestLaps;
    out['total_points'] = bPts + c.pointsTotal;
    out['laps_raced'] = bLaps + c.lapsRaced;
    out['starts'] = bStarts + c.starts;
    out['dnfs'] = bDnf + c.dnfs;
    out['dsqs'] = bDsq + c.dsqs;
    out['dnqs'] = bDnq + c.dnqs;
    out['hat_tricks'] = bHt + c.hatTricks;

    // Championships: session data cannot prove titles — copy baseline.
    out['championships'] = baseline['championships'];
    out['championship_years'] =
        baseline['championship_years'] is List
            ? List<dynamic>.from(baseline['championship_years'] as List)
            : <dynamic>[];

    // Laps led: not in JSON — keep baseline career value.
    out['laps_led'] = baseline['laps_led'];

    out['highest_finish'] = mergeTierStat(
      baselineString: hfBase,
      seasonPositions: c.raceFinishes,
      baselineAtPlace: (p) => _baselineRaceAtPlace(baseline, p),
    );
    out['highest_grid'] = mergeTierStat(
      baselineString: hgBase,
      seasonPositions: c.qualiPositions,
      baselineAtPlace: (p) => _baselineGridAtPlace(baseline, p),
    );

    // Seizoenspunten (zoals in Driver.points)
    out['points'] = c.pointsTotal;

    final pps = _copyPointsPerSeason(baseline);
    pps['$_targetYear'] = c.pointsTotal;
    out['points_per_season'] = pps;

    out['merge_meta_2026'] = {
      'schema': 1,
      'baseline_season_year': usedSyntheticBaseline
          ? null
          : _baselineYearFromSeasons(seasons),
      'baseline_is_synthetic_zero': usedSyntheticBaseline,
      'events_scanned': weekends.map((w) => w.eventSlug).toList(),
      'computed_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (dryRun) {
      stdout.writeln(
        '[dry-run] #$number ${out['name']}: points +${c.pointsTotal.toStringAsFixed(1)} '
        'HT+${c.hatTricks} …',
      );
      touched++;
      continue;
    }

    _replaceSeasonRecord(doc, _targetYear, out);
    entity.writeAsStringSync('${encoder.convert(doc)}\n');
    touched++;
    final blY = _baselineYearFromSeasons(seasons);
    final blTag =
        usedSyntheticBaseline ? 'synthetic_zero' : 'baseline<$blY';
    stdout.writeln(
      'OK #$number ${out['name']}: +${c.pointsTotal.toStringAsFixed(1)} pts '
      '(${c.wins}W ${c.p2}P2 ${c.p3}P3 ${c.poles}pole ${c.fastestLaps}FL '
      '${c.hatTricks}HT) $blTag',
    );
  }

  stdout.writeln(
    dryRun ? 'Dry-run: $touched driver(s) zouden worden bijgewerkt ($files files).'
        : 'Klaar: $touched driver(s) bijgewerkt ($files JSON-bestanden).',
  );
}

int? _baselineYearFromSeasons(List<dynamic> seasons) {
  var bestY = -1;
  for (final s in seasons) {
    if (s is! Map) continue;
    final y = s['season_year'];
    if (y is int && y < _targetYear && y > bestY) bestY = y;
  }
  return bestY < 0 ? null : bestY;
}
