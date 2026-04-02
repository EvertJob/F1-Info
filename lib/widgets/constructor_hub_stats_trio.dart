import 'package:flutter/material.dart';

import '../theme/hub_mobile_tuning.dart';
import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';

/// Three stat cells (Points · Championship · Titles) for constructor detail hero.
class ConstructorHubStatsTrio extends StatelessWidget {
  const ConstructorHubStatsTrio({
    required this.layoutWidth,
    this.forceThreeInRow = false,
    required this.points,
    required this.rankDisplay,
    required this.constructorsTitles,
    required this.seasonYear,
    required this.pointsLabel,
    required this.championshipLabel,
    required this.titlesLabel,
    required this.accent,
    super.key,
  });

  /// Content width inside the hero glass padding (from parent [LayoutBuilder]).
  final double layoutWidth;

  /// If true, always show three cells in one [Row].
  final bool forceThreeInRow;

  final int points;
  final String rankDisplay;
  final int constructorsTitles;
  final String seasonYear;
  final String pointsLabel;
  final String championshipLabel;
  final String titlesLabel;
  final Color accent;

  static const double _boxRadius = 12;

  static const EdgeInsets _cellPadding =
      EdgeInsets.fromLTRB(16, 16, 16, 14);

  @override
  Widget build(BuildContext context) {
    final w = layoutWidth;
    final narrow = w < HubMobileTuning.narrowLayoutWidth;
    final twoCol = !forceThreeInRow && narrow && w >= 360;
    final gapH = SizedBox(width: forceThreeInRow && narrow ? 6 : 12);

    Widget cell({
      required String value,
      required String caption,
      required Color valueColor,
      bool pointsCell = false,
    }) {
      final borderColor = HubTheme.statsTrioCellBorder(
        context,
        pointsCell: pointsCell,
        accent: accent,
      );

      return DecoratedBox(
        decoration: BoxDecoration(
          color: HubTheme.statsTrioNestedFill(context),
          borderRadius: BorderRadius.circular(_boxRadius),
          border: Border.all(
            color: borderColor,
            width: pointsCell ? 1 : 0.85,
          ),
        ),
        child: Padding(
          padding: _cellPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: HubVisualLanguage.f1Wide(
                  context,
                  fontSize: pointsCell ? 28 : 26,
                  color: valueColor,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                caption.toUpperCase(),
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.05,
                  height: 1.2,
                  color: HubTheme.primaryOnGlassText(context),
                  opacity: 0.6,
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
      pointsCell: true,
    );
    final c2 = cell(
      value: rankDisplay,
      caption: championshipLabel,
      valueColor: HubTheme.primaryOnGlassText(context),
    );
    final c3 = cell(
      value: '$constructorsTitles',
      caption: titlesLabel,
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
