import 'crop_data.dart';

/// Datos ng DSS para sa mga karaniwang pananim sa Pagsanjan, Laguna.
///
/// PAALALA SA PINAGMULAN (nasa [DssCrop.sources] ng bawat pananim):
/// - Presyo ng abono: FPA weekly retail price, Laguna, 20-24 Hulyo 2026.
/// - Oras at paraan ng abono at peste: PhilRice PalayCheck, DA-ATI at DA-BPI na mga gabay (tingnan ang sources).
/// - Gastos: PSA Costs and Returns (palay 2024; talong, sitaw, kamoteng kahoy 2016). Ang iba ay TANTIYA.
/// - Ang mga sukat na may tatak na "tantiya" ay hindi galing sa iisang opisyal na gabay. Ipa-verify sa MAO.

enum SoilType { clay, clayLoam, loam, sandyLoam, sandy, unknown }

const List<SoilType> kSoilOrder = [SoilType.clay, SoilType.clayLoam, SoilType.loam, SoilType.sandyLoam, SoilType.sandy, SoilType.unknown];

String soilName(SoilType s, bool tl) {
  switch (s) {
    case SoilType.clay:
      return tl ? 'Luwad' : 'Clay';
    case SoilType.clayLoam:
      return tl ? 'Malagkit na mabuhaghag' : 'Clay loam';
    case SoilType.loam:
      return tl ? 'Mabuhaghag (Loam)' : 'Loam';
    case SoilType.sandyLoam:
      return tl ? 'Mabuhangin na mabuhaghag' : 'Sandy loam';
    case SoilType.sandy:
      return tl ? 'Mabuhangin' : 'Sandy';
    case SoilType.unknown:
      return tl ? 'Hindi ko alam' : "I don't know";
  }
}

String soilHint(SoilType s, bool tl) {
  switch (s) {
    case SoilType.clay:
      return tl
          ? 'Napakalagkit kapag basa at nabubuo ang mahabang laso kapag pinisil. Matagal humawi ang tubig. Mabuti sa palay; sa gulay, gumawa ng mataas na kama at kanal.'
          : 'Very sticky when wet and forms a long ribbon when squeezed. Holds water. Good for rice; for vegetables use raised beds and drainage canals.';
    case SoilType.clayLoam:
      return tl
          ? 'Malagkit pero nabubuo lang ang maikling laso. Mahusay mag-imbak ng tubig at sustansya. Iwasan ang pagbabad sa tag-ulan.'
          : 'Sticky but forms only a short ribbon. Stores water and nutrients well. Avoid waterlogging in the rainy season.';
    case SoilType.loam:
      return tl
          ? 'Malambot at medyo madulas, nabubuo ang bola pero madaling nabubuwag. Pinakamainam para sa karamihan ng pananim.'
          : 'Soft and slightly silky, forms a ball that crumbles easily. Best for most crops.';
    case SoilType.sandyLoam:
      return tl
          ? 'Magaspang pero nabubuo pa rin ang bola. Mabilis humawi ang tubig at sustansya: hatiin ang abono sa mas maraming beses at dagdagan ng organikong abono.'
          : 'Gritty but still forms a ball. Water and nutrients drain fast: split fertilizer into more applications and add organic fertilizer.';
    case SoilType.sandy:
      return tl
          ? 'Magaspang at hindi nabubuo kapag pinisil. Napakabilis maubos ang tubig at sustansya: maraming organikong abono, mulch at madalas na patubig.'
          : 'Gritty and does not hold shape. Water and nutrients run out very fast: lots of organic fertilizer, mulch and frequent watering.';
    case SoilType.unknown:
      return tl
          ? 'Pisilin ang basang lupa sa palad para malaman. Para tumpak, magpasuri ng lupa sa BSWM o sa Tanggapan ng Agrikultura.'
          : 'Squeeze wet soil in your palm to tell. For accuracy, get a soil test from BSWM or the Agriculture Office.';
  }
}

enum Suit { good, fair, poor, unknown }

enum FertProduct { complete, urea, ammophos, ammosul, mop, organic }

/// Presyo bawat sako (50 kg). Complete, urea, ammophos, ammosul at MOP: FPA retail price sa Laguna, 20-24 Hulyo 2026.
/// Organikong abono (dumi ng manok): TANTIYA.
const Map<FertProduct, double> kFertPrice = {
  FertProduct.complete: 2068.01,
  FertProduct.urea: 2379.94,
  FertProduct.ammophos: 1954.20,
  FertProduct.ammosul: 1315.85,
  FertProduct.mop: 1815.53,
  FertProduct.organic: 120.0,
};

String fertName(FertProduct p, bool tl) {
  switch (p) {
    case FertProduct.complete:
      return 'Complete (14-14-14)';
    case FertProduct.urea:
      return 'Urea (46-0-0)';
    case FertProduct.ammophos:
      return 'Ammophos (16-20-0)';
    case FertProduct.ammosul:
      return 'Ammosul (21-0-0)';
    case FertProduct.mop:
      return 'Muriate of Potash (0-0-60)';
    case FertProduct.organic:
      return tl ? 'Organikong abono (dumi ng manok)' : 'Organic fertilizer (chicken dung)';
  }
}

