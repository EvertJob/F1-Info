import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _jolpicaBaseUrl = 'https://api.jolpi.ca/ergast/f1';
const _openF1BaseAuthority = 'api.openf1.org';
const _defaultOutputDirectory = 'data/results';

Future<void> main(List<String> arguments) async {
  try {
    final config = CliConfig.parse(arguments);

    if (config.showHelp) {
      _printUsage();
      return;
    }

    final fetcher = RaceDataFetcher(http.Client());
    try {
      final export = await fetcher.fetchRaceExport(
        year: config.year,
        round: config.round,
        format: config.format,
      );

      final outputFile = await _writeJsonFile(
        outputDirectory: config.outputDirectory,
        fileName: export.fileName,
        jsonData: export.jsonData,
      );
      final additionalFiles = <File>[];
      for (final extraFile in export.additionalFiles) {
        additionalFiles.add(
          await _writeJsonFile(
            outputDirectory: config.outputDirectory,
            fileName: extraFile.fileName,
            jsonData: extraFile.jsonData,
          ),
        );
      }

      stdout.writeln('Saved ${outputFile.path}');
      for (final file in additionalFiles) {
        stdout.writeln('Saved ${file.path}');
      }
      stdout.writeln(
        config.format == OutputFormat.app
            ? 'The file is app-compatible and can be parsed directly into RaceResultRow.'
            : 'The file uses the generic export structure.',
      );
    } finally {
      fetcher.close();
    }
  } on CliUsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    _printUsage();
    exitCode = 64;
  } on FetchException catch (error) {
    stderr.writeln('Failed to fetch race data: ${error.message}');
    exitCode = 1;
  } on SocketException catch (error) {
    stderr.writeln('Network error while fetching race data: ${error.message}');
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

Future<File> _writeJsonFile({
  required String outputDirectory,
  required String fileName,
  required Object jsonData,
}) async {
  final directory = Directory(outputDirectory);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(jsonData)}\n');
  return file;
}

void _printUsage() {
  stdout.writeln('Admin Data Fetcher for F1 race results');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run fetch_race_data.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --year <year>           Season year to query. Defaults to current year.',
  );
  stdout.writeln('  --round <round>         Specific race round to fetch.');
  stdout.writeln('  --format <app|generic>  Export format. Defaults to app.');
  stdout.writeln(
    '  --output-dir <path>     Directory for the JSON file. Defaults to $_defaultOutputDirectory.',
  );
  stdout.writeln('  --help                  Show this help message.');
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run fetch_race_data.dart');
  stdout.writeln('  dart run fetch_race_data.dart --year 2026 --round 2');
  stdout.writeln('  dart run fetch_race_data.dart --round=2 --format=app');
  stdout.writeln(
    '  dart run fetch_race_data.dart --round=2 --output-dir=./other-folder',
  );
}

enum OutputFormat { app, generic }

class CliConfig {
  const CliConfig({
    required this.year,
    required this.round,
    required this.format,
    required this.outputDirectory,
    required this.showHelp,
  });

  final int year;
  final int? round;
  final OutputFormat format;
  final String outputDirectory;
  final bool showHelp;

  factory CliConfig.parse(List<String> arguments) {
    var year = DateTime.now().year;
    int? round;
    var format = OutputFormat.app;
    var outputDirectory = _defaultOutputDirectory;
    var showHelp = false;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];

      if (argument == '--help' || argument == '-h') {
        showHelp = true;
        continue;
      }

      if (argument.startsWith('--year=')) {
        year = _parsePositiveInt(argument.split('=').last, 'year');
        continue;
      }

      if (argument == '--year') {
        if (index + 1 >= arguments.length) {
          throw const CliUsageException('Missing value for --year.');
        }
        year = _parsePositiveInt(arguments[++index], 'year');
        continue;
      }

      if (argument.startsWith('--round=')) {
        round = _parsePositiveInt(argument.split('=').last, 'round');
        continue;
      }

      if (argument == '--round') {
        if (index + 1 >= arguments.length) {
          throw const CliUsageException('Missing value for --round.');
        }
        round = _parsePositiveInt(arguments[++index], 'round');
        continue;
      }

      if (argument.startsWith('--format=')) {
        format = _parseFormat(argument.split('=').last);
        continue;
      }

      if (argument == '--format') {
        if (index + 1 >= arguments.length) {
          throw const CliUsageException('Missing value for --format.');
        }
        format = _parseFormat(arguments[++index]);
        continue;
      }

      if (argument.startsWith('--output-dir=')) {
        outputDirectory = argument.split('=').last.trim();
        if (outputDirectory.isEmpty) {
          throw const CliUsageException('Output directory cannot be empty.');
        }
        continue;
      }

      if (argument == '--output-dir') {
        if (index + 1 >= arguments.length) {
          throw const CliUsageException('Missing value for --output-dir.');
        }
        outputDirectory = arguments[++index].trim();
        if (outputDirectory.isEmpty) {
          throw const CliUsageException('Output directory cannot be empty.');
        }
        continue;
      }

      throw CliUsageException('Unknown argument: $argument');
    }

    return CliConfig(
      year: year,
      round: round,
      format: format,
      outputDirectory: outputDirectory,
      showHelp: showHelp,
    );
  }

  static int _parsePositiveInt(String rawValue, String fieldName) {
    final value = int.tryParse(rawValue.trim());
    if (value == null || value <= 0) {
      throw CliUsageException(
        'Invalid $fieldName: "$rawValue". Expected a positive integer.',
      );
    }
    return value;
  }

  static OutputFormat _parseFormat(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'app':
        return OutputFormat.app;
      case 'generic':
        return OutputFormat.generic;
      default:
        throw CliUsageException(
          'Invalid format: "$rawValue". Use "app" or "generic".',
        );
    }
  }
}

class RaceDataFetcher {
  RaceDataFetcher(this._client);

  final http.Client _client;
  final Map<String, List<Map<String, dynamic>>> _openF1Cache = {};
  DateTime? _lastOpenF1RequestAt;

  Future<RaceExport> fetchRaceExport({
    required int year,
    required int? round,
    required OutputFormat format,
  }) async {
    final targetRound = round ?? await _resolveLatestCompletedRound(year);
    final metadata = await _fetchRaceMetadata(year: year, round: targetRound);
    final weatherExport = await _fetchWeatherExport(metadata);
    final raceControlExport = await _fetchRaceControlExport(metadata);

    switch (format) {
      case OutputFormat.app:
        final sessionOverviewExport = await _fetchSessionOverviewExport(
          metadata,
        );
        final rows = await _fetchAppCompatibleRows(metadata);
        return RaceExport(
          fileName: metadata.fileName,
          jsonData: rows.map((row) => row.toJson()).toList(growable: false),
          additionalFiles: <ExportFile>[
            ExportFile(
              fileName: metadata.sessionsFileName,
              jsonData: {
                'season': metadata.season,
                'round': metadata.round,
                'raceName': metadata.raceName,
                'sessions': sessionOverviewExport,
              },
            ),
            ExportFile(
              fileName: metadata.weatherFileName,
              jsonData: weatherExport,
            ),
            ExportFile(
              fileName: metadata.raceControlFileName,
              jsonData: raceControlExport,
            ),
          ],
        );
      case OutputFormat.generic:
        final summary = await _fetchGenericSummary(metadata);
        return RaceExport(
          fileName: metadata.fileName,
          jsonData: summary.toJson(),
          additionalFiles: <ExportFile>[
            ExportFile(
              fileName: metadata.weatherFileName,
              jsonData: weatherExport,
            ),
            ExportFile(
              fileName: metadata.raceControlFileName,
              jsonData: raceControlExport,
            ),
          ],
        );
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherExport(RaceMetadata metadata) async {
    final raceSession = await _findClosestSessionForRace(
      year: metadata.season,
      targetDateUtc: metadata.raceDateUtc,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return {
        'season': metadata.season,
        'round': metadata.round,
        'raceName': metadata.raceName,
        'source': 'OpenF1 weather',
        'availableSessions': const <String>[],
        'sessions': const <Map<String, dynamic>>{},
      };
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    if (meetingKey == null) {
      return {
        'season': metadata.season,
        'round': metadata.round,
        'raceName': metadata.raceName,
        'source': 'OpenF1 weather',
        'availableSessions': const <String>[],
        'sessions': const <Map<String, dynamic>>{},
      };
    }

    final meetingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{'meeting_key': meetingKey.toString()},
    );
    final sortedSessions = List<Map<String, dynamic>>.from(meetingSessions)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date_start']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date_start']?.toString() ?? '');
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final sessionExports = <String, Map<String, dynamic>>{};
    final availableSessions = <String>[];
    for (final session in sortedSessions) {
      final sessionKey = _asInt(session['session_key']);
      if (sessionKey == null) {
        continue;
      }

      final sessionName =
          _normalizeSessionNameForApp(session['session_name']?.toString()) ??
          session['session_name']?.toString() ??
          'Unknown';
      final weather = await _fetchOpenF1Collection('weather', <String, String>{
        'session_key': sessionKey.toString(),
      });
      final laps = await _fetchOpenF1Collection('laps', <String, String>{
        'session_key': sessionKey.toString(),
      });
      final samples = _buildWeatherSamples(weather);
      final lapTimeline = _buildSessionLapTimeline(laps);
      sessionExports[sessionName] = {
        'sessionKey': sessionKey,
        'sampleCount': samples.length,
        'lapCount': lapTimeline.length,
        'lapTimeline': lapTimeline,
        'samples': samples.map((sample) => sample.toJson()).toList(growable: false),
      };
      availableSessions.add(sessionName);
    }

    return {
      'season': metadata.season,
      'round': metadata.round,
      'raceName': metadata.raceName,
      'source': 'OpenF1 weather',
      'availableSessions': availableSessions,
      'sessions': sessionExports,
    };
  }

