// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get accident => 'Kans op crash';

  @override
  String get age => 'Leeftijd';

  @override
  String get ai_avg_gap => 'Gem. verschil';

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
  String get ai_compare_no_match => 'Ik kon geen twee geldige drivers of teams vinden voor deze vergelijking.';

  @override
  String get ai_compare_parse_error => 'Ik kon de vergelijking niet lezen. Gebruik: naam1 vs naam2';

  @override
  String ai_crash(String error) {
    return 'De assistent liep vast op: $error';
  }

  @override
  String ai_driver_compare_ready(String left, String right) {
    return 'Driver comparison klaar voor $left en $right.';
  }

  @override
  String ai_driver_profile_ready(String driver) {
    return 'Driverprofiel klaar voor $driver.';
  }

  @override
  String ai_driver_standings_summary(String year, String summary) {
    return 'Driver standings $year: $summary';
  }

  @override
  String ai_drivers_chart_ready(String year) {
    return 'De coureursgrafiek staat klaar voor $year.';
  }

  @override
  String get ai_example_prompt => 'Probeer bijvoorbeeld: \"Fetch latest results\", \"Show next weekend\", \"Show driver standings\", \"Open driver Charles Leclerc\" of \"Show latest penalties\".';

  @override
  String ai_form_no_cache(String driver) {
    return 'Nog geen gecachte recente races voor $driver.';
  }

  @override
  String get ai_form_no_driver => 'Ik kon geen coureur vinden voor de form-analyse.';

  @override
  String ai_form_summary(String driver, String summary) {
    return 'Laatste vorm van $driver: $summary';
  }

  @override
  String ai_latest_penalties_none(String race) {
    return 'Geen penalties gevonden voor $race.';
  }

  @override
  String ai_latest_penalties_summary(String race, String count, String details) {
    return 'Laatste penalties bij $race: $count. $details';
  }

  @override
  String ai_latest_race_control_none(String race) {
    return 'Geen Race Control-berichten gevonden voor $race.';
  }

  @override
  String ai_latest_race_control_summary(String race, String count, String message) {
    return 'Race Control bij $race: $count berichten. Laatste update: $message';
  }

  @override
  String ai_latest_results_podium(String podium) {
    return 'Laatste resultaten vernieuwd. Podium: $podium';
  }

  @override
  String get ai_latest_results_refreshed => 'De laatste uitslag is opnieuw opgehaald.';

  @override
  String ai_next_weekend(String race, String date) {
    return 'Volgend weekend: $race op $date.';
  }

  @override
  String ai_next_weekend_weather(String race, String temp, String rain, String wind) {
    return 'Weer voor $race: ${temp}C, $rain% regen, $wind km/u wind.';
  }

  @override
  String get ai_no_completed_race => 'Er is nog geen verreden race gevonden.';

  @override
  String get ai_open_driver_compare => 'Open driver compare';

  @override
  String get ai_open_driver_profile => 'Open driverprofiel';

  @override
  String get ai_open_driver_standings => 'Open driver standings';

  @override
  String get ai_open_drivers_chart => 'Open coureursgrafiek';

  @override
  String get ai_open_latest_results => 'Open laatste resultaten';

  @override
  String get ai_open_team_compare => 'Open team compare';

  @override
  String get ai_open_team_profile => 'Open teamprofiel';

  @override
  String get ai_open_team_standings => 'Open constructor standings';

  @override
  String get ai_open_weekend_hub => 'Open weekend hub';

  @override
  String get ai_qualifying_duel => 'Kwalificatie-duel';

  @override
  String get ai_race_engineer => 'AI Race Engineer';

  @override
  String get ai_rain_chance_label => 'Regenkans';

  @override
  String get ai_rain_chance_slider => 'Regenkans';

  @override
  String get ai_sentiment_generic_neutral => 'Team Vibe: Gemengde signalen van teamradio\'\'s.';

  @override
  String get ai_sentiment_generic_positive => 'Team Vibe: Positieve energie in de paddock.';

  @override
  String get ai_sentiment_label => 'Team Vibe';

  @override
  String get ai_sentiment_mercedes_positive => 'Team Vibe: Spanning stijgt bij Mercedes na gridstraf Hamilton.';

  @override
  String get ai_strategist_tap_hint => 'Tik om vragen te stellen...';

  @override
  String get ai_strategist_title => 'AI Strategist';

  @override
  String get ai_prefs_section_title => 'AI Strategist';

  @override
  String get ai_prefs_section_subtitle => 'Pas de AI Strategist-kaart op het startscherm aan.';

  @override
  String get ai_prefs_disable_card => 'AI Strategist-kaart uitschakelen';

  @override
  String get ai_prefs_hide_teambattle => 'Teammate Battle verbergen';

  @override
  String get ai_prefs_hide_teambattle_hint => 'Verberg de teamgenoot-vergelijking als de kaart zichtbaar is.';

  @override
  String get ai_prefs_hide_coach_corner => 'Coach\'\'s Corner verbergen';

  @override
  String get ai_prefs_hide_coach_corner_hint => 'Verberg coachtips als de kaart zichtbaar is.';

  @override
  String get ai_prefs_hide_team_vibe => 'Team Vibe verbergen';

  @override
  String get ai_prefs_hide_team_vibe_hint => 'Verberg sentiment als de kaart zichtbaar is.';

  @override
  String get ai_supported_commands => 'Ondersteunde commando\'\'s: Fetch latest results, Show next weekend, Compare naam1 vs naam2, Show form [driver], Show driver standings, Show team standings, Open driver [naam], Open team [naam], Show drivers chart, Show latest penalties, Show latest race control.';

  @override
  String ai_team_compare_ready(String left, String right) {
    return 'Team comparison klaar voor $left en $right.';
  }

  @override
  String ai_team_profile_ready(String team) {
    return 'Teamprofiel klaar voor $team.';
  }

  @override
  String ai_team_standings_summary(String year, String summary) {
    return 'Constructor standings $year: $summary';
  }

  @override
  String get ai_teammate_battle => 'Teamgenoten-duel';

  @override
  String ai_teammate_insight(String driver, String teammate) {
    return '$driver is traditioneel sterker op dit circuit in de kwalificatie, terwijl $teammate uitblinkt in bandenbeheer.';
  }

  @override
  String get ai_type_command => 'Typ een opdracht...';

  @override
  String ai_weather_effect(String pct, String driver, String pct2) {
    return 'Bij $pct% regen: Kans op podium voor $driver stijgt $pct2% vanwege superieure regen-pace.';
  }

  @override
  String ai_weather_effect_at(String pct, String insight) {
    return 'Bij $pct% regen: $insight';
  }

  @override
  String get ai_weather_insight_alonso => 'Kans op podium voor Alonso stijgt 15% vanwege superieure regen-pace.';

  @override
  String get ai_weather_insight_generic => 'Natte omstandigheden gunstig voor sterke regen-coureurs.';

  @override
  String get air_temperature => 'Luchttemperatuur';

  @override
  String get all_scopes => 'Alle scopes';

  @override
  String get app_title => 'F1 Hub';

  @override
  String get average_speed => 'Gemiddelde snelheid';

  @override
  String get avg_finish => 'Gem. finish';

  @override
  String get avg_finish_l5 => 'Gem. finish (L5)';

  @override
  String get avg_gforce => 'Gem. G-kracht';

  @override
  String get avg_lap => 'Gemiddelde ronde';

  @override
  String get best_combination => 'Beste combinatie';

  @override
  String get best_lap => 'Beste ronde';

  @override
  String get birth_place => 'Geboorteplaats';

  @override
  String get cache_cleared => 'Cache succesvol geleegd!';

  @override
  String car_label(String number) {
    return 'Auto $number';
  }

  @override
  String get career_stats => 'Carrière statistieken';

  @override
  String get cc_wins => 'Constructeurstitels';

  @override
  String get championship_progression => 'Kampioenschapsverloop';

  @override
  String get championships => 'Wereldtitels';

  @override
  String get calendar_prefs_section_title => 'Kalender';

  @override
  String get calendar_prefs_section_subtitle => 'Pas de circuits-kalender aan.';

  @override
  String get calendar_prefs_hide_cancelled => 'Placeholder-races verbergen';

  @override
  String get calendar_prefs_hide_cancelled_hint => 'Verberg geannuleerde of placeholder-races die niet op de echte kalender staan.';

  @override
  String get display_prefs_section_title => 'Weergave';

  @override
  String get display_prefs_section_subtitle => 'Uiterlijk en animaties. Ingelogd worden ze met je account gesynchroniseerd.';

  @override
  String get display_prefs_ui_mode => 'Interfacestijl';

  @override
  String get display_prefs_mode_standard => 'Standaard';

  @override
  String get display_prefs_mode_standard_hint => 'Glasachtige vervaging en zachte schaduwen.';

  @override
  String get display_prefs_mode_simple => 'Eenvoudig';

  @override
  String get display_prefs_mode_simple_hint => 'Vlakke vlakken en sterker contrast.';

  @override
  String get display_prefs_compact => 'Compacte modus';

  @override
  String get display_prefs_compact_hint => 'Strakkere marges en kleinere kaarten.';

  @override
  String get display_prefs_motion_reduced => 'Minder beweging';

  @override
  String get display_prefs_motion_reduced_hint => 'Minder animatie, vervaging en thema-overgangen.';

  @override
  String get display_prefs_saving => 'Opslaan…';

  @override
  String get my_paddock_title => 'Mijn paddock';

  @override
  String get my_paddock_session_unknown => 'Live timing';

  @override
  String my_paddock_resume_subtitle(String session, String lap) {
    return 'Hervatten: $session — frame $lap';
  }

  @override
  String get my_paddock_favorite_drivers => 'Favoriete coureurs';

  @override
  String get my_paddock_favorite_teams => 'Favoriete teams';

  @override
  String get my_paddock_last_race => 'Laatste race';

  @override
  String my_paddock_last_race_summary(String date, String podium) {
    return '$date · $podium';
  }

  @override
  String get my_paddock_points_suffix => 'pnt';

  @override
  String get changelog => 'Changelog';

  @override
  String get characteristics => 'CIRCUIT KENMERKEN';

  @override
  String get chart_no_data => 'Geen grafiekdata beschikbaar voor dit seizoen.';

  @override
  String get children => 'Kinderen';

  @override
  String get circuit => 'Circuit';

  @override
  String get circuit_difficulty => 'Circuit moeilijkheid';

  @override
  String get circuit_info => 'Circuit info';

  @override
  String get circuit_layout => 'Circuit lay-out';

  @override
  String get circuits => 'Circuits';

  @override
  String get city => 'Stad';

  @override
  String get clear_cache => 'Cache legen';

  @override
  String get close => 'Sluiten';

  @override
  String get compare => 'Vergelijken';

  @override
  String get compare_overall => 'Overall';

  @override
  String get compare_season => 'Per seizoen';

  @override
  String get compare_season_unavailable => 'Seizoensdata voor deze vergelijking is niet beschikbaar.';

  @override
  String get compare_year => 'Seizoen';

  @override
  String get contract_until => 'Contract tot';

  @override
  String get country => 'Land';

  @override
  String get country_australia => 'Australië';

  @override
  String get country_austria => 'Oostenrijk';

  @override
  String get country_azerbaijan => 'Azerbeidzjan';

  @override
  String get country_bahrain => 'Bahrein';

  @override
  String get country_belgium => 'België';

  @override
  String get country_brazil => 'Brazilië';

  @override
  String get country_canada => 'Canada';

  @override
  String get country_china => 'China';

  @override
  String get country_hungary => 'Hongarije';

  @override
  String get country_italy => 'Italië';

  @override
  String get country_japan => 'Japan';

  @override
  String get country_mexico => 'Mexico';

  @override
  String get country_monaco => 'Monaco';

  @override
  String get country_netherlands => 'Nederland';

  @override
  String get country_qatar => 'Qatar';

  @override
  String get country_saudi_arabia => 'Saoedi-Arabië';

  @override
  String get country_singapore => 'Singapore';

  @override
  String get country_spain => 'Spanje';

  @override
  String get country_uae => 'V.A.E.';

  @override
  String get country_uk => 'Groot-Brittannië';

  @override
  String get country_usa => 'VS';

  @override
  String get current_team => 'Huidig team';

  @override
  String get date => 'Datum';

  @override
  String get day => 'dag';

  @override
  String get days => 'dagen';

  @override
  String get dc_wins => 'Coureurstitels';

  @override
  String get distance_to_turn1 => 'Afstand tot bocht 1';

  @override
  String get dnf => 'Uitvalbeurten (DNF)';

  @override
  String get dnf_percentage => 'Uitval %';

  @override
  String get dnqs => 'Niet gekwalificeerd';

  @override
  String get driver => 'Coureur';

  @override
  String get driver_facts_title => 'Feiten & weetjes';

  @override
  String get driver_history => 'Historie (laatste 5 jaar)';

  @override
  String get drivers => 'Coureurs';

  @override
  String get drivers_chart => 'Coureursgrafiek';

  @override
  String get dsqs => 'Gediskwalificeerd';

  @override
  String get engine => 'Motor';

  @override
  String get engine_name => 'Motornaam';

  @override
  String get engine_supplier => 'Motorleverancier';

  @override
  String get experience => 'Ervaring';

  @override
  String get f1_debut => 'F1 debuut';

  @override
  String get fastest_lap => 'Snelste ronde';

  @override
  String get fastest_lap_rate => 'Snelste ronde %';

  @override
  String get fastest_laps => 'Snelste rondes';

  @override
  String get fastest_pit => 'Snelste pitstop';

  @override
  String get favorite_circuit => 'Favoriete circuit';

  @override
  String get favorite_driver => 'Favoriete coureur';

  @override
  String get favorite_team => 'Favoriete team';

  @override
  String get finish => 'Finish';

  @override
  String get fp1 => 'Vrije training 1';

  @override
  String get fp2 => 'Vrije training 2';

  @override
  String get fp3 => 'Vrije training 3';

  @override
  String get front_row_starts => 'Starts 1e rij';

  @override
  String get fullscreen_table => 'Tabel op volledig scherm';

  @override
  String get gap => 'Verschil';

  @override
  String get general => 'Algemeen';

  @override
  String get gp_abu_dhabi_grand_prix => 'Grand Prix van Abu Dhabi';

  @override
  String get gp_australian_grand_prix => 'Grand Prix van Australië';

  @override
  String get gp_austrian_grand_prix => 'Grand Prix van Oostenrijk';

  @override
  String get gp_azerbaijan_grand_prix => 'Grand Prix van Azerbeidzjan';

  @override
  String get gp_bahrain_grand_prix => 'Grand Prix van Bahrein';

  @override
  String get gp_barcelona_grand_prix => 'Grand Prix van Barcelona';

  @override
  String get gp_belgian_grand_prix => 'Grand Prix van België';

  @override
  String get gp_british_grand_prix => 'Grand Prix van Groot-Brittannië';

  @override
  String get gp_canadian_grand_prix => 'Grand Prix van Canada';

  @override
  String get gp_chinese_grand_prix => 'Grand Prix van China';

  @override
  String get gp_dutch_grand_prix => 'Grand Prix van Nederland';

  @override
  String get gp_hungarian_grand_prix => 'Grand Prix van Hongarije';

  @override
  String get gp_italian_grand_prix => 'Grand Prix van Italië';

  @override
  String get gp_japanese_grand_prix => 'Grand Prix van Japan';

  @override
  String get gp_las_vegas_grand_prix => 'Grand Prix van Las Vegas';

  @override
  String get gp_mexico_city_grand_prix => 'Grand Prix van Mexico';

  @override
  String get gp_miami_grand_prix => 'Grand Prix van Miami';

  @override
  String get gp_monaco_grand_prix => 'Grand Prix van Monaco';

  @override
  String get gp_qatar_grand_prix => 'Grand Prix van Qatar';

  @override
  String get gp_s_o_paulo_grand_prix => 'Grand Prix van São Paulo';

  @override
  String get gp_saudi_arabian_grand_prix => 'Grand Prix van Saoedi-Arabië';

  @override
  String get gp_singapore_grand_prix => 'Grand Prix van Singapore';

  @override
  String get gp_spanish_grand_prix => 'Grand Prix van Spanje';

  @override
  String get gp_united_states_grand_prix => 'Grand Prix van de VS';

  @override
  String get hard_tire => 'Hard';

  @override
  String get hat_tricks => 'Hattricks';

  @override
  String get headquarters => 'Hoofdkantoor';

  @override
  String get height => 'Lengte';

  @override
  String get help_and_ideas => 'Hulp & ideeën';

  @override
  String get hide_all => 'Geen';

  @override
  String get highest_finish => 'Hoogste finish';

  @override
  String get highest_grid => 'Hoogste startplek';

  @override
  String get hours => 'uur';

  @override
  String get humidity => 'Luchtvochtigheid';

  @override
  String get language => 'Taal';

  @override
  String get language_chooser => 'Nederlands';

  @override
  String get language_selector => 'Nederlands';

  @override
  String lap_label(String lap) {
    return 'Ronde $lap';
  }

  @override
  String get lap_speed_stats => 'RONDE & SNELHEID';

  @override
  String get laps => 'Rondes';

  @override
  String get laps_led => 'Rondes aan de leiding';

  @override
  String get last_5_points => 'Punten laatste 5';

  @override
  String get last_podium_prefs_section_title => 'Laatste podium';

  @override
  String get last_podium_prefs_section_subtitle => 'Hoeveel recente races op circuitkaarten tonen.';

  @override
  String get last_podium_prefs_races_label => 'Aantal races';

  @override
  String get last_winner => 'Winnaar vorig jaar';

  @override
  String get length => 'Lengte';

  @override
  String get level_1 => 'Zeer makkelijk';

  @override
  String get level_2 => 'Makkelijk';

  @override
  String get level_3 => 'Gemiddeld';

  @override
  String get level_4 => 'Moeilijk';

  @override
  String get level_5 => 'Zeer moeilijk';

  @override
  String linked_update_many(String count) {
    return '$count gekoppelde updates';
  }

  @override
  String get linked_update_one => '1 gekoppelde update';

  @override
  String get live_leaderboard => 'Klassement';

  @override
  String get live_switch_test => 'Schakel naar testdata';

  @override
  String get live_teammate_battle => 'Teamgenoten-duel';

  @override
  String get live_timing_title => 'Live Timing';

  @override
  String get live_waiting => 'Wachten op live data...';

  @override
  String get loading => 'Laden';

  @override
  String get logged_in => 'Je bent ingelogd';

  @override
  String get login => 'Inloggen';

  @override
  String get logout => 'Uitloggen';

  @override
  String get manager => 'Manager';

  @override
  String get max_g_force => 'Max G-kracht';

  @override
  String get medium_tire => 'Medium';

  @override
  String get minutes => 'minuten';

  @override
  String get name => 'Naam';

  @override
  String get nat_argentine => 'Argentijns';

  @override
  String get nat_australian => 'Australisch';

  @override
  String get nat_brazilian => 'Braziliaans';

  @override
  String get nat_british => 'Brits';

  @override
  String get nat_canadian => 'Canadees';

  @override
  String get nat_dutch => 'Nederlands';

  @override
  String get nat_finnish => 'Fins';

  @override
  String get nat_french => 'Frans';

  @override
  String get nat_german => 'Duits';

  @override
  String get nat_italian => 'Italiaans';

  @override
  String get nat_japanese => 'Japans';

  @override
  String get nat_mexican => 'Mexicaans';

  @override
  String get nat_monegasque => 'Monegaskisch';

  @override
  String get nat_new_zealander => 'Nieuw-Zeelands';

  @override
  String get nat_spanish => 'Spaans';

  @override
  String get nat_thai => 'Thais';

  @override
  String get nationality => 'Nationaliteit';

  @override
  String get next_race => 'Volgende race';

  @override
  String get no_data_yet => 'Data nog niet beschikbaar of API is nog niet geüpdatet';

  @override
  String get no_finish_data => 'Geen finishdata';

  @override
  String get no_race_results_available => 'Nog geen race-uitslag beschikbaar.';

  @override
  String get one_two => '1-2 finishes';

  @override
  String get overtakes => 'Inhaalacties';

  @override
  String get overtaking_difficulty => 'Inhaal moeilijkheid';

  @override
  String get partner => 'Partner';

  @override
  String get penalties => 'Penalties';

  @override
  String get penalties_empty => 'Geen penalties gevonden in de huidige weekendcache.';

  @override
  String get penalty => 'Straf';

  @override
  String get personal_info => 'Persoonlijke info';

  @override
  String get personal_sponsors => 'Persoonlijke sponsors';

  @override
  String get pets => 'Huisdieren';

  @override
  String get pitstop_leadership => 'Pitstop & leiderschap';

  @override
  String get placeholder_page => 'Nieuwe pagina';

  @override
  String get placeholder_page_empty => 'Deze pagina is nog leeg.';

  @override
  String get podiums => 'Podiums';

  @override
  String get points => 'Punten';

  @override
  String get points_after_each_race => 'Stand na elke race';

  @override
  String get points_history => 'Punten per seizoen';

  @override
  String get points_per_entry => 'Punten / entry';

  @override
  String get points_per_start => 'Punten / start';

  @override
  String get points_progression => 'Puntenverloop';

  @override
  String get pole_rate => 'Pole %';

  @override
  String get poles => 'Pole positions';

  @override
  String get pos => 'Pos';

  @override
  String get pressure => 'Druk';

  @override
  String get previous_teams => 'Teams';

  @override
  String get previous_winners => 'Eerdere winnaars';

  @override
  String get profile => 'Profiel';

  @override
  String get pts => 'PNT';

  @override
  String get q1_out => 'Q1 uit';

  @override
  String get q2_out => 'Q2 uit';

  @override
  String get qualifying => 'Kwalificatie';

  @override
  String get race => 'Race';

  @override
  String get race_control => 'Race Control';

  @override
  String get race_control_detail => 'Race Control detail';

  @override
  String get race_control_empty => 'Geen race control-berichten gevonden voor deze filter of zoekopdracht.';

  @override
  String get race_control_filter_alerts => 'Waarschuwingen';

  @override
  String get race_control_filter_all => 'Alle';

  @override
  String get race_control_filter_stewards => 'Commissarissen';

  @override
  String race_control_message_count(String visible, String total) {
    return '$visible van $total berichten';
  }

  @override
  String get race_control_no_linked_message => 'Geen gekoppeld steward-bericht gevonden.';

  @override
  String get race_control_related_updates => 'Gerelateerde steward-updates';

  @override
  String get race_control_relation_investigation => 'Onderzoek';

  @override
  String get race_control_relation_issued_earlier => 'Eerder opgelegd';

  @override
  String get race_control_relation_linked => 'Gekoppeld bericht';

  @override
  String get race_control_relation_message => 'Race Control-bericht';

  @override
  String get race_control_relation_noted => 'Genoteerd';

  @override
  String get race_control_relation_outcome => 'Uitkomst';

  @override
  String get race_control_relation_penalty_message => 'Strafbericht';

  @override
  String get race_control_relation_served_later => 'Later uitgevoerd';

  @override
  String get race_control_relation_served_penalty => 'Uitgevoerde straf';

  @override
  String get race_control_search_hint => 'Zoek op bericht, vlag, categorie, ronde of coureur';

  @override
  String get race_stats => 'Race statistieken';

  @override
  String get rain => 'Regen';

  @override
  String get rain_chance => 'Regenkans';

  @override
  String get rainfall => 'Neerslag';

  @override
  String get red_flag => 'Kans op rode vlag';

  @override
  String get reserve_driver => 'Reservecoureur';

  @override
  String get result => 'Resultaat';

  @override
  String get results => 'Resultaten';

  @override
  String get retirements => 'Uitvalbeurten';

  @override
  String get risks => 'Risico\'\'s';

  @override
  String get risks_incidents => 'RISICO\'\'S & INCIDENTEN';

  @override
  String get round_short => 'R';

  @override
  String get scope => 'Scope';

  @override
  String get season_2026 => '2026 Seizoen';

  @override
  String get select_drivers_to_compare => 'Selecteer 2 coureurs';

  @override
  String get select_favorite => 'Selecteer...';

  @override
  String get select_teams_to_compare => 'Selecteer 2 teams';

  @override
  String get session => 'Sessie';

  @override
  String session_data_unavailable(String session) {
    return '$session-data wordt geladen of is nog niet beschikbaar.';
  }

  @override
  String get session_future => 'Sessie begint op';

  @override
  String get session_results => 'Sessie resultaten';

  @override
  String get session_status_completed => 'Voltooid';

  @override
  String get session_status_live_recent => 'Live / recent';

  @override
  String get session_status_upcoming => 'Aankomend';

  @override
  String session_weather_unavailable(String session) {
    return 'Geen weerdata beschikbaar voor $session.';
  }

  @override
  String get settings => 'Instellingen';

  @override
  String get show_all => 'Alles';

  @override
  String show_all_messages(String count) {
    return 'Alle $count berichten tonen';
  }

  @override
  String get show_less_messages => 'Minder berichten tonen';

  @override
  String get since => 'Op kalender sinds';

  @override
  String get slowest_lap => 'Langzaamste ronde';

  @override
  String get soft_tire => 'Zacht';

  @override
  String get sponsors => 'Sponsors';

  @override
  String get sprint => 'Sprintrace';

  @override
  String get sprint_quali => 'Sprint kwalificatie';

  @override
  String get standings => 'Standen';

  @override
  String get start => 'Start';

  @override
  String get starts => 'Starts';

  @override
  String get starts_in => 'Start in';

  @override
  String get status => 'Status';

  @override
  String get strategy => 'Strategie';

  @override
  String get strategy_1_stop => '1 stop';

  @override
  String get strategy_2_stops => '2 stops';

  @override
  String get strategy_3_stops => '3 stops';

  @override
  String get summer_break => 'Zomerstop';

  @override
  String get summer_break_subtitle => 'Tussen Hongarije en Nederland ligt de zomerstop.';

  @override
  String get team_facts_title => 'Wist je dat?';

  @override
  String get team_history => 'Teamgeschiedenis';

  @override
  String get team_principal => 'Teambaas';

  @override
  String get team_theme => 'Teamthema';

  @override
  String get teams => 'Teams';

  @override
  String get teams_chart => 'Teamsgrafiek';

  @override
  String get technical_director => 'Technisch directeur';

  @override
  String get temp => 'Temperatuur';

  @override
  String get theme_mode => 'Weergavemodus';

  @override
  String get theme_mode_dark => 'Donker';

  @override
  String get theme_mode_light => 'Licht';

  @override
  String get theme_mode_system => 'Systeem';

  @override
  String get time => 'Tijd';

  @override
  String get time_gap => 'Tijd / verschil';

  @override
  String get tire_wear => 'Bandenslijtage';

  @override
  String get toggle_theme => 'Wissel thema';

  @override
  String get top_10 => 'Top 10';

  @override
  String get top_3 => 'Top 3';

  @override
  String get top_5 => 'Top 5';

  @override
  String get top_speed => 'Topsnelheid';

  @override
  String get total_entries => 'Totale inschrijvingen';

  @override
  String get total_length => 'Totale lengte';

  @override
  String get total_points => 'Totale punten';

  @override
  String get total_time => 'Totale tijd';

  @override
  String get track_flag_double_yellow => 'Dubbel geel';

  @override
  String get track_flag_green => 'Groene vlag';

  @override
  String get track_flag_red => 'Rode vlag';

  @override
  String get track_flag_yellow => 'Gele vlag';

  @override
  String get track_playback_dry_track => 'Droge baan';

  @override
  String get track_playback_interpolated_minute => 'geïnterpoleerde minuut';

  @override
  String get track_playback_no_weather => 'Geen weerdata beschikbaar voor deze sessie.';

  @override
  String get track_playback_rain_active => 'Regen actief';

  @override
  String get track_playback_recorded_sample => 'opgenomen sample';

  @override
  String get track_playback_title => 'Track Playback';

  @override
  String get track_playback_unknown_sample => 'Onbekend sample';

  @override
  String get track_temperature => 'Baantemperatuur';

  @override
  String get turn1_accident => 'Kans crash bocht 1';

  @override
  String get tyre => 'Band';

  @override
  String get tyres => 'Banden';

  @override
  String get tyres_strategy => 'BANDEN & STRATEGIE';

  @override
  String get unknown => 'Onbekend';

  @override
  String get unknown_sample => 'Onbekend';

  @override
  String get unknown_time => 'Onbekende tijd';

  @override
  String get until => 'Contract tot';

  @override
  String get used_tyre => 'gebruikt';

  @override
  String get using_fallback_data => 'Offline/fallback data in gebruik.';

  @override
  String get version => 'Versie';

  @override
  String get vsc => 'Kans op VSC';

  @override
  String get wear_high => 'Hoog';

  @override
  String get wear_low => 'Laag';

  @override
  String get wear_medium => 'Gemiddeld';

  @override
  String get weather_forecast => 'Weerverwachting';

  @override
  String get week => 'week';

  @override
  String get weekend_hub => 'Weekend hub';

  @override
  String get weekend_hub_card_subtitle => 'Schema, weer, podium en penalties in één scherm';

  @override
  String get weekend_hub_load_error => 'Weekend hub kon niet volledig laden. Cachedata wordt getoond.';

  @override
  String get weekend_hub_loading => 'Weekend hub laden...';

  @override
  String get weekend_schedule => 'Weekend schema';

  @override
  String get weeks => 'weken';

  @override
  String get win_rate => 'Winrate %';

  @override
  String get wind => 'Wind';

  @override
  String get wind_speed => 'Windsnelheid';

  @override
  String get wins => 'Overwinningen';

  @override
  String get ai_fab_label => 'AI';

  @override
  String auth_error_message(String message) {
    return '$message';
  }

  @override
  String get calendar_race_status_cancelled => 'Geannuleerd';

  @override
  String get calendar_race_status_ended => 'Beëindigd';

  @override
  String get calendar_race_status_ongoing => 'Bezig';

  @override
  String get circuit_open_in_maps => 'Openen in Maps';

  @override
  String live_timing_air_temp_abbr(String temp) {
    return 'A $temp';
  }

  @override
  String get live_timing_banner_green => 'GREEN';

  @override
  String get live_timing_banner_red_flag => 'RODE VLAG';

  @override
  String get live_timing_banner_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_banner_vsc_deployed => 'VSC INGEZET';

  @override
  String get live_timing_banner_vsc_ending => 'VSC EINDIGT';

  @override
  String get live_timing_banner_yellow_flag => 'GELE VLAG';

  @override
  String get live_timing_chip_red_flag => 'RODE VLAG';

  @override
  String get live_timing_chip_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_chip_vsc => 'VSC';

  @override
  String get live_timing_chip_vsc_end => 'VSC EINDE';

  @override
  String get live_timing_chip_yellow => 'GEEL';

  @override
  String live_timing_data_source(String source) {
    return 'Bron: $source';
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
  String get live_timing_header_gain => 'WINST';

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
  String get live_timing_header_tyre => 'BAND';

  @override
  String get live_timing_hub_timestamp_tooltip => 'Tijdstempel laatste bericht (stream)';

  @override
  String live_timing_lap_of_total(String current, String total) {
    return 'Ronde $current / $total';
  }

  @override
  String get live_timing_session_pre_start => 'PRE-START';

  @override
  String get live_timing_session_starting_grid => 'STARTGRID';

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
    return 'Kon nieuws niet laden: $error';
  }

  @override
  String get news_title => 'F1 Nieuws';

  @override
  String get news_nav => 'Nieuws';

  @override
  String get news_empty => 'Geen artikelen op dit moment. Trek om te vernieuwen.';

  @override
  String get news_settings_title => 'Nieuwsfeeds';

  @override
  String get news_settings_subtitle => 'Voeg RSS- of Atom-URL\'\'s toe. Ze worden op het tabblad Nieuws geladen (nieuwste eerst).';

  @override
  String get news_settings_url_hint => 'https://voorbeeld.nl/feed.xml';

  @override
  String get news_settings_add => 'Toevoegen';

  @override
  String get news_settings_your_feeds => 'Jouw feeds';

  @override
  String get news_settings_no_feeds => 'Nog geen feeds. Voeg hierboven een URL toe.';

  @override
  String get news_settings_invalid_url => 'Voer een geldige http(s)-URL in.';

  @override
  String get news_settings_duplicate_url => 'Deze URL staat al in je lijst.';

  @override
  String get news_settings_save_failed => 'Opslaan mislukt. Probeer opnieuw.';

  @override
  String get news_settings_stream_error => 'Kon profiel-updates niet ontvangen.';

  @override
  String get race_results_empty => 'Nog geen race-resultaten beschikbaar.';

  @override
  String get secure_page_authorized => 'Je bent geautoriseerd!';

  @override
  String get secure_page_title => 'Beveiligde pagina';

  @override
  String team_comparison_title(String team1, String team2) {
    return '$team1 vs $team2';
  }

  @override
  String get unauthorized_page_message => 'Je hebt geen toestemming om deze pagina te bekijken.';

  @override
  String get unauthorized_page_title => 'Niet geautoriseerd';
}
