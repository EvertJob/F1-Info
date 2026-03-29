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

  /// No description provided for @best_tyre_combination.
  ///
  /// In en, this message translates to:
  /// **'Best Combination'**
  String get best_tyre_combination;

  /// No description provided for @cfield_air_pressure_hpa.
  ///
  /// In en, this message translates to:
  /// **'Air pressure'**
  String get cfield_air_pressure_hpa;

  /// No description provided for @cfield_asphalt_grip_score.
  ///
  /// In en, this message translates to:
  /// **'Asphalt grip score'**
  String get cfield_asphalt_grip_score;

  /// No description provided for @cfield_avg_g_force.
  ///
  /// In en, this message translates to:
  /// **'Average G-force'**
  String get cfield_avg_g_force;

  /// No description provided for @cfield_avg_time_2024_2025.
  ///
  /// In en, this message translates to:
  /// **'Average lap time (2024–25)'**
  String get cfield_avg_time_2024_2025;

  /// No description provided for @cfield_brake_cooling_requirement_score.
  ///
  /// In en, this message translates to:
  /// **'Brake cooling requirement'**
  String get cfield_brake_cooling_requirement_score;

  /// No description provided for @cfield_circuit_director.
  ///
  /// In en, this message translates to:
  /// **'Circuit director'**
  String get cfield_circuit_director;

  /// No description provided for @cfield_circuit_owner.
  ///
  /// In en, this message translates to:
  /// **'Circuit owner'**
  String get cfield_circuit_owner;

  /// No description provided for @cfield_contract_until.
  ///
  /// In en, this message translates to:
  /// **'Contract until'**
  String get cfield_contract_until;

  /// No description provided for @cfield_deployment_focus.
  ///
  /// In en, this message translates to:
  /// **'Deployment focus'**
  String get cfield_deployment_focus;

  /// No description provided for @cfield_direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get cfield_direction;

  /// No description provided for @cfield_distance_to_t1.
  ///
  /// In en, this message translates to:
  /// **'Distance to Turn 1'**
  String get cfield_distance_to_t1;

  /// No description provided for @cfield_electrical_ratio.
  ///
  /// In en, this message translates to:
  /// **'Electrical ratio'**
  String get cfield_electrical_ratio;

  /// No description provided for @cfield_energy_flow_strategy.
  ///
  /// In en, this message translates to:
  /// **'Energy flow strategy'**
  String get cfield_energy_flow_strategy;

  /// No description provided for @cfield_engine_derating_risk.
  ///
  /// In en, this message translates to:
  /// **'Engine derating risk'**
  String get cfield_engine_derating_risk;

  /// No description provided for @cfield_era_delta.
  ///
  /// In en, this message translates to:
  /// **'Era delta'**
  String get cfield_era_delta;

  /// No description provided for @cfield_est_time_2026.
  ///
  /// In en, this message translates to:
  /// **'Estimated lap time (2026)'**
  String get cfield_est_time_2026;

  /// No description provided for @cfield_elevation_sea_level.
  ///
  /// In en, this message translates to:
  /// **'Elevation (sea level)'**
  String get cfield_elevation_sea_level;

  /// No description provided for @cfield_harvest_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Harvest difficulty'**
  String get cfield_harvest_difficulty;

  /// No description provided for @cfield_harvesting_zones.
  ///
  /// In en, this message translates to:
  /// **'Harvesting zones'**
  String get cfield_harvesting_zones;

  /// No description provided for @cfield_latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get cfield_latitude;

  /// No description provided for @cfield_local_time_zone.
  ///
  /// In en, this message translates to:
  /// **'Local time zone'**
  String get cfield_local_time_zone;

  /// No description provided for @cfield_longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get cfield_longitude;

  /// No description provided for @cfield_lap_record_detail.
  ///
  /// In en, this message translates to:
  /// **'Lap record'**
  String get cfield_lap_record_detail;

  /// No description provided for @cfield_laps.
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get cfield_laps;

  /// No description provided for @cfield_lateral_stress_score.
  ///
  /// In en, this message translates to:
  /// **'Lateral stress score'**
  String get cfield_lateral_stress_score;

  /// No description provided for @cfield_length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get cfield_length;

  /// No description provided for @cfield_manual_override_energy_cost.
  ///
  /// In en, this message translates to:
  /// **'Manual override energy cost'**
  String get cfield_manual_override_energy_cost;

  /// No description provided for @cfield_manual_override_points.
  ///
  /// In en, this message translates to:
  /// **'Manual override points'**
  String get cfield_manual_override_points;

  /// No description provided for @cfield_max_elevation_change.
  ///
  /// In en, this message translates to:
  /// **'Max elevation change'**
  String get cfield_max_elevation_change;

  /// No description provided for @cfield_max_g_force.
  ///
  /// In en, this message translates to:
  /// **'Max G-force'**
  String get cfield_max_g_force;

  /// No description provided for @cfield_override_impact_score.
  ///
  /// In en, this message translates to:
  /// **'Override impact score'**
  String get cfield_override_impact_score;

  /// No description provided for @cfield_on_calendar_since.
  ///
  /// In en, this message translates to:
  /// **'On calendar since'**
  String get cfield_on_calendar_since;

  /// No description provided for @cfield_overtaking_delta.
  ///
  /// In en, this message translates to:
  /// **'Overtaking delta'**
  String get cfield_overtaking_delta;

  /// No description provided for @cfield_pit_exit_delta.
  ///
  /// In en, this message translates to:
  /// **'Pit exit delta'**
  String get cfield_pit_exit_delta;

  /// No description provided for @cfield_pitstop_record_detail.
  ///
  /// In en, this message translates to:
  /// **'Pit stop record'**
  String get cfield_pitstop_record_detail;

  /// No description provided for @cfield_race_day_capacity.
  ///
  /// In en, this message translates to:
  /// **'Race day capacity'**
  String get cfield_race_day_capacity;

  /// No description provided for @cfield_rain_chance.
  ///
  /// In en, this message translates to:
  /// **'Rain chance'**
  String get cfield_rain_chance;

  /// No description provided for @cfield_recovery_points.
  ///
  /// In en, this message translates to:
  /// **'Recovery points'**
  String get cfield_recovery_points;

  /// No description provided for @cfield_red_flag_prob.
  ///
  /// In en, this message translates to:
  /// **'Red flag probability'**
  String get cfield_red_flag_prob;

  /// No description provided for @cfield_s1.
  ///
  /// In en, this message translates to:
  /// **'Sector 1'**
  String get cfield_s1;

  /// No description provided for @cfield_s2.
  ///
  /// In en, this message translates to:
  /// **'Sector 2'**
  String get cfield_s2;

  /// No description provided for @cfield_s3.
  ///
  /// In en, this message translates to:
  /// **'Sector 3'**
  String get cfield_s3;

  /// No description provided for @cfield_safety_car_prob.
  ///
  /// In en, this message translates to:
  /// **'Safety Car probability'**
  String get cfield_safety_car_prob;

  /// No description provided for @cfield_safety_car_window_laps.
  ///
  /// In en, this message translates to:
  /// **'Safety Car window (laps)'**
  String get cfield_safety_car_window_laps;

  /// No description provided for @cfield_straight_mode_zones.
  ///
  /// In en, this message translates to:
  /// **'Straight Mode zones'**
  String get cfield_straight_mode_zones;

  /// No description provided for @cfield_sun_angle_start.
  ///
  /// In en, this message translates to:
  /// **'Sun angle at start'**
  String get cfield_sun_angle_start;

  /// No description provided for @cfield_t1_accident_risk.
  ///
  /// In en, this message translates to:
  /// **'Turn 1 accident risk'**
  String get cfield_t1_accident_risk;

  /// No description provided for @cfield_temperature_c.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get cfield_temperature_c;

  /// No description provided for @cfield_top_speed.
  ///
  /// In en, this message translates to:
  /// **'Top speed'**
  String get cfield_top_speed;

  /// No description provided for @cfield_top_speed_delta.
  ///
  /// In en, this message translates to:
  /// **'Top speed delta'**
  String get cfield_top_speed_delta;

  /// No description provided for @cfield_track_evolution.
  ///
  /// In en, this message translates to:
  /// **'Track evolution'**
  String get cfield_track_evolution;

  /// No description provided for @cfield_track_type.
  ///
  /// In en, this message translates to:
  /// **'Track type'**
  String get cfield_track_type;

  /// No description provided for @cfield_tyre_physics.
  ///
  /// In en, this message translates to:
  /// **'Tyre physics'**
  String get cfield_tyre_physics;

  /// No description provided for @cfield_tyre_working_window_c.
  ///
  /// In en, this message translates to:
  /// **'Tyre working window'**
  String get cfield_tyre_working_window_c;

  /// No description provided for @cfield_undercut_potential_score.
  ///
  /// In en, this message translates to:
  /// **'Undercut potential'**
  String get cfield_undercut_potential_score;

  /// No description provided for @cfield_utc_offset.
  ///
  /// In en, this message translates to:
  /// **'UTC offset'**
  String get cfield_utc_offset;

  /// No description provided for @cfield_vsc_prob.
  ///
  /// In en, this message translates to:
  /// **'VSC probability'**
  String get cfield_vsc_prob;

  /// No description provided for @cfield_wind_sensitivity_sector.
  ///
  /// In en, this message translates to:
  /// **'Wind sensitivity (sector)'**
  String get cfield_wind_sensitivity_sector;

  /// No description provided for @cfield_x_mode_usage.
  ///
  /// In en, this message translates to:
  /// **'X mode usage'**
  String get cfield_x_mode_usage;

  /// No description provided for @cfield_z_mode_activation_delay.
  ///
  /// In en, this message translates to:
  /// **'Z mode activation delay'**
  String get cfield_z_mode_activation_delay;

  /// No description provided for @cfield_z_mode_usage.
  ///
  /// In en, this message translates to:
  /// **'Z mode usage'**
  String get cfield_z_mode_usage;

  /// No description provided for @cfield_zone_name.
  ///
  /// In en, this message translates to:
  /// **'Time zone name'**
  String get cfield_zone_name;

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

  /// No description provided for @championship_leader_pill.
  ///
  /// In en, this message translates to:
  /// **'Championship leader'**
  String get championship_leader_pill;

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

  /// No description provided for @cat_ambient_stats.
  ///
  /// In en, this message translates to:
  /// **'Ambient Conditions'**
  String get cat_ambient_stats;

  /// No description provided for @cat_history_comparison.
  ///
  /// In en, this message translates to:
  /// **'Era Comparison'**
  String get cat_history_comparison;

  /// No description provided for @cat_risks_stats.
  ///
  /// In en, this message translates to:
  /// **'Performance & Risk'**
  String get cat_risks_stats;

  /// No description provided for @cat_tech_2026.
  ///
  /// In en, this message translates to:
  /// **'2026 Tech & Aero'**
  String get cat_tech_2026;

  /// No description provided for @cat_track_specs.
  ///
  /// In en, this message translates to:
  /// **'Track Geometry'**
  String get cat_track_specs;

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

  /// No description provided for @circuit_difficulty_l10n.
  ///
  /// In en, this message translates to:
  /// **'Circuit Difficulty'**
  String get circuit_difficulty_l10n;

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

  /// No description provided for @diff_easy.
  ///
  /// In en, this message translates to:
  /// **'Very Easy'**
  String get diff_easy;

  /// No description provided for @diff_extreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get diff_extreme;

  /// No description provided for @diff_hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get diff_hard;

  /// No description provided for @diff_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get diff_high;

  /// No description provided for @diff_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get diff_low;

  /// No description provided for @diff_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get diff_medium;

  /// No description provided for @dir_clockwise.
  ///
  /// In en, this message translates to:
  /// **'Clockwise'**
  String get dir_clockwise;

  /// No description provided for @dir_counter_clockwise.
  ///
  /// In en, this message translates to:
  /// **'Counter-Clockwise'**
  String get dir_counter_clockwise;

  /// No description provided for @dir_figure_eight.
  ///
  /// In en, this message translates to:
  /// **'Figure-Eight'**
  String get dir_figure_eight;

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

  /// No description provided for @feature_130r_high_speed.
  ///
  /// In en, this message translates to:
  /// **'Iconic 130R High-Speed Left'**
  String get feature_130r_high_speed;

  /// No description provided for @feature_90_degree_corners.
  ///
  /// In en, this message translates to:
  /// **'Sequential 90-Degree Street Turns'**
  String get feature_90_degree_corners;

  /// No description provided for @feature_abrasive_asphalt.
  ///
  /// In en, this message translates to:
  /// **'Highly Abrasive Asphalt'**
  String get feature_abrasive_asphalt;

  /// No description provided for @feature_aggressive_kerbs.
  ///
  /// In en, this message translates to:
  /// **'Aggressive Sausage Kerb Risk'**
  String get feature_aggressive_kerbs;

  /// No description provided for @feature_aero_efficiency_test.
  ///
  /// In en, this message translates to:
  /// **'Ultimate Aero Efficiency Test'**
  String get feature_aero_efficiency_test;

  /// No description provided for @feature_banked_corners_t3_t14.
  ///
  /// In en, this message translates to:
  /// **'Unique Banked Corners (T3 & T14)'**
  String get feature_banked_corners_t3_t14;

  /// No description provided for @feature_battery_drain_kemmel.
  ///
  /// In en, this message translates to:
  /// **'High Battery Drain (Kemmel Straight)'**
  String get feature_battery_drain_kemmel;

  /// No description provided for @feature_blind_corners.
  ///
  /// In en, this message translates to:
  /// **'Dangerous Blind Apexes'**
  String get feature_blind_corners;

  /// No description provided for @feature_bumpy_city_roads.
  ///
  /// In en, this message translates to:
  /// **'Highly Irregular City Road Surface'**
  String get feature_bumpy_city_roads;

  /// No description provided for @feature_bumpy_surface.
  ///
  /// In en, this message translates to:
  /// **'Bumpy Track Surface'**
  String get feature_bumpy_surface;

  /// No description provided for @feature_bumpy_surface_subsidence.
  ///
  /// In en, this message translates to:
  /// **'Surface Bumps due to Subsidence'**
  String get feature_bumpy_surface_subsidence;

  /// No description provided for @feature_castle_section_tight.
  ///
  /// In en, this message translates to:
  /// **'Ultra-Tight Castle Section'**
  String get feature_castle_section_tight;

  /// No description provided for @feature_cold_tire_struggle.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Retaining Tire Heat'**
  String get feature_cold_tire_struggle;

  /// No description provided for @feature_curb_riding_chicane.
  ///
  /// In en, this message translates to:
  /// **'Aggressive Chicane Curb Riding'**
  String get feature_curb_riding_chicane;

  /// No description provided for @feature_degner_curves.
  ///
  /// In en, this message translates to:
  /// **'Precise Degner Curves'**
  String get feature_degner_curves;

  /// No description provided for @feature_dusty_surface.
  ///
  /// In en, this message translates to:
  /// **'Initially Dusty Surface Conditions'**
  String get feature_dusty_surface;

  /// No description provided for @feature_eau_rouge_raidillon.
  ///
  /// In en, this message translates to:
  /// **'Legendary Eau Rouge-Raidillon'**
  String get feature_eau_rouge_raidillon;

  /// No description provided for @feature_esses_section_flow.
  ///
  /// In en, this message translates to:
  /// **'High-Speed Rhythmic Esses'**
  String get feature_esses_section_flow;

  /// No description provided for @feature_extreme_altitude.
  ///
  /// In en, this message translates to:
  /// **'Extreme Altitude (2,200m+)'**
  String get feature_extreme_altitude;

  /// No description provided for @feature_extreme_humidity.
  ///
  /// In en, this message translates to:
  /// **'Oppressive Equatorial Humidity'**
  String get feature_extreme_humidity;

  /// No description provided for @feature_extreme_low_drag.
  ///
  /// In en, this message translates to:
  /// **'Extreme Low-Drag Aero Setup'**
  String get feature_extreme_low_drag;

  /// No description provided for @feature_fastest_street_track.
  ///
  /// In en, this message translates to:
  /// **'Fastest Street Track on Calendar'**
  String get feature_fastest_street_track;

  /// No description provided for @feature_figure_eight_layout.
  ///
  /// In en, this message translates to:
  /// **'Unique Figure-Eight Layout'**
  String get feature_figure_eight_layout;

  /// No description provided for @feature_glittering_night_race.
  ///
  /// In en, this message translates to:
  /// **'Glittering Night-Time Backdrop'**
  String get feature_glittering_night_race;

  /// No description provided for @feature_groundhog_risk.
  ///
  /// In en, this message translates to:
  /// **'Local Wildlife (Groundhog) Risk'**
  String get feature_groundhog_risk;

  /// No description provided for @feature_heavy_braking.
  ///
  /// In en, this message translates to:
  /// **'Severe Braking Demands'**
  String get feature_heavy_braking;

  /// No description provided for @feature_heavy_braking_variante.
  ///
  /// In en, this message translates to:
  /// **'Hard Braking into Chicanes'**
  String get feature_heavy_braking_variante;

  /// No description provided for @feature_heavy_braking_zones.
  ///
  /// In en, this message translates to:
  /// **'Hard Braking into Chicanes'**
  String get feature_heavy_braking_zones;

  /// No description provided for @feature_heavy_traction_points.
  ///
  /// In en, this message translates to:
  /// **'Critical Low-Speed Traction Zones'**
  String get feature_heavy_traction_points;

  /// No description provided for @feature_high_altitude_cooling.
  ///
  /// In en, this message translates to:
  /// **'High Altitude Power Unit Cooling'**
  String get feature_high_altitude_cooling;

  /// No description provided for @feature_high_altitude_impact.
  ///
  /// In en, this message translates to:
  /// **'Significant Altitude Aero Impact'**
  String get feature_high_altitude_impact;

  /// No description provided for @feature_high_downforce_focus.
  ///
  /// In en, this message translates to:
  /// **'Maximum Downforce Priority'**
  String get feature_high_downforce_focus;

  /// No description provided for @feature_high_front_tyre_wear.
  ///
  /// In en, this message translates to:
  /// **'High Front Tyre Degradation'**
  String get feature_high_front_tyre_wear;

  /// No description provided for @feature_high_humidity.
  ///
  /// In en, this message translates to:
  /// **'High Ambient Humidity'**
  String get feature_high_humidity;

  /// No description provided for @feature_high_kerb_usage.
  ///
  /// In en, this message translates to:
  /// **'Aggressive Kerb Riding'**
  String get feature_high_kerb_usage;

  /// No description provided for @feature_high_lateral_load.
  ///
  /// In en, this message translates to:
  /// **'Intense Lateral G-Force Loads'**
  String get feature_high_lateral_load;

  /// No description provided for @feature_high_speed_corners.
  ///
  /// In en, this message translates to:
  /// **'Ultra High-Speed Cornering'**
  String get feature_high_speed_corners;

  /// No description provided for @feature_high_speed_flow.
  ///
  /// In en, this message translates to:
  /// **'Continuous High-Speed Corner Flow'**
  String get feature_high_speed_flow;

  /// No description provided for @feature_high_stamina_required.
  ///
  /// In en, this message translates to:
  /// **'High Driver Stamina Required'**
  String get feature_high_stamina_required;

  /// No description provided for @feature_high_wind_sensitivity.
  ///
  /// In en, this message translates to:
  /// **'Extreme Crosswind Sensitivity'**
  String get feature_high_wind_sensitivity;

  /// No description provided for @feature_hotel_underpass.
  ///
  /// In en, this message translates to:
  /// **'Unique Yas Hotel Underpass'**
  String get feature_hotel_underpass;

  /// No description provided for @feature_iconic_tunnel.
  ///
  /// In en, this message translates to:
  /// **'High-Speed Harbor Tunnel'**
  String get feature_iconic_tunnel;

  /// No description provided for @feature_legendary_esses.
  ///
  /// In en, this message translates to:
  /// **'Legendary \'\'S\'\' Curves'**
  String get feature_legendary_esses;

  /// No description provided for @feature_long_back_straight.
  ///
  /// In en, this message translates to:
  /// **'Extremely Long Back Straight'**
  String get feature_long_back_straight;

  /// No description provided for @feature_long_main_straight.
  ///
  /// In en, this message translates to:
  /// **'Long Drag to Turn 1'**
  String get feature_long_main_straight;

  /// No description provided for @feature_longest_run_to_t1.
  ///
  /// In en, this message translates to:
  /// **'Longest Run from Start to Turn 1'**
  String get feature_longest_run_to_t1;

  /// No description provided for @feature_longest_straight.
  ///
  /// In en, this message translates to:
  /// **'Flat-Out 2.2km Full Throttle Section'**
  String get feature_longest_straight;

  /// No description provided for @feature_longest_track.
  ///
  /// In en, this message translates to:
  /// **'Longest Track on the Calendar'**
  String get feature_longest_track;

  /// No description provided for @feature_low_grip_asphalt.
  ///
  /// In en, this message translates to:
  /// **'Low-Grip Semi-Permanent Surface'**
  String get feature_low_grip_asphalt;

  /// No description provided for @feature_maggotts_becketts_flow.
  ///
  /// In en, this message translates to:
  /// **'Maggotts-Becketts-Chapel Flow'**
  String get feature_maggotts_becketts_flow;

  /// No description provided for @feature_micro_climates.
  ///
  /// In en, this message translates to:
  /// **'Multiple Track Micro-Climates'**
  String get feature_micro_climates;

  /// No description provided for @feature_monaco_without_walls.
  ///
  /// In en, this message translates to:
  /// **'Technical \'\'Monaco-Style\'\' Flow'**
  String get feature_monaco_without_walls;

  /// No description provided for @feature_multi_surface_grip.
  ///
  /// In en, this message translates to:
  /// **'Varying Multi-Surface Grip'**
  String get feature_multi_surface_grip;

  /// No description provided for @feature_multiple_overtaking_lines.
  ///
  /// In en, this message translates to:
  /// **'Wide Track with Multiple Lines'**
  String get feature_multiple_overtaking_lines;

  /// No description provided for @feature_narrow_passing_zones.
  ///
  /// In en, this message translates to:
  /// **'Narrow Overtaking Opportunities'**
  String get feature_narrow_passing_zones;

  /// No description provided for @feature_narrow_track_width.
  ///
  /// In en, this message translates to:
  /// **'Narrow Historic Track Width'**
  String get feature_narrow_track_width;

  /// No description provided for @feature_new_straight_section.
  ///
  /// In en, this message translates to:
  /// **'Revised High-Speed Sector 3'**
  String get feature_new_straight_section;

  /// No description provided for @feature_old_school_track.
  ///
  /// In en, this message translates to:
  /// **'Classic \'\'Old-School\'\' Layout'**
  String get feature_old_school_track;

  /// No description provided for @feature_physical_exhaustion.
  ///
  /// In en, this message translates to:
  /// **'Extreme Driver Physical Exhaustion'**
  String get feature_physical_exhaustion;

  /// No description provided for @feature_physical_heat_stress.
  ///
  /// In en, this message translates to:
  /// **'Severe Physical Heat Stress'**
  String get feature_physical_heat_stress;

  /// No description provided for @feature_precision_steering.
  ///
  /// In en, this message translates to:
  /// **'Millimeter-Precision Steering'**
  String get feature_precision_steering;

  /// No description provided for @feature_rollercoaster_ride.
  ///
  /// In en, this message translates to:
  /// **'High-Speed \'\'Rollercoaster\'\' Feel'**
  String get feature_rollercoaster_ride;

  /// No description provided for @feature_sand_on_track.
  ///
  /// In en, this message translates to:
  /// **'Risk of Wind-Blown Sand'**
  String get feature_sand_on_track;

  /// No description provided for @feature_sand_wind_impact.
  ///
  /// In en, this message translates to:
  /// **'Desert Sand and Wind Buffeting'**
  String get feature_sand_wind_impact;

  /// No description provided for @feature_sea_breeze_sand.
  ///
  /// In en, this message translates to:
  /// **'Onshore Sea Breeze & Sand Risk'**
  String get feature_sea_breeze_sand;

  /// No description provided for @feature_senna_s_curves.
  ///
  /// In en, this message translates to:
  /// **'Legendary \'\'Senna S\'\' Complex'**
  String get feature_senna_s_curves;

  /// No description provided for @feature_short_lap_time.
  ///
  /// In en, this message translates to:
  /// **'Extremely Short Lap Duration'**
  String get feature_short_lap_time;

  /// No description provided for @feature_snail_corner_t1.
  ///
  /// In en, this message translates to:
  /// **'Technical \'\'Snail\'\' Turn 1'**
  String get feature_snail_corner_t1;

  /// No description provided for @feature_stadium_atmosphere.
  ///
  /// In en, this message translates to:
  /// **'Iconic Stadium Atmosphere'**
  String get feature_stadium_atmosphere;

  /// No description provided for @feature_stadium_section.
  ///
  /// In en, this message translates to:
  /// **'Iconic Foro Sol Stadium Section'**
  String get feature_stadium_section;

  /// No description provided for @feature_steep_uphill_braking.
  ///
  /// In en, this message translates to:
  /// **'Aggressive Uphill Braking Zones'**
  String get feature_steep_uphill_braking;

  /// No description provided for @feature_steep_uphill_t1.
  ///
  /// In en, this message translates to:
  /// **'Extreme Uphill Run to Turn 1'**
  String get feature_steep_uphill_t1;

  /// No description provided for @feature_street_circuit.
  ///
  /// In en, this message translates to:
  /// **'Temporary Street Surface'**
  String get feature_street_circuit;

  /// No description provided for @feature_straight_mode_5_zones.
  ///
  /// In en, this message translates to:
  /// **'5 Straight Mode Zones'**
  String get feature_straight_mode_5_zones;

  /// No description provided for @feature_sunset_to_night.
  ///
  /// In en, this message translates to:
  /// **'Day-to-Night Sunset Transition'**
  String get feature_sunset_to_night;

  /// No description provided for @feature_sweeping_corners.
  ///
  /// In en, this message translates to:
  /// **'High-Speed Sweeping Corners'**
  String get feature_sweeping_corners;

  /// No description provided for @feature_technical_chicane.
  ///
  /// In en, this message translates to:
  /// **'Precision Chicane Placement'**
  String get feature_technical_chicane;

  /// No description provided for @feature_technical_final_sector.
  ///
  /// In en, this message translates to:
  /// **'Tight & Technical Final Sector'**
  String get feature_technical_final_sector;

  /// No description provided for @feature_technical_flow.
  ///
  /// In en, this message translates to:
  /// **'Continuous Rhythmic Corner Flow'**
  String get feature_technical_flow;

  /// No description provided for @feature_technical_sector_2.
  ///
  /// In en, this message translates to:
  /// **'Technical Mid-Sector Flow'**
  String get feature_technical_sector_2;

  /// No description provided for @feature_temple_of_speed.
  ///
  /// In en, this message translates to:
  /// **'The Iconic \'\'Temple of Speed\'\''**
  String get feature_temple_of_speed;

  /// No description provided for @feature_the_strip_straight.
  ///
  /// In en, this message translates to:
  /// **'The Massive Las Vegas Strip Straight'**
  String get feature_the_strip_straight;

  /// No description provided for @feature_thin_air_cooling.
  ///
  /// In en, this message translates to:
  /// **'Thin Air Cooling Challenges'**
  String get feature_thin_air_cooling;

  /// No description provided for @feature_tight_hairpin.
  ///
  /// In en, this message translates to:
  /// **'World\'\'s Tightest Hairpin'**
  String get feature_tight_hairpin;

  /// No description provided for @feature_tire_killer.
  ///
  /// In en, this message translates to:
  /// **'High Lateral Tire Load'**
  String get feature_tire_killer;

  /// No description provided for @feature_track_limits_chaos.
  ///
  /// In en, this message translates to:
  /// **'High Risk of Track Limit Penalties'**
  String get feature_track_limits_chaos;

  /// No description provided for @feature_traction_limited.
  ///
  /// In en, this message translates to:
  /// **'Traction-Limited Exits'**
  String get feature_traction_limited;

  /// No description provided for @feature_unpredictable_weather.
  ///
  /// In en, this message translates to:
  /// **'Highly Unpredictable Weather'**
  String get feature_unpredictable_weather;

  /// No description provided for @feature_unpredictable_weather_interlagos.
  ///
  /// In en, this message translates to:
  /// **'Sudden Interlagos Micro-Storms'**
  String get feature_unpredictable_weather_interlagos;

  /// No description provided for @feature_uphill_start_finish.
  ///
  /// In en, this message translates to:
  /// **'Uphill Steep Start-Finish Straight'**
  String get feature_uphill_start_finish;

  /// No description provided for @feature_variable_grip.
  ///
  /// In en, this message translates to:
  /// **'Variable Grip Levels'**
  String get feature_variable_grip;

  /// No description provided for @feature_wall_of_champions.
  ///
  /// In en, this message translates to:
  /// **'Dangerous \'\'Wall of Champions\'\''**
  String get feature_wall_of_champions;

  /// No description provided for @feature_zero_margin_error.
  ///
  /// In en, this message translates to:
  /// **'Zero Margin for Error'**
  String get feature_zero_margin_error;

  /// No description provided for @feature_zero_overtaking_space.
  ///
  /// In en, this message translates to:
  /// **'Extremely Limited Passing Space'**
  String get feature_zero_overtaking_space;

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

  /// No description provided for @overtaking_difficulty_l10n.
  ///
  /// In en, this message translates to:
  /// **'Overtaking Difficulty'**
  String get overtaking_difficulty_l10n;

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

  /// No description provided for @race_control_filter_penalties.
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get race_control_filter_penalties;

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

  /// No description provided for @race_control_track_limits_strip.
  ///
  /// In en, this message translates to:
  /// **'Track limits — deleted laps'**
  String get race_control_track_limits_strip;

  /// No description provided for @race_control_steward_storyline.
  ///
  /// In en, this message translates to:
  /// **'Steward storyline'**
  String get race_control_steward_storyline;

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

  /// No description provided for @recommended_strategy_l10n.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get recommended_strategy_l10n;

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

  /// No description provided for @sun_0_deg_night_race.
  ///
  /// In en, this message translates to:
  /// **'Night Conditions (Artificial Light)'**
  String get sun_0_deg_night_race;

  /// No description provided for @sun_5_deg_twilight.
  ///
  /// In en, this message translates to:
  /// **'Twilight (Floodlights Active)'**
  String get sun_5_deg_twilight;

  /// No description provided for @sun_8_deg_horizon_dip.
  ///
  /// In en, this message translates to:
  /// **'Near Horizon (Extreme Glare)'**
  String get sun_8_deg_horizon_dip;

  /// No description provided for @sun_10_deg_harbor_reflection.
  ///
  /// In en, this message translates to:
  /// **'Very Low Sun (Water Reflection)'**
  String get sun_10_deg_harbor_reflection;

  /// No description provided for @sun_12_deg_mountain_occlusion.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (Mountain Shadows)'**
  String get sun_12_deg_mountain_occlusion;

  /// No description provided for @sun_14_deg_stadium_shadows.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (Grandstand Shadows)'**
  String get sun_14_deg_stadium_shadows;

  /// No description provided for @sun_15_deg_sunset_blind.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (High Blindness Risk)'**
  String get sun_15_deg_sunset_blind;

  /// No description provided for @sun_18_deg_paddock_glare.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (Building Reflections)'**
  String get sun_18_deg_paddock_glare;

  /// No description provided for @sun_20_deg_desert_haze.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (Dust & Haze Glare)'**
  String get sun_20_deg_desert_haze;

  /// No description provided for @sun_22_deg_coastal_mist.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (Sea Mist Diffusion)'**
  String get sun_22_deg_coastal_mist;

  /// No description provided for @sun_25_deg_morning_glow.
  ///
  /// In en, this message translates to:
  /// **'Early Morning Sun'**
  String get sun_25_deg_morning_glow;

  /// No description provided for @sun_28_deg_dunes_glare.
  ///
  /// In en, this message translates to:
  /// **'Low Sun (Dunes Glare)'**
  String get sun_28_deg_dunes_glare;

  /// No description provided for @sun_30_deg_low_winter_sun.
  ///
  /// In en, this message translates to:
  /// **'Low Winter Sun'**
  String get sun_30_deg_low_winter_sun;

  /// No description provided for @sun_32_deg_urban_canyon.
  ///
  /// In en, this message translates to:
  /// **'Medium Sun (Skyline Shadows)'**
  String get sun_32_deg_urban_canyon;

  /// No description provided for @sun_35_deg_forest_shadows.
  ///
  /// In en, this message translates to:
  /// **'Medium Sun (Intermittent Shadows)'**
  String get sun_35_deg_forest_shadows;

  /// No description provided for @sun_40_deg_cloudy_diffuse.
  ///
  /// In en, this message translates to:
  /// **'Diffuse Light (Overcast)'**
  String get sun_40_deg_cloudy_diffuse;

  /// No description provided for @sun_45_deg_mid_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Mid-Day Sun'**
  String get sun_45_deg_mid_afternoon;

  /// No description provided for @sun_50_deg_clear_sky.
  ///
  /// In en, this message translates to:
  /// **'Clear Afternoon Sun'**
  String get sun_50_deg_clear_sky;

  /// No description provided for @sun_55_deg_bright_oval.
  ///
  /// In en, this message translates to:
  /// **'High Brightness (Open Area)'**
  String get sun_55_deg_bright_oval;

  /// No description provided for @sun_60_deg_standard_day.
  ///
  /// In en, this message translates to:
  /// **'Standard Daylight'**
  String get sun_60_deg_standard_day;

  /// No description provided for @sun_65_deg_high_noon.
  ///
  /// In en, this message translates to:
  /// **'High Sun (Noon)'**
  String get sun_65_deg_high_noon;

  /// No description provided for @sun_70_deg_equatorial_high.
  ///
  /// In en, this message translates to:
  /// **'High Intensity Sun'**
  String get sun_70_deg_equatorial_high;

  /// No description provided for @sun_75_deg_tropical_peak.
  ///
  /// In en, this message translates to:
  /// **'Extreme Tropical Sun'**
  String get sun_75_deg_tropical_peak;

  /// No description provided for @sun_85_deg_zenith.
  ///
  /// In en, this message translates to:
  /// **'Overhead Sun (No Shadows)'**
  String get sun_85_deg_zenith;

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

  /// No description provided for @type_hybrid_street.
  ///
  /// In en, this message translates to:
  /// **'Hybrid Street Circuit'**
  String get type_hybrid_street;

  /// No description provided for @type_permanent_circuit.
  ///
  /// In en, this message translates to:
  /// **'Permanent Racing Circuit'**
  String get type_permanent_circuit;

  /// No description provided for @type_street_circuit.
  ///
  /// In en, this message translates to:
  /// **'Street Circuit'**
  String get type_street_circuit;

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

  /// No description provided for @weekend_hub_no_results_yet.
  ///
  /// In en, this message translates to:
  /// **'Results for this session are not yet available or have not been synced.'**
  String get weekend_hub_no_results_yet;

  /// No description provided for @weekend_hub_session_insights.
  ///
  /// In en, this message translates to:
  /// **'Session Insights'**
  String get weekend_hub_session_insights;

  /// No description provided for @weekend_hub_fastest_sectors.
  ///
  /// In en, this message translates to:
  /// **'Fastest Sectors'**
  String get weekend_hub_fastest_sectors;

  /// No description provided for @weekend_hub_sector_1_abbr.
  ///
  /// In en, this message translates to:
  /// **'S1'**
  String get weekend_hub_sector_1_abbr;

  /// No description provided for @weekend_hub_sector_2_abbr.
  ///
  /// In en, this message translates to:
  /// **'S2'**
  String get weekend_hub_sector_2_abbr;

  /// No description provided for @weekend_hub_sector_3_abbr.
  ///
  /// In en, this message translates to:
  /// **'S3'**
  String get weekend_hub_sector_3_abbr;

  /// No description provided for @weekend_hub_tyre_compound.
  ///
  /// In en, this message translates to:
  /// **'Tyre Compound'**
  String get weekend_hub_tyre_compound;

  /// No description provided for @weekend_hub_insights_sectors_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Sector data needs a live OpenF1 sync for this race.'**
  String get weekend_hub_insights_sectors_unavailable;

  /// No description provided for @weekend_hub_penalties_filter_empty.
  ///
  /// In en, this message translates to:
  /// **'No penalty or investigation messages for this session.'**
  String get weekend_hub_penalties_filter_empty;

  /// No description provided for @weekend_hub_spot_placeholder_title.
  ///
  /// In en, this message translates to:
  /// **'Live radar & DRS'**
  String get weekend_hub_spot_placeholder_title;

  /// No description provided for @weekend_hub_spot_placeholder_body.
  ///
  /// In en, this message translates to:
  /// **'Weather radar, track rain radar, and a DRS zone overview will appear here in a future update.'**
  String get weekend_hub_spot_placeholder_body;

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

  /// No description provided for @circuit_go_home.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get circuit_go_home;

  /// No description provided for @circuit_not_found_message.
  ///
  /// In en, this message translates to:
  /// **'No circuit data is available for this address. Check the link or pick a circuit from the calendar.'**
  String get circuit_not_found_message;

  /// No description provided for @circuit_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'Circuit not found'**
  String get circuit_not_found_title;

  /// No description provided for @circuit_open_in_maps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get circuit_open_in_maps;

  /// No description provided for @circuit_stat_full_throttle.
  ///
  /// In en, this message translates to:
  /// **'Full throttle'**
  String get circuit_stat_full_throttle;

  /// No description provided for @circuit_weekend_hub_go.
  ///
  /// In en, this message translates to:
  /// **'Go to {venue} Hub'**
  String circuit_weekend_hub_go(String venue);

  /// No description provided for @circuit_weekend_hub_no_data_tooltip.
  ///
  /// In en, this message translates to:
  /// **'No session data available yet.'**
  String get circuit_weekend_hub_no_data_tooltip;

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

  /// No description provided for @news_feed_section_empty.
  ///
  /// In en, this message translates to:
  /// **'No articles from this feed.'**
  String get news_feed_section_empty;

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

  /// No description provided for @news_settings_drag_to_reorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to change feed order'**
  String get news_settings_drag_to_reorder;

  /// No description provided for @orbit_nav.
  ///
  /// In en, this message translates to:
  /// **'Orbit'**
  String get orbit_nav;

  /// No description provided for @orbit_circuit_list.
  ///
  /// In en, this message translates to:
  /// **'Circuits'**
  String get orbit_circuit_list;

  /// No description provided for @orbit_load_error.
  ///
  /// In en, this message translates to:
  /// **'Could not load map data: {error}'**
  String orbit_load_error(String error);

  /// No description provided for @orbit_track_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get orbit_track_standard;

  /// No description provided for @orbit_track_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get orbit_track_details;

  /// No description provided for @orbit_track_technical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get orbit_track_technical;

  /// No description provided for @orbit_elevation_profile.
  ///
  /// In en, this message translates to:
  /// **'Elevation profile'**
  String get orbit_elevation_profile;

  /// No description provided for @orbit_stat_lap_distance.
  ///
  /// In en, this message translates to:
  /// **'Lap distance'**
  String get orbit_stat_lap_distance;

  /// No description provided for @orbit_stat_max_elevation.
  ///
  /// In en, this message translates to:
  /// **'Max elevation change'**
  String get orbit_stat_max_elevation;

  /// No description provided for @orbit_stat_banked_turns.
  ///
  /// In en, this message translates to:
  /// **'Banked turns'**
  String get orbit_stat_banked_turns;

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

  /// No description provided for @circuit_map_expand.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get circuit_map_expand;

  /// No description provided for @circuit_map_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse map'**
  String get circuit_map_collapse;

  /// No description provided for @circuit_map_zoom_in.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get circuit_map_zoom_in;

  /// No description provided for @circuit_map_zoom_out.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get circuit_map_zoom_out;

  /// No description provided for @recent_form_trend_title.
  ///
  /// In en, this message translates to:
  /// **'Recent Form Trend'**
  String get recent_form_trend_title;

  /// No description provided for @recent_form_last_5_points.
  ///
  /// In en, this message translates to:
  /// **'Last 5 Points'**
  String get recent_form_last_5_points;

  /// No description provided for @recent_form_avg_finish.
  ///
  /// In en, this message translates to:
  /// **'Avg. Finish'**
  String get recent_form_avg_finish;

  /// No description provided for @recent_form_total_season_points.
  ///
  /// In en, this message translates to:
  /// **'Total Season Points'**
  String get recent_form_total_season_points;

  /// No description provided for @recent_form_avg_race_finish.
  ///
  /// In en, this message translates to:
  /// **'Avg. Race Finish'**
  String get recent_form_avg_race_finish;

  /// No description provided for @recent_form_total_podiums.
  ///
  /// In en, this message translates to:
  /// **'Total Podiums (Race + Sprint)'**
  String get recent_form_total_podiums;

  /// No description provided for @recent_form_expand_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Open full season view'**
  String get recent_form_expand_tooltip;

  /// No description provided for @recent_form_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get recent_form_close;

  /// No description provided for @recent_form_no_data.
  ///
  /// In en, this message translates to:
  /// **'No form data for this season yet.'**
  String get recent_form_no_data;
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
