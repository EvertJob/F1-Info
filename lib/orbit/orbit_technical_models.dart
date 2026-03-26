import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// One sector polyline from a `*-details.geojson` feature (Name contains "Sector").
class OrbitSectorStroke {
  const OrbitSectorStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.label,
  });

  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  /// Short label for map chip, e.g. "S1".
  final String label;

  LatLng get midpoint {
    if (points.isEmpty) return const LatLng(0, 0);
    return points[points.length ~/ 2];
  }
}

/// Timing gate / sector boundary line (`properties.type == timing_gate`).
class OrbitTimingGateStroke {
  const OrbitTimingGateStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
}

/// Parsed technical overlay for one circuit (optional asset).
class OrbitCircuitTechnicalDetail {
  const OrbitCircuitTechnicalDetail({
    required this.sectors,
    required this.gates,
  });

  final List<OrbitSectorStroke> sectors;
  final List<OrbitTimingGateStroke> gates;

  bool get isEmpty => sectors.isEmpty && gates.isEmpty;
}
