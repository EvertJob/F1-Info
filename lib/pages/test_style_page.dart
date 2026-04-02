// Cockpit-style PoC for `/#/test` — `assets/styles/{slug}.json`.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, MaskFilter, BlurStyle;

import 'package:f1/widgets/hub_glass_chart_loading.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlapping wind-tunnel style rings; opacity capped & colours from [bgGradient].
class AnimatedAeroCirclesPainter extends CustomPainter {
  AnimatedAeroCirclesPainter({
    required this.style,
    required this.phase,
  });

  final TeamStyle style;
  final double phase;

  static const double _maxStrokeOpacity = 0.09;

  @override
  void paint(Canvas canvas, Size size) {
    final n = style.aeroCircleCount.clamp(4, 18);
    final strokeW = style.aeroStrokeWidth.clamp(0.35, 2.0);
    final curve = style.aeroCurviness.clamp(0.0, 1.0);
    final colors = style.bgGradient.isNotEmpty
        ? style.bgGradient
        : [style.backgroundStart, style.backgroundEnd];
    final baseOpacity = math.min(style.aeroLineOpacity, _maxStrokeOpacity);

    final t = phase * math.pi * 2;

    for (var i = 0; i < n; i++) {
      final fi = i / math.max(1, n - 1);
      final ox = math.sin(t * 0.85 + i * 1.1) * size.width * 0.06 * curve;
      final oy = math.cos(t * 0.7 + i * 0.9) * size.height * 0.05 * curve;
      final cx =
          size.width * (0.12 + 0.76 * fi) + ox + math.sin(t + i * 0.4) * size.width * 0.04;
      final cy = size.height *
              (0.18 + 0.64 * ((fi + phase * 0.35 + i * 0.07) % 1.0)) +
          oy;
      final baseR = math.min(size.width, size.height) *
          (0.11 + 0.09 * math.sin(t * 1.15 + i * 0.8)) *
          (0.55 + 0.45 * curve);
      final c = colors[i % colors.length].withValues(alpha: baseOpacity);

      final paint = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(cx, cy), baseR, paint);

      if (i.isEven) {
        final inner = Paint()
          ..color = colors[(i + 1) % colors.length].withValues(alpha: baseOpacity * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 0.65
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
        canvas.drawCircle(
          Offset(cx + baseR * 0.08, cy - baseR * 0.06),
          baseR * 0.72,
          inner,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAeroCirclesPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.style.aeroCircleCount != style.aeroCircleCount ||
        oldDelegate.style.aeroLineOpacity != style.aeroLineOpacity ||
        oldDelegate.style.aeroStrokeWidth != style.aeroStrokeWidth ||
        oldDelegate.style.aeroCurviness != style.aeroCurviness ||
        !listEquals(oldDelegate.style.bgGradient, style.bgGradient) ||
        oldDelegate.style.backgroundStart != style.backgroundStart ||
        oldDelegate.style.backgroundEnd != style.backgroundEnd;
  }
}

/// Blueprint grid inside cards.
class CardBlueprintGridPainter extends CustomPainter {
  CardBlueprintGridPainter({
    required this.lineColor,
    this.step = 14.0,
    this.opacity = 0.05,
  });

  final Color lineColor;
  final double step;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor.withValues(alpha: opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CardBlueprintGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.step != step ||
        oldDelegate.opacity != opacity;
  }
}

/// 0.5px frosted white rim + whisper-soft team sheen at corners (blurred radial falloff).
class RazorSheenCardPainter extends CustomPainter {
  RazorSheenCardPainter({
    required this.borderRadius,
    required this.primary,
    required this.secondary,
  });

  final double borderRadius;
  final Color primary;
  final Color secondary;

  static const double _kRimWidth = 0.5;
  static const double _kSheenPeak = 0.15;
  static const double _kBlurSigma = 22.0;
  static const double _kSheenRadius = 155.0;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final rim = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kRimWidth;
    canvas.drawRRect(r, rim);

    void cornerSheen(Offset center, Color whisper) {
      final rect = Rect.fromCircle(center: center, radius: _kSheenRadius);
      final shader = RadialGradient(
        colors: [
          whisper.withValues(alpha: _kSheenPeak),
          whisper.withValues(alpha: _kSheenPeak * 0.35),
          whisper.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(rect);

      final soft = Paint()
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _kBlurSigma);
      canvas.drawCircle(center, _kSheenRadius * 0.92, soft);
    }

    final inset = borderRadius * 0.85;
    cornerSheen(Offset(inset, inset), primary);
    cornerSheen(Offset(size.width - inset, inset), secondary);
    cornerSheen(Offset(inset, size.height - inset), secondary);
    cornerSheen(Offset(size.width - inset, size.height - inset), primary);
  }

  @override
  bool shouldRepaint(covariant RazorSheenCardPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}

class TeamStyle {
  const TeamStyle({
    required this.teamId,
    required this.teamName,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.headerGlow,
    required this.bgGradient,
    required this.blurSigma,
    required this.glassOpacity,
    required this.borderWidth,
    required this.cardBlurSigma,
    required this.cardPadding,
    required this.cardBorderRadius,
    required this.cardMarginVertical,
    required this.headerHeight,
    required this.showTeamStripe,
    required this.stripeHeight,
    required this.fontFamily,
    required this.titleLetterSpacing,
    required this.uppercaseHeaders,
    required this.headerNavLabels,
    required this.headerTitle,
    required this.headerActiveNav,
    required this.carImageAsset,
    required this.logoMinimalAsset,
    required this.aeroCircleCount,
    required this.aeroLineOpacity,
    required this.aeroStrokeWidth,
    required this.aeroCurviness,
    required this.aeroAnimate,
    required this.cardGridOpacity,
  });

  final String teamId;
  final String teamName;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color headerGlow;
  final List<Color> bgGradient;
  final double blurSigma;
  final double glassOpacity;
  final double borderWidth;
  final double cardBlurSigma;
  final double cardPadding;
  final double cardBorderRadius;
  final double cardMarginVertical;
  final double headerHeight;
  final bool showTeamStripe;
  final double stripeHeight;
  final String fontFamily;
  final double titleLetterSpacing;
  final bool uppercaseHeaders;
  final List<String> headerNavLabels;
  final String headerTitle;
  /// Nav label treated as active (glass capsule), case-insensitive match.
  final String headerActiveNav;
  final String carImageAsset;
  final String logoMinimalAsset;

  final int aeroCircleCount;
  final double aeroLineOpacity;
  final double aeroStrokeWidth;
  final double aeroCurviness;
  final bool aeroAnimate;
  final double cardGridOpacity;

  static Color _hex(String raw) {
    var s = raw.trim().replaceFirst('#', '');
    if (s.length == 6) {
      s = 'FF$s';
    }
    return Color(int.parse(s, radix: 16));
  }

  static Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static List<Color> _hexList(List<dynamic>? list, List<Color> fallback) {
    if (list == null || list.isEmpty) {
      return fallback;
    }
    try {
      return list.map((e) => _hex(e.toString())).toList();
    } catch (_) {
      return fallback;
    }
  }

  factory TeamStyle.fromJson(Map<String, dynamic> json) {
    final theme = _jsonMap(json['theme']);
    final colors = _jsonMap(theme['colors']);
    final glass = _jsonMap(theme['glass']);
    final layout = _jsonMap(theme['layout']);
    final typo = _jsonMap(theme['typography']);
    final assets = _jsonMap(theme['assets']);
    final aero = _jsonMap(theme['aero_effect']);

    final bgStart = _hex(colors['background_start']?.toString() ?? '#F5F5F5');
    final bgEnd = _hex(colors['background_end']?.toString() ?? '#E8E8E8');
    final bgGrad = _hexList(
      colors['bg_gradient'] as List<dynamic>?,
      [bgStart, bgEnd],
    );

    final blur = (glass['blur_sigma'] as num?)?.toDouble() ?? 12;
    final navRaw = theme['header_nav'];
    final navLabels = navRaw is List
        ? navRaw.map((e) => e.toString()).toList()
        : <String>[];

    final circleCount = (aero['circle_count'] as num?)?.round() ??
        (aero['line_count'] as num?)?.round() ??
        8;

    return TeamStyle(
      teamId: json['team_id']?.toString() ?? 'team',
      teamName: json['team_name']?.toString() ?? 'Team',
      primary: _hex(colors['primary']?.toString() ?? '#0066FF'),
      secondary: _hex(colors['secondary']?.toString() ?? '#FF0000'),
      accent: _hex(colors['accent']?.toString() ?? '#FFFFFF'),
      backgroundStart: bgStart,
      backgroundEnd: bgEnd,
      headerGlow: _hex(colors['header_glow']?.toString() ?? '#88CCFF'),
      bgGradient: bgGrad,
      blurSigma: blur,
      glassOpacity: (glass['opacity'] as num?)?.toDouble() ?? 0.05,
      borderWidth: (glass['border_width'] as num?)?.toDouble() ?? 0.5,
      cardBlurSigma:
          (glass['card_blur_sigma'] as num?)?.toDouble() ??
          (blur * 1.45).clamp(18.0, 40.0),
      cardPadding: (layout['card_padding'] as num?)?.toDouble() ?? 16,
      cardBorderRadius: (layout['card_border_radius'] as num?)?.toDouble() ?? 20,
      cardMarginVertical:
          (layout['card_margin_vertical'] as num?)?.toDouble() ?? 16,
      headerHeight: (layout['header_height'] as num?)?.toDouble() ?? 64,
      showTeamStripe: layout['show_team_stripe'] == true,
      stripeHeight: (layout['stripe_height'] as num?)?.toDouble() ?? 4,
      fontFamily: typo['font_family']?.toString() ?? 'Inter',
      titleLetterSpacing:
          (typo['title_letter_spacing'] as num?)?.toDouble() ?? 0.15,
      uppercaseHeaders: typo['uppercase_headers'] != false,
      headerNavLabels: navLabels,
      headerTitle: theme['header_title']?.toString() ?? 'F1 HUB',
      headerActiveNav: theme['header_active_nav']?.toString() ?? 'TEAMS',
      carImageAsset: assets['car_image']?.toString() ?? '',
      logoMinimalAsset: assets['logo_minimal']?.toString() ?? '',
      aeroCircleCount: circleCount.clamp(3, 24),
      aeroLineOpacity: (aero['line_opacity'] as num?)?.toDouble() ?? 0.08,
      aeroStrokeWidth: (aero['stroke_width'] as num?)?.toDouble() ?? 1.0,
      aeroCurviness: (aero['curviness'] as num?)?.toDouble() ?? 0.5,
      aeroAnimate: aero.isNotEmpty && (aero['animate'] != false),
      cardGridOpacity: (aero['card_grid_opacity'] as num?)?.toDouble() ?? 0.045,
    );
  }

  TextStyle chromeTextStyle({
    required double fontSize,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) {
    final c = color ?? const Color(0xFF1E293B);
    final ls = letterSpacing ?? titleLetterSpacing;
    final ff = fontFamily.toLowerCase();
    if (ff == 'roboto') {
      return GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: ls,
        color: c,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: ls,
      color: c,
    );
  }

  TextStyle dataTagTextStyle({double fontSize = 10.5}) {
    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: const Color(0xFF475569).withValues(alpha: 0.92),
    );
  }

  TextStyle bodyTextStyle(BuildContext context, {double fontSize = 14}) {
    final scheme = Theme.of(context).colorScheme;
    final ff = fontFamily.toLowerCase();
    final base = ff == 'roboto'
        ? GoogleFonts.roboto(fontSize: fontSize, height: 1.45)
        : GoogleFonts.inter(fontSize: fontSize, height: 1.45);
    return base.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.88),
    );
  }
}

class F1GlassCardWidget extends StatelessWidget {
  const F1GlassCardWidget({
    required this.style,
    required this.child,
    this.dataTag,
    super.key,
  });

  final TeamStyle style;
  final Widget child;
  final String? dataTag;

  @override
  Widget build(BuildContext context) {
    final r = style.cardBorderRadius;
    final veil = 0.05;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: style.cardBlurSigma,
                  sigmaY: style.cardBlurSigma,
                ),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: CardBlueprintGridPainter(
                lineColor: Colors.white,
                opacity: style.cardGridOpacity,
                step: 12,
              ),
            ),
          ),
          ColoredBox(
            color: Colors.white.withValues(alpha: veil),
            child: Padding(
              padding: EdgeInsets.all(style.cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 1,
                    color: style.secondary.withValues(alpha: 0.88),
                  ),
                  SizedBox(width: style.cardPadding.clamp(10.0, 16.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dataTag != null && dataTag!.isNotEmpty) ...[
                          Text(dataTag!, style: style.dataTagTextStyle()),
                          const SizedBox(height: 10),
                        ],
                        child,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: RazorSheenCardPainter(
                  borderRadius: r,
                  primary: style.primary,
                  secondary: style.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TestStylePage extends StatefulWidget {
  const TestStylePage({
    required this.slug,
    super.key,
  });

  final String slug;

  @override
  State<TestStylePage> createState() => _TestStylePageState();
}

class _StyleLoadOutcome {
  const _StyleLoadOutcome({this.style, this.userMessage});
  final TeamStyle? style;
  final String? userMessage;
}

class _TestStylePageState extends State<TestStylePage> {
  late Future<_StyleLoadOutcome> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadStyle(widget.slug);
  }

  @override
  void didUpdateWidget(covariant TestStylePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      setState(() => _loadFuture = _loadStyle(widget.slug));
    }
  }

  static Future<_StyleLoadOutcome> _loadStyle(String slug) async {
    final path = 'assets/styles/${slug.trim()}.json';
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return _StyleLoadOutcome(
          userMessage: 'Root value in $path must be a JSON object.',
        );
      }
      final root = Map<String, dynamic>.from(decoded);
      try {
        return _StyleLoadOutcome(style: TeamStyle.fromJson(root));
      } catch (e, st) {
        debugPrint('TestStylePage: TeamStyle.fromJson failed: $e\n$st');
        return _StyleLoadOutcome(
          userMessage: 'Invalid theme data in $path: $e',
        );
      }
    } catch (e, st) {
      debugPrint('TestStylePage: asset load failed $path — $e\n$st');
      return _StyleLoadOutcome(
        userMessage:
            'Could not load $path.\n\n'
            'Run flutter pub get, then stop the app and start again '
            '(hot reload does not pick up new assets on web).',
      );
    }
  }

  List<(String tag, String title, String body)> _mockCards(TeamStyle s) {
    final prefix = s.uppercaseHeaders ? s.teamName.toUpperCase() : s.teamName;
    return [
      (
        '01 // TEAM DATA',
        s.uppercaseHeaders ? 'PERFORMANCE SNAPSHOT' : 'Performance snapshot',
        '$prefix — Cockpit readout; theme from JSON only.',
      ),
      (
        '02 // TELEMETRY',
        s.uppercaseHeaders ? 'TELEMETRY STRIP' : 'Telemetry strip',
        'Glass veil α=0.05, blur σ=${s.cardBlurSigma.toStringAsFixed(0)}, aero circles ω=${s.aeroAnimate}.',
      ),
      (
        '03 // SYSTEMS',
        s.uppercaseHeaders ? 'SYSTEMS OK' : 'Systems OK',
        'Razor rim 0.5px @ 30% white; corner sheen peaks at 15% then soft-falloff with blur.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StyleLoadOutcome>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: HubGlassPageLoadingPlaceholder()),
          );
        }
        final outcome = snapshot.data;
        final style = outcome?.style;
        if (style == null) {
          final msg = outcome?.userMessage ??
              'Unknown error loading assets/styles/${widget.slug}.json';
          return Scaffold(
            appBar: AppBar(title: const Text('Style PoC')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          );
        }

        return _StyleLoadedBody(
          key: ValueKey<String>(widget.slug),
          style: style,
          mockCards: _mockCards(style),
        );
      },
    );
  }
}

