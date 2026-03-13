import 'package:hive/hive.dart';

import 'race_result.dart';

class RaceResultsCacheFields {
  static const int cacheKey = 0;
  static const int fetchedAtEpochMs = 1;
  static const int results = 2;
}

class RaceResultsCache {
  /// Wraps cached results together with fetch metadata for stale checks.
  const RaceResultsCache({
    required this.cacheKey,
    required this.fetchedAtEpochMs,
    required this.results,
  });

  final String cacheKey;
  final int fetchedAtEpochMs;
  final List<RaceResult> results;

  DateTime get fetchedAt =>
      DateTime.fromMillisecondsSinceEpoch(fetchedAtEpochMs);

  bool isStale(Duration maxAge) {
    return DateTime.now().difference(fetchedAt) > maxAge;
  }
}

class RaceResultsCacheAdapter extends TypeAdapter<RaceResultsCache> {
  @override
  final int typeId = 1;

  @override
  RaceResultsCache read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return RaceResultsCache(
      cacheKey: fields[RaceResultsCacheFields.cacheKey] as String,
      fetchedAtEpochMs: fields[RaceResultsCacheFields.fetchedAtEpochMs] as int,
      results: (fields[RaceResultsCacheFields.results] as List)
          .cast<RaceResult>(),
    );
  }

  @override
  void write(BinaryWriter writer, RaceResultsCache obj) {
    writer
      ..writeByte(3)
      ..writeByte(RaceResultsCacheFields.cacheKey)
      ..write(obj.cacheKey)
      ..writeByte(RaceResultsCacheFields.fetchedAtEpochMs)
      ..write(obj.fetchedAtEpochMs)
      ..writeByte(RaceResultsCacheFields.results)
      ..write(obj.results);
  }
}
