import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Per mini-segment display tier (from F1 segment Status / flags).
enum MiniSectorTier {
  off,
  neutral,
  personalBest,
  overallBest,
}

class MiniSectorBlockVM {
  const MiniSectorBlockVM({
    required this.fill,
    this.glow = 0,
  });
  final MiniSectorTier fill;
  final double glow;
}

/// One row for the live timing tower.
class LiveTimingTowerRowModel {
  LiveTimingTowerRowModel({
    required this.position,
    required this.number,
    required this.code,
    required this.fullName,
    required this.teamColor,
    required this.gapFormatted,
    required this.miniS1,
    required this.miniS2,
    required this.miniS3,
    required this.tyreLetter,
    required this.tyreAge,
    this.tyreNew,
    this.dataSourceLabel = 'UNKNOWN',
    required this.pitsText,
    required this.lastLap,
    this.lastLapPurple = false,
    this.stoppedOrOut = false,
    this.outLabel = '',
    this.gainLoss = 0,
    this.isOutLap = false,
    this.inPit = false,
    this.pitEntryTimestamp,
    this.trackStatusCode = 1,
    this.trackLimitTicks = 0,
    this.gapTrend = 0,
  });

  final int position;
  final int number;
  final String code;
  final String fullName;
  final Color teamColor;
  final String gapFormatted;
  final List<MiniSectorBlockVM> miniS1;
  final List<MiniSectorBlockVM> miniS2;
  final List<MiniSectorBlockVM> miniS3;
  final String tyreLetter;
  final int tyreAge;
  final bool? tyreNew;
  final String dataSourceLabel;
  final String pitsText;
  final String lastLap;
  final bool lastLapPurple;
  final bool stoppedOrOut;
  final String outLabel;
  final int gainLoss;
  final bool isOutLap;
  final bool inPit;
  final DateTime? pitEntryTimestamp;
  final int trackStatusCode;
  /// Track limit warnings for this driver this session.
  final int trackLimitTicks;
  /// +1 = gap increasing (slower), -1 = gap decreasing (faster), 0 = stable.
  final int gapTrend;
}

// ─── Design tokens ─────────────────────────────────────────────────────
const Color _kBg = Color(0xFFF1F2F5);
const Color _kPurple = Color(0xFF5C2D91);
const Color _kText = Color(0xFF1A1D21);
const Color _kMuted = Color(0xFF6B7280);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kGainGreen = Color(0xFF00D21D);
const Color _kLossRed = Color(0xFFDC2626);
const Color _kTyreNewGreen = Color(0xFF00D21D);
const Color _kTyreUsedOrange = Color(0xFFFF9000);

const Color _kOutLapGlow = Color(0x1A00D21D);
const Color _kFastestLapGlow = Color(0x335C2D91);

// ─── Side-Step animation constants ──────────────────────────────────────
const Duration _kSideStepDuration = Duration(milliseconds: 500);

/// No-scroll, fixed-height live timing table with FOM animations.
class LiveTimingDataTable extends StatefulWidget {
  const LiveTimingDataTable({
    super.key,
    required this.rows,
    required this.fastestLapDriverNumber,
    this.sectorBestCodes = const {0: '', 1: '', 2: ''},
    this.headerHeight = 34,
    this.rowHeight = 42,
    this.trackStatusCode = 1,
    this.trackStatusMessage = '',
  });

  final List<LiveTimingTowerRowModel> rows;
  final int? fastestLapDriverNumber;
  final Map<int, String> sectorBestCodes;
  final double headerHeight;
  final double rowHeight;
  final int trackStatusCode;
  final String trackStatusMessage;

  static double scaledFont(double rh, double min, double max) =>
      (min + (rh - 28) / (52 - 28) * (max - min)).clamp(min, max);

  @override
  State<LiveTimingDataTable> createState() => _LiveTimingDataTableState();
}

