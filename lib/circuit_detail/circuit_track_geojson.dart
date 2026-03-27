import 'dart:convert';

import 'package:f1/orbit/orbit_data.dart';
import 'package:f1/orbit/orbit_technical_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Bundled track layout: `assets/data/circuits/geojson/{stem}.geojson`.
String circuitGeoJsonAssetPath(String stem) =>
    'assets/data/circuits/geojson/$stem.geojson';

/// Strips `circuit_` prefix so legacy network URLs match `bacinger/f1-circuits` stems.
String orbitGeoJsonStemForCircuitId(String circuitId) {
  const prefix = 'circuit_';
  if (circuitId.startsWith(prefix)) {
    return circuitId.substring(prefix.length);
  }
  return circuitId;
}

/// Maps app [CircuitData.circuit_id] to GeoJSON filename stems (bacinger `id`, e.g. `nl-1948`).
const Map<String, String> kCircuitIdToGeoJsonStem = {
  'albert_park': 'au-1953',
  'shanghai_international': 'cn-2004',
  'suzuka_circuit': 'jp-1962',
  'bahrain_international': 'bh-2002',
  'jeddah_corniche': 'sa-2021',
  'miami_autodrome': 'us-2022',
  'gilles_villeneuve': 'ca-1978',
  'circuit_de_monaco': 'mc-1929',
  'circuit_barcelona_catalunya': 'es-1991',
  'red_bull_ring': 'at-1969',
  'silverstone_circuit': 'gb-1948',
  'spa_francorchamps': 'be-1925',
  'hungaroring': 'hu-1986',
  'circuit_zandvoort': 'nl-1948',
  'monza_circuit': 'it-1922',
  'madrid_madring': 'es-2026',
  'baku_city_circuit': 'az-2016',
  'marina_bay_circuit': 'sg-2008',
  'circuit_of_the_americas': 'us-2012',
  'hermanos_rodriguez': 'mx-1962',
  'interlagos_circuit': 'br-1940',
  'las_vegas_strip': 'us-2023',
  'lusail_circuit': 'qa-2004',
  'yas_marina': 'ae-2009',
};

/// Technische layout (`{stem}-details.geojson`).
///
/// Flutter bundelt `assets/data/circuits/` alleen met **directe** bestanden, niet met
/// `geojson/` tenzij die map apart in pubspec staat. Daarom eerst `geojson/`, dan root
/// `circuits/` als fallback (zoals `nl-1948-details.geojson`).
List<String> circuitDetailsGeoJsonCandidatePaths(String circuitId) {
  final stem = kCircuitIdToGeoJsonStem[circuitId];
  if (stem == null) return const [];
  return <String>[
    'assets/data/circuits/geojson/$stem-details.geojson',
    'assets/data/circuits/$stem-details.geojson',
  ];
}

/// Eerste bekende path (bv. documentatie); gebruik [loadCircuitDetailsMapOverlay] om te laden.
String? circuitDetailsGeoJsonAssetPath(String circuitId) {
  final paths = circuitDetailsGeoJsonCandidatePaths(circuitId);
  return paths.isEmpty ? null : paths.first;
}

/// Bocht-/POI-punt uit `*-details.geojson` (Point features).
class CircuitDetailCornerPoint {
  const CircuitDetailCornerPoint({
    required this.point,
    required this.name,
    this.number,
    this.isBanked = false,
  });

  final LatLng point;
  final String name;
  final int? number;
  final bool isBanked;
}

/// Sectoren (kleur/ dikte), timing gates en bochten voor de circuitkaart in Details-modus.
class CircuitDetailsMapOverlay {
  const CircuitDetailsMapOverlay({
    required this.technical,
    required this.corners,
    this.fallbackPlainSegments,
  });

  /// Geparset met [OrbitDataService.parseCircuitTechnicalDetail] (stroke, stroke-width, S1–S3).
  final OrbitCircuitTechnicalDetail? technical;

  /// Point-features (T1, T2, …).
  final List<CircuitDetailCornerPoint> corners;

  /// Alleen als er geen geldige sector-metadata is: kale LineStrings.
  final List<List<LatLng>>? fallbackPlainSegments;

  bool get hasTrackData =>
      (technical != null && !technical!.isEmpty) ||
      (fallbackPlainSegments != null && fallbackPlainSegments!.isNotEmpty);

  /// Polylijnen voor camera-bounds en fallback-tekening.
  List<List<LatLng>> segmentsForBounds() {
    if (technical != null && !technical!.isEmpty) {
      final out = <List<LatLng>>[];
      for (final s in technical!.sectors) {
        if (s.points.length >= 2) out.add(s.points);
      }
      for (final g in technical!.gates) {
        if (g.points.length >= 2) out.add(g.points);
      }
      return out;
    }
    return fallbackPlainSegments ?? const [];
  }
}

