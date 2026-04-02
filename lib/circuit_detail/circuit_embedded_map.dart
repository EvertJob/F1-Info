import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:f1/circuit_detail/circuit_map_placement.dart';
import 'package:f1/circuit_detail/circuit_track_geojson.dart';
import 'package:f1/display_settings_controller.dart';
import 'package:f1/orbit/orbit_data.dart';
import 'package:f1/orbit/orbit_technical_models.dart';
import 'package:f1/theme/f1_ui_theme.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desaturated “silver night” matrix for OSM tiles (neutral vs app ambient gradient).
/// Google Maps JSON styles do not apply to raster OSM; this approximates a cool neutral base.
const List<double> kCircuitSilverNightMapMatrix = <double>[
  0.2,
  0.52,
  0.1,
  0,
  0,
  0.2,
  0.52,
  0.1,
  0,
  14,
  0.2,
  0.52,
  0.1,
  0,
  18,
  0,
  0,
  0,
  1,
  0,
];

const Duration _kCircuitMapAnimDuration = Duration(milliseconds: 900);

const Color _kF1Blue = Color(0xFF1565C0);
const Color _kTrackSourceModeActive = Color(0xFF0D47A1);

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

/// Embedded Orbit-style [FlutterMap] for [CircuitPage]: styled tiles, fit-to-track on open.
class CircuitEmbeddedMap extends StatefulWidget {
  const CircuitEmbeddedMap({
    super.key,
    required this.placement,
    required this.circuitId,
    this.height = 232,
  });

  final CircuitMapPlacement placement;
  final String circuitId;
  final double height;

  @override
  State<CircuitEmbeddedMap> createState() => _CircuitEmbeddedMapState();
}

