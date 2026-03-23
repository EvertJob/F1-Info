part of '../main.dart';

String _driverTlaFromName(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  if (p.isEmpty) return '???';
  if (p.length == 1) {
    final s = p[0];
    return s.length >= 3 ? s.substring(0, 3).toUpperCase() : s.toUpperCase();
  }
  final a = p.first[0];
  final last = p.last;
  final b = last.length >= 2 ? last.substring(0, 2) : last;
  return '$a$b'.toUpperCase();
}

String _teamTlaFromName(String name) {
  final p =
      name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (p.length >= 3) {
    return '${p[0][0]}${p[1][0]}${p[2][0]}'.toUpperCase();
  }
  if (p.length == 2) {
    return '${p[0][0]}${p[1][0]}R'.toUpperCase();
  }
  if (p.length == 1 && p[0].length >= 3) {
    return p[0].substring(0, 3).toUpperCase();
  }
  return name.isNotEmpty ? name.substring(0, name.length.clamp(0, 3)).toUpperCase() : '???';
}

List<int> _paddockResolvedDriverNumbers(ProfileFavorites f) {
  if (f.favoriteDriverNumbers.isNotEmpty) {
    return f.favoriteDriverNumbers.take(8).toList(growable: false);
  }
  if (f.favoriteDriver != null && f.favoriteDriver!.isNotEmpty) {
    final d = _findDriver2026ByName(f.favoriteDriver!);
    if (d != null) return [d.number];
  }
  return const [];
}

List<RaceResultRow> _paddockPodiumRowsForRace(Race race) {
  final rows =
      SessionDataManager().raceResultsCache[SessionDataManager()
              .raceResultsKeyFor(race)] ??
          const <RaceResultRow>[];
  final sortedRows = List<RaceResultRow>.from(rows)
    ..sort((a, b) {
      final positionA = _extractFinishPosition(a.finish) ?? 999;
      final positionB = _extractFinishPosition(b.finish) ?? 999;
      return positionA.compareTo(positionB);
    });
  return sortedRows
      .where((row) {
        final position = _extractFinishPosition(row.finish);
        return position != null && position > 0 && position <= 3;
      })
      .take(3)
      .toList(growable: false);
}

Race? _paddockLatestCompletedRace() {
  final now = DateTime.now();
  for (final race in races.reversed) {
    if (!race.date.isAfter(now)) return race;
  }
  return races.isNotEmpty ? races.last : null;
}

String _paddockPodiumSummaryLine(Race race) {
  final rows = _paddockPodiumRowsForRace(race);
  if (rows.isEmpty) return '—';
  final parts = <String>[];
  for (final r in rows) {
    final p = _extractFinishPosition(r.finish);
    if (p != null) parts.add('P$p ${r.driver}');
  }
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// Section label: matches AI Strategist / standings micro-headers.
TextStyle _paddockSectionLabelStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: scheme.onSurfaceVariant,
  );
}

List<BoxShadow> _paddockCardShadows(ColorScheme scheme) => [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];

/// Logged-in quick access hub (favorites + optional live-timing resume).
/// Uses the same [F1Module] stack as profile cards and the AI Strategist card.
class MyPaddockWidget extends StatelessWidget {
  const MyPaddockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final f = context.select<ProfileFavoritesNotifier, ProfileFavorites>(
      (n) => n.value,
    );
    final display = context.select<DisplaySettingsController, DisplaySettings>(
      (c) => c.settings,
    );
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final driverNums = _paddockResolvedDriverNumbers(f);
    final teamNames = f.favoriteTeamKeys.take(6).toList(growable: false);
    final lastRace = _paddockLatestCompletedRace();

    final resumeFrame = display.liveTimingLastFrame;
    final resumeSession = display.liveTimingSessionLabel ?? l10n.my_paddock_session_unknown;
    final showResume = resumeFrame != null && resumeFrame > 0;

    final shadow = _paddockCardShadows(scheme);

