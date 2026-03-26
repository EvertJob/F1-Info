import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:f1/theme/f1_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Single sample along the lap: distance from start (meters) and altitude (meters).
class ElevationPoint {
  const ElevationPoint({
    required this.distance,
    required this.altitude,
    this.lon,
    this.lat,
  });

  final double distance;
  final double altitude;

  /// Geographic position of this sample (for mapping corner Points onto the profile).
  final double? lon;
  final double? lat;
}

/// Parsed turn marker positioned on the elevation profile X-axis (distance in m).
class ElevationTurnLayout {
  const ElevationTurnLayout({
    required this.turnNumber,
    required this.distanceM,
    required this.showLabel,
    required this.labelOffsetM,
    required this.isBankedHighlight,
    this.displayName,
  });

  final int turnNumber;
  final double distanceM;
  final bool showLabel;

  /// Horizontal offset (meters along lap) for badge when avoiding collisions.
  final double labelOffsetM;

  /// Turns 3 / 14 (Zandvoort banking) when [technicalBankingHighlights] is true.
  final bool isBankedHighlight;

  /// GeoJSON `properties.name`, e.g. `T3 (Hugenholtzbocht)`.
  final String? displayName;
}

/// Sector span from technical GeoJSON LineStrings (`start_m` / `end_m` / `name`).
class ElevationSectorBand {
  const ElevationSectorBand({
    required this.startM,
    required this.endM,
    required this.label,
  });

  final double startM;
  final double endM;
  final String label;
}

/// Index of [points] closest to [turnLon]/[turnLat] (haversine), or `null` if no geo.
int? closestElevationIndexToTurn(
  List<ElevationPoint> points,
  double turnLon,
  double turnLat,
) {
  if (points.isEmpty) return null;
  var bestI = 0;
  var bestD = double.infinity;
  var any = false;
  for (var i = 0; i < points.length; i++) {
    final lon = points[i].lon;
    final lat = points[i].lat;
    if (lon == null || lat == null) continue;
    any = true;
    final d = _haversineMeters(lat, lon, turnLat, turnLon);
    if (d < bestD) {
      bestD = d;
      bestI = i;
    }
  }
  return any ? bestI : null;
}

/// Extracts Point features with `properties.number` and maps each to profile distance.
/// Applies chicane-style label hiding when two turns are within [minLabelSeparationM].
List<ElevationTurnLayout> layoutElevationTurnMarkersFromGeoJson(
  Map<String, dynamic> featureCollection,
  List<ElevationPoint> points, {
  double minLabelSeparationM = 115,
  bool technicalBankingHighlights = false,
}) {
  if (points.length < 2) return const [];

  final features = featureCollection['features'];
  if (features is! List) return const [];

  final raw = <({int num, double dist, String? displayName})>[];
  for (final f in features) {
    if (f is! Map<String, dynamic>) continue;
    final geom = f['geometry'];
    if (geom is! Map<String, dynamic>) continue;
    if (geom['type'] != 'Point') continue;
    final props = f['properties'];
    if (props is! Map<String, dynamic>) continue;
    final n = props['number'];
    if (n is! num) continue;
    final turnNum = n.toInt();
    final rawName = props['name'];
    final displayName = rawName is String ? rawName : null;
    final coords = geom['coordinates'];
    if (coords is! List || coords.length < 2) continue;
    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    final idx = closestElevationIndexToTurn(points, lon, lat);
    if (idx == null) continue;
    raw.add((num: turnNum, dist: points[idx].distance, displayName: displayName));
  }

  if (raw.isEmpty) return const [];

  raw.sort((a, b) => a.dist.compareTo(b.dist));

  final layouts = <ElevationTurnLayout>[];
  for (var i = 0; i < raw.length; i++) {
    final t = raw[i];
    var showLabel = true;

    if (i > 0) {
      final prev = raw[i - 1];
      final gap = t.dist - prev.dist;
      if (gap < minLabelSeparationM) {
        showLabel = false;
      }
    }

    final banked =
        technicalBankingHighlights && (t.num == 3 || t.num == 14);

    layouts.add(
      ElevationTurnLayout(
        turnNumber: t.num,
        distanceM: t.dist,
        showLabel: showLabel,
        labelOffsetM: 0,
        isBankedHighlight: banked,
        displayName: t.displayName,
      ),
    );
  }

  return layouts;
}

