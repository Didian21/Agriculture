import 'package:flutter/material.dart';

import '../main.dart';
import '../models/farm_advice.dart';
import '../models/weather_models.dart';

class AdviceService {
  List<FarmAdvice> build(WeatherBundle w) {
    final out = <FarmAdvice>[];
    final today = w.daily.first;
    final next3 = w.daily.take(3).toList();
    final next3Rain = next3.fold<double>(0, (s, d) => s + d.rainMm);

    if (w.current.code >= 95) {
      out.add(const FarmAdvice(
        type: AdviceType.thunderstorm,
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFD84315),
      ));
    }
    if (today.rainChance >= 60 || today.rainMm >= 5) {
      out.add(const FarmAdvice(
        type: AdviceType.rainToday,
        icon: Icons.umbrella_rounded,
        color: AppColors.rain,
      ));
    }
    if (today.tempMax >= 34) {
      out.add(const FarmAdvice(
        type: AdviceType.hot,
        icon: Icons.thermostat_rounded,
        color: Color(0xFFEF6C00),
      ));
    }
    if (w.current.windKmh >= 30) {
      out.add(const FarmAdvice(
        type: AdviceType.wind,
        icon: Icons.air_rounded,
        color: Color(0xFF546E7A),
      ));
    }
    if (next3Rain < 3 && today.rainChance < 40) {
      out.add(const FarmAdvice(
        type: AdviceType.fieldWork,
        icon: Icons.agriculture_rounded,
        color: AppColors.fern,
      ));
    }
    if (out.isEmpty) {
      out.add(const FarmAdvice(
        type: AdviceType.normal,
        icon: Icons.check_circle_rounded,
        color: AppColors.fern,
      ));
    }
    return out;
  }
}