  Future<Map<String, dynamic>> _fetchRaceControlExport(
    RaceMetadata metadata,
  ) async {
    final raceSession = await _findClosestSessionForRace(
      year: metadata.season,
      targetDateUtc: metadata.raceDateUtc,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return {
        'season': metadata.season,
        'round': metadata.round,
        'raceName': metadata.raceName,
        'source': 'OpenF1 race_control',
        'messageCount': 0,
        'availableScopes': const <String>[],
        'availableSessions': const <String>[],
        'messages': const <Map<String, dynamic>>[],
      };
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    if (meetingKey == null) {
      return {
        'season': metadata.season,
        'round': metadata.round,
        'raceName': metadata.raceName,
        'source': 'OpenF1 race_control',
        'messageCount': 0,
        'availableScopes': const <String>[],
        'availableSessions': const <String>[],
        'messages': const <Map<String, dynamic>>[],
      };
    }

    final meetingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{'meeting_key': meetingKey.toString()},
    );
    final sortedSessions = List<Map<String, dynamic>>.from(meetingSessions)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date_start']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date_start']?.toString() ?? '');
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final normalizedMessages = <Map<String, dynamic>>[];
    for (final session in sortedSessions) {
      final sessionKey = _asInt(session['session_key']);
      if (sessionKey == null) {
        continue;
      }

      final sessionName =
          _normalizeSessionNameForApp(session['session_name']?.toString()) ??
          session['session_name']?.toString() ??
          'Unknown';
      final sessionMessages = await _fetchOpenF1Collection(
        'race_control',
        <String, String>{'session_key': sessionKey.toString()},
      );

      for (final message in sessionMessages) {
        final normalized = _normalizeRaceControlMessage(
          message,
          sessionName: sessionName,
          sessionKey: sessionKey,
        );
        if (normalized != null) {
          normalizedMessages.add(normalized);
        }
      }
    }

    normalizedMessages.sort((a, b) {
      final aDate = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
      if (aDate != null && bDate != null) {
        final compare = aDate.compareTo(bDate);
        if (compare != 0) {
          return compare;
        }
      }

      final aLap = _asInt(a['lap']) ?? -1;
      final bLap = _asInt(b['lap']) ?? -1;
      return aLap.compareTo(bLap);
    });

    final scopes = normalizedMessages
        .map((message) => message['scope']?.toString().trim() ?? '')
        .where((scope) => scope.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final sessions = normalizedMessages
        .map((message) => message['sessionName']?.toString().trim() ?? '')
        .where((sessionName) => sessionName.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    return {
      'season': metadata.season,
      'round': metadata.round,
      'raceName': metadata.raceName,
      'source': 'OpenF1 race_control',
      'messageCount': normalizedMessages.length,
      'availableScopes': scopes,
      'availableSessions': sessions,
      'messages': normalizedMessages,
    };
  }

  Map<String, dynamic>? _normalizeRaceControlMessage(
    Map<String, dynamic> entry, {
    required String sessionName,
    required int sessionKey,
  }) {
    final message = entry['message']?.toString().trim() ?? '';
    if (message.isEmpty) {
      return null;
    }

    return {
      'timestampUtc': entry['date']?.toString(),
      'lap': _asInt(entry['lap_number']),
      'category': entry['category']?.toString(),
      'flag': entry['flag']?.toString(),
      'scope': entry['scope']?.toString(),
      'sector': _asInt(entry['sector']),
      'driverNumber': _extractRaceControlDriverNumber(entry, message),
      'qualifyingPhase': entry['qualifying_phase']?.toString(),
      'sessionKey': sessionKey,
      'sessionName': sessionName,
      'message': message,
    };
  }

  int? _extractRaceControlDriverNumber(
    Map<String, dynamic> entry,
    String message,
  ) {
    final directDriverNumber = _asInt(entry['driver_number']);
    if (directDriverNumber != null) {
      return directDriverNumber;
    }

    final match = RegExp(r'CAR\s+(\d+)').firstMatch(message.toUpperCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<RaceMetadata> _fetchRaceMetadata({
    required int year,
    required int round,
  }) async {
    final raceJson = await _getJson('/$year/$round/results.json');
    final raceTable = _requireMap(raceJson['MRData'], 'MRData')['RaceTable'];
    final races = _requireList(_requireMap(raceTable, 'RaceTable'), 'Races');
    if (races.isEmpty) {
      throw FetchException(
        'No race results found for season $year round $round.',
      );
    }

    final race = _requireMap(races.first, 'Race');
    final circuit = _requireMap(race['Circuit'], 'Circuit');
    final location = _requireMap(circuit['Location'], 'Location');
    final raceDateUtc = _combineDateAndTime(
      _readString(race, 'date'),
      _readOptionalString(race, 'time'),
    );

    return RaceMetadata(
      season: year,
      round: round,
      raceName: _readString(race, 'raceName'),
      raceDateUtc: raceDateUtc,
      circuit: CircuitSummary(
        id: _readString(circuit, 'circuitId'),
        name: _readString(circuit, 'circuitName'),
        country: _readString(location, 'country'),
        locality: _readString(location, 'locality'),
        latitude: _readOptionalString(location, 'lat'),
        longitude: _readOptionalString(location, 'long'),
      ),
      rawRace: race,
    );
  }

  Future<GenericRaceSummary> _fetchGenericSummary(RaceMetadata metadata) async {
    final results = _requireList(metadata.rawRace, 'Results');
    final fetchedAt = DateTime.now().toUtc();

    return GenericRaceSummary(
      source: 'Jolpica Ergast-compatible API',
      fetchedAtUtc: fetchedAt,
      season: metadata.season,
      round: metadata.round,
      raceName: metadata.raceName,
      raceDateUtc: metadata.raceDateUtc,
      circuit: metadata.circuit,
      results: results
          .map(
            (entry) =>
                GenericRaceResult.fromErgast(_requireMap(entry, 'Result')),
          )
          .toList(growable: false),
    );
  }

  Future<List<AppRaceResultRow>> _fetchAppCompatibleRows(
    RaceMetadata metadata,
  ) async {
    try {
      final enrichedRows = await _fetchOpenF1RaceRows(metadata);
      if (enrichedRows.isNotEmpty) {
        return enrichedRows;
      }
    } catch (_) {
      // Fall back to Jolpica-only formatting when OpenF1 is unavailable.
    }

    final results = _requireList(metadata.rawRace, 'Results');
    return results
        .map(
          (entry) => AppRaceResultRow.fromErgast(_requireMap(entry, 'Result')),
        )
        .toList(growable: false);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchSessionOverviewExport(
    RaceMetadata metadata,
  ) async {
    final raceSession = await _findClosestSessionForRace(
      year: metadata.season,
      targetDateUtc: metadata.raceDateUtc,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    if (meetingKey == null) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final meetingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{'meeting_key': meetingKey.toString()},
    );
    final sortedSessions = List<Map<String, dynamic>>.from(meetingSessions)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date_start']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date_start']?.toString() ?? '');
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final export = <String, List<Map<String, dynamic>>>{};
    for (final session in sortedSessions) {
      final appSessionName = _normalizeSessionNameForApp(
        session['session_name']?.toString(),
      );
      final sessionKey = _asInt(session['session_key']);
      if (appSessionName == null ||
          appSessionName == 'Race' ||
          sessionKey == null) {
        continue;
      }

      final rows = await _fetchSessionOverviewRowsForSessionKey(
        sessionKey,
        appSessionName,
      );
      if (rows.isEmpty) {
        continue;
      }

      export[appSessionName] = rows
          .map((row) => row.toJson())
          .toList(growable: false);
    }

    return export;
  }

  Future<List<AppRaceResultRow>> _fetchOpenF1RaceRows(
    RaceMetadata metadata,
  ) async {
    final raceSession = await _findClosestSessionForRace(
      year: metadata.season,
      targetDateUtc: metadata.raceDateUtc,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return const <AppRaceResultRow>[];
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    final raceSessionKey = _asInt(raceSession['session_key']);
    if (meetingKey == null || raceSessionKey == null) {
      return const <AppRaceResultRow>[];
    }

    final meetingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{'meeting_key': meetingKey.toString()},
    );
    final qualifyingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{
        'meeting_key': meetingKey.toString(),
        'session_name': 'Qualifying',
      },
    );
    final qualifyingSession = qualifyingSessions.isEmpty
        ? null
        : qualifyingSessions.first;
    final qualifyingSessionKey = qualifyingSession == null
        ? null
        : _asInt(qualifyingSession['session_key']);

    final results = await _fetchOpenF1Collection(
      'session_result',
      <String, String>{'session_key': raceSessionKey.toString()},
    );
    final drivers = await _fetchOpenF1Collection('drivers', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final laps = await _fetchOpenF1Collection('laps', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final stints = await _fetchOpenF1Collection('stints', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final pits = await _fetchOpenF1Collection('pit', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final raceControlMessages = await _fetchOpenF1Collection(
      'race_control',
      <String, String>{'session_key': raceSessionKey.toString()},
    );

    final allWeekendControlMessages = <Map<String, dynamic>>[
      ...raceControlMessages,
    ];
    for (final session in meetingSessions) {
      final sessionKey = _asInt(session['session_key']);
      if (sessionKey == null || sessionKey == raceSessionKey) {
        continue;
      }
      allWeekendControlMessages.addAll(
        await _fetchOpenF1Collection('race_control', <String, String>{
          'session_key': sessionKey.toString(),
        }),
      );
    }

    final startingGrid = qualifyingSessionKey == null
        ? const <Map<String, dynamic>>[]
        : await _fetchOpenF1Collection('starting_grid', <String, String>{
            'session_key': qualifyingSessionKey.toString(),
          });

    if (results.isEmpty || drivers.isEmpty) {
      return const <AppRaceResultRow>[];
    }

    final driverNames = <int, String>{
      for (final driver in drivers)
        if (_asInt(driver['driver_number']) != null)
          _asInt(driver['driver_number'])!: _formatDriverName(driver),
    };
    final gridPositions = <int, int>{
      for (final entry in startingGrid)
        if (_asInt(entry['driver_number']) != null &&
            _asInt(entry['position']) != null)
          _asInt(entry['driver_number'])!: _asInt(entry['position'])!,
    };
    final penaltyDetailsByDriver = _buildPenaltyDetailsMap(
      allWeekendControlMessages,
    );
    final sessionNamesByKey = <int, String>{
      for (final session in meetingSessions)
        if (_asInt(session['session_key']) != null)
          _asInt(session['session_key'])!:
              session['session_name']?.toString() ?? 'Unknown',
    };
    final raceControlMessagesByDriver = _buildRaceControlMessagesMap(
      allWeekendControlMessages,
      sessionNamesByKey,
    );
    final fastestLapByDriver = _buildFastestLapDetailsMap(laps, stints);
    final tyreStintsByDriver = _buildTyreStintsMap(stints);
    final pitEventsByDriver = _buildPitEventMap(pits);
    final overallFastestLap = fastestLapByDriver.values.isEmpty
        ? null
        : fastestLapByDriver.values.reduce(
            (best, current) =>
                current.duration < best.duration ? current : best,
          );

    final sortedResults = List<Map<String, dynamic>>.from(results)
      ..sort((a, b) {
        final positionA = _asInt(a['position']) ?? 999;
        final positionB = _asInt(b['position']) ?? 999;
        if (positionA != positionB) {
          return positionA.compareTo(positionB);
        }

        final lapsA = _asInt(a['number_of_laps']) ?? -1;
        final lapsB = _asInt(b['number_of_laps']) ?? -1;
        return lapsB.compareTo(lapsA);
      });

    final winnerDuration = sortedResults
        .map((entry) => _asDouble(entry['duration']))
        .whereType<double>()
        .cast<double?>()
        .firstWhere((value) => value != null, orElse: () => null);

    return sortedResults
        .map((entry) {
          final driverNumber = _asInt(entry['driver_number']);
          final startPosition = driverNumber == null
              ? null
              : gridPositions[driverNumber];
          final driverFastestLap = driverNumber == null
              ? null
              : fastestLapByDriver[driverNumber];
          final tyreStints = driverNumber == null
              ? const <AppTyreStint>[]
              : (tyreStintsByDriver[driverNumber] ?? const <AppTyreStint>[]);
          final penaltyDetails = driverNumber == null
              ? const <AppPenaltyDetail>[]
              : (penaltyDetailsByDriver[driverNumber] ??
                    const <AppPenaltyDetail>[]);
          final penaltyServedLaps = penaltyDetails
              .map((detail) => detail.servedLap)
              .whereType<int>()
              .toList(growable: false);

          return AppRaceResultRow(
            driver: driverNumber == null
                ? '-'
                : (driverNames[driverNumber] ?? '-'),
            start: driverNumber == null
                ? '-'
                : (gridPositions[driverNumber]?.toString() ?? '-'),
            finish: _formatRaceFinish(entry, startPosition),
            timeOrGap: _formatTimeOrGap(entry, winnerDuration),
            fastestLap: _formatLapDuration(driverFastestLap?.duration),
            tyreCompound: _formatTyreCompound(driverFastestLap?.compound),
            penalty: penaltyDetails.isEmpty
                ? '-'
                : penaltyDetails
                      .map((detail) => detail.penalty)
                      .toSet()
                      .join(', '),
            points: _formatPoints(_asDouble(entry['points']) ?? 0),
            hasFastestLap:
                driverNumber != null &&
                overallFastestLap != null &&
                driverFastestLap?.duration == overallFastestLap.duration,
            tyreCompounds: tyreStints
                .map((stint) => stint.compound)
                .toList(growable: false),
            tyreStints: tyreStints,
            tyreStrategy: _buildTyreStrategyLabel(tyreStints),
            tyreChangeLaps: tyreStints
                .map((stint) => stint.changedOnLap)
                .whereType<int>()
                .toList(growable: false),
            penaltyDetails: penaltyDetails,
            penaltyServed: penaltyDetails.any((detail) => detail.served),
            penaltyServedLaps: penaltyServedLaps,
            raceControlMessages: driverNumber == null
                ? const <AppRaceControlMessage>[]
                : (raceControlMessagesByDriver[driverNumber] ??
                      const <AppRaceControlMessage>[]),
            pitStops: _buildPitStops(
              driverNumber == null
                  ? const <PitEvent>[]
                  : (pitEventsByDriver[driverNumber] ?? const <PitEvent>[]),
              tyreStints,
            ),
            totalPitTime: _formatPitDuration(
              _sumPitDuration(
                driverNumber == null
                    ? const <PitEvent>[]
                    : (pitEventsByDriver[driverNumber] ?? const <PitEvent>[]),
              ),
            ),
            fastestPitStop: _buildFastestPitStopSummary(
              driverNumber == null
                  ? const <PitEvent>[]
                  : (pitEventsByDriver[driverNumber] ?? const <PitEvent>[]),
            ),
            averagePitTime: _formatPitDuration(
              _averagePitDuration(
                driverNumber == null
                    ? const <PitEvent>[]
                    : (pitEventsByDriver[driverNumber] ?? const <PitEvent>[]),
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  Future<List<AppSessionOverviewRow>> _fetchSessionOverviewRowsForSessionKey(
    int sessionKey,
    String sessionName,
  ) async {
    final drivers = await _fetchOpenF1Collection('drivers', <String, String>{
      'session_key': sessionKey.toString(),
    });
    final laps = await _fetchOpenF1Collection('laps', <String, String>{
      'session_key': sessionKey.toString(),
    });
    final stints = await _fetchOpenF1Collection('stints', <String, String>{
      'session_key': sessionKey.toString(),
    });
    final sessionResults = await _fetchOpenF1Collection(
      'session_result',
      <String, String>{'session_key': sessionKey.toString()},
    );

    if (drivers.isEmpty) {
      return const <AppSessionOverviewRow>[];
    }

    final driverNames = <int, String>{
      for (final driver in drivers)
        if (_asInt(driver['driver_number']) != null)
          _asInt(driver['driver_number'])!: _formatDriverName(driver),
    };
    final fastestLapByDriver = _buildFastestLapDetailsMap(laps, stints);
    final lapSummaryByDriver = _buildSessionLapSummaryMap(stints);
    final overallFastestLap = fastestLapByDriver.values.isEmpty
        ? null
        : fastestLapByDriver.values.reduce(
            (best, current) =>
                current.duration < best.duration ? current : best,
          );

    if (sessionResults.isNotEmpty) {
      final sortedResults = List<Map<String, dynamic>>.from(sessionResults)
        ..sort((a, b) {
          final positionA = _asInt(a['position']) ?? 999;
          final positionB = _asInt(b['position']) ?? 999;
          return positionA.compareTo(positionB);
        });

      final isSprint = sessionName == 'Sprint';
      return sortedResults
          .map((entry) {
            final driverNumber = _asInt(entry['driver_number']);
            final driverFastestLap = driverNumber == null
                ? null
                : fastestLapByDriver[driverNumber];
            final lapSummary = driverNumber == null
                ? null
                : lapSummaryByDriver[driverNumber];
            final tyreUsage = driverNumber == null
                ? null
                : _tyreUsageForLap(
                    stints,
                    driverNumber,
                    driverFastestLap?.lapNumber,
                  );
            return AppSessionOverviewRow(
              driver: driverNumber == null
                  ? '-'
                  : (driverNames[driverNumber] ?? '-'),
              position: _formatSessionPosition(entry),
              result: isSprint
                  ? _formatSprintResult(entry)
                  : _formatLapDuration(driverFastestLap?.duration),
              fastestLap: _formatLapDuration(driverFastestLap?.duration),
              tyreCompound:
                  tyreUsage?.formattedCompound ??
                  _formatTyreCompound(driverFastestLap?.compound),
              points: isSprint
                  ? _formatPoints(_asDouble(entry['points']) ?? 0)
                  : '-',
              hasFastestLap:
                  driverNumber != null &&
                  overallFastestLap != null &&
                  driverFastestLap?.duration == overallFastestLap.duration,
              usedTyre: tyreUsage?.usedTyre ?? false,
              tyreAgeAtStart: tyreUsage?.tyreAgeAtStart,
              totalLaps: lapSummary?.totalLaps,
              tyreLaps: lapSummary?.lapsByCompound ?? const <String, int>{},
              tyreLapSequence:
                  lapSummary?.stintSequence ??
                  const <AppTyreLapSequenceEntry>[],
            );
          })
          .toList(growable: false);
    }

    final rankedDrivers = fastestLapByDriver.entries.toList()
      ..sort((a, b) => a.value.duration.compareTo(b.value.duration));

    return rankedDrivers
        .asMap()
        .entries
        .map((entry) {
          final position = entry.key + 1;
          final driverNumber = entry.value.key;
          final lap = entry.value.value;
          final lapSummary = lapSummaryByDriver[driverNumber];
          return AppSessionOverviewRow(
            driver: driverNames[driverNumber] ?? '-',
            position: position.toString(),
            result: _formatLapDuration(lap.duration),
            fastestLap: _formatLapDuration(lap.duration),
            tyreCompound:
                _tyreUsageForLap(
                  stints,
                  driverNumber,
                  lap.lapNumber,
                )?.formattedCompound ??
                _formatTyreCompound(lap.compound),
            points: '-',
            hasFastestLap:
                overallFastestLap != null &&
                lap.duration == overallFastestLap.duration,
            usedTyre:
                _tyreUsageForLap(
                  stints,
                  driverNumber,
                  lap.lapNumber,
                )?.usedTyre ??
                false,
            tyreAgeAtStart: _tyreUsageForLap(
              stints,
              driverNumber,
              lap.lapNumber,
            )?.tyreAgeAtStart,
            totalLaps: lapSummary?.totalLaps,
            tyreLaps: lapSummary?.lapsByCompound ?? const <String, int>{},
            tyreLapSequence:
                lapSummary?.stintSequence ?? const <AppTyreLapSequenceEntry>[],
          );
        })
        .toList(growable: false);
  }

  Map<int, _SessionLapSummary> _buildSessionLapSummaryMap(
    List<Map<String, dynamic>> stints,
  ) {
    final sortedStints = List<Map<String, dynamic>>.from(stints)
      ..sort((a, b) {
        final driverA = _asInt(a['driver_number']) ?? 999;
        final driverB = _asInt(b['driver_number']) ?? 999;
        if (driverA != driverB) {
          return driverA.compareTo(driverB);
        }

        final stintA = _asInt(a['stint_number']) ?? _asInt(a['lap_start']) ?? 0;
        final stintB = _asInt(b['stint_number']) ?? _asInt(b['lap_start']) ?? 0;
        return stintA.compareTo(stintB);
      });
    final summaries = <int, _MutableSessionLapSummary>{};

    for (final stint in sortedStints) {
      final driverNumber = _asInt(stint['driver_number']);
      if (driverNumber == null) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']);
      final lapEnd = _asInt(stint['lap_end']);
      if (lapStart == null || lapEnd == null || lapEnd < lapStart) {
        continue;
      }

      final compound = _formatTyreCompound(stint['compound']?.toString());
      final lapCount = (lapEnd - lapStart) + 1;
      if (lapCount <= 0) {
        continue;
      }

      final summary = summaries.putIfAbsent(
        driverNumber,
        () => _MutableSessionLapSummary(),
      );
      summary.totalLaps += lapCount;
      if (compound != '-') {
        summary.lapsByCompound.update(
          compound,
          (value) => value + lapCount,
          ifAbsent: () => lapCount,
        );
        summary.stintSequence.add(
          AppTyreLapSequenceEntry(
            compound: compound,
            laps: lapCount,
            usedTyre: (_asInt(stint['tyre_age_at_start']) ?? 0) > 0,
          ),
        );
      }
    }

    return {
      for (final entry in summaries.entries) entry.key: entry.value.build(),
    };
  }

  Future<int> _resolveLatestCompletedRound(int year) async {
    final scheduleJson = await _getJson('/$year/races.json');
    final raceTable = _requireMap(
      scheduleJson['MRData'],
      'MRData',
    )['RaceTable'];
    final races = _requireList(_requireMap(raceTable, 'RaceTable'), 'Races');
    if (races.isEmpty) {
      throw FetchException('No race schedule found for season $year.');
    }

    final nowUtc = DateTime.now().toUtc();
    Map<String, dynamic>? latestRace;

    for (final raceEntry in races) {
      final race = _requireMap(raceEntry, 'Race');
      final raceDateTime = _combineDateAndTime(
        _readString(race, 'date'),
        _readOptionalString(race, 'time'),
      );
      if (!raceDateTime.isAfter(nowUtc)) {
        latestRace = race;
      }
    }

    if (latestRace == null) {
      throw FetchException('No completed race found yet for season $year.');
    }

    return int.parse(_readString(latestRace, 'round'));
  }

  Future<Map<String, dynamic>?> _findClosestSessionForRace({
    required int year,
    required DateTime targetDateUtc,
    required String sessionName,
  }) async {
    final sessions = await _fetchOpenF1Collection('sessions', <String, String>{
      'year': year.toString(),
      'session_name': sessionName,
    });
    if (sessions.isEmpty) {
      return null;
    }

    Map<String, dynamic>? bestMatch;
    Duration? smallestDifference;

    for (final session in sessions) {
      final sessionDate = DateTime.tryParse(
        session['date_start']?.toString() ?? '',
      );
      if (sessionDate == null) {
        continue;
      }

      final difference = sessionDate.toUtc().difference(targetDateUtc).abs();
      if (smallestDifference == null || difference < smallestDifference) {
        smallestDifference = difference;
        bestMatch = session;
      }
    }

    if (smallestDifference == null ||
        smallestDifference > const Duration(days: 4)) {
      return null;
    }

    return bestMatch;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse('$_jolpicaBaseUrl$path');
    late final http.Response response;

    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } on SocketException {
      rethrow;
    } on HttpException catch (error) {
      throw FetchException('HTTP error for $uri: ${error.message}');
    } on TimeoutException {
      throw FetchException('Request timed out for $uri.');
    }

    if (response.statusCode != 200) {
      throw FetchException(
        'API returned status ${response.statusCode} for $uri.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw FetchException('Unexpected JSON format returned by $uri.');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> _fetchOpenF1Collection(
    String endpoint,
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.https(
      _openF1BaseAuthority,
      '/v1/$endpoint',
      queryParameters,
    );
    final cacheKey = uri.toString();
    final cached = _openF1Cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (_lastOpenF1RequestAt != null) {
      final elapsed = DateTime.now().difference(_lastOpenF1RequestAt!);
      const minimumDelay = Duration(milliseconds: 700);
      if (elapsed < minimumDelay) {
        await Future.delayed(minimumDelay - elapsed);
      }
    }

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    _lastOpenF1RequestAt = DateTime.now();
    if (response.statusCode != 200) {
      return const <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }

    final result = decoded
        .whereType<Map>()
        .map(
          (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
    _openF1Cache[cacheKey] = result;
    return result;
  }

  Map<int, FastestLapDetails> _buildFastestLapDetailsMap(
    List<Map<String, dynamic>> laps,
    List<Map<String, dynamic>> stints,
  ) {
    final fastestLapByDriver = <int, FastestLapDetails>{};

    for (final lap in laps) {
      final driverNumber = _asInt(lap['driver_number']);
      final lapDuration = _asDouble(lap['lap_duration']);
      final lapNumber = _asInt(lap['lap_number']);
      if (driverNumber == null || lapDuration == null || lapDuration <= 0) {
        continue;
      }
      if (lapNumber == null || lapNumber <= 0) {
        continue;
      }
      if (_asBool(lap['is_pit_out_lap'])) {
        continue;
      }

      final currentBest = fastestLapByDriver[driverNumber];
      if (currentBest == null || lapDuration < currentBest.duration) {
        fastestLapByDriver[driverNumber] = FastestLapDetails(
          duration: lapDuration,
          lapNumber: lapNumber,
          compound: _compoundForLap(stints, driverNumber, lapNumber),
        );
      }
    }

    return fastestLapByDriver;
  }

  Map<int, List<AppTyreStint>> _buildTyreStintsMap(
    List<Map<String, dynamic>> stints,
  ) {
    final sortedStints = List<Map<String, dynamic>>.from(stints)
      ..sort((a, b) {
        final driverA = _asInt(a['driver_number']) ?? 999;
        final driverB = _asInt(b['driver_number']) ?? 999;
        if (driverA != driverB) {
          return driverA.compareTo(driverB);
        }

        final startA = _asInt(a['lap_start']) ?? 0;
        final startB = _asInt(b['lap_start']) ?? 0;
        if (startA != startB) {
          return startA.compareTo(startB);
        }

        final stintA = _asInt(a['stint_number']) ?? 0;
        final stintB = _asInt(b['stint_number']) ?? 0;
        return stintA.compareTo(stintB);
      });

    final result = <int, List<AppTyreStint>>{};
    for (final stint in sortedStints) {
      final driverNumber = _asInt(stint['driver_number']);
      if (driverNumber == null) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']) ?? 0;
      final lapEnd = _asInt(stint['lap_end']) ?? lapStart;
      final compound = _formatTyreCompound(stint['compound']?.toString());
      if (compound == '-') {
        continue;
      }

      final entries = result.putIfAbsent(driverNumber, () => <AppTyreStint>[]);
      final stintNumber = _asInt(stint['stint_number']) ?? entries.length + 1;
      final changedOnLap = entries.isEmpty ? null : lapStart;
      entries.add(
        AppTyreStint(
          stint: stintNumber,
          compound: compound,
          lapStart: lapStart,
          lapEnd: lapEnd,
          changedOnLap: changedOnLap,
        ),
      );
    }

    return result;
  }

  String _buildTyreStrategyLabel(List<AppTyreStint> tyreStints) {
    if (tyreStints.isEmpty) {
      return '-';
    }
    return tyreStints.map((stint) => stint.compound).join(' -> ');
  }

  List<AppPitStop> _buildPitStops(
    List<PitEvent> pitEvents,
    List<AppTyreStint> tyreStints,
  ) {
    if (tyreStints.length < 2) {
      return const <AppPitStop>[];
    }

    final pitStops = <AppPitStop>[];
    for (var index = 1; index < tyreStints.length; index++) {
      final previous = tyreStints[index - 1];
      final current = tyreStints[index];
      final lap = current.changedOnLap;
      if (lap == null) {
        continue;
      }
      final matchedPit = pitEvents
          .where((event) => event.lapNumber == lap)
          .firstWhere((_) => true, orElse: () => const PitEvent.empty());
      final effectiveStopDuration = _effectiveStopDurationSeconds(matchedPit);
      pitStops.add(
        AppPitStop(
          stopNumber: pitStops.length + 1,
          lap: lap,
          fromCompound: previous.compound,
          toCompound: current.compound,
          pitTimestampUtc: matchedPit.date,
          duration: _formatPitDuration(
            matchedPit.stopDuration ??
                matchedPit.pitDuration ??
                matchedPit.laneDuration,
          ),
          durationSeconds:
              matchedPit.stopDuration ??
              matchedPit.pitDuration ??
              matchedPit.laneDuration,
          laneDurationSeconds: matchedPit.laneDuration,
          stopDurationSeconds: effectiveStopDuration,
          pitTypeDuration: {
            'pitDurationSeconds': matchedPit.pitDuration,
            'laneDurationSeconds': matchedPit.laneDuration,
            'stopDurationSeconds': effectiveStopDuration,
          },
        ),
      );
    }

    return pitStops;
  }

  double? _effectiveStopDurationSeconds(PitEvent pitEvent) {
    final stopDuration = pitEvent.stopDuration;
    if (stopDuration == null) {
      return null;
    }

    final laneDuration = pitEvent.laneDuration;
    if (laneDuration != null && (stopDuration - laneDuration).abs() < 0.0001) {
      return null;
    }

    return stopDuration;
  }

  double? _sumPitDuration(List<PitEvent> pitEvents) {
    final values = pitEvents
        .map(
          (event) =>
              event.stopDuration ?? event.pitDuration ?? event.laneDuration,
        )
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return values.reduce((total, value) => total + value);
  }

  double? _averagePitDuration(List<PitEvent> pitEvents) {
    final values = pitEvents
        .map(
          (event) =>
              event.stopDuration ?? event.pitDuration ?? event.laneDuration,
        )
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return values.reduce((total, value) => total + value) / values.length;
  }

  Map<String, dynamic>? _buildFastestPitStopSummary(List<PitEvent> pitEvents) {
    final eligible = pitEvents
        .where(
          (event) =>
              (event.stopDuration ?? event.pitDuration ?? event.laneDuration) !=
              null,
        )
        .toList(growable: false);
    if (eligible.isEmpty) {
      return null;
    }

    eligible.sort((a, b) {
      final aDuration =
          a.stopDuration ?? a.pitDuration ?? a.laneDuration ?? double.infinity;
      final bDuration =
          b.stopDuration ?? b.pitDuration ?? b.laneDuration ?? double.infinity;
      return aDuration.compareTo(bDuration);
    });

    final fastest = eligible.first;
    final duration =
        fastest.stopDuration ?? fastest.pitDuration ?? fastest.laneDuration;
    return {
      'lap': fastest.lapNumber,
      'timestampUtc': fastest.date,
      'duration': _formatPitDuration(duration),
      'durationSeconds': duration,
    };
  }

  Map<int, List<PitEvent>> _buildPitEventMap(List<Map<String, dynamic>> pits) {
    final result = <int, List<PitEvent>>{};
    final sortedPits = List<Map<String, dynamic>>.from(pits)
      ..sort((a, b) {
        final driverA = _asInt(a['driver_number']) ?? 999;
        final driverB = _asInt(b['driver_number']) ?? 999;
        if (driverA != driverB) {
          return driverA.compareTo(driverB);
        }

        final lapA = _asInt(a['lap_number']) ?? 0;
        final lapB = _asInt(b['lap_number']) ?? 0;
        return lapA.compareTo(lapB);
      });

    for (final pit in sortedPits) {
      final driverNumber = _asInt(pit['driver_number']);
      final lapNumber = _asInt(pit['lap_number']);
      if (driverNumber == null || lapNumber == null) {
        continue;
      }

      result
          .putIfAbsent(driverNumber, () => <PitEvent>[])
          .add(
            PitEvent(
              lapNumber: lapNumber,
              date: pit['date']?.toString(),
              pitDuration: _asDouble(pit['pit_duration']),
              laneDuration: _asDouble(pit['lane_duration']),
              stopDuration: _asDouble(pit['stop_duration']),
            ),
          );
    }

    return result;
  }

  List<AppWeatherSample> _buildWeatherSamples(
    List<Map<String, dynamic>> weatherEntries,
  ) {
    if (weatherEntries.isEmpty) {
      return const <AppWeatherSample>[];
    }

    final sortedEntries = List<Map<String, dynamic>>.from(weatherEntries)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final samples = <AppWeatherSample>[];
    for (final entry in sortedEntries) {
      final date = DateTime.tryParse(entry['date']?.toString() ?? '');
      if (date == null) {
        continue;
      }

      samples.add(
        AppWeatherSample(
          timestampUtc: entry['date']?.toString(),
          airTemperatureC: _asDouble(entry['air_temperature']),
          trackTemperatureC: _asDouble(entry['track_temperature']),
          humidity: _asDouble(entry['humidity']),
          rainfall: _asDouble(entry['rainfall']),
          pressure: _asDouble(entry['pressure']),
          windSpeed: _asDouble(entry['wind_speed']),
          windDirection: _asInt(entry['wind_direction']),
        ),
      );
    }

    return samples;
  }

  List<Map<String, dynamic>> _buildSessionLapTimeline(
    List<Map<String, dynamic>> lapEntries,
  ) {
    if (lapEntries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final earliestTimestampByLap = <int, DateTime>{};
    for (final entry in lapEntries) {
      final lapNumber = _asInt(entry['lap_number']);
      final timestamp = DateTime.tryParse(entry['date_start']?.toString() ?? '');
      if (lapNumber == null || lapNumber <= 0 || timestamp == null) {
        continue;
      }

      final existing = earliestTimestampByLap[lapNumber];
      if (existing == null || timestamp.isBefore(existing)) {
        earliestTimestampByLap[lapNumber] = timestamp;
      }
    }

    final markers = earliestTimestampByLap.entries.toList(growable: false)
      ..sort((a, b) => a.value.compareTo(b.value));

    return markers
        .map(
          (entry) => <String, dynamic>{
            'lap': entry.key,
            'timestampUtc': entry.value.toUtc().toIso8601String(),
          },
        )
        .toList(growable: false);
  }

  _TyreUsageDetails? _tyreUsageForLap(
    List<Map<String, dynamic>> stints,
    int driverNumber,
    int? lapNumber,
  ) {
    if (lapNumber == null || lapNumber <= 0) {
      return null;
    }

    for (final stint in stints) {
      if (_asInt(stint['driver_number']) != driverNumber) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']) ?? 0;
      final lapEnd = _asInt(stint['lap_end']) ?? 0;
      if (lapNumber < lapStart || lapNumber > lapEnd) {
        continue;
      }

      final compound = _formatTyreCompound(stint['compound']?.toString());
      final tyreAgeAtStart = _asInt(stint['tyre_age_at_start']);
      return _TyreUsageDetails(
        compound: compound,
        tyreAgeAtStart: tyreAgeAtStart,
      );
    }

    return null;
  }

  String? _formatPitDuration(double? seconds) {
    if (seconds == null) {
      return null;
    }
    return seconds.toStringAsFixed(3);
  }

  String _compoundForLap(
    List<Map<String, dynamic>> stints,
    int driverNumber,
    int lapNumber,
  ) {
    for (final stint in stints) {
      if (_asInt(stint['driver_number']) != driverNumber) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']) ?? 0;
      final lapEnd = _asInt(stint['lap_end']) ?? 0;
      if (lapNumber >= lapStart && lapNumber <= lapEnd) {
        return stint['compound']?.toString() ?? '-';
      }
    }

    return '-';
  }

  Map<int, List<AppPenaltyDetail>> _buildPenaltyDetailsMap(
    List<Map<String, dynamic>> messages,
  ) {
    final penaltiesByDriver = <int, Map<String, _MutablePenaltyDetail>>{};

    for (final entry in messages) {
      final message = entry['message']?.toString() ?? '';
      final normalizedPenalty = _normalizePenalty(message);
      if (normalizedPenalty == null) {
        continue;
      }

      final driverNumber = _extractPenaltyDriverNumber(entry, message);
      if (driverNumber == null) {
        continue;
      }

      final reason = _extractPenaltyReason(message);
      final key = '$normalizedPenalty|${reason ?? ''}';
      final perDriver = penaltiesByDriver.putIfAbsent(
        driverNumber,
        () => <String, _MutablePenaltyDetail>{},
      );
      final detail = perDriver.putIfAbsent(
        key,
        () => _MutablePenaltyDetail(penalty: normalizedPenalty, reason: reason),
      );

      final lapNumber = _asInt(entry['lap_number']);
      if (_isPenaltyServedMessage(message)) {
        detail.served = true;
        detail.servedLap = lapNumber ?? detail.servedLap;
      } else {
        detail.issuedLap = lapNumber ?? detail.issuedLap;
      }
    }

    return {
      for (final entry in penaltiesByDriver.entries)
        entry.key: entry.value.values
            .map((detail) => detail.build())
            .toList(growable: false),
    };
  }

  Map<int, List<AppRaceControlMessage>> _buildRaceControlMessagesMap(
    List<Map<String, dynamic>> messages,
    Map<int, String> sessionNamesByKey,
  ) {
    final sortedMessages = List<Map<String, dynamic>>.from(messages)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
        if (aDate != null && bDate != null) {
          final compare = aDate.compareTo(bDate);
          if (compare != 0) {
            return compare;
          }
        }

        final aLap = _asInt(a['lap_number']) ?? -1;
        final bLap = _asInt(b['lap_number']) ?? -1;
        return aLap.compareTo(bLap);
      });

    final result = <int, List<AppRaceControlMessage>>{};
    for (final entry in sortedMessages) {
      final message = entry['message']?.toString().trim() ?? '';
      if (message.isEmpty) {
        continue;
      }

      final driverNumber = _extractPenaltyDriverNumber(entry, message);
      if (driverNumber == null) {
        continue;
      }

      final sessionKey = _asInt(entry['session_key']);
      result
          .putIfAbsent(driverNumber, () => <AppRaceControlMessage>[])
          .add(
            AppRaceControlMessage(
              timestampUtc: entry['date']?.toString(),
              lap: _asInt(entry['lap_number']),
              category: entry['category']?.toString(),
              flag: entry['flag']?.toString(),
              scope: entry['scope']?.toString(),
              sector: _asInt(entry['sector']),
              qualifyingPhase: entry['qualifying_phase']?.toString(),
              message: message,
              sessionName: sessionKey == null
                  ? null
                  : sessionNamesByKey[sessionKey],
            ),
          );
    }

    return result;
  }

  int? _extractPenaltyDriverNumber(Map<String, dynamic> entry, String message) {
    final directDriverNumber = _asInt(entry['driver_number']);
    if (directDriverNumber != null) {
      return directDriverNumber;
    }

    final match = RegExp(r'CAR\s+(\d+)').firstMatch(message.toUpperCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  bool _isPenaltyServedMessage(String message) {
    return message.toUpperCase().contains('PENALTY SERVED');
  }

  String? _extractPenaltyReason(String message) {
    final parts = message
        .split(' - ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length < 2) {
      return null;
    }

    final trailing = parts.last;
    if (trailing.toUpperCase().contains('PENALTY')) {
      return null;
    }

    return _toSentenceCase(trailing);
  }

  String _toSentenceCase(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String? _normalizePenalty(String message) {
    if (message.isEmpty) {
      return null;
    }

    final upper = message.toUpperCase();
    if (upper.contains('NO FURTHER ACTION') ||
        upper.contains('UNDER INVESTIGATION') ||
        upper.contains('NOTED') ||
        upper.contains('SUMMONED') ||
        upper.contains('WARNING') ||
        upper.contains('REPRIMAND') ||
        upper.contains('FINE')) {
      return null;
    }

    final gridMatch = RegExp(
      r'(\d+)\s*(?:PLACE|POSITION)\s+GRID\s+(?:PENALTY|DROP)',
    ).firstMatch(upper);
    if (gridMatch != null) {
      return '${gridMatch.group(1)} Grid';
    }

    final altGridMatch = RegExp(
      r'GRID\s+(?:PENALTY|DROP)\s+OF\s+(\d+)\s*(?:PLACE|POSITION)',
    ).firstMatch(upper);
    if (altGridMatch != null) {
      return '${altGridMatch.group(1)} Grid';
    }

    final timeMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*SECOND(?:S)?\s+TIME\s+PENALTY',
    ).firstMatch(upper);
    if (timeMatch != null) {
      return '+${_trimTrailingZero(timeMatch.group(1)!)}s';
    }

    final altTimeMatch = RegExp(
      r'TIME\s+PENALTY\s+OF\s+(\d+(?:\.\d+)?)\s*SECOND(?:S)?',
    ).firstMatch(upper);
    if (altTimeMatch != null) {
      return '+${_trimTrailingZero(altTimeMatch.group(1)!)}s';
    }

    final simpleTimeMatch = RegExp(
      r'PENALTY\s*-\s*(\d+(?:\.\d+)?)\s*SECOND(?:S)?',
    ).firstMatch(upper);
    if (simpleTimeMatch != null) {
      return '+${_trimTrailingZero(simpleTimeMatch.group(1)!)}s';
    }

    if (upper.contains('STOP/GO PENALTY') ||
        upper.contains('STOP AND GO PENALTY') ||
        upper.contains('STOP-AND-GO PENALTY')) {
      return 'S&G';
    }

    if (upper.contains('DRIVE THROUGH PENALTY') ||
        upper.contains('DRIVE-THROUGH PENALTY')) {
      return 'DT';
    }

    return null;
  }

  String _formatDriverName(Map<String, dynamic> driver) {
    final firstName = driver['first_name']?.toString().trim() ?? '';
    final lastName = driver['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return driver['full_name']?.toString().trim() ?? '-';
  }

  String _formatRaceFinish(Map<String, dynamic> entry, int? startPosition) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return 'NC';
    }

    final finishPosition = _asInt(entry['position']);
    if (finishPosition == null) {
      return 'NC';
    }

    final finishLabel = 'P$finishPosition';
    if (startPosition == null || startPosition <= 0) {
      return finishLabel;
    }

    final delta = startPosition - finishPosition;
    final deltaLabel = delta > 0
        ? '+$delta'
        : delta < 0
        ? '$delta'
        : '-';
    return '$finishLabel ($deltaLabel)';
  }

  String _formatSessionPosition(Map<String, dynamic> entry) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return 'NC';
    }
    return (_asInt(entry['position'])?.toString()) ?? '-';
  }

  String _formatSprintResult(Map<String, dynamic> entry) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq']) || _asInt(entry['position']) == null) {
      return 'NC';
    }

    final position = _asInt(entry['position']);
    final gap = entry['gap_to_leader'];
    final duration = _asDouble(entry['duration']);
    if (position == 1 && duration != null) {
      return _formatRaceDuration(duration);
    }
    if (gap is num) {
      return '+${gap.toDouble().toStringAsFixed(3)}s';
    }

    final gapText = gap?.toString().trim() ?? '';
    if (gapText.isNotEmpty && gapText != '0') {
      return _normalizeGapText(gapText);
    }

    return '-';
  }

  String? _normalizeSessionNameForApp(String? openF1SessionName) {
    switch ((openF1SessionName ?? '').trim()) {
      case 'Practice 1':
      case 'Practice 2':
      case 'Practice 3':
      case 'Qualifying':
      case 'Sprint':
      case 'Race':
      case 'Sprint Qualifying':
        return openF1SessionName!.trim();
      case 'Sprint Shootout':
        return 'Sprint Qualifying';
      default:
        return null;
    }
  }

  String _formatTimeOrGap(Map<String, dynamic> entry, double? winnerDuration) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq']) || _asInt(entry['position']) == null) {
      return 'NC';
    }

    final position = _asInt(entry['position']);
    final gap = entry['gap_to_leader'];
    final duration = _asDouble(entry['duration']);
    if (position == 1) {
      return duration == null ? '-' : _formatRaceDuration(duration);
    }

    if (gap is num) {
      return '+${gap.toDouble().toStringAsFixed(3)}s';
    }

    final gapText = gap?.toString().trim() ?? '';
    if (gapText.isNotEmpty && gapText != '0') {
      return _normalizeGapText(gapText);
    }

    if (duration != null && winnerDuration != null) {
      return '+${(duration - winnerDuration).toStringAsFixed(3)}s';
    }

    return '-';
  }

  String _normalizeGapText(String gapText) {
    final upper = gapText.toUpperCase();
    final lapMatch = RegExp(r'\+(\d+)\s+LAP(S)?').firstMatch(upper);
    if (lapMatch != null) {
      final laps = lapMatch.group(1)!;
      return '+$laps ${laps == '1' ? 'lap' : 'laps'}';
    }

    if (gapText.startsWith('+')) {
      return gapText;
    }
    return '+$gapText';
  }

  String _formatRaceDuration(double totalSeconds) {
    final duration = Duration(
      microseconds: (totalSeconds * Duration.microsecondsPerSecond).round(),
    );
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMicroseconds.remainder(Duration.microsecondsPerSecond)) /
                1000)
            .round()
            .toString()
            .padLeft(3, '0');
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  String _formatLapDuration(double? totalSeconds) {
    if (totalSeconds == null) {
      return '-';
    }

    final duration = Duration(
      microseconds: (totalSeconds * Duration.microsecondsPerSecond).round(),
    );
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMicroseconds.remainder(Duration.microsecondsPerSecond)) /
                1000)
            .round()
            .toString()
            .padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatTyreCompound(String? compound) {
    switch ((compound ?? '').toUpperCase()) {
      case 'SOFT':
        return 'Soft';
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      case 'INTERMEDIATE':
        return 'Inter';
      case 'WET':
        return 'Wet';
      default:
        return '-';
    }
  }

  String _formatPoints(double points) {
    if (points == points.roundToDouble()) {
      return points.toInt().toString();
    }
    return points.toStringAsFixed(1);
  }

  bool _asBool(dynamic value) => value == true;

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> _requireMap(Object? value, String label) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    throw FetchException('Expected $label to be an object.');
  }

  List<dynamic> _requireList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is List<dynamic>) {
      return value;
    }
    throw FetchException('Expected "$key" to be a list.');
  }

  String _readString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString();
    if (value == null || value.trim().isEmpty) {
      throw FetchException('Missing required field "$key".');
    }
    return value;
  }

  String? _readOptionalString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  DateTime _combineDateAndTime(String date, String? time) {
    if (time == null) {
      return DateTime.parse('${date}T00:00:00Z').toUtc();
    }
    return DateTime.parse('${date}T$time').toUtc();
  }

  String _trimTrailingZero(String value) {
    if (!value.contains('.')) {
      return value;
    }
    return value
        .replaceFirst(RegExp(r'\.0+$'), '')
        .replaceFirst(RegExp(r'(\.[1-9]*)0+$'), r'$1');
  }

  void close() {
    _client.close();
  }
}

class RaceExport {
  const RaceExport({
    required this.fileName,
    required this.jsonData,
    required this.additionalFiles,
  });

  final String fileName;
  final Object jsonData;
  final List<ExportFile> additionalFiles;
}

class ExportFile {
  const ExportFile({required this.fileName, required this.jsonData});

  final String fileName;
  final Object jsonData;
}

class RaceMetadata {
  const RaceMetadata({
    required this.season,
    required this.round,
    required this.raceName,
    required this.raceDateUtc,
    required this.circuit,
    required this.rawRace,
  });

  final int season;
  final int round;
  final String raceName;
  final DateTime raceDateUtc;
  final CircuitSummary circuit;
  final Map<String, dynamic> rawRace;

  String get fileName => 'results_${season}_round_$round.json';
  String get sessionsFileName => 'sessions_${season}_round_$round.json';
  String get weatherFileName => 'weather_${season}_round_$round.json';
  String get raceControlFileName => 'race_control_${season}_round_$round.json';
}

class AppSessionOverviewRow {
  const AppSessionOverviewRow({
    required this.driver,
    required this.position,
    required this.result,
    required this.fastestLap,
    required this.tyreCompound,
    required this.points,
    required this.hasFastestLap,
    required this.usedTyre,
    required this.tyreAgeAtStart,
    required this.totalLaps,
    required this.tyreLaps,
    required this.tyreLapSequence,
  });

  final String driver;
  final String position;
  final String result;
  final String fastestLap;
  final String tyreCompound;
  final String points;
  final bool hasFastestLap;
  final bool usedTyre;
  final int? tyreAgeAtStart;
  final int? totalLaps;
  final Map<String, int> tyreLaps;
  final List<AppTyreLapSequenceEntry> tyreLapSequence;

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'position': position,
      'result': result,
      'fastestLap': fastestLap,
      'tyreCompound': tyreCompound,
      'points': points,
      'hasFastestLap': hasFastestLap,
      'usedTyre': usedTyre,
      'tyreAgeAtStart': tyreAgeAtStart,
      'totalLaps': totalLaps,
      'tyreLaps': tyreLaps,
      'tyreLapSequence': tyreLapSequence
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}

class AppTyreLapSequenceEntry {
  const AppTyreLapSequenceEntry({
    required this.compound,
    required this.laps,
    required this.usedTyre,
  });

  final String compound;
  final int laps;
  final bool usedTyre;

  Map<String, dynamic> toJson() {
    return {'compound': compound, 'laps': laps, 'usedTyre': usedTyre};
  }
}

class _SessionLapSummary {
  const _SessionLapSummary({
    required this.totalLaps,
    required this.lapsByCompound,
    required this.stintSequence,
  });

  final int totalLaps;
  final Map<String, int> lapsByCompound;
  final List<AppTyreLapSequenceEntry> stintSequence;
}

class _MutableSessionLapSummary {
  int totalLaps = 0;
  final Map<String, int> lapsByCompound = <String, int>{};
  final List<AppTyreLapSequenceEntry> stintSequence =
      <AppTyreLapSequenceEntry>[];

  _SessionLapSummary build() {
    return _SessionLapSummary(
      totalLaps: totalLaps,
      lapsByCompound: Map<String, int>.from(lapsByCompound),
      stintSequence: List<AppTyreLapSequenceEntry>.from(stintSequence),
    );
  }
}

class _TyreUsageDetails {
  const _TyreUsageDetails({
    required this.compound,
    required this.tyreAgeAtStart,
  });

  final String compound;
  final int? tyreAgeAtStart;

  bool get usedTyre => (tyreAgeAtStart ?? 0) > 0;

  String get formattedCompound => usedTyre ? '$compound (used)' : compound;
}

class AppRaceResultRow {
  const AppRaceResultRow({
    required this.driver,
    required this.start,
    required this.finish,
    required this.timeOrGap,
    required this.fastestLap,
    required this.tyreCompound,
    required this.penalty,
    required this.points,
    required this.hasFastestLap,
    required this.tyreCompounds,
    required this.tyreStints,
    required this.tyreStrategy,
    required this.tyreChangeLaps,
    required this.penaltyDetails,
    required this.penaltyServed,
    required this.penaltyServedLaps,
    required this.raceControlMessages,
    required this.pitStops,
    required this.totalPitTime,
    required this.fastestPitStop,
    required this.averagePitTime,
  });

  final String driver;
  final String start;
  final String finish;
  final String timeOrGap;
  final String fastestLap;
  final String tyreCompound;
  final String penalty;
  final String points;
  final bool hasFastestLap;
  final List<String> tyreCompounds;
  final List<AppTyreStint> tyreStints;
  final String tyreStrategy;
  final List<int> tyreChangeLaps;
  final List<AppPenaltyDetail> penaltyDetails;
  final bool penaltyServed;
  final List<int> penaltyServedLaps;
  final List<AppRaceControlMessage> raceControlMessages;
  final List<AppPitStop> pitStops;
  final String? totalPitTime;
  final Map<String, dynamic>? fastestPitStop;
  final String? averagePitTime;

  factory AppRaceResultRow.fromErgast(Map<String, dynamic> data) {
    final driverData = _coerceMap(data['Driver']);
    final givenName = driverData['givenName']?.toString().trim() ?? '';
    final familyName = driverData['familyName']?.toString().trim() ?? '';
    final fullName = '$givenName $familyName'.trim().isEmpty
        ? '-'
        : '$givenName $familyName'.trim();

    final grid = data['grid']?.toString() ?? '-';
    final finishPosition = int.tryParse(data['position']?.toString() ?? '');
    final startPosition = int.tryParse(grid);
    final finish = finishPosition == null
        ? (data['status']?.toString() ?? 'NC')
        : _formatFallbackFinish(finishPosition, startPosition);

    final timeData = _coerceMap(data['Time']);
    final timeText = timeData['time']?.toString();
    final fastestLapData = _coerceMap(data['FastestLap']);
    final fastestLapTime = _coerceMap(
      fastestLapData['Time'],
    )['time']?.toString();
    final fastestLapRank = int.tryParse(
      fastestLapData['rank']?.toString() ?? '',
    );
    final pointsValue = double.tryParse(data['points']?.toString() ?? '') ?? 0;

    return AppRaceResultRow(
      driver: fullName,
      start: grid,
      finish: finish,
      timeOrGap: timeText ?? (data['status']?.toString() ?? '-'),
      fastestLap: fastestLapTime ?? '-',
      tyreCompound: '-',
      penalty: '-',
      points: pointsValue == pointsValue.roundToDouble()
          ? pointsValue.toInt().toString()
          : pointsValue.toStringAsFixed(1),
      hasFastestLap: fastestLapRank == 1,
      tyreCompounds: const <String>[],
      tyreStints: const <AppTyreStint>[],
      tyreStrategy: '-',
      tyreChangeLaps: const <int>[],
      penaltyDetails: const <AppPenaltyDetail>[],
      penaltyServed: false,
      penaltyServedLaps: const <int>[],
      raceControlMessages: const <AppRaceControlMessage>[],
      pitStops: const <AppPitStop>[],
      totalPitTime: null,
      fastestPitStop: null,
      averagePitTime: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'start': start,
      'finish': finish,
      'timeOrGap': timeOrGap,
      'fastestLap': fastestLap,
      'tyreCompound': tyreCompound,
      'penalty': penalty,
      'points': points,
      'hasFastestLap': hasFastestLap,
      'tyreCompounds': tyreCompounds,
      'tyreStints': tyreStints.map((stint) => stint.toJson()).toList(),
      'tyreStrategy': tyreStrategy,
      'tyreChangeLaps': tyreChangeLaps,
      'penaltyDetails': penaltyDetails
          .map((detail) => detail.toJson())
          .toList(),
      'penaltyServed': penaltyServed,
      'penaltyServedLaps': penaltyServedLaps,
      'raceControlMessages': raceControlMessages
          .map((message) => message.toJson())
          .toList(),
      'pitStops': pitStops.map((stop) => stop.toJson()).toList(),
      'totalPitTime': totalPitTime,
      'fastestPitStop': fastestPitStop,
      'averagePitTime': averagePitTime,
    };
  }

  static Map<String, dynamic> _coerceMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, dynamic>{};
  }

  static String _formatFallbackFinish(int finishPosition, int? startPosition) {
    final finishLabel = 'P$finishPosition';
    if (startPosition == null || startPosition <= 0) {
      return finishLabel;
    }

    final delta = startPosition - finishPosition;
    final deltaLabel = delta > 0
        ? '+$delta'
        : delta < 0
        ? '$delta'
        : '-';
    return '$finishLabel ($deltaLabel)';
  }
}

