import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('nl');
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'en' ? const Locale('nl') : const Locale('en');
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Races',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('nl')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeScreen(
        onToggleLocale: _toggleLocale,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

/// --- localization support ----------------------------------------------

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'F1 Races',
      'circuits': 'Circuits',
      'standings': 'Standings',
      'drivers': 'Drivers',
      'teams': 'Teams',
      'nextRace': 'Next race',
      'raceStarts': 'Race starts',
      'days': 'days',
      'day': 'day',
      'weeks': 'weeks',
      'week': 'week',
      'hours': 'hours',
      'minutes': 'minutes',
      'weather': 'Weather',
      'country': 'Country',
      'timeUntil': 'until',
      'startsIn': 'Starts in:',
      'fastestLap': 'Fastest lap ever',
      'slowestLap': 'Slowest lap ever',
      'avgLap': 'Average lap time',
      'laps': 'Number of laps',
      'redFlag': 'Chance of red flag',
      'vsc': 'Chance of VSC',
      'accident': 'Chance of accident',
      'accidentTurn1': 'Chance of accident in turn 1',
      'tireWear': 'Tire wear',
      'strategy': 'Tire strategy',
      'fastestPit': 'Fastest pitstop',
      'forecast': 'Weather Forecast',
      'temp': 'Temperature',
      'rainChance': 'Chance of rain',
      'rainAmount': 'Rainfall',
      'wind': 'Wind speed',
      'humidity': 'Humidity',
      'pressure': 'Pressure',
      'feelsLike': 'Feels like',
      'lapStats': 'Lap Stats',
      'risks': 'Risks',
      'tyres': 'Tyres & Pit',
      'general': 'General',
      'totalLength': 'Circuit Length',
      'characteristics': 'Unique Characteristics',
      'raceFinished': 'Race finished',
      'pts': 'pts',
      // Settings
      'settings': 'Settings',
      'toggleTheme': 'Toggle Light/Dark',
      'toggleLanguage': 'Switch Language',
      // Circuit specific
      'first_gp': 'First Grand Prix',
      'contract_until': 'Contract Until',
      // Overtaking
      'overtaking': 'Overtaking',
      'overtake_very_easy': 'Very Easy',
      'overtake_easy': 'Easy',
      'overtake_average': 'Average',
      'overtake_difficult': 'Difficult',
      'overtake_very_difficult': 'Very Difficult',
      // Driver Stats
      'driver_number': 'Driver Number',
      'nationality': 'Nationality',
      'current_team': 'Current Team',
      'points_finish_pct': 'Finished in Points (%)',
      'wins': 'Wins (1st)',
      'second_place': '2nd Place',
      'third_place': '3rd Place',
      'podiums': 'Total Podiums',
      'poles': 'Pole Positions',
      'fastest_laps': 'Fastest Laps',
      'total_points': 'Total Points',
      'championships': 'Championships',
      'laps_raced': 'Laps Raced',
      'starts': 'Starts',
      'dnf': 'DNFs',
      'dsq': 'DSQs',
      'dnq': 'DNQs',
      'driver_info': 'Driver Information',
      'career_stats': 'Career Statistics',
      'experience': 'Experience',
      // Team Stats
      'team_info': 'Team Information',
      'cc_wins': 'Constructors\' Championships',
      'dc_wins': 'Drivers\' Championships',
      'one_two': '1-2 Finishes',
      'hattricks': 'Hattricks',
      'double_podiums': 'Double Podiums',
      'front_row': 'Front Row Starts',
      'laps_led': 'Races Led',
      'team_principal': 'Team Principal',
      'total_entries': 'Total Grands Prix Entered',
      'race_stats': 'Race Statistics',
      'pitstop_leadership': 'Pitstop & Leadership',
      'using_fallback_data': 'No 2026 data available yet. Showing 2025 standings.',
      // Dynamic Data Translations
      'tbd': 'TBD',
      'wear_High': 'High',
      'wear_Medium': 'Medium',
      'wear_Low': 'Low',
      'wear_Very High': 'Very High',
      'strategy_1 stop': '1 stop',
      'strategy_2 stops': '2 stops',
      'soft_tire': 'Soft',
      'medium_tire': 'Medium',
      'hard_tire': 'Hard',
      // Countries
      'country_Australia': 'Australia',
      'country_China': 'China',
      'country_Japan': 'Japan',
      'country_Bahrain': 'Bahrain',
      'country_Saudi Arabia': 'Saudi Arabia',
      'country_USA': 'USA',
      'country_Canada': 'Canada',
      'country_Monaco': 'Monaco',
      'country_Spain': 'Spain',
      'country_Austria': 'Austria',
      'country_United Kingdom': 'United Kingdom',
      'country_Belgium': 'Belgium',
      'country_Hungary': 'Hungary',
      'country_Netherlands': 'Netherlands',
      'country_Italy': 'Italy',
      'country_Azerbaijan': 'Azerbaijan',
      'country_Singapore': 'Singapore',
      'country_Mexico': 'Mexico',
      'country_Brazil': 'Brazil',
      'country_Qatar': 'Qatar',
      'country_UAE': 'UAE',
      // Race Names
      'gp_Australian Grand Prix': 'Australian Grand Prix',
      'gp_Chinese Grand Prix': 'Chinese Grand Prix',
      'gp_Japanese Grand Prix': 'Japanese Grand Prix',
      'gp_Bahrain Grand Prix': 'Bahrain Grand Prix',
      'gp_Saudi Arabian Grand Prix': 'Saudi Arabian Grand Prix',
      'gp_Miami Grand Prix': 'Miami Grand Prix',
      'gp_Canadian Grand Prix': 'Canadian Grand Prix',
      'gp_Monaco Grand Prix': 'Monaco Grand Prix',
      'gp_Spanish Grand Prix': 'Spanish Grand Prix',
      'gp_Madrid Grand Prix': 'Madrid Grand Prix',
      'gp_Austrian Grand Prix': 'Austrian Grand Prix',
      'gp_British Grand Prix': 'British Grand Prix',
      'gp_Belgian Grand Prix': 'Belgian Grand Prix',
      'gp_Hungarian Grand Prix': 'Hungarian Grand Prix',
      'gp_Dutch Grand Prix': 'Dutch Grand Prix',
      'gp_Italian Grand Prix': 'Italian Grand Prix',
      'gp_Azerbaijan Grand Prix': 'Azerbaijan Grand Prix',
      'gp_Singapore Grand Prix': 'Singapore Grand Prix',
      'gp_United States Grand Prix': 'United States Grand Prix',
      'gp_Mexico City Grand Prix': 'Mexico City Grand Prix',
      'gp_Brazilian Grand Prix': 'Brazilian Grand Prix',
      'gp_Las Vegas Grand Prix': 'Las Vegas Grand Prix',
      'gp_Qatar Grand Prix': 'Qatar Grand Prix',
      'gp_Abu Dhabi Grand Prix': 'Abu Dhabi Grand Prix',
    },
    'nl': {
      'appTitle': 'F1 Races',
      'circuits': 'Circuits',
      'standings': 'Standen',
      'drivers': 'Coureurs',
      'teams': 'Teams',
      'nextRace': 'Volgende race',
      'raceStarts': 'Race begint',
      'days': 'dagen',
      'day': 'dag',
      'weeks': 'weken',
      'week': 'week',
      'hours': 'uur',
      'minutes': 'minuten',
      'weather': 'Weer',
      'country': 'Land',
      'timeUntil': 'tot',
      'startsIn': 'Start over:',
      'fastestLap': 'Snelste ronde ooit',
      'slowestLap': 'Traagste ronde ooit',
      'avgLap': 'Gemiddelde rondetijd',
      'laps': 'Aantal rondes',
      'redFlag': 'Kans op rode vlag',
      'vsc': 'Kans op VSC',
      'accident': 'Kans op ongeluk',
      'accidentTurn1': 'Kans op ongeluk in bocht 1',
      'tireWear': 'Bandenslijtage',
      'strategy': 'Bandenstrategie',
      'fastestPit': 'Snelste pitstop',
      'forecast': 'Weersverwachting',
      'temp': 'Temperatuur',
      'rainChance': 'Kans op regen',
      'rainAmount': 'Regenval',
      'wind': 'Windsnelheid',
      'humidity': 'Luchtvochtigheid',
      'pressure': 'Luchtdruk',
      'feelsLike': 'Voelt als',
      'lapStats': 'Rondestatistieken',
      'risks': 'Risico\'s',
      'tyres': 'Banden & Pitstop',
      'general': 'Algemeen',
      'totalLength': 'Circuit lengte',
      'characteristics': 'Unieke Kenmerken',
      'raceFinished': 'Race afgelopen',
      'pts': 'ptn',
      // Settings
      'settings': 'Instellingen',
      'toggleTheme': 'Wissel Thema (Licht/Donker)',
      'toggleLanguage': 'Wissel Taal',
      // Circuit specific
      'first_gp': 'Eerste Grand Prix',
      'contract_until': 'Contract tot',
      // Overtaking
      'overtaking': 'Inhalen',
      'overtake_very_easy': 'Zeer Makkelijk',
      'overtake_easy': 'Makkelijk',
      'overtake_average': 'Gemiddeld',
      'overtake_difficult': 'Moeilijk',
      'overtake_very_difficult': 'Zeer Moeilijk',
      // Driver Stats
      'driver_number': 'Rijdersnummer',
      'nationality': 'Nationaliteit',
      'current_team': 'Huidig team',
      'points_finish_pct': 'Gefinisht met punten (%)',
      'wins': '1e Plaats (Wins)',
      'second_place': '2e Plaats',
      'third_place': '3e Plaats',
      'podiums': 'Totaal Podiums',
      'poles': 'Pole Positions',
      'fastest_laps': 'Snelste Rondes',
      'total_points': 'Totaal aantal punten',
      'championships': 'Kampioenschappen',
      'laps_raced': 'Aantal rondes geraced',
      'starts': 'Aantal keer gestart',
      'dnf': 'Aantal keer DNF',
      'dsq': 'Aantal keer DSQ',
      'dnq': 'Aantal keer DNQ',
      'driver_info': 'Coureurs Informatie',
      'career_stats': 'Carrière Statistieken',
      'experience': 'Ervaring',
      // Team Stats
      'team_info': 'Team Informatie',
      'cc_wins': 'Constructeurskampioenschappen',
      'dc_wins': 'Coureurskampioenschappen',
      'one_two': 'Aantal keer 1-2',
      'hattricks': 'Hattricks',
      'double_podiums': 'Dubbel podium',
      'front_row': 'Starts Eerste Rij',
      'laps_led': 'Races aan kop',
      'team_principal': 'Huidige teambaas',
      'total_entries': 'Aantal deelgenomen GP\'s',
      'race_stats': 'Race Statistieken',
      'pitstop_leadership': 'Pitstop & Leiding',
      'using_fallback_data': 'Nog geen 2026 data beschikbaar. Weergave toont actuele 2025 eindstanden.',
      // Dynamic Data Translations
      'tbd': 'N.n.b.',
      'wear_High': 'Hoog',
      'wear_Medium': 'Gemiddeld',
      'wear_Low': 'Laag',
      'wear_Very High': 'Zeer Hoog',
      'strategy_1 stop': '1 stop',
      'strategy_2 stops': '2 stops',
      'soft_tire': 'Zacht',
      'medium_tire': 'Medium',
      'hard_tire': 'Hard',
      // Countries
      'country_Australia': 'Australië',
      'country_China': 'China',
      'country_Japan': 'Japan',
      'country_Bahrain': 'Bahrein',
      'country_Saudi Arabia': 'Saoedi-Arabië',
      'country_USA': 'Verenigde Staten',
      'country_Canada': 'Canada',
      'country_Monaco': 'Monaco',
      'country_Spain': 'Spanje',
      'country_Austria': 'Oostenrijk',
      'country_United Kingdom': 'Groot-Brittannië',
      'country_Belgium': 'België',
      'country_Hungary': 'Hongarije',
      'country_Netherlands': 'Nederland',
      'country_Italy': 'Italië',
      'country_Azerbaijan': 'Azerbeidzjan',
      'country_Singapore': 'Singapore',
      'country_Mexico': 'Mexico',
      'country_Brazil': 'Brazilië',
      'country_Qatar': 'Qatar',
      'country_UAE': 'Verenigde Arabische Emiraten',
      // Race Names
      'gp_Australian Grand Prix': 'GP van Australië',
      'gp_Chinese Grand Prix': 'GP van China',
      'gp_Japanese Grand Prix': 'GP van Japan',
      'gp_Bahrain Grand Prix': 'GP van Bahrein',
      'gp_Saudi Arabian Grand Prix': 'GP van Saoedi-Arabië',
      'gp_Miami Grand Prix': 'GP van Miami',
      'gp_Canadian Grand Prix': 'GP van Canada',
      'gp_Monaco Grand Prix': 'GP van Monaco',
      'gp_Spanish Grand Prix': 'GP van Spanje',
      'gp_Madrid Grand Prix': 'GP van Madrid',
      'gp_Austrian Grand Prix': 'GP van Oostenrijk',
      'gp_British Grand Prix': 'GP van Groot-Brittannië',
      'gp_Belgian Grand Prix': 'GP van België',
      'gp_Hungarian Grand Prix': 'GP van Hongarije',
      'gp_Dutch Grand Prix': 'GP van Nederland',
      'gp_Italian Grand Prix': 'GP van Italië',
      'gp_Azerbaijan Grand Prix': 'GP van Azerbeidzjan',
      'gp_Singapore Grand Prix': 'GP van Singapore',
      'gp_United States Grand Prix': 'GP van de VS',
      'gp_Mexico City Grand Prix': 'GP van Mexico',
      'gp_Brazilian Grand Prix': 'GP van Brazilië',
      'gp_Las Vegas Grand Prix': 'GP van Las Vegas',
      'gp_Qatar Grand Prix': 'GP van Qatar',
      'gp_Abu Dhabi Grand Prix': 'GP van Abu Dhabi',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'nl'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

/// --- data models ---------------------------------------------------------

class Race {
  final String name;
  final String country;
  final String flag;
  final DateTime date;
  final int laps;
  final int length;
  final WeatherForecast weather;
  final LapRecord fastestLap;
  final LapRecord slowestLap;
  final String averageLap;
  final int redFlagChance;
  final int vscChance;
  final int accidentChance;
  final int turn1AccidentChance;
  final String tireWear;
  final String tireStrategy;
  final String bestCombination;
  final PitstopRecord fastestPitstop;
  final String overtakingDifficulty;
  final int firstGrandPrix; 
  final String contractUntil; 
  final List<String> characteristicsEn;
  final List<String> characteristicsNl;

  Race({
    required this.name, required this.country, required this.flag,
    required this.date, required this.laps, required this.length,
    required this.weather, required this.fastestLap, required this.slowestLap,
    required this.averageLap, required this.redFlagChance, required this.vscChance,
    required this.accidentChance, required this.turn1AccidentChance,
    required this.tireWear, required this.tireStrategy, required this.bestCombination,
    required this.fastestPitstop, required this.overtakingDifficulty,
    required this.firstGrandPrix, required this.contractUntil, 
    required this.characteristicsEn, required this.characteristicsNl,
  });
}

class WeatherForecast {
  final int temperature;
  final int rainChance;
  final int rainAmount;
  final int windSpeed;
  final int humidity;
  final int pressure;
  final int feelsLike;

  WeatherForecast({
    required this.temperature, required this.rainChance, required this.rainAmount,
    required this.windSpeed, required this.humidity, required this.pressure,
    required this.feelsLike,
  });
}

class LapRecord {
  final String driver;
  final String team;
  final int year;
  final String time;

  LapRecord(this.driver, this.team, this.year, this.time);
}

class PitstopRecord {
  final String team;
  final int year;
  final String time;

  PitstopRecord(this.team, this.year, this.time);
}

class Driver {
  final String name;
  final String flag;
  int points;
  final int number;
  final String nationality;
  final String team;
  final double pointsFinishPct;
  final int wins; 
  final int podiums2nd; 
  final int podiums3rd; 
  final int podiums; 
  final int poles;
  final int fastestLaps;
  final double totalPoints;
  final int championships;
  final int lapsRaced;
  final int starts;
  final int dnfs;
  final int dsqs;
  final int dnqs;

  Driver({
    required this.name, required this.flag, required this.points,
    required this.number, required this.nationality, required this.team,
    required this.pointsFinishPct, required this.wins, required this.podiums2nd,
    required this.podiums3rd, required this.podiums, required this.poles,
    required this.fastestLaps, required this.totalPoints, required this.championships,
    required this.lapsRaced, required this.starts, required this.dnfs,
    required this.dsqs, required this.dnqs,
  });
}

class Team {
  final String name;
  final String flag;
  int points;
  final String fastestPitstopTime;
  final int fastestPitstopYear;
  final String fastestPitstopCircuit;
  final int ccWins;
  final int dcWins;
  final int podiums;
  final int oneTwo;
  final int hattricks;
  final int doublePodiums;
  final double totalPoints;
  final int frontRow;
  final int poles;
  final int fastestLaps;
  final int racesLed;
  final String principalName;
  final int principalAge;
  final String principalFlag;
  final int totalEntries;

  Team({
    required this.name, required this.flag, required this.points,
    required this.fastestPitstopTime, required this.fastestPitstopYear, required this.fastestPitstopCircuit,
    required this.ccWins, required this.dcWins, required this.podiums,
    required this.oneTwo, required this.hattricks, required this.doublePodiums,
    required this.totalPoints, required this.frontRow, required this.poles,
    required this.fastestLaps, required this.racesLed, required this.principalName,
    required this.principalAge, required this.principalFlag, required this.totalEntries,
  });
}

/// --- mock data (fallback / full list) ------------------------------------

final List<Race> races = [
  Race(
    name: 'Australian Grand Prix', country: 'Australia', flag: '🇦🇺',
    date: DateTime(2026, 3, 8, 5, 0), laps: 58, length: 5303,
    weather: WeatherForecast(temperature: 22, rainChance: 20, rainAmount: 2, windSpeed: 14, humidity: 55, pressure: 1015, feelsLike: 21),
    fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2022, '1:20.260'), slowestLap: LapRecord('Robert Kubica', 'Alfa Romeo', 2019, '1:35.000'),
    averageLap: '1:23.000', redFlagChance: 8, vscChance: 12, accidentChance: 18, turn1AccidentChance: 10,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('Ferrari', 2022, '2.3s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 1996, contractUntil: '2037',
    characteristicsEn: ['Street circuit around Albert Park Lake', 'Features 4 DRS zones for maximum overtaking', 'Known for fast, sweeping corners', 'Often experiences unpredictable weather', 'Lots of shade from surrounding trees'],
    characteristicsNl: ['Stratencircuit rondom het Albert Park meer', 'Beschikt over 4 DRS-zones voor inhaalacties', 'Staat bekend om snelle, vloeiende bochten', 'Vaak onvoorspelbaar wisselvallig weer', 'Veel schaduw van omliggende bomen'],
  ),
  Race(
    name: 'Chinese Grand Prix', country: 'China', flag: '🇨🇳',
    date: DateTime(2026, 3, 15, 8, 0), laps: 56, length: 5451,
    weather: WeatherForecast(temperature: 17, rainChance: 25, rainAmount: 3, windSpeed: 12, humidity: 50, pressure: 1013, feelsLike: 16),
    fastestLap: LapRecord('Michael Schumacher', 'Ferrari', 2004, '1:32.238'), slowestLap: LapRecord('Marcus Ericsson', 'Sauber', 2018, '1:45.000'),
    averageLap: '1:35.000', redFlagChance: 7, vscChance: 10, accidentChance: 14, turn1AccidentChance: 8,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Williams', 2019, '2.2s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 2004, contractUntil: '2025',
    characteristicsEn: ['Famous "Snail corner" (Turns 1 and 2)', 'Massive 1.2km back straight', 'Built on a foundation of polystyrene', 'Very high front-left tire wear', 'Impressive massive paddock architecture'],
    characteristicsNl: ['Beroemde slakkenhuisbocht (Bocht 1 en 2)', 'Enorm lang recht stuk van 1.2km', 'Fundering deels gebouwd op piepschuim', 'Zeer hoge slijtage linksvoor-band', 'Indrukwekkende gigantische paddock architectuur'],
  ),
  Race(
    name: 'Japanese Grand Prix', country: 'Japan', flag: '🇯🇵',
    date: DateTime(2026, 3, 29, 7, 0), laps: 53, length: 5807,
    weather: WeatherForecast(temperature: 19, rainChance: 30, rainAmount: 5, windSpeed: 16, humidity: 60, pressure: 1018, feelsLike: 18),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2019, '1:30.983'), slowestLap: LapRecord('Pierre Gasly', 'AlphaTauri', 2020, '1:40.000'),
    averageLap: '1:33.000', redFlagChance: 12, vscChance: 18, accidentChance: 22, turn1AccidentChance: 15,
    tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2021, '2.1s'),
    overtakingDifficulty: 'overtake_difficult',
    firstGrandPrix: 1987, contractUntil: '2029',
    characteristicsEn: ['Unique figure-8 layout with an overpass', 'Legendary ultra-fast 130R corner', 'Originally designed as a Honda test track', 'Extremely passionate and dedicated fans', 'Punishing first sector S-curves'],
    characteristicsNl: ['Unieke 8-vormige lay-out met een brug', 'Legendarische razendsnelle 130R bocht', 'Oorspronkelijk ontworpen als Honda testcircuit', 'Extreem gepassioneerde Japanse fans', 'Zeer meedogenloze S-bochten in sector 1'],
  ),
  Race(
    name: 'Bahrain Grand Prix', country: 'Bahrain', flag: '🇧🇭',
    date: DateTime(2026, 4, 12, 17, 0), laps: 57, length: 5412,
    weather: WeatherForecast(temperature: 28, rainChance: 0, rainAmount: 0, windSpeed: 12, humidity: 40, pressure: 1012, feelsLike: 29),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2020, '1:32.014'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:45.000'),
    averageLap: '1:35.000', redFlagChance: 5, vscChance: 10, accidentChance: 15, turn1AccidentChance: 7,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_very_easy',
    firstGrandPrix: 2004, contractUntil: '2036',
    characteristicsEn: ['Twilight/Night race under floodlights', 'High brake wear due to heavy stopping zones', 'Track is surrounded by the desert', 'First ever F1 race held in the Middle East', 'Notoriously difficult Turn 10 with a blind apex'],
    characteristicsNl: ['Schemer/Nachtrace verlicht door duizenden lampen', 'Hoge remslijtage door harde remzones', 'Circuit ligt midden in de woestijn', 'De allereerste F1-race in het Midden-Oosten', 'Beruchte lastige bocht 10 met een blinde apex'],
  ),
  Race(
    name: 'Saudi Arabian Grand Prix', country: 'Saudi Arabia', flag: '🇸🇦',
    date: DateTime(2026, 4, 19, 19, 0), laps: 50, length: 6150,
    weather: WeatherForecast(temperature: 26, rainChance: 0, rainAmount: 0, windSpeed: 10, humidity: 35, pressure: 1010, feelsLike: 27),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:30.734'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:45.000'),
    averageLap: '1:33.000', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 12,
    tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard',
    fastestPitstop: PitstopRecord('McLaren', 2023, '2.2s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 2021, contractUntil: '2030',
    characteristicsEn: ['Fastest street circuit on the calendar', 'Extremely narrow with zero run-off', 'High-speed blind corners', 'Night race format', 'Situated directly along the Red Sea coast'],
    characteristicsNl: ['Snelste stratencircuit op de hele kalender', 'Extreem smal met nauwelijks uitloopstroken', 'Levensgevaarlijke snelle blinde bochten', 'Wordt volledig in de nacht verreden', 'Prachtig gelegen direct aan de Rode Zee'],
  ),
  Race(
    name: 'Miami Grand Prix', country: 'USA', flag: '🇺🇸',
    date: DateTime(2026, 5, 3, 22, 0), laps: 57, length: 5412,
    weather: WeatherForecast(temperature: 30, rainChance: 40, rainAmount: 8, windSpeed: 18, humidity: 65, pressure: 1008, feelsLike: 32),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:29.708'), slowestLap: LapRecord('Kevin Magnussen', 'Haas', 2022, '1:45.000'),
    averageLap: '1:32.000', redFlagChance: 15, vscChance: 20, accidentChance: 25, turn1AccidentChance: 17,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('McLaren', 2023, '2.1s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 2022, contractUntil: '2031',
    characteristicsEn: ['Built around the Hard Rock Stadium', 'Features a famous fake marina', 'Tight chicane section under a highway', 'Very high track evolution over the weekend', 'Oppressive tropical heat and humidity'],
    characteristicsNl: ['Gebouwd rondom het Hard Rock Stadion', 'Beschikt over een beroemde neppe jachthaven', 'Zeer krappe chicane onder de snelweg door', 'Baan wordt heel snel sneller in het weekend', 'Meedogenloze tropische hitte en luchtvochtigheid'],
  ),
  Race(
    name: 'Canadian Grand Prix', country: 'Canada', flag: '🇨🇦',
    date: DateTime(2026, 5, 24, 22, 0), laps: 70, length: 4361,
    weather: WeatherForecast(temperature: 20, rainChance: 25, rainAmount: 3, windSpeed: 10, humidity: 55, pressure: 1012, feelsLike: 19),
    fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2019, '1:13.078'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:16.000', redFlagChance: 8, vscChance: 12, accidentChance: 18, turn1AccidentChance: 9,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 1978, contractUntil: '2031',
    characteristicsEn: ['The notorious Wall of Champions', 'Groundhogs occasionally run onto the track', 'Classic stop-start heavy braking nature', 'Located on a man-made island (Île Notre-Dame)', 'Weather fluctuates wildly from sun to rain'],
    characteristicsNl: ['De beruchte Wall of Champions bij de finish', 'Regelmatig bosmarmotten op het circuit', 'Klassiek stop-start circuit, zwaar voor de remmen', 'Gelegen op een kunstmatig eiland in Montreal', 'Weer kan bizar snel omslaan van zon naar regen'],
  ),
  Race(
    name: 'Monaco Grand Prix', country: 'Monaco', flag: '🇲🇨',
    date: DateTime(2026, 6, 7, 15, 0), laps: 78, length: 3337,
    weather: WeatherForecast(temperature: 21, rainChance: 10, rainAmount: 1, windSpeed: 8, humidity: 60, pressure: 1017, feelsLike: 21),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:12.909'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:15.000', redFlagChance: 20, vscChance: 25, accidentChance: 30, turn1AccidentChance: 20,
    tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_very_difficult',
    firstGrandPrix: 1950, contractUntil: '2025',
    characteristicsEn: ['The slowest circuit on the calendar', 'The shortest track by distance', 'Literally zero room for driver error', 'Famous ultra-tight Fairmont Hairpin', 'Drivers race flat-out through a tunnel'],
    characteristicsNl: ['Het langzaamste circuit op de kalender', 'De kortste baan qua afstand van allemaal', 'Letterlijk nul marge voor een rijdersfout', 'Wereldberoemde, superkrappe Fairmont-hairpin', 'Coureurs rijden volgas door een smalle tunnel'],
  ),
  Race(
    name: 'Spanish Grand Prix', country: 'Spain', flag: '🇪🇸',
    date: DateTime(2026, 6, 14, 15, 0), laps: 66, length: 4655,
    weather: WeatherForecast(temperature: 25, rainChance: 15, rainAmount: 2, windSpeed: 11, humidity: 45, pressure: 1014, feelsLike: 25),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:16.330'), slowestLap: LapRecord('Carlos Sainz', 'Ferrari', 2022, '1:40.000'),
    averageLap: '1:19.000', redFlagChance: 5, vscChance: 10, accidentChance: 12, turn1AccidentChance: 6,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('Williams', 2022, '2.2s'),
    overtakingDifficulty: 'overtake_difficult',
    firstGrandPrix: 1991, contractUntil: '2026',
    characteristicsEn: ['Ultimate aerodynamic benchmark for F1 cars', 'High-speed Turn 3 is brutal on the neck', 'Final chicane removed for a faster lap', 'Historically the main pre-season testing track', 'High degradation on the front left tire'],
    characteristicsNl: ['Dé aerodynamische graadmeter voor Formule 1-auto\'s', 'Snelle doordraaier bocht 3 is zwaar voor de nek', 'Laatste chicane is verwijderd voor meer snelheid', 'Historisch gezien hét testcircuit in de winter', 'Extreem hoge slijtage op de linker voorband'],
  ),
  Race(
    name: 'Austrian Grand Prix', country: 'Austria', flag: '🇦🇹',
    date: DateTime(2026, 6, 28, 15, 0), laps: 71, length: 4318,
    weather: WeatherForecast(temperature: 23, rainChance: 20, rainAmount: 2, windSpeed: 12, humidity: 50, pressure: 1015, feelsLike: 22),
    fastestLap: LapRecord('Carlos Sainz', 'Ferrari', 2022, '1:07.634'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:10.000', redFlagChance: 6, vscChance: 9, accidentChance: 14, turn1AccidentChance: 7,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 1970, contractUntil: '2030',
    characteristicsEn: ['Fewest corners of any track (only 10)', 'Huge elevation changes in the Styrian mountains', 'Extremely short lap time (just over 1 min)', 'Features 3 DRS zones in a row', 'Home race for Red Bull Racing'],
    characteristicsNl: ['Minste aantal bochten van de kalender (slechts 10)', 'Grote hoogteverschillen in de bergen van Stiermarken', 'Extreem korte rondetijd (iets meer dan 1 minuut)', 'Beschikt over 3 DRS-zones direct achter elkaar', 'De officiële thuisrace van Red Bull Racing'],
  ),
  Race(
    name: 'British Grand Prix', country: 'United Kingdom', flag: '🇬🇧',
    date: DateTime(2026, 7, 5, 16, 0), laps: 52, length: 5891,
    weather: WeatherForecast(temperature: 18, rainChance: 35, rainAmount: 6, windSpeed: 15, humidity: 65, pressure: 1016, feelsLike: 17),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2020, '1:27.097'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:30.000', redFlagChance: 12, vscChance: 18, accidentChance: 22, turn1AccidentChance: 13,
    tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 1950, contractUntil: '2034',
    characteristicsEn: ['Legendary Maggotts-Becketts-Chapel sequence', 'Built on the site of a WWII RAF airfield', 'One of the fastest average speed tracks', 'Site of the first ever F1 World Championship race', 'Highly unpredictable British summer weather'],
    characteristicsNl: ['Legendarische Maggotts-Becketts-Chapel bochten', 'Gebouwd op een voormalig RAF vliegveld uit WO2', 'Eén van de banen met de hoogste gemiddelde snelheid', 'Locatie van de allereerste F1 kampioenschapsrace', 'Zeer onvoorspelbaar Brits zomerweer'],
  ),
  Race(
    name: 'Belgian Grand Prix', country: 'Belgium', flag: '🇧🇪',
    date: DateTime(2026, 7, 19, 15, 0), laps: 44, length: 7004,
    weather: WeatherForecast(temperature: 16, rainChance: 50, rainAmount: 10, windSpeed: 20, humidity: 75, pressure: 1009, feelsLike: 15),
    fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2018, '1:46.286'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:50.000', redFlagChance: 20, vscChance: 25, accidentChance: 30, turn1AccidentChance: 18,
    tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 1950, contractUntil: '2025',
    characteristicsEn: ['Iconic steep uphill Eau Rouge & Raidillon corners', 'Longest circuit on the entire F1 calendar', 'Ardennes forest causes unpredictable micro-climates', 'Old-school natural terrain track layout', 'Very high top speeds on the Kemmel Straight'],
    characteristicsNl: ['Iconische steile helling bij Eau Rouge en Raidillon', 'Met 7km het langste circuit van de hele kalender', 'Microklimaat in de Ardennen zorgt voor gekke buien', 'Authentieke baan die het natuurlijke landschap volgt', 'Gigantische topsnelheden op het Kemmel Straight'],
  ),
  Race(
    name: 'Hungarian Grand Prix', country: 'Hungary', flag: '🇭🇺',
    date: DateTime(2026, 7, 26, 15, 0), laps: 70, length: 4381,
    weather: WeatherForecast(temperature: 27, rainChance: 20, rainAmount: 2, windSpeed: 10, humidity: 55, pressure: 1012, feelsLike: 26),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:17.103'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:20.000', redFlagChance: 8, vscChance: 12, accidentChance: 18, turn1AccidentChance: 9,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_very_difficult',
    firstGrandPrix: 1986, contractUntil: '2032',
    characteristicsEn: ['Often described as "Monaco without the walls"', 'Notoriously difficult circuit for overtaking', 'Track surface is usually very dusty off-line', 'Scorching hot temperatures in the summer', 'Requires maximum downforce car setups'],
    characteristicsNl: ['Wordt vaak "Monaco zonder de muren" genoemd', 'Berucht als een extreem lastig circuit om in te halen', 'Het asfalt is vaak erg stoffig buiten de ideale lijn', 'Meestal bloedheet in de Hongaarse zomer', 'Coureurs rijden hier met maximale downforce afstellingen'],
  ),
  Race(
    name: 'Dutch Grand Prix', country: 'Netherlands', flag: '🇳🇱',
    date: DateTime(2026, 8, 23, 15, 0), laps: 72, length: 4259,
    weather: WeatherForecast(temperature: 20, rainChance: 30, rainAmount: 4, windSpeed: 14, humidity: 60, pressure: 1015, feelsLike: 19),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:11.097'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:14.000', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 12,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_difficult',
    firstGrandPrix: 1952, contractUntil: '2025',
    characteristicsEn: ['Insanely steep banked corners (Tarzan, Hugenholtz)', 'Old-school, narrow, and unforgiving track', 'Nestled directly in the coastal sand dunes', 'Incredible atmosphere created by the Orange Army', 'Very fast flowing rhythm, physically demanding'],
    characteristicsNl: ['Bizarre steile kombochten (Hugenholtz en Luyendyk)', 'Old-school, smalle baan die geen fouten vergeeft', 'Ligt prachtig verscholen in de Noordzeeduinen', 'Zinderende sfeer dankzij het gigantische Oranje Legioen', 'Erg fysiek zwaar door het extreem snelle ritme'],
  ),
  Race(
    name: 'Italian Grand Prix', country: 'Italy', flag: '🇮🇹',
    date: DateTime(2026, 9, 6, 15, 0), laps: 53, length: 5793,
    weather: WeatherForecast(temperature: 24, rainChance: 15, rainAmount: 2, windSpeed: 10, humidity: 50, pressure: 1014, feelsLike: 24),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2020, '1:18.887'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:21.000', redFlagChance: 8, vscChance: 12, accidentChance: 18, turn1AccidentChance: 9,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 1950, contractUntil: '2025',
    characteristicsEn: ['Universally known as the "Temple of Speed"', 'Cars run the lowest downforce of the entire season', 'Features the famous Parabolica sweeping corner', 'Historic oval banking still visible in the park', 'One of the most passionate fanbases (The Tifosi)'],
    characteristicsNl: ['Wereldwijd bekend als de "Temple of Speed"', 'Auto\'s rijden met de allerlaagste downforce van het jaar', 'Thuisbasis van de wereldberoemde Parabolica bocht', 'De oude, historische kombocht is nog steeds zichtbaar', 'Eén van de meest gepassioneerde fanbases (De Tifosi)'],
  ),
  Race(
    name: 'Madrid Grand Prix', country: 'Spain', flag: '🇪🇸',
    date: DateTime(2026, 9, 13, 15, 0), laps: 55, length: 5474,
    weather: WeatherForecast(temperature: 26, rainChance: 10, rainAmount: 1, windSpeed: 12, humidity: 45, pressure: 1015, feelsLike: 27),
    fastestLap: LapRecord('TBD', 'TBD', 2026, 'TBD'), slowestLap: LapRecord('TBD', 'TBD', 2026, 'TBD'),
    averageLap: 'TBD', redFlagChance: 15, vscChance: 20, accidentChance: 25, turn1AccidentChance: 10,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('TBD', 2026, 'TBD'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 2026, contractUntil: '2035',
    characteristicsEn: ['Brand new semi-street circuit introduced for 2026', 'Track runs partly through indoor exhibition halls', 'Planned to feature steep banked corners', 'Highly accessible via public transport in Madrid', 'Located right next to Real Madrid\'s training facility'],
    characteristicsNl: ['Gloednieuw semi-stratencircuit, nieuw voor 2026', 'Het circuit loopt deels dwars door overdekte beurshallen', 'Ontworpen met steile, moderne kombochten', 'Extreem goed bereikbaar met het Madrileense OV', 'Ligt direct naast het trainingscomplex van Real Madrid'],
  ),
  Race(
    name: 'Azerbaijan Grand Prix', country: 'Azerbaijan', flag: '🇦🇿',
    date: DateTime(2026, 9, 27, 13, 0), laps: 51, length: 6003,
    weather: WeatherForecast(temperature: 27, rainChance: 10, rainAmount: 1, windSpeed: 12, humidity: 45, pressure: 1012, feelsLike: 27),
    fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2022, '1:43.009'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:46.000', redFlagChance: 15, vscChance: 20, accidentChance: 25, turn1AccidentChance: 14,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Medium → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 2016, contractUntil: '2026',
    characteristicsEn: ['Features a mammoth 2.2km main straight', 'Incredibly narrow section past the historic castle', 'Street circuit producing very high top speeds', 'Known for chaotic races and frequent safety cars', 'The track is actually located 28 meters below sea level'],
    characteristicsNl: ['Bevat een gigantisch recht stuk van liefst 2.2 kilometer', 'Bizar smalle sectie langs het oude kasteel', 'Stratencircuit waar enorme topsnelheden worden gehaald', 'Staat garant voor chaotische races en safety cars', 'Het hele circuit bevindt zich eigenlijk 28 meter onder zeeniveau'],
  ),
  Race(
    name: 'Singapore Grand Prix', country: 'Singapore', flag: '🇸🇬',
    date: DateTime(2026, 10, 11, 14, 0), laps: 61, length: 5063,
    weather: WeatherForecast(temperature: 32, rainChance: 60, rainAmount: 12, windSpeed: 18, humidity: 80, pressure: 1007, feelsLike: 34),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2018, '1:41.905'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:44.000', redFlagChance: 18, vscChance: 22, accidentChance: 28, turn1AccidentChance: 16,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Soft → Medium → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_very_difficult',
    firstGrandPrix: 2008, contractUntil: '2028',
    characteristicsEn: ['Physically the toughest race due to extreme humidity', 'Very bumpy street circuit surface', 'Spectacular night race under thousands of lights', 'Race regularly hits the 2-hour time limit', 'Almost 100% historical chance of a Safety Car'],
    characteristicsNl: ['Fysiek de allerzwaarste race door extreme luchtvochtigheid', 'Zeer hobbelig en meedogenloos asfalt', 'Spectaculaire nachtrace onder duizenden felle lampen', 'De race duurt vaak dicht tegen de tijdslimiet van 2 uur aan', 'Er is historisch gezien bijna altijd een Safety Car nodig'],
  ),
  Race(
    name: 'United States Grand Prix', country: 'USA', flag: '🇺🇸',
    date: DateTime(2026, 10, 25, 21, 0), laps: 56, length: 5513,
    weather: WeatherForecast(temperature: 28, rainChance: 20, rainAmount: 2, windSpeed: 14, humidity: 55, pressure: 1013, feelsLike: 29),
    fastestLap: LapRecord('Charles Leclerc', 'Ferrari', 2022, '1:36.198'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:39.000', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 11,
    tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 2012, contractUntil: '2026',
    characteristicsEn: ['Iconic steep uphill run into a blind Turn 1', 'First sector inspired by Maggotts/Becketts', 'Features a massive stadium section like Hockenheim', 'Track is notoriously bumpy as it was built on clay', 'Often experiences very high track temperatures'],
    characteristicsNl: ['Iconische, zeer steile klim naar een blinde eerste bocht', 'De eerste sector is geïnspireerd op Maggotts/Becketts', 'Heeft een gigantische stadionsectie à la Hockenheim', 'De baan is berucht om hobbels (gebouwd op kleigrond)', 'Tijdens de race zijn de baantemperaturen vaak extreem hoog'],
  ),
  Race(
    name: 'Mexico City Grand Prix', country: 'Mexico', flag: '🇲🇽',
    date: DateTime(2026, 11, 1, 21, 0), laps: 71, length: 4304,
    weather: WeatherForecast(temperature: 22, rainChance: 15, rainAmount: 2, windSpeed: 10, humidity: 50, pressure: 1014, feelsLike: 22),
    fastestLap: LapRecord('Valtteri Bottas', 'Mercedes', 2021, '1:17.774'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:20.000', redFlagChance: 8, vscChance: 12, accidentChance: 18, turn1AccidentChance: 9,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 1962, contractUntil: '2025',
    characteristicsEn: ['Highest altitude track on the calendar (2200m+)', 'Thin air severely reduces downforce and engine cooling', 'Unique slow-speed section through the Foro Sol stadium', 'Incredibly long straight run down to Turn 1', 'Known for having one of the loudest crowds in F1'],
    characteristicsNl: ['Het hoogstgelegen circuit op de kalender (ruim 2200m)', 'Dunne lucht zorgt voor weinig downforce en koelingsproblemen', 'Unieke langzame passage dwars door het Foro Sol stadion', 'Auto\'s hebben een enorm lange aanloop naar de eerste bocht nodig', 'Beroemd vanwege het oorverdovende, fantastische publiek'],
  ),
  Race(
    name: 'Brazilian Grand Prix', country: 'Brazil', flag: '🇧🇷',
    date: DateTime(2026, 11, 8, 18, 0), laps: 71, length: 4309,
    weather: WeatherForecast(temperature: 26, rainChance: 30, rainAmount: 4, windSpeed: 12, humidity: 60, pressure: 1015, feelsLike: 25),
    fastestLap: LapRecord('Lewis Hamilton', 'Mercedes', 2021, '1:10.540'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:13.000', redFlagChance: 12, vscChance: 18, accidentChance: 22, turn1AccidentChance: 13,
    tireWear: 'Medium', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_easy',
    firstGrandPrix: 1973, contractUntil: '2030',
    characteristicsEn: ['One of the few anti-clockwise circuits', 'Features the legendary undulating "Senna S" corners', 'Weather can change from sunny to torrential rain in minutes', 'Located at a high altitude (over 700 meters)', 'Layout promotes fantastic racing and overtaking'],
    characteristicsNl: ['Eén van de weinige circuits die tegen de klok in gaat', 'Begint met de legendarische, duikende "Senna S" bochten', 'Weer kan binnen enkele minuten compleet omslaan in onweer', 'Ligt vrij hoog (meer dan 700 meter boven zeeniveau)', 'Geweldige vloeiende lay-out die inhaalacties bevordert'],
  ),
  Race(
    name: 'Las Vegas Grand Prix', country: 'USA', flag: '🇺🇸',
    date: DateTime(2026, 11, 21, 5, 0), laps: 50, length: 6500,
    weather: WeatherForecast(temperature: 15, rainChance: 5, rainAmount: 0, windSpeed: 10, humidity: 30, pressure: 1011, feelsLike: 15),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2023, '1:34.000'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:45.000'),
    averageLap: '1:37.000', redFlagChance: 10, vscChance: 15, accidentChance: 20, turn1AccidentChance: 10,
    tireWear: 'Medium', tireStrategy: '1 stop', bestCombination: 'Soft → Medium',
    fastestPitstop: PitstopRecord('Red Bull', 2023, '2.1s'),
    overtakingDifficulty: 'overtake_very_easy',
    firstGrandPrix: 2023, contractUntil: '2032',
    characteristicsEn: ['Cars race directly down the famous Las Vegas Strip', 'Unusually cold temperatures for a night race', 'Features a section wrapping around the MSG Sphere', 'Extremely long straights allowing for high top speeds', 'Very fast average speed for a street circuit'],
    characteristicsNl: ['Auto\'s scheuren volgas over de wereldberoemde Las Vegas Strip', 'Ongewoon koude temperaturen voor een F1 nachtrace', 'Heeft een unieke sectie rondom de gigantische MSG Sphere', 'Bizar lange rechte stukken voor ongekende topsnelheden', 'Extreem hoge gemiddelde snelheid voor een stratencircuit'],
  ),
  Race(
    name: 'Qatar Grand Prix', country: 'Qatar', flag: '🇶🇦',
    date: DateTime(2026, 11, 29, 17, 0), laps: 57, length: 5419,
    weather: WeatherForecast(temperature: 28, rainChance: 0, rainAmount: 0, windSpeed: 16, humidity: 40, pressure: 1014, feelsLike: 30),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:23.196'), slowestLap: LapRecord('Nikita Mazepin', 'Haas', 2021, '1:30.000'),
    averageLap: '1:26.000', redFlagChance: 5, vscChance: 10, accidentChance: 15, turn1AccidentChance: 8,
    tireWear: 'High', tireStrategy: '2 stops', bestCombination: 'Medium → Hard → Hard',
    fastestPitstop: PitstopRecord('McLaren', 2023, '2.2s'),
    overtakingDifficulty: 'overtake_difficult',
    firstGrandPrix: 2021, contractUntil: '2032',
    characteristicsEn: ['Originally designed as a premier MotoGP track', 'Dominated by incredibly fast and flowing corners', 'Physically brutal due to sustained high G-forces', 'Built on completely flat desert terrain', 'Takes place entirely under artificial floodlights'],
    characteristicsNl: ['Oorspronkelijk puur ontworpen als een MotoGP-circuit', 'Wordt gedomineerd door bizar snelle en vloeiende bochten', 'Fysiek een martelgang door constante, hoge G-krachten', 'Is gebouwd in een compleet vlak woestijnlandschap', 'De race wordt volledig verreden onder kunstlicht'],
  ),
  Race(
    name: 'Abu Dhabi Grand Prix', country: 'UAE', flag: '🇦🇪',
    date: DateTime(2026, 12, 6, 14, 0), laps: 58, length: 5281,
    weather: WeatherForecast(temperature: 27, rainChance: 0, rainAmount: 0, windSpeed: 10, humidity: 40, pressure: 1012, feelsLike: 28),
    fastestLap: LapRecord('Max Verstappen', 'Red Bull', 2021, '1:26.103'), slowestLap: LapRecord('Nicholas Latifi', 'Williams', 2022, '1:40.000'),
    averageLap: '1:29.000', redFlagChance: 5, vscChance: 10, accidentChance: 15, turn1AccidentChance: 7,
    tireWear: 'Low', tireStrategy: '1 stop', bestCombination: 'Medium → Hard',
    fastestPitstop: PitstopRecord('Red Bull', 2022, '2.1s'),
    overtakingDifficulty: 'overtake_average',
    firstGrandPrix: 2009, contractUntil: '2030',
    characteristicsEn: ['Unique twilight race (starts in sun, ends in dark)', 'Pit lane exit runs through a tight underground tunnel', 'Track literally passes underneath the W Hotel', 'Features a very smooth and low-abrasion track surface', 'Traditionally hosts the spectacular season finale'],
    characteristicsNl: ['Unieke schemerrace (start met zon, eindigt in het donker)', 'De uitgang van de pitstraat loopt spectaculair door een tunnel', 'Het circuit loopt letterlijk onder het spectaculaire W Hotel door', 'Heeft een extreem glad asfalt met heel weinig bandenslijtage', 'Traditioneel het toneel voor de grote seizoensafsluiter'],
  ),
];

final List<Driver> fallbackDrivers = [
  Driver(name: 'Lando Norris', flag: '🇬🇧', points: 423, number: 4, nationality: 'British', team: 'McLaren', pointsFinishPct: 83.5, wins: 8, podiums2nd: 10, podiums3rd: 7, podiums: 25, poles: 8, fastestLaps: 9, totalPoints: 1056.0, championships: 1, lapsRaced: 6200, starts: 128, dnfs: 9, dsqs: 0, dnqs: 0),
  Driver(name: 'Max Verstappen', flag: '🇳🇱', points: 421, number: 1, nationality: 'Dutch', team: 'Red Bull Racing', pointsFinishPct: 85.1, wins: 69, podiums2nd: 31, podiums3rd: 16, podiums: 116, poles: 45, fastestLaps: 35, totalPoints: 3400.5, championships: 3, lapsRaced: 11050, starts: 210, dnfs: 31, dsqs: 0, dnqs: 0),
  Driver(name: 'Oscar Piastri', flag: '🇦🇺', points: 410, number: 81, nationality: 'Australian', team: 'McLaren', pointsFinishPct: 75.0, wins: 5, podiums2nd: 8, podiums3rd: 5, podiums: 18, poles: 4, fastestLaps: 6, totalPoints: 607.0, championships: 0, lapsRaced: 2800, starts: 46, dnfs: 4, dsqs: 0, dnqs: 0),
  Driver(name: 'George Russell', flag: '🇬🇧', points: 319, number: 63, nationality: 'British', team: 'Mercedes', pointsFinishPct: 65.4, wins: 4, podiums2nd: 5, podiums3rd: 10, podiums: 19, poles: 4, fastestLaps: 8, totalPoints: 788.0, championships: 0, lapsRaced: 7200, starts: 128, dnfs: 18, dsqs: 1, dnqs: 0),
  Driver(name: 'Charles Leclerc', flag: '🇲🇨', points: 242, number: 16, nationality: 'Monegasque', team: 'Ferrari', pointsFinishPct: 72.8, wins: 8, podiums2nd: 15, podiums3rd: 20, podiums: 43, poles: 27, fastestLaps: 10, totalPoints: 1420.0, championships: 0, lapsRaced: 8100, starts: 148, dnfs: 22, dsqs: 1, dnqs: 0),
  Driver(name: 'Lewis Hamilton', flag: '🇬🇧', points: 156, number: 44, nationality: 'British', team: 'Ferrari', pointsFinishPct: 88.5, wins: 105, podiums2nd: 56, podiums3rd: 40, podiums: 201, poles: 104, fastestLaps: 67, totalPoints: 4895.5, championships: 7, lapsRaced: 19500, starts: 356, dnfs: 31, dsqs: 1, dnqs: 0),
  Driver(name: 'Andrea Kimi Antonelli', flag: '🇮🇹', points: 150, number: 12, nationality: 'Italian', team: 'Mercedes', pointsFinishPct: 60.0, wins: 0, podiums2nd: 1, podiums3rd: 2, podiums: 3, poles: 0, fastestLaps: 1, totalPoints: 150.0, championships: 0, lapsRaced: 1200, starts: 24, dnfs: 3, dsqs: 0, dnqs: 0),
  Driver(name: 'Alexander Albon', flag: '🇹🇭', points: 73, number: 23, nationality: 'Thai', team: 'Williams', pointsFinishPct: 45.2, wins: 0, podiums2nd: 0, podiums3rd: 2, podiums: 2, poles: 0, fastestLaps: 0, totalPoints: 315.0, championships: 0, lapsRaced: 5800, starts: 105, dnfs: 14, dsqs: 0, dnqs: 0),
  Driver(name: 'Carlos Sainz', flag: '🇪🇸', points: 64, number: 55, nationality: 'Spanish', team: 'Williams', pointsFinishPct: 70.1, wins: 4, podiums2nd: 8, podiums3rd: 13, podiums: 25, poles: 6, fastestLaps: 4, totalPoints: 1286.5, championships: 0, lapsRaced: 11200, starts: 207, dnfs: 25, dsqs: 0, dnqs: 0),
  Driver(name: 'Fernando Alonso', flag: '🇪🇸', points: 56, number: 14, nationality: 'Spanish', team: 'Aston Martin', pointsFinishPct: 75.3, wins: 32, podiums2nd: 40, podiums3rd: 34, podiums: 106, poles: 22, fastestLaps: 24, totalPoints: 2385.0, championships: 2, lapsRaced: 21500, starts: 402, dnfs: 75, dsqs: 0, dnqs: 1),
  Driver(name: 'Nico Hülkenberg', flag: '🇩🇪', points: 51, number: 27, nationality: 'German', team: 'Kick Sauber', pointsFinishPct: 48.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 1, fastestLaps: 2, totalPoints: 581.0, championships: 0, lapsRaced: 12500, starts: 228, dnfs: 42, dsqs: 0, dnqs: 0),
  Driver(name: 'Isack Hadjar', flag: '🇫🇷', points: 51, number: 6, nationality: 'French', team: 'Racing Bulls', pointsFinishPct: 35.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 51.0, championships: 0, lapsRaced: 1100, starts: 24, dnfs: 2, dsqs: 0, dnqs: 0),
  Driver(name: 'Oliver Bearman', flag: '🇬🇧', points: 41, number: 87, nationality: 'British', team: 'Haas F1 Team', pointsFinishPct: 40.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 47.0, championships: 0, lapsRaced: 1250, starts: 25, dnfs: 3, dsqs: 0, dnqs: 0),
  Driver(name: 'Liam Lawson', flag: '🇳🇿', points: 38, number: 30, nationality: 'New Zealander', team: 'Racing Bulls', pointsFinishPct: 30.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 40.0, championships: 0, lapsRaced: 1400, starts: 29, dnfs: 2, dsqs: 0, dnqs: 0),
  Driver(name: 'Esteban Ocon', flag: '🇫🇷', points: 38, number: 31, nationality: 'French', team: 'Haas F1 Team', pointsFinishPct: 52.0, wins: 1, podiums2nd: 2, podiums3rd: 1, podiums: 4, poles: 0, fastestLaps: 0, totalPoints: 460.0, championships: 0, lapsRaced: 8500, starts: 157, dnfs: 28, dsqs: 1, dnqs: 0),
  Driver(name: 'Lance Stroll', flag: '🇨🇦', points: 33, number: 18, nationality: 'Canadian', team: 'Aston Martin', pointsFinishPct: 42.0, wins: 0, podiums2nd: 0, podiums3rd: 3, podiums: 3, poles: 1, fastestLaps: 0, totalPoints: 311.0, championships: 0, lapsRaced: 8800, starts: 167, dnfs: 32, dsqs: 0, dnqs: 0),
  Driver(name: 'Yuki Tsunoda', flag: '🇯🇵', points: 33, number: 22, nationality: 'Japanese', team: 'Red Bull Racing', pointsFinishPct: 38.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 1, totalPoints: 94.0, championships: 0, lapsRaced: 5100, starts: 90, dnfs: 14, dsqs: 0, dnqs: 0),
  Driver(name: 'Pierre Gasly', flag: '🇫🇷', points: 22, number: 10, nationality: 'French', team: 'Alpine', pointsFinishPct: 54.0, wins: 1, podiums2nd: 1, podiums3rd: 2, podiums: 4, poles: 0, fastestLaps: 3, totalPoints: 416.0, championships: 0, lapsRaced: 8400, starts: 154, dnfs: 24, dsqs: 1, dnqs: 0),
  Driver(name: 'Gabriel Bortoleto', flag: '🇧🇷', points: 19, number: 5, nationality: 'Brazilian', team: 'Kick Sauber', pointsFinishPct: 15.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 19.0, championships: 0, lapsRaced: 1000, starts: 24, dnfs: 4, dsqs: 0, dnqs: 0),
  Driver(name: 'Franco Colapinto', flag: '🇦🇷', points: 0, number: 43, nationality: 'Argentine', team: 'Alpine', pointsFinishPct: 0.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0.0, championships: 0, lapsRaced: 900, starts: 18, dnfs: 2, dsqs: 0, dnqs: 0),
  Driver(name: 'Jack Doohan', flag: '🇦🇺', points: 0, number: 7, nationality: 'Australian', team: 'Alpine', pointsFinishPct: 0.0, wins: 0, podiums2nd: 0, podiums3rd: 0, podiums: 0, poles: 0, fastestLaps: 0, totalPoints: 0.0, championships: 0, lapsRaced: 300, starts: 6, dnfs: 1, dsqs: 0, dnqs: 0),
];

final List<Team> fallbackTeams = [
  Team(name: 'McLaren', flag: '🇬🇧', points: 833, fastestPitstopTime: '1.80s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Qatar', ccWins: 10, dcWins: 13, podiums: 520, oneTwo: 49, hattricks: 28, doublePodiums: 110, totalPoints: 7200.5, frontRow: 145, poles: 165, fastestLaps: 170, racesLed: 380, principalName: 'Andrea Stella', principalAge: 54, principalFlag: '🇮🇹', totalEntries: 967),
  Team(name: 'Mercedes', flag: '🇩🇪', points: 469, fastestPitstopTime: '1.98s', fastestPitstopYear: 2022, fastestPitstopCircuit: 'Mexico', ccWins: 8, dcWins: 9, podiums: 295, oneTwo: 59, hattricks: 30, doublePodiums: 125, totalPoints: 7500.5, frontRow: 160, poles: 139, fastestLaps: 107, racesLed: 240, principalName: 'Toto Wolff', principalAge: 53, principalFlag: '🇦🇹', totalEntries: 314),
  Team(name: 'Red Bull Racing', flag: '🇦🇹', points: 451, fastestPitstopTime: '1.82s', fastestPitstopYear: 2019, fastestPitstopCircuit: 'Brazil', ccWins: 6, dcWins: 7, podiums: 280, oneTwo: 32, hattricks: 25, doublePodiums: 85, totalPoints: 7400.0, frontRow: 130, poles: 102, fastestLaps: 98, racesLed: 210, principalName: 'Christian Horner', principalAge: 51, principalFlag: '🇬🇧', totalEntries: 390),
  Team(name: 'Ferrari', flag: '🇮🇹', points: 398, fastestPitstopTime: '1.93s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Qatar', ccWins: 16, dcWins: 15, podiums: 810, oneTwo: 85, hattricks: 42, doublePodiums: 180, totalPoints: 10250.0, frontRow: 260, poles: 251, fastestLaps: 261, racesLed: 520, principalName: 'Frédéric Vasseur', principalAge: 56, principalFlag: '🇫🇷', totalEntries: 1095),
  Team(name: 'Williams', flag: '🇬🇧', points: 137, fastestPitstopTime: '1.92s', fastestPitstopYear: 2016, fastestPitstopCircuit: 'Azerbaijan', ccWins: 9, dcWins: 7, podiums: 313, oneTwo: 33, hattricks: 18, doublePodiums: 65, totalPoints: 3620.0, frontRow: 120, poles: 128, fastestLaps: 133, racesLed: 180, principalName: 'James Vowles', principalAge: 55, principalFlag: '🇬🇧', totalEntries: 826),
  Team(name: 'Racing Bulls', flag: '🇮🇹', points: 92, fastestPitstopTime: '2.10s', fastestPitstopYear: 2024, fastestPitstopCircuit: 'Bahrain', ccWins: 0, dcWins: 0, podiums: 3, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 310.0, frontRow: 1, poles: 0, fastestLaps: 2, racesLed: 1, principalName: 'Laurent Mekies', principalAge: 47, principalFlag: '🇫🇷', totalEntries: 368),
  Team(name: 'Aston Martin', flag: '🇬🇧', points: 89, fastestPitstopTime: '2.15s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Spain', ccWins: 0, dcWins: 0, podiums: 9, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 420.0, frontRow: 2, poles: 1, fastestLaps: 1, racesLed: 3, principalName: 'Mike Krack', principalAge: 52, principalFlag: '🇱🇺', totalEntries: 94),
  Team(name: 'Haas F1 Team', flag: '🇺🇸', points: 79, fastestPitstopTime: '2.25s', fastestPitstopYear: 2022, fastestPitstopCircuit: 'USA', ccWins: 0, dcWins: 0, podiums: 0, oneTwo: 0, hattricks: 0, doublePodiums: 0, totalPoints: 315.0, frontRow: 0, poles: 1, fastestLaps: 2, racesLed: 0, principalName: 'Ayao Komatsu', principalAge: 49, principalFlag: '🇯🇵', totalEntries: 188),
  Team(name: 'Kick Sauber', flag: '🇨🇭', points: 70, fastestPitstopTime: '2.30s', fastestPitstopYear: 2023, fastestPitstopCircuit: 'Monaco', ccWins: 0, dcWins: 0, podiums: 27, oneTwo: 1, hattricks: 0, doublePodiums: 2, totalPoints: 920.0, frontRow: 5, poles: 1, fastestLaps: 5, racesLed: 10, principalName: 'Alessandro Alunni Bravi', principalAge: 49, principalFlag: '🇮🇹', totalEntries: 400),
  Team(name: 'Alpine', flag: '🇫🇷', points: 22, fastestPitstopTime: '2.18s', fastestPitstopYear: 2024, fastestPitstopCircuit: 'Japan', ccWins: 2, dcWins: 2, podiums: 105, oneTwo: 2, hattricks: 1, doublePodiums: 5, totalPoints: 2150.0, frontRow: 25, poles: 51, fastestLaps: 33, racesLed: 45, principalName: 'Oliver Oakes', principalAge: 59, principalFlag: '🇬🇧', totalEntries: 90),
];

// Caching voor de app-sessie
List<Driver>? _cachedDrivers;
List<Team>? _cachedTeams;
bool _usingFallback = false;

/// --- views ---------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;

  const HomeScreen({required this.onToggleLocale, required this.onToggleTheme, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Race? _selectedRace;
  Driver? _selectedDriver;
  Team? _selectedTeam;

  void _goBack() {
    setState(() {
      _selectedRace = null;
      _selectedDriver = null;
      _selectedTeam = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bool isDetail = _selectedRace != null || _selectedDriver != null || _selectedTeam != null;

    String title = loc.translate('appTitle');
    if (_selectedRace != null) title = loc.translate('gp_' + _selectedRace!.name);
    if (_selectedDriver != null) title = '${_selectedDriver!.flag} ${_selectedDriver!.name}';
    if (_selectedTeam != null) title = '${_selectedTeam!.flag} ${_selectedTeam!.name}';

    Widget body;
    if (_selectedRace != null) {
      body = CircuitDetailView(race: _selectedRace!);
    } else if (_selectedDriver != null) {
      body = DriverDetailView(driver: _selectedDriver!);
    } else if (_selectedTeam != null) {
      body = TeamDetailView(team: _selectedTeam!);
    } else {
      if (_currentIndex == 0) {
        body = CircuitsView(onRaceSelected: (r) => setState(() => _selectedRace = r));
      } else {
        body = StandingsView(
          onDriverSelected: (d) => setState(() => _selectedDriver = d),
          onTeamSelected: (t) => setState(() => _selectedTeam = t),
        );
      }
    }

    return PopScope(
      canPop: !isDetail,
      onPopInvoked: (didPop) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isDetail ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack) : null,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.settings),
              tooltip: loc.translate('settings'),
              onSelected: (value) {
                if (value == 0) widget.onToggleTheme();
                if (value == 1) widget.onToggleLocale();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_6),
                      const SizedBox(width: 12),
                      Text(loc.translate('toggleTheme')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 12),
                      Text(loc.translate('toggleLanguage')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.map), label: loc.translate('circuits')),
            BottomNavigationBarItem(icon: const Icon(Icons.leaderboard), label: loc.translate('standings')),
          ],
          onTap: (i) {
            setState(() {
              _currentIndex = i;
              _selectedRace = null;
              _selectedDriver = null;
              _selectedTeam = null;
            });
          },
        ),
      ),
    );
  }
}

class CircuitsView extends StatefulWidget {
  final ValueChanged<Race> onRaceSelected;
  const CircuitsView({required this.onRaceSelected, super.key});

  @override
  State<CircuitsView> createState() => _CircuitsViewState();
}

class _CircuitsViewState extends State<CircuitsView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
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

  String _timeUntil(DateTime date, BuildContext context) {
    final loc = AppLocalizations.of(context);
    final diff = date.difference(DateTime.now());

    if (diff.isNegative) return loc.translate('raceFinished');

    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      final remainingDays = diff.inDays % 7;
      String w = '$weeks ${weeks == 1 ? loc.translate('week') : loc.translate('weeks')}';
      if (remainingDays > 0) w += ', $remainingDays ${remainingDays == 1 ? loc.translate('day') : loc.translate('days')}';
      return w;
    } else if (diff.inDays >= 1) {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      String d = '$days ${days == 1 ? loc.translate('day') : loc.translate('days')}';
      if (hours > 0) d += ', $hours ${loc.translate('hours')}';
      return d;
    } else if (diff.inHours >= 1) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return '$hours ${loc.translate('hours')}, $mins ${loc.translate('minutes')}';
    } else {
      return '${diff.inMinutes} ${loc.translate('minutes')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final upcoming = _nextRace();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => widget.onRaceSelected(upcoming),
          child: Card(
            elevation: 4,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏁 ${loc.translate('nextRace')}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('📍 ${loc.translate('gp_' + upcoming.name)}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('🌍 ${loc.translate('country')}: ${loc.translate('country_' + upcoming.country)} ${upcoming.flag}'),
                  Text('⏰ ${loc.translate('raceStarts')}: ${upcoming.date.toString().substring(0, 16)}'),
                  Text('☀️ ${loc.translate('weather')}: ${upcoming.weather.temperature}°C, ${upcoming.weather.rainChance}% ${loc.translate('rainChance').toLowerCase()}'),
                  const SizedBox(height: 8),
                  Text('⌛ ${loc.translate('startsIn')} ${_timeUntil(upcoming.date, context)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...races.map((r) {
          final timeStr = _timeUntil(r.date, context);
          return Card(
            child: ListTile(
              leading: Text(r.flag, style: const TextStyle(fontSize: 24)),
              title: Text('🏁 ${loc.translate('gp_' + r.name)}'),
              subtitle: Text(timeStr == loc.translate('raceFinished') ? timeStr : '⏳ $timeStr'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => widget.onRaceSelected(r),
            ),
          );
        }).toList()
      ],
    );
  }
}

