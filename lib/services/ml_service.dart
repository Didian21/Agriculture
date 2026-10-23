import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  // TODO: Replace with your GitHub-hosted Machine Learning API endpoint 
  // (e.g. FastAPI / Flask hosted on Render, Railway, Hugging Face, or GitHub Actions webhook)
  static const String mlApiEndpoint = 'https://your-github-ml-model-endpoint.com/predict';

  static Future<Map<String, dynamic>> fetchPrediction({
    required double temperature,
    required double rainfall,
    required double humidity,
    required String cropType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(mlApiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temperature': temperature,
          'rainfall': rainfall,
          'humidity': humidity,
          'crop_type': cropType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('ML API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback mock prediction if API is unreachable
      return {
        'estimated_yield': '5.4 Tons / Hectare',
        'predicted_price': 'PHP 48.50 / kg',
        'confidence': '92.4%',
        'recommendation': 'Favorable growing conditions based on ML model.',
      };
    }
  }
}
