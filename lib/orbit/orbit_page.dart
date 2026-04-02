import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:f1/orbit/orbit_data.dart';
import 'package:f1/orbit/orbit_models.dart';
import 'package:f1/orbit/orbit_paths.dart';
import 'package:f1/orbit/orbit_prefs.dart';
import 'package:f1/orbit/orbit_technical_models.dart';
import 'package:f1/orbit/orbit_technical_stats.dart';
import 'package:go_router/go_router.dart';
import 'package:f1/theme/hub_modal_overlays.dart';
import 'package:f1/theme/f1_theme_tokens.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:f1/widgets/f1_elevation_chart.dart';
import 'package:f1/widgets/f1_module.dart';
import 'package:f1/widgets/hub_glass_chart_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';

/// Below this zoom: lightweight [CircleLayer] dots + map tap-to-pick (performance).
/// At/above: richer [MarkerLayer] with glow (fewer tiles changing during zoom).
const double _kLiteMarkerZoomThreshold = 11;

const Duration _kOrbitMapAnimDuration = Duration(milliseconds: 1000);
const Duration _kOrbitTechnicalFadeDuration = Duration(milliseconds: 400);

const double _kOrbitTechPanelWidth = 368;
const double _kOrbitWideDashboardBreakpoint = 960;

/// Standard / Technical segmented control — active segment (deep blue).
const Color _kOrbitModeActiveBlue = Color(0xFF0D47A1);
const Color _kOrbitModeActiveBlueOn = Color(0xFFFFFFFF);

/// Cool desaturated OSM tiles in technical mode (luma + slight blue bias).
const List<double> _kDesaturatedOsmColorMatrix = <double>[
  0.22, 0.62, 0.10, 0, 0,
  0.22, 0.62, 0.10, 0, 3,
  0.22, 0.62, 0.10, 0, 10,
  0, 0, 0, 1, 0,
];

/// F1 Hub "Orbit" — interactive world map (north-up, standard OSM, circuit tracks).
///
/// Deep links: `/orbit/<slug>` (slug from [F1CircuitLocation.location], e.g. `zandvoort`)
/// and `/orbit/<slug>/technical` when technical overlay exists.
class OrbitPage extends StatefulWidget {
  const OrbitPage({
    super.key,
    this.initialCircuitSlug,
    this.initialTechnical = false,
  });

  /// Lowercase path segment, e.g. `zandvoort` or `nl-1948`.
  final String? initialCircuitSlug;
  final bool initialTechnical;

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
  bool _technicalView = false;
  OrbitCircuitTechnicalDetail? _technicalDetail;
  List<ElevationPoint>? _elevationProfile;
  /// Same GeoJSON as used for [F1ElevationChart] (LineStrings + corner Points).
  String? _elevationGeoJson;
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

      final slug = widget.initialCircuitSlug?.trim();
      final deepLinked =
          slug != null && slug.isNotEmpty
              ? findOrbitCircuitByUrlSlug(locs, slug)
              : null;

      setState(() {
        _locations = locs;
        if (deepLinked != null) {
          _initialCenter = deepLinked.latLng;
          _initialZoom = deepLinked.suggestedZoom.clamp(2.0, 18.0);
          _currentZoom = _initialZoom;
          _selectedId = deepLinked.id;
        } else if (prefs != null) {
          _initialCenter = LatLng(prefs.lat, prefs.lng);
          _initialZoom = prefs.zoom.clamp(2.0, 18.0);
          _currentZoom = _initialZoom;
          _selectedId = prefs.circuitId;
        }
        _ready = true;
      });

