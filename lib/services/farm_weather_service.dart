import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kasalukuyang panahon sa mismong lokasyon ng bukid (Open-Meteo, walang API key).
class FarmWeather {
  final double tempC;
  final double feelsC;
  final int humidity;
  final double windKmh;
  final double rainMm;
  final int code;
  final bool isDay;
  final double rainNext24h;

  const FarmWeather({
    required this.tempC,
    required this.feelsC,
    required this.humidity,
    required this.windKmh,
    required this.rainMm,
    required this.code,
    required this.isDay,
    required this.rainNext24h,
  });
}

class FarmWeatherService {
  Future<FarmWeather> fetch(double lat, double lon) async {
    final uri = Uri.parse('https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day'
        '&hourly=precipitation&forecast_hours=24&timezone=Asia%2FManila');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final c = j['current'] as Map<String, dynamic>;
    final h = ((j['hourly'] as Map<String, dynamic>?)?['precipitation'] as List?) ?? const [];
    var sum = 0.0;
    for (final v in h) {
      sum += (v as num?)?.toDouble() ?? 0;
    }
    return FarmWeather(
      tempC: (c['temperature_2m'] as num).toDouble(),
      feelsC: (c['apparent_temperature'] as num).toDouble(),
      humidity: (c['relative_humidity_2m'] as num).round(),
      windKmh: (c['wind_speed_10m'] as num).toDouble(),
      rainMm: (c['precipitation'] as num).toDouble(),
      code: (c['weather_code'] as num).toInt(),
      isDay: (c['is_day'] as num) == 1,
      rainNext24h: sum,
    );
  }
}