import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:js' as js;

/// --- INTERNE LOKALISATIE MET EMOJIS -------------------------
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations) ?? const AppLocalizations(Locale('en'));
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
    'week': 'week', 'weeks': 'weken',
    'day': 'dag', 'days': 'dagen',
    'hours': 'uur', 'minutes': 'minuten', 'sponsors': 'Sponsors',
    'drivers': 'Coureurs', 'teams': 'Teams',
    'pts': 'PNT',
    'using_fallback_data': 'Offline/Fallback data in gebruik.',
    'points_history': 'Punten per Seizoen',
    'session_results': 'Sessie Resultaten',
    'fp1': 'Vrije Training 1', 'fp2': 'Vrije Training 2', 'fp3': 'Vrije Training 3',
    'sprint_quali': 'Sprint Kwalificatie', 'sprint': 'Sprintrace', 'qualifying': 'Kwalificatie',
    'session_future': 'Sessie begint op', 'no_data_yet': 'Data nog niet beschikbaar of API is nog niet geüpdatet',
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
    'totalLength': 'Totale Lengte', 'laps': 'Rondes',
    'fastestLap': 'Snelste Ronde', 'slowestLap': 'Langzaamste Ronde', 'avgLap': 'Gemiddelde Ronde',
    'topSpeed': 'Topsnelheid', 'averageSpeed': 'Gemiddelde Snelheid',
    'avgGForce': 'Gem. G-Kracht',
    'max_g_force': 'Max G-Kracht', 'risks': 'Risico\'s',
    'redFlag': 'Kans op Rode Vlag', 'vsc': 'Kans op VSC', 'accident': 'Kans op Crash',
    'turn1Accident': 'Kans Crash Bocht 1',
    'tyres': 'Banden', 'tireWear': 'Bandenslijtage', 'strategy': 'Strategie', 'bestCombination': 'Beste Combinatie',
    'fastestPit': 'Snelste Pitstop',
    'driver_facts_title': 'Feiten & Weetjes', 'general': 'Algemeen', 'current_team': 'Huidig Team', 'nationality': 'Nationaliteit',
    'personal_info': 'Persoonlijke Info',
    'age': 'Leeftijd', 'birth_place': 'Geboorteplaats',
    'partner': 'Partner', 'pets': 'Huisdieren',
    'children': 'Kinderen',
    'manager': 'Manager',
    'previous_teams': 'Vorige Teams',
    'career_stats': 'Carrière Statistieken', 'championships': 'Wereldtitels', 'wins': 'Overwinningen', 'podiums': 'Podiums',
    'poles': 'Pole Positions', 'fastest_laps': 'Snelste Rondes', 'total_points': 'Totale Punten',
    'f1_debut': 'F1 Debuut', 'contract_until': 'Contract tot',
    'driver_history': 'Historie (Laatste 5 jaar)',
    'experience': 'Ervaring', 'starts': 'Starts', 'laps_led': 'Rondes aan de leiding', 'dnf': 'Uitvalbeurten (DNF)',
    'dsqs': 'DSQs', 'Gediskwalificeerd': 'Niet gekwalificeerd', 'frontRowStarts': 'Starts 1e Rij', 'highestFinish': 'Hoogste Finish',
    'highestGrid': 'Hoogste Startplek',
    'hatTricks': 'Hattricks',
    'cc_wins': 'Constructeurstitels', 'dc_wins': 'Coureurstitels', 'race_stats': 'Race Statistieken',
    'total_entries': 'Totale Inschrijvingen', 'one_two': '1-2 Finishes', 'pitstop_leadership': 'Pitstop & Leiderschap',
    'overtakes': 'Inhaalacties',
    'team_principal': 'Teambaas',
    'technical_director': 'Technisch Directeur',
    'height': 'Lengte', 'engine': 'Motor',
    'soft_tire': 'Zacht', 'medium_tire': 'Medium', 'hard_tire': 'Hard',
    'wear_High': 'Hoog', 'wear_Medium': 'Gemiddeld', 'wear_Low': 'Laag',
    'strategy_1 stop': '1 stop', 'strategy_2 stops': '2 stops', 'strategy_3 stops': '3 stops',
    'level_1': 'Zeer Makkelijk', 'level_2': 'Makkelijk', 'level_3': 'Gemiddeld', 'level_4': 'Moeilijk', 'level_5': 'Zeer Moeilijk',
    'nat_Dutch': 'Nederlands', 'nat_British': 'Brits', 'nat_Spanish': 'Spaans', 'nat_Monegasque': 'Monegaskisch', 'nat_Australian': 'Australisch',
    'nat_French': 'Frans', 'nat_German': 'Duits', 'nat_Thai': 'Thais', 'nat_Canadian': 'Canadees', 'nat_Japanese': 'Japans', 'nat_Italian': 'Italiaans',
    'nat_New Zealander': 'Nieuw-Zeelands', 'nat_Brazilian': 'Braziliaans', 'nat_Argentine': 'Argentijns', 'nat_Mexican': 'Mexicaans', 'nat_Finnish': 'Fins',
    'gp_Bahrain Grand Prix': 'Grand Prix van Bahrein', 'gp_Saudi Arabian Grand Prix': 'Grand Prix van Saoedi-Arabië', 'gp_Australian Grand Prix': 'Grand Prix van Australië',
    'gp_Japanese Grand Prix': 'Grand Prix van Japan', 'gp_Chinese Grand Prix': 'Grand Prix van China', 'gp_Miami Grand Prix': 'Grand Prix van Miami',
    'gp_Barcelona Grand Prix': 'Grand Prix van Barcelona', 'gp_Monaco Grand Prix': 'Grand Prix van Monaco', 'gp_Canadian Grand Prix': 'Grand Prix van Canada',
    'gp_Spanish Grand Prix': 'Grand Prix van Spanje', 'gp_Austrian Grand Prix': 'Grand Prix van Oostenrijk', 'gp_British Grand Prix': 'Grand Prix van Groot-Brittannië',
    'gp_Hungarian Grand Prix': 'Grand Prix van Hongarije', 'gp_Belgian Grand Prix': 'Grand Prix van België', 'gp_Dutch Grand Prix': 'Grand Prix van Nederland',
    'gp_Italian Grand Prix': 'Grand Prix van Italië', 'gp_Azerbaijan Grand Prix': 'Grand Prix van Azerbeidzjan', 'gp_Singapore Grand Prix': 'Grand Prix van Singapore',
    'gp_United States Grand Prix': 'Grand Prix van de VS', 'gp_Mexico City Grand Prix': 'Grand Prix van Mexico', 'gp_São Paulo Grand Prix': 'Grand Prix van São Paulo',
    'gp_Las Vegas Grand Prix': 'Grand Prix van Las Vegas', 'gp_Qatar Grand Prix': 'Grand Prix van Qatar', 'gp_Abu Dhabi Grand Prix': 'Grand Prix van Abu Dhabi',
    'country_Bahrain': 'Bahrein', 'country_Saudi Arabia': 'Saoedi-Arabië', 'country_Australia': 'Australië', 'country_Japan': 'Japan', 'country_China': 'China',
    'country_USA': 'VS', 'country_Italy': 'Italië', 'country_Monaco': 'Monaco', 'country_Canada': 'Canada', 'country_Spain': 'Spanje',
    'country_Austria': 'Oostenrijk', 'country_UK': 'Groot-Brittannië', 'country_Hungary': 'Hongarije', 'country_Belgium': 'België', 'country_Netherlands': 'Nederland',
    'country_Azerbaijan': 'Azerbeidzjan', 'country_Singapore': 'Singapore', 'country_Mexico': 'Mexico', 'country_Brazil': 'Brazilië', 'country_Qatar': 'Qatar', 'country_UAE': 'V.A.E.',
    'clear_cache': 'Cache Legen', 'cache_cleared': 'Cache succesvol geleegd!',
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
    'week': 'week', 'weeks': 'weeks',
    'day': 'day', 'days': 'days',
    'hours': 'hours', 'minutes': 'minutes', 'sponsors': 'Sponsors',
    'drivers': 'Drivers', 'teams': 'Teams',
    'pts': 'PTS',
    'using_fallback_data': 'Using offline/fallback data.',
    'points_history': 'Points per Season',
    'session_results': 'Session Results',
    'fp1': 'Practice 1', 'fp2': 'Practice 2', 'fp3': 'Practice 3',
    'sprint_quali': 'Sprint Qualifying', 'sprint': 'Sprint', 'qualifying': 'Qualifying',
    'session_future': 'Session begins at', 'no_data_yet': 'Data not available yet or API pending update',
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
    'totalLength': 'Total Length', 'laps': 'Laps',
    'fastestLap': 'Fastest Lap', 'slowestLap': 'Slowest Lap', 'avgLap': 'Average Lap',
    'topSpeed': 'Top Speed', 'averageSpeed': 'Average Speed',
    'avgGForce': 'Avg G-Force',
    'max_g_force': 'Max G-Force', 'risks': 'Risks',
    'redFlag': 'Red Flag Chance', 'vsc': 'VSC Chance', 'accident': 'Accident Chance',
    'turn1Accident': 'Turn 1 Accident Chance',
    'tyres': 'Tyres', 'tireWear': 'Tire Wear', 'strategy': 'Strategy', 'bestCombination': 'Best Combination',
    'fastestPit': 'Fastest Pitstop',
    'driver_facts_title': 'Facts & Trivia', 'general': 'General', 'current_team': 'Current Team', 'nationality': 'Nationality',
    'personal_info': 'Personal Info',
    'age': 'Age', 'birth_place': 'Birthplace',
    'partner': 'Partner', 'pets': 'Pets',
    'children': 'Children',
    'manager': 'Manager',
    'previous_teams': 'Previous Teams',
    'career_stats': 'Career Stats', 'championships': 'Championships', 'wins': 'Wins', 'podiums': 'Podiums',
    'poles': 'Pole Positions', 'fastest_laps': 'Fastest Laps', 'total_points': 'Total Points',
    'f1_debut': 'F1 Debut', 'contract_until': 'Contract until',
    'driver_history': 'History (Last 5 Years)',
    'experience': 'Experience', 'starts': 'Starts', 'laps_led': 'Laps Led', 'dnf': 'Did Not Finish',
    'dsqs': 'Disqualified', 'dnqs': 'Did Not Qualify', 'frontRowStarts': 'Front Row Starts', 'highestFinish': 'Highest Finish',
    'highestGrid': 'Highest Grid Position',
    'hatTricks': 'Hat Tricks',
    'cc_wins': 'Constructors Titles', 'dc_wins': 'Drivers Titles', 'race_stats': 'Race Stats',
    'total_entries': 'Total Entries', 'one_two': '1-2 Finishes', 'pitstop_leadership': 'Pitstop & Leadership',
    'overtakes': 'Overtakes',
    'team_principal': 'Team Principal',
    'technical_director': 'Technical Director',
    'height': 'Height', 'engine': 'Engine',
    'soft_tire': 'Soft', 'medium_tire': 'Medium', 'hard_tire': 'Hard',
    'wear_High': 'High', 'wear_Medium': 'Medium', 'wear_Low': 'Low',
    'strategy_1 stop': '1 stop', 'strategy_2 stops': '2 stops', 'strategy_3 stops': '3 stops',
    'level_1': 'Very Easy', 'level_2': 'Easy', 'level_3': 'Medium', 'level_4': 'Hard', 'level_5': 'Very Hard',
    'nat_Dutch': 'Dutch', 'nat_British': 'British', 'nat_Spanish': 'Spanish', 'nat_Monegasque': 'Monegasque', 'nat_Australian': 'Australian',
    'nat_French': 'French', 'nat_German': 'German', 'nat_Thai': 'Thai', 'nat_Canadian': 'Canadian', 'nat_Japanese': 'Japanese', 'nat_Italian': 'Italian',
    'nat_New Zealander': 'New Zealander', 'nat_Brazilian': 'Brazilian', 'nat_Argentine': 'Argentine', 'nat_Mexican': 'Mexican', 'nat_Finnish': 'Finnish',
    'gp_Bahrain Grand Prix': 'Bahrain Grand Prix', 'gp_Saudi Arabian Grand Prix': 'Saudi Arabian Grand Prix', 'gp_Australian Grand Prix': 'Australian Grand Prix',
    'gp_Japanese Grand Prix': 'Japanese Grand Prix', 'gp_Chinese Grand Prix': 'Chinese Grand Prix', 'gp_Miami Grand Prix': 'Miami Grand Prix',
    'gp_Barcelona Grand Prix': 'Barcelona Grand Prix', 'gp_Monaco Grand Prix': 'Monaco Grand Prix', 'gp_Canadian Grand Prix': 'Canadian Grand Prix',
    'gp_Spanish Grand Prix': 'Spanish Grand Prix', 'gp_Austrian Grand Prix': 'Austrian Grand Prix', 'gp_British Grand Prix': 'British Grand Prix',
    'gp_Hungarian Grand Prix': 'Hungarian Grand Prix', 'gp_Belgian Grand Prix': 'Belgian Grand Prix', 'gp_Dutch Grand Prix': 'Dutch Grand Prix',
    'gp_Italian Grand Prix': 'Italian Grand Prix', 'gp_Azerbaijan Grand Prix': 'Azerbaijan Grand Prix', 'gp_Singapore Grand Prix': 'Singapore Grand Prix',
    'gp_United States Grand Prix': 'United States Grand Prix', 'gp_Mexico City Grand Prix': 'Mexico City Grand Prix', 'gp_São Paulo Grand Prix': 'São Paulo Grand Prix',
    'gp_Las Vegas Grand Prix': 'Las Vegas Grand Prix', 'gp_Qatar Grand Prix': 'Qatar Grand Prix', 'gp_Abu Dhabi Grand Prix': 'Abu Dhabi Grand Prix',
    'country_Bahrain': 'Bahrain', 'country_Saudi Arabia': 'Saudi Arabia', 'country_Australia': 'Australia', 'country_Japan': 'Japan', 'country_China': 'China',
    'country_USA': 'USA', 'country_Italy': 'Italy', 'country_Monaco': 'Monaco', 'country_Canada': 'Canada', 'country_Spain': 'Spain',
    'country_Austria': 'Austria', 'country_UK': 'UK', 'country_Hungary': 'Hungary', 'country_Belgium': 'Belgium', 'country_Netherlands': 'Netherlands', 'country_Azerbaijan': 'Azerbaijan', 'country_Singapore': 'Singapore', 'country_Mexico': 'Mexico', 'country_Brazil': 'Brazil', 'country_Qatar': 'Qatar', 'country_UAE': 'UAE',
    'clear_cache': 'Clear Cache', 'cache_cleared': 'Cache cleared successfully!',
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
    return _localizedValues[locale.languageCode]?[key] ?? _enDictionary[key] ?? key; 
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => ['en', 'nl', 'fr', 'es', 'de'].contains(locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
/// ---------------------------------------------------------------------

class EngineSupplier {
  final String name;
  final String engineName;
  final String city;
  EngineSupplier({required this.name, required this.engineName, required this.city});
}

final Map<String, EngineSupplier> engineSuppliers = {
  'Mercedes': EngineSupplier(name: 'Mercedes-AMG High Performance Powertrains', engineName: 'M17 E Performance', city: 'Brixworth, UK'),
  'Red Bull Ford': EngineSupplier(name: 'Red Bull Ford Powertrains', engineName: 'RB-Ford 2026', city: 'Milton Keynes, UK'),
  'Ferrari': EngineSupplier(name: 'Ferrari S.p.A.', engineName: '066/12', city: 'Maranello, IT'),
  'Honda': EngineSupplier(name: 'Honda Racing Corporation', engineName: 'Honda RBH002', city: 'Sakura, JP'),
  'Audi': EngineSupplier(name: 'Audi Formula Racing GmbH', engineName: 'Audi F1 2026', city: 'Neuburg, DE'),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SessionDataManager().init(races);
  runApp(const F1HubApp());
}

class F1HubApp extends StatefulWidget {
  const F1HubApp({super.key});

  @override
  State<F1HubApp> createState() => _F1HubAppState();
}

class _F1HubAppState extends State<F1HubApp> {
  Locale? _locale; 
  ThemeMode _themeMode = ThemeMode.dark;

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
      if (isDark != null) _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
    SharedPreferences.getInstance().then((p) => p.setString('language_code', newLocale.languageCode));
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    SharedPreferences.getInstance().then((p) => p.setBool('is_dark', _themeMode == ThemeMode.dark));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2196F3),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F2F7),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5, color: Colors.black),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        dividerColor: Colors.transparent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        cardTheme: CardThemeData(
          color: const Color(0xFF16161E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5, color: Colors.white),
        ),
        dividerColor: Colors.transparent, 
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      locale: _locale, 
      supportedLocales: const [Locale('en'), Locale('nl'), Locale('fr'), Locale('es'), Locale('de')],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == deviceLocale.languageCode) return supportedLocale;
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
    'Dutch': '', 'British': '', 'Monegasque': '', 'Spanish': '',
    'Australian': '', 'Italian': '', 'German': '', 'French': '',
    'Austrian': '', 'Swiss': '', 'Thai': '', 'Japanese': '', 
    'American': '', 'Mexican': '', 'Finnish': '', 'Argentine': '', 'New Zealander': '', 'Chinese': '', 'Danish': '',
    'Netherlands': '', 'Australia': '', 'Bahrain': '', 'Saudi Arabia': '', 'Japan': '', 'China': '',
    'USA': '', 'Monaco': '', 'Canada': '', 'Spain': '', 'Austria': '', 'UK': '', 'Hungary': '', 'Belgium': '',
    'Azerbaijan': '', 'Singapore': '', 'Mexico': '', 'Brazil': '', 'Qatar': '', 'UAE': '', 'United States': '', 'Italy': '',
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
  if (t.toLowerCase().contains('audi') || t.toLowerCase().contains('sauber')) return const Color(0xFFE2FF00);
  if (t.toLowerCase().contains('racing bulls') || t.toLowerCase().contains('rb')) return const Color(0xFF6692FF);
  if (t.toLowerCase().contains('cadillac')) return const Color(0xFFFFB800);
  return Colors.blueGrey;
}

String getTireEmoji(String compound) {
  switch (compound.toUpperCase()) {
    case 'SOFT': return 'Soft';
    case 'MEDIUM': return 'Med';
    case 'HARD': return 'Hard';
    case 'INTERMEDIATE': return 'Int';
    case 'WET': return 'Wet';
    default: return '$compound';
  }
}

String getCompactTireEmoji(String compound) {
  switch (compound.toUpperCase()) {
    case 'SOFT': return '';
    case 'MEDIUM': return '';
    case 'HARD': return '';
    case 'INTERMEDIATE': return '';
    case 'WET': return '';
    default: return '';
  }
}

Widget _sectionHeader(String t, String emoji) => Builder(builder: (context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
  padding: const EdgeInsets.only(top: 25, bottom: 12), 
  child: Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Text(t.toUpperCase(), style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2.0)),
      Expanded(child: Divider(indent: 15, color: isDark ? Colors.white10 : Colors.black12)),
    ],
  )
);});

Widget _statTile(String l, dynamic v, IconData icon) => Builder(builder: (context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
  margin: const EdgeInsets.symmetric(vertical: 4),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF2196F3).withOpacity(0.7)),
      const SizedBox(width: 12),
      Text(l, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
    ]),
    Flexible(child: v is Widget ? v : Text(v.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black), textAlign: TextAlign.right)),
  ]),
);});

/// --- Data Manager voor OpenF1 Sessies -----------------------

class SessionDataManager extends ChangeNotifier {
  static final SessionDataManager _instance = SessionDataManager._internal();
  factory SessionDataManager() => _instance;
  SessionDataManager._internal();

  final Map<String, List<SessionResult>> cache = {};
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
          final List decoded = jsonDecode(jsonStr);
          cache[key] = decoded.map((e) => SessionResult.fromJson(e)).toList();
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

  void _saveResults(List resultsData, String sessionType, String defaultTyre, String key, SharedPreferences prefs) {
    final results = resultsData.map((r) {
      String timeStr = 'N/A';
      if (sessionType == 'Qualifying' || sessionType == 'Sprint Qualifying') {
        timeStr = r['Q3'] ?? r['Q2'] ?? r['Q1'] ?? 'No Time';
      } else {
        timeStr = r['Time'] != null ? r['Time']['time'] : (r['status'] ?? 'Unknown');
      }
      return SessionResult(
        "${r['Driver']['givenName']} ${r['Driver']['familyName']}",
        timeStr,
        defaultTyre, 
      );
    }).toList();

    cache[key] = results;
    prefs.setString(key, jsonEncode(results.map((e) => e.toJson()).toList()));
  }

  Future<void> fetchDataForRace(Race race, int round) async {
    final prefs = await SharedPreferences.getInstance();
    final currentYear = race.date.year; 

    Future<void> fetchSession(String sessionType, String endpoint, String arrayName, String defaultTyre) async {
      final key = '${race.country}_${sessionType}_$currentYear';
      
      try {
        await Future.delayed(const Duration(milliseconds: 700)); 
        var res = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/$currentYear/$round/$endpoint.json')).timeout(const Duration(seconds: 4));
        
        bool dataFound = false;

        if (res.statusCode == 200) {
          final d = json.decode(res.body);
          final rList = d['MRData']['RaceTable']['Races'] as List;
          if (rList.isNotEmpty && rList[0][arrayName] != null) {
            final resultsData = rList[0][arrayName] as List;
            if (resultsData.isNotEmpty) {
              dataFound = true;
              _saveResults(resultsData, sessionType, defaultTyre, key, prefs);
            }
          }
        }

        // SLIMME FALLBACK: Als de API nog niet verwerkt is, val dan terug op vorig jaar
        if (!dataFound) {
          await Future.delayed(const Duration(milliseconds: 700)); 
          int fallbackYear = currentYear - 1; 
          var fbRes = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/$fallbackYear/$round/$endpoint.json')).timeout(const Duration(seconds: 4));
          
          if (fbRes.statusCode == 200) {
            final d = json.decode(fbRes.body);
            final rList = d['MRData']['RaceTable']['Races'] as List;
            if (rList.isNotEmpty && rList[0][arrayName] != null) {
              final resultsData = rList[0][arrayName] as List;
              if (resultsData.isNotEmpty) {
                _saveResults(resultsData, sessionType, defaultTyre, key, prefs);
              }
            }
          }
        }
      } catch (_) {}
    }

    await fetchSession('Qualifying', 'qualifying', 'QualifyingResults', 'SOFT');
    await fetchSession('Race', 'results', 'Results', 'HARD');

    if (race.hasSprint) {
      await fetchSession('Sprint', 'sprint', 'SprintResults', 'MEDIUM');
    }
    
    notifyListeners();
  }
}

