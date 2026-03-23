import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('nl')
  ];

  /// No description provided for @accident.
  ///
  /// In en, this message translates to:
  /// **'Accident Chance'**
  String get accident;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ai_avg_gap.
  ///
  /// In en, this message translates to:
  /// **'Avg. Gap'**
  String get ai_avg_gap;

  /// No description provided for @ai_chip_compare_max_lando.
  ///
  /// In en, this message translates to:
  /// **'Compare Max vs Lando'**
  String get ai_chip_compare_max_lando;

  /// No description provided for @ai_chip_fetch_latest_results.
  ///
  /// In en, this message translates to:
  /// **'Fetch latest results'**
  String get ai_chip_fetch_latest_results;

  /// No description provided for @ai_chip_show_driver_standings.
  ///
  /// In en, this message translates to:
  /// **'Show driver standings'**
  String get ai_chip_show_driver_standings;

  /// No description provided for @ai_chip_show_form_piastri.
  ///
  /// In en, this message translates to:
  /// **'Show form Piastri'**
  String get ai_chip_show_form_piastri;

  /// No description provided for @ai_chip_show_latest_penalties.
  ///
  /// In en, this message translates to:
  /// **'Show latest penalties'**
  String get ai_chip_show_latest_penalties;

  /// No description provided for @ai_chip_show_next_weekend.
  ///
  /// In en, this message translates to:
  /// **'Show next weekend'**
  String get ai_chip_show_next_weekend;

  /// No description provided for @ai_coach_title.
  ///
  /// In en, this message translates to:
  /// **'Coach\'\'s Corner'**
  String get ai_coach_title;

  /// No description provided for @ai_compare_no_match.
  ///
  /// In en, this message translates to:
  /// **'I could not find two valid drivers or teams for this comparison.'**
  String get ai_compare_no_match;

  /// No description provided for @ai_compare_parse_error.
  ///
  /// In en, this message translates to:
  /// **'I could not read the comparison. Use: name1 vs name2'**
  String get ai_compare_parse_error;

  /// No description provided for @ai_crash.
  ///
  /// In en, this message translates to:
  /// **'The assistant ran into: {error}'**
  String ai_crash(String error);

  /// No description provided for @ai_driver_compare_ready.
  ///
  /// In en, this message translates to:
  /// **'Driver comparison is ready for {left} and {right}.'**
  String ai_driver_compare_ready(String left, String right);

  /// No description provided for @ai_driver_profile_ready.
  ///
  /// In en, this message translates to:
  /// **'Driver profile ready for {driver}.'**
  String ai_driver_profile_ready(String driver);

  /// No description provided for @ai_driver_standings_summary.
  ///
  /// In en, this message translates to:
  /// **'Driver standings {year}: {summary}'**
  String ai_driver_standings_summary(String year, String summary);

  /// No description provided for @ai_drivers_chart_ready.
  ///
  /// In en, this message translates to:
  /// **'The drivers chart is ready for {year}.'**
  String ai_drivers_chart_ready(String year);

  /// No description provided for @ai_example_prompt.
  ///
  /// In en, this message translates to:
  /// **'Try for example: \"Fetch latest results\", \"Show next weekend\", \"Show driver standings\", \"Open driver Charles Leclerc\" or \"Show latest penalties\".'**
  String get ai_example_prompt;

  /// No description provided for @ai_form_no_cache.
  ///
  /// In en, this message translates to:
  /// **'No cached recent races for {driver} yet.'**
  String ai_form_no_cache(String driver);

  /// No description provided for @ai_form_no_driver.
  ///
  /// In en, this message translates to:
  /// **'I could not find a driver for the form analysis.'**
  String get ai_form_no_driver;

  /// No description provided for @ai_form_summary.
  ///
  /// In en, this message translates to:
  /// **'Recent form for {driver}: {summary}'**
  String ai_form_summary(String driver, String summary);

  /// No description provided for @ai_latest_penalties_none.
  ///
  /// In en, this message translates to:
  /// **'No penalties found for {race}.'**
  String ai_latest_penalties_none(String race);

  /// No description provided for @ai_latest_penalties_summary.
  ///
  /// In en, this message translates to:
  /// **'Latest penalties at {race}: {count}. {details}'**
  String ai_latest_penalties_summary(String race, String count, String details);

  /// No description provided for @ai_latest_race_control_none.
  ///
  /// In en, this message translates to:
  /// **'No Race Control messages found for {race}.'**
  String ai_latest_race_control_none(String race);

  /// No description provided for @ai_latest_race_control_summary.
  ///
  /// In en, this message translates to:
  /// **'Race Control at {race}: {count} messages. Latest update: {message}'**
  String ai_latest_race_control_summary(String race, String count, String message);

  /// No description provided for @ai_latest_results_podium.
  ///
  /// In en, this message translates to:
  /// **'Latest results refreshed. Podium: {podium}'**
  String ai_latest_results_podium(String podium);

  /// No description provided for @ai_latest_results_refreshed.
  ///
  /// In en, this message translates to:
  /// **'The latest results were refreshed.'**
  String get ai_latest_results_refreshed;

  /// No description provided for @ai_next_weekend.
  ///
  /// In en, this message translates to:
  /// **'Next weekend: {race} on {date}.'**
  String ai_next_weekend(String race, String date);

  /// No description provided for @ai_next_weekend_weather.
  ///
  /// In en, this message translates to:
  /// **'Weather for {race}: {temp}C, {rain}% rain, {wind} km/h wind.'**
  String ai_next_weekend_weather(String race, String temp, String rain, String wind);

  /// No description provided for @ai_no_completed_race.
  ///
  /// In en, this message translates to:
  /// **'No completed race has been found yet.'**
  String get ai_no_completed_race;

  /// No description provided for @ai_open_driver_compare.
  ///
  /// In en, this message translates to:
  /// **'Open driver compare'**
  String get ai_open_driver_compare;

  /// No description provided for @ai_open_driver_profile.
  ///
  /// In en, this message translates to:
  /// **'Open driver profile'**
  String get ai_open_driver_profile;

  /// No description provided for @ai_open_driver_standings.
  ///
  /// In en, this message translates to:
  /// **'Open driver standings'**
  String get ai_open_driver_standings;

  /// No description provided for @ai_open_drivers_chart.
  ///
  /// In en, this message translates to:
  /// **'Open drivers chart'**
  String get ai_open_drivers_chart;

  /// No description provided for @ai_open_latest_results.
  ///
  /// In en, this message translates to:
  /// **'Open latest results'**
  String get ai_open_latest_results;

  /// No description provided for @ai_open_team_compare.
  ///
  /// In en, this message translates to:
  /// **'Open team compare'**
  String get ai_open_team_compare;

  /// No description provided for @ai_open_team_profile.
  ///
  /// In en, this message translates to:
  /// **'Open team profile'**
  String get ai_open_team_profile;

  /// No description provided for @ai_open_team_standings.
  ///
  /// In en, this message translates to:
  /// **'Open team standings'**
  String get ai_open_team_standings;

  /// No description provided for @ai_open_weekend_hub.
  ///
  /// In en, this message translates to:
  /// **'Open weekend hub'**
  String get ai_open_weekend_hub;

  /// No description provided for @ai_qualifying_duel.
  ///
  /// In en, this message translates to:
  /// **'Qualifying Duel'**
  String get ai_qualifying_duel;

  /// No description provided for @ai_race_engineer.
  ///
  /// In en, this message translates to:
  /// **'AI Race Engineer'**
  String get ai_race_engineer;

  /// No description provided for @ai_rain_chance_label.
  ///
  /// In en, this message translates to:
  /// **'Rain Chance'**
  String get ai_rain_chance_label;

  /// No description provided for @ai_rain_chance_slider.
  ///
  /// In en, this message translates to:
  /// **'Rain Chance'**
  String get ai_rain_chance_slider;

  /// No description provided for @ai_sentiment_generic_neutral.
  ///
  /// In en, this message translates to:
  /// **'Team Vibe: Mixed signals from team radios.'**
  String get ai_sentiment_generic_neutral;

  /// No description provided for @ai_sentiment_generic_positive.
  ///
  /// In en, this message translates to:
  /// **'Team Vibe: Positive energy across the paddock.'**
  String get ai_sentiment_generic_positive;

  /// No description provided for @ai_sentiment_label.
  ///
  /// In en, this message translates to:
  /// **'Team Vibe'**
  String get ai_sentiment_label;

  /// No description provided for @ai_sentiment_mercedes_positive.
  ///
  /// In en, this message translates to:
  /// **'Team Vibe: Morale rises at Mercedes after Hamilton grid penalty.'**
  String get ai_sentiment_mercedes_positive;

  /// No description provided for @ai_strategist_tap_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to ask questions...'**
  String get ai_strategist_tap_hint;

  /// No description provided for @ai_strategist_title.
  ///
  /// In en, this message translates to:
  /// **'AI Strategist'**
  String get ai_strategist_title;

  /// No description provided for @ai_prefs_section_title.
  ///
  /// In en, this message translates to:
  /// **'AI Strategist'**
  String get ai_prefs_section_title;

  /// No description provided for @ai_prefs_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize the AI Strategist card on the home screen.'**
  String get ai_prefs_section_subtitle;

  /// No description provided for @ai_prefs_disable_card.
  ///
  /// In en, this message translates to:
  /// **'Disable AI Strategist card'**
  String get ai_prefs_disable_card;

  /// No description provided for @ai_prefs_hide_teambattle.
  ///
  /// In en, this message translates to:
  /// **'Hide Teammate Battle'**
  String get ai_prefs_hide_teambattle;

  /// No description provided for @ai_prefs_hide_teambattle_hint.
  ///
  /// In en, this message translates to:
  /// **'When the card is visible, hide the teammate comparison.'**
  String get ai_prefs_hide_teambattle_hint;

  /// No description provided for @ai_prefs_hide_coach_corner.
  ///
  /// In en, this message translates to:
  /// **'Hide Coach\'\'s Corner'**
  String get ai_prefs_hide_coach_corner;

  /// No description provided for @ai_prefs_hide_coach_corner_hint.
  ///
  /// In en, this message translates to:
  /// **'When the card is visible, hide coaching tips.'**
  String get ai_prefs_hide_coach_corner_hint;

  /// No description provided for @ai_prefs_hide_team_vibe.
  ///
  /// In en, this message translates to:
  /// **'Hide Team Vibe'**
  String get ai_prefs_hide_team_vibe;

  /// No description provided for @ai_prefs_hide_team_vibe_hint.
  ///
  /// In en, this message translates to:
  /// **'When the card is visible, hide sentiment.'**
  String get ai_prefs_hide_team_vibe_hint;

  /// No description provided for @ai_supported_commands.
  ///
  /// In en, this message translates to:
  /// **'Supported commands: Fetch latest results, Show next weekend, Compare name1 vs name2, Show form [driver], Show driver standings, Show team standings, Open driver [name], Open team [name], Show drivers chart, Show latest penalties, Show latest race control.'**
  String get ai_supported_commands;

  /// No description provided for @ai_team_compare_ready.
  ///
  /// In en, this message translates to:
  /// **'Team comparison is ready for {left} and {right}.'**
  String ai_team_compare_ready(String left, String right);

  /// No description provided for @ai_team_profile_ready.
  ///
  /// In en, this message translates to:
  /// **'Team profile ready for {team}.'**
  String ai_team_profile_ready(String team);

  /// No description provided for @ai_team_standings_summary.
  ///
  /// In en, this message translates to:
  /// **'Constructor standings {year}: {summary}'**
  String ai_team_standings_summary(String year, String summary);

  /// No description provided for @ai_teammate_battle.
  ///
  /// In en, this message translates to:
  /// **'Teammate Battle'**
  String get ai_teammate_battle;

  /// No description provided for @ai_teammate_insight.
  ///
  /// In en, this message translates to:
  /// **'{driver} is traditionally stronger on this circuit in qualifying, while {teammate} excels in tyre preservation.'**
  String ai_teammate_insight(String driver, String teammate);

  /// No description provided for @ai_type_command.
  ///
  /// In en, this message translates to:
  /// **'Type a command...'**
  String get ai_type_command;

  /// No description provided for @ai_weather_effect.
  ///
  /// In en, this message translates to:
  /// **'At {pct}% rain: Podium chance for {driver} rises {pct2}% due to superior wet pace.'**
  String ai_weather_effect(String pct, String driver, String pct2);

  /// No description provided for @ai_weather_effect_at.
  ///
  /// In en, this message translates to:
  /// **'At {pct}% rain: {insight}'**
  String ai_weather_effect_at(String pct, String insight);

  /// No description provided for @ai_weather_insight_alonso.
  ///
  /// In en, this message translates to:
  /// **'Podium chance for Alonso rises 15% due to superior wet pace.'**
  String get ai_weather_insight_alonso;

  /// No description provided for @ai_weather_insight_generic.
  ///
  /// In en, this message translates to:
  /// **'Wet conditions favor strong wet-weather drivers.'**
  String get ai_weather_insight_generic;

  /// No description provided for @air_temperature.
  ///
  /// In en, this message translates to:
  /// **'Air temperature'**
  String get air_temperature;

  /// No description provided for @all_scopes.
  ///
  /// In en, this message translates to:
  /// **'All scopes'**
  String get all_scopes;

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'F1 Hub'**
  String get app_title;

  /// No description provided for @average_speed.
  ///
  /// In en, this message translates to:
  /// **'Average Speed'**
  String get average_speed;

  /// No description provided for @avg_finish.
  ///
  /// In en, this message translates to:
  /// **'Avg finish'**
  String get avg_finish;

  /// No description provided for @avg_finish_l5.
  ///
  /// In en, this message translates to:
  /// **'Avg finish (L5)'**
  String get avg_finish_l5;

  /// No description provided for @avg_gforce.
  ///
  /// In en, this message translates to:
  /// **'Avg G-Force'**
  String get avg_gforce;

  /// No description provided for @avg_lap.
  ///
  /// In en, this message translates to:
  /// **'Average Lap'**
  String get avg_lap;

  /// No description provided for @best_combination.
  ///
  /// In en, this message translates to:
  /// **'Best Combination'**
  String get best_combination;

  /// No description provided for @best_lap.
  ///
  /// In en, this message translates to:
  /// **'Best lap'**
  String get best_lap;

  /// No description provided for @birth_place.
  ///
  /// In en, this message translates to:
  /// **'Birthplace'**
  String get birth_place;

  /// No description provided for @cache_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully!'**
  String get cache_cleared;

  /// No description provided for @car_label.
  ///
  /// In en, this message translates to:
  /// **'Car {number}'**
  String car_label(String number);

  /// No description provided for @career_stats.
  ///
  /// In en, this message translates to:
  /// **'Career Stats'**
  String get career_stats;

  /// No description provided for @cc_wins.
  ///
  /// In en, this message translates to:
  /// **'Constructors Titles'**
  String get cc_wins;

  /// No description provided for @championship_progression.
  ///
  /// In en, this message translates to:
  /// **'Championship progression'**
  String get championship_progression;

  /// No description provided for @championships.
  ///
  /// In en, this message translates to:
  /// **'Championships'**
  String get championships;

  /// No description provided for @calendar_prefs_section_title.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar_prefs_section_title;

  /// No description provided for @calendar_prefs_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize the circuits calendar.'**
  String get calendar_prefs_section_subtitle;

  /// No description provided for @calendar_prefs_hide_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Hide placeholder races'**
  String get calendar_prefs_hide_cancelled;

  /// No description provided for @calendar_prefs_hide_cancelled_hint.
  ///
  /// In en, this message translates to:
  /// **'Hide cancelled or placeholder races not on the real calendar.'**
  String get calendar_prefs_hide_cancelled_hint;

  /// No description provided for @display_prefs_section_title.
  ///
  /// In en, this message translates to:
  /// **'Display preferences'**
  String get display_prefs_section_title;

  /// No description provided for @display_prefs_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app looks and moves. When signed in, these sync to your account.'**
  String get display_prefs_section_subtitle;

  /// No description provided for @display_prefs_ui_mode.
  ///
  /// In en, this message translates to:
  /// **'Interface style'**
  String get display_prefs_ui_mode;

  /// No description provided for @display_prefs_mode_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get display_prefs_mode_standard;

  /// No description provided for @display_prefs_mode_standard_hint.
  ///
  /// In en, this message translates to:
  /// **'Glass blur and soft shadows.'**
  String get display_prefs_mode_standard_hint;

  /// No description provided for @display_prefs_mode_simple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get display_prefs_mode_simple;

  /// No description provided for @display_prefs_mode_simple_hint.
  ///
  /// In en, this message translates to:
  /// **'Flat surfaces and stronger contrast.'**
  String get display_prefs_mode_simple_hint;

  /// No description provided for @display_prefs_compact.
  ///
  /// In en, this message translates to:
  /// **'Compact mode'**
  String get display_prefs_compact;

  /// No description provided for @display_prefs_compact_hint.
  ///
  /// In en, this message translates to:
  /// **'Tighter spacing and smaller cards.'**
  String get display_prefs_compact_hint;

  /// No description provided for @display_prefs_motion_reduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get display_prefs_motion_reduced;

  /// No description provided for @display_prefs_motion_reduced_hint.
  ///
  /// In en, this message translates to:
  /// **'Less animation, blur, and theme transitions.'**
  String get display_prefs_motion_reduced_hint;

  /// No description provided for @display_prefs_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get display_prefs_saving;

  /// No description provided for @my_paddock_title.
  ///
  /// In en, this message translates to:
  /// **'My Paddock'**
  String get my_paddock_title;

  /// No description provided for @my_paddock_session_unknown.
  ///
  /// In en, this message translates to:
  /// **'Live timing'**
  String get my_paddock_session_unknown;

  /// No description provided for @my_paddock_resume_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Resume: {session} — frame {lap}'**
  String my_paddock_resume_subtitle(String session, String lap);

  /// No description provided for @my_paddock_favorite_drivers.
  ///
  /// In en, this message translates to:
  /// **'Favorite drivers'**
  String get my_paddock_favorite_drivers;

  /// No description provided for @my_paddock_favorite_teams.
  ///
  /// In en, this message translates to:
  /// **'Favorite teams'**
  String get my_paddock_favorite_teams;

  /// No description provided for @my_paddock_last_race.
  ///
  /// In en, this message translates to:
  /// **'Last race'**
  String get my_paddock_last_race;

  /// No description provided for @my_paddock_last_race_summary.
  ///
  /// In en, this message translates to:
  /// **'{date} · {podium}'**
  String my_paddock_last_race_summary(String date, String podium);

  /// No description provided for @my_paddock_points_suffix.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get my_paddock_points_suffix;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @characteristics.
  ///
  /// In en, this message translates to:
  /// **'CIRCUIT CHARACTERISTICS'**
  String get characteristics;

  /// No description provided for @chart_no_data.
  ///
  /// In en, this message translates to:
  /// **'No chart data is available for this season.'**
  String get chart_no_data;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @circuit.
  ///
  /// In en, this message translates to:
  /// **'Circuit'**
  String get circuit;

  /// No description provided for @circuit_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Circuit Difficulty'**
  String get circuit_difficulty;

  /// No description provided for @circuit_info.
  ///
  /// In en, this message translates to:
  /// **'Circuit Info'**
  String get circuit_info;

  /// No description provided for @circuit_layout.
  ///
  /// In en, this message translates to:
  /// **'Circuit Layout'**
  String get circuit_layout;

  /// No description provided for @circuits.
  ///
  /// In en, this message translates to:
  /// **'Circuits'**
  String get circuits;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clear_cache;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @compare_overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get compare_overall;

  /// No description provided for @compare_season.
  ///
  /// In en, this message translates to:
  /// **'By season'**
  String get compare_season;

  /// No description provided for @compare_season_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Season data is unavailable for this comparison.'**
  String get compare_season_unavailable;

  /// No description provided for @compare_year.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get compare_year;

  /// No description provided for @contract_until.
  ///
  /// In en, this message translates to:
  /// **'Contract until'**
  String get contract_until;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @country_australia.
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get country_australia;

  /// No description provided for @country_austria.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get country_austria;

  /// No description provided for @country_azerbaijan.
  ///
  /// In en, this message translates to:
  /// **'Azerbaijan'**
  String get country_azerbaijan;

  /// No description provided for @country_bahrain.
  ///
  /// In en, this message translates to:
  /// **'Bahrain'**
  String get country_bahrain;

  /// No description provided for @country_belgium.
  ///
  /// In en, this message translates to:
  /// **'Belgium'**
  String get country_belgium;

  /// No description provided for @country_brazil.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get country_brazil;

  /// No description provided for @country_canada.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get country_canada;

  /// No description provided for @country_china.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get country_china;

  /// No description provided for @country_hungary.
  ///
  /// In en, this message translates to:
  /// **'Hungary'**
  String get country_hungary;

  /// No description provided for @country_italy.
  ///
  /// In en, this message translates to:
  /// **'Italy'**
  String get country_italy;

  /// No description provided for @country_japan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get country_japan;

  /// No description provided for @country_mexico.
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get country_mexico;

  /// No description provided for @country_monaco.
  ///
  /// In en, this message translates to:
  /// **'Monaco'**
  String get country_monaco;

  /// No description provided for @country_netherlands.
  ///
  /// In en, this message translates to:
  /// **'Netherlands'**
  String get country_netherlands;

  /// No description provided for @country_qatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get country_qatar;

  /// No description provided for @country_saudi_arabia.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get country_saudi_arabia;

  /// No description provided for @country_singapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get country_singapore;

  /// No description provided for @country_spain.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get country_spain;

  /// No description provided for @country_uae.
  ///
  /// In en, this message translates to:
  /// **'UAE'**
  String get country_uae;

  /// No description provided for @country_uk.
  ///
  /// In en, this message translates to:
  /// **'UK'**
  String get country_uk;

  /// No description provided for @country_usa.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get country_usa;

  /// No description provided for @current_team.
  ///
  /// In en, this message translates to:
  /// **'Current Team'**
  String get current_team;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @dc_wins.
  ///
  /// In en, this message translates to:
  /// **'Drivers Titles'**
  String get dc_wins;

  /// No description provided for @distance_to_turn1.
  ///
  /// In en, this message translates to:
  /// **'Distance to Turn 1'**
  String get distance_to_turn1;

  /// No description provided for @dnf.
  ///
  /// In en, this message translates to:
  /// **'Did Not Finish'**
  String get dnf;

  /// No description provided for @dnf_percentage.
  ///
  /// In en, this message translates to:
  /// **'DNF %'**
  String get dnf_percentage;

  /// No description provided for @dnqs.
  ///
  /// In en, this message translates to:
  /// **'Did Not Qualify'**
  String get dnqs;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @driver_facts_title.
  ///
  /// In en, this message translates to:
  /// **'Facts & Trivia'**
  String get driver_facts_title;

  /// No description provided for @driver_history.
  ///
  /// In en, this message translates to:
  /// **'History (Last 5 Years)'**
  String get driver_history;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @drivers_chart.
  ///
  /// In en, this message translates to:
  /// **'Drivers chart'**
  String get drivers_chart;

  /// No description provided for @dsqs.
  ///
  /// In en, this message translates to:
  /// **'Disqualified'**
  String get dsqs;

  /// No description provided for @engine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get engine;

  /// No description provided for @engine_name.
  ///
  /// In en, this message translates to:
  /// **'Engine Name'**
  String get engine_name;

  /// No description provided for @engine_supplier.
  ///
  /// In en, this message translates to:
  /// **'Engine Supplier'**
  String get engine_supplier;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @f1_debut.
  ///
  /// In en, this message translates to:
  /// **'F1 Debut'**
  String get f1_debut;

  /// No description provided for @fastest_lap.
  ///
  /// In en, this message translates to:
  /// **'Fastest Lap'**
  String get fastest_lap;

  /// No description provided for @fastest_lap_rate.
  ///
  /// In en, this message translates to:
  /// **'Fastest lap rate %'**
  String get fastest_lap_rate;

  /// No description provided for @fastest_laps.
  ///
  /// In en, this message translates to:
  /// **'Fastest Laps'**
  String get fastest_laps;

  /// No description provided for @fastest_pit.
  ///
  /// In en, this message translates to:
  /// **'Fastest Pitstop'**
  String get fastest_pit;

  /// No description provided for @favorite_circuit.
  ///
  /// In en, this message translates to:
  /// **'Favorite Circuit'**
  String get favorite_circuit;

  /// No description provided for @favorite_driver.
  ///
  /// In en, this message translates to:
  /// **'Favorite Driver'**
  String get favorite_driver;

  /// No description provided for @favorite_team.
  ///
  /// In en, this message translates to:
  /// **'Favorite Team'**
  String get favorite_team;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @fp1.
  ///
  /// In en, this message translates to:
  /// **'Practice 1'**
  String get fp1;

  /// No description provided for @fp2.
  ///
  /// In en, this message translates to:
  /// **'Practice 2'**
  String get fp2;

  /// No description provided for @fp3.
  ///
  /// In en, this message translates to:
  /// **'Practice 3'**
  String get fp3;

  /// No description provided for @front_row_starts.
  ///
  /// In en, this message translates to:
  /// **'Front Row Starts'**
  String get front_row_starts;

  /// No description provided for @fullscreen_table.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen table'**
  String get fullscreen_table;

  /// No description provided for @gap.
  ///
  /// In en, this message translates to:
  /// **'Gap'**
  String get gap;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @gp_abu_dhabi_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Abu Dhabi Grand Prix'**
  String get gp_abu_dhabi_grand_prix;

  /// No description provided for @gp_australian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Australian Grand Prix'**
  String get gp_australian_grand_prix;

  /// No description provided for @gp_austrian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Austrian Grand Prix'**
  String get gp_austrian_grand_prix;

  /// No description provided for @gp_azerbaijan_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Azerbaijan Grand Prix'**
  String get gp_azerbaijan_grand_prix;

  /// No description provided for @gp_bahrain_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Bahrain Grand Prix'**
  String get gp_bahrain_grand_prix;

  /// No description provided for @gp_barcelona_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Barcelona Grand Prix'**
  String get gp_barcelona_grand_prix;

  /// No description provided for @gp_belgian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Belgian Grand Prix'**
  String get gp_belgian_grand_prix;

  /// No description provided for @gp_british_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'British Grand Prix'**
  String get gp_british_grand_prix;

  /// No description provided for @gp_canadian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Canadian Grand Prix'**
  String get gp_canadian_grand_prix;

  /// No description provided for @gp_chinese_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Chinese Grand Prix'**
  String get gp_chinese_grand_prix;

  /// No description provided for @gp_dutch_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Dutch Grand Prix'**
  String get gp_dutch_grand_prix;

  /// No description provided for @gp_hungarian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Hungarian Grand Prix'**
  String get gp_hungarian_grand_prix;

  /// No description provided for @gp_italian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Italian Grand Prix'**
  String get gp_italian_grand_prix;

  /// No description provided for @gp_japanese_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Japanese Grand Prix'**
  String get gp_japanese_grand_prix;

  /// No description provided for @gp_las_vegas_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Las Vegas Grand Prix'**
  String get gp_las_vegas_grand_prix;

  /// No description provided for @gp_mexico_city_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Mexico City Grand Prix'**
  String get gp_mexico_city_grand_prix;

  /// No description provided for @gp_miami_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Miami Grand Prix'**
  String get gp_miami_grand_prix;

  /// No description provided for @gp_monaco_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Monaco Grand Prix'**
  String get gp_monaco_grand_prix;

  /// No description provided for @gp_qatar_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Qatar Grand Prix'**
  String get gp_qatar_grand_prix;

  /// No description provided for @gp_s_o_paulo_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'São Paulo Grand Prix'**
  String get gp_s_o_paulo_grand_prix;

  /// No description provided for @gp_saudi_arabian_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabian Grand Prix'**
  String get gp_saudi_arabian_grand_prix;

  /// No description provided for @gp_singapore_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Singapore Grand Prix'**
  String get gp_singapore_grand_prix;

  /// No description provided for @gp_spanish_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'Spanish Grand Prix'**
  String get gp_spanish_grand_prix;

  /// No description provided for @gp_united_states_grand_prix.
  ///
  /// In en, this message translates to:
  /// **'United States Grand Prix'**
  String get gp_united_states_grand_prix;

  /// No description provided for @hard_tire.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard_tire;

  /// No description provided for @hat_tricks.
  ///
  /// In en, this message translates to:
  /// **'Hat Tricks'**
  String get hat_tricks;

  /// No description provided for @headquarters.
  ///
  /// In en, this message translates to:
  /// **'Headquarters'**
  String get headquarters;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @help_and_ideas.
  ///
  /// In en, this message translates to:
  /// **'Help & ideas'**
  String get help_and_ideas;

  /// No description provided for @hide_all.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get hide_all;

  /// No description provided for @highest_finish.
  ///
  /// In en, this message translates to:
  /// **'Highest Finish'**
  String get highest_finish;

  /// No description provided for @highest_grid.
  ///
  /// In en, this message translates to:
  /// **'Highest Grid Position'**
  String get highest_grid;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @language_chooser.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_chooser;

  /// No description provided for @language_selector.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_selector;

  /// No description provided for @lap_label.
  ///
  /// In en, this message translates to:
  /// **'Lap {lap}'**
  String lap_label(String lap);

  /// No description provided for @lap_speed_stats.
  ///
  /// In en, this message translates to:
  /// **'LAP & SPEED STATS'**
  String get lap_speed_stats;

  /// No description provided for @laps.
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get laps;

  /// No description provided for @laps_led.
  ///
  /// In en, this message translates to:
  /// **'Laps Led'**
  String get laps_led;

  /// No description provided for @last_5_points.
  ///
  /// In en, this message translates to:
  /// **'Last 5 points'**
  String get last_5_points;

  /// No description provided for @last_podium_prefs_section_title.
  ///
  /// In en, this message translates to:
  /// **'Last podium'**
  String get last_podium_prefs_section_title;

  /// No description provided for @last_podium_prefs_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'How many recent races to show on circuit cards.'**
  String get last_podium_prefs_section_subtitle;

  /// No description provided for @last_podium_prefs_races_label.
  ///
  /// In en, this message translates to:
  /// **'Number of races'**
  String get last_podium_prefs_races_label;

  /// No description provided for @last_winner.
  ///
  /// In en, this message translates to:
  /// **'Last year winner'**
  String get last_winner;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @level_1.
  ///
  /// In en, this message translates to:
  /// **'Very Easy'**
  String get level_1;

  /// No description provided for @level_2.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get level_2;

  /// No description provided for @level_3.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get level_3;

  /// No description provided for @level_4.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get level_4;

  /// No description provided for @level_5.
  ///
  /// In en, this message translates to:
  /// **'Very Hard'**
  String get level_5;

  /// No description provided for @linked_update_many.
  ///
  /// In en, this message translates to:
  /// **'{count} linked updates'**
  String linked_update_many(String count);

  /// No description provided for @linked_update_one.
  ///
  /// In en, this message translates to:
  /// **'1 linked update'**
  String get linked_update_one;

  /// No description provided for @live_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get live_leaderboard;

  /// No description provided for @live_switch_test.
  ///
  /// In en, this message translates to:
  /// **'Switch to Test Data'**
  String get live_switch_test;

  /// No description provided for @live_teammate_battle.
  ///
  /// In en, this message translates to:
  /// **'Teammate Battle'**
  String get live_teammate_battle;

  /// No description provided for @live_timing_title.
  ///
  /// In en, this message translates to:
  /// **'Live Timing'**
  String get live_timing_title;

  /// No description provided for @live_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for live data...'**
  String get live_waiting;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @logged_in.
  ///
  /// In en, this message translates to:
  /// **'You are logged in'**
  String get logged_in;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @max_g_force.
  ///
  /// In en, this message translates to:
  /// **'Max G-Force'**
  String get max_g_force;

  /// No description provided for @medium_tire.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium_tire;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nat_argentine.
  ///
  /// In en, this message translates to:
  /// **'Argentine'**
  String get nat_argentine;

  /// No description provided for @nat_australian.
  ///
  /// In en, this message translates to:
  /// **'Australian'**
  String get nat_australian;

  /// No description provided for @nat_brazilian.
  ///
  /// In en, this message translates to:
  /// **'Brazilian'**
  String get nat_brazilian;

  /// No description provided for @nat_british.
  ///
  /// In en, this message translates to:
  /// **'British'**
  String get nat_british;

  /// No description provided for @nat_canadian.
  ///
  /// In en, this message translates to:
  /// **'Canadian'**
  String get nat_canadian;

  /// No description provided for @nat_dutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get nat_dutch;

  /// No description provided for @nat_finnish.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get nat_finnish;

  /// No description provided for @nat_french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get nat_french;

  /// No description provided for @nat_german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get nat_german;

  /// No description provided for @nat_italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get nat_italian;

  /// No description provided for @nat_japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get nat_japanese;

  /// No description provided for @nat_mexican.
  ///
  /// In en, this message translates to:
  /// **'Mexican'**
  String get nat_mexican;

  /// No description provided for @nat_monegasque.
  ///
  /// In en, this message translates to:
  /// **'Monegasque'**
  String get nat_monegasque;

  /// No description provided for @nat_new_zealander.
  ///
  /// In en, this message translates to:
  /// **'New Zealander'**
  String get nat_new_zealander;

  /// No description provided for @nat_spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get nat_spanish;

  /// No description provided for @nat_thai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get nat_thai;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @next_race.
  ///
  /// In en, this message translates to:
  /// **'Next Race'**
  String get next_race;

  /// No description provided for @no_data_yet.
  ///
  /// In en, this message translates to:
  /// **'Data not available yet or API pending update'**
  String get no_data_yet;

  /// No description provided for @no_finish_data.
  ///
  /// In en, this message translates to:
  /// **'No finish data'**
  String get no_finish_data;

  /// No description provided for @no_race_results_available.
  ///
  /// In en, this message translates to:
  /// **'No race results available yet.'**
  String get no_race_results_available;

  /// No description provided for @one_two.
  ///
  /// In en, this message translates to:
  /// **'1-2 Finishes'**
  String get one_two;

  /// No description provided for @overtakes.
  ///
  /// In en, this message translates to:
  /// **'Overtakes'**
  String get overtakes;

  /// No description provided for @overtaking_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Overtaking Difficulty'**
  String get overtaking_difficulty;

  /// No description provided for @partner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partner;

  /// No description provided for @penalties.
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get penalties;

  /// No description provided for @penalties_empty.
  ///
  /// In en, this message translates to:
  /// **'No penalties found in the current weekend cache.'**
  String get penalties_empty;

  /// No description provided for @penalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get penalty;

  /// No description provided for @personal_info.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personal_info;

  /// No description provided for @personal_sponsors.
  ///
  /// In en, this message translates to:
  /// **'Personal Sponsors'**
  String get personal_sponsors;

  /// No description provided for @pets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @pitstop_leadership.
  ///
  /// In en, this message translates to:
  /// **'Pitstop & Leadership'**
  String get pitstop_leadership;

  /// No description provided for @placeholder_page.
  ///
  /// In en, this message translates to:
  /// **'New page'**
  String get placeholder_page;

  /// No description provided for @placeholder_page_empty.
  ///
  /// In en, this message translates to:
  /// **'This page is empty for now.'**
  String get placeholder_page_empty;

  /// No description provided for @podiums.
  ///
  /// In en, this message translates to:
  /// **'Podiums'**
  String get podiums;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @points_after_each_race.
  ///
  /// In en, this message translates to:
  /// **'Standings after each race'**
  String get points_after_each_race;

  /// No description provided for @points_history.
  ///
  /// In en, this message translates to:
  /// **'Points per Season'**
  String get points_history;

  /// No description provided for @points_per_entry.
  ///
  /// In en, this message translates to:
  /// **'Points / entry'**
  String get points_per_entry;

  /// No description provided for @points_per_start.
  ///
  /// In en, this message translates to:
  /// **'Points / start'**
  String get points_per_start;

  /// No description provided for @points_progression.
  ///
  /// In en, this message translates to:
  /// **'Points progression'**
  String get points_progression;

  /// No description provided for @pole_rate.
  ///
  /// In en, this message translates to:
  /// **'Pole rate %'**
  String get pole_rate;

  /// No description provided for @poles.
  ///
  /// In en, this message translates to:
  /// **'Pole Positions'**
  String get poles;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'Pos'**
  String get pos;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @previous_teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get previous_teams;

  /// No description provided for @previous_winners.
  ///
  /// In en, this message translates to:
  /// **'Previous winners'**
  String get previous_winners;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get pts;

  /// No description provided for @q1_out.
  ///
  /// In en, this message translates to:
  /// **'Q1 out'**
  String get q1_out;

  /// No description provided for @q2_out.
  ///
  /// In en, this message translates to:
  /// **'Q2 out'**
  String get q2_out;

  /// No description provided for @qualifying.
  ///
  /// In en, this message translates to:
  /// **'Qualifying'**
  String get qualifying;

  /// No description provided for @race.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get race;

  /// No description provided for @race_control.
  ///
  /// In en, this message translates to:
  /// **'Race Control'**
  String get race_control;

  /// No description provided for @race_control_detail.
  ///
  /// In en, this message translates to:
  /// **'Race Control detail'**
  String get race_control_detail;

  /// No description provided for @race_control_empty.
  ///
  /// In en, this message translates to:
  /// **'No race control messages found for this filter or search.'**
  String get race_control_empty;

  /// No description provided for @race_control_filter_alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get race_control_filter_alerts;

  /// No description provided for @race_control_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get race_control_filter_all;

  /// No description provided for @race_control_filter_stewards.
  ///
  /// In en, this message translates to:
  /// **'Stewards'**
  String get race_control_filter_stewards;

  /// No description provided for @race_control_message_count.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total} messages'**
  String race_control_message_count(String visible, String total);

  /// No description provided for @race_control_no_linked_message.
  ///
  /// In en, this message translates to:
  /// **'No linked steward message found.'**
  String get race_control_no_linked_message;

  /// No description provided for @race_control_related_updates.
  ///
  /// In en, this message translates to:
  /// **'Related steward updates'**
  String get race_control_related_updates;

  /// No description provided for @race_control_relation_investigation.
  ///
  /// In en, this message translates to:
  /// **'Investigation'**
  String get race_control_relation_investigation;

  /// No description provided for @race_control_relation_issued_earlier.
  ///
  /// In en, this message translates to:
  /// **'Issued earlier'**
  String get race_control_relation_issued_earlier;

  /// No description provided for @race_control_relation_linked.
  ///
  /// In en, this message translates to:
  /// **'Linked message'**
  String get race_control_relation_linked;

  /// No description provided for @race_control_relation_message.
  ///
  /// In en, this message translates to:
  /// **'Race Control message'**
  String get race_control_relation_message;

  /// No description provided for @race_control_relation_noted.
  ///
  /// In en, this message translates to:
  /// **'Noted'**
  String get race_control_relation_noted;

  /// No description provided for @race_control_relation_outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get race_control_relation_outcome;

  /// No description provided for @race_control_relation_penalty_message.
  ///
  /// In en, this message translates to:
  /// **'Penalty message'**
  String get race_control_relation_penalty_message;

  /// No description provided for @race_control_relation_served_later.
  ///
  /// In en, this message translates to:
  /// **'Served later'**
  String get race_control_relation_served_later;

  /// No description provided for @race_control_relation_served_penalty.
  ///
  /// In en, this message translates to:
  /// **'Served penalty'**
  String get race_control_relation_served_penalty;

  /// No description provided for @race_control_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search by message, flag, category, lap or driver'**
  String get race_control_search_hint;

  /// No description provided for @race_stats.
  ///
  /// In en, this message translates to:
  /// **'Race Stats'**
  String get race_stats;

  /// No description provided for @rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// No description provided for @rain_chance.
  ///
  /// In en, this message translates to:
  /// **'Rain Chance'**
  String get rain_chance;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @red_flag.
  ///
  /// In en, this message translates to:
  /// **'Red Flag Chance'**
  String get red_flag;

  /// No description provided for @reserve_driver.
  ///
  /// In en, this message translates to:
  /// **'Reserve Driver'**
  String get reserve_driver;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @retirements.
  ///
  /// In en, this message translates to:
  /// **'Retirements'**
  String get retirements;

  /// No description provided for @risks.
  ///
  /// In en, this message translates to:
  /// **'Risks'**
  String get risks;

  /// No description provided for @risks_incidents.
  ///
  /// In en, this message translates to:
  /// **'RISKS & INCIDENTS'**
  String get risks_incidents;

  /// No description provided for @round_short.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get round_short;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scope;

  /// No description provided for @season_2026.
  ///
  /// In en, this message translates to:
  /// **'2026 Season'**
  String get season_2026;

  /// No description provided for @select_drivers_to_compare.
  ///
  /// In en, this message translates to:
  /// **'Select 2 drivers'**
  String get select_drivers_to_compare;

  /// No description provided for @select_favorite.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get select_favorite;

  /// No description provided for @select_teams_to_compare.
  ///
  /// In en, this message translates to:
  /// **'Select 2 teams'**
  String get select_teams_to_compare;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @session_data_unavailable.
  ///
  /// In en, this message translates to:
  /// **'{session} data is loading or not available yet.'**
  String session_data_unavailable(String session);

  /// No description provided for @session_future.
  ///
  /// In en, this message translates to:
  /// **'Session begins at'**
  String get session_future;

  /// No description provided for @session_results.
  ///
  /// In en, this message translates to:
  /// **'Session Results'**
  String get session_results;

  /// No description provided for @session_status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get session_status_completed;

  /// No description provided for @session_status_live_recent.
  ///
  /// In en, this message translates to:
  /// **'Live / Recent'**
  String get session_status_live_recent;

  /// No description provided for @session_status_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get session_status_upcoming;

  /// No description provided for @session_weather_unavailable.
  ///
  /// In en, this message translates to:
  /// **'No weather data available for {session}.'**
  String session_weather_unavailable(String session);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @show_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get show_all;

  /// No description provided for @show_all_messages.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} messages'**
  String show_all_messages(String count);

  /// No description provided for @show_less_messages.
  ///
  /// In en, this message translates to:
  /// **'Show fewer messages'**
  String get show_less_messages;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'On calendar since'**
  String get since;

  /// No description provided for @slowest_lap.
  ///
  /// In en, this message translates to:
  /// **'Slowest Lap'**
  String get slowest_lap;

  /// No description provided for @soft_tire.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get soft_tire;

  /// No description provided for @sponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get sponsors;

  /// No description provided for @sprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get sprint;

  /// No description provided for @sprint_quali.
  ///
  /// In en, this message translates to:
  /// **'Sprint Qualifying'**
  String get sprint_quali;

  /// No description provided for @standings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get standings;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @starts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get starts;

  /// No description provided for @starts_in.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get starts_in;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @strategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get strategy;

  /// No description provided for @strategy_1_stop.
  ///
  /// In en, this message translates to:
  /// **'1 stop'**
  String get strategy_1_stop;

  /// No description provided for @strategy_2_stops.
  ///
  /// In en, this message translates to:
  /// **'2 stops'**
  String get strategy_2_stops;

  /// No description provided for @strategy_3_stops.
  ///
  /// In en, this message translates to:
  /// **'3 stops'**
  String get strategy_3_stops;

  /// No description provided for @summer_break.
  ///
  /// In en, this message translates to:
  /// **'Summer break'**
  String get summer_break;

  /// No description provided for @summer_break_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The summer break sits between Hungary and the Netherlands.'**
  String get summer_break_subtitle;

  /// No description provided for @team_facts_title.
  ///
  /// In en, this message translates to:
  /// **'Did You Know?'**
  String get team_facts_title;

  /// No description provided for @team_history.
  ///
  /// In en, this message translates to:
  /// **'Team History'**
  String get team_history;

  /// No description provided for @team_principal.
  ///
  /// In en, this message translates to:
  /// **'Team Principal'**
  String get team_principal;

  /// No description provided for @team_theme.
  ///
  /// In en, this message translates to:
  /// **'Team Theme'**
  String get team_theme;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @teams_chart.
  ///
  /// In en, this message translates to:
  /// **'Teams chart'**
  String get teams_chart;

  /// No description provided for @technical_director.
  ///
  /// In en, this message translates to:
  /// **'Technical Director'**
  String get technical_director;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temp;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// No description provided for @theme_mode_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_mode_dark;

  /// No description provided for @theme_mode_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_mode_light;

  /// No description provided for @theme_mode_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_mode_system;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @time_gap.
  ///
  /// In en, this message translates to:
  /// **'Time / Gap'**
  String get time_gap;

  /// No description provided for @tire_wear.
  ///
  /// In en, this message translates to:
  /// **'Tire Wear'**
  String get tire_wear;

  /// No description provided for @toggle_theme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggle_theme;

  /// No description provided for @top_10.
  ///
  /// In en, this message translates to:
  /// **'Top 10'**
  String get top_10;

  /// No description provided for @top_3.
  ///
  /// In en, this message translates to:
  /// **'Top 3'**
  String get top_3;

  /// No description provided for @top_5.
  ///
  /// In en, this message translates to:
  /// **'Top 5'**
  String get top_5;

  /// No description provided for @top_speed.
  ///
  /// In en, this message translates to:
  /// **'Top Speed'**
  String get top_speed;

  /// No description provided for @total_entries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get total_entries;

  /// No description provided for @total_length.
  ///
  /// In en, this message translates to:
  /// **'Total Length'**
  String get total_length;

  /// No description provided for @total_points.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get total_points;

  /// No description provided for @total_time.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get total_time;

  /// No description provided for @track_flag_double_yellow.
  ///
  /// In en, this message translates to:
  /// **'Double yellow'**
  String get track_flag_double_yellow;

  /// No description provided for @track_flag_green.
  ///
  /// In en, this message translates to:
  /// **'Green flag'**
  String get track_flag_green;

  /// No description provided for @track_flag_red.
  ///
  /// In en, this message translates to:
  /// **'Red flag'**
  String get track_flag_red;

  /// No description provided for @track_flag_yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow flag'**
  String get track_flag_yellow;

  /// No description provided for @track_playback_dry_track.
  ///
  /// In en, this message translates to:
  /// **'Dry track'**
  String get track_playback_dry_track;

  /// No description provided for @track_playback_interpolated_minute.
  ///
  /// In en, this message translates to:
  /// **'interpolated minute'**
  String get track_playback_interpolated_minute;

  /// No description provided for @track_playback_no_weather.
  ///
  /// In en, this message translates to:
  /// **'No weather data available for this session.'**
  String get track_playback_no_weather;

  /// No description provided for @track_playback_rain_active.
  ///
  /// In en, this message translates to:
  /// **'Rain active'**
  String get track_playback_rain_active;

  /// No description provided for @track_playback_recorded_sample.
  ///
  /// In en, this message translates to:
  /// **'recorded sample'**
  String get track_playback_recorded_sample;

  /// No description provided for @track_playback_title.
  ///
  /// In en, this message translates to:
  /// **'Track Playback'**
  String get track_playback_title;

  /// No description provided for @track_playback_unknown_sample.
  ///
  /// In en, this message translates to:
  /// **'Unknown sample'**
  String get track_playback_unknown_sample;

  /// No description provided for @track_temperature.
  ///
  /// In en, this message translates to:
  /// **'Track temperature'**
  String get track_temperature;

  /// No description provided for @turn1_accident.
  ///
  /// In en, this message translates to:
  /// **'Turn 1 Accident Chance'**
  String get turn1_accident;

  /// No description provided for @tyre.
  ///
  /// In en, this message translates to:
  /// **'Tyre'**
  String get tyre;

  /// No description provided for @tyres.
  ///
  /// In en, this message translates to:
  /// **'Tyres'**
  String get tyres;

  /// No description provided for @tyres_strategy.
  ///
  /// In en, this message translates to:
  /// **'TYRES & STRATEGY'**
  String get tyres_strategy;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknown_sample.
  ///
  /// In en, this message translates to:
  /// **'Unknown sample'**
  String get unknown_sample;

  /// No description provided for @unknown_time.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get unknown_time;

  /// No description provided for @until.
  ///
  /// In en, this message translates to:
  /// **'Contract until'**
  String get until;

  /// No description provided for @used_tyre.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used_tyre;

  /// No description provided for @using_fallback_data.
  ///
  /// In en, this message translates to:
  /// **'Using offline/fallback data.'**
  String get using_fallback_data;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @vsc.
  ///
  /// In en, this message translates to:
  /// **'VSC Chance'**
  String get vsc;

  /// No description provided for @wear_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get wear_high;

  /// No description provided for @wear_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get wear_low;

  /// No description provided for @wear_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get wear_medium;

  /// No description provided for @weather_forecast.
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast'**
  String get weather_forecast;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @weekend_hub.
  ///
  /// In en, this message translates to:
  /// **'Weekend Hub'**
  String get weekend_hub;

  /// No description provided for @weekend_hub_card_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule, weather, podium and penalties in one screen'**
  String get weekend_hub_card_subtitle;

  /// No description provided for @weekend_hub_load_error.
  ///
  /// In en, this message translates to:
  /// **'Weekend Hub could not be fully loaded. Cached data is being shown.'**
  String get weekend_hub_load_error;

  /// No description provided for @weekend_hub_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading Weekend Hub...'**
  String get weekend_hub_loading;

  /// No description provided for @weekend_schedule.
  ///
  /// In en, this message translates to:
  /// **'Weekend schedule'**
  String get weekend_schedule;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @win_rate.
  ///
  /// In en, this message translates to:
  /// **'Win rate %'**
  String get win_rate;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @wind_speed.
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get wind_speed;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @ai_fab_label.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai_fab_label;

  /// No description provided for @auth_error_message.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String auth_error_message(String message);

  /// No description provided for @calendar_race_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get calendar_race_status_cancelled;

  /// No description provided for @calendar_race_status_ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get calendar_race_status_ended;

  /// No description provided for @calendar_race_status_ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get calendar_race_status_ongoing;

  /// No description provided for @circuit_open_in_maps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get circuit_open_in_maps;

  /// No description provided for @live_timing_air_temp_abbr.
  ///
  /// In en, this message translates to:
  /// **'A {temp}'**
  String live_timing_air_temp_abbr(String temp);

  /// No description provided for @live_timing_banner_green.
  ///
  /// In en, this message translates to:
  /// **'GREEN'**
  String get live_timing_banner_green;

  /// No description provided for @live_timing_banner_red_flag.
  ///
  /// In en, this message translates to:
  /// **'RED FLAG'**
  String get live_timing_banner_red_flag;

  /// No description provided for @live_timing_banner_safety_car.
  ///
  /// In en, this message translates to:
  /// **'SAFETY CAR'**
  String get live_timing_banner_safety_car;

  /// No description provided for @live_timing_banner_vsc_deployed.
  ///
  /// In en, this message translates to:
  /// **'VSC DEPLOYED'**
  String get live_timing_banner_vsc_deployed;

  /// No description provided for @live_timing_banner_vsc_ending.
  ///
  /// In en, this message translates to:
  /// **'VSC ENDING'**
  String get live_timing_banner_vsc_ending;

  /// No description provided for @live_timing_banner_yellow_flag.
  ///
  /// In en, this message translates to:
  /// **'YELLOW FLAG'**
  String get live_timing_banner_yellow_flag;

  /// No description provided for @live_timing_chip_red_flag.
  ///
  /// In en, this message translates to:
  /// **'RED FLAG'**
  String get live_timing_chip_red_flag;

  /// No description provided for @live_timing_chip_safety_car.
  ///
  /// In en, this message translates to:
  /// **'SAFETY CAR'**
  String get live_timing_chip_safety_car;

  /// No description provided for @live_timing_chip_vsc.
  ///
  /// In en, this message translates to:
  /// **'VSC'**
  String get live_timing_chip_vsc;

  /// No description provided for @live_timing_chip_vsc_end.
  ///
  /// In en, this message translates to:
  /// **'VSC END'**
  String get live_timing_chip_vsc_end;

  /// No description provided for @live_timing_chip_yellow.
  ///
  /// In en, this message translates to:
  /// **'YELLOW'**
  String get live_timing_chip_yellow;

  /// No description provided for @live_timing_data_source.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String live_timing_data_source(String source);

  /// No description provided for @live_timing_demo_session_title.
  ///
  /// In en, this message translates to:
  /// **'Silverstone 2024'**
  String get live_timing_demo_session_title;

  /// No description provided for @live_timing_driver_out.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get live_timing_driver_out;

  /// No description provided for @live_timing_driver_pit.
  ///
  /// In en, this message translates to:
  /// **'PIT'**
  String get live_timing_driver_pit;

  /// No description provided for @live_timing_header_driver.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get live_timing_header_driver;

  /// No description provided for @live_timing_header_gain.
  ///
  /// In en, this message translates to:
  /// **'GAIN'**
  String get live_timing_header_gain;

  /// No description provided for @live_timing_header_int_gap.
  ///
  /// In en, this message translates to:
  /// **'INT / GAP'**
  String get live_timing_header_int_gap;

  /// No description provided for @live_timing_header_pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get live_timing_header_pos;

  /// No description provided for @live_timing_header_s1.
  ///
  /// In en, this message translates to:
  /// **'S1'**
  String get live_timing_header_s1;

  /// No description provided for @live_timing_header_s2.
  ///
  /// In en, this message translates to:
  /// **'S2'**
  String get live_timing_header_s2;

  /// No description provided for @live_timing_header_s3.
  ///
  /// In en, this message translates to:
  /// **'S3'**
  String get live_timing_header_s3;

  /// No description provided for @live_timing_header_tyre.
  ///
  /// In en, this message translates to:
  /// **'TYRE'**
  String get live_timing_header_tyre;

  /// No description provided for @live_timing_hub_timestamp_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Timestamp of last message (stream)'**
  String get live_timing_hub_timestamp_tooltip;

  /// No description provided for @live_timing_lap_of_total.
  ///
  /// In en, this message translates to:
  /// **'Lap {current} / {total}'**
  String live_timing_lap_of_total(String current, String total);

  /// No description provided for @live_timing_session_pre_start.
  ///
  /// In en, this message translates to:
  /// **'PRE-START'**
  String get live_timing_session_pre_start;

  /// No description provided for @live_timing_session_starting_grid.
  ///
  /// In en, this message translates to:
  /// **'STARTING GRID'**
  String get live_timing_session_starting_grid;

  /// No description provided for @live_timing_status_green.
  ///
  /// In en, this message translates to:
  /// **'GREEN'**
  String get live_timing_status_green;

  /// No description provided for @live_timing_track_temp_abbr.
  ///
  /// In en, this message translates to:
  /// **'T {temp}'**
  String live_timing_track_temp_abbr(String temp);

  /// No description provided for @metric_label_value.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String metric_label_value(String label, String value);

  /// No description provided for @news_load_error.
  ///
  /// In en, this message translates to:
  /// **'Could not load news: {error}'**
  String news_load_error(String error);

  /// No description provided for @news_title.
  ///
  /// In en, this message translates to:
  /// **'F1 News'**
  String get news_title;

  /// No description provided for @news_nav.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news_nav;

  /// No description provided for @news_empty.
  ///
  /// In en, this message translates to:
  /// **'No articles right now. Pull to refresh.'**
  String get news_empty;

  /// No description provided for @news_settings_title.
  ///
  /// In en, this message translates to:
  /// **'News feeds'**
  String get news_settings_title;

  /// No description provided for @news_settings_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add RSS or Atom URLs. They are loaded on the News tab (newest first).'**
  String get news_settings_subtitle;

  /// No description provided for @news_settings_url_hint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/feed.xml'**
  String get news_settings_url_hint;

  /// No description provided for @news_settings_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get news_settings_add;

  /// No description provided for @news_settings_your_feeds.
  ///
  /// In en, this message translates to:
  /// **'Your feeds'**
  String get news_settings_your_feeds;

  /// No description provided for @news_settings_no_feeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds yet. Add a URL above.'**
  String get news_settings_no_feeds;

  /// No description provided for @news_settings_invalid_url.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http(s) URL.'**
  String get news_settings_invalid_url;

  /// No description provided for @news_settings_duplicate_url.
  ///
  /// In en, this message translates to:
  /// **'That URL is already in your list.'**
  String get news_settings_duplicate_url;

  /// No description provided for @news_settings_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Try again.'**
  String get news_settings_save_failed;

  /// No description provided for @news_settings_stream_error.
  ///
  /// In en, this message translates to:
  /// **'Could not subscribe to profile updates.'**
  String get news_settings_stream_error;

  /// No description provided for @race_results_empty.
  ///
  /// In en, this message translates to:
  /// **'No race results available yet.'**
  String get race_results_empty;

  /// No description provided for @secure_page_authorized.
  ///
  /// In en, this message translates to:
  /// **'You are authorized!'**
  String get secure_page_authorized;

  /// No description provided for @secure_page_title.
  ///
  /// In en, this message translates to:
  /// **'Secure Page'**
  String get secure_page_title;

  /// No description provided for @team_comparison_title.
  ///
  /// In en, this message translates to:
  /// **'{team1} vs {team2}'**
  String team_comparison_title(String team1, String team2);

  /// No description provided for @unauthorized_page_message.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to view this page.'**
  String get unauthorized_page_message;

  /// No description provided for @unauthorized_page_title.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorized_page_title;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'nl': return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
