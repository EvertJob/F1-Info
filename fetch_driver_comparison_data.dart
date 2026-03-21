import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _jolpicaBaseUrl = 'https://api.jolpi.ca/ergast/f1';
const _defaultOutputDirectory = 'data/results/drivers';
const _defaultStartYear = 2025;
const _defaultEndYear = 2017;

Future<void> main(List<String> arguments) async {
  try {
    final config = DriverComparisonCliConfig.parse(arguments);

    if (config.showHelp) {
      _printUsage();
      return;
    }

    final fetcher = DriverComparisonDataFetcher(http.Client());
    try {
      final export = await fetcher.fetch(
        startYear: config.startYear,
        endYear: config.endYear,
      );

      final years = export['years'] as Map<String, dynamic>? ?? {};
      final dir = Directory(config.outputDirectory);
      if (!await dir.exists()) await dir.create(recursive: true);

      for (final entry in years.entries) {
        final year = int.tryParse(entry.key);
        if (year == null) continue;
        final yearData = entry.value as Map<String, dynamic>;
        final perYear = <String, dynamic>{
          'year': year,
          ...yearData,
        };
        final file = File('${dir.path}${Platform.pathSeparator}driver_comparison_stats_$year.json');
        await file.writeAsString('${const JsonEncoder.withIndent('  ').convert(perYear)}\n');
        stdout.writeln('Saved ${file.path}');
      }
    } finally {
      fetcher.close();
    }
  } on DriverComparisonCliUsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    _printUsage();
    exitCode = 64;
  } on SocketException catch (error) {
    stderr.writeln(
      'Network error while fetching comparison data: ${error.message}',
    );
    exitCode = 1;
  } on HttpException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not write JSON file: ${error.message}');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr.writeln('Unexpected error: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

void _printUsage() {
  stdout.writeln('Driver comparison seasonal data fetcher');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run fetch_driver_comparison_data.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --start-year <year>    Highest season year to include. Defaults to $_defaultStartYear.',
  );
  stdout.writeln(
    '  --end-year <year>      Lowest season year to include. Defaults to $_defaultEndYear.',
  );
  stdout.writeln(
    '  --output-dir <path>    Directory for per-year JSON files. Defaults to $_defaultOutputDirectory.',
  );
  stdout.writeln('  --help                 Show this help message.');
  stdout.writeln('');
  stdout.writeln('Example:');
  stdout.writeln(
    '  dart run fetch_driver_comparison_data.dart --start-year 2025 --end-year 2017',
  );
}

class DriverComparisonCliConfig {
  const DriverComparisonCliConfig({
    required this.startYear,
    required this.endYear,
    required this.outputDirectory,
    required this.showHelp,
  });

  final int startYear;
  final int endYear;
  final String outputDirectory;
  final bool showHelp;

  factory DriverComparisonCliConfig.parse(List<String> arguments) {
    var startYear = _defaultStartYear;
    var endYear = _defaultEndYear;
    var outputDirectory = _defaultOutputDirectory;
    var showHelp = false;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];

      if (argument == '--help' || argument == '-h') {
        showHelp = true;
        continue;
      }

      if (argument.startsWith('--start-year=')) {
        startYear = _parsePositiveInt(argument.split('=').last, 'start-year');
        continue;
      }
      if (argument == '--start-year') {
        if (index + 1 >= arguments.length) {
          throw const DriverComparisonCliUsageException(
            'Missing value for --start-year.',
          );
        }
        startYear = _parsePositiveInt(arguments[++index], 'start-year');
        continue;
      }

      if (argument.startsWith('--end-year=')) {
        endYear = _parsePositiveInt(argument.split('=').last, 'end-year');
        continue;
      }
      if (argument == '--end-year') {
        if (index + 1 >= arguments.length) {
          throw const DriverComparisonCliUsageException(
            'Missing value for --end-year.',
          );
        }
        endYear = _parsePositiveInt(arguments[++index], 'end-year');
        continue;
      }

      if (argument.startsWith('--output-dir=')) {
        outputDirectory = argument.split('=').last.trim();
        continue;
      }
      if (argument == '--output-dir') {
        if (index + 1 >= arguments.length) {
          throw const DriverComparisonCliUsageException(
            'Missing value for --output-dir.',
          );
        }
        outputDirectory = arguments[++index].trim();
        continue;
      }

