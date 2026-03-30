// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accident => 'Accident Chance';

  @override
  String get age => 'Age';

  @override
  String get ai_avg_gap => 'Avg. Gap';

  @override
  String get ai_chip_compare_max_lando => 'Compare Max vs Lando';

  @override
  String get ai_chip_fetch_latest_results => 'Fetch latest results';

  @override
  String get ai_chip_show_driver_standings => 'Show driver standings';

  @override
  String get ai_chip_show_form_piastri => 'Show form Piastri';

  @override
  String get ai_chip_show_latest_penalties => 'Show latest penalties';

  @override
  String get ai_chip_show_next_weekend => 'Show next weekend';

  @override
  String get ai_coach_title => 'Coach\'\'s Corner';

  @override
  String get ai_compare_no_match => 'I could not find two valid drivers or teams for this comparison.';

  @override
  String get ai_compare_parse_error => 'I could not read the comparison. Use: name1 vs name2';

  @override
  String ai_crash(String error) {
    return 'The assistant ran into: $error';
  }

  @override
  String ai_driver_compare_ready(String left, String right) {
    return 'Driver comparison is ready for $left and $right.';
  }

  @override
  String ai_driver_profile_ready(String driver) {
    return 'Driver profile ready for $driver.';
  }

  @override
  String ai_driver_standings_summary(String year, String summary) {
    return 'Driver standings $year: $summary';
  }

  @override
  String ai_drivers_chart_ready(String year) {
    return 'The drivers chart is ready for $year.';
  }

  @override
  String get ai_example_prompt => 'Try for example: \"Fetch latest results\", \"Show next weekend\", \"Show driver standings\", \"Open driver Charles Leclerc\" or \"Show latest penalties\".';

  @override
  String ai_form_no_cache(String driver) {
    return 'No cached recent races for $driver yet.';
  }

  @override
  String get ai_form_no_driver => 'I could not find a driver for the form analysis.';

  @override
  String ai_form_summary(String driver, String summary) {
    return 'Recent form for $driver: $summary';
  }

  @override
  String ai_latest_penalties_none(String race) {
    return 'No penalties found for $race.';
  }

  @override
  String ai_latest_penalties_summary(String race, String count, String details) {
    return 'Latest penalties at $race: $count. $details';
  }

  @override
  String ai_latest_race_control_none(String race) {
    return 'No Race Control messages found for $race.';
  }

  @override
  String ai_latest_race_control_summary(String race, String count, String message) {
    return 'Race Control at $race: $count messages. Latest update: $message';
  }

  @override
  String ai_latest_results_podium(String podium) {
    return 'Latest results refreshed. Podium: $podium';
  }

  @override
  String get ai_latest_results_refreshed => 'The latest results were refreshed.';

  @override
  String ai_next_weekend(String race, String date) {
    return 'Next weekend: $race on $date.';
  }

  @override
  String ai_next_weekend_weather(String race, String temp, String rain, String wind) {
    return 'Weather for $race: ${temp}C, $rain% rain, $wind km/h wind.';
  }

  @override
  String get ai_no_completed_race => 'No completed race has been found yet.';

  @override
  String get ai_open_driver_compare => 'Open driver compare';

  @override
  String get ai_open_driver_profile => 'Open driver profile';

  @override
  String get ai_open_driver_standings => 'Open driver standings';

  @override
  String get ai_open_drivers_chart => 'Open drivers chart';

  @override
  String get ai_open_latest_results => 'Open latest results';

  @override
  String get ai_open_team_compare => 'Open team compare';

  @override
  String get ai_open_team_profile => 'Open team profile';

  @override
  String get ai_open_team_standings => 'Open team standings';

  @override
  String get ai_open_weekend_hub => 'Open weekend hub';

  @override
  String get ai_qualifying_duel => 'Qualifying Duel';

  @override
  String get ai_race_engineer => 'AI Race Engineer';

  @override
  String get ai_rain_chance_label => 'Rain Chance';

  @override
  String get ai_rain_chance_slider => 'Rain Chance';

  @override
  String get ai_sentiment_generic_neutral => 'Team Vibe: Mixed signals from team radios.';

  @override
  String get ai_sentiment_generic_positive => 'Team Vibe: Positive energy across the paddock.';

  @override
  String get ai_sentiment_label => 'Team Vibe';

  @override
  String get ai_sentiment_mercedes_positive => 'Team Vibe: Morale rises at Mercedes after Hamilton grid penalty.';

  @override
  String get ai_strategist_tap_hint => 'Tap to ask questions...';

  @override
  String get ai_strategist_title => 'AI Strategist';

  @override
  String get ai_prefs_section_title => 'AI Strategist';

  @override
  String get ai_prefs_section_subtitle => 'Customize the AI Strategist card on the home screen.';

  @override
  String get ai_prefs_disable_card => 'Disable AI Strategist card';

  @override
  String get ai_prefs_hide_teambattle => 'Hide Teammate Battle';

  @override
  String get ai_prefs_hide_teambattle_hint => 'When the card is visible, hide the teammate comparison.';

  @override
  String get ai_prefs_hide_coach_corner => 'Hide Coach\'\'s Corner';

  @override
  String get ai_prefs_hide_coach_corner_hint => 'When the card is visible, hide coaching tips.';

  @override
  String get ai_prefs_hide_team_vibe => 'Hide Team Vibe';

  @override
  String get ai_prefs_hide_team_vibe_hint => 'When the card is visible, hide sentiment.';

  @override
  String get ai_supported_commands => 'Supported commands: Fetch latest results, Show next weekend, Compare name1 vs name2, Show form [driver], Show driver standings, Show team standings, Open driver [name], Open team [name], Show drivers chart, Show latest penalties, Show latest race control.';

  @override
  String ai_team_compare_ready(String left, String right) {
    return 'Team comparison is ready for $left and $right.';
  }

  @override
  String ai_team_profile_ready(String team) {
    return 'Team profile ready for $team.';
  }

  @override
  String ai_team_standings_summary(String year, String summary) {
    return 'Constructor standings $year: $summary';
  }

  @override
  String get ai_teammate_battle => 'Teammate Battle';

  @override
  String ai_teammate_insight(String driver, String teammate) {
    return '$driver is traditionally stronger on this circuit in qualifying, while $teammate excels in tyre preservation.';
  }

  @override
  String get ai_type_command => 'Type a command...';

  @override
  String ai_weather_effect(String pct, String driver, String pct2) {
    return 'At $pct% rain: Podium chance for $driver rises $pct2% due to superior wet pace.';
  }

  @override
  String ai_weather_effect_at(String pct, String insight) {
    return 'At $pct% rain: $insight';
  }

  @override
  String get ai_weather_insight_alonso => 'Podium chance for Alonso rises 15% due to superior wet pace.';

  @override
  String get ai_weather_insight_generic => 'Wet conditions favor strong wet-weather drivers.';

  @override
  String get air_temperature => 'Air temperature';

  @override
  String get all_scopes => 'All scopes';

  @override
  String get app_title => 'F1 Hub';

  @override
  String get average_speed => 'Average Speed';

  @override
  String get avg_finish => 'Avg finish';

  @override
  String get avg_finish_l5 => 'Avg finish (L5)';

  @override
  String get avg_gforce => 'Avg G-Force';

  @override
  String get avg_lap => 'Average Lap';

  @override
  String get best_combination => 'Best Combination';

  @override
  String get best_lap => 'Best lap';

  @override
  String get best_tyre_combination => 'Best Combination';

  @override
  String get cfield_air_pressure_hpa => 'Air pressure';

  @override
  String get cfield_asphalt_grip_score => 'Asphalt grip score';

  @override
  String get cfield_avg_g_force => 'Average G-force';

  @override
  String get cfield_avg_time_2024_2025 => 'Average lap time (2024–25)';

  @override
  String get cfield_brake_cooling_requirement_score => 'Brake cooling requirement';

  @override
  String get cfield_circuit_director => 'Circuit director';

  @override
  String get cfield_circuit_owner => 'Circuit owner';

  @override
  String get cfield_contract_until => 'Contract until';

  @override
  String get cfield_deployment_focus => 'Deployment focus';

  @override
  String get cfield_direction => 'Direction';

  @override
  String get cfield_distance_to_t1 => 'Distance to Turn 1';

  @override
  String get cfield_electrical_ratio => 'Electrical ratio';

  @override
  String get cfield_energy_flow_strategy => 'Energy flow strategy';

  @override
  String get cfield_engine_derating_risk => 'Engine derating risk';

  @override
  String get cfield_era_delta => 'Era delta';

  @override
  String get cfield_est_time_2026 => 'Estimated lap time (2026)';

  @override
  String get cfield_elevation_sea_level => 'Elevation (sea level)';

  @override
  String get cfield_harvest_difficulty => 'Harvest difficulty';

  @override
  String get cfield_harvesting_zones => 'Harvesting zones';

  @override
  String get cfield_latitude => 'Latitude';

  @override
  String get cfield_local_time_zone => 'Local time zone';

  @override
  String get cfield_longitude => 'Longitude';

  @override
  String get cfield_lap_record_detail => 'Lap record';

  @override
  String get cfield_laps => 'Laps';

  @override
  String get cfield_lateral_stress_score => 'Lateral stress score';

  @override
  String get cfield_length => 'Length';

  @override
  String get cfield_manual_override_energy_cost => 'Manual override energy cost';

  @override
  String get cfield_manual_override_points => 'Manual override points';

  @override
  String get cfield_max_elevation_change => 'Max elevation change';

  @override
  String get cfield_max_g_force => 'Max G-force';

  @override
  String get cfield_override_impact_score => 'Override impact score';

  @override
  String get cfield_on_calendar_since => 'On calendar since';

  @override
  String get cfield_overtaking_delta => 'Overtaking delta';

  @override
  String get cfield_pit_exit_delta => 'Pit exit delta';

  @override
  String get cfield_pitstop_record_detail => 'Pit stop record';

  @override
  String get cfield_race_day_capacity => 'Race day capacity';

  @override
  String get cfield_rain_chance => 'Rain chance';

  @override
  String get cfield_recovery_points => 'Recovery points';

  @override
  String get cfield_red_flag_prob => 'Red flag probability';

  @override
  String get cfield_s1 => 'Sector 1';

  @override
  String get cfield_s2 => 'Sector 2';

  @override
  String get cfield_s3 => 'Sector 3';

  @override
  String get cfield_safety_car_prob => 'Safety Car probability';

  @override
  String get cfield_safety_car_window_laps => 'Safety Car window (laps)';

  @override
  String get cfield_straight_mode_zones => 'Straight Mode zones';

  @override
  String get cfield_sun_angle_start => 'Sun angle at start';

  @override
  String get cfield_t1_accident_risk => 'Turn 1 accident risk';

  @override
  String get cfield_temperature_c => 'Temperature';

  @override
  String get cfield_top_speed => 'Top speed';

  @override
  String get cfield_top_speed_delta => 'Top speed delta';

  @override
  String get cfield_track_evolution => 'Track evolution';

  @override
  String get cfield_track_type => 'Track type';

  @override
  String get cfield_tyre_physics => 'Tyre physics';

  @override
  String get cfield_tyre_working_window_c => 'Tyre working window';

  @override
  String get cfield_undercut_potential_score => 'Undercut potential';

  @override
  String get cfield_utc_offset => 'UTC offset';

  @override
  String get cfield_vsc_prob => 'VSC probability';

  @override
  String get cfield_wind_sensitivity_sector => 'Wind sensitivity (sector)';

  @override
  String get cfield_x_mode_usage => 'X mode usage';

  @override
  String get cfield_z_mode_activation_delay => 'Z mode activation delay';

  @override
  String get cfield_z_mode_usage => 'Z mode usage';

  @override
  String get cfield_zone_name => 'Time zone name';

  @override
  String get birth_place => 'Birthplace';

  @override
  String get cache_cleared => 'Cache cleared successfully!';

  @override
  String car_label(String number) {
    return 'Car $number';
  }

  @override
  String get career_stats => 'Career Stats';

  @override
  String get cc_wins => 'Constructors Titles';

  @override
  String get championship_progression => 'Championship progression';

  @override
  String get championships => 'Championships';

  @override
  String get championship_leader_pill => 'Championship leader';

  @override
  String get calendar_prefs_section_title => 'Calendar';

  @override
  String get calendar_prefs_section_subtitle => 'Customize the circuits calendar.';

  @override
  String get calendar_prefs_hide_cancelled => 'Hide placeholder races';

  @override
  String get calendar_prefs_hide_cancelled_hint => 'Hide cancelled or placeholder races not on the real calendar.';

  @override
  String get cat_ambient_stats => 'Ambient Conditions';

  @override
  String get cat_history_comparison => 'Era Comparison';

  @override
  String get cat_risks_stats => 'Performance & Risk';

  @override
  String get cat_tech_2026 => '2026 Tech & Aero';

  @override
  String get cat_track_specs => 'Track Geometry';

  @override
  String get display_prefs_section_title => 'Display preferences';

  @override
  String get display_prefs_section_subtitle => 'Choose how the app looks and moves. When signed in, these sync to your account.';

  @override
  String get display_prefs_ui_mode => 'Interface style';

  @override
  String get display_prefs_mode_standard => 'Standard';

  @override
  String get display_prefs_mode_standard_hint => 'Glass blur and soft shadows.';

  @override
  String get display_prefs_mode_simple => 'Simple';

  @override
  String get display_prefs_mode_simple_hint => 'Flat surfaces and stronger contrast.';

  @override
  String get display_prefs_compact => 'Compact mode';

  @override
  String get display_prefs_compact_hint => 'Tighter spacing and smaller cards.';

  @override
  String get display_prefs_motion_reduced => 'Reduced motion';

  @override
  String get display_prefs_motion_reduced_hint => 'Less animation, blur, and theme transitions.';

  @override
  String get display_prefs_saving => 'Saving…';

  @override
  String get my_paddock_title => 'My Paddock';

  @override
  String get my_paddock_session_unknown => 'Live timing';

  @override
  String my_paddock_resume_subtitle(String session, String lap) {
    return 'Resume: $session — frame $lap';
  }

  @override
  String get my_paddock_favorite_drivers => 'Favorite drivers';

  @override
  String get my_paddock_favorite_teams => 'Favorite teams';

  @override
  String get my_paddock_last_race => 'Last race';

  @override
  String my_paddock_last_race_summary(String date, String podium) {
    return '$date · $podium';
  }

  @override
  String get my_paddock_points_suffix => 'pts';

  @override
  String get changelog => 'Changelog';

  @override
  String get characteristics => 'CIRCUIT CHARACTERISTICS';

  @override
  String get chart_no_data => 'No chart data is available for this season.';

  @override
  String get children => 'Children';

  @override
  String get circuit => 'Circuit';

  @override
  String get circuit_difficulty => 'Circuit Difficulty';

  @override
  String get circuit_difficulty_l10n => 'Circuit Difficulty';

  @override
  String get circuit_info => 'Circuit Info';

  @override
  String get circuit_layout => 'Circuit Layout';

  @override
  String get circuits => 'Circuits';

  @override
  String get city => 'City';

  @override
  String get clear_cache => 'Clear Cache';

  @override
  String get close => 'Close';

  @override
  String get compare => 'Compare';

  @override
  String get compare_overall => 'Overall';

  @override
  String get compare_season => 'By season';

  @override
  String get compare_season_unavailable => 'Season data is unavailable for this comparison.';

  @override
  String get compare_year => 'Season';

  @override
  String get contract_until => 'Contract until';

  @override
  String get country => 'Country';

  @override
  String get country_australia => 'Australia';

  @override
  String get country_austria => 'Austria';

  @override
  String get country_azerbaijan => 'Azerbaijan';

  @override
  String get country_bahrain => 'Bahrain';

  @override
  String get country_belgium => 'Belgium';

  @override
  String get country_brazil => 'Brazil';

  @override
  String get country_canada => 'Canada';

  @override
  String get country_china => 'China';

  @override
  String get country_hungary => 'Hungary';

  @override
  String get country_italy => 'Italy';

  @override
  String get country_japan => 'Japan';

  @override
  String get country_mexico => 'Mexico';

  @override
  String get country_monaco => 'Monaco';

  @override
  String get country_netherlands => 'Netherlands';

  @override
  String get country_qatar => 'Qatar';

  @override
  String get country_saudi_arabia => 'Saudi Arabia';

  @override
  String get country_singapore => 'Singapore';

  @override
  String get country_spain => 'Spain';

  @override
  String get country_uae => 'UAE';

  @override
  String get country_uk => 'UK';

  @override
  String get country_usa => 'USA';

  @override
  String get current_team => 'Current Team';

  @override
  String get date => 'Date';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get dc_wins => 'Drivers Titles';

  @override
  String get diff_easy => 'Very Easy';

  @override
  String get diff_extreme => 'Extreme';

  @override
  String get diff_hard => 'Hard';

  @override
  String get diff_high => 'High';

  @override
  String get diff_low => 'Low';

  @override
  String get diff_medium => 'Medium';

  @override
  String get dir_clockwise => 'Clockwise';

  @override
  String get dir_counter_clockwise => 'Counter-Clockwise';

  @override
  String get dir_figure_eight => 'Figure-Eight';

  @override
  String get distance_to_turn1 => 'Distance to Turn 1';

  @override
  String get dnf => 'Did Not Finish';

  @override
  String get dnf_percentage => 'DNF %';

  @override
  String get dnqs => 'Did Not Qualify';

  @override
  String get driver => 'Driver';

  @override
  String get driver_facts_title => 'Facts & Trivia';

  @override
  String get driver_history => 'History (Last 5 Years)';

  @override
  String get drivers => 'Drivers';

  @override
  String get drivers_chart => 'Drivers chart';

  @override
  String get dsqs => 'Disqualified';

  @override
  String get engine => 'Engine';

  @override
  String get engine_name => 'Engine Name';

  @override
  String get engine_supplier => 'Engine Supplier';

  @override
  String get experience => 'Experience';

  @override
  String get f1_debut => 'F1 Debut';

  @override
  String get fastest_lap => 'Fastest Lap';

  @override
  String get fastest_lap_rate => 'Fastest lap rate %';

  @override
  String get fastest_laps => 'Fastest Laps';

  @override
  String get fastest_pit => 'Fastest Pitstop';

  @override
  String get favorite_circuit => 'Favorite Circuit';

  @override
  String get favorite_driver => 'Favorite Driver';

  @override
  String get favorite_team => 'Favorite Team';

  @override
  String get feature_130r_high_speed => 'Iconic 130R High-Speed Left';

  @override
  String get feature_90_degree_corners => 'Sequential 90-Degree Street Turns';

  @override
  String get feature_abrasive_asphalt => 'Highly Abrasive Asphalt';

  @override
  String get feature_aggressive_kerbs => 'Aggressive Sausage Kerb Risk';

  @override
  String get feature_aero_efficiency_test => 'Ultimate Aero Efficiency Test';

  @override
  String get feature_banked_corners_t3_t14 => 'Unique Banked Corners (T3 & T14)';

  @override
  String get feature_battery_drain_kemmel => 'High Battery Drain (Kemmel Straight)';

  @override
  String get feature_blind_corners => 'Dangerous Blind Apexes';

  @override
  String get feature_bumpy_city_roads => 'Highly Irregular City Road Surface';

  @override
  String get feature_bumpy_surface => 'Bumpy Track Surface';

  @override
  String get feature_bumpy_surface_subsidence => 'Surface Bumps due to Subsidence';

  @override
  String get feature_castle_section_tight => 'Ultra-Tight Castle Section';

  @override
  String get feature_cold_tire_struggle => 'Difficulty Retaining Tire Heat';

  @override
  String get feature_curb_riding_chicane => 'Aggressive Chicane Curb Riding';

  @override
  String get feature_degner_curves => 'Precise Degner Curves';

  @override
  String get feature_dusty_surface => 'Initially Dusty Surface Conditions';

  @override
  String get feature_eau_rouge_raidillon => 'Legendary Eau Rouge-Raidillon';

  @override
  String get feature_esses_section_flow => 'High-Speed Rhythmic Esses';

  @override
  String get feature_extreme_altitude => 'Extreme Altitude (2,200m+)';

  @override
  String get feature_extreme_humidity => 'Oppressive Equatorial Humidity';

  @override
  String get feature_extreme_low_drag => 'Extreme Low-Drag Aero Setup';

  @override
  String get feature_fastest_street_track => 'Fastest Street Track on Calendar';

  @override
  String get feature_figure_eight_layout => 'Unique Figure-Eight Layout';

  @override
  String get feature_glittering_night_race => 'Glittering Night-Time Backdrop';

  @override
  String get feature_groundhog_risk => 'Local Wildlife (Groundhog) Risk';

  @override
  String get feature_heavy_braking => 'Severe Braking Demands';

  @override
  String get feature_heavy_braking_variante => 'Hard Braking into Chicanes';

  @override
  String get feature_heavy_braking_zones => 'Hard Braking into Chicanes';

  @override
  String get feature_heavy_traction_points => 'Critical Low-Speed Traction Zones';

  @override
  String get feature_high_altitude_cooling => 'High Altitude Power Unit Cooling';

  @override
  String get feature_high_altitude_impact => 'Significant Altitude Aero Impact';

  @override
  String get feature_high_downforce_focus => 'Maximum Downforce Priority';

  @override
  String get feature_high_front_tyre_wear => 'High Front Tyre Degradation';

  @override
  String get feature_high_humidity => 'High Ambient Humidity';

  @override
  String get feature_high_kerb_usage => 'Aggressive Kerb Riding';

  @override
  String get feature_high_lateral_load => 'Intense Lateral G-Force Loads';

  @override
  String get feature_high_speed_corners => 'Ultra High-Speed Cornering';

  @override
  String get feature_high_speed_flow => 'Continuous High-Speed Corner Flow';

  @override
  String get feature_high_stamina_required => 'High Driver Stamina Required';

  @override
  String get feature_high_wind_sensitivity => 'Extreme Crosswind Sensitivity';

  @override
  String get feature_hotel_underpass => 'Unique Yas Hotel Underpass';

  @override
  String get feature_iconic_tunnel => 'High-Speed Harbor Tunnel';

  @override
  String get feature_legendary_esses => 'Legendary \'\'S\'\' Curves';

  @override
  String get feature_long_back_straight => 'Extremely Long Back Straight';

  @override
  String get feature_long_main_straight => 'Long Drag to Turn 1';

  @override
  String get feature_longest_run_to_t1 => 'Longest Run from Start to Turn 1';

  @override
  String get feature_longest_straight => 'Flat-Out 2.2km Full Throttle Section';

  @override
  String get feature_longest_track => 'Longest Track on the Calendar';

  @override
  String get feature_low_grip_asphalt => 'Low-Grip Semi-Permanent Surface';

  @override
  String get feature_maggotts_becketts_flow => 'Maggotts-Becketts-Chapel Flow';

  @override
  String get feature_micro_climates => 'Multiple Track Micro-Climates';

  @override
  String get feature_monaco_without_walls => 'Technical \'\'Monaco-Style\'\' Flow';

  @override
  String get feature_multi_surface_grip => 'Varying Multi-Surface Grip';

  @override
  String get feature_multiple_overtaking_lines => 'Wide Track with Multiple Lines';

  @override
  String get feature_narrow_passing_zones => 'Narrow Overtaking Opportunities';

  @override
  String get feature_narrow_track_width => 'Narrow Historic Track Width';

  @override
  String get feature_new_straight_section => 'Revised High-Speed Sector 3';

  @override
  String get feature_old_school_track => 'Classic \'\'Old-School\'\' Layout';

  @override
  String get feature_physical_exhaustion => 'Extreme Driver Physical Exhaustion';

  @override
  String get feature_physical_heat_stress => 'Severe Physical Heat Stress';

  @override
  String get feature_precision_steering => 'Millimeter-Precision Steering';

  @override
  String get feature_rollercoaster_ride => 'High-Speed \'\'Rollercoaster\'\' Feel';

  @override
  String get feature_sand_on_track => 'Risk of Wind-Blown Sand';

  @override
  String get feature_sand_wind_impact => 'Desert Sand and Wind Buffeting';

  @override
  String get feature_sea_breeze_sand => 'Onshore Sea Breeze & Sand Risk';

  @override
  String get feature_senna_s_curves => 'Legendary \'\'Senna S\'\' Complex';

  @override
  String get feature_short_lap_time => 'Extremely Short Lap Duration';

  @override
  String get feature_snail_corner_t1 => 'Technical \'\'Snail\'\' Turn 1';

  @override
  String get feature_stadium_atmosphere => 'Iconic Stadium Atmosphere';

  @override
  String get feature_stadium_section => 'Iconic Foro Sol Stadium Section';

  @override
  String get feature_steep_uphill_braking => 'Aggressive Uphill Braking Zones';

  @override
  String get feature_steep_uphill_t1 => 'Extreme Uphill Run to Turn 1';

  @override
  String get feature_street_circuit => 'Temporary Street Surface';

  @override
  String get feature_straight_mode_5_zones => '5 Straight Mode Zones';

  @override
  String get feature_sunset_to_night => 'Day-to-Night Sunset Transition';

  @override
  String get feature_sweeping_corners => 'High-Speed Sweeping Corners';

  @override
  String get feature_technical_chicane => 'Precision Chicane Placement';

  @override
  String get feature_technical_final_sector => 'Tight & Technical Final Sector';

  @override
  String get feature_technical_flow => 'Continuous Rhythmic Corner Flow';

  @override
  String get feature_technical_sector_2 => 'Technical Mid-Sector Flow';

  @override
  String get feature_temple_of_speed => 'The Iconic \'\'Temple of Speed\'\'';

  @override
  String get feature_the_strip_straight => 'The Massive Las Vegas Strip Straight';

  @override
  String get feature_thin_air_cooling => 'Thin Air Cooling Challenges';

  @override
  String get feature_tight_hairpin => 'World\'\'s Tightest Hairpin';

  @override
  String get feature_tire_killer => 'High Lateral Tire Load';

  @override
  String get feature_track_limits_chaos => 'High Risk of Track Limit Penalties';

  @override
  String get feature_traction_limited => 'Traction-Limited Exits';

  @override
  String get feature_unpredictable_weather => 'Highly Unpredictable Weather';

  @override
  String get feature_unpredictable_weather_interlagos => 'Sudden Interlagos Micro-Storms';

  @override
  String get feature_uphill_start_finish => 'Uphill Steep Start-Finish Straight';

  @override
  String get feature_variable_grip => 'Variable Grip Levels';

  @override
  String get feature_wall_of_champions => 'Dangerous \'\'Wall of Champions\'\'';

  @override
  String get feature_zero_margin_error => 'Zero Margin for Error';

  @override
  String get feature_zero_overtaking_space => 'Extremely Limited Passing Space';

  @override
  String get finish => 'Finish';

  @override
  String get fp1 => 'Practice 1';

  @override
  String get fp2 => 'Practice 2';

  @override
  String get fp3 => 'Practice 3';

  @override
  String get front_row_starts => 'Front Row Starts';

  @override
  String get fullscreen_table => 'Fullscreen table';

  @override
  String get gap => 'Gap';

  @override
  String get general => 'General';

  @override
  String get gp_abu_dhabi_grand_prix => 'Abu Dhabi Grand Prix';

  @override
  String get gp_australian_grand_prix => 'Australian Grand Prix';

  @override
  String get gp_austrian_grand_prix => 'Austrian Grand Prix';

  @override
  String get gp_azerbaijan_grand_prix => 'Azerbaijan Grand Prix';

  @override
  String get gp_bahrain_grand_prix => 'Bahrain Grand Prix';

  @override
  String get gp_barcelona_grand_prix => 'Barcelona Grand Prix';

  @override
  String get gp_belgian_grand_prix => 'Belgian Grand Prix';

  @override
  String get gp_british_grand_prix => 'British Grand Prix';

  @override
  String get gp_canadian_grand_prix => 'Canadian Grand Prix';

  @override
  String get gp_chinese_grand_prix => 'Chinese Grand Prix';

  @override
  String get gp_dutch_grand_prix => 'Dutch Grand Prix';

  @override
  String get gp_hungarian_grand_prix => 'Hungarian Grand Prix';

  @override
  String get gp_italian_grand_prix => 'Italian Grand Prix';

  @override
  String get gp_japanese_grand_prix => 'Japanese Grand Prix';

  @override
  String get gp_las_vegas_grand_prix => 'Las Vegas Grand Prix';

  @override
  String get gp_mexico_city_grand_prix => 'Mexico City Grand Prix';

  @override
  String get gp_miami_grand_prix => 'Miami Grand Prix';

  @override
  String get gp_monaco_grand_prix => 'Monaco Grand Prix';

  @override
  String get gp_qatar_grand_prix => 'Qatar Grand Prix';

  @override
  String get gp_s_o_paulo_grand_prix => 'São Paulo Grand Prix';

  @override
  String get gp_saudi_arabian_grand_prix => 'Saudi Arabian Grand Prix';

  @override
  String get gp_singapore_grand_prix => 'Singapore Grand Prix';

  @override
  String get gp_spanish_grand_prix => 'Spanish Grand Prix';

  @override
  String get gp_united_states_grand_prix => 'United States Grand Prix';

  @override
  String get hard_tire => 'Hard';

  @override
  String get hat_tricks => 'Hat Tricks';

  @override
  String get headquarters => 'Headquarters';

  @override
  String get height => 'Height';

  @override
  String get help_and_ideas => 'Help & ideas';

  @override
  String get hide_all => 'None';

  @override
  String get highest_finish => 'Highest Finish';

  @override
  String get highest_grid => 'Highest Grid Position';

  @override
  String get hours => 'hours';

  @override
  String get humidity => 'Humidity';

  @override
  String get language => 'Language';

  @override
  String get language_chooser => 'English';

  @override
  String get language_selector => 'English';

  @override
  String lap_label(String lap) {
    return 'Lap $lap';
  }

  @override
  String get lap_speed_stats => 'LAP & SPEED STATS';

  @override
  String get laps => 'Laps';

  @override
  String get laps_led => 'Laps Led';

  @override
  String get last_5_points => 'Last 5 points';

  @override
  String get last_podium_prefs_section_title => 'Last podium';

  @override
  String get last_podium_prefs_section_subtitle => 'How many recent races to show on circuit cards.';

  @override
  String get last_podium_prefs_races_label => 'Number of races';

  @override
  String get last_winner => 'Last year winner';

  @override
  String get length => 'Length';

  @override
  String get level_1 => 'Very Easy';

  @override
  String get level_2 => 'Easy';

  @override
  String get level_3 => 'Medium';

  @override
  String get level_4 => 'Hard';

  @override
  String get level_5 => 'Very Hard';

  @override
  String linked_update_many(String count) {
    return '$count linked updates';
  }

  @override
  String get linked_update_one => '1 linked update';

  @override
  String get live_leaderboard => 'Leaderboard';

  @override
  String get live_switch_test => 'Switch to Test Data';

  @override
  String get live_teammate_battle => 'Teammate Battle';

  @override
  String get live_timing_title => 'Live Timing';

  @override
  String get live_waiting => 'Waiting for live data...';

  @override
  String get loading => 'Loading';

  @override
  String get logged_in => 'You are logged in';

  @override
  String get login => 'Login';

  @override
  String get login_register_menu => 'Login / Register';

  @override
  String get login_page_title => 'Sign in';

  @override
  String get logout => 'Logout';

  @override
  String get manager => 'Manager';

  @override
  String get max_g_force => 'Max G-Force';

  @override
  String get medium_tire => 'Medium';

  @override
  String get minutes => 'minutes';

  @override
  String get name => 'Name';

  @override
  String get nat_argentine => 'Argentine';

  @override
  String get nat_australian => 'Australian';

  @override
  String get nat_brazilian => 'Brazilian';

  @override
  String get nat_british => 'British';

  @override
  String get nat_canadian => 'Canadian';

  @override
  String get nat_dutch => 'Dutch';

  @override
  String get nat_finnish => 'Finnish';

  @override
  String get nat_french => 'French';

  @override
  String get nat_german => 'German';

  @override
  String get nat_italian => 'Italian';

  @override
  String get nat_japanese => 'Japanese';

  @override
  String get nat_mexican => 'Mexican';

  @override
  String get nat_monegasque => 'Monegasque';

  @override
  String get nat_new_zealander => 'New Zealander';

  @override
  String get nat_spanish => 'Spanish';

  @override
  String get nat_thai => 'Thai';

  @override
  String get nationality => 'Nationality';

  @override
  String get next_race => 'Next Race';

  @override
  String get no_data_yet => 'Data not available yet or API pending update';

  @override
  String get no_finish_data => 'No finish data';

  @override
  String get no_race_results_available => 'No race results available yet.';

  @override
  String get one_two => '1-2 Finishes';

  @override
  String get overtakes => 'Overtakes';

  @override
  String get overtaking_difficulty => 'Overtaking Difficulty';

  @override
  String get overtaking_difficulty_l10n => 'Overtaking Difficulty';

  @override
  String get partner => 'Partner';

  @override
  String get penalties => 'Penalties';

  @override
  String get penalties_empty => 'No penalties found in the current weekend cache.';

  @override
  String get penalty => 'Penalty';

  @override
  String get personal_info => 'Personal Info';

  @override
  String get personal_sponsors => 'Personal Sponsors';

  @override
  String get pets => 'Pets';

  @override
  String get pitstop_leadership => 'Pitstop & Leadership';

  @override
  String get placeholder_page => 'New page';

  @override
  String get placeholder_page_empty => 'This page is empty for now.';

  @override
  String get podiums => 'Podiums';

  @override
  String get points => 'Points';

  @override
  String get points_after_each_race => 'Standings after each race';

  @override
  String get points_history => 'Points per Season';

  @override
  String get points_per_entry => 'Points / entry';

  @override
  String get points_per_start => 'Points / start';

  @override
  String get points_progression => 'Points progression';

  @override
  String get pole_rate => 'Pole rate %';

  @override
  String get poles => 'Pole Positions';

  @override
  String get pos => 'Pos';

  @override
  String get pressure => 'Pressure';

  @override
  String get previous_teams => 'Teams';

  @override
  String get previous_winners => 'Previous winners';

  @override
  String get profile => 'Profile';

  @override
  String get pts => 'PTS';

  @override
  String get q1_out => 'Q1 out';

  @override
  String get q2_out => 'Q2 out';

  @override
  String get qualifying => 'Qualifying';

  @override
  String get race => 'Race';

  @override
  String get race_control => 'Race Control';

  @override
  String get race_control_detail => 'Race Control detail';

  @override
  String get race_control_empty => 'No race control messages found for this filter or search.';

  @override
  String get race_control_filter_alerts => 'Alerts';

  @override
  String get race_control_filter_all => 'All';

  @override
  String get race_control_filter_stewards => 'Stewards';

  @override
  String get race_control_filter_penalties => 'Penalties';

  @override
  String race_control_message_count(String visible, String total) {
    return '$visible of $total messages';
  }

  @override
  String get race_control_no_linked_message => 'No linked steward message found.';

  @override
  String get race_control_related_updates => 'Related steward updates';

  @override
  String get race_control_relation_investigation => 'Investigation';

  @override
  String get race_control_relation_issued_earlier => 'Issued earlier';

  @override
  String get race_control_relation_linked => 'Linked message';

  @override
  String get race_control_relation_message => 'Race Control message';

  @override
  String get race_control_relation_noted => 'Noted';

  @override
  String get race_control_relation_outcome => 'Outcome';

  @override
  String get race_control_relation_penalty_message => 'Penalty message';

  @override
  String get race_control_relation_served_later => 'Served later';

  @override
  String get race_control_relation_served_penalty => 'Served penalty';

  @override
  String get race_control_search_hint => 'Search by message, flag, category, lap or driver';

  @override
  String get race_control_track_limits_strip => 'Track limits — deleted laps';

  @override
  String get race_control_steward_storyline => 'Steward storyline';

  @override
  String get race_stats => 'Race Stats';

  @override
  String get rain => 'Rain';

  @override
  String get rain_chance => 'Rain Chance';

  @override
  String get rainfall => 'Rainfall';

  @override
  String get recommended_strategy_l10n => 'Strategy';

  @override
  String get red_flag => 'Red Flag Chance';

  @override
  String get reserve_driver => 'Reserve Driver';

  @override
  String get result => 'Result';

  @override
  String get results => 'Results';

  @override
  String get retirements => 'Retirements';

  @override
  String get risks => 'Risks';

  @override
  String get risks_incidents => 'RISKS & INCIDENTS';

  @override
  String get round_short => 'R';

  @override
  String get scope => 'Scope';

  @override
  String get season_2026 => '2026 Season';

  @override
  String get select_drivers_to_compare => 'Select 2 drivers';

  @override
  String get select_favorite => 'Select...';

  @override
  String get select_teams_to_compare => 'Select 2 teams';

  @override
  String get session => 'Session';

  @override
  String session_data_unavailable(String session) {
    return '$session data is loading or not available yet.';
  }

  @override
  String get session_future => 'Session begins at';

  @override
  String get session_results => 'Session Results';

  @override
  String get session_status_completed => 'Completed';

  @override
  String get session_status_live_recent => 'Live / Recent';

  @override
  String get session_status_upcoming => 'Upcoming';

  @override
  String session_weather_unavailable(String session) {
    return 'No weather data available for $session.';
  }

  @override
  String get settings => 'Settings';

  @override
  String get show_all => 'All';

  @override
  String show_all_messages(String count) {
    return 'Show all $count messages';
  }

  @override
  String get show_less_messages => 'Show fewer messages';

  @override
  String get since => 'On calendar since';

  @override
  String get slowest_lap => 'Slowest Lap';

  @override
  String get soft_tire => 'Soft';

  @override
  String get sponsors => 'Sponsors';

  @override
  String get sprint => 'Sprint';

  @override
  String get sprint_quali => 'Sprint Qualifying';

  @override
  String get standings => 'Standings';

  @override
  String get start => 'Start';

  @override
  String get starts => 'Starts';

  @override
  String get starts_in => 'Starts in';

  @override
  String get status => 'Status';

  @override
  String get strategy => 'Strategy';

  @override
  String get strategy_1_stop => '1 stop';

  @override
  String get strategy_2_stops => '2 stops';

  @override
  String get strategy_3_stops => '3 stops';

  @override
  String get summer_break => 'Summer break';

  @override
  String get summer_break_subtitle => 'The summer break sits between Hungary and the Netherlands.';

  @override
  String get sun_0_deg_night_race => 'Night Conditions (Artificial Light)';

  @override
  String get sun_5_deg_twilight => 'Twilight (Floodlights Active)';

  @override
  String get sun_8_deg_horizon_dip => 'Near Horizon (Extreme Glare)';

  @override
  String get sun_10_deg_harbor_reflection => 'Very Low Sun (Water Reflection)';

  @override
  String get sun_12_deg_mountain_occlusion => 'Low Sun (Mountain Shadows)';

  @override
  String get sun_14_deg_stadium_shadows => 'Low Sun (Grandstand Shadows)';

  @override
  String get sun_15_deg_sunset_blind => 'Low Sun (High Blindness Risk)';

  @override
  String get sun_18_deg_paddock_glare => 'Low Sun (Building Reflections)';

  @override
  String get sun_20_deg_desert_haze => 'Low Sun (Dust & Haze Glare)';

  @override
  String get sun_22_deg_coastal_mist => 'Low Sun (Sea Mist Diffusion)';

  @override
  String get sun_25_deg_morning_glow => 'Early Morning Sun';

  @override
  String get sun_28_deg_dunes_glare => 'Low Sun (Dunes Glare)';

  @override
  String get sun_30_deg_low_winter_sun => 'Low Winter Sun';

  @override
  String get sun_32_deg_urban_canyon => 'Medium Sun (Skyline Shadows)';

  @override
  String get sun_35_deg_forest_shadows => 'Medium Sun (Intermittent Shadows)';

  @override
  String get sun_40_deg_cloudy_diffuse => 'Diffuse Light (Overcast)';

  @override
  String get sun_45_deg_mid_afternoon => 'Mid-Day Sun';

  @override
  String get sun_50_deg_clear_sky => 'Clear Afternoon Sun';

  @override
  String get sun_55_deg_bright_oval => 'High Brightness (Open Area)';

  @override
  String get sun_60_deg_standard_day => 'Standard Daylight';

  @override
  String get sun_65_deg_high_noon => 'High Sun (Noon)';

  @override
  String get sun_70_deg_equatorial_high => 'High Intensity Sun';

  @override
  String get sun_75_deg_tropical_peak => 'Extreme Tropical Sun';

  @override
  String get sun_85_deg_zenith => 'Overhead Sun (No Shadows)';

  @override
  String get team_facts_title => 'Did You Know?';

  @override
  String get team_history => 'Team History';

  @override
  String get team_principal => 'Team Principal';

  @override
  String get team_theme => 'Team Theme';

  @override
  String get teams => 'Teams';

  @override
  String get teams_chart => 'Teams chart';

  @override
  String get technical_director => 'Technical Director';

  @override
  String get temp => 'Temperature';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get theme_mode_dark => 'Dark';

  @override
  String get theme_mode_light => 'Light';

  @override
  String get theme_mode_system => 'System';

  @override
  String get time => 'Time';

  @override
  String get time_gap => 'Time / Gap';

  @override
  String get tire_wear => 'Tire Wear';

  @override
  String get toggle_theme => 'Toggle Theme';

  @override
  String get top_10 => 'Top 10';

  @override
  String get top_3 => 'Top 3';

  @override
  String get top_5 => 'Top 5';

  @override
  String get top_speed => 'Top Speed';

  @override
  String get total_entries => 'Total Entries';

  @override
  String get total_length => 'Total Length';

  @override
  String get total_points => 'Total Points';

  @override
  String get total_time => 'Total time';

  @override
  String get track_flag_double_yellow => 'Double yellow';

  @override
  String get track_flag_green => 'Green flag';

  @override
  String get track_flag_red => 'Red flag';

  @override
  String get track_flag_yellow => 'Yellow flag';

  @override
  String get track_playback_dry_track => 'Dry track';

  @override
  String get track_playback_interpolated_minute => 'interpolated minute';

  @override
  String get track_playback_no_weather => 'No weather data available for this session.';

  @override
  String get track_playback_rain_active => 'Rain active';

  @override
  String get track_playback_recorded_sample => 'recorded sample';

  @override
  String get track_playback_title => 'Track Playback';

  @override
  String get track_playback_unknown_sample => 'Unknown sample';

  @override
  String get track_temperature => 'Track temperature';

  @override
  String get turn1_accident => 'Turn 1 Accident Chance';

  @override
  String get type_hybrid_street => 'Hybrid Street Circuit';

  @override
  String get type_permanent_circuit => 'Permanent Racing Circuit';

  @override
  String get type_street_circuit => 'Street Circuit';

  @override
  String get tyre => 'Tyre';

  @override
  String get tyres => 'Tyres';

  @override
  String get tyres_strategy => 'TYRES & STRATEGY';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknown_sample => 'Unknown sample';

  @override
  String get unknown_time => 'Unknown time';

  @override
  String get until => 'Contract until';

  @override
  String get used_tyre => 'used';

  @override
  String get using_fallback_data => 'Using offline/fallback data.';

  @override
  String get version => 'Version';

  @override
  String get vsc => 'VSC Chance';

  @override
  String get wear_high => 'High';

  @override
  String get wear_low => 'Low';

  @override
  String get wear_medium => 'Medium';

  @override
  String get weather_forecast => 'Weather Forecast';

  @override
  String get week => 'week';

  @override
  String get weekend_hub => 'Weekend Hub';

  @override
  String get weekend_hub_card_subtitle => 'Schedule, weather, podium and penalties in one screen';

  @override
  String get weekend_hub_load_error => 'Weekend Hub could not be fully loaded. Cached data is being shown.';

  @override
  String get weekend_hub_loading => 'Loading Weekend Hub...';

  @override
  String get weekend_hub_no_results_yet => 'Results for this session are not yet available or have not been synced.';

  @override
  String get weekend_hub_session_insights => 'Session Insights';

  @override
  String get weekend_hub_fastest_sectors => 'Fastest Sectors';

  @override
  String get weekend_hub_sector_1_abbr => 'S1';

  @override
  String get weekend_hub_sector_2_abbr => 'S2';

  @override
  String get weekend_hub_sector_3_abbr => 'S3';

  @override
  String get weekend_hub_tyre_compound => 'Tyre Compound';

  @override
  String get weekend_hub_insights_sectors_unavailable => 'Sector data needs a live OpenF1 sync for this race.';

  @override
  String get weekend_hub_penalties_filter_empty => 'No penalty or investigation messages for this session.';

  @override
  String get weekend_hub_spot_placeholder_title => 'Live radar & DRS';

  @override
  String get weekend_hub_spot_placeholder_body => 'Weather radar, track rain radar, and a DRS zone overview will appear here in a future update.';

  @override
  String get weekend_schedule => 'Weekend schedule';

  @override
  String get weeks => 'weeks';

  @override
  String get win_rate => 'Win rate %';

  @override
  String get wind => 'Wind';

  @override
  String get wind_speed => 'Wind Speed';

  @override
  String get wins => 'Wins';

  @override
  String get ai_fab_label => 'AI';

  @override
  String auth_error_message(String message) {
    return '$message';
  }

  @override
  String get calendar_race_status_cancelled => 'Cancelled';

  @override
  String get calendar_race_status_ended => 'Ended';

  @override
  String get calendar_race_status_ongoing => 'Ongoing';

  @override
  String get circuit_go_home => 'Back to home';

  @override
  String get circuit_not_found_message => 'No circuit data is available for this address. Check the link or pick a circuit from the calendar.';

  @override
  String get circuit_not_found_title => 'Circuit not found';

  @override
  String get circuit_open_in_maps => 'Open in Maps';

  @override
  String get circuit_stat_full_throttle => 'Full throttle';

  @override
  String circuit_weekend_hub_go(String venue) {
    return 'Go to $venue Hub';
  }

  @override
  String get circuit_weekend_hub_no_data_tooltip => 'No session data available yet.';

  @override
  String live_timing_air_temp_abbr(String temp) {
    return 'A $temp';
  }

  @override
  String get live_timing_banner_green => 'GREEN';

  @override
  String get live_timing_banner_red_flag => 'RED FLAG';

  @override
  String get live_timing_banner_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_banner_vsc_deployed => 'VSC DEPLOYED';

  @override
  String get live_timing_banner_vsc_ending => 'VSC ENDING';

  @override
  String get live_timing_banner_yellow_flag => 'YELLOW FLAG';

  @override
  String get live_timing_chip_red_flag => 'RED FLAG';

  @override
  String get live_timing_chip_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_chip_vsc => 'VSC';

  @override
  String get live_timing_chip_vsc_end => 'VSC END';

  @override
  String get live_timing_chip_yellow => 'YELLOW';

  @override
  String live_timing_data_source(String source) {
    return 'Source: $source';
  }

  @override
  String get live_timing_demo_session_title => 'Silverstone 2024';

  @override
  String get live_timing_driver_out => 'OUT';

  @override
  String get live_timing_driver_pit => 'PIT';

  @override
  String get live_timing_header_driver => 'DRIVER';

  @override
  String get live_timing_header_gain => 'GAIN';

  @override
  String get live_timing_header_int_gap => 'INT / GAP';

  @override
  String get live_timing_header_pos => 'POS';

  @override
  String get live_timing_header_s1 => 'S1';

  @override
  String get live_timing_header_s2 => 'S2';

  @override
  String get live_timing_header_s3 => 'S3';

  @override
  String get live_timing_header_tyre => 'TYRE';

  @override
  String get live_timing_hub_timestamp_tooltip => 'Timestamp of last message (stream)';

  @override
  String live_timing_lap_of_total(String current, String total) {
    return 'Lap $current / $total';
  }

  @override
  String get live_timing_session_pre_start => 'PRE-START';

  @override
  String get live_timing_session_starting_grid => 'STARTING GRID';

  @override
  String get live_timing_status_green => 'GREEN';

  @override
  String live_timing_track_temp_abbr(String temp) {
    return 'T $temp';
  }

  @override
  String metric_label_value(String label, String value) {
    return '$label: $value';
  }

  @override
  String news_load_error(String error) {
    return 'Could not load news: $error';
  }

  @override
  String get news_title => 'F1 News';

  @override
  String get news_nav => 'News';

  @override
  String get news_empty => 'No articles right now. Pull to refresh.';

  @override
  String get news_feed_section_empty => 'No articles from this feed.';

  @override
  String get news_settings_title => 'News feeds';

  @override
  String get news_settings_subtitle => 'Add RSS or Atom URLs. They are loaded on the News tab (newest first).';

  @override
  String get news_settings_url_hint => 'https://example.com/feed.xml';

  @override
  String get news_settings_add => 'Add';

  @override
  String get news_settings_your_feeds => 'Your feeds';

  @override
  String get news_settings_no_feeds => 'No feeds yet. Add a URL above.';

  @override
  String get news_settings_invalid_url => 'Enter a valid http(s) URL.';

  @override
  String get news_settings_duplicate_url => 'That URL is already in your list.';

  @override
  String get news_settings_save_failed => 'Could not save. Try again.';

  @override
  String get news_settings_stream_error => 'Could not subscribe to profile updates.';

  @override
  String get news_settings_drag_to_reorder => 'Drag to change feed order';

  @override
  String get orbit_nav => 'Orbit';

  @override
  String get orbit_circuit_list => 'Circuits';

  @override
  String orbit_load_error(String error) {
    return 'Could not load map data: $error';
  }

  @override
  String get orbit_track_standard => 'Standard';

  @override
  String get orbit_track_details => 'Details';

  @override
  String get orbit_track_technical => 'Technical';

  @override
  String get orbit_elevation_profile => 'Elevation profile';

  @override
  String get orbit_stat_lap_distance => 'Lap distance';

  @override
  String get orbit_stat_max_elevation => 'Max elevation change';

  @override
  String get orbit_stat_banked_turns => 'Banked turns';

  @override
  String get race_results_empty => 'No race results available yet.';

  @override
  String get secure_page_authorized => 'You are authorized!';

  @override
  String get secure_page_title => 'Secure Page';

  @override
  String team_comparison_title(String team1, String team2) {
    return '$team1 vs $team2';
  }

  @override
  String get unauthorized_page_message => 'You are not authorized to view this page.';

  @override
  String get unauthorized_page_title => 'Unauthorized';

  @override
  String get circuit_map_expand => 'Expand map';

  @override
  String get circuit_map_collapse => 'Collapse map';

  @override
  String get circuit_map_zoom_in => 'Zoom in';

  @override
  String get circuit_map_zoom_out => 'Zoom out';

  @override
  String get recent_form_trend_title => 'Recent Form Trend';

  @override
  String get recent_form_last_5_points => 'Last 5 Points';

  @override
  String get recent_form_avg_finish => 'Avg. Finish';

  @override
  String get recent_form_total_season_points => 'Total Season Points';

  @override
  String get recent_form_avg_race_finish => 'Avg. Race Finish';

  @override
  String get recent_form_total_podiums => 'Total Podiums (Race + Sprint)';

  @override
  String get recent_form_expand_tooltip => 'Open full season view';

  @override
  String get recent_form_close => 'Close';

  @override
  String get recent_form_no_data => 'No form data for this season yet.';

  @override
  String get simulator_nav => 'Simulator';

  @override
  String get simulator_title => 'Championship Simulator';

  @override
  String get simulator_timeline => 'Timeline';

  @override
  String get simulator_podium_hint => 'Drag a driver onto P1–P3. Drops bump other slots.';

  @override
  String get simulator_standings => 'Season standings';

  @override
  String get simulator_actual => 'Actual';

  @override
  String get simulator_prediction => 'Your pick';

  @override
  String get simulator_accuracy => 'Podium accuracy';

  @override
  String get simulator_magic_clinch => 'Title gap > points left (GP-only bound)';

  @override
  String get simulator_consensus_stub => 'Official championship points from races with results this season (no projections).';

  @override
  String get simulator_sync_cloud => 'Sync predictions to cloud';

  @override
  String get simulator_sync_cloud_done => 'Predictions saved to your account.';

  @override
  String get simulator_sync_cloud_nothing_to_sync => 'Nothing to upload — set P1–P3 for at least one race.';

  @override
  String get simulator_sync_cloud_not_signed_in => 'Sign in to save predictions to the cloud.';

  @override
  String get simulator_sync_cloud_read_only => 'Read-only — cloud sync is disabled.';

  @override
  String simulator_sync_cloud_failed(String detail) {
    return 'Cloud sync failed: $detail';
  }

  @override
  String get simulator_snapshot_tooltip => 'Share standings image';

  @override
  String get simulator_snapshot_copied_hint => 'Image ready — use your device share sheet.';

  @override
  String get simulator_share_readonly_tooltip => 'Share read-only link';

  @override
  String get simulator_share_readonly_subject => 'F1 Hub — championship simulator (read-only)';

  @override
  String get simulator_share_readonly_snackbar => 'Link ready — use your device share sheet.';

  @override
  String get simulator_share_readonly_need_login => 'Sign in to share your read-only simulator link.';

  @override
  String simulator_prediction_by(String username) {
    return 'Prediction by @$username';
  }

  @override
  String simulator_p1_accuracy_percent(int pct) {
    return 'P1 accuracy: $pct%';
  }

  @override
  String simulator_clinch_in(String venue) {
    return 'Title could be decided at: $venue';
  }

  @override
  String get simulator_steward_title => 'Steward grid';

  @override
  String get simulator_steward_hint => 'Penalties and DNFs re-sort the field; points update the projection.';

  @override
  String get simulator_sync_official => 'Sync finished races to official results';

  @override
  String get simulator_sync_official_done => 'Finished races now match official podiums.';

  @override
  String get simulator_save_draft => 'Save draft';

  @override
  String get simulator_undo => 'Undo';

  @override
  String get simulator_readonly_banner => 'Read-only shared view';

  @override
  String get simulator_share_stub_title => 'Shared predictions';

  @override
  String simulator_share_empty(String username) {
    return 'No cloud predictions for \"$username\". That person needs to sign in, fill the championship simulator, and let it sync to the server.';
  }

  @override
  String get simulator_share_error_load => 'Could not load shared predictions. If you use your own Supabase project, run sql/add_simulator_share_rpcs.sql (function get_shared_predictions) and try again.';

  @override
  String get simulator_share_local_preview => 'Preview from this device only — open the simulator while signed in so picks sync to the cloud for others.';

  @override
  String get simulator_steward_coming => 'Steward desk (penalties / status) — next iteration';

  @override
  String simulator_round(int round) {
    return 'R$round';
  }

  @override
  String get simulator_open_full_grid => 'Open full grid';

  @override
  String get simulator_full_grid_title => 'Full grid — 22 drivers';

  @override
  String get simulator_tab_grand_prix => 'Grand Prix';

  @override
  String get simulator_tab_sprint => 'Sprint';

  @override
  String get simulator_session_locked => 'Editing locked — session within 15 minutes';

  @override
  String get simulator_race_cancelled => 'Cancelled — no points';

  @override
  String get simulator_dns => 'DNS';

  @override
  String get simulator_dnf => 'DNF';

  @override
  String get simulator_dsq => 'DSQ';

  @override
  String simulator_stats_line(int predPts, int gridPct, int p1Pct) {
    return '$predPts pts · Grid $gridPct% · P1 $p1Pct%';
  }
}