/// LineString sector features with `start_m`, `end_m`, and `name` (technical master GeoJSON).
List<ElevationSectorBand> elevationSectorBandsFromGeoJsonMap(
  Map<String, dynamic> featureCollection,
) {
  final features = featureCollection['features'];
  if (features is! List) return const [];

  final out = <ElevationSectorBand>[];
  for (final f in features) {
    if (f is! Map<String, dynamic>) continue;
    final geom = f['geometry'];
    if (geom is! Map<String, dynamic>) continue;
    if (geom['type'] != 'LineString') continue;
    final props = f['properties'];
    if (props is! Map<String, dynamic>) continue;
    final start = props['start_m'];
    final end = props['end_m'];
    final name = props['name'];
    if (start is! num || end is! num) continue;
    if (name is! String) continue;
    out.add(
      ElevationSectorBand(
        startM: start.toDouble(),
        endM: end.toDouble(),
        label: name,
      ),
    );
  }
  out.sort((a, b) => a.startM.compareTo(b.startM));
  return out;
}

String? elevationTrackballContextLine(
  double distanceM,
  List<ElevationSectorBand> sectors,
  List<ElevationTurnLayout> turns,
) {
  String? sectorLabel;
  for (final s in sectors) {
    if (distanceM >= s.startM && distanceM <= s.endM) {
      sectorLabel = s.label;
      break;
    }
  }

  ElevationTurnLayout? nearest;
  var best = double.infinity;
  const snapM = 140.0;
  for (final t in turns) {
    final d = (t.distanceM - distanceM).abs();
    if (d < best) {
      best = d;
      nearest = t;
    }
  }
  String? turnPart;
  if (nearest != null && best <= snapM) {
    turnPart = nearest.displayName ?? 'Turn ${nearest.turnNumber}';
  }

  if (turnPart != null && sectorLabel != null) {
    return '$turnPart · $sectorLabel';
  }
  return turnPart ?? sectorLabel;
}

/// Parses GeoJSON [FeatureCollection] LineString features into [ElevationPoint]s.
///
/// Uses the third coordinate (Z) as elevation in meters when present; otherwise `0`.
/// [distance] is cumulative great-circle distance in meters along all sectors in
/// feature order (duplicated sector boundary points are skipped).
List<ElevationPoint> elevationPointsFromGeoJsonMap(
  Map<String, dynamic> featureCollection,
) {
  final features = featureCollection['features'];
  if (features is! List) return const [];

  double cumulativeM = 0;
  double? prevLat;
  double? prevLon;
  final out = <ElevationPoint>[];

  void appendPoint(double lon, double lat, double alt) {
    if (prevLat != null && prevLon != null) {
      cumulativeM += _haversineMeters(prevLat!, prevLon!, lat, lon);
    }
    prevLat = lat;
    prevLon = lon;
    out.add(
      ElevationPoint(
        distance: cumulativeM,
        altitude: alt,
        lon: lon,
        lat: lat,
      ),
    );
  }

  for (final raw in features) {
    if (raw is! Map<String, dynamic>) continue;
    final geom = raw['geometry'];
    if (geom is! Map<String, dynamic>) continue;
    if (geom['type'] != 'LineString') continue;
    final coords = geom['coordinates'];
    if (coords is! List) continue;

    for (final c in coords) {
      if (c is! List || c.length < 2) continue;
      final lon = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      final alt = c.length >= 3 ? (c[2] as num).toDouble() : 0.0;

      if (out.isNotEmpty &&
          prevLon != null &&
          prevLat != null &&
          (lon - prevLon!).abs() < 1e-9 &&
          (lat - prevLat!).abs() < 1e-9) {
        continue;
      }
      appendPoint(lon, lat, alt);
    }
  }

  return out;
}

/// Decodes a JSON string and returns elevation samples.
List<ElevationPoint> elevationPointsFromGeoJsonString(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) return const [];
  return elevationPointsFromGeoJsonMap(decoded);
}

