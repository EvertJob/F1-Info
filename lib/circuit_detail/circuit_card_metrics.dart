import 'dart:convert';

import 'package:f1/circuit_detail/circuit_data.dart';

/// Snapshot of [Race] fields needed for the circuits catalog (avoids importing `main.dart`).
class CircuitCatalogRaceInput {
  const CircuitCatalogRaceInput({
    required this.flag,
    required this.circuitAssetId,
    required this.circuitDisplayName,
    required this.grandPrixName,
    required this.country,
    required this.calendarYear,
    required this.lengthMeters,
    required this.laps,
    required this.topSpeedRaw,
    required this.lapRecordTime,
    required this.characteristicsEn,
    required this.characteristicsNl,
  });

  final String flag;
  final String circuitAssetId;
  final String circuitDisplayName;
  final String grandPrixName;
  final String country;
  final int calendarYear;
  final int lengthMeters;
  final int laps;
  final String topSpeedRaw;
  final String lapRecordTime;
  final List<String> characteristicsEn;
  final List<String> characteristicsNl;
}

/// Summary stats from `assets/data/circuits/*.json` with [CircuitCatalogRaceInput] fallback.
class CircuitCardMetrics {
  const CircuitCardMetrics({
    required this.name,
    required this.location,
    required this.lengthKm,
    required this.laps,
    required this.topSpeedKmh,
    this.trackTypeL10nKey,
    required this.lapRecordTime,
    this.timezoneZoneName,
    this.timezoneUtcOffset,
    this.lapRecordDriver,
    this.lapRecordTeam,
    this.lapRecordYear,
  });

  final String name;
  final String location;
  final double lengthKm;
  final int laps;
  final int topSpeedKmh;
  final String? trackTypeL10nKey;
  final String lapRecordTime;

  /// IANA-style short name + offset from `live_ambient_status.local_time_zone` in circuit JSON.
  final String? timezoneZoneName;
  final String? timezoneUtcOffset;

  final String? lapRecordDriver;
  final String? lapRecordTeam;
  final int? lapRecordYear;

  /// Single line for the hero (e.g. `CET · UTC+1`).
  String get timezoneDisplayLine {
    final z = timezoneZoneName?.trim();
    final u = timezoneUtcOffset?.trim();
    if (z != null && z.isNotEmpty && u != null && u.isNotEmpty) {
      return '$z · $u';
    }
    if (z != null && z.isNotEmpty) return z;
    if (u != null && u.isNotEmpty) return u;
    return '';
  }

  /// e.g. `AEDT (UTC+11)` for compact header lines.
  String get timezoneParenLine {
    final z = timezoneZoneName?.trim();
    final u = timezoneUtcOffset?.trim();
    if (z != null && z.isNotEmpty && u != null && u.isNotEmpty) {
      return '$z ($u)';
    }
    return timezoneDisplayLine;
  }

  static CircuitCardMetrics fromRaceInput(CircuitCatalogRaceInput race) {
    return CircuitCardMetrics(
      name: race.circuitDisplayName.trim().isNotEmpty
          ? race.circuitDisplayName
          : race.grandPrixName,
      location: race.country,
      lengthKm: race.lengthMeters / 1000.0,
      laps: race.laps,
      topSpeedKmh: _parseTopSpeedKmh(race.topSpeedRaw) ?? 0,
      trackTypeL10nKey: _inferTrackTypeKey(race),
      lapRecordTime: race.lapRecordTime,
      timezoneZoneName: null,
      timezoneUtcOffset: null,
      lapRecordDriver: null,
      lapRecordTeam: null,
      lapRecordYear: null,
    );
  }

