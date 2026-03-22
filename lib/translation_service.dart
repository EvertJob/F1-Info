import 'package:flutter/material.dart';

class TranslationService {
  static const supportedLocales = [
    Locale('en'),
    Locale('nl'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
  ];

  static const _translations = {
    'en': {
      'app_title': 'F1 App',
      'next_session': 'Next session',
      'ongoing': 'Ongoing',
      'starts_in': 'Starts in {time}',
      'gp_bahrain': 'Bahrain Grand Prix',
      'country_nl': 'Netherlands',
      'lap_label': 'Lap {lap}',
      'previous_winners': 'Previous winners',
      'last_winner': 'Last winner',
    },
    'nl': {
      'app_title': 'F1 App',
      'next_session': 'Volgende sessie',
      'ongoing': 'Bezig',
      'starts_in': 'Begint over {time}',
      'gp_bahrain': 'Grand Prix van Bahrein',
      'country_nl': 'Nederland',
      'lap_label': 'Ronde {lap}',
      'previous_winners': 'Vorige winnaars',
      'last_winner': 'Laatste winnaar',
    },
    'fr': {
      'app_title': 'F1 App',
      'next_session': 'Prochaine session',
      'ongoing': 'En cours',
      'starts_in': 'Commence dans {time}',
      'gp_bahrain': 'Grand Prix de Bahreïn',
      'country_nl': 'Pays-Bas',
      'lap_label': 'Tour {lap}',
      'previous_winners': 'Vainqueurs précédents',
      'last_winner': 'Dernier vainqueur',
    },
    'es': {
      'app_title': 'F1 App',
      'next_session': 'Próxima sesión',
      'ongoing': 'En curso',
      'starts_in': 'Comienza en {time}',
      'gp_bahrain': 'Gran Premio de Baréin',
      'country_nl': 'Países Bajos',
      'lap_label': 'Vuelta {lap}',
      'previous_winners': 'Ganadores anteriores',
      'last_winner': 'Último ganador',
    },
    'de': {
      'app_title': 'F1 App',
      'next_session': 'Nächste Sitzung',
      'ongoing': 'Laufend',
      'starts_in': 'Beginnt in {time}',
      'gp_bahrain': 'Großer Preis von Bahrain',
      'country_nl': 'Niederlande',
      'lap_label': 'Runde {lap}',
      'previous_winners': 'Vorherige Sieger',
      'last_winner': 'Letzter Sieger',
    },
  };

  static String translate(BuildContext context, String key, {Map<String, String>? params}) {
    final locale = Localizations.localeOf(context).languageCode;
    final map = _translations[locale] ?? _translations['en']!;
    var value = map[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }
}
