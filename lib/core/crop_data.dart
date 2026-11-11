/// Mga datos ng pananim na ginagamit ng DSS.
///
/// PAALALA:
/// - PRESYO (monthlyPrice): totoong farmgate price mula sa Tanggapan ng Pambayang Agrikultura (Mayo-Nobyembre).
///   Ang Rice ay wala sa datos kaya tantiya pa rin ang presyo nila (basePrice).
/// - ANI, tagal bago maani, at buwan ng pagtatanim: TANTIYA / GABAY LAMANG. Ipa-verify sa MAO.
class CropFacts {
  /// Tantiyang araw bago maani (min, max). Null kung taon ang hinihintay.
  final int? minDays;
  final int? maxDays;

  /// Tipikal na ani bawat hektarya, sa [unit] (kg, tali, o piraso). Bawat taon para sa Saging, Niyog, Calamansi.
  /// (Luma ang pangalan ng field - "KgHa" - pero sumusunod ito sa [unit].)
  final int lowKgHa;
  final int midKgHa;
  final int highKgHa;

  /// Sukatan ng ani at presyo: 'kg', 'tali' o 'pc'.
  final String unit;

  /// Tumatagal ba kapag iniimbak (puwedeng hintayin ang mas mataas na presyo).
  final bool storable;

  /// Pinakamainam at posibleng buwan ng pagtatanim (1-12).
  final Set<int> bestMonths;
  final Set<int> possibleMonths;

  /// Tantiyang presyo kung walang datos buwan-buwan.
  final double? _basePrice;

  /// Totoong farmgate price kada buwan (12 halaga, index 0 = Enero). Null ang buwang walang datos.
  final List<double?>? monthlyPrice;

  const CropFacts({
    this.minDays,
    this.maxDays,
    required this.lowKgHa,
    required this.midKgHa,
    required this.highKgHa,
    this.unit = 'kg',
    this.storable = false,
    required this.bestMonths,
    required this.possibleMonths,
    double? basePrice,
    this.monthlyPrice,
  }) : _basePrice = basePrice; // ignore: prefer_initializing_formals

  bool get hasHarvestDays => minDays != null && maxDays != null;

  /// Karaniwang presyo: average ng mga buwang may datos, o ang tantiya.
  double? get basePrice {
    final m = monthlyPrice;
    if (m == null) return _basePrice;
    final v = m.whereType<double>().toList();
    if (v.isEmpty) return _basePrice;
    return v.reduce((a, b) => a + b) / v.length;
  }

  /// Presyo para sa buwan (1-12). Kung walang datos ang buwan (Dis-Abr), average ang gamit.
  double? priceForMonth(int month) {
    final m = monthlyPrice;
    if (m == null) return _basePrice;
    return m[(month - 1) % 12] ?? basePrice;
  }

  /// May totoong datos ba ang presyo sa buwan na ito?
  bool hasRealPrice(int month) => monthlyPrice != null && monthlyPrice![(month - 1) % 12] != null;

  /// Kopya na may ibang buwan ng pagtatanim (ginagamit ng setCropCalendar).
  CropFacts withMonths(Set<int> best, Set<int> possible) => CropFacts(
    minDays: minDays,
    maxDays: maxDays,
    lowKgHa: lowKgHa,
    midKgHa: midKgHa,
    highKgHa: highKgHa,
    unit: unit,
    storable: storable,
    bestMonths: best,
    possibleMonths: possible,
    basePrice: _basePrice,
    monthlyPrice: monthlyPrice,
  );
}

