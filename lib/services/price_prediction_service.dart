import '../models/price_prediction.dart';
import '../models/weather_models.dart';

class PricePredictionService {
  static const Map<String, double> _currentPrices = {
    'Rice': 46.0,
    'Eggplant': 60.0,
    'Tomato': 55.0,
    'String beans': 70.0,
    'Banana': 40.0,
  };

  List<PricePrediction> predict(List<String> crops, List<WeatherDay> forecast) {
    final avgRain = forecast.isEmpty
        ? 0.0
        : forecast.map((d) => d.rainMm).reduce((a, b) => a + b) / forecast.length;

    final double factor;
    final PriceReason reason;
    if (avgRain > 10) {
      factor = 1.08;
      reason = PriceReason.heavyRain;
    } else if (avgRain < 2) {
      factor = 1.03;
      reason = PriceReason.dry;
    } else {
      factor = 0.98;
      reason = PriceReason.stable;
    }

    return crops.where(_currentPrices.containsKey).map((crop) {
      final now = _currentPrices[crop]!;
      return PricePrediction(
        crop: crop,
        currentPrice: now,
        predictedPrice: double.parse((now * factor).toStringAsFixed(2)),
        reason: reason,
      );
    }).toList();
  }
}