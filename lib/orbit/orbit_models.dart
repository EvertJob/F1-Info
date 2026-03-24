import 'package:latlong2/latlong.dart';

/// One row from `f1-locations-2026.json` (bacinger/f1-circuits).
class F1CircuitLocation {
  const F1CircuitLocation({
    required this.id,
    required this.name,
    required this.location,
    required this.lat,
    required this.lon,
    required this.suggestedZoom,
  });

  final String id;
  final String name;
  final String location;
  final double lat;
  final double lon;
  final double suggestedZoom;

  LatLng get latLng => LatLng(lat, lon);

  factory F1CircuitLocation.fromJson(Map<String, dynamic> j) {
    return F1CircuitLocation(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      location: j['location']?.toString() ?? '',
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lon: (j['lon'] as num?)?.toDouble() ?? 0,
      suggestedZoom: (j['zoom'] as num?)?.toDouble() ?? 14,
    );
  }
}
