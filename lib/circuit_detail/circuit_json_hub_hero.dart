import 'package:f1/circuit_detail/circuit_card_metrics.dart';
import 'package:f1/circuit_detail/circuit_weekend_hub_action_pill.dart';
import 'package:f1/theme/hub_mobile_tuning.dart';
import 'package:f1/theme/hub_theme.dart';
import 'package:f1/theme/hub_visual_language.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Circuit detail hero: frosted shell, ISO2 + title + Weekend Hub pill, four stat tiles, lap line.
class CircuitJsonHubHero extends StatelessWidget {
  const CircuitJsonHubHero({
    super.key,
    required this.metrics,
    required this.countryCode,
    this.circuitAssetId,
  });

  final CircuitCardMetrics metrics;
  final String countryCode;
  final String? circuitAssetId;

  static const Color _f1Red = Color(0xFFE10600);
  static const Color _trophyGold = Color(0xFFFFCF00);

  String _trackTypeLabel(BuildContext context, String? key) {
    if (key == null || key.isEmpty) return '';
    final l10n = context.l10n;
    switch (key) {
      case 'type_street_circuit':
        return l10n.type_street_circuit;
      case 'type_permanent_circuit':
        return l10n.type_permanent_circuit;
      default:
        return key;
    }
  }

  bool get _hasLapRecordTime {
    final t = metrics.lapRecordTime.trim();
    return t.isNotEmpty && t != '—';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statBoxBg =
        isDark ? const Color(0xFF1F1F1F) : Colors.black.withValues(alpha: 0.05);
    final bodyGrey = isDark
        ? const Color(0xFF949494)
        : scheme.onSurface.withValues(alpha: 0.62);
    final iconMuted = isDark
        ? const Color(0xFF949494)
        : scheme.onSurface.withValues(alpha: 0.55);

    final len = metrics.lengthKm > 0 ? metrics.lengthKm.toStringAsFixed(3) : '—';
    final speed = metrics.topSpeedKmh > 0 ? '${metrics.topSpeedKmh}' : '—';
    final lapDisplay =
        _hasLapRecordTime ? metrics.lapRecordTime : '—';
    final trackLabel = _trackTypeLabel(context, metrics.trackTypeL10nKey);
    final tzLine = metrics.timezoneParenLine;

    final driver = metrics.lapRecordDriver?.trim();
    final team = metrics.lapRecordTeam?.trim();
    final year = metrics.lapRecordYear;
    final showAttributionRow = (driver != null && driver.isNotEmpty) ||
        (team != null && team.isNotEmpty) ||
        year != null;

    Widget metricTile({
      required IconData icon,
      required String valueText,
      required String label,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: statBoxBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _f1Red, size: 22),
            const SizedBox(height: 10),
            Text(
              valueText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 22,
                color: HubTheme.primaryOnGlassText(context),
                height: 1.12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
                height: 1.2,
                color: HubTheme.primaryOnGlassText(context),
                opacity: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    final hubId = circuitAssetId?.trim();
    final hasHubPill = hubId != null && hubId.isNotEmpty;
    final Widget hubPill;
    if (hubId != null && hubId.isNotEmpty) {
      hubPill = CircuitWeekendHubHeroPill(circuitAssetId: hubId);
    } else {
      hubPill = const SizedBox.shrink();
    }

    final tiles = <Widget>[
      metricTile(
        icon: Icons.straighten_rounded,
        valueText: len == '—' ? '—' : '$len km',
        label: l10n.circuits_hero_stat_length,
      ),
      metricTile(
        icon: Icons.autorenew_rounded,
        valueText: '${metrics.laps}',
        label: l10n.circuits_hero_stat_laps,
      ),
      metricTile(
        icon: Icons.speed_rounded,
        valueText: speed == '—' ? '—' : '$speed km/h',
        label: l10n.circuits_hero_stat_top_speed,
      ),
      metricTile(
        icon: Icons.emoji_events_rounded,
        valueText: lapDisplay,
        label: l10n.circuits_hero_stat_lap_record,
      ),
    ];

    Widget metricsLayout(double maxWidth) {
      const gap = 12.0;
      if (maxWidth >= 620) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      }
      if (maxWidth < HubMobileTuning.narrowLayoutWidth) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: gap),
                Expanded(child: tiles[1]),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tiles[2]),
                const SizedBox(width: gap),
                Expanded(child: tiles[3]),
              ],
            ),
          ],
        );
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(width: 138, child: tiles[i]),
            ],
          ],
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, hc) {
            final narrowHero = hc.maxWidth < HubMobileTuning.narrowLayoutWidth;
            if (narrowHero) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countryCode,
                    style: HubVisualLanguage.f1Wide(
                      context,
                      fontSize: 26,
                      color: scheme.onSurface,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metrics.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: HubVisualLanguage.f1Wide(
                      context,
                      fontSize: 28,
                      color: scheme.onSurface,
                      height: 1.08,
                    ),
                  ),
                  if (hasHubPill) ...[
                    const SizedBox(height: 12),
                    Center(child: hubPill),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  countryCode,
                  style: HubVisualLanguage.f1Wide(
                    context,
                    fontSize: 28,
                    color: scheme.onSurface,
                    height: 1.08,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    metrics.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: HubVisualLanguage.f1Wide(
                      context,
                      fontSize: 30,
                      color: scheme.onSurface,
                      height: 1.08,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                hubPill,
              ],
            );
          },
        ),
          if (metrics.location.isNotEmpty && metrics.location != '—') ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: iconMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        metrics.location,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                          opacity: isDark ? 0.72 : 0.62,
                        ),
                      ),
                      if (tzLine.isNotEmpty) ...[
                        Text(
                          '·',
                          style: TextStyle(color: bodyGrey, fontSize: 14),
                        ),
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: iconMuted,
                        ),
                        Text(
                          tzLine,
                          style: HubVisualLanguage.titilliumSecondary(
                            context,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                            opacity: isDark ? 0.72 : 0.62,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) => metricsLayout(c.maxWidth),
          ),
          if (trackLabel.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              trackLabel,
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                opacity: isDark ? 0.72 : 0.62,
              ),
            ),
          ],
          if (_hasLapRecordTime && showAttributionRow) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 22,
                    color: _trophyGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                        opacity: isDark ? 0.72 : 0.62,
                      ),
                      children: [
                        TextSpan(text: l10n.circuit_hero_lap_record_by_prefix),
                        if (driver != null && driver.isNotEmpty)
                          TextSpan(
                            text: driver,
                            style: GoogleFonts.titilliumWeb(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              color: scheme.onSurface,
                            ),
                          ),
                        if (team != null && team.isNotEmpty)
                          TextSpan(
                            text: driver != null && driver.isNotEmpty
                                ? ' ($team)'
                                : team,
                          ),
                        if (year != null)
                          TextSpan(
                            text: (driver != null && driver.isNotEmpty) ||
                                    (team != null && team.isNotEmpty)
                                ? ' · $year'
                                : '$year',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
      ],
    );

    return HubVisualLanguage.glassPanel(
      context: context,
      topAccent: _f1Red,
      accentGlow: _f1Red,
      accentGlowOpacity: 0.08,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: content,
    );
  }
}
