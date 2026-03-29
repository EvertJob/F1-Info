part of '../main.dart';

/// One championship round: race + optional sprint deltas from bundled standings JSON.
class _DriverRoundFormRow {
  const _DriverRoundFormRow({
    required this.round,
    required this.circuitCode,
    required this.racePointsDelta,
    this.racePosition,
    this.sprintPointsDelta,
    this.sprintPosition,
  });

  final int round;
  final String circuitCode;
  final double racePointsDelta;
  final int? racePosition;
  final double? sprintPointsDelta;
  final int? sprintPosition;

  double get weekendPoints => racePointsDelta + (sprintPointsDelta ?? 0);
}

String _formCircuitCodeForRound(int year, int round) {
  if (year == 2026 && round >= 1 && round <= races.length) {
    return _circuitIsoCodeForRace(races[round - 1]);
  }
  return _abbreviateRaceLabel(_raceNameForRound(year, round));
}

bool _formRoundAllowsSprint(int year, int round) {
  if (year == 2026 && round >= 1 && round <= races.length) {
    return races[round - 1].hasSprint;
  }
  return true;
}

String _circuitIsoCodeForRace(Race race) {
  final country = race.country.toLowerCase();
  final name = race.name.toLowerCase();
  if (name.contains('miami')) return 'MIA';
  if (name.contains('las vegas')) return 'LAS';
  if (name.contains('austin') || name.contains('americas')) return 'USA';
  if (country == 'spain') {
    if (name.contains('madrid')) return 'MAD';
    return 'ESP';
  }
  const map = <String, String>{
    'australia': 'AUS',
    'china': 'CHN',
    'japan': 'JPN',
    'bahrain': 'BAH',
    'saudi arabia': 'KSA',
    'usa': 'USA',
    'canada': 'CAN',
    'monaco': 'MON',
    'austria': 'AUT',
    'uk': 'GBR',
    'belgium': 'BEL',
    'hungary': 'HUN',
    'netherlands': 'NED',
    'italy': 'ITA',
    'azerbaijan': 'AZE',
    'singapore': 'SGP',
    'mexico': 'MEX',
    'brazil': 'BRA',
    'qatar': 'QAT',
    'uae': 'UAE',
    'united arab emirates': 'UAE',
  };
  return map[country] ?? _abbreviateRaceLabel(race.name);
}

Future<List<_DriverRoundFormRow>?> _loadDriverRoundFormRowsFromStandings(
  int year,
  String driverName,
) async {
  for (final path in F1AssetResolver.driversStandingsCandidatePaths(year)) {
    try {
      final raw = await rootBundle.loadString(path);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final rounds = map['rounds'] as List?;
      if (rounds == null || rounds.isEmpty) continue;

      final rows = <_DriverRoundFormRow>[];
      for (final e in rounds) {
        if (e is! Map) continue;
        final r = int.tryParse(e['round']?.toString() ?? '');
        if (r == null) continue;
        final drivers = e['drivers'];
        if (drivers is! Map) continue;

        String? matchedKey;
        for (final k in drivers.keys) {
          if (_driverNameMatches(k.toString(), driverName)) {
            matchedKey = k.toString();
            break;
          }
        }
        if (matchedKey == null) continue;

        final dm = drivers[matchedKey];
        if (dm is! Map) continue;

        final raceMap = dm['Race'];
        double? rp;
        int? rpos;
        if (raceMap is Map) {
          rp = (raceMap['points_received'] as num?)?.toDouble();
          rpos = (raceMap['position_finish'] as num?)?.toInt();
        }

        double? sp;
        int? spos;
        final sprintMap = dm['Sprint'];
        if (sprintMap is Map && _formRoundAllowsSprint(year, r)) {
          sp = (sprintMap['points_received'] as num?)?.toDouble();
          spos = (sprintMap['position_finish'] as num?)?.toInt();
        }

        if (rp == null && sp == null) continue;

        rows.add(
          _DriverRoundFormRow(
            round: r,
            circuitCode: _formCircuitCodeForRound(year, r),
            racePointsDelta: rp ?? 0,
            racePosition: rpos,
            sprintPointsDelta: sp,
            sprintPosition: spos,
          ),
        );
      }
      if (rows.isEmpty) continue;
      rows.sort((a, b) => a.round.compareTo(b.round));
      return rows;
    } catch (_) {}
  }
  return null;
}

