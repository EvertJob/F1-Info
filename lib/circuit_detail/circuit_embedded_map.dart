import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:f1/circuit_detail/circuit_map_placement.dart';
import 'package:f1/display_settings_controller.dart';
import 'package:f1/orbit/orbit_data.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Dark, cool OSM tiles (ambient / night) — aligned with Orbit technical styling.
const List<double> kCircuitAmbientNightMapMatrix = <double>[
  0.12,
  0.42,
  0.06,
  0,
  0,
  0.12,
  0.42,
  0.06,
  0,
  8,
  0.12,
  0.42,
  0.06,
  0,
  22,
  0,
  0,
  0,
  1,
  0,
];

const Duration _kCircuitMapAnimDuration = Duration(milliseconds: 900);

/// `bacinger/f1-circuits` uses stems like `zandvoort`, not `circuit_zandvoort`.
String orbitGeoJsonStemForCircuitId(String circuitId) {
  const prefix = 'circuit_';
  if (circuitId.startsWith(prefix)) {
    return circuitId.substring(prefix.length);
  }
  return circuitId;
}

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

/// Intersects [track] with [pan] so the fit camera never targets area outside pan limits.
LatLngBounds _intersectBounds(LatLngBounds track, LatLngBounds pan) {
  final south = math.max(track.south, pan.south);
  final north = math.min(track.north, pan.north);
  final west = math.max(track.west, pan.west);
  final east = math.min(track.east, pan.east);
  if (south >= north || west >= east) {
    return pan;
  }
  return LatLngBounds(LatLng(south, west), LatLng(north, east));
}

/// Embedded Orbit-style [FlutterMap] for [CircuitPage]: bounded pan, zoom limits, night tiles.
class CircuitEmbeddedMap extends StatefulWidget {
  const CircuitEmbeddedMap({
    super.key,
    required this.placement,
    required this.title,
    required this.circuitId,
    this.height = 232,
  });

  final CircuitMapPlacement placement;
  final String title;
  final String circuitId;
  final double height;

  @override
  State<CircuitEmbeddedMap> createState() => _CircuitEmbeddedMapState();
}