class _StyleLoadedBody extends StatefulWidget {
  const _StyleLoadedBody({
    required this.style,
    required this.mockCards,
    super.key,
  });

  final TeamStyle style;
  final List<(String tag, String title, String body)> mockCards;

  @override
  State<_StyleLoadedBody> createState() => _StyleLoadedBodyState();
}

/// Owns the infinite aero animation loop (`AnimationController.repeat()`).
class _StyleLoadedBodyState extends State<_StyleLoadedBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aeroController;

  @override
  void initState() {
    super.initState();
    _aeroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    );
    if (widget.style.aeroAnimate) {
      _aeroController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StyleLoadedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style.aeroAnimate != widget.style.aeroAnimate) {
      if (widget.style.aeroAnimate) {
        _aeroController.repeat();
      } else {
        _aeroController.stop();
      }
    }
  }

  @override
  void dispose() {
    _aeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AmbientStyleScaffold(
      style: widget.style,
      mockCards: widget.mockCards,
      aeroController: _aeroController,
    );
  }
}

class _AmbientStyleScaffold extends StatelessWidget {
  const _AmbientStyleScaffold({
    required this.style,
    required this.mockCards,
    required this.aeroController,
  });

  final TeamStyle style;
  final List<(String tag, String title, String body)> mockCards;
  final AnimationController aeroController;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final gradColors = style.bgGradient.length >= 2
        ? style.bgGradient
        : [style.backgroundStart, style.backgroundEnd];

