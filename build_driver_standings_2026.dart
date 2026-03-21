import 'dart:convert';
import 'dart:io';

/// Script om automatisch drivers_standings_2026.json te genereren op basis van race- en sprintresultaten.
/// Gebruik: dart run build_driver_standings_2026.dart <ronde1> <ronde2> ...
/// Voorbeeld: dart run build_driver_standings_2026.dart 1 2 3 4

void main(List<String> args) async {
    // Mapping van aliassen naar de gewenste naam
    const Map<String, String> driverAliases = {
      'Andrea Kimi Antonelli': 'Kimi Antonelli',
    };
  if (args.isEmpty) {
    print('Gebruik: dart run build_driver_standings_2026.dart <ronde1> <ronde2> ... [--rebuild]');
    exit(1);
  }

  final outputFile = File('data/results/drivers/drivers_standings_2026.json');
  bool doRebuild = args.contains('--rebuild');
  List<String> rounds = args.where((a) => a != '--rebuild').toList();

  List<dynamic> existingData = [];
  if (await outputFile.exists()) {
    try {
      existingData = jsonDecode(await outputFile.readAsString());
    } catch (e) {
      existingData = [];
    }
  }

  if (doRebuild) {
    // Verzamel alle bestaande rondes (bestanden) en sorteer op nummer
    final dir = Directory('data/results');
    final roundNumbers = <int>[];
    await for (final f in dir.list()) {
      final name = f.uri.pathSegments.last;
      final match = RegExp(r'results_2026_round_(\d+)\.json').firstMatch(name);
      if (match != null) {
        roundNumbers.add(int.parse(match.group(1)!));
      }
    }
    roundNumbers.sort();
    rounds = roundNumbers.map((n) => n.toString()).toList();
  }

  // Map ronde -> bestaande data (voor niet-overschreven rondes)
  final Map<String, dynamic> existingRounds = {
    for (final r in existingData)
      if (r is Map && r['round'] != null) r['round'].toString(): r
  };

  // Cumulatieve punten per coureur

  final Map<String, num> driverPoints = {}; // driver -> cumulatieve punten
  final Map<String, int?> driverLastFinish = {}; // driver -> laatste finish positie (int of null)
  final List<Map<String, dynamic>> output = [];

  int? parsePosition(dynamic pos) {
    if (pos == null) return null;
    final s = pos.toString().trim();
    if (s.isEmpty) return null;
    // Race: bv. 'P1 (-)', 'P4 (+3)', 'P10', 'DNF', 'DNS', '13', '1'
    final match = RegExp(r'P?(\d+)').firstMatch(s);
    if (match != null) return int.tryParse(match.group(1)!);
    if (s == 'DNF' || s == 'DNS') return null;
    return int.tryParse(s);
  }

  for (final round in rounds) {
    print('--- Ronde $round openen ---');
    final raceFile = File('data/results/results_2026_round_$round.json');
    final sessionsFile = File('data/results/sessions_2026_round_$round.json');
    final Map<String, Map<String, dynamic>> drivers = {};

    // SPRINT eerst (indien aanwezig)
    if (await sessionsFile.exists()) {
      final sessionsData = jsonDecode(await sessionsFile.readAsString());
      final sessions = sessionsData['sessions'] ?? {};
      final sprintList = sessions['Sprint'] ?? [];
      for (final entry in sprintList) {
        var driver = entry['driver_number']?.toString() ?? entry['driver']?.toString() ?? '-';
        driver = driverAliases[driver] ?? driver;
        final prevPoints = driverPoints[driver] ?? 0;
        final pointsEarned = entry['points'] == '-' ? 0 : num.tryParse(entry['points']?.toString() ?? '0') ?? 0;
        final prevFinish = driverLastFinish[driver];
        final positionFinish = parsePosition(entry['position'] ?? entry['position_finish']);
        int? positionChanged;
        if (prevFinish != null && positionFinish != null) {
          positionChanged = prevFinish - positionFinish;
        } else {
          positionChanged = null;
        }
        drivers[driver] ??= {};
        (drivers[driver] as Map)['Sprint'] = {
          'points_start': prevPoints,
          'points_finish': prevPoints + pointsEarned,
          'points_received': pointsEarned,
          'position_start': prevFinish,
          'position_finish': positionFinish,
          'position_changed': positionChanged == null ? null : (positionChanged >= 0 ? '+$positionChanged' : '$positionChanged'),
        };
        driverPoints[driver] = prevPoints + pointsEarned;
        driverLastFinish[driver] = positionFinish;
      }
    }

    // RACE daarna
    if (await raceFile.exists()) {
      final raceData = jsonDecode(await raceFile.readAsString());
      for (final entry in raceData) {
        var driver = entry['driver_number']?.toString() ?? entry['driver']?.toString() ?? '-';
        driver = driverAliases[driver] ?? driver;
        final prevPoints = driverPoints[driver] ?? 0;
        final pointsEarned = num.tryParse(entry['points']?.toString() ?? '0') ?? 0;
        final prevFinish = driverLastFinish[driver];
        // In results JSON is finish de finishpositie (kan bv. 'P1 (-)' zijn)
        final positionFinish = parsePosition(entry['finish'] ?? entry['position_current'] ?? entry['position']);
        int? positionChanged;
        if (prevFinish != null && positionFinish != null) {
          positionChanged = prevFinish - positionFinish;
        } else {
          positionChanged = null;
        }
        drivers[driver] ??= {};
        (drivers[driver] as Map)['Race'] = {
          'points_start': prevPoints,
          'points_finish': prevPoints + pointsEarned,
          'points_received': pointsEarned,
          'position_start': prevFinish,
          'position_finish': positionFinish,
          'position_changed': positionChanged == null ? null : (positionChanged >= 0 ? '+$positionChanged' : '$positionChanged'),
        };
        driverPoints[driver] = prevPoints + pointsEarned;
        driverLastFinish[driver] = positionFinish;
      }
    }

    output.add({
      'round': round,
      'drivers': drivers,
    });
    print('--- Ronde $round sluiten ---');
  }

  // Voeg bestaande rondes toe die niet in rebuild zitten
  final rebuiltRounds = {for (final r in rounds) r};
  for (final r in existingRounds.entries) {
    if (!rebuiltRounds.contains(r.key)) {
      output.add(r.value);
    }
  }

  // Maak standings-lijst
  final standings = driverPoints.entries
    .map((e) => {'driver': e.key, 'points': e.value})
    .toList()
    ..sort((a, b) => (b['points'] as num).compareTo(a['points'] as num));

  // Combineer standings en output in één JSON-object
  final result = {
    'standings': standings,
    'rounds': output,
  };

  await outputFile.writeAsString(JsonEncoder.withIndent('  ').convert(result));
  print('drivers_standings_2026.json bijgewerkt!');
  if (doRebuild) print('Volledig opnieuw opgebouwd!');
  return;
  // --- Einde rebuild ---

  // --- Oude niet-rebuild code ---
  // (deze code wordt niet meer bereikt bij --rebuild)
  // ...existing code...
}