class AppTyreStint {
  const AppTyreStint({
    required this.stint,
    required this.compound,
    required this.lapStart,
    required this.lapEnd,
    required this.changedOnLap,
  });

  final int stint;
  final String compound;
  final int lapStart;
  final int lapEnd;
  final int? changedOnLap;

  Map<String, dynamic> toJson() {
    return {
      'stint': stint,
      'compound': compound,
      'lapStart': lapStart,
      'lapEnd': lapEnd,
      'changedOnLap': changedOnLap,
    };
  }
}

class AppPenaltyDetail {
  const AppPenaltyDetail({
    required this.penalty,
    required this.reason,
    required this.issuedLap,
    required this.served,
    required this.servedLap,
  });

  final String penalty;
  final String? reason;
  final int? issuedLap;
  final bool served;
  final int? servedLap;

  Map<String, dynamic> toJson() {
    return {
      'penalty': penalty,
      'reason': reason,
      'issuedLap': issuedLap,
      'served': served,
      'servedLap': servedLap,
    };
  }
}

class AppRaceControlMessage {
  const AppRaceControlMessage({
    required this.timestampUtc,
    required this.lap,
    required this.category,
    required this.flag,
    required this.scope,
    required this.sector,
    required this.qualifyingPhase,
    required this.message,
    required this.sessionName,
  });