/// Isang paglalagay ng abono. [day] = araw pagkatapos magtanim/lumipat-tanim (-1 = taunan, walang tiyak na araw).
class FertStep {
  final int day;
  final FertProduct product;
  final double bagsPerHa; // sako (50 kg) bawat ektarya
  final String noteTl;
  final String noteEn;
  const FertStep(this.day, this.product, this.bagsPerHa, this.noteTl, this.noteEn);
}

class PestItem {
  final String nameTl, nameEn, controlTl, controlEn;
  const PestItem(this.nameTl, this.nameEn, this.controlTl, this.controlEn);
}

/// Mga gastos bawat ektarya (bawat taon para sa pangmatagalang pananim), maliban sa abono na kinukuwenta mula sa [DssCrop.steps].
class CostBase {
  final double seeds, pesticide, labor, other;
  final double establish; // minsanang gastos sa pagtatatag (punla), para sa pangmatagalang pananim
  const CostBase({required this.seeds, required this.pesticide, required this.labor, required this.other, this.establish = 0});
}

class DssCrop {
  final String id; // ginagamit din sa litrato (CropPhoto)
  final String nameTl, nameEn;
  final String group; // 'main', 'veg', 'low'
  final String? factsId; // ID sa kCropFacts (ani, tagal, presyo)
  final (int, int)? days; // araw bago maani (min, max)
  final int? firstHarvestDays; // para sa pangmatagalang pananim
  final bool perennial;
  final (double, double, double)? ownYield; // (mababa, katamtaman, mataas) bawat ha kung wala sa kCropFacts
  final String unit; // 'kg' o 'pc'
  final double? priceOverride;
  final double defaultPrice;
  final String priceNoteTl, priceNoteEn;
  final Set<int> bestMonths, possibleMonths;
  final Set<SoilType> soilGood, soilFair;
  final List<FertStep> steps;
  final List<FertStep> matureSteps;
  final CostBase cost;
  final List<PestItem> pests;
  final String assumptionTl, assumptionEn;
  final List<String> sources;

  const DssCrop({
    required this.id,
    required this.nameTl,
    required this.nameEn,
    required this.group,
    this.factsId,
    this.days,
    this.firstHarvestDays,
    this.perennial = false,
    this.ownYield,
    this.unit = 'kg',
    this.priceOverride,
    this.defaultPrice = 0,
    this.priceNoteTl = '',
    this.priceNoteEn = '',
    this.bestMonths = const {},
    this.possibleMonths = const {},
    required this.soilGood,
    required this.soilFair,
    required this.steps,
    this.matureSteps = const [],
    required this.cost,
    required this.pests,
    this.assumptionTl = '',
    this.assumptionEn = '',
    required this.sources,
  });

  String name(bool tl) => tl ? nameTl : nameEn;

  CropFacts? get facts => factsId == null ? null : factsFor(factsId!);

  (double, double, double) get yieldPerHa {
    final f = facts;
    if (f != null) return (f.lowKgHa.toDouble(), f.midKgHa.toDouble(), f.highKgHa.toDouble());
    return ownYield ?? (0, 0, 0);
  }

  Set<int> get best => facts?.bestMonths ?? bestMonths;
  Set<int> get possible => facts?.possibleMonths ?? possibleMonths;
}

const _kSrcFpa = 'FPA Weekly Fertilizer Prices, Laguna (20-24 Hulyo 2026)';
const _kSrcRice = 'PhilRice PalayCheck System 2022 (oras ng abono at peste); PSA 2024 (gastos at presyo ng palay)';

