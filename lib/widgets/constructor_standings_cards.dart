part of '../main.dart';

String _constructorRankPrefix(List<Driver> order, Driver d) {
  final r = _championshipRankForDriver(order, d);
  return r != null ? 'P$r ' : '';
}

/// Base44-style constructor list for [StandingsView] (teams tab only). Data: JSON
/// team standings + championship-ordered drivers from `drivers_standings_*.json`.
Widget _buildConstructorStandingsHubScrollable(
  _StandingsViewState state, {
  required BuildContext context,
  required bool compact,
  required double listPadV,
}) {
  final theme = Theme.of(context);
  final hubDark = theme.brightness == Brightness.dark;
  final ch = state._championshipDriversOrdered;
  final items = state._standingsItems(false);
  final teams = <Team>[
    for (final e in items)
      if (e is Team) e,
  ];
  final leaderPts = teams.isEmpty
      ? 0
      : teams.map((t) => t.points).reduce((a, b) => a > b ? a : b);
  final leaderDenominator =
      leaderPts > 0 ? leaderPts.toDouble() : 1.0; // avoid div by zero when scaling

  const listHorizontalPad = 16.0;

  final header = Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.constructor_standings_title,
          style: hubDark
              ? HubVisualLanguage.f1Wide(
                  context,
                  fontSize: compact ? 24 : 28,
                  color: ConstructorHubColors.textPrimary,
                  height: 1.05,
                )
              : TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.4,
                  color: theme.colorScheme.onSurface,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.constructor_standings_subtitle(
            state._selectedYear.toString(),
          ),
          style: hubDark
              ? HubVisualLanguage.titilliumSecondary(
                  context,
                  fontWeight: FontWeight.w600,
                  color: ConstructorHubColors.textPrimary,
                  opacity: 0.7,
                )
              : TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      ],
    ),
  );

  return LayoutBuilder(
    builder: (context, inner) {
      var usableW = inner.maxWidth;
      if (!usableW.isFinite || usableW <= 0) {
        usableW = 320;
      }
      usableW = usableW.clamp(200.0, 10000.0);
      final useTwoColumns = usableW >= 560;

      Widget cardFor(int index) => _ConstructorTeamStandingCard(
            state: state,
            team: teams[index],
            constructorPosition: index + 1,
            championshipOrder: ch,
            hubDark: hubDark,
            compact: compact,
            leaderPointsDenominator: leaderDenominator,
            leaderPointsRaw: leaderPts,
          );

      final rows = <Widget>[];
      if (useTwoColumns) {
        for (var i = 0; i < teams.length; i += 2) {
          if (i + 1 < teams.length) {
            rows.add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cardFor(i)),
                    const SizedBox(width: 16),
                    Expanded(child: cardFor(i + 1)),
                  ],
                ),
              ),
            );
          } else {
            rows.add(cardFor(i));
          }
        }
      } else {
        for (var i = 0; i < teams.length; i++) {
          rows.add(cardFor(i));
        }
      }

      final separated = <Widget>[];
      for (var i = 0; i < rows.length; i++) {
        if (i > 0) separated.add(const SizedBox(height: 16));
        separated.add(rows[i]);
      }

      return ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          listHorizontalPad,
          listPadV,
          listHorizontalPad,
          24,
        ),
        children: [
          header,
          const SizedBox(height: 4),
          ...separated,
        ],
      );
    },
  );
}

class _ConstructorTeamStandingCard extends StatefulWidget {
  const _ConstructorTeamStandingCard({
    required this.state,
    required this.team,
    required this.constructorPosition,
    required this.championshipOrder,
    required this.hubDark,
    required this.compact,
    required this.leaderPointsDenominator,
    required this.leaderPointsRaw,
  });

  final _StandingsViewState state;
  final Team team;
  final int constructorPosition;
  final List<Driver> championshipOrder;
  final bool hubDark;
  final bool compact;
  final double leaderPointsDenominator;
  final int leaderPointsRaw;

  @override
  State<_ConstructorTeamStandingCard> createState() =>
      _ConstructorTeamStandingCardState();
}

