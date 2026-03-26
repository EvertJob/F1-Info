import 'dart:convert';

import 'package:f1/orbit/orbit_models.dart';
import 'package:f1/orbit/orbit_technical_models.dart';
import 'package:flutter/material.dart';
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
  final Map<String, OrbitCircuitTechnicalDetail?> _technicalCache = {};
  final Map<String, String> _technicalDetailsRawByCircuitId = {};

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

  /// Bundled `assets/data/circuits/{id}-details.geojson` only; returns null if missing.
  Future<OrbitCircuitTechnicalDetail?> tryLoadCircuitTechnicalDetail(
    String circuitId,
  ) async {
    final cached = _technicalCache[circuitId];
    if (_technicalCache.containsKey(circuitId)) return cached;

    final path = 'assets/data/circuits/$circuitId-details.geojson';
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (_) {
      _technicalCache[circuitId] = null;
      _technicalDetailsRawByCircuitId.remove(circuitId);
      return null;
    }

    _technicalDetailsRawByCircuitId[circuitId] = raw;
    final parsed = parseCircuitTechnicalDetail(raw);
    _technicalCache[circuitId] = parsed;
    return parsed;
  }

  /// Raw JSON of `*-details.geojson` after [tryLoadCircuitTechnicalDetail] loaded it.
  String? technicalDetailsGeoJson(String circuitId) =>
      _technicalDetailsRawByCircuitId[circuitId];

  /// Sectors (Name contains "Sector") and timing gates from a FeatureCollection.
  static OrbitCircuitTechnicalDetail? parseCircuitTechnicalDetail(String raw) {
    final sectors = <OrbitSectorStroke>[];
    final gates = <OrbitTimingGateStroke>[];

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final features = decoded['features'];
    if (features is! List<dynamic>) return null;

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final props = f['properties'];
      final propMap = props is Map<String, dynamic> ? props : null;
      if (propMap == null) continue;

      final geom = f['geometry'];
      if (geom is! Map<String, dynamic>) continue;
      final gType = geom['type']?.toString();
      final coords = geom['coordinates'];
      if (gType == 'LineString' && coords is List<dynamic>) {
        final pts = _coordsToLatLngs(coords);
        if (pts.length < 2) continue;
        _appendTechnicalFeature(
          propMap,
          pts,
          sectors: sectors,
          gates: gates,
        );
      } else if (gType == 'MultiLineString' && coords is List<dynamic>) {
        for (final line in coords) {
          if (line is! List<dynamic>) continue;
          final pts = _coordsToLatLngs(line);
          if (pts.length < 2) continue;
          _appendTechnicalFeature(
            propMap,
            pts,
            sectors: sectors,
            gates: gates,
          );
        }
      }
    }

    if (sectors.isEmpty && gates.isEmpty) return null;
    return OrbitCircuitTechnicalDetail(sectors: sectors, gates: gates);
  }

  static void _appendTechnicalFeature(
    Map<String, dynamic> propMap,
    List<LatLng> pts, {
    required List<OrbitSectorStroke> sectors,
    required List<OrbitTimingGateStroke> gates,
  }) {
    final typeProp = propMap['type']?.toString().toLowerCase();
    if (typeProp == 'timing_gate') {
      final w = _readStrokeWidth(propMap, fallback: 4);
      final c = _readStrokeColor(propMap) ?? Colors.white;
      gates.add(OrbitTimingGateStroke(points: pts, color: c, strokeWidth: w));
      return;
    }

    final name = (propMap['Name'] ?? propMap['name'])?.toString() ?? '';
    if (!name.toLowerCase().contains('sector')) return;

    final w = _readStrokeWidth(propMap, fallback: 6);
    final c = _readStrokeColor(propMap) ?? const Color(0xFFE10600);
    final label = _sectorShortLabel(name);
    sectors.add(
      OrbitSectorStroke(
        points: pts,
        color: c,
        strokeWidth: w,
        label: label,
      ),
    );
  }

  static String _sectorShortLabel(String name) {
    final m = RegExp(r'(\d+)').firstMatch(name);
    if (m != null) return 'S${m.group(1)}';
    return name.length <= 3 ? name : name.substring(0, 3);
  }

  static double _readStrokeWidth(Map<String, dynamic> p, {required double fallback}) {
    final v = p['stroke-width'] ?? p['strokeWidth'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static Color? _readStrokeColor(Map<String, dynamic> p) {
    final v = p['stroke'] ?? p['stroke-color'] ?? p['color'];
    return _parseColor(v);
  }

  static Color? _parseColor(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) {
      var hex = s.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) {
        final n = int.tryParse(hex, radix: 16);
        if (n != null) return Color(0xFF000000 | n);
      }
      if (hex.length == 8) {
        final n = int.tryParse(hex, radix: 16);
        if (n != null) return Color(n);
      }
    }
    return null;
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