  final String? timestampUtc;
  final int? lap;
  final String? category;
  final String? flag;
  final String? scope;
  final int? sector;
  final String? qualifyingPhase;
  final String message;
  final String? sessionName;

  Map<String, dynamic> toJson() {
    return {
      'timestampUtc': timestampUtc,
      'lap': lap,
      'category': category,
      'flag': flag,
      'scope': scope,
      'sector': sector,
      'qualifyingPhase': qualifyingPhase,
      'message': message,
      'sessionName': sessionName,
    };
  }
}

class AppWeatherSample {
  const AppWeatherSample({
    required this.timestampUtc,
    required this.airTemperatureC,
    required this.trackTemperatureC,
    required this.humidity,
    required this.rainfall,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
  });

  final String? timestampUtc;
  final double? airTemperatureC;
  final double? trackTemperatureC;
  final double? humidity;
  final double? rainfall;
  final double? pressure;
  final double? windSpeed;
  final int? windDirection;

  Map<String, dynamic> toJson() {
    return {
      'timestampUtc': timestampUtc,
      'airTemperatureC': airTemperatureC,
      'trackTemperatureC': trackTemperatureC,
      'humidity': humidity,
      'rainfall': rainfall,
      'pressure': pressure,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
    };
  }
}

class AppPitStop {
  const AppPitStop({
    required this.stopNumber,
    required this.lap,
    required this.fromCompound,
    required this.toCompound,
    required this.pitTimestampUtc,
    required this.duration,
    required this.durationSeconds,
    required this.laneDurationSeconds,
    required this.stopDurationSeconds,
    required this.pitTypeDuration,
  });

