import 'package:hive/hive.dart';

import '../local/hive/hive_boxes.dart';
import '../local/models/race_result.dart';
import '../local/models/race_results_cache.dart';
import '../remote/f1_remote_api_service.dart';

class RaceRepository {
  factory RaceRepository.standard() {
    return RaceRepository(apiService: F1RemoteApiService());
  }

  RaceRepository({
    required F1RemoteApiService apiService,
    Box<RaceResultsCache>? cacheBox,
  }) : _apiService = apiService,
       _cacheBox =
           cacheBox ?? Hive.box<RaceResultsCache>(HiveBoxes.raceResults);

  final F1RemoteApiService _apiService;
  final Box<RaceResultsCache> _cacheBox;

  /// Cache-first flow:
  /// 1. Return non-stale Hive data immediately when available.
  /// 2. Otherwise fetch remote data.
  /// 3. Persist the fresh payload into Hive.
  /// 4. Return the fresh payload.
  Future<List<RaceResult>> getRaceResults({
    required int season,
    required int round,
    Duration maxAge = const Duration(hours: 6),
  }) async {
    final cacheKey = _raceKey(season: season, round: round);
    final cached = _cacheBox.get(cacheKey);

    if (cached != null &&
        cached.results.isNotEmpty &&
        !cached.isStale(maxAge)) {
      return cached.results;
    }

    final freshResults = await _apiService.fetchRaceResults(
      season: season,
      round: round,
    );

    final cacheEntry = RaceResultsCache(
      cacheKey: cacheKey,
      fetchedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      results: freshResults,
    );

    await _cacheBox.put(cacheKey, cacheEntry);
    return freshResults;
  }

  /// Bypasses the local cache so an AI-triggered command can force a sync.
  Future<List<RaceResult>> forceRefreshLatestResults() async {
    final latestResults = await _apiService.fetchLatestRaceResults();
    if (latestResults.isEmpty) {
      return const <RaceResult>[];
    }

    final season = latestResults.first.season;
    final round = latestResults.first.round;
    final cacheKey = _raceKey(season: season, round: round);

    await _cacheBox.put(
      cacheKey,
      RaceResultsCache(
        cacheKey: cacheKey,
        fetchedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        results: latestResults,
      ),
    );

    return latestResults;
  }

  String _raceKey({required int season, required int round}) {
    return 'race_results_${season}_$round';
  }
}
