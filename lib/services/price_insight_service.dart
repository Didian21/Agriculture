import 'dart:math' as math;

import '../core/crop_data.dart';
import '../models/planting_guide.dart';
import '../models/price_insight.dart';
import '../models/weather_models.dart';

/// Presyo ng pananim ay galing sa crop_data.dart (farmgate price ng MAO kada buwan; tantiya lang ang Rice).

// Gaano kasensitibo ang presyo ng pananim sa ulan at init (1.0 = pinakasensitibo).
const Map<String, double> _rainSens = {
  'Eggplant': 1.0, 'Tomato': 1.0, 'String beans': 1.0, 'Ampalaya': 1.0, 'Squash': 0.8,
  'Rice': 0.6, 'Coconut': 0.3, 'Saba': 0.8, 'Lakatan': 0.8, 'Tordan': 0.8, 'Sweet potato': 0.6, 'Taro': 0.3, 'Calamansi': 0.5,
};
const Map<String, double> _heatSens = {
  'Eggplant': 1.0, 'Tomato': 1.0, 'String beans': 1.0, 'Ampalaya': 1.0, 'Squash': 0.8,
  'Rice': 0.3, 'Coconut': 0.3, 'Saba': 0.5, 'Lakatan': 0.5, 'Tordan': 0.5, 'Sweet potato': 0.5, 'Taro': 0.4, 'Calamansi': 0.5,
};

/// SIMPLENG MODELO (hindi opisyal na taya sa palengke).
/// Ginagamit ang 7-araw na weather forecast (ulan at heat index) at ang kalendaryo
/// ng pagtatanim para tantiyahin kung tataas o bababa ang suplay at presyo.
class PriceInsightService {
  static const double _maxPct = 15;

  List<PriceInsight> build({
    required List<String> crops,
    required List<WeatherDay> days,
    required List<PlantingGuide> guides,
    DateTime? now,
  }) {
    final month = (now ?? DateTime.now()).month;
    final out = <PriceInsight>[];

    for (final crop in crops) {
      final base = farmgatePrice(crop, month);
      if (base == null) continue;

      PlantingGuide? guide;
      for (final g in guides) {
        if (g.crop == crop) guide = g;
      }

      final rs = _rainSens[crop] ?? 0.6;
      final hs = _heatSens[crop] ?? 0.5;

      var rawRain = 0.0, rawHeat = 0.0, rain = 0.0, heat = 0.0, totalRain = 0.0, maxHi = 0.0;
      final dayPct = <double>[];
      for (final d in days) {
        final hi = d.heatPeak?.celsius ?? d.tempMax;
        totalRain += d.rainMm;
        maxHi = math.max(maxHi, hi);
        final rp = _rainPct(d.rainMm);
        final hp = _heatPct(hi);
        rawRain += rp;
        rawHeat += hp;
        rain += rp * rs;
        heat += hp * hs;
        dayPct.add(rp * rs + hp * hs);
      }

      // Panahon ng ani: ayon sa pinakamagandang buwan ng pagtatanim + tagal bago maani.
      double season = 0;
      PriceCase? seasonCase;
      final f = kCropFacts[crop];
      final range = (f != null && f.hasHarvestDays) ? (f.minDays!, f.maxDays!) : null;
      if (guide != null && range != null) {
        final offset = ((range.$1 + range.$2) / 2 / 30).round();
        final peak = {for (final m in guide.bestMonths) ((m - 1 + offset) % 12) + 1};
        if (peak.contains(month)) {
          season = -4;
          seasonCase = PriceCase.seasonPeak;
        } else {
          season = 1.5;
          seasonCase = PriceCase.seasonOff;
        }
      }

      final raw = rain + heat + season;
      final scale = raw.abs() > _maxPct ? _maxPct / raw.abs() : 1.0;

      final series = <double>[base];
      var cum = 0.0;
      for (var i = 1; i <= days.length; i++) {
        cum += dayPct[i - 1] * scale;
        final seasonal = season * scale * (i / days.length);
        series.add(double.parse((base * (1 + (cum + seasonal) / 100)).toStringAsFixed(2)));
      }

      final rainCase = (rawRain >= 1.0 && totalRain >= 35)
          ? PriceCase.rainHeavy
          : (rawRain >= 0.5 ? PriceCase.rainDry : PriceCase.rainNormal);
      final heatCase = rawHeat >= 1.0 ? PriceCase.heatHigh : PriceCase.heatNormal;

      out.add(PriceInsight(
        crop: crop,
        currentPrice: base,
        series: series,
        rainTotalMm: totalRain,
        maxHeatIndex: maxHi,
        factors: [
          PriceFactor(PriceFactorKind.rain, rainCase, rain * scale),
          PriceFactor(PriceFactorKind.heat, heatCase, heat * scale),
          if (seasonCase != null) PriceFactor(PriceFactorKind.season, seasonCase, season * scale),
        ],
      ));
    }
    return out;
  }

  // Epekto ng ulan sa isang araw (%): malakas na ulan = kaunting suplay = tataas ang presyo.
  static double _rainPct(double mm) {
    if (mm >= 30) return 1.5;
    if (mm >= 15) return 0.8;
    if (mm >= 5) return 0.0;
    if (mm >= 1) return -0.3;
    return 0.2; // tuyo
  }

  // Epekto ng matinding init (heat index) sa isang araw (%).
  static double _heatPct(double hi) {
    if (hi >= 42) return 0.8;
    if (hi >= 38) return 0.3;
    return 0.0;
  }
}