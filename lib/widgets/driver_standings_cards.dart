part of '../main.dart';

String _driverStandingsLastName(String fullName) {
  final p = fullName.trim().split(RegExp(r'\s+'));
  if (p.length >= 2) return p.last;
  return fullName.trim();
}

/// Three-letter country-style tag for standings subtitle (e.g. NED).
String _driverStandingsNationalityIso(Driver d) {
  final raw = d.nationality.trim();
  if (raw.isEmpty) return '';
  if (raw.length == 3 && RegExp(r'^[A-Za-z]{3}$').hasMatch(raw)) {
    return raw.toUpperCase();
  }
  const m = <String, String>{
    'Dutch': 'NED',
    'British': 'GBR',
    'Monegasque': 'MON',
    'Canadian': 'CAN',
    'Danish': 'DEN',
    'Australian': 'AUS',
    'French': 'FRA',
    'German': 'GER',
    'Italian': 'ITA',
    'Spanish': 'ESP',
    'American': 'USA',
    'Chinese': 'CHN',
    'Mexican': 'MEX',
    'Brazilian': 'BRA',
    'Argentine': 'ARG',
    'Finnish': 'FIN',
    'New Zealander': 'NZL',
    'Belgian': 'BEL',
    'Swiss': 'SUI',
    'Austrian': 'AUT',
    'South African': 'RSA',
    'Colombian': 'COL',
    'Indian': 'IND',
    'Irish': 'IRL',
    'Polish': 'POL',
    'Estonian': 'EST',
    'Japanese': 'JPN',
    'Thai': 'THA',
    'Korean': 'KOR',
    'Israeli': 'ISR',
    'Swedish': 'SWE',
    'Hungarian': 'HUN',
    'Norwegian': 'NOR',
    'Welsh': 'GBR',
    'Scottish': 'GBR',
    'English': 'GBR',
  };
  return m[raw] ??
      (raw.length >= 3 ? raw.substring(0, 3).toUpperCase() : raw.toUpperCase());
}

Color _driverPodiumTrophyTint(int podiumIndex0Based) {
  switch (podiumIndex0Based) {
    case 0:
      return const Color(0xFFFFD700);
    case 1:
      return const Color(0xFFC0C0C0);
    case 2:
    default:
      return const Color(0xFFCD7F32);
  }
}

Color _driverStandingsRankBadgeBorder(
  BuildContext context,
  int championshipPosition,
) {
  switch (championshipPosition) {
    case 1:
      return const Color(0xFFD4AF37);
    case 2:
      return const Color(0xFFB0B0B0);
    case 3:
      return const Color(0xFFCD7F32);
    default:
      return HubTheme.isDark(context)
          ? ConstructorHubColors.border
          : Colors.black.withValues(alpha: 0.08);
  }
}