class _CircuitEmbeddedMapState extends State<CircuitEmbeddedMap>
    with SingleTickerProviderStateMixin {
  /// Ruim zoombereik; tegels schalen boven [TileLayer.maxNativeZoom].
  static const double _minZoom = 1;
  static const double _maxZoom = 22;

  static const EdgeInsets _kFitPadding = EdgeInsets.all(50);

  late final AnimatedMapController _animatedMap;
  Future<void>? _trackLoadFuture;
  List<List<LatLng>>? _trackSegments;
  bool _trackFailed = false;
  bool _didInitialCamera = false;
  bool _didLateTrackRefit = false;
  bool _mapExpanded = false;

  /// Sectoren (kleuren), gates en bochten uit `*-details.geojson`.
  CircuitDetailsMapOverlay? _detailsOverlay;
  bool _hasDetailsAsset = false;
  bool _useDetailsTrack = false;

  @override
  void initState() {
    super.initState();
    _animatedMap = AnimatedMapController(
      vsync: this,
      duration: _kCircuitMapAnimDuration,
      curve: Curves.easeOutExpo,
      cancelPreviousAnimations: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trackLoadFuture ??= _loadTrack(DefaultAssetBundle.of(context));
  }

  @override
  void didUpdateWidget(covariant CircuitEmbeddedMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circuitId != widget.circuitId) {
      _trackLoadFuture = _loadTrack(DefaultAssetBundle.of(context));
      _trackSegments = null;
      _detailsOverlay = null;
      _hasDetailsAsset = false;
      _useDetailsTrack = false;
      _trackFailed = false;
      _didInitialCamera = false;
      _didLateTrackRefit = false;
      _mapExpanded = false;
    }
  }

  Future<void> _loadTrack(AssetBundle bundle) async {
    final detailsOverlay = await loadCircuitDetailsMapOverlay(
      bundle: bundle,
      circuitId: widget.circuitId,
    );
    final hasDetails = detailsOverlay != null && detailsOverlay.hasTrackData;

    try {
      final segs = await loadCircuitTrackSegments(
        bundle: bundle,
        circuitId: widget.circuitId,
        useNetworkFallback: true,
      );
      if (!mounted) return;
      final mainUsable = segs.where((s) => s.length >= 2).isNotEmpty;
      setState(() {
        _detailsOverlay = detailsOverlay;
        _hasDetailsAsset = hasDetails;
        _trackSegments = segs;
        _trackFailed = false;
        if (!_hasDetailsAsset) {
          _useDetailsTrack = false;
        } else if (!mainUsable) {
          _useDetailsTrack = true;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRefitForLateTrack();
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _detailsOverlay = detailsOverlay;
        _hasDetailsAsset = hasDetails;
        _trackFailed = true;
        _trackSegments = null;
        if (!_hasDetailsAsset) {
          _useDetailsTrack = false;
        } else {
          _useDetailsTrack = true;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRefitForLateTrack();
      });
    }
  }

  @override
  void dispose() {
    _animatedMap.dispose();
    super.dispose();
  }

  List<List<LatLng>>? _activeTrackSegments() {
    if (_useDetailsTrack &&
        _detailsOverlay != null &&
        _detailsOverlay!.hasTrackData) {
      final segs = _detailsOverlay!.segmentsForBounds();
      return segs.isEmpty ? null : segs;
    }
    if (_trackFailed) return null;
    final s = _trackSegments;
    if (s == null || s.isEmpty) return null;
    return s;
  }

  CameraFit? _trackCameraFit() {
    final segments = _activeTrackSegments();
    if (segments == null || segments.isEmpty) {
      return null;
    }
    var flat = OrbitDataService.flattenSegments(segments);
    if (_useDetailsTrack && _detailsOverlay != null) {
      for (final c in _detailsOverlay!.corners) {
        flat = [...flat, c.point];
      }
    }
    if (flat.length < 2) return null;
    var bounds = LatLngBounds.fromPoints(flat);
    bounds = _ensureMinBoundsSpan(bounds);
    return CameraFit.bounds(
      bounds: bounds,
      padding: _kFitPadding,
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
        zoom: 12,
        curve: Curves.easeOutExpo,
        duration: _kCircuitMapAnimDuration,
        cancelPreviousAnimations: true,
      );
    } else {
      _animatedMap.mapController.move(p.center, 12);
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

  void _refitToActiveTrack() {
    if (!mounted) return;
    final fit = _trackCameraFit();
    if (fit == null) return;
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

  void _onTrackSourceChanged(bool useDetails) {
    setState(() => _useDetailsTrack = useDetails);
    _didLateTrackRefit = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refitToActiveTrack());
  }

  void _scheduleInitialCamera() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInitialCamera) return;

      try {
        await _trackLoadFuture?.timeout(const Duration(milliseconds: 2400));
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

  void _nudgeZoom(double delta) {
    try {
      final ctrl = _animatedMap.mapController;
      final cam = ctrl.camera;
      final z = (cam.zoom + delta).clamp(_minZoom, _maxZoom);
      if ((z - cam.zoom).abs() < 0.001) return;
      ctrl.move(cam.center, z);
    } on Object catch (_) {}
  }

  double _effectiveMapHeight(BuildContext context) {
    if (!_mapExpanded) return widget.height;
    final h = MediaQuery.sizeOf(context).height;
    return math.min(560, math.max(320, h * 0.52));
  }

  List<Polyline> _polylinesFromTechnicalDetail(
    OrbitCircuitTechnicalDetail t,
    bool isDark,
  ) {
    final halo = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2);
    final out = <Polyline>[];
    for (final s in t.sectors) {
      if (s.points.length < 2) continue;
      out.add(
        Polyline(
          points: s.points,
          strokeWidth: s.strokeWidth + 2.5,
          color: halo,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
      out.add(
        Polyline(
          points: s.points,
          strokeWidth: s.strokeWidth,
          color: s.color,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }
    for (final g in t.gates) {
      if (g.points.length < 2) continue;
      out.add(
        Polyline(
          points: g.points,
          strokeWidth: g.strokeWidth + 1.5,
          color: Colors.white.withValues(alpha: 0.25),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
      out.add(
        Polyline(
          points: g.points,
          strokeWidth: g.strokeWidth,
          color: g.color,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }
    return out;
  }

  /// Standaardbaan (F1-blauw) of Details met GeoJSON-kleuren / fallback.
  List<Polyline> _mapPolylines(bool isDark) {
    if (_useDetailsTrack && _detailsOverlay != null) {
      final t = _detailsOverlay!.technical;
      if (t != null && !t.isEmpty) {
        return _polylinesFromTechnicalDetail(t, isDark);
      }
      final plain = _detailsOverlay!.fallbackPlainSegments;
      if (plain != null && plain.isNotEmpty) {
        final outer = (isDark ? Colors.white : _kF1Blue).withValues(alpha: 0.28);
        return polylinesFromTrackSegments(
          plain,
          strokeColor: _kF1Blue,
          strokeWidth: 4,
          outerStrokeColor: outer,
          outerStrokeWidth: 6,
        );
      }
    }

    if (_trackFailed) return const [];
    final segments = _trackSegments;
    if (segments == null || segments.isEmpty) return const [];
    final outer = (isDark ? Colors.white : _kF1Blue).withValues(alpha: 0.28);
    return polylinesFromTrackSegments(
      segments,
      strokeColor: _kF1Blue,
      strokeWidth: 4,
      outerStrokeColor: outer,
      outerStrokeWidth: 6,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f1 = Theme.of(context).extension<F1UiTheme>();
    final radius = f1?.cardBorderRadius ?? 20;
    final motionReduced = context.select<DisplaySettingsController, bool>(
      (c) => c.motionReduced,
    );
    // Zelfde toon als gesilverde OSM-tegels — minder zichtbare “letterbox”-vlakken naast de baan.
    final mapBg = Color.lerp(
      const Color(0xFF1E2430),
      scheme.surfaceContainerHighest,
      0.22,
    )!;

    final isDark = scheme.brightness == Brightness.dark;

    final p = widget.placement;
    final polylines = _mapPolylines(isDark);
    final showDetailsOverlays =
        _useDetailsTrack && _detailsOverlay != null && _hasDetailsAsset;
    final technical = _detailsOverlay?.technical;
    final showSectorChips =
        showDetailsOverlays && technical != null && !technical.isEmpty;
    final showCornerDots =
        showDetailsOverlays && _detailsOverlay!.corners.isNotEmpty;
    final l10n = context.l10n;
    final mapH = _effectiveMapHeight(context);
    // Geen glazen titelbalk meer: zoomknoppen onder expand / track-toggle.
    final zoomColumnTop = _hasDetailsAsset ? 100.0 : 56.0;

    return SizedBox(
      height: mapH,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _animatedMap.mapController,
                options: MapOptions(
                  initialCenter: p.center,
                  initialZoom: 14.2,
                  initialRotation: 0,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  backgroundColor: mapBg,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: p.panBounds,
                  ),
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    cursorKeyboardRotationOptions:
                        CursorKeyboardRotationOptions.disabled(),
                  ),
                  onMapReady: _scheduleInitialCamera,
                ),
                children: [
                  RepaintBoundary(
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(
                        kCircuitSilverNightMapMatrix,
                      ),
                      child: TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'F1Hub/1.0 (+https://f1hub.app)',
                        maxNativeZoom: 19,
                      ),
                    ),
                  ),
                  if (polylines.isNotEmpty)
                    RepaintBoundary(
                      child: PolylineLayer(polylines: polylines),
                    ),
                  if (showSectorChips)
                    RepaintBoundary(
                      child: MarkerLayer(
                        markers: [
                          for (final s in technical.sectors)
                            Marker(
                              point: s.midpoint,
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              child: _CircuitSectorMapChip(
                                sector: s,
                                motionReduced: motionReduced,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (showCornerDots)
                    RepaintBoundary(
                      child: MarkerLayer(
                        markers: [
                          for (final c in _detailsOverlay!.corners)
                            Marker(
                              point: c.point,
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              child: _CircuitCornerMapDot(
                                corner: c,
                                scheme: scheme,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MapChromeButton(
                    tooltip: _mapExpanded
                        ? l10n.circuit_map_collapse
                        : l10n.circuit_map_expand,
                    icon: _mapExpanded
                        ? Icons.fullscreen_exit_rounded
                        : Icons.open_in_full_rounded,
                    isDark: isDark,
                    onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
                  ),
                  if (_hasDetailsAsset) ...[
                    const SizedBox(height: 8),
                    _CircuitMapTrackSourceToggle(
                      scheme: scheme,
                      isDark: isDark,
                      useDetails: _useDetailsTrack,
                      onChanged: _onTrackSourceChanged,
                      standardLabel: l10n.orbit_track_standard,
                      detailsLabel: l10n.orbit_track_details,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 6,
              top: zoomColumnTop,
              bottom: 30,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MapChromeButton(
                    tooltip: l10n.circuit_map_zoom_in,
                    icon: Icons.add_rounded,
                    isDark: isDark,
                    onPressed: () => _nudgeZoom(1),
                  ),
                  const SizedBox(height: 10),
                  _MapChromeButton(
                    tooltip: l10n.circuit_map_zoom_out,
                    icon: Icons.remove_rounded,
                    isDark: isDark,
                    onPressed: () => _nudgeZoom(-1),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: _OsmAttributionChip(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// S1 / S2 / S3 op het midden van de sectorpolylijn (zelfde idee als Orbit).
class _CircuitSectorMapChip extends StatelessWidget {
  const _CircuitSectorMapChip({
    required this.sector,
    required this.motionReduced,
  });

  final OrbitSectorStroke sector;
  final bool motionReduced;

  @override
  Widget build(BuildContext context) {
    Widget core = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(color: sector.color, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: sector.color.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        sector.label,
        style: TextStyle(
          color: sector.color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );

    if (!motionReduced) {
      core = ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: core,
        ),
      );
    }

    return Tooltip(
      message: sector.label,
      child: IgnorePointer(child: core),
    );
  }
}

/// Bochtnummer (T1 …); tooltip met volledige naam.
class _CircuitCornerMapDot extends StatelessWidget {
  const _CircuitCornerMapDot({
    required this.corner,
    required this.scheme,
  });

  final CircuitDetailCornerPoint corner;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        corner.isBanked ? const Color(0xFFFFA000) : scheme.primary;
    final label = corner.number?.toString() ?? '·';

    return Tooltip(
      message: corner.name.isEmpty ? label : corner.name,
      child: IgnorePointer(
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.95),
            border: Border.all(color: borderColor, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Standaard (hoofd-GeoJSON) vs Details (`*-details.geojson` sectoren), onder de vergroten-knop.
class _CircuitMapTrackSourceToggle extends StatelessWidget {
  const _CircuitMapTrackSourceToggle({
    required this.scheme,
    required this.isDark,
    required this.useDetails,
    required this.onChanged,
    required this.standardLabel,
    required this.detailsLabel,
  });

  final ColorScheme scheme;
  final bool isDark;
  final bool useDetails;
  final void Function(bool useDetails) onChanged;
  final String standardLabel;
  final String detailsLabel;

  @override
  Widget build(BuildContext context) {
    final panelBg = isDark
        ? const Color(0xFF1E2836).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final panelBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : _kF1Blue.withValues(alpha: 0.55);

    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 52,
          decoration: BoxDecoration(
            color: panelBg,
            border: Border.all(color: panelBorder, width: 1.25),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TrackSourceCell(
              label: standardLabel,
              selected: !useDetails,
              onTap: () => onChanged(false),
              scheme: scheme,
              isDark: isDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
            _TrackSourceCell(
              label: detailsLabel,
              selected: useDetails,
              onTap: () => onChanged(true),
              scheme: scheme,
              isDark: isDark,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(7),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _TrackSourceCell extends StatelessWidget {
  const _TrackSourceCell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.isDark,
    required this.borderRadius,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: selected
                  ? _kTrackSourceModeActive.withValues(
                      alpha: isDark ? 0.88 : 0.96,
                    )
                  : Colors.transparent,
            ),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1.05,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.88)
                          : const Color(0xFF0D47A1)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoge contrast op lichte/grijze kaarttegels (was: bijna onzichtbaar wit 38%).
class _MapChromeButton extends StatelessWidget {
  const _MapChromeButton({
    required this.tooltip,
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? const Color(0xFF252E3D) : Colors.white;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF0D47A1);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : _kF1Blue.withValues(alpha: 0.6);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: fill.withValues(alpha: isDark ? 0.96 : 0.99),
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
        shape: CircleBorder(side: BorderSide(color: borderColor, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 23, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Compact OSM credit — avoids overlapping the global app bar; link opens copyright page.
class _OsmAttributionChip extends StatelessWidget {
  const _OsmAttributionChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(
            launchUrl(
              Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '© OpenStreetMap',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: isDark ? 0.45 : 0.5,
              ),
              decoration: TextDecoration.underline,
              decorationColor: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
