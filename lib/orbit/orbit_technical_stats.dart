import 'dart:convert';
import 'dart:math' as math;

import 'package:f1/widgets/f1_elevation_chart.dart';

/// Lap metrics derived from `geojson/*-details.geojson` + elevation profile.
class OrbitTechnicalStats {
  const OrbitTechnicalStats({
    required this.lapLengthKm,
    required this.maxElevationDeltaM,
    required this.bankedTurnsCount,
  });

  /// Total lap length from cumulative profile distance (km).
  final double lapLengthKm;

  /// Max − min altitude along profile (m).
  final double maxElevationDeltaM;

  /// Corners with `banking` over [bankingThresholdDeg] (steep banked).
  final int bankedTurnsCount;

  /// Banking above this counts as “banked” (matches ~3 at Zandvoort).
  static const double bankingThresholdDeg = 5.01;
}

/// Returns `null` if JSON or profile is unusable.
OrbitTechnicalStats? computeOrbitTechnicalStats(
  String? geoJson,
  List<ElevationPoint>? points,
) {
  if (geoJson == null ||
      geoJson.isEmpty ||
      points == null ||
      points.length < 2) {
    return null;
  }
  Map<String, dynamic> map;
  try {
    final d = jsonDecode(geoJson);
    if (d is! Map<String, dynamic>) return null;
    map = d;
  } catch (_) {
    return null;
  }

  var banked = 0;
  final features = map['features'];
  if (features is List) {
    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final geom = f['geometry'];
      if (geom is! Map<String, dynamic>) continue;
      if (geom['type'] != 'Point') continue;
      final props = f['properties'];
      if (props is! Map<String, dynamic>) continue;
      final b = props['banking'];
      if (b is num && b.toDouble() > OrbitTechnicalStats.bankingThresholdDeg) {
        banked++;
      }
    }
  }

  final alts = points.map((e) => e.altitude).toList(growable: false);
  final minA = alts.reduce(math.min);
  final maxA = alts.reduce(math.max);
  final lapM = points.last.distance;

  return OrbitTechnicalStats(
    lapLengthKm: lapM / 1000.0,
    maxElevationDeltaM: maxA - minA,
    bankedTurnsCount: banked,
  );
}
