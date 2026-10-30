import 'dart:math' as math;

import '../models/planting_guide.dart';
import '../models/price_insight.dart';
import '../models/weather_models.dart';

/// MGA HALIMBAWANG PRESYO (PHP kada kg) - hindi pa ito totoong datos ng palengke.
/// Palitan ng opisyal na presyo (hal. mula sa Tanggapan ng Pambayang Agrikultura)
/// kapag may koneksyon na sa totoong datos.
const Map<String, double> kBasePrices = {
  'Rice': 46.0,
  'Eggplant': 60.0,
  'Tomato': 55.0,
  'String beans': 70.0,
  'Banana': 40.0,
  'Coconut': 15.0, // tantiya: buong niyog (hilaw), hindi opisyal
  'Ampalaya': 65.0,
  'Squash': 30.0,
  'Sweet potato': 35.0,
  'Taro': 45.0,
  'Calamansi': 70.0,
};

/// Tantiyang araw bago maani (min, max). Wala ang Niyog at Calamansi.
const Map<String, (int, int)> _harvestDays = {
  'Rice': (110, 120),
  'Eggplant': (90, 120),
  'Tomato': (90, 110),
  'String beans': (60, 70),
  'Banana': (270, 360),
  'Ampalaya': (60, 90),
  'Squash': (90, 120),
  'Sweet potato': (90, 120),
  'Taro': (180, 270),
};

// Gaano kasensitibo ang presyo ng pananim sa ulan at init (1.0 = pinakasensitibo).
const Map<String, double> _rainSens = {
  'Eggplant': 1.0, 'Tomato': 1.0, 'String beans': 1.0, 'Ampalaya': 1.0, 'Squash': 0.8,
  'Rice': 0.6, 'Coconut': 0.3, 'Banana': 0.8, 'Sweet potato': 0.6, 'Taro': 0.3, 'Calamansi': 0.5,
};
const Map<String, double> _heatSens = {
  'Eggplant': 1.0, 'Tomato': 1.0, 'String beans': 1.0, 'Ampalaya': 1.0, 'Squash': 0.8,
  'Rice': 0.3, 'Coconut': 0.3, 'Banana': 0.5, 'Sweet potato': 0.5, 'Taro': 0.4, 'Calamansi': 0.5,
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
      final base = kBasePrices[crop];
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
      final range = _harvestDays[crop];
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