    Widget paddockModule({required Widget child}) => F1Module(
          fillWidth: true,
          padding: const EdgeInsets.all(20),
          borderRadius: kF1ModuleRadius,
          backgroundColor: scheme.surface,
          showFadingBorder: true,
          boxShadow: shadow,
          child: child,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        paddockModule(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: user.userMetadata?['avatar_url'] != null
                        ? NetworkImage('${user.userMetadata!['avatar_url']}')
                        : null,
                    child: user.userMetadata?['avatar_url'] == null
                        ? Icon(Icons.person, color: scheme.onPrimaryContainer)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.my_paddock_title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? user.phone ?? user.id,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showResume) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final q = Uri.encodeComponent(resumeSession);
                    context.push('${_livePath()}?frame=$resumeFrame&session=$q');
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                  label: Text(
                    l10n.my_paddock_resume_subtitle(
                      resumeSession,
                      '$resumeFrame',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (driverNums.isNotEmpty) ...[
          const SizedBox(height: 16),
          paddockModule(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.my_paddock_favorite_drivers.toUpperCase(),
                  style: _paddockSectionLabelStyle(context),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    if (wide) {
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final n in driverNums)
                            _PaddockDriverMiniCard(driverNumber: n),
                        ],
                      );
                    }
                    return SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: driverNums.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) =>
                            _PaddockDriverMiniCard(driverNumber: driverNums[i]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        if (teamNames.isNotEmpty) ...[
          const SizedBox(height: 16),
          paddockModule(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.my_paddock_favorite_teams.toUpperCase(),
                  style: _paddockSectionLabelStyle(context),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final children = <Widget>[
                      for (final name in teamNames)
                        _PaddockTeamMiniCard(teamName: name),
                    ];
                    if (wide) {
                      return GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.35,
                        children: children,
                      );
                    }
                    return SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: children.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) => children[i],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        if (lastRace != null) ...[
          const SizedBox(height: 16),
          paddockModule(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.my_paddock_last_race.toUpperCase(),
                  style: _paddockSectionLabelStyle(context),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.my_paddock_last_race_summary(
                    MaterialLocalizations.of(context).formatFullDate(lastRace.date),
                    _paddockPodiumSummaryLine(lastRace),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaddockDriverMiniCard extends StatelessWidget {
  const _PaddockDriverMiniCard({required this.driverNumber});

  final int driverNumber;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = _themeTokens(context);
    Driver? d;
    for (final x in drivers2026) {
      if (x.number == driverNumber) {
        d = x;
        break;
      }
    }
    if (d == null) {
      return const SizedBox.shrink();
    }
    final pos = _paddockDriverStandingPosition(d.name);
    final stripe = F1TeamSchemes.getTeamColor(d.team);
    final tla = _driverTlaFromName(d.name);

    return Container(
      width: 118,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tokens.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: stripe,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tla,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.4,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${d.number}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  pos != null ? 'P$pos' : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int? _paddockDriverStandingPosition(String driverName) {
  try {
    final list = List<Driver>.from(driversData[DateTime.now().year] ?? drivers2026);
    list.sort((a, b) => b.points.compareTo(a.points));
    final idx = list.indexWhere(
      (e) => normalizeForComparison(e.name) == normalizeForComparison(driverName),
    );
    if (idx < 0) return null;
    return idx + 1;
  } catch (_) {
    return null;
  }
}

class _PaddockTeamMiniCard extends StatelessWidget {
  const _PaddockTeamMiniCard({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = _themeTokens(context);
    Team? team;
    for (final t in fallbackTeams) {
      if (normalizeForComparison(t.name) == normalizeForComparison(teamName)) {
        team = t;
        break;
      }
    }
    if (team == null) return const SizedBox.shrink();
    final pos = _paddockTeamStandingPosition(team.name);
    final pts = team.points;
    final stripe = F1TeamSchemes.getTeamColor(team.name);
    final tla = _teamTlaFromName(team.name);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tokens.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: stripe,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tla,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pos != null
                      ? 'C$pos · $pts ${context.l10n.my_paddock_points_suffix}'
                      : '$pts ${context.l10n.my_paddock_points_suffix}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int? _paddockTeamStandingPosition(String teamName) {
  try {
    final list = List<Team>.from(fallbackTeams);
    list.sort((a, b) => b.points.compareTo(a.points));
    final idx = list.indexWhere(
      (e) => normalizeForComparison(e.name) == normalizeForComparison(teamName),
    );
    if (idx < 0) return null;
    return idx + 1;
  } catch (_) {
    return null;
  }
}
