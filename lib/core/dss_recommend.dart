import '../services/dss_planner.dart';
import 'dss_catalog.dart';

/// Kondisyon ng lupa pagdating sa tubig (drainage).
enum Drainage { poor, good, fast, unknown }

/// Suplay ng tubig sa bukid.
enum WaterSupply { irrigated, rainOnly, limited, unknown }

const List<Drainage> kDrainOrder = [Drainage.poor, Drainage.good, Drainage.fast, Drainage.unknown];
const List<WaterSupply> kWaterOrder = [WaterSupply.irrigated, WaterSupply.rainOnly, WaterSupply.limited, WaterSupply.unknown];

String drainName(Drainage d, bool tl) {
  switch (d) {
    case Drainage.poor:
      return tl ? 'Laging basa / binabaha' : 'Always wet / floods';
    case Drainage.good:
      return tl ? 'Maayos ang agos ng tubig' : 'Drains well';
    case Drainage.fast:
      return tl ? 'Mabilis matuyo' : 'Dries quickly';
    case Drainage.unknown:
      return tl ? 'Hindi ko alam' : 'Not sure';
  }
}

String drainHint(Drainage d, bool tl) {
  switch (d) {
    case Drainage.poor:
      return tl ? 'Nakatayo ang tubig matapos ang ulan nang ilang araw.' : 'Water stands for days after rain.';
    case Drainage.good:
      return tl ? 'Natutuyo ang ibabaw sa loob ng isa o dalawang araw matapos umulan.' : 'The surface dries in a day or two after rain.';
    case Drainage.fast:
      return tl ? 'Mabilis tumagos ang tubig; madaling matuyo at kailangan ng madalas na patubig.' : 'Water drains fast; dries out and needs frequent irrigation.';
    case Drainage.unknown:
      return '';
  }
}

String waterName(WaterSupply w, bool tl) {
  switch (w) {
    case WaterSupply.irrigated:
      return tl ? 'May irigasyon / poso' : 'Irrigation / pump';
    case WaterSupply.rainOnly:
      return tl ? 'Ulan lang' : 'Rain only';
    case WaterSupply.limited:
      return tl ? 'Kulang ang tubig' : 'Limited water';
    case WaterSupply.unknown:
      return tl ? 'Hindi ko alam' : 'Not sure';
  }
}

/// Katangian ng pananim na ginagamit sa mungkahi (tantiya batay sa karaniwang kaalaman sa pagsasaka; hindi live na datos).
class CropTraits {
  final int waterNeed; // 1 = kaunti, 2 = katamtaman, 3 = marami (palayan na may tubig)
  final bool wetTolerant; // kaya ang lupang laging basa
  final bool droughtTolerant; // kaya ang tuyong lupa
  final int demand; // 1-3 antas ng demand sa pamilihan (tantiya)
  final String areaStyle; // 'small' (angkop sa maliit na taniman), 'large' (mas mainam sa malawak), 'any'
  final double minAreaHa; // pinakamaliit na praktikal na lawak
  final String demandTl, demandEn;
  const CropTraits({
    required this.waterNeed,
    required this.wetTolerant,
    required this.droughtTolerant,
    required this.demand,
    required this.areaStyle,
    this.minAreaHa = 0,
    required this.demandTl,
    required this.demandEn,
  });
}