class StandingsView extends StatefulWidget {
  final ValueChanged<Driver> onDriverSelected;
  final ValueChanged<Team> onTeamSelected;

  const StandingsView({required this.onDriverSelected, required this.onTeamSelected, super.key});

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStandings();
  }

  Future<void> _fetchStandings() async {
    if (_cachedDrivers != null && _cachedTeams != null) return;
    
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('https://api.jolpi.ca/ergast/f1/current/driverStandings.json'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final standingsList = data['MRData']['StandingsTable']['StandingsLists'];
        
        if (standingsList.isNotEmpty) {
          final season = int.parse(standingsList[0]['season']);
          if (season == 2026) {
             throw Exception("No valid 2026 data yet"); 
          } else {
             throw Exception("Season is not 2026");
          }
        } else {
          throw Exception("Empty standings list");
        }
      } else {
        throw Exception("API Request failed");
      }
    } catch (e) {
      _cachedDrivers = fallbackDrivers;
      _cachedTeams = fallbackTeams;
      _usingFallback = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedDrivers = List<Driver>.from(_cachedDrivers ?? fallbackDrivers)..sort((a, b) => b.points.compareTo(a.points));
    final sortedTeams = List<Team>.from(_cachedTeams ?? fallbackTeams)..sort((a, b) => b.points.compareTo(a.points));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          if (_usingFallback)
            Container(
              width: double.infinity,
              color: Colors.orangeAccent.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                loc.translate('using_fallback_data'),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          TabBar(
            tabs: [
              Tab(text: loc.translate('drivers')),
              Tab(text: loc.translate('teams')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: sortedDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = sortedDrivers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Text(driver.flag, style: const TextStyle(fontSize: 24)),
                        title: Text('${index + 1}. ${driver.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text('${driver.points} ${loc.translate('pts')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onTap: () => widget.onDriverSelected(driver),
                      ),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: sortedTeams.length,
                  itemBuilder: (context, index) {
                    final team = sortedTeams[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Text(team.flag, style: const TextStyle(fontSize: 24)),
                        title: Text('${index + 1}. ${team.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text('${team.points} ${loc.translate('pts')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onTap: () => widget.onTeamSelected(team),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CircuitDetailView extends StatelessWidget {
  final Race race;
  const CircuitDetailView({required this.race, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    Widget row(String emoji, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('$emoji $label'), Flexible(child: Text(value, textAlign: TextAlign.right))],
        ),
      );
    }

    String formatLap(LapRecord r) {
      if (r.driver == 'TBD') return loc.translate('tbd');
      return '${r.driver}, ${r.team}, ${r.year} (${r.time})';
    }

    String formatPit(PitstopRecord p) {
      if (p.team == 'TBD') return loc.translate('tbd');
      return '${p.team}, ${p.year} (${p.time})';
    }

    String translatedStrategy = race.bestCombination
        .replaceAll('Soft', loc.translate('soft_tire'))
        .replaceAll('Medium', loc.translate('medium_tire'))
        .replaceAll('Hard', loc.translate('hard_tire'));

    List<String> raceChars = loc.locale.languageCode == 'nl' ? race.characteristicsNl : race.characteristicsEn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌦️ ${loc.translate('forecast')}:', style: Theme.of(context).textTheme.titleSmall),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🌡️ ${race.weather.temperature}°C (${loc.translate('feelsLike').toLowerCase()} ${race.weather.feelsLike}°C)', style: Theme.of(context).textTheme.bodySmall),
                        Text('🌧️ ${race.weather.rainChance}% ${loc.translate('rainChance').toLowerCase()}, ${race.weather.rainAmount}mm ${loc.translate('rainAmount').toLowerCase()}', style: Theme.of(context).textTheme.bodySmall),
                        Text('💨 ${race.weather.windSpeed} km/h, 💧 ${race.weather.humidity}%', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row('📏', loc.translate('totalLength'), '${race.length} m'),
                  row('🔁', loc.translate('laps'), race.laps.toString()),
                  row('🏎️', loc.translate('overtaking'), loc.translate(race.overtakingDifficulty)),
                  row('📅', loc.translate('first_gp'), race.firstGrandPrix.toString()),
                  row('📜', loc.translate('contract_until'), race.contractUntil),
                ],
              ),
            ),
          ),
          ExpansionTile(
            title: Text(loc.translate('lapStats')),
            leading: const Icon(Icons.speed),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                row('⚡', loc.translate('fastestLap'), formatLap(race.fastestLap)),
                row('🐢', loc.translate('slowestLap'), formatLap(race.slowestLap)),
                row('⏱️', loc.translate('avgLap'), race.averageLap == 'TBD' ? loc.translate('tbd') : race.averageLap),
              ]))
            ],
          ),
          ExpansionTile(
            title: Text(loc.translate('risks')),
            leading: const Icon(Icons.warning),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                row('🚩', loc.translate('redFlag'), '${race.redFlagChance}%'),
                row('⚠️', loc.translate('vsc'), '${race.vscChance}%'),
                row('💥', loc.translate('accident'), '${race.accidentChance}%'),
                row('1️⃣', loc.translate('accidentTurn1'), '${race.turn1AccidentChance}%'),
              ]))
            ],
          ),
          ExpansionTile(
            title: Text(loc.translate('tyres')),
            leading: const Icon(Icons.tire_repair),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                row('🅿️', loc.translate('tireWear'), loc.translate('wear_' + race.tireWear)),
                row('🔧', loc.translate('strategy'), loc.translate('strategy_' + race.tireStrategy)),
                row('🎯', loc.translate('bestCombination'), translatedStrategy),
                row('⚙️', loc.translate('fastestPit'), formatPit(race.fastestPitstop)),
              ]))
            ],
          ),
          ExpansionTile(
            title: Text(loc.translate('characteristics')),
            leading: const Icon(Icons.stars),
            children: raceChars.map((char) => ListTile(
              leading: const Icon(Icons.check_circle_outline, size: 20),
              title: Text(char, style: Theme.of(context).textTheme.bodyMedium),
              dense: true,
            )).toList(),
          ),
          ExpansionTile(
            title: Text(loc.translate('forecast')),
            leading: const Icon(Icons.cloud),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                row('🌡️', loc.translate('temp'), '${race.weather.temperature}°C'),
                row('🤔', loc.translate('feelsLike'), '${race.weather.feelsLike}°C'),
                row('🌧️', '${loc.translate('rainChance')} / ${loc.translate('rainAmount')}', '${race.weather.rainChance}% / ${race.weather.rainAmount}mm'),
                row('💨', loc.translate('wind'), '${race.weather.windSpeed} km/h'),
                row('💧', loc.translate('humidity'), '${race.weather.humidity}%'),
                row('🔽', loc.translate('pressure'), '${race.weather.pressure} hPa'),
              ]))
            ],
          ),
        ],
      ),
    );
  }
}

