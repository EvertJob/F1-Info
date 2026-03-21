import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoWeather {
  final double temperature;
  final double windspeed;
  final double winddirection;
  final double precipitation;
  final double rain;
  final double showers;
  final double snowfall;
  final double cloudcover;
  final double humidity;
  /// Precipitation probability 0-100 (from hourly forecast).
  final int precipitationProbability;

  OpenMeteoWeather({
    required this.temperature,
    required this.windspeed,
    required this.winddirection,
    required this.precipitation,
    required this.rain,
    required this.showers,
    required this.snowfall,
    required this.cloudcover,
    required this.humidity,
    this.precipitationProbability = 0,
  });

  factory OpenMeteoWeather.fromJson(Map<String, dynamic> json) {
    return OpenMeteoWeather(
      temperature: (json['temperature_2m'] as num?)?.toDouble() ??
          (json['temperature'] as num?)?.toDouble() ?? 0.0,
      windspeed: (json['windspeed_10m'] as num?)?.toDouble() ??
          (json['windspeed'] as num?)?.toDouble() ?? 0.0,
      winddirection: (json['winddirection_10m'] as num?)?.toDouble() ??
          (json['winddirection'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      rain: (json['rain'] as num?)?.toDouble() ?? 0.0,
      showers: (json['showers'] as num?)?.toDouble() ?? 0.0,
      snowfall: (json['snowfall'] as num?)?.toDouble() ?? 0.0,
      cloudcover: (json['cloudcover'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      precipitationProbability:
          (json['precipitation_probability'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Fetches weather for a circuit location. Uses Open-Meteo forecast API.
Future<OpenMeteoWeather?> fetchWeatherForRace(double lat, double lon) async {
  final url = Uri.parse(
    'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
    '&current_weather=true'
    '&hourly=temperature_2m,precipitation_probability,relative_humidity_2m'
    '&forecast_days=7',
  );
  final response = await http.get(url);
  if (response.statusCode != 200) return null;

  final data = json.decode(response.body) as Map<String, dynamic>;
  final current = data['current_weather'] as Map<String, dynamic>? ?? {};
  final hourly = data['hourly'] as Map<String, dynamic>? ?? {};

  final temp = (current['temperature'] as num?)?.toDouble() ?? 0.0;
  final windspeed = (current['windspeed'] as num?)?.toDouble() ?? 0.0;
  final winddirection =
      (current['winddirection'] as num?)?.toDouble() ?? 0.0;

  final times = hourly['time'] as List<dynamic>? ?? [];
  final probs = hourly['precipitation_probability'] as List<dynamic>? ?? [];
  final temps = hourly['temperature_2m'] as List<dynamic>? ?? [];
  final humidities = hourly['relative_humidity_2m'] as List<dynamic>? ?? [];

  int rainChance = 0;
  double displayTemp = temp;
  double displayHumidity = 0;
  final now = DateTime.now();
  for (var i = 0; i < times.length; i++) {
    final t = DateTime.tryParse(times[i].toString());
    if (t != null && !t.isBefore(now)) {
      rainChance = (probs.length > i ? probs[i] as num? : null)?.toInt() ?? 0;
      if (temps.length > i) {
        displayTemp = (temps[i] as num?)?.toDouble() ?? temp;
      }
      if (humidities.length > i) {
        displayHumidity = (humidities[i] as num?)?.toDouble() ?? 0;
      }
      break;
    }
  }

  return OpenMeteoWeather(
    temperature: displayTemp,
    windspeed: windspeed,
    winddirection: winddirection,
    precipitation: 0,
    rain: 0,
    showers: 0,
    snowfall: 0,
    cloudcover: 0,
    humidity: displayHumidity,
    precipitationProbability: rainChance,
  );
}
