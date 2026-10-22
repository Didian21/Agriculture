/// Mga dahilan ng pagbabago ng presyo.
enum PriceFactorKind { rain, heat, season }

enum PriceCase { rainHeavy, rainDry, rainNormal, heatHigh, heatNormal, seasonPeak, seasonOff }

class PriceFactor {
  final PriceFactorKind kind;
  final PriceCase kase;

  /// Epekto sa presyo sa loob ng 7 araw, sa porsyento (+ tataas, - bababa).
  final double pct;

  const PriceFactor(this.kind, this.kase, this.pct);
}

/// Taya ng presyo ng isang pananim para sa susunod na 7 araw.
class PriceInsight {
  final String crop;
  final double currentPrice; // PHP kada kg
  final List<double> series; // [ngayon, +1, ... +7]
  final List<PriceFactor> factors;
  final double rainTotalMm;
  final double maxHeatIndex;

  const PriceInsight({
    required this.crop,
    required this.currentPrice,
    required this.series,
    required this.factors,
    required this.rainTotalMm,
    required this.maxHeatIndex,
  });

  double get predictedPrice => series.last;

  double get changePercent => currentPrice == 0 ? 0 : (predictedPrice - currentPrice) / currentPrice * 100;

  double get minPrice => series.reduce((a, b) => a < b ? a : b);
  double get maxPrice => series.reduce((a, b) => a > b ? a : b);

  /// Index ng araw na may pinakamataas na inaasahang presyo (0 = ngayon).
  int get bestIndex {
    var best = 0;
    for (var i = 1; i < series.length; i++) {
      if (series[i] > series[best]) best = i;
    }
    return best;
  }
}