Future<List<_DriverRoundFormRow>?> _loadDriverRoundFormRowsFallback(
  int year,
  String driverName,
) async {
  if (year < 2017 || year > 2025) return null;
  try {
    final cache = await _readSeasonalDriverComparisonAssetCache();
    final byYear = cache[year];
    if (byYear == null) return null;
    SeasonalDriverComparisonStats? stats;
    for (final e in byYear.entries) {
      if (_driverNameMatches(e.key, driverName)) {
        stats = e.value;
        break;
      }
    }
    if (stats == null) return null;

    var prev = 0.0;
    final rows = <_DriverRoundFormRow>[];
    for (final e in stats.pointsByRace) {
      final delta = e.points - prev;
      prev = e.points;
      rows.add(
        _DriverRoundFormRow(
          round: e.round,
          circuitCode: _abbreviateRaceLabel(e.raceName),
          racePointsDelta: delta,
          racePosition: null,
          sprintPointsDelta: null,
          sprintPosition: null,
        ),
      );
    }
    return rows;
  } catch (_) {
    return null;
  }
}

Future<List<_DriverRoundFormRow>?> _loadDriverRoundFormRows(
  int year,
  String driverName,
) async {
  final fromStandings = await _loadDriverRoundFormRowsFromStandings(
    year,
    driverName,
  );
  if (fromStandings != null && fromStandings.isNotEmpty) {
    return fromStandings;
  }
  return _loadDriverRoundFormRowsFallback(year, driverName);
}

/// Glassmorphism recent form: compact card + full-season expansion.
class RecentFormTrendCard extends StatefulWidget {
  const RecentFormTrendCard({
    super.key,
    required this.driverName,
    required this.seasonYear,
    this.showHeaderTitle = true,
  });

  final String driverName;
  final int seasonYear;

  /// When false (e.g. inside an [ExpansionTile] that already shows the title),
  /// only the expand control and chart are shown in the top row.
  final bool showHeaderTitle;

  @override
  State<RecentFormTrendCard> createState() => _RecentFormTrendCardState();
}

