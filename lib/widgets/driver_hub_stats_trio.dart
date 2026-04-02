import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/hub_mobile_tuning.dart';
import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';
import 'constructor_hub_theme.dart';

/// Points · championship rank · podiums for driver detail hero.
class DriverHubStatsTrio extends StatelessWidget {
  const DriverHubStatsTrio({
    required this.layoutWidth,
    this.forceThreeInRow = false,
    required this.points,
    required this.rankDisplay,
    required this.podiums,
    required this.seasonYear,
    required this.pointsLabel,
    required this.rankLabel,
    required this.podiumsLabel,
    required this.accent,
    this.standingsRank,
    this.championshipLeader = false,
    super.key,
  });

  final double layoutWidth;
  final bool forceThreeInRow;
  final int? standingsRank;
  final bool championshipLeader;
  final int points;
  final String rankDisplay;
  final int podiums;
  final String seasonYear;
  final String pointsLabel;
  final String rankLabel;
  final String podiumsLabel;
  final Color accent;

  static const double _boxRadius = 14;
  static const Color _gold = Color(0xFFE8C547);

  static Color? _trophyTintForRank(int? rank) {
    if (rank == null || rank < 1 || rank > 3) return null;
    if (rank == 1) return _gold;
    if (rank == 2) return const Color(0xFFC5C9D1);
    return const Color(0xFFB87333);
  }

  static Color? _pointsCellTrophyColor(int? rank, bool championshipLeader) {
    if (championshipLeader) return _gold;
    return _trophyTintForRank(rank);
  }

  @override
  Widget build(BuildContext context) {
    final w = layoutWidth;
    final narrow = w < HubMobileTuning.narrowLayoutWidth;
    final twoCol = !forceThreeInRow && narrow && w >= 360;
    final gapH = SizedBox(width: forceThreeInRow && narrow ? 6 : 10);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nestedFill = isDark
        ? ConstructorHubColors.surfaceElevated.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.05);

    Widget cell({
      required String value,
      required String caption,
      required Color valueColor,
      bool pointsGlow = false,
      int? trophyRank,
      bool leaderTrophy = false,
    }) {
      final trophyTint = _pointsCellTrophyColor(trophyRank, leaderTrophy);
      final borderColor = pointsGlow
          ? HubTheme.statsTrioCellBorder(
              context,
              pointsCell: true,
              accent: accent,
            )
          : HubTheme.statsTrioCellBorder(
              context,
              pointsCell: false,
              accent: accent,
            );

      return DecoratedBox(
        decoration: BoxDecoration(
          color: nestedFill,
          borderRadius: BorderRadius.circular(_boxRadius),
          border: Border.all(
            color: borderColor,
            width: pointsGlow ? 1 : 0.8,
          ),
          boxShadow: pointsGlow
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: HubVisualLanguage.f1Wide(
                      context,
                      fontSize: pointsGlow ? 28 : 26,
                      color: valueColor,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    caption.toUpperCase(),
                    style: HubVisualLanguage.titilliumSecondary(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.65,
                      color: HubTheme.primaryOnGlassText(context),
                      opacity: 0.6,
                    ),
                  ),
                ],
              ),
              if (trophyTint != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: FaIcon(
                    FontAwesomeIcons.trophy,
                    size: 15,
                    color: trophyTint,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final gapV = const SizedBox(height: 12);

    final c1 = cell(
      value: '$points',
      caption: '$seasonYear $pointsLabel',
      valueColor: accent,
      pointsGlow: true,
      trophyRank: standingsRank,
      leaderTrophy: championshipLeader,
    );
    final c2 = cell(
      value: rankDisplay,
      caption: rankLabel,
      valueColor: HubTheme.primaryOnGlassText(context),
    );
    final c3 = cell(
      value: '$podiums',
      caption: podiumsLabel,
      valueColor: HubTheme.primaryOnGlassText(context),
    );

    if (forceThreeInRow || !narrow) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: c1),
          gapH,
          Expanded(child: c2),
          gapH,
          Expanded(child: c3),
        ],
      );
    }
    if (twoCol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: c1),
              gapH,
              Expanded(child: c2),
            ],
          ),
          gapV,
          c3,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        c1,
        gapV,
        c2,
        gapV,
        c3,
      ],
    );
  }
}