double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusM = 6371000.0;
  final rLat1 = lat1 * math.pi / 180;
  final rLat2 = lat2 * math.pi / 180;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rLat1) *
          math.cos(rLat2) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusM * c;
}

/// F1 circuit elevation profile (Syncfusion [SfCartesianChart] + [SplineAreaSeries]).
///
/// Interactive sampling uses [TrackballBehavior] (single tap / configured mode)—
/// same role as touch/hover tooltips in other chart packages.
class F1ElevationChart extends StatelessWidget {
  const F1ElevationChart({
    super.key,
    required this.points,
    this.height = 160,
    this.lineColor,
    this.useF1RedLine = false,
    this.trackballActivationMode = ActivationMode.singleTap,
    this.axisLabelColor,

    /// Full GeoJSON string (same file as profile): Point features with `properties.number`.
    this.geoJsonForTurnMarkers,

    /// When true (Orbit technical mode), turns 3 & 14 use accent line / glow.
    this.technicalBankingHighlights = false,

    /// Orbit technical dashboard: visible Y-axis, grid, peak callouts, deeper red spline.
    this.dashboardStyle = false,
  });

  /// Profile samples (e.g. from [elevationPointsFromGeoJsonMap]).
  final List<ElevationPoint> points;

  final double height;

  /// Spline border color when [useF1RedLine] is false. Defaults to white.
  final Color? lineColor;

  /// Use F1 red (`#E10600`) for the spline border instead of [lineColor]/white.
  final bool useF1RedLine;

  final ActivationMode trackballActivationMode;

  final Color? axisLabelColor;

  final String? geoJsonForTurnMarkers;

  final bool technicalBankingHighlights;

  /// Rich “F1 Hub technical” chart treatment (grid, axis, peaks).
  final bool dashboardStyle;

  static const Color _f1Red = Color(0xFFE10600);
  static const Color _deepTrackRed = Color(0xFF9A1027);

  /// LineString features only; Z = altitude (m). X uses cumulative distance (m).
  static List<ElevationPoint> parseFeatureCollection(
    Map<String, dynamic> featureCollection,
  ) =>
      elevationPointsFromGeoJsonMap(featureCollection);

  static List<ElevationPoint> parseFeatureCollectionJson(String json) =>
      elevationPointsFromGeoJsonString(json);