class _RecentFormTrendCardState extends State<RecentFormTrendCard> {
  Future<List<_DriverRoundFormRow>?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDriverRoundFormRows(widget.seasonYear, widget.driverName);
  }

  @override
  void didUpdateWidget(covariant RecentFormTrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverName != widget.driverName ||
        oldWidget.seasonYear != widget.seasonYear) {
      _future = _loadDriverRoundFormRows(widget.seasonYear, widget.driverName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return FutureBuilder<List<_DriverRoundFormRow>?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: scheme.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final all = snap.data;
        if (all == null || all.isEmpty) {
          return Text(
            l10n.recent_form_no_data,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          );
        }

        final last5 = all.length <= 5 ? all : all.sublist(all.length - 5);
        final last5Points =
            last5.fold<double>(0, (s, r) => s + r.weekendPoints);
        final finishes = last5
            .expand(
              (r) => [
                if (r.racePosition != null) r.racePosition!,
                if (r.sprintPosition != null) r.sprintPosition!,
              ],
            )
            .toList();
        final avgFinish = finishes.isEmpty
            ? '-'
            : (finishes.reduce((a, b) => a + b) / finishes.length)
                .toStringAsFixed(1);

        final heroTag =
            'recent_form_${widget.driverName}_${widget.seasonYear}';

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.38),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (widget.showHeaderTitle)
                          Expanded(
                            child: Text(
                              l10n.recent_form_trend_title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                            ),
                          )
                        else
                          const Spacer(),
                        IconButton(
                          tooltip: l10n.recent_form_expand_tooltip,
                          onPressed: () => _openExpanded(context, all, heroTag),
                          icon: Icon(
                            Icons.open_in_full_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Hero(
                      tag: heroTag,
                      flightShuttleBuilder:
                          (
                            context,
                            animation,
                            direction,
                            from,
                            to,
                          ) =>
                              to.widget,
                      child: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          height: 132,
                          child: CustomPaint(
                            painter: _CompactFormAreaPainter(
                              weekendDeltas:
                                  last5.map((r) => r.weekendPoints).toList(),
                              circuitCodes:
                                  last5.map((r) => r.circuitCode).toList(),
                              primary: scheme.primary,
                              fillTopAlpha: 0.22,
                              axisIconColor: scheme.onSurfaceVariant,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _RecentFormMetricChip(
                          label: l10n.recent_form_last_5_points,
                          value: last5Points == last5Points.roundToDouble()
                              ? last5Points.toInt().toString()
                              : last5Points.toStringAsFixed(1),
                        ),
                        _RecentFormMetricChip(
                          label: l10n.recent_form_avg_finish,
                          value: avgFinish,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openExpanded(
    BuildContext context,
    List<_DriverRoundFormRow> rows,
    String heroTag,
  ) {
    final theme = Theme.of(context);
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: theme.colorScheme.scrim.withValues(alpha: 0.45),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _RecentFormExpandedScaffold(
            driverName: widget.driverName,
            seasonYear: widget.seasonYear,
            rows: rows,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _RecentFormMetricChip extends StatelessWidget {
  const _RecentFormMetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactFormAreaPainter extends CustomPainter {
  _CompactFormAreaPainter({
    required this.weekendDeltas,
    required this.circuitCodes,
    required this.primary,
    required this.fillTopAlpha,
    required this.axisIconColor,
  });

  final List<double> weekendDeltas;
  final List<String> circuitCodes;
  final Color primary;
  final double fillTopAlpha;
  final Color axisIconColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (weekendDeltas.isEmpty) return;

    final n = weekendDeltas.length;
    final maxY = math.max(1, weekendDeltas.reduce(math.max) * 1.15);
    const padL = 8.0;
    const padR = 8.0;
    const padTop = 10.0;
    const padBottom = 36.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padTop - padBottom;

    double xFor(int i) => padL + chartW * (n <= 1 ? 0.5 : i / (n - 1));
    double yFor(double v) => padTop + chartH * (1 - v / maxY);

    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(xFor(i), yFor(weekendDeltas[i])),
    ];

    final fillPath = Path()..moveTo(pts.first.dx, size.height - padBottom);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height - padBottom)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, padTop),
        Offset(0, size.height - padBottom),
        [
          primary.withValues(alpha: fillTopAlpha),
          primary.withValues(alpha: 0.02),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final icon = Icons.timer_outlined;
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 14,
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(ui.TextStyle(color: axisIconColor))
      ..addText(String.fromCharCode(icon.codePoint));
    final para = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 24));

    final codeStyle = TextStyle(
      color: axisIconColor,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    for (var i = 0; i < n; i++) {
      final cx = xFor(i);
      canvas.save();
      canvas.translate(cx - 12, padTop - 2);
      canvas.drawParagraph(para, Offset.zero);
      canvas.restore();

      final tp = TextPainter(
        text: TextSpan(
          text: i < circuitCodes.length ? circuitCodes[i] : '',
          style: codeStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, size.height - padBottom + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompactFormAreaPainter oldDelegate) {
    return oldDelegate.weekendDeltas != weekendDeltas ||
        oldDelegate.primary != primary ||
        oldDelegate.circuitCodes != circuitCodes;
  }
}

class _RecentFormExpandedScaffold extends StatelessWidget {
  const _RecentFormExpandedScaffold({
    required this.driverName,
    required this.seasonYear,
    required this.rows,
    required this.heroTag,
  });

  final String driverName;
  final int seasonYear;
  final List<_DriverRoundFormRow> rows;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    var raceCum = 0.0;
    var sprintCum = 0.0;
    final raceSeries = <double>[];
    final sprintSeries = <double?>[];
    var podiums = 0;
    final raceFinishes = <int>[];

    for (final r in rows) {
      raceCum += r.racePointsDelta;
      raceSeries.add(raceCum);
      if (r.sprintPointsDelta != null) {
        sprintCum += r.sprintPointsDelta!;
        sprintSeries.add(sprintCum);
      } else {
        sprintSeries.add(null);
      }
      if (r.racePosition != null && r.racePosition! <= 3) podiums++;
      if (r.sprintPosition != null && r.sprintPosition! <= 3) podiums++;
      if (r.racePosition != null) raceFinishes.add(r.racePosition!);
    }

    final totalSeasonPoints =
        rows.fold<double>(0, (s, r) => s + r.weekendPoints);
    final avgRaceFinish = raceFinishes.isEmpty
        ? '-'
        : (raceFinishes.reduce((a, b) => a + b) / raceFinishes.length)
            .toStringAsFixed(2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Container(
                color: scheme.surface.withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: scheme.onSurface),
                        tooltip: l10n.recent_form_close,
                      ),
                      Expanded(
                        child: Text(
                          l10n.recent_form_trend_title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Text(
                    driverName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.outline.withValues(alpha: 0.38),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                            child: Hero(
                              tag: heroTag,
                              child: Material(
                                color: Colors.transparent,
                                child: CustomPaint(
                                  painter: _ExpandedDualTrendPainter(
                                    rows: rows,
                                    raceCumulative: raceSeries,
                                    sprintCumulative: sprintSeries,
                                    primary: scheme.primary,
                                    sprintColor: scheme.tertiary,
                                    labelColor: scheme.onSurfaceVariant,
                                    peakLabelColor: scheme.onSurface,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _RecentFormMetricChip(
                        label: l10n.recent_form_total_season_points,
                        value: totalSeasonPoints ==
                                totalSeasonPoints.roundToDouble()
                            ? totalSeasonPoints.toInt().toString()
                            : totalSeasonPoints.toStringAsFixed(1),
                      ),
                      _RecentFormMetricChip(
                        label: l10n.recent_form_avg_race_finish,
                        value: avgRaceFinish,
                      ),
                      _RecentFormMetricChip(
                        label: l10n.recent_form_total_podiums,
                        value: '$podiums',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedDualTrendPainter extends CustomPainter {
  _ExpandedDualTrendPainter({
    required this.rows,
    required this.raceCumulative,
    required this.sprintCumulative,
    required this.primary,
    required this.sprintColor,
    required this.labelColor,
    required this.peakLabelColor,
  });

  final List<_DriverRoundFormRow> rows;
  final List<double> raceCumulative;
  final List<double?> sprintCumulative;
  final Color primary;
  final Color sprintColor;
  final Color labelColor;
  final Color peakLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;
    final n = rows.length;
    final maxRace = raceCumulative.isEmpty
        ? 1.0
        : raceCumulative.reduce(math.max) * 1.08;
    final sprintVals =
        sprintCumulative.whereType<double>().toList();
    final maxSprint = sprintVals.isEmpty
        ? 0.0
        : sprintVals.reduce(math.max) * 1.08;
    final maxY = math.max(math.max(maxRace, maxSprint), 1.0);

    const padL = 36.0;
    const padR = 12.0;
    const padTop = 28.0;
    const padBottom = 52.0;
    final cw = size.width - padL - padR;
    final ch = size.height - padTop - padBottom;

    double xFor(int i) => padL + cw * (n <= 1 ? 0.5 : i / (n - 1));
    double yFor(double v) => padTop + ch * (1 - v / maxY);

    final racePts = <Offset>[
      for (var i = 0; i < n; i++) Offset(xFor(i), yFor(raceCumulative[i])),
    ];
    final racePaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rp = Path()..moveTo(racePts.first.dx, racePts.first.dy);
    for (var i = 1; i < racePts.length; i++) {
      rp.lineTo(racePts[i].dx, racePts[i].dy);
    }
    canvas.drawPath(rp, racePaint);

    final dashPaint = Paint()
      ..color = sprintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = sprintColor;
    for (var i = 0; i < n - 1; i++) {
      final a = sprintCumulative[i];
      final b = sprintCumulative[i + 1];
      if (a != null && b != null) {
        _drawDashedLine(
          canvas,
          Offset(xFor(i), yFor(a)),
          Offset(xFor(i + 1), yFor(b)),
          dashPaint,
        );
      }
    }
    for (var i = 0; i < n; i++) {
      final sv = sprintCumulative[i];
      if (sv != null) {
        canvas.drawCircle(Offset(xFor(i), yFor(sv)), 3.2, dotPaint);
      }
    }

    for (var i = 0; i < n; i++) {
      final r = rows[i];
      final code = r.circuitCode;
      final tp = TextPainter(
        text: TextSpan(
          text: code,
          style: TextStyle(
            color: labelColor,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(i) - tp.width / 2, size.height - 44));

      final peakRace = (r.racePointsDelta >= 15) ||
          (r.racePosition != null && r.racePosition == 1);
      if (peakRace) {
        final bracket =
            '[${r.racePointsDelta == r.racePointsDelta.roundToDouble() ? r.racePointsDelta.toInt() : r.racePointsDelta.toStringAsFixed(0)}]';
        final pos = r.racePosition != null ? '[P${r.racePosition}]' : '';
        final label = '$bracket $pos'.trim();
        final lp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: peakLabelColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 80);
        lp.paint(
          canvas,
          Offset(
            xFor(i) - lp.width / 2,
            yFor(raceCumulative[i]) - lp.height - 6,
          ),
        );
      }

      final sp = r.sprintPointsDelta;
      if (sp != null && (sp >= 8 || r.sprintPosition == 1)) {
        final bracket =
            '[${sp == sp.roundToDouble() ? sp.toInt() : sp.toStringAsFixed(0)}]';
        final pos =
            r.sprintPosition != null ? '[P${r.sprintPosition}]' : '';
        final label = '$bracket $pos'.trim();
        final yS = yFor(sprintCumulative[i]!);
        final lp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: sprintColor,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 72);
        lp.paint(canvas, Offset(xFor(i) - lp.width / 2, yS - lp.height - 4));
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    final d = b - a;
    final len = d.distance;
    if (len < 0.001) return;
    final dir = d / len;
    var dist = 0.0;
    while (dist < len) {
      final start = a + dir * dist;
      dist += dash;
      final end = a + dir * math.min(dist, len);
      canvas.drawLine(start, end, paint);
      dist += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ExpandedDualTrendPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.primary != primary ||
        oldDelegate.sprintColor != sprintColor;
  }
}

String? _paddockRecentFormDriverName(ProfileFavorites f) {
  if (f.favoriteDriver != null && f.favoriteDriver!.trim().isNotEmpty) {
    return f.favoriteDriver!.trim();
  }
  if (f.favoriteDriverNumbers.isEmpty) return null;
  final n = f.favoriteDriverNumbers.first;
  for (final x in drivers2026) {
    if (x.number == n) return x.name;
  }
  return null;
}

int _paddockRecentFormSeasonYear() {
  final now = DateTime.now();
  var completed2026 = 0;
  for (final r in races) {
    if (r.date.year != 2026) continue;
    if (!r.date.isAfter(now)) completed2026++;
  }
  if (completed2026 >= 1) return 2026;
  return 2025;
}
