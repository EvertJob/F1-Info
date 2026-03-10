import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'browser_bridge.dart' as browser_bridge;

part 'f1_data.dart';

@immutable
class F1ThemeTokens extends ThemeExtension<F1ThemeTokens> {
  final Color panel;
  final Color panelStrong;
  final Color outline;
  final Color accentSoft;
  final Color heroStart;
  final Color heroEnd;

  const F1ThemeTokens({
    required this.panel,
    required this.panelStrong,
    required this.outline,
    required this.accentSoft,
    required this.heroStart,
    required this.heroEnd,
  });

  @override
  F1ThemeTokens copyWith({
    Color? panel,
    Color? panelStrong,
    Color? outline,
    Color? accentSoft,
    Color? heroStart,
    Color? heroEnd,
  }) {
    return F1ThemeTokens(
      panel: panel ?? this.panel,
      panelStrong: panelStrong ?? this.panelStrong,
      outline: outline ?? this.outline,
      accentSoft: accentSoft ?? this.accentSoft,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
    );
  }

  @override
  F1ThemeTokens lerp(ThemeExtension<F1ThemeTokens>? other, double t) {
    if (other is! F1ThemeTokens) return this;

    return F1ThemeTokens(
      panel: Color.lerp(panel, other.panel, t) ?? panel,
      panelStrong: Color.lerp(panelStrong, other.panelStrong, t) ?? panelStrong,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      heroStart: Color.lerp(heroStart, other.heroStart, t) ?? heroStart,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t) ?? heroEnd,
    );
  }
}

class AppTheme {
  static const Color _primary = Color(0xFF2EA6FF);
  static const Color _secondary = Color(0xFFFF5A36);
  static const Color _tertiary = Color(0xFFFFC857);

  static final ThemeData lightTheme = _buildTheme(brightness: Brightness.light);
  static final ThemeData darkTheme = _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: brightness,
        ).copyWith(
          primary: _primary,
          secondary: _secondary,
          tertiary: _tertiary,
          surface: isDark ? const Color(0xFF11141B) : const Color(0xFFFFFFFF),
          surfaceContainerHighest: isDark
              ? const Color(0xFF1A1F29)
              : const Color(0xFFF3F6FB),
          onSurface: isDark ? const Color(0xFFF4F7FB) : const Color(0xFF11151C),
          onSurfaceVariant: isDark
              ? const Color(0xFFAAB6C8)
              : const Color(0xFF5F6B7A),
          outline: isDark ? const Color(0xFF2A3340) : const Color(0xFFD8E0EA),
        );

    final F1ThemeTokens tokens = F1ThemeTokens(
      panel: isDark ? const Color(0xFF171C25) : const Color(0xFFF8FAFD),
      panelStrong: isDark ? const Color(0xFF1D2430) : const Color(0xFFFFFFFF),
      outline: isDark ? const Color(0xFF2D3745) : const Color(0xFFDCE3ED),
      accentSoft: isDark
          ? _primary.withOpacity(0.16)
          : _primary.withOpacity(0.10),
      heroStart: isDark ? const Color(0xFF131923) : const Color(0xFFFFFFFF),
      heroEnd: isDark ? const Color(0xFF112841) : const Color(0xFFEAF5FF),
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF090C12)
          : const Color(0xFFF2F5FA),
      visualDensity: VisualDensity.standard,
    );

    final TextTheme textTheme = base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: scheme.onSurface,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.35,
        color: scheme.onSurface,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.35,
        color: scheme.onSurface,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );

    return base.copyWith(
      primaryColor: _primary,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: Colors.transparent,
      cardTheme: CardThemeData(
        color: tokens.panelStrong,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: tokens.outline.withOpacity(0.7)),
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
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: tokens.panelStrong,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.panelStrong,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.outline.withOpacity(0.8)),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF202733)
            : const Color(0xFF1C2330),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withOpacity(0.14),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: scheme.primary,
        collapsedTextColor: scheme.primary,
        iconColor: scheme.primary,
        collapsedIconColor: scheme.primary.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.outline.withOpacity(0.7)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.outline.withOpacity(0.7)),
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
        color: tokens.outline.withOpacity(0.75),
        thickness: 1,
      ),
      extensions: [tokens],
    );
  }
}

const F1ThemeTokens _fallbackThemeTokens = F1ThemeTokens(
  panel: Color(0xFFF8FAFD),
  panelStrong: Color(0xFFFFFFFF),
  outline: Color(0xFFDCE3ED),
  accentSoft: Color(0x1A2EA6FF),
  heroStart: Color(0xFFFFFFFF),
  heroEnd: Color(0xFFEAF5FF),
);

F1ThemeTokens _themeTokens(BuildContext context) =>
    Theme.of(context).extension<F1ThemeTokens>() ?? _fallbackThemeTokens;

