import 'supabase_service.dart';

class DssMlService {
  /// Queries the precomputed ML yield estimate (kg/ha) for a given crop, barangay, and month.
  static Future<double?> fetchYieldEstimate({
    required String crop,
    required String barangay,
    required int month,
  }) async {
    try {
      final res = await SupabaseService.client
          .from('yield_estimates')
          .select('yield_kg_ha')
          .eq('crop', crop)
          .eq('barangay', barangay)
          .eq('month', month)
          .maybeSingle();

      if (res != null) {
        return (res['yield_kg_ha'] as num?)?.toDouble();
      }

      // Fallback query for municipality-wide 'ALL' average
      final allRes = await SupabaseService.client
          .from('yield_estimates')
          .select('yield_kg_ha')
          .eq('crop', crop)
          .eq('barangay', 'ALL')
          .eq('month', month)
          .maybeSingle();

      if (allRes != null) {
        return (allRes['yield_kg_ha'] as num?)?.toDouble();
      }
    } catch (_) {}

    return null;
  }

  /// Queries the precomputed ML price forecast (PHP/kg) for a given crop and date.
  static Future<double?> fetchPriceForecast({
    required String crop,
    required DateTime date,
  }) async {
    try {
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-01';
      final res = await SupabaseService.client
          .from('price_forecasts')
          .select('forecast_price')
          .eq('crop', crop)
          .eq('month', monthStr)
          .maybeSingle();

      if (res != null) {
        return (res['forecast_price'] as num?)?.toDouble();
      }
    } catch (_) {}

    return null;
  }

  /// Queries planting suitability score (0.0 to 1.0) for a given crop and month.
  static Future<double?> fetchPlantingSuitability({
    required String crop,
    required int month,
  }) async {
    try {
      final res = await SupabaseService.client
          .from('planting_advisory')
          .select('score')
          .eq('crop', crop)
          .eq('month', month)
          .maybeSingle();

      if (res != null) {
        return (res['score'] as num?)?.toDouble();
      }
    } catch (_) {}

    return null;
  }
}