class SessionResult {
  final String driver;
  final String time;
  final String tyre;

  SessionResult(this.driver, this.time, this.tyre);
  Map<String, dynamic> toJson() => {'driver': driver, 'time': time, 'tyre': tyre};
  factory SessionResult.fromJson(Map<String, dynamic> json) => SessionResult(json['driver'], json['time'], json['tyre']);
}

/// --- MAIN NAVIGATION (UI) MET GENESTE VIEWS ----------------------------------------------
class MainNavigation extends StatefulWidget {
  final ValueChanged<Locale> onSetLocale;
  final VoidCallback onToggleTheme;

  const MainNavigation({required this.onSetLocale, required this.onToggleTheme, super.key});
  @override State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  
  final GlobalKey<NavigatorState> _racesNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _driversNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _teamsNavKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    SessionDataManager().fetchAllData();
  }

  Widget _buildSettingsMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return PopupMenuButton<int>(
      icon: const Icon(Icons.settings),
      onSelected: (value) async {
        if (value == 0) widget.onToggleTheme();
        if (value == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangelogScreen()));
        if (value == 3) {
          final prefs = await SharedPreferences.getInstance();
          final lang = prefs.getString('language_code');
          final dark = prefs.getBool('is_dark');
          await prefs.clear();
          if (lang != null) await prefs.setString('language_code', lang);
          if (dark != null) await prefs.setBool('is_dark', dark);
          SessionDataManager().cache.clear();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('cache_cleared'))));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Row(children: [const Icon(Icons.brightness_6), const SizedBox(width: 12), Text(loc.translate('toggleTheme'))])),
        PopupMenuItem(value: 1, child: Row(children: [
          const Icon(Icons.language), const SizedBox(width: 12),
          Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: loc.locale.languageCode, isDense: true, isExpanded: true,
            onChanged: (String? val) { if (val != null) { widget.onSetLocale(Locale(val)); Navigator.pop(context); } },
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'nl', child: Text('Nederlands')),
              DropdownMenuItem(value: 'fr', child: Text('Français')), DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            ],
          )))
        ])),
        PopupMenuItem(value: 2, child: Row(children: [const Icon(Icons.history), const SizedBox(width: 12), Text(loc.translate('changelog'))])), 
        PopupMenuItem(value: 3, child: Row(children: [const Icon(Icons.delete_outline, color: Colors.redAccent), const SizedBox(width: 12), Text(loc.translate('clear_cache'), style: const TextStyle(color: Colors.redAccent))])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, 
        onTap: (i) {
          if (_idx == i) {
            if (i == 0) _racesNavKey.currentState?.popUntil((route) => route.isFirst);
            if (i == 1) _driversNavKey.currentState?.popUntil((route) => route.isFirst);
            if (i == 2) _teamsNavKey.currentState?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _idx = i);
          }
        }, 
        selectedItemColor: const Color(0xFF2196F3), 
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111118) : Colors.white,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.speed), label: loc.translate('circuits').toUpperCase()),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: loc.translate('drivers').toUpperCase()),
          BottomNavigationBarItem(icon: const Icon(Icons.group), label: loc.translate('teams').toUpperCase()),
        ],
      ),
      body: IndexedStack(
        index: _idx, 
        children: [
          Navigator(
            key: _racesNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (context) => CircuitsView(settingsMenu: _buildSettingsMenu(context)));
            },
          ),
          Navigator(
            key: _driversNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (context) => StandingsView(isDriverView: true, settingsMenu: _buildSettingsMenu(context)));
            },
          ),
          Navigator(
            key: _teamsNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (context) => StandingsView(isDriverView: false, settingsMenu: _buildSettingsMenu(context)));
            },
          ),
        ]
      ),
    );
  }
}

/// --- CIRCUITS VIEW (TAB 0 ROOT) ---
class CircuitsView extends StatefulWidget {
  final Widget settingsMenu;
  const CircuitsView({required this.settingsMenu, super.key});
  @override State<CircuitsView> createState() => _CircuitsViewState();
}

class _CircuitsViewState extends State<CircuitsView> {
  String liveTemp = "--";
  int liveRain = 0;
  Timer? _timer;

  @override void initState() { 
    super.initState(); 
    _fetchLiveWeather();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) { if (mounted) _fetchLiveWeather(); });
  }

  @override void dispose() {
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

  Future<void> _fetchLiveWeather() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700)); 
      final nextTrack = _nextRace();
      final res = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=${nextTrack.lat}&longitude=${nextTrack.lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=precipitation_probability_max&timezone=auto'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { 
          liveTemp = d['current']['temperature_2m'].toString(); 
          liveRain = d['daily']['precipitation_probability_max'][0]; 
        });
      }
    } catch (_) {}
  }

  String _timeUntil(DateTime date, BuildContext context) {
    final loc = AppLocalizations.of(context);
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return '';
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      final remainingDays = diff.inDays % 7;
      String w = '$weeks ${weeks == 1 ? loc.translate('week') : loc.translate('weeks')}';
      if (remainingDays > 0) w += ', $remainingDays ${remainingDays == 1 ? loc.translate('day') : loc.translate('days')}';
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
    final results = SessionDataManager().cache['${race.country}_Race_${race.date.year}'];
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: widget.settingsMenu,
        title: Text(loc.translate('appTitle').toUpperCase()),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CircuitDetailScreen(race: upcoming, settingsMenu: widget.settingsMenu))),
          child: Card(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), 
                gradient: LinearGradient(begin: Alignment.topLeft, colors: isDark ? [const Color(0xFF1A1A22), const Color(0xFF2196F3).withOpacity(0.05)] : [Colors.white, const Color(0xFF2196F3).withOpacity(0.1)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("${loc.translate('nextRace').toUpperCase()}", style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                  Row(
                    children: [
                      Text('$liveTemp°C ', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      Icon(liveRain > 30 ? Icons.umbrella : Icons.wb_sunny, color: liveRain > 30 ? Colors.blue : Colors.amber, size: 20),
                    ],
                  ),
                ]),
                const SizedBox(height: 12),
                Text("${loc.translate('gp_${upcoming.name}')} ${_getFlag(loc.translate('country_${upcoming.country}'))}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                Text(upcoming.name, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
                Divider(height: 30, color: isDark ? Colors.white10 : Colors.black12),
                Text(timeStrNext.isEmpty ? _getPodiumString(upcoming) : '${loc.translate('startsIn')} $timeStrNext', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green)),
              ]),
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CircuitDetailScreen(race: r, settingsMenu: widget.settingsMenu))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(r.flag, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.translate('gp_${r.name}'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                          const SizedBox(height: 6),
                          Text("${r.date.day}-${r.date.month}-${r.date.year}", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(isFinished ? _getPodiumString(r) : '$tStr', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isFinished ? (isDark ? Colors.white70 : Colors.black54) : const Color(0xFF2196F3))),
                  ],
                ),
              ),
            ),
          );
        })
      ]),
    );
  }
}

/// --- STANDINGS VIEW (TAB 1 ROOT) ----------------------------------------------

class StandingsView extends StatefulWidget {
  final Widget settingsMenu;
  final bool isDriverView;
  const StandingsView({required this.settingsMenu, required this.isDriverView, super.key});
  @override State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  bool _isLoading = false;
  List<Driver> _cachedDrivers = [];
  List<Team> _cachedTeams = [];
  bool _usingFallback = false;
  int _selectedYear = DateTime.now().year;
  final List<int> _years = List.generate(10, (index) => DateTime.now().year - index);

  final List<dynamic> _selectedForComparison = [];
  bool _isCompareMode = false;

  @override void initState() { super.initState(); _fetchStandings(); }

  Future<void> _fetchStandings() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeyDrivers = 'api_drivers_cache_$_selectedYear';
    final cacheKeyTeams = 'api_teams_cache_$_selectedYear';
    final cacheTimeKey = 'api_cache_time_$_selectedYear';
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastFetch = prefs.getInt(cacheTimeKey) ?? 0;