/// Hub driver list: podium + glass search + list rows (same tree light / dark).
Widget _buildDriverStandingsHubScrollable(
  _StandingsViewState state, {
  required BuildContext context,
  required bool compact,
  required double listPadV,
}) {
  final items = state._standingsItems(true);
  final drivers = <Driver>[
    for (final e in items)
      if (e is Driver) e,
  ];
  final q = state._driverSearchQuery.trim().toLowerCase();
  final filtered = q.isEmpty
      ? drivers
      : drivers
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.team.toLowerCase().contains(q),
          )
          .toList();

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
          context.l10n.driver_standings_title,
          style: HubVisualLanguage.f1Wide(
            context,
            fontSize: compact ? 24 : 28,
            color: HubTheme.primaryOnGlassText(context),
            height: 1.05,
          ),
        ),
        const SizedBox(height: HubStandingsMetrics.titleSubtitleGap),
        Text(
          context.l10n.driver_standings_subtitle(
            state._selectedYear.toString(),
          ),
          style: HubVisualLanguage.titilliumSecondary(
            context,
            fontWeight: FontWeight.w600,
            color: HubTheme.primaryOnGlassText(context),
            opacity: 0.7,
          ),
        ),
      ],
    ),
  );

  final searchBlock = state._driverSearchController != null
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HubStandingsMetrics.searchTopGap),
            HubSearchBar(
              controller: state._driverSearchController!,
              hintText: context.l10n.hub_search_driver_hint,
            ),
            const SizedBox(height: HubStandingsMetrics.searchBottomGap),
          ],
        )
      : const SizedBox.shrink();

  return LayoutBuilder(
    builder: (context, inner) {
      var usableW = inner.maxWidth;
      if (!usableW.isFinite || usableW <= 0) {
        usableW = 320;
      }
      usableW = usableW.clamp(200.0, 10000.0);

      Widget emptySearch() => Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                context.l10n.hub_search_drivers_empty,
                textAlign: TextAlign.center,
                style: HubVisualLanguage.titilliumSecondary(context),
              ),
            ),
          );

      final podiumSeg = <Widget>[];
      if (filtered.isNotEmpty) {
        final nPodium = filtered.length >= 3 ? 3 : filtered.length;
        for (var i = 0; i < nPodium; i++) {
          if (i > 0) {
            podiumSeg.add(
              const SizedBox(width: HubStandingsMetrics.podiumCardGapH),
            );
          }
          podiumSeg.add(
            Expanded(
              child: _DriverPodiumHubCard(
                state: state,
                driver: filtered[i],
                championshipPosition: drivers.indexOf(filtered[i]) + 1,
                podiumSlotIndex: i,
              ),
            ),
          );
        }
      }

      final listSeg = <Widget>[];
      for (var i = 0; i < filtered.length; i++) {
        if (i > 0) {
          listSeg.add(const SizedBox(height: HubStandingsMetrics.listRowGap));
        }
        listSeg.add(
          _DriverStandingsHubListRow(
            state: state,
            driver: filtered[i],
            championshipPosition: drivers.indexOf(filtered[i]) + 1,
            usableWidth: usableW,
            compact: compact,
          ),
        );
      }

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
          searchBlock,
          if (filtered.isEmpty)
            emptySearch()
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: podiumSeg,
            ),
            const SizedBox(height: HubStandingsMetrics.afterPodiumGap),
            ...listSeg,
          ],
        ],
      );
    },
  );
}

class _DriverPodiumHubCard extends StatefulWidget {
  const _DriverPodiumHubCard({
    required this.state,
    required this.driver,
    required this.championshipPosition,
    required this.podiumSlotIndex,
  });

  final _StandingsViewState state;
  final Driver driver;
  final int championshipPosition;
  final int podiumSlotIndex;

  @override
  State<_DriverPodiumHubCard> createState() => _DriverPodiumHubCardState();
}