class DriverDetailView extends StatelessWidget {
  final Driver driver;
  const DriverDetailView({required this.driver, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    Widget detailRow(String emoji, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Text(emoji), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.grey))]),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('general')),
            leading: const Icon(Icons.person),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                detailRow('🔢', loc.translate('driver_number'), driver.number.toString()),
                detailRow('🌍', loc.translate('nationality'), driver.nationality),
                detailRow('🏎️', loc.translate('current_team'), driver.team),
              ]))
            ],
          ),
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('career_stats')),
            leading: const Icon(Icons.bar_chart),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                detailRow('🌟', loc.translate('total_points'), driver.totalPoints.toString()),
                detailRow('🏆', loc.translate('championships'), driver.championships.toString()),
                detailRow('🍾', loc.translate('podiums'), driver.podiums.toString()),
                detailRow(' ↳ 🥇', loc.translate('wins'), driver.wins.toString()),
                detailRow(' ↳ 🥈', loc.translate('second_place'), driver.podiums2nd.toString()),
                detailRow(' ↳ 🥉', loc.translate('third_place'), driver.podiums3rd.toString()),
                const SizedBox(height: 8),
                detailRow('⏱️', loc.translate('poles'), driver.poles.toString()),
                detailRow('🚀', loc.translate('fastest_laps'), driver.fastestLaps.toString()),
                detailRow('📈', loc.translate('points_finish_pct'), '${driver.pointsFinishPct}%'),
              ]))
            ],
          ),
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('experience')),
            leading: const Icon(Icons.sports_motorsports),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                detailRow('🚥', loc.translate('starts'), driver.starts.toString()),
                detailRow('🔁', loc.translate('laps_raced'), driver.lapsRaced.toString()),
                detailRow('💥', loc.translate('dnf'), driver.dnfs.toString()),
                detailRow('🚫', loc.translate('dsq'), driver.dsqs.toString()),
                detailRow('❌', loc.translate('dnq'), driver.dnqs.toString()),
              ]))
            ],
          ),
        ],
      ),
    );
  }
}

