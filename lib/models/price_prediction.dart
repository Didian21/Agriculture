enum PriceReason { heavyRain, dry, stable }

enum SellTip { wait, slightRise, sellSoon }

class PricePrediction {
  final String crop; // ID ng pananim, hal. 'Rice'
  final double currentPrice; // PHP per kg
  final double predictedPrice; // PHP per kg
  final PriceReason reason;

  const PricePrediction({
    required this.crop,
    required this.currentPrice,
    required this.predictedPrice,
    required this.reason,
  });

  double get changePercent => (predictedPrice - currentPrice) / currentPrice * 100;

  SellTip get sellTip {
    if (changePercent >= 5) return SellTip.wait;
    if (changePercent >= 0) return SellTip.slightRise;
    return SellTip.sellSoon;
  }
}