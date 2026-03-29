// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accident => 'Probabilité d’accident';

  @override
  String get age => 'Âge';

  @override
  String get ai_avg_gap => 'Écart moy.';

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
  String get ai_compare_no_match => 'Je n’ai pas trouvé deux pilotes ou équipes valides pour cette comparaison.';

  @override
  String get ai_compare_parse_error => 'Je n’ai pas pu lire la comparaison. Utilisez : nom1 vs nom2';

  @override
  String ai_crash(String error) {
    return 'L’assistant a rencontré une erreur : $error';
  }

  @override
  String ai_driver_compare_ready(String left, String right) {
    return 'Comparaison des pilotes prête pour $left et $right.';
  }

  @override
  String ai_driver_profile_ready(String driver) {
    return 'Profil pilote prêt pour $driver.';
  }

  @override
  String ai_driver_standings_summary(String year, String summary) {
    return 'Classement pilotes $year : $summary';
  }

  @override
  String ai_drivers_chart_ready(String year) {
    return 'Le graphique des pilotes est prêt pour $year.';
  }

  @override
  String get ai_example_prompt => 'Essayez par exemple : \"Fetch latest results\", \"Show next weekend\", \"Show driver standings\", \"Open driver Charles Leclerc\" ou \"Show latest penalties\".';

  @override
  String ai_form_no_cache(String driver) {
    return 'Pas encore de courses récentes en cache pour $driver.';
  }

  @override
  String get ai_form_no_driver => 'Je n’ai pas trouvé de pilote pour l’analyse de forme.';

  @override
  String ai_form_summary(String driver, String summary) {
    return 'Forme récente de $driver : $summary';
  }

  @override
  String ai_latest_penalties_none(String race) {
    return 'Aucune pénalité trouvée pour $race.';
  }

  @override
  String ai_latest_penalties_summary(String race, String count, String details) {
    return 'Dernières pénalités à $race : $count. $details';
  }

  @override
  String ai_latest_race_control_none(String race) {
    return 'Aucun message Race Control trouvé pour $race.';
  }

  @override
  String ai_latest_race_control_summary(String race, String count, String message) {
    return 'Race Control à $race : $count messages. Dernière mise à jour : $message';
  }

  @override
  String ai_latest_results_podium(String podium) {
    return 'Derniers résultats actualisés. Podium : $podium';
  }

  @override
  String get ai_latest_results_refreshed => 'Les derniers résultats ont été actualisés.';

  @override
  String ai_next_weekend(String race, String date) {
    return 'Prochain week-end : $race le $date.';
  }

  @override
  String ai_next_weekend_weather(String race, String temp, String rain, String wind) {
    return 'Météo pour $race : ${temp}C, $rain% de pluie, $wind km/h de vent.';
  }

  @override
  String get ai_no_completed_race => 'Aucune course terminée n’a encore été trouvée.';

  @override
  String get ai_open_driver_compare => 'Ouvrir comparaison pilotes';

  @override
  String get ai_open_driver_profile => 'Ouvrir profil pilote';

  @override
  String get ai_open_driver_standings => 'Ouvrir classement pilotes';

  @override
  String get ai_open_drivers_chart => 'Ouvrir graphique des pilotes';

  @override
  String get ai_open_latest_results => 'Ouvrir les derniers résultats';

  @override
  String get ai_open_team_compare => 'Ouvrir comparaison équipes';

  @override
  String get ai_open_team_profile => 'Ouvrir profil équipe';

  @override
  String get ai_open_team_standings => 'Ouvrir classement constructeurs';

  @override
  String get ai_open_weekend_hub => 'Ouvrir le hub du week-end';

  @override
  String get ai_qualifying_duel => 'Duel qualifications';

  @override
  String get ai_race_engineer => 'Ingénieur de course IA';

  @override
  String get ai_rain_chance_label => 'Risque de pluie';

  @override
  String get ai_rain_chance_slider => 'Risque de pluie';

  @override
  String get ai_sentiment_generic_neutral => 'Ambiance équipe : Signaux mitigés des radios équipe.';

  @override
  String get ai_sentiment_generic_positive => 'Ambiance équipe : Énergie positive dans tout le paddock.';

  @override
  String get ai_sentiment_label => 'Ambiance équipe';

  @override
  String get ai_sentiment_mercedes_positive => 'Ambiance équipe : Le moral monte chez Mercedes après la pénalité Hamilton.';

  @override
  String get ai_strategist_tap_hint => 'Appuyez pour poser des questions...';

  @override
  String get ai_strategist_title => 'Stratège IA';

  @override
  String get ai_prefs_section_title => 'Stratège IA';

  @override
  String get ai_prefs_section_subtitle => 'Personnalisez la carte Stratège IA sur l\'\'écran d\'\'accueil.';

  @override
  String get ai_prefs_disable_card => 'Désactiver la carte Stratège IA';

  @override
  String get ai_prefs_hide_teambattle => 'Masquer la bataille entre coéquipiers';

  @override
  String get ai_prefs_hide_teambattle_hint => 'Masquer la comparaison des coéquipiers lorsque la carte est visible.';

  @override
  String get ai_prefs_hide_coach_corner => 'Masquer Coach\'\'s Corner';

  @override
  String get ai_prefs_hide_coach_corner_hint => 'Masquer les conseils d\'\'entraînement lorsque la carte est visible.';

  @override
  String get ai_prefs_hide_team_vibe => 'Masquer Team Vibe';

  @override
  String get ai_prefs_hide_team_vibe_hint => 'Masquer le sentiment lorsque la carte est visible.';

  @override
  String get ai_supported_commands => 'Commandes prises en charge : Fetch latest results, Show next weekend, Compare name1 vs name2, Show form [driver], Show driver standings, Show team standings, Open driver [name], Open team [name], Show drivers chart, Show latest penalties, Show latest race control.';

  @override
  String ai_team_compare_ready(String left, String right) {
    return 'Comparaison des équipes prête pour $left et $right.';
  }

  @override
  String ai_team_profile_ready(String team) {
    return 'Profil équipe prêt pour $team.';
  }

  @override
  String ai_team_standings_summary(String year, String summary) {
    return 'Classement constructeurs $year : $summary';
  }

  @override
  String get ai_teammate_battle => 'Duel équipiers';

  @override
  String ai_teammate_insight(String driver, String teammate) {
    return '$driver est traditionnellement plus fort sur ce circuit en qualification, tandis que $teammate excelle en préservation des pneus.';
  }

  @override
  String get ai_type_command => 'Tapez une commande...';

  @override
  String ai_weather_effect(String pct, String driver, String pct2) {
    return 'À $pct% de pluie : chances de podium pour $driver en hausse de $pct2% grâce à un bon rythme sous la pluie.';
  }

  @override
  String ai_weather_effect_at(String pct, String insight) {
    return 'À $pct% de pluie : $insight';
  }

  @override
  String get ai_weather_insight_alonso => 'Les chances de podium pour Alonso augmentent de 15% grâce à un rythme supérieur sur piste humide.';

  @override
  String get ai_weather_insight_generic => 'Les conditions humides favorisent les pilotes forts en piste mouillée.';

  @override
  String get air_temperature => 'Température de l’air';

  @override
  String get all_scopes => 'Tous les scopes';

  @override
  String get app_title => 'F1 Hub';

  @override
  String get average_speed => 'Vitesse moyenne';

  @override
  String get avg_finish => 'Arrivée moy.';

  @override
  String get avg_finish_l5 => 'Arrivée moy. (L5)';

  @override
  String get avg_gforce => 'G moyen';

  @override
  String get avg_lap => 'Tour moyen';

  @override
  String get best_combination => 'Meilleure combinaison';

  @override
  String get best_lap => 'Meilleur tour';

  @override
  String get best_tyre_combination => 'Meilleure combinaison de pneus';

  @override
  String get cfield_air_pressure_hpa => 'Pression atmosphérique';

  @override
  String get cfield_asphalt_grip_score => 'Score d’adhérence asphaltique';

  @override
  String get cfield_avg_g_force => 'G-force moyenne';

  @override
  String get cfield_avg_time_2024_2025 => 'Temps au tour moyen (2024–25)';

  @override
  String get cfield_brake_cooling_requirement_score => 'Exigence refroidissement freins';

  @override
  String get cfield_circuit_director => 'Directeur de circuit';

  @override
  String get cfield_circuit_owner => 'Propriétaire du circuit';

  @override
  String get cfield_contract_until => 'Contrat jusqu’à';

  @override
  String get cfield_deployment_focus => 'Focus déploiement énergie';

  @override
  String get cfield_direction => 'Sens de course';

  @override
  String get cfield_distance_to_t1 => 'Distance jusqu’au virage 1';

  @override
  String get cfield_electrical_ratio => 'Part électrique';

  @override
  String get cfield_energy_flow_strategy => 'Stratégie de flux énergétique';

  @override
  String get cfield_engine_derating_risk => 'Risque de dérating moteur';

  @override
  String get cfield_era_delta => 'Écart entre ères';

  @override
  String get cfield_est_time_2026 => 'Temps au tour estimé (2026)';

  @override
  String get cfield_elevation_sea_level => 'Altitude (niveau de la mer)';

  @override
  String get cfield_harvest_difficulty => 'Difficulté de récupération';

  @override
  String get cfield_harvesting_zones => 'Zones de récupération';

  @override
  String get cfield_latitude => 'Latitude';

  @override
  String get cfield_local_time_zone => 'Fuseau horaire local';

  @override
  String get cfield_longitude => 'Longitude';

  @override
  String get cfield_lap_record_detail => 'Record du tour';

  @override
  String get cfield_laps => 'Tours';

  @override
  String get cfield_lateral_stress_score => 'Score contrainte latérale';

  @override
  String get cfield_length => 'Longueur';

  @override
  String get cfield_manual_override_energy_cost => 'Coût énergétique override manuel';

  @override
  String get cfield_manual_override_points => 'Points d’override manuel';

  @override
  String get cfield_max_elevation_change => 'Dénivelé maximal';

  @override
  String get cfield_max_g_force => 'G-force max.';

  @override
  String get cfield_override_impact_score => 'Score d’impact override';

  @override
  String get cfield_on_calendar_since => 'Au calendrier depuis';

  @override
  String get cfield_overtaking_delta => 'Delta de dépassement';

  @override
  String get cfield_pit_exit_delta => 'Delta sortie stands';

  @override
  String get cfield_pitstop_record_detail => 'Record arrêt au stand';

  @override
  String get cfield_race_day_capacity => 'Capacité jour de course';

  @override
  String get cfield_rain_chance => 'Risque de pluie';

  @override
  String get cfield_recovery_points => 'Points de recovery';

  @override
  String get cfield_red_flag_prob => 'Probabilité drapeau rouge';

  @override
  String get cfield_s1 => 'Secteur 1';

  @override
  String get cfield_s2 => 'Secteur 2';

  @override
  String get cfield_s3 => 'Secteur 3';

  @override
  String get cfield_safety_car_prob => 'Probabilité Safety Car';

  @override
  String get cfield_safety_car_window_laps => 'Fenêtre Safety Car (tours)';

  @override
  String get cfield_straight_mode_zones => 'Zones Straight Mode';

  @override
  String get cfield_sun_angle_start => 'Angle du soleil au départ';

  @override
  String get cfield_t1_accident_risk => 'Risque d’accident au virage 1';

  @override
  String get cfield_temperature_c => 'Température';

  @override
  String get cfield_top_speed => 'Vitesse de pointe';

  @override
  String get cfield_top_speed_delta => 'Écart vitesse de pointe';

  @override
  String get cfield_track_evolution => 'Évolution de la piste';

  @override
  String get cfield_track_type => 'Type de circuit';

  @override
  String get cfield_tyre_physics => 'Physique des pneus';

  @override
  String get cfield_tyre_working_window_c => 'Fenêtre de fonctionnement pneus';

  @override
  String get cfield_undercut_potential_score => 'Potentiel d’undercut';

  @override
  String get cfield_utc_offset => 'Décalage UTC';

  @override
  String get cfield_vsc_prob => 'Probabilité VSC';

  @override
  String get cfield_wind_sensitivity_sector => 'Sensibilité au vent (secteur)';

  @override
  String get cfield_x_mode_usage => 'Utilisation mode X';

  @override
  String get cfield_z_mode_activation_delay => 'Délai d’activation mode Z';

  @override
  String get cfield_z_mode_usage => 'Utilisation mode Z';

  @override
  String get cfield_zone_name => 'Nom du fuseau horaire';

  @override
  String get birth_place => 'Lieu de naissance';

  @override
  String get cache_cleared => 'Cache vidé avec succès !';

  @override
  String car_label(String number) {
    return 'Voiture $number';
  }

  @override
  String get career_stats => 'Statistiques de carrière';

  @override
  String get cc_wins => 'Titres constructeurs';

  @override
  String get championship_progression => 'Évolution du championnat';

  @override
  String get championships => 'Titres';

  @override
  String get championship_leader_pill => 'Leader du championnat';

  @override
  String get calendar_prefs_section_title => 'Calendrier';

  @override
  String get calendar_prefs_section_subtitle => 'Personnalisez le calendrier des circuits.';

  @override
  String get calendar_prefs_hide_cancelled => 'Masquer les courses placeholder';

  @override
  String get calendar_prefs_hide_cancelled_hint => 'Masquer les courses annulées ou placeholder absentes du calendrier réel.';

  @override
  String get cat_ambient_stats => 'Conditions ambiantes';

  @override
  String get cat_history_comparison => 'Comparaison d’époques';

  @override
  String get cat_risks_stats => 'Performance et risques';

  @override
  String get cat_tech_2026 => 'Technique et aéro 2026';

  @override
  String get cat_track_specs => 'Géométrie du tracé';

  @override
  String get display_prefs_section_title => 'Affichage';

  @override
  String get display_prefs_section_subtitle => 'Apparence et animations. Connecté, les réglages se synchronisent avec votre compte.';

  @override
  String get display_prefs_ui_mode => 'Style d’interface';

  @override
  String get display_prefs_mode_standard => 'Standard';

  @override
  String get display_prefs_mode_standard_hint => 'Flou type verre et ombres douces.';

  @override
  String get display_prefs_mode_simple => 'Simple';

  @override
  String get display_prefs_mode_simple_hint => 'Surfaces plates et contraste renforcé.';

  @override
  String get display_prefs_compact => 'Mode compact';

  @override
  String get display_prefs_compact_hint => 'Espacement réduit et cartes plus petites.';

  @override
  String get display_prefs_motion_reduced => 'Mouvement réduit';

  @override
  String get display_prefs_motion_reduced_hint => 'Moins d’animations, de flou et de transitions de thème.';

  @override
  String get display_prefs_saving => 'Enregistrement…';

  @override
  String get my_paddock_title => 'Mon paddock';

  @override
  String get my_paddock_session_unknown => 'Live timing';

  @override
  String my_paddock_resume_subtitle(String session, String lap) {
    return 'Reprendre : $session — image $lap';
  }

  @override
  String get my_paddock_favorite_drivers => 'Pilotes favoris';

  @override
  String get my_paddock_favorite_teams => 'Écuries favorites';

  @override
  String get my_paddock_last_race => 'Dernière course';

  @override
  String my_paddock_last_race_summary(String date, String podium) {
    return '$date · $podium';
  }

  @override
  String get my_paddock_points_suffix => 'pts';

  @override
  String get changelog => 'Changelog';

  @override
  String get characteristics => 'CARACTÉRISTIQUES DU CIRCUIT';

  @override
  String get chart_no_data => 'Aucune donnée de graphique disponible pour cette saison.';

  @override
  String get children => 'Enfants';

  @override
  String get circuit => 'Circuit';

  @override
  String get circuit_difficulty => 'Difficulté du circuit';

  @override
  String get circuit_difficulty_l10n => 'Difficulté du circuit';

  @override
  String get circuit_info => 'Infos circuit';

  @override
  String get circuit_layout => 'Plan du circuit';

  @override
  String get circuits => 'Circuits';

  @override
  String get city => 'Ville';

  @override
  String get clear_cache => 'Vider le cache';

  @override
  String get close => 'Fermer';

  @override
  String get compare => 'Comparer';

  @override
  String get compare_overall => 'Global';

  @override
  String get compare_season => 'Par saison';

  @override
  String get compare_season_unavailable => 'Les données de saison ne sont pas disponibles pour cette comparaison.';

  @override
  String get compare_year => 'Saison';

  @override
  String get contract_until => 'Contrat jusqu’à';

  @override
  String get country => 'Pays';

  @override
  String get country_australia => 'Australie';

  @override
  String get country_austria => 'Autriche';

  @override
  String get country_azerbaijan => 'Azerbaïdjan';

  @override
  String get country_bahrain => 'Bahreïn';

  @override
  String get country_belgium => 'Belgique';

  @override
  String get country_brazil => 'Brésil';

  @override
  String get country_canada => 'Canada';

  @override
  String get country_china => 'Chine';

  @override
  String get country_hungary => 'Hongrie';

  @override
  String get country_italy => 'Italie';

  @override
  String get country_japan => 'Japon';

  @override
  String get country_mexico => 'Mexique';

  @override
  String get country_monaco => 'Monaco';

  @override
  String get country_netherlands => 'Pays-Bas';

  @override
  String get country_qatar => 'Qatar';

  @override
  String get country_saudi_arabia => 'Arabie Saoudite';

  @override
  String get country_singapore => 'Singapour';

  @override
  String get country_spain => 'Espagne';

  @override
  String get country_uae => 'É.A.U.';

  @override
  String get country_uk => 'Royaume-Uni';

  @override
  String get country_usa => 'États-Unis';

  @override
  String get current_team => 'Équipe actuelle';

  @override
  String get date => 'Date';

  @override
  String get day => 'jour';

  @override
  String get days => 'jours';

  @override
  String get dc_wins => 'Titres pilotes';

  @override
  String get diff_easy => 'Très facile';

  @override
  String get diff_extreme => 'Extrême';

  @override
  String get diff_hard => 'Difficile';

  @override
  String get diff_high => 'Élevé';

  @override
  String get diff_low => 'Faible';

  @override
  String get diff_medium => 'Moyen';

  @override
  String get dir_clockwise => 'Dans le sens horaire';

  @override
  String get dir_counter_clockwise => 'Dans le sens antihoraire';

  @override
  String get dir_figure_eight => 'Tracé en huit';

  @override
  String get distance_to_turn1 => 'Distance jusqu’au virage 1';

  @override
  String get dnf => 'Abandons (DNF)';

  @override
  String get dnf_percentage => 'Abandons %';

  @override
  String get dnqs => 'Non qualifié';

  @override
  String get driver => 'Pilote';

  @override
  String get driver_facts_title => 'Faits & anecdotes';

  @override
  String get driver_history => 'Historique (5 dernières années)';

  @override
  String get drivers => 'Pilotes';

  @override
  String get drivers_chart => 'Graphique des pilotes';

  @override
  String get dsqs => 'Disqualifications';

  @override
  String get engine => 'Moteur';

  @override
  String get engine_name => 'Nom du moteur';

  @override
  String get engine_supplier => 'Motoriste';

  @override
  String get experience => 'Expérience';

  @override
  String get f1_debut => 'Débuts en F1';

  @override
  String get fastest_lap => 'Tour le plus rapide';

  @override
  String get fastest_lap_rate => 'Taux meilleur tour %';

  @override
  String get fastest_laps => 'Meilleurs tours';

  @override
  String get fastest_pit => 'Arrêt aux stands le plus rapide';

  @override
  String get favorite_circuit => 'Circuit favori';

  @override
  String get favorite_driver => 'Pilote favori';

  @override
  String get favorite_team => 'Équipe favorite';

  @override
  String get feature_130r_high_speed => 'Le gauche rapide emblématique du 130R';

  @override
  String get feature_90_degree_corners => 'Enchaînement de virages à 90° (circuit urbain)';

  @override
  String get feature_abrasive_asphalt => 'Asphalte très abrasive';

  @override
  String get feature_aggressive_kerbs => 'Risque de vibreurs agressifs type saucisse';

  @override
  String get feature_aero_efficiency_test => 'Test ultime d’efficacité aérodynamique';

  @override
  String get feature_banked_corners_t3_t14 => 'Virages relevés uniques (T3 et T14)';

  @override
  String get feature_battery_drain_kemmel => 'Forte décharge batterie (ligne droite du Kemmel)';

  @override
  String get feature_blind_corners => 'Apex dangereux sans visibilité';

  @override
  String get feature_bumpy_city_roads => 'Surface urbaine très irrégulière';

  @override
  String get feature_bumpy_surface => 'Piste bosselée';

  @override
  String get feature_bumpy_surface_subsidence => 'Bosselures dues à l’affaissement du sol';

  @override
  String get feature_castle_section_tight => 'Section château ultra-étroite';

  @override
  String get feature_cold_tire_struggle => 'Difficulté à maintenir la température des pneus';

  @override
  String get feature_curb_riding_chicane => 'Appui agressif sur les vibreurs de chicane';

  @override
  String get feature_degner_curves => 'Virages Degner exigeants';

  @override
  String get feature_dusty_surface => 'Conditions poussiéreuses en début de week-end';

  @override
  String get feature_eau_rouge_raidillon => 'Le mythique Eau Rouge-Raidillon';

  @override
  String get feature_esses_section_flow => 'Enchaînement rapide et rythmé type esses';

  @override
  String get feature_extreme_altitude => 'Altitude extrême (2200 m+)';

  @override
  String get feature_extreme_humidity => 'Humidité équatoriale étouffante';

  @override
  String get feature_extreme_low_drag => 'Configuration aéro très appui faible';

  @override
  String get feature_fastest_street_track => 'Circuit urbain le plus rapide du calendrier';

  @override
  String get feature_figure_eight_layout => 'Tracé en huit unique';

  @override
  String get feature_glittering_night_race => 'Toile de fond nocturne étincelante';

  @override
  String get feature_groundhog_risk => 'Risque d’animaux (marmottes) sur la piste';

  @override
  String get feature_heavy_braking => 'Freinages très exigeants';

  @override
  String get feature_heavy_braking_variante => 'Freinage brutal avant les chicanes';

  @override
  String get feature_heavy_braking_zones => 'Zones de freinage sévères vers les chicanes';

  @override
  String get feature_heavy_traction_points => 'Zones de traction critiques en sortie de virage lent';

  @override
  String get feature_high_altitude_cooling => 'Refroidissement du groupe propulseur en altitude';

  @override
  String get feature_high_altitude_impact => 'Impact aéro notable lié à l’altitude';

  @override
  String get feature_high_downforce_focus => 'Priorité maximale à l’appui aérodynamique';

  @override
  String get feature_high_front_tyre_wear => 'Forte dégradation des pneus avant';

  @override
  String get feature_high_humidity => 'Humidité ambiante élevée';

  @override
  String get feature_high_kerb_usage => 'Utilisation agressive des vibreurs';

  @override
  String get feature_high_lateral_load => 'Charges latérales intenses';

  @override
  String get feature_high_speed_corners => 'Enchaînement de virages très rapides';

  @override
  String get feature_high_speed_flow => 'Flux continu à haute vitesse';

  @override
  String get feature_high_stamina_required => 'Forte exigence physique pour le pilote';

  @override
  String get feature_high_wind_sensitivity => 'Sensibilité extrême au vent de travers';

  @override
  String get feature_hotel_underpass => 'Passage unique sous l’hôtel Yas';

  @override
  String get feature_iconic_tunnel => 'Tunnel du port à haute vitesse';

  @override
  String get feature_legendary_esses => 'Esses mythiques en \'\'S\'\'';

  @override
  String get feature_long_back_straight => 'Très longue ligne droite au fond du circuit';

  @override
  String get feature_long_main_straight => 'Longue pleine charge jusqu’au virage 1';

  @override
  String get feature_longest_run_to_t1 => 'Plus longue distance du départ au virage 1';

  @override
  String get feature_longest_straight => '2,2 km à plein gaz';

  @override
  String get feature_longest_track => 'Circuit le plus long du calendrier';

  @override
  String get feature_low_grip_asphalt => 'Surface semi-permanente à faible adhérence';

  @override
  String get feature_maggotts_becketts_flow => 'Flux Maggotts-Becketts-Chapel';

  @override
  String get feature_micro_climates => 'Plusieurs microclimats sur le tracé';

  @override
  String get feature_monaco_without_walls => 'Flow technique façon \'\'Monaco\'\'';

  @override
  String get feature_multi_surface_grip => 'Adhérence variable selon les surfaces';

  @override
  String get feature_multiple_overtaking_lines => 'Piste large avec plusieurs trajectoires';

  @override
  String get feature_narrow_passing_zones => 'Zones de dépassement étroites';

  @override
  String get feature_narrow_track_width => 'Largeur historique étroite';

  @override
  String get feature_new_straight_section => 'Secteur 3 haute vitesse révisé';

  @override
  String get feature_old_school_track => 'Tracé classique \'\'old-school\'\'';

  @override
  String get feature_physical_exhaustion => 'Épuisement physique extrême';

  @override
  String get feature_physical_heat_stress => 'Stress thermique sévère';

  @override
  String get feature_precision_steering => 'Précision de direction au millimètre';

  @override
  String get feature_rollercoaster_ride => 'Sensation de montagnes russes à haute vitesse';

  @override
  String get feature_sand_on_track => 'Risque de sable emporté par le vent';

  @override
  String get feature_sand_wind_impact => 'Sable désertique et buffeting du vent';

  @override
  String get feature_sea_breeze_sand => 'Brise marine et risque de sable';

  @override
  String get feature_senna_s_curves => 'Le complexe mythique \'\'Senna S\'\'';

  @override
  String get feature_short_lap_time => 'Durée de tour extrêmement courte';

  @override
  String get feature_snail_corner_t1 => 'Virage 1 technique \'\'escargot\'\'';

  @override
  String get feature_stadium_atmosphere => 'Ambiance de stade iconique';

  @override
  String get feature_stadium_section => 'Section emblématique du stade Foro Sol';

  @override
  String get feature_steep_uphill_braking => 'Zones de freinage en forte montée';

  @override
  String get feature_steep_uphill_t1 => 'Montée extrême jusqu’au virage 1';

  @override
  String get feature_street_circuit => 'Surface de rue temporaire';

  @override
  String get feature_straight_mode_5_zones => '5 zones Straight Mode';

  @override
  String get feature_sunset_to_night => 'Transition crépuscule vers la nuit';

  @override
  String get feature_sweeping_corners => 'Grands virages rapides en balayage';

  @override
  String get feature_technical_chicane => 'Placement précis des chicanes';

  @override
  String get feature_technical_final_sector => 'Dernier secteur serré et technique';

  @override
  String get feature_technical_flow => 'Enchaînement rythmique continu';

  @override
  String get feature_technical_sector_2 => 'Secteur médian technique';

  @override
  String get feature_temple_of_speed => 'Le mythique \'\'temple de la vitesse\'\'';

  @override
  String get feature_the_strip_straight => 'L’immense ligne droite du Las Vegas Strip';

  @override
  String get feature_thin_air_cooling => 'Défis de refroidissement dans l’air raréfié';

  @override
  String get feature_tight_hairpin => 'Épingle la plus serrée';

  @override
  String get feature_tire_killer => 'Forte charge latérale sur les pneus';

  @override
  String get feature_track_limits_chaos => 'Risque élevé de pénalités track limits';

  @override
  String get feature_traction_limited => 'Sorties en traction limitée';

  @override
  String get feature_unpredictable_weather => 'Météo très changeante';

  @override
  String get feature_unpredictable_weather_interlagos => 'Micro-orages soudains (Interlagos)';

  @override
  String get feature_uphill_start_finish => 'Ligne droite départ-arrivée en montée';

  @override
  String get feature_variable_grip => 'Niveaux d’adhérence variables';

  @override
  String get feature_wall_of_champions => 'Le dangereux \'\'Mur des Champions\'\'';

  @override
  String get feature_zero_margin_error => 'Aucune marge d’erreur';

  @override
  String get feature_zero_overtaking_space => 'Espace de dépassement extrêmement limité';

  @override
  String get finish => 'Arrivée';

  @override
  String get fp1 => 'Essais libres 1';

  @override
  String get fp2 => 'Essais libres 2';

  @override
  String get fp3 => 'Essais libres 3';

  @override
  String get front_row_starts => 'Départs en 1re ligne';

  @override
  String get fullscreen_table => 'Tableau en plein écran';

  @override
  String get gap => 'Écart';

  @override
  String get general => 'Général';

  @override
  String get gp_abu_dhabi_grand_prix => 'Grand Prix d’Abu Dhabi';

  @override
  String get gp_australian_grand_prix => 'Grand Prix d’Australie';

  @override
  String get gp_austrian_grand_prix => 'Grand Prix d’Autriche';

  @override
  String get gp_azerbaijan_grand_prix => 'Grand Prix d’Azerbaïdjan';

  @override
  String get gp_bahrain_grand_prix => 'Grand Prix de Bahreïn';

  @override
  String get gp_barcelona_grand_prix => 'Grand Prix de Barcelone';

  @override
  String get gp_belgian_grand_prix => 'Grand Prix de Belgique';

  @override
  String get gp_british_grand_prix => 'Grand Prix de Grande-Bretagne';

  @override
  String get gp_canadian_grand_prix => 'Grand Prix du Canada';

  @override
  String get gp_chinese_grand_prix => 'Grand Prix de Chine';

  @override
  String get gp_dutch_grand_prix => 'Grand Prix des Pays-Bas';

  @override
  String get gp_hungarian_grand_prix => 'Grand Prix de Hongrie';

  @override
  String get gp_italian_grand_prix => 'Grand Prix d’Italie';

  @override
  String get gp_japanese_grand_prix => 'Grand Prix du Japon';

  @override
  String get gp_las_vegas_grand_prix => 'Grand Prix de Las Vegas';

  @override
  String get gp_mexico_city_grand_prix => 'Grand Prix de Mexico';

  @override
  String get gp_miami_grand_prix => 'Grand Prix de Miami';

  @override
  String get gp_monaco_grand_prix => 'Grand Prix de Monaco';

  @override
  String get gp_qatar_grand_prix => 'Grand Prix du Qatar';

  @override
  String get gp_s_o_paulo_grand_prix => 'Grand Prix de São Paulo';

  @override
  String get gp_saudi_arabian_grand_prix => 'Grand Prix d’Arabie Saoudite';

  @override
  String get gp_singapore_grand_prix => 'Grand Prix de Singapour';

  @override
  String get gp_spanish_grand_prix => 'Grand Prix d’Espagne';

  @override
  String get gp_united_states_grand_prix => 'Grand Prix des États-Unis';

  @override
  String get hard_tire => 'Dur';

  @override
  String get hat_tricks => 'Hat-tricks';

  @override
  String get headquarters => 'Siège';

  @override
  String get height => 'Taille';

  @override
  String get help_and_ideas => 'Aide et idées';

  @override
  String get hide_all => 'Aucun';

  @override
  String get highest_finish => 'Meilleur résultat';

  @override
  String get highest_grid => 'Meilleure position sur la grille';

  @override
  String get hours => 'heures';

  @override
  String get humidity => 'Humidité';

  @override
  String get language => 'Langue';

  @override
  String get language_chooser => 'Français';

  @override
  String get language_selector => 'Français';

  @override
  String lap_label(String lap) {
    return 'Tour $lap';
  }

  @override
  String get lap_speed_stats => 'TOURS & VITESSE';

  @override
  String get laps => 'Tours';

  @override
  String get laps_led => 'Tours en tête';

  @override
  String get last_5_points => 'Points des 5 derniers';

  @override
  String get last_podium_prefs_section_title => 'Dernier podium';

  @override
  String get last_podium_prefs_section_subtitle => 'Combien de courses récentes afficher sur les cartes circuit.';

  @override
  String get last_podium_prefs_races_label => 'Nombre de courses';

  @override
  String get last_winner => 'Vainqueur de l’an dernier';

  @override
  String get length => 'Longueur';

  @override
  String get level_1 => 'Très facile';

  @override
  String get level_2 => 'Facile';

  @override
  String get level_3 => 'Moyen';

  @override
  String get level_4 => 'Difficile';

  @override
  String get level_5 => 'Très difficile';

  @override
  String linked_update_many(String count) {
    return '$count mises à jour associées';
  }

  @override
  String get linked_update_one => '1 mise à jour associée';

  @override
  String get live_leaderboard => 'Classement';

  @override
  String get live_switch_test => 'Passer aux données de test';

  @override
  String get live_teammate_battle => 'Duel équipiers';

  @override
  String get live_timing_title => 'Live Timing';

  @override
  String get live_waiting => 'En attente des données live...';

  @override
  String get loading => 'Chargement';

  @override
  String get logged_in => 'Vous êtes connecté';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get manager => 'Manager';

  @override
  String get max_g_force => 'G max';

  @override
  String get medium_tire => 'Medium';

  @override
  String get minutes => 'minutes';

  @override
  String get name => 'Nom';

  @override
  String get nat_argentine => 'Argentin';

  @override
  String get nat_australian => 'Australien';

  @override
  String get nat_brazilian => 'Brésilien';

  @override
  String get nat_british => 'Britannique';

  @override
  String get nat_canadian => 'Canadien';

  @override
  String get nat_dutch => 'Néerlandais';

  @override
  String get nat_finnish => 'Finlandais';

  @override
  String get nat_french => 'Français';

  @override
  String get nat_german => 'Allemand';

  @override
  String get nat_italian => 'Italien';

  @override
  String get nat_japanese => 'Japonais';

  @override
  String get nat_mexican => 'Mexicain';

  @override
  String get nat_monegasque => 'Monégasque';

  @override
  String get nat_new_zealander => 'Néo-zélandais';

  @override
  String get nat_spanish => 'Espagnol';

  @override
  String get nat_thai => 'Thaïlandais';

  @override
  String get nationality => 'Nationalité';

  @override
  String get next_race => 'Prochaine course';

  @override
  String get no_data_yet => 'Données non disponibles ou API en attente de mise à jour';

  @override
  String get no_finish_data => 'Aucune donnée d’arrivée';

  @override
  String get no_race_results_available => 'Aucun résultat de course disponible pour le moment.';

  @override
  String get one_two => 'Arrivées 1-2';

  @override
  String get overtakes => 'Dépassements';

  @override
  String get overtaking_difficulty => 'Difficulté de dépassement';

  @override
  String get overtaking_difficulty_l10n => 'Difficulté de dépassement';

  @override
  String get partner => 'Partenaire';

  @override
  String get penalties => 'Pénalités';

  @override
  String get penalties_empty => 'Aucune pénalité trouvée dans le cache du week-end.';

  @override
  String get penalty => 'Pénalité';

  @override
  String get personal_info => 'Infos personnelles';

  @override
  String get personal_sponsors => 'Sponsors personnels';

  @override
  String get pets => 'Animaux';

  @override
  String get pitstop_leadership => 'Arrêts & leadership';

  @override
  String get placeholder_page => 'Nouvelle page';

  @override
  String get placeholder_page_empty => 'Cette page est encore vide.';

  @override
  String get podiums => 'Podiums';

  @override
  String get points => 'Points';

  @override
  String get points_after_each_race => 'Classement après chaque course';

  @override
  String get points_history => 'Points par saison';

  @override
  String get points_per_entry => 'Points / engagement';

  @override
  String get points_per_start => 'Points / départ';

  @override
  String get points_progression => 'Évolution des points';

  @override
  String get pole_rate => 'Taux de pole %';

  @override
  String get poles => 'Poles';

  @override
  String get pos => 'Pos';

  @override
  String get pressure => 'Pression';

  @override
  String get previous_teams => 'Équipes';

  @override
  String get previous_winners => 'Vainqueurs précédents';

  @override
  String get profile => 'Profil';

  @override
  String get pts => 'PTS';

  @override
  String get q1_out => 'Éliminé Q1';

  @override
  String get q2_out => 'Éliminé Q2';

  @override
  String get qualifying => 'Qualifications';

  @override
  String get race => 'Course';

  @override
  String get race_control => 'Race Control';

  @override
  String get race_control_detail => 'Détail Race Control';

  @override
  String get race_control_empty => 'Aucun message Race Control trouvé pour ce filtre ou cette recherche.';

  @override
  String get race_control_filter_alerts => 'Alertes';

  @override
  String get race_control_filter_all => 'Tous';

  @override
  String get race_control_filter_stewards => 'Commissaires';

  @override
  String get race_control_filter_penalties => 'Pénalités';

  @override
  String race_control_message_count(String visible, String total) {
    return '$visible sur $total messages';
  }

  @override
  String get race_control_no_linked_message => 'Aucun message de commissaires associé trouvé.';

  @override
  String get race_control_related_updates => 'Mises à jour des commissaires associées';

  @override
  String get race_control_relation_investigation => 'Enquête';

  @override
  String get race_control_relation_issued_earlier => 'Prononcée plus tôt';

  @override
  String get race_control_relation_linked => 'Message associé';

  @override
  String get race_control_relation_message => 'Message Race Control';

  @override
  String get race_control_relation_noted => 'Noté';

  @override
  String get race_control_relation_outcome => 'Décision';

  @override
  String get race_control_relation_penalty_message => 'Message de pénalité';

  @override
  String get race_control_relation_served_later => 'Effectuée plus tard';

  @override
  String get race_control_relation_served_penalty => 'Pénalité effectuée';

  @override
  String get race_control_search_hint => 'Rechercher par message, drapeau, catégorie, tour ou pilote';

  @override
  String get race_control_track_limits_strip => 'Limites de piste — tours effacés';

  @override
  String get race_control_steward_storyline => 'Fil d’incident stewards';

  @override
  String get race_stats => 'Statistiques de course';

  @override
  String get rain => 'Pluie';

  @override
  String get rain_chance => 'Risque de pluie';

  @override
  String get rainfall => 'Précipitations';

  @override
  String get recommended_strategy_l10n => 'Stratégie';

  @override
  String get red_flag => 'Probabilité drapeau rouge';

  @override
  String get reserve_driver => 'Pilote de réserve';

  @override
  String get result => 'Résultat';

  @override
  String get results => 'Résultats';

  @override
  String get retirements => 'Abandons';

  @override
  String get risks => 'Risques';

  @override
  String get risks_incidents => 'RISQUES & INCIDENTS';

  @override
  String get round_short => 'M';

  @override
  String get scope => 'Portée';

  @override
  String get season_2026 => 'Saison 2026';

  @override
  String get select_drivers_to_compare => 'Sélectionner 2 pilotes';

  @override
  String get select_favorite => 'Sélectionner...';

  @override
  String get select_teams_to_compare => 'Sélectionner 2 équipes';

  @override
  String get session => 'Session';

  @override
  String session_data_unavailable(String session) {
    return 'Les données $session sont en cours de chargement ou indisponibles.';
  }

  @override
  String get session_future => 'La session commence à';

  @override
  String get session_results => 'Résultats des sessions';

  @override
  String get session_status_completed => 'Terminé';

  @override
  String get session_status_live_recent => 'Live / Récent';

  @override
  String get session_status_upcoming => 'À venir';

  @override
  String session_weather_unavailable(String session) {
    return 'Aucune donnée météo disponible pour $session.';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get show_all => 'Tout';

  @override
  String show_all_messages(String count) {
    return 'Afficher les $count messages';
  }

  @override
  String get show_less_messages => 'Afficher moins de messages';

  @override
  String get since => 'Au calendrier depuis';

  @override
  String get slowest_lap => 'Tour le plus lent';

  @override
  String get soft_tire => 'Tendre';

  @override
  String get sponsors => 'Sponsors';

  @override
  String get sprint => 'Sprint';

  @override
  String get sprint_quali => 'Qualifications sprint';

  @override
  String get standings => 'Classements';

  @override
  String get start => 'Départ';

  @override
  String get starts => 'Départs';

  @override
  String get starts_in => 'Départ dans';

  @override
  String get status => 'Statut';

  @override
  String get strategy => 'Stratégie';

  @override
  String get strategy_1_stop => '1 arrêt';

  @override
  String get strategy_2_stops => '2 arrêts';

  @override
  String get strategy_3_stops => '3 arrêts';

  @override
  String get summer_break => 'Pause estivale';

  @override
  String get summer_break_subtitle => 'La pause estivale se situe entre la Hongrie et les Pays-Bas.';

  @override
  String get sun_0_deg_night_race => 'Conditions de nuit (éclairage artificiel)';

  @override
  String get sun_5_deg_twilight => 'Crépuscule (projecteurs allumés)';

  @override
  String get sun_8_deg_horizon_dip => 'Près de l’horizon (éblouissement extrême)';

  @override
  String get sun_10_deg_harbor_reflection => 'Soleil très bas (réflexion sur l’eau)';

  @override
  String get sun_12_deg_mountain_occlusion => 'Soleil bas (ombres des montagnes)';

  @override
  String get sun_14_deg_stadium_shadows => 'Soleil bas (ombres des tribunes)';

  @override
  String get sun_15_deg_sunset_blind => 'Soleil bas (risque d’éblouissement élevé)';

  @override
  String get sun_18_deg_paddock_glare => 'Soleil bas (réflexions des bâtiments)';

  @override
  String get sun_20_deg_desert_haze => 'Soleil bas (poussière et brume, éblouissement)';

  @override
  String get sun_22_deg_coastal_mist => 'Soleil bas (diffusion par brume côtière)';

  @override
  String get sun_25_deg_morning_glow => 'Soleil du petit matin';

  @override
  String get sun_28_deg_dunes_glare => 'Soleil bas (éblouissement des dunes)';

  @override
  String get sun_30_deg_low_winter_sun => 'Soleil d’hiver bas sur l’horizon';

  @override
  String get sun_32_deg_urban_canyon => 'Soleil moyen (ombres des tours)';

  @override
  String get sun_35_deg_forest_shadows => 'Soleil moyen (ombres intermittentes)';

  @override
  String get sun_40_deg_cloudy_diffuse => 'Lumière diffuse (ciel couvert)';

  @override
  String get sun_45_deg_mid_afternoon => 'Soleil de milieu d’après-midi';

  @override
  String get sun_50_deg_clear_sky => 'Après-midi ensoleillée claire';

  @override
  String get sun_55_deg_bright_oval => 'Forte luminosité (zone dégagée)';

  @override
  String get sun_60_deg_standard_day => 'Lumière du jour standard';

  @override
  String get sun_65_deg_high_noon => 'Soleil haut (midi)';

  @override
  String get sun_70_deg_equatorial_high => 'Ensoleillement intense';

  @override
  String get sun_75_deg_tropical_peak => 'Soleil tropical extrême';

  @override
  String get sun_85_deg_zenith => 'Soleil au zénith (pas d’ombres)';

  @override
  String get team_facts_title => 'Le saviez-vous ?';

  @override
  String get team_history => 'Historique de l’équipe';

  @override
  String get team_principal => 'Directeur d’équipe';

  @override
  String get team_theme => 'Thème équipe';

  @override
  String get teams => 'Équipes';

  @override
  String get teams_chart => 'Graphique des équipes';

  @override
  String get technical_director => 'Directeur technique';

  @override
  String get temp => 'Température';

  @override
  String get theme_mode => 'Mode d\'\'affichage';

  @override
  String get theme_mode_dark => 'Sombre';

  @override
  String get theme_mode_light => 'Clair';

  @override
  String get theme_mode_system => 'Système';

  @override
  String get time => 'Temps';

  @override
  String get time_gap => 'Temps / écart';

  @override
  String get tire_wear => 'Usure des pneus';

  @override
  String get toggle_theme => 'Changer de thème';

  @override
  String get top_10 => 'Top 10';

  @override
  String get top_3 => 'Top 3';

  @override
  String get top_5 => 'Top 5';

  @override
  String get top_speed => 'Vitesse de pointe';

  @override
  String get total_entries => 'Engagements totaux';

  @override
  String get total_length => 'Longueur totale';

  @override
  String get total_points => 'Points totaux';

  @override
  String get total_time => 'Temps total';

  @override
  String get track_flag_double_yellow => 'Double jaune';

  @override
  String get track_flag_green => 'Drapeau vert';

  @override
  String get track_flag_red => 'Drapeau rouge';

  @override
  String get track_flag_yellow => 'Drapeau jaune';

  @override
  String get track_playback_dry_track => 'Piste sèche';

  @override
  String get track_playback_interpolated_minute => 'minute interpolée';

  @override
  String get track_playback_no_weather => 'Aucune donnée météo disponible pour cette session.';

  @override
  String get track_playback_rain_active => 'Pluie active';

  @override
  String get track_playback_recorded_sample => 'échantillon enregistré';

  @override
  String get track_playback_title => 'Track Playback';

  @override
  String get track_playback_unknown_sample => 'Échantillon inconnu';

  @override
  String get track_temperature => 'Température de la piste';

  @override
  String get turn1_accident => 'Probabilité d’accident virage 1';

  @override
  String get type_hybrid_street => 'Circuit urbain hybride';

  @override
  String get type_permanent_circuit => 'Circuit permanent';

  @override
  String get type_street_circuit => 'Circuit urbain';

  @override
  String get tyre => 'Pneu';

  @override
  String get tyres => 'Pneus';

  @override
  String get tyres_strategy => 'PNEUS & STRATÉGIE';

  @override
  String get unknown => 'Inconnu';

  @override
  String get unknown_sample => 'Inconnu';

  @override
  String get unknown_time => 'Heure inconnue';

  @override
  String get until => 'Contrat jusqu’à';

  @override
  String get used_tyre => 'utilisé';

  @override
  String get using_fallback_data => 'Utilisation des données hors ligne/de secours.';

  @override
  String get version => 'Version';

  @override
  String get vsc => 'Probabilité VSC';

  @override
  String get wear_high => 'Élevée';

  @override
  String get wear_low => 'Faible';

  @override
  String get wear_medium => 'Moyenne';

  @override
  String get weather_forecast => 'Prévisions météo';

  @override
  String get week => 'semaine';

  @override
  String get weekend_hub => 'Hub du week-end';

  @override
  String get weekend_hub_card_subtitle => 'Programme, météo, podium et pénalités sur un écran';

  @override
  String get weekend_hub_load_error => 'Le hub du week-end n’a pas pu se charger entièrement. Données en cache affichées.';

  @override
  String get weekend_hub_loading => 'Chargement du hub du week-end...';

  @override
  String get weekend_hub_no_results_yet => 'Les résultats de cette session ne sont pas encore disponibles ou n’ont pas encore été synchronisés.';

  @override
  String get weekend_hub_session_insights => 'Aperçu de la session';

  @override
  String get weekend_hub_fastest_sectors => 'Secteurs les plus rapides';

  @override
  String get weekend_hub_sector_1_abbr => 'S1';

  @override
  String get weekend_hub_sector_2_abbr => 'S2';

  @override
  String get weekend_hub_sector_3_abbr => 'S3';

  @override
  String get weekend_hub_tyre_compound => 'Composé pneumatique';

  @override
  String get weekend_hub_insights_sectors_unavailable => 'Les données de secteurs nécessitent une synchronisation OpenF1 en direct pour cette course.';

  @override
  String get weekend_hub_penalties_filter_empty => 'Aucun message de pénalité ou d’enquête pour cette session.';

  @override
  String get weekend_hub_spot_placeholder_title => 'Radar live & DRS';

  @override
  String get weekend_hub_spot_placeholder_body => 'Radar météo, pluie sur la piste et aperçu des zones DRS apparaîtront ici dans une prochaine mise à jour.';

  @override
  String get weekend_schedule => 'Programme du week-end';

  @override
  String get weeks => 'semaines';

  @override
  String get win_rate => 'Taux de victoire %';

  @override
  String get wind => 'Vent';

  @override
  String get wind_speed => 'Vitesse du vent';

  @override
  String get wins => 'Victoires';

  @override
  String get ai_fab_label => 'IA';

  @override
  String auth_error_message(String message) {
    return '$message';
  }

  @override
  String get calendar_race_status_cancelled => 'Annulé';

  @override
  String get calendar_race_status_ended => 'Terminé';

  @override
  String get calendar_race_status_ongoing => 'En cours';

  @override
  String get circuit_go_home => 'Retour à l’accueil';

  @override
  String get circuit_not_found_message => 'Aucune donnée circuit n’est disponible pour cette adresse. Vérifiez le lien ou choisissez un circuit dans le calendrier.';

  @override
  String get circuit_not_found_title => 'Circuit introuvable';

  @override
  String get circuit_open_in_maps => 'Ouvrir dans Plans';

  @override
  String get circuit_stat_full_throttle => 'Plein gaz';

  @override
  String circuit_weekend_hub_go(String venue) {
    return 'Aller au hub $venue';
  }

  @override
  String get circuit_weekend_hub_no_data_tooltip => 'Aucune donnée de session pour le moment.';

  @override
  String live_timing_air_temp_abbr(String temp) {
    return 'A $temp';
  }

  @override
  String get live_timing_banner_green => 'GREEN';

  @override
  String get live_timing_banner_red_flag => 'DRAPEAU ROUGE';

  @override
  String get live_timing_banner_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_banner_vsc_deployed => 'VSC DÉPLOYÉ';

  @override
  String get live_timing_banner_vsc_ending => 'FIN DE VSC';

  @override
  String get live_timing_banner_yellow_flag => 'DRAPEAU JAUNE';

  @override
  String get live_timing_chip_red_flag => 'DRAPEAU ROUGE';

  @override
  String get live_timing_chip_safety_car => 'SAFETY CAR';

  @override
  String get live_timing_chip_vsc => 'VSC';

  @override
  String get live_timing_chip_vsc_end => 'FIN VSC';

  @override
  String get live_timing_chip_yellow => 'JAUNE';

  @override
  String live_timing_data_source(String source) {
    return 'Source : $source';
  }

  @override
  String get live_timing_demo_session_title => 'Silverstone 2024';

  @override
  String get live_timing_driver_out => 'OUT';

  @override
  String get live_timing_driver_pit => 'PIT';

  @override
  String get live_timing_header_driver => 'PILOTE';

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
  String get live_timing_header_tyre => 'PNEU';

  @override
  String get live_timing_hub_timestamp_tooltip => 'Horodatage du dernier message (flux)';

  @override
  String live_timing_lap_of_total(String current, String total) {
    return 'Tour $current / $total';
  }

  @override
  String get live_timing_session_pre_start => 'PRE-START';

  @override
  String get live_timing_session_starting_grid => 'GRILLE DE DÉPART';

  @override
  String get live_timing_status_green => 'GREEN';

  @override
  String live_timing_track_temp_abbr(String temp) {
    return 'T $temp';
  }

  @override
  String metric_label_value(String label, String value) {
    return '$label : $value';
  }

  @override
  String news_load_error(String error) {
    return 'Impossible de charger les actualités : $error';
  }

  @override
  String get news_title => 'Actus F1';

  @override
  String get news_nav => 'Actus';

  @override
  String get news_empty => 'Aucun article pour le moment. Tirez pour actualiser.';

  @override
  String get news_feed_section_empty => 'Aucun article pour ce flux.';

  @override
  String get news_settings_title => 'Flux d\'\'actualités';

  @override
  String get news_settings_subtitle => 'Ajoutez des URL RSS ou Atom. Elles sont chargées dans l\'\'onglet Actus (plus récent en premier).';

  @override
  String get news_settings_url_hint => 'https://exemple.fr/flux.xml';

  @override
  String get news_settings_add => 'Ajouter';

  @override
  String get news_settings_your_feeds => 'Vos flux';

  @override
  String get news_settings_no_feeds => 'Aucun flux pour l\'\'instant. Ajoutez une URL ci-dessus.';

  @override
  String get news_settings_invalid_url => 'Saisissez une URL http(s) valide.';

  @override
  String get news_settings_duplicate_url => 'Cette URL est déjà dans la liste.';

  @override
  String get news_settings_save_failed => 'Enregistrement impossible. Réessayez.';

  @override
  String get news_settings_stream_error => 'Impossible de s\'\'abonner aux mises à jour du profil.';

  @override
  String get news_settings_drag_to_reorder => 'Glisser pour modifier l\'\'ordre des flux';

  @override
  String get orbit_nav => 'Orbit';

  @override
  String get orbit_circuit_list => 'Circuits';

  @override
  String orbit_load_error(String error) {
    return 'Impossible de charger la carte : $error';
  }

  @override
  String get orbit_track_standard => 'Standard';

  @override
  String get orbit_track_details => 'Détails';

  @override
  String get orbit_track_technical => 'Technique';

  @override
  String get orbit_elevation_profile => 'Profil d\'altitude';

  @override
  String get orbit_stat_lap_distance => 'Longueur du tour';

  @override
  String get orbit_stat_max_elevation => 'Dénivelé max.';

  @override
  String get orbit_stat_banked_turns => 'Virages relevés';

  @override
  String get race_results_empty => 'Aucun résultat de course pour le moment.';

  @override
  String get secure_page_authorized => 'Vous êtes autorisé !';

  @override
  String get secure_page_title => 'Page sécurisée';

  @override
  String team_comparison_title(String team1, String team2) {
    return '$team1 vs $team2';
  }

  @override
  String get unauthorized_page_message => 'Vous n’êtes pas autorisé à afficher cette page.';

  @override
  String get unauthorized_page_title => 'Non autorisé';

  @override
  String get circuit_map_expand => 'Agrandir la carte';

  @override
  String get circuit_map_collapse => 'Réduire la carte';

  @override
  String get circuit_map_zoom_in => 'Zoom avant';

  @override
  String get circuit_map_zoom_out => 'Zoom arrière';

  @override
  String get recent_form_trend_title => 'Tendance de forme';

  @override
  String get recent_form_last_5_points => '5 derniers points';

  @override
  String get recent_form_avg_finish => 'Moy. arrivée';

  @override
  String get recent_form_total_season_points => 'Points saison totaux';

  @override
  String get recent_form_avg_race_finish => 'Moy. arrivée (GP)';

  @override
  String get recent_form_total_podiums => 'Podiums totaux (course + sprint)';

  @override
  String get recent_form_expand_tooltip => 'Ouvrir la saison complète';

  @override
  String get recent_form_close => 'Fermer';

  @override
  String get recent_form_no_data => 'Pas encore de données de forme pour cette saison.';
}
