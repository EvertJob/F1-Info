import 'dart:convert';

import 'package:http/http.dart' as http;

import '../local/models/race_result.dart';

class F1RemoteApiService {
  /// Placeholder remote service.
  ///
  /// The default implementation reads Jolpica/Ergast-compatible JSON so the
  /// repository can be wired immediately, but this class is isolated so you can
  /// swap in OpenF1-specific endpoints later without touching cache logic.
  F1RemoteApiService({
    http.Client? client,
    this.ergastBaseUrl = 'https://api.jolpi.ca/ergast/f1',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String ergastBaseUrl;

  Future<List<RaceResult>> fetchRaceResults({
    required int season,
    required int round,
  }) async {
    final uri = Uri.parse('$ergastBaseUrl/$season/$round/results.json');
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteDataException(
        'Failed to fetch race results for season $season round $round.',
      );
    }

    return _parseErgastResults(
      response.body,
      fallbackSeason: season,
      fallbackRound: round,
    );
  }

  Future<List<RaceResult>> fetchLatestRaceResults() async {
    final uri = Uri.parse('$ergastBaseUrl/current/last/results.json');
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RemoteDataException('Failed to fetch latest race results.');
    }

    return _parseErgastResults(response.body);
  }

  List<RaceResult> _parseErgastResults(
    String body, {
    int? fallbackSeason,
    int? fallbackRound,
  }) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final mrData = decoded['MRData'] as Map<String, dynamic>? ?? const {};
    final raceTable = mrData['RaceTable'] as Map<String, dynamic>? ?? const {};
    final races = (raceTable['Races'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    if (races.isEmpty) {
      return const <RaceResult>[];
    }

    final race = races.first;
    final season =
        int.tryParse((race['season'] ?? fallbackSeason ?? 0).toString()) ?? 0;
    final round =
        int.tryParse((race['round'] ?? fallbackRound ?? 0).toString()) ?? 0;
    final grandPrixName = (race['raceName'] ?? '').toString();
    final results = (race['Results'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    return results
        .map(
          (json) => RaceResult.fromErgastJson(
            json,
            season: season,
            round: round,
            grandPrixName: grandPrixName,
          ),
        )
        .toList(growable: false);
  }
}

class RemoteDataException implements Exception {
  const RemoteDataException(this.message);

  final String message;

  @override
  String toString() => 'RemoteDataException: $message';
}
