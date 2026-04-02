part of '../main.dart';

/// Debug-only: set `true` and run a **debug** build — team cards become solid red
/// 100px-tall blocks. If they show on mobile, the list + data path is fine and the bug
/// is in card chrome (glass/layout). If they do not show, look above [StandingsView.body].
const bool kConstructorStandingsLayoutProbe = false;

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
  var teams = <Team>[
    for (final e in items)
      if (e is Team) e,
  ];
  // Defensive: if cache/types ever yield no Team rows, still show data (fixes empty mobile/web body).
  if (teams.isEmpty) {
    teams = List<Team>.from(fallbackTeams);
  }
  final leaderPts = teams.isEmpty
      ? 0
      : teams.map((t) => t.points).reduce((a, b) => a > b ? a : b);
  final leaderDenominator =
      leaderPts > 0 ? leaderPts.toDouble() : 1.0; // avoid div by zero when scaling

  // Same header metrics as driver standings (`_buildDriverStandingsHubScrollable`).
  final header = Padding(
    padding: const EdgeInsets.fromLTRB(
      HubStandingsMetrics.headerPaddingL,
      HubStandingsMetrics.headerPaddingT,
      HubStandingsMetrics.headerPaddingR,
      HubStandingsMetrics.headerPaddingB,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.constructor_standings_title,
          style: hubDark
              ? HubVisualLanguage.f1Wide(
                  context,
                  fontSize: compact ? 24 : 28,
                  color: HubTheme.primaryOnGlassText(context),
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
        const SizedBox(height: HubStandingsMetrics.titleSubtitleGap),
        Text(
          context.l10n.constructor_standings_subtitle(
            state._selectedYear.toString(),
          ),
          style: hubDark
              ? HubVisualLanguage.titilliumSecondary(
                  context,
                  fontWeight: FontWeight.w600,
                  color: HubTheme.primaryOnGlassText(context),
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
            usableWidth: usableW,
          );

      final rows = <Widget>[];
      if (useTwoColumns) {
        for (var i = 0; i < teams.length; i += 2) {
          if (i + 1 < teams.length) {
            // No [IntrinsicHeight] — avoids expensive intrinsics; cards top-align in wide grid.
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cardFor(i)),
                  const SizedBox(width: 16),
                  Expanded(child: cardFor(i + 1)),
                ],
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

      // Not ListView.builder: row count is `teams.length` (plus header). `teams` is never
      // empty here because of [fallbackTeams] when `_cachedTeams` / typing yields no rows.

      return ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          HubStandingsMetrics.listHorizontalPad,
          listPadV,
          HubStandingsMetrics.listHorizontalPad,
          HubStandingsMetrics.listBottomPad,
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
    required this.usableWidth,
  });

  final _StandingsViewState state;
  final Team team;
  final int constructorPosition;
  final List<Driver> championshipOrder;
  final bool hubDark;
  final bool compact;
  final double leaderPointsDenominator;
  final int leaderPointsRaw;
  /// From parent [LayoutBuilder] — same idea as driver hub list rows.
  final double usableWidth;

  @override
  State<_ConstructorTeamStandingCard> createState() =>
      _ConstructorTeamStandingCardState();
}

class _ConstructorTeamStandingCardState
    extends State<_ConstructorTeamStandingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && kConstructorStandingsLayoutProbe) {
      return SizedBox(
        width: double.infinity,
        height: 100,
        child: ColoredBox(
          color: Colors.red,
          child: Center(
            child: Text(
              'Test ${widget.team.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

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

    final narrow = widget.usableWidth < 380;
    // Match `_DriverStandingsHubListRow`: fixed rank box, tight points column on narrow screens.
    final rankBox =
        narrow ? 36.0 : HubStandingsMetrics.rankBadgeSize;
    final posFs = narrow
        ? (compact ? 16.0 : 17.0)
        : (compact ? 18.0 : 20.0);
    final nameFs = narrow
        ? (compact ? 15.0 : 16.0)
        : (compact ? 15.0 : 16.0);
    final ptsFs =
        narrow ? (compact ? 17.0 : 19.0) : (compact ? 22.0 : 24.0);
    final pointsColW = narrow ? 70.0 : 82.0;
    final gapAfterName = narrow ? 14.0 : 22.0;
    final gapBeforeChevron = narrow ? 10.0 : 14.0;

    final fill = hubDark
        ? ConstructorHubColors.surface
        : theme.colorScheme.surfaceContainerHighest;
    final borderC =
        hubDark ? ConstructorHubColors.border : theme.colorScheme.outline;
    // On dark hub, match driver standings rows: glass panel + hub ink colors.
    final titleC = hubDark
        ? HubTheme.primaryOnGlassText(context)
        : theme.colorScheme.onSurface;
    final muted = hubDark
        ? HubTheme.secondaryOnGlassText(context)
        : theme.colorScheme.onSurfaceVariant;
    final greyWide = hubDark
        ? HubTheme.secondaryOnGlassText(context)
        : theme.colorScheme.onSurfaceVariant;

    const radius = 20.0;

    final rankFill = hubDark
        ? ConstructorHubColors.surfaceElevated
        : Colors.white.withValues(alpha: 0.45);

    // Same nesting as `_DriverStandingsHubListRow` glass child: one [Row] with
    // Badge → gap → Stripe(6×46) → gap → Expanded(Column[Text,Text]) → gap → points → chevron.
    // Extra: progress + driver lines below in a [Column].
    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: rankBox,
                height: rankBox,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: rankFill,
                    borderRadius: BorderRadius.circular(
                      HubStandingsMetrics.rankBadgeInnerRadius,
                    ),
                    border: Border.all(
                      color: _driverStandingsRankBadgeBorder(
                        context,
                        constructorPosition,
                      ),
                      width: constructorPosition <= 3 ? 1.6 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$constructorPosition',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: HubVisualLanguage.f1Wide(
                        context,
                        fontSize: posFs,
                        color: greyWide,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: HubStandingsMetrics.rankToStripeGap),
              Container(
                width: HubStandingsMetrics.teamStripeWidth,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: HubStandingsMetrics.stripeToTextGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HubVisualLanguage.f1Wide(
                        context,
                        fontSize: nameFs,
                        fontWeight: FontWeight.w700,
                        color: titleC,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.constructor_team_driver_count(
                        teamDrivers.length,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hubDark
                          ? HubVisualLanguage.titilliumSecondary(
                              context,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HubTheme.primaryOnGlassText(context),
                              opacity: 0.7,
                            )
                          : TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: gapAfterName),
              SizedBox(
                width: pointsColW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state._formatPoints(team.points),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: HubVisualLanguage.f1Wide(
                        context,
                        fontSize: ptsFs,
                        color: greyWide,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.pts.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: hubDark
                          ? HubVisualLanguage.titilliumSecondary(
                              context,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: HubTheme.primaryOnGlassText(context),
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
              ),
              SizedBox(width: gapBeforeChevron),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: hubDark
                    ? HubTheme.secondaryOnGlassText(context)
                        .withValues(alpha: 0.85)
                    : greyWide.withValues(alpha: 0.85),
              ),
            ],
          ),
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
    );

    // Dark hub: same shell as driver standings rows ([HubVisualLanguage.glassPanel]).
    // The old nearly-transparent gradient on [BackdropFilter] often painted invisible
    // on Flutter web / narrow viewports.
    final decoratedChild = hubDark
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: selected
                  ? Border.all(
                      color: accent.withValues(alpha: _hover ? 0.8 : 0.55),
                      width: 1.2,
                    )
                  : null,
            ),
            child: HubVisualLanguage.glassPanel(
              context: context,
              radius: radius,
              accentGlow: accent,
              accentGlowOpacity: 0.085,
              padding: EdgeInsets.symmetric(
                horizontal: HubStandingsMetrics.rowHPadding,
                vertical: HubStandingsMetrics.rowVPadding,
              ),
              child: cardBody,
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
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: HubStandingsMetrics.rowHPadding,
                vertical: HubStandingsMetrics.rowVPadding,
              ),
              child: cardBody,
            ),
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
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
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.titilliumWeb(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleC,
          ),
        ),
      ),
      Flexible(
        fit: FlexFit.loose,
        child: Text(
          context.l10n.constructor_driver_points_short(
            state._formatPoints(d.points),
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: HubVisualLanguage.f1Wide(
            context,
            fontSize: 13,
            color: greyWide,
            height: 1.2,
          ),
        ),
      ),
    ],
  );
}
