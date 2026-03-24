import 'dart:convert';

import 'package:f1/orbit/orbit_models.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const String kOrbitLocationsAsset = 'assets/data/f1-locations-2026.json';

const String kF1Locations2026Url =
    'https://raw.githubusercontent.com/bacinger/f1-circuits/master/championships/f1-locations-2026.json';

String f1CircuitGeoJsonUrl(String id) =>
    'https://raw.githubusercontent.com/bacinger/f1-circuits/master/circuits/$id.geojson';

Uri _corsProxyUri(String targetUrl) =>
    Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}');

class OrbitDataService {
  OrbitDataService._();
  static final OrbitDataService instance = OrbitDataService._();

  List<F1CircuitLocation>? _locationsCache;
  final Map<String, List<List<LatLng>>> _trackCache = {};

  /// Prefer bundled JSON (instant, no CORS); fall back to GitHub if the asset is missing.
  Future<List<F1CircuitLocation>> fetchLocations() async {
    if (_locationsCache != null) return _locationsCache!;
    String body;
    try {
      body = await rootBundle.loadString(kOrbitLocationsAsset);
    } catch (_) {
      final r = await http.get(Uri.parse(kF1Locations2026Url));
      if (r.statusCode != 200) {
        throw Exception('HTTP ${r.statusCode}');
      }
      body = r.body;
    }
    final list = jsonDecode(body) as List<dynamic>;
    _locationsCache = list
        .map((e) => F1CircuitLocation.fromJson(e as Map<String, dynamic>))
        .where((c) => c.id.isNotEmpty)
        .toList(growable: false);
    return _locationsCache!;
  }

  /// Fetches GeoJSON; on web, retries via corsproxy.io if the direct request fails.
  Future<List<List<LatLng>>> fetchTrackSegments(String circuitId) async {
    final cached = _trackCache[circuitId];
    if (cached != null) return cached;

    final direct = Uri.parse(f1CircuitGeoJsonUrl(circuitId));

    Future<String?> tryGet(Uri uri) async {
      try {
        final r = await http.get(uri);
        if (r.statusCode == 200) return r.body;
      } catch (_) {}
      return null;
    }

    String? raw = await tryGet(direct);
    raw ??= await tryGet(_corsProxyUri(direct.toString()));

    if (raw == null) {
      throw Exception('Could not load track GeoJSON');
    }

    final segments = parseTrackSegments(raw);
    _trackCache[circuitId] = segments;
    return segments;
  }

  /// All LineString / MultiLineString segments from a FeatureCollection.
  static List<List<LatLng>> parseTrackSegments(String raw) {
    final out = <List<LatLng>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return out;
    final features = decoded['features'];
    if (features is! List<dynamic>) return out;

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final geom = f['geometry'];
      if (geom is! Map<String, dynamic>) continue;
      final type = geom['type']?.toString();
      final coords = geom['coordinates'];
      if (type == 'LineString' && coords is List<dynamic>) {
        final pts = _coordsToLatLngs(coords);
        if (pts.length >= 2) out.add(pts);
      } else if (type == 'MultiLineString' && coords is List<dynamic>) {
        for (final line in coords) {
          if (line is List<dynamic>) {
            final pts = _coordsToLatLngs(line);
            if (pts.length >= 2) out.add(pts);
          }
        }
      }
    }
    return out;
  }

  static List<LatLng> _coordsToLatLngs(List<dynamic> coords) {
    final out = <LatLng>[];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        out.add(LatLng(lat, lon));
      }
    }
    return out;
  }

  /// Flattened points for bounding-box / camera fit.
  static List<LatLng> flattenSegments(List<List<LatLng>> segments) =>
      segments.expand((e) => e).toList(growable: false);
}
