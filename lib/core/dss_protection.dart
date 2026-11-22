import 'dss_catalog.dart';
import 'dss_recommend.dart';

/// Isang banta (peste o sakit) sa pananim.
/// Ang mga "options" ay HALIMBAWANG aktibong sangkap na karaniwang binabanggit ng mga gabay sa pagsasaka.
/// Hindi ito reseta: ang rehistradong produkto, dosis at araw bago mag-ani ay nasa label (FPA).
class Threat {
  final String nameTl, nameEn;
  final bool disease; // true = sakit, false = peste
  final String signTl, signEn; // ano ang makikita sa bukid
  final String cultTl, cultEn; // natural at pang-iwas na paraan
  final List<String> options; // halimbawang aktibong sangkap (huling paraan)
  const Threat(this.nameTl, this.nameEn, this.disease, this.signTl, this.signEn, this.cultTl, this.cultEn, this.options);
}

const Map<String, List<Threat>> kThreats = {
  'Rice': [
    Threat('Rice stem borer (tagapitas ng palay)', 'Rice stem borer', false,
        'Patay na gitnang dahon ("deadheart") sa murang palay; puting uhay na walang laman ("whitehead") sa namumunga.',
        'Dead central shoot ("deadheart") in young plants; empty white panicles ("whitehead") at heading.',
        'Sabay-sabay na pagtatanim, tanggalin ang tuyong tuod, at iwasan ang sobrang nitrogen. Bantayan linggu-linggo ang mga itlog at paruparo.',
        'Synchronous planting, remove stubble and avoid excess nitrogen. Scout weekly for egg masses and moths.',
        ['chlorantraniliprole', 'cartap hydrochloride']),
    Threat('Brown planthopper (BPH, "hanip")', 'Brown planthopper (BPH)', false,
        'Naninilaw at natutuyong palay na parang nasunog ("hopperburn"); maraming maliit na kayumangging insekto sa ilalim ng puno.',
        'Yellowing, drying patches ("hopperburn"); many small brown insects at the base of the plants.',
        'Gumamit ng matibay na variety, huwag sobra ang abonong nitrogen, at palitan ang tubig. Huwag mag-spray ng pyrethroid dahil mas dadami ang BPH.',
        'Use resistant varieties, avoid excess nitrogen and drain the field intermittently. Do not spray pyrethroids; they make BPH worse.',
        ['buprofezin', 'pymetrozine', 'dinotefuran']),
    Threat('Blast', 'Blast', true,
        'Hugis-diyamanteng batik sa dahon; baling leeg ng uhay.',
        'Diamond-shaped leaf spots; neck rot of the panicle.',
        'Matibay na variety, balanseng abono (huwag sobra ang urea), at iwasan ang mahabang basang dahon.',
        'Resistant variety, balanced fertilizer (not too much urea) and avoid long leaf wetness.',
        ['tricyclazole']),
    Threat('Sheath blight at bacterial leaf blight', 'Sheath blight and bacterial leaf blight', true,
        'Hugis-ahas na batik sa puno ng palay (sheath blight); naninilaw at natutuyong gilid ng dahon (leaf blight).',
        'Snake-skin lesions at the base (sheath blight); yellowing, drying leaf edges (leaf blight).',
        'Tamang pagitan ng tanim, linisin ang pilapil, at huwag sobra ang nitrogen. Walang epektibong kemikal sa bacterial leaf blight; matibay na variety ang sagot.',
        'Proper spacing, clean the bunds and avoid excess nitrogen. There is no effective chemical for bacterial leaf blight; use resistant varieties.',
        ['hexaconazole', 'validamycin']),
    Threat('Kuhol (golden apple snail)', 'Golden apple snail', false,
        'Putol-putol na mura at bagong tanim na palay; kulay-rosas na itlog sa puno.',
        'Cut seedlings and newly transplanted plants; pink egg clusters on stems.',
        'Panatilihing basa lang (hindi lubog) sa unang linggo, pulutin ang kuhol at itlog, at maglagay ng pansala sa daluyan ng tubig.',
        'Keep the field only saturated in the first weeks, hand-pick snails and eggs, and screen water inlets.',
        []),
  ],
  'Eggplant': [
    Threat('Fruit and shoot borer (EFSB)', 'Eggplant fruit and shoot borer', false,
        'Nalalantang dulo ng sanga at may butas na bunga na may dumi.',
        'Wilting shoot tips and fruits with bore holes and frass.',
        'Putulin at sunugin ang apektadong sanga at bunga araw-araw, gumamit ng pheromone trap, at mag-ani nang madalas.',
        'Cut and burn infested shoots and fruits daily, use pheromone traps and harvest often.',
        ['Bacillus thuringiensis (Bt)', 'emamectin benzoate', 'chlorantraniliprole']),
    Threat('Aphids at whitefly', 'Aphids and whitefly', false,
        'Kulot at malagkit na dahon; maliliit na insekto sa ilalim ng dahon.',
        'Curled, sticky leaves; tiny insects under the leaves.',
        'Neem o sabon na pang-insekto, dilaw na malagkit na patibong, at pangalagaan ang mga kaibigang insekto.',
        'Neem or insecticidal soap, yellow sticky traps and protect beneficial insects.',
        ['imidacloprid', 'spinosad']),
    Threat('Bacterial wilt (pagkalanta)', 'Bacterial wilt', true,
        'Biglang pagkalanta ng buong halaman habang berde pa ang dahon.',
        'Sudden wilting of the whole plant while leaves are still green.',
        'Walang epektibong kemikal. Iwasan ang bahaing lupa, magpalit-palit ng pananim (hindi kamatis, sili o patatas), at bunutin ang apektadong halaman.',
        'No effective chemical. Avoid waterlogged soil, rotate crops (not tomato, pepper or potato) and uproot infected plants.',
        []),
  ],
  'Squash': [
    Threat('Melon fly (langaw ng bunga)', 'Melon fly', false,
        'Mga butas at nabubulok na bunga na may uod.',
        'Punctured, rotting fruit with maggots.',
        'Takpan o i-bag ang bunga, pulutin at ibaon ang nahulog na bunga, at gumamit ng bitag na may pang-akit.',
        'Bag the fruits, collect and bury fallen fruit and use lure traps.',
        ['protein bait + spinosad (spot spray)']),
    Threat('Aphids at virus', 'Aphids and virus', false,
        'Kulot, may batik at maliit na dahon.',
        'Curled, mottled and stunted leaves.',
        'Bunutin ang may virus, kontrolin ang damo, at gumamit ng reflective mulch kung kaya.',
        'Remove virus-infected plants, control weeds and use reflective mulch if possible.',
        ['neem / insecticidal soap', 'imidacloprid']),
    Threat('Powdery at downy mildew', 'Powdery and downy mildew', true,
        'Puting pulbos (powdery) o dilaw na batik na may abuhing amag sa ilalim (downy).',
        'White powder (powdery) or yellow spots with grey mould underneath (downy).',
        'Tamang pagitan ng tanim, iwasan ang pagbabasa ng dahon sa gabi, at alisin ang matatandang dahon.',
        'Proper spacing, avoid wetting leaves at night and remove old leaves.',
        ['sulfur (powdery)', 'mancozeb (downy)']),
  ],
  'String beans': [
    Threat('Pod borer (Maruca)', 'Legume pod borer (Maruca)', false,
        'Mga butas sa bulaklak at butil na may uod at dumi.',
        'Holes in flowers and pods with larvae and frass.',
        'Alisin ang apektadong bulaklak at butil, magtanim nang sabay-sabay, at bantayan sa pamumulaklak.',
        'Remove affected flowers and pods, plant synchronously and scout at flowering.',
        ['Bacillus thuringiensis (Bt)', 'emamectin benzoate']),
    Threat('Aphids at leafminer', 'Aphids and leafminer', false,
        'Kulot na dahon o puting liko-likong guhit sa dahon.',
        'Curled leaves or white winding trails on leaves.',
        'Neem, dilaw na malagkit na patibong, at alisin ang matinding apektadong dahon.',
        'Neem, yellow sticky traps and remove heavily affected leaves.',
        ['neem / insecticidal soap', 'spinosad']),
    Threat('Kalawang (rust) at anthracnose', 'Rust and anthracnose', true,
        'Kalawang na batik sa dahon; madilim na lubog na batik sa butil.',
        'Rust-coloured spots on leaves; dark sunken spots on pods.',
        'Magpalit-palit ng pananim, gumamit ng malinis na binhi, at iwasan ang basang dahon.',
        'Rotate crops, use clean seed and avoid wet leaves.',
        ['mancozeb', 'chlorothalonil']),
  ],
  'Okra': [
    Threat('Whitefly at leafhopper', 'Whitefly and leafhopper', false,
        'Naninilaw at kulot na dahon; mga puting lumilipad na insekto kapag ginalaw.',
        'Yellowing, curled leaves; small white insects fly up when disturbed.',
        'Dilaw na malagkit na patibong, neem, at tanggalin ang damo sa paligid.',
        'Yellow sticky traps, neem and remove weeds around the plot.',
        ['imidacloprid', 'spinosad']),
    Threat('Yellow vein mosaic virus', 'Yellow vein mosaic virus', true,
        'Dilaw na ugat sa dahon at pangit na bunga. Dala ito ng whitefly.',
        'Yellow veins on leaves and deformed fruit. It is spread by whitefly.',
        'Walang gamot sa virus. Bunutin agad ang apektadong halaman at kontrolin ang whitefly.',
        'No cure for the virus. Uproot infected plants quickly and control whitefly.',
        []),
    Threat('Fruit borer', 'Fruit borer', false,
        'Mga butas sa bunga at sanga.',
        'Holes in fruits and shoots.',
        'Pulutin at ibaon ang apektadong bunga; mag-ani nang madalas.',
        'Collect and bury affected fruit; harvest often.',
        ['Bacillus thuringiensis (Bt)', 'emamectin benzoate']),
  ],
  'Pechay (Tagalog)': [
    Threat('Diamondback moth (uod)', 'Diamondback moth', false,
        'Mga butas at "bintana" sa dahon na may maliliit na berdeng uod.',
        'Holes and "windows" in leaves with small green larvae.',
        'Takpan ng net, magpalit ng pananim, at bantayan 2 beses sa isang linggo. Iikli ang araw bago mag-ani kaya maingat sa spray.',
        'Cover with net, rotate crops and scout twice a week. The harvest interval is short, so be careful with spraying.',
        ['Bacillus thuringiensis (Bt)', 'spinosad']),
    Threat('Flea beetle, cutworm at aphids', 'Flea beetle, cutworm and aphids', false,
        'Maliliit na butas (flea beetle), putol na punla (cutworm), kulot na dahon (aphids).',
        'Tiny shot holes (flea beetle), cut seedlings (cutworm), curled leaves (aphids).',
        'Linisin ang bukid bago magtanim, pulutin ang uod sa gabi, at gumamit ng neem.',
        'Clean the field before planting, hand-pick larvae at night and use neem.',
        ['neem / insecticidal soap']),
    Threat('Soft rot (malabnaw na pagkabulok)', 'Soft rot', true,
        'Malambot, mabaho at nabubulok na puno at dahon.',
        'Soft, smelly, rotting stems and leaves.',
        'Maayos na agos ng tubig, huwag sugatan ang halaman, at iwasan ang sobrang basa.',
        'Good drainage, avoid wounding plants and avoid overwatering.',
        []),
  ],
  'Chili (hot)': [
    Threat('Thrips, mites at aphids', 'Thrips, mites and aphids', false,
        'Kulot paitaas na dahon, kulay-pilak na batik at maliit na bunga.',
        'Upward-curled leaves, silvery spots and small fruit.',
        'Neem at sabon na pang-insekto, dilaw o asul na malagkit na patibong, at tamang tubig.',
        'Neem and insecticidal soap, yellow or blue sticky traps and proper watering.',
        ['spinosad', 'abamectin']),
    Threat('Anthracnose (antraknos)', 'Anthracnose', true,
        'Lubog at itim na batik sa hinog na bunga.',
        'Sunken dark spots on ripe fruits.',
        'Malinis na binhi, magpalit ng pananim, at iwasang mabasa ang dahon sa gabi.',
        'Clean seed, rotate crops and avoid wet leaves at night.',
        ['copper-based fungicide', 'mancozeb', 'azoxystrobin']),
    Threat('Bacterial wilt at leaf curl virus', 'Bacterial wilt and leaf curl virus', true,
        'Biglang pagkalanta; o kulot at maliit na dahon (leaf curl, dala ng whitefly at thrips).',
        'Sudden wilting; or curled, stunted leaves (leaf curl, spread by whitefly and thrips).',
        'Walang epektibong kemikal. Bunutin ang apektado, iwasan ang bahaing lupa, at kontrolin ang whitefly.',
        'No effective chemical. Uproot infected plants, avoid waterlogging and control whitefly.',
        []),
  ],
  'Chili (long)': [
    Threat('Thrips, mites at aphids', 'Thrips, mites and aphids', false,
        'Kulot paitaas na dahon, kulay-pilak na batik at maliit na bunga.',
        'Upward-curled leaves, silvery spots and small fruit.',
        'Neem at sabon na pang-insekto, dilaw o asul na malagkit na patibong, at tamang tubig.',
        'Neem and insecticidal soap, yellow or blue sticky traps and proper watering.',
        ['spinosad', 'abamectin']),
    Threat('Anthracnose (antraknos)', 'Anthracnose', true,
        'Lubog at itim na batik sa hinog na bunga.',
        'Sunken dark spots on ripe fruits.',
        'Malinis na binhi, magpalit ng pananim, at iwasang mabasa ang dahon sa gabi.',
        'Clean seed, rotate crops and avoid wet leaves at night.',
        ['copper-based fungicide', 'mancozeb', 'azoxystrobin']),
    Threat('Bacterial wilt at leaf curl virus', 'Bacterial wilt and leaf curl virus', true,
        'Biglang pagkalanta; o kulot at maliit na dahon.',
        'Sudden wilting; or curled, stunted leaves.',
        'Walang epektibong kemikal. Bunutin ang apektado at iwasan ang bahaing lupa.',
        'No effective chemical. Uproot infected plants and avoid waterlogging.',
        []),
  ],
  'Cacao': [
    Threat('Black pod (Phytophthora)', 'Black pod (Phytophthora)', true,
        'Itim at nabubulok na bunga, lalo na sa tag-ulan.',
        'Black, rotting pods, especially in the rainy season.',
        'Anihin nang madalas, alisin at ibaon ang bulok na bunga, at putulin para makapasok ang hangin at araw.',
        'Harvest often, remove and bury rotten pods and prune for air and light.',
        ['copper-based fungicide']),
    Threat('Cacao pod borer at mirid bug', 'Cacao pod borer and mirid bug', false,
        'Maagang paghinog, magkakadikit na butil sa loob (pod borer); itim na batik sa bunga (mirid).',
        'Early ripening, stuck-together beans inside (pod borer); dark spots on pods (mirid).',
        'Madalas na pag-aani, ibaon ang balat ng bunga, at gumamit ng pananim na lilim.',
        'Frequent harvest, bury pod husks and keep proper shade.',
        []),
    Threat('Vascular streak dieback (VSD)', 'Vascular streak dieback (VSD)', true,
        'Naninilaw na dahon at natutuyong dulo ng sanga.',
        'Yellowing leaves and dying branch tips.',
        'Putulin ang apektadong sanga nang 30 cm sa ibaba ng sugat at sunugin.',
        'Prune affected branches 30 cm below the damage and burn them.',
        []),
  ],
  'Coconut': [
    Threat('Coconut scale insect (cocolisap)', 'Coconut scale insect', false,
        'Puting kolonya sa ilalim ng dahon; naninilaw at natutuyong palapa.',
        'White colonies under fronds; yellowing, drying fronds.',
        'Ipaalam agad sa Philippine Coconut Authority (PCA) at MAO. Putulin at sunugin ang matinding apektadong palapa at huwag ilipat ang mga buko o dahon palabas ng lugar.',
        'Report to the Philippine Coconut Authority (PCA) and MAO right away. Cut and burn heavily infested fronds and do not move nuts or fronds out of the area.',
        []),
    Threat('Rhinoceros beetle at red palm weevil', 'Rhinoceros beetle and red palm weevil', false,
        'Hugis-V na putol sa palapa (rhinoceros beetle); lanta at butas sa puno (weevil).',
        'V-shaped cuts in fronds (rhinoceros beetle); wilting and holes in the trunk (weevil).',
        'Linisin ang bunton ng basura at bulok na kahoy kung saan nangingitlog, at huwag sugatan ang puno.',
        'Clear piles of waste and rotting wood where they breed, and avoid wounding the palm.',
        []),
    Threat('Bud rot at leaf spot', 'Bud rot and leaf spot', true,
        'Nabubulok ang puso ng puno; batik sa dahon.',
        'Rotting palm heart; leaf spots.',
        'Maayos na agos ng tubig, malinis na paligid, at agad na magtanong sa PCA kapag may bud rot.',
        'Good drainage, a clean surrounding and ask the PCA right away if bud rot appears.',
        []),
  ],
  'Cassava': [
    Threat('Mealybug at whitefly', 'Mealybug and whitefly', false,
        'Puting bulak-bulak sa dulo ng halaman, baluktot at maliit na dahon.',
        'White cottony masses at shoot tips, twisted and stunted leaves.',
        'Gumamit ng malinis na pantanim, putulin at sunugin ang apektadong dulo, at iwasan ang tuyot na kondisyon.',
        'Use clean planting material, cut and burn affected tips and avoid drought stress.',
        []),
    Threat('Mosaic virus at bacterial blight', 'Mosaic virus and bacterial blight', true,
        'Dilaw-berdeng batik at kulot na dahon (mosaic); natutuyong dahon at sanga (blight).',
        'Yellow-green mottling and curling (mosaic); drying leaves and stems (blight).',
        'Bunutin at sunugin ang apektado. Huwag gumamit ng pantanim na galing sa may sakit.',
        'Uproot and burn affected plants. Do not use cuttings from sick plants.',
        []),
    Threat('Root rot (pagkabulok ng ugat)', 'Root rot', true,
        'Lanta at nabubulok na ugat at tuber.',
        'Wilting with rotting roots and tubers.',
        'Iwasan ang bahaing lupa; magtanim sa matataas na tagaytay o maayos ang agos ng tubig.',
        'Avoid waterlogged soil; plant on ridges or well-drained land.',
        []),
  ],
};

