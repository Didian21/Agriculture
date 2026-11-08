/// Gabay at paglalarawan ng bawat pananim (para sa "Mga Pananim" sa Home tab).
/// Ang mga numero (buwan, araw, ani, presyo) ay hindi dito; galing ang mga iyon sa crop_data.dart.
/// Ang mga paglalarawan at payo ay pangkalahatang gabay lamang.
enum CropGroup { veg, fruit, root, grain }

class CropInfo {
  final String id;
  final CropGroup group;
  final String emoji;
  final String nameTl;
  final String nameEn;
  final String descTl;
  final String descEn;
  final List<String> tipsTl;
  final List<String> tipsEn;

  const CropInfo(this.id, this.group, this.emoji, this.nameTl, this.nameEn, this.descTl, this.descEn, this.tipsTl, this.tipsEn);

  /// Pangalan ng litrato: `assets/crops/slug.jpg`  (hal. 'String beans' -> string_beans)
  String get slug => id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

  String name(bool tl) => tl ? nameTl : nameEn;
  String altName(bool tl) => tl ? nameEn : nameTl;
  String desc(bool tl) => tl ? descTl : descEn;
  List<String> tips(bool tl) => tl ? tipsTl : tipsEn;
}

const List<CropInfo> kCropInfo = [
  CropInfo('Rice', CropGroup.grain, '🌾', 'Palay / Bigas', 'Rice', 'Pangunahing pagkain ng Pilipino; itinatanim sa binabahang palayan.', 'The Philippines\' staple grain, grown in flooded paddies.', ['Piliin ang binhing angkop sa panahon (tag-ulan o tag-araw).', 'Panatilihing may tubig ang palayan at bantayan ang peste.'], ['Choose seed suited to the season (wet or dry).', 'Keep the paddy flooded and watch for pests.']),
  CropInfo('Coconut', CropGroup.grain, '🥥', 'Niyog', 'Coconut', 'Punong-kahoy na nagbibigay ng buko, kopra at langis.', 'A tree crop that gives buko, copra and oil.', ['Patabaan ang puno taon-taon at linisin ang paligid.', 'Magtanim ng pananim sa pagitan ng puno para may dagdag na kita.'], ['Fertilize trees yearly and keep the base clean.', 'Intercrop between trees for extra income.']),
  CropInfo('Eggplant', CropGroup.veg, '🍆', 'Talong', 'Eggplant', 'Gulay na bagay sa tortang talong at pinakbet.', 'A vegetable for tortang talong and pinakbet.', ['Itanim sa tuyo at malamig na buwan para kaunti ang sakit.', 'Putulin ang lumang sanga para dumami ang bunga.'], ['Plant in the cooler dry months to reduce disease.', 'Prune old branches to get more fruit.']),
  CropInfo('Tomato', CropGroup.veg, '🍅', 'Kamatis', 'Tomato', 'Gulay na laging hinahanap sa kusina.', 'A kitchen staple in high demand.', ['Suhayan ang tanim para hindi mabuwal at hindi mabulok ang bunga.', 'Iwasan ang labis na ulan; ayusin ang kanal.'], ['Stake plants so fruit stays off the soil.', 'Avoid waterlogging; keep drainage clear.']),
  CropInfo('String beans', CropGroup.veg, '🌿', 'Sitaw', 'String beans (yardlong bean)', 'Mabilis tubuan at ani na gulay na akyat.', 'A fast-growing climbing vegetable.', ['Lagyan ng tukod o trellis para umakyat ang halaman.', 'Pitasin nang madalas para tuloy-tuloy ang bunga.'], ['Provide stakes or a trellis for climbing.', 'Harvest often to keep the plants producing.']),
  CropInfo('Ampalaya', CropGroup.veg, '🥒', 'Ampalaya', 'Bitter gourd', 'Gulay na mataas ang halaga at laging may bumibili.', 'A high-value vegetable with steady buyers.', ['Gumamit ng trellis; mas malinis at mas mataas ang presyo ng bunga.', 'Balutin ang bunga laban sa langaw ng prutas.'], ['Use a trellis for cleaner, higher-priced fruit.', 'Bag the fruit against fruit flies.']),
  CropInfo('Squash', CropGroup.veg, '🎃', 'Kalabasa', 'Squash', 'Matibay na gulay na madaling alagaan at matagal itago.', 'A hardy vegetable that is easy to grow and keeps well.', ['Itanim sa maluwag na lupa na may sapat na tubig.', 'Ani kapag matigas na ang balat at tuyo na ang tangkay.'], ['Plant in loose soil with enough water.', 'Harvest when the rind is hard and the stem dry.']),
  CropInfo('Sweet potato', CropGroup.root, '🍠', 'Kamote', 'Sweet potato', 'Ugat na madaling itanim, kahit sa mahirap na lupa.', 'A root crop that is easy to grow, even on poor soil.', ['Gamitin ang dulo ng baging bilang pananim.', 'Itaas ang tudling para hindi mabulok sa ulan.'], ['Plant vine cuttings.', 'Use raised rows so roots do not rot in rain.']),
  CropInfo('Taro', CropGroup.root, '🌱', 'Gabi', 'Taro', 'Ugat at dahon na kinakain (laing).', 'A root and leaf crop (used for laing).', ['Gusto ang basa at maputik na lupa.', 'Maaaring ibenta pati ang dahon at tangkay.'], ['Prefers wet, muddy soil.', 'Leaves and stalks can be sold too.']),
  CropInfo('Calamansi', CropGroup.fruit, '🍋', 'Kalamansi', 'Calamansi', 'Maasim na prutas na gamit sa luto at inumin.', 'A sour citrus used in cooking and drinks.', ['Patabaan at putulan ang puno pagkatapos ng ani.', 'Ibenta rin bilang katas o processed na produkto para mas malaki ang kita.'], ['Fertilize and prune after harvest.', 'Sell as juice or processed products for more income.']),
  CropInfo('Saba', CropGroup.fruit, '🍌', 'Saging na Saba', 'Saba banana', 'Saging na lutuin; maraming gamit (turon, banana cue).', 'A cooking banana (turon, banana cue).', ['Suhayan ang puno bago ang bagyo.', 'Tanggalin ang sobrang suckers; magtira ng 2-3 lang.'], ['Prop plants before typhoons.', 'Remove extra suckers; keep 2-3.']),
  CropInfo('Lakatan', CropGroup.fruit, '🍌', 'Saging na Lakatan', 'Lakatan banana', 'Matamis na saging na kinakain nang hilaw.', 'A sweet dessert banana.', ['Bantayan ang sakit tulad ng bunchy top.', 'Takpan ang buwig para malinis ang balat.'], ['Watch for diseases such as bunchy top.', 'Bag the bunch to keep the skin clean.']),
  CropInfo('Tordan', CropGroup.fruit, '🍌', 'Saging na Tordan (Latundan)', 'Tordan banana (Latundan)', 'Maliit at matamis na saging.', 'A small, sweet banana.', ['Itanim sa lugar na may sapat na hangin at araw.', 'Linisin ang damo para mas mabilis lumaki.'], ['Plant where there is enough sun and air.', 'Keep weeds down for faster growth.']),
  CropInfo('Pechay (Tagalog)', CropGroup.veg, '🥬', 'Petsay (Tagalog)', 'Pechay (native)', 'Mabilis na gulay na ani sa loob ng isang buwan.', 'A quick leafy green, harvested within a month.', ['Magtanim nang paunti-unti para tuloy-tuloy ang ani.', 'Diligan araw-araw sa tuyo.'], ['Plant in small batches for steady harvest.', 'Water daily in dry weather.']),
  CropInfo('Pechay (Baguio)', CropGroup.veg, '🥬', 'Petsay (Baguio)', 'Pechay (Chinese cabbage)', 'Malaki at mas mataas ang presyo kaysa sa karaniwang petsay.', 'Larger, usually priced above native pechay.', ['Mas gusto ang malamig na panahon.', 'Mag-ani bago mamulaklak.'], ['Prefers cool weather.', 'Harvest before it bolts.']),
  CropInfo('Mustasa', CropGroup.veg, '🥬', 'Mustasa', 'Mustard greens', 'Madaling itanim na dahon na pang-sinigang at salad.', 'An easy leafy green for sinigang and salads.', ['Mabilis ang ani; puwedeng ilang beses sa isang taon.', 'Iwasan ang tubig na nakatayo.'], ['Fast to harvest; several crops a year.', 'Avoid standing water.']),
  CropInfo('Radish', CropGroup.root, '🥕', 'Labanos', 'Radish', 'Ugat na mabilis anihin at pang-sinigang.', 'A fast-growing root for sinigang.', ['Itanim nang diretso sa lupa; ayaw ng transplant.', 'Ani sa 30-45 araw bago maging mapait.'], ['Sow directly; it dislikes transplanting.', 'Harvest in 30-45 days before it turns pithy.']),
  CropInfo('Carrot', CropGroup.root, '🥕', 'Karot', 'Carrot', 'Ugat na gusto sa malamig at maluwag na lupa.', 'A root crop that likes cool, loose soil.', ['Palaging ihanda ang lupa nang maluwag at walang bato.', 'Ihinay ang tanim para lumaki ang ugat.'], ['Prepare loose, stone-free soil.', 'Thin seedlings so roots grow bigger.']),
  CropInfo('Potato', CropGroup.root, '🥔', 'Patatas', 'Potato', 'Ugat na matagal itago at mataas ang presyo.', 'A storable root with firm prices.', ['Gumamit ng malusog na buto ng patatas.', 'Tabunan ng lupa ang puno para hindi maberde ang tubers.'], ['Use healthy seed tubers.', 'Hill the soil so tubers do not turn green.']),
  CropInfo('Garlic', CropGroup.root, '🧄', 'Bawang', 'Garlic', 'Pampalasa na mataas ang halaga at matagal itago.', 'A high-value spice that stores well.', ['Patuyuin nang maayos pagkatapos anihin.', 'Ibenta kapag tumaas ang presyo; kaya itong iimbak.'], ['Cure well after harvest.', 'Store and sell when prices rise.']),
  CropInfo('Onion', CropGroup.root, '🧅', 'Sibuyas', 'Onion', 'Pampalasa na laging kailangan sa kusina.', 'A kitchen essential in constant demand.', ['Itanim sa tuyo na panahon.', 'Patuyuin ang bombilya bago itago.'], ['Plant in the dry season.', 'Dry the bulbs before storing.']),
  CropInfo('Ginger', CropGroup.root, '🌱', 'Luya', 'Ginger', 'Pampalasa at gamot; mataas ang presyo.', 'A spice and remedy with firm prices.', ['Mahaba ang panahon (8-9 buwan), kaya planuhin ang puhunan.', 'Itanim sa may lilim at mahusay ang kanal.'], ['Long crop (8-9 months); plan your capital.', 'Plant in partial shade with good drainage.']),
  CropInfo('Okra', CropGroup.veg, '🌿', 'Okra', 'Okra', 'Gulay na matibay sa init at madaling alagaan.', 'A heat-tolerant, easy vegetable.', ['Pitasin kapag bata pa para malambot.', 'Kayang tiisin ang tag-init.'], ['Pick young for tender pods.', 'Handles hot, dry weather well.']),
  CropInfo('Upo', CropGroup.veg, '🥒', 'Upo', 'Bottle gourd', 'Gulay na akyat; ibinebenta kada piraso.', 'A climbing gourd sold per piece.', ['Gumamit ng trellis para tuwid ang bunga.', 'Ani habang bata at mapusyaw ang balat.'], ['Use a trellis for straight fruit.', 'Harvest young while the skin is pale.']),
  CropInfo('Patola', CropGroup.veg, '🥒', 'Patola', 'Sponge gourd', 'Gulay na akyat na pang-sabaw.', 'A climbing gourd used in soups.', ['Trellis ang pinakamahusay na paraan.', 'Madalas na pitasin para tuloy-tuloy ang ani.'], ['A trellis works best.', 'Pick often to keep it producing.']),
  CropInfo('Cabbage', CropGroup.veg, '🥬', 'Repolyo', 'Cabbage', 'Gulay na gusto ang malamig na panahon at mataas ang ani.', 'A cool-season vegetable with high yields.', ['Diligan nang regular pero huwag baha.', 'Bantayan ang uod at peste.'], ['Water regularly without flooding.', 'Watch for caterpillars and pests.']),
  CropInfo('Beans', CropGroup.veg, '🌿', 'Baguio beans', 'Snap beans (Baguio beans)', 'Berdeng beans na malutong.', 'Crisp snap beans.', ['Piliin ang uri na bush o pole ayon sa espasyo.', 'Ani nang madalas habang bata ang bunga.'], ['Pick bush or pole type to suit your space.', 'Harvest often while pods are young.']),
  CropInfo('Kangkong', CropGroup.veg, '🥬', 'Kangkong', 'Water spinach', 'Mabilis na gulay; ibinebenta kada tali.', 'A fast green sold per bundle.', ['Puwedeng i-ani nang paulit-ulit (gupitin ang dulo).', 'Mahilig sa basa; mabuti sa mababang bahagi ng lupa.'], ['Cut and regrow for repeat harvests.', 'Loves wet ground.']),
  CropInfo('Celery', CropGroup.veg, '🥬', 'Kintsay', 'Celery', 'Pampalasa-gulay na mataas ang presyo sa tamang buwan.', 'A herb-vegetable with high prices at the right time.', ['Magtanim sa malamig na panahon.', 'Diligan nang madalas; mababaw ang ugat.'], ['Plant in cool weather.', 'Water often; roots are shallow.']),
  CropInfo('Cucumber', CropGroup.veg, '🥒', 'Pipino', 'Cucumber', 'Gulay na mabilis anihin at pang-salad.', 'A fast salad vegetable.', ['Gumamit ng trellis para malinis ang bunga.', 'Ani sa loob ng 45-60 araw.'], ['Use a trellis for cleaner fruit.', 'Harvest in 45-60 days.']),
  CropInfo('Sayote', CropGroup.veg, '🥒', 'Sayote', 'Chayote', 'Baging na gulay na pangmatagalan.', 'A perennial vine vegetable.', ['Gumamit ng matibay na trellis.', 'Ani nang madalas para tuloy-tuloy.'], ['Use a sturdy trellis.', 'Harvest often for steady production.']),
  CropInfo('Chili (long)', CropGroup.veg, '🌶️', 'Sili (Panigang)', 'Chili (long green)', 'Mahabang sili na pang-sinigang.', 'A long green chili used in sinigang.', ['Itanim kung saan hindi nababaha.', 'Pitasin nang madalas para tuloy ang bunga.'], ['Plant where water does not pool.', 'Pick often to keep fruit coming.']),
  CropInfo('Chili (hot)', CropGroup.veg, '🌶️', 'Sili (Labuyo)', 'Chili (bird\'s eye)', 'Maanghang na sili na mataas ang presyo kapag kakaunti.', 'A hot chili with high prices when scarce.', ['Mahilig sa araw pero kailangan ng tubig.', 'Patuyuin para itago at ibenta sa tamang oras.'], ['Loves sun but needs water.', 'Dry to store and sell later.']),
  CropInfo('Bell pepper', CropGroup.veg, '🫑', 'Bell pepper', 'Bell pepper', 'Gulay na mataas ang presyo; sensitibo sa init at ulan.', 'A high-value vegetable that is sensitive to heat and rain.', ['Mas mainam sa malamig na buwan.', 'Suhayan ang halaman.'], ['Does best in cooler months.', 'Stake the plants.']),
];

CropInfo? cropInfoFor(String id) {
  for (final c in kCropInfo) {
    if (c.id == id) return c;
  }
  return null;
}