import 'package:f1/circuit_detail/circuit_data.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Center + padded pan bounds for the embedded circuit map.
class CircuitMapPlacement {
  const CircuitMapPlacement({
    required this.center,
    required this.panBounds,
    this.lengthMeters,
  });

  final LatLng center;
  final LatLngBounds panBounds;

  /// Track length when present (used to scale padding).
  final double? lengthMeters;

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Resolves [LatLng] from root coordinates or [track_geometry] category.
  static CircuitMapPlacement? resolve(CircuitData data) {
    LatLng? center;
    double? lengthM;

    if (data.latitude != null && data.longitude != null) {
      center = LatLng(data.latitude!, data.longitude!);
    }

    for (final cat in data.categories) {
      if (cat.categoryId != 'track_geometry') continue;
      final dp = cat.dataPoints;
      final lat = _readDouble(dp['latitude']) ?? _readDouble(dp['lat']);
      final lng = _readDouble(dp['longitude']) ?? _readDouble(dp['lng']);
      if (lat != null && lng != null) {
        center = LatLng(lat, lng);
      }
      lengthM ??= _readDouble(dp['length_m']);
      final explicit = _boundsFromJson(dp['map_bounds']);
      if (explicit != null && center != null) {
        return CircuitMapPlacement(
          center: center,
          panBounds: explicit,
          lengthMeters: lengthM,
        );
      }
      break;
    }

    if (center == null) return null;

    final pad = _paddingDegrees(lengthM);
    final south = (center.latitude - pad.lat).clamp(-85.0, 85.0);
    final north = (center.latitude + pad.lat).clamp(-85.0, 85.0);
    final west = (center.longitude - pad.lng).clamp(-180.0, 180.0);
    final east = (center.longitude + pad.lng).clamp(-180.0, 180.0);

    return CircuitMapPlacement(
      center: center,
      panBounds: LatLngBounds(LatLng(south, west), LatLng(north, east)),
      lengthMeters: lengthM,
    );
  }

  static LatLngBounds? _boundsFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final s = _readDouble(m['south']);
    final n = _readDouble(m['north']);
    final w = _readDouble(m['west']);
    final e = _readDouble(m['east']);
    if (s == null || n == null || w == null || e == null) return null;
    return LatLngBounds(LatLng(s, w), LatLng(n, e));
  }

  /// Slightly larger than the circuit so panning stays meaningful but bounded.
  static ({double lat, double lng}) _paddingDegrees(double? lengthM) {
    if (lengthM == null) {
      return (lat: 0.018, lng: 0.024);
    }
    final km = (lengthM / 1000).clamp(0.9, 7.0);
    final scale = 0.007 + km * 0.0028;
    return (lat: scale, lng: scale * 1.25);
  }
}