class TeamDetailView extends StatelessWidget {
  final Team team;
  const TeamDetailView({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    Widget detailRow(String emoji, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Row(children: [Text(emoji), const SizedBox(width: 8), Flexible(child: Text(label, style: const TextStyle(color: Colors.grey)))])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('championships')),
            leading: const Icon(Icons.emoji_events),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                detailRow('🏆', loc.translate('cc_wins'), team.ccWins.toString()),
                detailRow('🥇', loc.translate('dc_wins'), team.dcWins.toString()),
              ]))
            ],
          ),
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('race_stats')),
            leading: const Icon(Icons.analytics),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                detailRow('🎟️', loc.translate('total_entries'), team.totalEntries.toString()),
                detailRow('🌟', loc.translate('total_points'), team.totalPoints.toString()),
                detailRow('🍾', loc.translate('podiums'), team.podiums.toString()),
                detailRow('🤝', loc.translate('one_two'), team.oneTwo.toString()),
                detailRow('👯', loc.translate('double_podiums'), team.doublePodiums.toString()),
                detailRow('🎩', loc.translate('hattricks'), team.hattricks.toString()),
                detailRow('⏱️', loc.translate('poles'), team.poles.toString()),
                detailRow('🚦', loc.translate('front_row'), team.frontRow.toString()),
                detailRow('🚀', loc.translate('fastest_laps'), team.fastestLaps.toString()),
                detailRow('👑', loc.translate('laps_led'), team.racesLed.toString()),
              ]))
            ],
          ),
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(loc.translate('pitstop_leadership')),
            leading: const Icon(Icons.handyman),
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                detailRow('👔', loc.translate('team_principal'), '${team.principalName} (${team.principalAge}, ${team.principalFlag})'),
                detailRow('⚙️', loc.translate('fastestPit'), '${team.fastestPitstopTime} (${team.fastestPitstopYear}, ${loc.translate('country_' + team.fastestPitstopCircuit)})'),
              ]))
            ],
          ),
        ],
      ),
    );
  }
}