const Map<String, CropFacts> kCropFacts = {
  'Rice': CropFacts(minDays: 110, maxDays: 120, lowKgHa: 3000, midKgHa: 4200, highKgHa: 5500, storable: true, bestMonths: {6, 7, 11, 12}, possibleMonths: {1, 5, 8, 10}, basePrice: 46.0),
  'Eggplant': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 8000, midKgHa: 12000, highKgHa: 16000, bestMonths: {10, 11, 12}, possibleMonths: {1, 2, 9}, monthlyPrice: [null, null, null, null, 35.0, 40.0, 55.0, 77.5, 110.0, 75.0, 75.0, null]),
  'Tomato': CropFacts(minDays: 90, maxDays: 110, lowKgHa: 8000, midKgHa: 12000, highKgHa: 18000, bestMonths: {10, 11, 12}, possibleMonths: {1, 9}, monthlyPrice: [null, null, null, null, 15.0, 40.0, 80.0, 67.5, 70.0, 67.5, 70.0, null]),
  'String beans': CropFacts(minDays: 60, maxDays: 70, lowKgHa: 4000, midKgHa: 6000, highKgHa: 8500, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 5, 6, 9}, monthlyPrice: [null, null, null, null, 65.0, 70.0, 45.0, 55.0, 90.0, 62.5, 70.0, null]),
  'Coconut': CropFacts(lowKgHa: 5000, midKgHa: 8000, highKgHa: 11000, storable: true, bestMonths: {6, 7, 8}, possibleMonths: {5, 9, 10}, unit: 'pc', monthlyPrice: [null, null, null, null, 10.0, 17.5, 20.0, 25.0, null, null, null, null]),
  'Ampalaya': CropFacts(minDays: 60, maxDays: 90, lowKgHa: 6000, midKgHa: 9000, highKgHa: 13000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 3, 9}, monthlyPrice: [null, null, null, null, 60.0, 55.0, 47.5, 67.5, 110.0, 67.5, 80.0, null]),
  'Squash': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 8000, midKgHa: 12000, highKgHa: 18000, bestMonths: {10, 11, 12}, possibleMonths: {1, 2, 9}, monthlyPrice: [null, null, null, null, 25.0, 30.0, 37.5, 35.0, 25.0, 27.5, 40.0, null]),
  'Sweet potato': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 6000, midKgHa: 9000, highKgHa: 14000, storable: true, bestMonths: {5, 6, 7, 8}, possibleMonths: {4, 9, 10}, monthlyPrice: [null, null, null, null, 50.0, 65.0, 69.0, 65.0, 60.0, 55.0, 50.0, null]),
  'Taro': CropFacts(minDays: 180, maxDays: 270, lowKgHa: 6000, midKgHa: 10000, highKgHa: 15000, storable: true, bestMonths: {5, 6, 7}, possibleMonths: {4, 8, 9}, monthlyPrice: [null, null, null, null, 40.0, 40.0, 45.0, 50.0, 60.0, 67.5, 65.0, null]),
  'Calamansi': CropFacts(lowKgHa: 6000, midKgHa: 10000, highKgHa: 16000, bestMonths: {6, 7, 8}, possibleMonths: {5, 9, 10}, monthlyPrice: [null, null, null, null, 60.0, 75.0, 97.5, 67.5, 40.0, 40.0, 50.0, null]),
  'Pechay (Tagalog)': CropFacts(minDays: 25, maxDays: 35, lowKgHa: 8000, midKgHa: 12000, highKgHa: 16000, bestMonths: {1, 2, 10, 11, 12}, possibleMonths: {3, 9}, monthlyPrice: [null, null, null, null, 70.0, 70.0, 32.5, 60.0, 100.0, 85.0, 65.0, null]),
  'Radish': CropFacts(minDays: 30, maxDays: 45, lowKgHa: 10000, midKgHa: 15000, highKgHa: 20000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 35.0, 70.0, 32.5, 40.0, 90.0, 82.5, 75.0, null]),
  'Chili (long)': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 3000, midKgHa: 5000, highKgHa: 8000, bestMonths: {10, 11, 12}, possibleMonths: {1, 9}, monthlyPrice: [null, null, null, null, 50.0, 55.0, 35.0, 32.5, 95.0, 87.5, 70.0, null]),
  'Okra': CropFacts(minDays: 50, maxDays: 60, lowKgHa: 6000, midKgHa: 9000, highKgHa: 12000, bestMonths: {4, 5, 6, 10, 11}, possibleMonths: {3, 7, 9, 12}, monthlyPrice: [null, null, null, null, 30.0, 40.0, 25.0, 32.5, 70.0, 67.5, 55.0, null]),
  'Upo': CropFacts(minDays: 60, maxDays: 80, lowKgHa: 12000, midKgHa: 20000, highKgHa: 30000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, unit: 'pc', monthlyPrice: [null, null, null, null, 5.0, 20.0, 25.0, 32.5, 30.0, 40.0, 40.0, null]),
  'Patola': CropFacts(minDays: 60, maxDays: 75, lowKgHa: 8000, midKgHa: 12000, highKgHa: 16000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 25.0, 30.0, 35.0, 40.0, 40.0, 35.0, 45.0, null]),
  'Potato': CropFacts(minDays: 90, maxDays: 110, lowKgHa: 10000, midKgHa: 15000, highKgHa: 22000, storable: true, bestMonths: {1, 11, 12}, possibleMonths: {2, 10}, monthlyPrice: [null, null, null, null, 42.0, 100.0, 95.0, 80.0, 110.0, 92.5, 85.0, null]),
  'Mustasa': CropFacts(minDays: 30, maxDays: 45, lowKgHa: 8000, midKgHa: 12000, highKgHa: 16000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 80.0, 95.0, 50.0, 32.5, 120.0, 85.0, 65.0, null]),
  'Cabbage': CropFacts(minDays: 70, maxDays: 90, lowKgHa: 20000, midKgHa: 30000, highKgHa: 40000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 15.0, 65.0, 36.0, 37.5, 75.0, 125.0, 110.0, null]),
  'Carrot': CropFacts(minDays: 70, maxDays: 100, lowKgHa: 15000, midKgHa: 22000, highKgHa: 30000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 100.0, 80.0, 61.5, 57.5, 70.0, 75.0, 80.0, null]),
  'Beans': CropFacts(minDays: 55, maxDays: 70, lowKgHa: 5000, midKgHa: 7500, highKgHa: 10000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 90.0, 90.0, 52.5, 70.0, 80.0, 65.0, 65.0, null]),
  'Pechay (Baguio)': CropFacts(minDays: 60, maxDays: 75, lowKgHa: 15000, midKgHa: 25000, highKgHa: 35000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 30.0, 80.0, 40.0, 37.5, 125.0, 120.0, 115.0, null]),
  'Garlic': CropFacts(minDays: 100, maxDays: 120, lowKgHa: 3000, midKgHa: 5000, highKgHa: 7000, storable: true, bestMonths: {10, 11, 12}, possibleMonths: {1, 9}, monthlyPrice: [null, null, null, null, 78.0, 130.0, 52.5, 51.5, 48.0, 140.0, 120.0, null]),
  'Onion': CropFacts(minDays: 100, maxDays: 120, lowKgHa: 8000, midKgHa: 12000, highKgHa: 18000, storable: true, bestMonths: {10, 11, 12}, possibleMonths: {1}, monthlyPrice: [null, null, null, null, 45.0, 100.0, 70.0, 72.5, 75.0, 125.0, 130.0, null]),
  'Kangkong': CropFacts(minDays: 25, maxDays: 35, lowKgHa: 20000, midKgHa: 30000, highKgHa: 45000, bestMonths: {5, 6, 7, 8, 9, 10}, possibleMonths: {1, 2, 3, 4, 11, 12}, unit: 'tali', monthlyPrice: [null, null, null, null, 5.0, 7.0, 7.0, 6.5, 7.0, 7.0, 7.0, null]),
  'Celery': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 20000, midKgHa: 30000, highKgHa: 40000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 9}, monthlyPrice: [null, null, null, null, 90.0, 200.0, 15.0, 28.0, 280.0, 52.5, 65.0, null]),
  'Cucumber': CropFacts(minDays: 45, maxDays: 60, lowKgHa: 10000, midKgHa: 15000, highKgHa: 22000, bestMonths: {1, 10, 11, 12}, possibleMonths: {2, 3, 9}, monthlyPrice: [null, null, null, null, 40.0, 50.0, 35.0, 42.5, 45.0, 40.0, 40.0, null]),
  'Sayote': CropFacts(minDays: 120, maxDays: 150, lowKgHa: 15000, midKgHa: 25000, highKgHa: 35000, bestMonths: {5, 6, 7}, possibleMonths: {4, 8}, monthlyPrice: [null, null, null, null, 40.0, 50.0, 26.5, 24.0, 70.0, 77.5, 90.0, null]),
  'Chili (hot)': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 1500, midKgHa: 3000, highKgHa: 5000, bestMonths: {10, 11, 12}, possibleMonths: {1, 9}, monthlyPrice: [null, null, null, null, 70.0, 110.0, 57.5, 37.5, 100.0, 205.0, 175.0, null]),
  'Bell pepper': CropFacts(minDays: 70, maxDays: 90, lowKgHa: 8000, midKgHa: 12000, highKgHa: 18000, bestMonths: {10, 11, 12}, possibleMonths: {1, 9}, monthlyPrice: [null, null, null, null, 160.0, 250.0, 85.0, 75.0, 140.0, 37.5, 50.0, null]),
  'Ginger': CropFacts(minDays: 240, maxDays: 270, lowKgHa: 8000, midKgHa: 15000, highKgHa: 25000, storable: true, bestMonths: {4, 5, 6}, possibleMonths: {3, 7}, monthlyPrice: [null, null, null, null, 80.0, 110.0, 105.0, 85.0, 80.0, 75.0, 80.0, null]),
  'Saba': CropFacts(minDays: 270, maxDays: 360, lowKgHa: 10000, midKgHa: 18000, highKgHa: 28000, bestMonths: {5, 6, 7, 8}, possibleMonths: {4, 9, 10}, monthlyPrice: [null, null, null, null, 35.0, 25.0, 25.0, 22.5, 30.0, 47.5, 45.0, null]),
  'Lakatan': CropFacts(minDays: 300, maxDays: 360, lowKgHa: 12000, midKgHa: 20000, highKgHa: 30000, bestMonths: {5, 6, 7, 8}, possibleMonths: {4, 9, 10}, monthlyPrice: [null, null, null, null, 90.0, 85.0, 53.5, 57.5, 65.0, 67.5, 55.0, null]),
  'Tordan': CropFacts(minDays: 300, maxDays: 360, lowKgHa: 12000, midKgHa: 18000, highKgHa: 26000, bestMonths: {5, 6, 7, 8}, possibleMonths: {4, 9, 10}, monthlyPrice: [null, null, null, null, 45.0, 50.0, 40.0, 40.0, 50.0, 60.0, 50.0, null]),
};

