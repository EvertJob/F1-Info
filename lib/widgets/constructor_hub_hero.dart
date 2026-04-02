import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/team_standings_logo.dart';
import '../theme/hub_mobile_tuning.dart';
import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';
import 'constructor_hub_stats_trio.dart';
import 'hub_asset_image_chain.dart';

/// Constructor detail hero: glass panel + large team logo (~38% width) overlapping the top edge.
class ConstructorHubHeroCard extends StatelessWidget {
  const ConstructorHubHeroCard({
    required this.teamName,
    required this.countryPrefix,
    required this.teamTitleUpper,
    required this.headquarters,
    required this.engine,
    required this.points,
    required this.rankDisplay,
    required this.constructorsTitles,
    required this.seasonYear,
    required this.pointsLabel,
    required this.championshipLabel,
    required this.titlesLabel,
    required this.accent,
    this.statsThreeInRow = false,
    super.key,
  });

  /// Resolves bundled logos under `images/constructors/{slug}.png`.
  final String teamName;
  final String countryPrefix;
  final String teamTitleUpper;
  final String headquarters;
  final String engine;
  final int points;
  final String rankDisplay;
  final int constructorsTitles;
  final String seasonYear;
  final String pointsLabel;
  final String championshipLabel;
  final String titlesLabel;
  final Color accent;
  final bool statsThreeInRow;

  static const double _heroWidthFraction = 0.385;
  static const double _heroWMin = 118;
  static const double _heroWMax = 208;
  static const double _headOverlap = 12;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final logoCandidates =
        teamStandingsLogoAssetPathCandidates(teamName, forLightTheme: light);

    if (logoCandidates.isEmpty) {
      return LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < HubMobileTuning.narrowLayoutWidth;
          final statsLayoutWidth =
              (c.maxWidth - 48).clamp(0.0, double.infinity);
          return HubVisualLanguage.glassPanel(
            context: context,
            topAccent: accent,
            accentGlow: accent,
            accentGlowOpacity: 0.09,
            padding: const EdgeInsets.all(24),
            child: _contentColumn(
              context,
              narrow: narrow,
              statsLayoutWidth: statsLayoutWidth,
              statsThreeInRow: statsThreeInRow,
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: _headOverlap),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final narrow = maxW < HubMobileTuning.narrowLayoutWidth;
          final heroW =
              (maxW * _heroWidthFraction).clamp(_heroWMin, _heroWMax);
          final statsLayoutWidth =
              (narrow ? maxW - 48 : maxW - heroW - 36)
                  .clamp(0.0, double.infinity);

          if (narrow) {
            final logoW = (maxW * 0.55).clamp(140.0, 220.0);
            return HubVisualLanguage.glassPanel(
              context: context,
              topAccent: accent,
              accentGlow: accent,
              accentGlowOpacity: 0.09,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox(
                      height: 112,
                      child: HubAssetImageChain(
                        paths: logoCandidates,
                        bundle: rootBundle,
                        width: logoW,
                        height: null,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        fallback: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _contentColumn(
                    context,
                    narrow: true,
                    statsLayoutWidth: statsLayoutWidth,
                    statsThreeInRow: statsThreeInRow,
                  ),
                ],
              ),
            );
          }

          final heroLogo = Positioned(
            top: -_headOverlap,
            right: 2,
            bottom: 14,
            width: heroW,
            child: IgnorePointer(
              child: HubAssetImageChain(
                paths: logoCandidates,
                bundle: rootBundle,
                width: heroW,
                height: null,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                fallback: const SizedBox.shrink(),
              ),
            ),
          );

          final glassCard = HubVisualLanguage.glassPanel(
            context: context,
            topAccent: accent,
            accentGlow: accent,
            accentGlowOpacity: 0.09,
            padding: EdgeInsets.fromLTRB(24, 22, heroW + 12, 22),
            child: _contentColumn(
              context,
              narrow: false,
              statsLayoutWidth: statsLayoutWidth,
              statsThreeInRow: statsThreeInRow,
            ),
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              glassCard,
              heroLogo,
            ],
          );
        },
      ),
    );
  }

  Widget _contentColumn(
    BuildContext context, {
    required bool narrow,
    required double statsLayoutWidth,
    required bool statsThreeInRow,
  }) {
    final titleFs = narrow ? 26.0 : 30.0;
    final prefixStyle = HubVisualLanguage.f1Wide(
      context,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: HubTheme.secondaryOnGlassText(context),
      height: 1.05,
    );
    final titleStyle = HubVisualLanguage.f1Wide(
      context,
      fontSize: titleFs,
      color: HubTheme.primaryOnGlassText(context),
      height: 1.05,
    );

    final titleBlock = narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (countryPrefix.isNotEmpty) ...[
                Text(countryPrefix, style: prefixStyle),
                const SizedBox(height: 6),
              ],
              Text(
                teamTitleUpper,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (countryPrefix.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Text(countryPrefix, style: prefixStyle),
                ),
              ],
              Expanded(
                child: Text(
                  teamTitleUpper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ],
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleBlock,
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 17,
              color: accent.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                headquarters,
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: 13,
                  color: HubTheme.primaryOnGlassText(context),
                  opacity: 0.72,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.bolt_outlined,
              size: 17,
              color: accent.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                engine,
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: 13,
                  color: HubTheme.primaryOnGlassText(context),
                  opacity: 0.65,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ConstructorHubStatsTrio(
          layoutWidth: statsLayoutWidth,
          forceThreeInRow: statsThreeInRow,
          points: points,
          rankDisplay: rankDisplay,
          constructorsTitles: constructorsTitles,
          seasonYear: seasonYear,
          pointsLabel: pointsLabel,
          championshipLabel: championshipLabel,
          titlesLabel: titlesLabel,
          accent: accent,
        ),
      ],
    );
  }
}
