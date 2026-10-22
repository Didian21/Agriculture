import 'dart:convert';

import 'package:http/http.dart' as http;

import '../main.dart';
import '../models/weather_models.dart';

class WeatherService {
  Future<WeatherBundle> fetch({
    double lat = AppConstants.defaultLat,
    double lon = AppConstants.defaultLon,
  }) async {
    final uri = Uri.parse(AppConstants.weatherBaseUrl).replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day',
      'hourly': 'temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
      'timezone': AppConstants.timezone,
      'forecast_days': '7',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Weather service error (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;

    final c = json['current'] as Map<String, dynamic>;
    final now = DateTime.parse(c['time'] as String);
    final current = CurrentWeather(
      time: now,
      temp: (c['temperature_2m'] as num).toDouble(),
      feelsLike: (c['apparent_temperature'] as num).toDouble(),
      humidity: (c['relative_humidity_2m'] as num).round(),
      windKmh: (c['wind_speed_10m'] as num).toDouble(),
      rainMm: (c['precipitation'] as num).toDouble(),
      code: (c['weather_code'] as num).toInt(),
      isDay: (c['is_day'] as num) == 1,
    );

    // Lahat ng oras (7 araw) - kasama ang halumigmig para sa heat index.
    final h = json['hourly'] as Map<String, dynamic>;
    final hTimes = List<String>.from(h['time']);
    final hourlyAll = <HourlyWeather>[];
    for (var i = 0; i < hTimes.length; i++) {
      final tempRaw = h['temperature_2m'][i] as num?;
      if (tempRaw == null) continue;
      hourlyAll.add(HourlyWeather(
        time: DateTime.parse(hTimes[i]),
        temp: tempRaw.toDouble(),
        humidity: ((h['relative_humidity_2m'][i] as num?) ?? 70).round(),
        rainChance: ((h['precipitation_probability'][i] as num?) ?? 0).round(),
        code: ((h['weather_code'][i] as num?) ?? 3).toInt(),
        isDay: ((h['is_day'][i] as num?) ?? 1) == 1,
      ));
    }

    // Susunod na 12 oras.
    final startOfHour = DateTime(now.year, now.month, now.day, now.hour);
    final hourly = hourlyAll.where((e) => !e.time.isBefore(startOfHour)).take(12).toList();

    // Araw-araw, kasama ang pinakamataas na heat index at ang oras nito.
    final d = json['daily'] as Map<String, dynamic>;
    final dates = List<String>.from(d['time']);
    final daily = List.generate(dates.length, (i) {
      final date = DateTime.parse(dates[i]);
      HourlyWeather? peak;
      for (final e in hourlyAll) {
        if (e.time.year != date.year || e.time.month != date.month || e.time.day != date.day) continue;
        if (peak == null || e.heat.celsius > peak.heat.celsius) peak = e;
      }
      return WeatherDay(
        date: date,
        tempMax: (d['temperature_2m_max'][i] as num).toDouble(),
        tempMin: (d['temperature_2m_min'][i] as num).toDouble(),
        rainMm: ((d['precipitation_sum'][i] as num?) ?? 0).toDouble(),
        rainChance: ((d['precipitation_probability_max'][i] as num?) ?? 0).round(),
        code: (d['weather_code'][i] as num).toInt(),
        heatPeak: peak?.heat,
        peakTime: peak?.time,
      );
    });

    return WeatherBundle(current, hourly, daily, hourlyAll: hourlyAll);
  }
}