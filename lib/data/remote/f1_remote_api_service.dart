
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../local/models/race_result.dart';


class F1RemoteApiService {
  F1RemoteApiService();


  Future<List<RaceResult>> fetchRaceResults({
    required int season,
    required int round,
  }) async {
    final assetPath = 'assets/data/results/${season}_$round.json';
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return _parseLocalResults(jsonString, season: season, round: round);
    } catch (e) {
      throw RemoteDataException('Failed to load local results for $season round $round: $e');
    }
  }


  Future<List<RaceResult>> fetchLatestRaceResults() async {
    // Zoek het laatste beschikbare bestand in assets/data/results/
    // Dit vereist dat je een lijst van beschikbare races bijhoudt, of een conventie gebruikt.
    // Hier een simpele placeholder die altijd 2025_22.json probeert te laden:
    const latestSeason = 2025;
    const latestRound = 22;
    return fetchRaceResults(season: latestSeason, round: latestRound);
  }


  List<RaceResult> _parseLocalResults(
    String body, {
    required int season,
    required int round,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      // Verwacht een lijst van resultaten direct
      return decoded.map<RaceResult>((json) => RaceResult.fromJson(json)).toList(growable: false);
    } else if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      // Of een object met een 'results' key
      return (decoded['results'] as List)
          .map<RaceResult>((json) => RaceResult.fromJson(json))
          .toList(growable: false);
    } else {
      return const <RaceResult>[];
    }
  }
}

class RemoteDataException implements Exception {
  const RemoteDataException(this.message);

  final String message;

  @override
  String toString() => 'RemoteDataException: $message';
}