  List<CartesianChartAnnotation> _buildAnnotations(
    List<ElevationTurnLayout> turns,
    double yMin,
    double yMax,
    double yMid,
    double yBadge,
    double chartPixelHeight, {
    required bool glassBadges,
    required double badgeBlurSigma,
  }) {
    const dash = <double>[4, 4];
    final annotations = <CartesianChartAnnotation>[];

    for (final t in turns) {
      final lineColor = t.isBankedHighlight
          ? const Color(0xFFFFB74D).withValues(alpha: 0.42)
          : Colors.white.withValues(alpha: 0.15);
      final glow = t.isBankedHighlight
          ? ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5)
          : null;

      annotations.add(
        CartesianChartAnnotation(
          coordinateUnit: CoordinateUnit.point,
          region: AnnotationRegion.plotArea,
          x: t.distanceM,
          y: yMid,
          horizontalAlignment: ChartAlignment.center,
          verticalAlignment: ChartAlignment.center,
          widget: _TurnDashedVerticalLine(
            height: chartPixelHeight + 24,
            color: lineColor,
            dashPattern: dash,
            glowMask: glow,
            strokeWidth: t.isBankedHighlight ? 1.4 : 1,
          ),
        ),
      );

      if (t.showLabel) {
        final bx = t.distanceM + t.labelOffsetM;
        annotations.add(
          CartesianChartAnnotation(
            coordinateUnit: CoordinateUnit.point,
            region: AnnotationRegion.plotArea,
            x: bx,
            y: yBadge,
            horizontalAlignment: ChartAlignment.center,
            verticalAlignment: ChartAlignment.center,
            widget: _TurnNumberBadge(
              number: t.turnNumber,
              accent: t.isBankedHighlight,
              useGlassBackdrop: glassBadges,
              blurSigma: badgeBlurSigma,
            ),
          ),
        );
      }
    }
    return annotations;
  }

  /// Local maxima along the lap with minimum prominence — top [maxLabels] only.
  static List<CartesianChartAnnotation> buildPeakCalloutAnnotations(
    List<ElevationPoint> points, {
    int maxLabels = 5,
    double minProminenceM = 0.55,
  }) {
    if (points.length < 3) return const [];
    final candidates = <({double dist, double alt, double prom})>[];
    for (var i = 1; i < points.length - 1; i++) {
      final a = points[i].altitude;
      final a0 = points[i - 1].altitude;
      final a1 = points[i + 1].altitude;
      if (a >= a0 && a >= a1) {
        final prom = a - math.max(a0, a1);
        if (prom >= minProminenceM) {
          candidates.add((dist: points[i].distance, alt: a, prom: prom));
        }
      }
    }
    candidates.sort((a, b) => b.prom.compareTo(a.prom));
    final out = <CartesianChartAnnotation>[];
    for (final c in candidates.take(maxLabels)) {
      out.add(
        CartesianChartAnnotation(
          coordinateUnit: CoordinateUnit.point,
          region: AnnotationRegion.plotArea,
          x: c.dist,
          y: c.alt,
          horizontalAlignment: ChartAlignment.center,
          verticalAlignment: ChartAlignment.near,
          widget: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${c.alt.toStringAsFixed(1)}m',
              style: TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.88),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: height);
    }

    final scheme = Theme.of(context).colorScheme;
    final f1Ui =
        Theme.of(context).extension<F1UiTheme>() ?? F1UiTheme.fallback();
    final borderCol = dashboardStyle
        ? _deepTrackRed
        : (useF1RedLine ? _f1Red : (lineColor ?? Colors.white));
    final yLabelStrong =
        axisLabelColor ?? scheme.onSurface.withValues(alpha: 0.94);
    final redAreaFill = useF1RedLine || dashboardStyle;

    final yMin = points.map((e) => e.altitude).reduce(math.min);
    final yMax = points.map((e) => e.altitude).reduce(math.max);
    final yMid = (yMin + yMax) / 2;
    final span = (yMax - yMin).clamp(1.0, double.infinity);
    final yBadge = yMin + span * 0.04;

    final yAxisMin = math.min(-5.0, yMin - 2.0);
    final yAxisMax = math.max(20.0, yMax + 2.0);

    Map<String, dynamic>? geoMap;
    List<ElevationTurnLayout> turns = const [];
    final raw = geoJsonForTurnMarkers;
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          geoMap = map;
          turns = layoutElevationTurnMarkersFromGeoJson(
            map,
            points,
            technicalBankingHighlights: technicalBankingHighlights,
          );
        }
      } catch (_) {}
    }

    final sectors = geoMap != null
        ? elevationSectorBandsFromGeoJsonMap(geoMap)
        : <ElevationSectorBand>[];

    final glassBadges = dashboardStyle || useF1RedLine;
    final badgeBlurSigma =
        f1Ui.glassBlur > 0 ? f1Ui.glassBlur * 0.45 : 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartH = constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite
            ? math.min(height, constraints.maxHeight)
            : height;

        final turnAnnotations = turns.isEmpty
            ? <CartesianChartAnnotation>[]
            : _buildAnnotations(
                turns,
                yMin,
                yMax,
                yMid,
                yBadge,
                chartH,
                glassBadges: glassBadges,
                badgeBlurSigma: badgeBlurSigma,
              );
        final peakAnnotations = dashboardStyle
            ? buildPeakCalloutAnnotations(points)
            : <CartesianChartAnnotation>[];
        final annotations = <CartesianChartAnnotation>[
          ...peakAnnotations,
          ...turnAnnotations,
        ];
        final annotationsArg = annotations.isEmpty ? null : annotations;

        final trackball = TrackballBehavior(
          enable: true,
          activationMode: trackballActivationMode,
          lineType: TrackballLineType.vertical,
          lineWidth: 1,
          lineColor: Colors.white.withValues(alpha: 0.45),
          tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
          tooltipSettings: InteractiveTooltip(
            color: Colors.transparent,
            borderWidth: 0,
            borderColor: Colors.transparent,
          ),
          builder: (BuildContext ctx, TrackballDetails details) {
            final p = details.point;
            if (p == null) return const SizedBox.shrink();
            final alt = (p.y as num).toDouble();
            final dist = (p.x as num).toDouble();
            final subtitle =
                elevationTrackballContextLine(dist, sectors, turns);
            return _GlassElevationTrackballTooltip(
              altitudeM: alt,
              subtitle: subtitle,
              scheme: scheme,
              f1Ui: f1Ui,
            );
          },
        );

        return SizedBox(
          height: chartH,
          child: SfCartesianChart(
            backgroundColor: Colors.transparent,
            plotAreaBackgroundColor: Colors.transparent,
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            annotations: annotationsArg,
            primaryXAxis: NumericAxis(
              isVisible: dashboardStyle,
              opposedPosition: false,
              axisLine: AxisLine(
                width: dashboardStyle ? 1 : 0,
                color: scheme.outline.withValues(
                  alpha: dashboardStyle ? 0.35 : 0,
                ),
              ),
              majorGridLines: MajorGridLines(
                width: dashboardStyle ? 1 : 0,
                color: scheme.outline.withValues(
                  alpha: dashboardStyle ? 0.12 : 0,
                ),
              ),
              majorTickLines: MajorTickLines(
                size: dashboardStyle ? 3 : 0,
                color: scheme.outline.withValues(
                  alpha: dashboardStyle ? 0.4 : 0,
                ),
              ),
              minorGridLines: const MinorGridLines(width: 0),
              minorTickLines: const MinorTickLines(size: 0),
              labelStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.88),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                fontFamily: 'TitilliumWeb',
              ),
              axisLabelFormatter: (AxisLabelRenderDetails d) {
                final m = d.value.toDouble();
                final text = m >= 1000
                    ? '${(m / 1000).toStringAsFixed(1)} km'
                    : '${m.round()} m';
                return ChartAxisLabel(
                  text,
                  TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'TitilliumWeb',
                  ),
                );
              },
            ),
            primaryYAxis: NumericAxis(
              isVisible: dashboardStyle,
              minimum: dashboardStyle ? yAxisMin : null,
              maximum: dashboardStyle ? yAxisMax : null,
              rangePadding: dashboardStyle
                  ? ChartRangePadding.none
                  : ChartRangePadding.additional,
              labelFormat: '{value}',
              axisLine: AxisLine(
                width: dashboardStyle ? 1 : 0,
                color: scheme.outline.withValues(
                  alpha: dashboardStyle ? 0.35 : 0,
                ),
              ),
              majorGridLines: MajorGridLines(
                width: dashboardStyle ? 1 : 0,
                color: Colors.white.withValues(
                  alpha: dashboardStyle ? 0.14 : 0,
                ),
                dashArray: dashboardStyle ? const <double>[4, 4] : null,
              ),
              minorGridLines: const MinorGridLines(width: 0),
              majorTickLines: MajorTickLines(
                size: dashboardStyle ? 4 : 0,
                color: scheme.outline.withValues(
                  alpha: dashboardStyle ? 0.35 : 0,
                ),
              ),
              minorTickLines: const MinorTickLines(size: 0),
              labelStyle: TextStyle(
                color: yLabelStrong,
                fontSize: dashboardStyle ? 10 : 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'TitilliumWeb',
              ),
              title: AxisTitle(
                text: dashboardStyle ? 'Elevation (m)' : '',
                textStyle: TextStyle(
                  color: yLabelStrong.withValues(alpha: 0.95),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'TitilliumWeb',
                ),
              ),
            ),
            trackballBehavior: trackball,
            series: <SplineAreaSeries<ElevationPoint, double>>[
              SplineAreaSeries<ElevationPoint, double>(
                dataSource: points,
                xValueMapper: (ElevationPoint e, _) => e.distance,
                yValueMapper: (ElevationPoint e, _) => e.altitude,
                splineType: SplineType.natural,
                borderDrawMode: BorderDrawMode.top,
                borderWidth: 2,
                borderColor: borderCol,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: redAreaFill
                      ? <Color>[
                          _f1Red.withValues(alpha: 0.30),
                          _f1Red.withValues(alpha: 0.08),
                          _f1Red.withValues(alpha: 0.0),
                        ]
                      : <Color>[
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                  stops: redAreaFill
                      ? const <double>[0.0, 0.42, 1.0]
                      : null,
                ),
                color: Colors.transparent,
                enableTrackball: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassElevationTrackballTooltip extends StatelessWidget {
  const _GlassElevationTrackballTooltip({
    required this.altitudeM,
    required this.subtitle,
    required this.scheme,
    required this.f1Ui,
  });

  final double altitudeM;
  final String? subtitle;
  final ColorScheme scheme;
  final F1UiTheme f1Ui;

  @override
  Widget build(BuildContext context) {
    final blur = f1Ui.glassBlur > 0 ? f1Ui.glassBlur * 0.45 : 0.0;
    final fill = scheme.surfaceContainerHighest.withValues(
      alpha: f1Ui.glassBlur > 0 ? 0.42 : 0.92,
    );

    Widget card = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: fill,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${altitudeM.toStringAsFixed(1)} m',
            style: TextStyle(
              fontFamily: 'TitilliumWeb',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.15,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );

    if (blur > 0) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: card,
        ),
      );
    }

    return card;
  }
}

