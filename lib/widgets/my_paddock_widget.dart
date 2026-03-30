part of '../main.dart';

// --- Paddock copy (NL / EN) driven by [PaddockUserPreferences.language] ------------

class _PaddockI18n {
  _PaddockI18n._();

  static String myPaddock(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'MIJN PADDOCK' : 'MY PADDOCK';

  static String nextRace(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'VOLGENDE RACE' : 'NEXT RACE';

  static String lastPodium(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'LAATSTE PODIUM' : 'LAST PODIUM';

  static String favoriteDriver(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'FAVORIETE COUREUR' : 'FAVORITE DRIVER';

  static String favoriteTeam(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'FAVORIETE TEAM' : 'FAVORITE TEAM';

  static String sessionTimes(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'SESSIE TIJDEN' : 'SESSION TIMES';

  static String previousWinners(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'Eerdere winnaars' : 'Previous winners';

  static String rain(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'regen' : 'rain';

  static String aiStrategist(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'AI STRATEGIST' : 'AI STRATEGIST';

  static String coachCorner(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'Coach\'s Corner' : 'Coach\'s Corner';

  static String ended(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'Beëindigd' : 'Ended';

  static String results(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'Uitslagen' : 'Results';

  static String friday(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'VRIJDAG' : 'FRIDAY';

  static String saturday(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'ZATERDAG' : 'SATURDAY';

  static String sunday(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'ZONDAG' : 'SUNDAY';

  static String race(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? 'RACE' : 'RACE';

  static String noData(PaddockLanguage l) =>
      l == PaddockLanguage.nl ? '—' : '—';
}

/// Matches hub / circuit pages: Titillium via [ThemeData.textTheme], not monospace.
TextStyle _paddockText(
  BuildContext context,
  PaddockUserPreferences prefs, {
  double fontSize = 12,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
  double letterSpacing = 0.2,
  double height = 1.25,
  List<Shadow>? shadows,
}) {
  final scheme = Theme.of(context).colorScheme;
  final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  return base.copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color ?? scheme.onSurface,
    shadows: shadows,
  );
}

List<Race> _paddockChartRaces() {
  if (races.isEmpty) return const [];
  final n = math.min(28, races.length);
  return races.take(n).toList(growable: false);
}

String _paddockCircuitAxisShortLabel(Race r) {
  final n = r.circuitDisplayName.trim();
  if (n.isEmpty) return '—';
  if (n.length <= 5) return n.toUpperCase();
  final parts = n.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.length >= 2) {
    final buf = StringBuffer();
    for (final p in parts.take(4)) {
      if (p.isNotEmpty) buf.write(p[0]);
    }
    final s = buf.toString();
    if (s.isNotEmpty) return s.toUpperCase();
  }
  return n.substring(0, math.min(4, n.length)).toUpperCase();
}

String _paddockSparkTooltipLine(PaddockLanguage lang, double v) {
  final s = v.round().toString();
  return lang == PaddockLanguage.nl
      ? 'Seizoensindicator: $s'
      : 'Season indicator: $s';
}

String _driverTlaFromNamePaddock(String name) {
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

String _teamTlaFromNamePaddock(String name) {
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

Color? _paddockStripeForDriverName(String driverName) {
  for (final d in drivers2026) {
    if (normalizeForComparison(d.name) == normalizeForComparison(driverName)) {
      return F1TeamSchemes.getTeamColor(d.team);
    }
  }
  return const Color(0xFF6B7280);
}

String _paddockFormatSessionTime(BuildContext context, DateTime dt) {
  final t = TimeOfDay.fromDateTime(dt);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    t,
    alwaysUse24HourFormat: true,
  );
}

String _paddockCountdownLabel(DateTime target) {
  final now = DateTime.now();
  final diff = target.difference(now);
  if (diff.inSeconds <= 0) return '00W : 00D : 00H : 00M';
  final totalSec = diff.inSeconds;
  final weeks = totalSec ~/ (7 * 24 * 3600);
  var rem = totalSec % (7 * 24 * 3600);
  final days = rem ~/ (24 * 3600);
  rem %= 24 * 3600;
  final hours = rem ~/ 3600;
  rem %= 3600;
  final minutes = rem ~/ 60;
  String z2(int v) => v.clamp(0, 99).toString().padLeft(2, '0');
  return '${z2(weeks)}W : ${z2(days)}D : ${z2(hours)}H : ${z2(minutes)}M';
}

String _paddockRaceDateChip(Race race) {
  final d = race.date;
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd-$mm ${d.year}';
}

/// Same shell as [F1Module] / circuits hub (surface + fading primary border).
class BaseGlassPanel extends StatelessWidget {
  const BaseGlassPanel({
    super.key,
    required this.prefs,
    required this.child,
    this.height,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final PaddockUserPreferences prefs;
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final h = height ?? prefs.panelHeight;
    return SizedBox(
      height: h,
      width: width,
      child: F1Module(
        fillWidth: true,
        padding: padding,
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _PaddockSparklinePainter extends CustomPainter {
  _PaddockSparklinePainter({
    required this.points,
    required this.glow,
    this.gridColor,
  });

  final List<double> points;
  final bool glow;
  final Color? gridColor;

  static const _red = Color(0xFFFF1801);
  static const _blue = Color(0xFF3B82F6);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final gridPaint = Paint()
      ..color = gridColor ?? Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const gx = 5;
    for (var i = 0; i <= gx; i++) {
      final x = size.width * i / gx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    const gy = 4;
    for (var j = 0; j <= gy; j++) {
      final y = size.height * j / gy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minV = points.reduce(math.min);
    final maxV = points.reduce(math.max);
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final t = i / (points.length - 1);
      final x = t * size.width;
      final n = (points[i] - minV) / span;
      final y = size.height * (0.85 - n * 0.7);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (glow) {
      final glowPaint = Paint()
        ..color = _red.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);
    }

    final shader = ui.Gradient.linear(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      [_blue, _red],
    );
    final linePaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final lastT = 1.0;
    final lastX = lastT * size.width;
    final lastN = (points.last - minV) / span;
    final lastY = size.height * (0.85 - lastN * 0.7);
    canvas.drawCircle(
      Offset(lastX, lastY),
      glow ? 4.5 : 3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    if (glow) {
      canvas.drawCircle(
        Offset(lastX, lastY),
        8,
        Paint()
          ..color = _red.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaddockSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.glow != glow ||
        oldDelegate.gridColor != gridColor;
  }
}

class _PaddockTeamSparkChart extends StatelessWidget {
  const _PaddockTeamSparkChart({
    required this.points,
    required this.chartRaces,
    required this.prefs,
    required this.lang,
    required this.glow,
  });

  final List<double> points;
  final List<Race> chartRaces;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gridColor = scheme.outline.withValues(alpha: 0.2);
    if (points.length < 2 || chartRaces.length != points.length) {
      return const SizedBox.expand();
    }
    final n = points.length;
    final fs = prefs.compactMode ? 7.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _PaddockSparklinePainter(
                  points: points,
                  glow: glow,
                  gridColor: gridColor,
                ),
              ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          message:
                              '${chartRaces[i].circuitDisplayName}\n${_paddockSparkTooltipLine(lang, points[i])}',
                          showDuration: const Duration(seconds: 4),
                          waitDuration: const Duration(milliseconds: 120),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              splashColor:
                                  scheme.primary.withValues(alpha: 0.14),
                              highlightColor: Colors.transparent,
                              onTap: () {},
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: prefs.compactMode ? 16 : 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Text(
                    _paddockCircuitAxisShortLabel(chartRaces[i]),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: _paddockText(
                      context,
                      prefs,
                      fontSize: fs,
                      letterSpacing: 0,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                      height: 1.05,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaddockCountdownClock extends StatefulWidget {
  const _PaddockCountdownClock({
    required this.target,
    required this.prefs,
  });

  final DateTime target;
  final PaddockUserPreferences prefs;

  @override
  State<_PaddockCountdownClock> createState() => _PaddockCountdownClockState();
}

class _PaddockCountdownClockState extends State<_PaddockCountdownClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _paddockCountdownLabel(widget.target);
    final scheme = Theme.of(context).colorScheme;
    final shadows = widget.prefs.interfaceStyle == PaddockInterfaceStyle.standard
        ? <Shadow>[
            Shadow(
              color: scheme.primary.withValues(alpha: 0.75),
              blurRadius: 14,
            ),
            Shadow(
              color: scheme.onSurface.withValues(alpha: 0.35),
              blurRadius: 4,
            ),
          ]
        : null;
    return Text(
      label,
      style: _paddockText(
        context,
        widget.prefs,
        fontSize: widget.prefs.compactMode ? 10 : 12,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.95),
        letterSpacing: 0.4,
        shadows: shadows,
      ),
    );
  }
}

/// Logged-in paddock command center (replaces prior hub layout entirely).
class MyPaddockWidget extends StatelessWidget {
  const MyPaddockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final prefs = context.watch<PaddockUserPreferencesNotifier>().value;
    final favorites = context.watch<ProfileFavoritesNotifier>().value;
    final lang = prefs.language;
    final gap = prefs.verticalGap;
    final ph = prefs.panelHeight;
    final topStackH = 3 * ph + 2 * gap;
    final bottomH = 2 * ph + gap;

    final scheme = Theme.of(context).colorScheme;
    final nextRace = nextRaceAfterNowSkippingCancelled(races);
    final lastRace = _paddockLatestCompletedRace();
    final driverNums = _paddockResolvedDriverNumbers(favorites);
    final teamNames = favorites.favoriteTeamKeys.take(6).toList(growable: false);
    final firstTeam = teamNames.isNotEmpty ? teamNames.first : null;

    var chartRaces = _paddockChartRaces();
    if (chartRaces.length < 2) {
      chartRaces = chartRaces.isEmpty
          ? <Race>[nextRace, nextRace]
          : <Race>[chartRaces.first, chartRaces.first];
    }
    final sparkPoints = List<double>.generate(
      chartRaces.length,
      (i) => 42 + math.sin(i * 0.45) * 8 + i * 0.35,
    );

    Widget vGap() => SizedBox(height: gap);

    final nextRaceHero = BaseGlassPanel(
      prefs: prefs,
      height: topStackH,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: _PaddockNextRaceHeroBody(
        race: nextRace,
        prefs: prefs,
        lang: lang,
      ),
    );

    final identity = BaseGlassPanel(
      prefs: prefs,
      height: ph,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.apple,
            size: prefs.compactMode ? 26 : 30,
            color: scheme.onSurface.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _PaddockI18n.myPaddock(lang),
                  style: _paddockText(
                    context,
                    prefs,
                    fontSize: prefs.compactMode ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  user.email ?? user.phone ?? user.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _paddockText(
                    context,
                    prefs,
                    fontSize: prefs.compactMode ? 9 : 10,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final favDriver = BaseGlassPanel(
      prefs: prefs,
      height: ph,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: driverNums.isEmpty
          ? _PaddockEmptyFavRow(
              prefs: prefs,
              label: _PaddockI18n.favoriteDriver(lang),
            )
          : _PaddockFavoriteDriverRow(
              driverNumber: driverNums.first,
              prefs: prefs,
              lang: lang,
            ),
    );

    final favTeam = BaseGlassPanel(
      prefs: prefs,
      height: ph,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: firstTeam == null
          ? _PaddockEmptyFavRow(
              prefs: prefs,
              label: _PaddockI18n.favoriteTeam(lang),
            )
          : _PaddockFavoriteTeamRow(
              teamName: firstTeam,
              prefs: prefs,
              lang: lang,
            ),
    );

    final teamSpark = BaseGlassPanel(
      prefs: prefs,
      height: bottomH,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _PaddockI18n.favoriteTeam(lang),
            style: _paddockText(
              context,
              prefs,
              fontSize: 9,
              letterSpacing: 1.4,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: prefs.compactMode ? 6 : 10),
          if (firstTeam != null)
            Row(
              children: [
                Text(
                  _teamTlaFromNamePaddock(firstTeam),
                  style: _paddockText(
                    context,
                    prefs,
                    fontSize: prefs.compactMode ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _paddockTeamSubtitle(context, firstTeam),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _paddockText(
                      context,
                      prefs,
                      fontSize: 10,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              _PaddockI18n.noData(lang),
              style: _paddockText(
                context,
                prefs,
                color: scheme.onSurfaceVariant,
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _PaddockTeamSparkChart(
                points: sparkPoints,
                chartRaces: chartRaces,
                prefs: prefs,
                lang: lang,
                glow: prefs.interfaceStyle == PaddockInterfaceStyle.standard,
              ),
            ),
          ),
        ],
      ),
    );

    final aiCard = BaseGlassPanel(
      prefs: prefs,
      height: bottomH,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: _PaddockAiStrategistBody(
        race: nextRace,
        prefs: prefs,
        lang: lang,
      ),
    );

    final podium = BaseGlassPanel(
      prefs: prefs,
      height: topStackH,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: _PaddockLastPodiumBody(
        race: lastRace,
        prefs: prefs,
        lang: lang,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1020;
        final hPad = 16.0;
        final content = wide
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: topStackH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 232,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              identity,
                              vGap(),
                              favDriver,
                              vGap(),
                              favTeam,
                            ],
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(child: nextRaceHero),
                        SizedBox(width: gap),
                        SizedBox(width: 260, child: podium),
                      ],
                    ),
                  ),
                  vGap(),
                  SizedBox(
                    height: bottomH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 11, child: teamSpark),
                        SizedBox(width: gap),
                        Expanded(flex: 13, child: aiCard),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  vGap(),
                  nextRaceHero,
                  vGap(),
                  podium,
                  vGap(),
                  favDriver,
                  vGap(),
                  favTeam,
                  vGap(),
                  teamSpark,
                  vGap(),
                  aiCard,
                ],
              );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: content,
        );
      },
    );
  }
}

String _paddockTeamSubtitle(BuildContext context, String teamName) {
  Team? team;
  for (final t in fallbackTeams) {
    if (normalizeForComparison(t.name) == normalizeForComparison(teamName)) {
      team = t;
      break;
    }
  }
  if (team == null) return '—';
  final pos = _paddockTeamStandingPosition(team.name);
  final pts = team.points;
  final suffix = context.l10n.my_paddock_points_suffix;
  return pos != null ? 'C$pos — $pts $suffix' : '$pts $suffix';
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

class _PaddockEmptyFavRow extends StatelessWidget {
  const _PaddockEmptyFavRow({
    required this.prefs,
    required this.label,
  });

  final PaddockUserPreferences prefs;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: _paddockText(
            context,
            prefs,
            fontSize: 9,
            letterSpacing: 1.3,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: prefs.compactMode ? 4 : 6),
        Text(
          _PaddockI18n.noData(prefs.language),
          style: _paddockText(
            context,
            prefs,
            fontSize: prefs.compactMode ? 13 : 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PaddockFavoriteDriverRow extends StatelessWidget {
  const _PaddockFavoriteDriverRow({
    required this.driverNumber,
    required this.prefs,
    required this.lang,
  });

  final int driverNumber;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;

  @override
  Widget build(BuildContext context) {
    Driver? d;
    for (final x in drivers2026) {
      if (x.number == driverNumber) {
        d = x;
        break;
      }
    }
    if (d == null) {
      return _PaddockEmptyFavRow(
        prefs: prefs,
        label: _PaddockI18n.favoriteDriver(lang),
      );
    }
    final pos = _paddockDriverStandingPosition(d.name);
    final stripe = F1TeamSchemes.getTeamColor(d.team);
    final tla = _driverTlaFromNamePaddock(d.name);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _PaddockI18n.favoriteDriver(lang),
          style: _paddockText(
            context,
            prefs,
            fontSize: 9,
            letterSpacing: 1.3,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: prefs.compactMode ? 4 : 6),
        Row(
          children: [
            Container(
              width: 3,
              height: prefs.compactMode ? 36 : 44,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              tla,
              style: _paddockText(
                context,
                prefs,
                fontSize: prefs.compactMode ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#${d.number}',
              style: _paddockText(
                context,
                prefs,
                fontSize: 11,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              pos != null ? 'P$pos' : '—',
              style: _paddockText(
                context,
                prefs,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaddockFavoriteTeamRow extends StatelessWidget {
  const _PaddockFavoriteTeamRow({
    required this.teamName,
    required this.prefs,
    required this.lang,
  });

  final String teamName;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;

  @override
  Widget build(BuildContext context) {
    Team? team;
    for (final t in fallbackTeams) {
      if (normalizeForComparison(t.name) == normalizeForComparison(teamName)) {
        team = t;
        break;
      }
    }
    if (team == null) {
      return _PaddockEmptyFavRow(
        prefs: prefs,
        label: _PaddockI18n.favoriteTeam(lang),
      );
    }
    final pos = _paddockTeamStandingPosition(team.name);
    final stripe = F1TeamSchemes.getTeamColor(team.name);
    final tla = _teamTlaFromNamePaddock(team.name);
    final pts = team.points;
    final suffix = context.l10n.my_paddock_points_suffix;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _PaddockI18n.favoriteTeam(lang),
          style: _paddockText(
            context,
            prefs,
            fontSize: 9,
            letterSpacing: 1.3,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: prefs.compactMode ? 4 : 6),
        Row(
          children: [
            Container(
              width: 3,
              height: prefs.compactMode ? 34 : 40,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              tla,
              style: _paddockText(
                context,
                prefs,
                fontSize: prefs.compactMode ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pos != null ? 'C$pos — $pts $suffix' : '$pts $suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _paddockText(
                  context,
                  prefs,
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaddockNextRaceHeroBody extends StatelessWidget {
  const _PaddockNextRaceHeroBody({
    required this.race,
    required this.prefs,
    required this.lang,
  });

  final Race race;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;

  @override
  Widget build(BuildContext context) {
    final w = race.weather;
    final weatherLine =
        '${w.temperature}°C · ${w.rainChance}% ${_PaddockI18n.rain(lang)} · ${w.windSpeed} km/h';
    final circuitSvg = race.circuitImage.trim();
    final hasCircuitSvg = circuitSvg.startsWith('http://') ||
        circuitSvg.startsWith('https://');
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          right: 8,
          child: _PaddockCountdownClock(target: race.date, prefs: prefs),
        ),
        Padding(
          padding: EdgeInsets.only(top: prefs.compactMode ? 22 : 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: prefs.compactMode ? 14 : 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            weatherLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _paddockText(
                              context,
                              prefs,
                              fontSize: prefs.compactMode ? 9 : 10,
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.calendar_month_outlined,
                          size: prefs.compactMode ? 14 : 16,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _paddockRaceDateChip(race),
                          style: _paddockText(
                            context,
                            prefs,
                            fontSize: prefs.compactMode ? 9 : 10,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: prefs.compactMode ? 8 : 12),
                    Text(
                      _PaddockI18n.nextRace(lang),
                      style: _paddockText(
                        context,
                        prefs,
                        fontSize: 9,
                        letterSpacing: 1.6,
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: prefs.compactMode ? 6 : 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(race.flag, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                race.circuitDisplayName,
                                style: _paddockText(
                                  context,
                                  prefs,
                                  fontSize: prefs.compactMode ? 13 : 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                l10nGrandPrix(l10n, race.name),
                                style: _paddockText(
                                  context,
                                  prefs,
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: prefs.compactMode ? 8 : 10),
                    Text(
                      _PaddockI18n.previousWinners(lang),
                      style: _paddockText(
                        context,
                        prefs,
                        fontSize: 9,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in race.previousWinners.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              name.split(' ').last.toUpperCase(),
                              style: _paddockText(
                                context,
                                prefs,
                                fontSize: 9,
                                color: scheme.onSurface.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final side = math.max(
                            132.0,
                            math.min(c.maxWidth - 4, c.maxHeight) * 0.96,
                          );
                          return Center(
                            child: SizedBox(
                              width: side,
                              height: side,
                              child: hasCircuitSvg
                                  ? Opacity(
                                      opacity: prefs.interfaceStyle ==
                                              PaddockInterfaceStyle.standard
                                          ? 0.55
                                          : 0.72,
                                      child: SvgPicture.network(
                                        circuitSvg,
                                        fit: BoxFit.contain,
                                        colorFilter: ColorFilter.mode(
                                          scheme.onSurface.withValues(
                                            alpha: 0.88,
                                          ),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.timeline,
                                      size: side * 0.42,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: prefs.compactMode ? 8 : 12),
              Expanded(
                flex: 28,
                child: _PaddockSessionTimesColumn(
                  race: race,
                  prefs: prefs,
                  lang: lang,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaddockSessionTimesColumn extends StatelessWidget {
  const _PaddockSessionTimesColumn({
    required this.race,
    required this.prefs,
    required this.lang,
  });

  final Race race;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;

  @override
  Widget build(BuildContext context) {
    final rows = <(String day, String lab, DateTime tm)>[];

    if (race.hasSprint) {
      rows.add((_PaddockI18n.friday(lang), 'FP1', race.fp1));
      rows.add((_PaddockI18n.friday(lang), 'SQ', race.sprintQuali));
      rows.add((_PaddockI18n.saturday(lang), 'Sprint', race.sprintRace));
      rows.add((_PaddockI18n.saturday(lang), 'FP2', race.fp2));
      rows.add((_PaddockI18n.sunday(lang), _PaddockI18n.race(lang), race.date));
    } else {
      rows.add((_PaddockI18n.friday(lang), 'FP1', race.fp1));
      rows.add((_PaddockI18n.friday(lang), 'FP2', race.fp2));
      rows.add((_PaddockI18n.saturday(lang), 'FP3', race.fp3));
      rows.add((_PaddockI18n.saturday(lang), 'Q', race.qualifying));
      rows.add((_PaddockI18n.sunday(lang), _PaddockI18n.race(lang), race.date));
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _PaddockI18n.sessionTimes(lang),
          style: _paddockText(
            context,
            prefs,
            fontSize: 8,
            letterSpacing: 1.4,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: prefs.compactMode ? 6 : 10),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0 &&
                    rows[i].$1 != rows[i - 1].$1 &&
                    i < rows.length)
                  SizedBox(height: prefs.compactMode ? 6 : 8),
                _PaddockSessionRow(
                  dayUpper: rows[i].$1,
                  label: rows[i].$2,
                  time: _paddockFormatSessionTime(context, rows[i].$3),
                  prefs: prefs,
                  showDay: i == 0 || rows[i].$1 != rows[i - 1].$1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaddockSessionRow extends StatelessWidget {
  const _PaddockSessionRow({
    required this.dayUpper,
    required this.label,
    required this.time,
    required this.prefs,
    required this.showDay,
  });

  final String dayUpper;
  final String label;
  final String time;
  final PaddockUserPreferences prefs;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: prefs.compactMode ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: showDay
                ? Text(
                    dayUpper,
                    style: _paddockText(
                      context,
                      prefs,
                      fontSize: 8,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.62),
                      letterSpacing: 0.8,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Text(
              label,
              style: _paddockText(
                context,
                prefs,
                fontSize: 9,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
              ),
            ),
          ),
          Text(
            time,
            style: _paddockText(
              context,
              prefs,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaddockLastPodiumBody extends StatelessWidget {
  const _PaddockLastPodiumBody({
    required this.race,
    required this.prefs,
    required this.lang,
  });

  final Race? race;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final rows =
        race != null ? _paddockPodiumRowsForRace(race!) : const <RaceResultRow>[];
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _PaddockI18n.lastPodium(lang),
          style: _paddockText(
            context,
            prefs,
            fontSize: 9,
            letterSpacing: 1.5,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: prefs.compactMode ? 10 : 14),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < 2 ? 8 : 0),
                    child: _PaddockPodiumSlot(
                      medal: i < _medals.length ? _medals[i] : '•',
                      row: i < rows.length ? rows[i] : null,
                      prefs: prefs,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: race == null
                    ? null
                    : () => context.push(_weekendHubPath(race!)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
                  padding: EdgeInsets.symmetric(
                    vertical: prefs.compactMode ? 6 : 8,
                  ),
                ),
                child: Text(
                  _PaddockI18n.ended(lang),
                  style: _paddockText(context, prefs, fontSize: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: race == null
                    ? null
                    : () => context.push(_weekendHubPath(race!)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
                  padding: EdgeInsets.symmetric(
                    vertical: prefs.compactMode ? 6 : 8,
                  ),
                ),
                child: Text(
                  _PaddockI18n.results(lang),
                  style: _paddockText(context, prefs, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaddockPodiumSlot extends StatelessWidget {
  const _PaddockPodiumSlot({
    required this.medal,
    required this.row,
    required this.prefs,
  });

  final String medal;
  final RaceResultRow? row;
  final PaddockUserPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = row?.driver ?? '—';
    final tla = row != null ? _driverTlaFromNamePaddock(name) : '—';
    final stripe =
        row != null ? _paddockStripeForDriverName(name) : scheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              medal,
              style: TextStyle(fontSize: prefs.compactMode ? 16 : 18),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                tla,
                style: _paddockText(
                  context,
                  prefs,
                  fontSize: prefs.compactMode ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            width: 4,
            height: double.infinity,
            color: stripe,
          ),
        ],
      ),
    );
  }
}

class _PaddockAiStrategistBody extends StatelessWidget {
  const _PaddockAiStrategistBody({
    required this.race,
    required this.prefs,
    required this.lang,
  });

  final Race race;
  final PaddockUserPreferences prefs;
  final PaddockLanguage lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = lang == PaddockLanguage.nl ? 'nl' : 'en';
    final lines = coachCornerFiveLines(race.name, code);
    final icons = <IconData>[
      Icons.flag_outlined,
      Icons.rocket_launch_outlined,
      Icons.cloud_outlined,
      Icons.sports_motorsports_outlined,
      Icons.calendar_month_outlined,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: prefs.compactMode ? 16 : 18,
              color: scheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _PaddockI18n.aiStrategist(lang),
                style: _paddockText(
                  context,
                  prefs,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => context.push(_weekendHubPath(race)),
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        SizedBox(height: prefs.compactMode ? 4 : 6),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: prefs.compactMode ? 5 : 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: prefs.compactMode ? 13 : 14,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _PaddockI18n.coachCorner(lang),
                        style: _paddockText(
                          context,
                          prefs,
                          fontSize: prefs.compactMode ? 8.5 : 9.5,
                          height: 1.35,
                          color: scheme.onSurface.withValues(alpha: 0.88),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < lines.length && i < icons.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: prefs.compactMode ? 5 : 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icons[i],
                        size: prefs.compactMode ? 13 : 14,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lines[i],
                          style: _paddockText(
                            context,
                            prefs,
                            fontSize: prefs.compactMode ? 8.5 : 9.5,
                            height: 1.35,
                            color: scheme.onSurface.withValues(alpha: 0.88),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
