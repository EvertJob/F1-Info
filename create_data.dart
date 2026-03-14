import 'dart:convert';
import 'dart:io';

/// Usage:
///   dart create_data.dart <round> [<session>]
///
/// - <round>: verplicht, bv. 2
/// - <session>: optioneel, bv. FP1, FP2, FP3, Q, SQ, S, R
///
/// Dit script combineert losse data-bestanden (weather, race control, results, sessions)
/// tot één JSON-bestand per sessie.

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Gebruik: dart create_data.dart <round> [<session>]');
    exit(1);
  }
  final round = args[0];
  final sessionFilter = args.length > 1 ? args[1].toUpperCase() : null;

  // Mapping van korte codes naar bestandsnamen
  const sessionMap = {
    'FP1': 'Practice 1',
    'FP2': 'Practice 2',
    'FP3': 'Practice 3',
    'Q': 'Qualifying',
    'SQ': 'Sprint Qualifying',
    'S': 'Sprint',
    'R': 'Race',
  };

  // Bestandslocaties
  final base = 'data/results';
  final rcFile = File('$base/race_control_2026_round_$round.json');
  final resultsFile = File('$base/results_2026_round_$round.json');
  final sessionsFile = File('$base/sessions_2026_round_$round.json');
  final weatherFile = File('$base/weather_2026_round_$round.json');

  if (!rcFile.existsSync() || !resultsFile.existsSync() || !sessionsFile.existsSync() || !weatherFile.existsSync()) {
    print('Niet alle benodigde bronbestanden gevonden voor ronde $round.');
    exit(1);
  }

  final rcData = jsonDecode(await rcFile.readAsString());
  final resultsData = jsonDecode(await resultsFile.readAsString());
  final sessionsData = jsonDecode(await sessionsFile.readAsString());
  final weatherData = jsonDecode(await weatherFile.readAsString());

  // Bepaal beschikbare sessies
  final List<String> allSessions = (rcData['availableSessions'] ?? weatherData['availableSessions'] ?? [] as List).cast<String>();
  final sessionsToProcess = sessionFilter != null
      ? [sessionMap[sessionFilter] ?? sessionFilter]
      : allSessions;

  for (final session in sessionsToProcess) {
    print('Verwerken: $session');
    // Race control messages filteren op sessie
    final rcMessages = (rcData['messages'] as List)
        .where((m) => (m['sessionName'] ?? '').toString().toUpperCase() == session.toString().toUpperCase())
        .toList();
    // Weather per sessie
    final weatherSession = (weatherData['sessions'] ?? {})[session] ?? {};
    // Session driver info
    final sessionDrivers = (sessionsData['sessions'] ?? {})[session] ?? [];
    // Results per sessie (voor Race, maar mogelijk ook voor andere sessies)
    final resultsDrivers = (resultsData is List)
        ? resultsData
        : ((resultsData['sessions'] ?? {})[session] ?? []);

    // Combineer per driver
    final List<Map<String, dynamic>> drivers = [];
    final Map<String, dynamic> driverMap = {};
    for (final d in sessionDrivers) {
      driverMap[d['driver']] = Map<String, dynamic>.from(d);
    }
    for (final d in resultsDrivers) {
      final name = d['driver'] ?? d['name'];
      if (name == null) continue;
      driverMap[name] = {...?driverMap[name], ...Map<String, dynamic>.from(d)};
    }
    drivers.addAll(driverMap.values.cast<Map<String, dynamic>>());

    // Bouw het gecombineerde sessie-object
    final sessionObj = {
      'season': rcData['season'] ?? weatherData['season'],
      'round': rcData['round'] ?? weatherData['round'],
      'raceName': rcData['raceName'] ?? weatherData['raceName'],
      'session': session,
      'sessionKey': weatherSession['sessionKey'],
      'weather': weatherSession,
      'raceControlMessages': rcMessages,
      'drivers': drivers,
    };

    // Schrijf naar bestand
    final outDir = Directory('data/sessions_combined');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File('${outDir.path}/2026_round_${round}_${session.replaceAll(' ', '_').toLowerCase()}.json');
    await outFile.writeAsString(JsonEncoder.withIndent('  ').convert(sessionObj));
    print('Gemaakt: ${outFile.path}');
  }
}