    final aeroLayer = AnimatedBuilder(
      animation: aeroController,
      builder: (context, _) => CustomPaint(
        painter: AnimatedAeroCirclesPainter(
          style: style,
          phase: style.aeroAnimate ? aeroController.value : 0,
        ),
        child: const SizedBox.expand(),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradColors,
                ),
              ),
            ),
          ),
          Positioned.fill(child: aeroLayer),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CockpitHeader(style: style),
                  if (style.showTeamStripe)
                    Container(
                      height: style.stripeHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [style.primary, style.secondary],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        20 + mq.padding.bottom,
                      ),
                      itemCount: mockCards.length + 1,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: style.cardMarginVertical),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CarHero(style: style);
                        }
                        final c = mockCards[index - 1];
                        return F1GlassCardWidget(
                          style: style,
                          dataTag: c.$1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.uppercaseHeaders
                                    ? c.$2.toUpperCase()
                                    : c.$2,
                                style: style.chromeTextStyle(
                                  fontSize: 15,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(c.$3, style: style.bodyTextStyle(context)),
                            ],
                          ),
                        );
                      },
                    ),
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

class _CockpitHeader extends StatelessWidget {
  const _CockpitHeader({required this.style});

  final TeamStyle style;

  bool _isActiveNav(String label) {
    final target = style.headerActiveNav.trim().toUpperCase();
    final t = label.trim().toUpperCase();
    return t == target || t.contains(target) || target.contains(t);
  }