  final int stopNumber;
  final int lap;
  final String fromCompound;
  final String toCompound;
  final String? pitTimestampUtc;
  final String? duration;
  final double? durationSeconds;
  final double? laneDurationSeconds;
  final double? stopDurationSeconds;
  final Map<String, dynamic> pitTypeDuration;

  Map<String, dynamic> toJson() {
    return {
      'stopNumber': stopNumber,
      'lap': lap,
      'fromCompound': fromCompound,
      'toCompound': toCompound,
      'pitTimestampUtc': pitTimestampUtc,
      'duration': duration,
      'durationSeconds': durationSeconds,
      'laneDurationSeconds': laneDurationSeconds,
      'stopDurationSeconds': stopDurationSeconds,
      'pitTypeDuration': pitTypeDuration,
    };
  }
}

class PitEvent {
  const PitEvent({
    required this.lapNumber,
    required this.date,
    required this.pitDuration,
    required this.laneDuration,
    required this.stopDuration,
  });

  const PitEvent.empty()
    : lapNumber = -1,
      date = null,
      pitDuration = null,
      laneDuration = null,
      stopDuration = null;

  final int lapNumber;
  final String? date;
  final double? pitDuration;
  final double? laneDuration;
  final double? stopDuration;
}

class _MutablePenaltyDetail {
  _MutablePenaltyDetail({required this.penalty, required this.reason});