class _ConstructorTeamStandingCardState
    extends State<_ConstructorTeamStandingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final team = widget.team;
    final hubDark = widget.hubDark;
    final compact = widget.compact;
    final constructorPosition = widget.constructorPosition;
    final championshipOrder = widget.championshipOrder;

    final accent = teamBrandPrimaryColor(team.name) ??
        F1TeamSchemes.getTeamColor(team.name);
    final teamDrivers = championshipOrder
        .where((d) => _driverTeamMatchesConstructorTeam(d, team))
        .toList();
    final selected =
        state._isCompareMode && state._selectedForComparison.contains(team);

    final progressFrac = widget.leaderPointsRaw > 0
        ? (team.points / widget.leaderPointsDenominator).clamp(0.0, 1.0)
        : (constructorPosition == 1 ? 1.0 : 0.0);

    final fill = hubDark
        ? ConstructorHubColors.surface
        : theme.colorScheme.surfaceContainerHighest;
    final borderC =
        hubDark ? ConstructorHubColors.border : theme.colorScheme.outline;
    final titleC =
        hubDark ? ConstructorHubColors.textPrimary : theme.colorScheme.onSurface;
    final muted = hubDark
        ? ConstructorHubColors.textSecondary
        : theme.colorScheme.onSurfaceVariant;
    final greyWide =
        hubDark ? ConstructorHubColors.textSecondary : theme.colorScheme.onSurfaceVariant;

    const radius = 20.0;
    const stripeW = 6.0;

    final cardBody = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: accent,
          child: const SizedBox(width: stripeW),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: compact ? 10 : 12,
                    ),
                    constraints: BoxConstraints(
                      minWidth: compact ? 46 : 50,
                      minHeight: compact ? 46 : 50,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hubDark
                          ? ConstructorHubColors.surfaceElevated
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hubDark
                            ? ConstructorHubColors.border
                            : theme.colorScheme.outline
                                .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '$constructorPosition',
                      textAlign: TextAlign.center,
                      style: HubVisualLanguage.f1Wide(
                        context,
                        fontSize: compact ? 24 : 28,
                        color: greyWide,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: GoogleFonts.titilliumWeb(
                            fontSize: compact ? 17 : 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                            color: titleC,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.constructor_team_driver_count(
                                  teamDrivers.length,
                                ),
                                style: hubDark
                                    ? HubVisualLanguage.titilliumSecondary(
                                        context,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ConstructorHubColors.textPrimary,
                                        opacity: 0.7,
                                      )
                                    : TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: muted,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            state._formatPoints(team.points),
                            style: HubVisualLanguage.f1Wide(
                              context,
                              fontSize: compact ? 28 : 32,
                              color: greyWide,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.pts.toUpperCase(),
                            style: hubDark
                                ? HubVisualLanguage.titilliumSecondary(
                                    context,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    color: ConstructorHubColors.textPrimary,
                                    opacity: 0.65,
                                  )
                                : TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    color: muted,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: greyWide.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressFrac,
                  minHeight: 6,
                  backgroundColor: hubDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : theme.colorScheme.surfaceContainerHighest,
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
              if (teamDrivers.isNotEmpty) ...[
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < teamDrivers.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < teamDrivers.length - 1 ? 10 : 0,
                        ),
                        child: _constructorDriverRow(
                          context,
                          state: state,
                          d: teamDrivers[i],
                          championshipOrder: championshipOrder,
                          greyWide: greyWide,
                          titleC: titleC,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ],
    );

    final borderOpacity = _hover ? 0.3 : 0.12;
    final decoratedChild = hubDark
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: HubVisualLanguage.glassBlurSigma,
                sigmaY: HubVisualLanguage.glassBlurSigma,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: _hover ? 0.75 : 0.55)
                        : Colors.white.withValues(alpha: borderOpacity),
                    width: selected ? 1.1 : 0.8,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: cardBody,
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? accent
                    : borderC.withValues(alpha: _hover ? 1 : 0.9),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: cardBody,
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => state._handleStandingsTap(team, false),
            borderRadius: BorderRadius.circular(radius),
            child: decoratedChild,
          ),
        ),
      ),
    );
  }
}

Widget _constructorDriverRow(
  BuildContext context, {
  required _StandingsViewState state,
  required Driver d,
  required List<Driver> championshipOrder,
  required Color greyWide,
  required Color titleC,
}) {
  return Row(
    children: [
      Text(
        _constructorRankPrefix(championshipOrder, d),
        style: HubVisualLanguage.f1Wide(
          context,
          fontSize: 13,
          color: greyWide,
          height: 1.2,
        ),
      ),
      Expanded(
        child: Text(
          d.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.titilliumWeb(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleC,
          ),
        ),
      ),
      Text(
        context.l10n.constructor_driver_points_short(
          state._formatPoints(d.points),
        ),
        style: HubVisualLanguage.f1Wide(
          context,
          fontSize: 13,
          color: greyWide,
          height: 1.2,
        ),
      ),
    ],
  );
}