/// Iisang pinagmulan ng kalendaryo ng pagtatanim: ang mga PlantingGuide sa farmer_repository.dart.
/// Pagkaload ng app, ipinapasa ng DashboardProvider ang mga buwan dito (setCropCalendar), kaya
/// pareho ang nakikita sa DSS, My Farm, mga abiso, at presyo. Para baguhin ang mga buwan,
/// sa farmer_repository.dart lang mag-edit.
final Map<String, ({Set<int> best, Set<int> possible})> _calendar = {};

void setCropCalendar(String crop, Set<int> best, Set<int> possible) {
  _calendar[crop] = (best: best, possible: possible);
}

CropFacts? factsFor(String crop) {
  final clean = crop.trim().toLowerCase();

  // 1. Exact match
  for (final entry in kCropFacts.entries) {
    if (entry.key.toLowerCase() == clean) {
      final cal = _calendar[entry.key];
      return cal == null ? entry.value : entry.value.withMonths(cal.best, cal.possible);
    }
  }

  // 2. Substring match (e.g. 'Talong (Eggplant)' matches 'Eggplant' or 'Talong')
  for (final entry in kCropFacts.entries) {
    final keyLc = entry.key.toLowerCase();
    if (clean.contains(keyLc) || keyLc.contains(clean)) {
      final cal = _calendar[entry.key];
      return cal == null ? entry.value : entry.value.withMonths(cal.best, cal.possible);
    }
  }

  // 3. Word token match
  final words = clean.replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
  for (final entry in kCropFacts.entries) {
    final keyLc = entry.key.toLowerCase();
    for (final w in words) {
      if (w.length > 2 && keyLc.contains(w)) {
        final cal = _calendar[entry.key];
        return cal == null ? entry.value : entry.value.withMonths(cal.best, cal.possible);
      }
    }
  }

  // Fallback CropFacts for custom/unknown crops
  return kCropFacts.values.first;
}

