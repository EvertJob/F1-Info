import 'dart:math' as math;

import 'package:f1/l10n/app_localizations.dart';
import 'package:f1/theme/f1_team_schemes.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/widgets/hub_fullscreen_glass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'simulator_models.dart';

/// Minimal multi-line chart: thin axes, 2px team-colored lines, Titillium legend.
class SimulatorTeamTrendChart extends StatelessWidget {
  const SimulatorTeamTrendChart({
    super.key,
    required this.series,
    required this.title,
    required this.hint,
    required this.emptyMessage,
    this.height = 208,
    this.compact = true,
    this.onOpenFullscreen,
  });

  final List<SimulatorTeamSeriesData> series;
  final String title;
  final String hint;
  final String emptyMessage;
  final double height;
  final bool compact;
  final VoidCallback? onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: HubVisualLanguage.titilliumSecondary(context, fontSize: 13),
          ),
        ),
      );
    }

    final chart = CustomPaint(
      painter: _TeamTrendChartPainter(
        series: series,
        labelStyle: GoogleFonts.titilliumWeb(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
      child: SizedBox.expand(),
    );

    final core = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  opacity: 0.92,
                ),
              ),
            ),
            if (compact)
              Icon(
                Icons.open_in_full_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: HubVisualLanguage.titilliumSecondary(context, fontSize: 11),
        ),
        SizedBox(height: compact ? 10 : 14),
        SizedBox(height: height - (compact ? 52 : 58), child: chart),
        SizedBox(height: compact ? 10 : 12),
        _LegendRow(series: series),
      ],
    );

    if (!compact) return core;

    final open = onOpenFullscreen;
    if (open == null) return core;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: core,
        ),
      ),
    );
  }

  static Future<void> openFullscreenIfNeeded(
    BuildContext context, {
    required List<SimulatorTeamSeriesData> series,
    required AppLocalizations l10n,
    required Color topAccent,
  }) async {
    if (series.isEmpty) return;
    await showHubFullscreenGlassDialog<void>(
      context: context,
      topAccent: topAccent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: SimulatorTeamTrendChart(
          series: series,
          title: l10n.simulator_chart_team_title,
          hint: l10n.simulator_chart_team_hint,
          emptyMessage: l10n.simulator_chart_empty,
          height: MediaQuery.sizeOf(context).height * 0.52,
          compact: false,
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.series});

  final List<SimulatorTeamSeriesData> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final s in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: F1TeamSchemes.getTeamColor(s.team),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: F1TeamSchemes.getTeamColor(s.team).withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                s.team,
                style: GoogleFonts.titilliumWeb(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TeamTrendChartPainter extends CustomPainter {
  _TeamTrendChartPainter({
    required this.series,
    required this.labelStyle,
  });

  final List<SimulatorTeamSeriesData> series;
  final TextStyle labelStyle;

  static const double _leftGutter = 36;
  static const double _bottomGutter = 22;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    final chartRect = Rect.fromLTWH(
      _leftGutter,
      8,
      size.width - _leftGutter - 10,
      size.height - _bottomGutter - 8,
    );

    final axis = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    canvas.drawLine(chartRect.bottomLeft, chartRect.bottomRight, axis);
    canvas.drawLine(chartRect.bottomLeft, chartRect.topLeft, axis);

    var maxY = 1.0;
    for (final s in series) {
      for (final y in s.cumulativePoints) {
        maxY = math.max(maxY, y);
      }
    }

    final n = series.first.cumulativePoints.length;
    if (n < 2) {
      for (final s in series) {
        final c = F1TeamSchemes.getTeamColor(s.team);
        final p = s.cumulativePoints.isEmpty ? 0.0 : s.cumulativePoints.last;
        final dy = chartRect.bottom - (p / maxY) * chartRect.height;
        final dot = Paint()
          ..color = c
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(chartRect.center.dx, dy), 4, dot);
        canvas.drawCircle(Offset(chartRect.center.dx, dy), 3, Paint()..color = c);
      }
      return;
    }

    for (final s in series) {
      final c = F1TeamSchemes.getTeamColor(s.team);
      final path = Path();
      for (var i = 0; i < s.cumulativePoints.length; i++) {
        final t = i / (n - 1);
        final x = chartRect.left + t * chartRect.width;
        final yv = s.cumulativePoints[i];
        final y = chartRect.bottom - (yv / maxY) * chartRect.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = c.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(text: '0', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(4, chartRect.bottom - tp.height / 2));

    final topVal = maxY.ceil();
    tp.text = TextSpan(text: '$topVal', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(4, chartRect.top - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TeamTrendChartPainter oldDelegate) {
    if (oldDelegate.series.length != series.length) return true;
    if (identical(oldDelegate.series, series)) return false;
    for (var i = 0; i < series.length; i++) {
      if (oldDelegate.series[i].team != series[i].team) return true;
      final a = oldDelegate.series[i].cumulativePoints;
      final b = series[i].cumulativePoints;
      if (a.length != b.length) return true;
    }
    return oldDelegate.labelStyle != labelStyle;
  }
}
