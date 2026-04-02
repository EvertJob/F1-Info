
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'live_timing_page.dart';
import 'login_page.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'theme/f1_team_schemes.dart';
import 'theme/f1_theme_tokens.dart';
import 'theme/theme_controller.dart';
import 'widgets/constructor_hub_hero.dart';
import 'widgets/driver_hub_hero.dart';
import 'widgets/f1_tire_badge.dart';
import 'widgets/hub_ambient_backdrop.dart';
import 'widgets/hub_asset_image_chain.dart';
import 'widgets/hub_fullscreen_glass_dialog.dart';
import 'widgets/hub_legal_dialog.dart';
import 'widgets/hub_glass_chart_loading.dart';
import 'widgets/hub_entity_chip.dart';
import 'widgets/hub_interactive_glass.dart';
import 'widgets/hub_search_bar.dart';
import 'widgets/constructor_hub_theme.dart';
import 'widgets/f1_hub_app_header.dart';
import 'widgets/f1_hub_mobile_glass_app_bar.dart';
import 'widgets/f1_hub_mobile_nav_overlay.dart';
import 'widgets/next_race_hub_mini_card.dart';
import 'theme/hub_mobile_tuning.dart';
import 'widgets/f1_hub_image_fallback.dart';
import 'widgets/f1_module.dart';
import 'circuit_detail/circuit_card_metrics.dart';
import 'widgets/circuits_catalog_section.dart';
import 'theme/theme_service.dart';
import 'profile_favorites_service.dart';
import 'ai_strategist_prefs_service.dart';
import 'calendar_prefs_service.dart';
import 'last_podium_prefs_service.dart';
import 'detail_expansion_prefs_service.dart';
import 'display_settings.dart';
import 'display_settings_controller.dart';
import 'web_url_strategy.dart';
import 'theme/f1_ui_theme.dart';
import 'theme/hub_modal_overlays.dart';
import 'theme/hub_theme.dart';
import 'theme/hub_standings_metrics.dart';
import 'theme/hub_visual_language.dart';
import 'theme/hub_list_card_style.dart';
import 'widgets/hub_list_row_shell.dart';
import 'utils/driver_name_utils.dart';
import 'package:f1/utils/l10n_extension.dart';
import 'utils/l10n_lookups.dart';
import 'package:f1/l10n/app_localizations.dart';
import 'data/f1_asset_resolver.dart';
import 'data/team_standings_logo.dart';
import 'data/team_car_image.dart';
import 'pages/test_style_page.dart';
import 'data/repositories/race_repository.dart';
import 'data/local/hive/hive_boxes.dart';
import 'data/local/hive/hive_bootstrap.dart';
import 'browser_bridge.dart' as browser_bridge;
import 'open_meteo_api.dart';
import 'changelog_page.dart';
import 'circuit_detail/circuit_page.dart';
import 'coach_corner_data.dart';
import 'paddock_user_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'simulator/championship_simulator_page.dart';
import 'simulator/simulator_grid_config.dart';
import 'simulator/simulator_models.dart';
part 'f1_data.dart';
part 'widgets/my_paddock_widget.dart';
part 'widgets/recent_form_trend_card.dart';
part 'widgets/constructor_standings_cards.dart';
part 'widgets/driver_standings_cards.dart';

// Normalizes driver names for lookup (diacritics, special chars, etc.)
String _normalizeDriverLookupName(String value) {
  final replacements = <String, String>{
    'ß': 'ss',
    'ý': 'y',
    'ÿ': 'y',
    'ř': 'r',
    'š': 's',
    'č': 'c',
    'ž': 'z',
  };
  var normalized = value.trim().toLowerCase();
  replacements.forEach((source, target) {
    normalized = normalized.replaceAll(source, target);
  });
  return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// GP wins and podiums (race P1–P3 only) per driver from `drivers_standings_*.json` [rounds].
Map<String, ({int wins, int podiums})> _seasonGpWinsPodiumsFromStandingsRounds(
  List<dynamic> rounds,
) {
  final winC = <String, int>{};
  final podC = <String, int>{};
  for (final raw in rounds) {
    if (raw is! Map) continue;
    final dMap = raw['drivers'];
    if (dMap is! Map) continue;
    for (final e in dMap.entries) {
      final norm = _normalizeDriverLookupName(e.key.toString());
      if (norm.isEmpty) continue;
      final block = e.value;
      if (block is! Map) continue;
      final race = block['Race'];
      if (race is! Map) continue;
      final pr = race['position_finish'];
      final pos = pr is int ? pr : (pr is num ? pr.toInt() : null);
      if (pos == null || pos < 1) continue;
      if (pos == 1) winC[norm] = (winC[norm] ?? 0) + 1;
      if (pos <= 3) podC[norm] = (podC[norm] ?? 0) + 1;
    }
  }
  final keys = {...winC.keys, ...podC.keys};
  return {
    for (final k in keys)
      k: (wins: winC[k] ?? 0, podiums: podC[k] ?? 0),
  };
}

Driver _driverMergedFromStandingsRow({
  required Driver local,
  required double points,
  required String standingDriverName,
  required Map<String, dynamic> entry,
  required Map<String, ({int wins, int podiums})> roundDerived,
  required bool roundsPresentInDoc,
}) {
  final nk = _normalizeDriverLookupName(standingDriverName);
  final derived = roundDerived[nk] ?? (wins: 0, podiums: 0);
  final ew = entry['wins'];
  final ep = entry['podiums'];
  final explicitW = ew is num ? ew.toInt() : null;
  final explicitP = ep is num ? ep.toInt() : null;
  if (roundsPresentInDoc || explicitW != null || explicitP != null) {
    return Driver.copyWithPointsAndSeasonRaceStats(
      local,
      points,
      seasonRaceWins: explicitW ?? derived.wins,
      seasonRacePodiums: explicitP ?? derived.podiums,
    );
  }
  return Driver.copy(local, points);
}

abstract final class AppTheme {
  static FlexSchemeData get _defaultScheme =>
      F1TeamSchemes.schemeAt(F1TeamSchemes.defaultIndex);

  static ThemeData get lightTheme {
    final colors = _defaultScheme.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.light,
      primary: colors.primary,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
    );
    return _buildTheme(base: ThemeData.light().copyWith(colorScheme: scheme), isDark: false);
  }

  static ThemeData get darkTheme {
    final colors = _defaultScheme.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.dark,
      primary: colors.primary,
      secondary: colors.secondary,
      tertiary: colors.tertiary,
    );
    return _buildTheme(base: ThemeData.dark().copyWith(colorScheme: scheme), isDark: true);
  }

  static ThemeData _buildTheme({
    required ThemeData base,
    required bool isDark,
  }) {
    final scheme = base.colorScheme;
    final tokens = F1ThemeTokens.fromColorScheme(scheme);
    const regular = FontWeight.w400;
    const bold = FontWeight.w700;

    TextTheme textTheme = GoogleFonts.titilliumWebTextTheme(base.textTheme);

    TextStyle hubF1Wide(TextStyle? s) {
      return GoogleFonts.orbitron(
        textStyle: s,
        letterSpacing: HubVisualLanguage.letterSpacingF1Wide,
        fontWeight: bold,
      );
    }

    textTheme = textTheme.copyWith(
      displayLarge: hubF1Wide(textTheme.displayLarge),
      displayMedium: hubF1Wide(textTheme.displayMedium),
      displaySmall: hubF1Wide(textTheme.displaySmall),
      headlineLarge: hubF1Wide(textTheme.headlineLarge),
      headlineMedium: hubF1Wide(textTheme.headlineMedium),
      headlineSmall: hubF1Wide(textTheme.headlineSmall),
      titleLarge: hubF1Wide(textTheme.titleLarge),
      titleMedium: hubF1Wide(textTheme.titleMedium),
      titleSmall: GoogleFonts.titilliumWeb(
        textStyle: textTheme.titleSmall,
        fontWeight: bold,
      ),
      bodyLarge: GoogleFonts.titilliumWeb(textStyle: textTheme.bodyLarge, fontSize: 16),
      bodyMedium: GoogleFonts.titilliumWeb(textStyle: textTheme.bodyMedium, fontSize: 14),
      bodySmall: GoogleFonts.titilliumWeb(
        textStyle: textTheme.bodySmall,
        fontSize: 14,
        color: scheme.onSurface.withValues(alpha: 0.7),
      ),
      labelLarge: GoogleFonts.titilliumWeb(textStyle: textTheme.labelLarge),
      labelMedium: GoogleFonts.titilliumWeb(textStyle: textTheme.labelMedium),
      labelSmall: GoogleFonts.titilliumWeb(
        textStyle: textTheme.labelSmall,
        fontSize: 14,
        color: scheme.onSurface.withValues(alpha: 0.7),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: Colors.transparent,
      cardTheme: CardThemeData(
        color: tokens.panelStrong,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.35 : 0.08),
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.outline.withValues(alpha: 0.7)),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontWeight: bold,
          fontSize: 18,
          letterSpacing: HubVisualLanguage.letterSpacingF1Wide,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: tokens.panelStrong,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: GoogleFonts.titilliumWeb(
          fontWeight: bold,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: GoogleFonts.titilliumWeb(
          fontWeight: regular,
          letterSpacing: 0.6,
        ),
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.panelStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.outline.withValues(alpha: 0.8)),
        ),
        textStyle: GoogleFonts.titilliumWeb(fontWeight: regular),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: GoogleFonts.titilliumWeb(
          fontWeight: regular,
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: GoogleFonts.orbitron(
          fontWeight: bold,
          fontSize: 20,
          letterSpacing: HubVisualLanguage.letterSpacingF1Wide,
        ),
        contentTextStyle: GoogleFonts.titilliumWeb(fontWeight: regular, fontSize: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.14),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        style: ListTileStyle.list,
        dense: false,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: scheme.primary,
        collapsedTextColor: scheme.primary,
        iconColor: scheme.primary,
        collapsedIconColor: scheme.primary.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.outline.withValues(alpha: 0.7)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.outline.withValues(alpha: 0.7)),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.outline.withValues(alpha: 0.75),
        thickness: 1,
      ),
      extensions: [tokens],
    );
  }
}

F1ThemeTokens get _fallbackThemeTokens {
  final flexColors = F1TeamSchemes.schemeAt(F1TeamSchemes.defaultIndex).light;
  final scheme = ColorScheme.fromSeed(seedColor: flexColors.primary, brightness: Brightness.light);
  return F1ThemeTokens.fromColorScheme(scheme);
}

F1ThemeTokens _themeTokens(BuildContext context) =>
    Theme.of(context).extension<F1ThemeTokens>() ?? _fallbackThemeTokens;

LinearGradient _heroPanelGradient(BuildContext context) {
  final tokens = _themeTokens(context);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      tokens.heroStart.withValues(alpha: 0.4), // 60% transparant links
      tokens.heroEnd,
    ],
  );
}

/// Ambient glow: white base with subtle team-primary bloom (5–8% opacity)
/// in top-left and bottom-right for cards to "float".
Widget _buildAmbientBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final primary = scheme.primary.withValues(alpha: 0.06);
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          Colors.white,
          Colors.white,
          primary,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ),
    ),
  );
}

/// Paints subtle radial blooms at top-left and bottom-right for ambient glow.
class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({required this.topLeftGlow, required this.bottomRightGlow});
  final Color topLeftGlow;
  final Color bottomRightGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.45,
      colors: [topLeftGlow, Colors.transparent],
    );
    final bottomRight = RadialGradient(
      center: Alignment.bottomRight,
      radius: 1.45,
      colors: [bottomRightGlow, Colors.transparent],
    );
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = topLeft.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = bottomRight.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter old) =>
      topLeftGlow != old.topLeftGlow || bottomRightGlow != old.bottomRightGlow;
}

List<SimulatorDriverRef> _gridSimulatorDriverRoster() {
  final seen = <String>{};
  final roster = <SimulatorDriverRef>[];
  void addDrivers(List<Driver> list) {
    for (final d in list) {
      if (seen.add(d.name)) {
        roster.add(
          SimulatorDriverRef(
            number: d.number,
            name: d.name,
            team: d.team,
          ),
        );
      }
    }
  }

  for (final list in driversData.values) {
    addDrivers(list);
  }
  addDrivers(drivers2026);
  return roster;
}

String _driverPortraitAssetPathForGrid(String rawName) {
  return simulatorDriverPortraitPath(rawName, _gridSimulatorDriverRoster());
}

List<String> _driverPortraitPathCandidatesForGrid(String rawName) {
  return simulatorDriverPortraitPathCandidates(
    rawName,
    _gridSimulatorDriverRoster(),
  );
}

Widget _driverPortraitInitialsPlaceholder(
  BuildContext context,
  Driver driver,
  double size,
) {
  final scheme = Theme.of(context).colorScheme;
  final parts = driver.name
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0])
      .take(2)
      .join();
  final initials = parts.isEmpty ? '?' : parts.toUpperCase();
  return Container(
    width: size,
    height: size,
    color: scheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Text(
      initials,
      style: TextStyle(
        fontSize: (size * 0.32).clamp(10.0, 22.0),
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
  );
}

/// Headshot (`images/drivers/{slug}.png` → `/assets/images/drivers/` on web).
///
/// [useHero]: off for driver **standings** rows — avoids web/shell glitches; on
/// for team roster / compare where a flight is still useful.
Widget _buildDriverHeadshot({
  required BuildContext context,
  required Driver driver,
  required String heroTag,
  required double size,
  bool useHero = true,
}) {
  final paths = _driverPortraitPathCandidatesForGrid(driver.name);
  final face = Material(
    color: Colors.transparent,
    child: HubAssetImageChain(
      paths: paths,
      bundle: rootBundle,
      width: size,
      height: size,
      fit: BoxFit.cover,
      clipOval: true,
      fallback: _driverPortraitInitialsPlaceholder(context, driver, size),
    ),
  );
  if (!useHero) {
    return face;
  }
  return Hero(tag: heroTag, child: face);
}

Widget _buildStandingsLeadingGraphic(
  BuildContext context, {
  required bool isDriver,
  required Driver? driver,
  required Team? team,
  required String heroTag,
  required double flagSize,
  TextAlign textAlign = TextAlign.left,
}) {
  if (isDriver && driver != null) {
    return _buildDriverHeadshot(
      context: context,
      driver: driver,
      heroTag: heroTag,
      size: 40,
      useHero: false,
    );
  }
  if (team != null) {
    final logoPaths = teamStandingsLogoAssetPathCandidates(
      team.name,
      forLightTheme: Theme.of(context).brightness == Brightness.light,
    );
    if (logoPaths.isNotEmpty) {
      final tileBg = teamStandingsLogoBackgroundColor(team.name) ??
          Theme.of(context).colorScheme.surfaceContainerHigh;
      final brand = teamBrandPrimaryColorOrF1(team.name);
      // Use [rootBundle] so assets resolve even if an ancestor overrides
      // [DefaultAssetBundle] (e.g. some web / test embedders).
      Widget logoImage() => HubAssetImageChain(
            paths: logoPaths,
            bundle: rootBundle,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            glassFallbackAccent: brand,
            fallback: const SizedBox(width: 30, height: 30),
          );
      return SizedBox(
        width: 40,
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(kTeamStandingsLogoTileRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Center(child: logoImage()),
          ),
        ),
      );
    }
    return _buildFlagHero(
      tag: heroTag,
      flag: team.flag,
      fontSize: flagSize,
      textAlign: textAlign,
    );
  }
  return const SizedBox(width: 40, height: 40);
}

String _driverFlagHeroTag(Driver driver, {String source = 'default'}) =>
    'driver-flag:$source:${driver.name}';

String _teamFlagHeroTag(Team team, {String source = 'default'}) =>
    'team-flag:$source:${team.name}';

String _raceFlagHeroTag(Race race, {String source = 'default'}) =>
    'race-flag:$source:${race.name}';

Widget _buildFlagHero({
  required String tag,
  required String flag,
  required double fontSize,
  TextAlign textAlign = TextAlign.center,
}) {
  return Hero(
    tag: tag,
    child: Material(
      color: Colors.transparent,
      child: Text(
        flag,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, height: 1),
      ),
    ),
  );
}

Widget _buildGlyphIcon(String glyph, {double size = 18}) {
  return Text(
    glyph,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: size, height: 1),
  );
}

/// Animated weather icon: sunny=360° rotation, clouds=horizontal drift, rain=vertical slide.
class _AnimatedWeatherIcon extends StatefulWidget {
  const _AnimatedWeatherIcon({
    required this.isRain,
    required this.isCloudy,
    required this.color,
    this.size = 20,
  });

  final bool isRain;
  final bool isCloudy;
  final Color color;
  final double size;

  @override
  State<_AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<_AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isRain) {
      return _RainAnimation(color: widget.color, size: widget.size);
    }
    if (widget.isCloudy) {
      return _CloudyAnimation(
        color: widget.color,
        size: widget.size,
        controller: _controller,
      );
    }
    return _SunnyAnimation(
      color: widget.color,
      size: widget.size,
      controller: _controller,
    );
  }
}

class _CloudyAnimation extends StatelessWidget {
  const _CloudyAnimation({
    required this.color,
    required this.size,
    required this.controller,
  });

  final Color color;
  final double size;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Transform.translate(
        offset: Offset(4 * (controller.value * 2 % 1) - 2, 0),
        child: Icon(Icons.cloud, color: color, size: size),
      ),
    );
  }
}

class _SunnyAnimation extends StatelessWidget {
  const _SunnyAnimation({
    required this.color,
    required this.size,
    required this.controller,
  });

  final Color color;
  final double size;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.rotate(
        angle: controller.value * 2 * 3.14159,
        child: Icon(Icons.wb_sunny, color: color, size: size),
      ),
    );
  }
}

class _RainAnimation extends StatefulWidget {
  const _RainAnimation({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<_RainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: 0.3 + 0.7 * (1 - (_controller.value * 2 % 1).abs()),
        child: Transform.translate(
          offset: Offset(0, 4 * (_controller.value * 2 % 1)),
          child: Icon(Icons.umbrella, color: widget.color, size: widget.size),
        ),
      ),
    );
  }
}

/// Wraps a child with a subtle lift (scale 1.02) effect on tap/hover.
class _LiftOnTap extends StatefulWidget {
  const _LiftOnTap({required this.child});

  final Widget child;

  @override
  State<_LiftOnTap> createState() => _LiftOnTapState();
}

class _LiftOnTapState extends State<_LiftOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform(
            transform: Matrix4.identity()..scale(_scale.value),
            alignment: Alignment.center,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Pulsing AI/Brain icon in Team Primary Color for the AI Strategist card.
class _PulsingAIIcon extends StatefulWidget {
  const _PulsingAIIcon({required this.color, this.size = 28});

  final Color color;
  final double size;

  @override
  State<_PulsingAIIcon> createState() => _PulsingAIIconState();
}

class _PulsingAIIconState extends State<_PulsingAIIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Icon(
          Icons.psychology_rounded,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}

/// AI Strategist card: Teammate Battle, Coach's Corner (5 lines), Sentiment Tracker.
/// Historical/seasonal focus. Tappable to open the full AI chat overlay.
class _AIStrategistCard extends StatefulWidget {
  const _AIStrategistCard({
    required this.race,
    required this.strategistPrefs,
    required this.onTap,
  });

  final Race race;
  final AiStrategistPrefs strategistPrefs;
  final VoidCallback onTap;

  @override
  State<_AIStrategistCard> createState() => _AIStrategistCardState();
}

class _AIStrategistCardState extends State<_AIStrategistCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late AnimationController _coachPulseController;
  late Animation<double> _coachPulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.2, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _coachPulseOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _coachPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _coachPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final favorites = context.watch<ProfileFavoritesNotifier>().value;
    final favoriteDriver = favorites.favoriteDriver ?? 'Alonso';
    final favoriteTeam = favorites.favoriteTeam ?? 'Aston Martin';

    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: F1Module(
        fillWidth: true,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        borderRadius: 20,
        backgroundColor: scheme.surface,
        showFadingBorder: true,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PulsingAIIcon(color: primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.ai_strategist_title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.open_in_new, size: 18, color: primary.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 16),
            if (!widget.strategistPrefs.hideTeambattle) ...[
              _buildTeammateBattleSection(context, theme, favoriteDriver),
              const SizedBox(height: 16),
            ],
            if (!widget.strategistPrefs.hideCoachCorner) ...[
              _buildCoachCornerSection(theme, primary),
              const SizedBox(height: 16),
            ],
            if (!widget.strategistPrefs.hideTeamVibe) ...[
              Text(
                context.l10n.ai_sentiment_label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const sentimentValue = 0.72;
                    final indicatorLeft = (constraints.maxWidth * sentimentValue) - 4;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                theme.colorScheme.error,
                                theme.colorScheme.tertiary,
                                theme.colorScheme.primary,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: indicatorLeft - 6,
                          top: -9,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return Container(
                                width: 20 + (_pulseScale.value * 12),
                                height: 20 + (_pulseScale.value * 12),
                                margin: EdgeInsets.all((10 - (_pulseScale.value * 6)).clamp(0.0, 10.0)),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withValues(alpha: _pulseOpacity.value * 0.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: _pulseOpacity.value),
                                      blurRadius: 8 + (_pulseScale.value * 4),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: indicatorLeft,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(alpha: 0.25),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _sentimentSummary(favoriteTeam),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeammateBattleSection(
    BuildContext context,
    ThemeData theme,
    String favoriteDriver,
  ) {
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final fav = _findDriver2026ByName(favoriteDriver);
    if (fav == null) return const SizedBox.shrink();
    final teammate = _getTeammate2026(fav);
    if (teammate == null) return const SizedBox.shrink();

    final (favWins, teWins, gapSec) = _teammateQualifyingStats(fav, teammate);
    final gapStr = gapSec < 0
        ? '${gapSec.toStringAsFixed(3)}s'
        : '+${gapSec.toStringAsFixed(3)}s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events_outlined, size: 16, color: primary),
            const SizedBox(width: 6),
            Text(
              context.l10n.ai_teammate_battle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(_driverPath(fav)),
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: secondary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Text(fav.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fav.name.split(' ').last,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$favWins - $teWins',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: secondary,
                    ),
                  ),
                  Text(
                    context.l10n.ai_qualifying_duel,
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondary.withValues(alpha: 0.15),
                      border: Border.all(color: secondary.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(_driverPath(teammate)),
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: secondary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Text(teammate.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            teammate.name.split(' ').last,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.swap_horiz, size: 14, color: secondary),
            const SizedBox(width: 4),
            Text(
              context.l10n.ai_avg_gap,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              gapStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.ai_teammate_insight(
            fav.name.split(' ').last,
            teammate.name.split(' ').last,
          ),
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCoachCornerSection(ThemeData theme, Color primary) {
    final l10n = context.l10n;
    final onSurface = theme.colorScheme.onSurface;
    final lines = coachCornerFiveLines(
      widget.race.name,
      Localizations.localeOf(context).languageCode,
    );
    assert(lines.length == 5, 'Coach corner expects exactly 5 lines per circuit');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: primary),
            const SizedBox(width: 6),
            Text(
              l10n.ai_coach_title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _coachPulseController,
          builder: (context, _) {
            final opacity = _coachPulseOpacity.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _coachCornerPulseRow(
                  opacity,
                  primary,
                  onSurface,
                  Icons.flag_outlined,
                  lines[0],
                ),
                const SizedBox(height: 6),
                _coachCornerPulseRow(
                  opacity,
                  primary,
                  onSurface,
                  Icons.insights_outlined,
                  lines[1],
                ),
                const SizedBox(height: 6),
                _coachCornerPulseRow(
                  opacity,
                  primary,
                  onSurface,
                  Icons.wb_cloudy_outlined,
                  lines[2],
                ),
                const SizedBox(height: 6),
                _coachCornerPulseRow(
                  opacity,
                  primary,
                  onSurface,
                  Icons.sports_motorsports_outlined,
                  lines[3],
                ),
                const SizedBox(height: 6),
                _coachCornerPulseRow(
                  opacity,
                  primary,
                  onSurface,
                  Icons.event_note_outlined,
                  lines[4],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _coachCornerPulseRow(
    double opacity,
    Color primary,
    Color onSurface,
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: opacity,
          child: Icon(icon, size: 14, color: primary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _sentimentSummary(String team) {
    if (team.toLowerCase().contains('mercedes')) {
      return context.l10n.ai_sentiment_mercedes_positive;
    }
    return context.l10n.ai_sentiment_generic_positive;
  }

}

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _themeTokens(context);
    final baseColor = tokens.panel.withValues(alpha: 0.96);
    final highlightColor = tokens.panelStrong.withValues(alpha: 0.98);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmer = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.2 + (shimmer * 2), -0.25),
              end: Alignment(0.2 + (shimmer * 2), 0.25),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.15, 0.35, 0.55],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildStandingsSkeleton(BuildContext context, {required bool isDriver}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 10),
    itemCount: 8,
    itemBuilder: (context, index) {
      final tokens = Theme.of(context).extension<F1ThemeTokens>();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: F1Module(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: tokens?.panelStrong ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: 12,
          borderWidth: 2,
          boxShadow: isDark
              ? null
              : [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
          child: Row(
            children: [
              const SkeletonBox(
                width: 24,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              const SizedBox(width: 16),
              const SkeletonBox(
                width: 18,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: index.isEven ? 148 : 172,
                      height: 14,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    if (isDriver) ...[
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: index.isEven ? 82 : 96,
                        height: 10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SkeletonBox(
                width: index.isEven ? 72 : 64,
                height: 14,
                borderRadius: BorderRadius.circular(7),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSessionResultsSkeleton(
  BuildContext context, {
  required Race race,
}) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _themeTokens(context).panelStrong,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _themeTokens(context).outline.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: index.isEven ? 154 : 172,
                  height: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
                const SizedBox(height: 14),
                const SkeletonBox(height: 38),
                const SizedBox(height: 10),
                ...List.generate(
                  3,
                  (rowIndex) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const SkeletonBox(
                          width: 30,
                          height: 12,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SkeletonBox(
                            width: rowIndex.isEven ? 146 : 126,
                            height: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SkeletonBox(
                          width: 64,
                          height: 12,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}

Widget _buildSessionWidgetSkeleton(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _hubReadableAccent(context),
            fontFamily: 'TitilliumWeb',
          ),
        ),
        const SizedBox(height: 10),
        const SkeletonBox(height: 34),
        const SizedBox(height: 10),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const SkeletonBox(
                  width: 34,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SkeletonBox(
                    width: index.isEven ? 150 : 132,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                const SkeletonBox(
                  width: 68,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.black12,
        ),
      ],
    ),
  );
}

Widget _buildWeatherSkeletonRows(BuildContext context) {
  Widget skeletonRow(IconData icon, double valueWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _hubReadableAccent(context)),
          const SizedBox(width: 12),
          Expanded(
            child: SkeletonBox(
              width: 118,
              height: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          SkeletonBox(
            width: valueWidth,
            height: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  return Column(
    children: [
      skeletonRow(Icons.thermostat, 42),
      skeletonRow(Icons.umbrella, 36),
      skeletonRow(Icons.air, 52),
      skeletonRow(Icons.water_drop, 38),
      const SizedBox(height: 8),
    ],
  );
}

String _formatWeatherTimeLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatWeatherTimestampLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day-$month ${_formatWeatherTimeLabel(timestamp)}';
}

String _normalizeSessionName(String? raw) {
  final s = raw?.trim().toLowerCase() ?? '';
  switch (s) {
    case 'practice 1': return 'Practice 1';
    case 'practice 2': return 'Practice 2';
    case 'practice 3': return 'Practice 3';
    case 'qualifying': return 'Qualifying';
    case 'sprint shootout':
    case 'sprint qualifying': return 'Sprint Qualifying';
    case 'sprint': return 'Sprint';
    case 'race': return 'Race';
    case 'day 1': return 'Day 1';
    case 'day 2': return 'Day 2';
    default: return raw?.trim() ?? '';
  }
}

/// colorKey: 'success'|'warning'|'error' — resolved from F1ThemeTokens at build time.
@immutable
class _TrackFlagState {
  final String labelKey;
  final String colorKey;

  const _TrackFlagState({required this.labelKey, required this.colorKey});
}

Color _trackFlagColor(_TrackFlagState state, F1ThemeTokens tokens) {
  switch (state.colorKey) {
    case 'success': return tokens.statusSuccess;
    case 'warning': return tokens.statusWarning;
    case 'error': return tokens.statusError;
    default: return tokens.outline;
  }
}

@immutable
class _TrackFlagContext {
  final _TrackFlagState state;
  final String? message;

  const _TrackFlagContext({required this.state, this.message});
}

@immutable
class _WeekendWeatherData {
  final Map<String, List<Map<String, dynamic>>> weatherBySession;
  final Map<String, List<Map<String, dynamic>>> lapTimelineBySession;

  const _WeekendWeatherData({
    required this.weatherBySession,
    required this.lapTimelineBySession,
  });
}

const _trackClearState = _TrackFlagState(
  labelKey: 'track_flag_green',
  colorKey: 'success',
);

const _trackYellowState = _TrackFlagState(
  labelKey: 'track_flag_yellow',
  colorKey: 'warning',
);

const _trackDoubleYellowState = _TrackFlagState(
  labelKey: 'track_flag_double_yellow',
  colorKey: 'warning',
);

const _trackRedState = _TrackFlagState(
  labelKey: 'track_flag_red',
  colorKey: 'error',
);

String? _trackFlagScopeKey(Map<String, dynamic> message) {
  final scope = message['scope']?.toString().trim().toUpperCase() ?? '';
  if (scope == 'DRIVER') {
    return null;
  }
  if (scope == 'SECTOR') {
    final sector = message['sector'];
    return 'sector:${sector ?? 'unknown'}';
  }
  if (scope == 'TRACK' || scope.isEmpty) {
    return 'track';
  }
  return scope.toLowerCase();
}

bool _isSessionFlagMessage(Map<String, dynamic> message, String sessionName) {
  final category = message['category']?.toString().trim().toUpperCase() ?? '';
  final flag = message['flag']?.toString().trim().toUpperCase() ?? '';
  final session = _normalizeSessionName(message['sessionName']);
  return category == 'FLAG' &&
      flag.isNotEmpty &&
      session == _normalizeSessionName(sessionName);
}

int _trackFlagSeverity(String flag) {
  switch (flag.trim().toUpperCase()) {
    case 'RED':
      return 3;
    case 'DOUBLE YELLOW':
      return 2;
    default:
      return flag.toUpperCase().contains('YELLOW') ? 1 : 0;
  }
}

_TrackFlagContext _resolveTrackFlagContext(
  DateTime? timestamp,
  List<Map<String, dynamic>> messages,
  String sessionName,
) {
  if (timestamp == null) {
    return const _TrackFlagContext(state: _trackClearState);
  }

  final relevantMessages =
      messages
          .where((message) => _isSessionFlagMessage(message, sessionName))
          .toList()
        ..sort((a, b) {
          final aTime = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
          final bTime = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
          if (aTime == null && bTime == null) {
            return 0;
          }
          if (aTime == null) {
            return 1;
          }
          if (bTime == null) {
            return -1;
          }
          return aTime.compareTo(bTime);
        });

  if (relevantMessages.isEmpty) {
    return const _TrackFlagContext(state: _trackClearState);
  }

  final activeFlags = <String, Map<String, dynamic>>{};
  String? lastSignalFlag;

  for (final message in relevantMessages) {
    final messageTime = DateTime.tryParse(
      message['timestampUtc']?.toString() ?? '',
    );
    if (messageTime == null || messageTime.isAfter(timestamp)) {
      break;
    }

    final scopeKey = _trackFlagScopeKey(message);
    if (scopeKey == null) {
      continue;
    }

    final flag = message['flag']?.toString().trim().toUpperCase() ?? '';
    if (flag.isEmpty) {
      continue;
    }

    lastSignalFlag = flag;
    if (flag == 'CLEAR' || flag == 'GREEN') {
      activeFlags.remove(scopeKey);
      continue;
    }

    if (flag == 'RED' || flag.contains('YELLOW')) {
      activeFlags[scopeKey] = message;
    }
  }

  if (activeFlags.isNotEmpty) {
    final prioritizedActiveFlags = activeFlags.values.toList(growable: false)
      ..sort((a, b) {
        final flagA = a['flag']?.toString() ?? '';
        final flagB = b['flag']?.toString() ?? '';
        final severityCompare = _trackFlagSeverity(
          flagB,
        ).compareTo(_trackFlagSeverity(flagA));
        if (severityCompare != 0) {
          return severityCompare;
        }

        final timeA = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
        final timeB = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
        if (timeA != null && timeB != null) {
          return timeB.compareTo(timeA);
        }
        if (timeA == null && timeB == null) {
          return 0;
        }
        return timeA == null ? 1 : -1;
      });

    final activeMessage = prioritizedActiveFlags.first;
    final activeFlag =
        activeMessage['flag']?.toString().trim().toUpperCase() ?? '';
    final activeReason = activeMessage['message']?.toString().trim();
    if (activeFlag == 'RED') {
      return _TrackFlagContext(state: _trackRedState, message: activeReason);
    }
    if (activeFlag == 'DOUBLE YELLOW') {
      return _TrackFlagContext(
        state: _trackDoubleYellowState,
        message: activeReason,
      );
    }
    if (activeFlag.contains('YELLOW')) {
      return _TrackFlagContext(state: _trackYellowState, message: activeReason);
    }
  }
  if (lastSignalFlag == 'GREEN' || lastSignalFlag == 'CLEAR') {
    return const _TrackFlagContext(state: _trackClearState);
  }

  return const _TrackFlagContext(state: _trackClearState);
}

int? _resolveLapFromTimeline(
  DateTime? timestamp,
  List<Map<String, dynamic>> lapTimeline,
) {
  if (timestamp == null || lapTimeline.isEmpty) {
    return null;
  }

  int? latestLap;
  final sortedMarkers = List<Map<String, dynamic>>.from(lapTimeline)
    ..sort((a, b) {
      final aTime = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
      if (aTime == null && bTime == null) {
        return 0;
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return aTime.compareTo(bTime);
    });

  for (final marker in sortedMarkers) {
    final markerTime = DateTime.tryParse(
      marker['timestampUtc']?.toString() ?? '',
    );
    if (markerTime == null || markerTime.isAfter(timestamp)) {
      break;
    }

    final lap = _asInt(marker['lap']);
    if (lap != null && lap > 0) {
      latestLap = lap;
    }
  }

  return latestLap;
}

int? _resolveCurrentSessionLap(
  DateTime? timestamp,
  List<Map<String, dynamic>> lapTimeline,
  List<Map<String, dynamic>> messages,
  String sessionName,
) {
  if (timestamp == null) {
    return null;
  }

  final timelineLap = _resolveLapFromTimeline(timestamp, lapTimeline);
  if (timelineLap != null) {
    return timelineLap;
  }

  int? latestLap;
  final relevantMessages =
      messages
          .where(
            (message) =>
                _normalizeSessionName(message['sessionName']) ==
                _normalizeSessionName(sessionName),
          )
          .toList()
        ..sort((a, b) {
          final aTime = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
          final bTime = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
          if (aTime == null && bTime == null) {
            return 0;
          }
          if (aTime == null) {
            return 1;
          }
          if (bTime == null) {
            return -1;
          }
          return aTime.compareTo(bTime);
        });

  for (final message in relevantMessages) {
    final messageTime = DateTime.tryParse(
      message['timestampUtc']?.toString() ?? '',
    );
    if (messageTime == null || messageTime.isAfter(timestamp)) {
      break;
    }

    final lap = _asInt(message['lap']);
    if (lap != null && lap > 0) {
      latestLap = lap;
    }
  }

  return latestLap;
}

double _normalizeWindDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

String _windDirectionLabel(int? degrees) {
  if (degrees == null) {
    return '-';
  }
  const labels = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final normalized = _normalizeWindDegrees(degrees.toDouble());
  final index = ((normalized + 22.5) ~/ 45) % labels.length;
  return labels[index];
}

double? _lerpNullableDouble(double? start, double? end, double t) {
  if (start == null && end == null) {
    return null;
  }
  if (start == null) {
    return end;
  }
  if (end == null) {
    return start;
  }
  return start + ((end - start) * t);
}

double? _lerpDegrees(int? start, int? end, double t) {
  if (start == null && end == null) {
    return null;
  }
  if (start == null) {
    return end?.toDouble();
  }
  if (end == null) {
    return start.toDouble();
  }
  final delta = (((end - start) + 540) % 360) - 180;
  return _normalizeWindDegrees(start + (delta * t).toDouble());
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

String _trimTrailingZero(String value) {
  if (!value.contains('.')) {
    return value;
  }
  return value
      .replaceFirst(RegExp(r'\.0+$'), '')
      .replaceFirst(RegExp(r'(\.[1-9]*)0+$'), r'$1');
}

bool _isRaceControlPenaltyServedMessage(String? rawMessage) {
  final message = rawMessage?.trim().toUpperCase() ?? '';
  return message.contains('PENALTY SERVED');
}

String _formatTyreCompound(String? compound) {
  switch ((compound ?? '').toUpperCase()) {
    case 'SOFT':
      return 'Soft';
    case 'MEDIUM':
      return 'Medium';
    case 'HARD':
      return 'Hard';
    case 'INTERMEDIATE':
      return 'Inter';
    case 'WET':
      return 'Wet';
    default:
      return '-';
  }
}

/// OpenF1 weather JSON uses `date`, `air_temperature`, `wind_speed` (m/s), …;
/// [CircuitWeatherPlaybackCard] expects `timestampUtc`, `airTemperatureC`, `windSpeed` (km/h).
Map<String, dynamic> _normalizeWeatherPlaybackSample(Map<String, dynamic> raw) {
  double? readNum(String a, String b) {
    final v = raw[a] ?? raw[b];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  var ts = raw['timestampUtc']?.toString();
  if (ts == null || ts.isEmpty) {
    ts = raw['date']?.toString();
  }
  if (ts == null || ts.isEmpty) {
    ts = raw['timestamp']?.toString();
  }
  ts ??= '';

  final air = readNum('airTemperatureC', 'air_temperature');
  final track = readNum('trackTemperatureC', 'track_temperature');
  final humidity = readNum('humidity', 'humidity');
  final rain = readNum('rainfall', 'rainfall') ?? 0;
  final pressure = readNum('pressure', 'pressure');

  double windKmh;
  if (raw.containsKey('wind_speed') && raw['wind_speed'] != null) {
    final ms = readNum('windSpeed', 'wind_speed') ?? 0;
    windKmh = ms * 3.6;
  } else {
    windKmh = readNum('windSpeed', 'wind_speed') ?? 0;
  }

  final windDir = _asInt(raw['windDirection'] ?? raw['wind_direction']);

  return <String, dynamic>{
    'timestampUtc': ts,
    'airTemperatureC': ?air,
    'trackTemperatureC': ?track,
    'humidity': ?humidity,
    'rainfall': rain,
    'pressure': ?pressure,
    'windSpeed': windKmh,
    'windDirection': ?windDir,
  };
}

List<Map<String, dynamic>> _buildInterpolatedWeatherSamples(
  List<Map<String, dynamic>> samples,
) {
  final normalized = samples
      .map(
        (m) => _normalizeWeatherPlaybackSample(
          m.map((k, v) => MapEntry(k.toString(), v)),
        ),
      )
      .where(
        (m) =>
            DateTime.tryParse(m['timestampUtc']?.toString() ?? '') != null,
      )
      .toList();

  if (normalized.length < 2) {
    return List<Map<String, dynamic>>.from(normalized);
  }

  final sortedSamples = List<Map<String, dynamic>>.from(normalized)
    ..sort((a, b) {
      final aTime = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
      if (aTime == null && bTime == null) {
        return 0;
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return aTime.compareTo(bTime);
    });

  final interpolated = <Map<String, dynamic>>[];
  for (var index = 0; index < sortedSamples.length - 1; index++) {
    final current = sortedSamples[index];
    final next = sortedSamples[index + 1];
    final currentTime = DateTime.tryParse(current['timestampUtc']?.toString() ?? '');
    final nextTime = DateTime.tryParse(next['timestampUtc']?.toString() ?? '');
    if (currentTime == null || nextTime == null || !nextTime.isAfter(currentTime)) {
      interpolated.add(current);
      continue;
    }

    interpolated.add(current);
    final totalMillis = nextTime.difference(currentTime).inMilliseconds;
    final minutesBetween = nextTime.difference(currentTime).inMinutes;
    if (minutesBetween <= 1) {
      continue;
    }

    for (var minute = 1; minute < minutesBetween; minute++) {
      final targetTime = currentTime.add(Duration(minutes: minute));
      final t = (targetTime.difference(currentTime).inMilliseconds) / totalMillis;
      interpolated.add({
        'timestampUtc': targetTime.toUtc().toIso8601String(),
        'airTemperatureC': _lerpNullableDouble(
          (current['airTemperatureC'] as num?)?.toDouble(),
          (next['airTemperatureC'] as num?)?.toDouble(),
          t,
        ),
        'trackTemperatureC': _lerpNullableDouble(
          (current['trackTemperatureC'] as num?)?.toDouble(),
          (next['trackTemperatureC'] as num?)?.toDouble(),
          t,
        ),
        'humidity': _lerpNullableDouble(
          (current['humidity'] as num?)?.toDouble(),
          (next['humidity'] as num?)?.toDouble(),
          t,
        ),
        'rainfall': _lerpNullableDouble(
          (current['rainfall'] as num?)?.toDouble(),
          (next['rainfall'] as num?)?.toDouble(),
          t,
        ),
        'pressure': _lerpNullableDouble(
          (current['pressure'] as num?)?.toDouble(),
          (next['pressure'] as num?)?.toDouble(),
          t,
        ),
        'windSpeed': _lerpNullableDouble(
          (current['windSpeed'] as num?)?.toDouble(),
          (next['windSpeed'] as num?)?.toDouble(),
          t,
        ),
        // windDirection: always interpolate shortest path, handle nulls gracefully
        'windDirection': _lerpDegrees(
          current['windDirection'] as int?,
          next['windDirection'] as int?,
          t,
        )?.round(),
        'interpolated': true,
      });
    }
  }

  interpolated.add(sortedSamples.last);
  return interpolated;
}

class _WeatherMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WeatherMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _hubReadableAccent(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'TitilliumWeb',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'TitilliumWeb',
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

class _WeatherTrackOverlayPainter extends CustomPainter {
  final Color primaryColor;
  final Color rainColor;
  final double phase;
  final double windSpeed;
  final double windDirectionDegrees;
  final double rainIntensity;

  const _WeatherTrackOverlayPainter({
    required this.primaryColor,
    required this.rainColor,
    required this.phase,
    required this.windSpeed,
    required this.windDirectionDegrees,
    required this.rainIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final directionRadians = windDirectionDegrees * (math.pi / 180);
    final windVector = Offset(
      math.cos(directionRadians),
      math.sin(directionRadians),
    );
    final normalVector = Offset(-windVector.dy, windVector.dx);
    final trackBounds = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.62,
    );
    final flowLength = math.sqrt(
      (trackBounds.width * trackBounds.width) +
          (trackBounds.height * trackBounds.height),
    );

    final particleCount = (20 + (windSpeed * 1.35)).round().clamp(20, 42);
    final baseOpacity = (0.22 + (windSpeed / 38)).clamp(0.22, 0.5);
    final speedFactor = 0.11 + (windSpeed / 260);

    for (var index = 0; index < particleCount; index++) {
      final lane = index % 5;
      final progressSeed = ((index * 37) % 100) / 100;
      final spreadSeed = (((index * 29) % 100) / 100) - 0.5;
      final wave = math.sin((phase * math.pi * 2.4) + index) * 4;
      final flowProgress = ((progressSeed + (phase * speedFactor)) % 1.0) - 0.5;
      final travel = flowProgress * flowLength * 1.08;
      final lateral =
          ((lane - 2) * trackBounds.height * 0.16) + (spreadSeed * 26) + wave;
      final particleCenter = Offset(
        center.dx + (windVector.dx * travel) + (normalVector.dx * lateral),
        center.dy + (windVector.dy * travel) + (normalVector.dy * lateral),
      );
      final particleSize = 7.0 + (((index * 13) % 7) / 7) * 5;
      final particlePaint = Paint()
        ..color = primaryColor.withValues(
          alpha: (baseOpacity + ((((index * 17) % 100) / 100) * 0.18)).clamp(
            0.22,
            0.62,
          ),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      _drawWindArrowParticle(
        canvas,
        particleCenter,
        directionRadians,
        particleSize,
        particlePaint,
      );
    }

    if (rainIntensity <= 0) {
      return;
    }

    final streakCount = (18 + (rainIntensity * 6)).round().clamp(18, 72);
    final rainPaint = Paint()
      ..color = rainColor.withValues(
        alpha: (0.18 + (rainIntensity * 0.08)).clamp(0.2, 0.55),
      )
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < streakCount; index++) {
      final xSeed = (index * 37.0) % size.width;
      final ySeed =
          ((index * 53.0) + (phase * size.height * 1.8)) % size.height;
      final start = Offset(xSeed, ySeed);
      final end = Offset(
        start.dx + (-7 - (windVector.dx * 10)),
        start.dy + (14 + (windVector.dy * 6)),
      );
      canvas.drawLine(start, end, rainPaint);
    }
  }

  void _drawWindArrowParticle(
    Canvas canvas,
    Offset center,
    double rotation,
    double size,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(-size * 0.6, 0)
      ..lineTo(size * 0.45, 0)
      ..moveTo(size * 0.05, -size * 0.32)
      ..lineTo(size * 0.45, 0)
      ..lineTo(size * 0.05, size * 0.32);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeatherTrackOverlayPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.windSpeed != windSpeed ||
        oldDelegate.windDirectionDegrees != windDirectionDegrees ||
        oldDelegate.rainIntensity != rainIntensity ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.rainColor != rainColor;
  }
}

class CircuitWeatherPlaybackCard extends StatefulWidget {
  final Race race;
  final List<Map<String, dynamic>> weatherSamples;
  final List<Map<String, dynamic>> lapTimeline;
  final List<Map<String, dynamic>> raceControlMessages;
  final String sessionName;
  /// When false, omits the outer card container so parent F1Module provides styling.
  final bool embedInCard;

  const CircuitWeatherPlaybackCard({
    required this.race,
    required this.weatherSamples,
    this.lapTimeline = const <Map<String, dynamic>>[],
    this.raceControlMessages = const <Map<String, dynamic>>[],
    this.sessionName = 'Race',
    this.embedInCard = true,
    super.key,
  });

  @override
  State<CircuitWeatherPlaybackCard> createState() =>
      _CircuitWeatherPlaybackCardState();
}

class _CircuitWeatherPlaybackCardState extends State<CircuitWeatherPlaybackCard>
  with TickerProviderStateMixin {
  static const Duration _autoLoopAnimationDuration = Duration(seconds: 5);

  late final AnimationController _controller;
  late List<Map<String, dynamic>> _resolvedSamples;
  Timer? _autoLoopTimer;
  double _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _resolvedSamples = _buildInterpolatedWeatherSamples(widget.weatherSamples);
    _startAutoLoop();
  }

  AnimationController? _autoLoopController;
  void _startAutoLoop() {
    _autoLoopTimer?.cancel();
    _autoLoopController?.dispose();
    _autoLoopController = null;
    if (_resolvedSamples.length <= 1) {
      return;
    }

    // Find the next sample at least 5 minutes ahead
    final currentIndex = _selectedIndex.round();
    final currentTime = DateTime.tryParse(_resolvedSamples[currentIndex]['timestampUtc']?.toString() ?? '');
    if (currentTime == null) return;

    int nextIndex = currentIndex;
    for (int i = currentIndex + 1; i < _resolvedSamples.length; i++) {
      final t = DateTime.tryParse(_resolvedSamples[i]['timestampUtc']?.toString() ?? '');
      if (t != null && t.difference(currentTime).inMinutes >= 5) {
        nextIndex = i;
        break;
      }
    }
    // If no next 5-min sample, loop to start
    if (nextIndex == currentIndex) {
      nextIndex = 0;
    }

    final double from = _selectedIndex;
    final double to = nextIndex.toDouble();
    final controller = AnimationController(
      vsync: this,
      duration: _autoLoopAnimationDuration,
    );
    _autoLoopController = controller;
    final animation = Tween<double>(begin: from, end: to).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    controller.addListener(() {
      if (!mounted) return;
      setState(() {
        _selectedIndex = animation.value;
      });
    });
    controller.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _autoLoopController = null;
        // Start next interval
        _startAutoLoop();
      }
    });
    controller.forward();
    _autoLoopTimer = Timer(_autoLoopAnimationDuration, () {}); // Dummy timer to keep reference
  }

  DateTime? _interpolateDateTime(DateTime? start, DateTime? end, double t) {
    if (start == null && end == null) {
      return null;
    }
    if (start == null) {
      return end;
    }
    if (end == null) {
      return start;
    }

    final deltaMilliseconds = end.difference(start).inMilliseconds;
    return start.add(Duration(milliseconds: (deltaMilliseconds * t).round()));
  }

  Map<String, dynamic> _resolvedPlaybackSample() {
    if (_resolvedSamples.length <= 1) {
      return _resolvedSamples.first;
    }

    final lowerIndex = _selectedIndex.floor().clamp(
      0,
      _resolvedSamples.length - 1,
    );
    final upperIndex = _selectedIndex.ceil().clamp(
      0,
      _resolvedSamples.length - 1,
    );
    final lowerSample = _resolvedSamples[lowerIndex];
    final upperSample = _resolvedSamples[upperIndex];

    if (lowerIndex == upperIndex) {
      return lowerSample;
    }

    final t = (_selectedIndex - lowerIndex).clamp(0.0, 1.0);
    final lowerTime = DateTime.tryParse(
      lowerSample['timestampUtc']?.toString() ?? '',
    );
    final upperTime = DateTime.tryParse(
      upperSample['timestampUtc']?.toString() ?? '',
    );
    final interpolatedTime = _interpolateDateTime(lowerTime, upperTime, t);

    return {
      'timestampUtc':
          interpolatedTime?.toUtc().toIso8601String() ??
          lowerSample['timestampUtc']?.toString(),
      'airTemperatureC': _lerpNullableDouble(
        (lowerSample['airTemperatureC'] as num?)?.toDouble(),
        (upperSample['airTemperatureC'] as num?)?.toDouble(),
        t,
      ),
      'trackTemperatureC': _lerpNullableDouble(
        (lowerSample['trackTemperatureC'] as num?)?.toDouble(),
        (upperSample['trackTemperatureC'] as num?)?.toDouble(),
        t,
      ),
      'humidity': _lerpNullableDouble(
        (lowerSample['humidity'] as num?)?.toDouble(),
        (upperSample['humidity'] as num?)?.toDouble(),
        t,
      ),
      'rainfall': _lerpNullableDouble(
        (lowerSample['rainfall'] as num?)?.toDouble(),
        (upperSample['rainfall'] as num?)?.toDouble(),
        t,
      ),
      'pressure': _lerpNullableDouble(
        (lowerSample['pressure'] as num?)?.toDouble(),
        (upperSample['pressure'] as num?)?.toDouble(),
        t,
      ),
      'windSpeed': _lerpNullableDouble(
        (lowerSample['windSpeed'] as num?)?.toDouble(),
        (upperSample['windSpeed'] as num?)?.toDouble(),
        t,
      ),
      'windDirection': _lerpDegrees(
        lowerSample['windDirection'] as int?,
        upperSample['windDirection'] as int?,
        t,
      )?.round(),
      'interpolated': true,
    };
  }

  @override
  void didUpdateWidget(covariant CircuitWeatherPlaybackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherSamples != widget.weatherSamples ||
        oldWidget.sessionName != widget.sessionName) {
      _resolvedSamples = _buildInterpolatedWeatherSamples(
        widget.weatherSamples,
      );
      _selectedIndex = 0;
      if (_selectedIndex >= _resolvedSamples.length) {
        _selectedIndex = math.max(0, _resolvedSamples.length - 1).toDouble();
      }
      _startAutoLoop();
    }
  }

  @override
  void dispose() {
    _autoLoopTimer?.cancel();
    _autoLoopController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    if (_resolvedSamples.isEmpty) {
      final content = Text(
        context.l10n.track_playback_no_weather,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
      if (!widget.embedInCard) {
        return content;
      }
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.panelStrong,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.7)),
        ),
        child: content,
      );
    }

    final selectedSample = _resolvedPlaybackSample();
    final timestamp = DateTime.tryParse(
      selectedSample['timestampUtc']?.toString() ?? '',
    );
    final air = (selectedSample['airTemperatureC'] as num?)?.toDouble();
    final track = (selectedSample['trackTemperatureC'] as num?)?.toDouble();
    final humidity = (selectedSample['humidity'] as num?)?.toDouble();
    final rain = (selectedSample['rainfall'] as num?)?.toDouble() ?? 0;
    final pressure = (selectedSample['pressure'] as num?)?.toDouble();
    final windSpeed = (selectedSample['windSpeed'] as num?)?.toDouble() ?? 0;
    final windDirection = selectedSample['windDirection'] as int?;
    final isInterpolated = selectedSample['interpolated'] == true;
    final trackFlagContext = _resolveTrackFlagContext(
      timestamp,
      widget.raceControlMessages,
      widget.sessionName,
    );
    final trackFlagState = trackFlagContext.state;
    final trackFlagColor = _trackFlagColor(trackFlagState, tokens);
    final currentLap = _resolveCurrentSessionLap(
      timestamp,
      widget.lapTimeline,
      widget.raceControlMessages,
      widget.sessionName,
    );
    final translatedTrackFlagLabel =
        l10nTrackFlagLabel(context.l10n, trackFlagState.labelKey);
    final trackStatusLabel =
        trackFlagState.labelKey == _trackClearState.labelKey &&
            currentLap != null
        ? context.l10n.lap_label('$currentLap')
        : translatedTrackFlagLabel;

    final columnContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.track_playback_title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'TitilliumWeb',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp == null
                          ? context.l10n.track_playback_unknown_sample
                          : '${_formatWeatherTimestampLabel(timestamp)} • ${isInterpolated ? context.l10n.track_playback_interpolated_minute : context.l10n.track_playback_recorded_sample}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'TitilliumWeb',
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: trackFlagColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: trackFlagColor.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Text(
                      trackStatusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: trackFlagColor,
                        fontFamily: 'TitilliumWeb',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rain > 0
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : tokens.statusSuccess.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rain > 0
                          ? context.l10n.track_playback_rain_active
                          : context.l10n.track_playback_dry_track,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: rain > 0
                          ? theme.colorScheme.primary
                          : tokens.statusSuccess,
                        fontFamily: 'TitilliumWeb',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (trackFlagContext.message != null &&
              trackFlagContext.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: trackFlagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: trackFlagColor.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                trackFlagContext.message!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: trackFlagColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    trackFlagColor.withValues(alpha: 0.14),
                    tokens.panel.withValues(alpha: 0.92),
                  ),
                  Color.alphaBlend(
                    trackFlagColor.withValues(alpha: 0.08),
                    tokens.accentSoft.withValues(alpha: 0.45),
                  ),
                ],
              ),
              border: Border.all(
                color: trackFlagColor.withValues(alpha: 0.45),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SvgPicture.network(
                      widget.race.circuitImage,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        trackFlagColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => CustomPaint(
                          painter: _WeatherTrackOverlayPainter(
                            primaryColor: theme.colorScheme.primary,
                            rainColor: theme.colorScheme.primaryContainer,
                            phase: _controller.value,
                            windSpeed: windSpeed,
                            windDirectionDegrees: (windDirection ?? 0)
                                .toDouble(),
                            rainIntensity: rain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.panelStrong.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tokens.outline.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.wind,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _hubReadableAccent(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${windSpeed.toStringAsFixed(1)} km/h',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${windDirection ?? '-'}° ${_windDirectionLabel(windDirection)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              thumbColor: theme.colorScheme.primary,
              inactiveTrackColor: tokens.outline.withValues(alpha: 0.5),
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            ),
            child: Slider(
              min: 0,
              max: (_resolvedSamples.length - 1).toDouble(),
              value: _selectedIndex.clamp(
                0,
                (_resolvedSamples.length - 1).toDouble(),
              ),
              onChangeStart: (_) {
                _autoLoopTimer?.cancel();
              },
              onChanged: (value) {
                setState(() => _selectedIndex = value);
              },
              onChangeEnd: (_) {
                // Only restart auto loop if not at the end
                _startAutoLoop();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _resolvedSamples.isEmpty
                    ? '--:--'
                    : _formatWeatherTimeLabel(
                        DateTime.parse(
                          _resolvedSamples.first['timestampUtc'].toString(),
                        ),
                      ),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                timestamp == null
                    ? '--:--'
                    : _formatWeatherTimeLabel(timestamp),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                _resolvedSamples.isEmpty
                    ? '--:--'
                    : _formatWeatherTimeLabel(
                        DateTime.parse(
                          _resolvedSamples.last['timestampUtc'].toString(),
                        ),
                      ),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 150,
                child: _WeatherMetricTile(
                  label: context.l10n.air_temperature,
                  value: air == null ? '-' : '${air.toStringAsFixed(1)} C',
                  icon: Icons.thermostat,
                ),
              ),
              SizedBox(
                width: 150,
                child: _WeatherMetricTile(
                  label: context.l10n.track_temperature,
                  value: track == null ? '-' : '${track.toStringAsFixed(1)} C',
                  icon: Icons.device_thermostat,
                ),
              ),
              SizedBox(
                width: 150,
                child: _WeatherMetricTile(
                  label: context.l10n.humidity,
                  value: humidity == null
                      ? '-'
                      : '${humidity.toStringAsFixed(1)}%',
                  icon: Icons.water_drop,
                ),
              ),
              SizedBox(
                width: 150,
                child: _WeatherMetricTile(
                  label: context.l10n.rainfall,
                  value: '${rain.toStringAsFixed(1)} mm',
                  icon: Icons.umbrella,
                ),
              ),
              SizedBox(
                width: 150,
                child: _WeatherMetricTile(
                  label: context.l10n.pressure,
                  value: pressure == null
                      ? '-'
                      : '${pressure.toStringAsFixed(1)} hPa',
                  icon: Icons.compress,
                ),
              ),
            ],
          ),
        ],
      );
    if (!widget.embedInCard) {
      return columnContent;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.panelStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.8)),
      ),
      child: columnContent,
    );
  }
}

/// ---

/// ---------------------------------------------------------------------

class EngineSupplier {
  final String name;
  final String engineName;
  final String city;
  EngineSupplier({
    required this.name,
    required this.engineName,
    required this.city,
  });
}

final Map<String, EngineSupplier> engineSuppliers = {
  'Mercedes': EngineSupplier(
    name: 'Mercedes-AMG High Performance Powertrains',
    engineName: 'M17 E Performance',
    city: 'Brixworth, UK',
  ),
  'Red Bull Ford': EngineSupplier(
    name: 'Red Bull Ford Powertrains',
    engineName: 'RB-Ford 2026',
    city: 'Milton Keynes, UK',
  ),
  'Ferrari': EngineSupplier(
    name: 'Ferrari S.p.A.',
    engineName: '066/12',
    city: 'Maranello, IT',
  ),
  'Honda': EngineSupplier(
    name: 'Honda Racing Corporation',
    engineName: 'Honda RBH002',
    city: 'Sakura, JP',
  ),
  'Audi': EngineSupplier(
    name: 'Audi Formula Racing GmbH',
    engineName: 'Audi F1 2026',
    city: 'Neuburg, DE',
  ),
};

String _slugify(String value) => slugifyForHubUrl(value);

String _raceSlug(Race race) => _slugify(
  race.name.replaceAll(RegExp(r'\s+Grand Prix$', caseSensitive: false), ''),
);
String _driverSlug(Driver driver) => _slugify(driver.name);
String _teamSlug(Team team) => _slugify(team.name);

int? _constructorRankInStandings(Team team) {
  final list = List<Team>.from(fallbackTeams)
    ..sort((a, b) => b.points.compareTo(a.points));
  final i = list.indexWhere((t) => t.name == team.name);
  if (i < 0) {
    return null;
  }
  return i + 1;
}

int? _driverRankInStandings(Driver driver) {
  final year = DateTime.now().year;
  final roster = driversData[year];
  if (roster == null || roster.isEmpty) {
    return null;
  }
  final list = roster
      .map(
        (d) => normalizeForComparison(d.name) ==
                normalizeForComparison(driver.name)
            ? Driver.copy(d, driver.points)
            : d,
      )
      .toList();
  list.sort((a, b) => b.points.compareTo(a.points));
  final i = list.indexWhere(
    (d) => normalizeForComparison(d.name) == normalizeForComparison(driver.name),
  );
  if (i < 0) {
    return null;
  }
  return i + 1;
}

String _driverHeroCountryPrefix(Driver d) {
  final n = d.nationality.trim();
  if (n.length == 2) {
    return n.toUpperCase();
  }
  return '';
}

Race? _nextUpcomingRaceForHub() {
  if (races.isEmpty) {
    return null;
  }
  return nextRaceAfterNowSkippingCancelled(races);
}
String _sessionSlug(String sessionName) => _slugify(sessionName);

const List<String> _knownSessionNames = <String>[
  'Practice 1',
  'Practice 2',
  'Practice 3',
  'Sprint Qualifying',
  'Sprint',
  'Qualifying',
  'Race',
];

String? _sessionNameFromSlug(String slug) {
  for (final sessionName in _knownSessionNames) {
    if (_sessionSlug(sessionName) == slug) {
      return sessionName;
    }
  }
  return null;
}

/// Friendly slugs that map to the canonical [_raceSlug] value (English short
/// slug from the GP name, e.g. Japanese GP → `japanese`).
const Map<String, String> _raceSlugAliases = <String, String>{
  'grand-prix-of-japan': 'japanese',
  'japanse': 'japanese', // Dutch adjective; canonical slug stays `japanese`
};

Race? _findRaceBySlug(String slug) {
  if (slug.isEmpty) return null;
  final resolved = _raceSlugAliases[slug] ?? slug;
  for (final race in races) {
    if (_raceSlug(race) == resolved || _raceSlug(race) == slug) {
      return race;
    }
  }
  // e.g. `japanese-grand-prix` while canonical short slug is `japanese`
  for (final race in races) {
    if (_slugify(race.name) == resolved || _slugify(race.name) == slug) {
      return race;
    }
  }
  return null;
}

/// OpenF1 bundle folder under `assets/data/{year}/` for this race.
String? _venueFolderForRace(Race race) {
  return F1AssetResolver.venueFolderForCircuitAssetId(race.circuitAssetId) ??
      F1AssetResolver.venueFolderForYearAndRound(
        race.date.year,
        raceRoundFor(race),
      );
}

/// Same calendar event (hub must reload when this changes; session stems are
/// shared across venues so stale [State] would keep the previous JSON maps).
bool _isSameGrandPrixWeekend(Race a, Race b) {
  return a.name == b.name &&
      a.country == b.country &&
      a.date == b.date;
}

/// Weekend hub path segment: stable short slug (`spa`, `barcelona`, …), not raw asset folder.
String _weekendHubSlugForRace(Race race) {
  final vf = _venueFolderForRace(race);
  if (vf != null && vf.isNotEmpty) {
    return F1AssetResolver.weekendHubPathSlug(vf);
  }
  return _raceSlug(race);
}

/// Old `/weekendhub/australian` bookmarks → canonical venue slug.
const Map<String, String> _weekendHubLegacyVenueRedirects = <String, String>{
  'australian': 'melbourne',
  'australian-grand-prix': 'melbourne',
};

Race? _findRaceByWeekendHubSlug(String slug) {
  if (slug.isEmpty) return null;
  final normalized = slug.toLowerCase().trim();
  final venueTarget = _weekendHubLegacyVenueRedirects[normalized] ?? normalized;

  Race? best;
  for (final race in races) {
    final vf = _venueFolderForRace(race);
    final matches = vf != null &&
        F1AssetResolver.weekendHubSlugMatches(venueTarget, vf);
    if (!matches) continue;
    if (best == null || race.date.isAfter(best.date)) {
      best = race;
    }
  }
  return best ?? _findRaceBySlug(normalized);
}

Driver? _findDriverBySlug(String slug) {
  final seenNames = <String>{};
  for (final seasonDrivers in driversData.values) {
    for (final driver in seasonDrivers) {
      if (!seenNames.add(driver.name)) {
        continue;
      }
      if (_driverSlug(driver) == slug) {
        return driver;
      }
      if (driverJsonSlugCandidates(driver.name).contains(slug)) {
        return driver;
      }
    }
  }
  return null;
}

Team? _findTeamBySlug(String slug) {
  for (final team in fallbackTeams) {
    if (_teamSlug(team) == slug) {
      return team;
    }
  }
  return null;
}

Driver? _findDriver2026ByName(String nameOrLastName) {
  final lower = nameOrLastName.trim().toLowerCase();
  for (final d in drivers2026) {
    if (d.name.toLowerCase() == lower ||
        d.name.toLowerCase().endsWith(' $lower') ||
        d.name.split(' ').last.toLowerCase() == lower) {
      return d;
    }
  }
  return null;
}

Driver? _getTeammate2026(Driver driver) {
  for (final d in drivers2026) {
    if (d.team == driver.team && d.name != driver.name) return d;
  }
  return null;
}

/// Returns (favoriteDriverWins, teammateWins, avgGapSec). Gap negative = favorite faster.
(int, int, double) _teammateQualifyingStats(Driver fav, Driver teammate) {
  final key1 = '${fav.name.toLowerCase()}|${teammate.name.toLowerCase()}';
  final key2 = '${teammate.name.toLowerCase()}|${fav.name.toLowerCase()}';
  const stats = <String, (int, int, double)>{
    'lewis hamilton|charles leclerc': (7, 3, -0.084),
    'charles leclerc|lewis hamilton': (3, 7, 0.084),
    'max verstappen|isack hadjar': (10, 0, -0.250),
    'isack hadjar|max verstappen': (0, 10, 0.250),
    'lando norris|oscar piastri': (6, 4, -0.042),
    'oscar piastri|lando norris': (4, 6, 0.042),
    'george russell|kimi antonelli': (5, 5, 0.012),
    'kimi antonelli|george russell': (5, 5, -0.012),
    'fernando alonso|lance stroll': (8, 2, -0.156),
    'lance stroll|fernando alonso': (2, 8, 0.156),
  };
  return stats[key1] ?? stats[key2] ?? (5, 5, -0.050);
}

String _circuitsPath() => '/circuits';

String _calendarPath() => '/calendar';

/// Legacy next-race / podium / AI Strategist dashboard (not linked from the nav menu).
String _oldDashPath() => '/old/dash';
String _driversPath() => '/drivers';
String _teamsPath() => '/teams';
String _changelogPath() => '/profile/changelog';
String _loginPath() => '/login';
String _livePath() => '/live';
String _profilePath() => '/profile';
String _myPaddockPath() => '/my-paddock';
String _simulatorPath() => '/simulator';
String _testStylePath() => '/test';

/// Simulator: voided weekends — no results, no points; random decorative podium only.
const _kSimulatorVoidedCircuitIds = <String>{
  'bahrain_international',
  'jeddah_corniche',
};

List<SimulatorRoundInput> _simulatorRoundInputs() {
  final out = <SimulatorRoundInput>[];
  for (var i = 0; i < races.length; i++) {
    final r = races[i];
    final key = SessionDataManager().raceResultsKeyFor(r);
    final cached = SessionDataManager().raceResultsCache[key];
    final hasData = cached != null && cached.isNotEmpty;
    final actualRows = (cached == null || cached.isEmpty)
        ? const <SimulatorResultRowLite>[]
        : cached
            .map(
              (row) => SimulatorResultRowLite(
                driver: row.driver,
                finish: row.finish,
                pointsRaw: row.points,
              ),
            )
            .toList();
    final sprintKey = '${r.country}_Sprint_${r.date.year}';
    final sprintCached = SessionDataManager().raceResultsCache[sprintKey];
    final sprintRows = (sprintCached == null || sprintCached.isEmpty)
        ? const <SimulatorResultRowLite>[]
        : sprintCached
            .map(
              (row) => SimulatorResultRowLite(
                driver: row.driver,
                finish: row.finish,
                pointsRaw: row.points,
              ),
            )
            .toList();
    final cid = r.circuitAssetId.trim().isNotEmpty
        ? r.circuitAssetId.trim()
        : 'round_${i + 1}';
    final voided = _kSimulatorVoidedCircuitIds.contains(cid);
    out.add(
      SimulatorRoundInput(
        circuitId: cid,
        roundIndex: i + 1,
        displayName: r.circuitDisplayName.trim().isNotEmpty
            ? r.circuitDisplayName
            : r.name,
        grandPrixName: r.name,
        date: r.date,
        hasSprint: voided ? false : r.hasSprint,
        hasActualResults: voided ? false : hasData,
        actualRows: voided ? const <SimulatorResultRowLite>[] : actualRows,
        sprintActualRows: voided ? const <SimulatorResultRowLite>[] : sprintRows,
        grandPrixStartUtc: r.date.toUtc(),
        sprintRaceStartUtc:
            voided ? null : (r.hasSprint ? r.sprintRace.toUtc() : null),
        isCancelled: voided,
      ),
    );
  }
  return out;
}

List<SimulatorDriverRef> _simulatorDriverRefs() {
  return drivers2026
      .take(kSimulatorGridSize)
      .map(
        (d) => SimulatorDriverRef(
          number: d.number,
          name: d.name,
          team: d.team,
        ),
      )
      .toList();
}

const String _kGithubHelpIssuesUrl =
    'https://github.com/EvertJob/F1-Info/issues/new/choose';

String _racePath(Race race) => '${_circuitsPath()}/${_raceSlug(race)}';

/// JSON circuit hub (`CircuitPage`): slug = `circuit_id` / asset stem in `assets/data/circuits/*.json`.
String _circuitJsonDetailPath(Race race) =>
    '${_circuitsPath()}/${race.circuitAssetId}';
/// Short shareable path (`/#/weekendhub/melbourne`, …); venue folder matches bundled JSON.
String _weekendHubPath(Race race) => '/weekendhub/${_weekendHubSlugForRace(race)}';

/// Nested paths like `/circuits/:slug/weekend` require a real [Race]; otherwise send to JSON circuit page or calendar.
String? _circuitsRaceChildRedirect(String? slug) {
  if (slug == null || slug.isEmpty) {
    return _circuitsPath();
  }
  if (_findRaceBySlug(slug) != null) {
    return null;
  }
  return '${_circuitsPath()}/$slug';
}
String _raceResultsPath(Race race) => '${_racePath(race)}/results';
String _fullscreenRaceResultsPath(Race race) =>
    '${_raceResultsPath(race)}/fullscreen';
String _singleSessionResultsPath(Race race, String sessionName) =>
    '${_racePath(race)}/session/${_sessionSlug(sessionName)}';
String _driverPath(Driver driver) => '${_driversPath()}/${_driverSlug(driver)}';
String _teamPath(Team team) => '${_teamsPath()}/${_teamSlug(team)}';
String _driverComparePath(Driver driver1, Driver driver2) =>
    '${_driversPath()}/compare/${_driverSlug(driver1)}/${_driverSlug(driver2)}';
String _teamComparePath(Team team1, Team team2) =>
    '${_teamsPath()}/compare/${_teamSlug(team1)}/${_teamSlug(team2)}';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureF1WebUrlStrategy();
  // Web: sync the URL bar with imperative navigation (push/pop), e.g. drivers list → detail.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await Supabase.initialize(
    url: 'https://aeekchoaetlksooyylsv.supabase.co',
    anonKey: 'sb_publishable_38F48DBpJ7cWwVo-2yZjhA_rE6wE9uz',
  );
  await HiveBootstrap.initialize();
  await SessionDataManager().init(races);
  // Preload all JSON files in the background (do not await)
  // This ensures all race/session data is loaded without blocking the UI
  // ignore: unawaited_futures
  SessionDataManager().fetchAllData();

  final stored = await ThemeService.instance.load();
  final themeController = ThemeController(
    initialSchemeIndex: stored.schemeIndex,
    initialThemeMode: stored.isDark ? ThemeMode.dark : ThemeMode.light,
  );

  // Fetch theme from Supabase profile before first frame (if logged in)
  await themeController.initFromSupabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<ProfileFavoritesNotifier>(
          create: (_) => ProfileFavoritesNotifier(),
        ),
        ChangeNotifierProvider<AiStrategistPrefsNotifier>(
          create: (_) => AiStrategistPrefsNotifier(),
        ),
        ChangeNotifierProvider<CalendarPrefsNotifier>(
          create: (_) => CalendarPrefsNotifier(),
        ),
        ChangeNotifierProvider<LastPodiumPrefsNotifier>(
          create: (_) => LastPodiumPrefsNotifier(),
        ),
        ChangeNotifierProvider<DetailExpansionPrefsNotifier>(
          create: (_) => DetailExpansionPrefsNotifier(),
        ),
        ChangeNotifierProvider<DisplaySettingsController>(
          create: (context) => DisplaySettingsController(
            context.read<DetailExpansionPrefsNotifier>(),
          ),
        ),
        ChangeNotifierProvider<PaddockUserPreferencesNotifier>(
          create: (_) => PaddockUserPreferencesNotifier(),
        ),
      ],
      child: const F1HubApp(),
    ),
  );
}

class F1HubApp extends StatefulWidget {
  const F1HubApp({super.key});

  static State<F1HubApp> of(BuildContext context) {
    final state = context.findAncestorStateOfType<_F1HubAppState>();
    assert(state != null, 'F1HubApp state not found in context');
    return state!;
  }

  static Future<void> setAppLocale(BuildContext context, Locale locale) async {
    final state = context.findAncestorStateOfType<_F1HubAppState>();
    await state?._applyLocale(locale);
  }

  @override
  State<F1HubApp> createState() => _F1HubAppState();
}

/// Branded 2026-style splash screen: white bg, logo fade-in, loading subtitle,
/// animated fading perimeter border at bottom (0%→100% width).
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({
    required this.primaryColor,
    required this.onComplete,
  });

  final Color primaryColor;
  final VoidCallback onComplete;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _borderController;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoController.forward();
    _borderController.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _logoOpacity,
                  builder: (context, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: child,
                  ),
                  child: Icon(
                    Icons.sports_motorsports,
                    size: 80,
                    color: widget.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.app_title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  context.l10n.season_2026,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.loading,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _borderController,
                builder: (context, _) {
                  final width = MediaQuery.of(context).size.width * _borderController.value;
                  return Container(
                    height: 3,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: width,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.primaryColor,
                            widget.primaryColor.withValues(alpha: 0.5),
                          ],
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
    );
  }
}

class _F1HubAppState extends State<F1HubApp> {
  bool _showSplash = true;
  bool _splashFadingOut = false;
  static const _splashDuration = Duration(milliseconds: 2200);
  static const _splashFadeOut = Duration(milliseconds: 400);

  Locale _locale = const Locale('en');

  Future<void> _restoreLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() => _locale = Locale(code));
    }
  }

  Future<void> _applyLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_restoreLocale());
    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      setState(() => _splashFadingOut = true);
      Future.delayed(_splashFadeOut, () {
        if (mounted) setState(() => _showSplash = false);
      });
    });
  }

  Widget _buildSettingsMenu(BuildContext context) => AppSettingsMenuButton(
    onToggleTheme: () => context.read<ThemeController>().toggleBrightness(),
  );

  late final GoRouter _router = GoRouter(
    initialLocation: _circuitsPath(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => _circuitsPath()),
      GoRoute(
        path: '/changelog',
        redirect: (context, state) => _changelogPath(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _LoggedInSnackBarTrigger(
              child: MainNavigation(navigationShell: navigationShell),
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _circuitsPath(),
                builder: (context, state) => const CircuitsView(),
                routes: [
                  GoRoute(
                    path: ':raceSlug',
                    redirect: (context, state) {
                      final slug = state.pathParameters['raceSlug'] ?? '';
                      if (slug.isEmpty) {
                        return _circuitsPath();
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final slug =
                          state.pathParameters['raceSlug']?.trim() ?? '';
                      final race = _findRaceBySlug(slug);
                      if (race != null) {
                        return CircuitDetailScreen(
                          race: race,
                          heroTag: _raceFlagHeroTag(race, source: 'route'),
                          settingsMenu: _buildSettingsMenu(context),
                        );
                      }
                      return CircuitPage(circuitAssetId: slug);
                    },
                    routes: [
                      GoRoute(
                        path: 'weekend',
                        redirect: (context, state) => _circuitsRaceChildRedirect(
                          state.pathParameters['raceSlug'],
                        ),
                        builder: (context, state) {
                          final race = _findRaceBySlug(
                            state.pathParameters['raceSlug']!,
                          )!;
                          return WeekendHubScreen(
                            key: ValueKey(
                              'weekend_hub_${race.country}_${race.date.toIso8601String()}',
                            ),
                            race: race,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'results',
                        redirect: (context, state) => _circuitsRaceChildRedirect(
                          state.pathParameters['raceSlug'],
                        ),
                        builder: (context, state) {
                          final race = _findRaceBySlug(
                            state.pathParameters['raceSlug']!,
                          )!;
                          return SessionResultsScreen(race: race);
                        },
                        routes: [
                          GoRoute(
                            path: 'fullscreen',
                            builder: (context, state) {
                              final race = _findRaceBySlug(
                                state.pathParameters['raceSlug']!,
                              )!;
                              return FullscreenRaceResultsScreen(
                                race: race,
                                title: _sessionDisplayTitle(context, 'Race'),
                              );
                            },
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'session/:sessionSlug',
                        redirect: (context, state) {
                          final slug = state.pathParameters['raceSlug'];
                          final childRedirect = _circuitsRaceChildRedirect(slug);
                          if (childRedirect != null) {
                            return childRedirect;
                          }
                          final race = _findRaceBySlug(slug ?? '');
                          final sessionName = _sessionNameFromSlug(
                            state.pathParameters['sessionSlug'] ?? '',
                          );
                          if (race == null || sessionName == null) {
                            return _circuitsPath();
                          }
                          return null;
                        },
                        builder: (context, state) {
                          final race = _findRaceBySlug(
                            state.pathParameters['raceSlug']!,
                          )!;
                          final sessionName = _sessionNameFromSlug(
                            state.pathParameters['sessionSlug']!,
                          )!;
                          return SingleSessionResultsScreen(
                            race: race,
                            sessionName: sessionName,
                            displayTitle: _sessionDisplayTitle(
                              context,
                              sessionName,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            GoRoute(
              path: '/weekendhub/:raceSlug',
              redirect: (context, state) {
                final slug = (state.pathParameters['raceSlug'] ?? '').trim();
                if (slug.isEmpty) return _circuitsPath();
                final lower = slug.toLowerCase();
                final canon = _weekendHubLegacyVenueRedirects[lower];
                if (canon != null) {
                  return '/weekendhub/$canon';
                }
                return _findRaceByWeekendHubSlug(slug) == null
                    ? _circuitsPath()
                    : null;
              },
              builder: (context, state) {
                final race = _findRaceByWeekendHubSlug(
                  state.pathParameters['raceSlug']!,
                )!;
                return WeekendHubScreen(
                  key: ValueKey(
                    'weekend_hub_${race.country}_${race.date.toIso8601String()}',
                  ),
                  race: race,
                );
              },
            ),
            GoRoute(
              path: _myPaddockPath(),
              builder: (context, state) => MyPaddockScreen(
                settingsMenu: _buildSettingsMenu(context),
              ),
            ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _calendarPath(),
                builder: (context, state) => const CircuitsView(
                  homeMode: CircuitsHomeMode.calendarPage,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _driversPath(),
                builder: (context, state) => StandingsView(
                  isDriverView: true,
                  settingsMenu: _buildSettingsMenu(context),
                ),
                routes: [
                  GoRoute(
                    path: 'compare/:leftSlug/:rightSlug',
                    redirect: (context, state) {
                      final left = _findDriverBySlug(
                        state.pathParameters['leftSlug'] ?? '',
                      );
                      final right = _findDriverBySlug(
                        state.pathParameters['rightSlug'] ?? '',
                      );
                      return left == null || right == null
                          ? _driversPath()
                          : null;
                    },
                    builder: (context, state) {
                      final left = _findDriverBySlug(
                        state.pathParameters['leftSlug']!,
                      )!;
                      final right = _findDriverBySlug(
                        state.pathParameters['rightSlug']!,
                      )!;
                      return DriverComparisonView(
                        driver1: left,
                        driver2: right,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':driverSlug',
                    redirect: (context, state) =>
                        _findDriverBySlug(
                              state.pathParameters['driverSlug'] ?? '',
                            ) ==
                            null
                        ? _driversPath()
                        : null,
                    builder: (context, state) {
                      final driver = _findDriverBySlug(
                        state.pathParameters['driverSlug']!,
                      )!;
                      return DriverDetailView(
                        driver: driver,
                        heroTag: _driverFlagHeroTag(driver, source: 'route'),
                        settingsMenu: _buildSettingsMenu(context),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _teamsPath(),
                builder: (context, state) => StandingsView(
                  isDriverView: false,
                  settingsMenu: _buildSettingsMenu(context),
                ),
                routes: [
                  GoRoute(
                    path: 'compare/:leftSlug/:rightSlug',
                    redirect: (context, state) {
                      final left = _findTeamBySlug(
                        state.pathParameters['leftSlug'] ?? '',
                      );
                      final right = _findTeamBySlug(
                        state.pathParameters['rightSlug'] ?? '',
                      );
                      return left == null || right == null
                          ? _teamsPath()
                          : null;
                    },
                    builder: (context, state) {
                      final left = _findTeamBySlug(
                        state.pathParameters['leftSlug']!,
                      )!;
                      final right = _findTeamBySlug(
                        state.pathParameters['rightSlug']!,
                      )!;
                      return TeamComparisonView(team1: left, team2: right);
                    },
                  ),
                  GoRoute(
                    path: ':teamSlug',
                    redirect: (context, state) =>
                        _findTeamBySlug(
                              state.pathParameters['teamSlug'] ?? '',
                            ) ==
                            null
                        ? _teamsPath()
                        : null,
                    builder: (context, state) {
                      final team = _findTeamBySlug(
                        state.pathParameters['teamSlug']!,
                      )!;
                      return TeamDetailView(
                        team: team,
                        heroTag: _teamFlagHeroTag(team, source: 'route'),
                        settingsMenu: _buildSettingsMenu(context),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _simulatorPath(),
                builder: (context, state) => ListenableBuilder(
                  listenable: SessionDataManager(),
                  builder: (context, _) => ChampionshipSimulatorPage(
                    roundInputs: _simulatorRoundInputs(),
                    driverRefs: _simulatorDriverRefs(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _profilePath(),
                builder: (context, state) =>
                    ProfileScreen(settingsMenu: _buildSettingsMenu(context)),
                routes: [
                  GoRoute(
                    path: 'changelog',
                    builder: (context, state) => ChangelogPage(
                      settingsMenu: _buildSettingsMenu(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/news',
        redirect: (context, state) => _circuitsPath(),
      ),
      GoRoute(
        path: '/orbit',
        redirect: (context, state) => _circuitsPath(),
        routes: [
          GoRoute(
            path: ':circuitSlug',
            redirect: (context, state) => _circuitsPath(),
            routes: [
              GoRoute(
                path: 'technical',
                redirect: (context, state) => _circuitsPath(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/s/:username',
        builder: (context, state) {
          final raw = state.pathParameters['username'] ?? '';
          return ListenableBuilder(
            listenable: SessionDataManager(),
            builder: (context, _) => SharedChampionshipPredictionsPage(
              username: Uri.decodeComponent(raw),
              roundInputs: _simulatorRoundInputs(),
              driverRefs: _simulatorDriverRefs(),
            ),
          );
        },
      ),
      GoRoute(
        path: _loginPath(),
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: _livePath(),
        builder: (context, state) {
          final frame = int.tryParse(state.uri.queryParameters['frame'] ?? '');
          final initial = frame != null && frame > 0 ? frame : null;
          final session = state.uri.queryParameters['session'];
          return LiveTimingPage(
            initialReplayFrame: initial,
            resumeSessionLabelFromRoute: session,
          );
        },
      ),
      GoRoute(
        path: _testStylePath(),
        builder: (context, state) {
          final q = state.uri.queryParameters['slug']?.trim();
          final slug = (q != null && q.isNotEmpty) ? q : 'racingbulls';
          return TestStylePage(slug: slug);
        },
      ),
      GoRoute(
        path: _oldDashPath(),
        builder: (context, state) => const CircuitsView(
          homeMode: CircuitsHomeMode.legacyDashboard,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final displaySettings = context.watch<DisplaySettingsController>();
    final f1Ui = F1UiTheme.fromSettings(displaySettings.settings);
    final lightTheme = themeWithF1Ui(themeController.lightTheme, f1Ui);
    final darkTheme = themeWithF1Ui(themeController.darkTheme, f1Ui);
    final primaryColor = themeController.resolvedIsDark
        ? darkTheme.colorScheme.primary
        : lightTheme.colorScheme.primary;
    return MaterialApp.router(
      title: 'F1 Hub',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeAnimationCurve: f1Ui.useInstantTransitions
          ? Curves.linear
          : Curves.easeInOutCubic,
      themeAnimationDuration: f1Ui.useInstantTransitions
          ? Duration.zero
          : const Duration(milliseconds: 320),
      themeMode: themeController.themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const HubAmbientBackdrop(),
            if (child != null) child,
            if (_showSplash)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _splashFadingOut,
                  child: AnimatedOpacity(
                    opacity: _splashFadingOut ? 0 : 1,
                    duration: _splashFadeOut,
                    onEnd: () {
                      if (mounted && _splashFadingOut) {
                        setState(() => _showSplash = false);
                      }
                    },
                    child: _SplashScreen(
                      primaryColor: primaryColor,
                      onComplete: () {},
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// --- Globale UI Helpers ----------------------------------------------

String getTireEmoji(String compound) {
  switch (compound.toUpperCase()) {
    case 'SOFT':
      return 'Soft';
    case 'MEDIUM':
      return 'Med';
    case 'HARD':
      return 'Hard';
    case 'INTERMEDIATE':
      return 'Int';
    case 'WET':
      return 'Wet';
    default:
      return compound;
  }
}

String getCompactTireEmoji(String compound) {
  switch (compound.toUpperCase()) {
    case 'SOFT':
      return '';
    case 'MEDIUM':
      return '';
    case 'HARD':
      return '';
    case 'INTERMEDIATE':
      return '';
    case 'WET':
      return '';
    default:
      return '';
  }
}

/// Section titles / list accents: follows [ThemeData.colorScheme.primary] (team pages
/// override primary via an ancestor [Theme]).
Color _hubReadableAccent(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}

Widget _sectionHeader(String t, String emoji) => Builder(
  builder: (context) {
    final tokens = _themeTokens(context);
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            t.toUpperCase(),
            style: TextStyle(
              color: _hubReadableAccent(context),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          Expanded(
            child: Divider(
              indent: 15,
              color: tokens.outline.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  },
);

Widget _statTile(String l, dynamic v, IconData icon) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary.withValues(alpha: 0.82);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Text(
                l,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Flexible(
            child: v is Widget
                ? v
                : Text(
                    v.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ],
      ),
    );
  },
);

Widget _buildResponsiveSections({
  required List<Widget> sections,
  double breakpoint = 601,
  double spacing = 16,
  double minColumnWidth = 320,
  int maxColumns = 3,
}) => LayoutBuilder(
  builder: (context, constraints) {
    Widget buildSectionColumn(List<Widget> columnSections) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < columnSections.length; index++) ...[
            columnSections[index],
            if (index != columnSections.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }

    if (constraints.maxWidth > breakpoint) {
      final availableWidth = constraints.maxWidth;
      final estimatedColumns =
          ((availableWidth + spacing) / (minColumnWidth + spacing)).floor();
      final columnCount = estimatedColumns.clamp(2, maxColumns);
      final distributedSections = List.generate(columnCount, (_) => <Widget>[]);

      for (int index = 0; index < sections.length; index++) {
        distributedSections[index % columnCount].add(sections[index]);
      }

      return AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (
              int index = 0;
              index < distributedSections.length;
              index++
            ) ...[
              Expanded(child: buildSectionColumn(distributedSections[index])),
              if (index != distributedSections.length - 1)
                SizedBox(width: spacing),
            ],
          ],
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: buildSectionColumn(sections),
    );
  },
);

/// Flat hub surface (light ≈ dark structure: fill + hairline border, no glass rim).
BoxDecoration _hubFlatHubCardDecoration(
  BuildContext context, {
  double radius = 14,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? ConstructorHubColors.surface : Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: isDark ? ConstructorHubColors.border : Colors.black.withValues(alpha: 0.08),
      width: isDark ? 1.0 : 0.8,
    ),
  );
}

/// Circuit / driver / team detail sections: same flat card in light and dark.
Widget _detailHubSectionCard(
  BuildContext context, {
  required Widget child,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor =
      isDark ? ConstructorHubColors.textPrimary : HubTheme.f1DeepCharcoal;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DecoratedBox(
      decoration: _hubFlatHubCardDecoration(context, radius: 14),
      child: Builder(
        builder: (innerContext) {
          final accent = Theme.of(innerContext).colorScheme.primary;
          return Theme(
            data: Theme.of(innerContext).copyWith(
              dividerColor: Colors.transparent,
              expansionTileTheme: ExpansionTileThemeData(
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                textColor: titleColor,
                collapsedTextColor: titleColor,
                iconColor: accent.withValues(alpha: 0.88),
                collapsedIconColor: accent.withValues(alpha: 0.88),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  side: BorderSide.none,
                ),
                collapsedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  side: BorderSide.none,
                ),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              ),
            ),
            child: child,
          );
        },
      ),
    ),
  );
}

/// Alias: overview hubs use the same flat shell as constructor-style dark panels.
Widget _detailOverviewSectionCard(
  BuildContext context, {
  required Widget child,
}) {
  return _detailHubSectionCard(context, child: child);
}

/// Profile settings blocks: hub glass panel (parity with standings / hub shells).
Widget _profileSectionCard(BuildContext context, {required Widget child}) {
  final scheme = Theme.of(context).colorScheme;
  return HubVisualLanguage.glassPanel(
    context: context,
    accentGlow: scheme.primary,
    accentGlowOpacity: 0.07,
    padding: const EdgeInsets.all(20),
    child: child,
  );
}

/// --- Data Manager voor OpenF1 Sessies -----------------------

class SessionResult {
  final String driver;
  final String time;
  final String tyre;

  const SessionResult({
    required this.driver,
    required this.time,
    required this.tyre,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    return SessionResult(
      driver: json['driver']?.toString() ?? '-',
      time: json['time']?.toString() ?? '-',
      tyre: json['tyre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'driver': driver, 'time': time, 'tyre': tyre};
  }
}

class RaceResultRow {
  final String driver;
  final String start;
  final String finish;
  final String timeOrGap;
  final String fastestLap;
  final String tyreCompound;
  final String penalty;
  final String points;
  final bool hasFastestLap;
  final List<String> tyreCompounds;
  final List<Map<String, dynamic>> tyreStints;
  final String tyreStrategy;
  final List<int> tyreChangeLaps;
  final List<Map<String, dynamic>> penaltyDetails;
  final bool penaltyServed;
  final List<int> penaltyServedLaps;
  final List<Map<String, dynamic>> weatherSamples;
  final List<Map<String, dynamic>> raceControlMessages;
  final List<Map<String, dynamic>> pitStops;
  final String totalPitTime;
  final Map<String, dynamic>? fastestPitStop;
  final String averagePitTime;

  const RaceResultRow({
    required this.driver,
    required this.start,
    required this.finish,
    required this.timeOrGap,
    required this.fastestLap,
    required this.tyreCompound,
    required this.penalty,
    required this.points,
    required this.hasFastestLap,
    required this.tyreCompounds,
    required this.tyreStints,
    required this.tyreStrategy,
    required this.tyreChangeLaps,
    required this.penaltyDetails,
    required this.penaltyServed,
    required this.penaltyServedLaps,
    required this.weatherSamples,
    required this.raceControlMessages,
    required this.pitStops,
    required this.totalPitTime,
    required this.fastestPitStop,
    required this.averagePitTime,
  });

  static bool _jsonLooksLikeOpenF1RaceResult(Map<String, dynamic> json) {
    return json.containsKey('broadcastName') ||
        (json.containsKey('driverNumber') &&
            json.containsKey('finishPosition'));
  }

  /// Lap time in seconds (OpenF1) → `m:ss.mmm` for results tables.
  static String formatOpenF1LapSeconds(dynamic raw) {
    if (raw == null) return '-';
    final sec = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (sec == null || sec <= 0) return '-';
    final duration = Duration(
      microseconds: (sec * Duration.microsecondsPerSecond).round(),
    );
    final minutes = duration.inMinutes;
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMicroseconds.remainder(Duration.microsecondsPerSecond)) /
                1000)
            .round()
            .toString()
            .padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  /// OpenF1 `session_result.duration` is a single lap time (practice) or a list
  /// of segment times (qualifying). Races use a large total-time `duration`; those
  /// must not be treated as a lap time (see [_kOpenF1MaxLapLikeSeconds]).
  static const double _kOpenF1MaxLapLikeSeconds = 360;

  static double? openF1ResultFastestLapSeconds(Map<String, dynamic> json) {
    for (final key in ['fastestLapDuration', 'fastest_lap_duration']) {
      final v = json[key];
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    final dfl = json['driverFastestLap'];
    if (dfl is Map) {
      final n = dfl['duration'];
      if (n is num && n.toDouble() > 0) return n.toDouble();
      final p = double.tryParse(n?.toString() ?? '');
      if (p != null && p > 0) return p;
    }
    final d = json['duration'];
    if (d is num) {
      final sec = d.toDouble();
      if (sec > 0 && sec <= _kOpenF1MaxLapLikeSeconds) return sec;
      return null;
    }
    if (d is List) {
      double? best;
      for (final e in d) {
        if (e is! num) continue;
        final x = e.toDouble();
        if (x > 0 && (best == null || x < best)) best = x;
      }
      return best;
    }
    return null;
  }

  /// Bundled `*_results.json`: prefer [driverFastestLap.time], else format from seconds.
  static String openF1BundledFastestLapDisplayString(Map<String, dynamic> json) {
    final dfl = json['driverFastestLap'];
    if (dfl is Map) {
      final t = dfl['time']?.toString().trim();
      if (t != null && t.isNotEmpty && t != '-') {
        return t;
      }
    }
    return formatOpenF1LapSeconds(openF1ResultFastestLapSeconds(json));
  }

  static int? _openF1LapNumberFromDriverFastestLap(Map<String, dynamic> json) {
    final dfl = json['driverFastestLap'];
    if (dfl is! Map) return null;
    final ln = dfl['lapNumber'];
    if (ln is num) return ln.toInt();
    return int.tryParse(ln?.toString() ?? '');
  }

  /// e.g. `1:28.778 (12)` when [driverFastestLap.lapNumber] is set in bundled JSON.
  static String openF1BundledFastestLapWithLapNumber(Map<String, dynamic> json) {
    final base = openF1BundledFastestLapDisplayString(json);
    return openF1AppendLapNumberInParens(
      base,
      _openF1LapNumberFromDriverFastestLap(json),
    );
  }

  static String openF1AppendLapNumberInParens(String lapTimeDisplay, int? lapNumber) {
    if (lapTimeDisplay.isEmpty ||
        lapTimeDisplay == '-' ||
        lapNumber == null ||
        lapNumber <= 0) {
      return lapTimeDisplay;
    }
    return '$lapTimeDisplay ($lapNumber)';
  }

  static bool _openF1TimeOrGapIsMeaningful(String? raw) {
    if (raw == null) return false;
    final s = raw.trim();
    if (s.isEmpty || s == '-') return false;
    return true;
  }

  /// Hub labels like `P2 (+0.298s)` / `P1 (-)` → finish position only (not all digits).
  static int? openF1PositionFromPLabel(String raw) {
    final m = RegExp(r'^P\s*(\d+)').firstMatch(raw.trim());
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  /// Weekend hub / bundled JSON: gap vs leader when `timeOrGap` / `gap_to_leader` are absent.
  static String openF1HubGapToLeaderLine(
    Map<String, dynamic> json,
    int finishPosition,
    double? leaderFastestLapSec,
  ) {
    if (finishPosition <= 1) return '-';
    final g = json['gap_to_leader'] ?? json['gapToLeader'];
    if (g is num) {
      final v = g.toDouble();
      final sign = v >= 0 ? '+' : '';
      return '$sign${v.toStringAsFixed(3)}s';
    }
    if (g is List) {
      for (var i = g.length - 1; i >= 0; i--) {
        final e = g[i];
        if (e is! num) continue;
        final v = e.toDouble();
        final sign = v >= 0 ? '+' : '';
        return '$sign${v.toStringAsFixed(3)}s';
      }
    }
    final gs = g?.toString().trim();
    if (gs != null && gs.isNotEmpty && gs != '-') {
      return gs;
    }
    final legacy = json['timeOrGap']?.toString().trim();
    if (legacy != null &&
        legacy.isNotEmpty &&
        legacy != '-' &&
        !legacy.toUpperCase().startsWith('P')) {
      return legacy;
    }
    final my = openF1ResultFastestLapSeconds(json);
    if (leaderFastestLapSec != null && my != null) {
      final delta = my - leaderFastestLapSec;
      if (delta.abs() < 1e-9) return '-';
      final sign = delta > 0 ? '+' : '';
      return '$sign${delta.toStringAsFixed(3)}s';
    }
    return '-';
  }

  /// P1 column: best lap from OpenF1 fields (bundled JSON has no reliable race-duration unit).
  static String openF1HubLeaderSessionTimeLine(
    Map<String, dynamic> json,
    SessionOverviewRow row,
  ) {
    final formatted = openF1BundledFastestLapWithLapNumber(json);
    if (formatted != '-') {
      return formatted;
    }
    final r = row.result.trim();
    if (r.isNotEmpty && r != '-') return r;
    return '-';
  }

  /// Per-driver `tyreStints` from bundled session results (`lapStart`/`lapEnd`, no `driver_number`).
  static ({
    int? totalLaps,
    Map<String, int> tyreLaps,
    List<SessionTyreLapBreakdownEntry> tyreLapSequence,
  }) openF1TyreStintsSummaryForDriver(List<dynamic>? stintsRaw) {
    if (stintsRaw == null || stintsRaw.isEmpty) {
      return (
        totalLaps: null,
        tyreLaps: const <String, int>{},
        tyreLapSequence: const <SessionTyreLapBreakdownEntry>[],
      );
    }
    var maxLap = 0;
    final sequence = <SessionTyreLapBreakdownEntry>[];
    final lapsByCompound = <String, int>{};
    for (final raw in stintsRaw) {
      if (raw is! Map) continue;
      final m = raw.map((k, v) => MapEntry(k.toString(), v));
      final lapStartRaw = m['lapStart'] ?? m['lap_start'];
      final lapEndRaw = m['lapEnd'] ?? m['lap_end'];
      final start = lapStartRaw is num
          ? lapStartRaw.toInt()
          : int.tryParse(lapStartRaw?.toString() ?? '');
      final end = lapEndRaw is num
          ? lapEndRaw.toInt()
          : int.tryParse(lapEndRaw?.toString() ?? '');
      if (start == null || end == null || end < start) continue;
      if (end > maxLap) maxLap = end;
      final lapCount = end - start + 1;
      if (lapCount <= 0) continue;
      final compound = openF1CompoundDisplay(m['compound']?.toString());
      final tyreAgeRaw = m['tyre_age_at_start'] ?? m['tyreAgeAtStart'];
      final usedTyre = tyreAgeRaw is num
          ? tyreAgeRaw.toInt() > 0
          : (int.tryParse(tyreAgeRaw?.toString() ?? '') ?? 0) > 0;
      if (compound != '-') {
        lapsByCompound[compound] =
            (lapsByCompound[compound] ?? 0) + lapCount;
        sequence.add(
          SessionTyreLapBreakdownEntry(
            compound: compound,
            laps: lapCount,
            usedTyre: usedTyre,
          ),
        );
      }
    }
    return (
      totalLaps: maxLap > 0 ? maxLap : null,
      tyreLaps: lapsByCompound,
      tyreLapSequence: sequence,
    );
  }

  static String openF1CompoundDisplay(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'SOFT':
        return 'Soft';
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      case 'INTERMEDIATE':
      case 'INTER':
        return 'Inter';
      case 'WET':
        return 'Wet';
      default:
        return '-';
    }
  }

  static int? openF1FastestLapLapNumber(Map<String, dynamic> json) {
    const keys = <String>[
      'fastest_lap_lap_number',
      'fastestLapLapNumber',
      'fastest_lap_number',
      'fastestLapNumber',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v is num) {
        final n = v.toInt();
        if (n > 0) return n;
      }
      final p = int.tryParse(v?.toString().trim() ?? '');
      if (p != null && p > 0) return p;
    }
    return null;
  }

  /// Tyre compound letter for the lap that set [fastestLapDuration], when lap number + stints allow it.
  static String openF1BestLapTyreAbbrev(Map<String, dynamic> json) {
    final lapNum = openF1FastestLapLapNumber(json);
    if (lapNum == null) return '—';
    final stints = json['tyreStints'] as List<dynamic>? ?? const [];
    for (final raw in stints) {
      if (raw is! Map) continue;
      final m = raw.map((k, v) => MapEntry(k.toString(), v));
      final lapStartRaw = m['lapStart'] ?? m['lap_start'];
      final lapEndRaw = m['lapEnd'] ?? m['lap_end'];
      final start = lapStartRaw is num
          ? lapStartRaw.toInt()
          : int.tryParse(lapStartRaw?.toString() ?? '');
      final end = lapEndRaw is num
          ? lapEndRaw.toInt()
          : int.tryParse(lapEndRaw?.toString() ?? '');
      if (start == null || end == null || end < start) continue;
      if (lapNum >= start && lapNum <= end) {
        return tyreCompoundDisplayToInsightsLetter(
          openF1CompoundDisplay(m['compound']?.toString()),
        );
      }
    }
    return '—';
  }

  static String tyreCompoundDisplayToInsightsLetter(String compound) {
    final t = compound.trim();
    if (t.isEmpty || t == '-') return '—';
    final u = t.toUpperCase();
    if (u.startsWith('SOFT')) return 'S';
    if (u.startsWith('MEDIUM')) return 'M';
    if (u.startsWith('HARD')) return 'H';
    if (u.startsWith('INTER')) return 'I';
    if (u.startsWith('WET')) return 'W';
    return t.substring(0, 1).toUpperCase();
  }

  static String openF1FinishLabel(dynamic gridRaw, dynamic finishRaw) {
    final finish = finishRaw is num
        ? finishRaw.toInt()
        : int.tryParse('${finishRaw ?? ''}'.trim());
    if (finish == null || finish <= 0) return 'NC';
    final grid = gridRaw is num
        ? gridRaw.toInt()
        : int.tryParse('${gridRaw ?? ''}'.trim());
    if (grid == null || grid <= 0) return 'P$finish (-)';
    final delta = grid - finish;
    if (delta == 0) return 'P$finish (-)';
    final sign = delta > 0 ? '+' : '';
    return 'P$finish ($sign$delta)';
  }

  /// Maps OpenF1 `status` (and grid / `finishPosition`) to a compact finish label.
  static String openF1RaceFinishFromSession(
    dynamic statusRaw,
    dynamic gridRaw,
    dynamic finishRaw,
  ) {
    final s = statusRaw?.toString().trim() ?? '';
    final upper = s.toUpperCase();

    bool lapDownFinisher() =>
        upper.startsWith('+') && upper.contains('LAP');

    if (upper.contains('DID NOT START') ||
        upper == 'DNS' ||
        (upper.contains('NOT START') && !upper.contains('FINISH'))) {
      return 'DNS';
    }
    if (upper.contains('DISQUALIF') || upper == 'DSQ') {
      return 'DSQ';
    }
    if (lapDownFinisher() ||
        upper == 'FINISHED' ||
        upper == '-' ||
        upper.isEmpty) {
      return openF1FinishLabel(gridRaw, finishRaw);
    }
    if (upper.contains('NOT CLASSIFIED')) {
      return 'NC';
    }

    const dnfHints = <String>[
      'RETIRED',
      'ACCIDENT',
      'MECHANICAL',
      'DNF',
      'ENGINE',
      'GEARBOX',
      'SUSPENSION',
      'HYDRAULIC',
      'ELECTRICAL',
      'OIL',
      'WHEEL',
      'TYRE',
      'TIRE',
      'BRAKE',
      'DRIVESHAFT',
      'SPUN OFF',
      'COLLISION',
      'PUNCTURE',
      'FUEL',
      'OVERHEAT',
      'VIBRATION',
      'POWER UNIT',
      'ERS',
      'CLUTCH',
      'DID NOT FINISH',
      'WITHDRAWN',
      'DAMAGE',
      'LOSS OF POWER',
      'WATER LEAK',
      'OIL LEAK',
    ];
    for (final hint in dnfHints) {
      if (upper.contains(hint)) {
        return 'DNF';
      }
    }

    return openF1FinishLabel(gridRaw, finishRaw);
  }

  static String formatOpenF1PitStopsLine(List<Map<String, dynamic>> pitStops) {
    if (pitStops.isEmpty) return '-';
    final parts = <String>[];
    for (final p in pitStops) {
      final lapRaw = p['lap'] ?? p['lapNumber'] ?? p['pit_lap'];
      final lap = lapRaw is num
          ? lapRaw.toInt()
          : int.tryParse(lapRaw?.toString().trim() ?? '');
      final durRaw =
          p['pit_duration'] ?? p['durationSeconds'] ?? p['laneDurationSeconds'];
      final dur = durRaw is num
          ? durRaw.toDouble()
          : double.tryParse(durRaw?.toString().trim() ?? '');
      if (lap == null || lap <= 0 || dur == null) continue;
      final durStr = dur == dur.roundToDouble()
          ? dur.toInt().toString()
          : dur.toStringAsFixed(1);
      parts.add('L$lap: ${durStr}s');
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  factory RaceResultRow.fromOpenF1BundledJson(
    Map<String, dynamic> json, {
    double? leaderFastestLapSec,
    double? sessionBestLapSec,
  }) {
    final broadcast = json['broadcastName']?.toString() ?? '-';
    final grid = json['gridPosition'];
    final start = grid == null ? '-' : grid.toString();
    final finish = openF1RaceFinishFromSession(
      json['status'],
      grid,
      json['finishPosition'],
    );
    final finishPos = json['finishPosition'] is num
        ? (json['finishPosition'] as num).toInt()
        : int.tryParse(json['finishPosition']?.toString() ?? '') ??
            0;
    final trimmedTimeOrGap = json['timeOrGap']?.toString().trim();
    final meaningfulGap = _openF1TimeOrGapIsMeaningful(trimmedTimeOrGap)
        ? trimmedTimeOrGap!
        : null;
    var timeOrGap = (finish == 'DNF' ||
            finish == 'DNS' ||
            finish == 'DSQ' ||
            finish == 'NC')
        ? '-'
        : (meaningfulGap ?? '-');
    if (timeOrGap == '-') {
      if (finishPos > 1 && leaderFastestLapSec != null) {
        final g = openF1HubGapToLeaderLine(
          json,
          finishPos,
          leaderFastestLapSec,
        );
        if (g != '-') {
          timeOrGap = g;
        }
      } else if (finishPos == 1) {
        final leaderFmt = openF1BundledFastestLapWithLapNumber(json);
        if (leaderFmt != '-') {
          timeOrGap = leaderFmt;
        }
      }
    }
    final pts = json['points'];
    final pointsStr = pts is num
        ? (pts == pts.roundToDouble()
            ? pts.toInt().toString()
            : pts.toString())
        : (pts?.toString() ?? '0');
    final fastest = openF1BundledFastestLapWithLapNumber(json);
    final myFastestSec = openF1ResultFastestLapSeconds(json);
    final hasOverallFastest = sessionBestLapSec != null &&
        myFastestSec != null &&
        (myFastestSec - sessionBestLapSec).abs() < 1e-6;
    final stintMaps = (json['tyreStints'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (e) => e.map((k, v) => MapEntry(k.toString(), v)),
        )
        .toList();
    final orderedCompounds = <String>[];
    for (final s in stintMaps) {
      final label = openF1CompoundDisplay(s['compound']?.toString());
      if (label != '-') orderedCompounds.add(label);
    }
    final tyreCompound =
        orderedCompounds.isNotEmpty ? orderedCompounds.last : '-';
    final tyreStrategy =
        orderedCompounds.isEmpty ? '-' : orderedCompounds.join(' -> ');
    final pitStops = (json['pitStops'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((p) {
          final m = Map<String, dynamic>.from(
            p.map((k, v) => MapEntry(k.toString(), v)),
          );
          final d = m['durationSeconds'] ?? m['laneDurationSeconds'];
          if (d != null && m['pit_duration'] == null) {
            m['pit_duration'] = d;
          }
          return m;
        })
        .toList();
    return RaceResultRow(
      driver: broadcast,
      start: start,
      finish: finish,
      timeOrGap: timeOrGap,
      fastestLap: fastest,
      tyreCompound: tyreCompound,
      penalty: json['penalty']?.toString() ?? '-',
      points: pointsStr,
      hasFastestLap: json['hasFastestLap'] == true || hasOverallFastest,
      tyreCompounds: List<String>.from(orderedCompounds),
      tyreStints: stintMaps,
      tyreStrategy: tyreStrategy,
      tyreChangeLaps: const [],
      penaltyDetails: const [],
      penaltyServed: false,
      penaltyServedLaps: const [],
      weatherSamples: const [],
      raceControlMessages: const [],
      pitStops: pitStops,
      totalPitTime: json['totalPitTime']?.toString() ?? '-',
      fastestPitStop: null,
      averagePitTime: json['averagePitTime']?.toString() ?? '-',
    );
  }

  factory RaceResultRow.fromJson(Map<String, dynamic> json) {
    if (_jsonLooksLikeOpenF1RaceResult(json)) {
      return RaceResultRow.fromOpenF1BundledJson(json);
    }
    return RaceResultRow(
      driver: json['driver']?.toString() ?? '-',
      start: json['start']?.toString() ?? '-',
      finish: json['finish']?.toString() ?? '-',
      timeOrGap: json['timeOrGap']?.toString() ?? '-',
      fastestLap: json['fastest_lap']?.toString() ?? '-',
      tyreCompound: json['tyreCompound']?.toString() ?? '-',
      penalty: json['penalty']?.toString() ?? '-',
      points: json['points']?.toString() ?? '0',
      hasFastestLap: json['hasFastestLap'] == true,
      tyreCompounds: (json['tyreCompounds'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      tyreStints: (json['tyreStints'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false),
      tyreStrategy: json['tyreStrategy']?.toString() ?? '-',
      tyreChangeLaps: (json['tyreChangeLaps'] as List<dynamic>? ?? const [])
          .map((entry) => int.tryParse(entry.toString()))
          .whereType<int>()
          .toList(growable: false),
      penaltyDetails: (json['penaltyDetails'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false),
      penaltyServed: json['penaltyServed'] == true,
      penaltyServedLaps:
          (json['penaltyServedLaps'] as List<dynamic>? ?? const [])
              .map((entry) => int.tryParse(entry.toString()))
              .whereType<int>()
              .toList(growable: false),
      weatherSamples: (json['weatherSamples'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false),
      raceControlMessages:
          (json['raceControlMessages'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map(
                (entry) =>
                    entry.map((key, value) => MapEntry(key.toString(), value)),
              )
              .toList(growable: false),
      pitStops: (json['pitStops'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false),
      totalPitTime: json['totalPitTime']?.toString() ?? '-',
      fastestPitStop: json['fastestPitStop'] is Map
          ? (json['fastestPitStop'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : null,
      averagePitTime: json['averagePitTime']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'start': start,
      'finish': finish,
      'timeOrGap': timeOrGap,
      'fastest_lap': fastestLap,
      'tyreCompound': tyreCompound,
      'penalty': penalty,
      'points': points,
      'hasFastestLap': hasFastestLap,
      'tyreCompounds': tyreCompounds,
      'tyreStints': tyreStints,
      'tyreStrategy': tyreStrategy,
      'tyreChangeLaps': tyreChangeLaps,
      'penaltyDetails': penaltyDetails,
      'penaltyServed': penaltyServed,
      'penaltyServedLaps': penaltyServedLaps,
      'weatherSamples': weatherSamples,
      'raceControlMessages': raceControlMessages,
      'pitStops': pitStops,
      'totalPitTime': totalPitTime,
      'fastestPitStop': fastestPitStop,
      'averagePitTime': averagePitTime,
    };
  }
}

class SessionOverviewRow {
  final String driver;
  final String position;
  final String result;
  final String fastestLap;
  final String tyreCompound;
  final String points;
  final bool hasFastestLap;
  final bool usedTyre;
  final int? tyreAgeAtStart;
  final int? totalLaps;
  final Map<String, int> tyreLaps;
  final List<SessionTyreLapBreakdownEntry> tyreLapSequence;

  const SessionOverviewRow({
    required this.driver,
    required this.position,
    required this.result,
    required this.fastestLap,
    required this.tyreCompound,
    required this.points,
    required this.hasFastestLap,
    required this.usedTyre,
    required this.tyreAgeAtStart,
    required this.totalLaps,
    required this.tyreLaps,
    required this.tyreLapSequence,
  });

  factory SessionOverviewRow.fromJson(Map<String, dynamic> json) {
    return SessionOverviewRow(
      driver: json['driver']?.toString() ?? '-',
      position: json['position']?.toString() ?? '-',
      result: json['result']?.toString() ?? '-',
      fastestLap: json['fastest_lap']?.toString() ?? '-',
      tyreCompound: json['tyreCompound']?.toString() ?? '-',
      points: json['points']?.toString() ?? '-',
      hasFastestLap: json['hasFastestLap'] == true,
      usedTyre: json['usedTyre'] == true,
      tyreAgeAtStart: int.tryParse(json['tyreAgeAtStart']?.toString() ?? ''),
      totalLaps: int.tryParse(json['totalLaps']?.toString() ?? ''),
      tyreLaps: ((json['tyreLaps'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) =>
            MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0),
      ),
      tyreLapSequence: (json['tyreLapSequence'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) => SessionTyreLapBreakdownEntry.fromJson(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
    );
  }

  factory SessionOverviewRow.fromOpenF1ResultMap(
    Map<String, dynamic> json, {
    double? leaderFastestLapSeconds,
    double? sessionBestLapSeconds,
  }) {
    final grid = json['gridPosition'];
    final finishLabel = RaceResultRow.openF1RaceFinishFromSession(
      json['status'],
      grid,
      json['finishPosition'],
    );
    final finishPos = json['finishPosition'] is num
        ? (json['finishPosition'] as num).toInt()
        : int.tryParse(json['finishPosition']?.toString() ?? '') ??
            0;
    final gapRaw = json['timeOrGap']?.toString().trim();
    final useGap =
        RaceResultRow._openF1TimeOrGapIsMeaningful(gapRaw) ? gapRaw! : null;
    var resultStr = (finishLabel == 'DNF' ||
            finishLabel == 'DNS' ||
            finishLabel == 'DSQ' ||
            finishLabel == 'NC')
        ? '-'
        : (useGap ?? '-');
    final fastestLapStr =
        RaceResultRow.openF1BundledFastestLapWithLapNumber(json);
    if (resultStr == '-' &&
        fastestLapStr != '-' &&
        finishLabel != 'DNF' &&
        finishLabel != 'DNS' &&
        finishLabel != 'DSQ' &&
        finishLabel != 'NC') {
      resultStr = fastestLapStr;
    }
    final pts = json['points'];
    final pointsStr = pts is num
        ? (pts % 1 == 0 ? pts.toInt().toString() : pts.toString())
        : (pts?.toString() ?? '-');
    var tyre = '-';
    final stints = (json['tyreStints'] as List<dynamic>? ?? const []);
    for (var i = stints.length - 1; i >= 0; i--) {
      final s = stints[i];
      if (s is! Map) continue;
      final c = RaceResultRow.openF1CompoundDisplay(s['compound']?.toString());
      if (c != '-') {
        tyre = c;
        break;
      }
    }
    final tyreSummary =
        RaceResultRow.openF1TyreStintsSummaryForDriver(stints);
    var positionStr = finishLabel;
    if (leaderFastestLapSeconds != null && finishPos > 0) {
      final gapLine = RaceResultRow.openF1HubGapToLeaderLine(
        json,
        finishPos,
        leaderFastestLapSeconds,
      );
      if (gapLine != '-') {
        positionStr = 'P$finishPos ($gapLine)';
      } else if (finishLabel.contains('(-)') && finishPos > 0) {
        positionStr = 'P$finishPos';
      }
    }
    final myFastest = RaceResultRow.openF1ResultFastestLapSeconds(json);
    final hasFastest = sessionBestLapSeconds != null &&
        myFastest != null &&
        (myFastest - sessionBestLapSeconds).abs() < 1e-6;
    return SessionOverviewRow(
      driver: json['broadcastName']?.toString() ?? '-',
      position: positionStr,
      result: resultStr,
      fastestLap: fastestLapStr,
      tyreCompound: tyre,
      points: pointsStr,
      hasFastestLap: hasFastest,
      usedTyre: false,
      tyreAgeAtStart: null,
      totalLaps: tyreSummary.totalLaps,
      tyreLaps: tyreSummary.tyreLaps,
      tyreLapSequence: tyreSummary.tyreLapSequence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'position': position,
      'result': result,
      'fastest_lap': fastestLap,
      'tyreCompound': tyreCompound,
      'points': points,
      'hasFastestLap': hasFastestLap,
      'usedTyre': usedTyre,
      'tyreAgeAtStart': tyreAgeAtStart,
      'totalLaps': totalLaps,
      'tyreLaps': tyreLaps,
      'tyreLapSequence': tyreLapSequence
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}

class SessionTyreLapBreakdownEntry {
  final String compound;
  final int laps;
  final bool usedTyre;

  const SessionTyreLapBreakdownEntry({
    required this.compound,
    required this.laps,
    required this.usedTyre,
  });

  factory SessionTyreLapBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return SessionTyreLapBreakdownEntry(
      compound: json['compound']?.toString() ?? '-',
      laps: int.tryParse(json['laps']?.toString() ?? '') ?? 0,
      usedTyre: json['usedTyre'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'compound': compound, 'laps': laps, 'usedTyre': usedTyre};
  }
}

class FastestLapDetails {
  final double duration;
  final int lapNumber;
  final String compound;

  const FastestLapDetails({
    required this.duration,
    required this.lapNumber,
    required this.compound,
  });
}

class _TyreUsageDetails {
  final String compound;
  final int? tyreAgeAtStart;

  const _TyreUsageDetails({
    required this.compound,
    required this.tyreAgeAtStart,
  });

  bool get usedTyre => (tyreAgeAtStart ?? 0) > 0;

  String get formattedCompound {
    if (compound == '-' || compound.isEmpty) {
      return '-';
    }
    return usedTyre ? '$compound (used)' : compound;
  }
}

class _SessionLapSummary {
  final int totalLaps;
  final Map<String, int> lapsByCompound;
  final List<SessionTyreLapBreakdownEntry> stintSequence;

  const _SessionLapSummary({
    required this.totalLaps,
    required this.lapsByCompound,
    required this.stintSequence,
  });
}

class _MutableSessionLapSummary {
  int totalLaps = 0;
  final Map<String, int> lapsByCompound = <String, int>{};
  final List<SessionTyreLapBreakdownEntry> stintSequence =
      <SessionTyreLapBreakdownEntry>[];

  _SessionLapSummary build() {
    return _SessionLapSummary(
      totalLaps: totalLaps,
      lapsByCompound: Map<String, int>.from(lapsByCompound),
      stintSequence: List<SessionTyreLapBreakdownEntry>.from(stintSequence),
    );
  }
}

class WeekendHubPodiumEntry {
  final int position;
  final int? driverNumber;
  final String driver;
  final String points;
  final String totalTime;
  final String gapToLeader;
  final String fastestLap;
  final bool hasFastestLap;
  final List<String> tyreCompounds;
  /// Single-letter tyre code on best lap when known (S/M/H/…); em dash when unknown.
  final String bestLapTyreAbbrev;

  const WeekendHubPodiumEntry({
    required this.position,
    required this.driverNumber,
    required this.driver,
    required this.points,
    required this.totalTime,
    required this.gapToLeader,
    required this.fastestLap,
    required this.hasFastestLap,
    required this.tyreCompounds,
    required this.bestLapTyreAbbrev,
  });
}

class WeekendHubPodiumFetchResult {
  final List<WeekendHubPodiumEntry> podium;

  const WeekendHubPodiumFetchResult({
    required this.podium,
  });
}

class DriverFormEntry {
  final Race race;
  final String sessionName; // 'Race' of 'Sprint'
  final int? finishPosition;
  final double points;
  final bool hasFastestLap;
  final bool hasPenalty;

  const DriverFormEntry({
    required this.race,
    required this.sessionName,
    required this.finishPosition,
    required this.points,
    required this.hasFastestLap,
    required this.hasPenalty,
  });

  bool get isPodium => finishPosition != null && finishPosition! <= 3;
  bool get isDnf => finishPosition == null;

  String get label => finishPosition == null ? 'DNF' : 'P$finishPosition';
}

bool _driverNameMatches(String cachedName, String targetName) {
  final cached = cachedName.trim().toLowerCase();
  final target = targetName.trim().toLowerCase();
  if (cached == target) {
    return true;
  }

  final cachedParts = cached.split(RegExp(r'\s+'));
  final targetParts = target.split(RegExp(r'\s+'));
  if (cachedParts.isEmpty || targetParts.isEmpty) {
    return false;
  }

  return cachedParts.last == targetParts.last;
}

int? _extractFinishPosition(String finish) {
  final match = RegExp(r'P(\d+)').firstMatch(finish.toUpperCase());
  return match == null ? null : int.tryParse(match.group(1)!);
}

double _parsePointsValue(String points) {
  return double.tryParse(points.trim()) ?? 0;
}

/// Retourneert een lijst van lijsten: per raceweekend maximaal 2 entries (Sprint, Race)
List<List<DriverFormEntry>> _buildDriverRecentFormEntries(String driverName) {
  final now = DateTime.now();
  final completedRaces = races.where((race) => !race.date.isAfter(now)).toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final List<List<DriverFormEntry>> result = [];
  for (final race in completedRaces) {
      final List<DriverFormEntry> weekendEntries = [];
    // Eerst sprint (indien aanwezig)
    if (race.hasSprint) {
      final sprintKey = '${race.country}_Sprint_${race.date.year}';
      final sprintRows = SessionDataManager().raceResultsCache[sprintKey];
      if (sprintRows != null && sprintRows.isNotEmpty) {
        RaceResultRow? sprintRow;
        for (final candidate in sprintRows) {
          if (_driverNameMatches(candidate.driver, driverName)) {
            sprintRow = candidate;
            break;
          }
        }
        if (sprintRow != null) {
          weekendEntries.add(DriverFormEntry(
            race: race,
            sessionName: 'Sprint',
            finishPosition: _extractFinishPosition(sprintRow.finish),
            points: _parsePointsValue(sprintRow.points),
            hasFastestLap: sprintRow.hasFastestLap,
            hasPenalty: sprintRow.penalty.trim() != '-' && sprintRow.penalty.trim().isNotEmpty,
          ));
        }
      }
    }
    // Daarna hoofdrace
    final raceKey = SessionDataManager().raceResultsKeyFor(race);
    final raceRows = SessionDataManager().raceResultsCache[raceKey];
    if (raceRows != null && raceRows.isNotEmpty) {
      RaceResultRow? raceRow;
      for (final candidate in raceRows) {
        if (_driverNameMatches(candidate.driver, driverName)) {
          raceRow = candidate;
          break;
        }
      }
      if (raceRow != null) {
        weekendEntries.add(DriverFormEntry(
          race: race,
          sessionName: 'Race',
          finishPosition: _extractFinishPosition(raceRow.finish),
          points: _parsePointsValue(raceRow.points),
          hasFastestLap: raceRow.hasFastestLap,
          hasPenalty: raceRow.penalty.trim() != '-' && raceRow.penalty.trim().isNotEmpty,
        ));
      }
    }
    if (weekendEntries.isNotEmpty) {
      result.add(weekendEntries);
    }
    if (result.length == 5) {
      break;
    }
  }
  return result;
}

double? _averageDriverFinish(List<List<DriverFormEntry>> entryGroups) {
  final finishes = entryGroups.expand((e) => e)
      .where((entry) => entry.finishPosition != null)
      .map((entry) => entry.finishPosition!.toDouble())
      .toList();
  if (finishes.isEmpty) {
    return null;
  }
  return finishes.reduce((a, b) => a + b) / finishes.length;
}

double _sumDriverPoints(List<List<DriverFormEntry>> entryGroups) {
  return entryGroups.expand((e) => e).fold<double>(0, (sum, entry) => sum + entry.points);
}

String _formatDriverAverageFinish(List<List<DriverFormEntry>> entryGroups) {
  final average = _averageDriverFinish(entryGroups);
  if (average == null) {
    return '-';
  }
  return average.toStringAsFixed(1);
}

String _formatFormPoints(List<List<DriverFormEntry>> entryGroups) {
  final total = _sumDriverPoints(entryGroups);
  return total == total.roundToDouble()
      ? total.toInt().toString()
      : total.toStringAsFixed(1);
}

Driver? _driverForSeason(String driverName, int year) {
  final seasonDrivers = driversData[year] ?? const <Driver>[];
  for (final driver in seasonDrivers) {
    if (_driverNameMatches(driver.name, driverName)) {
      return driver;
    }
  }
  return null;
}

List<int> _sharedDriverComparisonYears(String driverName1, String driverName2) {
  final years = <int>[];
  for (final year in driversData.keys) {
    if (_driverForSeason(driverName1, year) != null &&
        _driverForSeason(driverName2, year) != null) {
      years.add(year);
    }
  }
  years.sort((a, b) => b.compareTo(a));
  return years;
}

class SeasonalDriverComparisonStats {
  final double points;
  final List<SeasonRacePointsEntry> pointsByRace;
  final int poles;
  final int fastestLaps;
  final double dnfPercentage;
  final int podiums;
  final String highestFinish;
  final String highestGrid;
  final double winRate;

  const SeasonalDriverComparisonStats({
    required this.points,
    required this.pointsByRace,
    required this.poles,
    required this.fastestLaps,
    required this.dnfPercentage,
    required this.podiums,
    required this.highestFinish,
    required this.highestGrid,
    required this.winRate,
  });

  factory SeasonalDriverComparisonStats.fromJson(Map<String, dynamic> json) {
    return SeasonalDriverComparisonStats(
      points: (json['points'] as num?)?.toDouble() ?? 0,
      pointsByRace:
          (json['pointsByRace'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => SeasonRacePointsEntry.fromJson(
                  entry.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList() ??
          const <SeasonRacePointsEntry>[],
      poles: (json['poles'] as num?)?.toInt() ?? 0,
      fastestLaps: (json['fastestLaps'] as num?)?.toInt() ?? 0,
      dnfPercentage: (json['dnfPercentage'] as num?)?.toDouble() ?? 0,
      podiums: (json['podiums'] as num?)?.toInt() ?? 0,
      highestFinish: json['highest_finish']?.toString() ?? '-',
      highestGrid: json['highest_grid']?.toString() ?? '-',
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'pointsByRace': pointsByRace.map((entry) => entry.toJson()).toList(),
      'poles': poles,
      'fastestLaps': fastestLaps,
      'dnfPercentage': dnfPercentage,
      'podiums': podiums,
      'highest_finish': highestFinish,
      'highest_grid': highestGrid,
      'winRate': winRate,
    };
  }
}

class SeasonRacePointsEntry {
  final int round;
  final String raceName;
  final double points;

  const SeasonRacePointsEntry({
    required this.round,
    required this.raceName,
    required this.points,
  });

  factory SeasonRacePointsEntry.fromJson(Map<String, dynamic> json) {
    return SeasonRacePointsEntry(
      round: (json['round'] as num?)?.toInt() ?? 0,
      raceName: json['raceName']?.toString() ?? '-',
      points: (json['points'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'round': round, 'raceName': raceName, 'points': points};
  }
}

class DriverStandingsChartSeries {
  final String driverName;
  final List<SeasonRacePointsEntry> pointsByRace;
  final Color color;

  const DriverStandingsChartSeries({
    required this.driverName,
    required this.pointsByRace,
    required this.color,
  });
}

class DriverStandingsChartData {
  final int year;
  final List<String> circuitLabels;
  final List<DriverStandingsChartSeries> series;
  final double maxPoints;

  const DriverStandingsChartData({
    required this.year,
    required this.circuitLabels,
    required this.series,
    required this.maxPoints,
  });
}

class TeamStandingsChartSeries {
  final String teamName;
  final List<SeasonRacePointsEntry> pointsByRace;
  final Color color;

  const TeamStandingsChartSeries({
    required this.teamName,
    required this.pointsByRace,
    required this.color,
  });
}

class TeamStandingsChartData {
  final int year;
  final List<String> circuitLabels;
  final List<TeamStandingsChartSeries> series;
  final double maxPoints;

  const TeamStandingsChartData({
    required this.year,
    required this.circuitLabels,
    required this.series,
    required this.maxPoints,
  });
}

final Map<String, Future<SeasonalDriverComparisonStats?>>
_seasonalDriverComparisonStatsCache =
    <String, Future<SeasonalDriverComparisonStats?>>{};
Future<Map<int, Map<String, SeasonalDriverComparisonStats>>>?
_seasonalDriverComparisonAssetCache;
final Map<int, Future<DriverStandingsChartData?>>
_driverStandingsChartDataCache = <int, Future<DriverStandingsChartData?>>{};
final Map<int, Future<TeamStandingsChartData?>>
_teamStandingsChartDataCache = <int, Future<TeamStandingsChartData?>>{};

Future<Map<int, Map<String, SeasonalDriverComparisonStats>>>
_loadSeasonalDriverComparisonAssetCache() {
  return _seasonalDriverComparisonAssetCache ??=
      _readSeasonalDriverComparisonAssetCache();
}

Future<DriverStandingsChartData?> _fetchDriverStandingsChartData(int year) {
  return _driverStandingsChartDataCache.putIfAbsent(
    year,
    () => _loadDriverStandingsChartData(year),
  );
}

Future<DriverStandingsChartData?> _loadDriverStandingsChartData(
  int year,
) async {
  return _loadDriverStandingsChartDataFromAsset(year);
}

Future<DriverStandingsChartData?> _loadDriverStandingsChartDataFromAsset(
  int year,
) async {
  try {
    standingsPath:
    for (final driversStandingsPath
        in F1AssetResolver.driversStandingsCandidatePaths(year)) {
      try {
      final raw = await rootBundle.loadString(driversStandingsPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final roundsRaw = decoded['rounds'];
        if (roundsRaw is List) {
          double pointsReceivedForSession(dynamic sessionData) {
            if (sessionData is! Map) return 0.0;
            final received = sessionData['points_received'];
            if (received is num) return received.toDouble();
            final start = sessionData['points_start'];
            final finish = sessionData['points_finish'];
            if (start is num && finish is num) {
              return finish.toDouble() - start.toDouble();
            }
            return 0.0;
          }
          final allDrivers = <String>{};
          final pointsDeltaByRound = <int, Map<String, double>>{};
          final labels = <String>[];
          for (final entry in roundsRaw) {
            if (entry is! Map) continue;
            final roundStr = entry['round']?.toString();
            final round = int.tryParse(roundStr ?? '');
            if (round == null) continue;
            final drivers = entry['drivers'];
            if (drivers is! Map) continue;
            final raceName = _raceNameForRound(year, round);
            labels.add(_abbreviateRaceLabel(raceName));
            final deltas = <String, double>{};
            for (final driverEntry in drivers.entries) {
              final driverName = driverEntry.key.toString();
              final driverData = driverEntry.value;
              if (driverData is! Map) continue;
              allDrivers.add(driverName);
              double roundPoints = 0.0;
              for (final sessionKey in ['Sprint', 'Race']) {
                final session = driverData[sessionKey];
                if (session is Map) {
                  roundPoints += pointsReceivedForSession(session);
                }
              }
              if (roundPoints != 0.0) deltas[driverName] = roundPoints;
            }
            pointsDeltaByRound[round] = deltas;
          }
          if (allDrivers.isEmpty || pointsDeltaByRound.isEmpty) {
            continue standingsPath;
          }
          final standings = decoded['standings'];
          if (standings is List) {
            for (final entry in standings) {
              if (entry is Map && entry['driver'] != null) {
                allDrivers.add(entry['driver'].toString());
              }
            }
          }
          final cumulativeByDriver = <String, List<SeasonRacePointsEntry>>{
            for (final d in allDrivers) d: [],
          };
          final totals = <String, double>{for (final d in allDrivers) d: 0.0};
          final allRounds = pointsDeltaByRound.keys.toList()..sort();
          final sortedRounds = allRounds.where((round) {
            final deltas = pointsDeltaByRound[round] ?? const {};
            return deltas.values.any((v) => v > 0);
          }).toList();
          for (final round in sortedRounds) {
            final deltas = pointsDeltaByRound[round] ?? const {};
            final raceName = _raceNameForRound(year, round);
            for (final driver in allDrivers) {
              totals[driver] = (totals[driver] ?? 0.0) + (deltas[driver] ?? 0.0);
              cumulativeByDriver[driver]!.add(SeasonRacePointsEntry(
                round: round,
                raceName: raceName,
                points: totals[driver]!,
              ));
            }
          }
          final sortedDrivers = cumulativeByDriver.keys.toList()
            ..sort((a, b) {
              final aLast = cumulativeByDriver[a]!.isNotEmpty
                  ? cumulativeByDriver[a]!.last.points
                  : 0.0;
              final bLast = cumulativeByDriver[b]!.isNotEmpty
                  ? cumulativeByDriver[b]!.last.points
                  : 0.0;
              return bLast.compareTo(aLast);
            });
          final series = <DriverStandingsChartSeries>[];
          double maxPoints = 0.0;
          for (var i = 0; i < sortedDrivers.length; i++) {
            final driverName = sortedDrivers[i];
            final pointsByRace = cumulativeByDriver[driverName]!;
            if (pointsByRace.isNotEmpty) {
              maxPoints = math.max(maxPoints, pointsByRace.last.points);
            }
            series.add(DriverStandingsChartSeries(
              driverName: driverName,
              pointsByRace: pointsByRace,
              color: _chartColorForDriver(driverName, year, i),
            ));
          }
          if (series.isEmpty) continue standingsPath;
          return DriverStandingsChartData(
            year: year,
            circuitLabels: labels,
            series: series,
            maxPoints: maxPoints <= 0 ? 1 : maxPoints,
          );
        }
      }
      if (year == 2026 && decoded is List) {
        final List<dynamic> data = decoded;
        final Map<int, String> driverNumberToName = {};
        if (driversData.containsKey(2026)) {
          for (final driver in driversData[2026]!) {
            driverNumberToName[driver.number] = driver.name;
          }
        }
        final Map<int, List<Map<String, dynamic>>> bySession = {};
        for (final entry in data) {
          final map = entry as Map<String, dynamic>;
          final sessionKey = map['session_key'] as int? ?? map['meeting_key'] as int?;
          if (sessionKey != null) {
            final sessionStandings = map['standings'] as List? ?? [map];
            for (final s in sessionStandings) {
              if (s is Map<String, dynamic>) {
                bySession.putIfAbsent(sessionKey, () => []).add(s);
              }
            }
            if (sessionStandings.isEmpty) {
              bySession.putIfAbsent(sessionKey, () => []).add(map);
            }
          }
        }
        final sessionKeys = bySession.keys.toList()..sort();
        final Map<String, List<SeasonRacePointsEntry>> driverPointsByRace = {};
        final Map<String, double> driverTotalPoints = {};
        int round = 1;
        for (final sessionKey in sessionKeys) {
          final raceEntries = bySession[sessionKey]!;
          for (final entry in raceEntries) {
            final driverNumber = entry['driver_number'];
            if (driverNumber == null) continue;
            final driverName = driverNumberToName[driverNumber] ?? 'Driver $driverNumber';
            final points = (entry['points_current'] as num?)?.toDouble() ?? 0.0;
            final raceName = 'Race $round';
            driverPointsByRace.putIfAbsent(driverName, () => []);
            driverPointsByRace[driverName]!.add(SeasonRacePointsEntry(
              round: round,
              raceName: raceName,
              points: points,
            ));
            driverTotalPoints[driverName] = points;
          }
          round++;
        }
        // Build chart series
        final List<DriverStandingsChartSeries> series = [];
      double maxPoints = 0.0;
      int index = 0;
      for (final entry in driverPointsByRace.entries) {
        final driverName = entry.key;
        final pointsByRace = entry.value;
        final totalPoints = driverTotalPoints[driverName] ?? 0.0;
        maxPoints = math.max(maxPoints, totalPoints);
        series.add(DriverStandingsChartSeries(
          driverName: driverName,
          pointsByRace: pointsByRace,
          color: _chartColorForDriver(driverName, year, index),
        ));
        index++;
      }
        if (series.isEmpty) {
          continue standingsPath;
        }
        series.sort((left, right) =>
          (right.pointsByRace.isEmpty ? 0.0 : right.pointsByRace.last.points)
              .compareTo(left.pointsByRace.isEmpty ? 0.0 : left.pointsByRace.last.points));
        final labels = [for (var i = 1; i < round; i++) 'R$i'];
        return DriverStandingsChartData(
          year: year,
          circuitLabels: labels,
          series: series,
          maxPoints: maxPoints <= 0 ? 1 : maxPoints,
        );
      }
      } catch (_) {}
    }
    if (year >= 2017 && year <= 2025) {
      final raw = await rootBundle.loadString(
        'data/results/drivers/driver_comparison_stats_$year.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final drivers =
          decoded['drivers'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final series = <DriverStandingsChartSeries>[];
      var maxPoints = 0.0;

      var index = 0;
      for (final entry in drivers.entries) {
        final stats = SeasonalDriverComparisonStats.fromJson(
          (entry.value as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
        if (stats.pointsByRace.isEmpty) {
          continue;
        }
        maxPoints = math.max(maxPoints, stats.points);
        series.add(
          DriverStandingsChartSeries(
            driverName: entry.key,
            pointsByRace: stats.pointsByRace,
            color: _chartColorForDriver(entry.key, year, index),
          ),
        );
        index += 1;
      }

      if (series.isEmpty) {
        return null;
      }

      series.sort(
        (left, right) =>
            (right.pointsByRace.isEmpty ? 0.0 : right.pointsByRace.last.points)
                .compareTo(
                  left.pointsByRace.isEmpty ? 0.0 : left.pointsByRace.last.points,
                ),
      );
      final labels = _buildCircuitLabels(series);

      return DriverStandingsChartData(
        year: year,
        circuitLabels: labels,
        series: series,
        maxPoints: maxPoints <= 0 ? 1 : maxPoints,
      );
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<TeamStandingsChartData?> _fetchTeamStandingsChartData(int year) {
  return _teamStandingsChartDataCache.putIfAbsent(
    year,
    () => _loadTeamStandingsChartDataFromAsset(year),
  );
}

Future<TeamStandingsChartData?> _loadTeamStandingsChartDataFromAsset(
  int year,
) async {
  for (final teamsStandingsPath
      in F1AssetResolver.teamsStandingsCandidatePaths(year)) {
  try {
    final raw = await rootBundle.loadString(teamsStandingsPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) continue;
    final roundsRaw = decoded['rounds'];
    if (roundsRaw is! List) continue;

    double pointsReceivedForSession(dynamic sessionData) {
      if (sessionData is! Map) return 0.0;
      final received = sessionData['points_received'];
      if (received is num) return received.toDouble();
      final start = sessionData['points_start'];
      final finish = sessionData['points_finish'];
      if (start is num && finish is num) {
        return finish.toDouble() - start.toDouble();
      }
      return 0.0;
    }

    final allTeams = <String>{};
    final pointsDeltaByRound = <int, Map<String, double>>{};
    final labels = <String>[];

    for (final entry in roundsRaw) {
      if (entry is! Map) continue;
      final roundStr = entry['round']?.toString();
      final round = int.tryParse(roundStr ?? '');
      if (round == null) continue;
      final teams = entry['teams'];
      if (teams is! Map) continue;
      final raceName = _raceNameForRound(year, round);
      labels.add(_abbreviateRaceLabel(raceName));
      final deltas = <String, double>{};
      for (final teamEntry in teams.entries) {
        final teamName = teamEntry.key.toString();
        final teamData = teamEntry.value;
        if (teamData is! Map) continue;
        allTeams.add(teamName);
        double roundPoints = 0.0;
        for (final sessionKey in ['Sprint', 'Race']) {
          final session = teamData[sessionKey];
          if (session is Map) {
            roundPoints += pointsReceivedForSession(session);
          }
        }
        if (roundPoints != 0.0) deltas[teamName] = roundPoints;
      }
      pointsDeltaByRound[round] = deltas;
    }

    if (allTeams.isEmpty || pointsDeltaByRound.isEmpty) continue;

    final standings = decoded['standings'];
    if (standings is List) {
      for (final entry in standings) {
        if (entry is Map && entry['team'] != null) {
          allTeams.add(entry['team'].toString());
        }
      }
    }

    final cumulativeByTeam = <String, List<SeasonRacePointsEntry>>{
      for (final t in allTeams) t: [],
    };
    final totals = <String, double>{for (final t in allTeams) t: 0.0};
    final allRounds = pointsDeltaByRound.keys.toList()..sort();
    final sortedRounds = allRounds.where((round) {
      final deltas = pointsDeltaByRound[round] ?? const {};
      return deltas.values.any((v) => v > 0);
    }).toList();

    for (final round in sortedRounds) {
      final deltas = pointsDeltaByRound[round] ?? const {};
      final raceName = _raceNameForRound(year, round);
      for (final team in allTeams) {
        totals[team] = (totals[team] ?? 0.0) + (deltas[team] ?? 0.0);
        cumulativeByTeam[team]!.add(SeasonRacePointsEntry(
          round: round,
          raceName: raceName,
          points: totals[team]!,
        ));
      }
    }

    final sortedTeams = cumulativeByTeam.keys.toList()
      ..sort((a, b) {
        final aLast = cumulativeByTeam[a]!.isNotEmpty
            ? cumulativeByTeam[a]!.last.points
            : 0.0;
        final bLast = cumulativeByTeam[b]!.isNotEmpty
            ? cumulativeByTeam[b]!.last.points
            : 0.0;
        return bLast.compareTo(aLast);
      });

    final series = <TeamStandingsChartSeries>[];
    double maxPoints = 0.0;
    for (var i = 0; i < sortedTeams.length; i++) {
      final teamName = sortedTeams[i];
      final pointsByRace = cumulativeByTeam[teamName]!;
      if (pointsByRace.isNotEmpty) {
        maxPoints = math.max(maxPoints, pointsByRace.last.points);
      }
      series.add(TeamStandingsChartSeries(
        teamName: teamName,
        pointsByRace: pointsByRace,
        color: F1TeamSchemes.getTeamColor(teamName),
      ));
    }
    if (series.isEmpty) continue;
    return TeamStandingsChartData(
      year: year,
      circuitLabels: labels,
      series: series,
      maxPoints: maxPoints <= 0 ? 1 : maxPoints,
    );
  } catch (_) {}
  }
  return null;
}

// All API calls removed. Only local data is used.

List<String> _buildCircuitLabels(List<DriverStandingsChartSeries> series) {
  final labelsByRound = <int, String>{};
  for (final driverSeries in series) {
    for (final entry in driverSeries.pointsByRace) {
      labelsByRound.putIfAbsent(
        entry.round,
        () => _abbreviateRaceLabel(entry.raceName),
      );
    }
  }

  final rounds = labelsByRound.keys.toList()..sort();
  return rounds
      .map((round) => labelsByRound[round] ?? round.toString())
      .toList();
}

String _raceNameForRound(int year, int round) {
  if (year == 2026 && round >= 1 && round <= races.length) {
    return races[round - 1].name;
  }
  return 'Round $round';
}

String _abbreviateRaceLabel(String raceName) {
  final cleaned = raceName.replaceAll(' Grand Prix', '').trim();
  if (cleaned.isEmpty) {
    return '-';
  }
  final words = cleaned.split(RegExp(r'\s+'));
  if (words.length == 1) {
    final word = words.first;
    return word.length <= 3
        ? word.toUpperCase()
        : word.substring(0, 3).toUpperCase();
  }
  return words.take(3).map((word) => word.substring(0, 1).toUpperCase()).join();
}

Color _chartColorForDriver(String driverName, int year, int index) {
  final hue = (index * 37) % 360;
  final fallback = HSVColor.fromAHSV(1, hue.toDouble(), 0.72, 0.92).toColor();
  final driver = _driverForSeason(driverName, year);
  if (driver == null) {
    return fallback;
  }
  final teamColor = F1TeamSchemes.getTeamColor(driver.team);
  return Color.lerp(teamColor, fallback, 0.35) ?? teamColor;
}

Future<Map<int, Map<String, SeasonalDriverComparisonStats>>>
_readSeasonalDriverComparisonAssetCache() async {
  final resolved = <int, Map<String, SeasonalDriverComparisonStats>>{};
  for (var year = 2017; year <= 2025; year++) {
    try {
      final raw = await rootBundle.loadString(
        'data/results/drivers/driver_comparison_stats_$year.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final drivers =
          decoded['drivers'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final driverStats = <String, SeasonalDriverComparisonStats>{};
      for (final entry in drivers.entries) {
        driverStats[entry.key] = SeasonalDriverComparisonStats.fromJson(
          (entry.value as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      }
      resolved[year] = driverStats;
    } catch (_) {
      // Skip year if file missing or invalid
    }
  }
  return resolved;
}

bool _apiDriverEntryMatches(dynamic driverData, String driverName) {
  if (driverData is! Map) {
    return false;
  }

  final givenName = driverData['givenName']?.toString() ?? '';
  final familyName = driverData['familyName']?.toString() ?? '';
  final fullName = '$givenName $familyName'.trim();
  final normalizedTarget = _normalizeDriverLookupName(driverName);
  final normalizedFull = _normalizeDriverLookupName(fullName);
  final normalizedFamily = _normalizeDriverLookupName(familyName);
  final targetParts = normalizedTarget.split(' ');
  final targetFamily = targetParts.isEmpty
      ? normalizedTarget
      : targetParts.last;

  return normalizedFull == normalizedTarget || normalizedFamily == targetFamily;
}

bool _isRetirementStatus(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized.isEmpty) {
    return false;
  }
  if (normalized == 'FINISHED' || normalized == 'DISQUALIFIED') {
    return false;
  }
  if (RegExp(r'^\+\d+\s+LAPS?$').hasMatch(normalized)) {
    return false;
  }
  return true;
}

Future<SeasonalDriverComparisonStats?> _fetchSeasonalDriverComparisonStats(
  String driverName,
  int year,
) {
  final cacheKey = '$year|$driverName';
  return _seasonalDriverComparisonStatsCache.putIfAbsent(cacheKey, () async {
    final assetCache = await _loadSeasonalDriverComparisonAssetCache();
    final cachedStats =
        assetCache[year]?[_normalizeDriverLookupName(driverName)];
    if (cachedStats != null) {
      return cachedStats;
    }

    final standingsResponse = await http
        .get(
          Uri.parse(
            'https://api.jolpi.ca/ergast/f1/$year/driverStandings.json',
          ),
        )
        .timeout(const Duration(seconds: 4));

    if (standingsResponse.statusCode != 200) {
      return null;
    }

    final standingsData = json.decode(standingsResponse.body);
    final standingsLists =
        standingsData['MRData']?['StandingsTable']?['StandingsLists']
            as List? ??
        const <dynamic>[];
    if (standingsLists.isEmpty) {
      return null;
    }

    final driverStandings =
        standingsLists.first['DriverStandings'] as List? ?? const <dynamic>[];
    Map<String, dynamic>? standingEntry;
    for (final entry in driverStandings.whereType<Map>()) {
      if (_apiDriverEntryMatches(entry['Driver'], driverName)) {
        standingEntry = entry.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        break;
      }
    }
    if (standingEntry == null) {
      return null;
    }

    final driverId = standingEntry['Driver'] is Map
        ? (standingEntry['Driver'] as Map)['driverId']?.toString()
        : null;
    if (driverId == null || driverId.isEmpty) {
      return null;
    }

    final points =
        double.tryParse(standingEntry['points']?.toString() ?? '') ?? 0;

    final resultsResponse = await http
        .get(
          Uri.parse(
            'https://api.jolpi.ca/ergast/f1/$year/drivers/$driverId/results.json?limit=100',
          ),
        )
        .timeout(const Duration(seconds: 4));
    final qualifyingResponse = await http
        .get(
          Uri.parse(
            'https://api.jolpi.ca/ergast/f1/$year/drivers/$driverId/qualifying.json?limit=100',
          ),
        )
        .timeout(const Duration(seconds: 4));

    if (resultsResponse.statusCode != 200 ||
        qualifyingResponse.statusCode != 200) {
      return null;
    }

    final resultsData = json.decode(resultsResponse.body);
    final qualifyingData = json.decode(qualifyingResponse.body);
    final resultRaces =
        resultsData['MRData']?['RaceTable']?['Races'] as List? ??
        const <dynamic>[];
    final qualifyingRaces =
        qualifyingData['MRData']?['RaceTable']?['Races'] as List? ??
        const <dynamic>[];

    var wins = 0;
    var podiums = 0;
    var fastestLaps = 0;
    var dnfs = 0;
    int? highestFinish;
    int? highestGrid;
    var runningPoints = 0.0;
    final pointsByRace = <SeasonRacePointsEntry>[];

    for (final race in resultRaces.whereType<Map>()) {
      final results = race['Results'] as List? ?? const <dynamic>[];
      if (results.isEmpty || results.first is! Map) {
        continue;
      }
      final result = (results.first as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final finishPosition = int.tryParse(result['position']?.toString() ?? '');
      if (finishPosition != null) {
        if (finishPosition == 1) {
          wins += 1;
        }
        if (finishPosition <= 3) {
          podiums += 1;
        }
        highestFinish = highestFinish == null
            ? finishPosition
            : math.min(highestFinish, finishPosition).toInt();
      }

      final fastestLapRank = result['FastestLap'] is Map
          ? (result['FastestLap'] as Map)['rank']?.toString()
          : null;
      if (fastestLapRank == '1') {
        fastestLaps += 1;
      }

      if (_isRetirementStatus(result['status']?.toString() ?? '')) {
        dnfs += 1;
      }

      final grid = int.tryParse(result['grid']?.toString() ?? '');
      if (grid != null && grid > 0) {
        highestGrid = highestGrid == null
            ? grid
            : math.min(highestGrid, grid).toInt();
      }

      final racePoints =
          double.tryParse(result['points']?.toString() ?? '') ?? 0.0;
      runningPoints += racePoints;
      pointsByRace.add(
        SeasonRacePointsEntry(
          round:
              int.tryParse(race['round']?.toString() ?? '') ??
              pointsByRace.length + 1,
          raceName: race['raceName']?.toString() ?? '-',
          points: runningPoints,
        ),
      );
    }

    var poles = 0;
    for (final race in qualifyingRaces.whereType<Map>()) {
      final qualifyingResults =
          race['QualifyingResults'] as List? ?? const <dynamic>[];
      if (qualifyingResults.isEmpty || qualifyingResults.first is! Map) {
        continue;
      }
      final qualifyingResult = (qualifyingResults.first as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final qualifyingPosition = int.tryParse(
        qualifyingResult['position']?.toString() ?? '',
      );
      if (qualifyingPosition != null && qualifyingPosition > 0) {
        if (qualifyingPosition == 1) {
          poles += 1;
        }
        highestGrid = highestGrid == null
            ? qualifyingPosition
            : math.min(highestGrid, qualifyingPosition).toInt();
      }
    }

    final starts = resultRaces.length;
    final dnfPercentage = starts == 0 ? 0.0 : (dnfs / starts) * 100.0;
    final winRate = starts == 0 ? 0.0 : (wins / starts) * 100.0;

    return SeasonalDriverComparisonStats(
      points: points,
      pointsByRace: pointsByRace,
      poles: poles,
      fastestLaps: fastestLaps,
      dnfPercentage: dnfPercentage,
      podiums: podiums,
      highestFinish: highestFinish == null ? '-' : 'P$highestFinish',
      highestGrid: highestGrid == null ? '-' : 'P$highestGrid',
      winRate: winRate,
    );
  });
}

Future<Race?> _findLatestCompletedRace() async {
  final now = DateTime.now();
  for (final race in races.reversed) {
    if (!race.date.isAfter(now)) {
      return race;
    }
  }
  return null;
}

int raceRoundFor(Race race) {
  final seasonRaces =
      races.where((entry) => entry.date.year == race.date.year).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  final resolvedIndex = seasonRaces.indexWhere(
    (entry) =>
        entry.name == race.name &&
        entry.country == race.country &&
        entry.date == race.date,
  );

  if (resolvedIndex != -1) {
    return resolvedIndex + 1;
  }

  final fallbackIndex = races.indexOf(race);
  return fallbackIndex == -1 ? 1 : fallbackIndex + 1;
}

/// Placeholder GPs still in [raceList] but off the real calendar (e.g. 2026).
bool isCancelledGrandPrix(Race race) {
  return race.name == 'Bahrain Grand Prix' ||
      race.name == 'Saudi Arabian Grand Prix';
}

/// Home / AI “next race”: ongoing window, else earliest future race, skipping [isCancelledGrandPrix].
Race nextRaceAfterNowSkippingCancelled(
  List<Race> raceList, [
  DateTime? reference,
]) {
  final now = reference ?? DateTime.now();
  bool ok(Race r) => !isCancelledGrandPrix(r);
  final ongoing = raceList.where((r) {
    if (!ok(r)) return false;
    final isToday = r.date.year == now.year &&
        r.date.month == now.month &&
        r.date.day == now.day;
    final isFinished = r.date.isBefore(now);
    final isOngoing = isToday &&
        !isFinished &&
        (now.difference(r.date).inHours.abs() <= 4);
    return isOngoing;
  }).toList();
  if (ongoing.isNotEmpty) {
    return ongoing.first;
  }
  try {
    return raceList.firstWhere((r) => r.date.isAfter(now) && ok(r));
  } catch (_) {
    return raceList.lastWhere(ok, orElse: () => raceList.last);
  }
}

List<Map<String, dynamic>>? _jsonDecodedToMapList(
  Object? decoded, {
  String listKey = 'results',
}) {
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }
  if (decoded is Map) {
    final raw = decoded[listKey];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }
  }
  return null;
}

class SessionDataManager extends ChangeNotifier {
  static final SessionDataManager _instance = SessionDataManager._internal();
  factory SessionDataManager() => _instance;
  SessionDataManager._internal();

  final Map<String, List<SessionResult>> cache = {};
  final Map<String, List<RaceResultRow>> raceResultsCache = {};
  final Map<String, List<SessionOverviewRow>> sessionOverviewCache = {};
  final Map<String, List<Map<String, dynamic>>> raceWeatherCache = {};
  final Map<String, List<Map<String, dynamic>>> raceControlCache = {};
  final Map<String, List<Map<String, dynamic>>> _openF1Cache = {};
  DateTime? _lastOpenF1RequestAt;
  bool isInitialized = false;

  Box<String> get _sessionPayloadBox =>
      Hive.box<String>(HiveBoxes.sessionPayloads);

  Future<void> init(List<Race> races) async {
    final sessionBox = _sessionPayloadBox;
    final prefs = await SharedPreferences.getInstance();
    for (final race in races) {
      final sessionNames = race.hasSprint
          ? ['Practice 1', 'Sprint Qualifying', 'Sprint', 'Qualifying', 'Race']
          : ['Practice 1', 'Practice 2', 'Practice 3', 'Qualifying', 'Race'];
      for (final session in sessionNames) {
        final key = '${race.country}_${session}_${race.date.year}';
        final jsonStr = _readCachedPayload(sessionBox, prefs, key);
        if (jsonStr != null) {
          final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
          cache[key] = decoded
              .map(
                (entry) =>
                    SessionResult.fromJson(entry as Map<String, dynamic>),
              )
              .toList();
        }
      }

      final raceResultsJson = _readCachedPayload(
        sessionBox,
        prefs,
        _raceResultsKey(race),
      );
      if (raceResultsJson != null) {
        final List<dynamic> decoded =
            jsonDecode(raceResultsJson) as List<dynamic>;
        final rows = decoded
            .map(
              (entry) => RaceResultRow.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
        final hasInvalidPenaltyCache = rows.any(
          (row) => row.penalty.trim() == '0' || row.penalty.trim() == '0.0',
        );
        if (!hasInvalidPenaltyCache) {
          raceResultsCache[_raceResultsKey(race)] = rows;
        }
      }

      final raceWeatherJson = _readCachedPayload(
        sessionBox,
        prefs,
        _raceWeatherKey(race),
      );
      if (raceWeatherJson != null) {
        final decoded = jsonDecode(raceWeatherJson);
        dynamic weatherEntries;
        if (decoded is Map<String, dynamic>) {
          weatherEntries = decoded['samples'];
          if (weatherEntries is! List) {
            final sessions = decoded['sessions'];
            if (sessions is Map) {
              final raceSession = sessions['Race'];
              if (raceSession is Map) {
                weatherEntries = raceSession['samples'];
              }
            }
          }
        }
        if (weatherEntries is List) {
          raceWeatherCache[_raceWeatherKey(race)] = weatherEntries
              .whereType<Map>()
              .map(
                (entry) =>
                    entry.map((key, value) => MapEntry(key.toString(), value)),
              )
              .toList(growable: false);
        }
      }

      final raceControlJson = _readCachedPayload(
        sessionBox,
        prefs,
        _raceControlKey(race),
      );
      if (raceControlJson != null) {
        final decoded = jsonDecode(raceControlJson);
        final raceControlEntries = decoded is Map<String, dynamic>
            ? decoded['messages']
            : null;
        if (raceControlEntries is List) {
          // Sorteer op tijd indien mogelijk (bijv. op 'utc' of 'date' veld)
          final entries = raceControlEntries
              .whereType<Map>()
              .map((entry) => entry.map((key, value) => MapEntry(key.toString(), value)))
              .toList(growable: false);
          // Sorteer op tijd als veld aanwezig is
          entries.sort((a, b) {
            final aTime = a['utc'] ?? a['date'] ?? '';
            final bTime = b['utc'] ?? b['date'] ?? '';
            return aTime.compareTo(bTime);
          });
          // Voeg previousId en nextId toe
          for (var i = 0; i < entries.length; i++) {
            final prev = i > 0 ? entries[i - 1] : null;
            final next = i < entries.length - 1 ? entries[i + 1] : null;
            // Gebruik een uniek veld als id, anders index
            final id = entries[i]['id'] ?? i.toString();
            entries[i]['id'] = id;
            entries[i]['previousId'] = prev != null ? (prev['id'] ?? (i - 1).toString()) : null;
            entries[i]['nextId'] = next != null ? (next['id'] ?? (i + 1).toString()) : null;
          }
          raceControlCache[_raceControlKey(race)] = entries;
        }
      }

      for (final session in sessionNames.where((name) => name != 'Race')) {
        final overviewJson = _readCachedPayload(
          sessionBox,
          prefs,
          _sessionOverviewKey(race, session),
        );
        if (overviewJson != null) {
          final List<dynamic> decoded =
              jsonDecode(overviewJson) as List<dynamic>;
          sessionOverviewCache[_sessionOverviewKey(race, session)] = decoded
              .map(
                (entry) =>
                    SessionOverviewRow.fromJson(entry as Map<String, dynamic>),
              )
              .toList();
        }
      }
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchAllData() async {
    for (int i = 0; i < races.length; i++) {
      await fetchDataForRace(races[i], i + 1);
    }
  }

  Future<void> ensureRaceDataAvailable(Race race, int roundIndex) async {
    await _hydrateBundledRaceData(race);
    if (_hasRaceDataCached(race)) {
      return;
    }
    await fetchDataForRace(race, roundIndex);
  }

  /// Overwrite Hive/session cache with `assets/data/{year}/{venue}/` when present
  /// so detail tables match bundled OpenF1 (avoids stale empty overview rows).
  Future<void> _hydrateBundledRaceData(Race race) async {
    final sessionNames = race.hasSprint
        ? [
            'Practice 1',
            'Sprint Qualifying',
            'Sprint',
            'Qualifying',
            'Race',
          ]
        : [
            'Practice 1',
            'Practice 2',
            'Practice 3',
            'Qualifying',
            'Race',
          ];
    for (final sessionName in sessionNames) {
      if (sessionName == 'Race') continue;
      final rows = await _loadStaticSessionOverviewRows(race, sessionName);
      if (rows.isNotEmpty) {
        final key = _sessionOverviewKey(race, sessionName);
        sessionOverviewCache[key] = rows;
        await _saveSessionOverview(key, rows);
      }
    }
    final raceRows = await _loadStaticRaceResults(race);
    if (raceRows.isNotEmpty) {
      final rk = _raceResultsKey(race);
      raceResultsCache[rk] = raceRows;
      await _saveRaceResults(rk, raceRows);
    }
    final weather = await _loadStaticRaceWeather(race);
    if (weather.isNotEmpty) {
      final wk = _raceWeatherKey(race);
      raceWeatherCache[wk] = weather;
      await _saveRaceWeather(wk, weather);
    }
    final rc = await _loadStaticRaceControl(race);
    if (rc.isNotEmpty) {
      final rck = _raceControlKey(race);
      raceControlCache[rck] = rc;
      await _saveRaceControl(rck, rc);
    }
    notifyListeners();
  }

  Future<void> clearStoredSessionCache() async {
    cache.clear();
    raceResultsCache.clear();
    sessionOverviewCache.clear();
    raceWeatherCache.clear();
    raceControlCache.clear();
    _openF1Cache.clear();
    await _sessionPayloadBox.clear();
  }

  Future<void> fetchDataForRace(Race race, int roundIndex) async {
    final sessionNames = race.hasSprint
        ? ['Practice 1', 'Sprint Qualifying', 'Sprint', 'Qualifying', 'Race']
        : ['Practice 1', 'Practice 2', 'Practice 3', 'Qualifying', 'Race'];

    for (final sessionName in sessionNames) {
      if (sessionName == 'Race') {
        continue;
      }

      final key = '${race.country}_${sessionName}_${race.date.year}';
      final staticOverview = await _loadStaticSessionOverviewRows(
        race,
        sessionName,
      );
      if (staticOverview.isNotEmpty) {
        await _saveSessionOverview(
          _sessionOverviewKey(race, sessionName),
          staticOverview,
        );
        cache.remove(key);
        continue;
      }

      try {
        final results = await _fetchSessionResults(
          year: race.date.year,
          roundIndex: roundIndex,
          sessionName: sessionName,
        );
        _saveResults(key, results);
      } catch (_) {
        _saveResults(key, const <SessionResult>[]);
      }

      try {
        final overviewRows = await _fetchSessionOverviewRows(
          race,
          sessionName,
        );
        if (overviewRows.isNotEmpty) {
          await _saveSessionOverview(
            _sessionOverviewKey(race, sessionName),
            overviewRows,
          );
        } else {
          sessionOverviewCache.remove(_sessionOverviewKey(race, sessionName));
        }
      } catch (_) {
        sessionOverviewCache.remove(_sessionOverviewKey(race, sessionName));
      }
    }

    final raceResultsKey = _raceResultsKey(race);
    try {
      final rows = await _fetchRaceResultRows(race);
      if (rows.isNotEmpty) {
        await _saveRaceResults(raceResultsKey, rows);
      } else {
        raceResultsCache.remove(raceResultsKey);
      }
    } catch (_) {
      raceResultsCache.remove(raceResultsKey);
    }

    try {
      final weatherRows = await _fetchRaceWeatherRows(race);
      if (weatherRows.isNotEmpty) {
        await _saveRaceWeather(_raceWeatherKey(race), weatherRows);
      } else {
        raceWeatherCache.remove(_raceWeatherKey(race));
      }
    } catch (_) {
      raceWeatherCache.remove(_raceWeatherKey(race));
    }

    try {
      final raceControlRows = await _fetchRaceControlRows(race);
      if (raceControlRows.isNotEmpty) {
        await _saveRaceControl(_raceControlKey(race), raceControlRows);
      } else {
        raceControlCache.remove(_raceControlKey(race));
      }
    } catch (_) {
      raceControlCache.remove(_raceControlKey(race));
    }

    isInitialized = true;
    notifyListeners();
  }

  String raceResultsKeyFor(Race race) => _raceResultsKey(race);

  String raceWeatherKeyFor(Race race) => _raceWeatherKey(race);

  String raceControlKeyFor(Race race) => _raceControlKey(race);

  String sessionOverviewKeyFor(Race race, String sessionName) =>
      _sessionOverviewKey(race, sessionName);

  Future<WeekendHubPodiumFetchResult> fetchWeekendHubPodium(Race race) async {
    final raceSession = await _findClosestSessionForRace(
      race: race,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return const WeekendHubPodiumFetchResult(podium: []);
    }

    final raceSessionKey = _asInt(raceSession['session_key']);
    if (raceSessionKey == null) {
      return const WeekendHubPodiumFetchResult(podium: []);
    }

    final results = await _fetchOpenF1Collection(
      'session_result',
      <String, String>{'session_key': raceSessionKey.toString()},
    );
    final drivers = await _fetchOpenF1Collection('drivers', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final laps = await _fetchOpenF1Collection('laps', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final stints = await _fetchOpenF1Collection('stints', <String, String>{
      'session_key': raceSessionKey.toString(),
    });

    if (results.isEmpty || drivers.isEmpty) {
      return const WeekendHubPodiumFetchResult(podium: []);
    }

    final driverNames = <int, String>{
      for (final driver in drivers)
        if (_asInt(driver['driver_number']) != null)
          _asInt(driver['driver_number'])!: _formatDriverName(driver),
    };
    final fastestLapByDriver = _buildFastestLapDetailsMap(laps, stints);
    final overallFastestLap = fastestLapByDriver.values.isEmpty
        ? null
        : fastestLapByDriver.values.reduce(
            (best, current) =>
                current.duration < best.duration ? current : best,
          );
    final tyreStrategyByDriver = _buildTyreStrategyMap(stints);

    final sortedResults = List<Map<String, dynamic>>.from(results)
      ..sort((a, b) {
        final positionA = _asInt(a['position']) ?? 999;
        final positionB = _asInt(b['position']) ?? 999;
        if (positionA != positionB) {
          return positionA.compareTo(positionB);
        }

        final lapsA = _asInt(a['number_of_laps']) ?? -1;
        final lapsB = _asInt(b['number_of_laps']) ?? -1;
        return lapsB.compareTo(lapsA);
      });

    final winnerDuration = sortedResults
        .map((entry) => _asDouble(entry['duration']))
        .whereType<double>()
        .cast<double?>()
        .firstWhere((value) => value != null, orElse: () => null);

    final podium = sortedResults
        .take(3)
        .map((entry) {
          final driverNumber = _asInt(entry['driver_number']);
          final fastestLap = driverNumber == null
              ? null
              : fastestLapByDriver[driverNumber];
          final hasOverallFastestLap =
              driverNumber != null &&
              overallFastestLap != null &&
              fastestLap?.duration == overallFastestLap.duration;
          final tyreAbbrev = RaceResultRow.tyreCompoundDisplayToInsightsLetter(
            _formatTyreCompound(fastestLap?.compound),
          );

          return WeekendHubPodiumEntry(
            position: _asInt(entry['position']) ?? 0,
            driverNumber: driverNumber,
            driver: driverNumber == null
                ? '-'
                : (driverNames[driverNumber] ?? '-'),
            points: _formatPoints(_asDouble(entry['points']) ?? 0),
            totalTime: _formatTotalRaceTime(entry, winnerDuration),
            gapToLeader: _formatTimeOrGap(entry, winnerDuration),
            fastestLap: _formatLapDurationWithOptionalLap(
              fastestLap?.duration,
              fastestLap?.lapNumber,
            ),
            hasFastestLap: hasOverallFastestLap,
            tyreCompounds: driverNumber == null
                ? const <String>[]
                : (tyreStrategyByDriver[driverNumber] ?? const <String>[]),
            bestLapTyreAbbrev: tyreAbbrev,
          );
        })
        .toList(growable: false);

    return WeekendHubPodiumFetchResult(podium: podium);
  }

  Future<List<SessionResult>> _fetchSessionResults({
    required int year,
    required int roundIndex,
    required String sessionName,
  }) async {
    final endpoint = _endpointForSession(sessionName);
    final resultsKey = _resultsKeyForSession(sessionName);
    if (endpoint == null || resultsKey == null) {
      return const <SessionResult>[];
    }

    // API call removed. Only local data is used.
    return const <SessionResult>[];
  }

  String? _endpointForSession(String sessionName) {
    switch (sessionName) {
      case 'Qualifying':
        return 'qualifying';
      case 'Sprint':
        return 'sprint';
      case 'Race':
        return 'results';
      default:
        return null;
    }
  }

  String? _resultsKeyForSession(String sessionName) {
    switch (sessionName) {
      case 'Qualifying':
        return 'QualifyingResults';
      case 'Sprint':
        return 'SprintResults';
      case 'Race':
        return 'Results';
      default:
        return null;
    }
  }

  Future<void> _saveResults(String key, List<SessionResult> results) async {
    cache[key] = results;
    await _sessionPayloadBox.put(
      key,
      jsonEncode(results.map((result) => result.toJson()).toList()),
    );
  }

  Future<void> _saveRaceResults(String key, List<RaceResultRow> rows) async {
    raceResultsCache[key] = rows;
    await _sessionPayloadBox.put(
      key,
      jsonEncode(rows.map((row) => row.toJson()).toList()),
    );
  }

  Future<void> _saveRaceWeather(
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    raceWeatherCache[key] = rows;
    await _sessionPayloadBox.put(
      key,
      jsonEncode(<String, dynamic>{'samples': rows}),
    );
  }

  Future<void> _saveRaceControl(
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    raceControlCache[key] = rows;
    await _sessionPayloadBox.put(
      key,
      jsonEncode(<String, dynamic>{'messages': rows}),
    );
  }

  Future<void> _saveSessionOverview(
    String key,
    List<SessionOverviewRow> rows,
  ) async {
    sessionOverviewCache[key] = rows;
    await _sessionPayloadBox.put(
      key,
      jsonEncode(rows.map((row) => row.toJson()).toList()),
    );
  }

  String? _readCachedPayload(
    Box<String> sessionBox,
    SharedPreferences prefs,
    String key,
  ) {
    final hiveValue = sessionBox.get(key);
    if (hiveValue != null) {
      return hiveValue;
    }

    final legacyValue = prefs.getString(key);
    if (legacyValue != null) {
      sessionBox.put(key, legacyValue);
    }
    return legacyValue;
  }

  bool _hasRaceDataCached(Race race) {
    final sessionNames = race.hasSprint
        ? ['Practice 1', 'Sprint Qualifying', 'Sprint', 'Qualifying', 'Race']
        : ['Practice 1', 'Practice 2', 'Practice 3', 'Qualifying', 'Race'];

    for (final sessionName in sessionNames) {
      if (sessionName == 'Race') {
        continue;
      }

      final sessionKey = '${race.country}_${sessionName}_${race.date.year}';
      final overviewKey = _sessionOverviewKey(race, sessionName);
      final hasSessionRows =
          cache.containsKey(sessionKey) ||
          _sessionPayloadBox.containsKey(sessionKey);
      final hasOverviewRows =
          sessionOverviewCache.containsKey(overviewKey) ||
          _sessionPayloadBox.containsKey(overviewKey);

      if (!hasOverviewRows && !hasSessionRows) {
        return false;
      }
    }

    final raceResultsKey = _raceResultsKey(race);
    final hasRaceResults =
        raceResultsCache.containsKey(raceResultsKey) ||
        _sessionPayloadBox.containsKey(raceResultsKey);
    if (!hasRaceResults) {
      return false;
    }

    final raceWeatherKey = _raceWeatherKey(race);
    final hasRaceWeather =
        raceWeatherCache.containsKey(raceWeatherKey) ||
        _sessionPayloadBox.containsKey(raceWeatherKey);
    if (!hasRaceWeather) {
      return false;
    }

    final raceControlKey = _raceControlKey(race);
    final hasRaceControl =
        raceControlCache.containsKey(raceControlKey) ||
        _sessionPayloadBox.containsKey(raceControlKey);
    if (!hasRaceControl) {
      return false;
    }

    return true;
  }

  String _raceResultsKey(Race race) =>
      '${race.country}_RaceResults_${race.date.year}_v2';

  String _raceWeatherKey(Race race) =>
      '${race.country}_RaceWeather_${race.date.year}_v1';

  String _raceControlKey(Race race) =>
      '${race.country}_RaceControl_${race.date.year}_v1';

  String _sessionOverviewKey(Race race, String sessionName) =>
      '${race.country}_${sessionName}_${race.date.year}_Overview';

  Future<List<SessionOverviewRow>> _fetchSessionOverviewRows(
    Race race,
    String sessionName,
  ) async {
    final staticRows = await _loadStaticSessionOverviewRows(race, sessionName);
    if (staticRows.isNotEmpty) {
      return staticRows;
    }

    final session = await _findClosestSessionForRace(
      race: race,
      sessionName: sessionName,
    );
    if (session == null) {
      return const <SessionOverviewRow>[];
    }

    final sessionKey = _asInt(session['session_key']);
    if (sessionKey == null) {
      return const <SessionOverviewRow>[];
    }

    final drivers = await _fetchOpenF1Collection('drivers', <String, String>{
      'session_key': sessionKey.toString(),
    });
    final laps = await _fetchOpenF1Collection('laps', <String, String>{
      'session_key': sessionKey.toString(),
    });
    final stints = await _fetchOpenF1Collection('stints', <String, String>{
      'session_key': sessionKey.toString(),
    });
    final sessionResults = await _fetchOpenF1Collection(
      'session_result',
      <String, String>{'session_key': sessionKey.toString()},
    );

    if (drivers.isEmpty) {
      return const <SessionOverviewRow>[];
    }

    final driverNames = <int, String>{
      for (final driver in drivers)
        if (_asInt(driver['driver_number']) != null)
          _asInt(driver['driver_number'])!: _formatDriverName(driver),
    };
    final fastestLapByDriver = _buildFastestLapDetailsMap(laps, stints);
    final lapSummaryByDriver = _buildSessionLapSummaryMap(stints);
    final overallFastestLap = fastestLapByDriver.values.isEmpty
        ? null
        : fastestLapByDriver.values.reduce(
            (best, current) =>
                current.duration < best.duration ? current : best,
          );

    if (sessionResults.isNotEmpty) {
      final sortedResults = List<Map<String, dynamic>>.from(sessionResults)
        ..sort((a, b) {
          final positionA = _asInt(a['position']) ?? 999;
          final positionB = _asInt(b['position']) ?? 999;
          return positionA.compareTo(positionB);
        });

      return sortedResults.map((entry) {
        final driverNumber = _asInt(entry['driver_number']);
        final isSprint = sessionName == 'Sprint';
        final driverFastestLap = driverNumber == null
            ? null
            : fastestLapByDriver[driverNumber];
        final lapSummary = driverNumber == null
            ? null
            : lapSummaryByDriver[driverNumber];
        final tyreUsage = driverNumber == null
            ? null
            : _tyreUsageForLap(
                stints,
                driverNumber,
                driverFastestLap?.lapNumber,
              );

        return SessionOverviewRow(
          driver: driverNumber == null
              ? '-'
              : (driverNames[driverNumber] ?? '-'),
          position: _formatSessionPosition(entry),
          result: isSprint
              ? _formatSprintResult(entry)
              : _formatLapDuration(driverFastestLap?.duration),
          fastestLap: _formatLapDuration(driverFastestLap?.duration),
          tyreCompound:
              tyreUsage?.formattedCompound ??
              _formatTyreCompound(driverFastestLap?.compound),
          points: isSprint
              ? _formatPoints(_asDouble(entry['points']) ?? 0)
              : '-',
          hasFastestLap:
              driverNumber != null &&
              overallFastestLap != null &&
              driverFastestLap?.duration == overallFastestLap.duration,
          usedTyre: tyreUsage?.usedTyre ?? false,
          tyreAgeAtStart: tyreUsage?.tyreAgeAtStart,
          totalLaps: lapSummary?.totalLaps,
          tyreLaps: lapSummary?.lapsByCompound ?? const <String, int>{},
          tyreLapSequence:
              lapSummary?.stintSequence ??
              const <SessionTyreLapBreakdownEntry>[],
        );
      }).toList();
    }

    final rankedDrivers = fastestLapByDriver.entries.toList()
      ..sort((a, b) => a.value.duration.compareTo(b.value.duration));

    return rankedDrivers.asMap().entries.map((entry) {
      final position = entry.key + 1;
      final driverNumber = entry.value.key;
      final lap = entry.value.value;
      final lapSummary = lapSummaryByDriver[driverNumber];
      final tyreUsage = _tyreUsageForLap(stints, driverNumber, lap.lapNumber);
      return SessionOverviewRow(
        driver: driverNames[driverNumber] ?? '-',
        position: position.toString(),
        result: _formatLapDuration(lap.duration),
        fastestLap: _formatLapDuration(lap.duration),
        tyreCompound:
            tyreUsage?.formattedCompound ?? _formatTyreCompound(lap.compound),
        points: '-',
        hasFastestLap:
            overallFastestLap != null &&
            lap.duration == overallFastestLap.duration,
        usedTyre: tyreUsage?.usedTyre ?? false,
        tyreAgeAtStart: tyreUsage?.tyreAgeAtStart,
        totalLaps: lapSummary?.totalLaps,
        tyreLaps: lapSummary?.lapsByCompound ?? const <String, int>{},
        tyreLapSequence:
            lapSummary?.stintSequence ?? const <SessionTyreLapBreakdownEntry>[],
      );
    }).toList();
  }

  _TyreUsageDetails? _tyreUsageForLap(
    List<Map<String, dynamic>> stints,
    int driverNumber,
    int? lapNumber,
  ) {
    if (lapNumber == null || lapNumber <= 0) {
      return null;
    }

    for (final stint in stints) {
      if (_asInt(stint['driver_number']) != driverNumber) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']) ?? 0;
      final lapEnd = _asInt(stint['lap_end']) ?? 0;
      if (lapNumber < lapStart || lapNumber > lapEnd) {
        continue;
      }

      final compound = _formatTyreCompound(stint['compound']?.toString());
      final tyreAgeAtStart = _asInt(stint['tyre_age_at_start']);
      return _TyreUsageDetails(
        compound: compound,
        tyreAgeAtStart: tyreAgeAtStart,
      );
    }

    return null;
  }

  Future<List<SessionOverviewRow>> _loadStaticSessionOverviewRows(
    Race race,
    String sessionName,
  ) async {
    final year = race.date.year;
    final round = raceRoundFor(race);
    for (final path
        in F1AssetResolver.legacySessionsOverviewPaths(year, round)) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) continue;
      try {
        final body = await rootBundle.loadString(path);
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;
        final sessions = decoded['sessions'];
        if (sessions is! Map<String, dynamic>) continue;
        final sessionRows = sessions[sessionName];
        if (sessionRows is! List) continue;
        final rows = sessionRows
            .whereType<Map>()
            .map(
              (entry) => SessionOverviewRow.fromJson(
                entry.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      } catch (_) {}
    }

    final stem = F1AssetResolver.sanitizeSessionStem(sessionName);
    for (final venue in F1AssetResolver.expandedVenueFoldersForRace(
      circuitAssetId: race.circuitAssetId,
      year: year,
      round: round,
    )) {
      final modularPath = F1AssetResolver.sessionAssetPath(
        year: year,
        venueFolder: venue,
        sessionStem: stem,
        suffix: 'results',
      );
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, modularPath)) {
        continue;
      }
      try {
        final body = await rootBundle.loadString(modularPath);
        final list = _jsonDecodedToMapList(jsonDecode(body), listKey: 'results');
        if (list != null && list.isNotEmpty) {
          int posOf(Map<String, dynamic> m) {
            final f = m['finishPosition'];
            if (f is int) return f;
            return int.tryParse(f?.toString() ?? '') ?? 999;
          }

          final sorted = List<Map<String, dynamic>>.from(list)
            ..sort((a, b) => posOf(a).compareTo(posOf(b)));
          final leaderLap =
              RaceResultRow.openF1ResultFastestLapSeconds(sorted.first);
          double? sessionBest;
          for (final m in sorted) {
            final t = RaceResultRow.openF1ResultFastestLapSeconds(m);
            if (t != null && (sessionBest == null || t < sessionBest)) {
              sessionBest = t;
            }
          }
          return sorted
              .map(
                (m) => SessionOverviewRow.fromOpenF1ResultMap(
                  m,
                  leaderFastestLapSeconds: leaderLap,
                  sessionBestLapSeconds: sessionBest,
                ),
              )
              .toList(growable: false);
        }
      } catch (_) {}
    }

    return const <SessionOverviewRow>[];
  }

  Future<List<Map<String, dynamic>>> _fetchRaceWeatherRows(Race race) async {
    final staticWeather = await _loadStaticRaceWeather(race);
    if (staticWeather.isNotEmpty) {
      return staticWeather;
    }

    final raceSession = await _findClosestSessionForRace(
      race: race,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return const <Map<String, dynamic>>[];
    }

    final raceSessionKey = _asInt(raceSession['session_key']);
    if (raceSessionKey == null) {
      return const <Map<String, dynamic>>[];
    }

    final weather = await _fetchOpenF1Collection('weather', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    return _buildWeatherSamples(weather);
  }

  Future<List<Map<String, dynamic>>> _fetchRaceControlRows(Race race) async {
    final staticMessages = await _loadStaticRaceControl(race);
    if (staticMessages.isNotEmpty) {
      return staticMessages;
    }

    final raceSession = await _findClosestSessionForRace(
      race: race,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return const <Map<String, dynamic>>[];
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    if (meetingKey == null) {
      return const <Map<String, dynamic>>[];
    }

    final meetingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{'meeting_key': meetingKey.toString()},
    );
    final sortedSessions = List<Map<String, dynamic>>.from(meetingSessions)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date_start']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date_start']?.toString() ?? '');
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final normalizedMessages = <Map<String, dynamic>>[];
    for (final session in sortedSessions) {
      final sessionKey = _asInt(session['session_key']);
      if (sessionKey == null) {
        continue;
      }

      final sessionName = session['session_name']?.toString() ?? 'Unknown';
      final sessionMessages = await _fetchOpenF1Collection(
        'race_control',
        <String, String>{'session_key': sessionKey.toString()},
      );

      for (final message in sessionMessages) {
        final normalized = _normalizeRaceControlMessageForWeekend(
          message,
          sessionName: sessionName,
          sessionKey: sessionKey,
        );
        if (normalized != null) {
          normalizedMessages.add(normalized);
        }
      }
    }

    normalizedMessages.sort((a, b) {
      final aDate = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
      if (aDate != null && bDate != null) {
        final compare = aDate.compareTo(bDate);
        if (compare != 0) {
          return compare;
        }
      }

      final aLap = _asInt(a['lap']) ?? -1;
      final bLap = _asInt(b['lap']) ?? -1;
      return aLap.compareTo(bLap);
    });

    return normalizedMessages;
  }

  Future<List<RaceResultRow>> _fetchRaceResultRows(Race race) async {
    final staticRows = await _loadStaticRaceResults(race);
    final staticRowsHaveRichData = staticRows.any(
      (row) =>
          row.tyreStints.isNotEmpty ||
          row.tyreCompounds.isNotEmpty ||
          row.penaltyDetails.isNotEmpty ||
          (row.penalty.trim().isNotEmpty && row.penalty.trim() != '-'),
    );
    if (staticRows.isNotEmpty && staticRowsHaveRichData) {
      return staticRows;
    }

    final raceSession = await _findClosestSessionForRace(
      race: race,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return staticRows;
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    final raceSessionKey = _asInt(raceSession['session_key']);
    if (meetingKey == null || raceSessionKey == null) {
      return staticRows;
    }

    final meetingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{'meeting_key': meetingKey.toString()},
    );
    final qualifyingSessions = await _fetchOpenF1Collection(
      'sessions',
      <String, String>{
        'meeting_key': meetingKey.toString(),
        'session_name': 'Qualifying',
      },
    );
    final qualifyingSession = qualifyingSessions.isNotEmpty
        ? qualifyingSessions.first
        : null;
    final qualifyingSessionKey = qualifyingSession == null
        ? null
        : _asInt(qualifyingSession['session_key']);

    final results = await _fetchOpenF1Collection(
      'session_result',
      <String, String>{'session_key': raceSessionKey.toString()},
    );
    final drivers = await _fetchOpenF1Collection('drivers', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final laps = await _fetchOpenF1Collection('laps', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final stints = await _fetchOpenF1Collection('stints', <String, String>{
      'session_key': raceSessionKey.toString(),
    });
    final raceControlMessages = await _fetchOpenF1Collection(
      'race_control',
      <String, String>{'session_key': raceSessionKey.toString()},
    );
    final allWeekendControlMessages = <Map<String, dynamic>>[
      ...raceControlMessages,
    ];
    for (final session in meetingSessions) {
      final sessionKey = _asInt(session['session_key']);
      if (sessionKey == null || sessionKey == raceSessionKey) {
        continue;
      }
      final sessionMessages = await _fetchOpenF1Collection(
        'race_control',
        <String, String>{'session_key': sessionKey.toString()},
      );
      allWeekendControlMessages.addAll(sessionMessages);
    }
    final startingGrid = qualifyingSessionKey == null
        ? const <Map<String, dynamic>>[]
        : await _fetchOpenF1Collection('starting_grid', <String, String>{
            'session_key': qualifyingSessionKey.toString(),
          });

    if (results.isEmpty || drivers.isEmpty) {
      return staticRows;
    }

    final Map<int, String> driverNames = {
      for (final driver in drivers)
        if (_asInt(driver['driver_number']) != null)
          _asInt(driver['driver_number'])!: _formatDriverName(driver),
    };
    final Map<int, int> gridPositions = {
      for (final entry in startingGrid)
        if (_asInt(entry['driver_number']) != null &&
            _asInt(entry['position']) != null)
          _asInt(entry['driver_number'])!: _asInt(entry['position'])!,
    };
    final Map<int, String> penalties = _buildPenaltyMap(
      allWeekendControlMessages,
    );
    final sessionNamesByKey = <int, String>{
      for (final session in meetingSessions)
        if (_asInt(session['session_key']) != null)
          _asInt(session['session_key'])!:
              session['session_name']?.toString() ?? 'Unknown',
    };
    final raceControlMessagesByDriver = _buildRaceControlMessagesMap(
      allWeekendControlMessages,
      sessionNamesByKey,
    );
    final fastestLapByDriver = _buildFastestLapDetailsMap(laps, stints);
    final tyreStrategyByDriver = _buildTyreStrategyMap(stints);
    final tyreStintsByDriver = _buildRaceTyreStintsMap(stints);
    final penaltyDetailsByDriver = _buildPenaltyDetailsMap(
      allWeekendControlMessages,
      sessionNamesByKey,
    );
    final overallFastestLap = fastestLapByDriver.values.isEmpty
        ? null
        : fastestLapByDriver.values.reduce(
            (best, current) =>
                current.duration < best.duration ? current : best,
          );

    final sortedResults = List<Map<String, dynamic>>.from(results)
      ..sort((a, b) {
        final positionA = _asInt(a['position']) ?? 999;
        final positionB = _asInt(b['position']) ?? 999;
        if (positionA != positionB) {
          return positionA.compareTo(positionB);
        }

        final lapsA = _asInt(a['number_of_laps']) ?? -1;
        final lapsB = _asInt(b['number_of_laps']) ?? -1;
        return lapsB.compareTo(lapsA);
      });

    final winnerDuration = sortedResults
        .map((entry) => _asDouble(entry['duration']))
        .whereType<double>()
        .cast<double?>()
        .firstWhere((value) => value != null, orElse: () => null);

    final liveRows = sortedResults
        .map((entry) {
          final driverNumber = _asInt(entry['driver_number']);
          final startPosition = driverNumber == null
              ? null
              : gridPositions[driverNumber];
          final penaltyDetails = driverNumber == null
              ? const <Map<String, dynamic>>[]
              : (penaltyDetailsByDriver[driverNumber] ??
                    const <Map<String, dynamic>>[]);
          final penaltyServedLaps = penaltyDetails
              .map((detail) => detail['lap'])
              .whereType<int>()
              .toSet()
              .toList(growable: false);
          final tyreCompounds = driverNumber == null
              ? const <String>[]
              : (tyreStrategyByDriver[driverNumber] ?? const <String>[]);
          final tyreStints = driverNumber == null
              ? const <Map<String, dynamic>>[]
              : (tyreStintsByDriver[driverNumber] ??
                    const <Map<String, dynamic>>[]);
          return RaceResultRow(
            driver: driverNumber == null
                ? '-'
                : (driverNames[driverNumber] ?? '-'),
            start: driverNumber == null
                ? '-'
                : (gridPositions[driverNumber]?.toString() ?? '-'),
            finish: _formatRaceFinish(entry, startPosition),
            timeOrGap: _formatTimeOrGap(entry, winnerDuration),
            fastestLap: driverNumber == null
                ? '-'
                : _formatLapDuration(
                    fastestLapByDriver[driverNumber]?.duration,
                  ),
            tyreCompound: driverNumber == null
                ? '-'
                : _formatTyreCompound(
                    fastestLapByDriver[driverNumber]?.compound,
                  ),
            penalty: driverNumber == null
                ? '-'
                : (penalties[driverNumber] ?? '-'),
            points: _formatPoints(_asDouble(entry['points']) ?? 0),
            hasFastestLap:
                driverNumber != null &&
                overallFastestLap != null &&
                fastestLapByDriver[driverNumber]?.duration ==
                    overallFastestLap.duration,
            tyreCompounds: tyreCompounds,
            tyreStints: tyreStints,
            tyreStrategy: tyreCompounds.isEmpty
                ? '-'
                : tyreCompounds.join(' -> '),
            tyreChangeLaps: const <int>[],
            penaltyDetails: penaltyDetails,
            penaltyServed: penaltyDetails.any(
              (detail) => detail['served'] == true,
            ),
            penaltyServedLaps: penaltyServedLaps,
            weatherSamples: const <Map<String, dynamic>>[],
            raceControlMessages: driverNumber == null
                ? const <Map<String, dynamic>>[]
                : (raceControlMessagesByDriver[driverNumber] ??
                      const <Map<String, dynamic>>[]),
            pitStops: const <Map<String, dynamic>>[],
            totalPitTime: '-',
            fastestPitStop: null,
            averagePitTime: '-',
          );
        })
        .toList(growable: false);

    return liveRows.isNotEmpty ? liveRows : staticRows;
  }

  Future<List<RaceResultRow>> _loadStaticRaceResults(Race race) async {
    final year = race.date.year;
    final round = raceRoundFor(race);
    final paths = <String>[];
    for (final venue in F1AssetResolver.expandedVenueFoldersForRace(
      circuitAssetId: race.circuitAssetId,
      year: year,
      round: round,
    )) {
      paths.addAll(
        F1AssetResolver.candidateRaceResultPaths(
          year: year,
          venueFolder: venue,
        ),
      );
    }
    paths.addAll(F1AssetResolver.legacyRoundResultPaths(year, round));

    List<Map<String, dynamic>>? bestMaps;
    for (final path in paths) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) continue;
      try {
        final body = await rootBundle.loadString(path);
        final list = _jsonDecodedToMapList(jsonDecode(body), listKey: 'results');
        if (list == null || list.isEmpty) continue;
        if (bestMaps == null || list.length > bestMaps.length) {
          bestMaps = list;
        }
      } catch (_) {}
    }
    if (bestMaps == null) return const <RaceResultRow>[];
    int posOf(Map<String, dynamic> m) {
      final f = m['finishPosition'];
      if (f is int) return f;
      return int.tryParse(f?.toString() ?? '') ?? 999;
    }

    final sorted = List<Map<String, dynamic>>.from(bestMaps)
      ..sort((a, b) => posOf(a).compareTo(posOf(b)));
    final leaderLap = RaceResultRow.openF1ResultFastestLapSeconds(sorted.first);
    double? sessionBest;
    for (final m in sorted) {
      final t = RaceResultRow.openF1ResultFastestLapSeconds(m);
      if (t != null && (sessionBest == null || t < sessionBest)) {
        sessionBest = t;
      }
    }
    return sorted
        .map(
          (e) => RaceResultRow.fromOpenF1BundledJson(
            e,
            leaderFastestLapSec: leaderLap,
            sessionBestLapSec: sessionBest,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadStaticRaceWeather(Race race) async {
    final year = race.date.year;
    final round = raceRoundFor(race);
    final paths = <String>[];
    for (final venue in F1AssetResolver.expandedVenueFoldersForRace(
      circuitAssetId: race.circuitAssetId,
      year: year,
      round: round,
    )) {
      paths.addAll(
        F1AssetResolver.candidateRaceWeatherPaths(
          year: year,
          venueFolder: venue,
        ),
      );
    }
    paths.addAll(F1AssetResolver.legacyRoundWeatherPaths(year, round));

    for (final path in paths) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) continue;
      try {
        final body = await rootBundle.loadString(path);
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;

        dynamic samples = decoded['samples'];
        if (samples is! List) {
          final sessions = decoded['sessions'];
          if (sessions is Map) {
            final raceSession = sessions['Race'];
            if (raceSession is Map) {
              samples = raceSession['samples'];
            }
          }
        }
        if (samples is! List) continue;

        final rows = samples
            .whereType<Map>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      } catch (_) {}
    }

    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _loadStaticRaceControl(Race race) async {
    final year = race.date.year;
    final round = raceRoundFor(race);
    final paths = <String>[];
    for (final venue in F1AssetResolver.expandedVenueFoldersForRace(
      circuitAssetId: race.circuitAssetId,
      year: year,
      round: round,
    )) {
      paths.addAll(
        F1AssetResolver.candidateRaceRaceControlPaths(
          year: year,
          venueFolder: venue,
        ),
      );
    }
    paths.addAll(F1AssetResolver.legacyRoundRaceControlPaths(year, round));

    for (final path in paths) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) continue;
      try {
        final body = await rootBundle.loadString(path);
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;

        final messages = decoded['messages'];
        if (messages is! List) continue;

        final rows = messages
            .whereType<Map>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      } catch (_) {}
    }

    return const <Map<String, dynamic>>[];
  }

  Map<int, FastestLapDetails> _buildFastestLapDetailsMap(
    List<Map<String, dynamic>> laps,
    List<Map<String, dynamic>> stints,
  ) {
    final fastestLapByDriver = <int, FastestLapDetails>{};

    for (final lap in laps) {
      final driverNumber = _asInt(lap['driver_number']);
      final lapDuration = _asDouble(lap['lap_duration']);
      final lapNumber = _asInt(lap['lap_number']);
      if (driverNumber == null || lapDuration == null || lapDuration <= 0) {
        continue;
      }
      if (lapNumber == null || lapNumber <= 0) {
        continue;
      }
      if (_asBool(lap['is_pit_out_lap'])) {
        continue;
      }

      final currentBest = fastestLapByDriver[driverNumber];
      if (currentBest == null || lapDuration < currentBest.duration) {
        fastestLapByDriver[driverNumber] = FastestLapDetails(
          duration: lapDuration,
          lapNumber: lapNumber,
          compound: _compoundForLap(stints, driverNumber, lapNumber),
        );
      }
    }

    return fastestLapByDriver;
  }

  Map<int, _SessionLapSummary> _buildSessionLapSummaryMap(
    List<Map<String, dynamic>> stints,
  ) {
    final sortedStints = List<Map<String, dynamic>>.from(stints)
      ..sort((a, b) {
        final driverA = _asInt(a['driver_number']) ?? 999;
        final driverB = _asInt(b['driver_number']) ?? 999;
        if (driverA != driverB) {
          return driverA.compareTo(driverB);
        }

        final stintA = _asInt(a['stint_number']) ?? _asInt(a['lap_start']) ?? 0;
        final stintB = _asInt(b['stint_number']) ?? _asInt(b['lap_start']) ?? 0;
        return stintA.compareTo(stintB);
      });
    final summaries = <int, _MutableSessionLapSummary>{};

    for (final stint in sortedStints) {
      final driverNumber = _asInt(stint['driver_number']);
      if (driverNumber == null) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']);
      final lapEnd = _asInt(stint['lap_end']);
      if (lapStart == null || lapEnd == null || lapEnd < lapStart) {
        continue;
      }

      final lapCount = (lapEnd - lapStart) + 1;
      if (lapCount <= 0) {
        continue;
      }

      final compound = _formatTyreCompound(stint['compound']?.toString());
      final summary = summaries.putIfAbsent(
        driverNumber,
        () => _MutableSessionLapSummary(),
      );
      summary.totalLaps += lapCount;
      if (compound != '-') {
        summary.lapsByCompound.update(
          compound,
          (value) => value + lapCount,
          ifAbsent: () => lapCount,
        );
        summary.stintSequence.add(
          SessionTyreLapBreakdownEntry(
            compound: compound,
            laps: lapCount,
            usedTyre: (_asInt(stint['tyre_age_at_start']) ?? 0) > 0,
          ),
        );
      }
    }

    return {
      for (final entry in summaries.entries) entry.key: entry.value.build(),
    };
  }

  Map<int, List<String>> _buildTyreStrategyMap(
    List<Map<String, dynamic>> stints,
  ) {
    final sortedStints = List<Map<String, dynamic>>.from(stints)
      ..sort((a, b) {
        final driverA = _asInt(a['driver_number']) ?? 999;
        final driverB = _asInt(b['driver_number']) ?? 999;
        if (driverA != driverB) {
          return driverA.compareTo(driverB);
        }

        final stintA = _asInt(a['stint_number']) ?? _asInt(a['lap_start']) ?? 0;
        final stintB = _asInt(b['stint_number']) ?? _asInt(b['lap_start']) ?? 0;
        return stintA.compareTo(stintB);
      });

    final strategies = <int, List<String>>{};
    for (final stint in sortedStints) {
      final driverNumber = _asInt(stint['driver_number']);
      if (driverNumber == null) {
        continue;
      }

      final formattedCompound = _formatTyreCompound(
        stint['compound']?.toString(),
      );
      if (formattedCompound == '-') {
        continue;
      }

      final compounds = strategies.putIfAbsent(driverNumber, () => <String>[]);
      if (compounds.isEmpty || compounds.last != formattedCompound) {
        compounds.add(formattedCompound);
      }
    }

    return strategies;
  }

  Map<int, List<Map<String, dynamic>>> _buildRaceTyreStintsMap(
    List<Map<String, dynamic>> stints,
  ) {
    final sortedStints = List<Map<String, dynamic>>.from(stints)
      ..sort((a, b) {
        final driverA = _asInt(a['driver_number']) ?? 999;
        final driverB = _asInt(b['driver_number']) ?? 999;
        if (driverA != driverB) {
          return driverA.compareTo(driverB);
        }

        final stintA = _asInt(a['stint_number']) ?? _asInt(a['lap_start']) ?? 0;
        final stintB = _asInt(b['stint_number']) ?? _asInt(b['lap_start']) ?? 0;
        return stintA.compareTo(stintB);
      });

    final stintsByDriver = <int, List<Map<String, dynamic>>>{};
    for (final stint in sortedStints) {
      final driverNumber = _asInt(stint['driver_number']);
      if (driverNumber == null) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']);
      final lapEnd = _asInt(stint['lap_end']);
      final compound = _formatTyreCompound(stint['compound']?.toString());
      if (lapStart == null ||
          lapEnd == null ||
          lapEnd < lapStart ||
          compound == '-') {
        continue;
      }

      stintsByDriver
          .putIfAbsent(driverNumber, () => <Map<String, dynamic>>[])
          .add({
            'compound': compound,
            'lapStart': lapStart,
            'lapEnd': lapEnd,
            'laps': (lapEnd - lapStart) + 1,
            'usedTyre': (_asInt(stint['tyre_age_at_start']) ?? 0) > 0,
          });
    }

    return stintsByDriver;
  }

  Map<int, List<Map<String, dynamic>>> _buildPenaltyDetailsMap(
    List<Map<String, dynamic>> messages,
    Map<int, String> sessionNamesByKey,
  ) {
    final penaltyDetailsByDriver = <int, List<Map<String, dynamic>>>{};

    for (final entry in messages) {
      final message = entry['message']?.toString().trim() ?? '';
      if (message.isEmpty) {
        continue;
      }

      final driverNumber = _extractPenaltyDriverNumber(entry, message);
      if (driverNumber == null) {
        continue;
      }

      final normalizedPenalty = _normalizePenalty(message);
      final isPenaltyServed = _isRaceControlPenaltyServedMessage(message);
      if (normalizedPenalty == null && !isPenaltyServed) {
        continue;
      }

      final sessionKey = _asInt(entry['session_key']);
      penaltyDetailsByDriver
          .putIfAbsent(driverNumber, () => <Map<String, dynamic>>[])
          .add({
            'timestampUtc': entry['date']?.toString(),
            'lap': _asInt(entry['lap_number']),
            'sessionName': sessionKey == null
                ? null
                : _normalizeSessionName(sessionNamesByKey[sessionKey]),
            'message': message,
            'penalty': normalizedPenalty,
            'served': isPenaltyServed,
          });
    }

    return penaltyDetailsByDriver;
  }

  String _compoundForLap(
    List<Map<String, dynamic>> stints,
    int driverNumber,
    int lapNumber,
  ) {
    for (final stint in stints) {
      if (_asInt(stint['driver_number']) != driverNumber) {
        continue;
      }

      final lapStart = _asInt(stint['lap_start']) ?? 0;
      final lapEnd = _asInt(stint['lap_end']) ?? 0;
      if (lapNumber >= lapStart && lapNumber <= lapEnd) {
        return stint['compound']?.toString() ?? '-';
      }
    }

    return '-';
  }

  Future<Map<String, dynamic>?> _findClosestSessionForRace({
    required Race race,
    required String sessionName,
  }) async {
    final sessions = await _fetchOpenF1Collection('sessions', <String, String>{
      'year': race.date.year.toString(),
      'session_name': sessionName,
    });
    if (sessions.isEmpty) {
      return null;
    }

    final targetDate = race.date.toUtc();
    Map<String, dynamic>? bestMatch;
    Duration? smallestDifference;

    for (final session in sessions) {
      final sessionDate = DateTime.tryParse(
        session['date_start']?.toString() ?? '',
      );
      if (sessionDate == null) {
        continue;
      }

      final difference = sessionDate.difference(targetDate).abs();
      if (smallestDifference == null || difference < smallestDifference) {
        smallestDifference = difference;
        bestMatch = session;
      }
    }

    if (smallestDifference == null ||
        smallestDifference > const Duration(days: 4)) {
      return null;
    }

    return bestMatch;
  }

  Future<List<Map<String, dynamic>>> _fetchOpenF1Collection(
    String endpoint,
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.https('api.openf1.org', '/v1/$endpoint', queryParameters);
    final cacheKey = uri.toString();
    final cached = _openF1Cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    if (_lastOpenF1RequestAt != null) {
      final elapsed = DateTime.now().difference(_lastOpenF1RequestAt!);
      const minimumDelay = Duration(milliseconds: 700);
      if (elapsed < minimumDelay) {
        await Future.delayed(minimumDelay - elapsed);
      }
    }

    // API call removed. Use local data or return empty result.
    return const <Map<String, dynamic>>[];
  }

  Map<int, String> _buildPenaltyMap(List<Map<String, dynamic>> messages) {
    final Map<int, Set<String>> penaltiesByDriver = {};

    for (final entry in messages) {
      final message = entry['message']?.toString() ?? '';
      final normalizedPenalty = _normalizePenalty(message);
      if (normalizedPenalty == null) {
        continue;
      }

      final driverNumber = _extractPenaltyDriverNumber(entry, message);
      if (driverNumber == null) {
        continue;
      }

      penaltiesByDriver
          .putIfAbsent(driverNumber, () => <String>{})
          .add(normalizedPenalty);
    }

    return {
      for (final entry in penaltiesByDriver.entries)
        entry.key: entry.value.join(', '),
    };
  }

  Map<int, List<Map<String, dynamic>>> _buildRaceControlMessagesMap(
    List<Map<String, dynamic>> messages,
    Map<int, String> sessionNamesByKey,
  ) {
    final sortedMessages = List<Map<String, dynamic>>.from(messages)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
        if (aDate != null && bDate != null) {
          final compare = aDate.compareTo(bDate);
          if (compare != 0) {
            return compare;
          }
        }

        final aLap = _asInt(a['lap_number']) ?? -1;
        final bLap = _asInt(b['lap_number']) ?? -1;
        return aLap.compareTo(bLap);
      });

    final result = <int, List<Map<String, dynamic>>>{};
    for (final entry in sortedMessages) {
      final message = entry['message']?.toString().trim() ?? '';
      if (message.isEmpty) {
        continue;
      }

      final driverNumber = _extractPenaltyDriverNumber(entry, message);
      if (driverNumber == null) {
        continue;
      }

      final sessionKey = _asInt(entry['session_key']);
      result.putIfAbsent(driverNumber, () => <Map<String, dynamic>>[]).add({
        'timestampUtc': entry['date']?.toString(),
        'lap': _asInt(entry['lap_number']),
        'category': entry['category']?.toString(),
        'flag': entry['flag']?.toString(),
        'scope': entry['scope']?.toString(),
        'sector': _asInt(entry['sector']),
        'qualifyingPhase': entry['qualifying_phase']?.toString(),
        'message': message,
        'sessionName': sessionKey == null
            ? null
                : _normalizeSessionName(sessionNamesByKey[sessionKey]),
      });
    }

    return result;
  }

  Map<String, dynamic>? _normalizeRaceControlMessageForWeekend(
    Map<String, dynamic> entry, {
    required String sessionName,
    required int sessionKey,
  }) {
    final message = entry['message']?.toString().trim() ?? '';
    if (message.isEmpty) {
      return null;
    }

    return {
      'timestampUtc': entry['date']?.toString(),
      'lap': _asInt(entry['lap_number']),
      'category': entry['category']?.toString(),
      'flag': entry['flag']?.toString(),
      'scope': entry['scope']?.toString(),
      'sector': _asInt(entry['sector']),
      'driverNumber': _extractPenaltyDriverNumber(entry, message),
      'qualifyingPhase': entry['qualifying_phase']?.toString(),
      'sessionKey': sessionKey,
      'sessionName': _normalizeSessionName(sessionName),
      'message': message,
    };
  }

  List<Map<String, dynamic>> _buildWeatherSamples(
    List<Map<String, dynamic>> weatherEntries,
  ) {
    if (weatherEntries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final sortedEntries = List<Map<String, dynamic>>.from(weatherEntries)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return aDate.compareTo(bDate);
      });

    final samplesByBucket = <String, Map<String, dynamic>>{};
    for (final entry in sortedEntries) {
      final date = DateTime.tryParse(entry['date']?.toString() ?? '');
      if (date == null) {
        continue;
      }

      final utcDate = date.toUtc();
      final bucketMinute = (utcDate.minute ~/ 5) * 5;
      final bucket = DateTime.utc(
        utcDate.year,
        utcDate.month,
        utcDate.day,
        utcDate.hour,
        bucketMinute,
      );
      final bucketKey = bucket.toIso8601String();
      samplesByBucket.putIfAbsent(bucketKey, () {
        return {
          'timestampUtc': entry['date']?.toString(),
          'airTemperatureC': _asDouble(entry['air_temperature']),
          'trackTemperatureC': _asDouble(entry['track_temperature']),
          'humidity': _asDouble(entry['humidity']),
          'rainfall': _asDouble(entry['rainfall']),
          'pressure': _asDouble(entry['pressure']),
          'windSpeed': _asDouble(entry['wind_speed']),
          'windDirection': _asInt(entry['wind_direction']),
        };
      });
    }

    return samplesByBucket.values.toList(growable: false);
  }

  int? _extractPenaltyDriverNumber(Map<String, dynamic> entry, String message) {
    final directDriverNumber = _asInt(entry['driver_number']);
    if (directDriverNumber != null) {
      return directDriverNumber;
    }

    final match = RegExp(r'CAR\s+(\d+)').firstMatch(message.toUpperCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String? _normalizePenalty(String message) {
    if (message.isEmpty) {
      return null;
    }

    final upper = message.toUpperCase();
    if (upper.contains('NO FURTHER ACTION') ||
        upper.contains('UNDER INVESTIGATION') ||
        upper.contains('NOTED') ||
        upper.contains('SUMMONED') ||
        upper.contains('WARNING') ||
        upper.contains('REPRIMAND') ||
        upper.contains('FINE')) {
      return null;
    }

    final gridMatch = RegExp(
      r'(\d+)\s*(?:PLACE|POSITION)\s+GRID\s+(?:PENALTY|DROP)',
    ).firstMatch(upper);
    if (gridMatch != null) {
      return '${gridMatch.group(1)} Grid';
    }

    final altGridMatch = RegExp(
      r'GRID\s+(?:PENALTY|DROP)\s+OF\s+(\d+)\s*(?:PLACE|POSITION)',
    ).firstMatch(upper);
    if (altGridMatch != null) {
      return '${altGridMatch.group(1)} Grid';
    }

    final timeMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*SECOND(?:S)?\s+TIME\s+PENALTY',
    ).firstMatch(upper);
    if (timeMatch != null) {
      return '+${_trimTrailingZero(timeMatch.group(1)!)}s';
    }

    final altTimeMatch = RegExp(
      r'TIME\s+PENALTY\s+OF\s+(\d+(?:\.\d+)?)\s*SECOND(?:S)?',
    ).firstMatch(upper);
    if (altTimeMatch != null) {
      return '+${_trimTrailingZero(altTimeMatch.group(1)!)}s';
    }

    final simpleTimeMatch = RegExp(
      r'PENALTY\s*-\s*(\d+(?:\.\d+)?)\s*SECOND(?:S)?',
    ).firstMatch(upper);
    if (simpleTimeMatch != null) {
      return '+${_trimTrailingZero(simpleTimeMatch.group(1)!)}s';
    }

    if (upper.contains('STOP/GO PENALTY') ||
        upper.contains('STOP AND GO PENALTY') ||
        upper.contains('STOP-AND-GO PENALTY')) {
      return 'S&G';
    }

    if (upper.contains('DRIVE THROUGH PENALTY') ||
        upper.contains('DRIVE-THROUGH PENALTY')) {
      return 'DT';
    }

    return null;
  }

  String _formatDriverName(Map<String, dynamic> driver) {
    final firstName = driver['first_name']?.toString().trim() ?? '';
    final lastName = driver['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return driver['full_name']?.toString().trim() ?? '-';
  }

  String _formatRaceFinish(Map<String, dynamic> entry, int? startPosition) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return 'DSQ';
    }

    final finishPosition = _asInt(entry['position']);
    if (finishPosition == null) {
      return 'NC';
    }

    final finishLabel = 'P$finishPosition';
    if (startPosition == null || startPosition <= 0) {
      return finishLabel;
    }

    final delta = startPosition - finishPosition;
    final deltaLabel = delta > 0
        ? '+$delta'
        : delta < 0
        ? '$delta'
        : '-';
    return '$finishLabel ($deltaLabel)';
  }

  String _formatSessionPosition(Map<String, dynamic> entry) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return 'DSQ';
    }

    return (_asInt(entry['position'])?.toString()) ?? '-';
  }

  String _formatSprintResult(Map<String, dynamic> entry) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return 'DSQ';
    }
    if (_asInt(entry['position']) == null) {
      return 'NC';
    }

    final position = _asInt(entry['position']);
    final gap = entry['gap_to_leader'];
    final duration = _asDouble(entry['duration']);
    if (position == 1 && duration != null) {
      return _formatRaceDuration(duration);
    }
    if (gap is num) {
      return '+${gap.toDouble().toStringAsFixed(3)}s';
    }

    final gapText = gap?.toString().trim() ?? '';
    if (gapText.isNotEmpty && gapText != '0') {
      return _normalizeGapText(gapText);
    }

    return '-';
  }

  String _formatTimeOrGap(Map<String, dynamic> entry, double? winnerDuration) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return '-';
    }
    if (_asInt(entry['position']) == null) {
      return 'NC';
    }

    final position = _asInt(entry['position']);
    final gap = entry['gap_to_leader'];
    final duration = _asDouble(entry['duration']);
    if (position == 1) {
      return duration == null ? '-' : _formatRaceDuration(duration);
    }

    if (gap is num) {
      return '+${gap.toDouble().toStringAsFixed(3)}s';
    }

    final gapText = gap?.toString().trim() ?? '';
    if (gapText.isNotEmpty && gapText != '0') {
      return _normalizeGapText(gapText);
    }

    if (duration != null && winnerDuration != null) {
      return '+${(duration - winnerDuration).toStringAsFixed(3)}s';
    }

    return '-';
  }

  String _formatTotalRaceTime(
    Map<String, dynamic> entry,
    double? winnerDuration,
  ) {
    if (_asBool(entry['dns'])) {
      return 'DNS';
    }
    if (_asBool(entry['dnf'])) {
      return 'DNF';
    }
    if (_asBool(entry['dsq'])) {
      return '-';
    }
    if (_asInt(entry['position']) == null) {
      return 'NC';
    }

    final duration = _asDouble(entry['duration']);
    if (duration != null) {
      return _formatRaceDuration(duration);
    }

    final gapSeconds = _extractGapInSeconds(entry['gap_to_leader']);
    if (gapSeconds != null && winnerDuration != null) {
      return _formatRaceDuration(winnerDuration + gapSeconds);
    }

    return _formatTimeOrGap(entry, winnerDuration);
  }

  double? _extractGapInSeconds(dynamic gap) {
    if (gap is num) {
      return gap.toDouble();
    }

    final gapText = gap?.toString().trim() ?? '';
    if (gapText.isEmpty) {
      return null;
    }

    final normalized = gapText.replaceAll('+', '').replaceAll('s', '').trim();
    final numericGap = double.tryParse(normalized);
    if (numericGap != null) {
      return numericGap;
    }

    final minuteSecondMatch = RegExp(
      r'^(\d+):(\d{1,2}(?:\.\d+)?)$',
    ).firstMatch(normalized);
    if (minuteSecondMatch != null) {
      final minutes = int.tryParse(minuteSecondMatch.group(1)!);
      final seconds = double.tryParse(minuteSecondMatch.group(2)!);
      if (minutes != null && seconds != null) {
        return minutes * 60 + seconds;
      }
    }

    return null;
  }

  String _normalizeGapText(String gapText) {
    final upper = gapText.toUpperCase();
    final lapMatch = RegExp(r'\+(\d+)\s+LAP(S)?').firstMatch(upper);
    if (lapMatch != null) {
      final laps = lapMatch.group(1)!;
      return '+$laps ${laps == '1' ? 'lap' : 'laps'}';
    }

    if (gapText.startsWith('+')) {
      return gapText;
    }
    return '+$gapText';
  }

  String _formatRaceDuration(double totalSeconds) {
    final duration = Duration(
      microseconds: (totalSeconds * Duration.microsecondsPerSecond).round(),
    );
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMicroseconds.remainder(Duration.microsecondsPerSecond)) /
                1000)
            .round()
            .toString()
            .padLeft(3, '0');
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  String _formatLapDuration(double? totalSeconds) {
    if (totalSeconds == null) {
      return '-';
    }

    final duration = Duration(
      microseconds: (totalSeconds * Duration.microsecondsPerSecond).round(),
    );
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        ((duration.inMicroseconds.remainder(Duration.microsecondsPerSecond)) /
                1000)
            .round()
            .toString()
            .padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatLapDurationWithOptionalLap(
    double? totalSeconds,
    int? lapNumber,
  ) {
    return RaceResultRow.openF1AppendLapNumberInParens(
      _formatLapDuration(totalSeconds),
      lapNumber,
    );
  }

  String _formatTyreCompound(String? compound) {
    switch ((compound ?? '').toUpperCase()) {
      case 'SOFT':
        return 'Soft';
      case 'MEDIUM':
        return 'Medium';
      case 'HARD':
        return 'Hard';
      case 'INTERMEDIATE':
        return 'Inter';
      case 'WET':
        return 'Wet';
      default:
        return '-';
    }
  }

  String _formatPoints(double points) {
    if (points == points.roundToDouble()) {
      return points.toInt().toString();
    }
    return points.toStringAsFixed(1);
  }

  bool _asBool(dynamic value) => value == true;

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}

/// Native display names for each supported locale (gen-l10n [language_selector]).
Map<Locale, String> _f1LanguageDisplayNames(List<Locale> supportedLocales) {
  final entries = <Locale, String>{};
  for (final locale in supportedLocales) {
    try {
      entries[locale] = lookupAppLocalizations(locale).language_selector;
    } catch (_) {
      entries[locale] = locale.languageCode;
    }
  }
  return entries;
}

/// Shared language picker (also used from full settings menu).
Future<void> showF1LanguageDialog(BuildContext context) async {
  final entries = _f1LanguageDisplayNames(AppLocalizations.supportedLocales);
  if (!context.mounted) return;
  final Locale? selectedLocale = await hubShowDialogWithBlurBarrier<Locale>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text(context.l10n.language),
        children: entries.entries
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, e.key),
                child: Text(e.value),
              ),
            )
            .toList(),
      );
    },
  );
  if (selectedLocale != null && context.mounted) {
    await F1HubApp.setAppLocale(context, selectedLocale);
  }
}

/// Desktop sidebar: account actions only (no theme/cache here — use profile when logged in).
class RailAccountMenuButton extends StatelessWidget {
  const RailAccountMenuButton({super.key, this.hubCockpit = false});

  /// Legacy flag (shell styling); icon always uses hub-readable contrast.
  final bool hubCockpit;

  static Stream<AuthState> get _authStream =>
      Supabase.instance.client.auth.onAuthStateChange;

  @override
  Widget build(BuildContext menuButtonContext) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (streamContext, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;

        return PopupMenuButton<String>(
          icon: Icon(
            Icons.settings_outlined,
            size: 22,
            color: HubTheme.secondaryOnGlassText(menuButtonContext),
          ),
          tooltip: isLoggedIn
              ? menuButtonContext.l10n.profile
              : menuButtonContext.l10n.login_register_menu,
          onSelected: (value) async {
            switch (value) {
              case 'login':
                streamContext.push(_loginPath());
                break;
              case 'profile':
                streamContext.go(_profilePath());
                break;
              case 'logout':
                await Supabase.instance.client.auth.signOut();
                if (streamContext.mounted) {
                  streamContext.go(_circuitsPath());
                }
                break;
              case 'help_github':
                browser_bridge.openExternalUrl(_kGithubHelpIssuesUrl);
                break;
            }
          },
          // Use menuButtonContext for tr(): overlay itemBuilder context can miss
          // Localizations in some builds (e.g. web).
          itemBuilder: (_) => [
            if (!isLoggedIn)
              PopupMenuItem<String>(
                value: 'login',
                child: Row(
                  children: [
                    _buildGlyphIcon('🔐', size: 18),
                    const SizedBox(width: 12),
                    Text(menuButtonContext.l10n.login_register_menu),
                  ],
                ),
              ),
            if (isLoggedIn) ...[
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    _buildGlyphIcon('👤', size: 18),
                    const SizedBox(width: 12),
                    Text(menuButtonContext.l10n.profile),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    _buildGlyphIcon('🚪', size: 18),
                    const SizedBox(width: 12),
                    Text(menuButtonContext.l10n.logout),
                  ],
                ),
              ),
            ],
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'help_github',
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Theme.of(menuButtonContext).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(menuButtonContext.l10n.help_and_ideas),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class AppSettingsMenuButton extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final Widget? icon;

  const AppSettingsMenuButton({
    required this.onToggleTheme,
    this.icon,
    super.key,
  });

  static Stream<AuthState> get _authStateStream =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<void> _handleSettingsSelection(
    BuildContext context,
    String value,
  ) async {
    switch (value) {
      case 'theme':
        await _showThemeBottomSheet(context);
        break;
      case 'language':
        await showF1LanguageDialog(context);
        break;
      case 'changelog':
        context.push(_changelogPath());
        break;
      case 'clear_cache':
        await _clearCache(context);
        break;
      case 'login':
        context.push(_loginPath());
        break;
      case 'profile':
        context.go(_profilePath());
        break;
      case 'logout':
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          context.go(_circuitsPath());
        }
        break;
      case 'help_github':
        browser_bridge.openExternalUrl(_kGithubHelpIssuesUrl);
        break;
      case 'legal':
        await showHubLegalGlassDialog(context);
        break;
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    final themeSchemeIndex = prefs.getInt('theme_scheme_index');
    final themeIsDark = prefs.getBool('theme_is_dark');

    await prefs.clear();
    if (languageCode != null) {
      await prefs.setString('language_code', languageCode);
    }
    if (themeSchemeIndex != null) {
      await prefs.setInt('theme_scheme_index', themeSchemeIndex);
    }
    if (themeIsDark != null) {
      await prefs.setBool('theme_is_dark', themeIsDark);
    }

    await SessionDataManager().clearStoredSessionCache();
    await Hive.box(HiveBoxes.raceResults).clear();
    SessionDataManager().isInitialized = false;
    await SessionDataManager().init(races);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.cache_cleared)));
  }

  Future<void> _showThemeBottomSheet(BuildContext context) async {
    final controller = context.read<ThemeController>();
    if (!context.mounted) return;
    await hubShowModalBottomSheetWithBlurBarrier<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            elevation: 10,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  context.l10n.toggle_theme,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(value: ThemeMode.light, label: Text(context.l10n.theme_mode_light)),
                          ButtonSegment(value: ThemeMode.dark, label: Text(context.l10n.theme_mode_dark)),
                          ButtonSegment(value: ThemeMode.system, label: Text(context.l10n.theme_mode_system)),
                        ],
                        selected: {controller.themeMode},
                        onSelectionChanged: (modes) {
                          controller.setThemeMode(modes.first);
                        },
                      ),
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

  @override
  Widget build(BuildContext menuButtonContext) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (streamContext, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;

        return PopupMenuButton<String>(
          icon: icon ?? _buildGlyphIcon('⚙', size: 20),
          tooltip: menuButtonContext.l10n.settings,
          onSelected: (value) =>
              _handleSettingsSelection(streamContext, value),
          itemBuilder: (_) => [
            if (!isLoggedIn)
              PopupMenuItem<String>(
                value: 'login',
                child: Row(
                  children: [
                    _buildGlyphIcon('🔐', size: 18),
                    const SizedBox(width: 12),
                    Text(menuButtonContext.l10n.login_register_menu),
                  ],
                ),
              ),
            if (isLoggedIn) ...[
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    _buildGlyphIcon('👤', size: 18),
                    const SizedBox(width: 12),
                    Text(menuButtonContext.l10n.profile),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    _buildGlyphIcon('🚪', size: 18),
                    const SizedBox(width: 12),
                    Text(menuButtonContext.l10n.logout),
                  ],
                ),
              ),
            ],
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'help_github',
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Theme.of(menuButtonContext).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(menuButtonContext.l10n.help_and_ideas),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  _buildGlyphIcon('◐', size: 18),
                  const SizedBox(width: 12),
                  Text(menuButtonContext.l10n.toggle_theme),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'language',
              child: Row(
                children: [
                  _buildGlyphIcon('🌐', size: 18),
                  const SizedBox(width: 12),
                  Text(menuButtonContext.l10n.language),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'changelog',
              child: Row(
                children: [
                  _buildGlyphIcon('↻', size: 18),
                  const SizedBox(width: 12),
                  Text(menuButtonContext.l10n.changelog),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'legal',
              child: Row(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    size: 18,
                    color: Theme.of(menuButtonContext).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(menuButtonContext.l10n.nav_legal),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'clear_cache',
              child: Row(
                children: [
                  _buildGlyphIcon('🗑', size: 18),
                  const SizedBox(width: 12),
                  Text(
                    menuButtonContext.l10n.clear_cache,
                    style: TextStyle(
                      color: Theme.of(menuButtonContext).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows "Je bent ingelogd" SnackBar (3 sec) when returning from login.
class _LoggedInSnackBarTrigger extends StatefulWidget {
  final Widget child;

  const _LoggedInSnackBarTrigger({required this.child});

  @override
  State<_LoggedInSnackBarTrigger> createState() => _LoggedInSnackBarTriggerState();
}

class _LoggedInSnackBarTriggerState extends State<_LoggedInSnackBarTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (LoggedInNotifier.shouldShowAndClear()) {
        final controller = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.logged_in),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) controller.close();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Custom nav rail: neutral inactive icons, primary + 3px stripe for active,
/// hover tint from F1ThemeTokens.hoverHighlight. No bright bubble.
class _F1NavRail extends StatefulWidget {
  /// Index of selected tab, or `null` when the active route has no rail tile (e.g. profile-only branch).
  final int? selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;

  const _F1NavRail({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  State<_F1NavRail> createState() => _F1NavRailState();
}

class _F1NavRailState extends State<_F1NavRail> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<F1ThemeTokens>();
    final primary = scheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? ConstructorHubColors.textSecondary
        : HubTheme.f1DeepCharcoal;
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : (tokens?.hoverHighlight ?? primary.withValues(alpha: 0.08));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: widget.extended ? 18 : 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ConstructorHubColors.railLogoRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 22),
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'F1HUB',
                      style: HubVisualLanguage.f1Wide(
                        context,
                        fontSize: 15,
                        color: HubTheme.primaryOnGlassText(context),
                      ),
                    ),
                    Text(
                      'SEASON ${DateTime.now().year}',
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.85,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        for (int i = 0; i < widget.destinations.length; i++)
          _F1NavTile(
            destination: widget.destinations[i],
            isSelected:
                widget.selectedIndex != null && widget.selectedIndex == i,
            isHovered: _hoveredIndex == i,
            inactiveColor: inactiveColor,
            primaryColor: primary,
            hoverBackground: hoverBg,
            extended: widget.extended,
            onTap: () => widget.onDestinationSelected(i),
            onHover: (hover) => setState(() => _hoveredIndex = hover ? i : null),
          ),
      ],
    );
  }
}

class _F1NavTile extends StatelessWidget {
  final NavigationRailDestination destination;
  final bool isSelected;
  final bool isHovered;
  final Color inactiveColor;
  final Color primaryColor;
  final Color hoverBackground;
  final bool extended;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _F1NavTile({
    required this.destination,
    required this.isSelected,
    required this.isHovered,
    required this.inactiveColor,
    required this.primaryColor,
    required this.hoverBackground,
    required this.extended,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedRed = ConstructorHubColors.railLogoRed;
    final iconColor = isSelected ? selectedRed : inactiveColor;
    final showFadingBorder = isSelected;

    final labelStyle = GoogleFonts.titilliumWeb(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: iconColor,
    );

    Widget rowContent({required EdgeInsetsGeometry padding}) {
      return Padding(
        padding: padding,
        child: Row(
          mainAxisSize: extended ? MainAxisSize.max : MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: iconColor, size: 22),
                  child: DefaultTextStyle(
                    style: TextStyle(color: iconColor, fontSize: 18),
                    child: isSelected ? destination.selectedIcon : destination.icon,
                  ),
                ),
              ),
            ),
            if (extended)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: DefaultTextStyle(
                  style: labelStyle,
                  child: destination.label,
                ),
              ),
          ],
        ),
      );
    }

    Widget selectedGlass() {
      if (isDark) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: HubVisualLanguage.glassBlurSigma,
              sigmaY: HubVisualLanguage.glassBlurSigma,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: isHovered ? 0.22 : 0.12,
                  ),
                  width: 0.8,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      ConstructorHubColors.surfaceElevated,
                      ConstructorHubColors.railLogoRed,
                      isHovered ? 0.5 : 0.42,
                    )!,
                    ConstructorHubColors.surfaceElevated
                        .withValues(alpha: 0.94),
                  ],
                ),
              ),
              child: rowContent(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: HubVisualLanguage.glassBlurSigma,
            sigmaY: HubVisualLanguage.glassBlurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black.withValues(
                  alpha: isHovered ? 0.10 : 0.06,
                ),
                width: HubVisualLanguage.glassBorderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    Colors.white.withValues(alpha: 0.82),
                    ConstructorHubColors.railLogoRed,
                    isHovered ? 0.20 : 0.14,
                  )!,
                  Colors.white.withValues(alpha: 0.52),
                ],
              ),
            ),
            child: rowContent(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: showFadingBorder
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: selectedGlass(),
              )
            : Container(
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isHovered ? hoverBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: extended ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: IconTheme.merge(
                          data: IconThemeData(color: iconColor, size: 22),
                          child: DefaultTextStyle(
                            style: TextStyle(color: iconColor, fontSize: 18),
                            child: isSelected
                                ? destination.selectedIcon
                                : destination.icon,
                          ),
                        ),
                      ),
                    ),
                    if (extended)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: DefaultTextStyle(
                          style: labelStyle,
                          child: destination.label,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

List<F1HubMobileNavEntry> _hubMobileNavEntries(
  BuildContext context,
  bool hubNavIcons,
) {
  return <F1HubMobileNavEntry>[
    F1HubMobileNavEntry(
      icon: hubNavIcons
          ? const Icon(Icons.view_quilt_outlined, size: 22)
          : _buildGlyphIcon('🏁', size: 20),
      selectedIcon: hubNavIcons
          ? const Icon(Icons.view_quilt, size: 22)
          : _buildGlyphIcon('🏁', size: 20),
      label: context.l10n.circuits.toUpperCase(),
    ),
    F1HubMobileNavEntry(
      icon: hubNavIcons
          ? const Icon(Icons.calendar_month_outlined, size: 22)
          : _buildGlyphIcon('📅', size: 20),
      selectedIcon: hubNavIcons
          ? const Icon(Icons.calendar_month, size: 22)
          : _buildGlyphIcon('📅', size: 20),
      label: context.l10n.calendar_nav.toUpperCase(),
    ),
    F1HubMobileNavEntry(
      icon: hubNavIcons
          ? const Icon(Icons.people_outline, size: 22)
          : _buildGlyphIcon('👤', size: 20),
      selectedIcon: hubNavIcons
          ? const Icon(Icons.people, size: 22)
          : _buildGlyphIcon('👤', size: 20),
      label: context.l10n.drivers.toUpperCase(),
    ),
    F1HubMobileNavEntry(
      icon: hubNavIcons
          ? const Icon(Icons.emoji_events_outlined, size: 22)
          : _buildGlyphIcon('👥', size: 20),
      selectedIcon: hubNavIcons
          ? const Icon(Icons.emoji_events, size: 22)
          : _buildGlyphIcon('👥', size: 20),
      label: context.l10n.teams.toUpperCase(),
    ),
    F1HubMobileNavEntry(
      icon: hubNavIcons
          ? const Icon(Icons.insights_outlined, size: 22)
          : _buildGlyphIcon('📊', size: 20),
      selectedIcon: hubNavIcons
          ? const Icon(Icons.insights, size: 22)
          : _buildGlyphIcon('📊', size: 20),
      label: context.l10n.simulator_nav.toUpperCase(),
    ),
    F1HubMobileNavEntry(
      icon: hubNavIcons
          ? const Icon(Icons.person_outline, size: 22)
          : _buildGlyphIcon('👤', size: 20),
      selectedIcon: hubNavIcons
          ? const Icon(Icons.person, size: 22)
          : _buildGlyphIcon('👤', size: 20),
      label: context.l10n.profile.toUpperCase(),
    ),
  ];
}

class MainNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  /// Width >= 600: sidebar (rail). Width < 600: glass top bar + full-screen menu.
  static const double _desktopShellBreakpoint = 600;

  const MainNavigation({required this.navigationShell, super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool _mobileMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    const hubNavIcons = true;

    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const Icon(Icons.view_quilt_outlined, size: 22),
        selectedIcon: const Icon(Icons.view_quilt, size: 22),
        label: Text(context.l10n.circuits.toUpperCase()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.calendar_month_outlined, size: 22),
        selectedIcon: const Icon(Icons.calendar_month, size: 22),
        label: Text(context.l10n.calendar_nav.toUpperCase()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.people_outline, size: 22),
        selectedIcon: const Icon(Icons.people, size: 22),
        label: Text(context.l10n.drivers.toUpperCase()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.emoji_events_outlined, size: 22),
        selectedIcon: const Icon(Icons.emoji_events, size: 22),
        label: Text(context.l10n.teams.toUpperCase()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.insights_outlined, size: 22),
        selectedIcon: const Icon(Icons.insights, size: 22),
        label: Text(context.l10n.simulator_nav.toUpperCase()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.person_outline, size: 22),
        selectedIcon: const Icon(Icons.person, size: 22),
        label: Text(context.l10n.profile.toUpperCase()),
      ),
    ];
    final railDestinations = destinations.sublist(0, 5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= MainNavigation._desktopShellBreakpoint;
        final hubCockpit = Theme.of(context).brightness == Brightness.dark;
        final scheme = Theme.of(context).colorScheme;
        final ambientGlow = hubCockpit
            ? Colors.transparent
            : scheme.primary.withValues(alpha: 0.10);
        final shellBase =
            hubCockpit ? ConstructorHubColors.background : HubTheme.lightCanvas;

        // Extended rail (labels + 242px) for every desktop shell width. The old
        // 1320px cutoff collapsed the hub rail on typical 14" viewports (~1280–1366).
        final railExtended = isDesktop;
        final bottomSafe = MediaQuery.paddingOf(context).bottom;
        final railBlurSigma = HubMobileTuning.panelBackdropBlurSigma(context);

        Widget railPanel = const SizedBox.shrink();
        if (isDesktop) {
          final hubRailW = railExtended ? 242.0 : 84.0;
          final railColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _F1NavRail(
                    selectedIndex: navigationShell.currentIndex < 5
                        ? navigationShell.currentIndex
                        : null,
                    extended: railExtended,
                    onDestinationSelected: (i) => navigationShell.goBranch(
                      i,
                      initialLocation: true,
                    ),
                    destinations: railDestinations,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RailAccountMenuButton(hubCockpit: hubCockpit),
                ),
              ),
              NextRaceHubMiniCard(
                raceName: _nextUpcomingRaceForHub()?.name,
                raceDate: _nextUpcomingRaceForHub()?.date,
                lightForegroundOnDarkPanel: hubCockpit,
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: 2,
                  left: railExtended ? 4 : 0,
                ),
                child: Align(
                  alignment:
                      railExtended ? Alignment.centerLeft : Alignment.center,
                  child: HubLegalNavLink(
                    hubCockpit: hubCockpit,
                    compact: !railExtended,
                  ),
                ),
              ),
              SizedBox(height: bottomSafe > 0 ? bottomSafe + 8 : 12),
            ],
          );
          railPanel = SizedBox(
            width: hubRailW,
            child: hubCockpit
                ? ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: railBlurSigma,
                        sigmaY: railBlurSigma,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                ConstructorHubColors.surface,
                                Colors.white,
                                0.05,
                              )!,
                              ConstructorHubColors.surface,
                            ],
                          ),
                          border: const Border(
                            right: BorderSide(color: ConstructorHubColors.border),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 14, 10, 0),
                          child: railColumn,
                        ),
                      ),
                    ),
                  )
                : HubVisualLanguage.glassPanel(
                    context: context,
                    radius: 0,
                    blurSigma: railBlurSigma,
                    panelBorder: Border(
                      right: BorderSide(
                        color: Colors.black.withValues(alpha: 0.06),
                        width: HubVisualLanguage.glassBorderWidth,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 14, 10, 0),
                    child: railColumn,
                  ),
          );
        }

        final hubBackdrop = DecoratedBox(
          decoration: BoxDecoration(
            color: hubCockpit ? Colors.transparent : shellBase,
          ),
          child: hubCockpit
              ? const SizedBox.shrink()
              : CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
        );

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor:
              hubCockpit ? ConstructorHubColors.background : shellBase,
          body: isDesktop
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    hubBackdrop,
                    SafeArea(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          railPanel,
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // No desktop title pill — branding lives in the rail only
                                // (matches dark hub; avoids duplicate "F1 HUB" in light mode).
                                Padding(
                                  padding: f1HubShellHorizontalPadding(context),
                                  child: const SizedBox.shrink(),
                                ),
                                Expanded(
                                  child: hubCockpit
                                      ? Padding(
                                          padding:
                                              f1HubShellHorizontalPadding(
                                            context,
                                          ),
                                          child: navigationShell,
                                        )
                                      : ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: f1HubShellHorizontalPadding(
                                              context,
                                            ),
                                            child: navigationShell,
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
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(child: hubBackdrop),
                          Positioned.fill(
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: () {
                                  final h = f1HubShellHorizontalPadding(context);
                                  return EdgeInsets.fromLTRB(
                                    h.left,
                                    F1HubMobileGlassAppBar.reservedHeight(
                                      context,
                                    ),
                                    h.right,
                                    0,
                                  );
                                }(),
                                child: navigationShell,
                              ),
                            ),
                          ),
                          if (_mobileMenuOpen)
                            Positioned.fill(
                              child: () {
                                final nr = _nextUpcomingRaceForHub();
                                return F1HubMobileNavOverlay(
                                  hubCockpitDark: hubCockpit,
                                  selectedIndex: navigationShell.currentIndex,
                                  entries: _hubMobileNavEntries(
                                    context,
                                    hubNavIcons,
                                  ),
                                  onClose: () =>
                                      setState(() => _mobileMenuOpen = false),
                                  onDestinationSelected: (i) {
                                    navigationShell.goBranch(
                                      i,
                                      initialLocation: true,
                                    );
                                    setState(() => _mobileMenuOpen = false);
                                  },
                                  nextRaceName: nr?.name,
                                  nextRaceDate: nr?.date,
                                );
                              }(),
                            ),
                          // Last: paints above full-screen overlay on web (avoids “empty” bar).
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: F1HubMobileGlassAppBar(
                              hubCockpitDark: hubCockpit,
                              onMenuPressed: () =>
                                  setState(() => _mobileMenuOpen = true),
                              navMenuOpen: _mobileMenuOpen,
                              onNavMenuClose: () =>
                                  setState(() => _mobileMenuOpen = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: null,
        );
      },
    );
  }
}

bool _isDesktopShellLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= MainNavigation._desktopShellBreakpoint;

List<Widget> _desktopAwareSettingsActions(
  BuildContext context,
  Widget settingsMenu,
) {
  if (_isDesktopShellLayout(context)) {
    return const <Widget>[];
  }
  final path = GoRouterState.of(context).uri.path;
  final base = _profilePath();
  final isProfileRoute = path == base || path.startsWith('$base/');
  if (!isProfileRoute) {
    return const <Widget>[];
  }
  return <Widget>[settingsMenu];
}

/// Logged-in quick-access hub at [`_myPaddockPath`] (web: `/#/my-paddock`).
class MyPaddockScreen extends StatelessWidget {
  const MyPaddockScreen({super.key, required this.settingsMenu});

  final Widget settingsMenu;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(context.l10n.my_paddock_title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        actions: _desktopAwareSettingsActions(context, settingsMenu),
      ),
      body: user != null
          ? SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                    children: const [MyPaddockWidget()],
                  ),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _profileSectionCard(
                    context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.my_paddock_title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => context.push(_loginPath()),
                          child: Text(context.l10n.login),
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

/// [circuitsOnly]: circuit catalog only. [calendarPage]: full race calendar at `/calendar`. [legacyDashboard]: `/#/old/dash` (hidden from the menu).
enum CircuitsHomeMode {
  circuitsOnly,
  legacyDashboard,
  calendarPage,
}

/// --- CIRCUITS VIEW (TAB 0 ROOT) ---
class CircuitsView extends StatefulWidget {
  const CircuitsView({super.key, this.homeMode = CircuitsHomeMode.circuitsOnly});
  final CircuitsHomeMode homeMode;
  @override
  State<CircuitsView> createState() => _CircuitsViewState();
}

class _CircuitsViewState extends State<CircuitsView> {
  bool _hasResultsForRace(Race race) {
      final cacheKey = SessionDataManager().raceResultsKeyFor(race);
      final cachedResults = SessionDataManager().raceResultsCache[cacheKey];
      return cachedResults != null && cachedResults.isNotEmpty;
    }
  static const double _desktopCircuitsBreakpoint = 1100;
  /// Min content width for two-column circuit cards (sidebar shrinks viewport; 1100 was too high).
  static const double _circuitsCatalogTwoColumnBreakpoint = 720;
  String liveTemp = "--";
  int liveRain = 0;
  /// Display e.g. "18 km/h"; '--' when unknown.
  String liveWind = '--';
  Timer? _timer;
  TextEditingController? _calendarSearchController;
  TextEditingController? _circuitsSearchController;

  @override
  void initState() {
    super.initState();
    if (widget.homeMode == CircuitsHomeMode.calendarPage) {
      _calendarSearchController = TextEditingController();
      _calendarSearchController!.addListener(() {
        if (mounted) setState(() {});
      });
    }
    if (widget.homeMode == CircuitsHomeMode.circuitsOnly) {
      _circuitsSearchController = TextEditingController();
      _circuitsSearchController!.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _primeHomeData();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _fetchLiveWeather();
    });
  }

  @override
  void dispose() {
    _calendarSearchController?.dispose();
    _circuitsSearchController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Race _nextRace() => nextRaceAfterNowSkippingCancelled(races);

  Race? _latestCompletedRace() {
    final list = _lastNCompletedRaces(1);
    return list.isEmpty ? null : list.first;
  }

  /// Most recent past races by calendar date, newest first (up to [maxCount]).
  List<Race> _lastNCompletedRaces(int maxCount) {
    if (maxCount < 1) return const [];
    final now = DateTime.now();
    final out = <Race>[];
    for (final race in races.reversed) {
      if (!race.date.isAfter(now)) {
        out.add(race);
        if (out.length >= maxCount) break;
      }
    }
    return out;
  }

  Future<void> _primeHomeData() async {
    await _fetchLiveWeather();
    await _preloadLatestRacePodium();
    await _preloadRecentSessionResults();
  }

  Future<void> _preloadLatestRacePodium() async {
    final toLoad = _lastNCompletedRaces(3);
    if (toLoad.isEmpty) {
      return;
    }

    for (final race in toLoad) {
      final cacheKey = SessionDataManager().raceResultsKeyFor(race);
      final cachedResults = SessionDataManager().raceResultsCache[cacheKey];
      if (cachedResults != null && cachedResults.length >= 3) {
        continue;
      }
      final roundIndex = raceRoundFor(race);
      await SessionDataManager().fetchDataForRace(race, roundIndex);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _preloadRecentSessionResults() async {
    final now = DateTime.now();
    final targetRaces = races.where((race) {
      if (race.date.isAfter(now)) {
        return false;
      }
      return race.date.difference(now).inDays.abs() <= 7;
    }).toList();

    if (targetRaces.isEmpty) {
      final latestRace = _latestCompletedRace();
      if (latestRace != null) {
        targetRaces.add(latestRace);
      }
    }

    for (final race in targetRaces) {
      final roundIndex = raceRoundFor(race);
      await SessionDataManager().ensureRaceDataAvailable(race, roundIndex);
    }
  }

  Future<void> _fetchLiveWeather() async {
    try {
      final race = _nextRace();
      final w = await fetchWeatherForRace(race.lat, race.lon);
      if (mounted && w != null) {
        setState(() {
          liveTemp = w.temperature.round().toString();
          liveRain = w.precipitationProbability;
          liveWind = '${w.windspeed.round()} km/h';
        });
      } else if (mounted) {
        setState(() {
          liveTemp = '-';
          liveRain = 0;
          liveWind = '-';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          liveTemp = '-';
          liveRain = 0;
          liveWind = '-';
        });
      }
    }
  }

  Future<void> _refreshCircuits() async {
    await _fetchLiveWeather();
    await _preloadLatestRacePodium();

    final now = DateTime.now();
    final racesToRefresh = races.where((race) {
      final dayDifference = race.date.difference(now).inDays.abs();
      return dayDifference <= 7;
    }).toList();

    if (racesToRefresh.isEmpty) {
      racesToRefresh.add(_nextRace());
    }

    for (final race in racesToRefresh) {
      final roundIndex = raceRoundFor(race);
      await SessionDataManager().fetchDataForRace(race, roundIndex);
    }
  }

  String _timeUntil(DateTime date, BuildContext context) {

    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return '';
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      final remainingDays = diff.inDays % 7;
      String w =
          '$weeks ${weeks == 1 ? context.l10n.week : context.l10n.weeks}';
      if (remainingDays > 0) {
        w +=
            ', $remainingDays ${remainingDays == 1 ? context.l10n.day : context.l10n.days}';
      }
      return w;
    } else if (diff.inDays >= 1) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return '$days ${days == 1 ? context.l10n.day : context.l10n.days}${hours > 0 ? ', $hours ${context.l10n.hours}' : ''}';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} ${context.l10n.hours}, ${diff.inMinutes % 60} ${context.l10n.minutes}';
    } else {
      return '${diff.inMinutes} ${context.l10n.minutes}';
    }
  }

  String _getPodiumString(Race race) {
    final results = _circuitPodiumRows(race);
    final medals = ['🥇', '🥈', '🥉'];
    if (results.isNotEmpty) {
      return results
          .asMap()
          .map((i, row) => MapEntry(i, '${medals[i]} ${row.driver.split(' ').last}'))
          .values
          .join('  ');
    }
    final fallback = ['Verstappen', 'Norris', 'Leclerc'];
    return List.generate(3, (i) => '${medals[i]} ${fallback[i]}').join('  ');
  }

  bool _hasSummerBreakAfter(Race race) {
    return race.name == 'Hungarian Grand Prix';
  }

  List<Race> _calendarRacesList(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final hideCancelled = user != null &&
        context.watch<CalendarPrefsNotifier>().value.hideCancelledRaces;
    return hideCancelled
        ? races.where((r) => !_isCancelledGrandPrix(r)).toList()
        : List<Race>.from(races);
  }

  /// Placeholder “cancelled” races (not on calendar when user hides them).
  bool _isCancelledGrandPrix(Race race) => isCancelledGrandPrix(race);

  List<Race> _summerBreakRaces() {
    final hungarianIndex = races.indexWhere(
      (race) => race.name == 'Hungarian Grand Prix',
    );
    final dutchIndex = races.indexWhere(
      (race) => race.name == 'Dutch Grand Prix',
    );
    if (hungarianIndex == -1 ||
        dutchIndex == -1 ||
        dutchIndex <= hungarianIndex) {
      return const <Race>[];
    }
    return <Race>[races[hungarianIndex], races[dutchIndex]];
  }

  String _calendarDateLabel(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  List<String> _recentPreviousWinners(Race race, {int count = 3}) {
    if (race.previousWinners.isEmpty) {
      return const <String>[];
    }
    return race.previousWinners.take(count).map((s) {
      final match = RegExp(r'^\d{4}:\s*').firstMatch(s);
      return match != null ? s.substring(match.end).trim() : s;
    }).toList(growable: false);
  }

  Widget _buildPreviousWinnersBlock(
    BuildContext context,
    Race race, {
    bool compact = false,
    String? favoriteDriver,
    bool onLightBackground = false,
  }) {
    final theme = Theme.of(context);
    final labelColor = onLightBackground ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    final textColor = onLightBackground ? Colors.white : theme.colorScheme.onSurface;
    final accentColor = onLightBackground ? Colors.white : theme.colorScheme.secondary;

    final winners = _recentPreviousWinners(race, count: compact ? 2 : 3);
    if (winners.isEmpty) {
      return const SizedBox.shrink();
    }

    final lastWinner = winners.first;
    bool isFavoriteWinner(String name) =>
        favoriteDriver != null &&
        favoriteDriver.isNotEmpty &&
        normalizeForComparison(name) == normalizeForComparison(favoriteDriver);

    TextStyle winnerTextStyle(String winner, {bool compactStyle = false}) {
      final isFavorite = isFavoriteWinner(winner);
      return TextStyle(
        fontSize: compactStyle ? 12 : 11,
        fontWeight: isFavorite ? FontWeight.bold : (compactStyle ? FontWeight.w700 : FontWeight.w600),
        color: isFavorite ? accentColor : textColor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compact ? context.l10n.last_winner : context.l10n.previous_winners,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        if (compact)
          Text(
            lastWinner,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: winnerTextStyle(lastWinner, compactStyle: true),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: winners
                .map(
                  (winner) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: onLightBackground
                          ? Colors.white.withValues(alpha: 0.2)
                          : theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: onLightBackground
                            ? Colors.white.withValues(alpha: 0.4)
                            : theme.colorScheme.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      winner,
                      style: winnerTextStyle(winner),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  List<Widget> _buildCalendarEntries(BuildContext context) {
    final calendarRaces = _calendarRacesList(context);
    return calendarRaces
        .map((race) => _buildCalendarRaceCard(context, race))
        .toList();
  }

  /// Calendar list / separator spacing (cards must not touch).
  double _calendarInterRowGap(BuildContext context) => 16.0;

  Widget _buildCalendarSeparator(BuildContext context) {
    return SizedBox(height: _calendarInterRowGap(context));
  }

  /// Returns calendar entries interleaved with separators.
  List<Widget> _buildCalendarListWithSeparators(BuildContext context) {
    final entries = _buildCalendarEntries(context);
    if (entries.isEmpty) return [];

    final result = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      result.add(entries[i]);
      if (i < entries.length - 1) {
        result.add(_buildCalendarSeparator(context));
      }
    }
    return result;
  }

  /// Desktop / compact: one card listing podiums for the most recent races (profile 1–3).
  Widget _buildDesktopOverviewSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final n = context.watch<LastPodiumPrefsNotifier>().value.raceCount;
    final completed = _lastNCompletedRaces(n);
    if (completed.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      Text(
        context.l10n.last_podium_prefs_section_title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.secondary,
        ),
      ),
    ];

    for (var i = 0; i < completed.length; i++) {
      final race = completed[i];
      if (i > 0) {
        children.addAll([
          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
        ]);
      } else {
        children.add(const SizedBox(height: 10));
      }
      children.addAll([
        Text(
          l10nGrandPrix(context.l10n, race.name),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        _buildCircuitPodiumPreview(
          context,
          race,
          alignment: CrossAxisAlignment.start,
        ),
      ]);
    }

    return Card(
      color: theme.colorScheme.surface,
      elevation: 1,
      shadowColor: theme.colorScheme.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: F1Module(
        fillWidth: true,
        padding: const EdgeInsets.all(18),
        borderRadius: 20,
        backgroundColor: theme.colorScheme.surface,
        showFadingBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDesktopCalendarHeader(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    const headerHeight = 48.0;

    return Container(
      height: headerHeight,
      margin: const EdgeInsets.fromLTRB(
        HubListCardStyle.shellHorizontalMargin,
        10,
        HubListCardStyle.shellHorizontalMargin,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: tokens.panelStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                const SizedBox(width: 48),
                Text(
                  context.l10n.race.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.l10n.country.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              context.l10n.date.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              context.l10n.last_winner.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                context.l10n.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCalendarGrid(
    BuildContext context, {
    bool includeColumnHeader = true,
  }) {
    final calendarRaces = _calendarRacesList(context);
    final rowGap = _calendarInterRowGap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeColumnHeader) ...[
          _buildDesktopCalendarHeader(context),
          const SizedBox(height: 16),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: calendarRaces.length,
          separatorBuilder: (context, index) {
            final gap = SizedBox(height: rowGap);
            if (index < calendarRaces.length - 1 &&
                _hasSummerBreakAfter(calendarRaces[index])) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  gap,
                  _buildSummerBreakHubStrip(context),
                  gap,
                ],
              );
            }
            return gap;
          },
          itemBuilder: (context, index) =>
              _buildCalendarRaceCard(context, calendarRaces[index]),
        ),
      ],
    );
  }

  Widget _buildDesktopCalendarStatusCell(
    BuildContext context,
    Race race,
    bool isFinished,
    bool isOngoing,
    String timeLabel,
  ) {

    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final isCancelled = isCancelledGrandPrix(race);
    // statusChip variable removed (no longer used)

    final hasResults = _hasResultsForRace(race);
    final isToday = DateTime.now().year == race.date.year && DateTime.now().month == race.date.month && DateTime.now().day == race.date.day;
    Widget chip(String label, Color color, Color border, Color textColor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor),
        ),
      );
    }
    if (isFinished && hasResults) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              chip(context.l10n.calendar_race_status_ended, tokens.statusSuccess.withValues(alpha: 0.10), tokens.statusSuccess.withValues(alpha: 0.24), tokens.statusSuccess),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.push(_weekendHubPath(race)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: tokens.statusSuccess.withValues(alpha: 0.24)),
                ),
                child: Text(
                  context.l10n.results,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tokens.statusSuccess),
                ),
              ),
            ],
          ),
          if (race.date.year != 2026) ...[
            const SizedBox(height: 6),
            Text(
              _getPodiumString(race),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
              ),
            ),
          ],
        ],
      );
    } else if (!isCancelled && (isOngoing || (isToday && !hasResults))) {
      return chip(context.l10n.calendar_race_status_ongoing, tokens.statusWarning.withValues(alpha: 0.10), tokens.statusWarning.withValues(alpha: 0.24), tokens.statusWarning);
    } else if (!isCancelled && !isFinished) {
      return chip('${context.l10n.starts_in} $timeLabel', theme.colorScheme.primary.withValues(alpha: 0.10), theme.colorScheme.primary.withValues(alpha: 0.18), theme.colorScheme.primary);
    } else if (isCancelled) {
      return chip(context.l10n.calendar_race_status_cancelled, tokens.statusError.withValues(alpha: 0.08), tokens.statusError.withValues(alpha: 0.24), tokens.statusError);
    } else if (isFinished && !hasResults) {
      return chip(context.l10n.calendar_race_status_ended, tokens.statusSuccess.withValues(alpha: 0.10), tokens.statusSuccess.withValues(alpha: 0.24), tokens.statusSuccess);
    } else {
      return chip(context.l10n.unknown, theme.colorScheme.outline.withValues(alpha: 0.10), theme.colorScheme.outline.withValues(alpha: 0.24), theme.colorScheme.outline);
    }
  }

  Widget _buildNextRaceContent(
    BuildContext context,
    Race upcoming,
    String timeStrNext, {
    required bool isCancelled,
    required bool isRainy,
    required bool isCloudy,
    bool onBlueBackground = false,
  }) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final primary = theme.colorScheme.primary;
    final textColor = onBlueBackground ? Colors.white : theme.colorScheme.onSurface;

    final windSegment =
        (liveWind == '--' || liveWind == '-') ? '—' : liveWind;
    final weatherLine =
        '$liveTemp°C · $liveRain% ${context.l10n.rain.toLowerCase()} · $windSegment';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCancelled) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: onBlueBackground
                      ? tokens.statusError.withValues(alpha: 0.35)
                      : tokens.statusError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: onBlueBackground
                        ? tokens.statusError
                        : tokens.statusError.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  context.l10n.calendar_race_status_cancelled,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: onBlueBackground ? Colors.white : tokens.statusError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          context.l10n.next_race.toUpperCase(),
          style: TextStyle(
            color: onBlueBackground ? Colors.white70 : primary,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: onBlueBackground
                ? Colors.white.withValues(alpha: 0.15)
                : primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AnimatedWeatherIcon(
                isRain: isRainy,
                isCloudy: isCloudy,
                color: onBlueBackground
                    ? Colors.white
                    : (isRainy ? primary : theme.colorScheme.tertiary),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  weatherLine,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlagHero(
              tag: _raceFlagHeroTag(upcoming, source: 'featured'),
              flag: upcoming.flag,
              fontSize: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upcoming.circuitDisplayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10nGrandPrix(context.l10n, upcoming.name),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPreviousWinnersBlock(
          context,
          upcoming,
          favoriteDriver: context.watch<ProfileFavoritesNotifier>().value.favoriteDriver,
          onLightBackground: onBlueBackground,
        ),
        Divider(
          height: 30,
          color: onBlueBackground ? Colors.white24 : tokens.outline.withValues(alpha: 0.75),
        ),
        if (isCancelledGrandPrix(upcoming))
          const SizedBox.shrink()
        else if (timeStrNext.isEmpty)
          _buildCircuitPodiumPreview(
            context,
            upcoming,
            alignment: CrossAxisAlignment.start,
            onLightBackground: onBlueBackground,
          )
        else
          Text(
            '${context.l10n.starts_in} $timeStrNext',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: onBlueBackground ? Colors.white : primary,
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedRaceCard(
    BuildContext context,
    Race upcoming,
    String timeStrNext,
  ) {
    final isCancelled = isCancelledGrandPrix(upcoming);
    final isRainy = liveRain > 30;
    final isCloudy = !isRainy && liveRain > 10;

    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push(_circuitJsonDetailPath(upcoming)),
      child: F1Module(
        fillWidth: true,
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        backgroundColor: scheme.surface,
        showFadingBorder: true,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        child: _buildNextRaceContent(
          context,
          upcoming,
          timeStrNext,
          isCancelled: isCancelled,
          isRainy: isRainy,
          isCloudy: isCloudy,
          onBlueBackground: false,
        ),
      ),
    );
  }

  Widget _buildCalendarRaceCard(BuildContext context, Race race) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final prefs = context.watch<DisplaySettingsController>().settings;
    final titleFs = HubListCardStyle.titleFontSize(prefs);
    final subFs = HubListCardStyle.subtitleFontSize(prefs);
    final flagCalendar = prefs.compact ? 22.0 : 26.0;
    final now = DateTime.now();
    final isFinished = race.date.isBefore(now);
    final isOngoing = !isFinished &&
        now.year == race.date.year &&
        now.month == race.date.month &&
        now.day == race.date.day &&
        (now.difference(race.date).inHours.abs() <= 4); // 4 hour window for 'Ongoing'
    final isCancelled = isCancelledGrandPrix(race);
    final tStr = _timeUntil(race.date, context);
    final showDesktopExtras =
        MediaQuery.of(context).size.width >= _desktopCircuitsBreakpoint;
    final isRowMuted = isCancelled || isFinished;
    final dim =
        theme.colorScheme.onSurface.withValues(alpha: isRowMuted ? 0.5 : 1.0);

    if (showDesktopExtras) {
      final lastWinnerData = _calendarWinnerYearAndName(race);
      return HubListRowShell(
        onTap: () => context.push(_circuitJsonDetailPath(race)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  _buildFlagHero(
                    tag: _raceFlagHeroTag(race, source: 'calendar'),
                    flag: race.flag,
                    fontSize: flagCalendar,
                  ),
                  SizedBox(width: prefs.compact ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          race.circuitDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isRowMuted
                              ? TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: titleFs,
                                  color: dim,
                                )
                              : HubVisualLanguage.f1Wide(
                                  context,
                                  fontSize: titleFs,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.2,
                                ),
                        ),
                        SizedBox(height: prefs.compact ? 2 : 4),
                        Text(
                          l10nGrandPrix(context.l10n, race.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HubVisualLanguage.titilliumSecondary(
                            context,
                            fontSize: subFs,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            opacity: isRowMuted ? 0.5 : 0.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                l10nCountry(context.l10n, race.country),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: subFs,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  opacity: isRowMuted ? 0.5 : 0.92,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _calendarDateLabel(race.date),
                style: HubVisualLanguage.titilliumSecondary(
                  context,
                  fontSize: subFs,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  opacity: isRowMuted ? 0.5 : 0.62,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildCalendarWinnerRichLine(
                context,
                data: lastWinnerData,
                referenceFontSize: subFs,
                muted: isRowMuted,
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildDesktopCalendarStatusCell(
                  context,
                  race,
                  isFinished,
                  isOngoing,
                  tStr,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final statusWidget = () {
      final hasResults = _hasResultsForRace(race);
      final isToday = DateTime.now().year == race.date.year &&
          DateTime.now().month == race.date.month &&
          DateTime.now().day == race.date.day;
      if (race.date.year == 2026) {
        if (isCancelled) {
          return Text(context.l10n.calendar_race_status_cancelled,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tokens.statusError,
                  fontFamily: 'TitilliumWeb'));
        } else if (isOngoing || (isToday && !hasResults)) {
          return Text(context.l10n.calendar_race_status_ongoing,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tokens.statusWarning,
                  fontFamily: 'TitilliumWeb'));
        } else if (isFinished && hasResults) {
          return _buildCircuitPodiumPreview(context, race);
        } else if (isFinished && !hasResults) {
          return Text(context.l10n.calendar_race_status_ended,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tokens.statusSuccess,
                  fontFamily: 'TitilliumWeb'));
        } else {
          return Text(tStr,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _hubReadableAccent(context),
                  fontFamily: 'TitilliumWeb'));
        }
      } else {
        if (isFinished && hasResults) {
          return _buildCircuitPodiumPreview(context, race);
        } else if (isCancelled) {
          return Text(context.l10n.calendar_race_status_cancelled,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tokens.statusError));
        } else if (isOngoing || (isToday && !hasResults)) {
          return Text(context.l10n.calendar_race_status_ongoing,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tokens.statusWarning));
        } else {
          return Text(tStr,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _hubReadableAccent(context)));
        }
      }
    }();

    final lastWinnerData = _calendarWinnerYearAndName(race);
    final narrowCalendarCard =
        MediaQuery.sizeOf(context).width < HubMobileTuning.narrowLayoutWidth;

    TextStyle captionLabel(Color c) => TextStyle(
          fontSize: 10,
          letterSpacing: 1.05,
          fontWeight: FontWeight.w800,
          color: c,
        );

    if (narrowCalendarCard) {
      final capC = theme.colorScheme.onSurfaceVariant;
      return HubListRowShell(
        onTap: () => context.push(_circuitJsonDetailPath(race)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFlagHero(
                tag: _raceFlagHeroTag(race, source: 'calendar'),
                flag: race.flag,
                fontSize: flagCalendar,
              ),
              SizedBox(width: prefs.compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.date.toUpperCase(),
                      style: captionLabel(capC),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calendarDateLabel(race.date),
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: subFs + 1,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        opacity: isRowMuted ? 0.5 : 0.92,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.race.toUpperCase(),
                      style: captionLabel(capC),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10nGrandPrix(context.l10n, race.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: isRowMuted
                          ? TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: titleFs,
                              color: dim,
                            )
                          : HubVisualLanguage.f1Wide(
                              context,
                              fontSize: titleFs,
                              color: theme.colorScheme.onSurface,
                              height: 1.2,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _raceCalendarLocationLine(context, race),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: subFs,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        opacity: isRowMuted ? 0.5 : 0.65,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.country.toUpperCase(),
                      style: captionLabel(capC),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10nCountry(context.l10n, race.country),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: subFs,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        opacity: isRowMuted ? 0.5 : 0.88,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.last_winner.toUpperCase(),
                      style: captionLabel(capC),
                    ),
                    const SizedBox(height: 6),
                    _buildCalendarWinnerRichLine(
                      context,
                      data: lastWinnerData,
                      referenceFontSize: subFs,
                      muted: isRowMuted,
                    ),
                    const SizedBox(height: 12),
                    statusWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HubListRowShell(
      onTap: () => context.push(_circuitJsonDetailPath(race)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFlagHero(
            tag: _raceFlagHeroTag(race, source: 'calendar'),
            flag: race.flag,
            fontSize: flagCalendar,
          ),
          SizedBox(width: prefs.compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10nGrandPrix(context.l10n, race.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isRowMuted
                      ? TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: titleFs,
                          color: dim,
                        )
                      : HubVisualLanguage.f1Wide(
                          context,
                          fontSize: titleFs,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                ),
                SizedBox(height: prefs.compact ? 1 : 2),
                Text(
                  _raceCalendarLocationLine(context, race),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: subFs,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    opacity: isRowMuted ? 0.5 : 0.62,
                  ),
                ),
                if (!prefs.compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    _calendarDateLabel(race.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubVisualLanguage.titilliumSecondary(
                      context,
                      fontSize: subFs - 2,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                      opacity: isRowMuted ? 0.5 : 0.85,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: statusWidget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _calendarRaceDatePassed(Race race) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final rd = DateTime(race.date.year, race.date.month, race.date.day);
    return rd.isBefore(today);
  }

  Race? _nextUpcomingCalendarRace(BuildContext context) {
    final all = _calendarRacesList(context);
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    for (final r in all) {
      if (isCancelledGrandPrix(r)) {
        continue;
      }
      final rd = DateTime(r.date.year, r.date.month, r.date.day);
      if (!rd.isBefore(today)) {
        return r;
      }
    }
    return null;
  }

  int _calendarRoundNumber(BuildContext context, Race race) {
    final all = _calendarRacesList(context);
    final i = all.indexWhere(
      (r) =>
          r.name == race.name &&
          r.date.year == race.date.year &&
          r.date.month == race.date.month &&
          r.date.day == race.date.day,
    );
    return i < 0 ? 0 : i + 1;
  }

  int _calendarCompletedCount(BuildContext context) {
    var n = 0;
    for (final r in _calendarRacesList(context)) {
      if (isCancelledGrandPrix(r)) {
        continue;
      }
      if (_calendarRaceDatePassed(r)) {
        n++;
      }
    }
    return n;
  }

  List<Race> _filteredCalendarRaces(BuildContext context) {
    final list = _calendarRacesList(context);
    final q = (_calendarSearchController?.text ?? '').trim().toLowerCase();
    if (q.isEmpty) {
      return list;
    }
    return list.where((r) {
      final gp = l10nGrandPrix(context.l10n, r.name).toLowerCase();
      final blob =
          '${r.name} ${r.circuitDisplayName} ${r.country} $gp'.toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  List<Race> _filteredCircuitsCatalogRaces(
    BuildContext context,
    List<Race> source,
  ) {
    final raw = (_circuitsSearchController?.text ?? '').trim();
    if (raw.isEmpty) {
      return List<Race>.from(source);
    }
    final q = normalizeForComparison(raw);
    if (q.isEmpty) {
      return List<Race>.from(source);
    }
    final l10n = context.l10n;
    return source.where((r) {
      final gp = normalizeForComparison(l10nGrandPrix(l10n, r.name));
      final countryEn = normalizeForComparison(r.country);
      final countryLoc = normalizeForComparison(l10nCountry(l10n, r.country));
      final city = _kRaceCalendarHostCities[r.name.trim()];
      final cityN = city != null ? normalizeForComparison(city) : '';
      final blob = [
        normalizeForComparison(r.name),
        normalizeForComparison(r.circuitDisplayName),
        countryEn,
        countryLoc,
        gp,
        normalizeForComparison(r.circuitAssetId),
        cityN,
      ].where((s) => s.isNotEmpty).join(' ');
      return blob.contains(q);
    }).toList();
  }

  Widget _buildCircuitsCatalogSearchBar(BuildContext context) {
    final c = _circuitsSearchController!;
    return HubSearchBar(
      controller: c,
      hintText: context.l10n.hub_search_circuits_hint,
    );
  }

  /// Host city for "City, Country" on calendar cards (keys = English `Race.name`).
  static const Map<String, String> _kRaceCalendarHostCities = {
    'Australian Grand Prix': 'Melbourne',
    'Chinese Grand Prix': 'Shanghai',
    'Japanese Grand Prix': 'Suzuka',
    'Bahrain Grand Prix': 'Sakhir',
    'Saudi Arabian Grand Prix': 'Jeddah',
    'Miami Grand Prix': 'Miami',
    'Emilia Romagna Grand Prix': 'Imola',
    'Monaco Grand Prix': 'Monte Carlo',
    'Spanish Grand Prix': 'Barcelona',
    'Barcelona Grand Prix': 'Barcelona',
    'Canadian Grand Prix': 'Montreal',
    'Austrian Grand Prix': 'Spielberg',
    'British Grand Prix': 'Silverstone',
    'Belgian Grand Prix': 'Spa',
    'Hungarian Grand Prix': 'Budapest',
    'Dutch Grand Prix': 'Zandvoort',
    'Italian Grand Prix': 'Monza',
    'Azerbaijan Grand Prix': 'Baku',
    'Singapore Grand Prix': 'Singapore',
    'United States Grand Prix': 'Austin',
    'Mexico City Grand Prix': 'Mexico City',
    'São Paulo Grand Prix': 'São Paulo',
    'Las Vegas Grand Prix': 'Las Vegas',
    'Qatar Grand Prix': 'Lusail',
    'Abu Dhabi Grand Prix': 'Abu Dhabi',
  };

  String _raceCalendarLocationLine(BuildContext context, Race race) {
    final city = _kRaceCalendarHostCities[race.name.trim()];
    final country = l10nCountry(context.l10n, race.country);
    if (city != null && city.isNotEmpty) {
      return '$city, $country';
    }
    return country;
  }

  static final RegExp _kPreviousWinnerYearName =
      RegExp(r'^(\d{4}):\s*(.+)$');

  ({int year, String name})? _parsePreviousWinnerEntry(String raw) {
    final m = _kPreviousWinnerYearName.firstMatch(raw.trim());
    if (m == null) return null;
    final y = int.tryParse(m.group(1)!);
    final name = m.group(2)!.trim();
    if (y == null || name.isEmpty) return null;
    return (year: y, name: name);
  }

  ({int year, String name})? _jsonWinnerForYear(Race race, int year) {
    for (final raw in race.previousWinners) {
      final p = _parsePreviousWinnerEntry(raw);
      if (p != null && p.year == year) return p;
    }
    return null;
  }

  /// Strongest `previousWinners` row with year strictly before [beforeYear].
  ({int year, String name})? _latestJsonWinnerBeforeYear(
    Race race,
    int beforeYear,
  ) {
    var bestY = -1;
    ({int year, String name})? best;
    for (final raw in race.previousWinners) {
      final p = _parsePreviousWinnerEntry(raw);
      if (p == null || p.year >= beforeYear) continue;
      if (p.year > bestY) {
        bestY = p.year;
        best = p;
      }
    }
    return best;
  }

  /// P1 driver string from bundled/cache race results (e.g. broadcast name).
  String? _raceWinnerDriverRaw(Race race) {
    final rows = SessionDataManager()
            .raceResultsCache[SessionDataManager().raceResultsKeyFor(race)] ??
        const <RaceResultRow>[];
    for (final row in rows) {
      if (_extractFinishPosition(row.finish) == 1) {
        final d = row.driver.trim();
        if (d.isNotEmpty && d != '-') return d;
      }
    }
    return null;
  }

  String _calendarResolveWinnerDisplayName(String rawFromResults, int seasonYear) {
    final roster = driversData[seasonYear] ?? drivers2026;
    for (final d in roster) {
      if (_driverNameMatches(rawFromResults, d.name)) {
        return d.name;
      }
    }
    return rawFromResults;
  }

  /// Calendar winner: year + display name for UI (`Naam (jaar)`).
  ({int year, String name})? _calendarWinnerYearAndName(Race race) {
    final passed = _calendarRaceDatePassed(race);
    final cancelled = isCancelledGrandPrix(race);
    final seasonY = race.date.year;

    if (!passed && !cancelled) {
      final pick = _jsonWinnerForYear(race, seasonY - 1) ??
          _latestJsonWinnerBeforeYear(race, seasonY);
      if (pick == null) return null;
      return (year: pick.year, name: pick.name);
    }

    if (cancelled) {
      final pick = _jsonWinnerForYear(race, seasonY - 1) ??
          _latestJsonWinnerBeforeYear(race, seasonY);
      if (pick == null) return null;
      return (year: pick.year, name: pick.name);
    }

    if (_hasResultsForRace(race)) {
      final raw = _raceWinnerDriverRaw(race);
      if (raw != null) {
        final display = _calendarResolveWinnerDisplayName(raw, seasonY);
        return (year: seasonY, name: display);
      }
    }

    final fromJson = _jsonWinnerForYear(race, seasonY);
    if (fromJson != null) {
      return (year: fromJson.year, name: fromJson.name);
    }
    return null;
  }

  /// `Naam (jaar)` — coureur F1 Wide [referenceFontSize−1], jaartal Titillium kleiner.
  /// [muted]: voltooide/geannuleerde race → grijs; anders wit (dark hub) / onSurface (light).
  Widget _buildCalendarWinnerRichLine(
    BuildContext context, {
    required ({int year, String name})? data,
    required double referenceFontSize,
    required bool muted,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hubDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = muted
        ? scheme.onSurface.withValues(alpha: 0.5)
        : (hubDark ? ConstructorHubColors.textPrimary : scheme.onSurface);
    final yearColor = muted
        ? scheme.onSurface.withValues(alpha: 0.4)
        : nameColor.withValues(alpha: hubDark ? 0.72 : 0.62);

    final driverFs = (referenceFontSize - 1).clamp(9.0, 40.0);
    final yearFs = (driverFs - 2).clamp(7.0, 36.0);

    if (data == null) {
      return Text(
        '-',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HubVisualLanguage.f1Wide(
          context,
          fontSize: driverFs,
          color: nameColor,
          height: 1.2,
        ),
      );
    }

    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: [
          TextSpan(
            text: data.name,
            style: HubVisualLanguage.f1Wide(
              context,
              fontSize: driverFs,
              color: nameColor,
              height: 1.25,
            ),
          ),
          TextSpan(
            text: ' (${data.year})',
            style: GoogleFonts.titilliumWeb(
              fontSize: yearFs,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: yearColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceCalendarHubRow(
    BuildContext context,
    Race race, {
    required int roundNumber,
    required Race? nextRace,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final isCancelled = isCancelledGrandPrix(race);
    final passed = _calendarRaceDatePassed(race);
    final mutedPast = isCancelled || passed;
    final isNext = !isCancelled &&
        nextRace != null &&
        nextRace.name == race.name &&
        nextRace.date.year == race.date.year &&
        nextRace.date.month == race.date.month &&
        nextRace.date.day == race.date.day;
    final monthAbbrev = DateFormat('MMM', locale).format(race.date);
    final dayNum = '${race.date.day}';
    final winnerData = _calendarWinnerYearAndName(race);

    final pastDim = scheme.onSurface.withValues(alpha: 0.5);
    final titleColor = mutedPast ? pastDim : scheme.onSurface;
    final bodyMuted =
        mutedPast ? pastDim : scheme.onSurface.withValues(alpha: 0.62);
    final roundMuted =
        mutedPast ? pastDim : scheme.onSurface.withValues(alpha: 0.42);

    Widget? statusBadge;
    if (isCancelled || passed) {
      final label = isCancelled
          ? l10n.calendar_race_status_cancelled
          : l10n.race_calendar_status_completed;
      final pillBg = theme.brightness == Brightness.dark
          ? const Color(0xFF2C2C32)
          : scheme.surfaceContainerHighest;
      final pillFg = theme.brightness == Brightness.dark
          ? const Color(0xFFE8E8EC)
          : scheme.onSurface.withValues(alpha: 0.88);
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: pillFg,
          ),
        ),
      );
    } else if (isNext) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          l10n.race_calendar_status_next,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: scheme.primary,
          ),
        ),
      );
    }

    final cardBg = theme.brightness == Brightness.dark
        ? const Color(0xFF121212)
        : scheme.surfaceContainerHigh;
    final borderC = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : scheme.outline.withValues(alpha: 0.2);
    final dividerC = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : scheme.outline.withValues(alpha: 0.28);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(_circuitJsonDetailPath(race)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderC),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'R${roundNumber.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: roundMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        monthAbbrev,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          opacity: mutedPast ? 0.5 : 0.88,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayNum,
                        style: mutedPast
                            ? GoogleFonts.orbitron(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: 0.5,
                                color: pastDim,
                              )
                            : HubVisualLanguage.f1Wide(
                                context,
                                fontSize: 26,
                                color: scheme.onSurface,
                                height: 1,
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: dividerC,
                  ),
                ),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: statusBadge != null ? 86 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10nGrandPrix(context.l10n, race.name),
                              style: mutedPast
                                  ? TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                      color: titleColor,
                                    )
                                  : HubVisualLanguage.f1Wide(
                                      context,
                                      fontSize: 16,
                                      color: scheme.onSurface,
                                      height: 1.25,
                                    ),
                            ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: mutedPast ? pastDim : bodyMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _raceCalendarLocationLine(context, race),
                              style: HubVisualLanguage.titilliumSecondary(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface,
                                opacity: mutedPast ? 0.5 : 0.62,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        race.circuitDisplayName,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          opacity: mutedPast ? 0.5 : 0.78,
                          height: 1.35,
                        ),
                      ),
                      if (winnerData != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 18,
                              color: const Color(0xFFE6C200),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCalendarWinnerRichLine(
                                context,
                                data: winnerData,
                                referenceFontSize: 13,
                                muted: mutedPast,
                              ),
                            ),
                          ],
                        ),
                      ],
                          ],
                        ),
                      ),
                      if (statusBadge != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: statusBadge,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaceCalendarScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final all = _calendarRacesList(context);
    final total = all.length;
    final completed = _calendarCompletedCount(context);
    final nextR = _nextUpcomingCalendarRace(context);
    final filtered = _filteredCalendarRaces(context);
    final searchEmpty = (_calendarSearchController?.text ?? '').trim().isEmpty;

    final hubDarkCal = theme.brightness == Brightness.dark;

    final header = LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        final title = Text(
          l10n.race_calendar_title,
          style: hubDarkCal
              ? HubVisualLanguage.f1Wide(
                  context,
                  fontSize: 26,
                  color: ConstructorHubColors.textPrimary,
                  height: 1.05,
                )
              : Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ) ??
                  TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
        );
        final searchField = hubDarkCal &&
                _calendarSearchController != null
            ? HubSearchBar(
                controller: _calendarSearchController!,
                hintText: l10n.calendar_search_hint,
              )
            : TextField(
                controller: _calendarSearchController,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.calendar_search_hint,
                  hintStyle: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.22),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.65),
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                ),
              );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              searchField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            SizedBox(
              width: 260,
              child: searchField,
            ),
          ],
        );
      },
    );

    final progressSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.race_calendar_season_progress,
              style: hubDarkCal
                  ? HubVisualLanguage.titilliumSecondary(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ConstructorHubColors.textPrimary,
                      opacity: 0.72,
                    )
                  : TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
            ),
            Text(
              l10n.race_calendar_progress_fraction(completed, total),
              style: hubDarkCal
                  ? HubVisualLanguage.titilliumSecondary(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ConstructorHubColors.textPrimary,
                      opacity: 0.55,
                    )
                  : TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            minHeight: 6,
            backgroundColor: hubDarkCal
                ? Colors.white.withValues(alpha: 0.08)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.85),
            color: hubDarkCal
                ? ConstructorHubColors.railLogoRed
                : scheme.primary,
          ),
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCircuits,
                  child: SafeArea(
                    top: true,
                    bottom: true,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                header,
                                const SizedBox(height: 14),
                                progressSection,
                                const SizedBox(height: 16),
                                Text(
                                  l10n.race_calendar_subtitle(total, completed),
                                  style: hubDarkCal
                                      ? HubVisualLanguage.titilliumSecondary(
                                          context,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: ConstructorHubColors.textPrimary,
                                          opacity: 0.58,
                                        )
                                      : TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.58),
                                        ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        if (filtered.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: const SliverToBoxAdapter(
                              child: SizedBox.shrink(),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) {
                                final gap = SizedBox(
                                  height: _calendarInterRowGap(context),
                                );
                                if (searchEmpty &&
                                    _hasSummerBreakAfter(filtered[index])) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      gap,
                                      _buildSummerBreakHubStrip(context),
                                      gap,
                                    ],
                                  );
                                }
                                return gap;
                              },
                              itemBuilder: (context, index) {
                                final race = filtered[index];
                                return _buildRaceCalendarHubRow(
                                  context,
                                  race,
                                  roundNumber:
                                      _calendarRoundNumber(context, race),
                                  nextRace: nextR,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedRaceBackground(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildSummerBreakHubStrip(BuildContext context) {
    final hubDark = Theme.of(context).brightness == Brightness.dark;
    final label = context.l10n.summer_break.toUpperCase();
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: hubDark
          ? HubVisualLanguage.f1Wide(
              context,
              fontSize: 12,
              color: ConstructorHubColors.textPrimary,
              height: 1.1,
            ).copyWith(letterSpacing: 1.35)
          : GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: HubTheme.f1DeepCharcoal,
            ),
    );
    return Center(
      child: DecoratedBox(
        decoration: _hubFlatHubCardDecoration(context, radius: 999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: text,
        ),
      ),
    );
  }


  List<RaceResultRow> _circuitPodiumRows(Race race) {
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

  Widget _buildCircuitPodiumPreview(
    BuildContext context,
    Race race, {
    CrossAxisAlignment alignment = CrossAxisAlignment.end,
    bool onLightBackground = false,
  }) {
    final theme = Theme.of(context);
    final podiumRows = _circuitPodiumRows(race);
    final textColor = onLightBackground ? Colors.white : theme.colorScheme.onSurface;
    final variantColor = onLightBackground ? Colors.white70 : theme.colorScheme.onSurfaceVariant;

    if (podiumRows.isEmpty) {
      return Text(
        _getPodiumString(race),
        textAlign: alignment == CrossAxisAlignment.end
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: variantColor,
        ),
      );
    }

    // Show all podium drivers with team colors, indicator strips, and medal drop-shadows
    final medals = ['🥇', '🥈', '🥉'];
    final raceYear = race.date.year;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment == CrossAxisAlignment.end
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: List.generate(
        podiumRows.length,
        (i) {
          final driverName = podiumRows[i].driver;
          final teamColor = _teamColorForPodiumDriver(driverName, raceYear);
          return Padding(
            padding: EdgeInsets.only(right: i < podiumRows.length - 1 ? 12 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medals[i],
                  style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 1.5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: onLightBackground
                        ? Colors.white.withValues(alpha: 0.2)
                        : teamColor.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: teamColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: 14,
                        decoration: BoxDecoration(
                          color: teamColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        driverName.split(' ').last,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _teamColorForPodiumDriver(String driverName, int year) {
    final driver = _driverForSeason(driverName, year);
    if (driver != null) {
      return F1TeamSchemes.getTeamColor(driver.team);
    }
    return _hubReadableAccent(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homeMode == CircuitsHomeMode.calendarPage) {
      return _buildRaceCalendarScaffold(context);
    }

    final upcoming = _nextRace();
    final timeStrNext = _timeUntil(upcoming.date, context);

    final legacyDash = widget.homeMode == CircuitsHomeMode.legacyDashboard;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: legacyDash ? Colors.black : Colors.transparent,
      appBar: legacyDash
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(_circuitsPath());
                  }
                },
              ),
            )
          : null,
      // Mobile: no AppBar — shell [F1HubAppHeader] already reserves status-bar
      // inset; a second bar duplicated “F1 Hub” / looked like a grey pill.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCircuits,
                  child: SafeArea(
                    top: true,
                    bottom: true,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                      separatorBuilder: (context, index) => SizedBox(
                        height: _calendarInterRowGap(context),
                      ),
                      itemCount: legacyDash ? 2 : 1,
                      itemBuilder: (context, index) {
                        if (!legacyDash) {
                          final allCircuits = _calendarRacesList(context);
                          final filteredCircuits =
                              _filteredCircuitsCatalogRaces(
                            context,
                            allCircuits,
                          );
                          final catalogYear = allCircuits.isNotEmpty
                              ? allCircuits.first.date.year
                              : DateTime.now().year;
                          final qCircuits =
                              (_circuitsSearchController?.text ?? '')
                                  .trim();
                          final circuitsSearchEmpty = filteredCircuits
                                  .isEmpty &&
                              qCircuits.isNotEmpty;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: CircuitsCatalogSection(
                                  races: filteredCircuits
                                      .map(
                                        (r) => CircuitCatalogRaceInput(
                                          flag: r.flag,
                                          circuitAssetId: r.circuitAssetId,
                                          circuitDisplayName:
                                              r.circuitDisplayName,
                                          grandPrixName: r.name,
                                          country: r.country,
                                          calendarYear: r.date.year,
                                          lengthMeters: r.length,
                                          laps: r.laps,
                                          topSpeedRaw: r.topSpeed,
                                          lapRecordTime: r.fastestLap.time,
                                          characteristicsEn:
                                              r.characteristicsEn,
                                          characteristicsNl:
                                              r.characteristicsNl,
                                        ),
                                      )
                                      .toList(growable: false),
                                  desktopBreakpoint:
                                      _circuitsCatalogTwoColumnBreakpoint,
                                  searchField: _circuitsSearchController != null
                                      ? _buildCircuitsCatalogSearchBar(context)
                                      : null,
                                  catalogSeasonYear: catalogYear,
                                  emptyFilterMessage: circuitsSearchEmpty
                                      ? context.l10n.hub_search_circuits_empty
                                      : null,
                                ),
                              ),
                            ],
                          );
                        }
                        switch (index) {
                          case 0:
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  final isDesktop =
                                      w >= _desktopCircuitsBreakpoint;
                                  final showPodiumSidebar =
                                      _latestCompletedRace() != null;
                                  final featured = _buildFeaturedRaceCard(
                                    context,
                                    upcoming,
                                    timeStrNext,
                                  );
                                  if (isDesktop) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              featured,
                                            ],
                                          ),
                                        ),
                                        if (showPodiumSidebar) ...[
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 320,
                                            child: _buildDesktopOverviewSidebar(
                                              context,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      featured,
                                      if (showPodiumSidebar) ...[
                                        const SizedBox(height: 16),
                                        _buildDesktopOverviewSidebar(context),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            );
                          case 1:
                            return Builder(
                              builder: (context) {
                                final user = Supabase
                                    .instance.client.auth.currentUser;
                                final prefs = context
                                    .watch<AiStrategistPrefsNotifier>()
                                    .value;
                                final effective = user != null
                                    ? prefs
                                    : AiStrategistPrefs.defaults;
                                if (user != null && effective.cardDisabled) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: _AIStrategistCard(
                                    race: upcoming,
                                    strategistPrefs: effective,
                                    onTap: () async {
                                      await hubShowModalBottomSheetWithBlurBarrier<
                                          void>(
                                        context: context,
                                        isScrollControlled: true,
                                        enableDrag: true,
                                        builder: (sheetCtx) => Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Material(
                                            color: Theme.of(sheetCtx)
                                                .colorScheme
                                                .surface,
                                            elevation: 12,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: const AIAssistantSheet(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// --- STANDINGS VIEW (TAB 1 ROOT) ----------------------------------------------

Driver? _findDriverInRosterByName(List<Driver> roster, String rawName) {
  final key = rawName.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final d in roster) {
    if (d.name.trim().toLowerCase() == key) return d;
  }
  return null;
}

/// Championship-ordered drivers from bundled `drivers_standings_*.json` (same merge as [StandingsView]).
Future<List<Driver>> _loadChampionshipDriversOrdered(
  BuildContext context,
  int year,
) async {
  try {
    String? raw;
    for (final path in F1AssetResolver.driversStandingsCandidatePaths(year)) {
      if (!await F1AssetResolver.bundleHasAsset(
            DefaultAssetBundle.of(context),
            path,
          )) {
        continue;
      }
      try {
        raw = await DefaultAssetBundle.of(context).loadString(path);
        break;
      } catch (_) {}
    }
    if (raw == null) throw Exception('No drivers standings asset');
    final jsonData = json.decode(raw);
    final doc = Map<String, dynamic>.from(jsonData as Map);
    final standings = doc['standings'] as List<dynamic>;
    final roundsRaw = doc['rounds'];
    final roundsPresent = roundsRaw is List<dynamic> && roundsRaw.isNotEmpty;
    final roundDerived = roundsPresent
        ? _seasonGpWinsPodiumsFromStandingsRounds(roundsRaw)
        : <String, ({int wins, int podiums})>{};
    final localDrivers = driversData[year] ?? [];
    final mergedDrivers = <Driver>[];
    for (final rawEntry in standings) {
      if (rawEntry is! Map) continue;
      final entry = Map<String, dynamic>.from(
        rawEntry.map((k, v) => MapEntry(k.toString(), v)),
      );
      final name = entry['driver']?.toString() ?? '';
      final points = entry['points'] is num
          ? (entry['points'] as num).toDouble()
          : double.tryParse(entry['points']?.toString() ?? '') ?? 0.0;
      final teamJson = entry['team']?.toString().trim() ?? '';
      final teamLabel = teamJson.isEmpty ? 'Independent' : teamJson;
      final local = _findDriverInRosterByName(localDrivers, name) ??
          Driver(
            name: name,
            flag: '',
            points: points,
            number: 0,
            nationality: '',
            team: teamLabel,
            pointsFinishPct: 0.0,
            seasonPointsFinishPct: 0.0,
            wins: 0,
            podiums2nd: 0,
            podiums3rd: 0,
            podiums: 0,
            poles: 0,
            fastestLaps: 0,
            totalPoints: 0.0,
            championships: 0,
            championshipYears: [],
            lapsRaced: 0,
            starts: 0,
            dnfs: 0,
            dsqs: 0,
            dnqs: 0,
            lapsLed: 0,
            frontRowStarts: 0,
            highestFinish: '',
            highestGrid: '',
            hatTricks: 0,
            overtakes: 0,
            age: 0,
            height: '',
            birthPlace: '',
            partner: '',
            children: '',
            pets: '',
            manager: '',
            realWorldFactsEn: [],
            realWorldFactsNl: [],
            pointsPerSeason: {},
            debutYear: 0,
            contractUntil: '',
            previousTeams: [],
            personalSponsors: [],
            reserveDriver: null,
          );
      mergedDrivers.add(
        _driverMergedFromStandingsRow(
          local: local,
          points: points,
          standingDriverName: name,
          entry: entry,
          roundDerived: roundDerived,
          roundsPresentInDoc: roundsPresent,
        ),
      );
    }
    mergedDrivers.sort((a, b) => b.points.compareTo(a.points));
    return mergedDrivers;
  } catch (_) {
    final list = List<Driver>.from(driversData[year] ?? []);
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }
}

bool _driverTeamMatchesConstructorTeam(Driver d, Team t) {
  return d.team.trim().toLowerCase() == t.name.trim().toLowerCase();
}

int? _championshipRankForDriver(List<Driver> ordered, Driver d) {
  final key = _normalizeDriverLookupName(d.name);
  for (var i = 0; i < ordered.length; i++) {
    if (_normalizeDriverLookupName(ordered[i].name) == key) {
      return i + 1;
    }
  }
  return null;
}

/// Row for [d] in championship-ordered list ([_loadChampionshipDriversOrdered]).
Driver? _championshipDriverRow(List<Driver> ordered, Driver d) {
  final key = _normalizeDriverLookupName(d.name);
  for (final x in ordered) {
    if (_normalizeDriverLookupName(x.name) == key) {
      return x;
    }
  }
  return null;
}

/// Championship-ordered teams from bundled `teams_standings_*.json` (same merge as
/// [StandingsView] constructors tab for 2026+).
Future<List<Team>> _loadChampionshipTeamsOrdered(
  BuildContext context,
  int year,
) async {
  try {
    String? raw;
    for (final path in F1AssetResolver.teamsStandingsCandidatePaths(year)) {
      if (!await F1AssetResolver.bundleHasAsset(
            DefaultAssetBundle.of(context),
            path,
          )) {
        continue;
      }
      try {
        raw = await DefaultAssetBundle.of(context).loadString(path);
        break;
      } catch (_) {}
    }
    if (raw == null) throw Exception('No teams standings asset');
    final jsonData = json.decode(raw);
    final doc = Map<String, dynamic>.from(jsonData as Map);
    final standings = doc['standings'] as List<dynamic>;
    final mergedTeams = <Team>[];
    for (final rawEntry in standings) {
      if (rawEntry is! Map) continue;
      final entry = Map<String, dynamic>.from(
        rawEntry.map((k, v) => MapEntry(k.toString(), v)),
      );
      final name = entry['team']?.toString() ?? '';
      if (name.isEmpty) continue;
      final pts = entry['points'];
      final points = pts is num
          ? pts.round()
          : int.tryParse(pts?.toString() ?? '') ?? 0;
      final local = fallbackTeams.firstWhere(
        (t) => t.name == name,
        orElse: () => fallbackTeams.firstWhere(
          (t) => t.name.toLowerCase() == name.toLowerCase(),
          orElse: () => Team(
            name: name,
            flag: '',
            points: points,
            engine: '',
            fastestPitstopTime: '',
            fastestPitstopYear: 0,
            fastestPitstopCircuit: '',
            ccWins: 0,
            dcWins: 0,
            podiums: 0,
            oneTwo: 0,
            hattricks: 0,
            doublePodiums: 0,
            totalPoints: 0.0,
            frontRow: 0,
            poles: 0,
            fastestLaps: 0,
            racesLed: 0,
            principalName: '',
            principalAge: 0,
            principalFlag: '',
            totalEntries: 0,
            technicalDirectorName: '',
            technicalDirectorAge: 0,
            engineSupplier:
                EngineSupplier(name: '', engineName: '', city: ''),
            sponsors: const [],
            ccYears: const [],
            dcList: const [],
            headquarters: '',
            previousNames: const [],
            drivers: const [],
            carImageUrl: '',
          ),
        ),
      );
      mergedTeams.add(Team.copy(local, points));
    }
    mergedTeams.sort((a, b) => b.points.compareTo(a.points));
    return mergedTeams;
  } catch (_) {
    final list = List<Team>.from(fallbackTeams);
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }
}

bool _teamStandingsNameMatch(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

int? _championshipRankForTeam(List<Team> ordered, Team t) {
  for (var i = 0; i < ordered.length; i++) {
    if (_teamStandingsNameMatch(ordered[i].name, t.name)) {
      return i + 1;
    }
  }
  return null;
}

Team? _championshipTeamRow(List<Team> ordered, Team t) {
  for (final x in ordered) {
    if (_teamStandingsNameMatch(x.name, t.name)) {
      return x;
    }
  }
  return null;
}

class StandingsView extends StatefulWidget {
  final Widget settingsMenu;
  final bool isDriverView;
  const StandingsView({
    required this.settingsMenu,
    required this.isDriverView,
    super.key,
  });
  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  bool _isLoading = false;
  List<Driver> _cachedDrivers = [];
  List<Team> _cachedTeams = [];
  /// Full championship order (for /teams constructor cards: P + driver lines).
  List<Driver> _championshipDriversOrdered = [];
  bool _usingFallback = false;
  int _selectedYear = DateTime.now().year;
  final List<int> _years = List.generate(
    10,
    (index) => DateTime.now().year - index,
  );

  final List<dynamic> _selectedForComparison = [];
  bool _isCompareMode = false;

  TextEditingController? _driverSearchController;
  String _driverSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.isDriverView) {
      _driverSearchController = TextEditingController();
      _driverSearchController!.addListener(() {
        setState(() => _driverSearchQuery = _driverSearchController!.text);
      });
    }
    _fetchStandings();
  }

  @override
  void dispose() {
    _driverSearchController?.dispose();
    super.dispose();
  }

  Future<void> _fetchStandings({bool forceRefresh = false}) async {
    if (_selectedYear == 2026 && widget.isDriverView) {
      setState(() => _isLoading = true);
      try {
        String? raw;
        for (final path
            in F1AssetResolver.driversStandingsCandidatePaths(2026)) {
          if (!await F1AssetResolver.bundleHasAsset(
                DefaultAssetBundle.of(context),
                path,
              )) {
            continue;
          }
          try {
            raw = await DefaultAssetBundle.of(context).loadString(path);
            break;
          } catch (_) {}
        }
        if (raw == null) throw Exception('No drivers standings asset');
        final jsonData = json.decode(raw);
        final doc = Map<String, dynamic>.from(jsonData as Map);
        final standings = doc['standings'] as List<dynamic>;
        final roundsRaw = doc['rounds'];
        final roundsPresent =
            roundsRaw is List<dynamic> && roundsRaw.isNotEmpty;
        final roundDerived = roundsPresent
            ? _seasonGpWinsPodiumsFromStandingsRounds(roundsRaw)
            : <String, ({int wins, int podiums})>{};
        final localDrivers = driversData[2026] ?? [];
        List<Driver> mergedDrivers = [];
        for (final raw in standings) {
          if (raw is! Map) continue;
          final entry = Map<String, dynamic>.from(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          );
          final name = entry['driver']?.toString() ?? '';
          final points = entry['points'] is num
              ? (entry['points'] as num).toDouble()
              : double.tryParse(entry['points']?.toString() ?? '') ?? 0.0;
          final teamJson = entry['team']?.toString().trim() ?? '';
          final teamLabel = teamJson.isEmpty ? 'Independent' : teamJson;
          final local = _findDriverInRosterByName(localDrivers, name) ??
              Driver(
                name: name,
                flag: '',
                points: points,
                number: 0,
                nationality: '',
                team: teamLabel,
                pointsFinishPct: 0.0,
                seasonPointsFinishPct: 0.0,
                wins: 0,
                podiums2nd: 0,
                podiums3rd: 0,
                podiums: 0,
                poles: 0,
                fastestLaps: 0,
                totalPoints: 0.0,
                championships: 0,
                championshipYears: [],
                lapsRaced: 0,
                starts: 0,
                dnfs: 0,
                dsqs: 0,
                dnqs: 0,
                lapsLed: 0,
                frontRowStarts: 0,
                highestFinish: '',
                highestGrid: '',
                hatTricks: 0,
                overtakes: 0,
                age: 0,
                height: '',
                birthPlace: '',
                partner: '',
                children: '',
                pets: '',
                manager: '',
                realWorldFactsEn: [],
                realWorldFactsNl: [],
                pointsPerSeason: {},
                debutYear: 0,
                contractUntil: '',
                previousTeams: [],
                personalSponsors: [],
                reserveDriver: null,
              );
          mergedDrivers.add(
            _driverMergedFromStandingsRow(
              local: local,
              points: points,
              standingDriverName: name,
              entry: entry,
              roundDerived: roundDerived,
              roundsPresentInDoc: roundsPresent,
            ),
          );
        }
        mergedDrivers.sort((a, b) => b.points.compareTo(a.points));
        if (mounted) {
          setState(() {
            _cachedDrivers = mergedDrivers;
            _cachedTeams = List.from(fallbackTeams);
            _usingFallback = false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _cachedDrivers = List.from(driversData[2026] ?? []);
            _cachedTeams = List.from(fallbackTeams);
            _usingFallback = true;
            _isLoading = false;
          });
        }
      }
      return;
    }

    if (_selectedYear == 2026 && !widget.isDriverView) {
      setState(() => _isLoading = true);
      try {
        String? raw;
        for (final path in F1AssetResolver.teamsStandingsCandidatePaths(2026)) {
          if (!await F1AssetResolver.bundleHasAsset(
                DefaultAssetBundle.of(context),
                path,
              )) {
            continue;
          }
          try {
            raw = await DefaultAssetBundle.of(context).loadString(path);
            break;
          } catch (_) {}
        }
        if (raw == null) throw Exception('No teams standings asset');
        final jsonData = json.decode(raw);
        final standings = jsonData['standings'] as List<dynamic>;
        List<Team> mergedTeams = [];
        for (final entry in standings) {
          final name = entry['team'] as String;
          final points = (entry['points'] as num).toInt();
          final local = fallbackTeams.firstWhere(
            (t) => t.name == name,
            orElse: () => fallbackTeams.firstWhere(
              (t) => t.name.toLowerCase() == name.toLowerCase(),
              orElse: () => Team(
                name: name,
                flag: '',
                points: points,
                engine: '',
                fastestPitstopTime: '',
                fastestPitstopYear: 0,
                fastestPitstopCircuit: '',
                ccWins: 0,
                dcWins: 0,
                podiums: 0,
                oneTwo: 0,
                hattricks: 0,
                doublePodiums: 0,
                totalPoints: 0.0,
                frontRow: 0,
                poles: 0,
                fastestLaps: 0,
                racesLed: 0,
                principalName: '',
                principalAge: 0,
                principalFlag: '',
                totalEntries: 0,
                technicalDirectorName: '',
                technicalDirectorAge: 0,
                engineSupplier: EngineSupplier(name: '', engineName: '', city: ''),
                sponsors: const [],
                ccYears: const [],
                dcList: const [],
                headquarters: '',
                previousNames: const [],
                drivers: const [],
                carImageUrl: '',
              ),
            ),
          );
          mergedTeams.add(Team.copy(local, points));
        }
        mergedTeams.sort((a, b) => b.points.compareTo(a.points));
        final chDrivers =
            await _loadChampionshipDriversOrdered(context, _selectedYear);
        if (!mounted) return;
        setState(() {
          _cachedTeams = mergedTeams;
          _championshipDriversOrdered = chDrivers;
          _usingFallback = false;
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          final fb = List<Driver>.from(driversData[_selectedYear] ?? []);
          fb.sort((a, b) => b.points.compareTo(a.points));
          setState(() {
            _cachedTeams = List.from(fallbackTeams);
            _championshipDriversOrdered = fb;
            _usingFallback = true;
            _isLoading = false;
          });
        }
      }
      return;
    }

    setState(() => _isLoading = true);
    if (mounted) {
      setState(() {
        if (widget.isDriverView) {
          _cachedDrivers = List<Driver>.from(
            driversData[_selectedYear] ?? const <Driver>[],
          );
          _usingFallback = _cachedDrivers.isEmpty;
          _championshipDriversOrdered = [];
        } else {
          _cachedTeams = List<Team>.from(fallbackTeams);
          _usingFallback = false;
          final fb = List<Driver>.from(driversData[_selectedYear] ?? []);
          fb.sort((a, b) => b.points.compareTo(a.points));
          _championshipDriversOrdered = fb;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStandings() => _fetchStandings(forceRefresh: true);

  void _handleChartYearChanged(int year) {
    if (_selectedYear == year) {
      return;
    }

    setState(() {
      _selectedYear = year;
      _cachedDrivers = [];
      _cachedTeams = [];
    });
    _fetchStandings();
  }


  String _formatPoints(num points) {
    if (points is double && points == points.roundToDouble()) {
      return points.toInt().toString();
    }
    return points.toString();
  }

  List<dynamic> _standingsItems(bool isDriver) {
    if (isDriver) {
      return _cachedDrivers.isEmpty
          ? List<dynamic>.from(driversData[_selectedYear] ?? const <Driver>[])
          : List<dynamic>.from(_cachedDrivers);
    }

    return _cachedTeams.isEmpty
        ? List<dynamic>.from(fallbackTeams)
        : List<dynamic>.from(_cachedTeams);
  }

  void _handleStandingsTap(dynamic item, bool isDriverView) {
    if (_isCompareMode) {
      setState(() {
        if (_selectedForComparison.contains(item)) {
          _selectedForComparison.remove(item);
        } else if (_selectedForComparison.length < 2) {
          _selectedForComparison.add(item);
        }
      });
      if (_selectedForComparison.length == 2) {
        context
            .push(
              isDriverView
                  ? _driverComparePath(
                      _selectedForComparison[0] as Driver,
                      _selectedForComparison[1] as Driver,
                    )
                  : _teamComparePath(
                      _selectedForComparison[0] as Team,
                      _selectedForComparison[1] as Team,
                    ),
            )
            .then((_) {
              setState(() {
                _isCompareMode = false;
                _selectedForComparison.clear();
              });
            });
      }
      return;
    }

    context.push(
      isDriverView ? _driverPath(item as Driver) : _teamPath(item as Team),
    );
  }

  Widget _buildDesktopStandingsHeader(
    BuildContext context,
    bool isDriver, {
    required F1UiTheme f1Ui,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final headerRadius = (f1Ui.cardBorderRadius * 0.65).clamp(10.0, 16.0);
    final labelSize = compact ? 10.0 : 11.0;

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        f1Ui.cardPadding.top * 0.5,
        16,
        f1Ui.cardPadding.bottom * 0.4,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: f1Ui.cardPadding.left,
        vertical: (f1Ui.cardPadding.top * 0.6).clamp(8.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: tokens.panelStrong,
        borderRadius: BorderRadius.circular(headerRadius),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              'POS',
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              isDriver ? 'DRIVER' : 'TEAM',
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              isDriver ? 'TEAM / TITLES' : 'PRINCIPAL / TITLES',
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              'POINTS',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 30),
        ],
      ),
    );
  }

  Widget _buildDesktopStandingsRow(
    BuildContext context, {
    required dynamic item,
    required int index,
    required bool isDriver,
    required bool compact,
    required DisplaySettings displayPrefs,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final driver = isDriver ? item as Driver : null;
    final team = isDriver ? null : item as Team;
    final name = isDriver ? driver!.name : team!.name;
    final points = isDriver ? driver!.points : team!.points;
    final teamName = isDriver ? driver!.team : team!.name;
    final heroTag = isDriver
        ? _driverFlagHeroTag(driver!, source: 'standings')
        : _teamFlagHeroTag(team!, source: 'standings');
    final isSelected = _isCompareMode && _selectedForComparison.contains(item);
    final secondaryLabel = isDriver
        ? driver!.team.toUpperCase()
        : team!.principalName.toUpperCase();
    final tertiaryLabel = isDriver
        ? driverStandingsTitlesLine(driver!)
        : 'CC ${team!.ccWins}  DC ${team.dcWins}';

    if (kDebugMode && isDriver) {
      debugPrint('Standings desktop: Processing: ${driver!.name}');
      debugPrint('Standings desktop: Found Team: ${driver.team}');
      final te = kDriverWorldTitlesEntryForName(driver.name);
      debugPrint(
        'Standings desktop: Titles map: ${te != null}; tertiary="$tertiaryLabel"',
      );
    }

    final titleFs = HubListCardStyle.titleFontSize(displayPrefs);
    final subFs = HubListCardStyle.subtitleFontSize(displayPrefs);
    final posSize = compact ? 15.0 : 17.0;
    final flagSize = displayPrefs.compact ? 18.0 : 20.0;
    final iconSize = displayPrefs.compact ? 16.0 : 18.0;
    final teamTint = F1TeamSchemes.getTeamColor(teamName);
    final brandPrimary = isDriver
        ? teamBrandPrimaryColor(driver!.team)
        : teamBrandPrimaryColor(team!.name);
    final effectiveTint = brandPrimary ?? teamTint;

    return HubListRowShell(
      onTap: () => _handleStandingsTap(item, widget.isDriverView),
      selectionTint: isSelected ? effectiveTint.withValues(alpha: 0.16) : null,
      selectionBorder: isSelected ? effectiveTint : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: posSize,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _buildStandingsLeadingGraphic(
                  context,
                  isDriver: isDriver,
                  driver: driver,
                  team: team,
                  heroTag: heroTag,
                  flagSize: flagSize,
                  textAlign: TextAlign.left,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: !isDriver
                          ? (brandPrimary ?? theme.colorScheme.onSurface)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  secondaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleFs,
                    fontWeight: FontWeight.w700,
                    color: effectiveTint,
                  ),
                ),
                if (!isDriver || tertiaryLabel.isNotEmpty) ...[
                  SizedBox(height: compact ? 2 : 3),
                  Tooltip(
                    message: tertiaryLabel,
                    waitDuration: const Duration(milliseconds: 400),
                    child: Text(
                      tertiaryLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subFs,
                        height: 1.25,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              _formatPoints(points),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: titleFs,
                color: effectiveTint,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: _isCompareMode
                ? Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: iconSize,
                    color: isSelected ? effectiveTint : theme.colorScheme.onSurfaceVariant,
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    size: iconSize,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStandingsRow(
    BuildContext context, {
    required dynamic item,
    required int index,
    required bool isDriver,
    required bool compact,
    required DisplaySettings displayPrefs,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = isDriver ? (item as Driver).name : (item as Team).name;
    final points = isDriver ? (item as Driver).points : (item as Team).points;
    final driver = isDriver ? item as Driver : null;
    final team = isDriver ? null : item as Team;
    final heroTag = isDriver
        ? _driverFlagHeroTag(item as Driver, source: 'standings')
        : _teamFlagHeroTag(item as Team, source: 'standings');
    final teamName = isDriver ? (item as Driver).team : (item as Team).name;
    final bool isSelected =
        _isCompareMode && _selectedForComparison.contains(item);
    final driverTitlesLine =
        isDriver ? driverStandingsTitlesLine(item as Driver) : '';
    final teamPrincipal = isDriver
        ? null
        : (item as Team).principalName.toUpperCase();
    final teamTint = F1TeamSchemes.getTeamColor(teamName);
    final brandPrimary = isDriver
        ? teamBrandPrimaryColor((item as Driver).team)
        : teamBrandPrimaryColor((item as Team).name);
    final effectiveTint = brandPrimary ?? teamTint;

    if (kDebugMode && isDriver) {
      final d = item as Driver;
      debugPrint('Standings mobile: Processing: ${d.name}');
      debugPrint('Standings mobile: Found Team: ${d.team}');
      final te = kDriverWorldTitlesEntryForName(d.name);
      debugPrint(
        'Standings mobile: Titles map: ${te != null}; line="${driverTitlesLine.isEmpty ? '(empty)' : driverTitlesLine}"',
      );
    }

    final titleFs = HubListCardStyle.titleFontSize(displayPrefs);
    final subFs = HubListCardStyle.subtitleFontSize(displayPrefs);
    final posSize = compact ? 15.0 : 17.0;
    final flagSize = displayPrefs.compact ? 18.0 : 20.0;
    final titlesFont = subFs - 1;

    return HubListRowShell(
      onTap: () => _handleStandingsTap(item, widget.isDriverView),
      selectionTint: isSelected ? effectiveTint.withValues(alpha: 0.16) : null,
      selectionBorder: isSelected ? effectiveTint : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: posSize,
              ),
            ),
          ),
          _buildStandingsLeadingGraphic(
            context,
            isDriver: isDriver,
            driver: driver,
            team: team,
            heroTag: heroTag,
            flagSize: flagSize,
            textAlign: TextAlign.left,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: titleFs,
                    letterSpacing: 0.6,
                    color: !isDriver
                        ? (brandPrimary ?? theme.colorScheme.onSurface)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (teamPrincipal != null) ...[
                  SizedBox(height: compact ? 1 : 2),
                  Text(
                    teamPrincipal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w700,
                      color: effectiveTint,
                    ),
                  ),
                ],
                if (isDriver && driverTitlesLine.isNotEmpty) ...[
                  SizedBox(height: compact ? 1 : 2),
                  Tooltip(
                    message: driverTitlesLine,
                    waitDuration: const Duration(milliseconds: 400),
                    child: Text(
                      driverTitlesLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titlesFont,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_formatPoints(points)} ${context.l10n.pts}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: subFs,
              color: effectiveTint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    bool isDriver, {
    required F1UiTheme f1Ui,
    required bool compact,
  }) {
    final listPadV = f1Ui.cardPadding.top.clamp(8.0, 14.0);

    if (!isDriver) {
      // Direct scrollable under [RefreshIndicator] — avoids LayoutBuilder width
      // quirks (web / shell) that can zero out or inflate nested ListView children.
      return _buildConstructorStandingsHubScrollable(
        this,
        context: context,
        compact: compact,
        listPadV: listPadV,
      );
    }

    return _buildDriverStandingsHubScrollable(
      this,
      context: context,
      compact: compact,
      listPadV: listPadV,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySettings = context.watch<DisplaySettingsController>();
    final f1Ui = Theme.of(context).extension<F1UiTheme>() ??
        F1UiTheme.fromSettings(displaySettings.settings);
    final compact = displaySettings.settings.compact;

    final isDriverView = widget.isDriverView;
    final desktopShell = _isDesktopShellLayout(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: desktopShell ? 0 : null,
        scrolledUnderElevation: desktopShell ? 0 : null,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        title: _isCompareMode
            ? Text(
                '${isDriverView ? context.l10n.select_drivers_to_compare : context.l10n.select_teams_to_compare} (${_selectedForComparison.length}/2)',
              )
            : DropdownButton<int>(
                value: _selectedYear,
                underline: Container(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                      _cachedDrivers = [];
                      _cachedTeams = [];
                    });
                    _fetchStandings();
                  }
                },
                items: _years.map<DropdownMenuItem<int>>((int year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
        actions: [
          if (isDriverView)
            IconButton(
              icon: const Icon(Icons.show_chart),
              tooltip: context.l10n.drivers_chart,
              onPressed: () => _openDriverStandingsChartSheet(
                context,
                initialYear: _selectedYear,
                availableYears: _years,
                onYearChanged: _handleChartYearChanged,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.show_chart),
              tooltip: context.l10n.teams_chart,
              onPressed: () => _openTeamStandingsChartSheet(
                context,
                initialYear: _selectedYear,
                availableYears: _years,
                onYearChanged: _handleChartYearChanged,
              ),
            ),
          IconButton(
            icon: Icon(_isCompareMode ? Icons.cancel : Icons.compare_arrows),
            tooltip: context.l10n.compare,
            onPressed: () => setState(() {
              _isCompareMode = !_isCompareMode;
              _selectedForComparison.clear();
            }),
          ),
          ..._desktopAwareSettingsActions(context, widget.settingsMenu),
        ],
      ),
      body: _isLoading
          ? RefreshIndicator(
              onRefresh: _refreshStandings,
              child: SizedBox.expand(
                child: _buildStandingsSkeleton(
                  context,
                  isDriver: widget.isDriverView,
                ),
              ),
            )
          : Column(
              children: [
                if (_usingFallback)
                  Container(
                    width: double.infinity,
                    color: Colors.orangeAccent.withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Text(
                      context.l10n.using_fallback_data,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshStandings,
                    // Fill viewport so the scrollable lays out; otherwise web/shell
                    // can give the indicator a zero-height child and paint nothing.
                    child: SizedBox.expand(
                      child: _buildList(
                        widget.isDriverView,
                        f1Ui: f1Ui,
                        compact: compact,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// --- DRIVER COMPARISON VIEW ----------------------------------------------
class ComparisonRow extends StatelessWidget {
  final String label;
  final dynamic value1;
  final dynamic value2;
  final bool isDark;
  final bool lowerIsBetter;

  const ComparisonRow({
    super.key,
    required this.label,
    required this.value1,
    required this.value2,
    required this.isDark,
    this.lowerIsBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    bool d1IsBetter = false;
    bool d2IsBetter = false;

    num? numVal1;
    num? numVal2;

    if (value1 is num) {
      numVal1 = value1;
    } else if (value1 is String) {
      numVal1 = double.tryParse(
        value1.split(' ').first.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
    }

    if (value2 is num) {
      numVal2 = value2;
    } else if (value2 is String) {
      numVal2 = double.tryParse(
        value2.split(' ').first.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
    }

    if (numVal1 != null && numVal2 != null) {
      if (lowerIsBetter) {
        d1IsBetter = numVal1 < numVal2;
        d2IsBetter = numVal2 < numVal1;
      } else {
        d1IsBetter = numVal1 > numVal2;
        d2IsBetter = numVal2 > numVal1;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCell(value1.toString(), d1IsBetter, isDark),
              _buildStatCell(value2.toString(), d2IsBetter, isDark),
            ],
          ),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCell(String text, bool isBetter, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: isBetter
          ? BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isBetter ? 20 : 16,
          fontWeight: isBetter ? FontWeight.bold : FontWeight.normal,
          color: isBetter
              ? Colors.green
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}

void _openDriverStandingsChartSheet(
  BuildContext context, {
  required int initialYear,
  required List<int> availableYears,
  ValueChanged<int>? onYearChanged,
}) {
  showHubFullscreenGlassDialog<void>(
    context: context,
    body: DriverStandingsChartSheet(
      initialYear: initialYear,
      availableYears: availableYears,
      onYearChanged: onYearChanged,
      useSafeArea: false,
    ),
  );
}

void _openTeamStandingsChartSheet(
  BuildContext context, {
  required int initialYear,
  required List<int> availableYears,
  ValueChanged<int>? onYearChanged,
}) {
  showHubFullscreenGlassDialog<void>(
    context: context,
    body: TeamStandingsChartSheet(
      initialYear: initialYear,
      availableYears: availableYears,
      onYearChanged: onYearChanged,
      useSafeArea: false,
    ),
  );
}

class DriverStandingsChartSheet extends StatefulWidget {
  final int initialYear;
  final List<int> availableYears;
  final ValueChanged<int>? onYearChanged;
  final bool useSafeArea;

  const DriverStandingsChartSheet({
    required this.initialYear,
    required this.availableYears,
    this.onYearChanged,
    this.useSafeArea = true,
    super.key,
  });

  @override
  State<DriverStandingsChartSheet> createState() =>
      _DriverStandingsChartSheetState();
}

class _DriverStandingsChartSheetState extends State<DriverStandingsChartSheet> {
  late int _selectedYear;
  final Map<int, Set<String>> _selectedDriverNamesByYear = <int, Set<String>>{};
  int? _hoveredRound;
  Offset? _hoverPosition;

  Set<String> _buildDefaultChartSelection(DriverStandingsChartData data) {
    return data.series.take(8).map((series) => series.driverName).toSet();
  }

  void _selectTopDrivers(DriverStandingsChartData data, int count) {
    setState(() {
      _selectedDriverNamesByYear[_selectedYear] = data.series
          .take(count)
          .map((series) => series.driverName)
          .toSet();
    });
  }

  void _setAllDriversVisible(DriverStandingsChartData data) {
    setState(() {
      _selectedDriverNamesByYear[_selectedYear] = data.series
          .map((series) => series.driverName)
          .toSet();
    });
  }

  void _clearAllDrivers() {
    setState(() {
      _selectedDriverNamesByYear[_selectedYear] = <String>{};
    });
  }

  List<int> _sortedChartRoundsForSeries(
    List<DriverStandingsChartSeries> series,
  ) {
    final rounds = <int>{
      for (final driverSeries in series)
        ...driverSeries.pointsByRace.map((entry) => entry.round),
    }.toList()..sort();
    return rounds;
  }

  String _roundShortLabel(DriverStandingsChartData data, int round) {
    for (final series in data.series) {
      for (final entry in series.pointsByRace) {
        if (entry.round == round) {
          return _abbreviateRaceLabel(entry.raceName);
        }
      }
    }
    return round.toString();
  }

  String _roundFullLabel(DriverStandingsChartData data, int round) {
    for (final series in data.series) {
      for (final entry in series.pointsByRace) {
        if (entry.round == round) {
          return entry.raceName;
        }
      }
    }
    return 'Round $round';
  }

  double? _pointsForRound(DriverStandingsChartSeries series, int round) {
    for (final entry in series.pointsByRace) {
      if (entry.round == round) {
        return entry.points;
      }
    }
    return null;
  }

  String _formatChartPoints(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  List<MapEntry<DriverStandingsChartSeries, double>> _rankedValuesForRound(
    List<DriverStandingsChartSeries> visibleSeries,
    int round,
  ) {
    final values =
        visibleSeries
            .map((series) => MapEntry(series, _pointsForRound(series, round)))
            .where((entry) => entry.value != null)
            .map((entry) => MapEntry(entry.key, entry.value!))
            .toList()
          ..sort((left, right) => right.value.compareTo(left.value));
    return values;
  }

  int? _resolveHoveredRound(List<int> rounds, double localX, double width) {
    if (rounds.isEmpty || width <= 0) {
      return null;
    }
    if (rounds.length == 1) {
      return rounds.first;
    }

    final clampedX = localX.clamp(0.0, width);
    final stepWidth = width / (rounds.length - 1);
    final index = (clampedX / stepWidth).round().clamp(0, rounds.length - 1);
    return rounds[index];
  }

  Widget _buildHoverTooltip(
    BuildContext context, {
    required DriverStandingsChartData data,
    required List<DriverStandingsChartSeries> visibleSeries,
    required int round,
  }) {
    final theme = Theme.of(context);
    final values = _rankedValuesForRound(visibleSeries, round);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _roundFullLabel(data, round),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...values
              .take(6)
              .toList()
              .asMap()
              .entries
              .map(
                (rankedEntry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '#${rankedEntry.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _hubReadableAccent(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: rankedEntry.value.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rankedEntry.value.key.driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatChartPoints(rankedEntry.value.value)} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
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

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetPad = widget.useSafeArea
        ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
        : EdgeInsets.zero;
    final sheetBody = Padding(
        padding: sheetPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.drivers_chart,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.championship_progression,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedYear,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedYear = value;
                      _hoveredRound = null;
                      _hoverPosition = null;
                    });
                    widget.onYearChanged?.call(value);
                  },
                  items: widget.availableYears
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<DriverStandingsChartData?>(
                future: _fetchDriverStandingsChartData(_selectedYear),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const HubGlassChartLoadingPlaceholder();
                  }

                  final data = snapshot.data;
                  if (snapshot.hasError ||
                      data == null ||
                      data.series.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.chart_no_data,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final selectedNames = _selectedDriverNamesByYear.putIfAbsent(
                    _selectedYear,
                    () => _buildDefaultChartSelection(data),
                  );
                  final visibleSeries = data.series
                      .where(
                        (series) => selectedNames.contains(series.driverName),
                      )
                      .toList(growable: false);
                  final rounds = _sortedChartRoundsForSeries(visibleSeries);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth <
                          HubMobileTuning.narrowLayoutWidth;
                      final axisMuted = HubTheme.primaryOnGlassText(context)
                          .withValues(alpha: 0.6);

                      void toggleDriver(String name) {
                        setState(() {
                          final selection =
                              _selectedDriverNamesByYear.putIfAbsent(
                            _selectedYear,
                            () => _buildDefaultChartSelection(data),
                          );
                          if (selection.contains(name)) {
                            selection.remove(name);
                          } else {
                            selection.add(name);
                          }
                        });
                      }

                      final toolBar = Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: Text(context.l10n.top_5),
                            onPressed: () => _selectTopDrivers(data, 5),
                          ),
                          ActionChip(
                            label: Text(context.l10n.top_10),
                            onPressed: () => _selectTopDrivers(data, 10),
                          ),
                          ActionChip(
                            label: Text(context.l10n.show_all),
                            onPressed: () => _setAllDriversVisible(data),
                          ),
                          ActionChip(
                            label: Text(context.l10n.hide_all),
                            onPressed: _clearAllDrivers,
                          ),
                        ],
                      );

                      final legendHorizontal = SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 8),
                          itemCount: data.series.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final series = data.series[index];
                            final isSelected = selectedNames
                                .contains(series.driverName);
                            return HubEntityChip(
                              label: series.driverName,
                              teamColor: series.color,
                              active: isSelected,
                              labelMaxWidth: 132,
                              onTap: () => toggleDriver(series.driverName),
                            );
                          },
                        ),
                      );

                      final legendColumn = ListView.separated(
                        itemCount: data.series.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final series = data.series[index];
                          final isSelected =
                              selectedNames.contains(series.driverName);
                          return HubEntityChip(
                            label: series.driverName,
                            teamColor: series.color,
                            active: isSelected,
                            onTap: () => toggleDriver(series.driverName),
                          );
                        },
                      );

                      Widget chartPane() {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final chartWidth = math.max(
                              0.0,
                              constraints.maxWidth - 24,
                            );
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                8,
                                16,
                                16,
                                16,
                              ),
                              child: SizedBox(
                                width: chartWidth,
                                child: MouseRegion(
                                  onExit: (_) => setState(() {
                                    _hoveredRound = null;
                                    _hoverPosition = null;
                                  }),
                                  onHover: (event) {
                                    final box = context.findRenderObject();
                                    if (box is! RenderBox) {
                                      return;
                                    }
                                    final local = box.globalToLocal(
                                      event.position,
                                    );
                                    setState(() {
                                      _hoverPosition = local;
                                      _hoveredRound = _resolveHoveredRound(
                                        rounds,
                                        local.dx,
                                        chartWidth,
                                      );
                                    });
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) {
                                      setState(() {
                                        _hoverPosition =
                                            details.localPosition;
                                        _hoveredRound = _resolveHoveredRound(
                                          rounds,
                                          details.localPosition.dx,
                                          chartWidth,
                                        );
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            Expanded(
                                              child: CustomPaint(
                                                painter:
                                                    _DriverStandingsChartPainter(
                                                  data: data,
                                                  series: visibleSeries,
                                                  rounds: rounds,
                                                  theme: theme,
                                                  isDark: isDark,
                                                  hoveredRound: _hoveredRound,
                                                ),
                                                child: const SizedBox.expand(),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 36,
                                              width: chartWidth,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  for (var i = 0;
                                                      i < rounds.length;
                                                      i++)
                                                    Positioned(
                                                      left:
                                                          _standingsChartRoundAxisX(
                                                                i,
                                                                chartWidth,
                                                                rounds.length,
                                                              ) -
                                                              28,
                                                      width: 56,
                                                      top: 0,
                                                      child: Transform.rotate(
                                                        angle: -0.8,
                                                        alignment: Alignment
                                                            .topCenter,
                                                        child: Text(
                                                          _roundShortLabel(
                                                            data,
                                                            rounds[i],
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .titilliumWeb(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: axisMuted,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_hoveredRound != null &&
                                            _hoverPosition != null)
                                          Positioned(
                                            left: (_hoverPosition!.dx + 12)
                                                .clamp(
                                              8.0,
                                              chartWidth - 228.0,
                                            ),
                                            top: 8,
                                            child: _buildHoverTooltip(
                                              context,
                                              data: data,
                                              visibleSeries: visibleSeries,
                                              round: _hoveredRound!,
                                            ),
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

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            toolBar,
                            const SizedBox(height: 12),
                            legendHorizontal,
                            const SizedBox(height: 8),
                            Expanded(child: chartPane()),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 200,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 12,
                                top: 4,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  toolBar,
                                  const SizedBox(height: 12),
                                  Expanded(child: legendColumn),
                                ],
                              ),
                            ),
                          ),
                          Expanded(child: chartPane()),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    return widget.useSafeArea ? SafeArea(child: sheetBody) : sheetBody;
  }
}

/// Horizontal position of round [index] on the chart, matching
/// [_DriverStandingsChartPainter] / [_TeamStandingsChartPainter] (12px insets).
double _standingsChartRoundAxisX(
  int index,
  double layoutWidth,
  int roundCount,
) {
  if (roundCount <= 0 || layoutWidth <= 0) {
    return 0;
  }
  const leftInset = 12.0;
  final internal = math.max(0.0, layoutWidth - leftInset * 2);
  final steps = math.max(1, roundCount - 1);
  return leftInset + (internal / steps) * index;
}

class _DriverStandingsChartPainter extends CustomPainter {
  final DriverStandingsChartData data;
  final List<DriverStandingsChartSeries> series;
  final List<int> rounds;
  final ThemeData theme;
  final bool isDark;
  final int? hoveredRound;

  const _DriverStandingsChartPainter({
    required this.data,
    required this.series,
    required this.rounds,
    required this.theme,
    required this.isDark,
    this.hoveredRound,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rounds.isEmpty || series.isEmpty) {
      return;
    }

    final gridAlpha = 0.05;
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: gridAlpha)
      ..strokeWidth = 1;
    final axisColor = (isDark ? Colors.white : HubTheme.f1DeepCharcoal)
        .withValues(alpha: 0.6);
    final axisLabelStyle = GoogleFonts.titilliumWeb(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: axisColor,
    );
    const leftInset = 12.0;
    const topInset = 20.0;
    const bottomInset = 16.0;
    final chartWidth = size.width - leftInset * 2;
    final chartHeight = size.height - topInset - bottomInset;
    final steps = math.max(1, rounds.length - 1);
    final maxPoints = math.max(1.0, data.maxPoints);
    final roundIndexMap = <int, int>{
      for (var index = 0; index < rounds.length; index++) rounds[index]: index,
    };

    for (var index = 0; index <= 4; index++) {
      final y = topInset + (chartHeight / 4) * index;
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(size.width - leftInset, y),
        gridPaint,
      );
      final value = ((maxPoints / 4) * (4 - index));
      final painter = TextPainter(
        text: TextSpan(
          text: value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toStringAsFixed(1),
          style: axisLabelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(leftInset, y - painter.height - 2));
    }

    if (hoveredRound != null) {
      final hoverIndex = roundIndexMap[hoveredRound!];
      if (hoverIndex != null) {
        final hoverX = leftInset + (chartWidth / steps) * hoverIndex;
        final hoverPaint = Paint()
          ..color = theme.colorScheme.primary.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(hoverX, topInset),
          Offset(hoverX, topInset + chartHeight),
          hoverPaint,
        );
      }
    }

    for (final driverSeries in series) {
      final sortedEntries = [...driverSeries.pointsByRace]
        ..sort((left, right) => left.round.compareTo(right.round));
      if (sortedEntries.isEmpty) {
        continue;
      }

      final path = Path();
      for (var index = 0; index < sortedEntries.length; index++) {
        final entry = sortedEntries[index];
        final roundIndex = roundIndexMap[entry.round];
        if (roundIndex == null) {
          continue;
        }
        final x = leftInset + (chartWidth / steps) * roundIndex;
        final y =
            topInset + chartHeight - ((entry.points / maxPoints) * chartHeight);
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final lineColor = driverSeries.color;
      if (!isDark) {
        final shadowPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.2)
          ..strokeWidth = 3.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5);
        canvas.drawPath(path, shadowPaint);
      }
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);

      final dotPaint = Paint()..color = driverSeries.color;
      for (final entry in sortedEntries) {
        final roundIndex = roundIndexMap[entry.round];
        if (roundIndex == null) {
          continue;
        }
        final x = leftInset + (chartWidth / steps) * roundIndex;
        final y =
            topInset + chartHeight - ((entry.points / maxPoints) * chartHeight);
        canvas.drawCircle(Offset(x, y), 2.1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DriverStandingsChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.series != series ||
        oldDelegate.theme != theme ||
        oldDelegate.isDark != isDark ||
        oldDelegate.hoveredRound != hoveredRound;
  }
}

class TeamStandingsChartSheet extends StatefulWidget {
  final int initialYear;
  final List<int> availableYears;
  final ValueChanged<int>? onYearChanged;
  final bool useSafeArea;

  const TeamStandingsChartSheet({
    required this.initialYear,
    required this.availableYears,
    this.onYearChanged,
    this.useSafeArea = true,
    super.key,
  });

  @override
  State<TeamStandingsChartSheet> createState() =>
      _TeamStandingsChartSheetState();
}

class _TeamStandingsChartSheetState extends State<TeamStandingsChartSheet> {
  late int _selectedYear;
  final Map<int, Set<String>> _selectedTeamNamesByYear = <int, Set<String>>{};
  int? _hoveredRound;
  Offset? _hoverPosition;

  Set<String> _buildDefaultChartSelection(TeamStandingsChartData data) {
    return data.series.take(8).map((series) => series.teamName).toSet();
  }

  void _selectTopTeams(TeamStandingsChartData data, int count) {
    setState(() {
      _selectedTeamNamesByYear[_selectedYear] = data.series
          .take(count)
          .map((series) => series.teamName)
          .toSet();
    });
  }

  void _setAllTeamsVisible(TeamStandingsChartData data) {
    setState(() {
      _selectedTeamNamesByYear[_selectedYear] = data.series
          .map((series) => series.teamName)
          .toSet();
    });
  }

  void _clearAllTeams() {
    setState(() {
      _selectedTeamNamesByYear[_selectedYear] = <String>{};
    });
  }

  List<int> _sortedChartRoundsForSeries(
    List<TeamStandingsChartSeries> series,
  ) {
    final rounds = <int>{
      for (final teamSeries in series)
        ...teamSeries.pointsByRace.map((entry) => entry.round),
    }.toList()..sort();
    return rounds;
  }

  String _roundShortLabel(TeamStandingsChartData data, int round) {
    for (final series in data.series) {
      for (final entry in series.pointsByRace) {
        if (entry.round == round) {
          return _abbreviateRaceLabel(entry.raceName);
        }
      }
    }
    return round.toString();
  }

  String _roundFullLabel(TeamStandingsChartData data, int round) {
    for (final series in data.series) {
      for (final entry in series.pointsByRace) {
        if (entry.round == round) {
          return entry.raceName;
        }
      }
    }
    return 'Round $round';
  }

  double? _pointsForRound(TeamStandingsChartSeries series, int round) {
    for (final entry in series.pointsByRace) {
      if (entry.round == round) {
        return entry.points;
      }
    }
    return null;
  }

  String _formatChartPoints(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  List<MapEntry<TeamStandingsChartSeries, double>> _rankedValuesForRound(
    List<TeamStandingsChartSeries> visibleSeries,
    int round,
  ) {
    final values =
        visibleSeries
            .map((series) => MapEntry(series, _pointsForRound(series, round)))
            .where((entry) => entry.value != null)
            .map((entry) => MapEntry(entry.key, entry.value!))
            .toList()
          ..sort((left, right) => right.value.compareTo(left.value));
    return values;
  }

  int? _resolveHoveredRound(List<int> rounds, double localX, double width) {
    if (rounds.isEmpty || width <= 0) {
      return null;
    }
    if (rounds.length == 1) {
      return rounds.first;
    }

    final clampedX = localX.clamp(0.0, width);
    final stepWidth = width / (rounds.length - 1);
    final index = (clampedX / stepWidth).round().clamp(0, rounds.length - 1);
    return rounds[index];
  }

  Widget _buildHoverTooltip(
    BuildContext context, {
    required TeamStandingsChartData data,
    required List<TeamStandingsChartSeries> visibleSeries,
    required int round,
  }) {
    final theme = Theme.of(context);
    final values = _rankedValuesForRound(visibleSeries, round);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _roundFullLabel(data, round),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...values
              .take(6)
              .toList()
              .asMap()
              .entries
              .map(
                (rankedEntry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '#${rankedEntry.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _hubReadableAccent(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: rankedEntry.value.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rankedEntry.value.key.teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatChartPoints(rankedEntry.value.value)} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
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

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final teamSheetPad = widget.useSafeArea
        ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
        : EdgeInsets.zero;
    final sheetBody = Padding(
        padding: teamSheetPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.teams_chart,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.championship_progression,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedYear,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedYear = value;
                      _hoveredRound = null;
                      _hoverPosition = null;
                    });
                    widget.onYearChanged?.call(value);
                  },
                  items: widget.availableYears
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<TeamStandingsChartData?>(
                future: _fetchTeamStandingsChartData(_selectedYear),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const HubGlassChartLoadingPlaceholder();
                  }

                  final data = snapshot.data;
                  if (snapshot.hasError ||
                      data == null ||
                      data.series.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.chart_no_data,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final selectedNames = _selectedTeamNamesByYear.putIfAbsent(
                    _selectedYear,
                    () => _buildDefaultChartSelection(data),
                  );
                  final visibleSeries = data.series
                      .where(
                        (series) => selectedNames.contains(series.teamName),
                      )
                      .toList(growable: false);
                  final rounds = _sortedChartRoundsForSeries(visibleSeries);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth <
                          HubMobileTuning.narrowLayoutWidth;
                      final axisMuted = HubTheme.primaryOnGlassText(context)
                          .withValues(alpha: 0.6);

                      void toggleTeam(String name) {
                        setState(() {
                          final selection =
                              _selectedTeamNamesByYear.putIfAbsent(
                            _selectedYear,
                            () => _buildDefaultChartSelection(data),
                          );
                          if (selection.contains(name)) {
                            selection.remove(name);
                          } else {
                            selection.add(name);
                          }
                        });
                      }

                      final toolBar = Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: Text(context.l10n.top_5),
                            onPressed: () => _selectTopTeams(data, 5),
                          ),
                          ActionChip(
                            label: Text(context.l10n.top_10),
                            onPressed: () => _selectTopTeams(data, 10),
                          ),
                          ActionChip(
                            label: Text(context.l10n.show_all),
                            onPressed: () => _setAllTeamsVisible(data),
                          ),
                          ActionChip(
                            label: Text(context.l10n.hide_all),
                            onPressed: _clearAllTeams,
                          ),
                        ],
                      );

                      final legendHorizontal = SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 8),
                          itemCount: data.series.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final series = data.series[index];
                            final isSelected =
                                selectedNames.contains(series.teamName);
                            return HubEntityChip(
                              label: series.teamName,
                              teamColor: series.color,
                              active: isSelected,
                              labelMaxWidth: 132,
                              onTap: () => toggleTeam(series.teamName),
                            );
                          },
                        ),
                      );

                      final legendColumn = ListView.separated(
                        itemCount: data.series.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final series = data.series[index];
                          final isSelected =
                              selectedNames.contains(series.teamName);
                          return HubEntityChip(
                            label: series.teamName,
                            teamColor: series.color,
                            active: isSelected,
                            onTap: () => toggleTeam(series.teamName),
                          );
                        },
                      );

                      Widget chartPane() {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final chartWidth = math.max(
                              0.0,
                              constraints.maxWidth - 24,
                            );
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                8,
                                16,
                                16,
                                16,
                              ),
                              child: SizedBox(
                                width: chartWidth,
                                child: MouseRegion(
                                  onExit: (_) => setState(() {
                                    _hoveredRound = null;
                                    _hoverPosition = null;
                                  }),
                                  onHover: (event) {
                                    final box = context.findRenderObject();
                                    if (box is! RenderBox) {
                                      return;
                                    }
                                    final local = box.globalToLocal(
                                      event.position,
                                    );
                                    setState(() {
                                      _hoverPosition = local;
                                      _hoveredRound = _resolveHoveredRound(
                                        rounds,
                                        local.dx,
                                        chartWidth,
                                      );
                                    });
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) {
                                      setState(() {
                                        _hoverPosition =
                                            details.localPosition;
                                        _hoveredRound = _resolveHoveredRound(
                                          rounds,
                                          details.localPosition.dx,
                                          chartWidth,
                                        );
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            Expanded(
                                              child: CustomPaint(
                                                painter:
                                                    _TeamStandingsChartPainter(
                                                  data: data,
                                                  series: visibleSeries,
                                                  rounds: rounds,
                                                  theme: theme,
                                                  isDark: isDark,
                                                  hoveredRound: _hoveredRound,
                                                ),
                                                child: const SizedBox.expand(),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 36,
                                              width: chartWidth,
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  for (var i = 0;
                                                      i < rounds.length;
                                                      i++)
                                                    Positioned(
                                                      left:
                                                          _standingsChartRoundAxisX(
                                                                i,
                                                                chartWidth,
                                                                rounds.length,
                                                              ) -
                                                              28,
                                                      width: 56,
                                                      top: 0,
                                                      child: Transform.rotate(
                                                        angle: -0.8,
                                                        alignment: Alignment
                                                            .topCenter,
                                                        child: Text(
                                                          _roundShortLabel(
                                                            data,
                                                            rounds[i],
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .titilliumWeb(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: axisMuted,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_hoveredRound != null &&
                                            _hoverPosition != null)
                                          Positioned(
                                            left: (_hoverPosition!.dx + 12)
                                                .clamp(
                                              8.0,
                                              chartWidth - 228.0,
                                            ),
                                            top: 8,
                                            child: _buildHoverTooltip(
                                              context,
                                              data: data,
                                              visibleSeries: visibleSeries,
                                              round: _hoveredRound!,
                                            ),
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

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            toolBar,
                            const SizedBox(height: 12),
                            legendHorizontal,
                            const SizedBox(height: 8),
                            Expanded(child: chartPane()),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 200,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 12,
                                top: 4,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  toolBar,
                                  const SizedBox(height: 12),
                                  Expanded(child: legendColumn),
                                ],
                              ),
                            ),
                          ),
                          Expanded(child: chartPane()),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    return widget.useSafeArea ? SafeArea(child: sheetBody) : sheetBody;
  }
}

class _TeamStandingsChartPainter extends CustomPainter {
  final TeamStandingsChartData data;
  final List<TeamStandingsChartSeries> series;
  final List<int> rounds;
  final ThemeData theme;
  final bool isDark;
  final int? hoveredRound;

  const _TeamStandingsChartPainter({
    required this.data,
    required this.series,
    required this.rounds,
    required this.theme,
    required this.isDark,
    this.hoveredRound,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rounds.isEmpty || series.isEmpty) {
      return;
    }

    final gridAlpha = 0.05;
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: gridAlpha)
      ..strokeWidth = 1;
    final axisColor = (isDark ? Colors.white : HubTheme.f1DeepCharcoal)
        .withValues(alpha: 0.6);
    final axisLabelStyle = GoogleFonts.titilliumWeb(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: axisColor,
    );
    const leftInset = 12.0;
    const topInset = 20.0;
    const bottomInset = 16.0;
    final chartWidth = size.width - leftInset * 2;
    final chartHeight = size.height - topInset - bottomInset;
    final steps = math.max(1, rounds.length - 1);
    final maxPoints = math.max(1.0, data.maxPoints);
    final roundIndexMap = <int, int>{
      for (var index = 0; index < rounds.length; index++) rounds[index]: index,
    };

    for (var index = 0; index <= 4; index++) {
      final y = topInset + (chartHeight / 4) * index;
      canvas.drawLine(
        Offset(leftInset, y),
        Offset(size.width - leftInset, y),
        gridPaint,
      );
      final value = ((maxPoints / 4) * (4 - index));
      final painter = TextPainter(
        text: TextSpan(
          text: value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toStringAsFixed(1),
          style: axisLabelStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(leftInset, y - painter.height - 2));
    }

    if (hoveredRound != null) {
      final hoverIndex = roundIndexMap[hoveredRound!];
      if (hoverIndex != null) {
        final hoverX = leftInset + (chartWidth / steps) * hoverIndex;
        final hoverPaint = Paint()
          ..color = theme.colorScheme.primary.withValues(alpha: 0.35)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(hoverX, topInset),
          Offset(hoverX, topInset + chartHeight),
          hoverPaint,
        );
      }
    }

    for (final teamSeries in series) {
      final sortedEntries = [...teamSeries.pointsByRace]
        ..sort((left, right) => left.round.compareTo(right.round));
      if (sortedEntries.isEmpty) {
        continue;
      }

      final path = Path();
      for (var index = 0; index < sortedEntries.length; index++) {
        final entry = sortedEntries[index];
        final roundIndex = roundIndexMap[entry.round];
        if (roundIndex == null) {
          continue;
        }
        final x = leftInset + (chartWidth / steps) * roundIndex;
        final y =
            topInset + chartHeight - ((entry.points / maxPoints) * chartHeight);
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final lineColor = teamSeries.color;
      if (!isDark) {
        final shadowPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.2)
          ..strokeWidth = 3.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5);
        canvas.drawPath(path, shadowPaint);
      }
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);

      final dotPaint = Paint()..color = teamSeries.color;
      for (final entry in sortedEntries) {
        final roundIndex = roundIndexMap[entry.round];
        if (roundIndex == null) {
          continue;
        }
        final x = leftInset + (chartWidth / steps) * roundIndex;
        final y =
            topInset + chartHeight - ((entry.points / maxPoints) * chartHeight);
        canvas.drawCircle(Offset(x, y), 2.1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TeamStandingsChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.series != series ||
        oldDelegate.theme != theme ||
        oldDelegate.isDark != isDark ||
        oldDelegate.hoveredRound != hoveredRound;
  }
}

class DriverComparisonView extends StatefulWidget {
  final Driver driver1;
  final Driver driver2;

  const DriverComparisonView({
    required this.driver1,
    required this.driver2,
    super.key,
  });

  @override
  State<DriverComparisonView> createState() => _DriverComparisonViewState();
}

class _DriverComparisonViewState extends State<DriverComparisonView> {
  bool _showOverall = true;
  late final List<int> _availableYears;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _availableYears = _sharedDriverComparisonYears(
      widget.driver1.name,
      widget.driver2.name,
    );
    _selectedYear = _availableYears.isEmpty ? null : _availableYears.first;
  }

  Driver get _leftDriver {
    if (_showOverall || _selectedYear == null) {
      return widget.driver1;
    }
    return _driverForSeason(widget.driver1.name, _selectedYear!) ??
        widget.driver1;
  }

  Driver get _rightDriver {
    if (_showOverall || _selectedYear == null) {
      return widget.driver2;
    }
    return _driverForSeason(widget.driver2.name, _selectedYear!) ??
        widget.driver2;
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leftDriver = _leftDriver;
    final rightDriver = _rightDriver;
    final recentForm1 = _buildDriverRecentFormEntries(widget.driver1.name);
    final recentForm2 = _buildDriverRecentFormEntries(widget.driver2.name);
    final starts1 = leftDriver.starts == 0 ? 1 : leftDriver.starts;
    final starts2 = rightDriver.starts == 0 ? 1 : rightDriver.starts;

    final scheme = Theme.of(context).colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      0.04,
    )!;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final listTopPadding = desktopShell ? 20.0 : topInset + 20;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: !desktopShell,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: !desktopShell,
        title: Text(
          '${widget.driver1.name.split(' ').last} vs ${widget.driver2.name.split(' ').last}',
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, listTopPadding, 16, 16),
              children: [
                _buildHeader(context, leftDriver, rightDriver),
          const SizedBox(height: 20),
          _buildCompareScopeControls(context),
          const SizedBox(height: 20),
          if (_showOverall) ...[
            ComparisonRow(
              label: context.l10n.championships,
              value1: leftDriver.championships,
              value2: rightDriver.championships,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.wins,
              value1: leftDriver.wins,
              value2: rightDriver.wins,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.podiums,
              value1: leftDriver.podiums,
              value2: rightDriver.podiums,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.poles,
              value1: leftDriver.poles,
              value2: rightDriver.poles,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.fastest_laps,
              value1: leftDriver.fastestLaps,
              value2: rightDriver.fastestLaps,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.total_points,
              value1: leftDriver.totalPoints,
              value2: rightDriver.totalPoints,
              isDark: isDark,
            ),
          ],
          if (_showOverall) ...[
            ComparisonRow(
              label: context.l10n.starts,
              value1: leftDriver.starts,
              value2: rightDriver.starts,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.dnf,
              value1: leftDriver.dnfs,
              value2: rightDriver.dnfs,
              isDark: isDark,
              lowerIsBetter: true,
            ),
            ComparisonRow(
              label: context.l10n.laps_led,
              value1: leftDriver.lapsLed,
              value2: rightDriver.lapsLed,
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.highest_finish,
              value1: leftDriver.highestFinish,
              value2: rightDriver.highestFinish,
              isDark: isDark,
              lowerIsBetter: true,
            ),
            ComparisonRow(
              label: context.l10n.highest_grid,
              value1: leftDriver.highestGrid,
              value2: rightDriver.highestGrid,
              isDark: isDark,
              lowerIsBetter: true,
            ),
            ComparisonRow(
              label: context.l10n.points_per_start,
              value1: (leftDriver.totalPoints / starts1).toStringAsFixed(2),
              value2: (rightDriver.totalPoints / starts2).toStringAsFixed(2),
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.win_rate,
              value1: ((leftDriver.wins / starts1) * 100).toStringAsFixed(1),
              value2: ((rightDriver.wins / starts2) * 100).toStringAsFixed(1),
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.last_5_points,
              value1: _formatFormPoints(recentForm1),
              value2: _formatFormPoints(recentForm2),
              isDark: isDark,
            ),
            ComparisonRow(
              label: context.l10n.avg_finish_l5,
              value1: _formatDriverAverageFinish(recentForm1),
              value2: _formatDriverAverageFinish(recentForm2),
              isDark: isDark,
              lowerIsBetter: true,
            ),
          ] else if (_selectedYear != null)
            ..._buildSeasonComparisonRows(
              context,
              year: _selectedYear!,
              isDark: isDark,
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeasonComparisonRows(
    BuildContext context, {
    required int year,
    required bool isDark,
  }) {


    return <Widget>[
      FutureBuilder<List<SeasonalDriverComparisonStats?>>(
        future: Future.wait(<Future<SeasonalDriverComparisonStats?>>[
          _fetchSeasonalDriverComparisonStats(widget.driver1.name, year),
          _fetchSeasonalDriverComparisonStats(widget.driver2.name, year),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: HubGlassPageLoadingPlaceholder(fixedHeight: 140),
            );
          }

          final stats = snapshot.data;
          if (snapshot.hasError ||
              stats == null ||
              stats.length != 2 ||
              stats[0] == null ||
              stats[1] == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                context.l10n.compare_season_unavailable,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final leftStats = stats[0]!;
          final rightStats = stats[1]!;

          return Column(
            children: [
              ComparisonRow(
                label: context.l10n.points,
                value1: leftStats.points.toStringAsFixed(
                  leftStats.points == leftStats.points.roundToDouble() ? 0 : 1,
                ),
                value2: rightStats.points.toStringAsFixed(
                  rightStats.points == rightStats.points.roundToDouble()
                      ? 0
                      : 1,
                ),
                isDark: isDark,
              ),
              ComparisonRow(
                label: context.l10n.poles,
                value1: leftStats.poles,
                value2: rightStats.poles,
                isDark: isDark,
              ),
              ComparisonRow(
                label: context.l10n.fastest_laps,
                value1: leftStats.fastestLaps,
                value2: rightStats.fastestLaps,
                isDark: isDark,
              ),
              ComparisonRow(
                label: context.l10n.dnf_percentage,
                value1: leftStats.dnfPercentage.toStringAsFixed(1),
                value2: rightStats.dnfPercentage.toStringAsFixed(1),
                isDark: isDark,
                lowerIsBetter: true,
              ),
              ComparisonRow(
                label: context.l10n.podiums,
                value1: leftStats.podiums,
                value2: rightStats.podiums,
                isDark: isDark,
              ),
              ComparisonRow(
                label: context.l10n.highest_finish,
                value1: leftStats.highestFinish,
                value2: rightStats.highestFinish,
                isDark: isDark,
                lowerIsBetter: true,
              ),
              ComparisonRow(
                label: context.l10n.highest_grid,
                value1: leftStats.highestGrid,
                value2: rightStats.highestGrid,
                isDark: isDark,
                lowerIsBetter: true,
              ),
              ComparisonRow(
                label: context.l10n.win_rate,
                value1: leftStats.winRate.toStringAsFixed(1),
                value2: rightStats.winRate.toStringAsFixed(1),
                isDark: isDark,
              ),
              _buildSeasonPointsProgressionCard(
                context,
                leftStats: leftStats,
                rightStats: rightStats,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildSeasonPointsProgressionCard(
    BuildContext context, {
    required SeasonalDriverComparisonStats leftStats,
    required SeasonalDriverComparisonStats rightStats,
    required bool isDark,
  }) {
    final rounds = <int>{
      ...leftStats.pointsByRace.map((entry) => entry.round),
      ...rightStats.pointsByRace.map((entry) => entry.round),
    }.toList()..sort();

    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }


    final theme = Theme.of(context);
    final leftByRound = {
      for (final entry in leftStats.pointsByRace) entry.round: entry,
    };
    final rightByRound = {
      for (final entry in rightStats.pointsByRace) entry.round: entry,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              context.l10n.points_progression,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(context.l10n.points_after_each_race),
            children: rounds
                .map((round) {
                  final leftEntry = leftByRound[round];
                  final rightEntry = rightByRound[round];
                  final leftPoints = leftEntry?.points;
                  final rightPoints = rightEntry?.points;
                  final leftBetter =
                      leftPoints != null &&
                      rightPoints != null &&
                      leftPoints > rightPoints;
                  final rightBetter =
                      leftPoints != null &&
                      rightPoints != null &&
                      rightPoints > leftPoints;
                  final raceName =
                      leftEntry?.raceName ?? rightEntry?.raceName ?? '-';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildProgressionValueChip(
                              _formatSeasonPointsValue(leftPoints),
                              leftBetter,
                              isDark,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(
                                '${context.l10n.round_short} $round',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                raceName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildProgressionValueChip(
                              _formatSeasonPointsValue(rightPoints),
                              rightBetter,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionValueChip(String text, bool isBetter, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isBetter
            ? Colors.green.withValues(alpha: 0.14)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBetter
              ? Colors.green.withValues(alpha: 0.45)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isBetter ? 15 : 14,
          fontWeight: isBetter ? FontWeight.w700 : FontWeight.w500,
          color: isBetter
              ? Colors.green
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  String _formatSeasonPointsValue(double? value) {
    if (value == null) {
      return '-';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Widget _buildCompareScopeControls(BuildContext context) {

    final theme = Theme.of(context);
    final seasonsAvailable = _availableYears.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(context.l10n.compare_overall),
              selected: _showOverall,
              onSelected: (_) => setState(() => _showOverall = true),
            ),
            ChoiceChip(
              label: Text(context.l10n.compare_season),
              selected: !_showOverall,
              onSelected: seasonsAvailable
                  ? (_) => setState(() => _showOverall = false)
                  : null,
            ),
          ],
        ),
        if (!_showOverall && _selectedYear != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${context.l10n.compare_year}:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _selectedYear,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                  }
                },
                items: _availableYears
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Driver leftDriver,
    Driver rightDriver,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDriverHeader(context, leftDriver)),
        const Padding(
          padding: EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0),
          child: Text(
            'VS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildDriverHeader(context, rightDriver)),
      ],
    );
  }

  Widget _buildDriverHeader(BuildContext context, Driver driver) {
    return Column(
      children: [
        _buildDriverHeadshot(
          context: context,
          driver: driver,
          heroTag: _driverFlagHeroTag(driver, source: 'driver-compare'),
          size: 56,
        ),
        const SizedBox(height: 8),
        Text(
          driver.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        Text(
          '#${driver.number}',
          style: TextStyle(
            color: F1TeamSchemes.getTeamColor(driver.team),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// --- TEAM COMPARISON VIEW ----------------------------------------------
class TeamComparisonView extends StatefulWidget {
  final Team team1;
  final Team team2;

  const TeamComparisonView({
    required this.team1,
    required this.team2,
    super.key,
  });

  @override
  State<TeamComparisonView> createState() => _TeamComparisonViewState();
}

class _TeamComparisonViewState extends State<TeamComparisonView> {
  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leftTeam = widget.team1;
    final rightTeam = widget.team2;
    final entries1 = leftTeam.totalEntries == 0 ? 1 : leftTeam.totalEntries;
    final entries2 = rightTeam.totalEntries == 0 ? 1 : rightTeam.totalEntries;

    final scheme = Theme.of(context).colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      0.04,
    )!;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final listTopPadding = desktopShell ? 20.0 : topInset + 20;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: !desktopShell,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: !desktopShell,
        title: Text(context.l10n.team_comparison_title(widget.team1.name, widget.team2.name)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, listTopPadding, 16, 16),
              children: [
                _buildHeader(context, leftTeam, rightTeam),
          const SizedBox(height: 20),
          ComparisonRow(
            label: context.l10n.cc_wins,
            value1: widget.team1.ccWins,
            value2: widget.team2.ccWins,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.dc_wins,
            value1: widget.team1.dcWins,
            value2: widget.team2.dcWins,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.wins,
            value1: widget.team1.podiums,
            value2: widget.team2.podiums,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.one_two,
            value1: widget.team1.oneTwo,
            value2: widget.team2.oneTwo,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.poles,
            value1: widget.team1.poles,
            value2: widget.team2.poles,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.fastest_laps,
            value1: widget.team1.fastestLaps,
            value2: widget.team2.fastestLaps,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.total_points,
            value1: widget.team1.totalPoints,
            value2: widget.team2.totalPoints,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.total_entries,
            value1: widget.team1.totalEntries,
            value2: widget.team2.totalEntries,
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.fastest_pit,
            value1: widget.team1.fastestPitstopTime,
            value2: widget.team2.fastestPitstopTime,
            isDark: isDark,
            lowerIsBetter: true,
          ),
          ComparisonRow(
            label: context.l10n.points_per_entry,
            value1: (leftTeam.totalPoints / entries1).toStringAsFixed(2),
            value2: (rightTeam.totalPoints / entries2).toStringAsFixed(2),
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.pole_rate,
            value1: ((leftTeam.poles / entries1) * 100).toStringAsFixed(1),
            value2: ((rightTeam.poles / entries2) * 100).toStringAsFixed(1),
            isDark: isDark,
          ),
          ComparisonRow(
            label: context.l10n.fastest_lap_rate,
            value1: ((leftTeam.fastestLaps / entries1) * 100).toStringAsFixed(
              1,
            ),
            value2: ((rightTeam.fastestLaps / entries2) * 100).toStringAsFixed(
              1,
            ),
            isDark: isDark,
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Team leftTeam, Team rightTeam) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTeamHeader(leftTeam)),
        const Padding(
          padding: EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0),
          child: Text(
            'VS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildTeamHeader(rightTeam)),
      ],
    );
  }

  Widget _buildTeamHeader(Team team) {
    return Column(
      children: [
        Text(team.flag, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        Text(
          team.principalName,
          style: TextStyle(color: F1TeamSchemes.getTeamColor(team.name), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// --- DETAIL VIEWS ----------------------------------------------

class CircuitDetailScreen extends StatefulWidget {
  final Race race;
  final String heroTag;
  final Widget settingsMenu;
  const CircuitDetailScreen({
    super.key,
    required this.race,
    required this.heroTag,
    required this.settingsMenu,
  });
  @override
  State<CircuitDetailScreen> createState() => _CircuitDetailScreenState();
}

class _CircuitDetailScreenState extends State<CircuitDetailScreen> {
  String t = "--";
  int r = 0;
  String w = "--";
  String h = "--";
  bool _isWeatherLoading = true;
  late ScrollController _scrollController;
  bool _showFlagInTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchWeather();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 140;
      if (show != _showFlagInTitle) {
        setState(() => _showFlagInTitle = show);
      }
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weath = await fetchWeatherForRace(
        widget.race.lat,
        widget.race.lon,
      );
      if (mounted) {
        if (weath != null) {
          setState(() {
            t = weath.temperature.round().toString();
            r = weath.precipitationProbability;
            w = weath.windspeed.round().toString();
            h = weath.humidity.round().toString();
            _isWeatherLoading = false;
          });
        } else {
          setState(() {
            t = '-';
            w = '-';
            h = '-';
            r = 0;
            _isWeatherLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          t = '-';
          w = '-';
          h = '-';
          r = 0;
          _isWeatherLoading = false;
        });
      }
    }
  }

  Widget _buildCircuitHero(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _heroPanelGradient(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          _buildFlagHero(
            tag: widget.heroTag,
            flag: widget.race.flag,
            fontSize: 58,
          ),
          const SizedBox(height: 12),
          Text(
            l10nGrandPrix(context.l10n, widget.race.name).toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.race.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroChip(
                context,
                Icons.straighten,
                '${widget.race.length} m',
              ),
              _buildHeroChip(
                context,
                Icons.format_list_numbered,
                '${widget.race.laps} ${context.l10n.laps.toLowerCase()}',
              ),
              _buildHeroChip(
                context,
                Icons.workspace_premium,
                l10nDifficultyLevel(context.l10n, widget.race.circuitDifficulty),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.panelStrong.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _hubReadableAccent(context)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitLayoutCard(BuildContext context) {
    final tokens = _themeTokens(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: tokens.panelStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.circuit_layout,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: SvgPicture.network(
                      widget.race.circuitImage,
                      width: constraints.maxWidth,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        BlendMode.srcIn,
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

  Widget _buildCircuitTopArea(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        if (isWide) {
          return SizedBox(
            height: 340,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: _buildCircuitHero(context)),
                const SizedBox(width: 16),
                Expanded(flex: 9, child: _buildCircuitLayoutCard(context)),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildCircuitHero(context),
            const SizedBox(height: 20),
            SizedBox(height: 340, child: _buildCircuitLayoutCard(context)),
          ],
        );
      },
    );
  }

  void _openCircuitMap() {
    final userAgent = browser_bridge.browserUserAgent();
    final isApple =
        userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod') ||
        userAgent.contains('macintosh') ||
        userAgent.contains('mac os');
    final url = isApple
        ? 'https://maps.apple.com/?ll=${widget.race.lat},${widget.race.lon}&q=${Uri.encodeComponent(widget.race.name)}'
        : 'https://www.google.com/maps/search/?api=1&query=${widget.race.lat},${widget.race.lon}';
    browser_bridge.openExternalUrl(url);
  }

  Color _getDifficultyColor(String level) {
    switch (level) {
      case 'level_1':
        return Colors.green;
      case 'level_2':
        return Colors.lightGreen;
      case 'level_3':
        return Colors.orange;
      case 'level_4':
        return Colors.deepOrange;
      case 'level_5':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {

    String translatedStrategy = widget.race.bestCombination
        .replaceAll('Soft', context.l10n.soft_tire)
        .replaceAll('Medium', context.l10n.medium_tire)
        .replaceAll('Hard', context.l10n.hard_tire);
    final isDutch =
        Localizations.localeOf(context).languageCode == 'nl' ||
            Localizations.localeOf(context).languageCode == 'de';
    final List<String> characteristics = isDutch
        ? widget.race.characteristicsNl
        : widget.race.characteristicsEn;
    String title =
        l10nGrandPrix(context.l10n, widget.race.name).toUpperCase();
    if (_showFlagInTitle) {
      title = '${widget.race.flag} $title';
    }

    final expPrefs = context.watch<DetailExpansionPrefsNotifier>();

    final List<Widget> circuitSections = [
      _detailOverviewSectionCard(context, child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitWeather,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitWeather,
          v,
        ),
        title: Text(
          context.l10n.weather_forecast,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
        ),
        children: [
          if (_isWeatherLoading)
            _buildWeatherSkeletonRows(context)
          else ...[
            _statTile(context.l10n.temp, '$t°C', Icons.thermostat),
            _statTile(context.l10n.rain_chance, '$r%', Icons.umbrella),
            _statTile(context.l10n.wind_speed, '$w km/h', Icons.air),
            _statTile(context.l10n.humidity, '$h%', Icons.water_drop),
            const SizedBox(height: 8),
          ],
        ],
      )),
      _detailOverviewSectionCard(context, child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitInfo,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitInfo,
          v,
        ),
        title: Text(
          context.l10n.circuit_info,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
        ),
        children: [
          _statTile(
            context.l10n.length,
            '${widget.race.length} m',
            Icons.straighten,
          ),
          _statTile(
            context.l10n.distance_to_turn1,
            widget.race.distanceToTurn1,
            Icons.turn_right,
          ),
          _statTile(
            context.l10n.laps,
            widget.race.laps.toString(),
            Icons.format_list_numbered,
          ),
          _statTile(
            context.l10n.since,
            widget.race.firstGrandPrix.toString(),
            Icons.history,
          ),
          _statTile(
            context.l10n.until,
            widget.race.contractUntil,
            Icons.event,
          ),
          _statTile(
            context.l10n.circuit_difficulty,
            Text(
              l10nDifficultyLevel(context.l10n, widget.race.circuitDifficulty),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _getDifficultyColor(widget.race.circuitDifficulty),
              ),
            ),
            Icons.speed,
          ),
          _statTile(
            context.l10n.overtaking_difficulty,
            Text(
              l10nDifficultyLevel(context.l10n, widget.race.overtakingDifficulty),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _getDifficultyColor(widget.race.overtakingDifficulty),
              ),
            ),
            Icons.swap_horiz,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openCircuitMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(context.l10n.circuit_open_in_maps),
              ),
            ),
          ),
        ],
      )),
      _detailOverviewSectionCard(context, child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitLapSpeed,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitLapSpeed,
          v,
        ),
        title: Text(
          '⚡ ${context.l10n.lap_speed_stats}',
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
        ),
        children: [
          _statTile(
            context.l10n.fastest_lap,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.race.fastestLap.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${widget.race.fastestLap.driver} (${widget.race.fastestLap.year})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Icons.timer,
          ),
          _statTile(
            context.l10n.slowest_lap,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.race.slowestLap.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${widget.race.slowestLap.driver} (${widget.race.slowestLap.year})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Icons.timer_off,
          ),
          _statTile(
            context.l10n.avg_lap,
            widget.race.averageLap,
            Icons.av_timer,
          ),
          _statTile(
            context.l10n.top_speed,
            widget.race.topSpeed,
            Icons.speed,
          ),
          _statTile(
            context.l10n.average_speed,
            widget.race.averageSpeed,
            Icons.directions_car,
          ),
          _statTile(
            context.l10n.max_g_force,
            widget.race.maxGForce,
            Icons.compress,
          ),
          _statTile(
            context.l10n.avg_gforce,
            widget.race.avgGForce,
            Icons.compress,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(context, child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitRisks,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitRisks,
          v,
        ),
        title: Text(
          context.l10n.risks_incidents,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
        ),
        children: [
          _statTile(
            context.l10n.red_flag,
            '${widget.race.redFlagChance}%',
            Icons.flag,
          ),
          _statTile(
            context.l10n.vsc,
            '${widget.race.vscChance}%',
            Icons.warning_amber,
          ),
          _statTile(
            context.l10n.accident,
            '${widget.race.accidentChance}%',
            Icons.car_crash,
          ),
          _statTile(
            context.l10n.turn1_accident,
            '${widget.race.turn1AccidentChance}%',
            Icons.turn_right,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(context, child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitTyres,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitTyres,
          v,
        ),
        title: Text(
          '🛞 ${context.l10n.tyres_strategy}',
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
        ),
        children: [
          _statTile(
            context.l10n.tire_wear,
            l10nWearLabel(context.l10n, widget.race.tireWear),
            Icons.layers,
          ),
          _statTile(
            context.l10n.strategy,
            l10nStrategyLabel(context.l10n, widget.race.tireStrategy),
            Icons.settings_suggest,
          ),
          _statTile(
            context.l10n.best_combination,
            translatedStrategy,
            Icons.donut_large,
          ),
          _statTile(
            context.l10n.fastest_pit,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.race.fastestPitstop.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${widget.race.fastestPitstop.team} (${widget.race.fastestPitstop.year})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Icons.build,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(context, child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitCharacteristics,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.circuit,
          DetailExpansionSection.circuitCharacteristics,
          v,
        ),
        title: Text(
          '📍 ${context.l10n.characteristics}',
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _hubReadableAccent(context),
            ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: characteristics
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📌 ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _hubReadableAccent(context),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              c,
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      )),
    ];

    final scheme = Theme.of(context).colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      0.04,
    )!;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final listTopPadding = desktopShell ? 20.0 : topInset + 20;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: !desktopShell,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: !desktopShell,
        actions: _desktopAwareSettingsActions(context, widget.settingsMenu),
        title: Text(title),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _fetchWeather,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, listTopPadding, 20, 20),
                children: [
                  _buildCircuitTopArea(context),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.view_timeline),
                      title: Text(
                        context.l10n.weekend_hub,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(context.l10n.weekend_hub_card_subtitle),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => context.push(_weekendHubPath(widget.race)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: ValueKey('circuit-sections-${expPrefs.loadedRevision}'),
                    child: _buildResponsiveSections(sections: circuitSections),
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

/// Wraps a child with the unified F1 module style: surfaceContainerLow,
/// 20px radius, fading perimeter border (primary → transparent at 50% width).
/// Replaces the legacy 2px vertical stripe. Used by Weekend Hub and Race Control.
Widget _weekendHubCard(
  BuildContext context, {
  required Widget child,
  EdgeInsetsGeometry? padding,
  bool fillWidth = false,
}) {
  const radius = 20.0;
  final inner = DecoratedBox(
    decoration: _hubFlatHubCardDecoration(context, radius: radius),
    child: Padding(
      padding: padding ?? const EdgeInsets.all(18),
      child: child,
    ),
  );
  if (fillWidth) {
    return SizedBox(width: double.infinity, child: inner);
  }
  return inner;
}

class WeekendHubScreen extends StatefulWidget {
  final Race race;

  const WeekendHubScreen({required this.race, super.key});

  @override
  State<WeekendHubScreen> createState() => _WeekendHubScreenState();
}

String _sessionDisplayTitle(BuildContext context, String sessionName) {

  switch (sessionName) {
    case 'Practice 1':
      return context.l10n.fp1;
    case 'Practice 2':
      return context.l10n.fp2;
    case 'Practice 3':
      return context.l10n.fp3;
    case 'Sprint Qualifying':
      return context.l10n.sprint_quali;
    case 'Sprint':
      return context.l10n.sprint;
    case 'Qualifying':
      return context.l10n.qualifying;
    case 'Race':
      return '🏁 ${context.l10n.race}';
    case 'Day 1':
      return 'Day 1';
    case 'Day 2':
      return 'Day 2';
    default:
      return sessionName;
  }
}

/// Maps bundled JSON stem (`practice_1`, `day_3`, …) to UI session names for the hub.
String _hubStemToUiSessionName(String stem) {
  switch (stem) {
    case 'practice_1':
      return 'Practice 1';
    case 'practice_2':
      return 'Practice 2';
    case 'practice_3':
      return 'Practice 3';
    case 'sprint_qualifying':
      return 'Sprint Qualifying';
    case 'sprint':
      return 'Sprint';
    case 'qualifying':
      return 'Qualifying';
    case 'race':
      return 'Race';
    case 'day_1':
      return 'Day 1';
    case 'day_2':
      return 'Day 2';
    case 'day_3':
      return 'Race';
    default:
      return stem.replaceAll('_', ' ');
  }
}

String _hubStemDisplayTitle(BuildContext context, String stem) {
  return _sessionDisplayTitle(context, _hubStemToUiSessionName(stem));
}

F1TireCompound? _weekendHubTireCompoundFromAbbrev(String abbrev) {
  switch (abbrev.trim().toUpperCase()) {
    case 'S':
      return F1TireCompound.soft;
    case 'M':
      return F1TireCompound.medium;
    case 'H':
      return F1TireCompound.hard;
    default:
      return null;
  }
}

class _WeekendHubScreenState extends State<WeekendHubScreen> {
  static const double _weekendHubMobileBreak = 600;
  /// When true, shows the third bottom card ("Live radar & DRS"). Kept off until
  /// the feature ships; layout below assumes two columns on wide screens.
  static const bool _kWeekendHubShowLiveRadarDrCard = false;

      void _debugPrintSessionCache() {
        final race = widget.race;
        final year = race.date.year;
        final prefix = '${race.country}_';
      // print('--- DEBUG: Session cache keys for ${race.country} $year ---');
        for (final key in SessionDataManager().cache.keys) {
          if (key.startsWith(prefix) && key.endsWith('_$year')) {
          // print('  $key: ${SessionDataManager().cache[key]?.length ?? 0} results');
          }
        }
      // print('--- END DEBUG ---');
      }
    // Returns true if the given session has results in the cache
    bool _hasSessionResults(String sessionName) {
      final normalized = _normalizeSessionName(sessionName);
      final cacheKey = '${widget.race.country}_${normalized}_${widget.race.date.year}';
      final results = SessionDataManager().cache[cacheKey];
      return results != null && results.isNotEmpty;
    }
  static const String _allRaceControlScopes = '__all_scopes__';
  static const int _defaultRaceControlVisibleCount = 10;

  bool _loading = true;
  String _temperature = '--';
  String _trackTempDisplay = '--';
  String _humidityDisplay = '--';
  int _rainChance = 0;
  List<WeekendHubPodiumEntry> _podiumDetails = const <WeekendHubPodiumEntry>[];
  final TextEditingController _raceControlSearchController =
      TextEditingController();
  String _selectedRaceControlScope = _allRaceControlScopes;
  static const String _rcFilterAll = 'all';
  static const String _rcFilterAlerts = 'alerts';
  static const String _rcFilterStewards = 'stewards';
  static const String _rcFilterPenalties = 'penalties';
  String _selectedRaceControlQuickFilter = _rcFilterAll;
  /// Asset stem (`race`, `practice_1`, `day_2`, …) for modular `assets/data/{year}/{venue}/`.
  String _selectedSessionStem = '';
  String _raceControlSearchQuery = '';
  bool _showAllRaceControlMessages = false;
  Map<String, List<Map<String, dynamic>>> _weatherBySession =
      const <String, List<Map<String, dynamic>>>{};
  String? _loadError;
  List<String> _hubSessionStems = const [];
  final Map<String, List<Map<String, dynamic>>> _hubWeatherByStem = {};
  final Map<String, List<Map<String, dynamic>>> _hubRaceControlByStem = {};
  final Map<String, List<WeekendHubPodiumEntry>> _hubPodiumByStem = {};
  final Map<String, List<Map<String, dynamic>>> _hubLapTimelineByStem = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadWeekendData();
    });
  }

  @override
  void didUpdateWidget(covariant WeekendHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSameGrandPrixWeekend(oldWidget.race, widget.race)) {
      return;
    }
    final raceToLoad = widget.race;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_isSameGrandPrixWeekend(raceToLoad, widget.race)) {
        return;
      }
      _loadWeekendData();
    });
  }

  @override
  void dispose() {
    _raceControlSearchController.dispose();
    super.dispose();
  }

  Future<void> _discoverAndPreloadHubAssets() async {
    final race = widget.race;
    final year = race.date.year;
    final round = raceRoundFor(race);
    _hubSessionStems = const [];
    _hubWeatherByStem.clear();
    _hubRaceControlByStem.clear();
    _hubPodiumByStem.clear();
    _hubLapTimelineByStem.clear();
    if (!mounted) {
      return;
    }

    // Use [rootBundle] so discovery works on web and is not affected by an
    // inherited [DefaultAssetBundle] above this route.
    final bundle = rootBundle;
    final venue = await F1AssetResolver.resolveBundledVenueFolder(
      bundle: bundle,
      year: year,
      circuitAssetId: race.circuitAssetId,
      round: round,
    );
    if (venue == null || !mounted) {
      return;
    }

    final stems = await F1AssetResolver.discoverSessionResultStems(
      bundle: bundle,
      year: year,
      venueFolder: venue,
      hasSprintWeekend: race.hasSprint,
    );
    if (!mounted) {
      return;
    }
    _hubSessionStems = stems;
    if (stems.isEmpty) {
      return;
    }

    for (final stem in stems) {
      final uiName = _hubStemToUiSessionName(stem);
      final resPath = F1AssetResolver.sessionAssetPath(
        year: year,
        venueFolder: venue,
        sessionStem: stem,
        suffix: 'results',
      );
      final wxPath = F1AssetResolver.sessionAssetPath(
        year: year,
        venueFolder: venue,
        sessionStem: stem,
        suffix: 'weather',
      );
      final rcPath = F1AssetResolver.sessionAssetPath(
        year: year,
        venueFolder: venue,
        sessionStem: stem,
        suffix: 'race_control',
      );
      if (await F1AssetResolver.bundleHasAsset(bundle, wxPath)) {
        try {
          final wBody = await bundle.loadString(wxPath);
          _hubWeatherByStem[stem] = _parseHubWeatherSamples(wBody);
          _hubLapTimelineByStem[stem] = _parseHubLapTimeline(wBody);
        } catch (_) {
          _hubWeatherByStem[stem] = const [];
          _hubLapTimelineByStem[stem] = const [];
        }
      } else {
        _hubWeatherByStem[stem] = const [];
        _hubLapTimelineByStem[stem] = const [];
      }
      if (await F1AssetResolver.bundleHasAsset(bundle, rcPath)) {
        try {
          final rcBody = await bundle.loadString(rcPath);
          _hubRaceControlByStem[stem] =
              _normalizeHubRaceControlJson(rcBody, uiName);
        } catch (_) {
          _hubRaceControlByStem[stem] = const [];
        }
      } else {
        _hubRaceControlByStem[stem] = const [];
      }
      if (await F1AssetResolver.bundleHasAsset(bundle, resPath)) {
        try {
          final rBody = await bundle.loadString(resPath);
          _hubPodiumByStem[stem] = _hubTopThreeFromResultsBody(rBody);
        } catch (_) {
          _hubPodiumByStem[stem] = const [];
        }
      } else {
        _hubPodiumByStem[stem] = const [];
      }
    }
  }

  List<Map<String, dynamic>> _parseHubWeatherSamples(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final samples = decoded['samples'];
    if (samples is! List) return const [];
    return samples
        .whereType<Map>()
        .map((s) => s.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _parseHubLapTimeline(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final lt = decoded['lapTimeline'];
    if (lt is! List) return const [];
    return lt
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _normalizeHubRaceControlJson(
    String body,
    String uiSessionName,
  ) {
    final decoded = jsonDecode(body);
    final msgs = decoded is Map<String, dynamic> ? decoded['messages'] : null;
    if (msgs is! List) return const [];
    return msgs
        .whereType<Map>()
        .map((m) {
          final map = m.map((k, v) => MapEntry(k.toString(), v));
          final ts = map['timestampUtc'] ?? map['date'];
          return <String, dynamic>{
            ...map,
            'timestampUtc': ts,
            'sessionName': uiSessionName,
            'lap': map['lap'] ?? map['lap_number'],
            'driverNumber': map['driverNumber'] ?? map['driver_number'],
          };
        })
        .toList(growable: false);
  }

  List<WeekendHubPodiumEntry> _hubTopThreeFromResultsBody(String body) {
    final decoded = jsonDecode(body);
    final List<dynamic> raw;
    double? rootSessionBest;
    if (decoded is Map<String, dynamic>) {
      final sfl = decoded['sessionFastestLap'];
      if (sfl is Map) {
        final d = sfl['duration'];
        if (d is num) rootSessionBest = d.toDouble();
      }
    }
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['results'] is List) {
      raw = decoded['results'] as List<dynamic>;
    } else {
      return const [];
    }
    final maps = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = item.map((k, v) => MapEntry(k.toString(), v));
      if (!RaceResultRow._jsonLooksLikeOpenF1RaceResult(m)) continue;
      maps.add(m);
    }
    int posOf(Map<String, dynamic> m) {
      final f = m['finishPosition'];
      if (f is int) return f;
      return int.tryParse(f?.toString() ?? '') ?? 999;
    }
    maps.sort((a, b) => posOf(a).compareTo(posOf(b)));
    final leaderLap = maps.isEmpty
        ? null
        : RaceResultRow.openF1ResultFastestLapSeconds(maps.first);
    var sessionBest = rootSessionBest;
    if (sessionBest == null) {
      for (final m in maps) {
        final t = RaceResultRow.openF1ResultFastestLapSeconds(m);
        if (t != null && (sessionBest == null || t < sessionBest)) {
          sessionBest = t;
        }
      }
    }
    return maps
        .take(3)
        .map((m) {
          final row = SessionOverviewRow.fromOpenF1ResultMap(
            m,
            leaderFastestLapSeconds: leaderLap,
            sessionBestLapSeconds: sessionBest,
          );
          final tyreCompounds = row.tyreLapSequence
              .map((e) => e.compound)
              .where((c) => c.trim().isNotEmpty)
              .toSet()
              .toList(growable: false);
          final pos = posOf(m);
          final gapLine = RaceResultRow.openF1HubGapToLeaderLine(m, pos, leaderLap);
          final leaderTimeLine =
              RaceResultRow.openF1HubLeaderSessionTimeLine(m, row);
          return WeekendHubPodiumEntry(
            position: pos,
            driverNumber: null,
            driver: row.driver,
            points: row.points,
            totalTime: leaderTimeLine,
            gapToLeader: gapLine,
            fastestLap: row.fastestLap,
            hasFastestLap: row.hasFastestLap,
            tyreCompounds: tyreCompounds.isNotEmpty
                ? tyreCompounds
                : (row.tyreCompound.trim().isEmpty || row.tyreCompound == '-')
                ? const <String>[]
                : <String>[row.tyreCompound],
            bestLapTyreAbbrev: RaceResultRow.openF1BestLapTyreAbbrev(m),
          );
        })
        .toList(growable: false);
  }

  bool _matchesRaceControlPenaltiesFilter(String? raw) {
    final msg = raw?.toUpperCase() ?? '';
    return msg.contains('PENALTY') ||
        msg.contains('INVESTIGATION') ||
        msg.contains('SUMMONED') ||
        msg.contains('STEWARD');
  }

  Future<void> _loadWeekendData() async {

    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        _trackTempDisplay = '--';
        _humidityDisplay = '--';
      });
    }

    var podiumDetails = _fallbackPodiumDetails();

    try {
      // Bundled OpenF1 JSON under assets/data/{year}/{venue}/ — independent of
      // SessionDataManager / network so the hub always tries local files first.
      try {
        await _discoverAndPreloadHubAssets();
      } catch (e, st) {
        debugPrint('Weekend hub asset discovery failed: $e\n$st');
      }

      final roundIndex = raceRoundFor(widget.race);
      await SessionDataManager().ensureRaceDataAvailable(
        widget.race,
        roundIndex,
      );
      _debugPrintSessionCache();
      try {
        final fetched = await SessionDataManager().fetchWeekendHubPodium(
          widget.race,
        );
        if (fetched.podium.isNotEmpty) {
          podiumDetails = fetched.podium;
        }
      } catch (_) {}

      try {
        await _fetchWeekendWeather();
      } catch (_) {}
      try {
        final weatherData = await _loadStaticWeekendWeatherData();
        if (weatherData.weatherBySession.isNotEmpty && mounted) {
          setState(() {
            _weatherBySession = weatherData.weatherBySession;
          });
        }
      } catch (_) {}
    } catch (_) {
      if (mounted) {
        _loadError = context.l10n.weekend_hub_load_error;
      }
    }

    if (mounted) {
      final defaultStem = _hubSessionStems.isEmpty
          ? ''
          : _hubSessionStems.last;
      setState(() {
        _podiumDetails = podiumDetails;
        _loading = false;
        if (_hubSessionStems.isNotEmpty) {
          if (!_hubSessionStems.contains(_selectedSessionStem)) {
            _selectedSessionStem = defaultStem;
          }
        }
      });
    }
  }

  List<WeekendHubPodiumEntry> _fallbackPodiumDetails() {
    final rows =
        SessionDataManager().raceResultsCache[SessionDataManager()
            .raceResultsKeyFor(widget.race)] ??
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
        .map((row) {
          final position = _extractFinishPosition(row.finish);
          return WeekendHubPodiumEntry(
            position: position ?? 0,
            driverNumber: null,
            driver: row.driver,
            points: row.points,
            totalTime: row.timeOrGap,
            gapToLeader: row.timeOrGap,
            fastestLap: row.fastestLap,
            hasFastestLap: row.hasFastestLap,
            tyreCompounds:
                row.tyreCompound == '-' || row.tyreCompound.trim().isEmpty
                ? const <String>[]
                : <String>[row.tyreCompound],
            bestLapTyreAbbrev: RaceResultRow.tyreCompoundDisplayToInsightsLetter(
              row.tyreCompound,
            ),
          );
        })
        .toList(growable: false);
  }

  List<WeekendHubPodiumEntry> _sessionTopThree(String sessionName) {
    final normalized = _normalizeSessionName(sessionName);
    if (normalized == 'Race') {
      return _podiumDetails.isNotEmpty
          ? _podiumDetails
          : _fallbackPodiumDetails();
    }

    final overviewRows =
        SessionDataManager().sessionOverviewCache[SessionDataManager()
            .sessionOverviewKeyFor(widget.race, normalized)] ??
        const <SessionOverviewRow>[];
    if (overviewRows.isNotEmpty) {
      return overviewRows
          .take(3)
          .map((row) {
            final tyreCompounds = row.tyreLapSequence
                .map((entry) => entry.compound)
                .where((compound) => compound.trim().isNotEmpty)
                .toSet()
                .toList(growable: false);
            final position =
                RaceResultRow.openF1PositionFromPLabel(row.position) ?? 0;
            final resultValue = row.result.trim().isEmpty ? '-' : row.result;
            return WeekendHubPodiumEntry(
              position: position,
              driverNumber: null,
              driver: row.driver,
              points: row.points,
              totalTime: resultValue,
              gapToLeader: resultValue,
              fastestLap: row.fastestLap,
              hasFastestLap: row.hasFastestLap,
              tyreCompounds: tyreCompounds.isNotEmpty
                  ? tyreCompounds
                  : (row.tyreCompound.trim().isEmpty || row.tyreCompound == '-')
                  ? const <String>[]
                  : <String>[row.tyreCompound],
              bestLapTyreAbbrev:
                  RaceResultRow.tyreCompoundDisplayToInsightsLetter(
                row.tyreCompound,
              ),
            );
          })
          .toList(growable: false);
    }

    final cachedResults =
        SessionDataManager()
            .cache['${widget.race.country}_${normalized}_${widget.race.date.year}'] ??
        const <SessionResult>[];
    return cachedResults
        .take(3)
        .toList()
        .asMap()
        .entries
        .map((entry) {
          final row = entry.value;
          final tyreCompounds = row.tyre.trim().isEmpty || row.tyre == '-'
              ? const <String>[]
              : <String>[row.tyre];
          return WeekendHubPodiumEntry(
            position: entry.key + 1,
            driverNumber: null,
            driver: row.driver,
            points: '-',
            totalTime: row.time,
            gapToLeader: row.time,
            fastestLap: row.time,
            hasFastestLap: entry.key == 0,
            tyreCompounds: tyreCompounds,
            bestLapTyreAbbrev:
                RaceResultRow.tyreCompoundDisplayToInsightsLetter(row.tyre),
          );
        })
        .toList(growable: false);
  }

  Future<void> _fetchWeekendWeather() async {
    try {
      final w = widget.race.weather;
      _temperature = '${w.temperature}';
      _trackTempDisplay = '${w.feelsLike}';
      _rainChance = w.rainChance;
      _humidityDisplay = '${w.humidity}';
    } catch (_) {}
  }

  List<MapEntry<String, DateTime>> _sessionSchedule() {
    final sessions = <MapEntry<String, DateTime>>[
      MapEntry('Practice 1', widget.race.fp1),
    ];

    if (widget.race.hasSprint) {
      sessions.addAll([
        MapEntry('Sprint Qualifying', widget.race.sprintQuali),
        MapEntry('Sprint', widget.race.sprintRace),
      ]);
    } else {
      sessions.addAll([
        MapEntry('Practice 2', widget.race.fp2),
        MapEntry('Practice 3', widget.race.fp3),
      ]);
    }

    sessions.addAll([
      MapEntry('Qualifying', widget.race.qualifying),
      MapEntry('Race', widget.race.date),
    ]);
    return sessions;
  }

  String _sessionStatus(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return 'session_status_upcoming';
    }
    if (now.difference(date) < const Duration(hours: 3)) {
      return 'session_status_live_recent';
    }
    return 'session_status_completed';
  }

  void _openSingleSessionResults(String sessionName) {
    context.push(_singleSessionResultsPath(widget.race, sessionName));
  }

  String _sessionTimeLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day-$month ${local.year}  $hour:$minute';
  }

  List<String> _raceControlScopes(
    List<Map<String, dynamic>> messages,
    String selectedSession,
  ) {
    final sessionMessages = messages
        .where((message) => _normalizeSessionName(message['sessionName']) == _normalizeSessionName(selectedSession))
        .toList(growable: false);
    final scopes = sessionMessages
        .map((message) => message['scope']?.toString().trim() ?? '')
        .where((scope) => scope.isNotEmpty)
        .toSet()
        .toList(growable: true)
      ..sort();

    // Voeg (V)SC toe als er VSC/SC-berichten zijn
    final hasVSC = sessionMessages.any((m) {
      final msg = (m['message']?.toString() ?? '').toUpperCase();
      return msg.contains('VSC') || msg.contains('SAFETY CAR');
    });
    if (hasVSC) {
      scopes.add('(V)SC');
    }
    return <String>[_allRaceControlScopes, ...scopes];
  }

  List<Map<String, dynamic>> _filterRaceControlMessages(
    List<Map<String, dynamic>> messages,
    String selectedSession,
    String selectedScope,
  ) {
    final query = _raceControlSearchQuery.trim().toLowerCase();
    final filtered = messages
        .where((message) {
          final sessionName = _normalizeSessionName(message['sessionName']);
          if (sessionName != _normalizeSessionName(selectedSession)) {
            return false;
          }

          final scope = message['scope']?.toString().trim() ?? '';
          if (selectedScope != _allRaceControlScopes) {
            if (selectedScope == '(V)SC') {
              final msg = (message['message']?.toString() ?? '').toUpperCase();
              if (!(msg.contains('VSC') || msg.contains('SAFETY CAR'))) {
                return false;
              }
            } else if (scope != selectedScope) {
              return false;
            }
          }

          if (query.isEmpty) {
            return true;
          }

          final searchHaystack = <String>[
            message['message']?.toString() ?? '',
            message['sessionName']?.toString() ?? '',
            message['scope']?.toString() ?? '',
            message['category']?.toString() ?? '',
            message['flag']?.toString() ?? '',
            message['driverNumber']?.toString() ?? '',
            message['lap']?.toString() ?? '',
          ].join(' ').toLowerCase();

          return searchHaystack.contains(query);
        })
        .toList(growable: false);

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate == null && bDate == null) {
        return 0;
      }
      return aDate == null ? 1 : -1;
    });

    return filtered;
  }

  List<Map<String, dynamic>> _applyRaceControlQuickFilter(
    List<Map<String, dynamic>> messages,
  ) {
    if (_selectedRaceControlQuickFilter == _rcFilterAll) return messages;
    return messages.where((m) {
      final msg = m['message']?.toString();
      if (_selectedRaceControlQuickFilter == _rcFilterAlerts) {
        return _matchesRaceControlAlertsFilter(msg);
      }
      if (_selectedRaceControlQuickFilter == _rcFilterStewards) {
        return _matchesRaceControlStewardsFilter(msg);
      }
      if (_selectedRaceControlQuickFilter == _rcFilterPenalties) {
        return _matchesRaceControlPenaltiesFilter(msg);
      }
      return true;
    }).toList(growable: false);
  }

  List<String> _availableWeekendSessions(
    List<Map<String, dynamic>> raceControlMessages,
  ) {
    final scheduledSessions = _sessionSchedule()
        .map((entry) => entry.key)
        .toList();
      final weatherSessions = _weatherBySession.keys.map(_normalizeSessionName).toSet();
    final raceControlSessions = raceControlMessages
          .map((message) => _normalizeSessionName(message['sessionName']))
        .where((session) => session.isNotEmpty)
        .toSet();

    final available = scheduledSessions
        .where(
          (session) =>
              weatherSessions.contains(session) ||
              raceControlSessions.contains(session) ||
              session == 'Race',
        )
        .toList(growable: false);

    return available.isEmpty ? scheduledSessions : available;
  }

  Future<_WeekendWeatherData> _loadStaticWeekendWeatherData() async {
    final race = widget.race;
    final year = race.date.year;
    final round = raceRoundFor(race);

    for (final candidatePath
        in F1AssetResolver.legacyRoundWeatherPaths(year, round)) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, candidatePath)) {
        continue;
      }
      try {
        final body = await rootBundle.loadString(candidatePath);
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;

        final sessions = decoded['sessions'];
        if (sessions is Map) {
          final weatherBySession = <String, List<Map<String, dynamic>>>{};
          final lapTimelineBySession = <String, List<Map<String, dynamic>>>{};
          for (final entry in sessions.entries) {
            final sessionName = entry.key.toString();
            final sessionData = entry.value;
            if (sessionData is! Map) continue;
            final samples = sessionData['samples'];
            if (samples is! List) continue;
            weatherBySession[sessionName] = samples
                .whereType<Map>()
                .map(
                  (sample) => sample.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                )
                .toList(growable: false);

            final lapTimeline = sessionData['lapTimeline'];
            if (lapTimeline is List) {
              lapTimelineBySession[sessionName] = lapTimeline
                  .whereType<Map>()
                  .map(
                    (marker) => marker.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  )
                  .toList(growable: false);
            }
          }
          if (weatherBySession.isNotEmpty) {
            return _WeekendWeatherData(
              weatherBySession: weatherBySession,
              lapTimelineBySession: lapTimelineBySession,
            );
          }
        }

        final legacySamples = decoded['samples'];
        if (legacySamples is List) {
          return _WeekendWeatherData(
            weatherBySession: {
              'Race': legacySamples
                  .whereType<Map>()
                  .map(
                    (sample) => sample.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  )
                  .toList(growable: false),
            },
            lapTimelineBySession: const <String, List<Map<String, dynamic>>>{},
          );
        }
      } catch (_) {}
    }

    final modularBySession = <String, List<Map<String, dynamic>>>{};
    for (final venue in F1AssetResolver.expandedVenueFoldersForRace(
      circuitAssetId: race.circuitAssetId,
      year: year,
      round: round,
    )) {
      for (final entry in _sessionSchedule()) {
        final sessionNameStr = entry.key;
        if (modularBySession.containsKey(sessionNameStr)) continue;
        final stem = F1AssetResolver.sanitizeSessionStem(sessionNameStr);
        final path = F1AssetResolver.sessionAssetPath(
          year: year,
          venueFolder: venue,
          sessionStem: stem,
          suffix: 'weather',
        );
        if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) continue;
        try {
          final body = await rootBundle.loadString(path);
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded['samples'] is List) {
            final samples = (decoded['samples'] as List)
                .whereType<Map>()
                .map(
                  (s) => s.map((k, v) => MapEntry(k.toString(), v)),
                )
                .toList(growable: false);
            if (samples.isNotEmpty) {
              modularBySession[sessionNameStr] = samples;
            }
          }
        } catch (_) {}
      }
    }
    if (modularBySession.isNotEmpty) {
      return _WeekendWeatherData(
        weatherBySession: modularBySession,
        lapTimelineBySession: const <String, List<Map<String, dynamic>>>{},
      );
    }

    return const _WeekendWeatherData(
      weatherBySession: <String, List<Map<String, dynamic>>>{},
      lapTimelineBySession: <String, List<Map<String, dynamic>>>{},
    );
  }

  String _formatRaceControlTimestamp(
    BuildContext context,
    String? timestampUtc,
  ) {
    if (timestampUtc == null || timestampUtc.trim().isEmpty) {
      return context.l10n.unknown_time;
    }

    final date = DateTime.tryParse(timestampUtc)?.toLocal();
    if (date == null) {
      return timestampUtc;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$day-$month $hour:$minute:$second';
  }

  String _formatRaceControlBroadcastClock(String? timestampUtc) {
    if (timestampUtc == null || timestampUtc.trim().isEmpty) {
      return '--:--:--';
    }
    final date = DateTime.tryParse(timestampUtc)?.toLocal();
    if (date == null) {
      return '--:--:--';
    }
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static final RegExp _raceControlCarTurnHighlight =
      RegExp(r'\b(CAR\s+\d+|TURN\s+\d+)\b', caseSensitive: false);

  Widget _buildRaceControlBroadcastRichText(
    String text,
    Color baseColor,
    double fontSize,
  ) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _raceControlCarTurnHighlight.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: TextStyle(
              color: baseColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: baseColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            color: baseColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      );
    }
    if (spans.isEmpty) {
      return Text(
        text.isEmpty ? '-' : text,
        style: TextStyle(
          color: baseColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        softWrap: true,
        textAlign: TextAlign.start,
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      softWrap: true,
      textAlign: TextAlign.start,
    );
  }

  bool _isRaceControlTrackLimitDeletionMessage(String? rawMessage) {
    final u = rawMessage?.toUpperCase() ?? '';
    return u.contains('LAP TIME DELETED') || u.contains('DELETED LAP');
  }

  /// Groups NOTED / investigation / NFI with penalty imposition and PENALTY SERVED
  /// when [penaltySignature] or incident signature matches.
  String? _raceControlStorylineSignature(Map<String, dynamic> m) {
    final text = m['message']?.toString();
    final incident = _raceControlIncidentSignature(text);
    if (incident != null) {
      return 'i|$incident';
    }
    final penalty = _raceControlPenaltySignature(m);
    if (penalty != null) {
      return 'p|$penalty';
    }
    return null;
  }

  bool _isRaceControlStorylineClusterMessage(String? rawMessage) {
    return _isRaceControlIncidentFamilyMessage(rawMessage) ||
        _isRaceControlPenaltyMessage(rawMessage) ||
        _isRaceControlPenaltyServedMessage(rawMessage);
  }

  List<List<Map<String, dynamic>>> _groupBroadcastStorylineMessages(
    List<Map<String, dynamic>> ordered,
  ) {
    final groups = <List<Map<String, dynamic>>>[];
    for (final m in ordered) {
      final sig = _raceControlStorylineSignature(m);
      final fam = _isRaceControlStorylineClusterMessage(m['message']?.toString());
      if (fam &&
          sig != null &&
          groups.isNotEmpty &&
          groups.last.length < 20) {
        final last = groups.last;
        final lastSig = _raceControlStorylineSignature(last.last);
        if (lastSig == sig) {
          last.add(m);
          continue;
        }
      }
      groups.add(<Map<String, dynamic>>[m]);
    }
    return groups;
  }

  /// Race Control message style: Green (resolved), Red (alert), Orange (active).
  /// Uses FIA semantic colors (green/orange/red), not team primary.
  ({Color background, Color border, Color text})? _raceControlMessageStyle(
    String? rawMessage,
    F1ThemeTokens tokens,
  ) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    if (message.isEmpty) return null;

    // FIA semantic colors: Green (clear/resolved), Orange (caution), Red (alert)
    final success = const Color(0xFF2E7D32); // Material Green 800
    final error = tokens.statusError;
    final warning = const Color(0xFFE65100); // Material Orange 900
    ({Color background, Color border, Color text}) style({required Color c}) => (
          background: c,
          border: c,
          text: F1ThemeTokens.textOnBackground(c),
        );

    final neutralGrey = const Color(0xFF757575);

    // ─── GREY (Neutral closure) – NFI outcomes before generic “resolved” green ─
    if (message.contains('NO FURTHER INVESTIGATION')) {
      return style(c: neutralGrey);
    }

    // ─── GREEN (Success/Resolved) – most specific first ─────────────────────
    // Resolution phrases (check before generic "ENDING" to avoid false matches)
    if (_matchesAny(message, [
      'PENALTY SERVED',
      'PENALTY NOTED', // penalty acknowledged / no further action
      'NO FURTHER ACTION',
      'VSC ENDING',
      'VSC ENDED',
      'SAFETY CAR IN THIS LAP',
      'SAFETY CAR IN LAP',
      'SAFETY CAR RETURNING',
      'TRACK CLEAR',
      'CLEAR IN TRACK',
      'ALL CLEAR',
      'RACE RESUMED',
      'SESSION RESUMED',
      'START PROCEDURE RESUMED',
      'OVERTAKE RESTORED',
      'LAPPED CARS MAY NOW OVERTAKE',
      'LAPPED CARS TO OVERTAKE',
      'FORMATION LAP RESUMED',
      'WARNING', // steward warning issued (resolution)
      'REPRIMAND',
      'BLACK AND WHITE FLAG',
      'FINE', // steward fine (resolution)
      // 2026
      'OVERTAKE MODE ENABLED',
      'OVERTAKE AVAILABLE',
      'ACTIVE AERO ENABLED',
    ])) {
      return style(c: success);
    }
    // Generic "ending" / "cleared" (after specific phrases)
    if (message.contains('ENDING') || message.contains('ENDED') ||
        message.contains('WITHDRAWN') || message.contains('CLEARED')) {
      return style(c: success);
    }

    // ─── RED (Alert/Critical) – highest priority first ──────────────────────
    if (_matchesAny(message, [
      'ABORTED',
      'DELAYED',
      'EMERGENCY E-STOP',
      'BATTERY ISOLATION REQUIRED',
      'RED FLAG',
      'RACE SUSPENDED',
      'RACE STOPPED',
      'SESSION SUSPENDED',
      'SESSION STOPPED',
      'DISQUALIFIED',
      'EXCLUDED',
      'BLACK FLAG',
      'BLACK AND ORANGE',
    ])) {
      return style(c: error);
    }
    // Imposed time penalties (explicit before generic PENALTY branch)
    if (message.contains('TIME PENALTY')) {
      return style(c: error);
    }
    // Penalty imposition (not "PENALTY SERVED" – already handled above)
    if (message.contains('PENALTY') &&
        !message.contains('PENALTY SERVED') &&
        !message.contains('PENALTY NOTED')) {
      return style(c: error);
    }

    // ─── ORANGE (Warning/Active) – situations requiring caution ────────────
    if (_matchesAny(message, [
      'DEBRIS ON TRACK',
      'DEBRIS',
      'OIL ON TRACK',
      'FLUID ON TRACK',
      'MARSHALS ON TRACK',
      'DOUBLE YELLOW',
      'SINGLE YELLOW',
      'YELLOW FLAG',
      'VSC DEPLOYED',
      'VSC DEPLOYMENT',
      'SAFETY CAR DEPLOYED',
      'SAFETY CAR DEPLOYMENT',
      'SC DEPLOYED',
      'UNDER INVESTIGATION',
      'WILL BE INVESTIGATED',
      'SUMMONED',
      'SUMMONED TO STEWARDS',
      'NOTED',
      'DEPLOYED',
      'FORMATION LAP',
      'START PROCEDURE',
      // 2026
      'ACTIVE AERO RESTRICTED',
      'ENERGY RECOVERY LIMIT',
      'POWER UNIT CLIPPING',
    ])) {
      return style(c: warning);
    }

    // ─── NEUTRAL – informational (DRS, chequered, etc.) – no highlight ────
    // Return null so message uses default panelStrong styling
    return null;
  }

  bool _matchesAny(String message, List<String> phrases) {
    for (final phrase in phrases) {
      if (message.contains(phrase)) return true;
    }
    return false;
  }

  /// 'warning' | 'error' = Alerts. Uses same logic as _raceControlMessageStyle.
  String? _raceControlMessageCategory(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    if (message.isEmpty) return null;

    if (message.contains('NO FURTHER INVESTIGATION')) {
      return 'neutral';
    }

    if (_matchesAny(message, [
      'PENALTY SERVED', 'PENALTY NOTED', 'NO FURTHER ACTION',
      'VSC ENDING', 'VSC ENDED',
      'SAFETY CAR IN THIS LAP', 'SAFETY CAR IN LAP', 'SAFETY CAR RETURNING',
      'TRACK CLEAR', 'CLEAR IN TRACK', 'ALL CLEAR', 'RACE RESUMED',
      'SESSION RESUMED', 'START PROCEDURE RESUMED', 'OVERTAKE RESTORED',
      'LAPPED CARS MAY NOW OVERTAKE', 'LAPPED CARS TO OVERTAKE',
      'FORMATION LAP RESUMED', 'WARNING', 'REPRIMAND', 'BLACK AND WHITE FLAG',
      'FINE', 'OVERTAKE MODE ENABLED', 'OVERTAKE AVAILABLE', 'ACTIVE AERO ENABLED',
    ])) {
      return 'success';
    }
    if (message.contains('ENDING') || message.contains('ENDED') ||
        message.contains('WITHDRAWN') || message.contains('CLEARED')) {
      return 'success';
    }

    if (_matchesAny(message, [
      'ABORTED', 'DELAYED', 'EMERGENCY E-STOP', 'BATTERY ISOLATION REQUIRED',
      'RED FLAG', 'RACE SUSPENDED', 'RACE STOPPED', 'SESSION SUSPENDED',
      'SESSION STOPPED', 'DISQUALIFIED', 'EXCLUDED', 'BLACK FLAG', 'BLACK AND ORANGE',
    ])) {
      return 'error';
    }
    if (message.contains('TIME PENALTY')) {
      return 'error';
    }
    if (message.contains('PENALTY') && !message.contains('PENALTY SERVED') &&
        !message.contains('PENALTY NOTED')) {
      return 'error';
    }

    if (_matchesAny(message, [
      'DEBRIS ON TRACK', 'DEBRIS', 'OIL ON TRACK', 'FLUID ON TRACK',
      'MARSHALS ON TRACK', 'DOUBLE YELLOW', 'SINGLE YELLOW', 'YELLOW FLAG',
      'VSC DEPLOYED', 'VSC DEPLOYMENT', 'SAFETY CAR DEPLOYED', 'SAFETY CAR DEPLOYMENT',
      'SC DEPLOYED', 'UNDER INVESTIGATION', 'WILL BE INVESTIGATED', 'SUMMONED',
      'SUMMONED TO STEWARDS', 'NOTED', 'DEPLOYED', 'FORMATION LAP', 'START PROCEDURE',
      'ACTIVE AERO RESTRICTED', 'ENERGY RECOVERY LIMIT', 'POWER UNIT CLIPPING',
    ])) {
      return 'warning';
    }

    return null;
  }

  bool _matchesRaceControlAlertsFilter(String? rawMessage) {
    final cat = _raceControlMessageCategory(rawMessage);
    return cat == 'warning' || cat == 'error';
  }

  bool _matchesRaceControlStewardsFilter(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    return _matchesAny(message, [
      'INVESTIGATION', 'PENALTY', 'NOTED', 'SUMMONED', 'REPRIMAND',
    ]);
  }

  bool _isRaceControlPenaltyServedMessage(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    return message.contains('PENALTY SERVED');
  }

  bool _isRaceControlPenaltyMessage(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    return message.contains('PENALTY') &&
        !_isRaceControlPenaltyServedMessage(rawMessage) &&
        !message.contains('PENALTY NOTED');
  }

  bool _isRaceControlInvestigationMessage(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    return message.contains('UNDER INVESTIGATION') ||
        message.contains('WILL BE INVESTIGATED') ||
        message.contains('SUMMONED');
  }

  bool _isRaceControlNotedMessage(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    return message.contains(' NOTED') || message.endsWith('NOTED');
  }

  bool _isRaceControlResolutionMessage(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    return message.contains('NO FURTHER ACTION') ||
        message.contains('NO FURTHER INVESTIGATION REQUIRED') ||
        message.contains('REVIEWED NO FURTHER INVESTIGATION') ||
        message.contains('NOTED') ||
        message.contains('WARNING') ||
        message.contains('REPRIMAND') ||
        message.contains('BLACK AND WHITE FLAG') ||
        message.contains('FINE');
  }

  int? _raceControlDriverNumberForMessage(Map<String, dynamic> message) {
    final directDriverNumber = _asInt(message['driverNumber']);
    if (directDriverNumber != null) {
      return directDriverNumber;
    }

    final rawMessage = message['message']?.toString().toUpperCase() ?? '';
    final match = RegExp(r'CAR\s+(\d+)').firstMatch(rawMessage);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String _normalizeRaceControlMatchText(String value) {
    return value
        .toUpperCase()
        .replaceAll('INVOLDING', 'INVOLVING')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeRaceControlIncidentSource(String value) {
    return value
        .replaceAll(RegExp(r'\bINVOLDING\b', caseSensitive: false), 'INVOLVING')
        .trim();
  }

  String _stripRaceControlServedPrefix(String value) {
    return value.replaceFirst(
      RegExp(r'^\s*(?:FIA\s+STEWARDS:\s*)?PENALTY\s+SERVED\s*-\s*'),
      '',
    );
  }

  String? _raceControlPenaltyKindKey(String? rawMessage) {
    final message = rawMessage?.trim().toUpperCase() ?? '';
    if (message.isEmpty) {
      return null;
    }

    final source = _stripRaceControlServedPrefix(message);

    final gridMatch = RegExp(
      r'(\d+)\s*(?:PLACE|POSITION)\s+GRID\s+(?:PENALTY|DROP)',
    ).firstMatch(source);
    if (gridMatch != null) {
      return 'grid:${gridMatch.group(1)}';
    }

    final altGridMatch = RegExp(
      r'GRID\s+(?:PENALTY|DROP)\s+OF\s+(\d+)\s*(?:PLACE|POSITION)',
    ).firstMatch(source);
    if (altGridMatch != null) {
      return 'grid:${altGridMatch.group(1)}';
    }

    final timeMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*SECOND(?:S)?\s+TIME\s+PENALTY',
    ).firstMatch(source);
    if (timeMatch != null) {
      return 'time:${_trimTrailingZero(timeMatch.group(1)!)}';
    }

    final altTimeMatch = RegExp(
      r'TIME\s+PENALTY\s+OF\s+(\d+(?:\.\d+)?)\s*SECOND(?:S)?',
    ).firstMatch(source);
    if (altTimeMatch != null) {
      return 'time:${_trimTrailingZero(altTimeMatch.group(1)!)}';
    }

    final simpleTimeMatch = RegExp(
      r'PENALTY\s*-\s*(\d+(?:\.\d+)?)\s*SECOND(?:S)?',
    ).firstMatch(source);
    if (simpleTimeMatch != null) {
      return 'time:${_trimTrailingZero(simpleTimeMatch.group(1)!)}';
    }

    if (source.contains('STOP/GO PENALTY') ||
        source.contains('STOP AND GO PENALTY') ||
        source.contains('STOP-AND-GO PENALTY')) {
      return 'stop-go';
    }

    if (source.contains('DRIVE THROUGH PENALTY') ||
        source.contains('DRIVE-THROUGH PENALTY')) {
      return 'drive-through';
    }

    return null;
  }

  String? _raceControlPenaltyReasonKey(String? rawMessage) {
    final message = rawMessage?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }

    final source = _stripRaceControlServedPrefix(message);
    final match = RegExp(r'\s-\s(.+)$').firstMatch(source);
    if (match == null) {
      return null;
    }

    final normalized = _normalizeRaceControlMatchText(match.group(1)!);
    return normalized.isEmpty ? null : normalized;
  }

  String? _raceControlPenaltySignature(Map<String, dynamic> message) {
    final rawMessage = message['message']?.toString();
    final kindKey = _raceControlPenaltyKindKey(rawMessage);
    if (kindKey == null) {
      return null;
    }

    final driverNumber = _raceControlDriverNumberForMessage(message) ?? -1;
    final reasonKey = _raceControlPenaltyReasonKey(rawMessage) ?? '';
    return '$driverNumber|$kindKey|$reasonKey';
  }

  String? _raceControlIncidentSignature(String? rawMessage) {
    final message = rawMessage?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }

    final source = _normalizeRaceControlIncidentSource(
      message.replaceFirst(
        RegExp(r'^\s*FIA\s+STEWARDS:\s*', caseSensitive: false),
        '',
      ),
    );
    final match = RegExp(
      r'^(.*?)\s+(UNDER INVESTIGATION|WILL BE INVESTIGATED(?: AFTER THE SESSION| AFTER THE RACE)?|SUMMONED|NO FURTHER ACTION|NO FURTHER INVESTIGATION REQUIRED|REVIEWED NO FURTHER INVESTIGATION|NOTED|WARNING|REPRIMAND|BLACK AND WHITE FLAG|FINE)(?:\s*\-\s*(.*))?$',
      caseSensitive: false,
    ).firstMatch(source);
    if (match != null) {
      final incidentKey = _normalizeRaceControlMatchText(match.group(1) ?? '');
      if (incidentKey.isEmpty) {
        return null;
      }
      final reasonKey = _normalizeRaceControlMatchText(match.group(3) ?? '');
      return '$incidentKey|$reasonKey';
    }

    final upper = source.toUpperCase();
    // Standalone NFI outcomes (often "… NO FURTHER INVESTIGATION … CAR n")
    if (upper.contains('NO FURTHER INVESTIGATION')) {
      final car = RegExp(r'CAR\s+(\d+)', caseSensitive: false).firstMatch(source);
      final key = car != null
          ? 'NFI_CAR_${car.group(1)}'
          : _normalizeRaceControlMatchText(source);
      return '$key|nfi';
    }

    return null;
  }

  bool _isRaceControlIncidentFamilyMessage(String? rawMessage) {
    return _isRaceControlNotedMessage(rawMessage) ||
        _isRaceControlInvestigationMessage(rawMessage) ||
        _isRaceControlResolutionMessage(rawMessage);
  }

  String _raceControlRelationTitle(
    BuildContext context,
    String? rawMessage,
    bool isSource,
  ) {

    if (_isRaceControlPenaltyServedMessage(rawMessage)) {
      return isSource
          ? context.l10n.race_control_relation_served_penalty
          : context.l10n.race_control_relation_issued_earlier;
    }
    if (_isRaceControlPenaltyMessage(rawMessage)) {
      return isSource
          ? context.l10n.race_control_relation_penalty_message
          : context.l10n.race_control_relation_served_later;
    }
    if (_isRaceControlNotedMessage(rawMessage)) {
      return context.l10n.race_control_relation_noted;
    }
    if (_isRaceControlInvestigationMessage(rawMessage)) {
      return isSource
          ? context.l10n.race_control_relation_investigation
          : context.l10n.race_control_relation_outcome;
    }
    if (_isRaceControlResolutionMessage(rawMessage)) {
      return isSource
          ? context.l10n.race_control_relation_outcome
          : context.l10n.race_control_relation_investigation;
    }
    return isSource
        ? context.l10n.race_control_relation_message
        : context.l10n.race_control_relation_linked;
  }

  List<Map<String, dynamic>> _relatedRaceControlMessages(
    List<Map<String, dynamic>> allMessages,
    String selectedSession,
    Map<String, dynamic> sourceMessage,
  ) {
    final sourceText = sourceMessage['message']?.toString();
    final penaltySignature = _raceControlPenaltySignature(sourceMessage);
    final penaltyKindKey = _raceControlPenaltyKindKey(sourceText);
    final incidentSignature = _raceControlIncidentSignature(sourceText);
    final sourceDriverNumber = _raceControlDriverNumberForMessage(sourceMessage);

    // VSC/Safety Car koppeling
    final sourceTextUpper = sourceText?.toUpperCase() ?? '';
    final isVSC = sourceTextUpper.contains('VSC DEPLOYED') || sourceTextUpper.contains('VSC ENDING');
    final isSC = sourceTextUpper.contains('SAFETY CAR DEPLOYED') || sourceTextUpper.contains('SAFETY CAR ENDING') || sourceTextUpper.contains('SAFETY CAR IN THIS LAP');
    if (isVSC || isSC) {
      final deployed = isVSC ? 'VSC DEPLOYED' : 'SAFETY CAR DEPLOYED';
      // Voor SC: zowel ENDING als IN THIS LAP zijn "einde"
      final ending = isVSC ? 'VSC ENDING' : 'SAFETY CAR ENDING';
      final inThisLap = isVSC ? null : 'SAFETY CAR IN THIS LAP';
      final isSourceDeployed = sourceTextUpper.contains('DEPLOYED');
      final isSourceEnding = sourceTextUpper.contains('ENDING') || sourceTextUpper.contains('IN THIS LAP');
      final sourceTime = DateTime.tryParse(sourceMessage['timestampUtc']?.toString() ?? '');
      Map<String, dynamic>? bestMatch;
      Duration? bestDelta;
      for (final candidate in allMessages) {
        if (identical(candidate, sourceMessage)) continue;
        final candidateSession = _normalizeSessionName(candidate['sessionName']);
        if (candidateSession != _normalizeSessionName(selectedSession)) continue;
        final candidateText = (candidate['message']?.toString() ?? '').toUpperCase();
        final candidateTime = DateTime.tryParse(candidate['timestampUtc']?.toString() ?? '');
        // Koppel deployed -> ending/in this lap
        if (isSourceDeployed && (
              candidateText.contains(ending) || (inThisLap != null && candidateText.contains(inThisLap))
            ) && sourceTime != null && candidateTime != null && candidateTime.isAfter(sourceTime)) {
          final delta = candidateTime.difference(sourceTime);
          if (bestDelta == null || delta < bestDelta) {
            bestDelta = delta;
            bestMatch = candidate;
          }
        }
        // Koppel ending/in this lap -> deployed
        if (isSourceEnding && candidateText.contains(deployed) && sourceTime != null && candidateTime != null && candidateTime.isBefore(sourceTime)) {
          final delta = sourceTime.difference(candidateTime);
          if (bestDelta == null || delta < bestDelta) {
            bestDelta = delta;
            bestMatch = candidate;
          }
        }
      }
      return bestMatch != null ? [bestMatch] : <Map<String, dynamic>>[];
    }

    if (penaltySignature == null && penaltyKindKey == null && incidentSignature == null) {
      return const <Map<String, dynamic>>[];
    }

    final sourceIsServed = _isRaceControlPenaltyServedMessage(sourceText);
    final sourceIsPenalty = _isRaceControlPenaltyMessage(sourceText);
    final sourceIsInvestigation = _isRaceControlInvestigationMessage(sourceText);
    final sourceIsResolution = _isRaceControlResolutionMessage(sourceText);
    if (!sourceIsServed && !sourceIsPenalty && !sourceIsInvestigation && !sourceIsResolution) {
      return const <Map<String, dynamic>>[];
    }

    final related = allMessages.where((candidate) {
      if (identical(candidate, sourceMessage)) {
        return false;
      }

      final candidateSession = _normalizeSessionName(candidate['sessionName']);
      if (candidateSession != _normalizeSessionName(selectedSession)) {
        return false;
      }

      final candidateText = candidate['message']?.toString();
      final candidatePenaltySignature = _raceControlPenaltySignature(candidate);
      final candidateIncidentSignature = _raceControlIncidentSignature(candidateText);
      if (penaltySignature != null || candidatePenaltySignature != null) {
        if (penaltySignature == null || candidatePenaltySignature == null) {
          return false;
        }
        if (candidatePenaltySignature != penaltySignature) {
          return false;
        }
      } else if (incidentSignature != null || candidateIncidentSignature != null) {
        if (incidentSignature == null || candidateIncidentSignature == null) {
          return false;
        }
        if (candidateIncidentSignature != incidentSignature) {
          return false;
        }
      } else {
        final candidatePenaltyKindKey = _raceControlPenaltyKindKey(candidateText);
        if (candidatePenaltyKindKey != penaltyKindKey) {
          return false;
        }
      }

      final candidateDriverNumber = _raceControlDriverNumberForMessage(candidate);
      if (sourceDriverNumber != null && candidateDriverNumber != null && sourceDriverNumber != candidateDriverNumber) {
        return false;
      }

      if (sourceIsServed) {
        return _isRaceControlPenaltyMessage(candidateText);
      }
      if (sourceIsPenalty) {
        return _isRaceControlPenaltyServedMessage(candidateText);
      }
      if (sourceIsInvestigation || sourceIsResolution) {
        return _isRaceControlIncidentFamilyMessage(candidateText);
      }
      return false;
    }).toList(growable: false)
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['timestampUtc']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['timestampUtc']?.toString() ?? '');
        if (aDate != null && bDate != null) {
          return aDate.compareTo(bDate);
        }
        if (aDate == null && bDate == null) {
          return 0;
        }
        return aDate == null ? 1 : -1;
      });

    return related;
  }

  Widget _buildRaceControlDetailCard(
    BuildContext context,
    String title,
    Map<String, dynamic> message,
  ) {

    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final style = _raceControlMessageStyle(message['message']?.toString(), tokens);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style?.background ?? tokens.panelStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: style?.border ?? tokens.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: style?.text ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message['message']?.toString() ?? '-',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: style?.text ?? theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (message['lap'] != null)
                _buildRaceControlTag(
                  context,
                  Icons.looks_one,
                  context.l10n.lap_label('${message['lap']}'),
                ),
              if (message['driverNumber'] != null)
                _buildRaceControlTag(
                  context,
                  Icons.directions_car,
                  context.l10n.car_label('${message['driverNumber']}'),
                ),
              if ((message['flag']?.toString() ?? '').trim().isNotEmpty)
                _buildRaceControlTag(
                  context,
                  Icons.flag,
                  message['flag']!.toString(),
                  accentColor: _raceControlFlagColor(
                    message['flag']?.toString(),
                    tokens,
                    theme.colorScheme,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatRaceControlTimestamp(
              context,
              message['timestampUtc']?.toString(),
            ),
            style: TextStyle(
              fontSize: 12,
              color:
                  style?.text.withValues(alpha: 0.88) ??
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRaceControlMessageDetails(
    BuildContext context,
    List<Map<String, dynamic>> allMessages,
    String selectedSession,
    Map<String, dynamic> message,
  ) async {

    final relatedMessages = _relatedRaceControlMessages(
      allMessages,
      selectedSession,
      message,
    );
    final sourceIsInvestigation = _isRaceControlInvestigationMessage(
      message['message']?.toString(),
    );
    final sourceIsResolution = _isRaceControlResolutionMessage(
      message['message']?.toString(),
    );
    final sourceTitle = _raceControlRelationTitle(
      context,
      message['message']?.toString(),
      true,
    );
    final relatedTitle = sourceIsInvestigation || sourceIsResolution
        ? context.l10n.race_control_related_updates
        : _raceControlRelationTitle(
            context,
            message['message']?.toString(),
            false,
          );

    await hubShowDialogWithBlurBarrier<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.race_control_detail),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRaceControlDetailCard(
                    dialogContext,
                    sourceTitle,
                    message,
                  ),
                  if (relatedMessages.isNotEmpty) ...[
                    Text(
                      relatedTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...relatedMessages.map(
                      (relatedMessage) => _buildRaceControlDetailCard(
                        dialogContext,
                        sourceIsInvestigation || sourceIsResolution
                            ? _raceControlRelationTitle(
                                dialogContext,
                                relatedMessage['message']?.toString(),
                                true,
                              )
                            : relatedTitle,
                        relatedMessage,
                      ),
                    ),
                  ] else ...[
                    Text(
                      context.l10n.race_control_no_linked_message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.close),
            ),
          ],
        );
      },
    );
  }

  Color? _raceControlFlagColor(String? flag, F1ThemeTokens tokens, ColorScheme scheme) {
    final normalized = flag?.trim().toUpperCase() ?? '';
    switch (normalized) {
      case 'BLUE': return scheme.primary;
      case 'RED': return tokens.statusError;
      case 'DOUBLE YELLOW':
      case 'YELLOW': return tokens.statusWarning;
      case 'GREEN':
      case 'CLEAR': return tokens.statusSuccess;
      default: return null;
    }
  }

  Widget _buildRaceControlScopeChips(
    BuildContext context,
    List<String> availableScopes,
    String selectedScope,
  ) {
    final theme = Theme.of(context);
    bool isSelected(String scope) => scope == selectedScope;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableScopes.map((scope) {
        final selected = isSelected(scope);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedRaceControlScope = scope;
                _showAllRaceControlMessages = false;
              });
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? Border.all(
                        color: _hubReadableAccent(context).withValues(alpha: 0.35),
                        width: 0.5,
                      )
                    : null,
              ),
              child: Text(
                scope == _allRaceControlScopes ? context.l10n.all_scopes : scope,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildRaceControlFilterBar(BuildContext context) {
    bool isSelected(String filter) => filter == _selectedRaceControlQuickFilter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRaceControlFilterChip(
            context,
            label: context.l10n.race_control_filter_all,
            filter: _rcFilterAll,
            selected: isSelected(_rcFilterAll),
          ),
          const SizedBox(width: 8),
          _buildRaceControlFilterChip(
            context,
            label: context.l10n.race_control_filter_alerts,
            filter: _rcFilterAlerts,
            selected: isSelected(_rcFilterAlerts),
          ),
          const SizedBox(width: 8),
          _buildRaceControlFilterChip(
            context,
            label: context.l10n.race_control_filter_stewards,
            filter: _rcFilterStewards,
            selected: isSelected(_rcFilterStewards),
          ),
          const SizedBox(width: 8),
          _buildRaceControlFilterChip(
            context,
            label: context.l10n.race_control_filter_penalties,
            filter: _rcFilterPenalties,
            selected: isSelected(_rcFilterPenalties),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceControlFilterChip(
    BuildContext context, {
    required String label,
    required String filter,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = selected
        ? scheme.primary
        : scheme.surfaceContainerLow;
    final textColor = selected
        ? F1ThemeTokens.textOnBackground(scheme.primary)
        : scheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRaceControlQuickFilter = filter;
            _showAllRaceControlMessages = false;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: FadingBorderPainter(
                        color: F1ThemeTokens.textOnBackground(scheme.primary)
                            .withValues(alpha: 0.4),
                        borderRadius: 20,
                        borderWidth: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRaceControlSection(
    BuildContext context,
    List<Map<String, dynamic>> messages,
    String selectedSession, {
    bool broadcastLayout = false,
  }) {
    final theme = Theme.of(context);
    final availableScopes = _raceControlScopes(messages, selectedSession);
    final selectedScope = availableScopes.contains(_selectedRaceControlScope)
        ? _selectedRaceControlScope
        : _allRaceControlScopes;
    var filteredMessages = _filterRaceControlMessages(
      messages,
      selectedSession,
      selectedScope,
    );
    filteredMessages = _applyRaceControlQuickFilter(filteredMessages);
    final visibleMessages = _showAllRaceControlMessages
        ? filteredMessages
        : filteredMessages.take(_defaultRaceControlVisibleCount).toList();

    if (broadcastLayout) {
      return _buildWeekendHubBroadcastRaceControlSection(
        context,
        messages,
        selectedSession,
        availableScopes,
        selectedScope,
        filteredMessages,
      );
    }

    return _weekendHubCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCardTitle(context, context.l10n.race_control),
          const SizedBox(height: 12),
          TextField(
            controller: _raceControlSearchController,
            onChanged: (value) {
              setState(() {
                _raceControlSearchQuery = value;
                _showAllRaceControlMessages = false;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.l10n.race_control_search_hint,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.scope,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildRaceControlScopeChips(
            context,
            availableScopes,
            selectedScope,
          ),
          const SizedBox(height: 12),
          _buildRaceControlFilterBar(context),
          const SizedBox(height: 12),
          Text(
            context.l10n.race_control_message_count(
              '${visibleMessages.length}',
              '${filteredMessages.length}',
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (filteredMessages.isEmpty)
            Text(
              context.l10n.race_control_empty,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Column(
              children: visibleMessages
                  .map((message) {
                    final tokens = _themeTokens(context);
                    final messageStyle = _raceControlMessageStyle(
                      message['message']?.toString(),
                      tokens,
                    );
                    final relatedMessages = _relatedRaceControlMessages(
                      messages,
                      selectedSession,
                      message,
                    );
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showRaceControlMessageDetails(
                          context,
                          messages,
                          selectedSession,
                          message,
                        ),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: messageStyle?.background ??
                                      tokens.panelStrong,
                                  borderRadius: BorderRadius.circular(20),
                                  border: messageStyle == null
                                      ? Border.all(
                                          color: tokens.outline
                                              .withValues(alpha: 0.6),
                                        )
                                      : null,
                                ),
                                child: _buildRaceControlMessageContent(
                                  context,
                                  message,
                                  theme,
                                  tokens,
                                  messageStyle,
                                  relatedMessages,
                                ),
                              ),
                              if (messageStyle != null)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: FadingBorderPainter(
                                        color: _hubReadableAccent(context),
                                        borderRadius: 20,
                                        borderWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          if (filteredMessages.length > _defaultRaceControlVisibleCount) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllRaceControlMessages =
                        !_showAllRaceControlMessages;
                  });
                },
                icon: Icon(
                  _showAllRaceControlMessages
                      ? Icons.unfold_less
                      : Icons.unfold_more,
                ),
                label: Text(
                  _showAllRaceControlMessages
                      ? context.l10n.show_less_messages
                      : context.l10n.show_all_messages('${filteredMessages.length}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _raceControlMessageSortMillis(Map<String, dynamic> m) {
    final d = DateTime.tryParse(m['timestampUtc']?.toString() ?? '');
    return d?.millisecondsSinceEpoch ?? 0;
  }

  Color _raceControlBroadcastBarColor(
    Map<String, dynamic> message,
    F1ThemeTokens tokens,
    ThemeData theme,
  ) {
    final style = _raceControlMessageStyle(
      message['message']?.toString(),
      tokens,
    );
    if (style != null) {
      return style.border;
    }
    final flagTint = _raceControlFlagColor(
      message['flag']?.toString(),
      tokens,
      theme.colorScheme,
    );
    return flagTint ?? theme.colorScheme.outline.withValues(alpha: 0.5);
  }

  Widget _buildBroadcastRaceControlRow(
    BuildContext context,
    Map<String, dynamic> message,
    List<Map<String, dynamic>> allSessionMessages,
    String selectedSession,
    F1ThemeTokens tokens,
    ThemeData theme, {
    bool inStoryline = false,
  }) {
    final scheme = theme.colorScheme;
    final raw = message['message']?.toString() ?? '-';
    final barColor = _raceControlBroadcastBarColor(message, tokens, theme);
    // Rows render on the light module background; only the strip is green/orange/red.
    // messageStyle.text is for text *on* those fill colors (often near-white) and is
    // unreadable on white — always use on-surface for the message body.
    final textColor = scheme.onSurface;
    final linkedToOthers = _relatedRaceControlMessages(
      allSessionMessages,
      selectedSession,
      message,
    ).isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showRaceControlMessageDetails(
          context,
          allSessionMessages,
          selectedSession,
          message,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: inStoryline ? 4 : 0,
            top: 8,
            bottom: 8,
            right: 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatRaceControlBroadcastClock(
                        message['timestampUtc']?.toString(),
                      ),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (linkedToOthers) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.link_sharp,
                        size: 14,
                        // primary can be very light in some team themes → invisible on white
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 40),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.65),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _buildRaceControlBroadcastRichText(
                    raw,
                    textColor,
                    14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekendHubBroadcastStorylineBlock(
    BuildContext context,
    List<Map<String, dynamic>> group,
    List<Map<String, dynamic>> allSessionMessages,
    String selectedSession,
    F1ThemeTokens tokens,
    ThemeData theme,
  ) {
    if (group.length == 1) {
      return _buildBroadcastRaceControlRow(
        context,
        group.single,
        allSessionMessages,
        selectedSession,
        tokens,
        theme,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: tokens.panelStrong.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subtitles_outlined,
                size: 18,
                color: _hubReadableAccent(context),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.race_control_steward_storyline,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...group.map(
            (m) => _buildBroadcastRaceControlRow(
              context,
              m,
              allSessionMessages,
              selectedSession,
              tokens,
              theme,
              inStoryline: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendHubBroadcastRaceControlSection(
    BuildContext context,
    List<Map<String, dynamic>> messages,
    String selectedSession,
    List<String> availableScopes,
    String selectedScope,
    List<Map<String, dynamic>> filteredMessages,
  ) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    final trackLimitMsgs = filteredMessages
        .where(
          (m) => _isRaceControlTrackLimitDeletionMessage(
            m['message']?.toString(),
          ),
        )
        .toList(growable: false)
      ..sort(
        (a, b) => _raceControlMessageSortMillis(a).compareTo(
          _raceControlMessageSortMillis(b),
        ),
      );

    final mainMsgs = filteredMessages
        .where(
          (m) => !_isRaceControlTrackLimitDeletionMessage(
            m['message']?.toString(),
          ),
        )
        .toList(growable: false)
      ..sort(
        (a, b) => _raceControlMessageSortMillis(a).compareTo(
          _raceControlMessageSortMillis(b),
        ),
      );

    final visibleMain = _showAllRaceControlMessages
        ? mainMsgs
        : mainMsgs.take(_defaultRaceControlVisibleCount).toList(growable: false);

    final storylineGroups = _groupBroadcastStorylineMessages(visibleMain);

    return _weekendHubCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCardTitle(context, context.l10n.race_control),
          const SizedBox(height: 12),
          TextField(
            controller: _raceControlSearchController,
            onChanged: (value) {
              setState(() {
                _raceControlSearchQuery = value;
                _showAllRaceControlMessages = false;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.l10n.race_control_search_hint,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.scope,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildRaceControlScopeChips(
            context,
            availableScopes,
            selectedScope,
          ),
          const SizedBox(height: 12),
          _buildRaceControlFilterBar(context),
          const SizedBox(height: 12),
          Text(
            context.l10n.race_control_message_count(
              '${visibleMain.length}',
              '${filteredMessages.length}',
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (trackLimitMsgs.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.9,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.race_control_track_limits_strip,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trackLimitMsgs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final m = trackLimitMsgs[i];
                  final msg = m['message']?.toString() ?? '-';
                  return SizedBox(
                    width: 260,
                    child: Material(
                      color: tokens.panel.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showRaceControlMessageDetails(
                          context,
                          messages,
                          selectedSession,
                          m,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatRaceControlBroadcastClock(
                                  m['timestampUtc']?.toString(),
                                ),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontFeatures: const [
                                    ui.FontFeature.tabularFigures(),
                                  ],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _hubReadableAccent(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  msg,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (filteredMessages.isEmpty)
            Text(
              _selectedRaceControlQuickFilter == _rcFilterPenalties
                  ? context.l10n.weekend_hub_penalties_filter_empty
                  : context.l10n.race_control_empty,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          else if (mainMsgs.isEmpty)
            const SizedBox.shrink()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: storylineGroups
                  .map(
                    (g) => _buildWeekendHubBroadcastStorylineBlock(
                      context,
                      g,
                      messages,
                      selectedSession,
                      tokens,
                      theme,
                    ),
                  )
                  .toList(growable: false),
            ),
          if (mainMsgs.length > _defaultRaceControlVisibleCount) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAllRaceControlMessages =
                        !_showAllRaceControlMessages;
                  });
                },
                icon: Icon(
                  _showAllRaceControlMessages
                      ? Icons.unfold_less
                      : Icons.unfold_more,
                ),
                label: Text(
                  _showAllRaceControlMessages
                      ? context.l10n.show_less_messages
                      : context.l10n.show_all_messages('${mainMsgs.length}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRaceControlMessageContent(
    BuildContext context,
    Map<String, dynamic> message,
    ThemeData theme,
    F1ThemeTokens tokens,
    ({Color background, Color border, Color text})? messageStyle,
    List<Map<String, dynamic>> relatedMessages,
  ) {
    final bg = messageStyle?.background ?? tokens.panelStrong;
    final textColor = messageStyle != null
        ? F1ThemeTokens.textOnBackground(bg)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRaceControlTag(
              context,
              Icons.schedule,
              _normalizeSessionName(message['sessionName']) == ''
                  ? context.l10n.unknown
                  : _normalizeSessionName(message['sessionName']),
              forceTextColor: textColor,
            ),
            if ((message['scope']?.toString() ?? '').trim().isNotEmpty)
              _buildRaceControlTag(
                context,
                Icons.center_focus_strong,
                message['scope']!.toString(),
                forceTextColor: textColor,
              ),
            if ((message['flag']?.toString() ?? '').trim().isNotEmpty)
              _buildRaceControlTag(
                context,
                Icons.flag,
                message['flag']!.toString(),
                accentColor: textColor == null
                    ? _raceControlFlagColor(
                        message['flag']?.toString(),
                        tokens,
                        theme.colorScheme,
                      )
                    : null,
                forceTextColor: textColor,
              ),
            if (message['lap'] != null)
              _buildRaceControlTag(
                context,
                Icons.looks_one,
                context.l10n.lap_label('${message['lap']}'),
                forceTextColor: textColor,
              ),
            if (message['driverNumber'] != null)
              _buildRaceControlTag(
                context,
                Icons.directions_car,
                context.l10n.car_label('${message['driverNumber']}'),
                forceTextColor: textColor,
              ),
            if (relatedMessages.isNotEmpty)
              _buildRaceControlTag(
                context,
                Icons.link,
                relatedMessages.length == 1
                    ? context.l10n.linked_update_one
                    : context.l10n.linked_update_many('${relatedMessages.length}'),
                forceTextColor: textColor,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          message['message']?.toString() ?? '-',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatRaceControlTimestamp(
            context,
            message['timestampUtc']?.toString(),
          ),
          style: TextStyle(
            fontSize: 12,
            color: textColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRaceControlTag(
    BuildContext context,
    IconData icon,
    String label, {
    Color? accentColor,
    Color? forceTextColor,
  }) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final effectiveColor = forceTextColor ??
        (accentColor ?? theme.colorScheme.onSurfaceVariant);
    final tagBg = forceTextColor != null
        ? effectiveColor.withValues(alpha: 0.2)
        : (accentColor == null
            ? tokens.panel
            : accentColor.withValues(alpha: 0.14));
    final tagBorder = forceTextColor != null
        ? effectiveColor.withValues(alpha: 0.4)
        : (accentColor == null
            ? tokens.outline.withValues(alpha: 0.55)
            : accentColor.withValues(alpha: 0.34));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tagBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHubAssets = _hubSessionStems.isNotEmpty;
    final selectedStem = hasHubAssets
        ? (_hubSessionStems.contains(_selectedSessionStem)
              ? _selectedSessionStem
              : _hubSessionStems.last)
        : '';
    final uiSessionName =
        selectedStem.isEmpty ? 'Race' : _hubStemToUiSessionName(selectedStem);

    final List<Map<String, dynamic>> selectedWeather;
    final List<Map<String, dynamic>> selectedLapTimeline;
    final List<Map<String, dynamic>> raceControlMessages;
    final List<WeekendHubPodiumEntry> headerTopThree;

    if (hasHubAssets) {
      selectedWeather = _hubWeatherByStem[selectedStem] ?? const [];
      selectedLapTimeline = _hubLapTimelineByStem[selectedStem] ?? const [];
      raceControlMessages = _hubRaceControlByStem[selectedStem] ?? const [];
      headerTopThree = _hubPodiumByStem[selectedStem] ?? const [];
    } else {
      selectedWeather = const [];
      selectedLapTimeline = const [];
      raceControlMessages = const [];
      headerTopThree = const [];
    }

    final scheme = theme.colorScheme;
    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _loading
                ? Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: safeTop + 24),
                        child: Text(
                          context.l10n.weekend_hub_loading,
                          textAlign: TextAlign.center,
                          style: HubVisualLanguage.titilliumSecondary(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                            opacity: 0.95,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: HubGlassPageLoadingPlaceholder(),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _loadWeekendData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        _buildWeekendHubBackRow(context, safeTop: safeTop),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey<String>(
                              hasHubAssets
                                  ? 'weekend_hub_full_${widget.race.country}_${widget.race.date.toIso8601String()}'
                                  : 'weekend_hub_minimal_${widget.race.country}_${widget.race.date.toIso8601String()}',
                            ),
                            child: hasHubAssets
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildWeekendHubHeader(
                                        context,
                                        hasHubAssets: true,
                                        sessionStems: _hubSessionStems,
                                        selectedStem: selectedStem,
                                        headerTopThree: headerTopThree,
                                      ),
                                      const SizedBox(height: 24),
                                      _buildWeekendHubLowerRow(
                                        context,
                                        uiSessionName,
                                        selectedWeather,
                                        selectedLapTimeline,
                                        raceControlMessages,
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildWeekendHubHeader(
                                        context,
                                        hasHubAssets: false,
                                        sessionStems: const [],
                                        selectedStem: '',
                                        headerTopThree: const [],
                                      ),
                                    ],
                                  ),
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

  Widget _buildWeekendHubBackRow(
    BuildContext context, {
    required double safeTop,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: safeTop + 32,
        bottom: 20,
        left: 0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(_calendarPath()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.weekend_hub_back_to_calendar,
                  style: GoogleFonts.titilliumWeb(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: scheme.onSurface.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _weekendHubTopAccentColor(Color primary) {
    if (primary.computeLuminance() < 0.08) {
      return HubVisualLanguage.f1DefaultAccent;
    }
    return primary;
  }

  List<String> _weekendHubCircuitAssetPaths() {
    final id = widget.race.circuitAssetId.trim();
    if (id.isEmpty) return const [];
    return [
      'assets/images/circuits/$id.png',
      'assets/images/circuits/$id.webp',
      'assets/data/images/circuits/$id.png',
    ];
  }

  Widget _buildWeekendHubStatCell(
    BuildContext context, {
    required Color accent,
    required String value,
    required String caption,
    bool emphasize = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = emphasize
        ? accent.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ConstructorHubColors.surfaceElevated.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: emphasize ? 1 : 0.85),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 22,
                height: 1.05,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              caption.toUpperCase(),
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.05,
                color: ConstructorHubColors.textSecondary,
                opacity: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekendHubWeatherMiniTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: _hubFlatHubCardDecoration(context, radius: 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: HubVisualLanguage.titilliumSecondary(
                      context,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubVisualLanguage.f1Wide(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekendHubLivePreviewBlock(
    BuildContext context,
    List<WeekendHubPodiumEntry> podium,
  ) {
    if (podium.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: _hubFlatHubCardDecoration(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.weekend_hub_live_preview.toUpperCase(),
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.05,
                color: scheme.onSurface,
                opacity: 0.75,
              ),
            ),
            const SizedBox(height: 10),
            ...podium.map((e) {
              final driverLabel = e.driverNumber == null
                  ? e.driver
                  : '#${e.driverNumber} ${e.driver}';
              final compound =
                  _weekendHubTireCompoundFromAbbrev(e.bestLapTyreAbbrev);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        'P${e.position}',
                        style: HubVisualLanguage.f1Wide(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        driverLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          opacity: 1,
                        ),
                      ),
                    ),
                    if (compound != null) ...[
                      const SizedBox(width: 8),
                      F1TireBadge(compound: compound, size: 20),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekendHubSessionStemPillRow(
    BuildContext context, {
    required List<String> sessionStems,
    required String selectedStem,
  }) {
    if (sessionStems.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.session.toUpperCase(),
          style: HubVisualLanguage.titilliumSecondary(
            context,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.05,
            color: scheme.onSurfaceVariant,
            opacity: 1,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                for (final stem in sessionStems)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          setState(() {
                            _selectedSessionStem = stem;
                            _showAllRaceControlMessages = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: stem == selectedStem
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border.all(
                              color: stem == selectedStem
                                  ? scheme.primary.withValues(alpha: 0.42)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            _hubStemDisplayTitle(context, stem),
                            style: GoogleFonts.titilliumWeb(
                              fontSize: 12,
                              fontWeight: stem == selectedStem
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekendHubHeroPrimaryActions(
    BuildContext context, {
    required bool showResultsCta,
    required VoidCallback? onOpenResults,
  }) {
    final scheme = Theme.of(context).colorScheme;
    Widget ctaShell({required Widget child}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: child,
      );
    }

    final live = HubInteractiveGlass(
      borderRadius: 16,
      onTap: () => context.push(_livePath()),
      child: ctaShell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 20,
              color: scheme.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.live_timing_title,
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                opacity: 1,
              ),
            ),
          ],
        ),
      ),
    );

    final results = showResultsCta && onOpenResults != null
        ? HubInteractiveGlass(
            borderRadius: 16,
            onTap: onOpenResults,
            child: ctaShell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    size: 20,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      context.l10n.weekend_hub_view_full_results,
                      textAlign: TextAlign.center,
                      style: HubVisualLanguage.titilliumSecondary(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        opacity: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;

    return LayoutBuilder(
      builder: (context, c) {
        final stack = c.maxWidth < _weekendHubMobileBreak;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              live,
              if (results != null) ...[
                const SizedBox(height: 10),
                results,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: live),
            if (results != null) ...[
              const SizedBox(width: 12),
              Expanded(child: results),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWeekendHubSpotPlaceholderCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = _themeTokens(context);
    return _weekendHubCard(
      context,
      padding: const EdgeInsets.all(18),
      fillWidth: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, color: scheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.weekend_hub_spot_placeholder_title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.weekend_hub_spot_placeholder_body,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.panel.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.podcasts_outlined,
                  color: scheme.primary.withValues(alpha: 0.45),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.cloud_outlined,
                  color: scheme.primary.withValues(alpha: 0.35),
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendHubLowerRow(
    BuildContext context,
    String selectedSession,
    List<Map<String, dynamic>> sessionWeather,
    List<Map<String, dynamic>> sessionLapTimeline,
    List<Map<String, dynamic>> raceControlMessages,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final race = _buildRaceOverviewCard(
          context,
          selectedSession,
          sessionWeather,
          sessionLapTimeline,
          raceControlMessages,
          includeSectionTitle: false,
        );
        final raceControl = _buildRaceControlSection(
          context,
          raceControlMessages,
          selectedSession,
          broadcastLayout: true,
        );
        final hubSpot = _buildWeekendHubSpotPlaceholderCard(context);
        // Align with top row: Circuit flex 6 vs Top3+Schedule flex 5+6 (→ 6 : 11).
        const lowerTrackFlex = 6;
        const lowerRaceControlFlex = 11;

        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: lowerTrackFlex, child: race),
              const SizedBox(width: 24),
              Expanded(flex: lowerRaceControlFlex, child: raceControl),
              if (_kWeekendHubShowLiveRadarDrCard) ...[
                const SizedBox(width: 24),
                Expanded(flex: 6, child: hubSpot),
              ],
            ],
          );
        }

        if (constraints.maxWidth >= _weekendHubMobileBreak) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: lowerTrackFlex, child: race),
                  const SizedBox(width: 24),
                  Expanded(flex: lowerRaceControlFlex, child: raceControl),
                ],
              ),
              if (_kWeekendHubShowLiveRadarDrCard) ...[
                const SizedBox(height: 24),
                hubSpot,
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            race,
            const SizedBox(height: 24),
            raceControl,
            if (_kWeekendHubShowLiveRadarDrCard) ...[
              const SizedBox(height: 24),
              hubSpot,
            ],
          ],
        );
      },
    );
  }

  Widget _buildWeekendScheduleCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _weekendHubTopAccentColor(scheme.primary);
    final schedule = _sessionSchedule();
    final now = DateTime.now();
    int? activeOrNextIndex;
    for (var i = 0; i < schedule.length; i++) {
      if (_sessionStatus(schedule[i].value) == 'session_status_live_recent') {
        activeOrNextIndex = i;
        break;
      }
    }
    if (activeOrNextIndex == null) {
      for (var i = 0; i < schedule.length; i++) {
        if (schedule[i].value.isAfter(now)) {
          activeOrNextIndex = i;
          break;
        }
      }
    }

    Widget buildSessionTile(int index, MapEntry<String, DateTime> entry) {
      final status = _sessionStatus(entry.value);
      final canOpenResults = status == 'session_status_completed';
      final statusColor = canOpenResults
          ? scheme.primary
          : entry.value.isAfter(now)
              ? scheme.primary
              : scheme.secondary;
      final isActiveOrNext = index == activeOrNextIndex;
      final hubLight = Theme.of(context).brightness == Brightness.light;
      final borderColor = isActiveOrNext
          ? accent.withValues(alpha: 0.3)
          : hubLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.1);

      final core = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canOpenResults
                    ? () => _openSingleSessionResults(entry.key)
                    : null,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        entry.key == 'Race'
                            ? Icons.flag_outlined
                            : entry.key.contains('Qualifying')
                                ? Icons.timer_outlined
                                : Icons.schedule_outlined,
                        size: 18,
                        color: statusColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _sessionDisplayTitle(context, entry.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HubVisualLanguage.titilliumSecondary(
                                context,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                opacity: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sessionTimeLabel(entry.value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HubVisualLanguage.f1Wide(
                                context,
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
                ),
              ),
            ),
            if (canOpenResults)
              HubInteractiveGlass(
                borderRadius: 10,
                onTap: () => _openSingleSessionResults(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    context.l10n.results,
                    style: HubVisualLanguage.titilliumSecondary(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: scheme.primary,
                      opacity: 1,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  l10nSessionStatusLabel(context.l10n, status),
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      );

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isActiveOrNext ? 2 : 0.85),
          boxShadow: isActiveOrNext
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: core,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 900;
        final tiles = <Widget>[
          for (var i = 0; i < schedule.length; i++)
            buildSessionTile(i, schedule[i]),
        ];

        final timeline = horizontal
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in tiles)
                      SizedBox(
                        width: 178,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: t,
                        ),
                      ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tiles,
              );

        return DecoratedBox(
          decoration: _hubFlatHubCardDecoration(context, radius: 18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.weekend_schedule.toUpperCase(),
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.05,
                    color: scheme.onSurface,
                    opacity: 0.75,
                  ),
                ),
                const SizedBox(height: 12),
                timeline,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRaceOverviewCard(
    BuildContext context,
    String selectedSession,
    List<Map<String, dynamic>> sessionWeather,
    List<Map<String, dynamic>> sessionLapTimeline,
    List<Map<String, dynamic>> raceControlMessages, {
    bool includeSectionTitle = true,
  }) {
    final theme = Theme.of(context);

    if (sessionWeather.isNotEmpty) {
      final trackPlayback = _weekendHubCard(
        context,
        padding: const EdgeInsets.all(18),
        fillWidth: true,
        child: CircuitWeatherPlaybackCard(
          race: widget.race,
          sessionName: selectedSession,
          weatherSamples: sessionWeather,
          lapTimeline: sessionLapTimeline,
          raceControlMessages: raceControlMessages,
          embedInCard: false,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (includeSectionTitle) ...[
            _buildSectionCardTitle(
              context,
              _sessionDisplayTitle(context, selectedSession),
            ),
            const SizedBox(height: 14),
          ],
          trackPlayback,
          if (_loadError != null) ...[
            const SizedBox(height: 12),
            Text(
              _loadError!,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      );
    }

    return _weekendHubCard(
      context,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCardTitle(
            context,
            _sessionDisplayTitle(context, selectedSession),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.weekend_hub_no_weather_data,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 12),
            Text(
              _loadError!,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

Widget _buildPenaltiesCard(
  BuildContext context,
  List<RaceResultRow> penalties,
) {
  // Verzamel alle penalty entries met reden en timestamp
  final penaltyEntries = <Map<String, dynamic>>[];
  for (final row in penalties) {
    for (final detail in row.penaltyDetails) {
      penaltyEntries.add({
        'driver': row.driver,
        'penalty': detail['penalty'] ?? row.penalty,
        'reason': detail['reason'],
        'issuedLap': detail['issuedLap'],
        'timestamp': _findPenaltyTimestamp(row, detail),
      });
    }
  }
  // Sorteer op timestamp (oudste onderaan, nieuwste bovenaan)
  penaltyEntries.sort((a, b) {
    final aTime = a['timestamp'] as DateTime?;
    final bTime = b['timestamp'] as DateTime?;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime); // nieuwste bovenaan
  });

  final theme = Theme.of(context);
  final tokens = _themeTokens(context);

  return _weekendHubCard(
    context,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCardTitle(context, 'Penalties'),
        const SizedBox(height: 12),
        if (penaltyEntries.isEmpty)
          Text(
            'Geen penalties gevonden in de huidige weekend cache.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Column(
            children: penaltyEntries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: tokens.statusWarning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry['driver']}: ${entry['penalty']}',
                                style: TextStyle(color: theme.colorScheme.onSurface),
                              ),
                              if (entry['reason'] != null && (entry['reason'] as String).trim().isNotEmpty)
                                Text(
                                  'Reden: ${entry['reason']}',
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            ),
        ],
      ),
    );
}

// Zoek timestamp van penalty detail via raceControlMessages
DateTime? _findPenaltyTimestamp(RaceResultRow row, Map<String, dynamic> detail) {
  // Zoek naar een raceControlMessage die overeenkomt met penalty en reden
  for (final msg in row.raceControlMessages) {
    final message = (msg['message'] ?? '').toString().toUpperCase();
    final penalty = (detail['penalty'] ?? '').toString().replaceAll(' ', '').toUpperCase();
    final reason = (detail['reason'] ?? '').toString().toUpperCase();
    if (message.contains(penalty) && (reason.isEmpty || message.contains(reason))) {
      final ts = msg['timestampUtc']?.toString();
      if (ts != null && ts.isNotEmpty) {
        final dt = DateTime.tryParse(ts);
        if (dt != null) return dt;
      }
    }
  }
  return null;
}

  Widget _buildHubMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _themeTokens(context).panelStrong,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(context.l10n.metric_label_value(label, value)),
        ],
      ),
    );
  }

  Widget _buildWeekendHubHeader(
    BuildContext context, {
    required bool hasHubAssets,
    required List<String> sessionStems,
    required String selectedStem,
    required List<WeekendHubPodiumEntry> headerTopThree,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final narrowMobile = w < _weekendHubMobileBreak;
        final isWide = !narrowMobile && w >= 860;
        final isThreeColumn = !narrowMobile && w >= 1180;
        final summary = _buildWeekendHubSummaryCard(
          context,
          hasHubAssets: hasHubAssets,
          sessionStems: sessionStems,
          selectedStem: selectedStem,
          headerTopThree: headerTopThree,
        );
        final summaryColumn = summary;
        final matchPodiumToSiblingCardHeight =
            hasHubAssets && (isThreeColumn || isWide);
        final podium = hasHubAssets
            ? _buildWeekendHubTopThreeCard(
                context,
                headerTopThree,
                _hubStemDisplayTitle(context, selectedStem),
                matchSiblingCardHeight: matchPodiumToSiblingCardHeight,
              )
            : const SizedBox.shrink();
        final schedule = _buildWeekendScheduleCard(context);

        if (isThreeColumn) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: summaryColumn),
                if (hasHubAssets) ...[
                  const SizedBox(width: 24),
                  Expanded(flex: 5, child: podium),
                ],
                const SizedBox(width: 24),
                Expanded(flex: 6, child: schedule),
              ],
            ),
          );
        }

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 6, child: summaryColumn),
                    if (hasHubAssets) ...[
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: podium),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              schedule,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            summary,
            if (hasHubAssets) ...[
              const SizedBox(height: 24),
              podium,
            ],
            const SizedBox(height: 24),
            schedule,
          ],
        );
      },
    );
  }

  Widget _buildWeekendHubSummaryCard(
    BuildContext context, {
    required bool hasHubAssets,
    required List<String> sessionStems,
    required String selectedStem,
    required List<WeekendHubPodiumEntry> headerTopThree,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _weekendHubTopAccentColor(scheme.primary);
    final localeName = Localizations.localeOf(context).toString();
    final dateLine = DateFormat.yMMMd(localeName).add_jm().format(
          widget.race.date.toLocal(),
        );

    final dropdownStem = hasHubAssets && sessionStems.contains(selectedStem)
        ? selectedStem
        : (hasHubAssets && sessionStems.isNotEmpty ? sessionStems.last : '');
    final effectiveStem = dropdownStem.isEmpty && sessionStems.isNotEmpty
        ? sessionStems.first
        : dropdownStem;

    final circuitSvg = widget.race.circuitImage.trim();
    final hasCircuitSvg =
        circuitSvg.startsWith('http://') || circuitSvg.startsWith('https://');

    final lengthKm = widget.race.length > 0
        ? (widget.race.length / 1000).toStringAsFixed(3)
        : '—';
    final lapsStr = widget.race.laps > 0 ? '${widget.race.laps}' : '—';

    final airVal = _temperature == '--' ? '—' : '$_temperature°C';
    final trackVal =
        _trackTempDisplay == '--' ? '—' : '$_trackTempDisplay°C';
    final humVal =
        _humidityDisplay == '--' ? '—' : '$_humidityDisplay%';
    final rainVal = '$_rainChance%';

    final sessionUiName = effectiveStem.isEmpty
        ? 'Race'
        : _hubStemToUiSessionName(effectiveStem);
    final canOpenSessionResults = _hasSessionResults(sessionUiName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrowWeather = constraints.maxWidth < _weekendHubMobileBreak;

        final weatherTiles = <Widget>[
          _buildWeekendHubWeatherMiniTile(
            context,
            label: context.l10n.weekend_hub_weather_air,
            value: airVal,
            icon: Icons.thermostat_outlined,
          ),
          _buildWeekendHubWeatherMiniTile(
            context,
            label: context.l10n.weekend_hub_weather_track,
            value: trackVal,
            icon: Icons.layers_outlined,
          ),
          _buildWeekendHubWeatherMiniTile(
            context,
            label: context.l10n.humidity,
            value: humVal,
            icon: Icons.water_drop_outlined,
          ),
          _buildWeekendHubWeatherMiniTile(
            context,
            label: context.l10n.rain,
            value: rainVal,
            icon: Icons.cloud_outlined,
          ),
        ];

        final weatherGrid = narrowWeather
            ? GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: weatherTiles,
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < weatherTiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: weatherTiles[i]),
                  ],
                ],
              );

        final circuitPaths = _weekendHubCircuitAssetPaths();
        final chainH = 96.0;

        final heroCore = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.race.flag, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.race.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.12,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.race.country,
                        style: HubVisualLanguage.titilliumSecondary(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLine,
                        style: HubVisualLanguage.f1Wide(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (circuitPaths.isNotEmpty || hasCircuitSvg)
                  SizedBox(
                    width: 112,
                    height: chainH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (circuitPaths.isNotEmpty)
                          HubAssetImageChain(
                            paths: circuitPaths,
                            bundle: rootBundle,
                            height: chainH,
                            width: 112,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerRight,
                            borderRadius: 12,
                            glassFallbackAccent: accent,
                          ),
                        if (hasCircuitSvg)
                          IgnorePointer(
                            child: Opacity(
                              opacity: circuitPaths.isNotEmpty ? 0.22 : 0.14,
                              child: SvgPicture.network(
                                circuitSvg,
                                height: chainH,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerRight,
                                colorFilter: ColorFilter.mode(
                                  scheme.onSurface.withValues(alpha: 0.88),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildWeekendHubStatCell(
                    context,
                    accent: accent,
                    value: '$lengthKm km',
                    caption: context.l10n.length,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeekendHubStatCell(
                    context,
                    accent: accent,
                    value: lapsStr,
                    caption: context.l10n.laps,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            weatherGrid,
            if (hasHubAssets && headerTopThree.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWeekendHubLivePreviewBlock(context, headerTopThree),
            ],
            if (hasHubAssets && sessionStems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWeekendHubSessionStemPillRow(
                context,
                sessionStems: sessionStems,
                selectedStem: sessionStems.contains(selectedStem)
                    ? selectedStem
                    : effectiveStem,
              ),
            ],
            const SizedBox(height: 16),
            _buildWeekendHubHeroPrimaryActions(
              context,
              showResultsCta: canOpenSessionResults,
              onOpenResults: canOpenSessionResults
                  ? () => _openSingleSessionResults(sessionUiName)
                  : null,
            ),
            if (!hasHubAssets) ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  context.l10n.weekend_hub_no_results_yet,
                  textAlign: TextAlign.center,
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: 13,
                    color: scheme.onSurface,
                    opacity: 0.52,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        );

        return DecoratedBox(
          decoration: _hubFlatHubCardDecoration(context, radius: 18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: heroCore,
          ),
        );
      },
    );
  }

  Widget _buildWeekendHubTopThreeCard(
    BuildContext context,
    List<WeekendHubPodiumEntry> topThree,
    String sessionTitleForEmpty, {
    bool matchSiblingCardHeight = false,
  }) {
    final theme = Theme.of(context);
    final title = Text(
      context.l10n.top_3,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );

    final Widget body;
    if (topThree.isEmpty) {
      body = matchSiblingCardHeight
          ? Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  context.l10n.session_data_unavailable(sessionTitleForEmpty),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : Text(
              context.l10n.session_data_unavailable(sessionTitleForEmpty),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            );
    } else {
      final driverList = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: topThree
            .map((entry) => _buildTopThreeRow(context, entry))
            .toList(growable: false),
      );
      body = matchSiblingCardHeight
          ? Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: driverList,
              ),
            )
          : driverList;
    }

    // Never use [LayoutBuilder] here: this card sits inside [IntrinsicHeight] on
    // desktop, and LayoutBuilder cannot participate in intrinsic height calc.
    return _weekendHubCard(
      context,
      padding: const EdgeInsets.all(18),
      fillWidth: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize:
            matchSiblingCardHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          title,
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }

  Widget _buildTopThreeRow(BuildContext context, WeekendHubPodiumEntry entry) {

    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final driverLabel = entry.driverNumber == null
        ? entry.driver
        : '#${entry.driverNumber} ${entry.driver}';
    final accent = _topThreeAccent(context, entry.position);
    final timingLabel = entry.position == 1
        ? context.l10n.total_time
        : context.l10n.gap;
    final timingValue = entry.position == 1
        ? entry.totalTime
        : entry.gapToLeader;
    final tyreCompound =
        _weekendHubTireCompoundFromAbbrev(entry.bestLapTyreAbbrev);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.panel.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
                child: Text(
                  'P${entry.position}',
                  style: HubVisualLanguage.f1Wide(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driverLabel,
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    opacity: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tyreCompound != null) ...[
                const SizedBox(width: 8),
                F1TireBadge(compound: tyreCompound, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTopThreeFact(context, timingLabel, timingValue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTopThreeFact(
                  context,
                  context.l10n.best_lap,
                  entry.fastestLap,
                  highlight: entry.hasFastestLap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopThreeFact(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlight
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _topThreeAccent(BuildContext context, int position) {
    final scheme = Theme.of(context).colorScheme;
    switch (position) {
      case 1:
        return scheme.tertiary;
      case 2:
        return scheme.outline;
      case 3:
        return scheme.secondary;
      default:
        return scheme.primary;
    }
  }

  Widget _buildSectionCardTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class AIAssistantSheet extends StatefulWidget {
  const AIAssistantSheet({super.key});

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  bool _isWorking = false;
  String? _actionLabel;
  VoidCallback? _action;

  String _normalizeAssistantText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  int _assistantMatchScore(String query, String candidate) {
    final normalizedQuery = _normalizeAssistantText(query);
    final normalizedCandidate = _normalizeAssistantText(candidate);
    if (normalizedQuery.isEmpty || normalizedCandidate.isEmpty) {
      return -1;
    }
    if (normalizedQuery == normalizedCandidate) {
      return 1000;
    }
    if (normalizedCandidate.startsWith(normalizedQuery)) {
      return 800;
    }
    if (normalizedCandidate.contains(normalizedQuery)) {
      return 700;
    }

    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final candidateTokens = normalizedCandidate
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();
    if (queryTokens.isEmpty) {
      return -1;
    }

    final matchedTokens = queryTokens
        .where(
          (token) => candidateTokens.any(
            (candidateToken) =>
                candidateToken == token || candidateToken.startsWith(token),
          ),
        )
        .length;
    if (matchedTokens == 0) {
      return -1;
    }
    return matchedTokens * 100;
  }

  List<Driver> _knownDrivers() {
    final seenNames = <String>{};
    final drivers = <Driver>[];
    for (final seasonDrivers in driversData.values) {
      for (final driver in seasonDrivers) {
        if (seenNames.add(driver.name)) {
          drivers.add(driver);
        }
      }
    }
    for (final driver in drivers2026) {
      if (seenNames.add(driver.name)) {
        drivers.add(driver);
      }
    }
    return drivers;
  }

  Driver? _matchDriver(String query) {
    Driver? bestMatch;
    var bestScore = -1;
    for (final driver in _knownDrivers()) {
      final score = math.max(
        _assistantMatchScore(query, driver.name),
        _assistantMatchScore(query, driver.name.split(' ').last),
      );
      if (score > bestScore) {
        bestScore = score;
        bestMatch = driver;
      }
    }
    return bestScore >= 100 ? bestMatch : null;
  }

  Team? _matchTeam(String query) {
    Team? bestMatch;
    var bestScore = -1;
    for (final team in fallbackTeams) {
      final score = _assistantMatchScore(query, team.name);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = team;
      }
    }
    return bestScore >= 100 ? bestMatch : null;
  }

  Race? _matchRace(String query) {
    Race? bestMatch;
    var bestScore = -1;
    for (final race in races) {
      final candidate = '${race.name} ${race.country}';
      final score = _assistantMatchScore(query, candidate);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = race;
      }
    }
    return bestScore >= 100 ? bestMatch : null;
  }

  int _latestKnownSeasonYear() {
    if (driversData.isEmpty) {
      return DateTime.now().year;
    }
    return driversData.keys.reduce(
      (left, right) => left > right ? left : right,
    );
  }

  String _formatAiPoints(num value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String _removeLeadingAssistantVerb(String prompt) {
    return prompt
        .replaceFirst(
          RegExp(
            r'^(show|open|find|tell me|give me|laat|toon|open|vind)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runPrompt([String? value]) async {

    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final prompt = (value ?? _controller.text).trim();
    if (prompt.isEmpty) {
      return;
    }

    setState(() {
      _isWorking = true;
      _action = null;
      _actionLabel = null;
    });

    try {
      final lower = prompt.toLowerCase();

      if (lower.contains('fetch latest results') ||
          lower.contains('latest results') ||
          lower.contains('haal laatste resultaten')) {
        final latestRace = await _findLatestCompletedRace();
        if (latestRace == null) {
          _response = context.l10n.ai_no_completed_race;
        } else {
          await RaceRepository.standard().forceRefreshLatestResults();
          final roundIndex = raceRoundFor(latestRace);
          await SessionDataManager().fetchDataForRace(latestRace, roundIndex);
          final rows =
              SessionDataManager().raceResultsCache[SessionDataManager()
                  .raceResultsKeyFor(latestRace)] ??
              const <RaceResultRow>[];
          final topThree = rows.take(3).map((row) => row.driver).join(' • ');
          _response = topThree.isEmpty
              ? context.l10n.ai_latest_results_refreshed
              : context.l10n.ai_latest_results_podium(topThree);
          _actionLabel = context.l10n.ai_open_latest_results;
          _action = () {
            navigator.pop();
            Future<void>.delayed(const Duration(milliseconds: 150), () {
              router.push(_raceResultsPath(latestRace));
            });
          };
        }
      } else if (lower.contains('next weekend') ||
          lower.contains('show next weekend') ||
          lower.contains('weekend hub')) {
        final nextRace = nextRaceAfterNowSkippingCancelled(races);
        _response = context.l10n.ai_next_weekend(
          nextRace.name,
          '${nextRace.date.day}-${nextRace.date.month}-${nextRace.date.year}',
        );
        _actionLabel = context.l10n.ai_open_weekend_hub;
        _action = () {
          navigator.pop();
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            router.push(_weekendHubPath(nextRace));
          });
        };
      } else if ((lower.contains('compare') || lower.contains('vergelijk')) &&
          (lower.contains(' vs ') || lower.contains(' tegen '))) {
        final parts = prompt.split(
          RegExp(r'\bvs\b|\btegen\b', caseSensitive: false),
        );
        if (parts.length < 2) {
          _response = context.l10n.ai_compare_parse_error;
        } else {
          final left = parts.first
              .replaceAll(
                RegExp(r'compare|vergelijk', caseSensitive: false),
                '',
              )
              .trim();
          final right = parts.last.trim();
          final drivers = {
            for (final driver in drivers2026) driver.name.toLowerCase(): driver,
          };
          final teams = {
            for (final team in fallbackTeams) team.name.toLowerCase(): team,
          };

          Driver? driver1;
          Driver? driver2;
          Team? team1;
          Team? team2;

          for (final driver in drivers.values) {
            if (driver1 == null &&
                driver.name.toLowerCase().contains(left.toLowerCase())) {
              driver1 = driver;
            }
            if (driver2 == null &&
                driver.name.toLowerCase().contains(right.toLowerCase())) {
              driver2 = driver;
            }
          }

          for (final team in teams.values) {
            if (team1 == null &&
                team.name.toLowerCase().contains(left.toLowerCase())) {
              team1 = team;
            }
            if (team2 == null &&
                team.name.toLowerCase().contains(right.toLowerCase())) {
              team2 = team;
            }
          }

          if (driver1 != null && driver2 != null) {
            _response = context.l10n.ai_driver_compare_ready(
              driver1.name,
              driver2.name,
            );
            _actionLabel = context.l10n.ai_open_driver_compare;
            _action = () {
              navigator.pop();
              Future<void>.delayed(const Duration(milliseconds: 150), () {
                router.push(_driverComparePath(driver1!, driver2!));
              });
            };
          } else if (team1 != null && team2 != null) {
            _response = context.l10n.ai_team_compare_ready(
              team1.name,
              team2.name,
            );
            _actionLabel = context.l10n.ai_open_team_compare;
            _action = () {
              navigator.pop();
              Future<void>.delayed(const Duration(milliseconds: 150), () {
                router.push(_teamComparePath(team1!, team2!));
              });
            };
          } else {
            _response = context.l10n.ai_compare_no_match;
          }
        }
      } else if (lower.contains('form') || lower.contains('trend')) {
        Driver? target;
        for (final driver in _knownDrivers()) {
          if (lower.contains(driver.name.toLowerCase()) ||
              lower.contains(driver.name.split(' ').last.toLowerCase())) {
            target = driver;
            break;
          }
        }

        if (target == null) {
          _response = context.l10n.ai_form_no_driver;
        } else {
          final entries = _buildDriverRecentFormEntries(target.name);
          if (entries.isEmpty) {
            _response = context.l10n.ai_form_no_cache(target.name);
          } else {
            final summary = entries.expand((e) => e)
                .map(
                  (entry) =>
                      '${entry.race.name.replaceAll(' Grand Prix', '')}: ${entry.label}',
                )
                .join(' • ');
            _response = context.l10n.ai_form_summary(target.name, summary);
          }
        }
      } else if ((lower.contains('driver standings') ||
              lower.contains('coureurstand') ||
              lower.contains('driver stand') ||
              lower == 'standings' ||
              lower == 'show standings') &&
          !lower.contains('team') &&
          !lower.contains('constructor')) {
        final year = _latestKnownSeasonYear();
        final standings = List<Driver>.from(driversData[year] ?? drivers2026)
          ..sort((left, right) => right.points.compareTo(left.points));
        final summary = standings
            .take(3)
            .map(
              (driver) =>
                  '${driver.name} ${_formatAiPoints(driver.points)} pts',
            )
            .join(' • ');
        _response = context.l10n.ai_driver_standings_summary('$year', summary);
        _actionLabel = context.l10n.ai_open_driver_standings;
        _action = () {
          navigator.pop();
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            router.push(_driversPath());
          });
        };
      } else if (lower.contains('team standings') ||
          lower.contains('constructor standings') ||
          lower.contains('constructors standings') ||
          lower.contains('team stand') ||
          lower.contains('constructor stand')) {
        final year = _latestKnownSeasonYear();
        final standings = List<Team>.from(fallbackTeams)
          ..sort((left, right) => right.points.compareTo(left.points));
        final summary = standings
            .take(3)
            .map((team) => '${team.name} ${team.points} pts')
            .join(' • ');
        _response = context.l10n.ai_team_standings_summary('$year', summary);
        _actionLabel = context.l10n.ai_open_team_standings;
        _action = () {
          navigator.pop();
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            router.push(_teamsPath());
          });
        };
      } else if ((lower.contains('drivers chart') ||
              lower.contains('driver chart') ||
              lower.contains('coureursgrafiek') ||
              lower.contains('grafiek coureurs')) &&
          !lower.contains('compare')) {
        final year = _latestKnownSeasonYear();
        _response = context.l10n.ai_drivers_chart_ready('$year');
        _actionLabel = context.l10n.ai_open_drivers_chart;
        _action = () {
          navigator.pop();
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (!mounted) {
              return;
            }
            _openDriverStandingsChartSheet(
              context,
              initialYear: year,
              availableYears: List<int>.generate(
                10,
                (index) => DateTime.now().year - index,
              ),
            );
          });
        };
      } else if ((lower.contains('weather') || lower.contains('weer')) &&
          (lower.contains('next weekend') ||
              lower.contains('volgend weekend') ||
              lower.contains('upcoming race'))) {
        final nextRace = nextRaceAfterNowSkippingCancelled(races);
        _response = context.l10n.ai_next_weekend_weather(
          nextRace.name,
          '${nextRace.weather.temperature}',
          '${nextRace.weather.rainChance}',
          '${nextRace.weather.windSpeed}',
        );
        _actionLabel = context.l10n.ai_open_weekend_hub;
        _action = () {
          navigator.pop();
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            router.push(_weekendHubPath(nextRace));
          });
        };
      } else if (lower.contains('penalt') ||
          lower.contains('straf') ||
          lower.contains('penalties')) {
        final latestRace = await _findLatestCompletedRace();
        if (latestRace == null) {
          _response = context.l10n.ai_no_completed_race;
        } else {
          final roundIndex = raceRoundFor(latestRace);
          await SessionDataManager().fetchDataForRace(latestRace, roundIndex);
          final rows =
              SessionDataManager().raceResultsCache[SessionDataManager()
                  .raceResultsKeyFor(latestRace)] ??
              const <RaceResultRow>[];
          final penalties = rows
              .where(
                (row) =>
                    row.penalty.trim().isNotEmpty && row.penalty.trim() != '-',
              )
              .toList(growable: false);
          if (penalties.isEmpty) {
            _response = context.l10n.ai_latest_penalties_none(latestRace.name);
          } else {
            final details = penalties
                .take(3)
                .map((row) => '${row.driver} (${row.penalty})')
                .join(' • ');
            _response = context.l10n.ai_latest_penalties_summary(
              latestRace.name,
              '${penalties.length}',
              details,
            );
          }
          _actionLabel = context.l10n.ai_open_weekend_hub;
          _action = () {
            navigator.pop();
            Future<void>.delayed(const Duration(milliseconds: 150), () {
              router.push(_weekendHubPath(latestRace));
            });
          };
        }
      } else if (lower.contains('race control') ||
          lower.contains('wedstrijdleiding') ||
          lower.contains('racecontrol')) {
        final latestRace = await _findLatestCompletedRace();
        if (latestRace == null) {
          _response = context.l10n.ai_no_completed_race;
        } else {
          final roundIndex = raceRoundFor(latestRace);
          await SessionDataManager().fetchDataForRace(latestRace, roundIndex);
          final messages =
              SessionDataManager().raceControlCache[SessionDataManager()
                  .raceControlKeyFor(latestRace)] ??
              const <Map<String, dynamic>>[];
          if (messages.isEmpty) {
            _response = context.l10n.ai_latest_race_control_none(latestRace.name);
          } else {
            final latestMessage = messages.last['message']?.toString() ?? '-';
            _response = context.l10n.ai_latest_race_control_summary(
              latestRace.name,
              '${messages.length}',
              latestMessage,
            );
          }
          _actionLabel = context.l10n.ai_open_weekend_hub;
          _action = () {
            navigator.pop();
            Future<void>.delayed(const Duration(milliseconds: 150), () {
              router.push(_weekendHubPath(latestRace));
            });
          };
        }
      } else {
        final strippedPrompt = _removeLeadingAssistantVerb(prompt);
        final requestedRace = _matchRace(strippedPrompt);
        final requestedDriver = _matchDriver(strippedPrompt);
        final requestedTeam = _matchTeam(strippedPrompt);

        if ((lower.contains('driver') || lower.contains('coureur')) &&
            requestedDriver != null) {
          _response = context.l10n.ai_driver_profile_ready(requestedDriver.name);
          _actionLabel = context.l10n.ai_open_driver_profile;
          _action = () {
            navigator.pop();
            Future<void>.delayed(const Duration(milliseconds: 150), () {
              router.push(_driverPath(requestedDriver));
            });
          };
        } else if ((lower.contains('team') || lower.contains('constructor')) &&
            requestedTeam != null) {
          _response = context.l10n.ai_team_profile_ready(requestedTeam.name);
          _actionLabel = context.l10n.ai_open_team_profile;
          _action = () {
            navigator.pop();
            Future<void>.delayed(const Duration(milliseconds: 150), () {
              router.push(_teamPath(requestedTeam));
            });
          };
        } else if ((lower.contains('weekend') ||
                lower.contains('race') ||
                lower.contains('circuit')) &&
            requestedRace != null) {
          _response = context.l10n.ai_next_weekend(
            requestedRace.name,
            '${requestedRace.date.day}-${requestedRace.date.month}-${requestedRace.date.year}',
          );
          _actionLabel = context.l10n.ai_open_weekend_hub;
          _action = () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            Future<void>.delayed(const Duration(milliseconds: 150), () {
              router.push(_weekendHubPath(requestedRace));
            });
          };
        } else {
          _response = context.l10n.ai_supported_commands;
        }
      }
    } catch (error) {
      _response = context.l10n.ai_crash('$error');
    }

    if (mounted) {
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final responseText = _response.isEmpty
        ? context.l10n.ai_example_prompt
        : _response;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.ai_race_engineer,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text(context.l10n.ai_chip_fetch_latest_results),
                  onPressed: () => _runPrompt('Fetch latest results'),
                ),
                ActionChip(
                  label: Text(context.l10n.ai_chip_show_next_weekend),
                  onPressed: () => _runPrompt('Show next weekend'),
                ),
                ActionChip(
                  label: Text(context.l10n.ai_chip_compare_max_lando),
                  onPressed: () =>
                      _runPrompt('Compare Max Verstappen vs Lando Norris'),
                ),
                ActionChip(
                  label: Text(context.l10n.ai_chip_show_form_piastri),
                  onPressed: () => _runPrompt('Show form Oscar Piastri'),
                ),
                ActionChip(
                  label: Text(context.l10n.ai_chip_show_driver_standings),
                  onPressed: () => _runPrompt('Show driver standings'),
                ),
                ActionChip(
                  label: Text(context.l10n.ai_chip_show_latest_penalties),
                  onPressed: () => _runPrompt('Show latest penalties'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.ai_type_command,
                suffixIcon: IconButton(
                  icon: _isWorking
                      ? const HubGlassInlineLoadingPlaceholder(
                          width: 18,
                          height: 18,
                        )
                      : const Icon(Icons.send),
                  onPressed: _isWorking ? null : _runPrompt,
                ),
              ),
              onSubmitted: (_) => _isWorking ? null : _runPrompt(),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _themeTokens(context).panelStrong,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(responseText),
            ),
            if (_action != null && _actionLabel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _action,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DriverDetailView extends StatefulWidget {
  final Driver driver;
  final String heroTag;
  final Widget settingsMenu;
  const DriverDetailView({
    required this.driver,
    required this.heroTag,
    required this.settingsMenu,
    super.key,
  });

  @override
  State<DriverDetailView> createState() => _DriverDetailViewState();
}

class _DriverDetailViewState extends State<DriverDetailView> {
  int? _selectedYearIndex;
  late ScrollController _scrollController;
  bool _showAllDnfs = false;
  late Driver _detailDriver;
  bool _isChampionshipLeader = false;
  /// Same merge as [StandingsView] / `/#/drivers` (drivers_standings_*.json).
  List<Driver>? _championshipDriversOrdered;

  @override
  void initState() {
    super.initState();
    _detailDriver = widget.driver;
    _scrollController = ScrollController();
    _loadHubDriverJson();
    unawaited(_loadChampionshipDriversForHero());
  }

  @override
  void didUpdateWidget(covariant DriverDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driver.name != widget.driver.name ||
        oldWidget.driver.number != widget.driver.number) {
      _detailDriver = widget.driver;
      _championshipDriversOrdered = null;
      _loadHubDriverJson();
      unawaited(_loadChampionshipDriversForHero());
    }
  }

  Future<void> _loadChampionshipDriversForHero() async {
    final year = DateTime.now().year;
    final ordered = await _loadChampionshipDriversOrdered(context, year);
    if (!mounted) {
      return;
    }
    setState(() => _championshipDriversOrdered = ordered);
  }

  /// True if [name] is among the driver(s) with the highest points in bundled
  /// `drivers_standings_{year}.json` for the current calendar year.
  Future<void> _refreshChampionshipLeaderStatus() async {
    final year = DateTime.now().year;
    final paths = F1AssetResolver.driversStandingsCandidatePaths(year);
    var leader = false;
    for (final path in paths) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) {
        continue;
      }
      try {
        final raw = await rootBundle.loadString(path);
        final dynamic doc = json.decode(raw);
        final list = doc is Map ? doc['standings'] : null;
        if (list is! List || list.isEmpty) {
          break;
        }
        var maxPts = double.negativeInfinity;
        final leaders = <String>[];
        for (final row in list) {
          if (row is! Map) {
            continue;
          }
          final p = row['points'];
          final nm = row['driver']?.toString().trim() ?? '';
          if (p is! num || nm.isEmpty) {
            continue;
          }
          final pd = p.toDouble();
          if (pd > maxPts) {
            maxPts = pd;
            leaders
              ..clear()
              ..add(nm);
          } else if ((pd - maxPts).abs() < 1e-9) {
            leaders.add(nm);
          }
        }
        if (maxPts.isFinite && leaders.isNotEmpty) {
          final my = normalizeForComparison(_detailDriver.name);
          leader = leaders.any((n) => normalizeForComparison(n) == my);
        }
        break;
      } catch (_) {
        continue;
      }
    }
    if (mounted) {
      setState(() => _isChampionshipLeader = leader);
    }
  }

  Future<void> _loadHubDriverJson() async {
    final paths = F1AssetResolver.hubDriverExportAssetPaths(widget.driver.name);
    for (final path in paths) {
      if (!await F1AssetResolver.bundleHasAsset(rootBundle, path)) {
        continue;
      }
      try {
        final raw = await rootBundle.loadString(path);
        final dynamic doc = json.decode(raw);
        if (doc is! Map<String, dynamic>) {
          continue;
        }
        final rec = latestHubDriverRecordFromExportDoc(doc);
        if (rec == null) {
          continue;
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _detailDriver = driverFromHubExportJsonRecord(rec);
        });
        await _refreshChampionshipLeaderStatus();
        return;
      } catch (_) {
        continue;
      }
    }
    await _refreshChampionshipLeaderStatus();
  }

  Widget _buildDriverPortraitForDetail(
    BuildContext context, {
    double dimension = 96,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final roster = _simulatorDriverRefs();
    final paths = simulatorDriverPortraitPathCandidates(_detailDriver.name, roster);
    final parts = _detailDriver.name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();
    final initials = parts.isEmpty ? '?' : parts;
    final avatarRadius = dimension / 2;
    final initialsSize = (dimension * 0.34).clamp(12.0, 28.0);
    final accent = teamBrandPrimaryColorOrF1(_detailDriver.team);

    return HubAssetImageChain(
      paths: paths,
      bundle: rootBundle,
      width: dimension,
      height: dimension,
      fit: BoxFit.cover,
      clipOval: true,
      glassFallbackAccent: accent,
      fallback: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Text(
          initials,
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: initialsSize,
          ),
        ),
      ),
    );
  }

  Widget _buildChampionshipLeaderPill(
    BuildContext context, {
    bool hubChrome = false,
    Color? accent,
  }) {
    if (hubChrome) {
      final a = accent ?? ConstructorHubColors.railLogoRed;
      const leaderTrophyGold = Color(0xFFE8C547);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: ConstructorHubColors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: a.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 18, color: leaderTrophyGold),
              const SizedBox(width: 8),
              Text(
                context.l10n.championship_leader_pill,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: ConstructorHubColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              context.l10n.championship_leader_pill,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _getDriverHistory(String name) {
    switch (name) {
      case 'Max Verstappen':
        return [1, 1, 1, 1, 2]; // 2021-2025
      case 'Lando Norris':
        return [6, 7, 6, 2, 1];
      case 'Oscar Piastri':
        return [21, 21, 9, 4, 3]; // 21 = N/A
      case 'George Russell':
        return [15, 4, 8, 6, 4];
      case 'Charles Leclerc':
        return [7, 2, 5, 3, 5];
      case 'Lewis Hamilton':
        return [2, 6, 3, 7, 6];
      case 'Kimi Antonelli':
        return [21, 21, 21, 21, 7];
      case 'Alexander Albon':
        return [21, 19, 13, 16, 8];
      case 'Carlos Sainz':
        return [5, 5, 7, 5, 9];
      case 'Fernando Alonso':
        return [10, 9, 4, 9, 10];
      case 'Nico Hülkenberg':
        return [21, 22, 16, 11, 11];
      case 'Isack Hadjar':
        return [21, 21, 21, 21, 12];
      case 'Oliver Bearman':
        return [21, 21, 21, 18, 13];
      case 'Esteban Ocon':
        return [11, 8, 12, 14, 14];
      case 'Liam Lawson':
        return [21, 21, 20, 21, 15];
      case 'Lance Stroll':
        return [13, 15, 10, 13, 16];
      case 'Yuki Tsunoda':
        return [14, 17, 14, 12, 17];
      case 'Pierre Gasly':
        return [9, 14, 11, 10, 18];
      case 'Gabriel Bortoleto':
        return [21, 21, 21, 21, 19];
      case 'Franco Colapinto':
        return [21, 21, 21, 19, 20];
      case 'Sergio Pérez':
        return [4, 3, 2, 8, 21];
      case 'Valtteri Bottas':
        return [3, 10, 15, 22, 21];
      default:
        return [21, 21, 21, 21, 21];
    }
  }

  Widget _buildHistoryChart(List<int> pos, Color color) {
    if (pos.isEmpty) return const SizedBox.shrink();
    final primaryFg = HubTheme.primaryOnGlassText(context);
    final secondaryFg = HubTheme.secondaryOnGlassText(context);
    List<String> years = ['21', '22', '23', '24', '25'];
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(pos.length, (i) {
              double h = 100.0 - (pos[i] * 4.0);
              if (h < 10) h = 10;
              final isSelected = _selectedYearIndex == i;

              return GestureDetector(
                onTap: () => setState(() => _selectedYearIndex = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "P${pos[i]}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? _hubReadableAccent(context)
                            : primaryFg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 28 : 24,
                      height: h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected
                            ? Border.all(
                                color: primaryFg,
                                width: 2,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      years[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? primaryFg : secondaryFg,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        if (_selectedYearIndex != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "20${years[_selectedYearIndex!]} Finish: P${pos[_selectedYearIndex!]}",
              style: TextStyle(
                color: primaryFg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  MapEntry<String, String> _splitDriverTimelineEntry(String entry) {
    String teamName = entry;
    String years = '';

    if (entry.contains(' (')) {
      final parts = entry.split(' (');
      teamName = parts[0];
      years = parts[1].replaceAll(')', '');
    }

    return MapEntry(teamName, years);
  }

  List<String> _buildDriverTimelineEntries() {
    final history = List<String>.from(_detailDriver.previousTeams);
    if (history.isEmpty) return history;

    String currentYears = 'Present';
    try {
      final lastEntry = _splitDriverTimelineEntry(history.last);
      final match = RegExp(r'(\d{4})(?!.*\d{4})').firstMatch(lastEntry.value);
      if (match != null) {
        final startYear = int.parse(match.group(1)!) + 1;
        currentYears = '$startYear-Present';
      }
    } catch (_) {}

    history.add('${_detailDriver.team} - F1 ($currentYears)');
    return history;
  }

  Widget _buildDriverPreviousTeamsTimeline(bool isDark) {
    final history = _buildDriverTimelineEntries();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: history.asMap().entries.map((entry) {
                final idx = entry.key;
                final timelineEntry = _splitDriverTimelineEntry(entry.value);
                final isLast = idx == history.length - 1;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: idx == 0
                                  ? Colors.transparent
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _hubReadableAccent(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isLast
                                  ? Colors.transparent
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timelineEntry.key,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        timelineEntry.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        return Column(
          children: history.asMap().entries.map((entry) {
            final idx = entry.key;
            final timelineEntry = _splitDriverTimelineEntry(entry.value);
            final isLast = idx == history.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _hubReadableAccent(context),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 1.5,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timelineEntry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            timelineEntry.value,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<MapEntry<int, double>> _sortedPointsTimelineEntries() {
    final entries = _detailDriver.pointsPerSeason.entries
        .map(
          (entry) => MapEntry(
            int.tryParse(entry.key.toString()) ?? 0,
            entry.value.toDouble(),
          ),
        )
        .where((entry) => entry.key > 0)
        .toList();

    entries.sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  Widget _buildPointsTimeline() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = _sortedPointsTimelineEntries();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: entries.asMap().entries.map((timelineEntry) {
        final index = timelineEntry.key;
        final entry = timelineEntry.value;
        final isLast = index == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _hubReadableAccent(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        entry.value == entry.value.roundToDouble()
                            ? entry.value.toInt().toString()
                            : entry.value.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDutch =
        Localizations.localeOf(context).languageCode == 'nl' ||
            Localizations.localeOf(context).languageCode == 'de';
    final List<String> facts = isDutch
        ? _detailDriver.realWorldFactsNl
        : _detailDriver.realWorldFactsEn;
    final List<int> driverHistory = _getDriverHistory(_detailDriver.name);

    final expPrefs = context.watch<DetailExpansionPrefsNotifier>();
    final scheme = Theme.of(context).colorScheme;
    final hubDark = scheme.brightness == Brightness.dark;
    final driverAccent = teamBrandPrimaryColorOrF1(_detailDriver.team);
    final driverSectionTitleColor = driverAccent;

    final List<Widget> driverSections = [
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverHistory,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverHistory,
          v,
        ),
        title: Text(
          context.l10n.driver_history,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildHistoryChart(
              driverHistory,
              F1TeamSchemes.getTeamColor(_detailDriver.team),
            ),
          ),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverRecentForm,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverRecentForm,
          v,
        ),
        title: Text(
          context.l10n.recent_form_trend_title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: driverSectionTitleColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: RecentFormTrendCard(
              driverName: _detailDriver.name,
              seasonYear: _paddockRecentFormSeasonYear(),
              showHeaderTitle: false,
            ),
          ),
        ],
      )),
      if (_detailDriver.previousTeams.isNotEmpty)
        _detailOverviewSectionCard(
          context,
          child: ExpansionTile(
            initiallyExpanded: expPrefs.initiallyExpanded(
              DetailExpansionCat.driver,
              DetailExpansionSection.driverPreviousTeams,
              false,
            ),
            onExpansionChanged: (v) => expPrefs.setExpanded(
              DetailExpansionCat.driver,
              DetailExpansionSection.driverPreviousTeams,
              v,
            ),
            title: Text(
              context.l10n.previous_teams,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: driverSectionTitleColor,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildDriverPreviousTeamsTimeline(isDark),
                ),
              ),
            ],
          ),
        ),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverFacts,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverFacts,
          v,
        ),
        title: Text(
          context.l10n.driver_facts_title,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facts
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 10),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: driverAccent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: scheme.onSurface.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverPersonal,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverPersonal,
          v,
        ),
        title: Text(
          context.l10n.personal_info,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          _statTile(context.l10n.age, _detailDriver.age, Icons.cake),
          _statTile(
            context.l10n.height,
            _detailDriver.height,
            Icons.height,
          ),
          _statTile(
            context.l10n.birth_place,
            _detailDriver.birthPlace,
            Icons.location_on,
          ),
          _statTile(
            context.l10n.partner,
            _detailDriver.partner,
            Icons.favorite,
          ),
          _statTile(
            context.l10n.children,
            _detailDriver.children,
            Icons.child_care,
          ),
          _statTile(context.l10n.pets, _detailDriver.pets, Icons.pets),
          _statTile(
            context.l10n.manager,
            _detailDriver.manager,
            Icons.work,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverGeneral,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverGeneral,
          v,
        ),
        title: Text(
          context.l10n.general,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          _statTile(
            context.l10n.nationality,
            l10nNationality(context.l10n, _detailDriver.nationality),
            Icons.public,
          ),
          _statTile(
            context.l10n.f1_debut,
            _detailDriver.debutYear,
            Icons.start,
          ),
          _statTile(
            context.l10n.contract_until,
            _detailDriver.contractUntil,
            Icons.edit_document,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverCareer,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverCareer,
          v,
        ),
        title: Text(
          context.l10n.career_stats,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          _statTile(
            context.l10n.championships,
            _detailDriver.championships,
            Icons.workspace_premium,
          ),
          _statTile(
            context.l10n.wins,
            _detailDriver.wins,
            Icons.emoji_events,
          ),
          _statTile(
            context.l10n.podiums,
            _detailDriver.podiums,
            Icons.leaderboard,
          ),
          _statTile(context.l10n.poles, _detailDriver.poles, Icons.flag),
          _statTile(
            context.l10n.fastest_laps,
            _detailDriver.fastestLaps,
            Icons.timer,
          ),
          _statTile(
            context.l10n.highest_finish,
            _detailDriver.highestFinish,
            Icons.military_tech,
          ),
          _statTile(
            context.l10n.highest_grid,
            _detailDriver.highestGrid,
            Icons.grid_3x3,
          ),
          _statTile(
            context.l10n.hat_tricks,
            _detailDriver.hatTricks,
            Icons.auto_awesome,
          ),
          _statTile(
            context.l10n.front_row_starts,
            _detailDriver.frontRowStarts,
            Icons.looks_two,
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.toll,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.total_points,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _detailDriver.totalPoints.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              children: [_buildPointsTimeline()],
            ),
          ),
          _statTile(
            context.l10n.overtakes,
            _detailDriver.overtakes,
            Icons.compare_arrows,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverExperience,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverExperience,
          v,
        ),
        title: Text(
          context.l10n.experience,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          _statTile(
            context.l10n.starts,
            _detailDriver.starts,
            Icons.traffic,
          ),
          _statTile(
            context.l10n.laps_led,
            _detailDriver.lapsLed,
            Icons.looks_one,
          ),
          _statTile(context.l10n.dnf, _detailDriver.dnfs, Icons.car_crash),
          _statTile(context.l10n.dsqs, _detailDriver.dsqs, Icons.block),
          _statTile(
            context.l10n.dnqs,
            _detailDriver.dnqs,
            Icons.cancel_schedule_send,
          ),
          if (_detailDriver.dnfs > 0)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.car_crash,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.retirements,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.82),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _detailDriver.dnfs.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                children: [_buildDnfTimeline()],
              ),
            ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverSponsors,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.driver,
          DetailExpansionSection.driverSponsors,
          v,
        ),
        title: Text(
          context.l10n.personal_sponsors,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: driverSectionTitleColor,
            ),
        ),
        children: [
          ..._detailDriver.personalSponsors.map(
            (s) => _statTile(s, '', Icons.business_center),
          ),
          const SizedBox(height: 8),
        ],
      )),
    ];

    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = hubDark
        ? ConstructorHubColors.background
        : HubTheme.lightCanvas;
    final listTopPadding = desktopShell
        ? MediaQuery.paddingOf(context).top + 12.0
        : 0.0;

    final seasonYear = DateTime.now().year.toString();
    final chOrdered = _championshipDriversOrdered;
    final chRow = chOrdered != null
        ? _championshipDriverRow(chOrdered, _detailDriver)
        : null;
    final rank = chOrdered != null
        ? _championshipRankForDriver(chOrdered, _detailDriver)
        : _driverRankInStandings(_detailDriver);
    final pointsHero = chRow != null
        ? chRow.points.round()
        : _detailDriver.points.round();
    final podiumsHero = chRow?.podiums ?? _detailDriver.podiums;
    final driverPortraitCandidates = simulatorDriverPortraitPathCandidates(
      _detailDriver.name,
      _simulatorDriverRefs(),
    );
    final driverPortraitIni = _detailDriver.name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();
    final driverPortraitInitials =
        driverPortraitIni.isEmpty ? '?' : driverPortraitIni;

    final hubBackStyle = hubDark
        ? ConstructorHubColors.textSecondary.withValues(alpha: 0.95)
        : HubTheme.secondaryOnGlassText(context);

    final listChildren = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 20, left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(_driversPath());
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: hubBackStyle,
            ),
            label: Text(
              context.l10n.hub_back_to_drivers,
              style: GoogleFonts.titilliumWeb(
                color: hubBackStyle,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
      DriverHubHeroCard(
        countryPrefix: _driverHeroCountryPrefix(_detailDriver),
        driverTitleUpper: _detailDriver.name.toUpperCase(),
        teamLine: _detailDriver.team,
        numberLine: '#${_detailDriver.number}',
        points: pointsHero,
        rankDisplay: rank != null ? 'P$rank' : '—',
        podiums: podiumsHero,
        seasonYear: seasonYear,
        pointsLabel: context.l10n.total_points,
        rankLabel: context.l10n.standings,
        podiumsLabel: context.l10n.podiums,
        accent: driverAccent,
        flagEmoji: _detailDriver.flag,
        flagHeroTag: widget.heroTag,
        portraitAssetPathCandidates: driverPortraitCandidates,
        portraitInitials: driverPortraitInitials,
        standingsRank: rank,
        championshipLeader: _isChampionshipLeader,
        statsThreeInRow: true,
      ),
      const SizedBox(height: 20),
      KeyedSubtree(
        key: ValueKey('driver-sections-${expPrefs.loadedRevision}'),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme.copyWith(primary: driverAccent),
          ),
          child: _buildResponsiveSections(sections: driverSections),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor:
          hubDark ? ConstructorHubColors.background : Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hubDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
              ),
            )
          else if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                listTopPadding,
                16,
                24,
              ),
              children: listChildren,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnfTimeline() {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final allEntries = _getDnfEntries(_detailDriver.name);
    final visibleEntries = _showAllDnfs || allEntries.length <= 5
        ? allEntries
        : allEntries.take(5).toList();

    return Column(
      children: [
        ...visibleEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final dnf = entry.value;
          final isLast = index == visibleEntries.length - 1;
          final lapValue = dnf[3].trim();
          final lapNumber = int.tryParse(lapValue);
          final lapLabel = lapNumber != null
              ? 'Lap $lapNumber'
              : lapValue.toUpperCase();

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _hubReadableAccent(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 1.5,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: tokens.outline.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dnf[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _hubReadableAccent(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lapLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dnf[1],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dnf[2],
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (allEntries.length > 5)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _showAllDnfs = !_showAllDnfs);
                },
                icon: Icon(
                  _showAllDnfs ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  _showAllDnfs
                      ? 'Show latest 5'
                      : 'Show all DNFs (${allEntries.length})',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TeamDetailView extends StatefulWidget {
  final Team team;
  final String heroTag;
  final Widget settingsMenu;
  const TeamDetailView({
    required this.team,
    required this.heroTag,
    required this.settingsMenu,
    super.key,
  });

  @override
  State<TeamDetailView> createState() => _TeamDetailViewState();
}

class _TeamDetailViewState extends State<TeamDetailView> {
  late ScrollController _scrollController;
  bool _showFlagInTitle = false;
  int? _selectedYearIndex;
  /// Same merge as `/#/teams` (teams_standings_*.json).
  List<Team>? _championshipTeamsOrdered;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    unawaited(_loadChampionshipTeamsForHero());
  }

  @override
  void didUpdateWidget(covariant TeamDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team.name != widget.team.name) {
      _championshipTeamsOrdered = null;
      unawaited(_loadChampionshipTeamsForHero());
    }
  }

  Future<void> _loadChampionshipTeamsForHero() async {
    final year = DateTime.now().year;
    final ordered = await _loadChampionshipTeamsOrdered(context, year);
    if (!mounted) {
      return;
    }
    setState(() => _championshipTeamsOrdered = ordered);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 140;
      if (show != _showFlagInTitle) {
        setState(() => _showFlagInTitle = show);
      }
    }
  }

  MapEntry<String, String> _splitTeamTimelineEntry(String entry) {
    String label = entry;
    String years = '';

    if (entry.contains(' (')) {
      final parts = entry.split(' (');
      label = parts[0];
      years = parts[1].replaceAll(')', '');
    }

    return MapEntry(label, years);
  }

  List<String> _buildTeamHistoryEntries() {
    final history = widget.team.previousNames.reversed.toList();

    if (history.isNotEmpty) {
      try {
        final lastEntry = history.last;
        final match = RegExp(r'(\d{4})(?!.*\d{4})').firstMatch(lastEntry);
        if (match != null) {
          final endYear = int.parse(match.group(1)!);
          history.add('${widget.team.name} (${endYear + 1}-Present)');
        }
      } catch (_) {}
    }

    return history;
  }

  Widget _buildHorizontalTimeline(List<String> entries) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.asMap().entries.map((entry) {
          final idx = entry.key;
          final timelineEntry = _splitTeamTimelineEntry(entry.value);
          final isLast = idx == entries.length - 1;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: idx == 0
                            ? Colors.transparent
                            : (isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _hubReadableAccent(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isLast
                            ? Colors.transparent
                            : (isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  timelineEntry.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                ),
                if (timelineEntry.value.isNotEmpty)
                  Text(
                    timelineEntry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerticalTimeline(List<String> entries) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: entries.asMap().entries.map((entry) {
        final idx = entry.key;
        final timelineEntry = _splitTeamTimelineEntry(entry.value);
        final isLast = idx == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _hubReadableAccent(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timelineEntry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      if (timelineEntry.value.isNotEmpty)
                        Text(
                          timelineEntry.value,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdaptiveTimeline(List<String> entries) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldUseVertical =
            constraints.maxWidth < 640 || entries.length > 4;
        return shouldUseVertical
            ? _buildVerticalTimeline(entries)
            : _buildHorizontalTimeline(entries);
      },
    );
  }

  Widget _buildAdaptiveStatTimeline(List<Map<String, String>> entries) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _hubReadableAccent(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                            if ((item['subtitle'] ?? '').isNotEmpty)
                              Text(
                                item['subtitle']!,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item['value'] ?? '',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Set<String> _teamTitleLookupKeys() {
    final keys = <String>{widget.team.name};

    for (final previousName in widget.team.previousNames) {
      keys.add(_splitTeamTimelineEntry(previousName).key);
    }

    if (widget.team.name == 'Red Bull Racing') {
      keys.add('Red Bull');
    }

    return keys;
  }

  String _normalizeTeamKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Map<int, double> _resolveTitlePoints(Map<String, Map<int, double>> source) {
    final lookupKeys = _teamTitleLookupKeys().map(_normalizeTeamKey).toSet();

    for (final entry in source.entries) {
      final normalizedEntryKey = _normalizeTeamKey(entry.key);
      if (lookupKeys.contains(normalizedEntryKey) ||
          lookupKeys.any(
            (key) =>
                key.contains(normalizedEntryKey) ||
                normalizedEntryKey.contains(key),
          )) {
        return entry.value;
      }
    }

    return const <int, double>{};
  }

  Map<int, List<String>> _resolveTitleDrivers(
    Map<String, Map<int, List<String>>> source,
  ) {
    final lookupKeys = _teamTitleLookupKeys().map(_normalizeTeamKey).toSet();

    for (final entry in source.entries) {
      final normalizedEntryKey = _normalizeTeamKey(entry.key);
      if (lookupKeys.contains(normalizedEntryKey) ||
          lookupKeys.any(
            (key) =>
                key.contains(normalizedEntryKey) ||
                normalizedEntryKey.contains(key),
          )) {
        return entry.value;
      }
    }

    return const <int, List<String>>{};
  }

  Map<int, String> _resolveChampionDriversByYear() {
    final championsByYear = <int, String>{};

    for (final titleEntry in widget.team.dcList) {
      final match = RegExp(r'^(.*?) \((.*)\)$').firstMatch(titleEntry);
      if (match == null) {
        continue;
      }

      final driverName = match.group(1)!;
      final years = match
          .group(2)!
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>();

      for (final year in years) {
        championsByYear[year] = driverName;
      }
    }

    return championsByYear;
  }

  String _formatTimelinePoints(double points) {
    if (points == 0) {
      return '0 pts';
    }

    final formatted = points == points.roundToDouble()
        ? points.toInt().toString()
        : points.toStringAsFixed(1);
    return '$formatted pts';
  }

  Widget _buildConstructorTitleTimeline() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pointsByYear = _resolveTitlePoints(teamConstructorTitlePoints);
    final driversByYear = _resolveTitleDrivers(teamConstructorTitleDrivers);
    final championsByYear = _resolveChampionDriversByYear();
    final entries = widget.team.ccYears.reversed.toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final year = entry.value;
        final isLast = index == entries.length - 1;
        final champion = championsByYear[year];
        final drivers = driversByYear[year] ?? const <String>[];

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _hubReadableAccent(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              year.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                            if (drivers.isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  children: [
                                    for (
                                      var driverIndex = 0;
                                      driverIndex < drivers.length;
                                      driverIndex++
                                    ) ...[
                                      if (driverIndex > 0)
                                        const TextSpan(text: '  •  '),
                                      if (drivers[driverIndex] == champion)
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Icon(
                                              Icons.emoji_events,
                                              size: 11,
                                              color: const Color(0xFFFFB300),
                                            ),
                                          ),
                                        ),
                                      TextSpan(
                                        text: drivers[driverIndex],
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight:
                                              drivers[driverIndex] == champion
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatTimelinePoints(pointsByYear[year] ?? 0),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _buildDriverTitleEntries() {
    final pointsByYear = _resolveTitlePoints(teamDriverTitlePoints);
    final entries = <Map<String, String>>[];

    for (final titleEntry in widget.team.dcList) {
      final match = RegExp(r'^(.*?) \((.*)\)$').firstMatch(titleEntry);
      if (match == null) {
        continue;
      }

      final driverName = match.group(1)!;
      final years = match
          .group(2)!
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>();

      for (final year in years) {
        entries.add(<String, String>{
          'title': driverName,
          'subtitle': year.toString(),
          'value': _formatTimelinePoints(pointsByYear[year] ?? 0),
        });
      }
    }

    entries.sort(
      (a, b) => int.parse(b['subtitle']!).compareTo(int.parse(a['subtitle']!)),
    );
    return entries;
  }

  Map<String, String> _parseDriverRosterEntry(String entry) {
    final match = RegExp(r'^(.*?) \((.*)\)$').firstMatch(entry);
    if (match == null) {
      return {'name': entry, 'details': '', 'role': 'driver'};
    }

    final details = match.group(2)!;
    final isReserve = details.contains('Reserve') || details.contains('Test');

    return {
      'name': match.group(1)!,
      'details': details,
      'role': isReserve ? 'reserve' : 'driver',
    };
  }

  List<Map<String, String>> _buildDriverTenureEntries() {
    return widget.team.drivers.map(_parseDriverRosterEntry).toList();
  }

  Widget _buildDriverRosterTimeline() {

    final theme = Theme.of(context);
    final rosterAccent =
        teamBrandPrimaryColorOrF1(widget.team.name);
    final isDark = theme.brightness == Brightness.dark;
    final entries = _buildDriverTenureEntries();
    final drivers = entries
        .where((entry) => entry['role'] == 'driver')
        .toList();
    final reserves = entries
        .where((entry) => entry['role'] == 'reserve')
        .toList();
    final rowCount = drivers.length > reserves.length
        ? drivers.length
        : reserves.length;

    if (rowCount == 0) {
      return const SizedBox.shrink();
    }

    Widget buildTextBlock(Map<String, String>? item, TextAlign align) {
      if (item == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            item['name'] ?? '',
            textAlign: align,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          if ((item['details'] ?? '').isNotEmpty)
            Text(
              item['details']!,
              textAlign: align,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.drivers,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: rosterAccent,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  context.l10n.reserve_driver,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: rosterAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(rowCount, (index) {
          final driver = index < drivers.length ? drivers[index] : null;
          final reserve = index < reserves.length ? reserves[index] : null;
          final isLast = index == rowCount - 1;
          final markerColor = reserve != null
              ? const Color(0xFFFF9800)
              : const Color(0xFFE53935);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 16,
                    ),
                    child: buildTextBlock(driver, TextAlign.right),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 1.5,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 16,
                    ),
                    child: buildTextBlock(reserve, TextAlign.left),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<int> _getTeamHistory(String name) {
    if (name.contains('Red Bull')) return [2, 1, 1, 2, 2]; // 2021-2025
    if (name.contains('Mercedes')) return [1, 3, 2, 4, 3];
    if (name.contains('Ferrari')) return [3, 2, 3, 3, 4];
    if (name.contains('McLaren')) return [4, 5, 4, 1, 1];
    if (name.contains('Aston')) return [7, 7, 5, 5, 5];
    if (name.contains('Alpine')) return [5, 4, 6, 7, 7];
    if (name.contains('Williams')) return [8, 10, 7, 8, 8];
    if (name.contains('Racing Bulls') || name.contains('RB')) {
      return [6, 9, 8, 6, 6];
    }
    if (name.contains('Haas')) return [10, 8, 10, 9, 9];
    if (name.contains('Audi') || name.contains('Sauber')) {
      return [9, 6, 9, 10, 10];
    }
    return [11, 11, 11, 11, 11];
  }

  Widget _buildHistoryChart(List<dynamic> pos, Color color) {
    if (pos.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartLabelAccent =
        teamBrandPrimaryColorOrF1(widget.team.name);
    List<String> years = ['21', '22', '23', '24', '25'];
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(pos.length, (i) {
              double h = (12 - (pos[i] > 10 ? 11 : pos[i])) * 8.0;
              if (h < 10) h = 10;
              final isSelected = _selectedYearIndex == i;

              return GestureDetector(
                onTap: () => setState(() => _selectedYearIndex = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "P${pos[i]}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? chartLabelAccent
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 28 : 24,
                      height: h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      years[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white54 : Colors.black54),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        if (_selectedYearIndex != null)
          _buildDriversForYear(2021 + _selectedYearIndex!),
      ],
    );
  }

  Widget _buildDriversForYear(int year) {
    final drivers = _getDriversForYear(year);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drivers $year',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (drivers.isEmpty)
            Text(
              'No driver data available.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...drivers.map(
              (d) => InkWell(
                onTap: () => context.push(_driverPath(d)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      _buildDriverHeadshot(
                        context: context,
                        driver: d,
                        heroTag: _driverFlagHeroTag(
                          d,
                          source: 'team-roster:${widget.team.name}',
                        ),
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Driver> _getDriversForYear(int year) {
    List<Driver> yearDrivers = [];
    for (String entry in widget.team.drivers) {
      final match = RegExp(r'^(.*?) \((.*)\)$').firstMatch(entry);
      if (match != null) {
        String name = match.group(1)!;
        String details = match.group(2)!;
        if (details.contains('Reserve') || details.contains('Test')) continue;

        String yearStr = details.replaceAll(' Current', '').replaceAll('+', '');
        List<int> years = [];
        if (yearStr.contains('-')) {
          final parts = yearStr.split('-');
          int start = int.tryParse(parts[0]) ?? 0;
          int end = int.tryParse(parts[1]) ?? 9999;
          for (int y = start; y <= end; y++) {
            years.add(y);
          }
        } else {
          int y = int.tryParse(yearStr) ?? 0;
          if (y != 0) years.add(y);
        }

        if (years.contains(year)) {
          // Try to find driver in the specific year list first, fallback to 2026 list for static data
          List<Driver> pool = driversData[year] ?? [];
          Driver d = pool.firstWhere(
            (fd) => fd.name == name,
            orElse: () => drivers2026.firstWhere(
              (fd) => fd.name == name,
              orElse: () => Driver(
                name: name,
                flag: '',
                points: 0,
                number: 0,
                nationality: '',
                team: widget.team.name,
                pointsFinishPct: 0,
                seasonPointsFinishPct: 0,
                wins: 0,
                podiums2nd: 0,
                podiums3rd: 0,
                podiums: 0,
                poles: 0,
                fastestLaps: 0,
                totalPoints: 0,
                championships: 0,
                championshipYears: [],
                lapsRaced: 0,
                starts: 0,
                dnfs: 0,
                dsqs: 0,
                dnqs: 0,
                lapsLed: 0,
                frontRowStarts: 0,
                highestFinish: 'N/A',
                highestGrid: 'N/A',
                hatTricks: 0,
                overtakes: 0,
                age: 0,
                height: '-',
                birthPlace: '-',
                partner: '-',
                children: '-',
                pets: '-',
                manager: '-',
                realWorldFactsEn: [],
                realWorldFactsNl: [],
                pointsPerSeason: {},
                debutYear: 0,
                contractUntil: '-',
                previousTeams: [],
                personalSponsors: [],
              ),
            ),
          );
          yearDrivers.add(d);
        }
      }
    }
    return yearDrivers;
  }

  @override
  Widget build(BuildContext context) {

    final teamHistory = _getTeamHistory(widget.team.name);

    String title = widget.team.name.toUpperCase();
    if (_showFlagInTitle) {
      title = "${widget.team.flag} $title";
    }

    final List<String> teamFacts = () {
      switch (Localizations.localeOf(context).languageCode) {
        case 'nl': return widget.team.factsNl;
        case 'fr': return widget.team.factsFr;
        case 'de': return widget.team.factsDe;
        default:   return widget.team.factsEn;
      }
    }();

    final expPrefs = context.watch<DetailExpansionPrefsNotifier>();
    final scheme = Theme.of(context).colorScheme;
    final hubDark = scheme.brightness == Brightness.dark;
    final teamAccent =
        teamBrandPrimaryColorOrF1(widget.team.name);

    final List<Widget> teamSections = [
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamPerformance,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamPerformance,
          v,
        ),
        title: Text(
          "📊 Performance History",
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildHistoryChart(
              teamHistory,
              F1TeamSchemes.getTeamColor(widget.team.name),
            ),
          ),
        ],
      )),
      if (teamFacts.isNotEmpty)
        _detailOverviewSectionCard(
          context,
          child: ExpansionTile(
          initiallyExpanded: expPrefs.initiallyExpanded(
            DetailExpansionCat.team,
            DetailExpansionSection.teamFacts,
            true,
          ),
          onExpansionChanged: (v) => expPrefs.setExpanded(
            DetailExpansionCat.team,
            DetailExpansionSection.teamFacts,
            v,
          ),
          title: Text(
            '💡 ${context.l10n.team_facts_title}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
          ),
          children: [
            ...teamFacts.map((fact) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 10),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: F1TeamSchemes.getTeamColor(widget.team.name),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      fact,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 4),
          ],
        )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamGeneral,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamGeneral,
          v,
        ),
        title: Text(
          context.l10n.general,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          _statTile(
            context.l10n.engine,
            widget.team.engine,
            Icons.settings_input_component,
          ),
          _statTile(
            context.l10n.headquarters,
            widget.team.headquarters,
            Icons.location_city,
          ),
          _statTile(
            context.l10n.total_points,
            widget.team.totalPoints == widget.team.totalPoints.roundToDouble()
                ? widget.team.totalPoints.toInt().toString()
                : widget.team.totalPoints.toString(),
            Icons.toll,
          ),
          if (widget.team.previousNames.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  context.l10n.team_history,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                children: [_buildAdaptiveTimeline(_buildTeamHistoryEntries())],
              ),
            ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamChampionships,
          true,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamChampionships,
          v,
        ),
        title: Text(
          context.l10n.championships,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          if (widget.team.ccYears.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  context.l10n.cc_wins,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  widget.team.ccWins.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                children: [_buildConstructorTitleTimeline()],
              ),
            )
          else
            _statTile(
              context.l10n.cc_wins,
              widget.team.ccWins,
              Icons.emoji_events,
            ),
          const SizedBox(height: 12),
          if (widget.team.dcList.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  context.l10n.dc_wins,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  widget.team.dcWins.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                children: [
                  _buildAdaptiveStatTimeline(_buildDriverTitleEntries()),
                ],
              ),
            )
          else
            _statTile(
              context.l10n.dc_wins,
              widget.team.dcWins,
              Icons.workspace_premium,
            ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamRaceStats,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamRaceStats,
          v,
        ),
        title: Text(
          context.l10n.race_stats,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          _statTile(
            context.l10n.total_entries,
            widget.team.totalEntries,
            Icons.traffic,
          ),
          _statTile(
            context.l10n.wins,
            widget.team.podiums,
            Icons.leaderboard,
          ),
          _statTile(
            context.l10n.one_two,
            widget.team.oneTwo,
            Icons.filter_2,
          ),
          _statTile(context.l10n.poles, widget.team.poles, Icons.flag),
          _statTile(
            context.l10n.fastest_laps,
            widget.team.fastestLaps,
            Icons.timer,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamPitstop,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamPitstop,
          v,
        ),
        title: Text(
          context.l10n.pitstop_leadership,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          _statTile(
            context.l10n.team_principal,
            "${widget.team.principalName} (${widget.team.principalAge})",
            Icons.person_outline,
          ),
          _statTile(
            context.l10n.technical_director,
            "${widget.team.technicalDirectorName} (${widget.team.technicalDirectorAge})",
            Icons.engineering,
          ),
          _statTile(
            context.l10n.fastest_pit,
            "${widget.team.fastestPitstopTime} (${l10nCountry(context.l10n, widget.team.fastestPitstopCircuit)} ${widget.team.fastestPitstopYear})",
            Icons.build,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamDrivers,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamDrivers,
          v,
        ),
        title: Text(
          context.l10n.drivers,
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [_buildDriverRosterTimeline(), const SizedBox(height: 8)],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamEngine,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamEngine,
          v,
        ),
        title: Text(
          '⚙️ ${context.l10n.engine_supplier}',
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          _statTile(
            context.l10n.name.split(' ').last,
            widget.team.engineSupplier.name,
            Icons.business,
          ),
          _statTile(
            context.l10n.engine_name.split(' ').last,
            widget.team.engineSupplier.engineName,
            Icons.settings,
          ),
          _statTile(
            context.l10n.city.split(' ').last,
            widget.team.engineSupplier.city,
            Icons.location_city,
          ),
          const SizedBox(height: 8),
        ],
      )),
      _detailOverviewSectionCard(
        context,
        child: ExpansionTile(
        initiallyExpanded: expPrefs.initiallyExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamSponsors,
          false,
        ),
        onExpansionChanged: (v) => expPrefs.setExpanded(
          DetailExpansionCat.team,
          DetailExpansionSection.teamSponsors,
          v,
        ),
        title: Text(
          '💰 ${context.l10n.sponsors}',
style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: teamAccent,
            ),
        ),
        children: [
          ...widget.team.sponsors.map(
            (s) => _statTile(s, '', Icons.business_center),
          ),
          const SizedBox(height: 8),
        ],
      )),
    ];

    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = hubDark
        ? ConstructorHubColors.background
        : Color.lerp(
            scheme.surfaceContainerLow,
            scheme.primary,
            0.04,
          )!;
    final listTopPadding = desktopShell ? 20.0 : 0.0;

    final seasonYear = DateTime.now().year.toString();
    final chTeams = _championshipTeamsOrdered;
    final chRow = chTeams != null
        ? _championshipTeamRow(chTeams, widget.team)
        : null;
    final rank = chTeams != null
        ? _championshipRankForTeam(chTeams, widget.team)
        : _constructorRankInStandings(widget.team);
    final pointsHero = chRow?.points ?? widget.team.points;
    final ccWinsHero = chRow?.ccWins ?? widget.team.ccWins;

    final teamHubBackStyle = hubDark
        ? ConstructorHubColors.textSecondary.withValues(alpha: 0.95)
        : HubTheme.secondaryOnGlassText(context);

    final listChildren = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 20, left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(_teamsPath());
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: teamHubBackStyle,
            ),
            label: Text(
              context.l10n.hub_back_to_constructors,
              style: GoogleFonts.titilliumWeb(
                color: teamHubBackStyle,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
      ConstructorHubHeroCard(
        teamName: widget.team.name,
        countryPrefix: constructorCountryPrefix(widget.team.name),
        teamTitleUpper: widget.team.name.toUpperCase(),
        headquarters: widget.team.headquarters,
        engine: widget.team.engine,
        points: pointsHero,
        rankDisplay: rank != null ? 'P$rank' : '—',
        constructorsTitles: ccWinsHero,
        seasonYear: seasonYear,
        pointsLabel: context.l10n.total_points,
        championshipLabel: context.l10n.championships,
        titlesLabel: context.l10n.cc_wins,
        accent: teamAccent,
        statsThreeInRow: true,
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          final maxW = (constraints.maxWidth * 0.68).clamp(200.0, 380.0);
          final carFallback = widget.team.carImageUrl.isEmpty
              ? F1HubImageGlassFallback(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  accentGradient: teamAccent,
                )
              : Image.network(
                  widget.team.carImageUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => F1HubImageGlassFallback(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(20),
                    accentGradient: teamAccent,
                  ),
                );
          return Padding(
            padding: EdgeInsets.only(bottom: hubDark ? 20 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: hubDark ? 128 : 132,
                  maxWidth: maxW,
                ),
                child: HubAssetImageChain(
                  paths: teamCarImageAssetPathCandidates(
                    widget.team.name,
                    forLightTheme:
                        Theme.of(context).brightness == Brightness.light,
                  ),
                  bundle: rootBundle,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  glassFallbackAccent: teamAccent,
                  fallback: carFallback,
                ),
              ),
            ),
          );
        },
      ),
      KeyedSubtree(
        key: ValueKey('team-sections-${expPrefs.loadedRevision}'),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme.copyWith(primary: teamAccent),
          ),
          child: _buildResponsiveSections(sections: teamSections),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: hubDark ? ConstructorHubColors.background : Colors.transparent,
      extendBodyBehindAppBar: !desktopShell,
      appBar: desktopShell
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: scheme.onSurface,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              title: Text(title),
              actions:
                  _desktopAwareSettingsActions(context, widget.settingsMenu),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hubDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
              ),
            )
          else if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                listTopPadding,
                16,
                24,
              ),
              children: listChildren,
            ),
          ),
        ],
      ),
    );
  }
}

class SessionResultsScreen extends StatefulWidget {
  final Race race;

  const SessionResultsScreen({required this.race, super.key});

  @override
  State<SessionResultsScreen> createState() => _SessionResultsScreenState();
}

class _SessionResultsScreenState extends State<SessionResultsScreen> {
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _ensureDataLoaded();
  }

  Future<void> _ensureDataLoaded() async {
    setState(() => _isFetching = true);
    final roundIndex = raceRoundFor(widget.race);
    await SessionDataManager().ensureRaceDataAvailable(widget.race, roundIndex);
    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _refreshData() async {
    setState(() => _isFetching = true);
    final roundIndex = raceRoundFor(widget.race);
    await SessionDataManager().fetchDataForRace(widget.race, roundIndex);
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {

    final scheme = Theme.of(context).colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      0.04,
    )!;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final scrollTop = desktopShell ? 20.0 : topInset + 20;
    final scrollPadding = EdgeInsets.fromLTRB(16, scrollTop, 16, 16);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: !desktopShell,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: !desktopShell,
        title: Text(
          "🏁 ${l10nGrandPrix(context.l10n, widget.race.name)} - 📊 ${context.l10n.session_results}",
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: _isFetching
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: scrollPadding,
                            children: [
                              _buildSessionResultsSkeleton(
                                context,
                                race: widget.race,
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: scrollPadding,
                      child: widget.race.hasSprint
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 1',
                                  displayTitle: context.l10n.fp1,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Sprint Qualifying',
                                  displayTitle: context.l10n.sprint_quali,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Qualifying',
                                  displayTitle: context.l10n.qualifying,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Sprint',
                                  displayTitle: context.l10n.sprint,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Race',
                                  displayTitle: '🏁 Race',
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 1',
                                  displayTitle: context.l10n.fp1,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 2',
                                  displayTitle: context.l10n.fp2,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 3',
                                  displayTitle: context.l10n.fp3,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Qualifying',
                                  displayTitle: context.l10n.qualifying,
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Race',
                                  displayTitle: '🏁 Race',
                                ),
                              ],
                            ),
                    ),
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

class SingleSessionResultsScreen extends StatefulWidget {
  final Race race;
  final String sessionName;
  final String displayTitle;

  const SingleSessionResultsScreen({
    required this.race,
    required this.sessionName,
    required this.displayTitle,
    super.key,
  });

  @override
  State<SingleSessionResultsScreen> createState() =>
      _SingleSessionResultsScreenState();
}

class _SingleSessionResultsScreenState
    extends State<SingleSessionResultsScreen> {
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _ensureDataLoaded();
  }

  Future<void> _ensureDataLoaded() async {
    setState(() => _isFetching = true);
    final roundIndex = raceRoundFor(widget.race);
    await SessionDataManager().ensureRaceDataAvailable(widget.race, roundIndex);
    if (mounted) {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isFetching = true);
    final roundIndex = raceRoundFor(widget.race);
    await SessionDataManager().fetchDataForRace(widget.race, roundIndex);
    if (mounted) {
      setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final desktopShell = _isDesktopShellLayout(context);
    final ambientGlow = scheme.primary.withValues(
      alpha: desktopShell ? 0.10 : 0.13,
    );
    final shellBase = Color.lerp(
      scheme.surfaceContainerLow,
      scheme.primary,
      0.04,
    )!;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final scrollTop = desktopShell ? 20.0 : topInset + 20;
    final scrollPadding = EdgeInsets.fromLTRB(16, scrollTop, 16, 16);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: !desktopShell,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: desktopShell ? scheme.onSurface : null,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: !desktopShell,
        title: Text(widget.displayTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!desktopShell)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: shellBase),
                child: CustomPaint(
                  painter: _AmbientGlowPainter(
                    topLeftGlow: ambientGlow,
                    bottomRightGlow: ambientGlow,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: _isFetching
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: scrollPadding,
                      children: [
                        _buildSessionResultsSkeleton(
                          context,
                          race: widget.race,
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: scrollPadding,
                      child: OpenF1SessionWidget(
                        race: widget.race,
                        sessionName: widget.sessionName,
                        displayTitle: widget.displayTitle,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpenF1SessionWidget extends StatelessWidget {
  final Race race;
  final String sessionName;
  final String displayTitle;

  const OpenF1SessionWidget({
    required this.race,
    required this.sessionName,
    required this.displayTitle,
    super.key,
  });

  bool get _isSprintSession => sessionName == 'Sprint';
  bool get _isPracticeSession =>
      sessionName == 'Practice 1' ||
      sessionName == 'Practice 2' ||
      sessionName == 'Practice 3';
  bool get _isPracticeLikeSession =>
      _isPracticeSession ||
      sessionName == 'Qualifying' ||
      sessionName == 'Sprint Qualifying';

  void _openFullscreenRaceResults(
    BuildContext context,
    List<RaceResultRow> rows,
  ) {
    if (rows.isEmpty) {
      return;
    }
    context.push(_fullscreenRaceResultsPath(race));
  }

  String? _tyreAssetPath(String compound) {
    switch (compound.toUpperCase()) {
      case 'SOFT':
      case 'SOFTS':
      case 'RED':
        return 'assets/tires/F1_tire_Pirelli_PZero_Red.svg';
      case 'MEDIUM':
      case 'YELLOW':
        return 'assets/tires/F1_tire_Pirelli_PZero_Yellow.svg';
      case 'HARD':
      case 'WHITE':
        return 'assets/tires/F1_tire_Pirelli_PZero_White.svg';
      case 'INTER':
      case 'INTERMEDIATE':
      case 'GREEN':
        return 'assets/tires/F1_tire_Pirelli_Cinturato_Green.svg';
      case 'WET':
      case 'BLUE':
        return 'assets/tires/F1_tire_Pirelli_Cinturato_Blue.svg';
      default:
        return null;
    }
  }

  String _baseTyreCompound(String compound) {
    return compound
        .replaceAll(RegExp(r'\s*\(used\)\s*', caseSensitive: false), '')
        .trim();
  }

  /// Pirelli-style solid fills (soft / medium / hard / inter / wet).
  Color? _tyrePirelliFillColor(String compound) {
    switch (_baseTyreCompound(compound).toUpperCase()) {
      case 'SOFT':
      case 'SOFTS':
      case 'RED':
        return const Color(0xFFE10600);
      case 'MEDIUM':
      case 'YELLOW':
        return const Color(0xFFFFD200);
      case 'HARD':
      case 'WHITE':
        return const Color(0xFFE8E8E8);
      case 'INTER':
      case 'INTERMEDIATE':
      case 'GREEN':
        return const Color(0xFF00A651);
      case 'WET':
      case 'BLUE':
        return const Color(0xFF00AEEF);
      default:
        return null;
    }
  }

  Widget _buildTyreCell(BuildContext context, String compound) {
    final theme = Theme.of(context);
    final normalized = compound.trim();
    final baseCompound = _baseTyreCompound(normalized);
    final isUsedTyre = normalized.toLowerCase().contains('(used)');
    final isUnknown = normalized.isEmpty || normalized == '-';
    final fill = _tyrePirelliFillColor(baseCompound);

    if (isUnknown) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    if (fill != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Semantics(
                label: '$baseCompound tyre',
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              if (isUsedTyre) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'used',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final assetPath = _tyreAssetPath(baseCompound);
    if (assetPath != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                assetPath,
                width: 34,
                height: 20,
                fit: BoxFit.contain,
                semanticsLabel: '$baseCompound tyre',
              ),
              if (isUsedTyre) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'used',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF90A4AE),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            normalized,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.surface,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  List<SessionTyreLapBreakdownEntry> _fallbackTyreLapSequence(
    Map<String, int> tyreLaps,
  ) {
    const compoundOrder = <String>[
      'Soft',
      'Medium',
      'Hard',
      'Intermediate',
      'Wet',
    ];

    final orderedEntries = <SessionTyreLapBreakdownEntry>[];
    for (final compound in compoundOrder) {
      final laps = tyreLaps[compound];
      if (laps != null && laps > 0) {
        orderedEntries.add(
          SessionTyreLapBreakdownEntry(
            compound: compound,
            laps: laps,
            usedTyre: false,
          ),
        );
      }
    }

    for (final entry in tyreLaps.entries) {
      if (entry.value <= 0 || compoundOrder.contains(entry.key)) {
        continue;
      }
      orderedEntries.add(
        SessionTyreLapBreakdownEntry(
          compound: entry.key,
          laps: entry.value,
          usedTyre: false,
        ),
      );
    }

    return orderedEntries;
  }

  Widget _buildTyreLapBreakdownCell(
    BuildContext context,
    List<SessionTyreLapBreakdownEntry> tyreLapSequence,
    Map<String, int> tyreLaps,
  ) {
    final theme = Theme.of(context);
    final orderedEntries = tyreLapSequence.isNotEmpty
        ? tyreLapSequence
              .where((entry) => entry.laps > 0)
              .toList(growable: false)
        : _fallbackTyreLapSequence(tyreLaps);

    if (orderedEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < orderedEntries.length; index++) ...[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '→',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              _buildTyreLapEntryChip(context, orderedEntries[index]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTyreLapEntryChip(
    BuildContext context,
    SessionTyreLapBreakdownEntry entry,
  ) {

    final theme = Theme.of(context);
    final fill = _tyrePirelliFillColor(entry.compound);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fill != null)
          Semantics(
            label: '${entry.compound} ${context.l10n.tyre}',
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
            ),
          )
        else
          Text(
            entry.compound,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          '${entry.laps}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: entry.usedTyre
                ? const Color(0xFFEF6C00)
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  List<SessionTyreLapBreakdownEntry> _raceTyreLapSequence(RaceResultRow row) {
    if (row.tyreStints.isNotEmpty) {
      return row.tyreStints
          .map((stint) {
            final compound = _formatTyreCompound(stint['compound']?.toString());
            int laps = _asInt(stint['laps']) ?? 0;
            // Als laps ontbreekt, bereken op basis van lapStart en lapEnd
            if (laps == 0 && stint['lapStart'] != null && stint['lapEnd'] != null) {
              final start = _asInt(stint['lapStart']);
              final end = _asInt(stint['lapEnd']);
              if (start != null && end != null && end >= start) {
                laps = end - start + 1;
              }
            }
            return SessionTyreLapBreakdownEntry(
              compound: compound,
              laps: laps,
              usedTyre: stint['usedTyre'] == true,
            );
          })
          .where((entry) => entry.compound != '-' && entry.laps > 0)
          .toList(growable: false);
    }

    return row.tyreCompounds
        .map((compound) {
          return SessionTyreLapBreakdownEntry(
            compound: compound,
            laps: 0,
            usedTyre: false,
          );
        })
        .where(
          (entry) => entry.compound.trim().isNotEmpty && entry.compound != '-',
        )
        .toList(growable: false);
  }

  String _racePenaltyText(RaceResultRow row) {
    final directPenalty = row.penalty.trim();
    if (directPenalty.isNotEmpty &&
        directPenalty != '-' &&
        directPenalty != '0' &&
        directPenalty != '0.0') {
      return directPenalty;
    }

    final detailPenalties = row.penaltyDetails
        .map((detail) => detail['penalty']?.toString().trim() ?? '')
        .where((penalty) => penalty.isNotEmpty && penalty != '-')
        .toSet()
        .toList(growable: false);
    if (detailPenalties.isNotEmpty) {
      return detailPenalties.join(', ');
    }

    return '-';
  }

  Color? _racePositionDeltaColor(BuildContext context, String finish) {
    final match = RegExp(r'\(([+-]\d+)\)').firstMatch(finish);
    final delta = match == null ? null : int.tryParse(match.group(1)!);
    if (delta == null || delta == 0) return null;
    final tokens = _themeTokens(context);
    return delta > 0 ? tokens.statusSuccess : tokens.statusError;
  }

  Widget _buildRaceFinishCell(
    BuildContext context,
    String finish, {
    TextAlign align = TextAlign.right,
  }) {
    final theme = Theme.of(context);
    final baseColor = finish == 'DNF' ||
            finish == 'DNS' ||
            finish == 'NC' ||
            finish == 'DSQ'
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final deltaMatch = RegExp(r'^(.*?)(\s*\(([+-]\d+)\))$').firstMatch(finish);
    final deltaColor = _racePositionDeltaColor(context, finish);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : align == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: RichText(
              textAlign: align,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: baseColor,
                ),
                children: deltaMatch == null
                    ? [TextSpan(text: finish)]
                    : [
                        TextSpan(text: deltaMatch.group(1) ?? finish),
                        TextSpan(
                          text: deltaMatch.group(2) ?? '',
                          style: TextStyle(color: deltaColor ?? baseColor),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceTyreStrategyCell(BuildContext context, RaceResultRow row) {
    final sequence = _raceTyreLapSequence(row);
    // Toon breakdown met aantal ronden per compound als die data er is
    if (sequence.isNotEmpty) {
      return _buildTyreLapBreakdownCell(
        context,
        sequence,
        const <String, int>{},
      );
    }

    // Fallback: alleen compound tonen als geen breakdown mogelijk is
    if (row.tyreCompounds.isNotEmpty) {
      final uniqueCompounds = row.tyreCompounds.toSet().toList();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < uniqueCompounds.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '→',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                SizedBox(
                  width: 48, // vaste breedte voor elke band
                  child: _buildTyreCell(context, uniqueCompounds[i]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildTyreCell(context, row.tyreCompound);
  }

  bool _useCompactRaceResultsLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.orientation == Orientation.portrait &&
        mediaQuery.size.width <= 460;
  }

  Widget _buildCompactRaceDetailRow(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildCompactRaceResultsList(
    BuildContext context,
    List<RaceResultRow> rows,
  ) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = _themeTokens(context);

    Widget buildValueText(String value, {bool strong = false, Color? color}) {
      return Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          color: color ?? theme.colorScheme.onSurface,
        ),
      );
    }

    Widget buildCompactHeaderCell(
      String label, {
      int flex = 1,
      TextAlign align = TextAlign.left,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _hubReadableAccent(context),
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C25) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D2430)
                      : const Color(0xFFEAF5FF),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    buildCompactHeaderCell(context.l10n.driver, flex: 6),
                    buildCompactHeaderCell(
                      context.l10n.finish,
                      flex: 4,
                      align: TextAlign.center,
                    ),
                    buildCompactHeaderCell(
                      context.l10n.time,
                      flex: 4,
                      align: TextAlign.right,
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              ...rows.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                final penaltyText = _racePenaltyText(row);

                return Container(
                  decoration: BoxDecoration(
                    color: rowIndex.isEven
                        ? Colors.transparent
                        : (isDark
                              ? const Color(0xFF141922)
                              : const Color(0xFFF8FBFF)),
                    border: rowIndex == rows.length - 1
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                              width: 0.8,
                            ),
                          ),
                  ),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    collapsedShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    iconColor: theme.colorScheme.primary,
                    collapsedIconColor: theme.colorScheme.primary,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    minTileHeight: 44,
                    title: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            row.driver,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: _buildRaceFinishCell(
                            context,
                            row.finish,
                            align: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Text(
                            row.timeOrGap,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _hubReadableAccent(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.start,
                        child: buildValueText(
                          row.start.trim().isEmpty || row.start == '-'
                              ? '-'
                              : (RegExp(r'^\d+$').hasMatch(row.start.trim())
                                    ? 'P${row.start.trim()}'
                                    : row.start),
                          strong: true,
                        ),
                      ),
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.best_lap,
                        child: buildValueText(
                          row.fastestLap,
                          strong: row.hasFastestLap,
                          color: row.hasFastestLap
                              ? const Color(0xFF8E24AA)
                              : null,
                        ),
                      ),
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.cfield_pitstop_record_detail,
                        child: buildValueText(
                          RaceResultRow.formatOpenF1PitStopsLine(row.pitStops),
                        ),
                      ),
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.tyre,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: tokens.panel.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _buildRaceTyreStrategyCell(context, row),
                        ),
                      ),
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.points,
                        child: buildValueText(row.points, strong: true),
                      ),
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.penalty,
                        child: buildValueText(
                          penaltyText,
                          strong: penaltyText != '-',
                          color: penaltyText != '-'
                              ? const Color(0xFFF57C00)
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSessionOverviewList(
    BuildContext context,
    List<SessionOverviewRow> rows,
  ) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = _themeTokens(context);

    Widget buildValueText(String value, {bool strong = false, Color? color}) {
      return Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          color: color ?? theme.colorScheme.onSurface,
        ),
      );
    }

    Widget buildCompactHeaderCell(
      String label, {
      int flex = 1,
      TextAlign align = TextAlign.left,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _hubReadableAccent(context),
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    Widget buildDetailPanel(Widget child) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tokens.panel.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );
    }

    String headerTitle() {
      if (_isPracticeSession) {
        return context.l10n.time;
      }
      return _isPracticeLikeSession
          ? context.l10n.time
          : context.l10n.result;
    }

    String? qualifyingEliminationLabel(int rowIndex, int totalRows) {
      if (sessionName != 'Qualifying' || totalRows < 13) {
        return null;
      }
      if (rowIndex >= totalRows - 6) {
        return context.l10n.q1_out;
      }
      if (rowIndex >= totalRows - 12) {
        return context.l10n.q2_out;
      }
      return null;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C25) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D2430)
                      : const Color(0xFFEAF5FF),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    buildCompactHeaderCell(context.l10n.driver, flex: 6),
                    buildCompactHeaderCell(
                      context.l10n.pos,
                      flex: 3,
                      align: TextAlign.center,
                    ),
                    buildCompactHeaderCell(
                      headerTitle(),
                      flex: 5,
                      align: TextAlign.right,
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              ...rows.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                final eliminationLabel = qualifyingEliminationLabel(
                  rowIndex,
                  rows.length,
                );
                final resultColor = row.hasFastestLap
                    ? const Color(0xFF8E24AA)
                    : theme.colorScheme.primary;

                return Container(
                  decoration: BoxDecoration(
                    color: rowIndex.isEven
                        ? Colors.transparent
                        : (isDark
                              ? const Color(0xFF141922)
                              : const Color(0xFFF8FBFF)),
                    border: rowIndex == rows.length - 1
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                              width: 0.8,
                            ),
                          ),
                  ),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    collapsedShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    iconColor: theme.colorScheme.primary,
                    collapsedIconColor: theme.colorScheme.primary,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    minTileHeight: 44,
                    title: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.driver,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (row.hasFastestLap) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Color(0xFF8E24AA),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            row.position,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: Text(
                            row.result,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: resultColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      if (_isPracticeSession)
                        _buildCompactRaceDetailRow(
                          context,
                          label: context.l10n.laps,
                          child: buildValueText(
                            row.totalLaps?.toString() ?? '-',
                            strong: true,
                          ),
                        ),
                      _buildCompactRaceDetailRow(
                        context,
                        label: context.l10n.tyre,
                        child: buildDetailPanel(
                          _isPracticeSession
                              ? _buildTyreLapBreakdownCell(
                                  context,
                                  row.tyreLapSequence,
                                  row.tyreLaps,
                                )
                              : _buildTyreCell(context, row.tyreCompound),
                        ),
                      ),
                      if (!_isPracticeSession && eliminationLabel != null)
                        _buildCompactRaceDetailRow(
                          context,
                          label: context.l10n.status,
                          child: buildValueText(
                            eliminationLabel,
                            strong: true,
                            color: eliminationLabel == context.l10n.q1_out
                                ? tokens.statusError
                                : tokens.statusWarning,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyResultsTable(
    BuildContext context, {
    required List<double> preferredColumnWidths,
    required List<Widget> headerCells,
    required List<List<Widget>> rows,
    required Color headerColor,
    required Color borderColor,
    required Color Function(int rowIndex) rowBackgroundBuilder,
  }) {
    const headerHeight = 48.0;
    const bodyRowHeight = 46.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolvedColumnWidths = _resolveResponsiveColumnWidths(
              constraints.maxWidth,
              preferredColumnWidths,
            );
            final bodyRowCount = rows.isEmpty ? 1 : rows.length;
            final tableHeight =
                headerHeight + (bodyRowCount * bodyRowHeight);
            final lastRowIndex = rows.length;
            final lastColumnIndex = headerCells.length - 1;

            return SizedBox(
              height: tableHeight,
              child: TableView.builder(
                diagonalDragBehavior: DiagonalDragBehavior.free,
                pinnedRowCount: 1,
                pinnedColumnCount: 1,
                columnCount: headerCells.length,
                rowCount: rows.length + 1,
                columnBuilder: (column) => TableSpan(
                  extent: FixedTableSpanExtent(resolvedColumnWidths[column]),
                ),
                rowBuilder: (row) => TableSpan(
                  extent: FixedTableSpanExtent(
                    row == 0 ? headerHeight : bodyRowHeight,
                  ),
                ),
                cellBuilder: (context, vicinity) {
                  final row = vicinity.row;
                  final column = vicinity.column;
                  final backgroundColor = row == 0
                      ? headerColor
                      : rowBackgroundBuilder(row - 1);
                  final showRightBorder = column < lastColumnIndex;
                  final showBottomBorder = row < lastRowIndex;
                  final cellChild = row == 0
                      ? headerCells[column]
                      : rows[row - 1][column];

                  return TableViewCell(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border(
                          right: showRightBorder
                              ? BorderSide(color: borderColor, width: 0.8)
                              : BorderSide.none,
                          bottom: showBottomBorder
                              ? BorderSide(color: borderColor, width: 0.8)
                              : BorderSide.none,
                        ),
                      ),
                      child: cellChild,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  List<double> _resolveResponsiveColumnWidths(
    double availableWidth,
    List<double> preferredWidths,
  ) {
    final totalPreferredWidth = preferredWidths.fold<double>(
      0,
      (sum, width) => sum + width,
    );

    if (availableWidth <= totalPreferredWidth) {
      return preferredWidths;
    }

    final scale = availableWidth / totalPreferredWidth;
    return preferredWidths
        .map((width) => width * scale)
        .toList(growable: false);
  }

  Widget _buildSessionOverviewTable(
    BuildContext context,
    List<SessionOverviewRow> rows,
  ) {
    if (_useCompactRaceResultsLayout(context) && !_isSprintSession) {
      return _buildCompactSessionOverviewList(context, rows);
    }

    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final headerColor = theme.colorScheme.primaryContainer;
    final borderColor = tokens.borderSubtle;

    Widget buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: _hubReadableAccent(context),
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    Widget buildBodyCell(
      String value, {
      TextAlign align = TextAlign.left,
      bool strong = false,
      Color? color,
      Widget? leading,
      Widget? trailing,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: align == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 4)],
            Flexible(
              child: Text(
                value,
                textAlign: align,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing],
          ],
        ),
      );
    }

    Widget buildQualifyingBadge(
      String label,
      Color background,
      Color foreground,
    ) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: foreground,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    String? qualifyingEliminationLabel(int rowIndex, int totalRows) {
      if (sessionName != 'Qualifying' || totalRows < 13) {
        return null;
      }
      if (rowIndex >= totalRows - 6) {
        return 'Q1 out';
      }
      if (rowIndex >= totalRows - 12) {
        return 'Q2 out';
      }
      return null;
    }

    final preferredColumnWidths = _isSprintSession
        ? const <double>[180, 62, 140, 132, 110, 58]
        : _isPracticeSession
        ? const <double>[160, 48, 104, 72, 250]
        : const <double>[154, 48, 92, 104];

    final headerCells = _isSprintSession
        ? <Widget>[
            buildHeaderCell('Coureur'),
            buildHeaderCell('Finish', align: TextAlign.right),
            buildHeaderCell('Tijd / Verschil'),
            buildHeaderCell('Band'),
            buildHeaderCell('Snelste ronde'),
            buildHeaderCell('Punten', align: TextAlign.right),
          ]
        : _isPracticeSession
        ? <Widget>[
            buildHeaderCell('Coureur'),
            buildHeaderCell('Pos', align: TextAlign.right),
            buildHeaderCell('Tijd'),
            buildHeaderCell('Rondes', align: TextAlign.right),
            buildHeaderCell('Band'),
          ]
        : <Widget>[
            buildHeaderCell('Coureur'),
            buildHeaderCell('Pos', align: TextAlign.right),
            buildHeaderCell(_isPracticeLikeSession ? 'Tijd' : 'Resultaat'),
            buildHeaderCell('Band'),
          ];

    final tableRows = rows
        .asMap()
        .entries
        .map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          final timerIcon = row.hasFastestLap
              ? Icon(Icons.timer, size: 14, color: theme.colorScheme.tertiary)
              : null;
          final eliminationLabel = qualifyingEliminationLabel(
            rowIndex,
            rows.length,
          );
          final eliminationBadge = eliminationLabel == null
              ? null
              : buildQualifyingBadge(
                  eliminationLabel,
                  eliminationLabel == 'Q1 out'
                      ? tokens.statusError.withValues(alpha: 0.12)
                      : tokens.statusWarning.withValues(alpha: 0.12),
                  eliminationLabel == 'Q1 out'
                      ? tokens.statusError
                      : tokens.statusWarning,
                );

          return _isSprintSession
              ? <Widget>[
                  buildBodyCell(row.driver, strong: true, leading: timerIcon),
                  buildBodyCell(
                    row.position,
                    align: TextAlign.right,
                    strong: true,
                  ),
                  buildBodyCell(row.result),
                  _buildTyreCell(context, row.tyreCompound),
                  buildBodyCell(
                    row.fastestLap,
                    strong: row.hasFastestLap,
                    color: row.hasFastestLap ? theme.colorScheme.tertiary : null,
                  ),
                  buildBodyCell(
                    row.points,
                    align: TextAlign.right,
                    strong: true,
                  ),
                ]
              : _isPracticeSession
              ? <Widget>[
                  buildBodyCell(row.driver, strong: true, leading: timerIcon),
                  buildBodyCell(
                    row.position,
                    align: TextAlign.right,
                    strong: true,
                  ),
                  buildBodyCell(
                    row.result,
                    strong: row.hasFastestLap,
                    color: row.hasFastestLap ? theme.colorScheme.tertiary : null,
                  ),
                  buildBodyCell(
                    row.totalLaps?.toString() ?? '-',
                    align: TextAlign.right,
                    strong: true,
                  ),
                  _buildTyreLapBreakdownCell(
                    context,
                    row.tyreLapSequence,
                    row.tyreLaps,
                  ),
                ]
              : <Widget>[
                  buildBodyCell(
                    row.driver,
                    strong: true,
                    leading: timerIcon,
                    trailing: eliminationBadge,
                  ),
                  buildBodyCell(
                    row.position,
                    align: TextAlign.right,
                    strong: true,
                  ),
                  buildBodyCell(
                    row.result,
                    strong: row.hasFastestLap,
                    color: row.hasFastestLap ? theme.colorScheme.tertiary : null,
                  ),
                  _buildTyreCell(context, row.tyreCompound),
                ];
        })
        .toList(growable: false);

    return _buildStickyResultsTable(
      context,
      preferredColumnWidths: preferredColumnWidths,
      headerCells: headerCells,
      rows: tableRows,
      headerColor: headerColor,
      borderColor: borderColor,
      rowBackgroundBuilder: (rowIndex) {
        final eliminationLabel = qualifyingEliminationLabel(
          rowIndex,
          rows.length,
        );
        if (eliminationLabel == 'Q1 out') {
          return tokens.statusError.withValues(alpha: 0.08);
        }
        if (eliminationLabel == 'Q2 out') {
          return tokens.statusWarning.withValues(alpha: 0.08);
        }
        return rowIndex.isEven
            ? Colors.transparent
            : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5);
      },
    );
  }

  Widget _buildRaceResultsTable(
    BuildContext context,
    List<RaceResultRow> rows,
  ) {
    if (_useCompactRaceResultsLayout(context)) {
      return _buildCompactRaceResultsList(context, rows);
    }

    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final headerColor = theme.colorScheme.primaryContainer;
    final borderColor = tokens.borderSubtle;

    Widget buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: _hubReadableAccent(context),
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    Widget buildBodyCell(
      String value, {
      TextAlign align = TextAlign.left,
      bool strong = false,
      Color? color,
      Widget? trailing,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: align == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                value,
                textAlign: align,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), trailing],
          ],
        ),
      );
    }

    Widget buildFastestLapCell(RaceResultRow row) {
      return buildBodyCell(
        row.fastestLap,
        strong: row.hasFastestLap,
        color: row.hasFastestLap ? theme.colorScheme.tertiary : null,
      );
    }

    final headerCells = <Widget>[
      buildHeaderCell('Coureur'),
      buildHeaderCell('Start', align: TextAlign.right),
      buildHeaderCell('Finish', align: TextAlign.right),
      buildHeaderCell('Tijd / Verschil'),
      buildHeaderCell('Straf'),
      buildHeaderCell('Band'),
      buildHeaderCell('Snelste ronde'),
      buildHeaderCell('Punten', align: TextAlign.right),
    ];

    final tableRows = rows
        .map((row) {
          final penaltyText = _racePenaltyText(row);
          final hasPenalty = penaltyText != '-';

          return <Widget>[
            buildBodyCell(
              row.driver,
              strong: true,
              trailing: row.hasFastestLap
                  ? const Icon(Icons.timer, size: 14, color: Color(0xFF8E24AA))
                  : null,
            ),
            buildBodyCell(row.start, align: TextAlign.right),
            _buildRaceFinishCell(context, row.finish, align: TextAlign.right),
            buildBodyCell(row.timeOrGap),
            buildBodyCell(
              penaltyText,
              strong: hasPenalty,
              color: hasPenalty ? const Color(0xFFF57C00) : null,
            ),
            _buildRaceTyreStrategyCell(context, row),
            buildFastestLapCell(row),
            buildBodyCell(row.points, align: TextAlign.right, strong: true),
          ];
        })
        .toList(growable: false);

    return _buildStickyResultsTable(
      context,
      preferredColumnWidths: const [170, 58, 92, 132, 88, 220, 102, 58],
      headerCells: headerCells,
      rows: tableRows,
      headerColor: headerColor,
      borderColor: borderColor,
      rowBackgroundBuilder: (rowIndex) => rowIndex.isEven
          ? Colors.transparent
          : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
    );
  }

  Widget _buildResultRow(SessionResult res, int index) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  'P$index.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  res.driver,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ),
              Text(
                res.time,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  getTireEmoji(res.tyre),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = '${race.country}_${sessionName}_${race.date.year}';
    final raceResultsKey = SessionDataManager().raceResultsKeyFor(race);
    final sessionOverviewKey = SessionDataManager().sessionOverviewKeyFor(
      race,
      sessionName,
    );
    DateTime sessionTime;

    if (sessionName == 'Practice 1') {
      sessionTime = race.fp1;
    } else if (sessionName == 'Practice 2') {
      sessionTime = race.fp2;
    } else if (sessionName == 'Practice 3') {
      sessionTime = race.fp3;
    } else if (sessionName == 'Sprint Qualifying') {
      sessionTime = race.sprintQuali;
    } else if (sessionName == 'Sprint') {
      sessionTime = race.sprintRace;
    } else if (sessionName == 'Qualifying') {
      sessionTime = race.qualifying;
    } else {
      sessionTime = race.date;
    }

    return AnimatedBuilder(
      animation: SessionDataManager(),
      builder: (context, child) {
    
        final results = SessionDataManager().cache[key];
        final raceResults =
            SessionDataManager().raceResultsCache[raceResultsKey];
        final sessionOverview =
            SessionDataManager().sessionOverviewCache[sessionOverviewKey];

        Widget buildEmpty(String title, String subtitle) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _hubReadableAccent(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ],
          ),
        );

        final hasRaceData = raceResults != null && raceResults.isNotEmpty;
        final hasSessionData = (sessionOverview != null && sessionOverview.isNotEmpty) ||
            (results != null && results.isNotEmpty);

        if (sessionName == 'Race' && sessionTime.isAfter(DateTime.now()) && !hasRaceData) {
          return const SizedBox.shrink();
        }
        if (sessionTime.isAfter(DateTime.now()) && !hasRaceData && !hasSessionData) {
          return buildEmpty(
            displayTitle,
            '${context.l10n.session_future} ${sessionTime.toString().substring(0, 16)}',
          );
        }
        if (results == null && !SessionDataManager().isInitialized) {
          return _buildSessionWidgetSkeleton(context, displayTitle);
        }
        if (sessionName == 'Race') {
          if (raceResults == null || raceResults.isEmpty) {
            return buildEmpty(displayTitle, context.l10n.no_data_yet);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _hubReadableAccent(context),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: context.l10n.fullscreen_table,
                      onPressed: () =>
                          _openFullscreenRaceResults(context, raceResults),
                    ),
                  ],
                ),
              ),
              _buildRaceResultsTable(context, raceResults),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ],
          );
        }
        if (sessionOverview != null && sessionOverview.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hubReadableAccent(context),
                  ),
                ),
              ),
              _buildSessionOverviewTable(context, sessionOverview),
              Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ],
          );
        }
        if (results == null || results.isEmpty) {
          return buildEmpty(displayTitle, context.l10n.no_data_yet);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
              child: Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _hubReadableAccent(context),
                ),
              ),
            ),

            ...results
                .asMap()
                .entries
                .map((e) => _buildResultRow(e.value, e.key + 1)),

            const SizedBox(height: 8),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          ],
        );
      },
    );
  }
}

class FullscreenRaceResultsScreen extends StatefulWidget {
  final Race race;
  final String title;

  const FullscreenRaceResultsScreen({
    super.key,
    required this.race,
    required this.title,
  });

  @override
  State<FullscreenRaceResultsScreen> createState() =>
      _FullscreenRaceResultsScreenState();
}

class _FullscreenRaceResultsScreenState
    extends State<FullscreenRaceResultsScreen> {
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _ensureDataLoaded();
  }

  Future<void> _ensureDataLoaded() async {
    setState(() => _isFetching = true);
    final roundIndex = raceRoundFor(widget.race);
    await SessionDataManager().ensureRaceDataAvailable(widget.race, roundIndex);
    if (mounted) {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isFetching = true);
    final roundIndex = raceRoundFor(widget.race);
    await SessionDataManager().fetchDataForRace(widget.race, roundIndex);
    if (mounted) {
      setState(() => _isFetching = false);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableWidget = OpenF1SessionWidget(
      race: widget.race,
      sessionName: 'Race',
      displayTitle: widget.title,
    );
    final raceResultsKey = SessionDataManager().raceResultsKeyFor(widget.race);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: AnimatedBuilder(
          animation: SessionDataManager(),
          builder: (context, _) {
            final raceResults =
                SessionDataManager().raceResultsCache[raceResultsKey] ??
                const <RaceResultRow>[];

            if (_isFetching && raceResults.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 24),
                  _buildSessionResultsSkeleton(context, race: widget.race),
                ],
              );
            }

            if (raceResults.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Center(child: Text(context.l10n.race_results_empty)),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;

                return InteractiveViewer(
                  constrained: false,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: SizedBox(
                    width: viewportWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: tableWidget._buildRaceResultsTable(
                        context,
                        raceResults,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Full-page profile route with theme settings and favorites. Syncs to Supabase on change.
/// Shown as 4th tab in main navigation (Circuits | Drivers | Teams | Profile).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.settingsMenu});

  final Widget settingsMenu;
  static const double _maxContentWidth = 1000;
  static const double _twoColumnBreakpoint = 720;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<String> _teamNames = [];
  List<String> _driverNames = [];
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final teams = await ProfileFavoritesService.instance.loadTeamNames();
    final drivers = await ProfileFavoritesService.instance.loadDriverNames();
    String? avatarUrl;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (row != null) {
          final raw = row['avatar_url'];
          if (raw is String && raw.trim().isNotEmpty) {
            avatarUrl = raw.trim();
          }
        }
      } catch (_) {
        // RLS or network: keep placeholder avatar
      }
    }
    if (mounted) {
      setState(() {
        _teamNames = teams;
        _driverNames = drivers;
        _avatarUrl = avatarUrl;
      });
    }
  }

  void _saveFavorites(ProfileFavorites next) {
    context.read<ProfileFavoritesNotifier>().update(next);
    ProfileFavoritesService.instance.saveToSupabase(next);
  }

  @override
  Widget build(BuildContext context) {
    // Subscribes to locale (rebuild when app language changes).
    final _ = Localizations.localeOf(context);
    final user = Supabase.instance.client.auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          context.l10n.profile,
          style: HubVisualLanguage.f1Wide(
            context,
            fontSize: 22,
            height: 1.05,
            color: HubTheme.primaryOnGlassText(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: HubTheme.primaryOnGlassText(context),
        actions: _desktopAwareSettingsActions(context, widget.settingsMenu),
      ),
      body: user != null
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ProfileScreen._maxContentWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol =
                        constraints.maxWidth >= ProfileScreen._twoColumnBreakpoint;
                    Widget profileRow(Widget a, Widget b) {
                      if (!twoCol) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            a,
                            const SizedBox(height: 24),
                            b,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: a),
                          const SizedBox(width: 24),
                          Expanded(child: b),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Consumer<ThemeController>(
                        builder: (_, controller, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProfileUserCard(
                                email: user.email ?? user.phone ?? '',
                                avatarUrl: _avatarUrl,
                              ),
                              const SizedBox(height: 16),
                              HubVisualLanguage.glassPanel(
                                context: context,
                                accentGlow: scheme.primary,
                                accentGlowOpacity: 0.06,
                                padding: EdgeInsets.zero,
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    leading: Icon(
                                      Icons.dashboard_customize_outlined,
                                      color: HubTheme.iconOnGlass(context),
                                    ),
                                    title: Text(
                                      context.l10n.my_paddock_title,
                                      style:
                                          HubVisualLanguage.titilliumSecondary(
                                        context,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: HubTheme.iconOnGlass(context),
                                    ),
                                    onTap: () => context.push(_myPaddockPath()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              profileRow(
                                const _ProfileLanguageCard(),
                                const _ProfileCalendarPrefsCard(),
                              ),
                              const SizedBox(height: 24),
                              const _ProfileAiStrategistPrefsCard(),
                              const SizedBox(height: 24),
                              Consumer<ProfileFavoritesNotifier>(
                                builder: (_, notifier, child) =>
                                    _ProfileFavoritesCard(
                                  teamNames: _teamNames,
                                  driverNames: _driverNames,
                                  favorites: notifier.value,
                                  onFavoritesChanged: _saveFavorites,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _ProfileThemeModeCard(controller: controller),
                              const SizedBox(height: 24),
                              _ProfileLogoutButton(
                                onPressed: () async {
                                  await Supabase.instance.client.auth.signOut();
                                  if (context.mounted) {
                                    context.go(_circuitsPath());
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ProfileScreen._maxContentWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol =
                        constraints.maxWidth >= ProfileScreen._twoColumnBreakpoint;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Consumer<ThemeController>(
                        builder: (_, controller, _) {
                          final themeRow = twoCol
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(child: _ProfileLanguageCard()),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _ProfileThemeModeCard(
                                        controller: controller,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const _ProfileLanguageCard(),
                                    const SizedBox(height: 24),
                                    _ProfileThemeModeCard(controller: controller),
                                  ],
                                );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.login,
                                textAlign: TextAlign.center,
                                style: HubVisualLanguage.f1Wide(
                                  context,
                                  fontSize: 22,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => context.push(_loginPath()),
                                child: Text(context.l10n.login),
                              ),
                              const SizedBox(height: 24),
                              themeRow,
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _ProfileFavoritesCard extends StatelessWidget {
  final List<String> teamNames;
  final List<String> driverNames;
  final ProfileFavorites favorites;
  final ValueChanged<ProfileFavorites> onFavoritesChanged;

  const _ProfileFavoritesCard({
    required this.teamNames,
    required this.driverNames,
    required this.favorites,
    required this.onFavoritesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final circuitKeys = races.map((r) => r.name).toList();
    return _profileSectionCard(
      context,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.favorite_team,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: favorites.favoriteTeam != null && teamNames.contains(favorites.favoriteTeam)
                  ? favorites.favoriteTeam
                  : null,
              decoration: InputDecoration(
                hintText: context.l10n.select_favorite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem<String>(value: null, child: Text(context.l10n.select_favorite)),
                ...teamNames.map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => onFavoritesChanged(ProfileFavorites(
                favoriteTeam: v,
                favoriteDriver: favorites.favoriteDriver,
                favoriteCircuit: favorites.favoriteCircuit,
              )),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.favorite_driver,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: favorites.favoriteDriver != null && driverNames.contains(favorites.favoriteDriver)
                  ? favorites.favoriteDriver
                  : null,
              decoration: InputDecoration(
                hintText: context.l10n.select_favorite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem<String>(value: null, child: Text(context.l10n.select_favorite)),
                ...driverNames.map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: (v) => onFavoritesChanged(ProfileFavorites(
                favoriteTeam: favorites.favoriteTeam,
                favoriteDriver: v,
                favoriteCircuit: favorites.favoriteCircuit,
              )),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.favorite_circuit,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: favorites.favoriteCircuit != null && circuitKeys.contains(favorites.favoriteCircuit)
                  ? favorites.favoriteCircuit
                  : null,
              decoration: InputDecoration(
                hintText: context.l10n.select_favorite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem<String>(value: null, child: Text(context.l10n.select_favorite)),
                ...circuitKeys.map((key) => DropdownMenuItem(
                  value: key,
                  child: Text(
                    l10nGrandPrix(context.l10n, key),
                  ),
                )),
              ],
              onChanged: (v) => onFavoritesChanged(ProfileFavorites(
                favoriteTeam: favorites.favoriteTeam,
                favoriteDriver: favorites.favoriteDriver,
                favoriteCircuit: v,
              )),
            ),
          ],
        ),
    );
  }
}

class _ProfileUserCard extends StatelessWidget {
  static const double _avatarSize = 56;

  final String email;
  final String? avatarUrl;

  const _ProfileUserCard({
    required this.email,
    this.avatarUrl,
  });

  Widget _placeholderAvatar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: _avatarSize / 2,
      backgroundColor: scheme.primaryContainer,
      child: Icon(
        Icons.person,
        color: scheme.onPrimaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return _profileSectionCard(
      context,
      child: Row(
        children: [
          SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child: hasUrl
                ? ClipOval(
                    child: Image.network(
                      url,
                      width: _avatarSize,
                      height: _avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _placeholderAvatar(context),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return CircleAvatar(
                          radius: _avatarSize / 2,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: const HubGlassInlineLoadingPlaceholder(
                            width: 22,
                            height: 22,
                          ),
                        );
                      },
                    ),
                  )
                : _placeholderAvatar(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              email,
              style: HubVisualLanguage.titilliumSecondary(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HubTheme.primaryOnGlassText(context),
                opacity: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAiStrategistPrefsCard extends StatelessWidget {
  const _ProfileAiStrategistPrefsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<AiStrategistPrefsNotifier>(
      builder: (_, notifier, _) {
        final p = notifier.value;
        final disabled = p.cardDisabled;
        return _profileSectionCard(
          context,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.ai_prefs_section_title,
                  style: HubVisualLanguage.f1Wide(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.ai_prefs_section_subtitle,
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.ai_prefs_disable_card),
                  value: p.cardDisabled,
                  onChanged: (v) => notifier.update(p.copyWith(cardDisabled: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.ai_prefs_hide_teambattle),
                  subtitle: Text(context.l10n.ai_prefs_hide_teambattle_hint),
                  value: p.hideTeambattle,
                  onChanged: disabled
                      ? null
                      : (v) => notifier.update(p.copyWith(hideTeambattle: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.ai_prefs_hide_coach_corner),
                  subtitle: Text(context.l10n.ai_prefs_hide_coach_corner_hint),
                  value: p.hideCoachCorner,
                  onChanged: disabled
                      ? null
                      : (v) => notifier.update(p.copyWith(hideCoachCorner: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.ai_prefs_hide_team_vibe),
                  subtitle: Text(context.l10n.ai_prefs_hide_team_vibe_hint),
                  value: p.hideTeamVibe,
                  onChanged: disabled
                      ? null
                      : (v) => notifier.update(p.copyWith(hideTeamVibe: v)),
                ),
              ],
            ),
        );
      },
    );
  }
}

class _ProfileCalendarPrefsCard extends StatelessWidget {
  const _ProfileCalendarPrefsCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarPrefsNotifier>(
      builder: (_, notifier, _) {
        final p = notifier.value;
        return _profileSectionCard(
          context,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.calendar_prefs_section_title,
                  style: HubVisualLanguage.f1Wide(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.calendar_prefs_section_subtitle,
                  style: HubVisualLanguage.titilliumSecondary(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.calendar_prefs_hide_cancelled),
                  subtitle:
                      Text(context.l10n.calendar_prefs_hide_cancelled_hint),
                  value: p.hideCancelledRaces,
                  onChanged: (v) =>
                      notifier.update(p.copyWith(hideCancelledRaces: v)),
                ),
              ],
            ),
        );
      },
    );
  }
}

class _ProfileLanguageCard extends StatefulWidget {
  const _ProfileLanguageCard();

  @override
  State<_ProfileLanguageCard> createState() => _ProfileLanguageCardState();
}

class _ProfileLanguageCardState extends State<_ProfileLanguageCard> {
  Locale _selectedLocale(List<Locale> supported) {
    final current = Localizations.localeOf(context);
    return supported.firstWhere(
      (l) => l.languageCode == current.languageCode,
      orElse: () => supported.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = _f1LanguageDisplayNames(AppLocalizations.supportedLocales);
    final supported = AppLocalizations.supportedLocales;
    final value = _selectedLocale(supported);

    return _profileSectionCard(
      context,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🌐',
                  style: TextStyle(
                    fontSize: 22,
                    color: _hubReadableAccent(context),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.language,
                  style: HubVisualLanguage.f1Wide(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Locale>(
              initialValue: value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: [
                for (final loc in supported)
                  DropdownMenuItem<Locale>(
                    value: loc,
                    child: Text(labels[loc] ?? loc.languageCode),
                  ),
              ],
              onChanged: (loc) {
                if (loc != null) {
                  F1HubApp.setAppLocale(context, loc);
                }
              },
            ),
          ],
        ),
    );
  }
}

class _ProfileThemeModeCard extends StatelessWidget {
  final ThemeController controller;

  const _ProfileThemeModeCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _profileSectionCard(
      context,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.theme_mode,
              style: HubVisualLanguage.f1Wide(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(context.l10n.theme_mode_light)),
                ButtonSegment(value: ThemeMode.dark, label: Text(context.l10n.theme_mode_dark)),
                ButtonSegment(value: ThemeMode.system, label: Text(context.l10n.theme_mode_system)),
              ],
              selected: {controller.themeMode},
              onSelectionChanged: (modes) => controller.setThemeMode(modes.first),
            ),
          ],
        ),
    );
  }
}

class _ProfileLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ProfileLogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout),
      label: Text(context.l10n.logout),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
      ),
    );
  }
}