  final String penalty;
  final String? reason;
  int? issuedLap;
  bool served = false;
  int? servedLap;

  AppPenaltyDetail build() {
    return AppPenaltyDetail(
      penalty: penalty,
      reason: reason,
      issuedLap: issuedLap,
      served: served,
      servedLap: servedLap,
    );
  }
}

class GenericRaceSummary {
  const GenericRaceSummary({
    required this.source,
    required this.fetchedAtUtc,
    required this.season,
    required this.round,
    required this.raceName,
    required this.raceDateUtc,
    required this.circuit,
    required this.results,
  });

  final String source;
  final DateTime fetchedAtUtc;
  final int season;
  final int round;
  final String raceName;
  final DateTime raceDateUtc;
  final CircuitSummary circuit;
  final List<GenericRaceResult> results;

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'fetchedAtUtc': fetchedAtUtc.toIso8601String(),
      'season': season,
      'round': round,
      'race': {
        'name': raceName,
        'dateUtc': raceDateUtc.toIso8601String(),
        'circuit': circuit.toJson(),
      },
      'results': results.map((result) => result.toJson()).toList(),
    };
  }
}

class CircuitSummary {
  const CircuitSummary({
    required this.id,
    required this.name,
    required this.country,
    required this.locality,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String country;
  final String locality;
  final String? latitude;
  final String? longitude;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'locality': locality,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class GenericRaceResult {
  const GenericRaceResult({
    required this.position,
    required this.positionText,
    required this.points,
    required this.grid,
    required this.laps,
    required this.status,
    required this.driver,
    required this.constructorName,
    required this.time,
    required this.fastestLap,
  });

  final int? position;
  final String positionText;
  final double points;
  final int? grid;
  final int? laps;
  final String status;
  final DriverSummary driver;
  final String constructorName;
  final ResultTimeSummary? time;
  final FastestLapSummary? fastestLap;

  factory GenericRaceResult.fromErgast(Map<String, dynamic> data) {
    final driverData = _coerceMap(data['Driver']);
    final constructorData = _coerceMap(data['Constructor']);
    final timeData = data['Time'];
    final fastestLapData = data['FastestLap'];

    return GenericRaceResult(
      position: int.tryParse(data['position']?.toString() ?? ''),
      positionText: data['positionText']?.toString() ?? '-',
      points: double.tryParse(data['points']?.toString() ?? '') ?? 0,
      grid: int.tryParse(data['grid']?.toString() ?? ''),
      laps: int.tryParse(data['laps']?.toString() ?? ''),
      status: data['status']?.toString() ?? '-',
      driver: DriverSummary(
        driverId: driverData['driverId']?.toString() ?? '-',
        permanentNumber: driverData['permanentNumber']?.toString(),
        code: driverData['code']?.toString(),
        givenName: driverData['givenName']?.toString() ?? '-',
        familyName: driverData['familyName']?.toString() ?? '-',
        nationality: driverData['nationality']?.toString(),
      ),
      constructorName: constructorData['name']?.toString() ?? '-',
      time: timeData == null
          ? null
          : ResultTimeSummary(
              millis: int.tryParse(
                _coerceMap(timeData)['millis']?.toString() ?? '',
              ),
              display: _coerceMap(timeData)['time']?.toString() ?? '-',
            ),
      fastestLap: fastestLapData == null
          ? null
          : FastestLapSummary.fromErgast(_coerceMap(fastestLapData)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'positionText': positionText,
      'points': points,
      'grid': grid,
      'laps': laps,
      'status': status,
      'driver': driver.toJson(),
      'constructor': constructorName,
      'time': time?.toJson(),
      'fastestLap': fastestLap?.toJson(),
    };
  }

  static Map<String, dynamic> _coerceMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, dynamic>{};
  }
}

class DriverSummary {
  const DriverSummary({
    required this.driverId,
    required this.permanentNumber,
    required this.code,
    required this.givenName,
    required this.familyName,
    required this.nationality,
  });

  final String driverId;
  final String? permanentNumber;
  final String? code;
  final String givenName;
  final String familyName;
  final String? nationality;

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'permanentNumber': permanentNumber,
      'code': code,
      'givenName': givenName,
      'familyName': familyName,
      'fullName': '$givenName $familyName',
      'nationality': nationality,
    };
  }
}

class ResultTimeSummary {
  const ResultTimeSummary({required this.millis, required this.display});

