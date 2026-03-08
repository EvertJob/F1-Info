import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:http/http.dart' as http;

/// --- INTERNE LOKALISATIE MET EMOJIS -------------------------
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, String> _nlDictionary = {
    'appTitle': '🏎️ F1 Strategie Pro',
    'settings': '⚙️ Instellingen',
    'toggleTheme': '🌗 Wissel Thema',
    'changelog': '📜 Changelog',
    'circuits': '🏁 Circuits',
    'standings': '🏆 Standen',
    'nextRace': '⏭️ Volgende Race',
    'startsIn': 'Start in',
    'week': 'week', 'weeks': 'weken',
    'day': 'dag', 'days': 'dagen',
    'hours': 'uur', 'minutes': 'minuten',
    'drivers': '🏎️ Coureurs', 'teams': '🏢 Teams',
    'pts': 'PNT',
    'using_fallback_data': '⚠️ Offline/Fallback data in gebruik.',
    'session_results': '📊 Sessie Resultaten',
    'fp1': '🏎️ Vrije Training 1', 'fp2': '🏎️ Vrije Training 2', 'fp3': '🏎️ Vrije Training 3',
    'sprint_quali': '⏱️ Sprint Kwalificatie', 'sprint': '🚀 Sprintrace', 'qualifying': '⏱️ Kwalificatie',
    'session_future': '⏳ Sessie begint op', 'no_data_yet': '📭 Data nog niet beschikbaar of API is nog niet geüpdatet',
    'version': '📌 Versie',
    'weather_forecast': '🌤️ Weerverwachting',
    'circuit_info': 'ℹ️ Circuit Info',
    'temp': '🌡️ Temperatuur',
    'rain_chance': '🌧️ Regenkans',
    'wind_speed': '💨 Windsnelheid',
    'humidity': '💧 Luchtvochtigheid',
    'length': '📏 Lengte',
    'since': '📅 Op kalender sinds',
    'until': '🏁 Contract tot',
    'lap_speed_stats': 'RONDE & SNELHEID',
    'risks_incidents': 'RISICO\'S & INCIDENTEN',
    'tyres_strategy': 'BANDEN & STRATEGIE',
    'characteristics': 'CIRCUIT KENMERKEN',
    'totalLength': '📏 Totale Lengte', 'laps': '🔄 Rondes',
    'fastestLap': '⏱️ Snelste Ronde', 'slowestLap': '🐢 Langzaamste Ronde', 'avgLap': '⚖️ Gemiddelde Ronde',
    'topSpeed': '🚀 Topsnelheid', 'averageSpeed': '🏎️ Gemiddelde Snelheid',
    'max_g_force': '🎢 Max G-Kracht', 'risks': '⚠️ Risico\'s',
    'redFlag': '🚩 Kans op Rode Vlag', 'vsc': '🟨 Kans op VSC', 'accident': '💥 Kans op Crash',
    'turn1Accident': '↪️ Kans Crash Bocht 1',
    'tyres': '🛞 Banden', 'tireWear': '📉 Bandenslijtage', 'strategy': '🧠 Strategie', 'bestCombination': '✨ Beste Combinatie',
    'fastestPit': '⚡ Snelste Pitstop',
    'driver_facts_title': '🌟 Feiten & Weetjes', 'general': '👤 Algemeen', 'current_team': '🤝 Huidig Team', 'nationality': '🌍 Nationaliteit',
    'career_stats': '🏆 Carrière Statistieken', 'championships': '👑 Wereldtitels', 'wins': '🥇 Overwinningen', 'podiums': '🍾 Podiums',
    'poles': '🚩 Pole Positions', 'fastest_laps': '🚀 Snelste Rondes', 'total_points': '💯 Totale Punten',
    'driver_history': '📈 Historie (Laatste 5 jaar)',
    'experience': '🏁 Ervaring', 'starts': '🚦 Starts', 'laps_led': '🥇 Rondes aan de leiding', 'dnf': '💥 Uitvalbeurten (DNF)',
    'cc_wins': '🏗️ Constructeurstitels', 'dc_wins': '🏎️ Coureurstitels', 'race_stats': '📈 Race Statistieken',
    'total_entries': '🎟️ Totale Inschrijvingen', 'one_two': '🥈 1-2 Finishes', 'pitstop_leadership': '⚙️ Pitstop & Leiderschap',
    'team_principal': '👔 Teambaas',
    'soft_tire': '🔴 Zacht', 'medium_tire': '🟡 Medium', 'hard_tire': '⚪ Hard',
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
  };

  static final Map<String, String> _enDictionary = {
    'appTitle': '🏎️ F1 Strategy Pro',
    'settings': '⚙️ Settings',
    'toggleTheme': '🌗 Toggle Theme',
    'changelog': '📜 Changelog',
    'circuits': '🏁 Circuits',
    'standings': '🏆 Standings',
    'nextRace': '⏭️ Next Race',
    'startsIn': 'Starts in',
    'week': 'week', 'weeks': 'weeks',
    'day': 'day', 'days': 'days',
    'hours': 'hours', 'minutes': 'minutes',
    'drivers': '🏎️ Drivers', 'teams': '🏢 Teams',
    'pts': 'PTS',
    'using_fallback_data': '⚠️ Using offline/fallback data.',
    'session_results': '📊 Session Results',
    'fp1': '🏎️ Practice 1', 'fp2': '🏎️ Practice 2', 'fp3': '🏎️ Practice 3',
    'sprint_quali': '⏱️ Sprint Qualifying', 'sprint': '🚀 Sprint', 'qualifying': '⏱️ Qualifying',
    'session_future': '⏳ Session begins at', 'no_data_yet': '📭 Data not available yet or API pending update',
    'version': '📌 Version',
    'weather_forecast': '🌤️ Weather Forecast',
    'circuit_info': 'ℹ️ Circuit Info',
    'temp': '🌡️ Temperature',
    'rain_chance': '🌧️ Rain Chance',
    'wind_speed': '💨 Wind Speed',
    'humidity': '💧 Humidity',
    'length': '📏 Length',
    'since': '📅 On calendar since',
    'until': '🏁 Contract until',
    'lap_speed_stats': 'LAP & SPEED STATS',
    'risks_incidents': 'RISKS & INCIDENTS',
    'tyres_strategy': 'TYRES & STRATEGY',
    'characteristics': 'CIRCUIT CHARACTERISTICS',
    'totalLength': '📏 Total Length', 'laps': '🔄 Laps',
    'fastestLap': '⏱️ Fastest Lap', 'slowestLap': '🐢 Slowest Lap', 'avgLap': '⚖️ Average Lap',
    'topSpeed': '🚀 Top Speed', 'averageSpeed': '🏎️ Average Speed',
    'max_g_force': '🎢 Max G-Force', 'risks': '⚠️ Risks',
    'redFlag': '🚩 Red Flag Chance', 'vsc': '🟨 VSC Chance', 'accident': '💥 Accident Chance',
    'turn1Accident': '↪️ Turn 1 Accident Chance',
    'tyres': '🛞 Tyres', 'tireWear': '📉 Tire Wear', 'strategy': '🧠 Strategy', 'bestCombination': '✨ Best Combination',
    'fastestPit': '⚡ Fastest Pitstop',
    'driver_facts_title': '🌟 Facts & Trivia', 'general': '👤 General', 'current_team': '🤝 Current Team', 'nationality': '🌍 Nationality',
    'career_stats': '🏆 Career Stats', 'championships': '👑 Championships', 'wins': '🥇 Wins', 'podiums': '🍾 Podiums',
    'poles': '🚩 Pole Positions', 'fastest_laps': '🚀 Fastest Laps', 'total_points': '💯 Total Points',
    'driver_history': '📈 History (Last 5 Years)',
    'experience': '🏁 Experience', 'starts': '🚦 Starts', 'laps_led': '🥇 Laps Led', 'dnf': '💥 DNFs',
    'cc_wins': '🏗️ Constructors Titles', 'dc_wins': '🏎️ Drivers Titles', 'race_stats': '📈 Race Stats',
    'total_entries': '🎟️ Total Entries', 'one_two': '🥈 1-2 Finishes', 'pitstop_leadership': '⚙️ Pitstop & Leadership',
    'team_principal': '👔 Team Principal',
    'soft_tire': '🔴 Soft', 'medium_tire': '🟡 Medium', 'hard_tire': '⚪ Hard',
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
    'country_Austria': 'Austria', 'country_UK': 'UK', 'country_Hungary': 'Hungary', 'country_Belgium': 'Belgium', 'country_Netherlands': 'Netherlands',
    'country_Azerbaijan': 'Azerbeidzjan', 'country_Singapore': 'Singapore', 'country_Mexico': 'Mexico', 'country_Brazil': 'Brazil', 'country_Qatar': 'Qatar', 'country_UAE': 'UAE',
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SessionDataManager().init(races);
  runApp(const F1ProApp());
}

class F1ProApp extends StatefulWidget {
  const F1ProApp({super.key});

  @override
  State<F1ProApp> createState() => _F1ProAppState();
}

class _F1ProAppState extends State<F1ProApp> {
  Locale? _locale; 
  ThemeMode _themeMode = ThemeMode.dark;

  void _setLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Strategy Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2196F3),
        useMaterial3: true,
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
    'Dutch': '🇳🇱', 'British': '🇬🇧', 'Monegasque': '🇲🇨', 'Spanish': '🇪🇸',
    'Australian': '🇦🇺', 'Italian': '🇮🇹', 'German': '🇩🇪', 'French': '🇫🇷',
    'Austrian': '🇦🇹', 'Swiss': '🇨🇭', 'Thai': '🇹🇭', 'Japanese': '🇯🇵', 
    'American': '🇺🇸', 'Mexican': '🇲🇽', 'Finnish': '🇫🇮', 'Argentine': '🇦🇷', 'New Zealander': '🇳🇿', 'Chinese': '🇨🇳', 'Danish': '🇩🇰',
    'Netherlands': '🇳🇱', 'Australia': '🇦🇺', 'Bahrain': '🇧🇭', 'Saudi Arabia': '🇸🇦', 'Japan': '🇯🇵', 'China': '🇨🇳',
    'USA': '🇺🇸', 'Monaco': '🇲🇨', 'Canada': '🇨🇦', 'Spain': '🇪🇸', 'Austria': '🇦🇹', 'UK': '🇬🇧', 'Hungary': '🇭🇺', 'Belgium': '🇧🇪',
    'Azerbaijan': '🇦🇿', 'Singapore': '🇸🇬', 'Mexico': '🇲🇽', 'Brazil': '🇧🇷', 'Qatar': '🇶🇦', 'UAE': '🇦🇪', 'United States': '🇺🇸', 'Italy': '🇮🇹',
  };
  return flags[nat] ?? '🏁';
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
    case 'SOFT': return '🔴 Soft';
    case 'MEDIUM': return '🟡 Med';
    case 'HARD': return '⚪ Hard';
    case 'INTERMEDIATE': return '🟢 Int';
    case 'WET': return '🔵 Wet';
    default: return '❔ $compound';
  }
}

