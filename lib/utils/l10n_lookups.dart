import 'package:f1/l10n/app_localizations.dart';

import 'l10n_key.dart';

/// Maps race display names to gen-l10n `gp_*` getters.
String l10nGrandPrix(AppLocalizations l10n, String raceName) {
  switch (l10nNormalizeLookupKey('gp_$raceName')) {
    case 'gp_abu_dhabi_grand_prix':
      return l10n.gp_abu_dhabi_grand_prix;
    case 'gp_australian_grand_prix':
      return l10n.gp_australian_grand_prix;
    case 'gp_austrian_grand_prix':
      return l10n.gp_austrian_grand_prix;
    case 'gp_azerbaijan_grand_prix':
      return l10n.gp_azerbaijan_grand_prix;
    case 'gp_bahrain_grand_prix':
      return l10n.gp_bahrain_grand_prix;
    case 'gp_barcelona_grand_prix':
      return l10n.gp_barcelona_grand_prix;
    case 'gp_belgian_grand_prix':
      return l10n.gp_belgian_grand_prix;
    case 'gp_british_grand_prix':
      return l10n.gp_british_grand_prix;
    case 'gp_canadian_grand_prix':
      return l10n.gp_canadian_grand_prix;
    case 'gp_chinese_grand_prix':
      return l10n.gp_chinese_grand_prix;
    case 'gp_dutch_grand_prix':
      return l10n.gp_dutch_grand_prix;
    case 'gp_hungarian_grand_prix':
      return l10n.gp_hungarian_grand_prix;
    case 'gp_italian_grand_prix':
      return l10n.gp_italian_grand_prix;
    case 'gp_japanese_grand_prix':
      return l10n.gp_japanese_grand_prix;
    case 'gp_las_vegas_grand_prix':
      return l10n.gp_las_vegas_grand_prix;
    case 'gp_mexico_city_grand_prix':
      return l10n.gp_mexico_city_grand_prix;
    case 'gp_miami_grand_prix':
      return l10n.gp_miami_grand_prix;
    case 'gp_monaco_grand_prix':
      return l10n.gp_monaco_grand_prix;
    case 'gp_qatar_grand_prix':
      return l10n.gp_qatar_grand_prix;
    case 'gp_s_o_paulo_grand_prix':
      return l10n.gp_s_o_paulo_grand_prix;
    case 'gp_saudi_arabian_grand_prix':
      return l10n.gp_saudi_arabian_grand_prix;
    case 'gp_singapore_grand_prix':
      return l10n.gp_singapore_grand_prix;
    case 'gp_spanish_grand_prix':
      return l10n.gp_spanish_grand_prix;
    case 'gp_united_states_grand_prix':
      return l10n.gp_united_states_grand_prix;
    default:
      return raceName;
  }
}

/// Circuit country label (`country_*` ARB keys).
String l10nCountry(AppLocalizations l10n, String country) {
  switch (l10nNormalizeLookupKey('country_$country')) {
    case 'country_australia':
      return l10n.country_australia;
    case 'country_austria':
      return l10n.country_austria;
    case 'country_azerbaijan':
      return l10n.country_azerbaijan;
    case 'country_bahrain':
      return l10n.country_bahrain;
    case 'country_belgium':
      return l10n.country_belgium;
    case 'country_brazil':
      return l10n.country_brazil;
    case 'country_canada':
      return l10n.country_canada;
    case 'country_china':
      return l10n.country_china;
    case 'country_hungary':
      return l10n.country_hungary;
    case 'country_italy':
      return l10n.country_italy;
    case 'country_japan':
      return l10n.country_japan;
    case 'country_mexico':
      return l10n.country_mexico;
    case 'country_monaco':
      return l10n.country_monaco;
    case 'country_netherlands':
      return l10n.country_netherlands;
    case 'country_qatar':
      return l10n.country_qatar;
    case 'country_saudi_arabia':
      return l10n.country_saudi_arabia;
    case 'country_singapore':
      return l10n.country_singapore;
    case 'country_spain':
      return l10n.country_spain;
    case 'country_uae':
      return l10n.country_uae;
    case 'country_uk':
      return l10n.country_uk;
    case 'country_usa':
      return l10n.country_usa;
    default:
      return country;
  }
}

