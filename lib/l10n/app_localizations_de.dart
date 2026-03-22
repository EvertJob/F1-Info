// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accident => 'Unfallwahrscheinlichkeit';

  @override
  String get age => 'Alter';

  @override
  String get ai_avg_gap => 'Ø Differenz';

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
  String get ai_compare_no_match => 'Ich konnte keine zwei gültigen Fahrer oder Teams für diesen Vergleich finden.';

  @override
  String get ai_compare_parse_error => 'Ich konnte den Vergleich nicht lesen. Verwende: name1 vs name2';

  @override
  String ai_crash(String error) {
    return 'Der Assistent ist abgestürzt: $error';
  }

  @override
  String ai_driver_compare_ready(String left, String right) {
    return 'Fahrervergleich ist bereit für $left und $right.';
  }

  @override
  String ai_driver_profile_ready(String driver) {
    return 'Fahrerprofil bereit für $driver.';
  }

  @override
  String ai_driver_standings_summary(String year, String summary) {
    return 'Fahrerwertung $year: $summary';
  }

  @override
  String ai_drivers_chart_ready(String year) {
    return 'Das Fahrerdiagramm ist bereit für $year.';
  }

  @override
  String get ai_example_prompt => 'Zum Beispiel: \"Fetch latest results\", \"Show next weekend\", \"Show driver standings\", \"Open driver Charles Leclerc\" oder \"Show latest penalties\".';

  @override
  String ai_form_no_cache(String driver) {
    return 'Noch keine gecachten letzten Rennen für $driver.';
  }

  @override
  String get ai_form_no_driver => 'Ich konnte keinen Fahrer für die Form-Analyse finden.';

  @override
  String ai_form_summary(String driver, String summary) {
    return 'Aktuelle Form von $driver: $summary';
  }

  @override
  String ai_latest_penalties_none(String race) {
    return 'Keine Strafen für $race gefunden.';
  }

  @override
  String ai_latest_penalties_summary(String race, String count, String details) {
    return 'Neueste Strafen in $race: $count. $details';
  }

  @override
  String ai_latest_race_control_none(String race) {
    return 'Keine Race-Control-Nachrichten für $race gefunden.';
  }

  @override
  String ai_latest_race_control_summary(String race, String count, String message) {
    return 'Race Control bei $race: $count Nachrichten. Letztes Update: $message';
  }

  @override
  String ai_latest_results_podium(String podium) {
    return 'Neueste Ergebnisse aktualisiert. Podium: $podium';
  }

  @override
  String get ai_latest_results_refreshed => 'Die neuesten Ergebnisse wurden aktualisiert.';

  @override
  String ai_next_weekend(String race, String date) {
    return 'Nächstes Wochenende: $race am $date.';
  }

  @override
  String ai_next_weekend_weather(String race, String temp, String rain, String wind) {
    return 'Wetter für $race: ${temp}C, $rain% Regen, $wind km/h Wind.';
  }

  @override
  String get ai_no_completed_race => 'Es wurde noch kein beendetes Rennen gefunden.';

  @override
  String get ai_open_driver_compare => 'Fahrervergleich öffnen';

  @override
  String get ai_open_driver_profile => 'Fahrerprofil öffnen';

  @override
  String get ai_open_driver_standings => 'Fahrerwertung öffnen';

  @override
  String get ai_open_drivers_chart => 'Fahrerdiagramm öffnen';

  @override
  String get ai_open_latest_results => 'Neueste Ergebnisse öffnen';

  @override
  String get ai_open_team_compare => 'Teamvergleich öffnen';

  @override
  String get ai_open_team_profile => 'Teamprofil öffnen';

  @override
  String get ai_open_team_standings => 'Konstrukteurswertung öffnen';

  @override
  String get ai_open_weekend_hub => 'Wochenend-Hub öffnen';

  @override
  String get ai_qualifying_duel => 'Qualifying-Duell';

  @override
  String get ai_race_engineer => 'KI-Renningenieur';

  @override
  String get ai_rain_chance_label => 'Regenwahrscheinlichkeit';

  @override
  String get ai_rain_chance_slider => 'Regenwahrscheinlichkeit';

  @override
  String get ai_sentiment_generic_neutral => 'Team-Stimmung: Gemischte Signale von Team-Funks.';

  @override
  String get ai_sentiment_generic_positive => 'Team-Stimmung: Positive Energie im gesamten Paddock.';

  @override
  String get ai_sentiment_label => 'Team-Stimmung';

  @override
  String get ai_sentiment_mercedes_positive => 'Team-Stimmung: Stimmung bei Mercedes steigt nach Hamilton-Gridstrafe.';

  @override
  String get ai_strategist_tap_hint => 'Tippen, um Fragen zu stellen...';

  @override
  String get ai_strategist_title => 'AI Strategist';

  @override
  String get ai_prefs_section_title => 'AI Strategist';

  @override
  String get ai_prefs_section_subtitle => 'Passen Sie die AI-Strategist-Karte auf dem Startbildschirm an.';

  @override
  String get ai_prefs_disable_card => 'AI-Strategist-Karte deaktivieren';

  @override
  String get ai_prefs_hide_teambattle => 'Teammate Battle ausblenden';

  @override
  String get ai_prefs_hide_teambattle_hint => 'Teamkollegen-Vergleich ausblenden, wenn die Karte sichtbar ist.';

  @override
  String get ai_prefs_hide_coach_corner => 'Coach\'\'s Corner ausblenden';

  @override
  String get ai_prefs_hide_coach_corner_hint => 'Coaching-Tipps ausblenden, wenn die Karte sichtbar ist.';

  @override
  String get ai_prefs_hide_team_vibe => 'Team Vibe ausblenden';

  @override
  String get ai_prefs_hide_team_vibe_hint => 'Stimmung ausblenden, wenn die Karte sichtbar ist.';

  @override
  String get ai_supported_commands => 'Unterstützte Befehle: Fetch latest results, Show next weekend, Compare name1 vs name2, Show form [driver], Show driver standings, Show team standings, Open driver [name], Open team [name], Show drivers chart, Show latest penalties, Show latest race control.';

  @override
  String ai_team_compare_ready(String left, String right) {
    return 'Teamvergleich ist bereit für $left und $right.';
  }

  @override
  String ai_team_profile_ready(String team) {
    return 'Teamprofil bereit für $team.';
  }

  @override
  String ai_team_standings_summary(String year, String summary) {
    return 'Konstrukteurswertung $year: $summary';
  }

  @override
  String get ai_teammate_battle => 'Teamgenossen-Duell';

  @override
  String ai_teammate_insight(String driver, String teammate) {
    return '$driver ist auf dieser Strecke traditionell stärker in der Qualifikation, während $teammate in Reifenschonung glänzt.';
  }

  @override
  String get ai_type_command => 'Befehl eingeben...';

  @override
  String ai_weather_effect(String pct, String driver, String pct2) {
    return 'Bei $pct% Regen: Podium-Chance für $driver steigt um $pct2% durch starke Regen-Pace.';
  }

  @override
  String ai_weather_effect_at(String pct, String insight) {
    return 'Bei $pct% Regen: $insight';
  }

  @override
  String get ai_weather_insight_alonso => 'Podium-Chance für Alonso steigt um 15% dank überlegenem Pace in der Nässe.';

  @override
  String get ai_weather_insight_generic => 'Nasse Bedingungen begünstigen starke Regen-Spezialisten.';

  @override
  String get air_temperature => 'Lufttemperatur';

  @override
  String get all_scopes => 'Alle Scopes';

  @override
  String get app_title => 'F1 Hub';

  @override
  String get average_speed => 'Durchschnittsgeschwindigkeit';

  @override
  String get avg_finish => 'Ø Ziel';

  @override
  String get avg_finish_l5 => 'Ø Ziel (L5)';

  @override
  String get avg_gforce => 'Ø G-Kraft';

  @override
  String get avg_lap => 'Durchschnittsrunde';

  @override
  String get best_combination => 'Beste Kombination';

  @override
  String get best_lap => 'Beste Runde';

  @override
  String get birth_place => 'Geburtsort';

  @override
  String get cache_cleared => 'Cache erfolgreich geleert!';

  @override
  String car_label(String number) {
    return 'Auto $number';
  }

  @override
  String get career_stats => 'Karrierestatistiken';

  @override
  String get cc_wins => 'Konstrukteursmeisterschaften';

  @override
  String get championship_progression => 'Meisterschaftsverlauf';

  @override
  String get championships => 'Weltmeistertitel';

  @override
  String get calendar_prefs_section_title => 'Kalender';

  @override
  String get calendar_prefs_section_subtitle => 'Streckenkalender anpassen.';

  @override
  String get calendar_prefs_hide_cancelled => 'Platzhalter-Rennen ausblenden';

  @override
  String get calendar_prefs_hide_cancelled_hint => 'Abgesagte oder Platzhalter-Rennen ausblenden, die nicht im echten Kalender stehen.';

  @override
  String get changelog => 'Changelog';

  @override
  String get characteristics => 'STRECKENMERKMALE';

  @override
  String get chart_no_data => 'Für diese Saison sind keine Diagrammdaten verfügbar.';

  @override
  String get children => 'Kinder';

  @override
  String get circuit => 'Strecke';

  @override
  String get circuit_difficulty => 'Streckenschwierigkeit';

  @override
  String get circuit_info => 'Streckeninfo';

  @override
  String get circuit_layout => 'Streckenlayout';

  @override
  String get circuits => 'Strecken';

  @override
  String get city => 'Stadt';

  @override
  String get clear_cache => 'Cache leeren';

  @override
  String get close => 'Schließen';

  @override
  String get compare => 'Vergleichen';

  @override
  String get compare_overall => 'Gesamt';

  @override
  String get compare_season => 'Pro Saison';

  @override
  String get compare_season_unavailable => 'Saisondaten sind für diesen Vergleich nicht verfügbar.';

  @override
  String get compare_year => 'Saison';

  @override
  String get contract_until => 'Vertrag bis';

  @override
  String get country => 'Land';

  @override
  String get country_australia => 'Australien';

  @override
  String get country_austria => 'Österreich';

  @override
  String get country_azerbaijan => 'Aserbaidschan';

  @override
  String get country_bahrain => 'Bahrain';

  @override
  String get country_belgium => 'Belgien';

  @override
  String get country_brazil => 'Brasilien';

  @override
  String get country_canada => 'Kanada';

  @override
  String get country_china => 'China';

  @override
  String get country_hungary => 'Ungarn';

  @override
  String get country_italy => 'Italien';

  @override
  String get country_japan => 'Japan';

  @override
  String get country_mexico => 'Mexiko';

  @override
  String get country_monaco => 'Monaco';

  @override
  String get country_netherlands => 'Niederlande';

  @override
  String get country_qatar => 'Katar';

  @override
  String get country_saudi_arabia => 'Saudi-Arabien';

  @override
  String get country_singapore => 'Singapur';

  @override
  String get country_spain => 'Spanien';

  @override
  String get country_uae => 'VAE';

  @override
  String get country_uk => 'Großbritannien';

  @override
  String get country_usa => 'USA';

  @override
  String get current_team => 'Aktuelles Team';

  @override
  String get date => 'Datum';

  @override
  String get day => 'Tag';

  @override
  String get days => 'Tage';

  @override
  String get dc_wins => 'Fahrermeisterschaften';

  @override
  String get distance_to_turn1 => 'Distanz bis Kurve 1';

  @override
  String get dnf => 'Nicht ins Ziel gekommen (DNF)';

  @override
  String get dnf_percentage => 'DNF %';

  @override
  String get dnqs => 'Nicht qualifiziert';

  @override
  String get driver => 'Fahrer';

  @override
  String get driver_facts_title => 'Fakten & Trivia';

  @override
  String get driver_history => 'Historie (letzte 5 Jahre)';

  @override
  String get drivers => 'Fahrer';

  @override
  String get drivers_chart => 'Fahrerdiagramm';

  @override
  String get dsqs => 'Disqualifiziert';

  @override
  String get engine => 'Motor';

  @override
  String get engine_name => 'Motorname';

  @override
  String get engine_supplier => 'Motorenlieferant';

  @override
  String get experience => 'Erfahrung';

  @override
  String get f1_debut => 'F1-Debüt';

  @override
  String get fastest_lap => 'Schnellste Runde';

  @override
  String get fastest_lap_rate => 'Schnellste-Runde-Quote %';

  @override
  String get fastest_laps => 'Schnellste Runden';

  @override
  String get fastest_pit => 'Schnellster Boxenstopp';

  @override
  String get favorite_circuit => 'Favoriten-Strecke';

  @override
  String get favorite_driver => 'Favoriten-Fahrer';

  @override
  String get favorite_team => 'Favoriten-Team';

  @override
  String get finish => 'Ziel';

  @override
  String get fp1 => 'Freies Training 1';

  @override
  String get fp2 => 'Freies Training 2';

  @override
  String get fp3 => 'Freies Training 3';

  @override
  String get front_row_starts => 'Starts aus der ersten Reihe';

  @override
  String get fullscreen_table => 'Tabelle im Vollbild';

  @override
  String get gap => 'Abstand';

  @override
  String get general => 'Allgemein';

  @override
  String get gp_abu_dhabi_grand_prix => 'Großer Preis von Abu Dhabi';

  @override
  String get gp_australian_grand_prix => 'Großer Preis von Australien';

  @override
  String get gp_austrian_grand_prix => 'Großer Preis von Österreich';

  @override
  String get gp_azerbaijan_grand_prix => 'Großer Preis von Aserbaidschan';

  @override
  String get gp_bahrain_grand_prix => 'Großer Preis von Bahrain';

  @override
  String get gp_barcelona_grand_prix => 'Großer Preis von Barcelona';

  @override
  String get gp_belgian_grand_prix => 'Großer Preis von Belgien';

  @override
  String get gp_british_grand_prix => 'Großer Preis von Großbritannien';

  @override
  String get gp_canadian_grand_prix => 'Großer Preis von Kanada';

  @override
  String get gp_chinese_grand_prix => 'Großer Preis von China';

  @override
  String get gp_dutch_grand_prix => 'Großer Preis der Niederlande';

  @override
  String get gp_hungarian_grand_prix => 'Großer Preis von Ungarn';

  @override
  String get gp_italian_grand_prix => 'Großer Preis von Italien';

  @override
  String get gp_japanese_grand_prix => 'Großer Preis von Japan';

  @override
  String get gp_las_vegas_grand_prix => 'Großer Preis von Las Vegas';

  @override
  String get gp_mexico_city_grand_prix => 'Großer Preis von Mexiko-Stadt';

  @override
  String get gp_miami_grand_prix => 'Großer Preis von Miami';

  @override
  String get gp_monaco_grand_prix => 'Großer Preis von Monaco';

  @override
  String get gp_qatar_grand_prix => 'Großer Preis von Katar';

  @override
  String get gp_s_o_paulo_grand_prix => 'Großer Preis von São Paulo';

  @override
  String get gp_saudi_arabian_grand_prix => 'Großer Preis von Saudi-Arabien';

  @override
  String get gp_singapore_grand_prix => 'Großer Preis von Singapur';

  @override
  String get gp_spanish_grand_prix => 'Großer Preis von Spanien';

  @override
  String get gp_united_states_grand_prix => 'Großer Preis der USA';

  @override
  String get hard_tire => 'Hart';

  @override
  String get hat_tricks => 'Hat-Tricks';

  @override
  String get headquarters => 'Hauptsitz';

  @override
  String get height => 'Größe';

  @override
  String get help_and_ideas => 'Hilfe & Ideen';

  @override
  String get hide_all => 'Keine';

  @override
  String get highest_finish => 'Bestes Ergebnis';

  @override
  String get highest_grid => 'Beste Startposition';

  @override
  String get hours => 'Stunden';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get language => 'Sprache';

  @override
  String get language_chooser => 'Deutsch';

  @override
  String get language_selector => 'Deutsch';

  @override
  String lap_label(String lap) {
    return 'Runde $lap';
  }

  @override
  String get lap_speed_stats => 'RUNDEN & GESCHWINDIGKEIT';

  @override
  String get laps => 'Runden';

  @override
  String get laps_led => 'Geführte Runden';

  @override
  String get last_5_points => 'Letzte 5 Punkte';

  @override
  String get last_podium_prefs_section_title => 'Letztes Podium';

  @override
  String get last_podium_prefs_section_subtitle => 'Wie viele der letzten Rennen auf Streckenkarten zeigen.';

  @override
  String get last_podium_prefs_races_label => 'Anzahl Rennen';

  @override
  String get last_winner => 'Sieger vom Vorjahr';

  @override
  String get length => 'Länge';

  @override
  String get level_1 => 'Sehr leicht';

  @override
  String get level_2 => 'Leicht';

  @override
  String get level_3 => 'Mittel';

  @override
  String get level_4 => 'Schwer';

  @override
  String get level_5 => 'Sehr schwer';

  @override
  String linked_update_many(String count) {
    return '$count verknüpfte Updates';
  }

  @override
  String get linked_update_one => '1 verknüpftes Update';

  @override
  String get live_leaderboard => 'Rangliste';

  @override
  String get live_switch_test => 'Zu Testdaten wechseln';

  @override
  String get live_teammate_battle => 'Teamkollegen-Duell';

  @override
  String get live_timing_title => 'Live Timing';

  @override
  String get live_waiting => 'Warten auf Live-Daten...';

  @override
  String get loading => 'Laden';

  @override
  String get logged_in => 'Sie sind angemeldet';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get manager => 'Manager';

  @override
  String get max_g_force => 'Max. G-Kraft';

  @override
  String get medium_tire => 'Medium';

  @override
  String get minutes => 'Minuten';

  @override
  String get name => 'Name';

  @override
  String get nat_argentine => 'Argentinisch';

  @override
  String get nat_australian => 'Australisch';

  @override
  String get nat_brazilian => 'Brasilianisch';

  @override
  String get nat_british => 'Britisch';

  @override
  String get nat_canadian => 'Kanadisch';

  @override
  String get nat_dutch => 'Niederländisch';

  @override
  String get nat_finnish => 'Finnisch';

  @override
  String get nat_french => 'Französisch';

  @override
  String get nat_german => 'Deutsch';

  @override
  String get nat_italian => 'Italienisch';

  @override
  String get nat_japanese => 'Japanisch';

  @override
  String get nat_mexican => 'Mexikanisch';

  @override
  String get nat_monegasque => 'Monegassisch';

  @override
  String get nat_new_zealander => 'Neuseeländisch';

  @override
  String get nat_spanish => 'Spanisch';

  @override
  String get nat_thai => 'Thailändisch';

  @override
  String get nationality => 'Nationalität';

  @override
  String get next_race => 'Nächstes Rennen';

  @override
  String get no_data_yet => 'Daten noch nicht verfügbar oder API noch nicht aktualisiert';

  @override
  String get no_finish_data => 'Keine Ziel-Daten';

  @override
  String get no_race_results_available => 'Noch kein Rennergebnis verfügbar.';

  @override
  String get one_two => '1-2-Finishes';

  @override
  String get overtakes => 'Überholmanöver';

  @override
  String get overtaking_difficulty => 'Überholschwierigkeit';

  @override
  String get partner => 'Partner/in';

  @override
  String get penalties => 'Strafen';

  @override
  String get penalties_empty => 'Keine Strafen im aktuellen Wochenend-Cache gefunden.';

  @override
  String get penalty => 'Strafe';

  @override
  String get personal_info => 'Persönliche Infos';

  @override
  String get personal_sponsors => 'Persönliche Sponsoren';

  @override
  String get pets => 'Haustiere';

  @override
  String get pitstop_leadership => 'Boxenstopp & Führung';

  @override
  String get placeholder_page => 'Neue Seite';

  @override
  String get placeholder_page_empty => 'Diese Seite ist noch leer.';

  @override
  String get podiums => 'Podien';

  @override
  String get points => 'Punkte';

  @override
  String get points_after_each_race => 'Stand nach jedem Rennen';

  @override
  String get points_history => 'Punkte pro Saison';

  @override
  String get points_per_entry => 'Punkte / Einsatz';

  @override
  String get points_per_start => 'Punkte / Start';

  @override
  String get points_progression => 'Punkteverlauf';

  @override
  String get pole_rate => 'Pole-Quote %';

  @override
  String get poles => 'Pole-Positions';

  @override
  String get pos => 'Pos';

  @override
  String get pressure => 'Druck';

  @override
  String get previous_teams => 'Teams';

  @override
  String get previous_winners => 'Frühere Sieger';

  @override
  String get profile => 'Profil';

  @override
  String get pts => 'PTS';

  @override
  String get q1_out => 'Q1 raus';

  @override
  String get q2_out => 'Q2 raus';

  @override
  String get qualifying => 'Qualifying';

  @override
  String get race => 'Rennen';

  @override
  String get race_control => 'Race Control';

  @override
  String get race_control_detail => 'Race-Control-Detail';

  @override
  String get race_control_empty => 'Keine Race-Control-Nachrichten für diesen Filter oder diese Suche gefunden.';

  @override
  String get race_control_filter_alerts => 'Warnungen';

  @override
  String get race_control_filter_all => 'Alle';

  @override
  String get race_control_filter_stewards => 'Streckenposten';

  @override
  String race_control_message_count(String visible, String total) {
    return '$visible von $total Nachrichten';
  }

  @override
  String get race_control_no_linked_message => 'Keine verknüpfte Steward-Nachricht gefunden.';

  @override
  String get race_control_related_updates => 'Zugehörige Steward-Updates';

  @override
  String get race_control_relation_investigation => 'Untersuchung';

  @override
  String get race_control_relation_issued_earlier => 'Früher verhängt';

  @override
  String get race_control_relation_linked => 'Verknüpfte Nachricht';

  @override
  String get race_control_relation_message => 'Race-Control-Nachricht';

  @override
  String get race_control_relation_noted => 'Zur Kenntnis genommen';

  @override
  String get race_control_relation_outcome => 'Ergebnis';

  @override
  String get race_control_relation_penalty_message => 'Strafnachricht';

  @override
  String get race_control_relation_served_later => 'Später abgesessen';

  @override
  String get race_control_relation_served_penalty => 'Abgesessene Strafe';

  @override
  String get race_control_search_hint => 'Suche nach Nachricht, Flagge, Kategorie, Runde oder Fahrer';

  @override
  String get race_stats => 'Rennstatistiken';

  @override
  String get rain => 'Regen';

  @override
  String get rain_chance => 'Regenwahrscheinlichkeit';

  @override
  String get rainfall => 'Niederschlag';

  @override
  String get red_flag => 'Wahrscheinlichkeit rote Flagge';

  @override
  String get reserve_driver => 'Ersatzfahrer';

  @override
  String get result => 'Ergebnis';

  @override
  String get results => 'Ergebnisse';

  @override
  String get retirements => 'Ausfälle';

  @override
  String get risks => 'Risiken';

  @override
  String get risks_incidents => 'RISIKEN & VORFÄLLE';

  @override
  String get round_short => 'R';

  @override
  String get scope => 'Umfang';

  @override
  String get season_2026 => '2026 Saison';

  @override
  String get select_drivers_to_compare => '2 Fahrer auswählen';

  @override
  String get select_favorite => 'Auswählen...';

  @override
  String get select_teams_to_compare => '2 Teams auswählen';

  @override
  String get session => 'Sitzung';

  @override
  String session_data_unavailable(String session) {
    return '$session-Daten werden geladen oder sind noch nicht verfügbar.';
  }

  @override
  String get session_future => 'Sitzung beginnt um';

  @override
  String get session_results => 'Sitzungsergebnisse';

  @override
  String get session_status_completed => 'Abgeschlossen';

  @override
  String get session_status_live_recent => 'Live / Kürzlich';

  @override
  String get session_status_upcoming => 'Bevorstehend';

  @override
  String session_weather_unavailable(String session) {
    return 'Keine Wetterdaten verfügbar für $session.';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get show_all => 'Alle';

  @override
  String show_all_messages(String count) {
    return 'Alle $count Nachrichten anzeigen';
  }

  @override
  String get show_less_messages => 'Weniger Nachrichten anzeigen';

  @override
  String get since => 'Im Kalender seit';

  @override
  String get slowest_lap => 'Langsamste Runde';

  @override
  String get soft_tire => 'Weich';

  @override
  String get sponsors => 'Sponsoren';

  @override
  String get sprint => 'Sprint';

  @override
  String get sprint_quali => 'Sprint-Qualifying';

  @override
  String get standings => 'Wertungen';

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
  String get strategy_1_stop => '1 Stopp';

  @override
  String get strategy_2_stops => '2 Stopps';

  @override
  String get strategy_3_stops => '3 Stopps';

  @override
  String get summer_break => 'Sommerpause';

  @override
  String get summer_break_subtitle => 'Die Sommerpause liegt zwischen Ungarn und den Niederlanden.';

  @override
  String get team_facts_title => 'Wusstest du schon?';

  @override
  String get team_history => 'Teamhistorie';

  @override
  String get team_principal => 'Teamchef';

  @override
  String get team_theme => 'Team-Design';

  @override
  String get teams => 'Teams';

  @override
  String get teams_chart => 'Teamdiagramm';

  @override
  String get technical_director => 'Technischer Direktor';

  @override
  String get temp => 'Temperatur';

  @override
  String get theme_mode => 'Darstellungsmodus';

  @override
  String get theme_mode_dark => 'Dunkel';

  @override
  String get theme_mode_light => 'Hell';

  @override
  String get theme_mode_system => 'System';

  @override
  String get time => 'Zeit';

  @override
  String get time_gap => 'Zeit / Abstand';

  @override
  String get tire_wear => 'Reifenverschleiß';

  @override
  String get toggle_theme => 'Design wechseln';

  @override
  String get top_10 => 'Top 10';

  @override
  String get top_3 => 'Top 3';

  @override
  String get top_5 => 'Top 5';

  @override
  String get top_speed => 'Höchstgeschwindigkeit';

  @override
  String get total_entries => 'Gesamteinsätze';

  @override
  String get total_length => 'Gesamtlänge';

  @override
  String get total_points => 'Gesamtpunkte';

  @override
  String get total_time => 'Gesamtzeit';

  @override
  String get track_flag_double_yellow => 'Doppelt gelb';

  @override
  String get track_flag_green => 'Grüne Flagge';

  @override
  String get track_flag_red => 'Rote Flagge';

  @override
  String get track_flag_yellow => 'Gelbe Flagge';

  @override
  String get track_playback_dry_track => 'Trockene Strecke';

  @override
  String get track_playback_interpolated_minute => 'interpolierte Minute';

  @override
  String get track_playback_no_weather => 'Für diese Sitzung sind keine Wetterdaten verfügbar.';

  @override
  String get track_playback_rain_active => 'Regen aktiv';

  @override
  String get track_playback_recorded_sample => 'aufgezeichnetes Sample';

  @override
  String get track_playback_title => 'Track Playback';

  @override
  String get track_playback_unknown_sample => 'Unbekanntes Sample';

  @override
  String get track_temperature => 'Streckentemperatur';

  @override
  String get turn1_accident => 'Unfallwahrscheinlichkeit Kurve 1';

  @override
  String get tyre => 'Reifen';

  @override
  String get tyres => 'Reifen';

  @override
  String get tyres_strategy => 'REIFEN & STRATEGIE';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get unknown_sample => 'Unbekannt';

  @override
  String get unknown_time => 'Unbekannte Zeit';

  @override
  String get until => 'Vertrag bis';

  @override
  String get used_tyre => 'gebraucht';

  @override
  String get using_fallback_data => 'Offline-/Fallback-Daten werden verwendet.';

  @override
  String get version => 'Version';

  @override
  String get vsc => 'Wahrscheinlichkeit VSC';

  @override
  String get wear_high => 'Hoch';

  @override
  String get wear_low => 'Niedrig';

  @override
  String get wear_medium => 'Mittel';

  @override
  String get weather_forecast => 'Wettervorhersage';

  @override
  String get week => 'Woche';

  @override
  String get weekend_hub => 'Wochenend-Hub';

  @override
  String get weekend_hub_card_subtitle => 'Zeitplan, Wetter, Podium und Strafen auf einem Screen';

  @override
  String get weekend_hub_load_error => 'Wochenend-Hub konnte nicht vollständig geladen werden. Zwischengespeicherte Daten werden angezeigt.';

  @override
  String get weekend_hub_loading => 'Wochenend-Hub wird geladen...';

  @override
  String get weekend_schedule => 'Wochenend-Zeitplan';

  @override
  String get weeks => 'Wochen';

  @override
  String get win_rate => 'Siegquote %';

  @override
  String get wind => 'Wind';

  @override
  String get wind_speed => 'Windgeschwindigkeit';

  @override
  String get wins => 'Siege';

  @override
  String get ai_fab_label => 'AI';

  @override
  String auth_error_message(String message) {
    return '$message';
  }

  @override
  String get calendar_race_status_cancelled => 'Abgesagt';

  @override
  String get calendar_race_status_ended => 'Beendet';

  @override
  String get calendar_race_status_ongoing => 'Laufend';

  @override
  String get circuit_open_in_maps => 'In Maps öffnen';

  @override
  String live_timing_air_temp_abbr(String temp) {
    return 'A $temp';
  }

  @override
  String get live_timing_banner_green => 'GREEN';

  @override
  String get live_timing_banner_red_flag => 'ROTE FLAGGE';

  @override
  String get live_timing_banner_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_banner_vsc_deployed => 'VSC AKTIV';

  @override
  String get live_timing_banner_vsc_ending => 'VSC ENDE';

  @override
  String get live_timing_banner_yellow_flag => 'GELBE FLAGGE';

  @override
  String get live_timing_chip_red_flag => 'ROTE FLAGGE';

  @override
  String get live_timing_chip_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_chip_vsc => 'VSC';

  @override
  String get live_timing_chip_vsc_end => 'VSC ENDE';

  @override
  String get live_timing_chip_yellow => 'GELB';

  @override
  String live_timing_data_source(String source) {
    return 'Quelle: $source';
  }

  @override
  String get live_timing_demo_session_title => 'Silverstone 2024';

  @override
  String get live_timing_driver_out => 'OUT';

  @override
  String get live_timing_driver_pit => 'PIT';

  @override
  String get live_timing_header_driver => 'FAHRER';

  @override
  String get live_timing_header_gain => 'DIFF';

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
  String get live_timing_header_tyre => 'REIFEN';

  @override
  String get live_timing_hub_timestamp_tooltip => 'Zeitstempel der letzten Nachricht (Stream)';

  @override
  String live_timing_lap_of_total(String current, String total) {
    return 'Runde $current / $total';
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
    return 'News konnten nicht geladen werden: $error';
  }

  @override
  String get news_title => 'F1 News';

  @override
  String get race_results_empty => 'Noch keine Rennergebnisse verfügbar.';

  @override
  String get secure_page_authorized => 'Sie sind berechtigt!';

  @override
  String get secure_page_title => 'Geschützte Seite';

  @override
  String team_comparison_title(String team1, String team2) {
    return '$team1 vs $team2';
  }

  @override
  String get unauthorized_page_message => 'Sie sind nicht berechtigt, diese Seite anzuzeigen.';

  @override
  String get unauthorized_page_title => 'Nicht autorisiert';
}