class _LiveTimingDataTableState extends State<LiveTimingDataTable>
    with TickerProviderStateMixin {
  /// Tracks each driver number → their last-known list index for side-step detection.
  final Map<int, int> _prevPositionIndex = {};

  /// Active side-step controllers keyed by driver number.
  final Map<int, AnimationController> _sideStepControllers = {};

  /// Purple pulse controller shared by all overallBest micro-blocks.
  late final AnimationController _purplePulseController;

  /// 1-second tick for live pit timers.
  Timer? _pitTimerTick;

  @override
  void initState() {
    super.initState();
    _purplePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pitTimerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant LiveTimingDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _detectPositionSwaps();
  }

  void _detectPositionSwaps() {
    for (var i = 0; i < widget.rows.length && i < 20; i++) {
      final r = widget.rows[i];
      final prev = _prevPositionIndex[r.number];
      if (prev != null && prev != i) {
        _triggerSideStep(r.number);
      }
    }
    for (var i = 0; i < widget.rows.length && i < 20; i++) {
      _prevPositionIndex[widget.rows[i].number] = i;
    }
  }

  void _triggerSideStep(int driverNumber) {
    final old = _sideStepControllers.remove(driverNumber);
    if (old != null) {
      old.stop();
      old.dispose();
    }
    if (!mounted) return;
    final ctrl = AnimationController(vsync: this, duration: _kSideStepDuration);
    _sideStepControllers[driverNumber] = ctrl;
    ctrl.forward().then((_) {
      // Only clean up if this controller is still the active one for this driver.
      if (mounted && _sideStepControllers[driverNumber] == ctrl) {
        _sideStepControllers.remove(driverNumber);
        ctrl.dispose();
      }
    });
  }

  @override
  void dispose() {
    _pitTimerTick?.cancel();
    _purplePulseController.dispose();
    for (final c in _sideStepControllers.values) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _sideStepControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerH = widget.trackStatusCode != 1 ? 28.0 : 0.0;
        final availH = constraints.maxHeight - bannerH;
        final hdrH = widget.headerHeight.clamp(26.0, 38.0);
        final rh = ((availH - hdrH) / 20).clamp(28.0, 52.0);

        final monoBase = GoogleFonts.robotoMono(
          fontSize: LiveTimingDataTable.scaledFont(rh, 9, 11),
          fontWeight: FontWeight.w600,
          color: _kPurple,
          height: 1.15,
        );
        final labelBase = GoogleFonts.robotoCondensed(
          fontSize: LiveTimingDataTable.scaledFont(rh, 9, 11),
          fontWeight: FontWeight.w600,
          color: _kText,
          height: 1.15,
        );

        return Column(
          children: [
            if (widget.trackStatusCode != 1)
              _TrackStatusBanner(
                code: widget.trackStatusCode,
                message: widget.trackStatusMessage,
                height: bannerH,
              ),
            SizedBox(
              height: hdrH,
              child: _buildHeaderRow(hdrH, labelBase),
            ),
            Expanded(
              child: ClipRect(
                child: Column(
                  children: [
                    for (var i = 0; i < widget.rows.length && i < 20; i++)
                      SizedBox(
                        height: rh,
                        child: _AnimatedTimingRow(
                          row: widget.rows[i],
                          rowHeight: rh,
                          monoBase: monoBase,
                          labelBase: labelBase,
                          isFastestLap: widget.fastestLapDriverNumber != null &&
                              widget.rows[i].number == widget.fastestLapDriverNumber,
                          isEven: i.isEven,
                          sideStepController: _sideStepControllers[widget.rows[i].number],
                          purplePulseAnimation: _purplePulseController,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow(double h, TextStyle base) {
    final s = base.copyWith(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      color: _kMuted,
      letterSpacing: 0.3,
    );
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _HdrCell(w: 42, label: 'POS', style: s),
          _HdrCell(w: 34, label: 'GAIN', style: s),
          const SizedBox(width: 6),
          _HdrCell(w: 140, label: 'DRIVER', style: s),
          _HdrCell(w: 68, label: 'TYRE', style: s),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _SectorHdrCell(label: 'S1', best: widget.sectorBestCodes[0] ?? '', style: s),
                _SectorHdrCell(label: 'S2', best: widget.sectorBestCodes[1] ?? '', style: s),
                _SectorHdrCell(label: 'S3', best: widget.sectorBestCodes[2] ?? '', style: s),
              ],
            ),
          ),
          _HdrCell(w: 100, label: 'INT / GAP', style: s, align: TextAlign.right),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Track Status Banner ────────────────────────────────────────────────
class _TrackStatusBanner extends StatelessWidget {
  const _TrackStatusBanner({
    required this.code,
    required this.message,
    required this.height,
  });
  final int code;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (code) {
      case 2:
        bg = const Color(0xFFFDE047);
        fg = const Color(0xFF1A1D21);
        label = message.isNotEmpty ? message : 'YELLOW FLAG';
        break;
      case 4:
        bg = const Color(0xFFFF9000);
        fg = Colors.white;
        label = message.isNotEmpty ? message : 'SAFETY CAR';
        break;
      case 5:
        bg = const Color(0xFFDC2626);
        fg = Colors.white;
        label = message.isNotEmpty ? message : 'RED FLAG';
        break;
      case 6:
        bg = const Color(0xFFFF9000);
        fg = Colors.white;
        label = message.isNotEmpty ? message : 'VSC DEPLOYED';
        break;
      case 7:
        bg = const Color(0xFFFF9000);
        fg = Colors.white;
        label = message.isNotEmpty ? message : 'VSC ENDING';
        break;
      default:
        bg = const Color(0xFF22C55E);
        fg = Colors.white;
        label = 'GREEN';
    }
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoCondensed(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Header cells ───────────────────────────────────────────────────────
class _HdrCell extends StatelessWidget {
  const _HdrCell({
    required this.w,
    required this.label,
    required this.style,
    this.align = TextAlign.left,
  });
  final double w;
  final String label;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(label, style: style, textAlign: align),
      ),
    );
  }
}

class _SectorHdrCell extends StatelessWidget {
  const _SectorHdrCell({
    required this.label,
    required this.best,
    required this.style,
  });
  final String label;
  final String best;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Text(label, style: style),
            if (best.isNotEmpty) ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  best,
                  style: style.copyWith(fontSize: 7, color: _kPurple, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Animated driver row (Side-Step + glow FX) ─────────────────────────
class _AnimatedTimingRow extends StatelessWidget {
  const _AnimatedTimingRow({
    required this.row,
    required this.rowHeight,
    required this.monoBase,
    required this.labelBase,
    required this.isFastestLap,
    required this.isEven,
    this.sideStepController,
    required this.purplePulseAnimation,
  });
  final LiveTimingTowerRowModel row;
  final double rowHeight;
  final TextStyle monoBase;
  final TextStyle labelBase;
  final bool isFastestLap;
  final bool isEven;
  final AnimationController? sideStepController;
  final AnimationController purplePulseAnimation;

  /// 3-phase FOM side-step: right 8px → hold → back to 0.
  static final TweenSequence<double> _sideStepTween = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 0, end: 8).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    TweenSequenceItem(tween: ConstantTween<double>(8), weight: 40),
    TweenSequenceItem(tween: Tween<double>(begin: 8, end: 0).chain(CurveTween(curve: Curves.easeIn)), weight: 35),
  ]);

  @override
  Widget build(BuildContext context) {
    final dim = row.stoppedOrOut ? 0.45 : 1.0;

    List<BoxShadow>? shadows;
    Color? rowBgOverride;
    if (isFastestLap) {
      shadows = const [BoxShadow(color: _kFastestLapGlow, blurRadius: 10, spreadRadius: 2)];
    }
    if (row.isOutLap && !row.stoppedOrOut) {
      rowBgOverride = _kOutLapGlow;
    }

    Widget content = Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: rowBgOverride ?? (isEven ? _kCardBg : _kBg.withValues(alpha: 0.5)),
        border: const Border(bottom: BorderSide(color: _kBorder, width: 0.3)),
        boxShadow: shadows,
      ),
      child: Opacity(
        opacity: dim,
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Center(
                child: Text(
                  '${row.position}',
                  style: labelBase.copyWith(fontWeight: FontWeight.w900, fontSize: _fs(11)),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: _GainLossCell(gainLoss: row.gainLoss, fontSize: _fs(9)),
            ),
            Container(
              width: 4,
              height: (rowHeight * 0.6).clamp(16.0, 28.0),
              margin: const EdgeInsets.only(left: 2, right: 4),
              decoration: BoxDecoration(
                color: row.teamColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(
              width: 136,
              child: _DriverCell(
                code: row.code,
                fullName: row.fullName,
                isFastestLap: isFastestLap,
                isOutLap: row.isOutLap,
                trackLimitTicks: row.trackLimitTicks,
                labelBase: labelBase,
                fontSize: _fs(11),
              ),
            ),
            SizedBox(
              width: 68,
              child: _TyreAgeCell(
                letter: row.tyreLetter,
                age: row.tyreAge,
                tyreNew: row.tyreNew,
                rowHeight: rowHeight,
                labelBase: labelBase,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _MiniSectorColumn(blocks: row.miniS1, rowHeight: rowHeight, pulseAnim: purplePulseAnimation),
                  _MiniSectorColumn(blocks: row.miniS2, rowHeight: rowHeight, pulseAnim: purplePulseAnimation),
                  _MiniSectorColumn(blocks: row.miniS3, rowHeight: rowHeight, pulseAnim: purplePulseAnimation),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: _GapCell(
                row: row,
                monoBase: monoBase,
                fontSize: _fs(10),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );

    final ctrl = sideStepController;
    if (ctrl != null) {
      content = AnimatedBuilder(
        animation: ctrl,
        builder: (context, child) {
          final dx = _sideStepTween.evaluate(ctrl);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: content,
      );
    }

    return content;
  }

  double _fs(double base) => LiveTimingDataTable.scaledFont(rowHeight, base - 1.5, base);
}

// ─── GAIN / LOSS cell ───────────────────────────────────────────────────
class _GainLossCell extends StatelessWidget {
  const _GainLossCell({required this.gainLoss, required this.fontSize});
  final int gainLoss;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (gainLoss == 0) {
      return Center(
        child: Text('–', style: TextStyle(color: _kMuted, fontSize: fontSize)),
      );
    }
    final up = gainLoss > 0;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 14,
            color: up ? _kGainGreen : _kLossRed,
          ),
          Text(
            '${gainLoss.abs()}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: up ? _kGainGreen : _kLossRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DRIVER cell (code + name + track limit ticks + out-lap badge) ──────
class _DriverCell extends StatelessWidget {
  const _DriverCell({
    required this.code,
    required this.fullName,
    required this.isFastestLap,
    required this.isOutLap,
    required this.trackLimitTicks,
    required this.labelBase,
    required this.fontSize,
  });
  final String code;
  final String fullName;
  final bool isFastestLap;
  final bool isOutLap;
  final int trackLimitTicks;
  final TextStyle labelBase;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                code,
                style: labelBase.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  color: _kPurple,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelBase.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize - 1,
                    color: _kText.withValues(alpha: 0.75),
                  ),
                ),
              ),
              if (trackLimitTicks > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    '|' * math.min(trackLimitTicks, 5),
                    style: TextStyle(
                      fontSize: fontSize - 1,
                      fontWeight: FontWeight.w900,
                      color: trackLimitTicks >= 3 ? _kLossRed : _kTyreUsedOrange,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              if (isFastestLap)
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(Icons.timer_outlined, size: 12, color: _kPurple),
                ),
            ],
          ),
          if (isOutLap)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _kTyreNewGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'OUT-LAP',
                  style: labelBase.copyWith(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w800,
                    color: _kTyreNewGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── TYRE & AGE cell ────────────────────────────────────────────────────
class _TyreAgeCell extends StatelessWidget {
  const _TyreAgeCell({
    required this.letter,
    required this.age,
    required this.tyreNew,
    required this.rowHeight,
    required this.labelBase,
  });
  final String letter;
  final int age;
  final bool? tyreNew;
  final double rowHeight;
  final TextStyle labelBase;

  static const _badgeColors = <String, (Color bg, Color fg, Color? border)>{
    'S': (Color(0xFFFF0000), Colors.white, null),
    'M': (Color(0xFFFFFF00), Colors.black, null),
    'H': (Colors.white, Colors.black, Color(0xFF9E9E9E)),
    'I': (Color(0xFF00D21D), Colors.white, null),
    'W': (Color(0xFF0082FA), Colors.white, null),
  };

  @override
  Widget build(BuildContext context) {
    final d = (rowHeight * 0.52).clamp(18.0, 24.0);
    final fontSize = LiveTimingDataTable.scaledFont(rowHeight, 10, 12);
    final (bg, fg, border) = _badgeColors[letter] ??
        (const Color(0xFFD1D5DB), const Color(0xFF6B7280), null);

    final ageColor = tyreNew == true
        ? _kTyreNewGreen
        : tyreNew == false
            ? _kTyreUsedOrange
            : _kMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: d,
            height: d,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border != null
                  ? Border.all(color: border, width: 1)
                  : null,
            ),
            child: Text(
              letter,
              style: GoogleFonts.inter(
                fontSize: fontSize * 0.82,
                fontWeight: FontWeight.w800,
                color: fg,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (letter != '?' && age >= 0)
            Text(
              '$age',
              style: GoogleFonts.robotoMono(
                fontSize: LiveTimingDataTable.scaledFont(rowHeight, 9, 11),
                fontWeight: FontWeight.w700,
                color: ageColor,
              ),
            )
          else
            Text('–', style: TextStyle(color: _kMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── MICRO-SECTOR column (with purple pulse for overallBest) ────────────
class _MiniSectorColumn extends StatelessWidget {
  const _MiniSectorColumn({
    required this.blocks,
    required this.rowHeight,
    required this.pulseAnim,
  });
  final List<MiniSectorBlockVM> blocks;
  final double rowHeight;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    final n = blocks.isEmpty ? 6 : blocks.length.clamp(6, 8);
    final vPad = ((rowHeight - 10) / 2).clamp(4.0, 12.0);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: vPad),
        child: Row(
          children: List.generate(n, (i) {
            final vm = i < blocks.length
                ? blocks[i]
                : const MiniSectorBlockVM(fill: MiniSectorTier.off);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.5),
                child: vm.fill == MiniSectorTier.overallBest
                    ? _PulsingMiniBlock(vm: vm, pulseAnim: pulseAnim)
                    : _MiniBlock(vm: vm),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Standard (non-purple) mini sector block.
class _MiniBlock extends StatelessWidget {
  const _MiniBlock({required this.vm});
  final MiniSectorBlockVM vm;

  static Color tierColor(MiniSectorTier t) {
    switch (t) {
      case MiniSectorTier.off:
        return _kBorder.withValues(alpha: 0.5);
      case MiniSectorTier.neutral:
        return const Color(0xFFFDE047);
      case MiniSectorTier.personalBest:
        return _kGainGreen;
      case MiniSectorTier.overallBest:
        return _kPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = vm.fill != MiniSectorTier.off
        ? tierColor(vm.fill)
        : _kBorder.withValues(alpha: 0.5);
    Widget core = Container(
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: _kBorder.withValues(alpha: vm.fill != MiniSectorTier.off ? 0.4 : 0.2),
          width: 0.5,
        ),
      ),
    );
    if (vm.fill == MiniSectorTier.off && vm.glow > 0.02) {
      final g = vm.glow.clamp(0.0, 1.0);
      core = Stack(
        fit: StackFit.passthrough,
        children: [
          core,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _kPurple.withValues(alpha: 0.0),
                    _kPurple.withValues(alpha: 0.10 * g),
                    _kPurple.withValues(alpha: 0.18 * g),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return core;
  }
}

/// 2051 Purple Pulse: breathing purple BoxShadow on overallBest mini-sector blocks.
class _PulsingMiniBlock extends StatelessWidget {
  const _PulsingMiniBlock({required this.vm, required this.pulseAnim});
  final MiniSectorBlockVM vm;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, _) {
        final pulse = pulseAnim.value;
        final blurRadius = 3.0 + pulse * 5.0;
        final spreadRadius = 0.5 + pulse * 1.5;
        final alpha = 0.30 + pulse * 0.35;
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: _kPurple,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: _kPurple.withValues(alpha: 0.6), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: alpha),
                blurRadius: blurRadius,
                spreadRadius: spreadRadius,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── INT/GAP cell with trend arrow ──────────────────────────────────────
class _GapCell extends StatelessWidget {
  const _GapCell({
    required this.row,
    required this.monoBase,
    required this.fontSize,
  });
  final LiveTimingTowerRowModel row;
  final TextStyle monoBase;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (row.inPit) {
      return _PitTimerDisplay(
        pitEntry: row.pitEntryTimestamp,
        monoBase: monoBase,
        fontSize: fontSize,
      );
    }

    final trendIcon = row.gapTrend > 0
        ? const Icon(Icons.arrow_upward, size: 10, color: _kLossRed)
        : row.gapTrend < 0
            ? const Icon(Icons.arrow_downward, size: 10, color: _kGainGreen)
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (trendIcon != null) ...[
            trendIcon,
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              row.gapFormatted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: monoBase.copyWith(
                fontSize: fontSize,
                color: row.stoppedOrOut ? _kLossRed : _kPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live pit timer — updates every second via parent timer.
class _PitTimerDisplay extends StatelessWidget {
  const _PitTimerDisplay({
    required this.pitEntry,
    required this.monoBase,
    required this.fontSize,
  });
  final DateTime? pitEntry;
  final TextStyle monoBase;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    String timer = '—';
    if (pitEntry != null) {
      final elapsed = DateTime.now().toUtc().difference(pitEntry!.toUtc());
      final s = elapsed.inSeconds.clamp(0, 999);
      timer = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'PIT',
                style: monoBase.copyWith(
                  fontSize: fontSize - 1,
                  fontWeight: FontWeight.w900,
                  color: _kLossRed,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              timer,
              style: monoBase.copyWith(fontSize: fontSize, color: _kLossRed),
            ),
          ],
        ),
      ),
    );
  }
}