class _TurnDashedVerticalLine extends StatelessWidget {
  const _TurnDashedVerticalLine({
    required this.height,
    required this.color,
    required this.dashPattern,
    this.glowMask,
    this.strokeWidth = 1,
  });

  final double height;
  final Color color;
  final List<double> dashPattern;
  final ui.MaskFilter? glowMask;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(10, height),
      painter: _DashedVerticalPainter(
        color: color,
        dashPattern: dashPattern,
        glowMask: glowMask,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _DashedVerticalPainter extends CustomPainter {
  _DashedVerticalPainter({
    required this.color,
    required this.dashPattern,
    this.glowMask,
    required this.strokeWidth,
  });

  final Color color;
  final List<double> dashPattern;
  final ui.MaskFilter? glowMask;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    if (glowMask != null) {
      paint.maskFilter = glowMask;
    }

    if (dashPattern.isEmpty) return;
    var y = 0.0;
    var i = 0;
    while (y < size.height) {
      final len = dashPattern[i % dashPattern.length];
      final isDash = i % 2 == 0;
      final y2 = (y + len).clamp(0.0, size.height);
      if (isDash && y2 > y) {
        canvas.drawLine(Offset(cx, y), Offset(cx, y2), paint);
      }
      y = y2;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVerticalPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glowMask != glowMask;
  }
}

class _TurnNumberBadge extends StatelessWidget {
  const _TurnNumberBadge({
    required this.number,
    this.accent = false,
    this.useGlassBackdrop = false,
    this.blurSigma = 10,
  });

  final int number;
  final bool accent;
  final bool useGlassBackdrop;
  final double blurSigma;

  static const Color _text = Color(0xFF1A1D21);

  @override
  Widget build(BuildContext context) {
    final solidFill =
        accent ? const Color(0xFFFFE8CC) : const Color(0xFFECEFF1);
    final borderColor = accent
        ? const Color(0xFFFF9800).withValues(alpha: 0.65)
        : const Color(0xFF263238).withValues(alpha: 0.22);

    Widget disc = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: useGlassBackdrop
            ? Colors.white.withValues(alpha: 0.78)
            : solidFill,
        border: Border.all(color: borderColor, width: accent ? 1.25 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: useGlassBackdrop ? 6 : 3,
            offset: const Offset(0, 1),
          ),
          if (accent)
            BoxShadow(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.28),
              blurRadius: 8,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'TitilliumWeb',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
          color: _text,
        ),
      ),
    );

    if (useGlassBackdrop) {
      return ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurSigma.clamp(4.0, 24.0),
            sigmaY: blurSigma.clamp(4.0, 24.0),
          ),
          child: disc,
        ),
      );
    }
    return disc;
  }
}