String getCompactTireEmoji(String compound) {
  switch (compound.toUpperCase()) {
    case 'SOFT': return '🔴';
    case 'MEDIUM': return '🟡';
    case 'HARD': return '⚪';
    case 'INTERMEDIATE': return '🟢';
    case 'WET': return '🔵';
    default: return '❔';
  }
}

Widget _sectionHeader(String t, String emoji) => Padding(
  padding: const EdgeInsets.only(top: 25, bottom: 12), 
  child: Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Text(t.toUpperCase(), style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2.0)),
      const Expanded(child: Divider(indent: 15, color: Colors.white10)),
    ],
  )
);

Widget _statTile(String l, dynamic v, IconData icon) => Container(
  margin: const EdgeInsets.symmetric(vertical: 4),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF2196F3).withOpacity(0.7)),
      const SizedBox(width: 12),
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]),
    Flexible(child: Text(v.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), textAlign: TextAlign.right)),
  ]),
);

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
  final GlobalKey<NavigatorState> _standingsNavKey = GlobalKey<NavigatorState>();

  Widget _buildSettingsMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return PopupMenuButton<int>(
      icon: const Icon(Icons.settings),
      onSelected: (value) {
        if (value == 0) widget.onToggleTheme();
        if (value == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangelogScreen()));
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Row(children: [const Icon(Icons.brightness_6), const SizedBox(width: 12), Text(loc.translate('toggleTheme'))])),
        PopupMenuItem(value: 1, child: Row(children: [
          const Icon(Icons.language), const SizedBox(width: 12),
          Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: loc.locale.languageCode, isDense: true, isExpanded: true,
            onChanged: (String? val) { if (val != null) { widget.onSetLocale(Locale(val)); Navigator.pop(context); } },
            items: const [
              DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')), DropdownMenuItem(value: 'nl', child: Text('🇳🇱 Nederlands')),
              DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')), DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
              DropdownMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
            ],
          )))
        ])),
        PopupMenuItem(value: 2, child: Row(children: [const Icon(Icons.history), const SizedBox(width: 12), Text(loc.translate('changelog'))])),
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
            if (i == 1) _standingsNavKey.currentState?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _idx = i);
          }
        }, 
        selectedItemColor: const Color(0xFF2196F3), 
        unselectedItemColor: Colors.white24,
        backgroundColor: const Color(0xFF111118),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.speed), label: loc.translate('circuits').toUpperCase()),
          BottomNavigationBarItem(icon: const Icon(Icons.leaderboard), label: loc.translate('standings').toUpperCase()),
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
            key: _standingsNavKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (context) => StandingsView(settingsMenu: _buildSettingsMenu(context)));
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
      return '🥇 ${results[0].driver.split(' ').last} ${getCompactTireEmoji(results[0].tyre)}  🥈 ${results[1].driver.split(' ').last} ${getCompactTireEmoji(results[1].tyre)}  🥉 ${results[2].driver.split(' ').last} ${getCompactTireEmoji(results[2].tyre)}';
    }
    return '🥇 Verstappen 🔴  🥈 Norris 🟡  🥉 Leclerc ⚪'; 
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final upcoming = _nextRace();
    final timeStrNext = _timeUntil(upcoming.date, context);

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
                gradient: LinearGradient(begin: Alignment.topLeft, colors: [const Color(0xFF1A1A22), const Color(0xFF2196F3).withOpacity(0.05)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("${loc.translate('nextRace').toUpperCase()} ⚡", style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                  Row(
                    children: [
                      Text('$liveTemp°C ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Icon(liveRain > 30 ? Icons.umbrella : Icons.wb_sunny, color: liveRain > 30 ? Colors.blue : Colors.amber, size: 20),
                    ],
                  ),
                ]),
                const SizedBox(height: 12),
                Text("${loc.translate('gp_${upcoming.name}')} ${_getFlag(loc.translate('country_${upcoming.country}'))}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(upcoming.name, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const Divider(height: 30, color: Colors.white10),
                Text(timeStrNext.isEmpty ? _getPodiumString(upcoming) : '⌛ ${loc.translate('startsIn')} $timeStrNext', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
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
                          Text(loc.translate('gp_${r.name}'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text("${r.date.day}-${r.date.month}-${r.date.year}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(isFinished ? _getPodiumString(r) : '⏳ $tStr', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isFinished ? Colors.white70 : const Color(0xFF2196F3))),
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
  const StandingsView({required this.settingsMenu, super.key});
  @override State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  bool _isLoading = false;
  List<Driver> _cachedDrivers = [];
  List<Team> _cachedTeams = [];
  bool _usingFallback = false;

  @override void initState() { super.initState(); _fetchStandings(); }

  Future<void> _fetchStandings() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeyDrivers = 'api_drivers_cache';
    final cacheKeyTeams = 'api_teams_cache';
    final cacheTimeKey = 'api_cache_time';
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
      final driverRes = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/current/driverStandings.json')).timeout(const Duration(seconds: 4));
      
      await Future.delayed(const Duration(milliseconds: 700)); 
      final teamRes = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/current/constructorStandings.json')).timeout(const Duration(seconds: 4));

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
          _cachedDrivers = List.from(fallbackDrivers);
          _cachedTeams = List.from(fallbackTeams);
          _usingFallback = true;
          _isLoading = false;
        });
      }
    }
  }

  void _processStandingsData(List apiDrivers, List apiTeams) {
    List<Driver> mergedDrivers = [];
    for (var localD in fallbackDrivers) {
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
    final int count = isDriver ? (_cachedDrivers.isEmpty ? fallbackDrivers.length : _cachedDrivers.length) : (_cachedTeams.isEmpty ? fallbackTeams.length : _cachedTeams.length);
    
    return ListView.builder(itemCount: count, padding: const EdgeInsets.symmetric(vertical: 10), itemBuilder: (c, i) {
      final item = isDriver ? (_cachedDrivers.isEmpty ? fallbackDrivers[i] : _cachedDrivers[i]) : (_cachedTeams.isEmpty ? fallbackTeams[i] : _cachedTeams[i]);
      final String name = isDriver ? (item as Driver).name : (item as Team).name;
      final int points = isDriver ? (item as Driver).points : (item as Team).points;
      final String flag = isDriver ? (item as Driver).flag : (item as Team).flag;
      final String teamName = isDriver ? (item as Driver).team : (item as Team).name;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), 
        decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: _getTeamColor(teamName), width: 6))), 
        child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => isDriver ? DriverDetailView(driver: item as Driver, settingsMenu: widget.settingsMenu) : TeamDetailView(team: item as Team, settingsMenu: widget.settingsMenu))),
          leading: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 16)),
          title: Row(children: [Text(flag), const SizedBox(width: 10), Expanded(child: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)))]),
          trailing: Text("$points ${loc.translate('pts')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2196F3))),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: widget.settingsMenu,
        title: Text(loc.translate('appTitle').toUpperCase()),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            if (_usingFallback) Container(width: double.infinity, color: Colors.orangeAccent.withOpacity(0.9), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Text(loc.translate('using_fallback_data'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Expanded(
              child: DefaultTabController(
                length: 2, 
                child: Column(children: [
                  TabBar(indicatorColor: const Color(0xFF2196F3), labelStyle: const TextStyle(fontWeight: FontWeight.bold), tabs: [Tab(text: loc.translate('drivers').toUpperCase()), Tab(text: loc.translate('teams').toUpperCase())]),
                  Expanded(child: TabBarView(children: [_buildList(true), _buildList(false)]))
                ])
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: valueColor ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTopBlock({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF2196F3)),
            const SizedBox(width: 8),
            Expanded(child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2), overflow: TextOverflow.ellipsis)),
          ]),
          const Divider(color: Colors.white10, height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                children: [
                  _infoLine(loc.translate('length'), "${widget.race.length} m"),
                  _infoLine(loc.translate('laps'), widget.race.laps.toString()),
                  _infoLine(loc.translate('since'), widget.race.firstGrandPrix.toString()),
                  _infoLine(loc.translate('until'), widget.race.contractUntil),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Card(color: Theme.of(context).colorScheme.primaryContainer, child: ListTile(leading: const Icon(Icons.format_list_numbered), title: Text(loc.translate('session_results'), style: const TextStyle(fontWeight: FontWeight.bold)), trailing: const Icon(Icons.arrow_forward), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SessionResultsScreen(race: widget.race))))),
        const SizedBox(height: 10),

        ExpansionTile(
          initiallyExpanded: true,
          title: Text("⚡ ${loc.translate('lap_speed_stats')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
          children: [
            _statTile(loc.translate('fastestLap'), "${widget.race.fastestLap.driver} (${widget.race.fastestLap.time})", Icons.timer),
            _statTile(loc.translate('slowestLap'), "${widget.race.slowestLap.driver} (${widget.race.slowestLap.time})", Icons.timer_off),
            _statTile(loc.translate('avgLap'), widget.race.averageLap, Icons.av_timer),
            _statTile(loc.translate('topSpeed'), widget.race.topSpeed, Icons.speed),
            _statTile(loc.translate('averageSpeed'), widget.race.averageSpeed, Icons.directions_car),
            _statTile(loc.translate('max_g_force'), widget.race.maxGForce, Icons.compress),
          ],
        ),

        ExpansionTile(
          title: Text("⚠️ ${loc.translate('risks_incidents')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
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
            _statTile(loc.translate('fastestPit'), "${widget.race.fastestPitstop.team} (${widget.race.fastestPitstop.time})", Icons.build),
          ],
        ),

        ExpansionTile(
          title: Text("📍 ${loc.translate('characteristics')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: characteristics.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("💡 ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3))), Expanded(child: Text(c, style: const TextStyle(color: Colors.white70)))]))).toList(),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class DriverDetailView extends StatelessWidget {
  final Driver driver;
  final Widget settingsMenu;
  const DriverDetailView({required this.driver, required this.settingsMenu, super.key});

  List<int> _getDriverHistory(String name) {
    switch (name) {
      case 'Max Verstappen': return [1, 1, 1, 1, 1];
      case 'Lewis Hamilton': return [2, 6, 3, 7, 8];
      case 'Charles Leclerc': return [7, 2, 5, 3, 4];
      case 'Lando Norris': return [6, 7, 6, 2, 2];
      case 'Carlos Sainz': return [5, 5, 7, 5, 6];
      case 'Fernando Alonso': return [10, 9, 4, 9, 8];
      case 'George Russell': return [15, 4, 8, 6, 5];
      case 'Oscar Piastri': return [20, 20, 9, 4, 3];
      case 'Sergio Pérez': return [4, 3, 2, 8, 7];
      case 'Valtteri Bottas': return [3, 10, 15, 20, 20];
      default:
        int hash = name.length;
        return [min(20, hash), min(20, hash+2), min(20, max(1, hash-1)), min(20, hash+1), min(20, max(1, hash-3))];
    }
  }

  Widget _buildHistoryChart(List<int> pos, Color color) {
    if (pos.isEmpty) return const SizedBox.shrink();
    List<String> years = ['21', '22', '23', '24', '25'];
    return Container(
      height: 140, 
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(15), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(pos.length, (i) {
          double h = 100.0 - (pos[i] * 4.0);
          if(h < 10) h = 10;
          
          return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text("P${pos[i]}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Container(width: 24, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 4),
            Text(years[i], style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ]);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDutch = loc.locale.languageCode == 'nl' || loc.locale.languageCode == 'de';
    final List<String> facts = isDutch ? driver.realWorldFactsNl : driver.realWorldFactsEn;
    final List<int> driverHistory = _getDriverHistory(driver.name);

    return Scaffold(
      appBar: AppBar(title: Text(driver.name.toUpperCase()), actions: [settingsMenu]),
      body: ListView(
        padding: const EdgeInsets.all(20), 
        children: [
          Center(child: Text(driver.flag, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 10),
          Text("#${driver.number}", textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getTeamColor(driver.team))),
          const SizedBox(height: 20),
          
          ExpansionTile(
            initiallyExpanded: true,
            title: Text("📈 ${loc.translate('driver_history')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildHistoryChart(driverHistory, _getTeamColor(driver.team)),
              ),
            ],
          ),

          ExpansionTile(
            initiallyExpanded: true,
            title: Text("🌟 ${loc.translate('driver_facts_title')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: facts.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("📌 ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3))), Expanded(child: Text(f, style: const TextStyle(color: Colors.white70)))]))).toList()
                ),
              ),
            ],
          ),

          ExpansionTile(
            title: Text("👤 ${loc.translate('general')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('current_team'), driver.team, Icons.groups),
              _statTile(loc.translate('nationality'), loc.translate('nat_${driver.nationality}'), Icons.public),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text("🏆 ${loc.translate('career_stats')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('championships'), driver.championships, Icons.workspace_premium),
              _statTile(loc.translate('wins'), driver.wins, Icons.emoji_events),
              _statTile(loc.translate('podiums'), driver.podiums, Icons.leaderboard),
              _statTile(loc.translate('poles'), driver.poles, Icons.flag),
              _statTile(loc.translate('fastest_laps'), driver.fastestLaps, Icons.timer),
              _statTile(loc.translate('total_points'), driver.totalPoints, Icons.score),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text("🏁 ${loc.translate('experience')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('starts'), driver.starts, Icons.traffic),
              _statTile(loc.translate('laps_led'), driver.lapsLed, Icons.looks_one),
              _statTile(loc.translate('dnf'), driver.dnfs, Icons.car_crash),
              const SizedBox(height: 8),
            ],
          ),
        ]
      ),
    );
  }
}

