import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/hub_mobile_tuning.dart';
import '../theme/hub_theme.dart';
import '../theme/hub_visual_language.dart';
import 'driver_hub_stats_trio.dart';
import 'f1_hub_image_fallback.dart';
import 'hub_asset_image_chain.dart';

/// Driver detail hero: glass panel + large portrait (~38% width) overlapping the top edge.
class DriverHubHeroCard extends StatelessWidget {
  const DriverHubHeroCard({
    required this.countryPrefix,
    required this.driverTitleUpper,
    required this.teamLine,
    required this.numberLine,
    required this.points,
    required this.rankDisplay,
    required this.podiums,
    required this.seasonYear,
    required this.pointsLabel,
    required this.rankLabel,
    required this.podiumsLabel,
    required this.accent,
    required this.flagEmoji,
    required this.flagHeroTag,
    required this.portraitAssetPathCandidates,
    required this.portraitInitials,
    this.standingsRank,
    this.championshipLeader = false,
    this.statsThreeInRow = false,
    super.key,
  });

  final String countryPrefix;
  final String driverTitleUpper;
  final String teamLine;
  final String numberLine;
  final int points;
  final String rankDisplay;
  final int podiums;
  final String seasonYear;
  final String pointsLabel;
  final String rankLabel;
  final String podiumsLabel;
  final Color accent;

  final String flagEmoji;
  final String flagHeroTag;

  final List<String> portraitAssetPathCandidates;
  final String portraitInitials;

  final int? standingsRank;
  final bool championshipLeader;
  /// When true, stats are always one horizontal row.
  final bool statsThreeInRow;

  static const double _flagFontSize = 30;

  /// ~35–40% of card width; clamp keeps narrow phones usable.
  static const double _heroWidthFraction = 0.385;
  static const double _heroWMin = 118;
  static const double _heroWMax = 208;

  /// Head extends above the rounded card for depth (sport-hub “pop”).
  static const double _headOverlap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final narrow = maxW < HubMobileTuning.narrowLayoutWidth;

        Widget portraitBlock(double w) {
          final chain = HubAssetImageChain(
            paths: portraitAssetPathCandidates,
            bundle: rootBundle,
            width: w,
            height: null,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            glassFallbackAccent: accent,
            fallback: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: w * 0.88,
                height: w * 0.95,
                child: F1HubImageGlassFallback(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(10),
                  accentGradient: accent,
                ),
              ),
            ),
          );
          if (narrow) {
            return SizedBox(height: 132, child: chain);
          }
          return chain;
        }

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

        final titleRow = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (countryPrefix.isNotEmpty) ...[
                    Text(countryPrefix, style: prefixStyle),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          driverTitleUpper,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      if (flagEmoji.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Hero(
                          tag: flagHeroTag,
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              flagEmoji,
                              style: const TextStyle(
                                fontSize: _flagFontSize,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            driverTitleUpper,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        if (flagEmoji.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 2),
                            child: Hero(
                              tag: flagHeroTag,
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  flagEmoji,
                                  style: const TextStyle(
                                    fontSize: _flagFontSize,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );

        final heroW =
            (maxW * _heroWidthFraction).clamp(_heroWMin, _heroWMax);
        final statsContentWidth =
            (narrow ? maxW - 48 : maxW - heroW - 36).clamp(0.0, double.infinity);

        final body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleRow,
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 17,
                  color: accent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    teamLine,
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
                  Icons.confirmation_number_outlined,
                  size: 17,
                  color: accent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    numberLine,
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
            DriverHubStatsTrio(
              layoutWidth: statsContentWidth,
              forceThreeInRow: statsThreeInRow,
              points: points,
              rankDisplay: rankDisplay,
              podiums: podiums,
              seasonYear: seasonYear,
              pointsLabel: pointsLabel,
              rankLabel: rankLabel,
              podiumsLabel: podiumsLabel,
              accent: accent,
              standingsRank: standingsRank,
              championshipLeader: championshipLeader,
            ),
          ],
        );

        if (narrow) {
          final logoW = (maxW * 0.52).clamp(118.0, 200.0);
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
                Center(child: portraitBlock(logoW)),
                const SizedBox(height: 12),
                body,
              ],
            ),
          );
        }

        final heroImage = Positioned(
          top: -_headOverlap,
          right: 2,
          bottom: 14,
          width: heroW,
          child: IgnorePointer(child: portraitBlock(heroW)),
        );

        final glassCard = HubVisualLanguage.glassPanel(
          context: context,
          topAccent: accent,
          accentGlow: accent,
          accentGlowOpacity: 0.09,
          padding: EdgeInsets.fromLTRB(24, 22, heroW + 12, 22),
          child: body,
        );

        return Padding(
          padding: const EdgeInsets.only(top: _headOverlap),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              glassCard,
              heroImage,
            ],
          ),
        );
      },
    );
  }
}