class _CircuitEmbeddedMapState extends State<CircuitEmbeddedMap>
    with SingleTickerProviderStateMixin {
  static const double _minZoom = 14;
  static const double _maxZoom = 18;

  late final AnimatedMapController _animatedMap;
  late final Future<void> _trackLoadFuture;
  List<List<LatLng>>? _trackSegments;
  bool _trackFailed = false;
  bool _didInitialCamera = false;
  bool _didLateTrackRefit = false;

  @override
  void initState() {
    super.initState();
    _animatedMap = AnimatedMapController(
      vsync: this,
      duration: _kCircuitMapAnimDuration,
      curve: Curves.easeOutExpo,
      cancelPreviousAnimations: true,
    );
    _trackLoadFuture = _loadTrack();
  }

  Future<void> _loadTrack() async {
    final stem = orbitGeoJsonStemForCircuitId(widget.circuitId);
    try {
      final segs = await OrbitDataService.instance.fetchTrackSegments(stem);
      if (!mounted) return;
      setState(() => _trackSegments = segs);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRefitForLateTrack();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trackFailed = true;
        _trackSegments = null;
      });
    }
  }

  @override
  void dispose() {
    _animatedMap.dispose();
    super.dispose();
  }

  CameraFit? _trackCameraFit() {
    final p = widget.placement;
    final segments = _trackSegments;
    if (segments == null || segments.isEmpty || _trackFailed) {
      return null;
    }
    final flat = OrbitDataService.flattenSegments(segments);
    if (flat.length < 2) return null;
    var bounds = LatLngBounds.fromPoints(flat);
    bounds = _ensureMinBoundsSpan(bounds);
    bounds = _intersectBounds(bounds, p.panBounds);
    return CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
      maxZoom: _maxZoom,
      minZoom: _minZoom,
    );
  }

  Future<void> _applyInitialCamera({required bool animated}) async {
    if (!mounted || _didInitialCamera) return;
    _didInitialCamera = true;

    final fit = _trackCameraFit();
    if (fit != null) {
      if (animated) {
        await _animatedMap.animatedFitCamera(
          cameraFit: fit,
          curve: Curves.easeOutExpo,
          duration: _kCircuitMapAnimDuration,
          cancelPreviousAnimations: true,
        );
      } else {
        _animatedMap.mapController.fitCamera(fit);
      }
      return;
    }

    final p = widget.placement;
    if (animated) {
      await _animatedMap.animateTo(
        dest: p.center,
        zoom: 15.4,
        curve: Curves.easeOutExpo,
        duration: _kCircuitMapAnimDuration,
        cancelPreviousAnimations: true,
      );
    } else {
      _animatedMap.mapController.move(p.center, 15.4);
    }
  }

  void _maybeRefitForLateTrack() {
    if (!_didInitialCamera || _didLateTrackRefit || !mounted) return;
    final fit = _trackCameraFit();
    if (fit == null) return;
    _didLateTrackRefit = true;

    final motionReduced = context
        .read<DisplaySettingsController>()
        .motionReduced;
    if (motionReduced) {
      _animatedMap.mapController.fitCamera(fit);
    } else {
      unawaited(
        _animatedMap.animatedFitCamera(
          cameraFit: fit,
          curve: Curves.easeOutExpo,
          duration: _kCircuitMapAnimDuration,
          cancelPreviousAnimations: true,
        ),
      );
    }
  }

  void _scheduleInitialCamera() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInitialCamera) return;

      try {
        await _trackLoadFuture.timeout(const Duration(milliseconds: 1600));
      } on TimeoutException {
        // Continue with center / partial track.
      }

      if (!mounted || _didInitialCamera) return;

      final motionReduced = context
          .read<DisplaySettingsController>()
          .motionReduced;
      await _applyInitialCamera(animated: !motionReduced);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f1 = Theme.of(context).extension<F1UiTheme>();
    final radius = f1?.cardBorderRadius ?? 20;
    final motionReduced = context.select<DisplaySettingsController, bool>(
      (c) => c.motionReduced,
    );
    final mapBg = const Color(0xFF050816);
    final f1PinkDeep = scheme.primary;

    final p = widget.placement;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(radius + 4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _animatedMap.mapController,
              options: MapOptions(
                initialCenter: p.center,
                initialZoom: 14.2,
                initialRotation: 0,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                backgroundColor: mapBg,
                cameraConstraint: CameraConstraint.contain(bounds: p.panBounds),
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  cursorKeyboardRotationOptions:
                      CursorKeyboardRotationOptions.disabled(),
                ),
                onMapReady: _scheduleInitialCamera,
              ),
              children: [
                RepaintBoundary(
                  child: Opacity(
                    opacity: 0.96,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(
                        kCircuitAmbientNightMapMatrix,
                      ),
                      child: TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'F1Hub/1.0 (+https://f1hub.app)',
                        maxNativeZoom: 19,
                      ),
                    ),
                  ),
                ),
                if (_trackSegments != null && _trackSegments!.isNotEmpty) ...[
                  RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        for (final seg in _trackSegments!)
                          if (seg.length >= 2)
                            Polyline(
                              points: seg,
                              strokeWidth: 7,
                              color: f1PinkDeep.withValues(alpha: 0.2),
                              strokeCap: StrokeCap.round,
                              strokeJoin: StrokeJoin.round,
                            ),
                      ],
                    ),
                  ),
                  RepaintBoundary(
                    child: PolylineLayer(
                      polylines: [
                        for (final seg in _trackSegments!)
                          if (seg.length >= 2)
                            Polyline(
                              points: seg,
                              strokeWidth: 2.8,
                              color: f1PinkDeep.withValues(alpha: 0.92),
                              strokeCap: StrokeCap.round,
                              strokeJoin: StrokeJoin.round,
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _GlassMapHeader(
                title: widget.title,
                motionReduced: motionReduced,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassMapHeader extends StatelessWidget {
  const _GlassMapHeader({required this.title, required this.motionReduced});

  final String title;
  final bool motionReduced;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blur = motionReduced ? 0.0 : 14.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withValues(alpha: 0.55),
                scheme.surface.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.95),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
