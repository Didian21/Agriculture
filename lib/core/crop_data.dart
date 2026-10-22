/// Mga datos ng pananim na ginagamit ng DSS.
///
/// PAALALA: ang mga bilang dito ay TANTIYA / GABAY LAMANG (hindi opisyal na datos).
/// Palitan ng tamang datos mula sa Tanggapan ng Pambayang Agrikultura (Pagsanjan)
/// bago gamitin sa totoong desisyon.
class CropFacts {
  /// Tantiyang araw bago maani (min, max). Null kung taon ang hinihintay.
  final int? minDays;
  final int? maxDays;

  /// Tipikal na ani sa kg bawat hektarya (bawat taniman; bawat taon para sa Saging, Niyog, Calamansi).
  final int lowKgHa;
  final int midKgHa;
  final int highKgHa;

  /// Tumatagal ba kapag iniimbak (puwedeng hintayin ang mas mataas na presyo).
  final bool storable;

  /// Pinakamainam at posibleng buwan ng pagtatanim (1-12). TANTIYA - ipa-verify sa Municipal Agriculture Office.
  final Set<int> bestMonths;
  final Set<int> possibleMonths;

  /// Halimbawang presyo (PHP kada kg) - hindi totoong presyo sa palengke.
  final double? basePrice;

  const CropFacts({
    this.minDays,
    this.maxDays,
    required this.lowKgHa,
    required this.midKgHa,
    required this.highKgHa,
    this.storable = false,
    required this.bestMonths,
    required this.possibleMonths,
    this.basePrice,
  });

  bool get hasHarvestDays => minDays != null && maxDays != null;

  /// Kopya na may ibang buwan ng pagtatanim (ginagamit ng setCropCalendar).
  CropFacts withMonths(Set<int> best, Set<int> possible) => CropFacts(
    minDays: minDays,
    maxDays: maxDays,
    lowKgHa: lowKgHa,
    midKgHa: midKgHa,
    highKgHa: highKgHa,
    storable: storable,
    bestMonths: best,
    possibleMonths: possible,
    basePrice: basePrice,
  );
}

const Map<String, CropFacts> kCropFacts = {
  'Rice': CropFacts(minDays: 110, maxDays: 120, lowKgHa: 3000, midKgHa: 4200, highKgHa: 5500, storable: true, bestMonths: {6, 7, 11, 12}, possibleMonths: {5, 8, 10, 1}, basePrice: 46.0),
  'Eggplant': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 8000, midKgHa: 12000, highKgHa: 16000, bestMonths: {10, 11, 12}, possibleMonths: {1, 2, 9}, basePrice: 60.0),
  'Tomato': CropFacts(minDays: 90, maxDays: 110, lowKgHa: 8000, midKgHa: 12000, highKgHa: 18000, bestMonths: {10, 11, 12}, possibleMonths: {1, 9}, basePrice: 55.0),
  'String beans': CropFacts(minDays: 60, maxDays: 70, lowKgHa: 4000, midKgHa: 6000, highKgHa: 8500, bestMonths: {10, 11, 12, 1}, possibleMonths: {2, 9, 5, 6}, basePrice: 70.0),
  'Banana': CropFacts(minDays: 270, maxDays: 360, lowKgHa: 10000, midKgHa: 18000, highKgHa: 28000, bestMonths: {5, 6, 7, 8}, possibleMonths: {4, 9, 10}, basePrice: 40.0),
  'Coconut': CropFacts(lowKgHa: 3000, midKgHa: 5000, highKgHa: 8000, storable: true, bestMonths: {6, 7, 8}, possibleMonths: {5, 9, 10}),
  'Ampalaya': CropFacts(minDays: 60, maxDays: 90, lowKgHa: 6000, midKgHa: 9000, highKgHa: 13000, bestMonths: {10, 11, 12, 1}, possibleMonths: {2, 3, 9}, basePrice: 65.0),
  'Squash': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 8000, midKgHa: 12000, highKgHa: 18000, bestMonths: {10, 11, 12}, possibleMonths: {1, 2, 9}, basePrice: 30.0),
  'Sweet potato': CropFacts(minDays: 90, maxDays: 120, lowKgHa: 6000, midKgHa: 9000, highKgHa: 14000, storable: true, bestMonths: {5, 6, 7, 8}, possibleMonths: {4, 9, 10}, basePrice: 35.0),
  'Taro': CropFacts(minDays: 180, maxDays: 270, lowKgHa: 6000, midKgHa: 10000, highKgHa: 15000, storable: true, bestMonths: {5, 6, 7}, possibleMonths: {4, 8, 9}, basePrice: 45.0),
  'Calamansi': CropFacts(lowKgHa: 6000, midKgHa: 10000, highKgHa: 16000, bestMonths: {6, 7, 8}, possibleMonths: {5, 9, 10}, basePrice: 70.0),
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
  final base = kCropFacts[crop];
  final cal = _calendar[crop];
  if (base == null || cal == null) return base;
  return base.withMonths(cal.best, cal.possible);
}