LinearGradient _heroPanelGradient(BuildContext context) {
  final tokens = _themeTokens(context);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tokens.heroStart, tokens.heroEnd],
  );
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
    final baseColor = tokens.panel.withOpacity(0.96);
    final highlightColor = tokens.panelStrong.withOpacity(0.98);

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
  final sampleDrivers =
      driversData[DateTime.now().year] ??
      driversData.values.firstWhere(
        (drivers) => drivers.isNotEmpty,
        orElse: () => <Driver>[],
      );

  return ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 10),
    itemCount: 8,
    itemBuilder: (context, index) {
      final accentColor = isDriver
          ? _getTeamColor(
              sampleDrivers.isEmpty
                  ? 'drivers'
                  : sampleDrivers[index % sampleDrivers.length].team,
            )
          : _getTeamColor(fallbackTeams[index % fallbackTeams.length].name);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accentColor, width: 6)),
          boxShadow: isDark
              ? []
              : [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: _themeTokens(context).outline.withOpacity(0.7),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
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
  final theme = Theme.of(context);

  Widget skeletonRow(IconData icon, double valueWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
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

/// --- INTERNE LOKALISATIE MET EMOJIS -------------------------
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, String> _nlDictionary = {
    'appTitle': 'F1 Hub',
    'settings': 'Instellingen',
    'toggleTheme': 'Wissel Thema',
    'changelog': 'Changelog',
    'compare': 'Vergelijken',
    'select_drivers_to_compare': 'Selecteer 2 coureurs',
    'select_teams_to_compare': 'Selecteer 2 teams',
    'circuits': 'Circuits',
    'standings': 'Standen',
    'nextRace': 'Volgende Race',
    'startsIn': 'Start in',
    'week': 'week',
    'weeks': 'weken',
    'day': 'dag',
    'days': 'dagen',
    'hours': 'uur',
    'minutes': 'minuten',
    'sponsors': 'Sponsors',
    'drivers': 'Coureurs',
    'reserve_driver': 'Reservecoureur',
    'teams': 'Teams',
    'pts': 'PNT',
    'using_fallback_data': 'Offline/Fallback data in gebruik.',
    'points_history': 'Punten per Seizoen',
    'session_results': 'Sessie Resultaten',
    'fp1': 'Vrije Training 1',
    'fp2': 'Vrije Training 2',
    'fp3': 'Vrije Training 3',
    'sprint_quali': 'Sprint Kwalificatie',
    'sprint': 'Sprintrace',
    'qualifying': 'Kwalificatie',
    'session_future': 'Sessie begint op',
    'no_data_yet': 'Data nog niet beschikbaar of API is nog niet geüpdatet',
    'version': 'Versie',
    'weather_forecast': 'Weerverwachting',
    'circuit_info': 'Circuit Info',
    'temp': 'Temperatuur',
    'rain_chance': 'Regenkans',
    'wind_speed': 'Windsnelheid',
    'humidity': 'Luchtvochtigheid',
    'length': 'Lengte',
    'since': 'Op kalender sinds',
    'until': 'Contract tot',
    'lap_speed_stats': 'RONDE & SNELHEID',
    'risks_incidents': 'RISICO\'S & INCIDENTEN',
    'tyres_strategy': 'BANDEN & STRATEGIE',
    'characteristics': 'CIRCUIT KENMERKEN',
    'totalLength': 'Totale Lengte',
    'laps': 'Rondes',
    'fastestLap': 'Snelste Ronde',
    'slowestLap': 'Langzaamste Ronde',
    'avgLap': 'Gemiddelde Ronde',
    'topSpeed': 'Topsnelheid',
    'averageSpeed': 'Gemiddelde Snelheid',
    'avgGForce': 'Gem. G-Kracht',
    'max_g_force': 'Max G-Kracht',
    'risks': 'Risico\'s',
    'redFlag': 'Kans op Rode Vlag',
    'vsc': 'Kans op VSC',
    'accident': 'Kans op Crash',
    'turn1Accident': 'Kans Crash Bocht 1',
    'tyres': 'Banden',
    'tireWear': 'Bandenslijtage',
    'strategy': 'Strategie',
    'bestCombination': 'Beste Combinatie',
    'fastestPit': 'Snelste Pitstop',
    'driver_facts_title': 'Feiten & Weetjes',
    'general': 'Algemeen',
    'current_team': 'Huidig Team',
    'nationality': 'Nationaliteit',
    'personal_info': 'Persoonlijke Info',
    'age': 'Leeftijd',
    'birth_place': 'Geboorteplaats',
    'partner': 'Partner',
    'pets': 'Huisdieren',
    'children': 'Kinderen',
    'manager': 'Manager',
    'previous_teams': 'Teams',
    'career_stats': 'Carrière Statistieken',
    'championships': 'Wereldtitels',
    'wins': 'Overwinningen',
    'podiums': 'Podiums',
    'poles': 'Pole Positions',
    'fastest_laps': 'Snelste Rondes',
    'total_points': 'Totale Punten',
    'f1_debut': 'F1 Debuut',
    'contract_until': 'Contract tot',
    'driver_history': 'Historie (Laatste 5 jaar)',
    'experience': 'Ervaring',
    'retirements': 'Uitvalbeurten',
    'starts': 'Starts',
    'laps_led': 'Rondes aan de leiding',
    'dnf': 'Uitvalbeurten (DNF)',
    'dsqs': 'Gediskwalificeerd',
    'dnqs': 'Niet gekwalificeerd',
    'frontRowStarts': 'Starts 1e Rij',
    'highestFinish': 'Hoogste Finish',
    'highestGrid': 'Hoogste Startplek',
    'hatTricks': 'Hattricks',
    'cc_wins': 'Constructeurstitels',
    'dc_wins': 'Coureurstitels',
    'race_stats': 'Race Statistieken',
    'total_entries': 'Totale Inschrijvingen',
    'one_two': '1-2 Finishes',
    'pitstop_leadership': 'Pitstop & Leiderschap',
    'overtakes': 'Inhaalacties',
    'team_principal': 'Teambaas',
    'technical_director': 'Technisch Directeur',
    'height': 'Lengte',
    'engine': 'Motor',
    'soft_tire': 'Zacht',
    'medium_tire': 'Medium',
    'hard_tire': 'Hard',
    'wear_High': 'Hoog',
    'wear_Medium': 'Gemiddeld',
    'wear_Low': 'Laag',
    'strategy_1 stop': '1 stop',
    'strategy_2 stops': '2 stops',
    'strategy_3 stops': '3 stops',
    'level_1': 'Zeer Makkelijk',
    'level_2': 'Makkelijk',
    'level_3': 'Gemiddeld',
    'level_4': 'Moeilijk',
    'level_5': 'Zeer Moeilijk',
    'nat_Dutch': 'Nederlands',
    'nat_British': 'Brits',
    'nat_Spanish': 'Spaans',
    'nat_Monegasque': 'Monegaskisch',
    'nat_Australian': 'Australisch',
    'nat_French': 'Frans',
    'nat_German': 'Duits',
    'nat_Thai': 'Thais',
    'nat_Canadian': 'Canadees',
    'nat_Japanese': 'Japans',
    'nat_Italian': 'Italiaans',
    'nat_New Zealander': 'Nieuw-Zeelands',
    'nat_Brazilian': 'Braziliaans',
    'nat_Argentine': 'Argentijns',
    'nat_Mexican': 'Mexicaans',
    'nat_Finnish': 'Fins',
    'gp_Bahrain Grand Prix': 'Grand Prix van Bahrein',
    'gp_Saudi Arabian Grand Prix': 'Grand Prix van Saoedi-Arabië',
    'gp_Australian Grand Prix': 'Grand Prix van Australië',
    'gp_Japanese Grand Prix': 'Grand Prix van Japan',
    'gp_Chinese Grand Prix': 'Grand Prix van China',
    'gp_Miami Grand Prix': 'Grand Prix van Miami',
    'gp_Barcelona Grand Prix': 'Grand Prix van Barcelona',
    'gp_Monaco Grand Prix': 'Grand Prix van Monaco',
    'gp_Canadian Grand Prix': 'Grand Prix van Canada',
    'gp_Spanish Grand Prix': 'Grand Prix van Spanje',
    'gp_Austrian Grand Prix': 'Grand Prix van Oostenrijk',
    'gp_British Grand Prix': 'Grand Prix van Groot-Brittannië',
    'gp_Hungarian Grand Prix': 'Grand Prix van Hongarije',
    'gp_Belgian Grand Prix': 'Grand Prix van België',
    'gp_Dutch Grand Prix': 'Grand Prix van Nederland',
    'gp_Italian Grand Prix': 'Grand Prix van Italië',
    'gp_Azerbaijan Grand Prix': 'Grand Prix van Azerbeidzjan',
    'gp_Singapore Grand Prix': 'Grand Prix van Singapore',
    'gp_United States Grand Prix': 'Grand Prix van de VS',
    'gp_Mexico City Grand Prix': 'Grand Prix van Mexico',
    'gp_São Paulo Grand Prix': 'Grand Prix van São Paulo',
    'gp_Las Vegas Grand Prix': 'Grand Prix van Las Vegas',
    'gp_Qatar Grand Prix': 'Grand Prix van Qatar',
    'gp_Abu Dhabi Grand Prix': 'Grand Prix van Abu Dhabi',
    'country_Bahrain': 'Bahrein',
    'country_Saudi Arabia': 'Saoedi-Arabië',
    'country_Australia': 'Australië',
    'country_Japan': 'Japan',
    'country_China': 'China',
    'country_USA': 'VS',
    'country_Italy': 'Italië',
    'country_Monaco': 'Monaco',
    'country_Canada': 'Canada',
    'country_Spain': 'Spanje',
    'country_Austria': 'Oostenrijk',
    'country_UK': 'Groot-Brittannië',
    'country_Hungary': 'Hongarije',
    'country_Belgium': 'België',
    'country_Netherlands': 'Nederland',
    'country_Azerbaijan': 'Azerbeidzjan',
    'country_Singapore': 'Singapore',
    'country_Mexico': 'Mexico',
    'country_Brazil': 'Brazilië',
    'country_Qatar': 'Qatar',
    'country_UAE': 'V.A.E.',
    'clear_cache': 'Cache Legen',
    'cache_cleared': 'Cache succesvol geleegd!',
    'engine_supplier': 'Motorleverancier',
    'name': 'Naam',
    'engine_name': 'Motornaam',
    'city': 'Stad',
    'headquarters': 'Hoofdkantoor',
    'team_history': 'Team Geschiedenis',
    'personal_sponsors': 'Persoonlijke Sponsors',
    'circuit_layout': 'Circuit Lay-out',
    'distanceToTurn1': 'Afstand tot Bocht 1',
    'circuitDifficulty': 'Circuit Moeilijkheid',
    'overtakingDifficulty': 'Inhaal Moeilijkheid',
  };

  static final Map<String, String> _enDictionary = {
    'appTitle': 'F1 Hub',
    'settings': 'Settings',
    'toggleTheme': 'Toggle Theme',
    'changelog': 'Changelog',
    'compare': 'Compare',
    'select_drivers_to_compare': 'Select 2 drivers',
    'select_teams_to_compare': 'Select 2 teams',
    'circuits': 'Circuits',
    'standings': 'Standings',
    'nextRace': 'Next Race',
    'startsIn': 'Starts in',
    'week': 'week',
    'weeks': 'weeks',
    'day': 'day',
    'days': 'days',
    'hours': 'hours',
    'minutes': 'minutes',
    'sponsors': 'Sponsors',
    'drivers': 'Drivers',
    'reserve_driver': 'Reserve Driver',
    'teams': 'Teams',
    'pts': 'PTS',
    'using_fallback_data': 'Using offline/fallback data.',
    'points_history': 'Points per Season',
    'session_results': 'Session Results',
    'fp1': 'Practice 1',
    'fp2': 'Practice 2',
    'fp3': 'Practice 3',
    'sprint_quali': 'Sprint Qualifying',
    'sprint': 'Sprint',
    'qualifying': 'Qualifying',
    'session_future': 'Session begins at',
    'no_data_yet': 'Data not available yet or API pending update',
    'version': 'Version',
    'weather_forecast': 'Weather Forecast',
    'circuit_info': 'Circuit Info',
    'temp': 'Temperature',
    'rain_chance': 'Rain Chance',
    'wind_speed': 'Wind Speed',
    'humidity': 'Humidity',
    'length': 'Length',
    'since': 'On calendar since',
    'until': 'Contract until',
    'lap_speed_stats': 'LAP & SPEED STATS',
    'risks_incidents': 'RISKS & INCIDENTS',
    'tyres_strategy': 'TYRES & STRATEGY',
    'characteristics': 'CIRCUIT CHARACTERISTICS',
    'totalLength': 'Total Length',
    'laps': 'Laps',
    'fastestLap': 'Fastest Lap',
    'slowestLap': 'Slowest Lap',
    'avgLap': 'Average Lap',
    'topSpeed': 'Top Speed',
    'averageSpeed': 'Average Speed',
    'avgGForce': 'Avg G-Force',
    'max_g_force': 'Max G-Force',
    'risks': 'Risks',
    'redFlag': 'Red Flag Chance',
    'vsc': 'VSC Chance',
    'accident': 'Accident Chance',
    'turn1Accident': 'Turn 1 Accident Chance',
    'tyres': 'Tyres',
    'tireWear': 'Tire Wear',
    'strategy': 'Strategy',
    'bestCombination': 'Best Combination',
    'fastestPit': 'Fastest Pitstop',
    'driver_facts_title': 'Facts & Trivia',
    'general': 'General',
    'current_team': 'Current Team',
    'nationality': 'Nationality',
    'personal_info': 'Personal Info',
    'age': 'Age',
    'birth_place': 'Birthplace',
    'partner': 'Partner',
    'pets': 'Pets',
    'children': 'Children',
    'manager': 'Manager',
    'previous_teams': 'Teams',
    'career_stats': 'Career Stats',
    'championships': 'Championships',
    'wins': 'Wins',
    'podiums': 'Podiums',
    'poles': 'Pole Positions',
    'fastest_laps': 'Fastest Laps',
    'total_points': 'Total Points',
    'f1_debut': 'F1 Debut',
    'contract_until': 'Contract until',
    'driver_history': 'History (Last 5 Years)',
    'experience': 'Experience',
    'retirements': 'Retirements',
    'starts': 'Starts',
    'laps_led': 'Laps Led',
    'dnf': 'Did Not Finish',
    'dsqs': 'Disqualified',
    'dnqs': 'Did Not Qualify',
    'frontRowStarts': 'Front Row Starts',
    'highestFinish': 'Highest Finish',
    'highestGrid': 'Highest Grid Position',
    'hatTricks': 'Hat Tricks',
    'cc_wins': 'Constructors Titles',
    'dc_wins': 'Drivers Titles',
    'race_stats': 'Race Stats',
    'total_entries': 'Total Entries',
    'one_two': '1-2 Finishes',
    'pitstop_leadership': 'Pitstop & Leadership',
    'overtakes': 'Overtakes',
    'team_principal': 'Team Principal',
    'technical_director': 'Technical Director',
    'height': 'Height',
    'engine': 'Engine',
    'soft_tire': 'Soft',
    'medium_tire': 'Medium',
    'hard_tire': 'Hard',
    'wear_High': 'High',
    'wear_Medium': 'Medium',
    'wear_Low': 'Low',
    'strategy_1 stop': '1 stop',
    'strategy_2 stops': '2 stops',
    'strategy_3 stops': '3 stops',
    'level_1': 'Very Easy',
    'level_2': 'Easy',
    'level_3': 'Medium',
    'level_4': 'Hard',
    'level_5': 'Very Hard',
    'nat_Dutch': 'Dutch',
    'nat_British': 'British',
    'nat_Spanish': 'Spanish',
    'nat_Monegasque': 'Monegasque',
    'nat_Australian': 'Australian',
    'nat_French': 'French',
    'nat_German': 'German',
    'nat_Thai': 'Thai',
    'nat_Canadian': 'Canadian',
    'nat_Japanese': 'Japanese',
    'nat_Italian': 'Italian',
    'nat_New Zealander': 'New Zealander',
    'nat_Brazilian': 'Brazilian',
    'nat_Argentine': 'Argentine',
    'nat_Mexican': 'Mexican',
    'nat_Finnish': 'Finnish',
    'gp_Bahrain Grand Prix': 'Bahrain Grand Prix',
    'gp_Saudi Arabian Grand Prix': 'Saudi Arabian Grand Prix',
    'gp_Australian Grand Prix': 'Australian Grand Prix',
    'gp_Japanese Grand Prix': 'Japanese Grand Prix',
    'gp_Chinese Grand Prix': 'Chinese Grand Prix',
    'gp_Miami Grand Prix': 'Miami Grand Prix',
    'gp_Barcelona Grand Prix': 'Barcelona Grand Prix',
    'gp_Monaco Grand Prix': 'Monaco Grand Prix',
    'gp_Canadian Grand Prix': 'Canadian Grand Prix',
    'gp_Spanish Grand Prix': 'Spanish Grand Prix',
    'gp_Austrian Grand Prix': 'Austrian Grand Prix',
    'gp_British Grand Prix': 'British Grand Prix',
    'gp_Hungarian Grand Prix': 'Hungarian Grand Prix',
    'gp_Belgian Grand Prix': 'Belgian Grand Prix',
    'gp_Dutch Grand Prix': 'Dutch Grand Prix',
    'gp_Italian Grand Prix': 'Italian Grand Prix',
    'gp_Azerbaijan Grand Prix': 'Azerbaijan Grand Prix',
    'gp_Singapore Grand Prix': 'Singapore Grand Prix',
    'gp_United States Grand Prix': 'United States Grand Prix',
    'gp_Mexico City Grand Prix': 'Mexico City Grand Prix',
    'gp_São Paulo Grand Prix': 'São Paulo Grand Prix',
    'gp_Las Vegas Grand Prix': 'Las Vegas Grand Prix',
    'gp_Qatar Grand Prix': 'Qatar Grand Prix',
    'gp_Abu Dhabi Grand Prix': 'Abu Dhabi Grand Prix',
    'country_Bahrain': 'Bahrain',
    'country_Saudi Arabia': 'Saudi Arabia',
    'country_Australia': 'Australia',
    'country_Japan': 'Japan',
    'country_China': 'China',
    'country_USA': 'USA',
    'country_Italy': 'Italy',
    'country_Monaco': 'Monaco',
    'country_Canada': 'Canada',
    'country_Spain': 'Spain',
    'country_Austria': 'Austria',
    'country_UK': 'UK',
    'country_Hungary': 'Hungary',
    'country_Belgium': 'Belgium',
    'country_Netherlands': 'Netherlands',
    'country_Azerbaijan': 'Azerbaijan',
    'country_Singapore': 'Singapore',
    'country_Mexico': 'Mexico',
    'country_Brazil': 'Brazil',
    'country_Qatar': 'Qatar',
    'country_UAE': 'UAE',
    'clear_cache': 'Clear Cache',
    'cache_cleared': 'Cache cleared successfully!',
    'engine_supplier': 'Engine Supplier',
    'name': 'Name',
    'engine_name': 'Engine Name',
    'city': 'City',
    'headquarters': 'Headquarters',
    'team_history': 'Team History',
    'personal_sponsors': 'Personal Sponsors',
    'circuit_layout': 'Circuit Layout',
    'distanceToTurn1': 'Distance to Turn 1',
    'circuitDifficulty': 'Circuit Difficulty',
    'overtakingDifficulty': 'Overtaking Difficulty',
  };

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _enDictionary,
    'nl': _nlDictionary,
    'fr': _enDictionary,
    'es': _enDictionary,
    'de': _nlDictionary, // Duits > Nederlands mapping
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _enDictionary[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'nl', 'fr', 'es', 'de'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionDataManager().init(races);
  runApp(const F1HubApp());
}

class F1HubApp extends StatefulWidget {
  const F1HubApp({super.key});

  @override
  State<F1HubApp> createState() => _F1HubAppState();
}

class _F1HubAppState extends State<F1HubApp> {
  Locale? _locale;
  ThemeMode _themeMode = (DateTime.now().hour > 6 && DateTime.now().hour < 20)
      ? ThemeMode.light
      : ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final lang = prefs.getString('language_code');
      if (lang != null) _locale = Locale(lang);
      final isDark = prefs.getBool('is_dark');
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    });
  }

  void _setLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
    SharedPreferences.getInstance().then(
      (p) => p.setString('language_code', newLocale.languageCode),
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    SharedPreferences.getInstance().then(
      (p) => p.setBool('is_dark', _themeMode == ThemeMode.dark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeAnimationCurve: Curves.easeInOutCubic,
      themeAnimationDuration: const Duration(milliseconds: 320),
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('nl'),
        Locale('fr'),
        Locale('es'),
        Locale('de'),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == deviceLocale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainNavigation(
        onSetLocale: _setLocale,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

/// --- Globale UI Helpers ----------------------------------------------

String _getFlag(String nat) {
  final Map<String, String> flags = {
    'Dutch': '',
    'British': '',
    'Monegasque': '',
    'Spanish': '',
    'Australian': '',
    'Italian': '',
    'German': '',
    'French': '',
    'Austrian': '',
    'Swiss': '',
    'Thai': '',
    'Japanese': '',
    'American': '',
    'Mexican': '',
    'Finnish': '',
    'Argentine': '',
    'New Zealander': '',
    'Chinese': '',
    'Danish': '',
    'Netherlands': '',
    'Australia': '',
    'Bahrain': '',
    'Saudi Arabia': '',
    'Japan': '',
    'China': '',
    'USA': '',
    'Monaco': '',
    'Canada': '',
    'Spain': '',
    'Austria': '',
    'UK': '',
    'Hungary': '',
    'Belgium': '',
    'Azerbaijan': '',
    'Singapore': '',
    'Mexico': '',
    'Brazil': '',
    'Qatar': '',
    'UAE': '',
    'United States': '',
    'Italy': '',
  };
  return flags[nat] ?? '';
}

Color _getTeamColor(String t) {
  if (t.toLowerCase().contains('ferrari')) return const Color(0xFFE80020);
  if (t.toLowerCase().contains('red bull')) return const Color(0xFF0600EF);
  if (t.toLowerCase().contains('mclaren')) return const Color(0xFFFF8700);
  if (t.toLowerCase().contains('mercedes')) return const Color(0xFF27F4D2);
  if (t.toLowerCase().contains('aston')) return const Color(0xFF229971);
  if (t.toLowerCase().contains('williams')) return const Color(0xFF005AFF);
  if (t.toLowerCase().contains('alpine')) return const Color(0xFFFF87BC);
  if (t.toLowerCase().contains('haas')) return const Color(0xFFB6BABD);
  if (t.toLowerCase().contains('audi') || t.toLowerCase().contains('sauber')) {
    return const Color(0xFFE2FF00);
  }
  if (t.toLowerCase().contains('racing bulls') ||
      t.toLowerCase().contains('rb')) {
    return const Color(0xFF6692FF);
  }
  if (t.toLowerCase().contains('cadillac')) return const Color(0xFFFFB800);
  return Colors.blueGrey;
}

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

Widget _sectionHeader(String t, String emoji) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          Expanded(
            child: Divider(indent: 15, color: tokens.outline.withOpacity(0.75)),
          ),
        ],
      ),
    );
  },
);

