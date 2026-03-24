import 'package:shared_preferences/shared_preferences.dart';

const _kCircuitId = 'orbit_last_circuit_id';
const _kLat = 'orbit_last_lat';
const _kLng = 'orbit_last_lng';
const _kZoom = 'orbit_last_zoom';

class OrbitPrefs {
  OrbitPrefs._();
  static final OrbitPrefs instance = OrbitPrefs._();

  Future<void> saveView({
    required String? circuitId,
    required double lat,
    required double lng,
    required double zoom,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (circuitId != null && circuitId.isNotEmpty) {
      await p.setString(_kCircuitId, circuitId);
    }
    await p.setDouble(_kLat, lat);
    await p.setDouble(_kLng, lng);
    await p.setDouble(_kZoom, zoom);
  }

  Future<OrbitSavedView?> loadView() async {
    final p = await SharedPreferences.getInstance();
    final lat = p.getDouble(_kLat);
    final lng = p.getDouble(_kLng);
    final zoom = p.getDouble(_kZoom);
    if (lat == null || lng == null || zoom == null) return null;
    return OrbitSavedView(
      circuitId: p.getString(_kCircuitId),
      lat: lat,
      lng: lng,
      zoom: zoom,
    );
  }
}

class OrbitSavedView {
  const OrbitSavedView({
    required this.circuitId,
    required this.lat,
    required this.lng,
    required this.zoom,
  });

  final String? circuitId;
  final double lat;
  final double lng;
  final double zoom;
}
