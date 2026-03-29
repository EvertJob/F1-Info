// @deprecated Gebruik `merge_driver_stats_from_2026.dart` — dekt alle statistieken
// + idempotente baseline. Dit bestand blijft alleen voor referentie.
//
// Updates `highest_finish` in assets/data/drivers/*.json using classified finishes
// from assets/data/2026/*/race_results.json. Does not modify lib/f1_data.dart.
//
// Run from repo root:
//   dart run tool/update_driver_json_highest_finish_2026.dart
//
// Logic:
// - Parse existing "Ne (xM)" → best place N, count M.
// - Collect all finishPosition (int >= 1) per driver number from 2026 races.
// - newBest = min(N, min(2026 finishes) if any, else N).
// - If newBest == N: newCount = M + (2026 finishes equal to N).
// - If newBest < N: improved tier → newCount = baselineField + (2026 finishes equal to newBest),
//   where baseline is wins (P1), podiums_2nd (P2), podiums_3rd (P3); else 0.

import 'dart:convert';
import 'dart:io';

final _finishRe = RegExp(r'^(\d+)e \(x(\d+)\)\s*$');

int? _parseHighestPlace(String s) {
  final m = _finishRe.firstMatch(s.trim());
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

int? _parseHighestCount(String s) {
  final m = _finishRe.firstMatch(s.trim());
  if (m == null) return null;
  return int.tryParse(m.group(2)!);
}

String _formatHighestFinish(int place, int count) => '${place}e (x$count)';

/// Loads 2026 race folders → driverNumber → list of classified finishes (in scan order).
Map<int, List<int>> load2026RaceFinishes(Directory repoRoot) {
  final yearDir = Directory.fromUri(repoRoot.uri.resolve('assets/data/2026/'));
  if (!yearDir.existsSync()) {
    stderr.writeln('No ${yearDir.path}');
    return {};
  }

  final byNumber = <int, List<int>>{};

  for (final entity in yearDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final raceFile = File('${entity.path}/race_results.json');
    if (!raceFile.existsSync()) continue;

    final dynamic decoded = json.decode(raceFile.readAsStringSync());
    if (decoded is! Map) continue;
    final results = decoded['results'];
    if (results is! List) continue;

    for (final row in results) {
      if (row is! Map) continue;
      final numRaw = row['driverNumber'];
      final posRaw = row['finishPosition'];
      if (numRaw is! int) continue;
      if (posRaw == null) continue;
      if (posRaw is! int) continue;
      if (posRaw < 1) continue;
      byNumber.putIfAbsent(numRaw, () => []).add(posRaw);
    }
  }

  return byNumber;
}

Map<String, dynamic>? _season2026(Map<String, dynamic> doc) {
  final seasons = doc['seasons'];
  if (seasons is! List) return null;
  for (final s in seasons) {
    if (s is! Map) continue;
    if (s['season_year'] == 2026) {
      return Map<String, dynamic>.from(s);
    }
  }
  return null;
}

Map<String, dynamic> _record(Map<String, dynamic> season2026) {
  final r = season2026['record'];
  if (r is Map<String, dynamic>) return r;
  if (r is Map) return Map<String, dynamic>.from(r);
  throw StateError('2026 season has no record map');
}

/// Baseline count at [place] from career aggregate fields (pre–extra-2026 logic).
int _baselineAtPlace(Map<String, dynamic> record, int place) {
  switch (place) {
    case 1:
      return (record['wins'] as num?)?.toInt() ?? 0;
    case 2:
      return (record['podiums_2nd'] as num?)?.toInt() ?? 0;
    case 3:
      return (record['podiums_3rd'] as num?)?.toInt() ?? 0;
    default:
      return 0;
  }
}

int _countInList(List<int> finishes, int place) =>
    finishes.where((p) => p == place).length;

String? computeNewHighestFinish({
  required String current,
  required List<int> finishes2026,
  required Map<String, dynamic> record,
}) {
  final oldPlace = _parseHighestPlace(current);
  final oldCount = _parseHighestCount(current);
  if (oldPlace == null || oldCount == null) return null;

  if (finishes2026.isEmpty) {
    return current;
  }

  final min2026 = finishes2026.reduce((a, b) => a < b ? a : b);
  final newBest = oldPlace < min2026 ? oldPlace : min2026;

  if (newBest == oldPlace) {
    final add = _countInList(finishes2026, oldPlace);
    if (add == 0) return current;
    return _formatHighestFinish(oldPlace, oldCount + add);
  }

  // Improved career best (lower place number = better).
  final base = _baselineAtPlace(record, newBest);
  final add = _countInList(finishes2026, newBest);
  final newCount = base + add;
  if (newCount < 1) {
    // Fallback: at least the 2026 finishes at newBest.
    return _formatHighestFinish(newBest, add < 1 ? 1 : add);
  }
  return _formatHighestFinish(newBest, newCount);
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final repoRoot = Directory.current;
  final driversDir = Directory.fromUri(
    repoRoot.uri.resolve('assets/data/drivers/'),
  );

  if (!driversDir.existsSync()) {
    stderr.writeln('Missing ${driversDir.path}');
    exitCode = 1;
    return;
  }

  final finishesByNumber = load2026RaceFinishes(repoRoot);
  if (finishesByNumber.isEmpty) {
    stderr.writeln('No 2026 race finishes found; nothing to do.');
    return;
  }

  final encoder = JsonEncoder.withIndent('  ');
  var updatedFiles = 0;
  var updatedRecords = 0;

  for (final entity in driversDir.listSync(followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;

    final raw = entity.readAsStringSync();
    final dynamic doc = json.decode(raw);
    if (doc is! Map<String, dynamic>) continue;

    final seasons = doc['seasons'];
    if (seasons is! List) continue;

    var changed = false;
    final newSeasons = <dynamic>[];

    for (final s in seasons) {
      if (s is! Map) {
        newSeasons.add(s);
        continue;
      }
      final sm = Map<String, dynamic>.from(s);
      if (sm['season_year'] != 2026) {
        newSeasons.add(sm);
        continue;
      }

      final rec = _record(sm);
      final number = (rec['number'] as num?)?.toInt();
      if (number == null) {
        newSeasons.add(sm);
        continue;
      }

      final finishes = finishesByNumber[number] ?? const <int>[];
      final hf = rec['highest_finish'];
      if (hf is! String) {
        newSeasons.add(sm);
        continue;
      }

      final next = computeNewHighestFinish(
        current: hf,
        finishes2026: finishes,
        record: rec,
      );

      if (next != null && next != hf) {
        rec['highest_finish'] = next;
        sm['record'] = rec;
        changed = true;
        updatedRecords++;
        stdout.writeln('${entity.uri.pathSegments.last}: $hf → $next (#$number)');
      }
      newSeasons.add(sm);
    }

    if (changed && !dryRun) {
      doc['seasons'] = newSeasons;
      entity.writeAsStringSync('${encoder.convert(doc)}\n');
      updatedFiles++;
    } else if (changed && dryRun) {
      updatedFiles++;
    }
  }

  stdout.writeln(
    dryRun
        ? 'Dry-run: would update $updatedRecords season(s) in $updatedFiles file(s).'
        : 'Updated $updatedRecords 2026 record(s) in $updatedFiles file(s).',
  );
}