/// Driver nationality label (`nat_*` ARB keys).
String l10nNationality(AppLocalizations l10n, String nationality) {
  switch (l10nNormalizeLookupKey('nat_$nationality')) {
    case 'nat_argentine':
      return l10n.nat_argentine;
    case 'nat_australian':
      return l10n.nat_australian;
    case 'nat_brazilian':
      return l10n.nat_brazilian;
    case 'nat_british':
      return l10n.nat_british;
    case 'nat_canadian':
      return l10n.nat_canadian;
    case 'nat_dutch':
      return l10n.nat_dutch;
    case 'nat_finnish':
      return l10n.nat_finnish;
    case 'nat_french':
      return l10n.nat_french;
    case 'nat_german':
      return l10n.nat_german;
    case 'nat_italian':
      return l10n.nat_italian;
    case 'nat_japanese':
      return l10n.nat_japanese;
    case 'nat_mexican':
      return l10n.nat_mexican;
    case 'nat_monegasque':
      return l10n.nat_monegasque;
    case 'nat_new_zealander':
      return l10n.nat_new_zealander;
    case 'nat_spanish':
      return l10n.nat_spanish;
    case 'nat_thai':
      return l10n.nat_thai;
    default:
      return nationality;
  }
}

/// Track status / race control flag label (`track_flag_*` ARB keys).
String l10nTrackFlagLabel(AppLocalizations l10n, String labelKey) {
  switch (l10nNormalizeLookupKey(labelKey)) {
    case 'track_flag_green':
      return l10n.track_flag_green;
    case 'track_flag_yellow':
      return l10n.track_flag_yellow;
    case 'track_flag_double_yellow':
      return l10n.track_flag_double_yellow;
    case 'track_flag_red':
      return l10n.track_flag_red;
    default:
      return labelKey;
  }
}

/// Tyre wear label (`wear_*` ARB keys).
String l10nWearLabel(AppLocalizations l10n, String tireWear) {
  switch (l10nNormalizeLookupKey('wear_$tireWear')) {
    case 'wear_high':
      return l10n.wear_high;
    case 'wear_low':
      return l10n.wear_low;
    case 'wear_medium':
      return l10n.wear_medium;
    case 'wear_very_high':
      return l10n.wear_high;
    default:
      return tireWear;
  }
}

/// Tyre strategy label (`strategy_*` ARB keys).
String l10nStrategyLabel(AppLocalizations l10n, String tireStrategy) {
  switch (l10nNormalizeLookupKey('strategy_$tireStrategy')) {
    case 'strategy_1_stop':
      return l10n.strategy_1_stop;
    case 'strategy_2_stops':
      return l10n.strategy_2_stops;
    case 'strategy_3_stops':
      return l10n.strategy_3_stops;
    default:
      return tireStrategy;
  }
}

/// Weekend hub session status (`session_status_*` ARB keys).
String l10nSessionStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'session_status_completed':
      return l10n.session_status_completed;
    case 'session_status_live_recent':
      return l10n.session_status_live_recent;
    case 'session_status_upcoming':
      return l10n.session_status_upcoming;
    default:
      return status;
  }
}

/// Difficulty level (`level_1` … `level_5` or raw `level_*` strings from data).
String l10nDifficultyLevel(AppLocalizations l10n, String level) {
  switch (l10nNormalizeLookupKey(level)) {
    case 'level_1':
      return l10n.level_1;
    case 'level_2':
      return l10n.level_2;
    case 'level_3':
      return l10n.level_3;
    case 'level_4':
      return l10n.level_4;
    case 'level_5':
      return l10n.level_5;
    default:
      return level;
  }
}