const Map<String, CropTraits> kCropTraits = {
  'Rice': CropTraits(
    waterNeed: 3, wetTolerant: true, droughtTolerant: false, demand: 3, areaStyle: 'any',
    demandTl: 'Pangunahing pagkain; laging may bumibili.', demandEn: 'Staple food; there is always a buyer.',
  ),
  'Coconut': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: true, demand: 3, areaStyle: 'large', minAreaHa: 0.3,
    demandTl: 'May bumibili ng buko, kopra at iba pang produkto ng niyog.', demandEn: 'Buyers for young nuts, copra and other coconut products.',
  ),
  'Eggplant': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: false, demand: 3, areaStyle: 'small',
    demandTl: 'Karaniwang gulay; mataas ang demand buong taon.', demandEn: 'A common vegetable with demand all year.',
  ),
  'Squash': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: true, demand: 2, areaStyle: 'any',
    demandTl: 'Katamtaman ang demand; madaling itago at ibenta.', demandEn: 'Moderate demand; keeps well and is easy to sell.',
  ),
  'String beans': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: false, demand: 3, areaStyle: 'small',
    demandTl: 'Mataas ang demand sa pamilihan at karinderya.', demandEn: 'High demand in markets and eateries.',
  ),
  'Okra': CropTraits(
    waterNeed: 1, wetTolerant: false, droughtTolerant: true, demand: 2, areaStyle: 'small',
    demandTl: 'Katamtaman ang demand; madalas anihin (halos araw-araw).', demandEn: 'Moderate demand; harvested very often.',
  ),
  'Pechay (Tagalog)': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: false, demand: 3, areaStyle: 'small',
    demandTl: 'Araw-araw na gulay; mabilis ang ani pero nagbabago ang presyo.', demandEn: 'An everyday vegetable; quick harvest but prices swing.',
  ),
  'Chili (hot)': CropTraits(
    waterNeed: 1, wetTolerant: false, droughtTolerant: true, demand: 3, areaStyle: 'small',
    demandTl: 'Mataas ang demand pero malaki ang pagtaas at pagbaba ng presyo.', demandEn: 'High demand but prices rise and fall sharply.',
  ),
  'Chili (long)': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: false, demand: 2, areaStyle: 'small',
    demandTl: 'Katamtaman ang demand; kailangan ng mahusay na pag-aalaga.', demandEn: 'Moderate demand; needs good care.',
  ),
  'Cacao': CropTraits(
    waterNeed: 2, wetTolerant: false, droughtTolerant: false, demand: 3, areaStyle: 'large', minAreaHa: 0.25,
    demandTl: 'Malakas ang demand sa tuyong butil; pangmatagalan ang puhunan.', demandEn: 'Strong demand for dried beans; a long-term investment.',
  ),
  'Cassava': CropTraits(
    waterNeed: 1, wetTolerant: false, droughtTolerant: true, demand: 2, areaStyle: 'any',
    demandTl: 'Katamtaman ang demand (pagkain, almirol, patuka); mababa ang presyo.', demandEn: 'Moderate demand (food, starch, feed); low price.',
  ),
};

enum RecLevel { good, fair, poor }

/// Isang batayan sa mungkahi (lupa, tubig, panahon, atbp.) na may puntos.
class RecFactor {
  final String key; // 'soil', 'drain', 'water', 'season', 'area', 'market'
  final double pts, max;
  final String noteTl, noteEn;
  const RecFactor(this.key, this.pts, this.max, this.noteTl, this.noteEn);
  RecLevel get level => pts / max >= 0.75 ? RecLevel.good : (pts / max >= 0.4 ? RecLevel.fair : RecLevel.poor);
  String note(bool tl) => tl ? noteTl : noteEn;
}

class CropRec {
  final DssCrop crop;
  final double score; // 0-100
  final List<RecFactor> factors;
  final double netPerHa; // tantiyang tubo bawat ha (bawat taon kung pangmatagalan)
  final double roi; // tubo / gastos
  final CropTraits traits;
  const CropRec(this.crop, this.score, this.factors, this.netPerHa, this.roi, this.traits);

  RecFactor factor(String key) => factors.firstWhere((f) => f.key == key);
  List<RecFactor> get cautions => factors.where((f) => f.level == RecLevel.poor).toList();
}