  @override
  Widget build(BuildContext context) {
    final r = 18.0;
    final title = style.uppercaseHeaders
        ? style.headerTitle.toUpperCase()
        : style.headerTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: style.blurSigma,
                    sigmaY: style.blurSigma,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          const Color(0xFFE8EAEF).withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.93),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: style.headerHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.headerGlow.withValues(alpha: 0.22),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    title,
                    style: style.chromeTextStyle(
                      fontSize: 13,
                      weight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < style.headerNavLabels.length; i++) ...[
                              if (i > 0) const SizedBox(width: 4),
                              _NavCapsule(
                                label: style.headerNavLabels[i],
                                uppercase: style.uppercaseHeaders,
                                active: _isActiveNav(style.headerNavLabels[i]),
                                style: style,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.settings_outlined,
                    color: const Color(0xFF64748B).withValues(alpha: 0.9),
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCapsule extends StatelessWidget {
  const _NavCapsule({
    required this.label,
    required this.uppercase,
    required this.active,
    required this.style,
  });

  final String label;
  final bool uppercase;
  final bool active;
  final TeamStyle style;

  @override
  Widget build(BuildContext context) {
    final text = uppercase ? label.toUpperCase() : label;
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        style: style.chromeTextStyle(
          fontSize: 10,
          weight: FontWeight.w600,
          color: active
              ? const Color(0xFF0F172A)
              : const Color(0xFF64748B),
        ),
      ),
    );

    if (!active) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: child,
    );
  }
}

class _CarHero extends StatelessWidget {
  const _CarHero({required this.style});

  final TeamStyle style;

  @override
  Widget build(BuildContext context) {
    final path = style.carImageAsset.trim();
    if (path.isEmpty) {
      return F1GlassCardWidget(
        style: style,
        dataTag: '00 // VISUAL',
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'Set theme.assets.car_image in JSON',
              style: style.bodyTextStyle(context),
            ),
          ),
        ),
      );
    }

    return F1GlassCardWidget(
      style: style,
      dataTag: '00 // LIVERY',
      child: Column(
        children: [
          Text(
            style.uppercaseHeaders
                ? style.teamName.toUpperCase()
                : style.teamName,
            textAlign: TextAlign.center,
            style: style.chromeTextStyle(
              fontSize: 17,
              weight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(style.cardBorderRadius * 0.5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: Image.asset(
                path,
                bundle: rootBundle,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Missing: $path',
                        textAlign: TextAlign.center,
                        style: style.bodyTextStyle(context, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