    if (now - lastFetch < 24 * 60 * 60 * 1000) {
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
      final driverRes = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/$_selectedYear/driverStandings.json')).timeout(const Duration(seconds: 4));
      
      await Future.delayed(const Duration(milliseconds: 700)); 
      final teamRes = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/$_selectedYear/constructorStandings.json')).timeout(const Duration(seconds: 4));

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

  void _processStandingsData(List apiDrivers, List apiTeams) {
    List<Driver> mergedDrivers = [];
    final localDrivers = driversData[_selectedYear] ?? [];
    for (var localD in localDrivers) {
      final apiMatch = apiDrivers.firstWhere((apiD) => localD.name.toLowerCase().contains((apiD['Driver']['familyName'] ?? '').toLowerCase()), orElse: () => null);
      int pts = apiMatch != null ? (double.tryParse(apiMatch['points'].toString())?.toInt() ?? 0) : 0;
      mergedDrivers.add(Driver.copy(localD, pts));
    }

    List<Team> mergedTeams = [];
    for (var localT in fallbackTeams) {
      final apiMatch = apiTeams.firstWhere((apiT) => localT.name.toLowerCase().contains((apiT['Constructor']['name'] ?? '').toLowerCase().split(' ').first), orElse: () => null);
      int pts = apiMatch != null ? (double.tryParse(apiMatch['points'].toString())?.toInt() ?? 0) : 0;
      mergedTeams.add(Team.copy(localT, pts));
    }
    
    mergedDrivers.sort((a, b) => b.points.compareTo(a.points));
    mergedTeams.sort((a, b) => b.points.compareTo(a.points));
    
    if (mounted) setState(() { _cachedDrivers = mergedDrivers; _cachedTeams = mergedTeams; _usingFallback = false; _isLoading = false; });
  }

  Widget _buildList(bool isDriver) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDriverView = widget.isDriverView;
    final int count = isDriver ? (_cachedDrivers.isEmpty ? (driversData[_selectedYear]?.length ?? 0) : _cachedDrivers.length) : (_cachedTeams.isEmpty ? fallbackTeams.length : _cachedTeams.length);
    
    return ListView.builder(itemCount: count, padding: const EdgeInsets.symmetric(vertical: 10), itemBuilder: (c, i) {
      final item = isDriver ? (_cachedDrivers.isEmpty ? driversData[_selectedYear]![i] : _cachedDrivers[i]) : (_cachedTeams.isEmpty ? fallbackTeams[i] : _cachedTeams[i]);
      final String name = isDriver ? (item as Driver).name : (item as Team).name;
      final int points = isDriver ? (item as Driver).points : (item as Team).points;
      final String flag = isDriver ? (item as Driver).flag : (item as Team).flag;
      final String teamName = isDriver ? (item as Driver).team : (item as Team).name;

      final bool isSelected = _isCompareMode && _selectedForComparison.contains(item);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), 
        decoration: BoxDecoration(
          color: isSelected ? _getTeamColor(teamName).withOpacity(0.3) : (isDark ? const Color(0xFF16161E) : Colors.white),
          borderRadius: BorderRadius.circular(12), 
          border: Border(left: BorderSide(color: _getTeamColor(teamName), width: 6)), 
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
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
                  comparisonPage = DriverComparisonView(driver1: _selectedForComparison[0] as Driver, driver2: _selectedForComparison[1] as Driver);
                } else {
                  comparisonPage = TeamComparisonView(team1: _selectedForComparison[0] as Team, team2: _selectedForComparison[1] as Team);
                }

                Navigator.push(context, MaterialPageRoute(builder: (context) => comparisonPage)).then((_) {
                  setState(() {
                    _isCompareMode = false;
                    _selectedForComparison.clear();
                  });
                });
              }
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (c) => isDriver ? DriverDetailView(driver: item as Driver, settingsMenu: widget.settingsMenu) : TeamDetailView(team: item as Team, settingsMenu: widget.settingsMenu)));
            }
          },
          leading: Text("${i + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black26, fontSize: 16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Text(flag), const SizedBox(width: 10), Expanded(child: Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1, color: isDark ? Colors.white : Colors.black)))]),
              if (isDriver && (item as Driver).championshipYears.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text((item).championshipYears.join(', '), style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          trailing: Text("$points ${loc.translate('pts')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2196F3))),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDriverView = widget.isDriverView;
    
    return Scaffold(
      appBar: AppBar(
        title: _isCompareMode
            ? Text('${isDriverView ? loc.translate('select_drivers_to_compare') : loc.translate('select_teams_to_compare')} (${_selectedForComparison.length}/2)')
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
                    child: Text(year.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                  );
                }).toList(),
              ),
        actions: [
          IconButton(icon: Icon(_isCompareMode ? Icons.cancel : Icons.compare_arrows), tooltip: loc.translate('compare'), onPressed: () => setState(() { _isCompareMode = !_isCompareMode; _selectedForComparison.clear(); })),
          widget.settingsMenu
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            if (_usingFallback) Container(width: double.infinity, color: Colors.orangeAccent.withOpacity(0.9), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Text(loc.translate('using_fallback_data'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Expanded(child: _buildList(widget.isDriverView)),
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

    if (value1 is num) { numVal1 = value1; } 
    else if (value1 is String) { numVal1 = double.tryParse(value1.split(' ').first.replaceAll(RegExp(r'[^0-9.]'), '')); }

    if (value2 is num) { numVal2 = value2; } 
    else if (value2 is String) { numVal2 = double.tryParse(value2.split(' ').first.replaceAll(RegExp(r'[^0-9.]'), '')); }

    if (numVal1 != null && numVal2 != null) {
      if (lowerIsBetter) { d1IsBetter = numVal1 < numVal2; d2IsBetter = numVal2 < numVal1; } 
      else { d1IsBetter = numVal1 > numVal2; d2IsBetter = numVal2 > numVal1; }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
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
      decoration: isBetter ? BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ) : null,
      child: Text(
        text, 
        style: TextStyle(
          fontSize: isBetter ? 20 : 16, 
          fontWeight: isBetter ? FontWeight.bold : FontWeight.normal, 
          color: isBetter ? Colors.green : (isDark ? Colors.white70 : Colors.black87)
        )
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
        title: Text('${driver1.name.split(' ').last} vs ${driver2.name.split(' ').last}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          ComparisonRow(label: loc.translate('championships'), value1: driver1.championships, value2: driver2.championships, isDark: isDark),
          ComparisonRow(label: loc.translate('wins'), value1: driver1.wins, value2: driver2.wins, isDark: isDark),
          ComparisonRow(label: loc.translate('podiums'), value1: driver1.podiums, value2: driver2.podiums, isDark: isDark),
          ComparisonRow(label: loc.translate('poles'), value1: driver1.poles, value2: driver2.poles, isDark: isDark),
          ComparisonRow(label: loc.translate('fastest_laps'), value1: driver1.fastestLaps, value2: driver2.fastestLaps, isDark: isDark),
          ComparisonRow(label: loc.translate('total_points'), value1: driver1.totalPoints, value2: driver2.totalPoints, isDark: isDark),
          ComparisonRow(label: loc.translate('starts'), value1: driver1.starts, value2: driver2.starts, isDark: isDark),
          ComparisonRow(label: loc.translate('dnf'), value1: driver1.dnfs, value2: driver2.dnfs, isDark: isDark, lowerIsBetter: true),
          ComparisonRow(label: loc.translate('laps_led'), value1: driver1.lapsLed, value2: driver2.lapsLed, isDark: isDark),
          ComparisonRow(label: loc.translate('highestFinish'), value1: driver1.highestFinish, value2: driver2.highestFinish, isDark: isDark, lowerIsBetter: true),
          ComparisonRow(label: loc.translate('highestGrid'), value1: driver1.highestGrid, value2: driver2.highestGrid, isDark: isDark, lowerIsBetter: true),
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
          child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
        Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        Text('#${driver.number}', style: TextStyle(color: _getTeamColor(driver.team), fontSize: 20, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        title: Text('${team1.name} vs ${team2.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          ComparisonRow(label: loc.translate('cc_wins'), value1: team1.ccWins, value2: team2.ccWins, isDark: isDark),
          ComparisonRow(label: loc.translate('dc_wins'), value1: team1.dcWins, value2: team2.dcWins, isDark: isDark),
          ComparisonRow(label: loc.translate('wins'), value1: team1.podiums, value2: team2.podiums, isDark: isDark),
          ComparisonRow(label: loc.translate('one_two'), value1: team1.oneTwo, value2: team2.oneTwo, isDark: isDark),
          ComparisonRow(label: loc.translate('poles'), value1: team1.poles, value2: team2.poles, isDark: isDark),
          ComparisonRow(label: loc.translate('fastest_laps'), value1: team1.fastestLaps, value2: team2.fastestLaps, isDark: isDark),
          ComparisonRow(label: loc.translate('total_points'), value1: team1.totalPoints, value2: team2.totalPoints, isDark: isDark),
          ComparisonRow(label: loc.translate('total_entries'), value1: team1.totalEntries, value2: team2.totalEntries, isDark: isDark),
          ComparisonRow(label: loc.translate('fastestPit'), value1: team1.fastestPitstopTime, value2: team2.fastestPitstopTime, isDark: isDark, lowerIsBetter: true),
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
          child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
        Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        Text(team.principalName, style: TextStyle(color: _getTeamColor(team.name), fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }
}

/// --- DETAIL VIEWS ----------------------------------------------

class CircuitDetailScreen extends StatefulWidget {
  final Race race;
  final Widget settingsMenu;
  const CircuitDetailScreen({super.key, required this.race, required this.settingsMenu});
  @override State<CircuitDetailScreen> createState() => _CircuitDetailScreenState();
}

class _CircuitDetailScreenState extends State<CircuitDetailScreen> {
  String t = "--"; 
  int r = 0; 
  String w = "--"; 
  String h = "--";

  @override void initState() { super.initState(); _fetchWeather(); }
  
  Future<void> _fetchWeather() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700)); 
      final res = await http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=${widget.race.lat}&longitude=${widget.race.lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=precipitation_probability_max&timezone=auto'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if(mounted) {
          setState(() { 
            t = d['current']['temperature_2m'].toString(); 
            w = d['current']['wind_speed_10m'].toString();
            h = d['current']['relative_humidity_2m'].toString();
            r = d['daily']['precipitation_probability_max'][0]; 
          });
        }
      }
    } catch (_) {}
  }

  Widget _infoLine(String label, String value, [Color? valueColor]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: valueColor ?? (isDark ? Colors.white : Colors.black))),
        ],
      ),
    );
  }

  Widget _buildTopBlock({required String title, required IconData icon, required List<Widget> children, Widget? action}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF2196F3)),
            const SizedBox(width: 8),
            Expanded(child: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: isDark ? Colors.white : Colors.black), overflow: TextOverflow.ellipsis)),
            if (action != null) Padding(padding: const EdgeInsets.only(left: 8.0), child: action),
          ]),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 20),
          ...children,
        ],
      ),
    );
  }

  Color _getDifficultyColor(String level) {
    switch (level) {
      case 'level_1': return Colors.green;
      case 'level_2': return Colors.lightGreen;
      case 'level_3': return Colors.orange;
      case 'level_4': return Colors.deepOrange;
      case 'level_5': return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String translatedStrategy = widget.race.bestCombination.replaceAll('Soft', loc.translate('soft_tire')).replaceAll('Medium', loc.translate('medium_tire')).replaceAll('Hard', loc.translate('hard_tire'));
    final isDutch = loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de';
    final List<String> characteristics = isDutch ? widget.race.characteristicsNl : widget.race.characteristicsEn;

    return Scaffold(
      appBar: AppBar(
        actions: [widget.settingsMenu],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.race.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(loc.translate('gp_${widget.race.name}').toUpperCase(), style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTopBlock(
                title: loc.translate('weather_forecast'),
                icon: Icons.cloud,
                children: [
                  _infoLine(loc.translate('temp'), "$t°C", Colors.orangeAccent),
                  _infoLine(loc.translate('rain_chance'), "$r%", Colors.lightBlueAccent),
                  _infoLine(loc.translate('wind_speed'), "$w km/h", Colors.white70),
                  _infoLine(loc.translate('humidity'), "$h%", Colors.white70),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTopBlock(
                title: loc.translate('circuit_info'),
                icon: Icons.info_outline,
                action: IconButton(
                  icon: Icon(Icons.map, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Open in Maps',
                  onPressed: () {
                    final userAgent = js.context['navigator']['userAgent'].toString().toLowerCase();
                    final isApple = userAgent.contains('iphone') || userAgent.contains('ipad') || userAgent.contains('ipod') || userAgent.contains('macintosh') || userAgent.contains('mac os');
                    final url = isApple
                        ? 'https://maps.apple.com/?ll=${widget.race.lat},${widget.race.lon}&q=${Uri.encodeComponent(widget.race.name)}'
                        : 'https://www.google.com/maps/search/?api=1&query=${widget.race.lat},${widget.race.lon}';
                    js.context.callMethod('open', [url]);
                  },
                ),
                children: [
                  _infoLine(loc.translate('length'), "${widget.race.length} m"),
                  _infoLine(loc.translate('distanceToTurn1'), widget.race.distanceToTurn1),
                  _infoLine(loc.translate('laps'), widget.race.laps.toString()),
                  _infoLine(loc.translate('since'), widget.race.firstGrandPrix.toString()),
                  _infoLine(loc.translate('until'), widget.race.contractUntil),
                  _infoLine(loc.translate('circuitDifficulty'), loc.translate(widget.race.circuitDifficulty), _getDifficultyColor(widget.race.circuitDifficulty)),
                  _infoLine(loc.translate('overtakingDifficulty'), loc.translate(widget.race.overtakingDifficulty), _getDifficultyColor(widget.race.overtakingDifficulty)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Text(loc.translate('circuit_layout').toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 10),
              SvgPicture.network(widget.race.circuitImage, height: 200, colorFilter: ColorFilter.mode(isDark ? Colors.white : Colors.black, BlendMode.srcIn)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Card(color: Theme.of(context).colorScheme.primaryContainer, child: ListTile(leading: const Icon(Icons.format_list_numbered), title: Text(loc.translate('session_results'), style: const TextStyle(fontWeight: FontWeight.bold)), trailing: const Icon(Icons.arrow_forward), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SessionResultsScreen(race: widget.race))))),
        const SizedBox(height: 10), 

        ExpansionTile(
          initiallyExpanded: true,
          title: Text("⚡ ${loc.translate('lap_speed_stats')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
          children: [
            _statTile(loc.translate('fastestLap'), Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.race.fastestLap.time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                Text("${widget.race.fastestLap.driver} (${widget.race.fastestLap.year})", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ), Icons.timer),
            _statTile(loc.translate('slowestLap'), Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.race.slowestLap.time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                Text("${widget.race.slowestLap.driver} (${widget.race.slowestLap.year})", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ), Icons.timer_off),
            _statTile(loc.translate('avgLap'), widget.race.averageLap, Icons.av_timer),
            _statTile(loc.translate('topSpeed'), widget.race.topSpeed, Icons.speed),
            _statTile(loc.translate('averageSpeed'), widget.race.averageSpeed, Icons.directions_car),
            _statTile(loc.translate('max_g_force'), widget.race.maxGForce, Icons.compress),
            _statTile(loc.translate('avgForce'), widget.race.avgGForce, Icons.compress),
          ],
        ),

        ExpansionTile(
          title: Text("${loc.translate('risks_incidents')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
          children: [
            _statTile(loc.translate('redFlag'), "${widget.race.redFlagChance}%", Icons.flag),
            _statTile(loc.translate('vsc'), "${widget.race.vscChance}%", Icons.warning_amber),
            _statTile(loc.translate('accident'), "${widget.race.accidentChance}%", Icons.car_crash),
            _statTile(loc.translate('turn1Accident'), "${widget.race.turn1AccidentChance}%", Icons.turn_right),
          ],
        ),

        ExpansionTile(
          title: Text("🛞 ${loc.translate('tyres_strategy')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
          children: [
            _statTile(loc.translate('tireWear'), loc.translate('wear_${widget.race.tireWear}'), Icons.layers),
            _statTile(loc.translate('strategy'), loc.translate('strategy_${widget.race.tireStrategy}'), Icons.settings_suggest),
            _statTile(loc.translate('bestCombination'), translatedStrategy, Icons.donut_large),
            _statTile(loc.translate('fastestPit'), Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.race.fastestPitstop.time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                Text("${widget.race.fastestPitstop.team} (${widget.race.fastestPitstop.year})", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ), Icons.build),
          ],
        ),

        ExpansionTile(
          title: Text("📍 ${loc.translate('characteristics')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: characteristics.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("💡 ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3))), Expanded(child: Text(c, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)))]))).toList(),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class DriverDetailView extends StatefulWidget {
  final Driver driver;
  final Widget settingsMenu;
  const DriverDetailView({required this.driver, required this.settingsMenu, super.key});

  @override
  State<DriverDetailView> createState() => _DriverDetailViewState();
}

class _DriverDetailViewState extends State<DriverDetailView> {
  int? _selectedYearIndex;
  late ScrollController _scrollController;
  bool _showFullTitle = false;

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
      case 'Max Verstappen': return [1, 1, 1, 1, 2]; // 2021-2025
      case 'Lando Norris': return [6, 7, 6, 2, 1];
      case 'Oscar Piastri': return [21, 21, 9, 4, 3]; // 21 = N/A
      case 'George Russell': return [15, 4, 8, 6, 4];
      case 'Charles Leclerc': return [7, 2, 5, 3, 5];
      case 'Lewis Hamilton': return [2, 6, 3, 7, 6];
      case 'Kimi Antonelli': return [21, 21, 21, 21, 7];
      case 'Alexander Albon': return [21, 19, 13, 16, 8];
      case 'Carlos Sainz': return [5, 5, 7, 5, 9];
      case 'Fernando Alonso': return [10, 9, 4, 9, 10];
      case 'Nico Hülkenberg': return [21, 22, 16, 11, 11];
      case 'Isack Hadjar': return [21, 21, 21, 21, 12];
      case 'Oliver Bearman': return [21, 21, 21, 18, 13];
      case 'Esteban Ocon': return [11, 8, 12, 14, 14];
      case 'Liam Lawson': return [21, 21, 20, 21, 15];
      case 'Lance Stroll': return [13, 15, 10, 13, 16];
      case 'Yuki Tsunoda': return [14, 17, 14, 12, 17];
      case 'Pierre Gasly': return [9, 14, 11, 10, 18];
      case 'Gabriel Bortoleto': return [21, 21, 21, 21, 19];
      case 'Franco Colapinto': return [21, 21, 21, 19, 20];
      case 'Sergio Pérez': return [4, 3, 2, 8, 21];
      case 'Valtteri Bottas': return [3, 10, 15, 22, 21];
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
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(15), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(pos.length, (i) {
              double h = 100.0 - (pos[i] * 4.0);
              if(h < 10) h = 10;
              final isSelected = _selectedYearIndex == i;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedYearIndex = i),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text("P${pos[i]}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.white : Colors.black))),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 28 : 24, 
                    height: h, 
                    decoration: BoxDecoration(
                      color: color, 
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(years[i], style: TextStyle(fontSize: 10, color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ]),
              );
            }),
          ),
        ),
        if (_selectedYearIndex != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("20${years[_selectedYearIndex!]} Finish: P${pos[_selectedYearIndex!]}", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDutch = loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de';
    final List<String> facts = isDutch ? widget.driver.realWorldFactsNl : widget.driver.realWorldFactsEn;
    final List<int> driverHistory = _getDriverHistory(widget.driver.name);

    String title = widget.driver.name.toUpperCase();
    if (_showFullTitle) {
      title = "${widget.driver.flag} $title - #${widget.driver.number}";
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [widget.settingsMenu]),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20), 
        children: [
          Center(child: Text(widget.driver.flag, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 10),
          Text("#${widget.driver.number}", textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getTeamColor(widget.driver.team))),
          const SizedBox(height: 20),
          
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('driver_history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildHistoryChart(driverHistory, _getTeamColor(widget.driver.team)),
              ),
            ],
          ),

          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('driver_facts_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: facts.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("📌 ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3))), Expanded(child: Text(f, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)))]))).toList()
                ),
              ),
            ],
          ),

          ExpansionTile(
            title: Text(loc.translate('personal_info'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('age'), widget.driver.age, Icons.cake),
              _statTile(loc.translate('height'), widget.driver.height, Icons.height),
              _statTile(loc.translate('birth_place'), widget.driver.birthPlace, Icons.location_on),
              _statTile(loc.translate('partner'), widget.driver.partner, Icons.favorite),
              _statTile(loc.translate('children'), widget.driver.children, Icons.child_care),
              _statTile(loc.translate('pets'), widget.driver.pets, Icons.pets),
              _statTile(loc.translate('manager'), widget.driver.manager, Icons.work),
              const SizedBox(height: 8),
            ],
          ),

          ExpansionTile(
            title: Text(loc.translate('general'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('current_team'), widget.driver.team, Icons.groups),
              
              if (widget.driver.previousTeams.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                          Text(loc.translate('previous_teams'),
                              style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 13)),
                          ]),
                        ],
                      ),
                      children: widget.driver.previousTeams.map((t) {
                        String team = t;
                        String years = "";
                        if (t.contains(' (')) {
                          final parts = t.split(' (');
                          team = parts[0];
                          years = "(${parts[1]}";
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(40, 2, 12, 6), 
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("• ", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: team, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                                      if (years.isNotEmpty)
                                        TextSpan(text: " $years", style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 13)),
                                    ]
                                  )
                                ),
                              ),
                            ],
                          )
                        );
                      }).toList(),
                    ),
                  ),
                ),

              _statTile(loc.translate('nationality'), loc.translate('nat_${widget.driver.nationality}'), Icons.public),
              _statTile(loc.translate('f1_debut'), widget.driver.debutYear, Icons.start),
              _statTile(loc.translate('contract_until'), widget.driver.contractUntil, Icons.edit_document),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text(loc.translate('career_stats'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('championships'), widget.driver.championships, Icons.workspace_premium),
              _statTile(loc.translate('wins'), widget.driver.wins, Icons.emoji_events),
              _statTile(loc.translate('podiums'), widget.driver.podiums, Icons.leaderboard),
              _statTile(loc.translate('poles'), widget.driver.poles, Icons.flag),
              _statTile(loc.translate('fastest_laps'), widget.driver.fastestLaps, Icons.timer),
              _statTile(loc.translate('highestFinish'), widget.driver.highestFinish, Icons.military_tech),
              _statTile(loc.translate('highestGrid'), widget.driver.highestGrid, Icons.grid_3x3),
              _statTile(loc.translate('hatTricks'), widget.driver.hatTricks, Icons.auto_awesome),
              _statTile(loc.translate('frontRowStarts'), widget.driver.frontRowStarts, Icons.looks_two),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Row(children: [
                            Text(loc.translate('total_points'),
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.white70 : Colors.black87,
                                    fontSize: 13)),
                          ]),
                        Text(widget.driver.totalPoints.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                      ],
                    ),
                    children: widget.driver.pointsPerSeason.entries.map((e) => Padding(padding: const EdgeInsets.fromLTRB(40, 4, 12, 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key.toString(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)), Text(e.value.toString(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12))]))).toList(),
                  ),
                ),
              ),
              _statTile(loc.translate('overtakes'), widget.driver.overtakes, Icons.compare_arrows),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text(loc.translate('experience'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('starts'), widget.driver.starts, Icons.traffic),
              _statTile(loc.translate('laps_led'), widget.driver.lapsLed, Icons.looks_one),
              _statTile(loc.translate('dnf'), widget.driver.dnfs, Icons.car_crash),
              _statTile(loc.translate('dsqs'), widget.driver.dsqs, Icons.block),
              _statTile(loc.translate('dnqs'), widget.driver.dnqs, Icons.cancel_schedule_send),
              if (widget.driver.dnfs > 0)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: Text("DNF History", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                      children: [
                        ..._getDnfData(widget.driver.name),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text("Showing notable retirements", style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                        )
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),

          ExpansionTile(
            title: Text("${loc.translate('personal_sponsors')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              ...widget.driver.personalSponsors.map((s) => _statTile(s, '', Icons.business_center)),
              const SizedBox(height: 8),
            ],
          ),
        ]
      ),
    );
  }

  List<Widget> _getDnfData(String name) {
    final Map<String, List<List<String>>> dnfMap = {
      'Max Verstappen': [['2024', 'Australian GP', 'Brakes', '3'], ['2022', 'Australian GP', 'Fuel Leak', '38'], ['2022', 'Bahrain GP', 'Fuel Pressure', '54'], ['2021', 'Azerbaijan GP', 'Tyre Failure', '45'], ['2021', 'British GP', 'Collision (w/ Hamilton)', '0'], ['2021', 'Italian GP', 'Collision (w/ Hamilton)', '25'], ['2020', 'Italian GP', 'Power Unit', '30'], ['2020', 'Tuscan GP', 'Collision (w/ Gasly)', '0'], ['2020', 'Austrian GP', 'Electronics', '11'], ['2020', 'Styrian GP', 'Brakes', '11'], ['2019', 'Belgian GP', 'Collision (w/ Raikkonen)', '0'], ['2018', 'Hungarian GP', 'Power Unit', '5'], ['2018', 'British GP', 'Brakes', '46'], ['2018', 'Azerbaijan GP', 'Collision (w/ Ricciardo)', '39'], ['2017', 'Singapore GP', 'Collision (w/ Vettel/Raikkonen)', '0'], ['2017', 'Austrian GP', 'Collision (w/ Kvyat/Alonso)', '0'], ['2017', 'Azerbaijan GP', 'Engine', '12'], ['2017', 'Canadian GP', 'Battery', '10'], ['2017', 'Spanish GP', 'Collision (w/ Raikkonen/Bottas)', '0'], ['2017', 'Bahrain GP', 'Brakes', '11'], ['2016', 'Monaco GP', 'Accident', '34'], ['2016', 'Russian GP', 'Engine', '33'], ['2015', 'British GP', 'Spin', '3'], ['2015', 'Austrian GP', 'Engine', '15'], ['2015', 'Monaco GP', 'Collision (w/ Grosjean)', '62'], ['2015', 'Bahrain GP', 'Electrical', '52'], ['2015', 'Australian GP', 'Engine', '32']],
      'Lando Norris': [['2024', 'Austrian GP', 'Collision (w/ Verstappen)', '64'], ['2023', 'Las Vegas GP', 'Accident', '2'], ['2022', 'Miami GP', 'Collision', '39'], ['2022', 'Brazilian GP', 'Gearbox', '50'], ['2021', 'Hungarian GP', 'Collision', '0'], ['2020', 'Eifel GP', 'Power Unit', '42'], ['2019', 'German GP', 'Power Loss', '25'], ['2019', 'Canadian GP', 'Suspension', '8'], ['2019', 'Chinese GP', 'Collision Damage', '50'], ['2019', 'Spanish GP', 'Collision', '44'], ['2019', 'Belgian GP', 'Power Unit', '43'], ['2019', 'Mexican GP', 'Wheel', '48']],
      'Oscar Piastri': [['2023', 'Belgian GP', 'Collision (w/ Sainz)', '1'], ['2023', 'United States GP', 'Radiator', '10'], ['2023', 'Bahrain GP', 'Electrical', '13']],
      'George Russell': [['2024', 'Australian GP', 'Accident', '57'], ['2024', 'British GP', 'Water Leak', '33'], ['2023', 'Singapore GP', 'Accident', '62'], ['2023', 'Canadian GP', 'Accident', '53'], ['2023', 'Australian GP', 'Engine', '17'], ['2022', 'British GP', 'Collision', '0'], ['2022', 'Singapore GP', 'Collision', '57'], ['2021', 'Emilia Romagna GP', 'Collision', '31'], ['2021', 'Belgian GP', 'Rain (DNS)', '0'], ['2020', 'Emilia Romagna GP', 'Accident', '51'], ['2020', 'Austrian GP', 'Fuel Pressure', '49'], ['2020', 'Styrian GP', 'Collision', '0'], ['2019', 'Singapore GP', 'Collision', '34'], ['2019', 'Russian GP', 'Brakes', '27']],
      'Charles Leclerc': [['2023', 'Brazilian GP', 'Hydraulics', '0'], ['2023', 'Australian GP', 'Collision (w/ Stroll)', '0'], ['2023', 'Dutch GP', 'Floor Damage', '41'], ['2022', 'French GP', 'Accident', '18'], ['2022', 'Spanish GP', 'Turbo', '27'], ['2022', 'Azerbaijan GP', 'Engine', '21'], ['2021', 'Hungarian GP', 'Collision', '0'], ['2021', 'Monaco GP', 'Driveshaft (DNS)', '0'], ['2020', 'Styrian GP', 'Collision', '4'], ['2020', 'Italian GP', 'Accident', '24'], ['2020', 'Sakhir GP', 'Collision', '0'], ['2019', 'German GP', 'Accident', '27'], ['2019', 'Monaco GP', 'Collision Damage', '16'], ['2018', 'British GP', 'Wheel', '18'], ['2018', 'Hungarian GP', 'Suspension', '0'], ['2018', 'Belgian GP', 'Collision', '0'], ['2018', 'Japanese GP', 'Spin', '38'], ['2018', 'Abu Dhabi GP', 'Engine', '0']],
      'Lewis Hamilton': [['2024', 'United States GP', 'Accident', '2'], ['2024', 'Australian GP', 'Engine', '15'], ['2023', 'Qatar GP', 'Collision (w/ Russell)', '0'], ['2022', 'Belgian GP', 'Collision (w/ Alonso)', '0'], ['2021', 'Italian GP', 'Collision (w/ Verstappen)', '25'], ['2018', 'Austrian GP', 'Fuel Pressure', '62'], ['2016', 'Spanish GP', 'Collision (w/ Rosberg)', '0'], ['2016', 'Malaysian GP', 'Engine', '40'], ['2014', 'Belgian GP', 'Collision Damage (w/ Rosberg)', '38'], ['2014', 'Australian GP', 'Engine', '2'], ['2013', 'Japanese GP', 'Collision Damage (w/ Vettel)', '7'], ['2012', 'Brazilian GP', 'Collision (w/ Hulkenberg)', '54'], ['2012', 'Abu Dhabi GP', 'Fuel Pressure', '19'], ['2012', 'Singapore GP', 'Gearbox', '22'], ['2012', 'Belgian GP', 'Collision (w/ Grosjean)', '0'], ['2012', 'German GP', 'Puncture', '56'], ['2011', 'Belgian GP', 'Collision (w/ Kobayashi)', '12'], ['2011', 'Canadian GP', 'Collision (w/ Button)', '7'], ['2010', 'Italian GP', 'Collision (w/ Massa)', '0'], ['2010', 'Hungarian GP', 'Gearbox', '23'], ['2009', 'Abu Dhabi GP', 'Brakes', '20'], ['2009', 'Belgian GP', 'Collision (w/ Grosjean)', '0'], ['2008', 'Canadian GP', 'Collision (w/ Raikkonen)', '19'], ['2007', 'Chinese GP', 'Stuck in gravel', '30']],
      'Carlos Sainz': [['2024', 'Canadian GP', 'Accident (w/ Albon)', '52'], ['2023', 'Belgian GP', 'Collision (w/ Piastri)', '23'], ['2022', 'Austrian GP', 'Engine Fire', '56'], ['2022', 'Azerbaijan GP', 'Hydraulics', '8'], ['2022', 'Emilia Romagna GP', 'Collision (w/ Ricciardo)', '0'], ['2022', 'Australian GP', 'Spin', '1'], ['2020', 'Tuscan GP', 'Collision (w/ Giovinazzi)', '5'], ['2020', 'Russian GP', 'Accident', '0'], ['2020', 'Belgian GP', 'Exhaust (DNS)', '0'], ['2019', 'Brazilian GP', 'Engine', '0'], ['2019', 'Belgian GP', 'Power Loss', '1'], ['2019', 'British GP', 'Collision (w/ Grosjean)', '52'], ['2018', 'German GP', 'Collision (w/ Grosjean)', '0'], ['2017', 'Japanese GP', 'Accident', '0'], ['2017', 'Austrian GP', 'Engine', '44'], ['2017', 'Canadian GP', 'Collision (w/ Grosjean)', '0'], ['2017', 'Bahrain GP', 'Collision (w/ Stroll)', '12'], ['2016', 'Abu Dhabi GP', 'Collision (w/ Palmer)', '41'], ['2015', 'Brazilian GP', 'Engine', '0'], ['2015', 'Russian GP', 'Brakes', '45'], ['2015', 'Singapore GP', 'Gearbox', '0'], ['2015', 'Belgian GP', 'Power Unit', '0'], ['2015', 'Hungarian GP', 'Fuel Pressure', '60'], ['2015', 'Austrian GP', 'Electrical', '35']],
      'Alexander Albon': [['2024', 'Mexican GP', 'Collision (w/ Tsunoda)', '0'], ['2024', 'Brazilian GP', 'Accident', '0'], ['2024', 'Japanese GP', 'Collision (w/ Ricciardo)', '0'], ['2023', 'Australian GP', 'Accident', '6'], ['2023', 'Saudi Arabian GP', 'Brakes', '27'], ['2022', 'Saudi Arabian GP', 'Collision (w/ Stroll)', '47'], ['2022', 'British GP', 'Collision (w/ Vettel)', '0'], ['2022', 'Singapore GP', 'Accident', '25'], ['2020', 'Eifel GP', 'Radiator', '23'], ['2020', 'Austrian GP', 'Electrical', '67'], ['2019', 'Canadian GP', 'Collision Damage (w/ Giovinazzi)', '59'], ['2019', 'Hungarian GP', 'Collision (w/ Grosjean)', '0']],
      'Fernando Alonso': [['2024', 'Mexican GP', 'Brakes', '15'], ['2023', 'Mexican GP', 'Floor Damage', '47'], ['2023', 'United States GP', 'Floor Damage', '49'], ['2022', 'Abu Dhabi GP', 'Water Leak', '27'], ['2022', 'Mexican GP', 'Engine', '63'], ['2022', 'Italian GP', 'Water Pressure', '31'], ['2022', 'Saudi Arabian GP', 'Engine', '35'], ['2021', 'Bahrain GP', 'Brakes', '32'], ['2018', 'Monaco GP', 'Gearbox', '52'], ['2018', 'French GP', 'Suspension', '58'], ['2018', 'Austrian GP', 'Engine', '0'], ['2017', 'Singapore GP', 'Collision Damage (w/ Verstappen)', '8'], ['2017', 'Belgian GP', 'Engine', '25'], ['2017', 'Austrian GP', 'Collision (w/ Kvyat)', '0'], ['2017', 'Canadian GP', 'Engine', '66'], ['2016', 'Australian GP', 'Accident (w/ Gutierrez)', '16'], ['2015', 'Mexican GP', 'Engine', '1'], ['2015', 'Austrian GP', 'Collision (w/ Raikkonen)', '0'], ['2015', 'Spanish GP', 'Brakes', '26'], ['2015', 'Malaysian GP', 'Engine', '21'], ['2014', 'Italian GP', 'Engine', '28'], ['2013', 'Malaysian GP', 'Collision (w/ Vettel)', '1'], ['2012', 'Japanese GP', 'Collision (w/ Raikkonen)', '0'], ['2012', 'Belgian GP', 'Collision (w/ Grosjean)', '0'], ['2010', 'Belgian GP', 'Accident', '37'], ['2009', 'Hungarian GP', 'Wheel', '12'], ['2008', 'Canadian GP', 'Accident', '44'], ['2007', 'Japanese GP', 'Accident', '41'], ['2006', 'Hungarian GP', 'Driveshaft', '51'], ['2005', 'Canadian GP', 'Suspension', '38'], ['2004', 'Monaco GP', 'Accident (w/ R. Schumacher)', '41'], ['2003', 'Brazilian GP', 'Accident', '54'], ['2001', 'Belgian GP', 'Gearbox', '0']],
      'Sergio Pérez': [['2024', 'Hungarian GP', 'Accident', '0'], ['2024', 'Monaco GP', 'Collision (w/ Magnussen)', '0'], ['2024', 'Canadian GP', 'Accident', '51'], ['2023', 'Mexican GP', 'Collision (w/ Leclerc)', '0'], ['2023', 'Japanese GP', 'Collision Damage (w/ Hamilton)', '15'], ['2022', 'Austrian GP', 'Collision Damage (w/ Russell)', '24'], ['2022', 'Canadian GP', 'Gearbox', '7'], ['2021', 'Saudi Arabian GP', 'Collision (w/ Leclerc)', '14'], ['2021', 'Abu Dhabi GP', 'Engine', '50'], ['2020', 'Bahrain GP', 'Engine', '53'], ['2020', 'Austrian GP', 'Engine', '0'], ['2019', 'German GP', 'Accident', '1'], ['2018', 'French GP', 'Engine', '28'], ['2017', 'Azerbaijan GP', 'Collision (w/ Ocon)', '39'], ['2016', 'Austrian GP', 'Brakes', '70'], ['2015', 'Hungarian GP', 'Brakes', '53'], ['2014', 'Canadian GP', 'Collision (w/ Massa)', '69'], ['2014', 'Australian GP', 'Collision', '0'], ['2013', 'Monaco GP', 'Collision Damage (w/ Raikkonen)', '72'], ['2012', 'Monaco GP', 'Collision (w/ Maldonado)', '0'], ['2011', 'Hungarian GP', 'Collision', '0']],
      'Lance Stroll': [['2024', 'Saudi Arabian GP', 'Accident', '5'], ['2023', 'Singapore GP', 'Accident', '0'], ['2023', 'Dutch GP', 'Engine', '0'], ['2022', 'Azerbaijan GP', 'Vibration', '46'], ['2021', 'Azerbaijan GP', 'Tyre Failure', '29'], ['2021', 'Hungarian GP', 'Collision (w/ Leclerc)', '0'], ['2020', 'Tuscan GP', 'Tyre Failure', '42'], ['2020', 'Russian GP', 'Collision (w/ Leclerc)', '0'], ['2020', 'Portuguese GP', 'Collision Damage (w/ Norris)', '51'], ['2019', 'German GP', 'Accident', '45'], ['2018', 'Canadian GP', 'Collision (w/ Hartley)', '0'], ['2017', 'Chinese GP', 'Collision (w/ Perez)', '0'], ['2017', 'Bahrain GP', 'Collision (w/ Sainz)', '12'], ['2017', 'Monaco GP', 'Brakes', '71']],
      'Yuki Tsunoda': [['2024', 'Mexican GP', 'Collision (w/ Albon)', '0'], ['2024', 'Chinese GP', 'Collision (w/ Magnussen)', '26'], ['2023', 'Italian GP', 'Engine', '0'], ['2023', 'Mexican GP', 'Collision', '0'], ['2022', 'Saudi Arabian GP', 'Driveshaft', '0'], ['2022', 'Canadian GP', 'Accident', '47'], ['2022', 'French GP', 'Collision Damage', '17'], ['2021', 'Dutch GP', 'Power Unit', '48'], ['2021', 'Brazilian GP', 'Collision Damage', '0']],
      'Nico Hülkenberg': [['2024', 'Monaco GP', 'Collision (w/ Perez)', '0'], ['2023', 'Monaco GP', 'Accident', '0'], ['2023', 'Dutch GP', 'Accident', '14'], ['2019', 'German GP', 'Accident', '39'], ['2019', 'Spanish GP', 'Collision', '0'], ['2018', 'Abu Dhabi GP', 'Collision/Flip (w/ Grosjean)', '0'], ['2018', 'Belgian GP', 'Collision (w/ Alonso)', '0'], ['2018', 'Austrian GP', 'Engine', '11'], ['2018', 'Azerbaijan GP', 'Accident', '10'], ['2017', 'Singapore GP', 'Oil Leak', '48'], ['2017', 'Azerbaijan GP', 'Accident', '24'], ['2016', 'Singapore GP', 'Collision (w/ Sainz)', '0'], ['2016', 'Russian GP', 'Collision (w/ Gutierrez)', '0'], ['2015', 'United States GP', 'Collision (w/ Ricciardo)', '35'], ['2015', 'Singapore GP', 'Collision (w/ Massa)', '12'], ['2015', 'Hungarian GP', 'Front Wing', '41'], ['2014', 'Hungarian GP', 'Collision (w/ Perez)', '14'], ['2013', 'Australian GP', 'Fuel System (DNS)', '0'], ['2012', 'Australian GP', 'Collision (w/ Webber)', '0'], ['2010', 'Japanese GP', 'Collision (w/ Petrov)', '0'], ['2010', 'Hungarian GP', 'Collision', '0']],
      'Esteban Ocon': [['2024', 'Monaco GP', 'Collision (w/ Gasly)', '0'], ['2023', 'Hungarian GP', 'Collision (w/ Gasly)', '2'], ['2023', 'Singapore GP', 'Gearbox', '42'], ['2023', 'British GP', 'Hydraulics', '9'], ['2023', 'Australian GP', 'Collision (w/ Gasly)', '56'], ['2022', 'British GP', 'Fuel Pump', '37'], ['2021', 'Azerbaijan GP', 'Turbo', '3'], ['2020', 'Turkish GP', 'Collision', '0'], ['2020', 'Eifel GP', 'Hydraulics', '22'], ['2020', 'Tuscan GP', 'Brakes', '7'], ['2020', 'Styrian GP', 'Overheating', '25'], ['2018', 'Brazilian GP', 'Collision (w/ Verstappen)', '0'], ['2018', 'Mexican GP', 'Collision', '0'], ['2018', 'Azerbaijan GP', 'Collision (w/ Raikkonen)', '0'], ['2017', 'Brazilian GP', 'Collision (w/ Grosjean)', '0']],
      'Pierre Gasly': [['2024', 'British GP', 'Gearbox', '0'], ['2024', 'Monaco GP', 'Collision (w/ Ocon)', '0'], ['2023', 'Hungarian GP', 'Collision (w/ Ocon)', '2'], ['2023', 'Australian GP', 'Collision (w/ Ocon)', '56'], ['2022', 'Miami GP', 'Collision Damage (w/ Norris)', '45'], ['2022', 'Singapore GP', 'Collision', '0'], ['2021', 'Italian GP', 'Accident', '0'], ['2021', 'Bahrain GP', 'Collision Damage (w/ Ricciardo)', '52'], ['2020', 'Hungarian GP', 'Engine', '12'], ['2019', 'German GP', 'Collision (w/ Albon)', '58'], ['2018', 'Australian GP', 'Engine', '13'], ['2018', 'Spanish GP', 'Collision (w/ Grosjean)', '0'], ['2018', 'French GP', 'Collision (w/ Ocon)', '0'], ['2018', 'British GP', 'Collision (w/ Perez)', '0']],
      'Valtteri Bottas': [['2024', 'Belgian GP', 'Technical', '44'], ['2023', 'Qatar GP', 'Heat Exhaustion', '0'], ['2022', 'British GP', 'Gearbox', '20'], ['2022', 'Hungarian GP', 'Fuel System', '65'], ['2022', 'Saudi Arabian GP', 'Cooling', '36'], ['2021', 'Hungarian GP', 'Collision', '0'], ['2021', 'Emilia Romagna GP', 'Collision', '30'], ['2020', 'Eifel GP', 'Power Unit', '18'], ['2019', 'German GP', 'Accident', '56'], ['2019', 'Austrian GP', 'Engine', '0'], ['2018', 'Azerbaijan GP', 'Puncture', '48'], ['2017', 'Spanish GP', 'Engine', '38'], ['2016', 'Singapore GP', 'Overheating', '35'], ['2015', 'Australian GP', 'Back Injury (DNS)', '0'], ['2014', 'Brazilian GP', 'Engine', '0'], ['2013', 'Malaysian GP', 'Engine', '0']],
      'Liam Lawson': [['2023', 'Qatar GP', 'Accident', '0'], ['2024', 'Mexican GP', 'Collision Damage', '68']],
      'Franco Colapinto': [['2024', 'Brazilian GP', 'Accident', '32'], ['2024', 'Qatar GP', 'Collision', '0']],
      'Oliver Bearman': [['2024', 'Brazilian GP', 'Accident', '0'], ['2025', 'Australian GP', 'Mechanical', '12']],
      'Isack Hadjar': [['2025', 'Pre-Season', 'Mechanical', '0'], ['2025', 'Bahrain GP', 'Engine', '4']],
      'Kimi Antonelli': [['2025', 'Pre-Season', 'Spin', '0'], ['2025', 'Chinese GP', 'Collision', '1']],
      'Gabriel Bortoleto': [['2025', 'Pre-Season', 'Engine', '0'], ['2025', 'Japanese GP', 'Gearbox', '22']],
    };

    final data = dnfMap[name] ?? [['N/A', 'No recent DNFs', '-', '0']];
    return data.map((d) => _dnfDetailRow(d[0], d[1], d[2], int.tryParse(d[3]) ?? 0)).toList();
  }

  Widget _dnfDetailRow(String year, String circuit, String reason, int lap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(year, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3), fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(circuit, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black)),
                Text("$reason - Lap $lap", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TeamDetailView extends StatefulWidget {
  final Team team;
  final Widget settingsMenu;
  const TeamDetailView({required this.team, required this.settingsMenu, super.key});

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

  List<int> _getTeamHistory(String name) {
    if (name.contains('Red Bull')) return [2, 1, 1, 2, 2]; // 2021-2025
    if (name.contains('Mercedes')) return [1, 3, 2, 4, 3];
    if (name.contains('Ferrari')) return [3, 2, 3, 3, 4];
    if (name.contains('McLaren')) return [4, 5, 4, 1, 1];
    if (name.contains('Aston')) return [7, 7, 5, 5, 5];
    if (name.contains('Alpine')) return [5, 4, 6, 7, 7];
    if (name.contains('Williams')) return [8, 10, 7, 8, 8];
    if (name.contains('Racing Bulls') || name.contains('RB')) return [6, 9, 8, 6, 6];
    if (name.contains('Haas')) return [10, 8, 10, 9, 9];
    if (name.contains('Audi') || name.contains('Sauber')) return [9, 6, 9, 10, 10];
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
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(15), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(pos.length, (i) {
              double h = (12 - (pos[i] > 10 ? 11 : pos[i])) * 8.0;
              if(h < 10) h = 10;
              final isSelected = _selectedYearIndex == i;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedYearIndex = i),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text("P${pos[i]}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.white : Colors.black))),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 28 : 24, 
                    height: h, 
                    decoration: BoxDecoration(
                      color: color, 
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(years[i], style: TextStyle(fontSize: 10, color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ]),
              );
            }),
          ),
        ),
        if (_selectedYearIndex != null)
          _buildDriversForYear(2021 + _selectedYearIndex!)
      ],
    );
  }

  Widget _buildDriversForYear(int year) {
    final drivers = _getDriversForYear(year);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Drivers $year", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (drivers.isEmpty)
            const Text("No driver data available.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))
          else
            ...drivers.map((d) => InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DriverDetailView(driver: d, settingsMenu: widget.settingsMenu))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    Text(d.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (d.nationality.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(d.flag, style: const TextStyle(fontSize: 12)),
                    ]
                  ],
                ),
              ),
            )),
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
          for (int y = start; y <= end; y++) years.add(y);
        } else {
          int y = int.tryParse(yearStr) ?? 0;
          if (y != 0) years.add(y);
        }
        
        if (years.contains(year)) {
          // Try to find driver in the specific year list first, fallback to 2026 list for static data
          List<Driver> pool = driversData[year] ?? [];
          Driver d = pool.firstWhere((fd) => fd.name == name, orElse: () => 
            drivers2026.firstWhere((fd) => fd.name == name, orElse: () => Driver(
               name: name, flag: '', points: 0, number: 0, nationality: '', team: widget.team.name,
               pointsFinishPct: 0, seasonPointsFinishPct: 0, wins: 0, podiums2nd: 0, podiums3rd: 0,
               podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0, championships: 0, championshipYears: [],
               lapsRaced: 0, starts: 0, dnfs: 0, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0,
               highestFinish: 'N/A', highestGrid: 'N/A', hatTricks: 0, overtakes: 0, age: 0, height: '-',
               birthPlace: '-', partner: '-', children: '-', pets: '-', manager: '-',
               realWorldFactsEn: [], realWorldFactsNl: [], pointsPerSeason: {}, debutYear: 0,
               contractUntil: '-', previousTeams: [], personalSponsors: []
             )));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title = widget.team.name.toUpperCase();
    if (_showFlagInTitle) {
      title = "${widget.team.flag} $title";
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [widget.settingsMenu]),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20), 
        children: [
          Center(child: Text(widget.team.flag, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 20),
          
          if (widget.team.carImageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(widget.team.carImageUrl, fit: BoxFit.contain),
            ),

          ExpansionTile(
            initiallyExpanded: true,
            title: Text("📊 Performance History", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildHistoryChart(teamHistory, _getTeamColor(widget.team.name)),
              ),
            ],
          ),

          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('general'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('engine'), widget.team.engine, Icons.settings_input_component),
              _statTile(loc.translate('headquarters'), widget.team.headquarters, Icons.location_city),
              if (widget.team.previousNames.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(loc.translate('team_history'),
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13)),
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 600;
                            final history = widget.team.previousNames.reversed.toList();
                            if (isWide) {
                              // Horizontal Layout for wider screens
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: history.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    String name = entry.value;
                                    String teamName = name;
                                    String years = "";
                                    if (name.contains(' (')) {
                                      final parts = name.split(' (');
                                      teamName = parts[0];
                                      years = parts[1].replaceAll(')', '');
                                    }
                                    bool isLast = idx == history.length - 1;

                                    return Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: Container(height: 2, color: idx == 0 ? Colors.transparent : (isDark ? Colors.white24 : Colors.black12))),
                                              Container(
                                                width: 10, height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2196F3),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                                ),
                                              ),
                                              Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : (isDark ? Colors.white24 : Colors.black12))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(teamName, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                                          Text(years, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            } else {
                              // Vertical Layout for narrower screens
                              return Column(
                                children: history.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String name = entry.value;
                                  String teamName = name;
                                  String years = "";
                                  if (name.contains(' (')) {
                                    final parts = name.split(' (');
                                    teamName = parts[0];
                                    years = parts[1].replaceAll(')', '');
                                  }
                                  bool isLast = idx == history.length - 1;
                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, right: 12),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 10, height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2196F3),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                                ),
                                              ),
                                              if (!isLast)
                                                Expanded(
                                                  child: Container(width: 2, color: isDark ? Colors.white24 : Colors.black12),
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
                                                Text(teamName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                                                Text(years, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
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
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),

          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('championships'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              if (widget.team.ccYears.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(loc.translate('cc_wins'),
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13)),
                      trailing: Text(widget.team.ccWins.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(widget.team.ccYears.join(', '), textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                )
              else
                _statTile(loc.translate('cc_wins'), widget.team.ccWins, Icons.emoji_events),
              if (widget.team.dcList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(loc.translate('dc_wins'),
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 13)),
                      trailing: Text(widget.team.dcWins.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                      children: widget.team.dcList.map((d) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(d, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                      )).toList(),
                    ),
                  ),
                )
              else
                _statTile(loc.translate('dc_wins'), widget.team.dcWins, Icons.workspace_premium),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text(loc.translate('race_stats'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('total_entries'), widget.team.totalEntries, Icons.traffic),
              _statTile(loc.translate('wins'), widget.team.podiums, Icons.leaderboard),
              _statTile(loc.translate('one_two'), widget.team.oneTwo, Icons.filter_2),
              _statTile(loc.translate('poles'), widget.team.poles, Icons.flag),
              _statTile(loc.translate('fastest_laps'), widget.team.fastestLaps, Icons.timer),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text(loc.translate('pitstop_leadership'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('team_principal'), "${widget.team.principalName} (${widget.team.principalAge})", Icons.person_outline),
              _statTile(loc.translate('technical_director'), "${widget.team.technicalDirectorName} (${widget.team.technicalDirectorAge})", Icons.engineering),
              _statTile(loc.translate('fastestPit'), "${widget.team.fastestPitstopTime} (${loc.translate('country_${widget.team.fastestPitstopCircuit}')} ${widget.team.fastestPitstopYear})", Icons.build),
              const SizedBox(height: 8),
            ],
          ),

          ExpansionTile(
            title: Text(loc.translate('drivers'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              ...widget.team.drivers.map((d) => _statTile(d, '', Icons.person)),
              const SizedBox(height: 8),
            ],
          ),

          ExpansionTile(
            title: Text('⚙️ ${loc.translate('engine_supplier')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('name').split(' ').last, widget.team.engineSupplier.name, Icons.business),
              _statTile(loc.translate('engine_name').split(' ').last, widget.team.engineSupplier.engineName, Icons.settings),
              _statTile(loc.translate('city').split(' ').last, widget.team.engineSupplier.city, Icons.location_city),
              const SizedBox(height: 8),
            ],
          ),

          ExpansionTile(
            title: Text('💰 ${loc.translate('sponsors')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              ...widget.team.sponsors.map((s) => _statTile(s, '', Icons.attach_money)),
              const SizedBox(height: 8),
            ],
          ),
        ]
      ),
    );
  }
}