class CropRecommender {
  /// Binibigyan ng puntos ang bawat pananim (0-100) batay sa lupa, kondisyon ng tubig, suplay ng tubig,
  /// buwan ng pagtatanim (klima), lawak, at demand at tubo. Ang mga timbang ay tantiya at gabay lamang.
  static List<CropRec> rank({
    required SoilType soil,
    required Drainage drain,
    required WaterSupply water,
    required double? areaHa,
    required DateTime plantedOn,
  }) {
    final out = <CropRec>[];
    for (final c in kDssCrops) {
      final t = kCropTraits[c.id];
      if (t == null) continue;

      // Lupa (25)
      final sf = DssPlan.soilSuitability(c, soil);
      final soilPts = {Suit.good: 25.0, Suit.fair: 15.0, Suit.poor: 4.0, Suit.unknown: 12.0}[sf]!;
      final soilF = RecFactor(
        'soil',
        soilPts,
        25,
        sf == Suit.good
            ? 'Angkop ang ${soilName(soil, true).toLowerCase()} sa ${c.nameTl}.'
            : sf == Suit.fair
            ? 'Puwede ang ${soilName(soil, true).toLowerCase()}, pero hindi ang pinakamainam.'
            : sf == Suit.poor
            ? 'Hindi gaanong angkop ang ${soilName(soil, true).toLowerCase()}.'
            : 'Hindi pa alam ang uri ng lupa.',
        sf == Suit.good
            ? '${soilName(soil, false)} suits ${c.nameEn}.'
            : sf == Suit.fair
            ? '${soilName(soil, false)} works, but it is not the best.'
            : sf == Suit.poor
            ? '${soilName(soil, false)} is not well suited.'
            : 'Soil type is not known yet.',
      );

      // Drainage (10)
      double dp;
      String dTl, dEn;
      switch (drain) {
        case Drainage.poor:
          if (t.wetTolerant) {
            dp = 10;
            dTl = 'Kaya ng pananim ang lupang laging basa.';
            dEn = 'The crop handles wet soil.';
          } else {
            dp = 0;
            dTl = 'Mabubulok ang ugat kapag laging basa o binabaha ang lupa.';
            dEn = 'Roots rot when the soil stays wet or floods.';
          }
          break;
        case Drainage.good:
          dp = c.id == 'Rice' ? 8 : 10;
          dTl = 'Maayos ang agos ng tubig sa lupa.';
          dEn = 'Water drains well.';
          break;
        case Drainage.fast:
          if (c.id == 'Rice') {
            dp = 2;
            dTl = 'Mahirap panatilihin ang tubig sa palayan kung mabilis matuyo ang lupa.';
            dEn = 'Hard to keep water in a paddy when soil dries fast.';
          } else if (t.droughtTolerant) {
            dp = 10;
            dTl = 'Kaya ng pananim ang mabilis matuyong lupa.';
            dEn = 'The crop copes with fast-drying soil.';
          } else {
            dp = 5;
            dTl = 'Kailangan ng madalas na patubig dahil mabilis matuyo ang lupa.';
            dEn = 'Needs frequent watering because the soil dries fast.';
          }
          break;
        case Drainage.unknown:
          dp = 6;
          dTl = 'Hindi pa alam ang kondisyon ng tubig sa lupa.';
          dEn = 'Soil drainage is not known yet.';
          break;
      }
      final drainF = RecFactor('drain', dp, 10, dTl, dEn);

      // Suplay ng tubig (15)
      final supply = {WaterSupply.irrigated: 3, WaterSupply.rainOnly: 2, WaterSupply.limited: 1, WaterSupply.unknown: 2}[water]!;
      final diff = supply - t.waterNeed;
      final wp = diff >= 0 ? 15.0 : (diff == -1 ? 8.0 : 0.0);
      final waterF = RecFactor(
        'water',
        wp,
        15,
        diff >= 0
            ? 'Sapat ang tubig para sa pananim.'
            : diff == -1
            ? 'Medyo kulang ang tubig; maaaring bumaba ang ani sa tag-init.'
            : 'Kulang ang tubig para sa pananim na ito.',
        diff >= 0
            ? 'Water supply is enough for the crop.'
            : diff == -1
            ? 'Water is a bit short; yield may drop in the dry season.'
            : 'Not enough water for this crop.',
      );

      // Panahon / klima ng Pagsanjan (20)
      final best = c.best, poss = c.possible;
      final noMonths = best.isEmpty && poss.isEmpty;
      final m = plantedOn.month;
      final sp = noMonths ? 15.0 : (best.contains(m) ? 20.0 : (poss.contains(m) ? 12.0 : 3.0));
      final seasonF = RecFactor(
        'season',
        sp,
        20,
        noMonths
            ? 'Pangmatagalan; puwedeng itanim sa tag-ulan.'
            : best.contains(m)
            ? 'Magandang buwan ng pagtatanim dito sa Pagsanjan.'
            : poss.contains(m)
            ? 'Puwede pa ang buwang ito, pero hindi ang pinakamainam.'
            : 'Hindi ito panahon ng pagtatanim ng pananim na ito.',
        noMonths
            ? 'A perennial; best planted in the rainy season.'
            : best.contains(m)
            ? 'A good planting month here in Pagsanjan.'
            : poss.contains(m)
            ? 'This month is possible, but not the best.'
            : 'This is not the planting season for this crop.',
      );

      // Lawak (5)
      double ap;
      String aTl, aEn;
      if (areaHa == null) {
        ap = 3;
        aTl = 'Hindi pa alam ang lawak.';
        aEn = 'Land size is not known yet.';
      } else if (t.areaStyle == 'small') {
        ap = areaHa <= 0.5 ? 5 : (areaHa <= 1 ? 4 : 3);
        aTl = areaHa <= 0.5 ? 'Bagay sa maliit na taniman (madaling alagaan).' : 'Kayang alagaan; mas maraming trabaho kapag malawak.';
        aEn = areaHa <= 0.5 ? 'Well suited to a small plot (easy to manage).' : 'Manageable; more work on a large area.';
      } else if (t.areaStyle == 'large') {
        ap = areaHa >= 0.5 ? 5 : (areaHa >= t.minAreaHa ? 3 : 1);
        aTl = areaHa >= 0.5 ? 'Bagay sa malawak na lupa.' : areaHa >= t.minAreaHa ? 'Maliit para sa pangmatagalang pananim, pero puwede.' : 'Masyadong maliit ang lupa para sa pananim na ito.';
        aEn = areaHa >= 0.5 ? 'Suits a larger area.' : areaHa >= t.minAreaHa ? 'Small for a perennial crop, but possible.' : 'The land is too small for this crop.';
      } else {
        ap = 4;
        aTl = 'Puwede sa maliit man o malawak na lupa.';
        aEn = 'Works on small or large land.';
      }
      final areaF = RecFactor('area', ap, 5, aTl, aEn);

      // Pamilihan at tubo (25): demand 10 + tubo 15. Ang pangmatagalan ay kinukuwenta bilang namumunga na.
      final base = DateTime.now();
      final plantDate = c.perennial ? base.subtract(const Duration(days: 365 * 8)) : plantedOn;
      final plan = DssPlan.build(crop: c, soil: soil, areaHa: 1, plantedOn: plantDate);
      final roi = plan.totalCost > 0 ? plan.netMid / plan.totalCost : 0.0;
      final dPts = {1: 4.0, 2: 7.0, 3: 10.0}[t.demand]!;
      final pPts = roi >= 1.0 ? 15.0 : (roi >= 0.5 ? 11.0 : (roi >= 0.2 ? 7.0 : (roi >= 0 ? 3.0 : 0.0)));
      final marketF = RecFactor(
        'market',
        dPts + pPts,
        25,
        '${t.demandTl} ${roi >= 0.5 ? 'Maganda ang tantiyang tubo.' : roi >= 0 ? 'Maliit ang tantiyang tubo.' : 'Posibleng malugi sa karaniwang ani at presyo.'}',
        '${t.demandEn} ${roi >= 0.5 ? 'Estimated profit looks good.' : roi >= 0 ? 'Estimated profit is small.' : 'Could lose money at typical yield and price.'}',
      );

      final factors = [soilF, drainF, waterF, seasonF, areaF, marketF];
      final total = factors.fold<double>(0, (s, f) => s + f.pts);
      out.add(CropRec(c, total, factors, plan.netMid, roi, t));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }
}