      if (slug != null && slug.isNotEmpty && deepLinked == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(kOrbitGoPath);
        });
        return;
      }

      if (deepLinked != null) {
        unawaited(
          _selectCircuit(
            deepLinked,
            openTechnicalAfterLoad: widget.initialTechnical,
          ),
        );
      } else {
        final sid = _selectedId;
        if (sid != null && _currentZoom > _kTrackFadeStartZoom) {
          unawaited(_loadTrack(sid));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  F1CircuitLocation? _circuitForSelectedId() {
    final id = _selectedId;
    if (id == null) return null;
    for (final c in _locations) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _syncOrbitUrl() {
    if (!mounted) return;
    final c = _circuitForSelectedId();
    if (c == null) {
      context.go(kOrbitGoPath);
      return;
    }
    final technical = _technicalView && _hasTechnicalOverlay;
    context.go(orbitGoLocationForCircuit(c, technical: technical));
  }

  Future<void> _loadTrack(String id) async {
    setState(() => _trackLoading = true);
    try {
      final segments = await OrbitDataService.instance.fetchTrackSegments(id);
      final technical =
          await OrbitDataService.instance.tryLoadCircuitTechnicalDetail(id);
      if (!mounted) return;
      final usable = segments.where((s) => s.length >= 2).toList();
      final rawDetail =
          OrbitDataService.instance.technicalDetailsGeoJson(id);
      List<ElevationPoint>? elev;
      if (rawDetail != null && rawDetail.isNotEmpty) {
        final parsed = F1ElevationChart.parseFeatureCollectionJson(rawDetail);
        elev = parsed.length >= 2 ? parsed : null;
      }
      setState(() {
        _trackSegments = usable.isEmpty ? null : usable;
        _technicalDetail =
            (technical != null && !technical.isEmpty) ? technical : null;
        if (_technicalDetail == null) _technicalView = false;
        _elevationProfile = elev;
        _elevationGeoJson =
            elev != null && rawDetail != null && rawDetail.isNotEmpty
                ? rawDetail
                : null;
        _trackLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trackSegments = null;
        _technicalDetail = null;
        _elevationProfile = null;
        _elevationGeoJson = null;
        _technicalView = false;
        _trackLoading = false;
      });
    }
  }

  bool get _hasTrackOverlay {
    final s = _trackSegments;
    if (s == null) return false;
    return s.any((seg) => seg.length >= 2);
  }

  bool get _hasTechnicalOverlay =>
      _technicalDetail != null && !_technicalDetail!.isEmpty;

  EdgeInsets _mapFitPadding(BuildContext context) {
    final extraBottom = MediaQuery.viewPaddingOf(context).bottom;
    final wide =
        MediaQuery.sizeOf(context).width >= _kOrbitWideDashboardBreakpoint;
    final techWideDash =
        wide &&
        _technicalView &&
        _hasTechnicalOverlay &&
        _selectedId != null &&
        _currentZoom > _kTrackFadeStartZoom;
    var left = 50.0;
    var bottom = 180.0 + extraBottom;
    if (techWideDash) {
      left += _kOrbitTechPanelWidth;
      bottom += 76;
    }
    return EdgeInsets.only(
      top: 50,
      left: left,
      right: 50,
      bottom: bottom,
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

  void _setTechnicalView(bool value) {
    setState(() => _technicalView = value);
    _syncOrbitUrl();
    if (!value || !mounted) return;
    final c = _circuitForSelectedId();
    if (c == null) return;
    final wide =
        MediaQuery.sizeOf(context).width >= _kOrbitWideDashboardBreakpoint;
    if (!wide ||
        !_hasTechnicalOverlay ||
        _currentZoom <= _kTrackFadeStartZoom) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_fitCircuitToBounds(context, c));
    });
  }

  Future<void> _selectCircuit(
    F1CircuitLocation c, {
    bool openTechnicalAfterLoad = false,
  }) async {
    setState(() {
      _selectedId = c.id;
      _trackSegments = null;
      _technicalDetail = null;
      _elevationProfile = null;
      _elevationGeoJson = null;
      _technicalView = false;
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
    if (!mounted) return;
    if (openTechnicalAfterLoad && _hasTechnicalOverlay) {
      _setTechnicalView(true);
    } else {
      _syncOrbitUrl();
    }
  }

  @override
  void didUpdateWidget(covariant OrbitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;

    final oldSlug = oldWidget.initialCircuitSlug?.trim();
    final newSlug = widget.initialCircuitSlug?.trim();
    final oldT = oldWidget.initialTechnical;
    final newT = widget.initialTechnical;

    if (oldSlug == newSlug && oldT == newT) return;

    if (newSlug == null || newSlug.isEmpty) return;

    if (oldSlug == newSlug && oldT != newT) {
      if (newT) {
        if (_hasTechnicalOverlay) _setTechnicalView(true);
      } else {
        setState(() => _technicalView = false);
        _syncOrbitUrl();
      }
      return;
    }

    final c = findOrbitCircuitByUrlSlug(_locations, newSlug);
    if (c != null) {
      unawaited(_selectCircuit(c, openTechnicalAfterLoad: newT));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(kOrbitGoPath);
      });
    }
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
    hubShowModalBottomSheetWithBlurBarrier<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (ctx) {
        return SizedBox.expand(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Material(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _locations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
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
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrbitFlutterMap({
    required ColorScheme scheme,
    required Color f1Pink,
    required Color f1PinkDeep,
    required Color markerNeonGlow,
    required bool techMapStyle,
    required Color mapBackground,
    required double trackOpacity,
    required double baseTrackVisualOpacity,
    required double technicalVisualOpacity,
    required double markerOpacity,
  }) {
    const markerStroke = Color(0xFF1A1A1A);
    return FlutterMap(
      mapController: _animatedMap.mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: _initialZoom,
        initialRotation: 0,
        minZoom: 2,
        maxZoom: 18,
        backgroundColor: mapBackground,
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
            child: techMapStyle
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix(
                      _kDesaturatedOsmColorMatrix,
                    ),
                    child: TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'F1Hub/1.0 (+https://f1hub.app)',
                      maxNativeZoom: 19,
                    ),
                  )
                : TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'F1Hub/1.0 (+https://f1hub.app)',
                    maxNativeZoom: 19,
                  ),
          ),
        ),
        if (_hasTrackOverlay && trackOpacity > 0.01) ...[
          RepaintBoundary(
            child: AnimatedOpacity(
              duration: _kOrbitTechnicalFadeDuration,
              curve: Curves.easeInOut,
              opacity: trackOpacity * baseTrackVisualOpacity,
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
            child: AnimatedOpacity(
              duration: _kOrbitTechnicalFadeDuration,
              curve: Curves.easeInOut,
              opacity: trackOpacity * baseTrackVisualOpacity,
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
        if (_hasTechnicalOverlay && trackOpacity > 0.01) ...[
          RepaintBoundary(
            child: AnimatedOpacity(
              duration: _kOrbitTechnicalFadeDuration,
              curve: Curves.easeInOut,
              opacity: trackOpacity * technicalVisualOpacity,
              child: PolylineLayer(
                polylines: [
                  for (final s in _technicalDetail!.sectors)
                    Polyline(
                      points: s.points,
                      strokeWidth: s.strokeWidth,
                      color: s.color,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  for (final g in _technicalDetail!.gates)
                    Polyline(
                      points: g.points,
                      strokeWidth: g.strokeWidth,
                      color: g.color,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedOpacity(
              duration: _kOrbitTechnicalFadeDuration,
              curve: Curves.easeInOut,
              opacity: trackOpacity * technicalVisualOpacity,
              child: MarkerLayer(
                markers: [
                  for (final s in _technicalDetail!.sectors)
                    Marker(
                      point: s.midpoint,
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                              sigmaX: 12,
                              sigmaY: 12,
                            ),
                            child: Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: s.color,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.color.withValues(alpha: 0.32),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'TitilliumWeb',
                                  height: 1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
                            0.10 * math.sin(_pulse.value * math.pi * 2);
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
                                borderColor: Colors.white.withValues(
                                  alpha: 0.95,
                                ),
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
                                  final sc = 1.0 +
                                      0.11 *
                                          math.sin(
                                            _pulse.value * math.pi * 2,
                                          );
                                  return Transform.scale(
                                    scale: sc,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: f1Pink.withValues(alpha: 0.95),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.18,
                                        ),
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
          backgroundColor: scheme.surface.withValues(
            alpha: techMapStyle ? 0.55 : 0.75,
          ),
          source: const Text('OpenStreetMap'),
        ),
      ],
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
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
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
        backgroundColor: Colors.transparent,
        body: const HubGlassPageLoadingPlaceholder(),
      );
    }

    final trackT = _trackBlendT;
    final markerOpacity = (1.0 - trackT).clamp(0.0, 1.0);
    final trackOpacity = trackT;
    final baseTrackVisualOpacity =
        (_technicalView && _hasTechnicalOverlay) ? 0.0 : 1.0;
    final technicalVisualOpacity = _technicalView ? 1.0 : 0.0;
    final techMapStyle = _technicalView && _hasTechnicalOverlay;
    final mapBackground =
        techMapStyle ? const Color(0xFF141C24) : const Color(0xFFE8E6E1);

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

    final techStats = computeOrbitTechnicalStats(
      _elevationGeoJson,
      _elevationProfile,
    );
    final wideDash =
        MediaQuery.sizeOf(context).width >= _kOrbitWideDashboardBreakpoint;
    final showTechDashboard =
        selectedLoc != null &&
        _currentZoom > _kTrackFadeStartZoom &&
        techMapStyle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: showTechDashboard && wideDash ? _kOrbitTechPanelWidth : 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: showTechDashboard && wideDash
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      child: _buildOrbitFlutterMap(
                        scheme: scheme,
                        f1Pink: f1Pink,
                        f1PinkDeep: f1PinkDeep,
                        markerNeonGlow: markerNeonGlow,
                        techMapStyle: techMapStyle,
                        mapBackground: mapBackground,
                        trackOpacity: trackOpacity,
                        baseTrackVisualOpacity: baseTrackVisualOpacity,
                        technicalVisualOpacity: technicalVisualOpacity,
                        markerOpacity: markerOpacity,
                      ),
                    )
                  : _buildOrbitFlutterMap(
                      scheme: scheme,
                      f1Pink: f1Pink,
                      f1PinkDeep: f1PinkDeep,
                      markerNeonGlow: markerNeonGlow,
                      techMapStyle: techMapStyle,
                      mapBackground: mapBackground,
                      trackOpacity: trackOpacity,
                      baseTrackVisualOpacity: baseTrackVisualOpacity,
                      technicalVisualOpacity: technicalVisualOpacity,
                      markerOpacity: markerOpacity,
                    ),
            ),
            if (showTechDashboard && wideDash)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _kOrbitTechPanelWidth,
                child: _OrbitTechnicalSidePanel(
                  location: selectedLoc,
                  f1Ui: f1Ui,
                  panelStrong: panelStrong,
                  scheme: scheme,
                  elevationProfile: _elevationProfile,
                  elevationGeoJson: _elevationGeoJson,
                  technicalView: _technicalView,
                ),
              ),
            if (showTechDashboard && wideDash)
              Positioned(
                left: _kOrbitTechPanelWidth + 16,
                right: 16,
                bottom: 12,
                child: _OrbitTechnicalBottomStrip(
                  scheme: scheme,
                  f1Ui: f1Ui,
                  panelStrong: panelStrong,
                  stats: techStats,
                  showTechnicalToggle: _hasTechnicalOverlay,
                  technicalView: _technicalView,
                  trackLoading: _trackLoading,
                  onTechnicalViewChanged: _setTechnicalView,
                ),
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
                  icon: Icon(Icons.menu_rounded, color: scheme.primary),
                ),
              ),
            ),
            if (selectedLoc != null &&
                _currentZoom > _kTrackFadeStartZoom &&
                !(showTechDashboard && wideDash))
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
                  showTechnicalToggle: _hasTechnicalOverlay,
                  technicalView: _technicalView,
                  onTechnicalViewChanged: (v) {
                    setState(() => _technicalView = v);
                    _syncOrbitUrl();
                  },
                  elevationProfile: _elevationProfile,
                  elevationGeoJson: _elevationGeoJson,
                  dashboardStyle: techMapStyle,
                  technicalStats: techStats,
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
    this.showTechnicalToggle = false,
    this.technicalView = false,
    this.onTechnicalViewChanged,
    this.elevationProfile,
    this.elevationGeoJson,
    this.dashboardStyle = false,
    this.technicalStats,
  });

  final F1CircuitLocation location;
  final bool trackLoading;
  final F1UiTheme f1Ui;
  final Color panelStrong;
  final ColorScheme scheme;
  final bool showTechnicalToggle;
  final bool technicalView;
  final ValueChanged<bool>? onTechnicalViewChanged;
  final List<ElevationPoint>? elevationProfile;
  final String? elevationGeoJson;
  final bool dashboardStyle;
  final OrbitTechnicalStats? technicalStats;

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
          if (showTechnicalToggle &&
              onTechnicalViewChanged != null &&
              !trackLoading) ...[
            const SizedBox(height: 12),
            _OrbitTrackModeBar(
              scheme: scheme,
              isDark: isDark,
              isTechnical: technicalView,
              onChanged: onTechnicalViewChanged!,
              standardLabel: context.l10n.orbit_track_standard,
              technicalLabel: context.l10n.orbit_track_technical,
            ),
          ],
          if (technicalView &&
              elevationProfile != null &&
              elevationProfile!.length >= 2) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.orbit_elevation_profile.toUpperCase(),
              style: TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: scheme.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            F1ElevationChart(
              points: elevationProfile!,
              height: dashboardStyle ? 200 : 152,
              useF1RedLine: true,
              axisLabelColor: scheme.onSurfaceVariant,
              geoJsonForTurnMarkers: elevationGeoJson,
              technicalBankingHighlights: technicalView,
              dashboardStyle: dashboardStyle,
            ),
          ],
          if (technicalView && technicalStats != null) ...[
            const SizedBox(height: 12),
            _OrbitTechnicalStatsRow(
              scheme: scheme,
              stats: technicalStats!,
              compact: true,
            ),
          ],
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

class _OrbitTrackModeBar extends StatelessWidget {
  const _OrbitTrackModeBar({
    required this.scheme,
    required this.isDark,
    required this.isTechnical,
    required this.onChanged,
    required this.standardLabel,
    required this.technicalLabel,
  });

  final ColorScheme scheme;
  final bool isDark;
  final bool isTechnical;
  final ValueChanged<bool> onChanged;
  final String standardLabel;
  final String technicalLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: scheme.surface.withValues(alpha: isDark ? 0.28 : 0.4),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _OrbitTrackModeSegment(
                label: standardLabel,
                selected: !isTechnical,
                onTap: () => onChanged(false),
                scheme: scheme,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _OrbitTrackModeSegment(
                label: technicalLabel,
                selected: isTechnical,
                onTap: () => onChanged(true),
                scheme: scheme,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitTrackModeSegment extends StatelessWidget {
  const _OrbitTrackModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: _kOrbitTechnicalFadeDuration,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected
                ? _kOrbitModeActiveBlue.withValues(alpha: isDark ? 0.88 : 0.96)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? _kOrbitModeActiveBlue.withValues(alpha: 0.7)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kOrbitModeActiveBlue.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: selected ? _kOrbitModeActiveBlueOn : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitTechnicalSidePanel extends StatelessWidget {
  const _OrbitTechnicalSidePanel({
    required this.location,
    required this.f1Ui,
    required this.panelStrong,
    required this.scheme,
    this.elevationProfile,
    this.elevationGeoJson,
    required this.technicalView,
  });

  final F1CircuitLocation location;
  final F1UiTheme f1Ui;
  final Color panelStrong;
  final ColorScheme scheme;
  final List<ElevationPoint>? elevationProfile;
  final String? elevationGeoJson;
  final bool technicalView;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = panelStrong.withValues(alpha: isDark ? 0.5 : 0.68);

    Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 10),
          Text(
            location.name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            location.location,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (elevationProfile != null && elevationProfile!.length >= 2) ...[
            const SizedBox(height: 22),
            Text(
              context.l10n.orbit_elevation_profile.toUpperCase(),
              style: TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: scheme.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 10),
            F1ElevationChart(
              points: elevationProfile!,
              height: 280,
              useF1RedLine: true,
              axisLabelColor: scheme.onSurfaceVariant,
              geoJsonForTurnMarkers: elevationGeoJson,
              technicalBankingHighlights: technicalView,
              dashboardStyle: true,
            ),
          ],
        ],
      ),
    );

    body = ColoredBox(color: fill, child: body);

    if (f1Ui.glassBlur > 0) {
      body = ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: f1Ui.glassBlur * 0.35,
            sigmaY: f1Ui.glassBlur * 0.35,
          ),
          child: body,
        ),
      );
    }

    return body;
  }
}

class _OrbitTechnicalBottomStrip extends StatelessWidget {
  const _OrbitTechnicalBottomStrip({
    required this.scheme,
    required this.f1Ui,
    required this.panelStrong,
    this.stats,
    this.showTechnicalToggle = false,
    this.technicalView = false,
    this.trackLoading = false,
    this.onTechnicalViewChanged,
  });

  final ColorScheme scheme;
  final F1UiTheme f1Ui;
  final Color panelStrong;
  final OrbitTechnicalStats? stats;
  final bool showTechnicalToggle;
  final bool technicalView;
  final bool trackLoading;
  final ValueChanged<bool>? onTechnicalViewChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = f1Ui.cardBorderRadius.clamp(12.0, 22.0);
    final fill = panelStrong.withValues(alpha: isDark ? 0.45 : 0.58);

    Widget inner = F1Module(
      fillWidth: true,
      borderRadius: radius,
      backgroundColor: fill,
      showFadingBorder: true,
      boxShadow: f1Ui.moduleShadow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 272,
                child:
                    showTechnicalToggle &&
                        onTechnicalViewChanged != null &&
                        !trackLoading
                    ? _OrbitTrackModeBar(
                        scheme: scheme,
                        isDark: isDark,
                        isTechnical: technicalView,
                        onChanged: onTechnicalViewChanged!,
                        standardLabel: context.l10n.orbit_track_standard,
                        technicalLabel: context.l10n.orbit_track_technical,
                      )
                    : const SizedBox.shrink(),
              ),
              if (stats != null) ...[
                const SizedBox(width: 12),
                _OrbitTechnicalStatsRow(
                  scheme: scheme,
                  stats: stats!,
                  compact: false,
                ),
              ],
            ],
          ),
        ),
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