class TeamDetailView extends StatelessWidget {
  final Team team;
  final Widget settingsMenu;
  const TeamDetailView({required this.team, required this.settingsMenu, super.key});

  Widget _buildHistoryChart(List<dynamic> pos, Color color) {
    if (pos.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 120, 
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(15), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(pos.length, (i) {
          double h = (12 - (pos[i] > 10 ? 11 : pos[i])) * 8.0;
          return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text("P${pos[i]}", style: const TextStyle(fontSize: 7, color: Colors.white38)),
            const SizedBox(height: 4),
            Container(width: 18, height: h, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          ]);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final mockHistory = [3, 2, 2, 2, 4, 6, 3, 2, 3, 2];

    return Scaffold(
      appBar: AppBar(title: Text(team.name.toUpperCase()), actions: [settingsMenu]),
      body: ListView(
        padding: const EdgeInsets.all(20), 
        children: [
          Center(child: Text(team.flag, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 20),
          
          ExpansionTile(
            initiallyExpanded: true,
            title: Text("📊 Performance History", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildHistoryChart(mockHistory, _getTeamColor(team.name)),
              ),
            ],
          ),

          ExpansionTile(
            title: Text("🏆 ${loc.translate('championships')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('cc_wins'), team.ccWins, Icons.emoji_events),
              _statTile(loc.translate('dc_wins'), team.dcWins, Icons.workspace_premium),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text("📈 ${loc.translate('race_stats')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('total_entries'), team.totalEntries, Icons.traffic),
              _statTile(loc.translate('wins'), team.podiums, Icons.leaderboard),
              _statTile(loc.translate('one_two'), team.oneTwo, Icons.filter_2),
              _statTile(loc.translate('poles'), team.poles, Icons.flag),
              _statTile(loc.translate('fastest_laps'), team.fastestLaps, Icons.timer),
              const SizedBox(height: 8),
            ],
          ),
          
          ExpansionTile(
            title: Text("⚙️ ${loc.translate('pitstop_leadership')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2196F3))),
            children: [
              _statTile(loc.translate('team_principal'), team.principalName, Icons.person_outline),
              _statTile(loc.translate('fastestPit'), team.fastestPitstopTime, Icons.build),
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
          "🏁 ${loc.translate('gp_' + widget.race.name)} - 📊 ${loc.translate('session_results')}",
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('P$index.', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(res.driver, overflow: TextOverflow.ellipsis)),
          Text(res.time, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(getTireEmoji(res.tyre), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
            const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white38)),
            const SizedBox(height: 8), const Divider(height: 1, color: Colors.white10),
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
                  title: Text("🔽 P4 t/m P${results.length} Weergeven", style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                  children: results.skip(3).toList().asMap().entries.map((e) => _buildResultRow(e.value, e.key + 4)).toList(),
                ),
              ),
              
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.white10),
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
    final List<Map<String, dynamic>> changelog = [
      {
        'version': '2.1.2',
        'date': 'Maart 2026',
        'changes_en': ['Merged live Open-Meteo weather API.', 'Added top blocks for weather and circuit info.', 'Session results fetch live data via Ergast API with smart fallback to last year if data is pending.', 'Top 3 results always visible, rest in a collapsible list.', 'Dynamic titles for session pages.', 'Added emojis globally.', 'Enforced a 700ms delay on all API calls.', 'Added interactive driver championship history chart.'],
        'changes_nl': ['Live Open-Meteo weer-API gekoppeld.', 'Nieuwe informatieblokken voor weer en circuit.', 'Sessie resultaten halen live data op via API met slimme fallback naar vorig jaar indien de race nog niet verwerkt is.', 'Top 3 resultaten direct in beeld, rest uitklapbaar.', 'Dynamische titels voor sessie-pagina\'s.', 'Emoji\'s globaal toegevoegd.', 'Standaard 700ms vertraging bij alle API verbindingen ingesteld.', 'Interactieve grafiek toegevoegd in de Coureur Details met kampioenschaphistorie.']
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${loc.translate('version')} ${entry['version']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2196F3), fontSize: 18)), Text(entry['date'], style: const TextStyle(color: Colors.white54))]),
                  const SizedBox(height: 12),
                  ...changes.map<Widget>((change) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Expanded(child: Text(change, style: const TextStyle(color: Colors.white70)))]))),
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
  final WeatherForecast weather; final LapRecord fastestLap; final LapRecord slowestLap; final String averageLap; final String topSpeed;
  final String averageSpeed; final int redFlagChance; final int vscChance; final int accidentChance; final int turn1AccidentChance;
  final String tireWear; final String tireStrategy; final String bestCombination; final PitstopRecord fastestPitstop;
  final String circuitDifficulty; final String overtakingDifficulty; final List<String> previousWinners; final String maxGForce;
  final String avgGForce; final int firstGrandPrix; final String contractUntil; final List<String> characteristicsEn; final List<String> characteristicsNl;
  final String mapUrl;
  final double lat; final double lon;

  DateTime get fp1 => date.subtract(const Duration(days: 2, hours: 4));
  DateTime get fp2 => date.subtract(const Duration(days: 2));
  DateTime get fp3 => date.subtract(const Duration(days: 1, hours: 4));
  DateTime get sprintQuali => date.subtract(const Duration(days: 2));
  DateTime get sprintRace => date.subtract(const Duration(days: 1, hours: 4));
  DateTime get qualifying => date.subtract(const Duration(days: 1));

  Race({required this.name, required this.country, required this.flag, required this.date, required this.hasSprint, required this.laps, required this.length, required this.weather, required this.fastestLap, required this.slowestLap, required this.averageLap, required this.topSpeed, required this.averageSpeed, required this.redFlagChance, required this.vscChance, required this.accidentChance, required this.turn1AccidentChance, required this.tireWear, required this.tireStrategy, required this.bestCombination, required this.fastestPitstop, required this.circuitDifficulty, required this.overtakingDifficulty, required this.previousWinners, required this.maxGForce, required this.avgGForce, required this.firstGrandPrix, required this.contractUntil, required this.characteristicsEn, required this.characteristicsNl, required this.mapUrl, required this.lat, required this.lon});
}

class WeatherForecast { final int temperature; final int rainChance; final int rainAmount; final int windSpeed; final int humidity; final int pressure; final int feelsLike; WeatherForecast({required this.temperature, required this.rainChance, required this.rainAmount, required this.windSpeed, required this.humidity, required this.pressure, required this.feelsLike}); }
class LapRecord { final String driver; final String team; final int year; final String time; LapRecord(this.driver, this.team, this.year, this.time); }
class PitstopRecord { final String team; final int year; final String time; PitstopRecord(this.team, this.year, this.time); }

class Driver { 
  final String name; final String flag; final int points; final int number; final String nationality; final String team; 
  final double pointsFinishPct; final double seasonPointsFinishPct; final int wins; final int podiums2nd; final int podiums3rd; final int podiums; 
  final int poles; final int fastestLaps; final double totalPoints; final int championships; final int lapsRaced; final int starts; 
  final int dnfs; final int dsqs; final int dnqs; final int lapsLed; final int frontRowStarts; final String highestFinish; final String highestGrid; final int hatTricks;
  final List<String> realWorldFactsEn; final List<String> realWorldFactsNl; 
  
  Driver({required this.name, required this.flag, required this.points, required this.number, required this.nationality, required this.team, required this.pointsFinishPct, required this.seasonPointsFinishPct, required this.wins, required this.podiums2nd, required this.podiums3rd, required this.podiums, required this.poles, required this.fastestLaps, required this.totalPoints, required this.championships, required this.lapsRaced, required this.starts, required this.dnfs, required this.dsqs, required this.dnqs, required this.lapsLed, required this.frontRowStarts, required this.highestFinish, required this.highestGrid, required this.hatTricks, required this.realWorldFactsEn, required this.realWorldFactsNl}); 
  factory Driver.copy(Driver d, int points) => Driver(name: d.name, flag: d.flag, points: points, number: d.number, nationality: d.nationality, team: d.team, pointsFinishPct: d.pointsFinishPct, seasonPointsFinishPct: d.seasonPointsFinishPct, wins: d.wins, podiums2nd: d.podiums2nd, podiums3rd: d.podiums3rd, podiums: d.podiums, poles: d.poles, fastestLaps: d.fastestLaps, totalPoints: d.totalPoints, championships: d.championships, lapsRaced: d.lapsRaced, starts: d.starts, dnfs: d.dnfs, dsqs: d.dsqs, dnqs: d.dnqs, lapsLed: d.lapsLed, frontRowStarts: d.frontRowStarts, highestFinish: d.highestFinish, highestGrid: d.highestGrid, hatTricks: d.hatTricks, realWorldFactsEn: d.realWorldFactsEn, realWorldFactsNl: d.realWorldFactsNl);
}

class Team { 
  final String name; final String flag; final int points; final String fastestPitstopTime; final int fastestPitstopYear; final String fastestPitstopCircuit; final int ccWins; final int dcWins; final int podiums; final int oneTwo; final int hattricks; final int doublePodiums; final double totalPoints; final int frontRow; final int poles; final int fastestLaps; final int racesLed; final String principalName; final int principalAge; final String principalFlag; final int totalEntries; 
  Team({required this.name, required this.flag, required this.points, required this.fastestPitstopTime, required this.fastestPitstopYear, required this.fastestPitstopCircuit, required this.ccWins, required this.dcWins, required this.podiums, required this.oneTwo, required this.hattricks, required this.doublePodiums, required this.totalPoints, required this.frontRow, required this.poles, required this.fastestLaps, required this.racesLed, required this.principalName, required this.principalAge, required this.principalFlag, required this.totalEntries}); 
  factory Team.copy(Team t, int points) => Team(name: t.name, flag: t.flag, points: points, fastestPitstopTime: t.fastestPitstopTime, fastestPitstopYear: t.fastestPitstopYear, fastestPitstopCircuit: t.fastestPitstopCircuit, ccWins: t.ccWins, dcWins: t.dcWins, podiums: t.podiums, oneTwo: t.oneTwo, hattricks: t.hattricks, doublePodiums: t.doublePodiums, totalPoints: t.totalPoints, frontRow: t.frontRow, poles: t.poles, fastestLaps: t.fastestLaps, racesLed: t.racesLed, principalName: t.principalName, principalAge: t.principalAge, principalFlag: t.principalFlag, totalEntries: t.totalEntries);
}

/// --- VOLLEDIGE 2026 GRID & KALENDER MET 5 KENMERKEN PER CIRCUIT ------------------------------------
final List<Race> races = [
  Race(name: 'Australian Grand Prix', country: 'Australia', flag: '🇦🇺', date: DateTime(2026, 3, 8, 5, 0), hasSprint: false, laps: 58, length: 5278, lat: -37.8497, lon: 144.968, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/australia.png', weather: WeatherForecast(temperature: 22, rainChance: 20, rainAmount: 2, windSpeed: 14, humidity: 55, pressure: 1015, feelsLike: 21), fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2022, '1:20.260'), slowestLap: LapRecord('Robert Kubica', 'Alfa Romeo', 2019, '1:35.000'), averageLap: '1:23.000', topSpeed: '335 km/h', averageSpeed: '230 km/h', redFlagChance: 15, vscChance: 20, accidentChance: 25, turn1AccidentChance: 15, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Ferrari', 2022, '2.3s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_3', previousWinners: ['2025: Lando Norris', '2024: Carlos Sainz'], maxGForce: '4.8 G', avgGForce: '2.6 G', firstGrandPrix: 1996, contractUntil: '2037', characteristicsEn: ['4 DRS zones', 'Sweeping corners', 'Temporary street circuit', 'Variable grip levels', 'Bumpy surface'], characteristicsNl: ['4 DRS-zones', 'Vloeiende bochten', 'Tijdelijk stratencircuit', 'Wisselende gripniveaus', 'Hobbelig oppervlak']),
  Race(name: 'Chinese Grand Prix', country: 'China', flag: '🇨🇳', date: DateTime(2026, 3, 15, 8, 0), hasSprint: true, laps: 56, length: 5451, lat: 31.3389, lon: 121.22, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/china.png', weather: WeatherForecast(temperature: 17, rainChance: 25, rainAmount: 3, windSpeed: 12, humidity: 50, pressure: 1013, feelsLike: 16), fastestLap: LapRecord('Michael Schumacher', 'Ferrari', 2004, '1:32.238'), slowestLap: LapRecord('Marcus Ericsson', 'Sauber', 2018, '1:45.000'), averageLap: '1:35.000', topSpeed: '340 km/h', averageSpeed: '210 km/h', redFlagChance: 7, vscChance: 10, accidentChance: 14, turn1AccidentChance: 8, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Williams', 2019, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Charles Leclerc', '2024: Max Verstappen'], maxGForce: '4.5 G', avgGForce: '2.4 G', firstGrandPrix: 2004, contractUntil: '2025', characteristicsEn: ['Famous Snail corner', 'Massive back straight', 'Front-left tire killer', 'Wide track for overtaking', 'High chance of rain'], characteristicsNl: ['Beroemde slakkenhuisbocht', 'Enorm lang recht stuk', 'Slecht voor linkervoorband', 'Breed circuit (goed inhalen)', 'Grote kans op regen']),
  Race(name: 'Japanese Grand Prix', country: 'Japan', flag: '🇯🇵', date: DateTime(2026, 3, 29, 7, 0), hasSprint: false, laps: 53, length: 5807, lat: 34.8431, lon: 136.531, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/japan.png', weather: WeatherForecast(temperature: 19, rainChance: 30, rainAmount: 5, windSpeed: 16, humidity: 60, pressure: 1018, feelsLike: 18), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2019, '1:30.983'), slowestLap: LapRecord('Pierre Gasly', 'AlphaTauri', 2020, '1:40.000'), averageLap: '1:33.000', topSpeed: '330 km/h', averageSpeed: '230 km/h', redFlagChance: 12, vscChance: 18, accidentChance: 22, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2021, '2.1s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '5.2 G', avgGForce: '3.1 G', firstGrandPrix: 1987, contractUntil: '2029', characteristicsEn: ['Figure-8 layout', 'Legendary 130R', 'High downforce demanded', 'High lateral G-forces', 'Unpredictable weather'], characteristicsNl: ['8-vormige lay-out', 'Legendarische 130R', 'Veel downforce vereist', 'Hoge laterale G-krachten', 'Onvoorspelbaar weer']),
  Race(name: 'Bahrain Grand Prix', country: 'Bahrain', flag: '🇧🇭', date: DateTime(2026, 4, 12, 16, 0), hasSprint: false, laps: 57, length: 5412, lat: 26.0325, lon: 50.5106, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/bahrain.png', weather: WeatherForecast(temperature: 24, rainChance: 0, rainAmount: 0, windSpeed: 15, humidity: 40, pressure: 1012, feelsLike: 24), fastestLap: LapRecord('Pedro de la Rosa', 'McLaren', 2005, '1:31.447'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:35.000'), averageLap: '1:33.500', topSpeed: '325 km/h', averageSpeed: '205 km/h', redFlagChance: 5, vscChance: 15, accidentChance: 12, turn1AccidentChance: 25, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Hard → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.2 G', avgGForce: '2.3 G', firstGrandPrix: 2004, contractUntil: '2036', characteristicsEn: ['High tire degradation', 'Heavy braking zones', 'Sakhir desert winds', 'Night race under floodlights', 'Long DRS straights'], characteristicsNl: ['Hoge bandenslijtage', 'Zware remzones', 'Sakhir woestijnwind', 'Nachtrace onder kunstlicht', 'Lange DRS stukken']),
  Race(name: 'Saudi Arabian Grand Prix', country: 'Saudi Arabia', flag: '🇸🇦', date: DateTime(2026, 4, 19, 18, 0), hasSprint: false, laps: 50, length: 6174, lat: 21.6319, lon: 39.1044, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/saudi_arabia.png', weather: WeatherForecast(temperature: 27, rainChance: 0, rainAmount: 0, windSpeed: 10, humidity: 60, pressure: 1010, feelsLike: 29), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:30.734'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:34.000'), averageLap: '1:32.000', topSpeed: '335 km/h', averageSpeed: '250 km/h', redFlagChance: 25, vscChance: 35, accidentChance: 40, turn1AccidentChance: 10, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('McLaren', 2023, '2.2s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_3', previousWinners: ['2025: Sergio Perez', '2024: Max Verstappen'], maxGForce: '4.9 G', avgGForce: '2.8 G', firstGrandPrix: 2021, contractUntil: '2030', characteristicsEn: ['Fastest street circuit', 'Blind high-speed corners', 'High risk of safety cars', 'Smooth tarmac', 'Very narrow run-off areas'], characteristicsNl: ['Snelste stratencircuit', 'Blinde hogesnelheidsbochten', 'Hoge kans op safety cars', 'Glad asfalt', 'Zeer smalle uitloopstroken']),
  Race(name: 'Miami Grand Prix', country: 'USA', flag: '🇺🇸', date: DateTime(2026, 5, 3, 22, 0), hasSprint: true, laps: 57, length: 5412, lat: 25.9581, lon: -80.2389, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/miami.png', weather: WeatherForecast(temperature: 29, rainChance: 40, rainAmount: 5, windSpeed: 10, humidity: 75, pressure: 1012, feelsLike: 33), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:29.708'), slowestLap: LapRecord('Kevin Magnussen', 'Haas', 2022, '1:33.000'), averageLap: '1:31.000', topSpeed: '335 km/h', averageSpeed: '215 km/h', redFlagChance: 10, vscChance: 20, accidentChance: 15, turn1AccidentChance: 10, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_3', previousWinners: ['2025: Lando Norris', '2024: Lando Norris'], maxGForce: '4.1 G', avgGForce: '2.2 G', firstGrandPrix: 2022, contractUntil: '2031', characteristicsEn: ['Fake marina', 'Tight chicane section', 'Hard overtaking', 'High humidity', 'Long back straight'], characteristicsNl: ['Nep jachthaven', 'Krappe chicane sectie', 'Lastig inhalen', 'Hoge luchtvochtigheid', 'Lang recht stuk achter']),
  Race(name: 'Canadian Grand Prix', country: 'Canada', flag: '🇨🇦', date: DateTime(2026, 5, 24, 20, 0), hasSprint: true, laps: 70, length: 4361, lat: 45.5000, lon: -73.5228, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/canada.png', weather: WeatherForecast(temperature: 20, rainChance: 40, rainAmount: 5, windSpeed: 15, humidity: 65, pressure: 1011, feelsLike: 20), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2019, '1:13.078'), slowestLap: LapRecord('Lance Stroll', 'Williams', 2018, '1:16.000'), averageLap: '1:14.500', topSpeed: '340 km/h', averageSpeed: '210 km/h', redFlagChance: 20, vscChance: 30, accidentChance: 35, turn1AccidentChance: 15, tireWear: 'Low', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Williams', 2019, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.4 G', avgGForce: '2.1 G', firstGrandPrix: 1978, contractUntil: '2031', characteristicsEn: ['Wall of Champions', 'Heavy braking zones', 'Groundhog hazard', 'Chicane riding', 'Stop-and-go layout'], characteristicsNl: ['Muur der Kampioenen', 'Zware remzones', 'Gevaar voor marmotten', 'Agressief over chicanes', 'Stop-and-go lay-out']),
  Race(name: 'Monaco Grand Prix', country: 'Monaco', flag: '🇲🇨', date: DateTime(2026, 6, 7, 15, 0), hasSprint: false, laps: 78, length: 3337, lat: 43.7347, lon: 7.4206, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/monaco.png', weather: WeatherForecast(temperature: 23, rainChance: 10, rainAmount: 1, windSpeed: 8, humidity: 55, pressure: 1016, feelsLike: 23), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:12.909'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:18.000'), averageLap: '1:15.000', topSpeed: '290 km/h', averageSpeed: '160 km/h', redFlagChance: 35, vscChance: 45, accidentChance: 50, turn1AccidentChance: 40, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2021, '2.0s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_5', previousWinners: ['2025: Charles Leclerc', '2024: Charles Leclerc'], maxGForce: '3.6 G', avgGForce: '1.8 G', firstGrandPrix: 1950, contractUntil: '2025', characteristicsEn: ['Ultimate driver test', 'Impossible to overtake', 'Shortest lap', 'High concentration required', 'Glamorous harbor setting'], characteristicsNl: ['Ultieme test voor coureurs', 'Onmogelijk in te halen', 'Kortste ronde', 'Hoge concentratie vereist', 'Glamoureuze havenomgeving']),
  Race(name: 'Barcelona Grand Prix', country: 'Spain', flag: '🇪🇸', date: DateTime(2026, 6, 14, 15, 0), hasSprint: false, laps: 66, length: 4657, lat: 41.5700, lon: 2.2611, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/spain.png', weather: WeatherForecast(temperature: 28, rainChance: 5, rainAmount: 0, windSpeed: 12, humidity: 50, pressure: 1014, feelsLike: 30), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:16.330'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:19.000'), averageLap: '1:18.000', topSpeed: '325 km/h', averageSpeed: '220 km/h', redFlagChance: 5, vscChance: 10, accidentChance: 10, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.0s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_4', previousWinners: ['2025: Lando Norris', '2024: Max Verstappen'], maxGForce: '4.7 G', avgGForce: '2.5 G', firstGrandPrix: 1991, contractUntil: '2026', characteristicsEn: ['High downforce test', 'Long fast corners', 'High tire wear', 'Often used for testing', 'Hard to follow closely'], characteristicsNl: ['Test voor downforce', 'Lange snelle bochten', 'Hoge bandenslijtage', 'Vaak gebruikt voor testdagen', 'Lastig om dichtbij te volgen']),
  Race(name: 'Austrian Grand Prix', country: 'Austria', flag: '🇦🇹', date: DateTime(2026, 6, 28, 15, 0), hasSprint: false, laps: 71, length: 4318, lat: 47.2197, lon: 14.7647, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/austria.png', weather: WeatherForecast(temperature: 24, rainChance: 30, rainAmount: 4, windSpeed: 10, humidity: 55, pressure: 1015, feelsLike: 25), fastestLap: LapRecord('Carlos Sainz', 'McLaren', 2020, '1:05.619'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2020, '1:08.000'), averageLap: '1:07.000', topSpeed: '330 km/h', averageSpeed: '235 km/h', redFlagChance: 10, vscChance: 25, accidentChance: 15, turn1AccidentChance: 20, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Medium', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_2', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: George Russell'], maxGForce: '4.3 G', avgGForce: '2.4 G', firstGrandPrix: 1970, contractUntil: '2030', characteristicsEn: ['Shortest lap time', 'High altitude', 'Elevation changes', '3 DRS zones', 'Aggressive kerbs'], characteristicsNl: ['Kortste rondetijd', 'Hoge ligging', 'Veel hoogteverschillen', '3 DRS-zones', 'Zeer agressieve kerbs']),
  Race(name: 'British Grand Prix', country: 'UK', flag: '🇬🇧', date: DateTime(2026, 7, 5, 16, 0), hasSprint: true, laps: 52, length: 5891, lat: 52.0786, lon: -1.0169, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/uk.png', weather: WeatherForecast(temperature: 20, rainChance: 50, rainAmount: 6, windSpeed: 20, humidity: 65, pressure: 1010, feelsLike: 19), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2020, '1:27.097'), slowestLap: LapRecord('Romain Grosjean', 'Haas', 2020, '1:31.000'), averageLap: '1:29.000', topSpeed: '330 km/h', averageSpeed: '245 km/h', redFlagChance: 20, vscChance: 25, accidentChance: 30, turn1AccidentChance: 15, tireWear: 'Very High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Soft', fastestPitstop: PitstopRecord('McLaren', 2023, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_3', previousWinners: ['2025: Lando Norris', '2024: Lewis Hamilton'], maxGForce: '5.2 G', avgGForce: '2.9 G', firstGrandPrix: 1950, contractUntil: '2034', characteristicsEn: ['Maggots and Becketts', 'High speed flowing', 'Historic airfield', 'High lateral loads', 'Famous unpredictable British weather'], characteristicsNl: ['Maggots en Becketts', 'Snel en vloeiend', 'Historisch vliegveld', 'Hoge laterale krachten', 'Onvoorspelbaar Brits weer']),
  Race(name: 'Belgian Grand Prix', country: 'Belgium', flag: '🇧🇪', date: DateTime(2026, 7, 19, 15, 0), hasSprint: false, laps: 44, length: 7004, lat: 50.4372, lon: 5.9714, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/belgium.png', weather: WeatherForecast(temperature: 18, rainChance: 60, rainAmount: 12, windSpeed: 15, humidity: 75, pressure: 1009, feelsLike: 17), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2018, '1:46.286'), slowestLap: LapRecord('Lance Stroll', 'Williams', 2018, '1:50.000'), averageLap: '1:48.000', topSpeed: '345 km/h', averageSpeed: '240 km/h', redFlagChance: 25, vscChance: 35, accidentChance: 40, turn1AccidentChance: 30, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Medium', fastestPitstop: PitstopRecord('Williams', 2019, '2.1s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Lewis Hamilton'], maxGForce: '4.8 G', avgGForce: '2.5 G', firstGrandPrix: 1950, contractUntil: '2025', characteristicsEn: ['Eau Rouge / Radillon', 'Longest track on calendar', 'Microclimates', 'Kemmel straight slipstreaming', 'Historic forest setting'], characteristicsNl: ['Eau Rouge / Radillon', 'Langste circuit van de kalender', 'Microklimaten (regen in 1 bocht)', 'Slipstreamen op Kemmel Straight', 'Historische bosrijke omgeving']),
  Race(name: 'Hungarian Grand Prix', country: 'Hungary', flag: '🇭🇺', date: DateTime(2026, 7, 26, 15, 0), hasSprint: false, laps: 70, length: 4381, lat: 47.5822, lon: 19.2511, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/hungary.png', weather: WeatherForecast(temperature: 31, rainChance: 15, rainAmount: 2, windSpeed: 10, humidity: 45, pressure: 1013, feelsLike: 33), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2020, '1:16.627'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2021, '1:21.000'), averageLap: '1:19.000', topSpeed: '315 km/h', averageSpeed: '200 km/h', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 25, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.3s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_5', previousWinners: ['2025: Oscar Piastri', '2024: Oscar Piastri'], maxGForce: '4.4 G', avgGForce: '2.2 G', firstGrandPrix: 1986, contractUntil: '2032', characteristicsEn: ['Monaco without walls', 'Dusty off racing line', 'Extremely hot', 'High downforce', 'Difficult to overtake'], characteristicsNl: ['Monaco zonder muren', 'Stoffig naast de ideale lijn', 'Meestal extreem heet', 'Veel downforce vereist', 'Erg moeilijk in te halen']),
  Race(name: 'Dutch Grand Prix', country: 'Netherlands', flag: '🇳🇱', date: DateTime(2026, 8, 23, 15, 0), hasSprint: true, laps: 72, length: 4259, lat: 52.3888, lon: 4.5409, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/netherlands.png', weather: WeatherForecast(temperature: 20, rainChance: 45, rainAmount: 6, windSpeed: 25, humidity: 70, pressure: 1012, feelsLike: 19), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:11.097'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:15.000'), averageLap: '1:13.000', topSpeed: '320 km/h', averageSpeed: '215 km/h', redFlagChance: 15, vscChance: 25, accidentChance: 25, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_5', previousWinners: ['2025: Max Verstappen', '2024: Lando Norris'], maxGForce: '4.9 G', avgGForce: '2.6 G', firstGrandPrix: 1952, contractUntil: '2025', characteristicsEn: ['Banked corners', 'Orange Army', 'Narrow and twisty', 'Sand on track', 'Zandvoort dunes'], characteristicsNl: ['Steile kombochten', 'Oranje Legioen', 'Smal en bochtig', 'Zand op de baan', 'Gelegen in de Zandvoortse duinen']),
  Race(name: 'Italian Grand Prix', country: 'Italy', flag: '🇮🇹', date: DateTime(2026, 9, 6, 15, 0), hasSprint: false, laps: 53, length: 5793, lat: 45.6156, lon: 9.2811, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/italy.png', weather: WeatherForecast(temperature: 26, rainChance: 10, rainAmount: 0, windSpeed: 5, humidity: 45, pressure: 1015, feelsLike: 27), fastestLap: LapRecord('Rubens Barrichello', 'Ferrari', 2004, '1:21.046'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:25.000'), averageLap: '1:23.000', topSpeed: '360 km/h', averageSpeed: '260 km/h', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 40, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Ferrari', 2022, '2.1s'), circuitDifficulty: 'level_2', overtakingDifficulty: 'level_2', previousWinners: ['2025: Charles Leclerc', '2024: Charles Leclerc'], maxGForce: '3.8 G', avgGForce: '1.9 G', firstGrandPrix: 1950, contractUntil: '2025', characteristicsEn: ['Temple of Speed', 'Lowest downforce', 'Heavy braking for chicane', 'Parabolica corner', 'Tifosi atmosphere'], characteristicsNl: ['Temple of Speed', 'Laagste downforce van het jaar', 'Zwaar aanremmen voor chicanes', 'De legendarische Parabolica', 'Gepassioneerde Tifosi sfeer']),
  Race(name: 'Spanish Grand Prix', country: 'Spain', flag: '🇪🇸', date: DateTime(2026, 9, 13, 15, 0), hasSprint: false, laps: 54, length: 5474, lat: 40.4700, lon: -3.6200, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/placeholder.png', weather: WeatherForecast(temperature: 27, rainChance: 10, rainAmount: 1, windSpeed: 10, humidity: 45, pressure: 1016, feelsLike: 29), fastestLap: LapRecord('TBD', 'TBD', 2026, '1:32.000'), slowestLap: LapRecord('TBD', 'TBD', 2026, '1:38.000'), averageLap: '1:34.000', topSpeed: '320 km/h', averageSpeed: '215 km/h', redFlagChance: 25, vscChance: 35, accidentChance: 30, turn1AccidentChance: 20, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard', fastestPitstop: PitstopRecord('TBD', 2026, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_3', previousWinners: ['(Nieuw circuit)'], maxGForce: '4.2 G', avgGForce: '2.4 G', firstGrandPrix: 2026, contractUntil: '2035', characteristicsEn: ['Brand new street track', 'Tunnel sections', 'IFEMA exhibition area', 'Hybrid permanent/street', 'Unpredictable surface'], characteristicsNl: ['Nieuw stratencircuit', 'Bevat tunnel secties', 'Rondom IFEMA complex', 'Hybride permanent/straten', 'Onvoorspelbaar asfalt']),
  Race(name: 'Azerbaijan Grand Prix', country: 'Azerbaijan', flag: '🇦🇿', date: DateTime(2026, 9, 26, 13, 0), hasSprint: false, laps: 51, length: 6003, lat: 40.3725, lon: 49.8533, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/azerbaijan.png', weather: WeatherForecast(temperature: 24, rainChance: 5, rainAmount: 0, windSpeed: 22, humidity: 55, pressure: 1016, feelsLike: 24), fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2019, '1:43.009'), slowestLap: LapRecord('Lance Stroll', 'Aston Martin', 2021, '1:47.000'), averageLap: '1:45.000', topSpeed: '350 km/h', averageSpeed: '210 km/h', redFlagChance: 30, vscChance: 40, accidentChance: 45, turn1AccidentChance: 20, tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Williams', 2016, '1.9s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_2', previousWinners: ['2025: Oscar Piastri', '2024: Oscar Piastri'], maxGForce: '4.0 G', avgGForce: '2.0 G', firstGrandPrix: 2016, contractUntil: '2026', characteristicsEn: ['Castle section', 'Massive main straight', 'High top speeds', 'Street circuit risks', 'Windy "City of Winds"'], characteristicsNl: ['Extreem krappe Kasteel sectie', 'Enorm lang recht stuk', 'Zeer hoge topsnelheden', 'Veel risico\'s door krappe muren', 'Veel wind ("Stad der Winden")']),
  Race(name: 'Singapore Grand Prix', country: 'Singapore', flag: '🇸🇬', date: DateTime(2026, 10, 11, 14, 0), hasSprint: true, laps: 62, length: 4940, lat: 1.2915, lon: 103.864, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/singapore.png', weather: WeatherForecast(temperature: 31, rainChance: 50, rainAmount: 15, windSpeed: 10, humidity: 85, pressure: 1008, feelsLike: 38), fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2023, '1:35.867'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:39.000'), averageLap: '1:37.000', topSpeed: '310 km/h', averageSpeed: '175 km/h', redFlagChance: 25, vscChance: 60, accidentChance: 50, turn1AccidentChance: 15, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.3s'), circuitDifficulty: 'level_5', overtakingDifficulty: 'level_5', previousWinners: ['2025: Lando Norris', '2024: Lando Norris'], maxGForce: '4.2 G', avgGForce: '2.1 G', firstGrandPrix: 2008, contractUntil: '2028', characteristicsEn: ['Night race', 'Extreme humidity', 'Bumpy street surface', 'Physically exhausting', 'High probability of safety car'], characteristicsNl: ['Nachtrace', 'Extreem hoge luchtvochtigheid', 'Hobbelig stratencircuit', 'Fysiek enorm slopend', 'Bijna 100% kans op Safety Car']),
  Race(name: 'United States Grand Prix', country: 'USA', flag: '🇺🇸', date: DateTime(2026, 10, 25, 21, 0), hasSprint: false, laps: 56, length: 5513, lat: 30.1328, lon: -97.6411, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/usa.png', weather: WeatherForecast(temperature: 28, rainChance: 10, rainAmount: 1, windSpeed: 15, humidity: 45, pressure: 1013, feelsLike: 29), fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2019, '1:36.169'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:40.000'), averageLap: '1:38.000', topSpeed: '335 km/h', averageSpeed: '205 km/h', redFlagChance: 10, vscChance: 20, accidentChance: 25, turn1AccidentChance: 30, tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Medium', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.2s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Charles Leclerc'], maxGForce: '4.5 G', avgGForce: '2.5 G', firstGrandPrix: 2012, contractUntil: '2026', characteristicsEn: ['Steep Turn 1', 'Bumpy surface', 'Inspired by other tracks', 'Fast sector 1', 'Wide run-offs'], characteristicsNl: ['Zeer steile bocht 1', 'Hobbelig asfalt (sinkholes)', 'Geïnspireerd door andere iconische banen', 'Zeer snelle eerste sector', 'Brede uitloopstroken']),
  Race(name: 'Mexico City Grand Prix', country: 'Mexico', flag: '🇲🇽', date: DateTime(2026, 11, 1, 21, 0), hasSprint: false, laps: 71, length: 4304, lat: 19.4042, lon: -99.0907, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/mexico.png', weather: WeatherForecast(temperature: 23, rainChance: 20, rainAmount: 2, windSpeed: 8, humidity: 40, pressure: 1025, feelsLike: 23), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2021, '1:17.774'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2021, '1:21.000'), averageLap: '1:19.000', topSpeed: '350 km/h', averageSpeed: '195 km/h', redFlagChance: 15, vscChance: 25, accidentChance: 20, turn1AccidentChance: 35, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.0s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Carlos Sainz'], maxGForce: '4.1 G', avgGForce: '2.0 G', firstGrandPrix: 1962, contractUntil: '2025', characteristicsEn: ['High altitude (thin air)', 'Stadium section', 'Less drag effect', 'Brake cooling issues', 'Long run to turn 1'], characteristicsNl: ['Hoge ligging (zeer ijle lucht)', 'Karakteristieke stadion sectie', 'Weinig luchtweerstand op straights', 'Problemen met remkoeling', 'Heel lang recht stuk naar bocht 1']),
  Race(name: 'São Paulo Grand Prix', country: 'Brazil', flag: '🇧🇷', date: DateTime(2026, 11, 8, 18, 0), hasSprint: true, laps: 71, length: 4309, lat: -23.7036, lon: -46.6997, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/brazil.png', weather: WeatherForecast(temperature: 25, rainChance: 60, rainAmount: 10, windSpeed: 12, humidity: 65, pressure: 1012, feelsLike: 27), fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2018, '1:10.540'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:14.000'), averageLap: '1:12.500', topSpeed: '335 km/h', averageSpeed: '215 km/h', redFlagChance: 20, vscChance: 35, accidentChance: 30, turn1AccidentChance: 25, tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Medium', fastestPitstop: PitstopRecord('Red Bull', 2019, '1.8s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.6 G', avgGForce: '2.5 G', firstGrandPrix: 1973, contractUntil: '2030', characteristicsEn: ['Senna S', 'Unpredictable weather', 'Anti-clockwise', 'Short lap', 'Passionate fans'], characteristicsNl: ['De beroemde Senna S', 'Zeer onvoorspelbaar weer', 'Tegen de klok in', 'Korte rondetijd', 'Extreem fanatiek publiek']),
  Race(name: 'Las Vegas Grand Prix', country: 'USA', flag: '🇺🇸', date: DateTime(2026, 11, 22, 7, 0), hasSprint: false, laps: 50, length: 6201, lat: 36.1147, lon: -115.1728, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/las_vegas.png', weather: WeatherForecast(temperature: 12, rainChance: 0, rainAmount: 0, windSpeed: 10, humidity: 30, pressure: 1018, feelsLike: 10), fastestLap: LapRecord('Oscar Piastri', 'McLaren', 2023, '1:35.490'), slowestLap: LapRecord('Kevin Magnussen', 'Haas', 2023, '1:39.000'), averageLap: '1:37.000', topSpeed: '350 km/h', averageSpeed: '235 km/h', redFlagChance: 15, vscChance: 30, accidentChance: 35, turn1AccidentChance: 25, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.2s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_2', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '3.9 G', avgGForce: '2.1 G', firstGrandPrix: 2023, contractUntil: '2032', characteristicsEn: ['The Strip straight', 'Cold night temperatures', 'Low grip', 'Heavy braking after long straights', 'Spectacular visuals'], characteristicsNl: ['Extreem lang stuk op The Strip', 'Zeer koude nachttemperaturen', 'Gevaarlijk lage grip', 'Zwaar aanremmen na rechte stukken', 'Spectaculaire visuele ervaring']),
  Race(name: 'Qatar Grand Prix', country: 'Qatar', flag: '🇶🇦', date: DateTime(2026, 11, 29, 18, 0), hasSprint: true, laps: 57, length: 5419, lat: 25.4900, lon: 51.4542, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/qatar.png', weather: WeatherForecast(temperature: 28, rainChance: 0, rainAmount: 0, windSpeed: 18, humidity: 55, pressure: 1013, feelsLike: 30), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:23.196'), slowestLap: LapRecord('Logan Sargeant', 'Williams', 2023, '1:27.000'), averageLap: '1:25.000', topSpeed: '330 km/h', averageSpeed: '235 km/h', redFlagChance: 5, vscChance: 15, accidentChance: 15, turn1AccidentChance: 10, tireWear: 'Very High', tireStrategy: '3 stops', bestCombination: 'Medium → Medium → Hard → Soft', fastestPitstop: PitstopRecord('McLaren', 2023, '1.80s'), circuitDifficulty: 'level_4', overtakingDifficulty: 'level_4', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '5.3 G', avgGForce: '3.0 G', firstGrandPrix: 2021, contractUntil: '2032', characteristicsEn: ['High speed corners', 'Physically demanding', 'Night race', 'Flat desert setting', 'High tire stress'], characteristicsNl: ['Veel opeenvolgende snelle bochten', 'Fysiek extreem veeleisend', 'Nachtrace', 'Volledig vlakke woestijnomgeving', 'Hoge belasting op de banden']),
  Race(name: 'Abu Dhabi Grand Prix', country: 'UAE', flag: '🇦🇪', date: DateTime(2026, 12, 6, 14, 0), hasSprint: false, laps: 58, length: 5281, lat: 24.4672, lon: 54.6031, mapUrl: 'https://raw.githubusercontent.com/f1stats/f1-maps/main/maps/abu_dhabi.png', weather: WeatherForecast(temperature: 26, rainChance: 0, rainAmount: 0, windSpeed: 12, humidity: 50, pressure: 1015, feelsLike: 27), fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:26.103'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:30.000'), averageLap: '1:28.000', topSpeed: '335 km/h', averageSpeed: '215 km/h', redFlagChance: 5, vscChance: 10, accidentChance: 10, turn1AccidentChance: 15, tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard', fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'), circuitDifficulty: 'level_3', overtakingDifficulty: 'level_3', previousWinners: ['2025: Max Verstappen', '2024: Max Verstappen'], maxGForce: '4.5 G', avgGForce: '2.3 G', firstGrandPrix: 2009, contractUntil: '2030', characteristicsEn: ['Twilight race', 'Long back straight', 'Smooth surface', 'Yas Marina setting', 'Technical sector 3'], characteristicsNl: ['Race tijdens de zonsondergang', 'Lang recht stuk achteraan', 'Zeer glad asfalt', 'Luxe Yas Marina omgeving', 'Technische en trage derde sector']),
];

final List<Driver> fallbackDrivers = [
  Driver(name: 'Max Verstappen', flag: '🇳🇱', points: 0, number: 33, nationality: 'Dutch', team: 'Red Bull Racing', pointsFinishPct: 85.1, seasonPointsFinishPct: 95.8, wins: 69, podiums2nd: 31, podiums3rd: 16, podiums: 116, poles: 45, fastestLaps: 35, totalPoints: 3400.5, championships: 3, lapsRaced: 11452, starts: 210, dnfs: 31, dsqs: 0, dnqs: 0, lapsLed: 3350, frontRowStarts: 65, highestFinish: '1e (x69)', highestGrid: '1e (x45)', hatTricks: 13, realWorldFactsNl: ['Jongste coureur ooit in een Grand Prix-weekend.', 'Recordhouder meeste overwinningen in één seizoen (19).'], realWorldFactsEn: ['Youngest ever driver in a GP weekend.', 'Most wins in a single season (19).']),
  Driver(name: 'Lewis Hamilton', flag: '🇬🇧', points: 0, number: 44, nationality: 'British', team: 'Ferrari', pointsFinishPct: 88.5, seasonPointsFinishPct: 66.6, wins: 105, podiums2nd: 56, podiums3rd: 40, podiums: 201, poles: 104, fastestLaps: 67, totalPoints: 4895.5, championships: 7, lapsRaced: 19612, starts: 356, dnfs: 31, dsqs: 1, dnqs: 0, lapsLed: 5455, frontRowStarts: 175, highestFinish: '1e (x105)', highestGrid: '1e (x104)', hatTricks: 19, realWorldFactsNl: ['Gedeeld record 7 wereldtitels.', 'Meeste Grand Prix overwinningen ooit.'], realWorldFactsEn: ['Shared record 7 World Titles.', 'Most Grand Prix wins in history.']),
  Driver(name: 'Fernando Alonso', flag: '🇪🇸', points: 0, number: 14, nationality: 'Spanish', team: 'Aston Martin', pointsFinishPct: 75.3, seasonPointsFinishPct: 45.8, wins: 32, podiums2nd: 40, podiums3rd: 34, podiums: 106, poles: 22, fastestLaps: 24, totalPoints: 2385.0, championships: 2, lapsRaced: 20145, starts: 402, dnfs: 75, dsqs: 0, dnqs: 1, lapsLed: 1773, frontRowStarts: 42, highestFinish: '1e (x32)', highestGrid: '1e (x22)', hatTricks: 5, realWorldFactsNl: ['Meeste F1 starts ooit.', 'Won Le Mans twee keer.'], realWorldFactsEn: ['Most F1 starts in history.', 'Won Le Mans twice.']),
  Driver(name: 'Lando Norris', flag: '🇬🇧', points: 0, number: 4, nationality: 'British', team: 'McLaren', pointsFinishPct: 83.5, seasonPointsFinishPct: 91.6, wins: 8, podiums2nd: 10, podiums3rd: 7, podiums: 25, poles: 8, fastestLaps: 9, totalPoints: 1056.0, championships: 1, lapsRaced: 6241, starts: 128, dnfs: 9, dsqs: 0, dnqs: 0, lapsLed: 642, frontRowStarts: 16, highestFinish: '1e (x8)', highestGrid: '1e (x8)', hatTricks: 2, realWorldFactsNl: ['Won Miami GP 2024.', 'Oprichter gaming merk Quadrant.'], realWorldFactsEn: ['Won Miami GP 2024.', 'Founder of gaming brand Quadrant.']),
  Driver(name: 'Charles Leclerc', flag: '🇲🇨', points: 0, number: 16, nationality: 'Monegasque', team: 'Ferrari', pointsFinishPct: 72.8, seasonPointsFinishPct: 79.1, wins: 8, podiums2nd: 15, podiums3rd: 20, podiums: 43, poles: 27, fastestLaps: 10, totalPoints: 1420.0, championships: 0, lapsRaced: 8432, starts: 148, dnfs: 22, dsqs: 1, dnqs: 0, lapsLed: 890, frontRowStarts: 35, highestFinish: '1e (x8)', highestGrid: '1e (x27)', hatTricks: 3, realWorldFactsNl: ['Won thuisrace Monaco in 2024.', 'Zeer sterk in kwalificaties.'], realWorldFactsEn: ['Won home race Monaco in 2024.', 'Very strong in qualifying.']),
  Driver(name: 'George Russell', flag: '🇬🇧', points: 0, number: 63, nationality: 'British', team: 'Mercedes', pointsFinishPct: 65.4, seasonPointsFinishPct: 83.3, wins: 4, podiums2nd: 5, podiums3rd: 10, podiums: 19, poles: 4, fastestLaps: 8, totalPoints: 788.0, championships: 0, lapsRaced: 7512, starts: 128, dnfs: 18, dsqs: 1, dnqs: 0, lapsLed: 210, frontRowStarts: 10, highestFinish: '1e (x4)', highestGrid: '1e (x4)', hatTricks: 0, realWorldFactsNl: ['Bijnaam "Mr. Saturday".', 'Directeur van de GPDA.'], realWorldFactsEn: ['Nickname "Mr. Saturday".', 'Director of the GPDA.']),
  Driver(name: 'Carlos Sainz', flag: '🇪🇸', points: 0, number: 55, nationality: 'Spanish', team: 'Williams', pointsFinishPct: 70.1, seasonPointsFinishPct: 75.0, wins: 4, podiums2nd: 8, podiums3rd: 13, podiums: 25, poles: 6, fastestLaps: 4, totalPoints: 1286.5, championships: 0, lapsRaced: 11214, starts: 207, dnfs: 25, dsqs: 0, dnqs: 0, lapsLed: 245, frontRowStarts: 12, highestFinish: '1e (x4)', highestGrid: '1e (x6)', hatTricks: 0, realWorldFactsNl: ['Zoon van Rally kampioen Sainz Sr.', 'Won Australië na blinde darm operatie.'], realWorldFactsEn: ['Son of Rally champ Sainz Sr.', 'Won Australia after appendicitis.']),
  Driver(name: 'Oscar Piastri', flag: '🇦🇺', points: 0, number: 81, nationality: 'Australian', team: 'McLaren', pointsFinishPct: 75.0, seasonPointsFinishPct: 87.5, wins: 5, podiums2nd: 8, podiums3rd: 5, podiums: 18, poles: 4, fastestLaps: 6, totalPoints: 607.0, championships: 0, lapsRaced: 2415, starts: 46, dnfs: 4, dsqs: 0, dnqs: 0, lapsLed: 154, frontRowStarts: 8, highestFinish: '1e (x5)', highestGrid: '1e (x4)', hatTricks: 0, realWorldFactsNl: ['Won Formule Renault, F3 en F2 back-to-back.', 'Gemanaged door Mark Webber.'], realWorldFactsEn: ['Won Formula Renault, F3 and F2 back-to-back.', 'Managed by Mark Webber.']),
  Driver(name: 'Nico Hülkenberg', flag: '🇩🇪', points: 0, number: 27, nationality: 'German', team: 'Audi', pointsFinishPct: 48.0, seasonPointsFinishPct: 41.6, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 1, fastestLaps: 2, totalPoints: 581.0, championships: 0, lapsRaced: 13541, starts: 228, dnfs: 42, dsqs: 0, dnqs: 0, lapsLed: 43, frontRowStarts: 2, highestFinish: '4e (x3)', highestGrid: '1e (x1)', hatTricks: 0, realWorldFactsNl: ['Meeste F1 starts zonder podium.', 'Won Le Mans in 2015.'], realWorldFactsEn: ['Most F1 starts without a podium.', 'Won Le Mans in 2015.']),
  Driver(name: 'Esteban Ocon', flag: '🇫🇷', points: 0, number: 31, nationality: 'French', team: 'Haas F1 Team', pointsFinishPct: 52.0, seasonPointsFinishPct: 25.0, wins: 1, podiums2nd: 2, podiums3rd: 1, podiums: 4, poles: 0, fastestLaps: 0, totalPoints: 460.0, championships: 0, lapsRaced: 8742, starts: 157, dnfs: 28, dsqs: 1, dnqs: 0, lapsLed: 66, frontRowStarts: 0, highestFinish: '1e (x1)', highestGrid: '3e (x2)', hatTricks: 0, realWorldFactsNl: ['Won Hongarije 2021.', 'Groeide op in een caravan.'], realWorldFactsEn: ['Won Hungary 2021.', 'Grew up living in a caravan.']),
  Driver(name: 'Pierre Gasly', flag: '🇫🇷', points: 0, number: 10, nationality: 'French', team: 'Alpine', pointsFinishPct: 54.0, seasonPointsFinishPct: 16.6, wins: 1, podiums2nd: 1, podiums3rd: 2, podiums: 4, poles: 0, fastestLaps: 3, totalPoints: 416.0, championships: 0, lapsRaced: 8641, starts: 154, dnfs: 24, dsqs: 1, dnqs: 0, lapsLed: 26, frontRowStarts: 1, highestFinish: '1e (x1)', highestGrid: '2e (x1)', hatTricks: 0, realWorldFactsNl: ['Won spectaculair op Monza 2020.', 'Zeer veerkrachtig na demotie.'], realWorldFactsEn: ['Won spectacular at Monza 2020.', 'Very resilient after demotion.']),
  Driver(name: 'Alexander Albon', flag: '🇹🇭', points: 0, number: 23, nationality: 'Thai', team: 'Williams', pointsFinishPct: 45.2, seasonPointsFinishPct: 54.1, wins: 0, podiums2nd: 0, podiums3rd: 2, podiums: 2, poles: 0, fastestLaps: 0, totalPoints: 315.0, championships: 0, lapsRaced: 6102, starts: 105, dnfs: 14, dsqs: 0, dnqs: 0, lapsLed: 1, frontRowStarts: 0, highestFinish: '3e (x2)', highestGrid: '4e (x1)', hatTricks: 0, realWorldFactsNl: ['Staat bekend als banden-fluisteraar.', 'Kwam knap terug na jaar afwezigheid.'], realWorldFactsEn: ['Known as the tire whisperer.', 'Strong comeback after a year off.']),
  Driver(name: 'Lance Stroll', flag: '🇨🇦', points: 0, number: 18, nationality: 'Canadian', team: 'Aston Martin', pointsFinishPct: 42.0, seasonPointsFinishPct: 20.8, wins: 0, podiums2nd: 0, podiums3rd: 3, podiums: 3, poles: 1, fastestLaps: 0, totalPoints: 311.0, championships: 0, lapsRaced: 9145, starts: 167, dnfs: 32, dsqs: 0, dnqs: 0, lapsLed: 32, frontRowStarts: 1, highestFinish: '3e (x3)', highestGrid: '1e (x1)', hatTricks: 0, realWorldFactsNl: ['Reed race met gebroken polsen.', 'Pole in natte Turkije 2020.'], realWorldFactsEn: ['Raced with broken wrists.', 'Pole in wet Turkey 2020.']),
  Driver(name: 'Yuki Tsunoda', flag: '🇯🇵', points: 0, number: 22, nationality: 'Japanese', team: 'Racing Bulls', pointsFinishPct: 38.0, seasonPointsFinishPct: 33.3, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 1, totalPoints: 94.0, championships: 0, lapsRaced: 5214, starts: 90, dnfs: 14, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '4e (x1)', highestGrid: '6e (x1)', hatTricks: 0, realWorldFactsNl: ['Bekend om boordradio uitbarstingen.', 'Zwaar gesteund door Honda.'], realWorldFactsEn: ['Known for radio outbursts.', 'Heavily backed by Honda.']),
  Driver(name: 'Kimi Antonelli', flag: '🇮🇹', points: 0, number: 12, nationality: 'Italian', team: 'Mercedes', pointsFinishPct: 60.0, seasonPointsFinishPct: 60.0, wins: 0, podiums2nd: 1, podiums3rd: 2, podiums: 3, poles: 0, fastestLaps: 1, totalPoints: 150.0, championships: 0, lapsRaced: 1244, starts: 24, dnfs: 3, dsqs: 0, dnqs: 0, lapsLed: 12, frontRowStarts: 1, highestFinish: '2e (x1)', highestGrid: '2e (x1)', hatTricks: 0, realWorldFactsNl: ['Sloeg F3 over voor F2.', 'Gezien als Hamiltons opvolger.'], realWorldFactsEn: ['Skipped F3 for F2.', 'Seen as Hamiltons successor.']),
  Driver(name: 'Liam Lawson', flag: '🇳🇿', points: 0, number: 30, nationality: 'New Zealander', team: 'Racing Bulls', pointsFinishPct: 30.0, seasonPointsFinishPct: 29.1, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 40.0, championships: 0, lapsRaced: 1453, starts: 29, dnfs: 2, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '9e (x1)', highestGrid: '10e (x1)', hatTricks: 0, realWorldFactsNl: ['IJzersterke invaller in 2023.', 'Miste nipt de Super Formula titel.'], realWorldFactsEn: ['Very strong substitute in 2023.', 'Narrowly missed Super Formula title.']),
  Driver(name: 'Oliver Bearman', flag: '🇬🇧', points: 0, number: 87, nationality: 'British', team: 'Haas F1 Team', pointsFinishPct: 40.0, seasonPointsFinishPct: 40.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 47.0, championships: 0, lapsRaced: 1289, starts: 25, dnfs: 3, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '7e (x2)', highestGrid: '8e (x1)', hatTricks: 0, realWorldFactsNl: ['Scoorde direct in F1 debuut op 18-jarige leeftijd.', 'Deel van de Ferrari Driver Academy.'], realWorldFactsEn: ['Scored immediately in F1 debut at 18.', 'Part of the Ferrari Driver Academy.']),
  Driver(name: 'Gabriel Bortoleto', flag: '🇧🇷', points: 0, number: 5, nationality: 'Brazilian', team: 'Audi', pointsFinishPct: 15.0, seasonPointsFinishPct: 15.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 19.0, championships: 0, lapsRaced: 1012, starts: 24, dnfs: 4, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '8e (x1)', highestGrid: '11e (x1)', hatTricks: 0, realWorldFactsNl: ['Won FIA F3 als rookie.', 'Gemanaged door Fernando Alonso.'], realWorldFactsEn: ['Won FIA F3 as rookie.', 'Managed by Fernando Alonso.']),
  Driver(name: 'Isack Hadjar', flag: '🇫🇷', points: 0, number: 6, nationality: 'French', team: 'Red Bull Racing', pointsFinishPct: 35.0, seasonPointsFinishPct: 35.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 51.0, championships: 0, lapsRaced: 1152, starts: 24, dnfs: 2, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '6e (x1)', highestGrid: '7e (x1)', hatTricks: 0, realWorldFactsNl: ['Bijnaam "De kleine Prost".', 'Franse en Algerijnse roots.'], realWorldFactsEn: ['Nickname "The little Prost".', 'French and Algerian roots.']),
  Driver(name: 'Franco Colapinto', flag: '🇦🇷', points: 0, number: 43, nationality: 'Argentine', team: 'Alpine', pointsFinishPct: 0.0, seasonPointsFinishPct: 0.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0.0, championships: 0, lapsRaced: 923, starts: 18, dnfs: 2, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: '12e (x1)', highestGrid: '12e (x1)', hatTricks: 0, realWorldFactsNl: ['Zorgde voor F1 gekte in Argentinië.', 'Enorme fanatieke fanbase.'], realWorldFactsEn: ['Sparked F1 mania in Argentina.', 'Huge fanatic fanbase.']),
  Driver(name: 'Arvid Lindblad', flag: '🇬🇧', points: 0, number: 41, nationality: 'British', team: 'Racing Bulls', pointsFinishPct: 0.0, seasonPointsFinishPct: 0.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0.0, championships: 0, lapsRaced: 0, starts: 0, dnfs: 0, dsqs: 0, dnqs: 0, lapsLed: 0, frontRowStarts: 0, highestFinish: 'N.v.t.', highestGrid: 'N.v.t.', hatTricks: 0, realWorldFactsNl: ['Groot talent Red Bull Academy.', 'Jongste coureur nieuwe generatie.'], realWorldFactsEn: ['Top talent Red Bull Academy.', 'Youngest driver new generation.']),
  Driver(name: 'Sergio Pérez', flag: '🇲🇽', points: 0, number: 11, nationality: 'Mexican', team: 'Cadillac', pointsFinishPct: 65.0, seasonPointsFinishPct: 50.0, wins: 6, podiums2nd: 15, podiums3rd: 18, podiums: 39, poles: 3, fastestLaps: 12, totalPoints: 1637.0, championships: 0, lapsRaced: 15123, starts: 280, dnfs: 31, dsqs: 0, dnqs: 0, lapsLed: 400, frontRowStarts: 10, highestFinish: '1e (x6)', highestGrid: '1e (x3)', hatTricks: 0, realWorldFactsNl: ['Minister of Defence.', 'Meester op stratencircuits.'], realWorldFactsEn: ['Minister of Defence.', 'Master of street circuits.']),
  Driver(name: 'Valtteri Bottas', flag: '🇫🇮', points: 0, number: 77, nationality: 'Finnish', team: 'Cadillac', pointsFinishPct: 70.0, seasonPointsFinishPct: 15.0, wins: 10, podiums2nd: 30, podiums3rd: 27, podiums: 67, poles: 20, fastestLaps: 19, totalPoints: 1797.0, championships: 0, lapsRaced: 13500, starts: 250, dnfs: 25, dsqs: 0, dnqs: 0, lapsLed: 650, frontRowStarts: 45, highestFinish: '1e (x10)', highestGrid: '1e (x20)', hatTricks: 2, realWorldFactsNl: ['Vijf constructeurstitels met Mercedes.', 'Brengt humor en ervaring naar Cadillac.'], realWorldFactsEn: ['Five constructors titles with Mercedes.', 'Brings humor and experience to Cadillac.']),
];

final List<Team> fallbackTeams = [
  Team(name: 'McLaren', flag: '🇬🇧', points: 0, fastestPitstopTime: '1.80s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Qatar', ccWins: 10, dcWins: 13, podiums: 520, oneTwo: 49, hattricks: 28, doublePodiums: 110, totalPoints: 7200.5, frontRow: 145, poles: 165, fastestLaps: 170, racesLed: 380, principalName: 'Andrea Stella', principalAge: 54, principalFlag: '🇮🇹', totalEntries: 967),
  Team(name: 'Mercedes', flag: '🇩🇪', points: 0, fastestPitstopTime: '1.98s', fastestPitstopYear: 2022, fastestPitstopCircuit: 'Mexico', ccWins: 8, dcWins: 9, podiums: 295, oneTwo: 59, hattricks: 30, doublePodiums: 125, totalPoints: 7500.5, frontRow: 160, poles: 139, fastestLaps: 107, racesLed: 240, principalName: 'Toto Wolff', principalAge: 53, principalFlag: '🇦🇹', totalEntries: 314),
  Team(name: 'Red Bull Racing', flag: '🇦🇹', points: 0, fastestPitstopTime: '1.82s', fastestPitstopYear: 2019, fastestPitstopCircuit: 'Brazil', ccWins: 6, dcWins: 7, podiums: 280, oneTwo: 32, hattricks: 25, doublePodiums: 85, totalPoints: 7400.0, frontRow: 130, poles: 102, fastestLaps: 98, racesLed: 210, principalName: 'Christian Horner', principalAge: 51, principalFlag: '🇬🇧', totalEntries: 390),
  Team(name: 'Ferrari', flag: '🇮🇹', points: 0, fastestPitstopTime: '1.93s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Qatar', ccWins: 16, dcWins: 15, podiums: 810, oneTwo: 85, hattricks: 42, doublePodiums: 180, totalPoints: 10250.0, frontRow: 260, poles: 251, fastestLaps: 261, racesLed: 520, principalName: 'Frédéric Vasseur', principalAge: 56, principalFlag: '🇫🇷', totalEntries: 1095),
  Team(name: 'Williams', flag: '🇬🇧', points: 0, fastestPitstopTime: '1.92s', fastestPitstopYear: 2016, fastestPitstopCircuit: 'Azerbaijan', ccWins: 9, dcWins: 7, podiums: 313, oneTwo: 33, hattricks: 18, doublePodiums: 65, totalPoints: 3620.0, frontRow: 120, poles: 128, fastestLaps: 133, racesLed: 180, principalName: 'James Vowles', principalAge: 55, principalFlag: '🇬🇧', totalEntries: 826),
  Team(name: 'Racing Bulls', flag: '🇮🇹', points: 0, fastestPitstopTime: '2.10s', fastestPitstopYear: 2024, fastestPitstopCircuit: 'Bahrain', ccWins: 0, dcWins: 0, podiums: 3, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 310.0, frontRow: 1, poles: 0, fastestLaps: 2, racesLed: 1, principalName: 'Laurent Mekies', principalAge: 47, principalFlag: '🇫🇷', totalEntries: 368),
  Team(name: 'Aston Martin', flag: '🇬🇧', points: 0, fastestPitstopTime: '2.15s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Spain', ccWins: 0, dcWins: 0, podiums: 9, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 420.0, frontRow: 2, poles: 1, fastestLaps: 1, racesLed: 3, principalName: 'Mike Krack', principalAge: 52, principalFlag: '🇱🇺', totalEntries: 94),
  Team(name: 'Haas F1 Team', flag: '🇺🇸', points: 0, fastestPitstopTime: '2.25s', fastestPitstopYear: 2022, fastestPitstopCircuit: 'USA', ccWins: 0, dcWins: 0, podiums: 0, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 315.0, frontRow: 0, poles: 1, fastestLaps: 2, racesLed: 0, principalName: 'Ayao Komatsu', principalAge: 49, principalFlag: '🇯🇵', totalEntries: 188),
  Team(name: 'Audi', flag: '🇩🇪', points: 0, fastestPitstopTime: '2.30s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Monaco', ccWins: 0, dcWins: 0, podiums: 27, oneTwo: 1, hattricks: 0, doublePodiums: 2, totalPoints: 920.0, frontRow: 5, poles: 1, fastestLaps: 5, racesLed: 10, principalName: 'Mattia Binotto', principalAge: 55, principalFlag: '🇮🇹', totalEntries: 400),
  Team(name: 'Alpine', flag: '🇫🇷', points: 0, fastestPitstopTime: '2.18s', fastestPitstopYear: 2024, fastestPitstopCircuit: 'Japan', ccWins: 2, dcWins: 2, podiums: 105, oneTwo: 2, hattricks: 1, doublePodiums: 5, totalPoints: 2150.0, frontRow: 25, poles: 51, fastestLaps: 33, racesLed: 45, principalName: 'Oliver Oakes', principalAge: 59, principalFlag: '🇬🇧', totalEntries: 90),
  Team(name: 'Cadillac', flag: '🇺🇸', points: 0, fastestPitstopTime: '2.40s', fastestPitstopYear: 2026, fastestPitstopCircuit: 'USA', ccWins: 0, dcWins: 0, podiums: 0, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 0.0, frontRow: 0, poles: 0, fastestLaps: 0, racesLed: 0, principalName: 'Michael Andretti', principalAge: 63, principalFlag: '🇺🇸', totalEntries: 0),
];