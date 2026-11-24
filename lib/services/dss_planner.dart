import '../core/dss_catalog.dart';

class CostLine {
  final String labelTl, labelEn;
  final double amount;
  final String? detailTl, detailEn;
  const CostLine(this.labelTl, this.labelEn, this.amount, {this.detailTl, this.detailEn});
  String label(bool tl) => tl ? labelTl : labelEn;
  String? detail(bool tl) => tl ? detailTl : detailEn;
}

class FertApp {
  final DateTime? date; // null = taunan
  final int day;
  final FertProduct product;
  final double bags; // sako (50 kg) para sa buong lawak
  final String noteTl, noteEn;
  const FertApp(this.date, this.day, this.product, this.bags, this.noteTl, this.noteEn);
  double get kg => bags * 50;
  String note(bool tl) => tl ? noteTl : noteEn;
}

/// Mga sariling numero ng farmer sa gastos (pamalit sa tantiya ng katalogo).
/// Ang [seeds], [pesticide], [labor] at [other] ay KABUUANG halaga (₱) para sa buong lawak, hindi kada ektarya.
/// Ang [bags] ay kabuuang sako bawat uri ng abono, at ang [price] ay presyo kada sako.
class CostOverride {
  final double? seeds, pesticide, labor, other;
  final Map<FertProduct, double> bags;
  final Map<FertProduct, double> price;
  const CostOverride({this.seeds, this.pesticide, this.labor, this.other, this.bags = const {}, this.price = const {}});

  bool get isEmpty => seeds == null && pesticide == null && labor == null && other == null && bags.isEmpty && price.isEmpty;
}

/// Resulta ng DSS: rekomendasyon ng abono at peste, gastos, ani at kita batay sa pananim, lupa, lawak at petsa.
/// Lahat ay TANTIYA at gabay lamang.
class DssPlan {
  final DssCrop crop;
  final SoilType soil;
  final double areaHa;
  final DateTime plantedOn;

  final DateTime? harvestFrom, harvestMid, harvestTo;
  final bool perennial;
  final DateTime? firstHarvest;
  final bool bearing;

  final double yLow, yMid, yHigh; // kabuuan para sa lawak (bawat taon kung pangmatagalan)
  final String unit;

  final double price;
  final bool priceReal;
  final bool priceFromUser;

  final List<CostLine> costs;
  final double totalCost;
  final double incLow, incMid, incHigh;

  final List<FertApp> fert;
  final Suit soilFit;
  final Suit seasonFit; // good = pinakamainam na buwan, fair = posible, poor = hindi panahon, unknown = walang datos

  const DssPlan({
    required this.crop,
    required this.soil,
    required this.areaHa,
    required this.plantedOn,
    required this.harvestFrom,
    required this.harvestMid,
    required this.harvestTo,
    required this.perennial,
    required this.firstHarvest,
    required this.bearing,
    required this.yLow,
    required this.yMid,
    required this.yHigh,
    required this.unit,
    required this.price,
    required this.priceReal,
    required this.priceFromUser,
    required this.costs,
    required this.totalCost,
    required this.incLow,
    required this.incMid,
    required this.incHigh,
    required this.fert,
    required this.soilFit,
    required this.seasonFit,
  });

  double get netLow => incLow - totalCost;
  double get netMid => incMid - totalCost;
  double get netHigh => incHigh - totalCost;

  static Suit soilSuitability(DssCrop c, SoilType s) {
    if (s == SoilType.unknown) return Suit.unknown;
    if (c.soilGood.contains(s)) return Suit.good;
    if (c.soilFair.contains(s)) return Suit.fair;
    return Suit.poor;
  }

  static Suit seasonSuitability(DssCrop c, int month) {
    if (c.best.isEmpty && c.possible.isEmpty) return Suit.unknown;
    if (c.best.contains(month)) return Suit.good;
    if (c.possible.contains(month)) return Suit.fair;
    return Suit.poor;
  }