List<CircuitDetailCornerPoint> parseCircuitDetailCornerPoints(String raw) {
  final out = <CircuitDetailCornerPoint>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return out;
    final features = decoded['features'];
    if (features is! List<dynamic>) return out;

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final geom = f['geometry'];
      if (geom is! Map<String, dynamic>) continue;
      if (geom['type']?.toString() != 'Point') continue;
      final coords = geom['coordinates'];
      if (coords is! List<dynamic> || coords.length < 2) continue;

      final props = f['properties'];
      final propMap =
          props is Map
              ? props.map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

      final lon = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      final name = propMap['name']?.toString() ?? '';
      final numRaw = propMap['number'];
      int? n;
      if (numRaw is int) {
        n = numRaw;
      } else {
        n = int.tryParse(numRaw?.toString() ?? '');
      }
      final banked = propMap['is_banked'] == true;
      out.add(
        CircuitDetailCornerPoint(
          point: LatLng(lat, lon),
          name: name,
          number: n,
          isBanked: banked,
        ),
      );
    }
  } on Object catch (_) {}
  return out;
}

/// Laadt `*-details.geojson`: sectoren met GeoJSON-kleuren, gates, bochten.
Future<CircuitDetailsMapOverlay?> loadCircuitDetailsMapOverlay({
  required AssetBundle bundle,
  required String circuitId,
}) async {
  final paths = circuitDetailsGeoJsonCandidatePaths(circuitId);
  if (paths.isEmpty) return null;

  String? raw;
  for (final path in paths) {
    try {
      raw = await bundle.loadString(path);
      break;
    } on Object catch (_) {}
    try {
      raw = await rootBundle.loadString(path);
      break;
    } on Object catch (_) {}
  }
  if (raw == null) return null;

  final technical = OrbitDataService.parseCircuitTechnicalDetail(raw);
  final corners = parseCircuitDetailCornerPoints(raw);

  if (technical != null && !technical.isEmpty) {
    return CircuitDetailsMapOverlay(technical: technical, corners: corners);
  }

  final plain =
      OrbitDataService.parseTrackSegments(raw)
          .where((s) => s.length >= 2)
          .toList();
  if (plain.isEmpty) return null;

  return CircuitDetailsMapOverlay(
    technical: null,
    corners: corners,
    fallbackPlainSegments: plain,
  );
}

/// Candidate asset stems: prefer explicit [circuitId] filename, then mapped championship id.
List<String> _assetCandidateStems(String circuitId) {
  final mapped = kCircuitIdToGeoJsonStem[circuitId];
  if (mapped != null && mapped != circuitId) {
    return <String>[circuitId, mapped];
  }
  return <String>[circuitId];
}

/// Network fallbacks after bundled assets (order: known bacinger id, then legacy stem).
List<String> _networkCandidateStems(String circuitId) {
  final mapped = kCircuitIdToGeoJsonStem[circuitId];
  final legacy = orbitGeoJsonStemForCircuitId(circuitId);
  if (mapped != null) {
    if (mapped == legacy) return <String>[mapped];
    return <String>[mapped, legacy];
  }
  return <String>[legacy];
}

/// Reads GeoJSON from assets (and optionally falls back to [OrbitDataService] HTTP).
Future<List<List<LatLng>>> loadCircuitTrackSegments({
  required AssetBundle bundle,
  required String circuitId,
  bool useNetworkFallback = true,
}) async {
  for (final stem in _assetCandidateStems(circuitId)) {
    try {
      final raw = await bundle.loadString(circuitGeoJsonAssetPath(stem));
      final segs = OrbitDataService.parseTrackSegments(raw);
      if (segs.isNotEmpty) return segs;
    } on Object catch (_) {
      continue;
    }
  }

  if (useNetworkFallback) {
    for (final stem in _networkCandidateStems(circuitId)) {
      try {
        final segs = await OrbitDataService.instance.fetchTrackSegments(stem);
        if (segs.isNotEmpty) return segs;
      } on Object catch (_) {
        continue;
      }
    }
  }

  throw StateError('No track GeoJSON for circuit_id=$circuitId');
}

/// Returns a growable list (flutter_map uses [List] on [PolylineLayer], not a [Set]).
List<Polyline> polylinesFromTrackSegments(
  List<List<LatLng>> segments, {
  required Color strokeColor,
  double strokeWidth = 4,
  Color? outerStrokeColor,
  double outerStrokeWidth = 6,
}) {
  final out = <Polyline>[];
  final outer = outerStrokeColor;
  for (final seg in segments) {
    if (seg.length < 2) continue;
    if (outer != null) {
      out.add(
        Polyline(
          points: seg,
          strokeWidth: outerStrokeWidth,
          color: outer,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }
    out.add(
      Polyline(
        points: seg,
        strokeWidth: strokeWidth,
        color: strokeColor,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    );
  }
  return out;
}
