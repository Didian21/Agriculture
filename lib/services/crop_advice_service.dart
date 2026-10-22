import 'package:flutter/material.dart';

import '../core/crop_data.dart';
import '../main.dart';
import '../models/crop_advice.dart';
import '../models/farm_planting.dart';
import '../models/weather_models.dart';

/// Gumagawa ng payo para sa bawat tanim ng farmer, ayon sa panahon at edad ng tanim.
/// MGA SIMPLENG ALITUNTUNIN - gabay lamang.
class CropAdviceService {
  // Mga gulay na madaling malunod at mainitan.
  static const _vegetables = {'Eggplant', 'Tomato', 'String beans', 'Ampalaya', 'Squash'};
  // Mga tanim na kailangang suhayan kapag malakas ang hangin.
  static const _needsSupport = {'Banana', 'Tomato', 'String beans', 'Ampalaya'};

  List<CropAdvice> build(List<FarmPlanting> plantings, WeatherBundle w) {
    final out = <CropAdvice>[];
    if (plantings.isEmpty || w.daily.isEmpty) return out;

    final next3 = w.daily.take(3).toList();
    final next3Rain = next3.fold<double>(0, (s, d) => s + d.rainMm);
    final todayMax = w.daily.first.tempMax;
    final wind = w.current.windKmh;
    final now = DateTime.now();
    final seen = <String>{};

    for (final pl in plantings) {
      final facts = factsFor(pl.crop);
      final days = now.difference(pl.plantedOn).inDays;

      // Ani
      if (facts != null && facts.hasHarvestDays && days >= 0) {
        if (days >= facts.minDays!) {
          if (seen.add('ready-${pl.crop}')) {
            out.add(CropAdvice(
              type: CropAdviceType.harvestReady,
              crop: pl.crop,
              icon: Icons.agriculture_rounded,
              color: AppColors.leaf,
            ));
          }
        } else if (facts.minDays! - days <= 14) {
          if (seen.add('soon-${pl.crop}')) {
            out.add(CropAdvice(
              type: CropAdviceType.harvestSoon,
              crop: pl.crop,
              icon: Icons.event_available_rounded,
              color: AppColors.fern,
              days: facts.minDays! - days,
            ));
          }
        }
      }

      // Panahon
      if (_vegetables.contains(pl.crop) && next3Rain >= 30 && seen.add('drain-${pl.crop}')) {
        out.add(CropAdvice(type: CropAdviceType.drainage, crop: pl.crop, icon: Icons.water_rounded, color: AppColors.rain));
      }
      if (_vegetables.contains(pl.crop) && todayMax >= 34 && seen.add('heat-${pl.crop}')) {
        out.add(CropAdvice(
          type: CropAdviceType.heatWater,
          crop: pl.crop,
          icon: Icons.thermostat_rounded,
          color: const Color(0xFFEF6C00),
        ));
      }
      if (_needsSupport.contains(pl.crop) && wind >= 30 && seen.add('wind-${pl.crop}')) {
        out.add(CropAdvice(
          type: CropAdviceType.windSupport,
          crop: pl.crop,
          icon: Icons.air_rounded,
          color: const Color(0xFF546E7A),
        ));
      }
      if (pl.crop == 'Rice' && next3Rain < 3 && w.daily.first.rainChance < 40 && seen.add('dry-${pl.crop}')) {
        out.add(CropAdvice(type: CropAdviceType.dryDays, crop: pl.crop, icon: Icons.wb_sunny_rounded, color: AppColors.sun));
      }
    }
    return out;
  }
}