class _DriverPodiumHubCardState extends State<_DriverPodiumHubCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final scaler = MediaQuery.textScalerOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        teamBrandPrimaryColor(driver.team) ?? F1TeamSchemes.getTeamColor(driver.team);
    final selected = widget.state._isCompareMode &&
        widget.state._selectedForComparison.contains(driver);
    final radius = HubStandingsMetrics.podiumCardRadius;
    final ring = selected
        ? Border.all(
            color: accent.withValues(alpha: _hover ? 0.85 : 0.65),
            width: 1.2,
          )
        : Border.all(color: Colors.transparent, width: 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.state._handleStandingsTap(driver, true),
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedScale(
            scale: _hover ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: ring,
              ),
              child: HubVisualLanguage.glassPanel(
                context: context,
                radius: radius,
                topAccent: accent,
                accentGlow: accent,
                accentGlowOpacity: isDark ? 0.085 : 0.06,
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 28,
                          color: _driverPodiumTrophyTint(widget.podiumSlotIndex),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _driverStandingsLastName(driver.name),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HubVisualLanguage.f1Wide(
                          context,
                          fontSize: scaler.scale(17).clamp(14.0, 20.0),
                          color: HubTheme.primaryOnGlassText(context),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.team,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.state._formatPoints(driver.points),
                        textAlign: TextAlign.center,
                        style: HubVisualLanguage.f1Wide(
                          context,
                          fontSize: scaler.scale(26).clamp(20.0, 30.0),
                          color: HubTheme.primaryOnGlassText(context),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.pts.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverStandingsHubListRow extends StatefulWidget {
  const _DriverStandingsHubListRow({
    required this.state,
    required this.driver,
    required this.championshipPosition,
    required this.usableWidth,
    required this.compact,
  });

  final _StandingsViewState state;
  final Driver driver;
  final int championshipPosition;
  final double usableWidth;
  final bool compact;

  @override
  State<_DriverStandingsHubListRow> createState() =>
      _DriverStandingsHubListRowState();
}

class _DriverStandingsHubListRowState extends State<_DriverStandingsHubListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final pos = widget.championshipPosition;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        teamBrandPrimaryColor(driver.team) ?? F1TeamSchemes.getTeamColor(driver.team);
    final selected = widget.state._isCompareMode &&
        widget.state._selectedForComparison.contains(driver);
    final nat = _driverStandingsNationalityIso(driver);
    final teamLine = nat.isEmpty
        ? driver.team
        : '${driver.team} $nat';

    final narrow = widget.usableWidth < 380;
    final rankBox = HubStandingsMetrics.rankBadgeSize;
    final labelFs = narrow ? 9.0 : 10.0;
    final statFigureFs = narrow ? 17.0 : 19.0;
    final statColW = narrow ? 54.0 : 62.0;
    final gapAfterName = narrow ? 14.0 : 22.0;
    final gapBetweenStatCols = narrow ? 14.0 : 20.0;
    final gapBeforeChevron = narrow ? 10.0 : 14.0;
    final rowRadius = HubStandingsMetrics.listRowGlassRadius;

    final rankFill = isDark
        ? ConstructorHubColors.surfaceElevated
        : Colors.white.withValues(alpha: 0.45);

    Widget statCol(String label, String value) {
      return SizedBox(
        width: statColW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: labelFs,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.85,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: statFigureFs,
                color: HubTheme.primaryOnGlassText(context),
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.state._handleStandingsTap(driver, true),
          borderRadius: BorderRadius.circular(rowRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(rowRadius),
              border: selected
                  ? Border.all(
                      color: accent.withValues(alpha: _hover ? 0.8 : 0.55),
                      width: 1.2,
                    )
                  : null,
            ),
            child: HubVisualLanguage.glassPanel(
              context: context,
              radius: rowRadius,
              topAccent: accent,
              accentGlow: accent,
              accentGlowOpacity: isDark ? 0.085 : 0.06,
              padding: EdgeInsets.symmetric(
                horizontal: HubStandingsMetrics.rowHPadding,
                vertical: HubStandingsMetrics.rowVPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: rankBox,
                    height: rankBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankFill,
                      borderRadius: BorderRadius.circular(
                        HubStandingsMetrics.rankBadgeInnerRadius,
                      ),
                      border: Border.all(
                        color: _driverStandingsRankBadgeBorder(context, pos),
                        width: pos <= 3 ? 1.6 : 1,
                      ),
                    ),
                    child: Text(
                      '$pos',
                      style: HubVisualLanguage.f1Wide(
                        context,
                        fontSize: widget.compact ? 18 : 20,
                        color: HubTheme.primaryOnGlassText(context),
                        height: 1,
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
                          driver.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HubVisualLanguage.f1Wide(
                            context,
                            fontSize: widget.compact ? 15 : 16,
                            color: HubTheme.primaryOnGlassText(context),
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teamLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HubVisualLanguage.titilliumSecondary(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: gapAfterName),
                  statCol(
                    context.l10n.wins.toUpperCase(),
                    '${driver.seasonStandingWins ?? driver.wins}',
                  ),
                  SizedBox(width: gapBetweenStatCols),
                  statCol(
                    context.l10n.podiums.toUpperCase(),
                    '${driver.seasonStandingPodiums ?? driver.podiums}',
                  ),
                  SizedBox(width: gapBetweenStatCols),
                  statCol(
                    context.l10n.pts.toUpperCase(),
                    widget.state._formatPoints(driver.points),
                  ),
                  SizedBox(width: gapBeforeChevron),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: HubTheme.secondaryOnGlassText(context)
                        .withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
