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
  String get best_tyre_combination => 'Beste Reifenkombination';

  @override
  String get cfield_air_pressure_hpa => 'Luftdruck';

  @override
  String get cfield_asphalt_grip_score => 'Asphalt-Grip-Score';

  @override
  String get cfield_avg_g_force => 'Durchschnittliche G-Kraft';

  @override
  String get cfield_avg_time_2024_2025 => 'Ø Rundenzeit (2024–25)';

  @override
  String get cfield_brake_cooling_requirement_score => 'Bremskühlungs-Anforderung';

  @override
  String get cfield_circuit_director => 'Streckendirektor';

  @override
  String get cfield_circuit_owner => 'Streckenbesitzer';

  @override
  String get cfield_contract_until => 'Vertrag bis';

  @override
  String get cfield_deployment_focus => 'Fokus Energieeinsatz';

  @override
  String get cfield_direction => 'Richtung';

  @override
  String get cfield_distance_to_t1 => 'Abstand bis Kurve 1';

  @override
  String get cfield_electrical_ratio => 'Elektrischer Anteil';

  @override
  String get cfield_energy_flow_strategy => 'Energiefluss-Strategie';

  @override
  String get cfield_engine_derating_risk => 'Motor-Derating-Risiko';

  @override
  String get cfield_era_delta => 'Ära-Delta';

  @override
  String get cfield_est_time_2026 => 'Geschätzte Rundenzeit (2026)';

  @override
  String get cfield_elevation_sea_level => 'Höhe (Meeresspiegel)';

  @override
  String get cfield_harvest_difficulty => 'Rekuperations-Schwierigkeit';

  @override
  String get cfield_harvesting_zones => 'Rekuperations-Zonen';

  @override
  String get cfield_latitude => 'Breitengrad';

  @override
  String get cfield_local_time_zone => 'Lokale Zeitzone';

  @override
  String get cfield_longitude => 'Längengrad';

  @override
  String get cfield_lap_record_detail => 'Rundenrekord';

  @override
  String get cfield_laps => 'Runden';

  @override
  String get cfield_lateral_stress_score => 'Seitliche Belastungs-Score';

  @override
  String get cfield_length => 'Länge';

  @override
  String get cfield_manual_override_energy_cost => 'Energiekosten manueller Override';

  @override
  String get cfield_manual_override_points => 'Manuelle Override-Punkte';

  @override
  String get cfield_max_elevation_change => 'Max. Höhenunterschied';

  @override
  String get cfield_max_g_force => 'Max. G-Kraft';

  @override
  String get cfield_override_impact_score => 'Override-Impact-Score';

  @override
  String get cfield_on_calendar_since => 'Im Kalender seit';

  @override
  String get cfield_overtaking_delta => 'Überhol-Delta';

  @override
  String get cfield_pit_exit_delta => 'Boxenausfahrts-Delta';

  @override
  String get cfield_pitstop_record_detail => 'Boxenstopp-Rekord';

  @override
  String get cfield_race_day_capacity => 'Zuschauerkapazität (Rennsonntag)';

  @override
  String get cfield_rain_chance => 'Regenwahrscheinlichkeit';

  @override
  String get cfield_recovery_points => 'Recovery-Punkte';

  @override
  String get cfield_red_flag_prob => 'Rote-Flagge-Wahrscheinlichkeit';

  @override
  String get cfield_s1 => 'Sektor 1';

  @override
  String get cfield_s2 => 'Sektor 2';

  @override
  String get cfield_s3 => 'Sektor 3';

  @override
  String get cfield_safety_car_prob => 'Safety-Car-Wahrscheinlichkeit';

  @override
  String get cfield_safety_car_window_laps => 'Safety-Car-Fenster (Runden)';

  @override
  String get cfield_straight_mode_zones => 'Straight-Mode-Zonen';

  @override
  String get cfield_sun_angle_start => 'Sonnenstand beim Start';

  @override
  String get cfield_t1_accident_risk => 'Unfallrisiko Kurve 1';

  @override
  String get cfield_temperature_c => 'Temperatur';

  @override
  String get cfield_top_speed => 'Höchstgeschwindigkeit';

  @override
  String get cfield_top_speed_delta => 'Höchstgeschwindigkeits-Delta';

  @override
  String get cfield_track_evolution => 'Streckenevolution';

  @override
  String get cfield_track_type => 'Streckentyp';

  @override
  String get cfield_tyre_physics => 'Reifenphysik';

  @override
  String get cfield_tyre_working_window_c => 'Reifen-Arbeitsfenster';

  @override
  String get cfield_undercut_potential_score => 'Undercut-Potenzial';

  @override
  String get cfield_utc_offset => 'UTC-Offset';

  @override
  String get cfield_vsc_prob => 'VSC-Wahrscheinlichkeit';

  @override
  String get cfield_wind_sensitivity_sector => 'Windempfindlichkeit (Sektor)';

  @override
  String get cfield_x_mode_usage => 'X-Mode-Nutzung';

  @override
  String get cfield_z_mode_activation_delay => 'Z-Mode-Aktivierungsverzögerung';

  @override
  String get cfield_z_mode_usage => 'Z-Mode-Nutzung';

  @override
  String get cfield_zone_name => 'Zeitzonenname';

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
  String get championship_leader_pill => 'WM-Führender';

  @override
  String get calendar_prefs_section_title => 'Kalender';

  @override
  String get calendar_prefs_section_subtitle => 'Streckenkalender anpassen.';

  @override
  String get calendar_prefs_hide_cancelled => 'Platzhalter-Rennen ausblenden';

  @override
  String get calendar_prefs_hide_cancelled_hint => 'Abgesagte oder Platzhalter-Rennen ausblenden, die nicht im echten Kalender stehen.';

  @override
  String get cat_ambient_stats => 'Umgebungsbedingungen';

  @override
  String get cat_history_comparison => 'Ära-Vergleich';

  @override
  String get cat_risks_stats => 'Performance & Risiko';

  @override
  String get cat_tech_2026 => 'Technik & Aero 2026';

  @override
  String get cat_track_specs => 'Streckengeometrie';

  @override
  String get display_prefs_section_title => 'Anzeige';

  @override
  String get display_prefs_section_subtitle => 'Aussehen und Animationen. Angemeldet werden die Einstellungen mit dem Konto synchronisiert.';

  @override
  String get display_prefs_ui_mode => 'Oberflächenstil';

  @override
  String get display_prefs_mode_standard => 'Standard';

  @override
  String get display_prefs_mode_standard_hint => 'Glas-Unschärfe und weiche Schatten.';

  @override
  String get display_prefs_mode_simple => 'Einfach';

  @override
  String get display_prefs_mode_simple_hint => 'Flache Flächen und stärkerer Kontrast.';

  @override
  String get display_prefs_compact => 'Kompakter Modus';

  @override
  String get display_prefs_compact_hint => 'Engerer Abstand und kleinere Karten.';

  @override
  String get display_prefs_motion_reduced => 'Reduzierte Bewegung';

  @override
  String get display_prefs_motion_reduced_hint => 'Weniger Animation, Unschärfe und Themenübergänge.';

  @override
  String get display_prefs_saving => 'Speichern…';

  @override
  String get my_paddock_title => 'Meine Box';

  @override
  String get my_paddock_session_unknown => 'Live-Timing';

  @override
  String my_paddock_resume_subtitle(String session, String lap) {
    return 'Fortsetzen: $session — Frame $lap';
  }

  @override
  String get my_paddock_favorite_drivers => 'Lieblingsfahrer';

  @override
  String get my_paddock_favorite_teams => 'Lieblingsteams';

  @override
  String get my_paddock_last_race => 'Letztes Rennen';

  @override
  String my_paddock_last_race_summary(String date, String podium) {
    return '$date · $podium';
  }

  @override
  String get my_paddock_points_suffix => 'Pkt.';

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
  String get circuit_difficulty_l10n => 'Streckenschwierigkeit';

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
  String get diff_easy => 'Sehr leicht';

  @override
  String get diff_extreme => 'Extrem';

  @override
  String get diff_hard => 'Schwer';

  @override
  String get diff_high => 'Hoch';

  @override
  String get diff_low => 'Niedrig';

  @override
  String get diff_medium => 'Mittel';

  @override
  String get dir_clockwise => 'Im Uhrzeigersinn';

  @override
  String get dir_counter_clockwise => 'Gegen den Uhrzeigersinn';

  @override
  String get dir_figure_eight => 'Achterbahn-Layout';

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
  String get feature_130r_high_speed => 'Ikone 130R Hochgeschwindigkeits-Linkskurve';

  @override
  String get feature_90_degree_corners => 'Aufeinanderfolgende 90°-Kurven (Stadtkurs)';

  @override
  String get feature_abrasive_asphalt => 'Stark abrasiver Asphalt';

  @override
  String get feature_aggressive_kerbs => 'Risiko aggressive sausage curbs';

  @override
  String get feature_aero_efficiency_test => 'Ultimativer Test aerodynamischer Effizienz';

  @override
  String get feature_banked_corners_t3_t14 => 'Einzigartige überhöhte Kurven (T3 & T14)';

  @override
  String get feature_battery_drain_kemmel => 'Hoher Batterieverbrauch (Kemmel-Gerade)';

  @override
  String get feature_blind_corners => 'Gefährliche blinde Apexes';

  @override
  String get feature_bumpy_city_roads => 'Stark unebene Stadtfahrbahn';

  @override
  String get feature_bumpy_surface => 'Unebene Streckenoberfläche';

  @override
  String get feature_bumpy_surface_subsidence => 'Unebenheiten durch Bodensenkung';

  @override
  String get feature_castle_section_tight => 'Ultraenge Schloss-Sektion';

  @override
  String get feature_cold_tire_struggle => 'Schwierigkeiten, Reifenwärme zu halten';

  @override
  String get feature_curb_riding_chicane => 'Aggressives Chicane-Curb-Riding';

  @override
  String get feature_degner_curves => 'Präzise Degner-Kurven';

  @override
  String get feature_dusty_surface => 'Staubige Bedingungen zu Beginn';

  @override
  String get feature_eau_rouge_raidillon => 'Legendäre Eau Rouge-Raidillon';

  @override
  String get feature_esses_section_flow => 'Rhythmische Hochgeschwindigkeits-Essen';

  @override
  String get feature_extreme_altitude => 'Extreme Höhe (2200 m+)';

  @override
  String get feature_extreme_humidity => 'Drückende äquatoriale Feuchtigkeit';

  @override
  String get feature_extreme_low_drag => 'Extremes Low-Drag-Aero-Setup';

  @override
  String get feature_fastest_street_track => 'Schnellster Stadtkurs im Kalender';

  @override
  String get feature_figure_eight_layout => 'Einzigartiges Achterbahn-Layout';

  @override
  String get feature_glittering_night_race => 'Funkelndes Nachtrennen-Panorama';

  @override
  String get feature_groundhog_risk => 'Risiko durch Wild (Groundhogs)';

  @override
  String get feature_heavy_braking => 'Hohe Bremsanforderungen';

  @override
  String get feature_heavy_braking_variante => 'Hartes Anbremsen in Chicanes';

  @override
  String get feature_heavy_braking_zones => 'Harte Bremszonen in Chicanes';

  @override
  String get feature_heavy_traction_points => 'Kritische Traktionszonen nach langsamen Passagen';

  @override
  String get feature_high_altitude_cooling => 'Kühlung des Antriebsstrangs in großer Höhe';

  @override
  String get feature_high_altitude_impact => 'Deutlicher Aero-Einfluss durch Höhe';

  @override
  String get feature_high_downforce_focus => 'Maximale Priorität auf Abtrieb';

  @override
  String get feature_high_front_tyre_wear => 'Hoher Reifenverschleiß an der Vorderachse';

  @override
  String get feature_high_humidity => 'Hohe Umgebungsfeuchtigkeit';

  @override
  String get feature_high_kerb_usage => 'Aggressives Mitnehmen der Curbs';

  @override
  String get feature_high_lateral_load => 'Intensive laterale g-Belastung';

  @override
  String get feature_high_speed_corners => 'Ultraschnelle Kurvenkombinationen';

  @override
  String get feature_high_speed_flow => 'Durchgehende Flow-Passagen in hoher Geschwindigkeit';

  @override
  String get feature_high_stamina_required => 'Hoher körperlicher Einsatz für den Fahrer';

  @override
  String get feature_high_wind_sensitivity => 'Extreme Empfindlichkeit gegen Seitenwind';

  @override
  String get feature_hotel_underpass => 'Einzigartige Unterführung unter dem Yas Hotel';

  @override
  String get feature_iconic_tunnel => 'Hochgeschwindigkeitstunnel am Hafen';

  @override
  String get feature_legendary_esses => 'Legendäre \'\'S\'\'-Kurven';

  @override
  String get feature_long_back_straight => 'Extrem lange Gerade auf der Gegenseite';

  @override
  String get feature_long_main_straight => 'Lange Vollgasphase bis Kurve 1';

  @override
  String get feature_longest_run_to_t1 => 'Längster Lauf von Start bis Kurve 1';

  @override
  String get feature_longest_straight => '2,2 km Vollgas-Gerade';

  @override
  String get feature_longest_track => 'Längste Strecke im Kalender';

  @override
  String get feature_low_grip_asphalt => 'Grip-armes semi-permanentes Asphaltband';

  @override
  String get feature_maggotts_becketts_flow => 'Maggotts-Becketts-Chapel-Flow';

  @override
  String get feature_micro_climates => 'Mehrere Mikroklimata auf der Strecke';

  @override
  String get feature_monaco_without_walls => 'Technischer \'\'Monaco-Style\'\'-Fluss';

  @override
  String get feature_multi_surface_grip => 'Wechselnder Grip auf mehreren Oberflächen';

  @override
  String get feature_multiple_overtaking_lines => 'Breite Strecke mit mehreren Linien';

  @override
  String get feature_narrow_passing_zones => 'Schmale Überholmöglichkeiten';

  @override
  String get feature_narrow_track_width => 'Schmale historische Streckenbreite';

  @override
  String get feature_new_straight_section => 'Überarbeiteter Hochgeschwindigkeits-Sektor 3';

  @override
  String get feature_old_school_track => 'Klassisches \'\'Old-School\'\'-Layout';

  @override
  String get feature_physical_exhaustion => 'Extreme körperliche Erschöpfung';

  @override
  String get feature_physical_heat_stress => 'Starke Hitzestress-Belastung';

  @override
  String get feature_precision_steering => 'Lenkpräzision im Millimeterbereich';

  @override
  String get feature_rollercoaster_ride => 'Achterbahn-Gefühl in hoher Geschwindigkeit';

  @override
  String get feature_sand_on_track => 'Risiko windgetriebenen Sands';

  @override
  String get feature_sand_wind_impact => 'Wüstensand und Wind-Buffeting';

  @override
  String get feature_sea_breeze_sand => 'Seebrise und Sandrisiko';

  @override
  String get feature_senna_s_curves => 'Legendärer \'\'Senna-S\'\'-Komplex';

  @override
  String get feature_short_lap_time => 'Extrem kurze Rundenzeit';

  @override
  String get feature_snail_corner_t1 => 'Technische \'\'Schnecken\'\'-Kurve 1';

  @override
  String get feature_stadium_atmosphere => 'Ikonische Stadion-Atmosphäre';

  @override
  String get feature_stadium_section => 'Ikonische Foro-Sol-Stadionpassage';

  @override
  String get feature_steep_uphill_braking => 'Steile Anstiegs-Bremszonen';

  @override
  String get feature_steep_uphill_t1 => 'Extremer Anstieg bis Kurve 1';

  @override
  String get feature_street_circuit => 'Temporäre Straßenoberfläche';

  @override
  String get feature_straight_mode_5_zones => '5 Straight-Mode-Zonen';

  @override
  String get feature_sunset_to_night => 'Übergang Dämmerung zu Nacht';

  @override
  String get feature_sweeping_corners => 'Schnelle, weit gefasste Sweeper';

  @override
  String get feature_technical_chicane => 'Präzise Chicane-Platzierung';

  @override
  String get feature_technical_final_sector => 'Enger, technischer Schlussektor';

  @override
  String get feature_technical_flow => 'Durchgehender rhythmischer Kurvenfluss';

  @override
  String get feature_technical_sector_2 => 'Technischer Mittelsektor';

  @override
  String get feature_temple_of_speed => 'Der ikonische \'\'Tempel der Geschwindigkeit\'\'';

  @override
  String get feature_the_strip_straight => 'Die riesige Las-Vegas-Strip-Gerade';

  @override
  String get feature_thin_air_cooling => 'Kühlherausforderungen durch dünne Luft';

  @override
  String get feature_tight_hairpin => 'Engste Haarnadelkurve';

  @override
  String get feature_tire_killer => 'Hohe laterale Reifenlast';

  @override
  String get feature_track_limits_chaos => 'Hohes Strafenrisiko bei Track Limits';

  @override
  String get feature_traction_limited => 'Traktionsbegrenzte Ausfahrten';

  @override
  String get feature_unpredictable_weather => 'Stark wechselhaftes Wetter';

  @override
  String get feature_unpredictable_weather_interlagos => 'Plötzliche Mikrostürme (Interlagos)';

  @override
  String get feature_uphill_start_finish => 'Steile Start-Ziel-Gerade bergauf';

  @override
  String get feature_variable_grip => 'Wechselnde Grip-Level';

  @override
  String get feature_wall_of_champions => 'Gefährliche \'\'Wall of Champions\'\'';

  @override
  String get feature_zero_margin_error => 'Kein Spielraum für Fehler';

  @override
  String get feature_zero_overtaking_space => 'Extrem begrenzter Überholraum';

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
  String get login_register_menu => 'Anmelden / Registrieren';

  @override
  String get login_page_title => 'Anmelden';

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
  String get overtaking_difficulty_l10n => 'Überholschwierigkeit';

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
  String get race_control_filter_penalties => 'Strafen';

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
  String get race_control_track_limits_strip => 'Track Limits — gestrichene Runden';

  @override
  String get race_control_steward_storyline => 'Steward-Fallverlauf';

  @override
  String get race_stats => 'Rennstatistiken';

  @override
  String get rain => 'Regen';

  @override
  String get rain_chance => 'Regenwahrscheinlichkeit';

  @override
  String get rainfall => 'Niederschlag';

  @override
  String get recommended_strategy_l10n => 'Strategie';

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
  String get sun_0_deg_night_race => 'Nachtbedingungen (Kunstlicht)';

  @override
  String get sun_5_deg_twilight => 'Dämmerung (Flutlicht aktiv)';

  @override
  String get sun_8_deg_horizon_dip => 'Nahe der Horizontlinie (extreme Blendung)';

  @override
  String get sun_10_deg_harbor_reflection => 'Sehr tiefstehende Sonne (Wasserreflexion)';

  @override
  String get sun_12_deg_mountain_occlusion => 'Tiefstehende Sonne (Bergenschatten)';

  @override
  String get sun_14_deg_stadium_shadows => 'Tiefstehende Sonne (Tribünenschatten)';

  @override
  String get sun_15_deg_sunset_blind => 'Tiefstehende Sonne (hohe Blendgefahr)';

  @override
  String get sun_18_deg_paddock_glare => 'Tiefstehende Sonne (Gebäudereflexionen)';

  @override
  String get sun_20_deg_desert_haze => 'Tiefstehende Sonne (Staub- und Dunstblendung)';

  @override
  String get sun_22_deg_coastal_mist => 'Tiefstehende Sonne (Diffusion durch Küstennebel)';

  @override
  String get sun_25_deg_morning_glow => 'Frühmorgensonne';

  @override
  String get sun_28_deg_dunes_glare => 'Tiefstehende Sonne (Dünenblendung)';

  @override
  String get sun_30_deg_low_winter_sun => 'Tiefstehende Wintersonne';

  @override
  String get sun_32_deg_urban_canyon => 'Mittlere Sonnenhöhe (Skyline-Schatten)';

  @override
  String get sun_35_deg_forest_shadows => 'Mittlere Sonnenhöhe (unterbrochene Schatten)';

  @override
  String get sun_40_deg_cloudy_diffuse => 'Diffuses Licht (bewölkt)';

  @override
  String get sun_45_deg_mid_afternoon => 'Mittags- und Nachmittagssonne';

  @override
  String get sun_50_deg_clear_sky => 'Klare Nachmittagssonne';

  @override
  String get sun_55_deg_bright_oval => 'Hohe Helligkeit (offene Strecke)';

  @override
  String get sun_60_deg_standard_day => 'Normales Tageslicht';

  @override
  String get sun_65_deg_high_noon => 'Hohe Sonne (Mittag)';

  @override
  String get sun_70_deg_equatorial_high => 'Intensive Sonneneinstrahlung';

  @override
  String get sun_75_deg_tropical_peak => 'Extreme Tropensonne';

  @override
  String get sun_85_deg_zenith => 'Sonne im Zenit (keine Schatten)';

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
  String get type_hybrid_street => 'Hybrid-Stadtkurs';

  @override
  String get type_permanent_circuit => 'Permanente Rennstrecke';

  @override
  String get type_street_circuit => 'Stadtkurs';

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
  String get weekend_hub_no_results_yet => 'Ergebnisse für diese Session sind noch nicht verfügbar oder wurden noch nicht synchronisiert.';

  @override
  String get weekend_hub_session_insights => 'Session-Einblicke';

  @override
  String get weekend_hub_fastest_sectors => 'Schnellste Sektoren';

  @override
  String get weekend_hub_sector_1_abbr => 'S1';

  @override
  String get weekend_hub_sector_2_abbr => 'S2';

  @override
  String get weekend_hub_sector_3_abbr => 'S3';

  @override
  String get weekend_hub_tyre_compound => 'Reifenmischung';

  @override
  String get weekend_hub_insights_sectors_unavailable => 'Sektordaten erfordern eine Live-OpenF1-Synchronisierung für dieses Rennen.';

  @override
  String get weekend_hub_penalties_filter_empty => 'Keine Straf- oder Untersuchungsmeldungen für diese Session.';

  @override
  String get weekend_hub_spot_placeholder_title => 'Live-Radar & DRS';

  @override
  String get weekend_hub_spot_placeholder_body => 'Wetterradar, Regenradar und eine DRS-Zonenübersicht erscheinen hier in einem zukünftigen Update.';

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
  String get circuit_go_home => 'Zur Startseite';

  @override
  String get circuit_not_found_message => 'Für diese Adresse liegen keine Streckendaten vor. Prüfen Sie den Link oder wählen Sie eine Strecke im Kalender.';

  @override
  String get circuit_not_found_title => 'Strecke nicht gefunden';

  @override
  String get circuit_open_in_maps => 'In Maps öffnen';

  @override
  String get circuit_stat_full_throttle => 'Vollgas';

  @override
  String circuit_weekend_hub_go(String venue) {
    return 'Zum $venue-Hub';
  }

  @override
  String get circuit_weekend_hub_no_data_tooltip => 'Noch keine Session-Daten verfügbar.';

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
  String get news_nav => 'News';

  @override
  String get news_empty => 'Zurzeit keine Artikel. Zum Aktualisieren nach unten ziehen.';

  @override
  String get news_feed_section_empty => 'Keine Artikel aus diesem Feed.';

  @override
  String get news_settings_title => 'News-Feeds';

  @override
  String get news_settings_subtitle => 'RSS- oder Atom-URLs hinzufügen. Sie werden im Tab News geladen (neueste zuerst).';

  @override
  String get news_settings_url_hint => 'https://beispiel.de/feed.xml';

  @override
  String get news_settings_add => 'Hinzufügen';

  @override
  String get news_settings_your_feeds => 'Deine Feeds';

  @override
  String get news_settings_no_feeds => 'Noch keine Feeds. Oben eine URL eintragen.';

  @override
  String get news_settings_invalid_url => 'Bitte eine gültige http(s)-URL eingeben.';

  @override
  String get news_settings_duplicate_url => 'Diese URL steht bereits in der Liste.';

  @override
  String get news_settings_save_failed => 'Speichern fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get news_settings_stream_error => 'Profil-Updates konnten nicht abonniert werden.';

  @override
  String get news_settings_drag_to_reorder => 'Ziehen, um die Feed-Reihenfolge zu ändern';

  @override
  String get orbit_nav => 'Orbit';

  @override
  String get orbit_circuit_list => 'Strecken';

  @override
  String orbit_load_error(String error) {
    return 'Kartendaten konnten nicht geladen werden: $error';
  }

  @override
  String get orbit_track_standard => 'Standard';

  @override
  String get orbit_track_details => 'Details';

  @override
  String get orbit_track_technical => 'Technisch';

  @override
  String get orbit_elevation_profile => 'Höhenprofil';

  @override
  String get orbit_stat_lap_distance => 'Rundenlänge';

  @override
  String get orbit_stat_max_elevation => 'Max. Höhenunterschied';

  @override
  String get orbit_stat_banked_turns => 'Überhöhte Kurven';

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

  @override
  String get circuit_map_expand => 'Karte vergrößern';

  @override
  String get circuit_map_collapse => 'Karte verkleinern';

  @override
  String get circuit_map_zoom_in => 'Hineinzoomen';

  @override
  String get circuit_map_zoom_out => 'Herauszoomen';

  @override
  String get recent_form_trend_title => 'Aktuelle Form';

  @override
  String get recent_form_last_5_points => 'Letzte 5 Punkte';

  @override
  String get recent_form_avg_finish => 'Ø Platzierung';

  @override
  String get recent_form_total_season_points => 'Saisonpunkte gesamt';

  @override
  String get recent_form_avg_race_finish => 'Ø Renn-Platzierung';

  @override
  String get recent_form_total_podiums => 'Podien gesamt (Rennen + Sprint)';

  @override
  String get recent_form_expand_tooltip => 'Vollständige Saisonansicht';

  @override
  String get recent_form_close => 'Schließen';

  @override
  String get recent_form_no_data => 'Noch keine Formdaten für diese Saison.';

  @override
  String get simulator_nav => 'Simulator';

  @override
  String get simulator_title => 'Meisterschafts-Simulator';

  @override
  String get simulator_timeline => 'Zeitleiste';

  @override
  String get simulator_podium_hint => 'Fahrer auf P1–P3 ziehen. Andere Plätze rutschen nach.';

  @override
  String get simulator_standings => 'Saisonstand';

  @override
  String get simulator_actual => 'Tatsächlich';

  @override
  String get simulator_prediction => 'Deine Wahl';

  @override
  String get simulator_accuracy => 'Podium-Trefferquote';

  @override
  String get simulator_magic_clinch => 'Vorsprung > Restpunkte (nur GP-Obergrenze)';

  @override
  String get simulator_consensus_stub => 'Offizielle Meisterschaftspunkte aus absolvierten Rennen dieser Saison (ohne Projektionen).';

  @override
  String get simulator_sync_cloud => 'Tipps in die Cloud synchronisieren';

  @override
  String get simulator_sync_cloud_done => 'Tipps in deinem Konto gespeichert.';

  @override
  String get simulator_sync_cloud_nothing_to_sync => 'Nichts zum Hochladen — setze P1–P3 für mindestens ein Rennen.';

  @override
  String get simulator_sync_cloud_not_signed_in => 'Zum Speichern in der Cloud anmelden.';

  @override
  String get simulator_sync_cloud_read_only => 'Nur lesen — Cloud-Sync ist deaktiviert.';

  @override
  String simulator_sync_cloud_failed(String detail) {
    return 'Cloud-Sync fehlgeschlagen: $detail';
  }

  @override
  String get simulator_snapshot_tooltip => 'Tabelle als Bild teilen';

  @override
  String get simulator_snapshot_copied_hint => 'Bild fertig — Teilen-Dialog deines Geräts nutzen.';

  @override
  String get simulator_share_readonly_tooltip => 'Nur-Lese-Link teilen';

  @override
  String get simulator_share_readonly_subject => 'F1 Hub — Meisterschafts-Simulator (nur lesen)';

  @override
  String get simulator_share_readonly_snackbar => 'Link fertig — Teilen-Dialog deines Geräts nutzen.';

  @override
  String get simulator_share_readonly_need_login => 'Zum Teilen des Nur-Lese-Links anmelden.';

  @override
  String simulator_prediction_by(String username) {
    return 'Tipp von @$username';
  }

  @override
  String simulator_p1_accuracy_percent(int pct) {
    return 'P1-Trefferquote: $pct%';
  }

  @override
  String simulator_clinch_in(String venue) {
    return 'Titel könnte fallen in: $venue';
  }

  @override
  String get simulator_steward_title => 'Steward-Raster';

  @override
  String get simulator_steward_hint => 'Strafen und DNFs sortieren das Feld neu; Punkte aktualisieren die Projektion.';

  @override
  String get simulator_sync_official => 'Beendete Rennen mit offiziellem Ergebnis abgleichen';

  @override
  String get simulator_sync_official_done => 'Beendete Rennen entsprechen jetzt dem offiziellen Podium.';

  @override
  String get simulator_save_draft => 'Entwurf speichern';

  @override
  String get simulator_undo => 'Rückgängig';

  @override
  String get simulator_readonly_banner => 'Nur-Lese-Ansicht (geteilt)';

  @override
  String get simulator_share_stub_title => 'Geteilte Tipps';

  @override
  String simulator_share_empty(String username) {
    return 'Keine Cloud-Tipps für „$username“. Diese Person muss angemeldet sein, den Meisterschafts-Simulator ausfüllen und mit dem Server synchronisieren.';
  }

  @override
  String get simulator_share_error_load => 'Geteilte Tipps konnten nicht geladen werden. Mit eigenem Supabase: sql/add_simulator_share_rpcs.sql ausführen (get_shared_predictions) und erneut versuchen.';

  @override
  String get simulator_share_local_preview => 'Nur Vorschau auf diesem Gerät — Simulator angemeldet öffnen, damit Tipps in die Cloud synchronisiert werden.';

  @override
  String get simulator_steward_coming => 'Stewards (Strafen / Status) — nächste Iteration';

  @override
  String simulator_round(int round) {
    return 'R$round';
  }

  @override
  String get simulator_open_full_grid => 'Vollständiges Grid öffnen';

  @override
  String get simulator_full_grid_title => 'Vollständiges Grid — 22 Fahrer';

  @override
  String get simulator_tab_grand_prix => 'Grand Prix';

  @override
  String get simulator_tab_sprint => 'Sprint';

  @override
  String get simulator_session_locked => 'Bearbeitung gesperrt — Session in unter 15 Minuten';

  @override
  String get simulator_race_cancelled => 'Abgesagt — keine Punkte';

  @override
  String get simulator_cancelled_no_points_banner => 'Dieser Grand Prix ist abgesagt — zählt nicht für Vorhersagepunkte. P1–P3 sind zufällig (nur Anzeige).';

  @override
  String get simulator_dns => 'DNS';

  @override
  String get simulator_dnf => 'DNF';

  @override
  String get simulator_dsq => 'DSQ';

  @override
  String simulator_stats_line(int predPts, int gridPct, int p1Pct) {
    return '$predPts Pkt. · Grid $gridPct% · P1 $p1Pct%';
  }
}