/// Live Supabase prices loaded from market_farmgate_prices & price_forecasts tables
final Map<String, double> _liveFarmgatePrices = {};
final Map<String, double> _liveMarketPrices = {};
final Map<String, double> _liveMlForecasts = {};
final Map<String, String> _liveMlModels = {};

void updateLiveSupabasePrices({
  required Map<String, double> farmgatePrices,
  required Map<String, double> marketPrices,
  required Map<String, double> mlForecasts,
  required Map<String, String> mlModels,
}) {
  _liveFarmgatePrices.clear();
  _liveFarmgatePrices.addAll(farmgatePrices);
  _liveMarketPrices.clear();
  _liveMarketPrices.addAll(marketPrices);
  _liveMlForecasts.clear();
  _liveMlForecasts.addAll(mlForecasts);
  _liveMlModels.clear();
  _liveMlModels.addAll(mlModels);
}

/// Presyo (PHP kada [CropFacts.unit]) ng pananim sa buwan. Unang binabasa mula sa Supabase market_farmgate_prices.
double? farmgatePrice(String crop, int month) {
  final clean = crop.trim().toLowerCase();
  for (final entry in _liveFarmgatePrices.entries) {
    final keyLc = entry.key.toLowerCase();
    if (clean.contains(keyLc) || keyLc.contains(clean)) {
      return entry.value;
    }
  }
  return kCropFacts[crop]?.priceForMonth(month) ?? kCropFacts[crop]?.basePrice;
}

/// Kuhaning live Presyo sa Palengke (Market Price) mula sa Supabase market_farmgate_prices.
double? getLiveMarketPrice(String crop) {
  final clean = crop.trim().toLowerCase();
  for (final entry in _liveMarketPrices.entries) {
    final keyLc = entry.key.toLowerCase();
    if (clean.contains(keyLc) || keyLc.contains(clean)) {
      return entry.value;
    }
  }
  return null;
}

/// Kuhaning live ML Forecast price mula sa Supabase price_forecasts.
double? getLiveMlForecastPrice(String crop) {
  final clean = crop.trim().toLowerCase();
  for (final entry in _liveMlForecasts.entries) {
    final keyLc = entry.key.toLowerCase();
    if (clean.contains(keyLc) || keyLc.contains(clean)) {
      return entry.value;
    }
  }
  return null;
}

/// Kuhaning ML model name mula sa Supabase price_forecasts.
String? getLiveMlModelName(String crop) {
  final clean = crop.trim().toLowerCase();
  for (final entry in _liveMlModels.entries) {
    final keyLc = entry.key.toLowerCase();
    if (clean.contains(keyLc) || keyLc.contains(clean)) {
      return entry.value;
    }
  }
  return null;
}