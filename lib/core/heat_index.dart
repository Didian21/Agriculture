import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum HeatLevel { normal, caution, extremeCaution, danger, extremeDanger }

class HeatIndex {
  final double celsius;
  final HeatLevel level;
  const HeatIndex(this.celsius, this.level);

  /// Kinukwenta ang heat index mula sa temperatura (°C) at halumigmig (%).
  /// Pormula: Rothfusz regression (NWS). Tantiya lamang.
  factory HeatIndex.from({required double tempC, required num humidity}) {
    final c = _compute(tempC, humidity.toDouble().clamp(0, 100).toDouble());
    return HeatIndex(c, _levelFor(c));
  }

  static double _compute(double tC, double rh) {
    final t = tC * 9 / 5 + 32; // °F
    var hi = 0.5 * (t + 61.0 + ((t - 68.0) * 1.2) + (rh * 0.094));
    if ((hi + t) / 2 >= 80) {
      hi = -42.379 +
          2.04901523 * t +
          10.14333127 * rh -
          0.22475541 * t * rh -
          0.00683783 * t * t -
          0.05481717 * rh * rh +
          0.00122874 * t * t * rh +
          0.00085282 * t * rh * rh -
          0.00000199 * t * t * rh * rh;
      if (rh < 13 && t >= 80 && t <= 112) {
        hi -= ((13 - rh) / 4) * math.sqrt((17 - (t - 95).abs()) / 17);
      } else if (rh > 85 && t >= 80 && t <= 87) {
        hi += ((rh - 85) / 10) * ((87 - t) / 5);
      }
    }
    return (hi - 32) * 5 / 9;
  }

  // Mga antas ayon sa heat index scale ng PAGASA (kumpirmahin sa opisyal na source).
  static HeatLevel _levelFor(double c) {
    final v = c.round();
    if (v >= 52) return HeatLevel.extremeDanger;
    if (v >= 42) return HeatLevel.danger;
    if (v >= 33) return HeatLevel.extremeCaution;
    if (v >= 27) return HeatLevel.caution;
    return HeatLevel.normal;
  }
}

/// Mga kulay na akma sa magaan na background.
Color heatColor(HeatLevel l) {
  switch (l) {
    case HeatLevel.normal:
      return const Color(0xFF2E9E4F);
    case HeatLevel.caution:
      return const Color(0xFFE59A00);
    case HeatLevel.extremeCaution:
      return const Color(0xFFEF6C00);
    case HeatLevel.danger:
      return const Color(0xFFD84315);
    case HeatLevel.extremeDanger:
      return const Color(0xFFC62828);
  }
}

extension HeatL10n on AppLocalizations {
  String heatLevelName(HeatLevel l) {
    switch (l) {
      case HeatLevel.normal:
        return heatNormal;
      case HeatLevel.caution:
        return heatCaution;
      case HeatLevel.extremeCaution:
        return heatExtremeCaution;
      case HeatLevel.danger:
        return heatDanger;
      case HeatLevel.extremeDanger:
        return heatExtremeDanger;
    }
  }

  String heatLevelAdvice(HeatLevel l) {
    switch (l) {
      case HeatLevel.normal:
        return heatAdviceNormal;
      case HeatLevel.caution:
        return heatAdviceCaution;
      case HeatLevel.extremeCaution:
        return heatAdviceExtremeCaution;
      case HeatLevel.danger:
        return heatAdviceDanger;
      case HeatLevel.extremeDanger:
        return heatAdviceExtremeDanger;
    }
  }
}