class _F1TurnMarker extends StatelessWidget {
  const _F1TurnMarker({
    required this.turnNumber,
    required this.brakingG,
  });

  final int turnNumber;
  final double brakingG;

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate the intensity of the braking zone (0.0 to 1.0)
    final double intensity = (brakingG / 6.0).clamp(0.0, 1.0);
    final bool isBrakingZone = brakingG > 0;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // The Red Glow
        boxShadow: isBrakingZone
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: intensity * 0.85),
                  blurRadius: 8.0 + (intensity * 12.0),
                  spreadRadius: 2.0 + (intensity * 8.0),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Glass Sigma 10+
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85), // Semi-transparent fill
              border: Border.all(
                color: Colors.black,
                width: 1.5, // 1.5px high-contrast border
              ),
            ),
            child: Text(
              '$turnNumber',
              style: const TextStyle(
                fontFamily: 'TitilliumWeb', // F1 Signature font
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitTechnicalStatsRow extends StatelessWidget {
  const _OrbitTechnicalStatsRow({
    required this.scheme,
    required this.stats,
    this.compact = false,
  });

  final ColorScheme scheme;
  final OrbitTechnicalStats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lap =
        stats.lapLengthKm >= 1
            ? '${stats.lapLengthKm.toStringAsFixed(2)} km'
            : '${(stats.lapLengthKm * 1000).toStringAsFixed(0)} m';
    final elev = '${stats.maxElevationDeltaM.toStringAsFixed(1)} m';
    final banked = '${stats.bankedTurnsCount}';

    final cells = <Widget>[
      _OrbitTechStatCell(
        scheme: scheme,
        label: l10n.orbit_stat_lap_distance,
        value: lap,
        compact: compact,
      ),
      _OrbitTechStatCell(
        scheme: scheme,
        label: l10n.orbit_stat_max_elevation,
        value: elev,
        compact: compact,
      ),
      _OrbitTechStatCell(
        scheme: scheme,
        label: l10n.orbit_stat_banked_turns,
        value: banked,
        compact: compact,
      ),
    ];

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: cells[i]),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          cells[i],
        ],
      ],
    );
  }
}

class _OrbitTechStatCell extends StatelessWidget {
  const _OrbitTechStatCell({
    required this.scheme,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final ColorScheme scheme;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        color: scheme.surface.withValues(alpha: 0.35),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: scheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