  final int? millis;
  final String display;

  Map<String, dynamic> toJson() {
    return {'millis': millis, 'display': display};
  }
}

class FastestLapSummary {
  const FastestLapSummary({
    required this.rank,
    required this.lap,
    required this.time,
    required this.averageSpeedKph,
  });

  final int? rank;
  final int? lap;
  final String? time;
  final double? averageSpeedKph;

  factory FastestLapSummary.fromErgast(Map<String, dynamic> data) {
    final timeData = GenericRaceResult._coerceMap(data['Time']);
    final averageSpeedData = GenericRaceResult._coerceMap(data['AverageSpeed']);

    return FastestLapSummary(
      rank: int.tryParse(data['rank']?.toString() ?? ''),
      lap: int.tryParse(data['lap']?.toString() ?? ''),
      time: timeData['time']?.toString(),
      averageSpeedKph: double.tryParse(
        averageSpeedData['speed']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'lap': lap,
      'time': time,
      'averageSpeedKph': averageSpeedKph,
    };
  }
}

class FastestLapDetails {
  const FastestLapDetails({
    required this.duration,
    required this.lapNumber,
    required this.compound,
  });

  final double duration;
  final int lapNumber;
  final String compound;
}

class CliUsageException implements Exception {
  const CliUsageException(this.message);

  final String message;
}

class FetchException implements Exception {
  const FetchException(this.message);

  final String message;
}