/// Mga paalala sa kaligtasan sa paggamit ng kemikal sa pagsasaka.
const List<(String, String)> kSafetyTips = [
  ('Basahing mabuti ang label bago gamitin. Sundin ang dosis at kung ilang araw dapat bago mag-ani (pre-harvest interval).',
  'Read the label carefully before use. Follow the dose and the pre-harvest interval.'),
  ('Bumili lang ng produktong rehistrado sa FPA, mula sa lisensyadong tindahan. Huwag gumamit ng walang label o pinaghalo-halo.',
  'Buy only FPA-registered products from licensed dealers. Do not use unlabeled or mixed-up products.'),
  ('Magsuot ng mahabang manggas at pantalon, guwantes, botas, takip sa ilong at bibig, at salamin sa mata habang nagsa-spray.',
  'Wear long sleeves and pants, gloves, boots, a mask and eye protection when spraying.'),
  ('Mag-spray kapag walang hangin (umaga o hapon), hindi paharap sa hangin, at huwag bago umulan.',
  'Spray when it is calm (morning or late afternoon), never into the wind, and not right before rain.'),
  ('Huwag kumain, uminom o manigarilyo habang naghahalo o nagsa-spray. Maligo at labhan ang damit pagkatapos.',
  'Do not eat, drink or smoke while mixing or spraying. Bathe and wash clothes afterwards.'),
  ('Ilayo sa bata, alagang hayop, pagkain at tubig. Itago ang kemikal sa nakasarang lalagyan na may kandado.',
  'Keep away from children, pets, food and water. Store chemicals locked in their original containers.'),
  ('Huwag itapon ang natirang kemikal o hugasan ang sprayer sa ilog, kanal o palayan. Itapon ang walang lamang lalagyan nang ligtas.',
  'Never dump leftover chemicals or wash sprayers in rivers, canals or paddies. Dispose of empty containers safely.'),
  ('Kapag nahilo, nasusuka o nalanghap/natapunan: itigil agad, hugasan ng tubig at sabon, at dalhin sa doktor o sa pinakamalapit na ospital kasama ang label.',
  'If you feel dizzy or sick, or are exposed: stop at once, wash with soap and water and go to a doctor or hospital with the label.'),
];

