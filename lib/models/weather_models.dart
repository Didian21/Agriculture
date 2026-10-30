import 'package:flutter/material.dart';

import '../core/heat_index.dart';

enum WeatherKind { sunny, clearNight, partlyCloudy, cloudy, foggy, drizzle, rain, thunderstorm }

class WeatherInfo {
  final WeatherKind kind;
  final IconData icon;
  final List<Color> gradient;

  const WeatherInfo(this.kind, this.icon, this.gradient);
}

WeatherInfo describeWeather(int code, {bool isDay = true}) {
  if (code == 0 || code == 1) {
    return isDay
        ? const WeatherInfo(WeatherKind.sunny, Icons.wb_sunny_rounded, [Color(0xFF56CCF2), Color(0xFF2F80ED)])
        : const WeatherInfo(WeatherKind.clearNight, Icons.nights_stay_rounded, [Color(0xFF283E51), Color(0xFF0B1620)]);
  }
  if (code == 2) {
    return const WeatherInfo(WeatherKind.partlyCloudy, Icons.wb_cloudy_rounded, [Color(0xFF6FB1E8), Color(0xFF4A7FBF)]);
  }
  if (code == 3) {
    return const WeatherInfo(WeatherKind.cloudy, Icons.cloud_rounded, [Color(0xFF8FA6B8), Color(0xFF5C7A99)]);
  }
  if (code == 45 || code == 48) {
    return const WeatherInfo(WeatherKind.foggy, Icons.blur_on_rounded, [Color(0xFF9AA9B5), Color(0xFF66798A)]);
  }
  if (code >= 51 && code <= 57) {
    return const WeatherInfo(WeatherKind.drizzle, Icons.grain_rounded, [Color(0xFF6C93B5), Color(0xFF3F6486)]);
  }
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
    return const WeatherInfo(WeatherKind.rain, Icons.water_drop_rounded, [Color(0xFF5B86A8), Color(0xFF2C4A66)]);
  }
  if (code >= 95) {
    return const WeatherInfo(WeatherKind.thunderstorm, Icons.thunderstorm_rounded, [Color(0xFF485563), Color(0xFF29323C)]);
  }
  return const WeatherInfo(WeatherKind.cloudy, Icons.cloud_rounded, [Color(0xFF8FA6B8), Color(0xFF5C7A99)]);
}

class CurrentWeather {
  final DateTime time;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windKmh;
  final double rainMm;
  final int code;
  final bool isDay;

  const CurrentWeather({
    required this.time,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windKmh,
    required this.rainMm,
    required this.code,
    required this.isDay,
  });

  WeatherInfo get info => describeWeather(code, isDay: isDay);

  /// Heat index na kinwenta mula sa temperatura at halumigmig.
  HeatIndex get heat => HeatIndex.from(tempC: temp, humidity: humidity);
}

class HourlyWeather {
  final DateTime time;
  final double temp;
  final int humidity;
  final int rainChance;
  final int code;
  final bool isDay;

  const HourlyWeather({
    required this.time,
    required this.temp,
    required this.humidity,
    required this.rainChance,
    required this.code,
    required this.isDay,
  });

  HeatIndex get heat => HeatIndex.from(tempC: temp, humidity: humidity);
}

class WeatherDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double rainMm;
  final int rainChance;
  final int code;

  /// Pinakamataas na heat index ng araw at ang oras kung kailan ito.
  final HeatIndex? heatPeak;
  final DateTime? peakTime;

  const WeatherDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.rainMm,
    required this.rainChance,
    required this.code,
    this.heatPeak,
    this.peakTime,
  });
}

class WeatherBundle {
  final CurrentWeather current;

  /// Susunod na 12 oras.
  final List<HourlyWeather> hourly;
  final List<WeatherDay> daily;

  /// Lahat ng oras sa loob ng 7 araw (para sa heat index timeline).
  final List<HourlyWeather> hourlyAll;

  const WeatherBundle(this.current, this.hourly, this.daily, {this.hourlyAll = const []});
}