const List<DssCrop> kDssCrops = [
  // ---------------- Pangunahing pananim ----------------
  DssCrop(
    id: 'Rice',
    nameTl: 'Palay',
    nameEn: 'Rice (palay)',
    group: 'main',
    factsId: 'Rice',
    days: (110, 120),
    priceOverride: 23.48,
    defaultPrice: 23.48,
    priceNoteTl: 'Karaniwang presyo ng palay sa bukid (PSA 2024, buong bansa). Ilagay ang presyo sa inyong lugar.',
    priceNoteEn: 'Average farmgate palay price (PSA 2024, national). Enter the price in your area.',
    soilGood: {SoilType.clay, SoilType.clayLoam},
    soilFair: {SoilType.loam},
    steps: [
      FertStep(7, FertProduct.complete, 3, 'Panimulang abono (0-14 araw pagkatanim): kasama ang posporus at potasyo.', 'Basal (0-14 days after transplanting): includes phosphorus and potassium.'),
      FertStep(28, FertProduct.urea, 1.5, 'Pangalawang nitrogen (gitna ng pagsusuwi). Ayusin ayon sa Leaf Color Chart.', 'Second nitrogen (mid-tillering). Adjust using the Leaf Color Chart.'),
      FertStep(40, FertProduct.urea, 1.5, '5-7 araw bago ang panicle initiation. Ayusin ayon sa Leaf Color Chart.', '5-7 days before panicle initiation. Adjust using the Leaf Color Chart.'),
    ],
    cost: CostBase(seeds: 4316, pesticide: 3500, labor: 30000, other: 11000),
    pests: [
      PestItem(
        'Stem borer, black bug, planthopper, rice bug',
        'Stem borer, black bug, planthopper, rice bug',
        'Gumamit ng matibay na variety, sabay-sabay na pagtatanim, at pangalagaan ang mga kaibigang insekto. Pestisidyo ang huling paraan. Huwag mag-spray laban sa kumakain ng dahon sa loob ng 30 araw pagkatanim.',
        'Use resistant varieties, synchronous planting and protect beneficial insects. Insecticide is the last resort. Do not spray against leaf-feeders within 30 days after transplanting.',
      ),
      PestItem(
        'Blast, sheath blight, bacterial leaf blight, tungro, brown spot',
        'Blast, sheath blight, bacterial leaf blight, tungro, brown spot',
        'Tamang diagnosis muna bago mag-spray. Linisin ang paligid, sabay-sabay na pagtatanim, at huwag sobra ang nitrogen.',
        'Diagnose correctly before spraying. Keep the field clean, plant synchronously and avoid too much nitrogen.',
      ),
      PestItem(
        'Kuhol (golden apple snail)',
        'Golden apple snail',
        'Panatilihing basa lang (saturated) hanggang 25 araw pagkabinhi o 15 araw pagkatanim. Gumawa ng maliit na kanal at pansala sa daluyan ng tubig.',
        'Keep the field only saturated until 25 days after sowing or 15 days after transplanting. Make small canals and screens at water inlets.',
      ),
      PestItem(
        'Daga at ibon',
        'Rats and birds',
        'Sabay-sabay na kontrol ng buong komunidad. Patambakan ng lupa at tubig ang lungga ng daga. Takutin ang mga ibon.',
        'Community-wide control. Fill rat burrows with soil and water. Scare birds away.',
      ),
      PestItem(
        'Damo',
        'Weeds',
        'Kontrolin sa 0-45 araw pagkatanim. Mas mainam ang kamay o makina; herbicide ang huling paraan.',
        'Control within 0-45 days. Manual or mechanical weeding is preferred; herbicide is the last option.',
      ),
    ],
    assumptionTl: 'Ang dami ng abono ay karaniwang gawi (3 sako complete at 3 sako urea bawat ektarya). Ayon sa PalayCheck, ang eksaktong dami ay dapat batay sa Leaf Color Chart o pagsusuri ng lupa.',
    assumptionEn: 'Fertilizer amounts follow common practice (3 bags complete and 3 bags urea per hectare). PalayCheck says exact amounts should come from the Leaf Color Chart or a soil test.',
    sources: [_kSrcRice, _kSrcFpa],
  ),
  DssCrop(
    id: 'Coconut',
    nameTl: 'Niyog',
    nameEn: 'Coconut',
    group: 'main',
    factsId: 'Coconut',
    perennial: true,
    firstHarvestDays: 2190,
    unit: 'pc',
    soilGood: {SoilType.loam, SoilType.sandyLoam, SoilType.clayLoam},
    soilFair: {SoilType.sandy, SoilType.clay},
    steps: [
      FertStep(-1, FertProduct.ammosul, 3.6, 'Taunang abono: 1.5 kg ammonium sulfate bawat puno. Hatiin sa 2 beses (simula at gitna ng tag-ulan).', 'Yearly: 1.5 kg ammonium sulfate per tree. Split in 2 (start and middle of the rainy season).'),
      FertStep(-1, FertProduct.mop, 4.8, 'Taunang abono: 2 kg muriate of potash bawat puno (o 1.7 kg asin kung mayaman sa potasyo ang lupa).', 'Yearly: 2 kg muriate of potash per tree (or 1.7 kg salt if the soil is rich in potassium).'),
    ],
    matureSteps: [],
    cost: CostBase(seeds: 0, pesticide: 1500, labor: 20000, other: 4000, establish: 9600),
    pests: [
      PestItem(
        'Coconut scale insect (CSI)',
        'Coconut scale insect (CSI)',
        'Putulin at sunugin ang malubhang apektadong dahon. Ipaalam agad sa Philippine Coconut Authority para sa biyolohikal na kontrol.',
        'Cut and burn heavily infested fronds. Report to the Philippine Coconut Authority for biological control.',
      ),
      PestItem(
        'Uwang (rhinoceros beetle)',
        'Rhinoceros beetle',
        'Linisin ang mga nabubulok na troso at tambak ng dumi malapit sa taniman, dahil doon sila nangingitlog.',
        'Remove rotting logs and manure heaps near the farm, where they breed.',
      ),
      PestItem(
        'Sakit na hindi nagagamot (cadang-cadang, bud rot)',
        'Incurable diseases (cadang-cadang, bud rot)',
        'Walang gamot. Ipaalam sa PCA, alisin ang apektadong puno ayon sa payo, at huwag ilipat ang mga punla mula sa apektadong lugar.',
        'No cure. Report to PCA, remove affected trees as advised and do not move seedlings from affected areas.',
      ),
    ],
    assumptionTl: 'Ipinagpapalagay na ~120 puno bawat ektarya at 8,000 niyog bawat ektarya bawat taon. Ang abono ay ayon sa ATI/PCA (bawat puno). Ang pagtatayang kita ay para sa taon na namumunga na ang puno.',
    assumptionEn: 'Assumes ~120 trees per hectare and 8,000 nuts per hectare per year. Fertilizer is per tree from ATI/PCA. Income is for a year when trees are bearing.',
    sources: ['DA-ATI Coconut-Cacao Intercropping (abono bawat puno); PCA', _kSrcFpa],
  ),
  // ---------------- Mga gulay na mataas ang halaga ----------------
  DssCrop(
    id: 'Eggplant',
    nameTl: 'Talong',
    nameEn: 'Eggplant',
    group: 'veg',
    factsId: 'Eggplant',
    days: (90, 120),
    soilGood: {SoilType.sandyLoam, SoilType.clayLoam},
    soilFair: {SoilType.loam, SoilType.clay},
    steps: [
      FertStep(0, FertProduct.organic, 100, 'Bago ihanda ang lupa: 5,000 kg organikong abono bawat ektarya.', 'Before land preparation: 5,000 kg organic fertilizer per hectare.'),
      FertStep(0, FertProduct.complete, 3.6, 'Sa paglilipat-tanim: 1 kutsara (15 g) bawat halaman.', 'At transplanting: 1 tablespoon (15 g) per plant.'),
      FertStep(12, FertProduct.urea, 3.6, '10-15 araw pagkalipat-tanim: 15 g bawat halaman.', '10-15 days after transplanting: 15 g per plant.'),
      FertStep(12, FertProduct.mop, 3.6, '10-15 araw pagkalipat-tanim: 15 g bawat halaman.', '10-15 days after transplanting: 15 g per plant.'),
      FertStep(30, FertProduct.urea, 3.6, 'Pahabol na abono sa 30 araw: 15 g bawat halaman.', 'Top dressing at 30 days: 15 g per plant.'),
    ],
    cost: CostBase(seeds: 3000, pesticide: 10790, labor: 52030, other: 45442),
    pests: [
      PestItem(
        'Shoot and fruit borer',
        'Shoot and fruit borer',
        'Kolektahin at sirain ang lantang talbos, mag-ilaw sa gabi, gumamit ng sex pheromone trap at Trichogramma chilonis (40,000/ha, simulan sa 42 araw pagkatanim at ulitin lingguhan).',
        'Collect and destroy wilted shoots, use light traps, sex pheromone traps and Trichogramma chilonis (40,000/ha, start 42 days after planting, repeat weekly).',
      ),
      PestItem('Aphids at whitefly', 'Aphids and whitefly', 'Bombahin ng siling labuyo extract o Silicidin, o sabon at gata ng niyog (1 bahagi sa 10 litro ng tubig) sa hapon, dalawang beses na may 2 araw na pagitan. Hindi epektibo ang paulit-ulit na pagbomba para sa whitefly.', 'Spray hot pepper extract or soap with coconut milk (1 part in 10 liters of water) in the afternoon, twice 2 days apart. Repeated spraying is not effective against whitefly.'),
      PestItem('Bacterial wilt at Phomopsis', 'Bacterial wilt and Phomopsis', 'Gumamit ng matibay na variety (hal. A 300, Mara), haluan ng compost o Trichoderma ang lupa. Huwag magtanim ng talong, kamatis o sili sa parehong lupa nang sunod-sunod.', 'Use resistant varieties (e.g. A 300, Mara), mix compost or Trichoderma into the soil. Do not plant eggplant, tomato or pepper in the same soil repeatedly.'),
      PestItem('Epilachna beetle', 'Epilachna beetle', 'Sabuyan ng abo ang mga dahon.', 'Dust the leaves with ash.'),
    ],
    assumptionTl: 'Ipinagpapalagay na ~12,000 halaman bawat ektarya. Ang abono ay mula sa gabay ng ATI (bawat halaman), na-convert sa ektarya. Gastos: PSA 2016 (mas mataas na ngayon).',
    assumptionEn: 'Assumes ~12,000 plants per hectare. Fertilizer is from the ATI guide (per plant) converted to hectares. Costs: PSA 2016 (higher today).',
    sources: ['DA-ATI 4B Gabay sa Produksyon ng Talong', 'PSA Costs and Returns 2016', _kSrcFpa],
  ),
  DssCrop(
    id: 'Squash',
    nameTl: 'Kalabasa',
    nameEn: 'Squash',
    group: 'veg',
    factsId: 'Squash',
    days: (90, 120),
    soilGood: {SoilType.loam, SoilType.sandyLoam},
    soilFair: {SoilType.clayLoam, SoilType.sandy},
    steps: [
      FertStep(0, FertProduct.complete, 1.8, 'Bago magtanim: 1 kutsara (15 g) bawat butas.', 'Before planting: 1 tablespoon (15 g) per hole.'),
      FertStep(30, FertProduct.urea, 1.8, '1 buwan pagkatanim: 1 kutsara bawat halaman.', '1 month after planting: 1 tablespoon per plant.'),
      FertStep(44, FertProduct.mop, 1.8, '2 linggo pagkatapos: 1 kutsara potash bawat halaman.', '2 weeks later: 1 tablespoon potash per plant.'),
      FertStep(59, FertProduct.urea, 1.8, 'Ulitin pagkatapos ng 15 araw depende sa tindig ng tanim.', 'Repeat after 15 days depending on crop stand.'),
      FertStep(59, FertProduct.mop, 1.8, 'Ulitin pagkatapos ng 15 araw depende sa tindig ng tanim.', 'Repeat after 15 days depending on crop stand.'),
    ],
    cost: CostBase(seeds: 2500, pesticide: 6000, labor: 38000, other: 18000),
    pests: [
      PestItem('Aphids at squash beetle', 'Aphids and squash beetle', 'Gumamit ng OHN o botanikong pamatay-peste (siling labuyo, tanglad, luya, katas ng kamatis).', 'Use OHN or botanical pesticides (hot pepper, lemongrass, ginger, tomato extract).'),
      PestItem('Powdery mildew', 'Powdery mildew', 'OHN o botanikong pamatay-fungus (katas ng sibuyas, ipil-ipil, kamantigi).', 'OHN or botanical fungicides (onion, ipil-ipil, kamantigi extracts).'),
      PestItem('Mosaic virus', 'Mosaic virus', 'Walang gamot. Bunutin ang apektadong halaman at kontrolin ang aphids na nagdadala nito.', 'No cure. Uproot affected plants and control the aphids that spread it.'),
    ],
    assumptionTl: 'Ipinagpapalagay na ~6,000 halaman bawat ektarya. Ang abono ay mula sa gabay ng ATI (bawat butas/halaman), na-convert sa ektarya. Ang gastos ay TANTIYA.',
    assumptionEn: 'Assumes ~6,000 plants per hectare. Fertilizer is from the ATI guide (per hole/plant) converted to hectares. Costs are ESTIMATES.',
    sources: ['DA-ATI CAR Squash Production Guide (leaflet)', _kSrcFpa],
  ),
  DssCrop(
    id: 'String beans',
    nameTl: 'Sitaw',
    nameEn: 'String beans',
    group: 'veg',
    factsId: 'String beans',
    days: (60, 70),
    soilGood: {SoilType.loam, SoilType.sandyLoam},
    soilFair: {SoilType.clayLoam, SoilType.sandy},
    steps: [
      FertStep(0, FertProduct.organic, 40, 'Bago magtanim: organikong abono (tantiya).', 'Before planting: organic fertilizer (estimate).'),
      FertStep(0, FertProduct.complete, 4, 'Panimulang abono sa pagtatanim (tantiya).', 'Basal at planting (estimate).'),
      FertStep(20, FertProduct.urea, 1, 'Kaunting nitrogen lang dahil nakakakuha ng nitrogen ang sitaw sa hangin (tantiya).', 'Only a little nitrogen because beans fix nitrogen from the air (estimate).'),
      FertStep(30, FertProduct.mop, 1, 'Potasyo bago mamulaklak nang marami (tantiya).', 'Potassium before heavy flowering (estimate).'),
    ],
    cost: CostBase(seeds: 8693, pesticide: 15923, labor: 68550, other: 45592),
    pests: [
      PestItem('Pod borer at aphids', 'Pod borer and aphids', 'Regular na pagsusuri, alisin ang apektadong bulaklak at bunga, at gumamit ng botanikong spray muna.', 'Scout regularly, remove affected flowers and pods, and use botanical sprays first.'),
      PestItem('Kalawang at anthracnose', 'Rust and anthracnose', 'Huwag magdilig sa dahon sa gabi, bigyan ng espasyo ang tanim, at bunutin ang apektadong halaman.', 'Avoid wetting leaves at night, keep spacing, and remove affected plants.'),
    ],
    assumptionTl: 'Ang abono at peste ay pangkalahatang TANTIYA dahil hindi nakuha ang gabay ng DA-BPI sa sitaw. Gastos: PSA 2016.',
    assumptionEn: 'Fertilizer and pests are general ESTIMATES because the DA-BPI bush sitao guide could not be retrieved. Costs: PSA 2016.',
    sources: ['PSA Costs and Returns 2016 (sitaw)', _kSrcFpa],
  ),
  DssCrop(
    id: 'Okra',
    nameTl: 'Okra',
    nameEn: 'Okra',
    group: 'veg',
    factsId: 'Okra',
    days: (50, 60),
    soilGood: {SoilType.sandyLoam},
    soilFair: {SoilType.loam, SoilType.clayLoam, SoilType.sandy},
    steps: [
      FertStep(0, FertProduct.organic, 40, 'Bago magtanim: organikong abono (tantiya).', 'Before planting: organic fertilizer (estimate).'),
      FertStep(0, FertProduct.complete, 4, 'Panimulang abono (tantiya; ang gabay ng ATI ay para sa maliit na kama).', 'Basal (estimate; the ATI guide is for a small plot).'),
      FertStep(30, FertProduct.urea, 2, 'Gitnang abono, kasabay ng pagtatabon ng lupa (tantiya).', 'Side-dress together with hilling up (estimate).'),
      FertStep(30, FertProduct.mop, 1, 'Potasyo para sa mas maraming bunga (tantiya).', 'Potassium for more pods (estimate).'),
    ],
    cost: CostBase(seeds: 3000, pesticide: 8000, labor: 42000, other: 20000),
    pests: [
      PestItem('Stink bug at cotton stainer', 'Stink bug and cotton stainer', 'Bunutin at ibaon ang apektadong halaman, panatilihing malinis ang bukid.', 'Uproot and bury affected plants, keep the field clean.'),
      PestItem('Cercospora, powdery mildew, fruit rot', 'Cercospora, powdery mildew, fruit rot', 'Sanitasyon, tamang espasyo, at pagpapalit ng pananim. Alisin ang apektadong bunga at dahon.', 'Sanitation, proper spacing and crop rotation. Remove affected pods and leaves.'),
      PestItem('Root-knot nematode', 'Root-knot nematode', 'Magpalit ng pananim (huwag okra nang sunod-sunod) at haluan ng compost ang lupa.', 'Rotate crops (not okra repeatedly) and mix compost into the soil.'),
    ],
    assumptionTl: 'Ang dami ng abono at gastos ay TANTIYA. Ang gabay ng ATI ay para sa 20 m na kama kaya hindi direktang magagamit sa ektarya.',
    assumptionEn: 'Fertilizer amounts and costs are ESTIMATES. The ATI guide is for a 20 m bed so it cannot be used directly per hectare.',
    sources: ['DA-ATI 7 Okra Production Guide', _kSrcFpa],
  ),
  DssCrop(
    id: 'Pechay (Tagalog)',
    nameTl: 'Pechay',
    nameEn: 'Pechay',
    group: 'veg',
    factsId: 'Pechay (Tagalog)',
    days: (25, 35),
    soilGood: {SoilType.loam, SoilType.sandyLoam, SoilType.clayLoam},
    soilFair: {SoilType.clay, SoilType.sandy},
    steps: [
      FertStep(0, FertProduct.organic, 20, 'Bago magtanim: organikong abono (tantiya).', 'Before planting: organic fertilizer (estimate).'),
      FertStep(0, FertProduct.complete, 4, 'Panimulang abono (tantiya; ang gabay ng ATI ay para sa maliit na kama).', 'Basal (estimate; the ATI guide is for a small bed).'),
      FertStep(12, FertProduct.urea, 2, 'Pahabol na nitrogen para sa berdeng dahon (tantiya).', 'Top-dress nitrogen for green leaves (estimate).'),
    ],
    cost: CostBase(seeds: 3500, pesticide: 5000, labor: 30000, other: 12000),
    pests: [
      PestItem('Aphids, flea beetle, diamondback moth', 'Aphids, flea beetle, diamondback moth', 'Bunutin at ibaon ang apektadong halaman, panatilihing malinis ang bukid at gumamit ng botanikong spray muna.', 'Uproot and bury affected plants, keep the field clean and use botanical sprays first.'),
      PestItem('Powdery mildew, soft rot, club root', 'Powdery mildew, soft rot, club root', 'Bunutin at ibaon ang apektado. Iwasan ang bahaing lupa at ang pagtatanim ng repolyo-pamilya nang sunod-sunod.', 'Uproot and bury affected plants. Avoid waterlogged soil and repeated planting of cabbage-family crops.'),
    ],
    assumptionTl: 'Ang dami ng abono at gastos ay TANTIYA. Maikli ang pananim kaya madaling magtanim nang paulit-ulit sa isang taon.',
    assumptionEn: 'Fertilizer amounts and costs are ESTIMATES. This is a short crop, so you can plant several times a year.',
    sources: ['DA-ATI 7 Pechay Production Guide', _kSrcFpa],
  ),
  DssCrop(
    id: 'Chili (hot)',
    nameTl: 'Sili (labuyo)',
    nameEn: 'Chili (bird\'s eye)',
    group: 'veg',
    factsId: 'Chili (hot)',
    days: (90, 120),
    soilGood: {SoilType.sandyLoam, SoilType.loam},
    soilFair: {SoilType.clayLoam},
    steps: _kPepperSteps,
    cost: CostBase(seeds: 3000, pesticide: 12000, labor: 55000, other: 25000),
    pests: _kPepperPests,
    assumptionTl: 'Ang abono ay mula sa gabay ng DA-ATI sa sili (bawat ektarya). Ang gastos ay TANTIYA batay sa gabay na may 9 na pag-spray.',
    assumptionEn: 'Fertilizer is from the DA-ATI hot pepper guide (per hectare). Costs are ESTIMATES based on the guide with 9 sprayings.',
    sources: ['DA-ATI Hot Pepper Production Guide', _kSrcFpa],
  ),
  DssCrop(
    id: 'Chili (long)',
    nameTl: 'Sili (haba)',
    nameEn: 'Chili (long green)',
    group: 'veg',
    factsId: 'Chili (long)',
    days: (90, 120),
    soilGood: {SoilType.sandyLoam, SoilType.loam},
    soilFair: {SoilType.clayLoam},
    steps: _kPepperSteps,
    cost: CostBase(seeds: 3000, pesticide: 12000, labor: 55000, other: 25000),
    pests: _kPepperPests,
    assumptionTl: 'Ang abono ay mula sa gabay ng DA-ATI sa sili (bawat ektarya). Ang gastos ay TANTIYA.',
    assumptionEn: 'Fertilizer is from the DA-ATI hot pepper guide (per hectare). Costs are ESTIMATES.',
    sources: ['DA-ATI Hot Pepper Production Guide', _kSrcFpa],
  ),
  // ---------------- Lowland at iba pa ----------------
  DssCrop(
    id: 'Cacao',
    nameTl: 'Kakaw (Cacao)',
    nameEn: 'Cacao',
    group: 'low',
    perennial: true,
    firstHarvestDays: 730,
    ownYield: (400, 700, 1200),
    defaultPrice: 130,
    priceNoteTl: 'Walang datos ng presyo mula sa MAO. Tantiya sa tuyong butil bawat kg; ilagay ang presyo ng inyong bibilhan.',
    priceNoteEn: 'No price data from the MAO. Estimate per kg of dried beans; enter your buyer\'s price.',
    bestMonths: {6, 7, 8},
    possibleMonths: {5, 9, 10},
    soilGood: {SoilType.loam, SoilType.clayLoam},
    soilFair: {SoilType.clay, SoilType.sandyLoam},
    steps: [
      FertStep(30, FertProduct.complete, 1.8, '1 buwan pagkatanim: 91 g bawat puno (BPI).', '1 month after planting: 91 g per tree (BPI).'),
      FertStep(120, FertProduct.complete, 2.4, '4 na buwan: 121 g bawat puno (BPI).', '4 months: 121 g per tree (BPI).'),
      FertStep(240, FertProduct.complete, 2.4, '8 buwan: 121 g bawat puno (BPI).', '8 months: 121 g per tree (BPI).'),
      FertStep(360, FertProduct.complete, 3.7, '12 buwan: 183 g bawat puno (BPI).', '12 months: 183 g per tree (BPI).'),
      FertStep(540, FertProduct.complete, 4.9, '18 buwan: 243 g bawat puno (BPI).', '18 months: 243 g per tree (BPI).'),
      FertStep(720, FertProduct.complete, 7.8, '24 buwan: 390 g bawat puno (BPI).', '24 months: 390 g per tree (BPI).'),
    ],
    matureSteps: [
      FertStep(-1, FertProduct.complete, 7.8, 'Taunang abono ng namumungang puno: 390 g bawat puno (huling hanay sa talaan ng BPI).', 'Yearly for bearing trees: 390 g per tree (last row of the BPI table).'),
      FertStep(-1, FertProduct.mop, 0.75, 'Potasyo: 37 g bawat puno (BPI).', 'Potassium: 37 g per tree (BPI).'),
    ],
    cost: CostBase(seeds: 0, pesticide: 4000, labor: 25000, other: 5000, establish: 45000),
    pests: [
      PestItem('Cacao pod borer', 'Cacao pod borer', 'Anihin lingguhan ang lahat ng hinog na bunga, ibaon ang balat, alisin ang bulok na bunga, mag-pruning para sa sikat ng araw, at balutin ang batang bunga ng plastik o dyaryo.', 'Harvest all ripe pods weekly, bury empty husks, remove diseased pods, prune for sunlight and bag young pods with plastic or newspaper.'),
      PestItem('Black pod rot at canker', 'Black pod rot and canker', 'Madalas na pag-ani, sirain ang apektadong bunga, mag-pruning para bumaba ang halumigmig, at ayusin ang daluyan ng tubig.', 'Harvest often, destroy affected pods, prune to lower humidity and improve drainage.'),
      PestItem('Vascular streak dieback', 'Vascular streak dieback', 'Putulin ang apektadong sanga 30 cm sa ibaba ng sakit at sunugin. Gumamit ng matibay na variety (hal. PBC 123, PBC 159).', 'Cut infected branches 30 cm below the infection and burn them. Plant tolerant clones (e.g. PBC 123, PBC 159).'),
      PestItem('Sap suckers, leaf eaters, stem borer, Helopeltis', 'Sap suckers, leaf eaters, stem borer, Helopeltis', 'Bawasan ang lilim at mag-pruning nang katamtaman. Putulin at sunugin ang sangang may stem borer. Pangalagaan ang mga kaibigang insekto.', 'Reduce shade and prune moderately. Cut and burn branches with stem borer. Protect beneficial insects.'),
    ],
    assumptionTl: 'Ipinagpapalagay na ~1,000 puno bawat ektarya (halimbawa, sa ilalim ng niyog). Ang abono ay mula sa talaan ng BPI. Ang gastos at presyo ay TANTIYA. Ang unang ani ay mga 2 taon pagkatanim.',
    assumptionEn: 'Assumes ~1,000 trees per hectare (e.g. under coconut). Fertilizer is from the BPI table. Costs and price are ESTIMATES. First harvest is about 2 years after planting.',
    sources: ['DA-BPI Cacao Production Guide (HVCDP)', 'DA-ATI Coconut-Cacao Intercropping', _kSrcFpa],
  ),
  DssCrop(
    id: 'Cassava',
    nameTl: 'Kamoteng kahoy (Balinghoy)',
    nameEn: 'Cassava',
    group: 'low',
    days: (240, 360),
    ownYield: (8000, 12000, 20000),
    defaultPrice: 6.26,
    priceNoteTl: 'Walang datos ng MAO. Ang ₱6.26/kg ay presyo sa bukid ayon sa PSA 2016, na mas mababa na kaysa ngayon. Ilagay ang presyo ninyo.',
    priceNoteEn: 'No MAO data. ₱6.26/kg is the PSA 2016 farmgate price, lower than today. Enter your own price.',
    bestMonths: {5, 6, 7},
    possibleMonths: {4, 8, 9, 10, 11},
    soilGood: {SoilType.sandyLoam, SoilType.loam},
    soilFair: {SoilType.sandy, SoilType.clayLoam},
    steps: [
      FertStep(30, FertProduct.complete, 3, '1 buwan pagkatanim (tantiya).', '1 month after planting (estimate).'),
      FertStep(60, FertProduct.mop, 1, 'Potasyo para sa mas malaking ugat (tantiya).', 'Potassium for bigger roots (estimate).'),
    ],
    cost: CostBase(seeds: 1399, pesticide: 500, labor: 17415, other: 9460),
    pests: [
      PestItem('Mealybug at mites', 'Mealybug and mites', 'Gumamit ng malinis na pantanim na sanga at mag-inspeksyon nang regular. Ipaalam sa MAO kung dumami.', 'Use clean planting cuttings and inspect regularly. Report to the MAO if numbers grow.'),
      PestItem('Bacterial blight at mosaic', 'Bacterial blight and mosaic', 'Huwag gamitin ang sangang galing sa may sakit. Bunutin at sunugin ang apektadong halaman.', 'Do not use cuttings from diseased plants. Uproot and burn affected plants.'),
      PestItem('Pagkabulok ng ugat sa baha', 'Root rot in waterlogged soil', 'Itanim sa lupang may mabuting daluyan ng tubig o sa matataas na tudling.', 'Plant in well-drained soil or on raised ridges.'),
    ],
    assumptionTl: 'Ang gastos ay mula sa PSA 2016 (mas mataas na ngayon). Ang abono at peste ay pangkalahatang TANTIYA.',
    assumptionEn: 'Costs are from PSA 2016 (higher today). Fertilizer and pests are general ESTIMATES.',
    sources: ['PSA Costs and Returns of Cassava 2016', _kSrcFpa],
  ),
];

