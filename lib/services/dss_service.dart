import '../core/crop_data.dart';
import '../models/farm_planting.dart';

/// Tantiyang ani at kita ng isang tanim, may saklaw (mababa - malamang - mataas).
class HarvestEstimate {
  final double kgLow, kgMid, kgHigh;
  final double kgPerHaMid;
  final bool usesOwnYield;
  final DateTime? harvestFrom;
  final DateTime? harvestTo;
  final double? priceLow, priceMid, priceHigh;
  final double? incomeLow, incomeMid, incomeHigh;

  const HarvestEstimate({
    required this.kgLow,
    required this.kgMid,
    required this.kgHigh,
    required this.kgPerHaMid,
    required this.usesOwnYield,
    this.harvestFrom,
    this.harvestTo,
    this.priceLow,
    this.priceMid,
    this.priceHigh,
    this.incomeLow,
    this.incomeMid,
    this.incomeHigh,
  });

  bool get hasPrice => priceMid != null;
}

enum PlantFit { best, possible, avoid }

/// MGA SIMPLENG ALITUNTUNIN (hindi napatunayang forecast).
class DssService {
  static PlantFit fitFor(String crop, int month) {
    final f = factsFor(crop);
    if (f == null) return PlantFit.possible;
    if (f.bestMonths.contains(month)) return PlantFit.best;
    if (f.possibleMonths.contains(month)) return PlantFit.possible;
    return PlantFit.avoid;
  }

  /// Buwan (1-12) ng ani kung itatanim sa [plantMonth].
  static int harvestMonthFor(String crop, int plantMonth) {
    final f = factsFor(crop);
    if (f == null || !f.hasHarvestDays) return plantMonth;
    final offset = ((f.minDays! + f.maxDays!) / 2 / 30).round();
    return ((plantMonth - 1 + offset) % 12) + 1;
  }

  /// 12 halaga (index 0 = Enero). 100 = karaniwang presyo.
  /// Mababa kapag maraming ani sa buwang iyon, mataas kapag kakaunti.
  static List<double> priceIndex(String crop) {
    final f = factsFor(crop);
    if (f == null || !f.hasHarvestDays) return List.filled(12, 100.0);
    final supply = List.filled(12, 0.0);
    for (final m in f.bestMonths) {
      supply[harvestMonthFor(crop, m) - 1] += 1.0;
    }
    for (final m in f.possibleMonths) {
      supply[harvestMonthFor(crop, m) - 1] += 0.5;
    }
    final sm = List.generate(12, (i) => supply[i] * 0.6 + 0.2 * (supply[(i + 11) % 12] + supply[(i + 1) % 12]));
    var mx = 0.0;
    for (final v in sm) {
      if (v > mx) mx = v;
    }
    if (mx <= 0) return List.filled(12, 100.0);
    return [for (final v in sm) 112 - 24 * (v / mx)];
  }

  /// Presyo (PHP/kg) kada buwan = halimbawang presyo x index. Null kung walang halimbawang presyo.
  static List<double>? monthlyPrices(String crop) {
    final base = factsFor(crop)?.basePrice;
    if (base == null) return null;
    return [for (final i in priceIndex(crop)) base * i / 100];
  }

  /// Susunod na pinakamagandang buwan ng pagtatanim simula sa [fromMonth].
  static List<int> nextBestMonths(String crop, int fromMonth, {int count = 2}) {
    final f = factsFor(crop);
    final out = <int>[];
    if (f == null) return out;
    for (var k = 0; k < 12 && out.length < count; k++) {
      final m = ((fromMonth - 1 + k) % 12) + 1;
      if (f.bestMonths.contains(m)) out.add(m);
    }
    return out;
  }

  /// Mga buwan na mataas ang inaasahang presyo (pinakamataas na 3).
  static List<int> bestSellMonths(String crop) {
    final idx = priceIndex(crop);
    final order = List.generate(12, (i) => i)..sort((a, b) => idx[b].compareTo(idx[a]));
    final top = order.take(3).map((e) => e + 1).toList()..sort();
    return top;
  }

  static HarvestEstimate? estimate(FarmPlanting p) {
    final f = factsFor(p.crop);
    if (f == null || p.hectares <= 0) return null;

    final own = p.lastYieldKg != null && p.lastYieldKg! > 0;
    final double mid = own ? p.lastYieldKg! / p.hectares : f.midKgHa.toDouble();
    final double lo = own ? mid * 0.85 : f.lowKgHa.toDouble();
    final double hi = own ? mid * 1.15 : f.highKgHa.toDouble();

    DateTime? from, to;
    if (f.hasHarvestDays) {
      from = p.plantedOn.add(Duration(days: f.minDays!));
      to = p.plantedOn.add(Duration(days: f.maxDays!));
    }

    double? pLow, pMid, pHigh;
    final prices = monthlyPrices(p.crop);
    if (prices != null) {
      final hd = (from != null && to != null) ? from.add(Duration(days: to.difference(from).inDays ~/ 2)) : DateTime.now();
      pMid = prices[hd.month - 1];
      pLow = pMid * 0.92;
      pHigh = pMid * 1.08;
    }

    final kgLow = lo * p.hectares, kgMid = mid * p.hectares, kgHigh = hi * p.hectares;
    return HarvestEstimate(
      kgLow: kgLow,
      kgMid: kgMid,
      kgHigh: kgHigh,
      kgPerHaMid: mid,
      usesOwnYield: own,
      harvestFrom: from,
      harvestTo: to,
      priceLow: pLow,
      priceMid: pMid,
      priceHigh: pHigh,
      incomeLow: pLow == null ? null : kgLow * pLow,
      incomeMid: pMid == null ? null : kgMid * pMid,
      incomeHigh: pHigh == null ? null : kgHigh * pHigh,
    );
  }
}