/// Yugto ng paglaki batay sa araw pagkatapos magtanim.
String stageLabel(DssCrop c, int day, bool tl) {
  if (day < 0) return tl ? 'Taunan' : 'Yearly';
  if (c.id == 'Rice') {
    if (day <= 14) return tl ? 'Panimula (basal)' : 'Basal';
    if (day <= 35) return tl ? 'Pagsusuwi (tillering)' : 'Tillering';
    if (day <= 55) return tl ? 'Bago mamunga ang uhay' : 'Panicle initiation';
    return tl ? 'Pamumulaklak' : 'Flowering';
  }
  final span = (c.days?.$1 ?? 90).toDouble();
  final f = day / span;
  if (day <= 7) return tl ? 'Pagtatanim (basal)' : 'Planting (basal)';
  if (f < 0.35) return tl ? 'Paglaki ng dahon' : 'Leaf growth';
  if (f < 0.65) return tl ? 'Pamumulaklak' : 'Flowering';
  return tl ? 'Pamumunga' : 'Fruiting';
}

/// Mga pagsasaayos sa abono batay sa lupa, agos ng tubig at suplay ng tubig. Palaging kasama ang paalala ng soil test.
List<(String, String)> fertAdjustments(DssCrop c, SoilType soil, Drainage drain, WaterSupply water) {
  final out = <(String, String)>[];
  switch (soil) {
    case SoilType.sandy:
    case SoilType.sandyLoam:
      out.add(('Mabuhangin ang lupa: madaling maanod ang abono. Hatiin sa mas maraming beses (mas kaunti bawat paglalagay) at dagdagan ng organikong abono.',
      'Sandy soil loses fertilizer fast. Split into more, smaller applications and add organic fertilizer.'));
      break;
    case SoilType.clay:
      out.add(('Malagkit ang lupa: dahan-dahan ang pagsipsip ng abono at puwedeng magkulang ng hangin. Ibaon nang bahagya ang abono at dagdagan ng organikong abono.',
      'Clay soil holds nutrients but drains and aerates poorly. Lightly incorporate fertilizer and add organic matter.'));
      break;
    case SoilType.clayLoam:
    case SoilType.loam:
      out.add(('Mainam ang uri ng lupa; sundin ang karaniwang iskedyul sa ibaba.', 'The soil type is favorable; follow the regular schedule below.'));
      break;
    case SoilType.unknown:
      out.add(('Hindi pa alam ang uri ng lupa, kaya karaniwang dami ang ipinapakita. Magpa-soil test para mas tumpak.', 'Soil type is not known, so typical amounts are shown. A soil test gives a more accurate dose.'));
      break;
  }
  if (drain == Drainage.poor && c.id != 'Rice') {
    out.add(('Laging basa ang lupa: nawawala ang nitrogen at nabubulok ang ugat. Gumawa ng kanal o tagaytay at huwag mag-abono kapag lubog.',
    'Always-wet soil loses nitrogen and rots roots. Dig drains or ridges and do not fertilize while flooded.'));
  } else if (drain == Drainage.fast) {
    out.add(('Mabilis matuyo ang lupa: mag-abono kapag basa ang lupa at diligan pagkatapos. Hatiin ang nitrogen.',
    'Fast-drying soil: fertilize when the soil is moist and water afterwards. Split the nitrogen.'));
  }
  if (water == WaterSupply.rainOnly || water == WaterSupply.limited) {
    out.add(('Ulan lang o kulang ang tubig: mag-abono pagkatapos umulan o kapag mamasa-masa ang lupa. Iwasan ang malakas na abono sa tag-init.',
    'Rain-fed or limited water: apply after rain or when the soil is moist. Avoid heavy fertilizer in the dry season.'));
  }
  out.add(('Para sa pinakatumpak na dami, magpa-soil test sa Municipal Agriculture Office (MAO) o Bureau of Soils and Water Management.',
  'For the most accurate dose, get a soil test from the Municipal Agriculture Office (MAO) or the Bureau of Soils and Water Management.'));
  return out;
}