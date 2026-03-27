import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../f1_asset_resolver.dart';
import '../local/models/race_result.dart';

class F1RemoteApiService {
  F1RemoteApiService();

  Future<List<RaceResult>> fetchRaceResults({
    required int season,
    required int round,
  }) async {
    final venue = F1AssetResolver.venueFolderForYearAndRound(season, round);
    final candidates = <String>[];
    if (venue != null) {
      candidates.addAll(
        F1AssetResolver.candidateRaceResultPaths(year: season, venueFolder: venue),
      );
    }
    candidates.addAll(F1AssetResolver.legacyRoundResultPaths(season, round));

    Object? lastError;
    for (final assetPath in candidates) {
      try {
        final jsonString = await rootBundle.loadString(assetPath);
        final results = _parseLocalResults(
          jsonString,
          season: season,
          round: round,
        );
        if (results.isNotEmpty) {
          return results;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw RemoteDataException(
      'Failed to load local results for $season round $round: $lastError',
    );
  }

  Future<List<RaceResult>> fetchLatestRaceResults() async {
    const latestSeason = 2026;
    const latestRound = 1;
    return fetchRaceResults(season: latestSeason, round: latestRound);
  }

  List<RaceResult> _parseLocalResults(
    String body, {
    required int season,
    required int round,
  }) {
    final decoded = jsonDecode(body);
    final List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      rawList = decoded['results'] as List<dynamic>;
    } else {
      return const <RaceResult>[];
    }

    if (rawList.isEmpty) {
      return const <RaceResult>[];
    }

    final first = rawList.first;
    if (first is! Map) {
      return const <RaceResult>[];
    }
    final firstMap = first.map((k, v) => MapEntry(k.toString(), v));
    final openF1Shape = firstMap.containsKey('broadcastName') ||
        firstMap.containsKey('driverNumber');

    if (openF1Shape) {
      return rawList
          .whereType<Map>()
          .map(
            (e) => RaceResult.fromOpenF1Row(
              e.map((k, v) => MapEntry(k.toString(), v)),
              season: season,
              round: round,
            ),
          )
          .toList(growable: false);
    }

    return rawList
        .whereType<Map>()
        .map(
          (json) => RaceResult.fromJson(
            json.map((k, v) => MapEntry(k.toString(), v)),
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