      throw DriverComparisonCliUsageException('Unknown argument: $argument');
    }

    return DriverComparisonCliConfig(
      startYear: startYear,
      endYear: endYear,
      outputDirectory: outputDirectory,
      showHelp: showHelp,
    );
  }
}

int _parsePositiveInt(String value, String label) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    throw DriverComparisonCliUsageException('Invalid $label: $value');
  }
  return parsed;
}

class DriverComparisonCliUsageException implements Exception {
  const DriverComparisonCliUsageException(this.message);
  final String message;
}

class DriverComparisonDataFetcher {
  DriverComparisonDataFetcher(this._client);

  final http.Client _client;

  void close() => _client.close();

  Future<Map<String, dynamic>> fetch({
    required int startYear,
    required int endYear,
  }) async {
    final highest = startYear >= endYear ? startYear : endYear;
    final lowest = startYear >= endYear ? endYear : startYear;
    final years = <String, dynamic>{};

    for (var year = highest; year >= lowest; year--) {
      stdout.writeln('Fetching driver comparison data for $year...');
      years['$year'] = await _fetchYear(year);
    }

    return <String, dynamic>{
      'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'source': 'Jolpica Ergast API',
      'startYear': highest,
      'endYear': lowest,
      'years': years,
    };
  }

  Future<Map<String, dynamic>> _fetchYear(int year) async {
    final standingsUri = Uri.parse(
      '$_jolpicaBaseUrl/$year/driverStandings.json',
    );
    final constructorStandingsUri = Uri.parse(
      '$_jolpicaBaseUrl/$year/constructorStandings.json',
    );
    final standingsResponse = await _getWithRetry(standingsUri);
    final constructorStandingsResponse = await _getWithRetry(
      constructorStandingsUri,
    );

    if (standingsResponse.statusCode != 200) {
      throw HttpException(
        'Failed to fetch driver standings for $year (HTTP ${standingsResponse.statusCode}).',
      );
    }
    if (constructorStandingsResponse.statusCode != 200) {
      throw HttpException(
        'Failed to fetch constructor standings for $year (HTTP ${constructorStandingsResponse.statusCode}).',
      );
    }

    final standingsData =
        jsonDecode(standingsResponse.body) as Map<String, dynamic>;
    final constructorStandingsData =
        jsonDecode(constructorStandingsResponse.body) as Map<String, dynamic>;
    final standingsLists =
        standingsData['MRData']?['StandingsTable']?['StandingsLists']
            as List? ??
        const <dynamic>[];
    final constructorStandingsLists =
        constructorStandingsData['MRData']?['StandingsTable']?['StandingsLists']
            as List? ??
        const <dynamic>[];
    if (standingsLists.isEmpty) {
      return <String, dynamic>{
        'available': false,
        'drivers': <String, dynamic>{},
        'teams': <String, dynamic>{},
      };
    }

    final finalStandings = (standingsLists.first as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final finalConstructorStandings = constructorStandingsLists.isEmpty
        ? const <String, dynamic>{}
        : (constructorStandingsLists.first as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          );
    final driverStandings =
        finalStandings['DriverStandings'] as List? ?? const <dynamic>[];
    final constructorStandings =
        finalConstructorStandings['ConstructorStandings'] as List? ??
        const <dynamic>[];
    final finalRound = int.tryParse(finalStandings['round']?.toString() ?? '');
    final raceNamesByRound = await _fetchRaceNamesByRound(year);
    final pointsByRound = await _fetchPointsByRound(
      year: year,
      finalRound: finalRound,
    );
    final constructorPointsByRound = await _fetchConstructorPointsByRound(
      year: year,
      finalRound: finalRound,
    );

    final seasonResultsUri = Uri.parse(
      '$_jolpicaBaseUrl/$year/results.json?limit=1000',
    );
    final seasonQualifyingUri = Uri.parse(
      '$_jolpicaBaseUrl/$year/qualifying.json?limit=1000',
    );
    final seasonResultsResponse = await _getWithRetry(seasonResultsUri);
    final seasonQualifyingResponse = await _getWithRetry(seasonQualifyingUri);

    if (seasonResultsResponse.statusCode != 200) {
      throw HttpException(
        'Failed to fetch season race results for $year (HTTP ${seasonResultsResponse.statusCode}).',
      );
    }
    if (seasonQualifyingResponse.statusCode != 200) {
      throw HttpException(
        'Failed to fetch season qualifying results for $year (HTTP ${seasonQualifyingResponse.statusCode}).',
      );
    }

    final seasonResultsData =
        jsonDecode(seasonResultsResponse.body) as Map<String, dynamic>;
    final seasonQualifyingData =
        jsonDecode(seasonQualifyingResponse.body) as Map<String, dynamic>;
    final resultEntriesByDriver = _buildResultEntriesByDriver(
      seasonResultsData,
    );
    final qualifyingEntriesByDriver = _buildQualifyingEntriesByDriver(
      seasonQualifyingData,
    );
    final resultEntriesByConstructor = _buildResultEntriesByConstructor(
      seasonResultsData,
    );
    final qualifyingEntriesByConstructor = _buildQualifyingEntriesByConstructor(
      seasonQualifyingData,
    );
    final drivers = <String, dynamic>{};
    final teams = <String, dynamic>{};

    for (final entry in driverStandings.whereType<Map>()) {
      final driverData = entry['Driver'] as Map? ?? const <String, dynamic>{};
      final driverId = driverData['driverId']?.toString();
      final driverName =
          '${driverData['givenName'] ?? ''} ${driverData['familyName'] ?? ''}'
              .trim();
      if (driverId == null || driverId.isEmpty || driverName.isEmpty) {
        continue;
      }

      final points = double.tryParse(entry['points']?.toString() ?? '') ?? 0.0;
      final stats = _buildDriverYearStats(
        driverId: driverId,
        points: points,
        resultEntries:
            resultEntriesByDriver[driverId] ?? const <Map<String, dynamic>>[],
        qualifyingEntries:
            qualifyingEntriesByDriver[driverId] ??
            const <Map<String, dynamic>>[],
        pointsByRound: pointsByRound[driverId] ?? const <int, double>{},
        raceNamesByRound: raceNamesByRound,
      );
      drivers[driverName] = stats;
    }

    for (final entry in constructorStandings.whereType<Map>()) {
      final constructorData =
          entry['Constructor'] as Map? ?? const <String, dynamic>{};
      final constructorId = constructorData['constructorId']?.toString();
      final constructorName = constructorData['name']?.toString() ?? '';
      if (constructorId == null ||
          constructorId.isEmpty ||
          constructorName.isEmpty) {
        continue;
      }

      final points = double.tryParse(entry['points']?.toString() ?? '') ?? 0.0;
      teams[constructorName] = _buildTeamYearStats(
        constructorId: constructorId,
        points: points,
        resultEntries:
            resultEntriesByConstructor[constructorId] ??
            const <Map<String, dynamic>>[],
        qualifyingEntries:
            qualifyingEntriesByConstructor[constructorId] ??
            const <Map<String, dynamic>>[],
        pointsByRound:
            constructorPointsByRound[constructorId] ?? const <int, double>{},
        raceNamesByRound: raceNamesByRound,
      );
    }

    return <String, dynamic>{
      'available': true,
      'drivers': drivers,
      'teams': teams,
    };
  }

  Map<String, dynamic> _buildDriverYearStats({
    required String driverId,
    required double points,
    required List<Map<String, dynamic>> resultEntries,
    required List<Map<String, dynamic>> qualifyingEntries,
    required Map<int, double> pointsByRound,
    required Map<int, String> raceNamesByRound,
  }) {
    final sortedResultEntries = [...resultEntries]
      ..sort(
        (left, right) =>
            (left['round'] as int).compareTo(right['round'] as int),
      );
    final sortedQualifyingEntries = [...qualifyingEntries]
      ..sort(
        (left, right) =>
            (left['round'] as int).compareTo(right['round'] as int),
      );

    var wins = 0;
    var podiums = 0;
    var fastestLaps = 0;
    var dnfs = 0;
    int? highestFinish;
    int? highestGrid;
    final pointsHistory = <Map<String, dynamic>>[];
    final raceNameFromResults = <int, String>{
      for (final entry in sortedResultEntries)
        entry['round'] as int: entry['raceName'] as String,
    };

    for (final resultEntry in sortedResultEntries) {
      final result = resultEntry['result'] as Map<String, dynamic>;
      final finishPosition = int.tryParse(result['position']?.toString() ?? '');
      if (finishPosition != null) {
        if (finishPosition == 1) {
          wins += 1;
        }
        if (finishPosition <= 3) {
          podiums += 1;
        }
        highestFinish = highestFinish == null
            ? finishPosition
            : _minInt(highestFinish, finishPosition);
      }

      final fastestLapRank = result['FastestLap'] is Map
          ? (result['FastestLap'] as Map)['rank']?.toString()
          : null;
      if (fastestLapRank == '1') {
        fastestLaps += 1;
      }

      if (_isRetirementStatus(result['status']?.toString() ?? '')) {
        dnfs += 1;
      }

      final grid = int.tryParse(result['grid']?.toString() ?? '');
      if (grid != null && grid > 0) {
        highestGrid = highestGrid == null ? grid : _minInt(highestGrid, grid);
      }
    }

    final sortedRounds = pointsByRound.keys.toList()..sort();
    for (final round in sortedRounds) {
      pointsHistory.add(<String, dynamic>{
        'round': round,
        'raceName':
            raceNamesByRound[round] ??
            raceNameFromResults[round] ??
            'Round $round',
        'points': pointsByRound[round] ?? 0.0,
      });
    }

    var poles = 0;
    for (final qualifyingEntry in sortedQualifyingEntries) {
      final qualifyingResult =
          qualifyingEntry['result'] as Map<String, dynamic>;
      final qualifyingPosition = int.tryParse(
        qualifyingResult['position']?.toString() ?? '',
      );
      if (qualifyingPosition != null && qualifyingPosition > 0) {
        if (qualifyingPosition == 1) {
          poles += 1;
        }
        highestGrid = highestGrid == null
            ? qualifyingPosition
            : _minInt(highestGrid, qualifyingPosition);
      }
    }

    final starts = sortedResultEntries.length;
    final dnfPercentage = starts == 0 ? 0.0 : (dnfs / starts) * 100.0;
    final winRate = starts == 0 ? 0.0 : (wins / starts) * 100.0;

    return <String, dynamic>{
      'driverId': driverId,
      'points': points,
      'pointsByRace': pointsHistory,
      'poles': poles,
      'fastestLaps': fastestLaps,
      'dnfPercentage': dnfPercentage,
      'podiums': podiums,
      'highestFinish': highestFinish == null ? '-' : 'P$highestFinish',
      'highestGrid': highestGrid == null ? '-' : 'P$highestGrid',
      'winRate': winRate,
    };
  }

  Map<String, dynamic> _buildTeamYearStats({
    required String constructorId,
    required double points,
    required List<Map<String, dynamic>> resultEntries,
    required List<Map<String, dynamic>> qualifyingEntries,
    required Map<int, double> pointsByRound,
    required Map<int, String> raceNamesByRound,
  }) {
    final sortedResultEntries = [...resultEntries]
      ..sort(
        (left, right) =>
            (left['round'] as int).compareTo(right['round'] as int),
      );
    final sortedQualifyingEntries = [...qualifyingEntries]
      ..sort(
        (left, right) =>
            (left['round'] as int).compareTo(right['round'] as int),
      );

    var wins = 0;
    var podiums = 0;
    var poles = 0;
    var fastestLaps = 0;
    var dnfs = 0;
    var oneTwo = 0;
    int? highestFinish;
    final pointsHistory = <Map<String, dynamic>>[];
    final raceNameFromResults = <int, String>{
      for (final entry in sortedResultEntries)
        entry['round'] as int: entry['raceName'] as String,
    };

    for (final resultEntry in sortedResultEntries) {
      final results = (resultEntry['results'] as List<Map<String, dynamic>>)
        ..sort((left, right) {
          final leftPosition =
              int.tryParse(left['position']?.toString() ?? '') ?? 999;
          final rightPosition =
              int.tryParse(right['position']?.toString() ?? '') ?? 999;
          return leftPosition.compareTo(rightPosition);
        });
      final finishPositions = <int>[];

      for (final result in results) {
        final finishPosition = int.tryParse(
          result['position']?.toString() ?? '',
        );
        if (finishPosition != null) {
          finishPositions.add(finishPosition);
          if (finishPosition == 1) {
            wins += 1;
          }
          if (finishPosition <= 3) {
            podiums += 1;
          }
          highestFinish = highestFinish == null
              ? finishPosition
              : _minInt(highestFinish, finishPosition);
        }

        final fastestLapRank = result['FastestLap'] is Map
            ? (result['FastestLap'] as Map)['rank']?.toString()
            : null;
        if (fastestLapRank == '1') {
          fastestLaps += 1;
        }

        if (_isRetirementStatus(result['status']?.toString() ?? '')) {
          dnfs += 1;
        }
      }

      if (finishPositions.contains(1) && finishPositions.contains(2)) {
        oneTwo += 1;
      }
    }

    for (final qualifyingEntry in sortedQualifyingEntries) {
      final results = qualifyingEntry['results'] as List<Map<String, dynamic>>;
      if (results.any(
        (result) => int.tryParse(result['position']?.toString() ?? '') == 1,
      )) {
        poles += 1;
      }
    }

    final sortedRounds = pointsByRound.keys.toList()..sort();
    for (final round in sortedRounds) {
      pointsHistory.add(<String, dynamic>{
        'round': round,
        'raceName':
            raceNamesByRound[round] ??
            raceNameFromResults[round] ??
            'Round $round',
        'points': pointsByRound[round] ?? 0.0,
      });
    }

    final starts = sortedResultEntries.fold<int>(
      0,
      (total, entry) =>
          total + (entry['results'] as List<Map<String, dynamic>>).length,
    );
    final rounds = sortedResultEntries.length;
    final dnfPercentage = starts == 0 ? 0.0 : (dnfs / starts) * 100.0;
    final winRate = rounds == 0 ? 0.0 : (wins / rounds) * 100.0;

    return <String, dynamic>{
      'constructorId': constructorId,
      'points': points,
      'pointsByRace': pointsHistory,
      'wins': wins,
      'poles': poles,
      'fastestLaps': fastestLaps,
      'dnfPercentage': dnfPercentage,
      'podiums': podiums,
      'oneTwo': oneTwo,
      'highestFinish': highestFinish == null ? '-' : 'P$highestFinish',
      'winRate': winRate,
    };
  }

  Future<Map<int, String>> _fetchRaceNamesByRound(int year) async {
    final scheduleUri = Uri.parse('$_jolpicaBaseUrl/$year.json?limit=100');
    final scheduleResponse = await _getWithRetry(scheduleUri);
    if (scheduleResponse.statusCode != 200) {
      throw HttpException(
        'Failed to fetch season schedule for $year (HTTP ${scheduleResponse.statusCode}).',
      );
    }

    final scheduleData =
        jsonDecode(scheduleResponse.body) as Map<String, dynamic>;
    final races =
        scheduleData['MRData']?['RaceTable']?['Races'] as List? ??
        const <dynamic>[];

    return <int, String>{
      for (final race in races.whereType<Map>())
        if (int.tryParse(race['round']?.toString() ?? '') != null)
          int.parse(race['round'].toString()):
              race['raceName']?.toString() ?? '-',
    };
  }

  Future<Map<String, Map<int, double>>> _fetchPointsByRound({
    required int year,
    required int? finalRound,
  }) async {
    if (finalRound == null || finalRound <= 0) {
      return const <String, Map<int, double>>{};
    }

    final pointsByRound = <String, Map<int, double>>{};

    for (var round = 1; round <= finalRound; round++) {
      final standingsUri = Uri.parse(
        '$_jolpicaBaseUrl/$year/$round/driverStandings.json',
      );
      final standingsResponse = await _getWithRetry(standingsUri);
      if (standingsResponse.statusCode != 200) {
        throw HttpException(
          'Failed to fetch round standings for $year round $round (HTTP ${standingsResponse.statusCode}).',
        );
      }

      final standingsData =
          jsonDecode(standingsResponse.body) as Map<String, dynamic>;
      final standingsLists =
          standingsData['MRData']?['StandingsTable']?['StandingsLists']
              as List? ??
          const <dynamic>[];
      if (standingsLists.isEmpty) {
        continue;
      }

      final driverStandings =
          standingsLists.first['DriverStandings'] as List? ?? const <dynamic>[];
      for (final entry in driverStandings.whereType<Map>()) {
        final driverData = entry['Driver'] as Map? ?? const <String, dynamic>{};
        final driverId = driverData['driverId']?.toString();
        if (driverId == null || driverId.isEmpty) {
          continue;
        }
        final points =
            double.tryParse(entry['points']?.toString() ?? '') ?? 0.0;
        pointsByRound.putIfAbsent(driverId, () => <int, double>{})[round] =
            points;
      }
    }

    return pointsByRound;
  }

  Future<Map<String, Map<int, double>>> _fetchConstructorPointsByRound({
    required int year,
    required int? finalRound,
  }) async {
    if (finalRound == null || finalRound <= 0) {
      return const <String, Map<int, double>>{};
    }

    final pointsByRound = <String, Map<int, double>>{};

    for (var round = 1; round <= finalRound; round++) {
      final standingsUri = Uri.parse(
        '$_jolpicaBaseUrl/$year/$round/constructorStandings.json',
      );
      final standingsResponse = await _getWithRetry(standingsUri);
      if (standingsResponse.statusCode != 200) {
        throw HttpException(
          'Failed to fetch constructor standings for $year round $round (HTTP ${standingsResponse.statusCode}).',
        );
      }

      final standingsData =
          jsonDecode(standingsResponse.body) as Map<String, dynamic>;
      final standingsLists =
          standingsData['MRData']?['StandingsTable']?['StandingsLists']
              as List? ??
          const <dynamic>[];
      if (standingsLists.isEmpty) {
        continue;
      }

      final constructorStandings =
          standingsLists.first['ConstructorStandings'] as List? ??
          const <dynamic>[];
      for (final entry in constructorStandings.whereType<Map>()) {
        final constructorData =
            entry['Constructor'] as Map? ?? const <String, dynamic>{};
        final constructorId = constructorData['constructorId']?.toString();
        if (constructorId == null || constructorId.isEmpty) {
          continue;
        }
        final points =
            double.tryParse(entry['points']?.toString() ?? '') ?? 0.0;
        pointsByRound.putIfAbsent(constructorId, () => <int, double>{})[round] =
            points;
      }
    }

    return pointsByRound;
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    const maxAttempts = 5;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final response = await _client
          .get(
            uri,
            headers: const <String, String>{
              'user-agent': 'f1hub-driver-comparison-export/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 429 || attempt == maxAttempts) {
        return response;
      }

      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      final delaySeconds = retryAfter ?? attempt * 2;
      await Future<void>.delayed(Duration(seconds: delaySeconds));
    }

    throw HttpException('Request retries exhausted for $uri');
  }
}

Map<String, List<Map<String, dynamic>>> _buildResultEntriesByDriver(
  Map<String, dynamic> resultsData,
) {
  final resultRaces =
      resultsData['MRData']?['RaceTable']?['Races'] as List? ??
      const <dynamic>[];
  final entriesByDriver = <String, List<Map<String, dynamic>>>{};

  for (final race in resultRaces.whereType<Map>()) {
    final round = int.tryParse(race['round']?.toString() ?? '');
    final raceName = race['raceName']?.toString() ?? '';
    if (round == null) {
      continue;
    }

    final results = race['Results'] as List? ?? const <dynamic>[];
    for (final resultEntry in results.whereType<Map>()) {
      final driverData =
          resultEntry['Driver'] as Map? ?? const <String, dynamic>{};
      final driverId = driverData['driverId']?.toString();
      if (driverId == null || driverId.isEmpty) {
        continue;
      }

      entriesByDriver
          .putIfAbsent(driverId, () => <Map<String, dynamic>>[])
          .add(<String, dynamic>{
            'round': round,
            'raceName': raceName,
            'result': resultEntry.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          });
    }
  }

  return entriesByDriver;
}

Map<String, List<Map<String, dynamic>>> _buildQualifyingEntriesByDriver(
  Map<String, dynamic> qualifyingData,
) {
  final qualifyingRaces =
      qualifyingData['MRData']?['RaceTable']?['Races'] as List? ??
      const <dynamic>[];
  final entriesByDriver = <String, List<Map<String, dynamic>>>{};

  for (final race in qualifyingRaces.whereType<Map>()) {
    final round = int.tryParse(race['round']?.toString() ?? '');
    if (round == null) {
      continue;
    }

    final qualifyingResults =
        race['QualifyingResults'] as List? ?? const <dynamic>[];
    for (final qualifyingEntry in qualifyingResults.whereType<Map>()) {
      final driverData =
          qualifyingEntry['Driver'] as Map? ?? const <String, dynamic>{};
      final driverId = driverData['driverId']?.toString();
      if (driverId == null || driverId.isEmpty) {
        continue;
      }

      entriesByDriver
          .putIfAbsent(driverId, () => <Map<String, dynamic>>[])
          .add(<String, dynamic>{
            'round': round,
            'result': qualifyingEntry.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          });
    }
  }

  return entriesByDriver;
}

Map<String, List<Map<String, dynamic>>> _buildResultEntriesByConstructor(
  Map<String, dynamic> resultsData,
) {
  final resultRaces =
      resultsData['MRData']?['RaceTable']?['Races'] as List? ??
      const <dynamic>[];
  final entriesByConstructor = <String, List<Map<String, dynamic>>>{};

  for (final race in resultRaces.whereType<Map>()) {
    final round = int.tryParse(race['round']?.toString() ?? '');
    final raceName = race['raceName']?.toString() ?? '';
    if (round == null) {
      continue;
    }

    final groupedResults = <String, List<Map<String, dynamic>>>{};
    final results = race['Results'] as List? ?? const <dynamic>[];
    for (final resultEntry in results.whereType<Map>()) {
      final constructorData =
          resultEntry['Constructor'] as Map? ?? const <String, dynamic>{};
      final constructorId = constructorData['constructorId']?.toString();
      if (constructorId == null || constructorId.isEmpty) {
        continue;
      }

      groupedResults
          .putIfAbsent(constructorId, () => <Map<String, dynamic>>[])
          .add(
            resultEntry.map((key, value) => MapEntry(key.toString(), value)),
          );
    }

    for (final entry in groupedResults.entries) {
      entriesByConstructor
          .putIfAbsent(entry.key, () => <Map<String, dynamic>>[])
          .add(<String, dynamic>{
            'round': round,
            'raceName': raceName,
            'results': entry.value,
          });
    }
  }

  return entriesByConstructor;
}

Map<String, List<Map<String, dynamic>>> _buildQualifyingEntriesByConstructor(
  Map<String, dynamic> qualifyingData,
) {
  final qualifyingRaces =
      qualifyingData['MRData']?['RaceTable']?['Races'] as List? ??
      const <dynamic>[];
  final entriesByConstructor = <String, List<Map<String, dynamic>>>{};

  for (final race in qualifyingRaces.whereType<Map>()) {
    final round = int.tryParse(race['round']?.toString() ?? '');
    if (round == null) {
      continue;
    }

    final groupedResults = <String, List<Map<String, dynamic>>>{};
    final qualifyingResults =
        race['QualifyingResults'] as List? ?? const <dynamic>[];
    for (final qualifyingEntry in qualifyingResults.whereType<Map>()) {
      final constructorData =
          qualifyingEntry['Constructor'] as Map? ?? const <String, dynamic>{};
      final constructorId = constructorData['constructorId']?.toString();
      if (constructorId == null || constructorId.isEmpty) {
        continue;
      }

      groupedResults
          .putIfAbsent(constructorId, () => <Map<String, dynamic>>[])
          .add(
            qualifyingEntry.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
    }

    for (final entry in groupedResults.entries) {
      entriesByConstructor
          .putIfAbsent(entry.key, () => <Map<String, dynamic>>[])
          .add(<String, dynamic>{'round': round, 'results': entry.value});
    }
  }

  return entriesByConstructor;
}

int _minInt(int left, int right) => left < right ? left : right;

bool _isRetirementStatus(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized.isEmpty) {
    return false;
  }
  if (normalized == 'FINISHED' || normalized == 'DISQUALIFIED') {
    return false;
  }
  if (RegExp(r'^\+\d+\s+LAPS?$').hasMatch(normalized)) {
    return false;
  }
  return true;
}