  static CircuitCardMetrics fromJsonString(String raw, CircuitCatalogRaceInput race) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return fromRaceInput(race);
      }
      final map = Map<String, dynamic>.from(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
      return tryParseJson(map, race) ?? fromRaceInput(race);
    } catch (_) {
      return fromRaceInput(race);
    }
  }

  static CircuitCardMetrics? tryParseJson(
    Map<String, dynamic> json,
    CircuitCatalogRaceInput race,
  ) {
    final name = json['name']?.toString().trim() ?? '';
    final location = json['location']?.toString().trim() ?? '';

    Map<String, dynamic>? track;
    Map<String, dynamic>? perf;
    Map<String, dynamic>? hist;
    Map<String, dynamic>? ambient;

    final cats = json['categories'];
    if (cats is List) {
      for (final c in cats) {
        if (c is! Map) continue;
        final id = c['category_id']?.toString();
        final dp = c['data_points'];
        if (dp is! Map) continue;
        final m = Map<String, dynamic>.from(
          dp.map((k, v) => MapEntry(k.toString(), v)),
        );
        switch (id) {
          case 'track_geometry':
            track = m;
          case 'performance_risk':
            perf = m;
          case 'historical_era':
            hist = m;
          case 'live_ambient_status':
            ambient = m;
        }
      }
    }

    final lengthM = _asNum(track?['length_m']);
    final laps = _asInt(track?['laps']);
    final topKmh = _asInt(perf?['top_speed_kmh']);
    final typeKey = track?['track_type_l10n']?.toString().trim();

    String? tzName;
    String? tzOffset;
    final ltz = ambient?['local_time_zone'];
    if (ltz is Map) {
      tzName = ltz['zone_name']?.toString().trim();
      tzOffset = ltz['utc_offset']?.toString().trim();
      if (tzName != null && tzName.isEmpty) tzName = null;
      if (tzOffset != null && tzOffset.isEmpty) tzOffset = null;
    }

    var lapTime = '';
    String? lapDriver;
    String? lapTeam;
    int? lapYear;
    final lrd = hist?['lap_record_detail'];
    if (lrd is Map) {
      lapTime = lrd['time']?.toString().trim() ?? '';
      lapDriver = lrd['driver']?.toString().trim();
      lapTeam = lrd['team']?.toString().trim();
      if (lapDriver != null && lapDriver.isEmpty) lapDriver = null;
      if (lapTeam != null && lapTeam.isEmpty) lapTeam = null;
      lapYear = _asInt(lrd['year']);
    }

    return CircuitCardMetrics(
      name: name.isNotEmpty
          ? name
          : (race.circuitDisplayName.trim().isNotEmpty
              ? race.circuitDisplayName
              : race.grandPrixName),
      location: location.isNotEmpty ? location : race.country,
      lengthKm: lengthM != null ? lengthM / 1000.0 : race.lengthMeters / 1000.0,
      laps: laps ?? race.laps,
      topSpeedKmh: topKmh ?? _parseTopSpeedKmh(race.topSpeedRaw) ?? 0,
      trackTypeL10nKey: (typeKey != null && typeKey.isNotEmpty)
          ? typeKey
          : _inferTrackTypeKey(race),
      lapRecordTime: lapTime.isNotEmpty ? lapTime : race.lapRecordTime,
      timezoneZoneName: tzName,
      timezoneUtcOffset: tzOffset,
      lapRecordDriver: lapDriver,
      lapRecordTeam: lapTeam,
      lapRecordYear: lapYear,
    );
  }

  /// Parsed from [CircuitData.categories] for the JSON circuit hub hero.
  static CircuitCardMetrics fromCircuitData(CircuitData data) {
    Map<String, dynamic>? track;
    Map<String, dynamic>? perf;
    Map<String, dynamic>? hist;
    Map<String, dynamic>? ambient;
    for (final cat in data.categories) {
      switch (cat.categoryId) {
        case 'track_geometry':
          track = cat.dataPoints;
          break;
        case 'performance_risk':
          perf = cat.dataPoints;
          break;
        case 'historical_era':
          hist = cat.dataPoints;
          break;
        case 'live_ambient_status':
          ambient = cat.dataPoints;
          break;
      }
    }
    final lengthM = _asNum(track?['length_m']);
    final laps = _asInt(track?['laps']) ?? 0;
    final topKmh = _asInt(perf?['top_speed_kmh']) ?? 0;
    final typeKey = track?['track_type_l10n']?.toString().trim();
    String? tzName;
    String? tzOffset;
    final ltz = ambient?['local_time_zone'];
    if (ltz is Map) {
      tzName = ltz['zone_name']?.toString().trim();
      tzOffset = ltz['utc_offset']?.toString().trim();
      if (tzName != null && tzName.isEmpty) tzName = null;
      if (tzOffset != null && tzOffset.isEmpty) tzOffset = null;
    }
    var lapTime = '';
    String? lapDriver;
    String? lapTeam;
    int? lapYear;
    final lrd = hist?['lap_record_detail'];
    if (lrd is Map) {
      lapTime = lrd['time']?.toString().trim() ?? '';
      lapDriver = lrd['driver']?.toString().trim();
      lapTeam = lrd['team']?.toString().trim();
      if (lapDriver != null && lapDriver.isEmpty) lapDriver = null;
      if (lapTeam != null && lapTeam.isEmpty) lapTeam = null;
      lapYear = _asInt(lrd['year']);
    }
    final displayName =
        data.name.trim().isNotEmpty ? data.name.trim() : data.circuitId;
    return CircuitCardMetrics(
      name: displayName,
      location: data.location.trim().isNotEmpty ? data.location.trim() : '—',
      lengthKm: lengthM != null ? lengthM / 1000.0 : 0,
      laps: laps,
      topSpeedKmh: topKmh,
      trackTypeL10nKey:
          (typeKey != null && typeKey.isNotEmpty) ? typeKey : null,
      lapRecordTime: lapTime.isNotEmpty ? lapTime : '—',
      timezoneZoneName: tzName,
      timezoneUtcOffset: tzOffset,
      lapRecordDriver: lapDriver,
      lapRecordTeam: lapTeam,
      lapRecordYear: lapYear,
    );
  }

  static int? _parseTopSpeedKmh(String raw) {
    final m = RegExp(r'(\d+)').firstMatch(raw);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  static String? _inferTrackTypeKey(CircuitCatalogRaceInput race) {
    final blob = [
      ...race.characteristicsEn,
      ...race.characteristicsNl,
    ].join(' ').toLowerCase();
    if (blob.contains('street') ||
        blob.contains('straten') ||
        blob.contains('urban')) {
      return 'type_street_circuit';
    }
    if (blob.contains('permanent')) {
      return 'type_permanent_circuit';
    }
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  static double? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