Widget _statTile(String l, dynamic v, IconData icon) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
              const SizedBox(width: 12),
              Text(
                l,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.82),
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
  });

  factory RaceResultRow.fromJson(Map<String, dynamic> json) {
    return RaceResultRow(
      driver: json['driver']?.toString() ?? '-',
      start: json['start']?.toString() ?? '-',
      finish: json['finish']?.toString() ?? '-',
      timeOrGap: json['timeOrGap']?.toString() ?? '-',
      fastestLap: json['fastestLap']?.toString() ?? '-',
      tyreCompound: json['tyreCompound']?.toString() ?? '-',
      penalty: json['penalty']?.toString() ?? '-',
      points: json['points']?.toString() ?? '0',
      hasFastestLap: json['hasFastestLap'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'start': start,
      'finish': finish,
      'timeOrGap': timeOrGap,
      'fastestLap': fastestLap,
      'tyreCompound': tyreCompound,
      'penalty': penalty,
      'points': points,
      'hasFastestLap': hasFastestLap,
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

  const SessionOverviewRow({
    required this.driver,
    required this.position,
    required this.result,
    required this.fastestLap,
    required this.tyreCompound,
    required this.points,
    required this.hasFastestLap,
  });

  factory SessionOverviewRow.fromJson(Map<String, dynamic> json) {
    return SessionOverviewRow(
      driver: json['driver']?.toString() ?? '-',
      position: json['position']?.toString() ?? '-',
      result: json['result']?.toString() ?? '-',
      fastestLap: json['fastestLap']?.toString() ?? '-',
      tyreCompound: json['tyreCompound']?.toString() ?? '-',
      points: json['points']?.toString() ?? '-',
      hasFastestLap: json['hasFastestLap'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'position': position,
      'result': result,
      'fastestLap': fastestLap,
      'tyreCompound': tyreCompound,
      'points': points,
      'hasFastestLap': hasFastestLap,
    };
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

class SessionDataManager extends ChangeNotifier {
  static final SessionDataManager _instance = SessionDataManager._internal();
  factory SessionDataManager() => _instance;
  SessionDataManager._internal();

  final Map<String, List<SessionResult>> cache = {};
  final Map<String, List<RaceResultRow>> raceResultsCache = {};
  final Map<String, List<SessionOverviewRow>> sessionOverviewCache = {};
  final Map<String, List<Map<String, dynamic>>> _openF1Cache = {};
  DateTime? _lastOpenF1RequestAt;
  bool isInitialized = false;

  Future<void> init(List<Race> races) async {
    final prefs = await SharedPreferences.getInstance();
    for (final race in races) {
      final sessionNames = race.hasSprint
          ? ['Practice 1', 'Sprint Qualifying', 'Sprint', 'Qualifying', 'Race']
          : ['Practice 1', 'Practice 2', 'Practice 3', 'Qualifying', 'Race'];
      for (final session in sessionNames) {
        final key = '${race.country}_${session}_${race.date.year}';
        final jsonStr = prefs.getString(key);
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

      final raceResultsJson = prefs.getString(_raceResultsKey(race));
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

      for (final session in sessionNames.where((name) => name != 'Race')) {
        final overviewJson = prefs.getString(
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

  Future<void> fetchDataForRace(Race race, int roundIndex) async {
    final sessionNames = race.hasSprint
        ? ['Practice 1', 'Sprint Qualifying', 'Sprint', 'Qualifying', 'Race']
        : ['Practice 1', 'Practice 2', 'Practice 3', 'Qualifying', 'Race'];
    final now = DateTime.now();

    for (final sessionName in sessionNames) {
      if (sessionName == 'Race' && race.date.isAfter(now)) {
        continue;
      }

      final key = '${race.country}_${sessionName}_${race.date.year}';
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

      if (sessionName != 'Race' &&
          !_sessionDateFor(race, sessionName).isAfter(now)) {
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
    }

    final raceResultsKey = _raceResultsKey(race);
    if (race.date.isAfter(now)) {
      raceResultsCache.remove(raceResultsKey);
    } else {
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
    }

    isInitialized = true;
    notifyListeners();
  }

  String raceResultsKeyFor(Race race) => _raceResultsKey(race);

  String sessionOverviewKeyFor(Race race, String sessionName) =>
      _sessionOverviewKey(race, sessionName);

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

    final response = await http
        .get(
          Uri.parse(
            'https://api.jolpi.ca/ergast/f1/$year/$roundIndex/$endpoint.json',
          ),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      return const <SessionResult>[];
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> racesData =
        (((decoded['MRData'] as Map<String, dynamic>?)?['RaceTable']
                as Map<String, dynamic>?)?['Races']
            as List<dynamic>?) ??
        const <dynamic>[];
    if (racesData.isEmpty) {
      return const <SessionResult>[];
    }

    final Map<String, dynamic> raceData =
        racesData.first as Map<String, dynamic>;
    final List<dynamic> rawResults =
        (raceData[resultsKey] as List<dynamic>?) ?? const <dynamic>[];

    return rawResults
        .map(
          (entry) =>
              _parseSessionResult(entry as Map<String, dynamic>, sessionName),
        )
        .toList();
  }

  SessionResult _parseSessionResult(
    Map<String, dynamic> entry,
    String sessionName,
  ) {
    final driverData = entry['Driver'] as Map<String, dynamic>?;
    final givenName = driverData?['givenName']?.toString() ?? '';
    final familyName = driverData?['familyName']?.toString() ?? '';
    final driverName = '$givenName $familyName'.trim();

    String time = '-';
    if (sessionName == 'Qualifying') {
      time =
          entry['Q3']?.toString() ??
          entry['Q2']?.toString() ??
          entry['Q1']?.toString() ??
          entry['status']?.toString() ??
          '-';
    } else {
      final timeData = entry['Time'] as Map<String, dynamic>?;
      time =
          timeData?['time']?.toString() ?? entry['status']?.toString() ?? '-';
    }

    return SessionResult(
      driver: driverName.isEmpty ? '-' : driverName,
      time: time,
      tyre: '',
    );
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(results.map((result) => result.toJson()).toList()),
    );
  }

  Future<void> _saveRaceResults(String key, List<RaceResultRow> rows) async {
    raceResultsCache[key] = rows;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(rows.map((row) => row.toJson()).toList()),
    );
  }

  Future<void> _saveSessionOverview(
    String key,
    List<SessionOverviewRow> rows,
  ) async {
    sessionOverviewCache[key] = rows;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(rows.map((row) => row.toJson()).toList()),
    );
  }

  String _raceResultsKey(Race race) =>
      '${race.country}_RaceResults_${race.date.year}_v2';

  String _sessionOverviewKey(Race race, String sessionName) =>
      '${race.country}_${sessionName}_${race.date.year}_Overview';

  DateTime _sessionDateFor(Race race, String sessionName) {
    switch (sessionName) {
      case 'Practice 1':
        return race.fp1;
      case 'Practice 2':
        return race.fp2;
      case 'Practice 3':
        return race.fp3;
      case 'Sprint Qualifying':
        return race.sprintQuali;
      case 'Sprint':
        return race.sprintRace;
      case 'Qualifying':
        return race.qualifying;
      default:
        return race.date;
    }
  }

  Future<List<SessionOverviewRow>> _fetchSessionOverviewRows(
    Race race,
    String sessionName,
  ) async {
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

        return SessionOverviewRow(
          driver: driverNumber == null
              ? '-'
              : (driverNames[driverNumber] ?? '-'),
          position: _formatSessionPosition(entry),
          result: isSprint
              ? _formatSprintResult(entry)
              : _formatLapDuration(
                  driverNumber == null
                      ? null
                      : fastestLapByDriver[driverNumber]?.duration,
                ),
          fastestLap: driverNumber == null
              ? '-'
              : _formatLapDuration(fastestLapByDriver[driverNumber]?.duration),
          tyreCompound: driverNumber == null
              ? '-'
              : _formatTyreCompound(fastestLapByDriver[driverNumber]?.compound),
          points: isSprint
              ? _formatPoints(_asDouble(entry['points']) ?? 0)
              : '-',
          hasFastestLap:
              driverNumber != null &&
              overallFastestLap != null &&
              fastestLapByDriver[driverNumber]?.duration ==
                  overallFastestLap.duration,
        );
      }).toList();
    }

    final rankedDrivers = fastestLapByDriver.entries.toList()
      ..sort((a, b) => a.value.duration.compareTo(b.value.duration));

    return rankedDrivers.asMap().entries.map((entry) {
      final position = entry.key + 1;
      final driverNumber = entry.value.key;
      final lap = entry.value.value;
      return SessionOverviewRow(
        driver: driverNames[driverNumber] ?? '-',
        position: position.toString(),
        result: _formatLapDuration(lap.duration),
        fastestLap: _formatLapDuration(lap.duration),
        tyreCompound: _formatTyreCompound(lap.compound),
        points: '-',
        hasFastestLap:
            overallFastestLap != null &&
            lap.duration == overallFastestLap.duration,
      );
    }).toList();
  }

  Future<List<RaceResultRow>> _fetchRaceResultRows(Race race) async {
    final raceSession = await _findClosestSessionForRace(
      race: race,
      sessionName: 'Race',
    );
    if (raceSession == null) {
      return const <RaceResultRow>[];
    }

    final meetingKey = _asInt(raceSession['meeting_key']);
    final raceSessionKey = _asInt(raceSession['session_key']);
    if (meetingKey == null || raceSessionKey == null) {
      return const <RaceResultRow>[];
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
      return const <RaceResultRow>[];
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
    final fastestLapByDriver = _buildFastestLapDetailsMap(laps, stints);
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

    return sortedResults.map((entry) {
      final driverNumber = _asInt(entry['driver_number']);
      final startPosition = driverNumber == null
          ? null
          : gridPositions[driverNumber];
      return RaceResultRow(
        driver: driverNumber == null ? '-' : (driverNames[driverNumber] ?? '-'),
        start: driverNumber == null
            ? '-'
            : (gridPositions[driverNumber]?.toString() ?? '-'),
        finish: _formatRaceFinish(entry, startPosition),
        timeOrGap: _formatTimeOrGap(entry, winnerDuration),
        fastestLap: driverNumber == null
            ? '-'
            : _formatLapDuration(fastestLapByDriver[driverNumber]?.duration),
        tyreCompound: driverNumber == null
            ? '-'
            : _formatTyreCompound(fastestLapByDriver[driverNumber]?.compound),
        penalty: driverNumber == null ? '-' : (penalties[driverNumber] ?? '-'),
        points: _formatPoints(_asDouble(entry['points']) ?? 0),
        hasFastestLap:
            driverNumber != null &&
            overallFastestLap != null &&
            fastestLapByDriver[driverNumber]?.duration ==
                overallFastestLap.duration,
      );
    }).toList();
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

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    _lastOpenF1RequestAt = DateTime.now();
    if (response.statusCode != 200) {
      return const <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }

    final result = decoded
        .whereType<Map>()
        .map(
          (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
    _openF1Cache[cacheKey] = result;
    return result;
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
        upper.contains('STOP AND GO PENALTY')) {
      return 'S&G';
    }

    if (upper.contains('DRIVE THROUGH PENALTY')) {
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
      return 'NC';
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
      return 'NC';
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
    if (_asBool(entry['dsq']) || _asInt(entry['position']) == null) {
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
    if (_asBool(entry['dsq']) || _asInt(entry['position']) == null) {
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

  String _trimTrailingZero(String value) {
    if (!value.contains('.')) {
      return value;
    }
    return value
        .replaceFirst(RegExp(r'\.0+$'), '')
        .replaceFirst(RegExp(r'(\.[1-9]*)0+$'), r'$1');
  }
}

class MainNavigation extends StatefulWidget {
  final ValueChanged<Locale> onSetLocale;
  final VoidCallback onToggleTheme;

  const MainNavigation({
    required this.onSetLocale,
    required this.onToggleTheme,
    super.key,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  late final PageController _pageController;
  final GlobalKey<NavigatorState> _racesNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _driversNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _teamsNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _idx);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    final isDark = prefs.getBool('is_dark');

    await prefs.clear();
    if (languageCode != null) {
      await prefs.setString('language_code', languageCode);
    }
    if (isDark != null) {
      await prefs.setBool('is_dark', isDark);
    }

    SessionDataManager().cache.clear();
    SessionDataManager().isInitialized = false;
    await SessionDataManager().init(races);

    if (!mounted) {
      return;
    }

    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.translate('cache_cleared'))));
  }

  Future<void> _showLanguageDialog() async {
    final Locale? selectedLocale = await showDialog<Locale>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Language'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, const Locale('en')),
              child: const Text('English'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, const Locale('nl')),
              child: const Text('Nederlands'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, const Locale('fr')),
              child: const Text('Français'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, const Locale('es')),
              child: const Text('Español'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, const Locale('de')),
              child: const Text('Deutsch'),
            ),
          ],
        );
      },
    );

    if (selectedLocale != null) {
      widget.onSetLocale(selectedLocale);
    }
  }

  Future<void> _handleSettingsSelection(String value) async {
    switch (value) {
      case 'theme':
        widget.onToggleTheme();
        break;
      case 'language':
        await _showLanguageDialog();
        break;
      case 'changelog':
        if (!mounted) {
          return;
        }
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChangelogScreen()));
        break;
      case 'clear_cache':
        await _clearCache();
        break;
    }
  }

  Widget _buildSettingsMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings),
      tooltip: loc.translate('settings'),
      onSelected: _handleSettingsSelection,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'theme',
          child: Row(
            children: [
              const Icon(Icons.brightness_6_outlined),
              const SizedBox(width: 12),
              Text(loc.translate('toggleTheme')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'language',
          child: const Row(
            children: [
              Icon(Icons.language),
              SizedBox(width: 12),
              Text('Language'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'changelog',
          child: Row(
            children: [
              const Icon(Icons.update),
              const SizedBox(width: 12),
              Text(loc.translate('changelog')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'clear_cache',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.redAccent),
              const SizedBox(width: 12),
              Text(
                loc.translate('clear_cache'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (_idx == i) {
            if (i == 0) {
              _racesNavKey.currentState?.popUntil((route) => route.isFirst);
            }
            if (i == 1) {
              _driversNavKey.currentState?.popUntil((route) => route.isFirst);
            }
            if (i == 2) {
              _teamsNavKey.currentState?.popUntil((route) => route.isFirst);
            }
          } else {
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.speed),
            label: loc.translate('circuits').toUpperCase(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: loc.translate('drivers').toUpperCase(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: loc.translate('teams').toUpperCase(),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_idx != index) {
            setState(() => _idx = index);
          }
        },
        children: [
          Navigator(
            key: _racesNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) =>
                    CircuitsView(settingsMenu: _buildSettingsMenu(context)),
              );
            },
          ),
          Navigator(
            key: _driversNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => StandingsView(
                  isDriverView: true,
                  settingsMenu: _buildSettingsMenu(context),
                ),
              );
            },
          ),
          Navigator(
            key: _teamsNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => StandingsView(
                  isDriverView: false,
                  settingsMenu: _buildSettingsMenu(context),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// --- CIRCUITS VIEW (TAB 0 ROOT) ---
class CircuitsView extends StatefulWidget {
  final Widget settingsMenu;
  const CircuitsView({required this.settingsMenu, super.key});
  @override
  State<CircuitsView> createState() => _CircuitsViewState();
}

class _CircuitsViewState extends State<CircuitsView> {
  String liveTemp = "--";
  int liveRain = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _primeHomeData();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _fetchLiveWeather();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Race _nextRace() {
    final now = DateTime.now();
    try {
      return races.firstWhere((r) => r.date.isAfter(now));
    } catch (e) {
      return races.last;
    }
  }

  Race? _latestCompletedRace() {
    final now = DateTime.now();
    for (final race in races.reversed) {
      if (!race.date.isAfter(now)) {
        return race;
      }
    }
    return null;
  }

  Future<void> _primeHomeData() async {
    await _fetchLiveWeather();
    await _preloadLatestRacePodium();
  }

  Future<void> _preloadLatestRacePodium() async {
    final latestRace = _latestCompletedRace();
    if (latestRace == null) {
      return;
    }

    final cacheKey = '${latestRace.country}_Race_${latestRace.date.year}';
    final cachedResults = SessionDataManager().cache[cacheKey];
    if (cachedResults != null && cachedResults.length >= 3) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final roundIndex = races.indexOf(latestRace) + 1;
    await SessionDataManager().fetchDataForRace(latestRace, roundIndex);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchLiveWeather() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      final nextTrack = _nextRace();
      final res = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${nextTrack.lat}&longitude=${nextTrack.lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=precipitation_probability_max&timezone=auto',
        ),
      );
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() {
          liveTemp = d['current']['temperature_2m'].toString();
          liveRain = d['daily']['precipitation_probability_max'][0];
        });
      }
    } catch (_) {}
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
      final roundIndex = races.indexOf(race) + 1;
      await SessionDataManager().fetchDataForRace(race, roundIndex);
    }
  }

  String _timeUntil(DateTime date, BuildContext context) {
    final loc = AppLocalizations.of(context);
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return '';
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      final remainingDays = diff.inDays % 7;
      String w =
          '$weeks ${weeks == 1 ? loc.translate('week') : loc.translate('weeks')}';
      if (remainingDays > 0) {
        w +=
            ', $remainingDays ${remainingDays == 1 ? loc.translate('day') : loc.translate('days')}';
      }
      return w;
    } else if (diff.inDays >= 1) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return '$days ${days == 1 ? loc.translate('day') : loc.translate('days')}${hours > 0 ? ', $hours ${loc.translate('hours')}' : ''}';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} ${loc.translate('hours')}, ${diff.inMinutes % 60} ${loc.translate('minutes')}';
    } else {
      return '${diff.inMinutes} ${loc.translate('minutes')}';
    }
  }

  String _getPodiumString(Race race) {
    final results =
        SessionDataManager().cache['${race.country}_Race_${race.date.year}'];
    if (results != null && results.length >= 3) {
      return '${results[0].driver.split(' ').last} ${getCompactTireEmoji(results[0].tyre)}  ${results[1].driver.split(' ').last} ${getCompactTireEmoji(results[1].tyre)}  ${results[2].driver.split(' ').last} ${getCompactTireEmoji(results[2].tyre)}';
    }
    return 'Verstappen  Norris  Leclerc';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final upcoming = _nextRace();
    final timeStrNext = _timeUntil(upcoming.date, context);
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('appTitle').toUpperCase()),
        actions: [widget.settingsMenu],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCircuits,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => CircuitDetailScreen(
                    race: upcoming,
                    heroTag: _raceFlagHeroTag(upcoming, source: 'featured'),
                    settingsMenu: widget.settingsMenu,
                  ),
                ),
              ),
              child: Card(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _heroPanelGradient(context),
                    border: Border.all(color: tokens.outline.withOpacity(0.65)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.translate('nextRace').toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '$liveTemp°C ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Icon(
                                liveRain > 30 ? Icons.umbrella : Icons.wb_sunny,
                                color: liveRain > 30
                                    ? Colors.blue
                                    : Colors.amber,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFlagHero(
                            tag: _raceFlagHeroTag(upcoming, source: 'featured'),
                            flag: _getFlag(
                              loc.translate('country_${upcoming.country}'),
                            ),
                            fontSize: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.translate('gp_${upcoming.name}'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        upcoming.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      Divider(
                        height: 30,
                        color: tokens.outline.withOpacity(0.75),
                      ),
                      Text(
                        timeStrNext.isEmpty
                            ? _getPodiumString(upcoming)
                            : '${loc.translate('startsIn')} $timeStrNext',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _sectionHeader("2026 Calendar", "📅"),
            ...races.map((r) {
              final isFinished = r.date.difference(DateTime.now()).isNegative;
              final tStr = _timeUntil(r.date, context);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => CircuitDetailScreen(
                        race: r,
                        heroTag: _raceFlagHeroTag(r, source: 'calendar'),
                        settingsMenu: widget.settingsMenu,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _buildFlagHero(
                          tag: _raceFlagHeroTag(r, source: 'calendar'),
                          flag: r.flag,
                          fontSize: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.translate('gp_${r.name}'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${r.date.day}-${r.date.month}-${r.date.year}",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFinished ? _getPodiumString(r) : tStr,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isFinished
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// --- STANDINGS VIEW (TAB 1 ROOT) ----------------------------------------------

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
  bool _usingFallback = false;
  int _selectedYear = DateTime.now().year;
  final List<int> _years = List.generate(
    10,
    (index) => DateTime.now().year - index,
  );

  final List<dynamic> _selectedForComparison = [];
  bool _isCompareMode = false;

  @override
  void initState() {
    super.initState();
    _fetchStandings();
  }

  Future<void> _fetchStandings({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeyDrivers = 'api_drivers_cache_$_selectedYear';
    final cacheKeyTeams = 'api_teams_cache_$_selectedYear';
    final cacheTimeKey = 'api_cache_time_$_selectedYear';
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastFetch = prefs.getInt(cacheTimeKey) ?? 0;

    if (!forceRefresh && now - lastFetch < 24 * 60 * 60 * 1000) {
      final cachedD = prefs.getString(cacheKeyDrivers);
      final cachedT = prefs.getString(cacheKeyTeams);
      if (cachedD != null && cachedT != null) {
        try {
          _processStandingsData(json.decode(cachedD), json.decode(cachedT));
          return;
        } catch (_) {}
      }
    }

    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      final driverRes = await http
          .get(
            Uri.parse(
              'https://api.jolpi.ca/ergast/f1/$_selectedYear/driverStandings.json',
            ),
          )
          .timeout(const Duration(seconds: 4));

      await Future.delayed(const Duration(milliseconds: 700));
      final teamRes = await http
          .get(
            Uri.parse(
              'https://api.jolpi.ca/ergast/f1/$_selectedYear/constructorStandings.json',
            ),
          )
          .timeout(const Duration(seconds: 4));

      if (driverRes.statusCode == 200 && teamRes.statusCode == 200) {
        final dData = json.decode(driverRes.body);
        final tData = json.decode(teamRes.body);
        final dList = dData['MRData']['StandingsTable']['StandingsLists'];
        final tList = tData['MRData']['StandingsTable']['StandingsLists'];

        if (dList.isNotEmpty && tList.isNotEmpty) {
          final parsedD = dList[0]['DriverStandings'];
          final parsedT = tList[0]['ConstructorStandings'];
          prefs.setString(cacheKeyDrivers, json.encode(parsedD));
          prefs.setString(cacheKeyTeams, json.encode(parsedT));
          prefs.setInt(cacheTimeKey, now);
          _processStandingsData(parsedD, parsedT);
        } else {
          throw Exception("No API points (start of season)");
        }
      } else {
        throw Exception("API Failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedDrivers = List.from(driversData[_selectedYear] ?? []);
          _cachedTeams = List.from(fallbackTeams);
          _usingFallback = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStandings() => _fetchStandings(forceRefresh: true);

  void _processStandingsData(List apiDrivers, List apiTeams) {
    List<Driver> mergedDrivers = [];
    final localDrivers = driversData[_selectedYear] ?? [];
    for (var localD in localDrivers) {
      final apiMatch = apiDrivers.firstWhere(
        (apiD) => localD.name.toLowerCase().contains(
          (apiD['Driver']['familyName'] ?? '').toLowerCase(),
        ),
        orElse: () => null,
      );
      double pts = apiMatch != null
          ? (double.tryParse(apiMatch['points'].toString()) ?? 0)
          : 0;
      mergedDrivers.add(Driver.copy(localD, pts));
    }

    List<Team> mergedTeams = [];
    for (var localT in fallbackTeams) {
      final apiMatch = apiTeams.firstWhere(
        (apiT) => localT.name.toLowerCase().contains(
          (apiT['Constructor']['name'] ?? '').toLowerCase().split(' ').first,
        ),
        orElse: () => null,
      );
      int pts = apiMatch != null
          ? (double.tryParse(apiMatch['points'].toString())?.toInt() ?? 0)
          : 0;
      mergedTeams.add(Team.copy(localT, pts));
    }

    mergedDrivers.sort((a, b) => b.points.compareTo(a.points));
    mergedTeams.sort((a, b) => b.points.compareTo(a.points));

    if (mounted) {
      setState(() {
        _cachedDrivers = mergedDrivers;
        _cachedTeams = mergedTeams;
        _usingFallback = false;
        _isLoading = false;
      });
    }
  }

  String _formatPoints(num points) {
    if (points is double && points == points.roundToDouble()) {
      return points.toInt().toString();
    }
    return points.toString();
  }

  Widget _buildList(bool isDriver) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDriverView = widget.isDriverView;
    final int count = isDriver
        ? (_cachedDrivers.isEmpty
              ? (driversData[_selectedYear]?.length ?? 0)
              : _cachedDrivers.length)
        : (_cachedTeams.isEmpty ? fallbackTeams.length : _cachedTeams.length);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: count,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemBuilder: (c, i) {
        final item = isDriver
            ? (_cachedDrivers.isEmpty
                  ? driversData[_selectedYear]![i]
                  : _cachedDrivers[i])
            : (_cachedTeams.isEmpty ? fallbackTeams[i] : _cachedTeams[i]);
        final String name = isDriver
            ? (item as Driver).name
            : (item as Team).name;
        final num points = isDriver
            ? (item as Driver).points
            : (item as Team).points;
        final String flag = isDriver
            ? (item as Driver).flag
            : (item as Team).flag;
        final String heroTag = isDriver
            ? _driverFlagHeroTag(item as Driver, source: 'standings')
            : _teamFlagHeroTag(item as Team, source: 'standings');
        final String teamName = isDriver
            ? (item as Driver).team
            : (item as Team).name;

        final bool isSelected =
            _isCompareMode && _selectedForComparison.contains(item);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? _getTeamColor(teamName).withOpacity(0.3)
                : (isDark ? const Color(0xFF16161E) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: _getTeamColor(teamName), width: 6),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: ListTile(
            onTap: () {
              if (_isCompareMode) {
                setState(() {
                  if (_selectedForComparison.contains(item)) {
                    _selectedForComparison.remove(item);
                  } else if (_selectedForComparison.length < 2) {
                    _selectedForComparison.add(item);
                  }
                });
                if (_selectedForComparison.length == 2) {
                  Widget comparisonPage;
                  if (isDriverView) {
                    comparisonPage = DriverComparisonView(
                      driver1: _selectedForComparison[0] as Driver,
                      driver2: _selectedForComparison[1] as Driver,
                    );
                  } else {
                    comparisonPage = TeamComparisonView(
                      team1: _selectedForComparison[0] as Team,
                      team2: _selectedForComparison[1] as Team,
                    );
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => comparisonPage),
                  ).then((_) {
                    setState(() {
                      _isCompareMode = false;
                      _selectedForComparison.clear();
                    });
                  });
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => isDriver
                        ? DriverDetailView(
                            driver: item as Driver,
                            heroTag: heroTag,
                            settingsMenu: widget.settingsMenu,
                          )
                        : TeamDetailView(
                            team: item as Team,
                            heroTag: heroTag,
                            settingsMenu: widget.settingsMenu,
                          ),
                  ),
                );
              }
            },
            leading: Text(
              "${i + 1}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 16,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFlagHero(
                      tag: heroTag,
                      flag: flag,
                      fontSize: 14,
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isDriver && (item as Driver).championshipYears.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      (item).championshipYears.join(', '),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Text(
              "${_formatPoints(points)} ${loc.translate('pts')}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDriverView = widget.isDriverView;

    return Scaffold(
      appBar: AppBar(
        title: _isCompareMode
            ? Text(
                '${isDriverView ? loc.translate('select_drivers_to_compare') : loc.translate('select_teams_to_compare')} (${_selectedForComparison.length}/2)',
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
          IconButton(
            icon: Icon(_isCompareMode ? Icons.cancel : Icons.compare_arrows),
            tooltip: loc.translate('compare'),
            onPressed: () => setState(() {
              _isCompareMode = !_isCompareMode;
              _selectedForComparison.clear();
            }),
          ),
          widget.settingsMenu,
        ],
      ),
      body: _isLoading
          ? RefreshIndicator(
              onRefresh: _refreshStandings,
              child: _buildStandingsSkeleton(
                context,
                isDriver: widget.isDriverView,
              ),
            )
          : Column(
              children: [
                if (_usingFallback)
                  Container(
                    width: double.infinity,
                    color: Colors.orangeAccent.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Text(
                      loc.translate('using_fallback_data'),
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
                    child: _buildList(widget.isDriverView),
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
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
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

class DriverComparisonView extends StatelessWidget {
  final Driver driver1;
  final Driver driver2;

  const DriverComparisonView({
    required this.driver1,
    required this.driver2,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${driver1.name.split(' ').last} vs ${driver2.name.split(' ').last}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          ComparisonRow(
            label: loc.translate('championships'),
            value1: driver1.championships,
            value2: driver2.championships,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('wins'),
            value1: driver1.wins,
            value2: driver2.wins,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('podiums'),
            value1: driver1.podiums,
            value2: driver2.podiums,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('poles'),
            value1: driver1.poles,
            value2: driver2.poles,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('fastest_laps'),
            value1: driver1.fastestLaps,
            value2: driver2.fastestLaps,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('total_points'),
            value1: driver1.totalPoints,
            value2: driver2.totalPoints,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('starts'),
            value1: driver1.starts,
            value2: driver2.starts,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('dnf'),
            value1: driver1.dnfs,
            value2: driver2.dnfs,
            isDark: isDark,
            lowerIsBetter: true,
          ),
          ComparisonRow(
            label: loc.translate('laps_led'),
            value1: driver1.lapsLed,
            value2: driver2.lapsLed,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('highestFinish'),
            value1: driver1.highestFinish,
            value2: driver2.highestFinish,
            isDark: isDark,
            lowerIsBetter: true,
          ),
          ComparisonRow(
            label: loc.translate('highestGrid'),
            value1: driver1.highestGrid,
            value2: driver2.highestGrid,
            isDark: isDark,
            lowerIsBetter: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDriverHeader(driver1)),
        const Padding(
          padding: EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0),
          child: Text(
            'VS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildDriverHeader(driver2)),
      ],
    );
  }

  Widget _buildDriverHeader(Driver driver) {
    return Column(
      children: [
        Text(driver.flag, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          driver.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        Text(
          '#${driver.number}',
          style: TextStyle(
            color: _getTeamColor(driver.team),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// --- TEAM COMPARISON VIEW ----------------------------------------------
class TeamComparisonView extends StatelessWidget {
  final Team team1;
  final Team team2;

  const TeamComparisonView({
    required this.team1,
    required this.team2,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('${team1.name} vs ${team2.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          ComparisonRow(
            label: loc.translate('cc_wins'),
            value1: team1.ccWins,
            value2: team2.ccWins,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('dc_wins'),
            value1: team1.dcWins,
            value2: team2.dcWins,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('wins'),
            value1: team1.podiums,
            value2: team2.podiums,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('one_two'),
            value1: team1.oneTwo,
            value2: team2.oneTwo,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('poles'),
            value1: team1.poles,
            value2: team2.poles,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('fastest_laps'),
            value1: team1.fastestLaps,
            value2: team2.fastestLaps,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('total_points'),
            value1: team1.totalPoints,
            value2: team2.totalPoints,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('total_entries'),
            value1: team1.totalEntries,
            value2: team2.totalEntries,
            isDark: isDark,
          ),
          ComparisonRow(
            label: loc.translate('fastestPit'),
            value1: team1.fastestPitstopTime,
            value2: team2.fastestPitstopTime,
            isDark: isDark,
            lowerIsBetter: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTeamHeader(team1)),
        const Padding(
          padding: EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0),
          child: Text(
            'VS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildTeamHeader(team2)),
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
          style: TextStyle(color: _getTeamColor(team.name), fontSize: 12),
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
      await Future.delayed(const Duration(milliseconds: 700));
      final res = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${widget.race.lat}&longitude=${widget.race.lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=precipitation_probability_max&timezone=auto',
        ),
      );
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) {
          setState(() {
            t = d['current']['temperature_2m'].toString();
            w = d['current']['wind_speed_10m'].toString();
            h = d['current']['relative_humidity_2m'].toString();
            r = d['daily']['precipitation_probability_max'][0];
            _isWeatherLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isWeatherLoading = false);
      }
    }
  }

  Widget _buildCircuitHero(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _heroPanelGradient(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.outline.withOpacity(0.7)),
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
            loc.translate('gp_${widget.race.name}').toUpperCase(),
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
                '${widget.race.laps} ${loc.translate('laps').toLowerCase()}',
              ),
              _buildHeroChip(
                context,
                Icons.workspace_premium,
                loc.translate(widget.race.circuitDifficulty),
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
        color: tokens.panelStrong.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.outline.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
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

  Widget _buildCircuitLayoutCard(BuildContext context, AppLocalizations loc) {
    final tokens = _themeTokens(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: tokens.panelStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.outline.withOpacity(0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('circuit_layout'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF2196F3),
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

  Widget _buildCircuitTopArea(BuildContext context, AppLocalizations loc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        if (isWide) {
          return SizedBox(
            height: 340,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: _buildCircuitHero(context, loc)),
                const SizedBox(width: 16),
                Expanded(flex: 9, child: _buildCircuitLayoutCard(context, loc)),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildCircuitHero(context, loc),
            const SizedBox(height: 20),
            SizedBox(height: 340, child: _buildCircuitLayoutCard(context, loc)),
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
    final loc = AppLocalizations.of(context);
    String translatedStrategy = widget.race.bestCombination
        .replaceAll('Soft', loc.translate('soft_tire'))
        .replaceAll('Medium', loc.translate('medium_tire'))
        .replaceAll('Hard', loc.translate('hard_tire'));
    final isDutch =
        loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de';
    final List<String> characteristics = isDutch
        ? widget.race.characteristicsNl
        : widget.race.characteristicsEn;
    String title = loc.translate('gp_${widget.race.name}').toUpperCase();
    if (_showFlagInTitle) {
      title = '${widget.race.flag} $title';
    }

    final List<Widget> circuitSections = [
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          loc.translate('weather_forecast'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          if (_isWeatherLoading)
            _buildWeatherSkeletonRows(context)
          else ...[
            _statTile(loc.translate('temp'), '$t°C', Icons.thermostat),
            _statTile(loc.translate('rain_chance'), '$r%', Icons.umbrella),
            _statTile(loc.translate('wind_speed'), '$w km/h', Icons.air),
            _statTile(loc.translate('humidity'), '$h%', Icons.water_drop),
            const SizedBox(height: 8),
          ],
        ],
      ),
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          loc.translate('circuit_info'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('length'),
            '${widget.race.length} m',
            Icons.straighten,
          ),
          _statTile(
            loc.translate('distanceToTurn1'),
            widget.race.distanceToTurn1,
            Icons.turn_right,
          ),
          _statTile(
            loc.translate('laps'),
            widget.race.laps.toString(),
            Icons.format_list_numbered,
          ),
          _statTile(
            loc.translate('since'),
            widget.race.firstGrandPrix.toString(),
            Icons.history,
          ),
          _statTile(
            loc.translate('until'),
            widget.race.contractUntil,
            Icons.event,
          ),
          _statTile(
            loc.translate('circuitDifficulty'),
            Text(
              loc.translate(widget.race.circuitDifficulty),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _getDifficultyColor(widget.race.circuitDifficulty),
              ),
            ),
            Icons.speed,
          ),
          _statTile(
            loc.translate('overtakingDifficulty'),
            Text(
              loc.translate(widget.race.overtakingDifficulty),
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
                label: const Text('Open in Maps'),
              ),
            ),
          ),
        ],
      ),
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          '⚡ ${loc.translate('lap_speed_stats')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('fastestLap'),
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
            loc.translate('slowestLap'),
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
            loc.translate('avgLap'),
            widget.race.averageLap,
            Icons.av_timer,
          ),
          _statTile(
            loc.translate('topSpeed'),
            widget.race.topSpeed,
            Icons.speed,
          ),
          _statTile(
            loc.translate('averageSpeed'),
            widget.race.averageSpeed,
            Icons.directions_car,
          ),
          _statTile(
            loc.translate('max_g_force'),
            widget.race.maxGForce,
            Icons.compress,
          ),
          _statTile(
            loc.translate('avgForce'),
            widget.race.avgGForce,
            Icons.compress,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('risks_incidents'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('redFlag'),
            '${widget.race.redFlagChance}%',
            Icons.flag,
          ),
          _statTile(
            loc.translate('vsc'),
            '${widget.race.vscChance}%',
            Icons.warning_amber,
          ),
          _statTile(
            loc.translate('accident'),
            '${widget.race.accidentChance}%',
            Icons.car_crash,
          ),
          _statTile(
            loc.translate('turn1Accident'),
            '${widget.race.turn1AccidentChance}%',
            Icons.turn_right,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          '🛞 ${loc.translate('tyres_strategy')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('tireWear'),
            loc.translate('wear_${widget.race.tireWear}'),
            Icons.layers,
          ),
          _statTile(
            loc.translate('strategy'),
            loc.translate('strategy_${widget.race.tireStrategy}'),
            Icons.settings_suggest,
          ),
          _statTile(
            loc.translate('bestCombination'),
            translatedStrategy,
            Icons.donut_large,
          ),
          _statTile(
            loc.translate('fastestPit'),
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
      ),
      ExpansionTile(
        title: Text(
          '📍 ${loc.translate('characteristics')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
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
                          const Text(
                            '📌 ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
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
      ),
    ];

    return Scaffold(
      appBar: AppBar(actions: [widget.settingsMenu], title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _fetchWeather,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            _buildCircuitTopArea(context, loc),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: Text(
                  loc.translate('session_results'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SessionResultsScreen(race: widget.race),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildResponsiveSections(sections: circuitSections),
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
  bool _showFullTitle = false;
  bool _showAllDnfs = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 140;
      if (show != _showFullTitle) {
        setState(() => _showFullTitle = show);
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            ? const Color(0xFF2196F3)
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
                                  color: color.withOpacity(0.5),
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
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "20${years[_selectedYearIndex!]} Finish: P${pos[_selectedYearIndex!]}",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
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
    final history = List<String>.from(widget.driver.previousTeams);
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

    history.add('${widget.driver.team} - F1 ($currentYears)');
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
                              color: const Color(0xFF2196F3),
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
                            color: const Color(0xFF2196F3),
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
    final entries = widget.driver.pointsPerSeason.entries
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
                        color: const Color(0xFF2196F3),
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
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDutch =
        loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de';
    final List<String> facts = isDutch
        ? widget.driver.realWorldFactsNl
        : widget.driver.realWorldFactsEn;
    final List<int> driverHistory = _getDriverHistory(widget.driver.name);

    String title = widget.driver.name.toUpperCase();
    if (_showFullTitle) {
      title = "${widget.driver.flag} $title - #${widget.driver.number}";
    }

    final List<Widget> driverSections = [
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          loc.translate('driver_history'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildHistoryChart(
              driverHistory,
              _getTeamColor(widget.driver.team),
            ),
          ),
        ],
      ),
      if (widget.driver.previousTeams.isNotEmpty)
        ExpansionTile(
          title: Text(
            loc.translate('previous_teams'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF2196F3),
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
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          loc.translate('driver_facts_title'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📌 ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              f,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
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
      ),
      ExpansionTile(
        title: Text(
          loc.translate('personal_info'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(loc.translate('age'), widget.driver.age, Icons.cake),
          _statTile(
            loc.translate('height'),
            widget.driver.height,
            Icons.height,
          ),
          _statTile(
            loc.translate('birth_place'),
            widget.driver.birthPlace,
            Icons.location_on,
          ),
          _statTile(
            loc.translate('partner'),
            widget.driver.partner,
            Icons.favorite,
          ),
          _statTile(
            loc.translate('children'),
            widget.driver.children,
            Icons.child_care,
          ),
          _statTile(loc.translate('pets'), widget.driver.pets, Icons.pets),
          _statTile(
            loc.translate('manager'),
            widget.driver.manager,
            Icons.work,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('general'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('nationality'),
            loc.translate('nat_${widget.driver.nationality}'),
            Icons.public,
          ),
          _statTile(
            loc.translate('f1_debut'),
            widget.driver.debutYear,
            Icons.start,
          ),
          _statTile(
            loc.translate('contract_until'),
            widget.driver.contractUntil,
            Icons.edit_document,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('career_stats'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('championships'),
            widget.driver.championships,
            Icons.workspace_premium,
          ),
          _statTile(
            loc.translate('wins'),
            widget.driver.wins,
            Icons.emoji_events,
          ),
          _statTile(
            loc.translate('podiums'),
            widget.driver.podiums,
            Icons.leaderboard,
          ),
          _statTile(loc.translate('poles'), widget.driver.poles, Icons.flag),
          _statTile(
            loc.translate('fastest_laps'),
            widget.driver.fastestLaps,
            Icons.timer,
          ),
          _statTile(
            loc.translate('highestFinish'),
            widget.driver.highestFinish,
            Icons.military_tech,
          ),
          _statTile(
            loc.translate('highestGrid'),
            widget.driver.highestGrid,
            Icons.grid_3x3,
          ),
          _statTile(
            loc.translate('hatTricks'),
            widget.driver.hatTricks,
            Icons.auto_awesome,
          ),
          _statTile(
            loc.translate('frontRowStarts'),
            widget.driver.frontRowStarts,
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
                        ).colorScheme.primary.withOpacity(0.8),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.translate('total_points'),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.driver.totalPoints.toString(),
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
            loc.translate('overtakes'),
            widget.driver.overtakes,
            Icons.compare_arrows,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('experience'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('starts'),
            widget.driver.starts,
            Icons.traffic,
          ),
          _statTile(
            loc.translate('laps_led'),
            widget.driver.lapsLed,
            Icons.looks_one,
          ),
          _statTile(loc.translate('dnf'), widget.driver.dnfs, Icons.car_crash),
          _statTile(loc.translate('dsqs'), widget.driver.dsqs, Icons.block),
          _statTile(
            loc.translate('dnqs'),
            widget.driver.dnqs,
            Icons.cancel_schedule_send,
          ),
          if (widget.driver.dnfs > 0)
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
                          ).colorScheme.primary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loc.translate('retirements'),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.82),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.driver.dnfs.toString(),
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
      ),
      ExpansionTile(
        title: Text(
          loc.translate('personal_sponsors'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          ...widget.driver.personalSponsors.map(
            (s) => _statTile(s, '', Icons.business_center),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [widget.settingsMenu]),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: _buildFlagHero(
              tag: widget.heroTag,
              flag: widget.driver.flag,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "#${widget.driver.number}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getTeamColor(widget.driver.team),
            ),
          ),
          const SizedBox(height: 20),
          _buildResponsiveSections(sections: driverSections),
        ],
      ),
    );
  }

  Widget _buildDnfTimeline() {
    final theme = Theme.of(context);
    final tokens = _themeTokens(context);
    final allEntries = _getDnfEntries(widget.driver.name);
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
                          color: theme.colorScheme.primary,
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
                            color: tokens.outline.withOpacity(0.75),
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
                                color: theme.colorScheme.primary,
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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
                        color: const Color(0xFF2196F3),
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
                        color: const Color(0xFF2196F3),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return constraints.maxWidth > 600
            ? _buildHorizontalTimeline(entries)
            : _buildVerticalTimeline(entries);
      },
    );
  }

  Map<int, double> _resolveTitlePoints(Map<String, Map<int, double>> source) {
    for (final entry in source.entries) {
      if (widget.team.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return const <int, double>{};
  }

  Map<int, List<String>> _resolveTitleDrivers(
    Map<String, Map<int, List<String>>> source,
  ) {
    for (final entry in source.entries) {
      if (widget.team.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return const <int, List<String>>{};
  }

  Map<int, String> _resolveChampionDriversByYear() {
    final champions = <int, String>{};

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
        champions[year] = driverName;
      }
    }

    return champions;
  }

  String _formatTimelinePoints(double points) {
    if (points == points.roundToDouble()) {
      return '${points.toInt()} pts';
    }
    return '${points.toStringAsFixed(1)} pts';
  }

  Widget _buildAdaptiveStatTimeline(List<Map<String, String>> entries) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

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
                        color: const Color(0xFF2196F3),
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
                        color: const Color(0xFF2196F3),
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
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
                  loc.translate('drivers'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  loc.translate('reserve_driver'),
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.primary,
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
                            ? const Color(0xFF2196F3)
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
                                  color: color.withOpacity(0.5),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => DriverDetailView(
                      driver: d,
                      heroTag: _driverFlagHeroTag(
                        d,
                        source: 'team-roster:${widget.team.name}',
                      ),
                      settingsMenu: widget.settingsMenu,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 8),
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
                      if (d.nationality.isNotEmpty)
                        _buildFlagHero(
                          tag: _driverFlagHeroTag(
                            d,
                            source: 'team-roster:${widget.team.name}',
                          ),
                          flag: d.flag,
                          fontSize: 12,
                          textAlign: TextAlign.left,
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
    final loc = AppLocalizations.of(context);
    final teamHistory = _getTeamHistory(widget.team.name);

    String title = widget.team.name.toUpperCase();
    if (_showFlagInTitle) {
      title = "${widget.team.flag} $title";
    }

    final List<Widget> teamSections = [
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          "📊 Performance History",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildHistoryChart(
              teamHistory,
              _getTeamColor(widget.team.name),
            ),
          ),
        ],
      ),
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          loc.translate('general'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('engine'),
            widget.team.engine,
            Icons.settings_input_component,
          ),
          _statTile(
            loc.translate('headquarters'),
            widget.team.headquarters,
            Icons.location_city,
          ),
          _statTile(
            loc.translate('total_points'),
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
                  loc.translate('team_history'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.82),
                    fontSize: 13,
                  ),
                ),
                children: [_buildAdaptiveTimeline(_buildTeamHistoryEntries())],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          loc.translate('championships'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
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
                  loc.translate('cc_wins'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.82),
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
              loc.translate('cc_wins'),
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
                  loc.translate('dc_wins'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.82),
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
              loc.translate('dc_wins'),
              widget.team.dcWins,
              Icons.workspace_premium,
            ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('race_stats'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('total_entries'),
            widget.team.totalEntries,
            Icons.traffic,
          ),
          _statTile(
            loc.translate('wins'),
            widget.team.podiums,
            Icons.leaderboard,
          ),
          _statTile(
            loc.translate('one_two'),
            widget.team.oneTwo,
            Icons.filter_2,
          ),
          _statTile(loc.translate('poles'), widget.team.poles, Icons.flag),
          _statTile(
            loc.translate('fastest_laps'),
            widget.team.fastestLaps,
            Icons.timer,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('pitstop_leadership'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('team_principal'),
            "${widget.team.principalName} (${widget.team.principalAge})",
            Icons.person_outline,
          ),
          _statTile(
            loc.translate('technical_director'),
            "${widget.team.technicalDirectorName} (${widget.team.technicalDirectorAge})",
            Icons.engineering,
          ),
          _statTile(
            loc.translate('fastestPit'),
            "${widget.team.fastestPitstopTime} (${loc.translate('country_${widget.team.fastestPitstopCircuit}')} ${widget.team.fastestPitstopYear})",
            Icons.build,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          loc.translate('drivers'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [_buildDriverRosterTimeline(), const SizedBox(height: 8)],
      ),
      ExpansionTile(
        title: Text(
          '⚙️ ${loc.translate('engine_supplier')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          _statTile(
            loc.translate('name').split(' ').last,
            widget.team.engineSupplier.name,
            Icons.business,
          ),
          _statTile(
            loc.translate('engine_name').split(' ').last,
            widget.team.engineSupplier.engineName,
            Icons.settings,
          ),
          _statTile(
            loc.translate('city').split(' ').last,
            widget.team.engineSupplier.city,
            Icons.location_city,
          ),
          const SizedBox(height: 8),
        ],
      ),
      ExpansionTile(
        title: Text(
          '💰 ${loc.translate('sponsors')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2196F3),
          ),
        ),
        children: [
          ...widget.team.sponsors.map(
            (s) => _statTile(s, '', Icons.business_center),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [widget.settingsMenu]),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: _buildFlagHero(
              tag: widget.heroTag,
              flag: widget.team.flag,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: 20),

          if (widget.team.carImageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                widget.team.carImageUrl,
                fit: BoxFit.contain,
              ),
            ),

          _buildResponsiveSections(sections: teamSections),
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
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isFetching = true);
    int roundIndex = races.indexOf(widget.race) + 1;
    await SessionDataManager().fetchDataForRace(widget.race, roundIndex);
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "🏁 ${loc.translate('gp_${widget.race.name}')} - 📊 ${loc.translate('session_results')}",
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: _isFetching
                  ? _buildSessionResultsSkeleton(context, race: widget.race)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: widget.race.hasSprint
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 1',
                                  displayTitle: loc.translate('fp1'),
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Sprint Qualifying',
                                  displayTitle: loc.translate('sprint_quali'),
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Qualifying',
                                  displayTitle: loc.translate('qualifying'),
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Sprint',
                                  displayTitle: loc.translate('sprint'),
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
                                  displayTitle: loc.translate('fp1'),
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 2',
                                  displayTitle: loc.translate('fp2'),
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Practice 3',
                                  displayTitle: loc.translate('fp3'),
                                ),
                                OpenF1SessionWidget(
                                  race: widget.race,
                                  sessionName: 'Qualifying',
                                  displayTitle: loc.translate('qualifying'),
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
  bool get _isPracticeLikeSession =>
      sessionName == 'Practice 1' ||
      sessionName == 'Practice 2' ||
      sessionName == 'Practice 3' ||
      sessionName == 'Qualifying' ||
      sessionName == 'Sprint Qualifying';

  void _openFullscreenRaceResults(
    BuildContext context,
    List<RaceResultRow> rows,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenTablePage(
          title: displayTitle,
          tableBuilder: (pageContext) =>
              _buildRaceResultsTable(pageContext, rows),
        ),
      ),
    );
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

  Widget _buildTyreCell(BuildContext context, String compound) {
    final theme = Theme.of(context);
    final normalized = compound.trim();
    final isUnknown = normalized.isEmpty || normalized == '-';
    final assetPath = _tyreAssetPath(normalized);

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

    if (assetPath != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            assetPath,
            width: 42,
            height: 24,
            fit: BoxFit.contain,
            semanticsLabel: '$normalized tyre',
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
              color: Colors.white,
              letterSpacing: 0.2,
            ),
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
    const maxVisibleBodyRows = 8;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF171C25)
            : const Color(0xFFFFFFFF),
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
            final visibleBodyRows = rows.isEmpty
                ? 1
                : (rows.length > maxVisibleBodyRows
                      ? maxVisibleBodyRows
                      : rows.length);
            final tableHeight =
                headerHeight + (visibleBodyRows * bodyRowHeight);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark
        ? const Color(0xFF1D2430)
        : const Color(0xFFEAF5FF);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    Widget buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: theme.colorScheme.primary,
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
          ],
        ),
      );
    }

    final preferredColumnWidths = _isSprintSession
        ? const <double>[180, 62, 140, 84, 110, 58]
        : const <double>[190, 62, 130, 84];

    final headerCells = _isSprintSession
        ? <Widget>[
            buildHeaderCell('Coureur'),
            buildHeaderCell('Finish', align: TextAlign.right),
            buildHeaderCell('Tijd / Verschil'),
            buildHeaderCell('Band'),
            buildHeaderCell('Snelste ronde'),
            buildHeaderCell('Punten', align: TextAlign.right),
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
          final row = entry.value;
          final timerIcon = row.hasFastestLap
              ? const Icon(Icons.timer, size: 14, color: Color(0xFF8E24AA))
              : null;

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
                    color: row.hasFastestLap ? const Color(0xFF8E24AA) : null,
                  ),
                  buildBodyCell(
                    row.points,
                    align: TextAlign.right,
                    strong: true,
                  ),
                ]
              : <Widget>[
                  buildBodyCell(row.driver, strong: true, leading: timerIcon),
                  buildBodyCell(
                    row.position,
                    align: TextAlign.right,
                    strong: true,
                  ),
                  buildBodyCell(
                    row.result,
                    strong: row.hasFastestLap,
                    color: row.hasFastestLap ? const Color(0xFF8E24AA) : null,
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
      rowBackgroundBuilder: (rowIndex) => rowIndex.isEven
          ? Colors.transparent
          : (isDark ? const Color(0xFF141922) : const Color(0xFFF8FBFF)),
    );
  }

  Widget _buildRaceResultsTable(
    BuildContext context,
    List<RaceResultRow> rows,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark
        ? const Color(0xFF1D2430)
        : const Color(0xFFEAF5FF);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    Widget buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          textAlign: align,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: theme.colorScheme.primary,
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
        color: row.hasFastestLap ? const Color(0xFF8E24AA) : null,
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
          final penaltyText = (() {
            final normalized = row.penalty.trim();
            if (normalized.isEmpty ||
                normalized == '0' ||
                normalized == '0.0') {
              return '-';
            }
            return normalized;
          })();
          final hasPenalty = penaltyText != '-';
          final statusColor =
              row.finish == 'DNF' || row.finish == 'DNS' || row.finish == 'NC'
              ? const Color(0xFFE53935)
              : theme.colorScheme.onSurface;

          return <Widget>[
            buildBodyCell(
              row.driver,
              strong: true,
              trailing: row.hasFastestLap
                  ? const Icon(Icons.timer, size: 14, color: Color(0xFF8E24AA))
                  : null,
            ),
            buildBodyCell(row.start, align: TextAlign.right),
            buildBodyCell(
              row.finish,
              align: TextAlign.right,
              strong: true,
              color: statusColor,
            ),
            buildBodyCell(row.timeOrGap),
            buildBodyCell(
              penaltyText,
              strong: hasPenalty,
              color: hasPenalty ? const Color(0xFFF57C00) : null,
            ),
            _buildTyreCell(context, row.tyreCompound),
            buildFastestLapCell(row),
            buildBodyCell(row.points, align: TextAlign.right, strong: true),
          ];
        })
        .toList(growable: false);

    return _buildStickyResultsTable(
      context,
      preferredColumnWidths: const [170, 58, 92, 132, 78, 76, 102, 58],
      headerCells: headerCells,
      rows: tableRows,
      headerColor: headerColor,
      borderColor: borderColor,
      rowBackgroundBuilder: (rowIndex) => rowIndex.isEven
          ? Colors.transparent
          : (isDark ? const Color(0xFF141922) : const Color(0xFFF8FBFF)),
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
    final loc = AppLocalizations.of(context);
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
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

        if (sessionName == 'Race' && sessionTime.isAfter(DateTime.now())) {
          return const SizedBox.shrink();
        }
        if (sessionTime.isAfter(DateTime.now())) {
          return buildEmpty(
            displayTitle,
            '${loc.translate('session_future')} ${sessionTime.toString().substring(0, 16)}',
          );
        }
        if (results == null && !SessionDataManager().isInitialized) {
          return _buildSessionWidgetSkeleton(context, displayTitle);
        }
        if (sessionName == 'Race') {
          if (raceResults == null || raceResults.isEmpty) {
            return buildEmpty(displayTitle, loc.translate('no_data_yet'));
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Fullscreen table',
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
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
          return buildEmpty(displayTitle, loc.translate('no_data_yet'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
              child: Text(
                displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),

            // Toon de Top 3 direct
            ...results
                .take(3)
                .toList()
                .asMap()
                .entries
                .map((e) => _buildResultRow(e.value, e.key + 1)),

            // Uitklapbaar voor de rest van de rijders (P4 t/m P22)
            if (results.length > 3)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    "🔽 P4 t/m P${results.length} Weergeven",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: results
                      .skip(3)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _buildResultRow(e.value, e.key + 4))
                      .toList(),
                ),
              ),

            const SizedBox(height: 8),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          ],
        );
      },
    );
  }
}

class FullscreenTablePage extends StatefulWidget {
  final String title;
  final WidgetBuilder tableBuilder;

  const FullscreenTablePage({
    super.key,
    required this.title,
    required this.tableBuilder,
  });

  @override
  State<FullscreenTablePage> createState() => _FullscreenTablePageState();
}

class _FullscreenTablePageState extends State<FullscreenTablePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 4.0,
        child: widget.tableBuilder(context),
      ),
    );
  }
}

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> changelog = [
      {
        'version': '1.0.0',
        'date': 'Maart 2026',
        'changes_en': [
          'F1 Hub 1.0.0 is the first full-featured release with a layout tuned for desktop use, while still staying clear and readable on smaller screens.',
          'Added driver and team comparison screens to place stats, performance, and key differences side by side.',
          'Introduced visual timelines across the app, including driver performance history, team history, championship overviews, and points progression.',
          'Expanded driver pages with a full career path, including previous teams before Formula 1 and the racing class for each step.',
          'Upgraded Facts & Trivia from 2 to 5 items per driver, with localized content support.',
          'Added full DNF overviews with the reason for each retirement, plus a compact expandable timeline.',
          'Updated team championship sections with corrected title years and constructor title context, including the drivers involved.',
          'Expanded team pages with historical naming, full driver line-ups including reserve drivers, and clearer roster timelines.',
          'Refined the circuit pages with a more complete overview: layout image, direct key stats, Turn 1 distance, difficulty indicators, lap references, and supporting context.',
          'Added live-updating session results with richer tables, tyre compounds, fastest lap highlights, penalties, and responsive sticky headers for easier reading on desktop.',
          'Added quick map opening from the circuit page so the track location can be opened directly in Apple Maps or Google Maps.',
          'Improved current-season content, data completeness, and overall consistency across circuits, drivers, teams, and session screens.',
        ],
        'changes_nl': [
          'F1 Hub 1.0.0 is de eerste volledige release, met een lay-out die beter werkt op een vaste pc en tegelijk overzichtelijk blijft op kleinere schermen.',
          'Vergelijkingsschermen toegevoegd voor coureurs en teams, zodat statistieken, prestaties en onderlinge verschillen direct naast elkaar zichtbaar zijn.',
          'Visuele tijdlijnen toegevoegd in de app, waaronder coureurshistorie, teamgeschiedenis, kampioenschapsoverzichten en puntenverloop per seizoen.',
          'Coureurspagina\'s uitgebreid met een volledig carrièrepad, inclusief eerdere teams van voor de Formule 1 en de klasse per stap.',
          'Feiten & weetjes uitgebreid van 2 naar 5 items per coureur, met ondersteuning voor gelokaliseerde inhoud.',
          'Alle uitvalbeurten opgenomen inclusief reden van uitval, verwerkt in een compacte en uitklapbare tijdlijn.',
          'De kampioenschapssecties van teams bijgewerkt met gecorrigeerde titeljaren en extra context bij constructeurstitels, inclusief de betrokken coureurs.',
          'Team pagina\'s uitgebreid met teamgeschiedenis, eerdere namen, volledige rijdersbezetting inclusief reservecoureurs en duidelijkere tijdlijnen.',
          'De circuitpagina\'s zijn vernieuwd met een completer overzicht: lay-out afbeelding, direct zichtbare kerninformatie, afstand tot bocht 1, moeilijkheidsniveaus, rondereferenties en extra context.',
          'Live sessieresultaten toegevoegd met uitgebreidere tabellen, bandensoorten, snelste ronde-markeringen, straffen en sticky headers die vooral op desktop prettiger werken.',
          'Mogelijkheid toegevoegd om vanuit de circuitpagina direct Apple Maps of Google Maps te openen voor de locatie van het circuit.',
          'De actuele seizoensdata, inhoudelijke volledigheid en algemene consistentie zijn verbeterd over circuits, coureurs, teams en sessieschermen.',
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('changelog'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: changelog.length,
        itemBuilder: (context, index) {
          final entry = changelog[index];
          final changes =
              loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de'
              ? entry['changes_nl']
              : entry['changes_en'];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${loc.translate('version')} ${entry['version']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        entry['date'],
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...changes.map<Widget>(
                    (change) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              change,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