/// --- OPEN F1 SESSIONS ---
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
          if (_isFetching) const LinearProgressIndicator(color: Color(0xFF2196F3)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.race.hasSprint
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OpenF1SessionWidget(race: widget.race, sessionName: 'Qualifying', displayTitle: loc.translate('qualifying')),
                        OpenF1SessionWidget(race: widget.race, sessionName: 'Sprint', displayTitle: loc.translate('sprint')),
                        OpenF1SessionWidget(race: widget.race, sessionName: 'Race', displayTitle: '🏁 Race'), 
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OpenF1SessionWidget(race: widget.race, sessionName: 'Qualifying', displayTitle: loc.translate('qualifying')),
                        OpenF1SessionWidget(race: widget.race, sessionName: 'Race', displayTitle: '🏁 Race'), 
                      ],
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

  const OpenF1SessionWidget({required this.race, required this.sessionName, required this.displayTitle, super.key});

  Widget _buildResultRow(SessionResult res, int index) {
    return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('P$index.', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(res.driver, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black))),
          Text(res.time, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(getTireEmoji(res.tyre), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
        ],
      ),
    );});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = '${race.country}_${sessionName}_${race.date.year}';
    DateTime sessionTime;
    
    if (sessionName == 'Sprint Qualifying') {
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
        
        Widget buildEmpty(String title, String subtitle) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
            const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 8), Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          ]),
        );

        if (sessionTime.isAfter(DateTime.now())) {
          return buildEmpty(displayTitle, '${loc.translate('session_future')} ${sessionTime.toString().substring(0, 16)}');
        }
        if (results == null && !SessionDataManager().isInitialized) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2196F3))), const SizedBox(width: 12), Text('$displayTitle laden...')]),
          );
        }
        if (results == null || results.isEmpty) {
          return buildEmpty(displayTitle, loc.translate('no_data_yet'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8), child: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3)))),
            
            // Toon de Top 3 direct
            ...results.take(3).toList().asMap().entries.map((e) => _buildResultRow(e.value, e.key + 1)),

            // Uitklapbaar voor de rest van de rijders (P4 t/m P22)
            if (results.length > 3)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text("🔽 P4 t/m P${results.length} Weergeven", style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                  children: results.skip(3).toList().asMap().entries.map((e) => _buildResultRow(e.value, e.key + 4)).toList(),
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

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> changelog = [
      {
        'version': '2.1.3',
        'date': 'Maart 2026',
        'changes_en': ['Merged live Open-Meteo weather API.', 'Added top blocks for weather and circuit info.', 'Session results fetch live data via Ergast API with smart fallback to last year if data is pending.', 'Top 3 results always visible, rest in a collapsible list.', 'Added previous teams section for all drivers in driver details.', 'Added interactive driver championship history chart.'],
        'changes_nl': ['Live Open-Meteo weer-API gekoppeld.', 'Nieuwe informatieblokken voor weer en circuit.', 'Sessie resultaten halen live data op via API met slimme fallback naar vorig jaar indien de race nog niet verwerkt is.', 'Top 3 resultaten direct in beeld, rest uitklapbaar.', 'Sectie Vorige Teams toegevoegd voor alle coureurs in de coureur details.', 'Interactieve grafiek toegevoegd in de Coureur Details met kampioenschaphistorie.']
      }
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('changelog'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: changelog.length,
        itemBuilder: (context, index) {
          final entry = changelog[index];
          final changes = loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de' ? entry['changes_nl'] : entry['changes_en'];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${loc.translate('version')} ${entry['version']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3), fontSize: 18)), Text(entry['date'], style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))]),
                  const SizedBox(height: 12),
                  ...changes.map<Widget>((change) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Expanded(child: Text(change, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)))]))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// --- DATA MODELS ---------------------------------------------------------
class Race {
  final String name; final String country; final String flag; final DateTime date; final bool hasSprint; final int laps; final int length;
  final String distanceToTurn1;
  final WeatherForecast weather; final LapRecord fastestLap; final LapRecord slowestLap; final String averageLap; final String topSpeed;
  final String averageSpeed; final int redFlagChance; final int vscChance; final int accidentChance; final int turn1AccidentChance;
  final String tireWear; final String tireStrategy; final String bestCombination; final PitstopRecord fastestPitstop;
  final String circuitDifficulty; final String overtakingDifficulty; final List<String> previousWinners; final String maxGForce;
  final String avgGForce; final int firstGrandPrix; final String contractUntil; final List<String> characteristicsEn; final List<String> characteristicsNl;
  final String mapUrl;
  final String circuitImage;
  final double lat; final double lon;

  DateTime get fp1 => date.subtract(const Duration(days: 2, hours: 4));
  DateTime get fp2 => date.subtract(const Duration(days: 2));
  DateTime get fp3 => date.subtract(const Duration(days: 1, hours: 4));
  DateTime get sprintQuali => date.subtract(const Duration(days: 2));
  DateTime get sprintRace => date.subtract(const Duration(days: 1, hours: 4));
  DateTime get qualifying => date.subtract(const Duration(days: 1));

  Race({required this.name, required this.country, required this.flag, required this.date, required this.hasSprint, required this.laps, required this.length, required this.distanceToTurn1, required this.weather, required this.fastestLap, required this.slowestLap, required this.averageLap, required this.topSpeed, required this.averageSpeed, required this.redFlagChance, required this.vscChance, required this.accidentChance, required this.turn1AccidentChance, required this.tireWear, required this.tireStrategy, required this.bestCombination, required this.fastestPitstop, required this.circuitDifficulty, required this.overtakingDifficulty, required this.previousWinners, required this.maxGForce, required this.avgGForce, required this.firstGrandPrix, required this.contractUntil, required this.characteristicsEn, required this.characteristicsNl, required this.mapUrl, required this.circuitImage, required this.lat, required this.lon});
}

class WeatherForecast { final int temperature; final int rainChance; final int rainAmount; final int windSpeed; final int humidity; final int pressure; final int feelsLike; WeatherForecast({required this.temperature, required this.rainChance, required this.rainAmount, required this.windSpeed, required this.humidity, required this.pressure, required this.feelsLike}); }
class LapRecord { final String driver; final String team; final int year; final String time; LapRecord(this.driver, this.team, this.year, this.time); }
class PitstopRecord { final String team; final int year; final String time; PitstopRecord(this.team, this.year, this.time); }

class Driver { 
  final String name; final String flag; final int points; final int number; final String nationality; final String team; 
  final double pointsFinishPct; final double seasonPointsFinishPct; final int wins; final int podiums2nd; final int podiums3rd; final int podiums; 
  final int poles; final int fastestLaps; final double totalPoints; final int championships; final List<int> championshipYears; final int lapsRaced; final int starts; 
  final int dnfs; final int dsqs; final int dnqs; final int lapsLed; final int frontRowStarts; final String highestFinish; final String highestGrid; final int hatTricks; final int overtakes;
  final int age; final String height; final String birthPlace; final String partner; final String pets; final String manager;
  final String children;
  final List<String> realWorldFactsEn; final List<String> realWorldFactsNl; 
  final Map<int, double> pointsPerSeason; final int debutYear; final String contractUntil;
  final List<String> previousTeams;
  final List<String> personalSponsors;
  
  Driver({required this.name, required this.flag, required this.points, required this.number, required this.nationality, required this.team, required this.pointsFinishPct, required this.seasonPointsFinishPct, required this.wins, required this.podiums2nd, required this.podiums3rd, required this.podiums, required this.poles, required this.fastestLaps, required this.totalPoints, required this.championships, required this.championshipYears, required this.lapsRaced, required this.starts, required this.dnfs, required this.dsqs, required this.dnqs, required this.lapsLed, required this.frontRowStarts, required this.highestFinish, required this.highestGrid, required this.hatTricks, required this.overtakes, required this.age, required this.height, required this.birthPlace, required this.partner, required this.children, required this.pets, required this.manager, required this.realWorldFactsEn, required this.realWorldFactsNl, required this.pointsPerSeason, required this.debutYear, required this.contractUntil, required this.previousTeams, required this.personalSponsors}); 
  factory Driver.copy(Driver d, int points) => Driver(name: d.name, flag: d.flag, points: points, number: d.number, nationality: d.nationality, team: d.team, pointsFinishPct: d.pointsFinishPct, seasonPointsFinishPct: d.seasonPointsFinishPct, wins: d.wins, podiums2nd: d.podiums2nd, podiums3rd: d.podiums3rd, podiums: d.podiums, poles: d.poles, fastestLaps: d.fastestLaps, totalPoints: d.totalPoints, championships: d.championships, championshipYears: d.championshipYears, lapsRaced: d.lapsRaced, starts: d.starts, dnfs: d.dnfs, dsqs: d.dsqs, dnqs: d.dnqs, lapsLed: d.lapsLed, frontRowStarts: d.frontRowStarts, highestFinish: d.highestFinish, highestGrid: d.highestGrid, hatTricks: d.hatTricks, overtakes: d.overtakes, age: d.age, height: d.height, birthPlace: d.birthPlace, partner: d.partner, children: d.children, pets: d.pets, manager: d.manager, realWorldFactsEn: d.realWorldFactsEn, realWorldFactsNl: d.realWorldFactsNl, pointsPerSeason: d.pointsPerSeason, debutYear: d.debutYear, contractUntil: d.contractUntil, previousTeams: d.previousTeams, personalSponsors: d.personalSponsors);
}

class Team { 
  final String name; final String flag; final int points; final String engine; final String fastestPitstopTime; final int fastestPitstopYear; final String fastestPitstopCircuit; final int ccWins; final int dcWins; final int podiums; final int oneTwo; final int hattricks; final int doublePodiums; final double totalPoints; final int frontRow; final int poles; final int fastestLaps; final int racesLed; final String principalName; final int principalAge; final String principalFlag; final int totalEntries; final String technicalDirectorName; final int technicalDirectorAge;
  final EngineSupplier engineSupplier;
  final List<String> sponsors;
  final List<int> ccYears;
  final List<String> dcList;
  final String headquarters;
  final List<String> previousNames;
  final List<String> drivers;
  final String carImageUrl;
  Team({required this.name, required this.flag, required this.points, required this.engine, required this.fastestPitstopTime, required this.fastestPitstopYear, required this.fastestPitstopCircuit, required this.ccWins, required this.dcWins, required this.podiums, required this.oneTwo, required this.hattricks, required this.doublePodiums, required this.totalPoints, required this.frontRow, required this.poles, required this.fastestLaps, required this.racesLed, required this.principalName, required this.principalAge, required this.principalFlag, required this.totalEntries, required this.technicalDirectorName, required this.technicalDirectorAge, required this.engineSupplier, required this.sponsors, required this.ccYears, required this.dcList, required this.headquarters, required this.previousNames, required this.drivers, required this.carImageUrl}); 
  factory Team.copy(Team t, int points) => Team(name: t.name, flag: t.flag, points: points, engine: t.engine, fastestPitstopTime: t.fastestPitstopTime, fastestPitstopYear: t.fastestPitstopYear, fastestPitstopCircuit: t.fastestPitstopCircuit, ccWins: t.ccWins, dcWins: t.dcWins, podiums: t.podiums, oneTwo: t.oneTwo, hattricks: t.hattricks, doublePodiums: t.doublePodiums, totalPoints: t.totalPoints, frontRow: t.frontRow, poles: t.poles, fastestLaps: t.fastestLaps, racesLed: t.racesLed, principalName: t.principalName, principalAge: t.principalAge, principalFlag: t.principalFlag, totalEntries: t.totalEntries, technicalDirectorName: t.technicalDirectorName, technicalDirectorAge: t.technicalDirectorAge, engineSupplier: t.engineSupplier, sponsors: t.sponsors, ccYears: t.ccYears, dcList: t.dcList, headquarters: t.headquarters, previousNames: t.previousNames, drivers: t.drivers, carImageUrl: t.carImageUrl);
}

/// --- VOLLEDIGE 2026 GRID & KALENDER MET 5 KENMERKEN PER CIRCUIT ------------------------------------
final List<Race> races = [
  Race(name: 'Australian Grand Prix', country: 'Australia', flag: '🇦🇺', date: DateTime(2026, 3, 8, 5, 0), hasSprint: false, laps: 58, length: 5278, distanceToTurn1: '260m', lat: -37.8497, lon: 144.968, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/australia.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmelbourneblackoutline.svg', weather: WeatherForecast(temperature: 22, rainChance: 20, rainAmount: 2, windSpeed: 14, humidity: 55, pressure: 1015, feelsLike: 21), fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2024, '1:19.813'), slowestLap: LapRecord('Robert Kubica', 'Alfa Romeo', 2019, '1:35.000'), averageLap: '1:23.000', topSpeed: '335 km/h', averageSpeed: '230 km/h', redFlagChance: 15, vscChance: 20, accidentChance: 25, turn1AccidentChance: 15, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Ferrari', 2022, '2.3s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_3', previousWinners: ['2025: Lando Norris', '2024: Carlos Sainz'], maxGForce: '4.8 G', avgGForce: '2.6 G', firstGrandPrix: 1996, contractUntil: '2037', characteristicsEn: ['4 DRS zones', 'Sweeping corners', 'Temporary street circuit', 'Variable grip levels', 'Bumpy surface'], characteristicsNl: ['4 DRS-zones', 'Vloeiende bochten', 'Tijdelijk stratencircuit', 'Wisselende gripniveaus', 'Hobbelig oppervlak']),
  Race(name: 'Chinese Grand Prix', country: 'China', flag: '🇨🇳', date: DateTime(2026, 3, 15, 8, 0), hasSprint: true, laps: 56, length: 5451, distanceToTurn1: '380m', lat: 31.3389, lon: 121.22, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/china.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackshanghaiblackoutline.svg', weather: WeatherForecast(temperature: 17, rainChance: 25, rainAmount: 3, windSpeed: 12, humidity: 50, pressure: 1013, feelsLike: 16), fastestLap: LapRecord('Michael Schumacher', 'Ferrari', 2004, '1:32.238'), slowestLap: LapRecord('Marcus Ericsson', 'Sauber', 2018, '1:45.000'), averageLap: '1:35.000', topSpeed: '340 km/h', averageSpeed: '210 km/h', redFlagChance: 7, vscChance: 10, accidentChance: 14, turn1AccidentChance: 8, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Williams', 2019, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Charles Leclerc', '2024: Max Verstappen'], maxGForce: '4.5 G', avgGForce: '2.4 G', firstGrandPrix: 2004, contractUntil: '2025', characteristicsEn: ['Famous Snail corner', 'Massive back straight', 'Front-left tire killer', 'Wide track for overtaking', 'High chance of rain'], characteristicsNl: ['Beroemde slakkenhuisbocht', 'Enorm lang recht stuk', 'Slecht voor linkervoorband', 'Breed circuit (goed inhalen)', 'Grote kans op regen']),
  Race(name: 'Japanese Grand Prix', country: 'Japan', flag: '🇯🇵', date: DateTime(2026, 3, 29, 7, 0), hasSprint: false, laps: 53, length: 5807, distanceToTurn1: '400m', lat: 34.8431, lon: 136.531, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/japan.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026tracksuzukablackoutline.svg', weather: WeatherForecast(temperature: 19, rainChance: 30, rainAmount: 5, windSpeed: 16, humidity: 60, pressure: 1018, feelsLike: 18), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2019, '1:30.983'), slowestLap: LapRecord('Pierre Gasly', 'AlphaTauri', 2020, '1:40.000'), averageLap: '1:33.000', topSpeed: '330 km/h', averageSpeed: '230 km/h', redFlagChance: 12, vscChance: 18, accidentChance: 22, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2021, '2.1s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '5.2 G', avgGForce: '3.1 G', firstGrandPrix: 1987, contractUntil: '2029', characteristicsEn: ['Figure-8 layout', 'Legendary 130R', 'High downforce demanded', 'High lateral G-forces', 'Unpredictable weather'], characteristicsNl: ['8-vormige lay-out', 'Legendarische 130R', 'Veel downforce vereist', 'Hoge laterale G-krachten', 'Onvoorspelbaar weer']),
  Race(name: 'Bahrain Grand Prix', country: 'Bahrain', flag: '🇧🇭', date: DateTime(2026, 4, 12, 16, 0), hasSprint: false, laps: 57, length: 5412, distanceToTurn1: '400m', lat: 26.0325, lon: 50.5106, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/bahrain.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026tracksakhirblackoutline.svg', weather: WeatherForecast(temperature: 24, rainChance: 0, rainAmount: 0, windSpeed: 15, humidity: 40, pressure: 1012, feelsLike: 24), fastestLap: LapRecord('Pedro de la Rosa', 'McLaren', 2005, '1:31.447'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:35.000'), averageLap: '1:33.500', topSpeed: '325 km/h', averageSpeed: '205 km/h', redFlagChance: 5, vscChance: 15, accidentChance: 12, turn1AccidentChance: 25, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Hard → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.2 G', avgGForce: '2.3 G', firstGrandPrix: 2004, contractUntil: '2036', characteristicsEn: ['High tire degradation', 'Heavy braking zones', 'Sakhir desert winds', 'Night race under floodlights', 'Long DRS straights'], characteristicsNl: ['Hoge bandenslijtage', 'Zware remzones', 'Sakhir woestijnwind', 'Nachtrace onder kunstlicht', 'Lange DRS stukken']),
  Race(name: 'Saudi Arabian Grand Prix', country: 'Saudi Arabia', flag: '🇸🇦', date: DateTime(2026, 4, 19, 18, 0), hasSprint: false, laps: 50, length: 6174, distanceToTurn1: '220m', lat: 21.6319, lon: 39.1044, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/saudi_arabia.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackjeddahblackoutline.svg', weather: WeatherForecast(temperature: 27, rainChance: 0, rainAmount: 0, windSpeed: 10, humidity: 60, pressure: 1010, feelsLike: 29), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:30.734'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:34.000'), averageLap: '1:32.000', topSpeed: '335 km/h', averageSpeed: '250 km/h', redFlagChance: 25, vscChance: 35, accidentChance: 40, turn1AccidentChance: 10, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('McLaren', 2023, '2.2s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_3', previousWinners: ['2025: Sergio Perez', '2024: Max Verstappen'], maxGForce: '4.9 G', avgGForce: '2.8 G', firstGrandPrix: 2021, contractUntil: '2030', characteristicsEn: ['Fastest street circuit', 'Blind high-speed corners', 'High risk of safety cars', 'Smooth tarmac', 'Very narrow run-off areas'], characteristicsNl: ['Snelste stratencircuit', 'Blinde hogesnelheidsbochten', 'Hoge kans op safety cars', 'Glad asfalt', 'Zeer smalle uitloopstroken']),
  Race(name: 'Miami Grand Prix', country: 'USA', flag: '🇺🇸', date: DateTime(2026, 5, 3, 22, 0), hasSprint: true, laps: 57, length: 5412, distanceToTurn1: '200m', lat: 25.9581, lon: -80.2389, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/miami.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmiamiblackoutline.svg', weather: WeatherForecast(temperature: 29, rainChance: 40, rainAmount: 5, windSpeed: 10, humidity: 75, pressure: 1012, feelsLike: 33), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:29.708'), slowestLap: LapRecord('Kevin Magnussen', 'Haas', 2022, '1:33.000'), averageLap: '1:31.000', topSpeed: '335 km/h', averageSpeed: '215 km/h', redFlagChance: 10, vscChance: 20, accidentChance: 15, turn1AccidentChance: 10, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_3', previousWinners: ['2025: Lando Norris', '2024: Lando Norris'], maxGForce: '4.1 G', avgGForce: '2.2 G', firstGrandPrix: 2022, contractUntil: '2031', characteristicsEn: ['Fake marina', 'Tight chicane section', 'Hard overtaking', 'High humidity', 'Long back straight'], characteristicsNl: ['Nep jachthaven', 'Krappe chicane sectie', 'Lastig inhalen', 'Hoge luchtvochtigheid', 'Lang recht stuk achter']),
  Race(name: 'Canadian Grand Prix', country: 'Canada', flag: '🇨🇦', date: DateTime(2026, 5, 24, 20, 0), hasSprint: true, laps: 70, length: 4361, distanceToTurn1: '260m', lat: 45.5000, lon: -73.5228, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/canada.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmontrealblackoutline.svg', weather: WeatherForecast(temperature: 20, rainChance: 40, rainAmount: 5, windSpeed: 15, humidity: 65, pressure: 1011, feelsLike: 20), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2019, '1:13.078'), slowestLap: LapRecord('Lance Stroll', 'Williams', 2018, '1:16.000'), averageLap: '1:14.500', topSpeed: '340 km/h', averageSpeed: '210 km/h', redFlagChance: 20, vscChance: 30, accidentChance: 35, turn1AccidentChance: 15, tireWear: 'Low', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Williams', 2019, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.4 G', avgGForce: '2.1 G', firstGrandPrix: 1978, contractUntil: '2031', characteristicsEn: ['Wall of Champions', 'Heavy braking zones', 'Groundhog hazard', 'Chicane riding', 'Stop-and-go layout'], characteristicsNl: ['Muur der Kampioenen', 'Zware remzones', 'Gevaar voor marmotten', 'Agressief over chicanes', 'Stop-and-go lay-out']),
  Race(name: 'Monaco Grand Prix', country: 'Monaco', flag: '🇲🇨', date: DateTime(2026, 6, 7, 15, 0), hasSprint: false, laps: 78, length: 3337, distanceToTurn1: '210m', lat: 43.7347, lon: 7.4206, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/monaco.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmontecarloblackoutline.svg', weather: WeatherForecast(temperature: 23, rainChance: 10, rainAmount: 1, windSpeed: 8, humidity: 55, pressure: 1016, feelsLike: 23), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:12.909'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:18.000'), averageLap: '1:15.000', topSpeed: '290 km/h', averageSpeed: '160 km/h', redFlagChance: 35, vscChance: 45, accidentChance: 50, turn1AccidentChance: 40, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2021, '2.0s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_5', previousWinners: ['2025: Charles Leclerc', '2024: Charles Leclerc'], maxGForce: '3.6 G', avgGForce: '1.8 G', firstGrandPrix: 1950, contractUntil: '2025', characteristicsEn: ['Ultimate driver test', 'Impossible to overtake', 'Shortest lap', 'High concentration required', 'Glamorous harbor setting'], characteristicsNl: ['Ultieme test voor coureurs', 'Onmogelijk in te halen', 'Kortste ronde', 'Hoge concentratie vereist', 'Glamoureuze havenomgeving']),
  Race(name: 'Barcelona Grand Prix', country: 'Spain', flag: '🇪🇸', date: DateTime(2026, 6, 14, 15, 0), hasSprint: false, laps: 66, length: 4657, distanceToTurn1: '600m', lat: 41.5700, lon: 2.2611, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/spain.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackcatalunyablackoutline.svg', weather: WeatherForecast(temperature: 28, rainChance: 5, rainAmount: 0, windSpeed: 12, humidity: 50, pressure: 1014, feelsLike: 30), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:16.330'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:19.000'), averageLap: '1:18.000', topSpeed: '325 km/h', averageSpeed: '220 km/h', redFlagChance: 5, vscChance: 10, accidentChance: 10, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.0s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_4', previousWinners: ['2025: Lando Norris', '2024: Max Verstappen'], maxGForce: '4.7 G', avgGForce: '2.5 G', firstGrandPrix: 1991, contractUntil: '2026', characteristicsEn: ['High downforce test', 'Long fast corners', 'High tire wear', 'Often used for testing', 'Hard to follow closely'], characteristicsNl: ['Test voor downforce', 'Lange snelle bochten', 'Hoge bandenslijtage', 'Vaak gebruikt voor testdagen', 'Lastig om dichtbij te volgen']),
  Race(name: 'Austrian Grand Prix', country: 'Austria', flag: '🇦🇹', date: DateTime(2026, 6, 28, 15, 0), hasSprint: false, laps: 71, length: 4318, distanceToTurn1: '330m', lat: 47.2197, lon: 14.7647, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/austria.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackspielbergblackoutline.svg', weather: WeatherForecast(temperature: 24, rainChance: 30, rainAmount: 4, windSpeed: 10, humidity: 55, pressure: 1015, feelsLike: 25), fastestLap: LapRecord('Carlos Sainz', 'McLaren', 2020, '1:05.619'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2020, '1:08.000'), averageLap: '1:07.000', topSpeed: '330 km/h', averageSpeed: '235 km/h', redFlagChance: 10, vscChance: 25, accidentChance: 15, turn1AccidentChance: 20, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Medium', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_2', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: George Russell'], maxGForce: '4.3 G', avgGForce: '2.4 G', firstGrandPrix: 1970, contractUntil: '2030', characteristicsEn: ['Shortest lap time', 'High altitude', 'Elevation changes', '3 DRS zones', 'Aggressive kerbs'], characteristicsNl: ['Kortste rondetijd', 'Hoge ligging', 'Veel hoogteverschillen', '3 DRS-zones', 'Zeer agressieve kerbs']),
  Race(name: 'British Grand Prix', country: 'UK', flag: '🇬🇧', date: DateTime(2026, 7, 5, 16, 0), hasSprint: true, laps: 52, length: 5891, distanceToTurn1: '280m', lat: 52.0786, lon: -1.0169, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/uk.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_392/v1740000000/common/f1/2026/track/2026tracksilverstoneblackoutline.svg', weather: WeatherForecast(temperature: 20, rainChance: 50, rainAmount: 6, windSpeed: 20, humidity: 65, pressure: 1010, feelsLike: 19), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2020, '1:27.097'), slowestLap: LapRecord('Romain Grosjean', 'Haas', 2020, '1:31.000'), averageLap: '1:29.000', topSpeed: '330 km/h', averageSpeed: '245 km/h', redFlagChance: 20, vscChance: 25, accidentChance: 30, turn1AccidentChance: 15, tireWear: 'Very High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Soft', fastestPitstop: PitstopRecord('McLaren', 2023, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_3', previousWinners: ['2025: Lando Norris', '2024: Lewis Hamilton'], maxGForce: '5.2 G', avgGForce: '2.9 G', firstGrandPrix: 1950, contractUntil: '2034', characteristicsEn: ['Maggots and Becketts', 'High speed flowing', 'Historic airfield', 'High lateral loads', 'Famous unpredictable British weather'], characteristicsNl: ['Maggots en Becketts', 'Snel en vloeiend', 'Historisch vliegveld', 'Hoge laterale krachten', 'Onvoorspelbaar Brits weer']),
  Race(name: 'Belgian Grand Prix', country: 'Belgium', flag: '🇧🇪', date: DateTime(2026, 7, 19, 15, 0), hasSprint: false, laps: 44, length: 7004, distanceToTurn1: '270m', lat: 50.4372, lon: 5.9714, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/belgium.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackspafrancorchampsblackoutline.svg', weather: WeatherForecast(temperature: 18, rainChance: 60, rainAmount: 12, windSpeed: 15, humidity: 75, pressure: 1009, feelsLike: 17), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2018, '1:46.286'), slowestLap: LapRecord('Lance Stroll', 'Williams', 2018, '1:50.000'), averageLap: '1:48.000', topSpeed: '345 km/h', averageSpeed: '240 km/h', redFlagChance: 25, vscChance: 35, accidentChance: 40, turn1AccidentChance: 30, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Medium', fastestPitstop: PitstopRecord('Williams', 2019, '2.1s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Lewis Hamilton'], maxGForce: '4.8 G', avgGForce: '2.5 G', firstGrandPrix: 1950, contractUntil: '2025', characteristicsEn: ['Eau Rouge / Radillon', 'Longest track on calendar', 'Microclimates', 'Kemmel straight slipstreaming', 'Historic forest setting'], characteristicsNl: ['Eau Rouge / Radillon', 'Langste circuit van de kalender', 'Microklimaten (regen in 1 bocht)', 'Slipstreamen op Kemmel Straight', 'Historische bosrijke omgeving']),
  Race(name: 'Hungarian Grand Prix', country: 'Hungary', flag: '🇭🇺', date: DateTime(2026, 7, 26, 15, 0), hasSprint: false, laps: 70, length: 4381, distanceToTurn1: '610m', lat: 47.5822, lon: 19.2511, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/hungary.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_392/v1740000000/common/f1/2026/track/2026trackhungaroringblackoutline.svg', weather: WeatherForecast(temperature: 31, rainChance: 15, rainAmount: 2, windSpeed: 10, humidity: 45, pressure: 1013, feelsLike: 33), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2020, '1:16.627'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2021, '1:21.000'), averageLap: '1:19.000', topSpeed: '315 km/h', averageSpeed: '200 km/h', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 25, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.3s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_5', previousWinners: ['2025: Oscar Piastri', '2024: Oscar Piastri'], maxGForce: '4.4 G', avgGForce: '2.2 G', firstGrandPrix: 1986, contractUntil: '2032', characteristicsEn: ['Monaco without walls', 'Dusty off racing line', 'Extremely hot', 'High downforce', 'Difficult to overtake'], characteristicsNl: ['Monaco zonder muren', 'Stoffig naast de ideale lijn', 'Meestal extreem heet', 'Veel downforce vereist', 'Erg moeilijk in te halen']),
  Race(name: 'Dutch Grand Prix', country: 'Netherlands', flag: '🇳🇱', date: DateTime(2026, 8, 23, 15, 0), hasSprint: true, laps: 72, length: 4259, distanceToTurn1: '240m', lat: 52.3888, lon: 4.5409, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/netherlands.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackzandvoortblackoutline.svg', weather: WeatherForecast(temperature: 20, rainChance: 45, rainAmount: 6, windSpeed: 25, humidity: 70, pressure: 1012, feelsLike: 19), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:11.097'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:15.000'), averageLap: '1:13.000', topSpeed: '320 km/h', averageSpeed: '215 km/h', redFlagChance: 15, vscChance: 25, accidentChance: 25, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_5', previousWinners: ['2025: Max Verstappen', '2024: Lando Norris'], maxGForce: '4.9 G', avgGForce: '2.6 G', firstGrandPrix: 1952, contractUntil: '2025', characteristicsEn: ['Banked corners', 'Orange Army', 'Narrow and twisty', 'Sand on track', 'Zandvoort dunes'], characteristicsNl: ['Steile kombochten', 'Oranje Legioen', 'Smal en bochtig', 'Zand op de baan', 'Gelegen in de Zandvoortse duinen']),
  Race(name: 'Italian Grand Prix', country: 'Italy', flag: '🇮🇹', date: DateTime(2026, 9, 6, 15, 0), hasSprint: false, laps: 53, length: 5793, distanceToTurn1: '640m', lat: 45.6156, lon: 9.2811, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/italy.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmonzablackoutline.svg', weather: WeatherForecast(temperature: 26, rainChance: 10, rainAmount: 0, windSpeed: 5, humidity: 45, pressure: 1015, feelsLike: 27), fastestLap: LapRecord('Rubens Barrichello', 'Ferrari', 2004, '1:21.046'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:25.000'), averageLap: '1:23.000', topSpeed: '360 km/h', averageSpeed: '260 km/h', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 40, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Ferrari', 2022, '2.1s'), circuitDifficulty: 'level_2', overtakingDifficulty: 'level_2', previousWinners: ['2025: Charles Leclerc', '2024: Charles Leclerc'], maxGForce: '3.8 G', avgGForce: '1.9 G', firstGrandPrix: 1950, contractUntil: '2025', characteristicsEn: ['Temple of Speed', 'Lowest downforce', 'Heavy braking for chicane', 'Parabolica corner', 'Tifosi atmosphere'], characteristicsNl: ['Temple of Speed', 'Laagste downforce van het jaar', 'Zware aanremmen voor chicanes', 'De legendarische Parabolica', 'Gepassioneerde Tifosi sfeer']),
  Race(name: 'Spanish Grand Prix', country: 'Spain', flag: '🇪🇸', date: DateTime(2026, 9, 13, 15, 0), hasSprint: false, laps: 54, length: 5474, distanceToTurn1: '300m', lat: 40.4700, lon: -3.6200, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/placeholder.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmadringblackoutline.svg', weather: WeatherForecast(temperature: 27, rainChance: 10, rainAmount: 1, windSpeed: 10, humidity: 45, pressure: 1016, feelsLike: 29), fastestLap: LapRecord('TBD', 'TBD', 2026, '1:32.000'), slowestLap: LapRecord('TBD', 'TBD', 2026, '1:38.000'), averageLap: '1:34.000', topSpeed: '320 km/h', averageSpeed: '215 km/h', redFlagChance: 25, vscChance: 35, accidentChance: 30, turn1AccidentChance: 20, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('TBD', 2026, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_3', previousWinners: ['(Nieuw circuit)'], maxGForce: '4.2 G', avgGForce: '2.4 G', firstGrandPrix: 2026, contractUntil: '2035', characteristicsEn: ['Brand new street track', 'Tunnel sections', 'IFEMA exhibition area', 'Hybrid permanent/street', 'Unpredictable surface'], characteristicsNl: ['Nieuw stratencircuit', 'Bevat tunnel secties', 'Rondom IFEMA complex', 'Hybride permanent/straten', 'Onvoorspelbaar asfalt']),
  Race(name: 'Azerbaijan Grand Prix', country: 'Azerbaijan', flag: '🇦🇿', date: DateTime(2026, 9, 26, 13, 0), hasSprint: false, laps: 51, length: 6003, distanceToTurn1: '200m', lat: 40.3725, lon: 49.8533, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/azerbaijan.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackbakublackoutline.svg', weather: WeatherForecast(temperature: 24, rainChance: 5, rainAmount: 0, windSpeed: 22, humidity: 55, pressure: 1016, feelsLike: 24), fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2019, '1:43.009'), slowestLap: LapRecord('Lance Stroll', 'Aston Martin', 2021, '1:47.000'), averageLap: '1:45.000', topSpeed: '350 km/h', averageSpeed: '210 km/h', redFlagChance: 30, vscChance: 40, accidentChance: 45, turn1AccidentChance: 20, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Williams', 2016, '1.9s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_2', previousWinners: ['2025: Oscar Piastri', '2024: Oscar Piastri'], maxGForce: '4.0 G', avgGForce: '2.0 G', firstGrandPrix: 2016, contractUntil: '2026', characteristicsEn: ['Castle section', 'Massive main straight', 'High top speeds', 'Street circuit risks', 'Windy "City of Winds"'], characteristicsNl: ['Extreem krappe Kasteel sectie', 'Enorm lang recht stuk', 'Zeer hoge topsnelheden', 'Veel risico\'s door krappe muren', 'Veel wind ("Stad der Winden")']),
  Race(name: 'Singapore Grand Prix', country: 'Singapore', flag: '🇸🇬', date: DateTime(2026, 10, 11, 14, 0), hasSprint: true, laps: 62, length: 4940, distanceToTurn1: '300m', lat: 1.2915, lon: 103.864, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/singapore.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026tracksingaporeblackoutline.svg', weather: WeatherForecast(temperature: 31, rainChance: 50, rainAmount: 15, windSpeed: 10, humidity: 85, pressure: 1008, feelsLike: 38), fastestLap: LapRecord('Daniel Ricciardo', 'VCARB', 2024, '1:34.486'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:39.000'), averageLap: '1:37.000', topSpeed: '310 km/h', averageSpeed: '175 km/h', redFlagChance: 25, vscChance: 60, accidentChance: 50, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.3s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_5', previousWinners: ['2025: Lando Norris', '2024: Lando Norris'], maxGForce: '4.2 G', avgGForce: '2.1 G', firstGrandPrix: 2008, contractUntil: '2028', characteristicsEn: ['Night race', 'Extreme humidity', 'Bumpy street surface', 'Physically exhausting', 'High probability of safety car'], characteristicsNl: ['Nachtrace', 'Extreem hoge luchtvochtigheid', 'Hobbelig stratencircuit', 'Fysiek enorm slopend', 'Bijna 100% kans op Safety Car']),
  Race(name: 'United States Grand Prix', country: 'USA', flag: '🇺🇸', date: DateTime(2026, 10, 25, 21, 0), hasSprint: false, laps: 56, length: 5513, distanceToTurn1: '280m', lat: 30.1328, lon: -97.6411, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/usa.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackaustinblackoutline.svg', weather: WeatherForecast(temperature: 28, rainChance: 10, rainAmount: 1, windSpeed: 15, humidity: 45, pressure: 1013, feelsLike: 29), fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2019, '1:36.169'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:40.000'), averageLap: '1:38.000', topSpeed: '335 km/h', averageSpeed: '205 km/h', redFlagChance: 10, vscChance: 20, accidentChance: 25, turn1AccidentChance: 30, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Medium', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Charles Leclerc'], maxGForce: '4.5 G', avgGForce: '2.5 G', firstGrandPrix: 2012, contractUntil: '2026', characteristicsEn: ['Steep Turn 1', 'Bumpy surface', 'Inspired by other tracks', 'Fast sector 1', 'Wide run-offs'], characteristicsNl: ['Zeer steile bocht 1', 'Hobbelig asfalt (sinkholes)', 'Geïnspireerd door andere iconische banen', 'Zeer snelle eerste sector', 'Brede uitloopstroken']),
  Race(name: 'Mexico City Grand Prix', country: 'Mexico', flag: '🇲🇽', date: DateTime(2026, 11, 1, 21, 0), hasSprint: false, laps: 71, length: 4304, distanceToTurn1: '810m', lat: 19.4042, lon: -99.0907, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/mexico.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackmexicocityblackoutline.svg', weather: WeatherForecast(temperature: 23, rainChance: 20, rainAmount: 2, windSpeed: 8, humidity: 40, pressure: 1025, feelsLike: 23), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2021, '1:17.774'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2021, '1:21.000'), averageLap: '1:19.000', topSpeed: '350 km/h', averageSpeed: '195 km/h', redFlagChance: 15, vscChance: 25, accidentChance: 20, turn1AccidentChance: 35, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.0s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Carlos Sainz'], maxGForce: '4.1 G', avgGForce: '2.0 G', firstGrandPrix: 1962, contractUntil: '2025', characteristicsEn: ['High altitude (thin air)', 'Stadium section', 'Less drag effect', 'Brake cooling issues', 'Long run to turn 1'], characteristicsNl: ['Hoge ligging (zeer ijle lucht)', 'Karakteristieke stadion sectie', 'Weinig luchtweerstand op straights', 'Problemen met remkoeling', 'Heel lang recht stuk naar bocht 1']),
  Race(name: 'São Paulo Grand Prix', country: 'Brazil', flag: '🇧🇷', date: DateTime(2026, 11, 8, 18, 0), hasSprint: true, laps: 71, length: 4309, distanceToTurn1: '190m', lat: -23.7036, lon: -46.6997, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/brazil.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackinterlagosblackoutline.svg', weather: WeatherForecast(temperature: 25, rainChance: 60, rainAmount: 10, windSpeed: 12, humidity: 65, pressure: 1012, feelsLike: 27), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2018, '1:10.540'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:14.000'), averageLap: '1:12.500', topSpeed: '335 km/h', averageSpeed: '215 km/h', redFlagChance: 20, vscChance: 35, accidentChance: 30, turn1AccidentChance: 25, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Medium', fastestPitstop: PitstopRecord('Red Bull', 2019, '1.8s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.6 G', avgGForce: '2.5 G', firstGrandPrix: 1973, contractUntil: '2030', characteristicsEn: ['Senna S', 'Unpredictable weather', 'Anti-clockwise', 'Short lap', 'Passionate fans'], characteristicsNl: ['De beroemde Senna S', 'Zeer onvoorspelbaar weer', 'Tegen de klok in', 'Korte rondetijd', 'Extreem fanatiek publiek']),
  Race(name: 'Las Vegas Grand Prix', country: 'USA', flag: '🇺🇸', date: DateTime(2026, 11, 22, 7, 0), hasSprint: false, laps: 50, length: 6201, distanceToTurn1: '240m', lat: 36.1147, lon: -115.1728, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/las_vegas.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026tracklasvegasblackoutline.svg', weather: WeatherForecast(temperature: 12, rainChance: 0, rainAmount: 0, windSpeed: 10, humidity: 30, pressure: 1018, feelsLike: 10), fastestLap: LapRecord('Oscar Piastri', 'McLaren', 2023, '1:35.490'), slowestLap: LapRecord('Kevin Magnussen', 'Haas', 2023, '1:39.000'), averageLap: '1:37.000', topSpeed: '350 km/h', averageSpeed: '235 km/h', redFlagChance: 15, vscChance: 30, accidentChance: 35, turn1AccidentChance: 25, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.2s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '3.9 G', avgGForce: '2.1 G', firstGrandPrix: 2023, contractUntil: '2032', characteristicsEn: ['The Strip straight', 'Cold night temperatures', 'Low grip', 'Heavy braking after long straights', 'Spectacular visuals'], characteristicsNl: ['Extreem lang stuk op The Strip', 'Zeer koude nachttemperaturen', 'Gevaarlijk lage grip', 'Zwaar aanremmen na rechte stukken', 'Spectaculaire visuele ervaring']),
  Race(name: 'Qatar Grand Prix', country: 'Qatar', flag: '🇶🇦', date: DateTime(2026, 11, 29, 18, 0), hasSprint: true, laps: 57, length: 5419, distanceToTurn1: '350m', lat: 25.4900, lon: 51.4542, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/qatar.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026tracklusailblackoutline.svg', weather: WeatherForecast(temperature: 28, rainChance: 0, rainAmount: 0, windSpeed: 18, humidity: 55, pressure: 1013, feelsLike: 30), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:23.196'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:27.000'), averageLap: '1:25.000', topSpeed: '330 km/h', averageSpeed: '235 km/h', redFlagChance: 5, vscChance: 15, accidentChance: 15, turn1AccidentChance: 10, tireWear: 'Very High', tireStrategy: '3 stops', bestCombination: 'Medium → Medium → Hard → Soft', fastestPitstop: PitstopRecord('McLaren', 2023, '1.80s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '5.3 G', avgGForce: '3.0 G', firstGrandPrix: 2021, contractUntil: '2032', characteristicsEn: ['High speed corners', 'Physically demanding', 'Night race', 'Flat desert setting', 'High tire stress'], characteristicsNl: ['Veel opeenvolgende snelle bochten', 'Fysiek extreem veeleisend', 'Nachtrace', 'Volledig vlakke woestijnomgeving', 'Hoge belasting op de banden']),
  Race(name: 'Abu Dhabi Grand Prix', country: 'UAE', flag: '🇦🇪', date: DateTime(2026, 12, 6, 14, 0), hasSprint: false, laps: 58, length: 5281, distanceToTurn1: '300m', lat: 24.4672, lon: 54.6031, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/abu_dhabi.png', circuitImage: 'https://media.formula1.com/image/upload/c_lfill,w_3392/v1740000000/common/f1/2026/track/2026trackyasmarinacircuitblackoutline.svg', weather: WeatherForecast(temperature: 26, rainChance: 0, rainAmount: 0, windSpeed: 12, humidity: 50, pressure: 1015, feelsLike: 27), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:26.103'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:30.000'), averageLap: '1:28.000', topSpeed: '335 km/h', averageSpeed: '215 km/h', redFlagChance: 5, vscChance: 10, accidentChance: 10, turn1AccidentChance: 15, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_3', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.5 G', avgGForce: '2.3 G', firstGrandPrix: 2009, contractUntil: '2030', characteristicsEn: ['Twilight race', 'Long back straight', 'Smooth surface', 'Yas Marina setting', 'Technical sector 3'], characteristicsNl: ['Race tijdens de zonsondergang', 'Lang recht stuk achteraan', 'Zeer glad asfalt', 'Luxe Yas Marina omgeving', 'Technische en trage derde sector']),
];

final List<Driver> drivers2026 = [
  Driver(name: 'Max Verstappen', flag: '🇳🇱', points: 0, number: 33, nationality: 'Dutch', team: 'Red Bull Racing', pointsFinishPct: 85.1, seasonPointsFinishPct: 95.8, wins: 62, podiums2nd: 31, podiums3rd: 16, podiums: 116, poles: 45, fastestLaps: 35, totalPoints: 3400.5, championships: 4, championshipYears: [2021, 2022, 2023, 2024], lapsRaced: 11452, starts: 210, dnfs: 31, dsqs: 0, dnqs: 0, lapsLed: 3350, frontRowStarts: 65, highestFinish: '1e (x62)', highestGrid: '1e (x45)', hatTricks: 13, overtakes: 850, age: 28, height: '1.81m', birthPlace: 'Hasselt, Belgium', partner: 'Kelly Piquet', children: 'Penelope (step), Carola', pets: 'Jimmy & Sassy (Cats)', manager: 'Raymond Vermeulen', realWorldFactsNl: ['Jongste coureur ooit in een Grand Prix-weekend.', 'Recordhouder meeste overwinningen in één seizoen (19).'], realWorldFactsEn: ['Youngest ever driver in a GP weekend.', 'Most wins in a single season (19).'], pointsPerSeason: {2025: 450, 2024: 400, 2023: 575, 2022: 454, 2021: 395.5}, debutYear: 2015, contractUntil: '2028', previousTeams: ['Toro Rosso (2015-2016)'], personalSponsors: ['Red Bull', 'Jumbo', 'CarNext.com', 'Viaplay']),
  Driver(name: 'Lewis Hamilton', flag: '🇬🇧', points: 0, number: 44, nationality: 'British', team: 'Ferrari', pointsFinishPct: 88.5, seasonPointsFinishPct: 66.6, wins: 105, podiums2nd: 56, podiums3rd: 40, podiums: 201, poles: 104, fastestLaps: 67, totalPoints: 4895.5, championships: 7, championshipYears: [2008, 2014, 2015, 2017, 2018, 2019, 2020], lapsRaced: 19612, starts: 356, dnfs: 31, dsqs: 1, dnqs: 0, lapsLed: 5455, frontRowStarts: 175, highestFinish: '1e (x105)', highestGrid: '1e (x104)', hatTricks: 19, overtakes: 1200, age: 41, height: '1.74m', birthPlace: 'Stevenage, UK', partner: '-', children: '-', pets: 'Roscoe (Dog)', manager: 'Marc Hynes', realWorldFactsNl: ['Gedeeld record 7 wereldtitels.', 'Meeste Grand Prix overwinningen ooit.'], realWorldFactsEn: ['Shared record 7 World Titles.', 'Most Grand Prix wins in history.'], pointsPerSeason: {2025: 200, 2024: 200, 2023: 234, 2022: 240, 2021: 387.5}, debutYear: 2007, contractUntil: '2026+', previousTeams: ['McLaren (2007-2012)', 'Mercedes (2013-2024)'], personalSponsors: ['Tommy Hilfiger', 'IWC', 'Monster Energy']),
  Driver(name: 'Fernando Alonso', flag: '🇪🇸', points: 0, number: 14, nationality: 'Spanish', team: 'Aston Martin', pointsFinishPct: 75.3, seasonPointsFinishPct: 45.8, wins: 32, podiums2nd: 40, podiums3rd: 34, podiums: 106, poles: 22, fastestLaps: 24, totalPoints: 2385.0, championships: 2, championshipYears: [2005, 2006], lapsRaced: 20145, starts: 402, dnfs: 75, dsqs: 0, dnqs: 1, lapsLed: 1773, frontRowStarts: 42, highestFinish: '1e (x32)', highestGrid: '1e (x22)', hatTricks: 5, overtakes: 1500, age: 44, height: '1.71m', birthPlace: 'Oviedo, Spain', partner: 'Melissa Jimenez', children: '-', pets: '-', manager: 'Flavio Briatore', realWorldFactsNl: ['Meeste F1 starts ooit.', 'Won Le Mans twee keer.'], realWorldFactsEn: ['Most F1 starts in history.', 'Won Le Mans twice.'], pointsPerSeason: {2025: 150, 2024: 100, 2023: 206, 2022: 81, 2021: 81}, debutYear: 2001, contractUntil: '2026', previousTeams: ['Minardi (2001)', 'Renault (2003-2006, 2008-2009)', 'McLaren (2007, 2015-2018)', 'Ferrari (2010-2014)', 'Alpine (2021-2022)'], personalSponsors: ['Kimoa', 'Finetwork', 'Citi']),
  Driver(name: 'Lando Norris', flag: '🇬🇧', points: 0, number: 4, nationality: 'British', team: 'McLaren', pointsFinishPct: 83.5, seasonPointsFinishPct: 91.6, wins: 3, podiums2nd: 10, podiums3rd: 7, podiums: 25, poles: 8, fastestLaps: 9, totalPoints: 1056.0, championships: 0, championshipYears: [], lapsRaced: 6241, starts: 128, dnfs: 9, dsqs: 0, dnqs: 0, lapsLed: 642, frontRowStarts: 16, highestFinish: '1e (x3)', highestGrid: '1e (x8)', hatTricks: 2, overtakes: 400, age: 26, height: '1.70m', birthPlace: 'Bristol, UK', partner: '-', children: '-', pets: '-', manager: 'Mark Berryman', realWorldFactsNl: ['Won Miami GP 2024.', 'Oprichter gaming merk Quadrant.'], realWorldFactsEn: ['Won Miami GP 2024.', 'Founder of gaming brand Quadrant.'], pointsPerSeason: {2025: 350, 2024: 300, 2023: 205, 2022: 122, 2021: 160}, debutYear: 2019, contractUntil: '2027+', previousTeams: [], personalSponsors: ['Quadrant', 'TUMI', 'GoPuff']),
  Driver(name: 'Charles Leclerc', flag: '🇲🇨', points: 0, number: 16, nationality: 'Monegasque', team: 'Ferrari', pointsFinishPct: 72.8, seasonPointsFinishPct: 79.1, wins: 8, podiums2nd: 15, podiums3rd: 20, podiums: 43, poles: 27, fastestLaps: 10, totalPoints: 1420.0, championships: 0, championshipYears: [], lapsRaced: 8432, starts: 148, dnfs: 22, dsqs: 1, dnqs: 0, lapsLed: 890, frontRowStarts: 35, highestFinish: '1e (x8)', highestGrid: '1e (x27)', hatTricks: 3, overtakes: 550, age: 28, height: '1.80m', birthPlace: 'Monte Carlo, Monaco', partner: 'Alexandra Saint Mleux', children: '-', pets: 'Leo (Dog)', manager: 'Nicholas Todt', realWorldFactsNl: ['Won thuisrace Monaco in 2024.', 'Zeer sterk in kwalificaties.'], realWorldFactsEn: ['Won home race Monaco in 2024.', 'Very strong in qualifying.'], pointsPerSeason: {2025: 300, 2024: 280, 2023: 206, 2022: 308, 2021: 159}, debutYear: 2018, contractUntil: '2029', previousTeams: ['Sauber (2018)'], personalSponsors: ['Richard Mille', 'Giorgio Armani']),
  Driver(name: 'George Russell', flag: '🇬🇧', points: 0, number: 63, nationality: 'British', team: 'Mercedes', pointsFinishPct: 65.4, seasonPointsFinishPct: 83.3, wins: 2, podiums2nd: 5, podiums3rd: 10, podiums: 19, poles: 4, fastestLaps: 8, totalPoints: 788.0, championships: 0, championshipYears: [], lapsRaced: 7512, starts: 128, dnfs: 18, dsqs: 1, dnqs: 0, lapsLed: 210, frontRowStarts: 10, highestFinish: '1e (x2)', highestGrid: '1e (x4)', hatTricks: 0, overtakes: 350, age: 28, height: '1.85m', birthPlace: 'King\'s Lynn, UK', partner: 'Carmen Montero Mundt', children: '-', pets: '-', manager: 'Harry Soden', realWorldFactsNl: ['Bijnaam "Mr. Saturday".', 'Directeur van de GPDA.'], realWorldFactsEn: ['Nickname "Mr. Saturday".', 'Director of the GPDA.'], pointsPerSeason: {2025: 250, 2024: 200, 2023: 175, 2022: 275, 2021: 16}, debutYear: 2019, contractUntil: '2025', previousTeams: ['Williams (2019-2021)'], personalSponsors: ['Puma', 'Alpinestars']),
  Driver(name: 'Carlos Sainz', flag: '🇪🇸', points: 0, number: 55, nationality: 'Spanish', team: 'Williams', pointsFinishPct: 70.1, seasonPointsFinishPct: 75.0, wins: 4, podiums2nd: 8, podiums3rd: 13, podiums: 25, poles: 6, fastestLaps: 4, totalPoints: 1286.5, championships: 0, championshipYears: [], lapsRaced: 11214, starts: 207, dnfs: 25, dsqs: 0, dnqs: 0, lapsLed: 245, frontRowStarts: 12, highestFinish: '1e (x4)', highestGrid: '1e (x6)', hatTricks: 0, overtakes: 600, age: 31, height: '1.78m', birthPlace: 'Madrid, Spain', partner: 'Rebecca Donaldson', children: '-', pets: 'Piñón (Dog)', manager: 'Carlos Sainz Sr.', realWorldFactsNl: ['Zoon van Rally kampioen Sainz Sr.', 'Won Australië na blinde darm operatie.'], realWorldFactsEn: ['Son of Rally champ Sainz Sr.', 'Won Australia after appendicitis.'], pointsPerSeason: {2025: 180, 2024: 200, 2023: 200, 2022: 246, 2021: 164.5}, debutYear: 2015, contractUntil: '2028', previousTeams: ['Toro Rosso (2015-2017)', 'Renault (2017-2018)', 'McLaren (2019-2020)', 'Ferrari (2021-2024)'], personalSponsors: ['Estrella Galicia 0,0', 'Shiseido']),
  Driver(name: 'Oscar Piastri', flag: '🇦🇺', points: 0, number: 81, nationality: 'Australian', team: 'McLaren', pointsFinishPct: 75.0, seasonPointsFinishPct: 87.5, wins: 2, podiums2nd: 8, podiums3rd: 5, podiums: 18, poles: 4, fastestLaps: 6, totalPoints: 607.0, championships: 0, championshipYears: [], lapsRaced: 2415, starts: 46, dnfs: 4, dsqs: 0, dnqs: 0, lapsLed: 154, frontRowStarts: 8, highestFinish: '1e (x2)', highestGrid: '1e (x4)', hatTricks: 0, overtakes: 200, age: 24, height: '1.78m', birthPlace: 'Melbourne, Australia', partner: 'Lily Zneimer', children: '-', pets: '-', manager: 'Mark Webber', realWorldFactsNl: ['Won Formule Renault, F3 en F2 back-to-back.', 'Gemanaged door Mark Webber.'], realWorldFactsEn: ['Won Formula Renault, F3 and F2 back-to-back.', 'Managed by Mark Webber.'], pointsPerSeason: {2025: 280, 2024: 250, 2023: 97, 2022: 0, 2021: 0}, debutYear: 2023, contractUntil: '2026', previousTeams: [], personalSponsors: ['HP', 'GoPro']),
  Driver(name: 'Nico Hülkenberg', flag: '🇩🇪', points: 0, number: 27, nationality: 'German', team: 'Audi', pointsFinishPct: 48.0, seasonPointsFinishPct: 41.6, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 1, fastestLaps: 2, totalPoints: 581.0, championships: 0, championshipYears: [], lapsRaced: 13541, starts: 228, dnfs: 42, dsqs: 0, dnqs: 0, lapsLed: 43, frontRowStarts: 2, highestFinish: '4e (x3)', highestGrid: '1e (x1)', hatTricks: 0, overtakes: 700, age: 38, height: '1.84m', birthPlace: 'Emmerich, Germany', partner: 'Egle Ruskyte', children: 'Noemi Sky', pets: 'Zeus (Dog)', manager: 'Raoul Spanger', realWorldFactsNl: ['Meeste F1 starts zonder podium.', 'Won Le Mans in 2015.'], realWorldFactsEn: ['Most F1 starts without a podium.', 'Won Le Mans in 2015.'], pointsPerSeason: {2025: 50, 2024: 40, 2023: 9, 2022: 0, 2021: 0}, debutYear: 2010, contractUntil: '2026', previousTeams: ['Williams (2010)', 'Force India (2011-2012, 2014-2016)', 'Sauber (2013)', 'Renault (2017-2019)', 'Racing Point (2020)', 'Aston Martin (2022)', 'Haas (2023-2024)'], personalSponsors: ['Dekra', 'Ravenol']),
  Driver(name: 'Esteban Ocon', flag: '🇫🇷', points: 0, number: 31, nationality: 'French', team: 'Haas F1 Team', pointsFinishPct: 52.0, seasonPointsFinishPct: 25.0, wins: 1, podiums2nd: 2, podiums3rd: 1, podiums: 4, poles: 0, fastestLaps: 0, totalPoints: 460.0, championships: 0, championshipYears: [], lapsRaced: 8742, starts: 157, dnfs: 28, dsqs: 1, dnqs: 0, lapsLed: 66, frontRowStarts: 0, highestFinish: '1e (x1)', highestGrid: '3e (x2)', hatTricks: 0, overtakes: 450, age: 29, height: '1.86m', birthPlace: 'Évreux, France', partner: 'Flavy Barla', children: '-', pets: '-', manager: 'Gwen Lagrue', realWorldFactsNl: ['Won Hongarije 2021.', 'Groeide op in een caravan.'], realWorldFactsEn: ['Won Hungary 2021.', 'Grew up living in a caravan.'], pointsPerSeason: {2025: 40, 2024: 30, 2023: 58, 2022: 92, 2021: 74}, debutYear: 2016, contractUntil: '2026', previousTeams: ['Manor (2016)', 'Force India (2017-2018)', 'Racing Point (2018)', 'Renault (2020)', 'Alpine (2021-2024)'], personalSponsors: ['Castrol', 'Mapfre']),
  Driver(name: 'Pierre Gasly', flag: '🇫🇷', points: 0, number: 10, nationality: 'French', team: 'Alpine', pointsFinishPct: 54.0, seasonPointsFinishPct: 16.6, wins: 1, podiums2nd: 1, podiums3rd: 2, podiums: 4, poles: 0, fastestLaps: 3, totalPoints: 416.0, championships: 0, championshipYears: [], lapsRaced: 8641, starts: 154, dnfs: 24, dsqs: 1, dnqs: 0, lapsLed: 26, frontRowStarts: 1, highestFinish: '1e (x1)', highestGrid: '2e (x1)', hatTricks: 0, overtakes: 480, age: 30, height: '1.77m', birthPlace: 'Rouen, France', partner: 'Kika Cerqueira Gomes', children: '-', pets: '-', manager: 'Guillaume Le Goff', realWorldFactsNl: ['Won spectaculair op Monza 2020.', 'Zeer veerkrachtig na demotie.'], realWorldFactsEn: ['Won spectacular at Monza 2020.', 'Very resilient after demotion.'], pointsPerSeason: {2025: 45, 2024: 35, 2023: 62, 2022: 23, 2021: 110}, debutYear: 2017, contractUntil: '2026+', previousTeams: ['Toro Rosso (2017-2018)', 'Red Bull Racing (2019)', 'AlphaTauri (2019-2022)'], personalSponsors: ['AlphaTauri', 'Red Bull']),
  Driver(name: 'Alexander Albon', flag: '🇹🇭', points: 0, number: 23, nationality: 'Thai', team: 'Williams', pointsFinishPct: 45.2, seasonPointsFinishPct: 54.1, wins: 0, podiums2nd: 0, podiums3rd: 2, podiums: 2, poles: 0, fastestLaps: 0, totalPoints: 315.0, championships: 0, championshipYears: [], lapsRaced: 6102, starts: 105, dnfs: 14, dsqs: 0, dnqs: 0, lapsLed: 1, frontRowStarts: 0, highestFinish: '3e (x2)', highestGrid: '4e (x1)', hatTricks: 0, overtakes: 300, age: 30, height: '1.86m', birthPlace: 'London, UK', partner: 'Lily Muni', children: '-', pets: 'Albon Pets', manager: 'Grau Private Management', realWorldFactsNl: ['Staat bekend als banden-fluisteraar.', 'Kwam knap terug na jaar afwezigheid.'], realWorldFactsEn: ['Known as the tire whisperer.', 'Strong comeback after a year off.'], pointsPerSeason: {2025: 60, 2024: 40, 2023: 27, 2022: 4, 2021: 0}, debutYear: 2019, contractUntil: '2027', previousTeams: ['Toro Rosso (2019)', 'Red Bull Racing (2019-2020)'], personalSponsors: ['Red Bull', 'Moose']),
  Driver(name: 'Lance Stroll', flag: '🇨🇦', points: 0, number: 18, nationality: 'Canadian', team: 'Aston Martin', pointsFinishPct: 42.0, seasonPointsFinishPct: 20.8, wins: 0, podiums2nd: 0, podiums3rd: 3, podiums: 3, poles: 1, fastestLaps: 0, totalPoints: 311.0, championships: 0, championshipYears: [], lapsRaced: 9145, starts: 167, dnfs: 32, dsqs: 0, dnqs: 0, lapsLed: 32, frontRowStarts: 1, highestFinish: '3e (x3)', highestGrid: '1e (x1)', hatTricks: 0, overtakes: 350, age: 27, height: '1.82m', birthPlace: 'Montreal, Canada', partner: 'Marilou Bélanger', children: '-', pets: '-', manager: 'Steve Robertson', realWorldFactsNl: ['Reed race met gebroken polsen.', 'Pole in natte Turkije 2020.'], realWorldFactsEn: ['Raced with broken wrists.', 'Pole in wet Turkey 2020.'], pointsPerSeason: {2025: 40, 2024: 30, 2023: 74, 2022: 18, 2021: 34}, debutYear: 2017, contractUntil: 'Rolling', previousTeams: ['Williams (2017-2018)', 'Racing Point (2019-2020)'], personalSponsors: ['Bombardier', 'Tag Heuer']),
  Driver(name: 'Yuki Tsunoda', flag: '🇯🇵', points: 0, number: 22, nationality: 'Japanese', team: 'Racing Bulls', pointsFinishPct: 38.0, seasonPointsFinishPct: 33.3, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 1, totalPoints: 94.0, championships: 0, championshipYears: [], lapsRaced: 5214, starts: 90, dnfs: 14, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '4e (x1)', highestGrid: '6e (x1)', hatTricks: 0, overtakes: 250, age: 25, height: '1.59m', birthPlace: 'Sagamihara, Japan', partner: '-', children: '-', pets: '-', manager: 'Mario Miyakawa', realWorldFactsNl: ['Bekend om boordradio uitbarstingen.', 'Zwaar gesteund door Honda.'], realWorldFactsEn: ['Known for radio outbursts.', 'Heavily backed by Honda.'], pointsPerSeason: {2025: 30, 2024: 25, 2023: 17, 2022: 12, 2021: 32}, debutYear: 2021, contractUntil: '2026', previousTeams: ['AlphaTauri (2021-2023)'], personalSponsors: ['Honda', 'Arai']),
  Driver(name: 'Kimi Antonelli', flag: '🇮🇹', points: 0, number: 12, nationality: 'Italian', team: 'Mercedes', pointsFinishPct: 60.0, seasonPointsFinishPct: 60.0, wins: 0, podiums2nd: 1, podiums3rd: 2, podiums: 3, poles: 0, fastestLaps: 1, totalPoints: 150.0, championships: 0, championshipYears: [], lapsRaced: 1244, starts: 24, dnfs: 3, dsqs: 0, dnqs: 0, lapsLed: 12, frontRowStarts: 1, highestFinish: '2e (x1)', highestGrid: '2e (x1)', hatTricks: 0, overtakes: 20, age: 19, height: '1.72m', birthPlace: 'Bologna, Italy', partner: '-', children: '-', pets: '-', manager: 'Toto Wolff', realWorldFactsNl: ['Sloeg F3 over voor F2.', 'Gezien als Hamiltons opvolger.'], realWorldFactsEn: ['Skipped F3 for F2.', 'Seen as Hamiltons successor.'], pointsPerSeason: {2025: 150, 2024: 0, 2023: 0, 2022: 0, 2021: 0}, debutYear: 2025, contractUntil: '2026+', previousTeams: [], personalSponsors: ['Petronas', 'Puma']),
  Driver(name: 'Liam Lawson', flag: '🇳🇿', points: 0, number: 30, nationality: 'New Zealander', team: 'Racing Bulls', pointsFinishPct: 30.0, seasonPointsFinishPct: 29.1, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 40.0, championships: 0, championshipYears: [], lapsRaced: 1453, starts: 29, dnfs: 2, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '9e (x1)', highestGrid: '10e (x1)', hatTricks: 0, overtakes: 30, age: 24, height: '1.74m', birthPlace: 'Hastings, New Zealand', partner: 'Charlotte Miller', children: '-', pets: '-', manager: 'Red Bull', realWorldFactsNl: ['IJzersterke invaller in 2023.', 'Miste nipt de Super Formula titel.'], realWorldFactsEn: ['Very strong substitute in 2023.', 'Narrowly missed Super Formula title.'], pointsPerSeason: {2025: 30, 2024: 0, 2023: 2, 2022: 0, 2021: 0}, debutYear: 2023, contractUntil: '2026', previousTeams: ['AlphaTauri (2023)'], personalSponsors: ['Red Bull', 'Rodin Cars']),
  Driver(name: 'Oliver Bearman', flag: '🇬🇧', points: 0, number: 87, nationality: 'British', team: 'Haas F1 Team', pointsFinishPct: 40.0, seasonPointsFinishPct: 40.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 47.0, championships: 0, championshipYears: [], lapsRaced: 1289, starts: 25, dnfs: 3, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '7e (x2)', highestGrid: '8e (x1)', hatTricks: 0, overtakes: 25, age: 20, height: '1.84m', birthPlace: 'Chelmsford, UK', partner: 'Estelle Ogilvy', children: '-', pets: '-', manager: 'Harry Soden', realWorldFactsNl: ['Scoorde direct in F1 debuut op 18-jarige leeftijd.', 'Deel van de Ferrari Driver Academy.'], realWorldFactsEn: ['Scored immediately in F1 debut at 18.', 'Part of the Ferrari Driver Academy.'], pointsPerSeason: {2025: 40, 2024: 7, 2023: 0, 2022: 0, 2021: 0}, debutYear: 2024, contractUntil: '2026', previousTeams: ['Ferrari (2024)'], personalSponsors: ['Richard Mille']),
  Driver(name: 'Gabriel Bortoleto', flag: '🇧🇷', points: 0, number: 5, nationality: 'Brazilian', team: 'Audi', pointsFinishPct: 15.0, seasonPointsFinishPct: 15.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 19.0, championships: 0, championshipYears: [], lapsRaced: 1012, starts: 24, dnfs: 4, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '8e (x1)', highestGrid: '11e (x1)', hatTricks: 0, overtakes: 15, age: 21, height: '1.80m', birthPlace: 'São Paulo, Brazil', partner: '-', children: '-', pets: '-', manager: 'Fernando Alonso', realWorldFactsNl: ['Won FIA F3 als rookie.', 'Gemanaged door Fernando Alonso.'], realWorldFactsEn: ['Won FIA F3 as rookie.', 'Managed by Fernando Alonso.'], pointsPerSeason: {2025: 19, 2024: 0, 2023: 0, 2022: 0, 2021: 0}, debutYear: 2025, contractUntil: '2026', previousTeams: [], personalSponsors: ['A14 Management']),
  Driver(name: 'Isack Hadjar', flag: '🇫🇷', points: 0, number: 6, nationality: 'French', team: 'Red Bull Racing', pointsFinishPct: 35.0, seasonPointsFinishPct: 35.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 51.0, championships: 0, championshipYears: [], lapsRaced: 1152, starts: 24, dnfs: 2, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '6e (x1)', highestGrid: '7e (x1)', hatTricks: 0, overtakes: 10, age: 21, height: '1.75m', birthPlace: 'Paris, France', partner: '-', children: '-', pets: '-', manager: 'Red Bull', realWorldFactsNl: ['Bijnaam "De kleine Prost".', 'Franse en Algerijnse roots.'], realWorldFactsEn: ['Nickname "The little Prost".', 'French and Algerian roots.'], pointsPerSeason: {2025: 51, 2024: 0, 2023: 0, 2022: 0, 2021: 0}, debutYear: 2025, contractUntil: '2026', previousTeams: [], personalSponsors: ['Red Bull']),
  Driver(name: 'Franco Colapinto', flag: '🇦🇷', points: 0, number: 43, nationality: 'Argentine', team: 'Alpine', pointsFinishPct: 0.0, seasonPointsFinishPct: 0.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0.0, championships: 0, championshipYears: [], lapsRaced: 923, starts: 18, dnfs: 2, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '12e (x1)', highestGrid: '12e (x1)', hatTricks: 0, overtakes: 10, age: 22, height: '1.76m', birthPlace: 'Buenos Aires, Argentina', partner: '-', children: '-', pets: '-', manager: 'Bullet Sports', realWorldFactsNl: ['Zorgde voor F1 gekte in Argentinië.', 'Enorme fanatieke fanbase.'], realWorldFactsEn: ['Sparked F1 mania in Argentina.', 'Huge fanatic fanbase.'], pointsPerSeason: {2025: 0, 2024: 5, 2023: 0, 2022: 0, 2021: 0}, debutYear: 2024, contractUntil: '2026', previousTeams: ['Williams (2024)'], personalSponsors: ['Visit Argentina', 'YPF']),
  Driver(name: 'Arvid Lindblad', flag: '🇬🇧', points: 0, number: 41, nationality: 'British', team: 'Racing Bulls', pointsFinishPct: 0.0, seasonPointsFinishPct: 0.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0.0, championships: 0, championshipYears: [], lapsRaced: 0, starts: 0, dnfs: 0, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: 'N.v.t.', highestGrid: 'N.v.t.', hatTricks: 0, overtakes: 0, age: 18, height: '1.70m', birthPlace: 'London, UK', partner: '-', children: '-', pets: '-', manager: 'Red Bull', realWorldFactsNl: ['Groot talent Red Bull Academy.', 'Jongste coureur nieuwe generatie.'], realWorldFactsEn: ['Top talent Red Bull Academy.', 'Youngest driver new generation.'], pointsPerSeason: {2025: 0, 2024: 0, 2023: 0, 2022: 0, 2021: 0}, debutYear: 2026, contractUntil: '2026', previousTeams: [], personalSponsors: ['Red Bull']),
  Driver(name: 'Sergio Pérez', flag: '🇲🇽', points: 0, number: 11, nationality: 'Mexican', team: 'Cadillac', pointsFinishPct: 65.0, seasonPointsFinishPct: 50.0, wins: 6, podiums2nd: 15, podiums3rd: 18, podiums: 39, poles: 3, fastestLaps: 12, totalPoints: 1637.0, championships: 0, championshipYears: [], lapsRaced: 15123, starts: 280, dnfs: 31, dsqs: 0, dnqs: 0, lapsLed: 400, frontRowStarts: 10, highestFinish: '1e (x6)', highestGrid: '1e (x3)', hatTricks: 0, overtakes: 950, age: 36, height: '1.73m', birthPlace: 'Guadalajara, Mexico', partner: 'Carola Martinez', children: 'Sergio Jr., Carlota, Emilio', pets: '-', manager: 'Julian Jakobi', realWorldFactsNl: ['Minister of Defence.', 'Meester op stratencircuits.'], realWorldFactsEn: ['Minister of Defence.', 'Master of street circuits.'], pointsPerSeason: {2025: 150, 2024: 150, 2023: 285, 2022: 305, 2021: 190}, debutYear: 2011, contractUntil: '2026', previousTeams: ['Sauber (2011-2012)', 'McLaren (2013)', 'Force India (2014-2018)', 'Racing Point (2018-2020)', 'Red Bull Racing (2021-2024)'], personalSponsors: ['Telmex', 'Claro']),
  Driver(name: 'Valtteri Bottas', flag: '🇫🇮', points: 0, number: 77, nationality: 'Finnish', team: 'Cadillac', pointsFinishPct: 70.0, seasonPointsFinishPct: 15.0, wins: 10, podiums2nd: 30, podiums3rd: 27, podiums: 67, poles: 20, fastestLaps: 19, totalPoints: 1797.0, championships: 0, championshipYears: [], lapsRaced: 13500, starts: 250, dnfs: 25, dsqs: 0, dnqs: 0, lapsLed: 650, frontRowStarts: 45, highestFinish: '1e (x10)', highestGrid: '1e (x20)', hatTricks: 2, overtakes: 900, age: 36, height: '1.73m', birthPlace: 'Nastola, Finland', partner: 'Tiffany Cromwell', children: '-', pets: '-', manager: 'Didier Coton', realWorldFactsNl: ['Vijf constructeurstitels met Mercedes.', 'Brengt humor en ervaring naar Cadillac.'], realWorldFactsEn: ['Five constructors titles with Mercedes.', 'Brings humor and experience to Cadillac.'], pointsPerSeason: {2025: 50, 2024: 0, 2023: 10, 2022: 49, 2021: 226}, debutYear: 2013, contractUntil: '2026', previousTeams: ['Williams (2013-2016)', 'Mercedes (2017-2021)', 'Alfa Romeo (2022-2023)', 'Kick Sauber (2024-2025)'], personalSponsors: ['Wihuri', 'Abloy']),
];

final Map<int, List<Driver>> driversData = {
  2026: drivers2026,
};

final List<Team> fallbackTeams = [
  Team(name: 'McLaren', flag: '🇬🇧', points: 0, engine: 'Mercedes', fastestPitstopTime: '1.80s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Qatar', ccWins: 9, dcWins: 13, ccYears: [1974, 1984, 1985, 1988, 1989, 1990, 1991, 1998, 2024], dcList: ['Lewis Hamilton (2008)', 'Mika Häkkinen (1998, 1999)', 'Ayrton Senna (1988, 1990, 1991)', 'Alain Prost (1985, 1986, 1989)', 'Niki Lauda (1984)', 'James Hunt (1976)', 'Emerson Fittipaldi (1974)'], podiums: 520, oneTwo: 49, hattricks: 28, doublePodiums: 110, totalPoints: 7200.5, frontRow: 145, poles: 165, fastestLaps: 170, racesLed: 380, principalName: 'Andrea Stella', principalAge: 54, principalFlag: '🇮🇹', totalEntries: 967, technicalDirectorName: 'Rob Marshall', technicalDirectorAge: 58, engineSupplier: engineSuppliers['Mercedes']!, sponsors: ['Google Chrome', 'Dell', 'Android', 'Coca-Cola'], headquarters: 'Woking, UK', previousNames: [], drivers: ['Lando Norris (2019-2027+ Current)', 'Oscar Piastri (2023-2026 Current)', 'Daniel Ricciardo (2021-2022)', 'Carlos Sainz (2019-2020)', 'Fernando Alonso (2015-2018)', 'Stoffel Vandoorne (2017-2018)', 'Jenson Button (2010-2017)', 'Pato O\'Ward (Reserve 2024-2025)', 'Ryo Hirakawa (Reserve 2024-2025)', 'Alex Palou (Reserve 2023)', 'Mick Schumacher (Reserve 2023)', 'Felipe Drugovich (Reserve 2023)', 'Nyck de Vries (Reserve 2021-2022)', 'Stoffel Vandoorne (Reserve 2020-2022)', 'Sergey Sirotkin (Reserve 2019-2020)', 'Lando Norris (Reserve 2018)', 'Jenson Button (Reserve 2017)', 'Nobuharu Matsushita (Test 2017)', 'Stoffel Vandoorne (Reserve 2016)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/mclaren/2026mclarencarright.webp'),
  Team(name: 'Mercedes', flag: '🇩🇪', points: 0, engine: 'Mercedes', fastestPitstopTime: '1.98s', fastestPitstopYear: 2022, fastestPitstopCircuit: 'Mexico', ccWins: 8, dcWins: 9, ccYears: [2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021], dcList: ['Lewis Hamilton (2014, 2015, 2017, 2018, 2019, 2020)', 'Nico Rosberg (2016)', 'Juan Manuel Fangio (1954, 1955)'], podiums: 295, oneTwo: 59, hattricks: 30, doublePodiums: 125, totalPoints: 7500.5, frontRow: 160, poles: 139, fastestLaps: 107, racesLed: 240, principalName: 'Toto Wolff', principalAge: 53, principalFlag: '🇦🇹', totalEntries: 314, technicalDirectorName: 'James Allison', technicalDirectorAge: 58, engineSupplier: engineSuppliers['Mercedes']!, sponsors: ['Petronas', 'Ineos', 'CrowdStrike', 'TeamViewer'], headquarters: 'Brackley, UK', previousNames: ['Brawn GP (2009)', 'Honda (2006-2008)', 'BAR (1999-2005)', 'Tyrrell (1970-1998)'], drivers: ['George Russell (2022-2025 Current)', 'Kimi Antonelli (2025-2026+ Current)', 'Lewis Hamilton (2013-2024)', 'Valtteri Bottas (2017-2021)', 'Nico Rosberg (2010-2016)', 'Mick Schumacher (Reserve 2023-2025)', 'Frederik Vesti (Reserve 2024-2025)', 'Nyck de Vries (Reserve 2021-2022)', 'Stoffel Vandoorne (Reserve 2020-2022)', 'Esteban Gutierrez (Reserve 2020)', 'Esteban Ocon (Reserve 2019)', 'Pascal Wehrlein (Reserve 2016, 2018)', 'George Russell (Reserve 2017-2018)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/mercedes/2026mercedescarright.webp'),
  Team(name: 'Red Bull Racing', flag: '🇦🇹', points: 0, engine: 'Red Bull Ford', fastestPitstopTime: '1.82s', fastestPitstopYear: 2019, fastestPitstopCircuit: 'Brazil', ccWins: 6, dcWins: 7, ccYears: [2010, 2011, 2012, 2013, 2022, 2023], dcList: ['Max Verstappen (2021, 2022, 2023, 2024)', 'Sebastian Vettel (2010, 2011, 2012, 2013)'], podiums: 280, oneTwo: 32, hattricks: 25, doublePodiums: 85, totalPoints: 7400.0, frontRow: 130, poles: 102, fastestLaps: 98, racesLed: 210, principalName: 'Christian Horner', principalAge: 51, principalFlag: '🇬🇧', totalEntries: 390, technicalDirectorName: 'Pierre Waché', technicalDirectorAge: 51, engineSupplier: engineSuppliers['Red Bull Ford']!, sponsors: ['Oracle', 'Rauch', 'Puma', 'Tag Heuer'], headquarters: 'Milton Keynes, UK', previousNames: ['Jaguar Racing (2000-2004)', 'Stewart Grand Prix (1997-1999)'], drivers: ['Max Verstappen (2016-2028 Current)', 'Isack Hadjar (2025-2026 Current)', 'Sergio Pérez (2021-2024)', 'Alexander Albon (2019-2020)', 'Pierre Gasly (2019)', 'Daniel Ricciardo (2014-2018)', 'Liam Lawson (Reserve 2022-2025)', 'Daniel Ricciardo (Reserve 2023)', 'Juri Vips (Reserve 2022)', 'Alexander Albon (Reserve 2021)', 'Sebastien Buemi (Reserve 2018-2020)', 'Sergio Sette Camara (Reserve 2020)', 'Pierre Gasly (Reserve 2016-2017)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/redbullracing/2026redbullracingcarright.webp'),
  Team(name: 'Ferrari', flag: '🇮🇹', points: 0, engine: 'Ferrari', fastestPitstopTime: '1.93s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Qatar', ccWins: 16, dcWins: 15, ccYears: [1961, 1964, 1975, 1976, 1977, 1979, 1982, 1983, 1999, 2000, 2001, 2002, 2003, 2004, 2007, 2008], dcList: ['Kimi Räikkönen (2007)', 'Michael Schumacher (2000, 2001, 2002, 2003, 2004)', 'Jody Scheckter (1979)', 'Niki Lauda (1975, 1977)', 'John Surtees (1964)', 'Phil Hill (1961)', 'Mike Hawthorn (1958)', 'Juan Manuel Fangio (1956)', 'Alberto Ascari (1952, 1953)'], podiums: 810, oneTwo: 85, hattricks: 42, doublePodiums: 180, totalPoints: 10250.0, frontRow: 260, poles: 251, fastestLaps: 261, racesLed: 520, principalName: 'Frédéric Vasseur', principalAge: 56, principalFlag: '🇫🇷', totalEntries: 1095, technicalDirectorName: 'Loic Serra', technicalDirectorAge: 53, engineSupplier: engineSuppliers['Ferrari']!, sponsors: ['Shell', 'Santander', 'Ray-Ban', 'Puma'], headquarters: 'Maranello, IT', previousNames: [], drivers: ['Charles Leclerc (2019-2029 Current)', 'Lewis Hamilton (2025-2026+ Current)', 'Carlos Sainz (2021-2024)', 'Sebastian Vettel (2015-2020)', 'Kimi Räikkönen (2014-2018)', 'Oliver Bearman (Reserve 2024-2025)', 'Antonio Giovinazzi (Reserve 2017-2018, 2022-2025)', 'Robert Shwartzman (Reserve 2023-2024)', 'Mick Schumacher (Reserve 2022)', 'Callum Ilott (Reserve 2021)', 'Pascal Wehrlein (Reserve 2019-2020)', 'Brendon Hartley (Reserve 2019)', 'Daniil Kvyat (Reserve 2018)', 'Jean-Eric Vergne (Reserve 2016)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/ferrari/2026ferraricarright.webp'),
  Team(name: 'Williams', flag: '🇬🇧', points: 0, engine: 'Mercedes', fastestPitstopTime: '1.92s', fastestPitstopYear: 2016, fastestPitstopCircuit: 'Azerbaijan', ccWins: 9, dcWins: 7, ccYears: [1980, 1981, 1986, 1987, 1992, 1993, 1994, 1996, 1997], dcList: ['Jacques Villeneuve (1997)', 'Damon Hill (1996)', 'Alain Prost (1993)', 'Nigel Mansell (1992)', 'Nelson Piquet (1987)', 'Keke Rosberg (1982)', 'Alan Jones (1980)'], podiums: 313, oneTwo: 33, hattricks: 18, doublePodiums: 65, totalPoints: 3620.0, frontRow: 120, poles: 128, fastestLaps: 133, racesLed: 180, principalName: 'James Vowles', principalAge: 55, principalFlag: '🇬🇧', totalEntries: 826, technicalDirectorName: 'Pat Fry', technicalDirectorAge: 62, engineSupplier: engineSuppliers['Mercedes']!, sponsors: ['Duracell', 'Komatsu', 'Gulf'], headquarters: 'Grove, UK', previousNames: [], drivers: ['Alexander Albon (2022-2027 Current)', 'Carlos Sainz (2025-2026 Current)', 'Franco Colapinto (2024)', 'Logan Sargeant (2023-2024)', 'Nicholas Latifi (2020-2022)', 'George Russell (2019-2021)', 'Robert Kubica (2019)', 'Sergey Sirotkin (2018)', 'Lance Stroll (2017-2018)', 'Felipe Massa (2014-2017)', 'Zak O\'Sullivan (Reserve 2025)', 'Franco Colapinto (Reserve 2024)', 'Mick Schumacher (Reserve 2023)', 'Logan Sargeant (Reserve 2022)', 'Nyck de Vries (Reserve 2022)', 'Jack Aitken (Reserve 2020-2021)', 'Nicholas Latifi (Reserve 2019)', 'Robert Kubica (Reserve 2018)', 'Paul di Resta (Reserve 2016-2017)', 'Gary Paffett (Reserve 2016)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/williams/2026williamscarright.webp'),
  Team(name: 'Racing Bulls', flag: '🇮🇹', points: 0, engine: 'Red Bull Ford', fastestPitstopTime: '2.10s', fastestPitstopYear: 2024, fastestPitstopCircuit: 'Bahrain', ccWins: 0, dcWins: 0, ccYears: [], dcList: [], podiums: 3, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 310.0, frontRow: 1, poles: 0, fastestLaps: 2, racesLed: 1, principalName: 'Laurent Mekies', principalAge: 47, principalFlag: '🇫🇷', totalEntries: 368, technicalDirectorName: 'Jody Egginton', technicalDirectorAge: 52, engineSupplier: engineSuppliers['Red Bull Ford']!, sponsors: ['Visa', 'Cash App', 'Hugo Boss'], headquarters: 'Faenza, IT', previousNames: ['AlphaTauri (2020-2023)', 'Toro Rosso (2006-2019)', 'Minardi (1985-2005)'], drivers: ['Yuki Tsunoda (2021-2026 Current)', 'Arvid Lindblad (2026-2026 Current)', 'Liam Lawson (2023-2025)', 'Daniel Ricciardo (2023-2024)', 'Nyck de Vries (2023)', 'Pierre Gasly (2017-2022)', 'Daniil Kvyat (2014-2020)', 'Brendon Hartley (2017-2018)', 'Carlos Sainz (2015-2017)', 'Ayumu Iwasa (Reserve 2025)', 'Liam Lawson (Reserve 2022-2024)', 'Alexander Albon (Reserve 2021)', 'Sergio Sette Camara (Reserve 2020)', 'Naoki Yamamoto (Reserve 2019)', 'Sean Gelael (Reserve 2018)', 'Pierre Gasly (Reserve 2016-2017)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/racingbulls/2026racingbullscarright.webp'),
  Team(name: 'Aston Martin', flag: '🇬🇧', points: 0, engine: 'Honda', fastestPitstopTime: '2.15s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Spain', ccWins: 0, dcWins: 0, ccYears: [], dcList: [], podiums: 9, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 420.0, frontRow: 2, poles: 1, fastestLaps: 1, racesLed: 3, principalName: 'Mike Krack', principalAge: 52, principalFlag: '🇱🇺', totalEntries: 94, technicalDirectorName: 'Enrico Cardile', technicalDirectorAge: 51, engineSupplier: engineSuppliers['Honda']!, sponsors: ['Aramco', 'Cognizant', 'JCB'], headquarters: 'Silverstone, UK', previousNames: ['Racing Point (2019-2020)', 'Force India (2008-2018)', 'Spyker (2007)', 'Midland (2006)', 'Jordan (1991-2005)'], drivers: ['Fernando Alonso (2023-2026 Current)', 'Lance Stroll (2019-Rolling Current)', 'Sebastian Vettel (2021-2022)', 'Sergio Pérez (2014-2020)', 'Nico Hülkenberg (2014-2022)', 'Esteban Ocon (2017-2018)', 'Felipe Drugovich (Reserve 2023-2025)', 'Stoffel Vandoorne (Reserve 2023-2025)', 'Nico Hülkenberg (Reserve 2021-2022)', 'Esteban Gutierrez (Reserve 2020)', 'Esteban Ocon (Reserve 2019)', 'Nicholas Latifi (Reserve 2018)', 'Alfonso Celis Jr (Reserve 2016-2017)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/astonmartin/2026astonmartincarright.webp'),
  Team(name: 'Haas F1 Team', flag: '🇺🇸', points: 0, engine: 'Ferrari', fastestPitstopTime: '2.25s', fastestPitstopYear: 2022, fastestPitstopCircuit: 'USA', ccWins: 0, dcWins: 0, ccYears: [], dcList: [], podiums: 0, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 315.0, frontRow: 0, poles: 1, fastestLaps: 2, racesLed: 0, principalName: 'Ayao Komatsu', principalAge: 49, principalFlag: '🇯🇵', totalEntries: 188, technicalDirectorName: 'Andrea De Zordo', technicalDirectorAge: 46, engineSupplier: engineSuppliers['Ferrari']!, sponsors: ['MoneyGram', 'Chipotle'], headquarters: 'Kannapolis, USA', previousNames: [], drivers: ['Esteban Ocon (2025-2026 Current)', 'Oliver Bearman (2025-2026 Current)', 'Nico Hülkenberg (2023-2024)', 'Kevin Magnussen (2017-2024)', 'Mick Schumacher (2021-2022)', 'Nikita Mazepin (2021)', 'Romain Grosjean (2016-2020)', 'Esteban Gutiérrez (2016)', 'Pietro Fittipaldi (Reserve 2019-2025)', 'Oliver Bearman (Reserve 2024)', 'Louis Deletraz (Reserve 2019-2020)', 'Arjun Maini (Reserve 2018)', 'Santino Ferrucci (Reserve 2016-2018)', 'Charles Leclerc (Reserve 2016)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/haasf1team/2026haasf1teamcarright.webp'),
  Team(name: 'Audi', flag: '🇩🇪', points: 0, engine: 'Audi', fastestPitstopTime: '2.30s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Monaco', ccWins: 0, dcWins: 0, ccYears: [], dcList: [], podiums: 27, oneTwo: 1, hattricks: 0, doublePodiums: 2, totalPoints: 920.0, frontRow: 5, poles: 1, fastestLaps: 5, racesLed: 10, principalName: 'Mattia Binotto', principalAge: 55, principalFlag: '🇮🇹', totalEntries: 400, technicalDirectorName: 'James Key', technicalDirectorAge: 54, engineSupplier: engineSuppliers['Audi']!, sponsors: ['Stake', 'Kick.com'], headquarters: 'Hinwil, CH', previousNames: ['Kick Sauber (2024-2025)', 'Alfa Romeo (2019-2023)', 'Sauber (1993-2018)'], drivers: ['Nico Hülkenberg (2025-2026 Current)', 'Gabriel Bortoleto (2025-2026 Current)', 'Valtteri Bottas (2022-2024)', 'Zhou Guanyu (2022-2024)', 'Kimi Räikkönen (2019-2021)', 'Antonio Giovinazzi (2017-2021)', 'Charles Leclerc (2018)', 'Marcus Ericsson (2015-2018)', 'Pascal Wehrlein (2017)', 'Felipe Nasr (2015-2016)', 'Théo Pourchaire (Reserve 2023-2025)', 'Zane Maloney (Reserve 2024)', 'Robert Kubica (Reserve 2020-2022)', 'Marcus Ericsson (Reserve 2019)', 'Antonio Giovinazzi (Reserve 2018)', 'Tatiana Calderon (Reserve 2018)', 'Charles Leclerc (Reserve 2017)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/audi/2026audicarright.webp'),
  Team(name: 'Alpine', flag: '🇫🇷', points: 0, engine: 'Mercedes', fastestPitstopTime: '2.18s', fastestPitstopYear: 2024, fastestPitstopCircuit: 'Japan', ccWins: 2, dcWins: 2, ccYears: [2005, 2006], dcList: ['Fernando Alonso (2005, 2006)'], podiums: 105, oneTwo: 2, hattricks: 1, doublePodiums: 5, totalPoints: 2150.0, frontRow: 25, poles: 51, fastestLaps: 33, racesLed: 45, principalName: 'Oliver Oakes', principalAge: 59, principalFlag: '🇬🇧', totalEntries: 90, technicalDirectorName: 'David Sanchez', technicalDirectorAge: 46, engineSupplier: engineSuppliers['Mercedes']!, sponsors: ['BWT', 'Castrol', 'Microsoft'], headquarters: 'Enstone, UK', previousNames: ['Renault (2016-2020)', 'Lotus (2012-2015)', 'Renault (2002-2011)', 'Benetton (1986-2001)', 'Toleman (1981-1985)'], drivers: ['Pierre Gasly (2023-2026+ Current)', 'Franco Colapinto (2026-2026 Current)', 'Jack Doohan (2025)', 'Esteban Ocon (2020-2024)', 'Fernando Alonso (2021-2022)', 'Daniel Ricciardo (2019-2020)', 'Nico Hülkenberg (2017-2019)', 'Carlos Sainz (2017-2018)', 'Jolyon Palmer (2016-2017)', 'Kevin Magnussen (2016)', 'Victor Martins (Reserve 2025)', 'Jack Doohan (Reserve 2023-2024)', 'Oscar Piastri (Reserve 2022)', 'Daniil Kvyat (Reserve 2021)', 'Sergey Sirotkin (Reserve 2017, 2019-2020)', 'Jack Aitken (Reserve 2018)', 'Artem Markelov (Reserve 2018)', 'Esteban Ocon (Reserve 2016)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/alpine/2026alpinecarright.webp'),
  Team(name: 'Cadillac', flag: '🇺🇸', points: 0, engine: 'Ferrari', fastestPitstopTime: '2.40s', fastestPitstopYear: 2026, fastestPitstopCircuit: 'USA', ccWins: 0, dcWins: 0, ccYears: [], dcList: [], podiums: 0, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 0.0, frontRow: 0, poles: 0, fastestLaps: 0, racesLed: 0, principalName: 'Michael Andretti', principalAge: 63, principalFlag: '🇺🇸', totalEntries: 0, technicalDirectorName: 'Mike Elliott', technicalDirectorAge: 52, engineSupplier: engineSuppliers['Ferrari']!, sponsors: ['General Motors', 'Guggenheim'], headquarters: 'Fishers, USA', previousNames: [], drivers: ['Sergio Pérez (2026-2026 Current)', 'Valtteri Bottas (2026-2026 Current)', 'Pato O\'Ward (Reserve 2026)'], carImageUrl: 'https://media.formula1.com/image/upload/c_lfill,w_600/q_auto/d_common:f1:2026:fallback:car:2026fallbackcarright.webp/v1740000000/common/f1/2026/cadillac/2026cadillaccarright.webp?v=2'),
];