  /// [harvestOn]: sariling petsa ng pag-aani (kung binago ng farmer). [userPrice]: sariling presyo bawat kg (o piraso).
  static DssPlan build({
    required DssCrop crop,
    required SoilType soil,
    required double areaHa,
    required DateTime plantedOn,
    DateTime? harvestOn,
    double? userPrice,
    CostOverride? costOv,
  }) {
    final now = DateTime.now();
    final perennial = crop.perennial;

    // --- Petsa ng ani ---
    DateTime? hFrom, hMid, hTo, first;
    var bearing = false;
    if (perennial) {
      first = plantedOn.add(Duration(days: crop.firstHarvestDays ?? 0));
      bearing = !now.isBefore(first);
    } else if (crop.days != null) {
      hFrom = plantedOn.add(Duration(days: crop.days!.$1));
      hTo = plantedOn.add(Duration(days: crop.days!.$2));
      hMid = hFrom.add(Duration(days: hTo.difference(hFrom).inDays ~/ 2));
      if (harvestOn != null) hMid = harvestOn;
    }

    // --- Ani ---
    final y = crop.yieldPerHa;
    final yLow = y.$1 * areaHa, yMid = y.$2 * areaHa, yHigh = y.$3 * areaHa;

    // --- Presyo ---
    final month = (hMid ?? (bearing ? now : (first ?? plantedOn))).month;
    final f = crop.facts;
    double price;
    var real = false;
    if (userPrice != null && userPrice > 0) {
      price = userPrice;
    } else if (crop.priceOverride != null) {
      price = crop.priceOverride!;
    } else if (f != null && f.priceForMonth(month) != null) {
      price = f.priceForMonth(month)!;
      real = f.hasRealPrice(month);
    } else {
      price = crop.defaultPrice;
    }

    // --- Abono ---
    final ageDays = now.difference(plantedOn).inDays;
    List<FertStep> steps;
    if (crop.id == 'Cacao') {
      steps = ageDays >= 730 ? crop.matureSteps : crop.steps.where((s) => s.day <= 365).toList();
    } else {
      steps = crop.steps;
    }
    final fert0 = <FertApp>[
      for (final s in steps)
        FertApp(
          s.day < 0 ? null : plantedOn.add(Duration(days: s.day)),
          s.day,
          s.product,
          s.bagsPerHa * areaHa,
          s.noteTl,
          s.noteEn,
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));

    // Kung binago ng farmer ang kabuuang sako ng isang abono, i-scale ang bawat paglalagay nang proporsyonal.
    final totals0 = <FertProduct, double>{};
    for (final a in fert0) {
      totals0[a.product] = (totals0[a.product] ?? 0) + a.bags;
    }
    final factor = <FertProduct, double>{};
    for (final e in totals0.entries) {
      final ob = costOv?.bags[e.key];
      factor[e.key] = (ob != null && e.value > 0) ? ob / e.value : 1.0;
    }
    final fert = <FertApp>[
      for (final a in fert0) FertApp(a.date, a.day, a.product, a.bags * (factor[a.product] ?? 1.0), a.noteTl, a.noteEn),
    ];

    // --- Gastos ---
    final fertByProduct = <FertProduct, double>{};
    for (final a in fert) {
      fertByProduct[a.product] = (fertByProduct[a.product] ?? 0) + a.bags;
    }
    final lines = <CostLine>[];
    var fertTotal = 0.0;
    for (final e in fertByProduct.entries) {
      fertTotal += e.value * (costOv?.price[e.key] ?? kFertPrice[e.key] ?? 0);
    }
    lines.add(CostLine(
      'Abono',
      'Fertilizer',
      fertTotal,
      detailTl: fertByProduct.entries.map((e) => '${fertName(e.key, true)}: ${_bags(e.value)}').join(' · '),
      detailEn: fertByProduct.entries.map((e) => '${fertName(e.key, false)}: ${_bags(e.value)}').join(' · '),
    ));
    final c = crop.cost;
    lines.add(CostLine('Binhi / pantanim', 'Seeds / planting material', costOv?.seeds ?? c.seeds * areaHa));
    lines.add(CostLine('Pestisidyo at pamatay-peste', 'Pesticides', costOv?.pesticide ?? c.pesticide * areaHa));
    lines.add(CostLine('Lakas-paggawa', 'Labor', costOv?.labor ?? c.labor * areaHa));
    lines.add(CostLine('Iba pa (patubig, hakot, upa, atbp.)', 'Others (irrigation, hauling, rentals, etc.)', costOv?.other ?? c.other * areaHa));
    if (perennial && c.establish > 0 && ageDays < 365) {
      lines.add(CostLine('Pagtatatag (punla)', 'Establishment (seedlings)', c.establish * areaHa));
    }
    final total = lines.fold<double>(0, (s, l) => s + l.amount);

    return DssPlan(
      crop: crop,
      soil: soil,
      areaHa: areaHa,
      plantedOn: plantedOn,
      harvestFrom: hFrom,
      harvestMid: hMid,
      harvestTo: hTo,
      perennial: perennial,
      firstHarvest: first,
      bearing: bearing,
      yLow: yLow,
      yMid: yMid,
      yHigh: yHigh,
      unit: crop.unit,
      price: price,
      priceReal: real,
      priceFromUser: userPrice != null && userPrice > 0,
      costs: lines,
      totalCost: total,
      incLow: yLow * price,
      incMid: yMid * price,
      incHigh: yHigh * price,
      fert: fert,
      soilFit: soilSuitability(crop, soil),
      seasonFit: seasonSuitability(crop, plantedOn.month),
    );
  }

  static String _bags(double b) => '${b.toStringAsFixed(b >= 10 ? 0 : 1)} sako';

  /// Mga payo tungkol sa uri ng lupa para sa pananim na ito.
  String soilAdvice(bool tl) {
    final base = soilHint(soil, tl);
    switch (soilFit) {
      case Suit.good:
        return tl ? 'Angkop ang lupang ito sa ${crop.nameTl}. $base' : 'This soil suits ${crop.nameEn}. $base';
      case Suit.fair:
        return tl
            ? 'Puwede ang lupang ito sa ${crop.nameTl}, pero hindi ang pinakamainam. $base'
            : 'This soil can grow ${crop.nameEn}, but it is not the best. $base';
      case Suit.poor:
        return tl
            ? 'Hindi gaanong angkop ang lupang ito sa ${crop.nameTl}. Kung itatanim pa rin, dagdagan ang organikong abono at ayusin ang daluyan ng tubig. $base'
            : 'This soil is not well suited to ${crop.nameEn}. If you still plant it, add organic fertilizer and improve drainage. $base';
      case Suit.unknown:
        return base;
    }
  }
}