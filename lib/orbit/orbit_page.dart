import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:f1/orbit/orbit_data.dart';
import 'package:f1/orbit/orbit_models.dart';
import 'package:f1/orbit/orbit_prefs.dart';
import 'package:f1/theme/f1_theme_tokens.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';

/// Below this zoom: lightweight [CircleLayer] dots + map tap-to-pick (performance).
/// At/above: richer [MarkerLayer] with glow (fewer tiles changing during zoom).
const double _kLiteMarkerZoomThreshold = 11;

const Duration _kOrbitMapAnimDuration = Duration(milliseconds: 1000);

/// F1 Hub "Orbit" — interactive world map (north-up, standard OSM, circuit tracks).
class OrbitPage extends StatefulWidget {
  const OrbitPage({super.key});

  @override
  State<OrbitPage> createState() => _OrbitPageState();
}

class _OrbitPageState extends State<OrbitPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const double _kGlobalZoom = 3;
  static const double _kTrackFadeStartZoom = 12;

  static const Distance _kGeoDistance = Distance();

  late final AnimatedMapController _animatedMap;
  late final AnimationController _pulse;

  List<F1CircuitLocation> _locations = [];
  List<List<LatLng>>? _trackSegments;
  String? _selectedId;
  LatLng _initialCenter = const LatLng(24, 10);
  double _initialZoom = _kGlobalZoom;
  double _currentZoom = _kGlobalZoom;
  bool _ready = false;
  String? _error;
  bool _trackLoading = false;
  Timer? _saveDebounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _animatedMap = AnimatedMapController(
      vsync: this,
      duration: _kOrbitMapAnimDuration,
      curve: Curves.easeOutExpo,
      cancelPreviousAnimations: true,
    );
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await OrbitPrefs.instance.loadView();
      final locs = await OrbitDataService.instance.fetchLocations();
      if (!mounted) return;
      setState(() {
        _locations = locs;
        if (prefs != null) {
          _initialCenter = LatLng(prefs.lat, prefs.lng);
          _initialZoom = prefs.zoom.clamp(2.0, 18.0);
          _currentZoom = _initialZoom;
          _selectedId = prefs.circuitId;
        }
        _ready = true;
      });
      final sid = _selectedId;
      if (sid != null && _currentZoom > _kTrackFadeStartZoom) {
        unawaited(_loadTrack(sid));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _loadTrack(String id) async {
    setState(() => _trackLoading = true);
    try {
      final segments = await OrbitDataService.instance.fetchTrackSegments(id);
      if (!mounted) return;
      final usable = segments.where((s) => s.length >= 2).toList();
      setState(() {
        _trackSegments = usable.isEmpty ? null : usable;
        _trackLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trackSegments = null;
        _trackLoading = false;
      });
    }
  }

  bool get _hasTrackOverlay {
    final s = _trackSegments;
    if (s == null) return false;
    return s.any((seg) => seg.length >= 2);
  }

  EdgeInsets _mapFitPadding(BuildContext context) {
    final extraBottom = MediaQuery.viewPaddingOf(context).bottom;
    return EdgeInsets.only(
      top: 50,
      left: 50,
      right: 50,
      bottom: 180 + extraBottom,
    );
  }

  /// Avoids degenerate bounds (Monaco-scale) blowing zoom to max.
  LatLngBounds _ensureMinBoundsSpan(LatLngBounds b) {
    const minDelta = 0.0012;
    var south = b.south;
    var north = b.north;
    var west = b.west;
    var east = b.east;
    if ((north - south) < minDelta) {
      final mid = (north + south) / 2;
      south = mid - minDelta / 2;
      north = mid + minDelta / 2;
    }
    if ((east - west) < minDelta) {
      final mid = (east + west) / 2;
      west = mid - minDelta / 2;
      east = mid + minDelta / 2;
    }
    return LatLngBounds(LatLng(south, west), LatLng(north, east));
  }

  Future<void> _fitCircuitToBounds(
    BuildContext context,
    F1CircuitLocation c,
  ) async {
    final segments = _trackSegments;
    if (segments == null || segments.isEmpty) {
      await _animatedMap.animateTo(
        dest: c.latLng,
        zoom: c.suggestedZoom.clamp(11.0, 17.0),
        duration: _kOrbitMapAnimDuration,
        curve: Curves.easeOutExpo,
        cancelPreviousAnimations: true,
      );
    } else {
      final flat = OrbitDataService.flattenSegments(segments);
      if (flat.isEmpty) {
        await _animatedMap.animateTo(
          dest: c.latLng,
          zoom: c.suggestedZoom.clamp(11.0, 17.0),
          duration: _kOrbitMapAnimDuration,
          curve: Curves.easeOutExpo,
          cancelPreviousAnimations: true,
        );
      } else if (flat.length == 1) {
        await _animatedMap.animateTo(
          dest: flat.first,
          zoom: c.suggestedZoom.clamp(12.0, 17.0),
          duration: _kOrbitMapAnimDuration,
          curve: Curves.easeOutExpo,
          cancelPreviousAnimations: true,
        );
      } else {
        var bounds = LatLngBounds.fromPoints(flat);
        bounds = _ensureMinBoundsSpan(bounds);
        await _animatedMap.animatedFitCamera(
          cameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: _mapFitPadding(context),
            maxZoom: 18,
            minZoom: 2,
          ),
          curve: Curves.easeOutExpo,
          duration: _kOrbitMapAnimDuration,
          cancelPreviousAnimations: true,
        );
      }
    }
    if (!mounted) return;
    final cam = _animatedMap.mapController.camera;
    unawaited(
      OrbitPrefs.instance.saveView(
        circuitId: c.id,
        lat: cam.center.latitude,
        lng: cam.center.longitude,
        zoom: cam.zoom,
      ),
    );
  }

  void _schedulePersist(MapCamera cam) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(
        OrbitPrefs.instance.saveView(
          circuitId: _selectedId,
          lat: cam.center.latitude,
          lng: cam.center.longitude,
          zoom: cam.zoom,
        ),
      );
    });
  }

  Future<void> _selectCircuit(F1CircuitLocation c) async {
    setState(() {
      _selectedId = c.id;
      _trackSegments = null;
      _trackLoading = true;
    });
    Navigator.of(context).maybePop();

    // Immediate fly — GeoJSON refines the camera when it arrives.
    unawaited(
      _animatedMap.animateTo(
        dest: c.latLng,
        zoom: c.suggestedZoom.clamp(10.5, 16.0),
        duration: _kOrbitMapAnimDuration,
        curve: Curves.easeOutExpo,
        cancelPreviousAnimations: true,
      ),
    );

    await _loadTrack(c.id);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _fitCircuitToBounds(context, c);
  }

  bool get _useLiteMarkers => _currentZoom < _kLiteMarkerZoomThreshold;

  /// Tap radius (meters) scales with zoom so picking works on the globe view.
  double _pickRadiusMeters() {
    final z = _currentZoom.clamp(2.0, 18.0);
    return 520000 / math.pow(2, z * 0.78);
  }

  F1CircuitLocation? _nearestCircuit(LatLng tap) {
    final maxM = _pickRadiusMeters();
    F1CircuitLocation? best;
    double? bestD;
    for (final c in _locations) {
      final d = _kGeoDistance(tap, c.latLng);
      if (d <= maxM && (bestD == null || d < bestD)) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  double get _trackBlendT {
    const span = 2.0;
    final linear =
        ((_currentZoom - _kTrackFadeStartZoom) / span).clamp(0.0, 1.0);
    return Curves.easeInOut.transform(linear);
  }

  void _openCircuitList() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _locations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = _locations[i];
                final selected = c.id == _selectedId;
                return Material(
                  color: scheme.surfaceContainerHighest.withValues(
                    alpha: selected ? 0.9 : 0.65,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    title: Text(
                      c.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      c.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.primary,
                    ),
                    onTap: () => _selectCircuit(c),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pulse.dispose();
    _animatedMap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final f1Ui =
        Theme.of(context).extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final tokens = Theme.of(context).extension<F1ThemeTokens>();
    final panelStrong = tokens?.panelStrong ?? scheme.surfaceContainerHighest;
    final f1Pink = scheme.primary;
    /// High-contrast track + marker glow on light OSM (slightly darkened primary).
    final f1PinkDeep = Color.lerp(f1Pink, const Color(0xFF0A0A0A), 0.22)!;
    final markerNeonGlow =
        Color.lerp(f1Pink, const Color(0xFF050505), 0.38)!.withValues(alpha: 0.52);
    const markerStroke = Color(0xFF1A1A1A);
    final desktopShell = MediaQuery.sizeOf(context).width >= 600;

    if (_error != null) {
      return Scaffold(
        backgroundColor: desktopShell ? Colors.transparent : null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.orbit_load_error(_error!),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return Scaffold(
        backgroundColor: desktopShell ? Colors.transparent : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final trackT = _trackBlendT;
    final markerOpacity = (1.0 - trackT).clamp(0.0, 1.0);
    final trackOpacity = trackT;

    F1CircuitLocation? selectedLoc;
    final sid = _selectedId;
    if (sid != null) {
      for (final e in _locations) {
        if (e.id == sid) {
          selectedLoc = e;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: desktopShell ? Colors.transparent : null,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _animatedMap.mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                initialRotation: 0,
                minZoom: 2,
                maxZoom: 18,
                backgroundColor: const Color(0xFF0D1117),
                keepAlive: true,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  cursorKeyboardRotationOptions:
                      CursorKeyboardRotationOptions.disabled(),
                ),
                onPositionChanged: (cam, hasGesture) {
                  final z = cam.zoom;
                  if ((z - _currentZoom).abs() > 0.02) {
                    setState(() => _currentZoom = z);
                  }
                  if (hasGesture) {
                    _schedulePersist(cam);
                  }
                },
                onTap: _locations.isEmpty
                    ? null
                    : (tapPosition, point) {
                        if (!_useLiteMarkers) return;
                        final hit = _nearestCircuit(point);
                        if (hit != null) {
                          unawaited(_selectCircuit(hit));
                        }
                      },
              ),
              children: [
                RepaintBoundary(
                  child: Opacity(
                    opacity: 0.97,
                    child: TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'F1Hub/1.0 (+https://f1hub.app)',
                      maxNativeZoom: 19,
                    ),
                  ),
                ),
                if (_hasTrackOverlay && trackOpacity > 0.01) ...[
                  RepaintBoundary(
                    child: Opacity(
                      opacity: trackOpacity,
                      child: PolylineLayer(
                        polylines: [
                          for (final seg in _trackSegments!)
                            if (seg.length >= 2)
                              Polyline(
                                points: seg,
                                strokeWidth: 8,
                                color: f1PinkDeep.withValues(alpha: 0.22),
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                              ),
                        ],
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: Opacity(
                      opacity: trackOpacity,
                      child: PolylineLayer(
                        polylines: [
                          for (final seg in _trackSegments!)
                            if (seg.length >= 2)
                              Polyline(
                                points: seg,
                                strokeWidth: 3,
                                color: f1PinkDeep,
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (markerOpacity > 0.01)
                  RepaintBoundary(
                    child: Opacity(
                      opacity: markerOpacity,
                      child: _useLiteMarkers
                          ? AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, _) {
                                final breathe = 1.0 +
                                    0.10 *
                                        math.sin(_pulse.value * math.pi * 2);
                                return CircleLayer(
                                  circles: [
                                    for (final c in _locations) ...[
                                      CircleMarker(
                                        point: c.latLng,
                                        radius: 18 * breathe,
                                        color: f1Pink.withValues(alpha: 0.14),
                                        borderStrokeWidth: 0,
                                      ),
                                      CircleMarker(
                                        point: c.latLng,
                                        radius: 12 * breathe,
                                        color: f1Pink.withValues(alpha: 0.28),
                                        borderStrokeWidth: 0,
                                      ),
                                      CircleMarker(
                                        point: c.latLng,
                                        radius: 6.5 * breathe,
                                        color: f1Pink.withValues(alpha: 0.96),
                                        borderStrokeWidth: 1.5,
                                        borderColor: Colors.white
                                            .withValues(alpha: 0.95),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            )
                          : MarkerLayer(
                              markers: [
                                for (final c in _locations)
                                  Marker(
                                    point: c.latLng,
                                    width: 52,
                                    height: 52,
                                    alignment: Alignment.center,
                                    child: GestureDetector(
                                      onTap: () => _selectCircuit(c),
                                      child: AnimatedBuilder(
                                        animation: _pulse,
                                        builder: (context, child) {
                                          final s = 1.0 +
                                              0.11 *
                                                  math.sin(
                                                    _pulse.value * math.pi * 2,
                                                  );
                                          return Transform.scale(
                                            scale: s,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: f1Pink.withValues(
                                              alpha: 0.95,
                                            ),
                                            border: Border.all(
                                              color: markerStroke,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: markerNeonGlow,
                                                blurRadius: 12,
                                                spreadRadius: 0,
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                SimpleAttributionWidget(
                  alignment: Alignment.bottomLeft,
                  backgroundColor: scheme.surface.withValues(alpha: 0.75),
                  source: const Text('© OpenStreetMap'),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 16,
              child: Material(
                color: panelStrong.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.5
                      : 0.75,
                ),
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: IconButton(
                  tooltip: context.l10n.orbit_circuit_list,
                  onPressed: _openCircuitList,
                  icon: Icon(Icons.list_rounded, color: scheme.primary),
                ),
              ),
            ),
            if (selectedLoc != null && _currentZoom > _kTrackFadeStartZoom)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _OrbitGlassInfoCard(
                  location: selectedLoc,
                  trackLoading: _trackLoading,
                  f1Ui: f1Ui,
                  panelStrong: panelStrong,
                  scheme: scheme,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrbitGlassInfoCard extends StatelessWidget {
  const _OrbitGlassInfoCard({
    required this.location,
    required this.trackLoading,
    required this.f1Ui,
    required this.panelStrong,
    required this.scheme,
  });

  final F1CircuitLocation location;
  final bool trackLoading;
  final F1UiTheme f1Ui;
  final Color panelStrong;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = f1Ui.cardBorderRadius.clamp(12.0, 24.0);
    final fill = panelStrong.withValues(alpha: isDark ? 0.42 : 0.55);

    Widget inner = F1Module(
      fillWidth: true,
      borderRadius: radius,
      backgroundColor: fill,
      showFadingBorder: true,
      boxShadow: f1Ui.moduleShadow,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.app_title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            location.name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.2,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location.location,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          if (trackLoading) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(2),
                color: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );

    if (f1Ui.glassBlur > 0) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: f1Ui.glassBlur * 0.45,
            sigmaY: f1Ui.glassBlur * 0.45,
          ),
          child: inner,
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: inner,
      );
    }

    return inner;
  }
}