const List<FertStep> _kPepperSteps = [
  FertStep(0, FertProduct.complete, 4, 'Panimulang abono sa paglilipat-tanim.', 'Basal at transplanting.'),
  FertStep(0, FertProduct.ammophos, 4, 'Panimulang abono sa paglilipat-tanim.', 'Basal at transplanting.'),
  FertStep(10, FertProduct.ammosul, 2, '10 araw pagkalipat-tanim.', '10 days after transplanting.'),
  FertStep(30, FertProduct.urea, 2, '30 araw pagkalipat-tanim.', '30 days after transplanting.'),
  FertStep(30, FertProduct.mop, 2, '30 araw pagkalipat-tanim.', '30 days after transplanting.'),
  FertStep(50, FertProduct.urea, 2, '50 araw pagkalipat-tanim. Huwag sobra ang nitrogen para hindi magdahon lang.', '50 days after transplanting. Do not overdo nitrogen or the plants become leafy with few fruits.'),
  FertStep(50, FertProduct.mop, 4, '50 araw: mas maraming potasyo habang namumunga.', '50 days: more potassium while fruiting.'),
];

const List<PestItem> _kPepperPests = [
  PestItem('Aphids, spider mites, leafhoppers', 'Aphids, spider mites, leafhoppers', 'Regular na pagsusuri at botanikong spray muna (siling labuyo, sabon). Kung malubha, kumonsulta sa MAO.', 'Scout regularly and use botanical sprays first (hot pepper, soap). If severe, consult the MAO.'),
  PestItem('Bacterial wilt', 'Bacterial wilt', 'Walang gamot. Bunutin ang apektadong halaman at huwag magtanim ng talong, kamatis o sili sa parehong lupa nang sunod-sunod.', 'No cure. Uproot affected plants and do not plant eggplant, tomato or pepper in the same soil repeatedly.'),
  PestItem('Anthracnose', 'Anthracnose', 'Gumamit ng malinis na binhi, alisin ang apektadong bunga, at iwasang mabasa ang dahon sa gabi.', 'Use clean seed, remove affected fruit and avoid wetting leaves at night.'),
];

DssCrop? dssCropFor(String id) {
  for (final c in kDssCrops) {
    if (c.id == id) return c;
  }
  return null;
}

String dssCropName(String id, bool tl) => dssCropFor(id)?.name(tl) ?? id;

/// Araw bago maani (min, max): una sa katalogo ng DSS, kung wala ay sa kCropFacts. Null kung taon ang hinihintay.
(int, int)? cropDays(String id) {
  final c = dssCropFor(id);
  if (c != null) return c.days;
  final f = factsFor(id);
  if (f == null || !f.hasHarvestDays) return null;
  return (f.minDays!, f.maxDays!);
}