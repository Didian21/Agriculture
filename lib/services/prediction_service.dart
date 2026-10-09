import 'dart:math';

class PredictionService {
  static Map<String, dynamic> getProductionPrediction() {
    // Mocking historical data and ML simulation
    final random = Random();
    final productionEstimate = 500 + random.nextInt(500); // 500 - 1000 kg
    final weatherFactor = 0.8 + (random.nextDouble() * 0.4); // 0.8 - 1.2
    final basePrice = 50.0;
    final pricePrediction = basePrice * weatherFactor;

    return {
      'historicalData': 'Standard growth pattern observed over last 5 years.',
      'mlStatus': 'Model training complete. Confidence: 92%.',
      'productionEstimate': '$productionEstimate kg',
      'pricePrediction': '\$${pricePrediction.toStringAsFixed(2)} per kg',
      'weatherEffect': weatherFactor > 1.0 ? 'Favorable weather' : 'Challenging weather',
    };
  }
}
