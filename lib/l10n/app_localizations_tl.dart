// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get appSubtitle => 'Sektor ng Agrikultura ng Pagsanjan';

  @override
  String get notifications => 'Mga Abiso';

  @override
  String get refresh => 'I-refresh';

  @override
  String get navHome => 'Home';

  @override
  String get navWeather => 'Panahon';

  @override
  String get navFarm => 'Aking Bukid';

  @override
  String get navPlanting => 'Pagtatanim';

  @override
  String get navPrices => 'Presyo';

  @override
  String get navSettings => 'Mga Setting';

  @override
  String get loadingWeather => 'Kina-karga ang panahon ng iyong bukid...';

  @override
  String get tryAgain => 'Subukang muli';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get save => 'I-save';

  @override
  String get edit => 'Baguhin';

  @override
  String get close => 'Isara';

  @override
  String get hectares => 'hektarya';

  @override
  String get sqmShort => 'mkv';

  @override
  String get now => 'Ngayon';

  @override
  String get today => 'Ngayon';

  @override
  String get portalTitle => 'Portal ng Magsasaka ng Pagsanjan';

  @override
  String get signInTitle => 'Mag-login sa Portal';

  @override
  String get signInHint =>
      'Ipasok ang numero ng telepono at PIN upang magpatuloy.';

  @override
  String get phoneNumber => 'Numero ng Telepono';

  @override
  String get pinLabel => '4-Digit PIN Passcode';

  @override
  String get signIn => 'Mag-login';

  @override
  String get greetingMorning => 'Magandang umaga';

  @override
  String get greetingAfternoon => 'Magandang hapon';

  @override
  String get greetingEvening => 'Magandang gabi';

  @override
  String get todayWeather => 'Panahon ngayon';

  @override
  String get heatIndex => 'Heat index';

  @override
  String get heatIndexSub =>
      'Gaano kainit ang pakiramdam kapag isinama ang halumigmig';

  @override
  String get heatNormal => 'Normal';

  @override
  String get heatCaution => 'Mag-ingat';

  @override
  String get heatExtremeCaution => 'Labis na pag-iingat';

  @override
  String get heatDanger => 'Panganib';

  @override
  String get heatExtremeDanger => 'Matinding panganib';

  @override
  String get heatAdviceNormal =>
      'Komportable para sa trabaho sa bukid. Uminom ng tubig nang regular.';

  @override
  String get heatAdviceCaution =>
      'Maaaring mapagod kapag matagal sa init. Magpahinga sa lilim at uminom ng tubig.';

  @override
  String get heatAdviceExtremeCaution =>
      'Posible ang pulikat at panghihina dahil sa init. Magtrabaho sa maagang umaga o hapon at magpahinga nang madalas.';

  @override
  String get heatAdviceDanger =>
      'Malamang ang panghihina dahil sa init at posible ang heat stroke. Iwasan ang trabaho sa bukid tuwing tanghali.';

  @override
  String get heatAdviceExtremeDanger =>
      'Napakalaki ng tsansa ng heat stroke. Manatili sa loob o sa lilim at iwasan ang trabaho sa bukid.';

  @override
  String get heatScaleSource =>
      'Tantiya mula sa temperatura at halumigmig. Ang mga antas ay ayon sa heat index scale ng PAGASA.';

  @override
  String get forecastTitle => 'Pagtaya';

  @override
  String get hourlyTab => 'Oras-oras';

  @override
  String get weeklyTab => '7 araw';

  @override
  String get heatTimeline => 'Heat index kada oras ngayong araw';

  @override
  String get heatHottest => 'Pinakamainit na oras';

  @override
  String get farmCropsTitle => 'Aking mga pananim';

  @override
  String get farmCropsSub =>
      'Pindutin ang pananim para makita ang pinakamagandang buwan ng pagtatanim.';

  @override
  String get farmTotalHarvest => 'Kabuuang ani';

  @override
  String farmShare(String percent) {
    return '$percent% ng iyong lupa';
  }

  @override
  String get farmThisMonth => 'Ngayong buwan';

  @override
  String farmDaysGrown(int days, int total) {
    return 'Araw $days ng tinatayang $total';
  }

  @override
  String farmExpectedHarvest(String range) {
    return 'Inaasahang ani: $range';
  }

  @override
  String get farmReadySoon => 'Malapit nang anihin';

  @override
  String get farmLastHarvest => 'Huling ani';

  @override
  String farmYieldPerHa(String value) {
    return '$value kg bawat hektarya';
  }

  @override
  String get farmEstimateNote =>
      'Tantiya lamang ang mga petsa. Nakadepende sa panahon at uri ng tanim ang aktwal na ani.';

  @override
  String get priceMyCrops => 'Aking pananim';

  @override
  String get priceAllCrops => 'Lahat';

  @override
  String get priceRising => 'Tumataas';

  @override
  String get priceFalling => 'Bumababa';

  @override
  String get priceGraphTitle => 'Inaasahang presyo sa susunod na 7 araw';

  @override
  String get priceRange => 'Saklaw sa 7 araw';

  @override
  String get priceHighest => 'Pinakamataas na inaasahan';

  @override
  String get priceWhyTitle => 'Bakit nagbabago ang presyo?';

  @override
  String get priceFactorRain => 'Ulan';

  @override
  String get priceFactorHeat => 'Init';

  @override
  String get priceFactorSeason => 'Panahon ng ani';

  @override
  String priceRainHeavy(String mm) {
    return 'Mga $mm mm ng ulan sa susunod na 7 araw. Maaaring bumaha sa bukid at kumonti ang suplay, kaya madalas tumataas ang presyo.';
  }

  @override
  String priceRainDry(String mm) {
    return 'Mga $mm mm lang ng ulan sa susunod na 7 araw. Ang tagtuyot ay maaaring magpababa ng ani, kaya bahagyang tataas ang presyo.';
  }

  @override
  String priceRainNormal(String mm) {
    return 'Mga $mm mm ng ulan sa susunod na 7 araw. Normal ang panahon, kaya steady ang suplay.';
  }

  @override
  String priceHeatHigh(String hi) {
    return 'Napakainit sa mga darating na araw (heat index hanggang $hi°C). Maaaring bumaba ang ani dahil sa init, kaya maaaring tumaas ang presyo.';
  }

  @override
  String get priceHeatNormal =>
      'Walang inaasahang matinding init. Walang epekto sa presyo.';

  @override
  String get priceSeasonPeak =>
      'Ayon sa kalendaryo ng pagtatanim, panahon na ng anihan ng pananim na ito. Mas maraming suplay, kaya karaniwang mas mababa ang presyo.';

  @override
  String get priceSeasonOff =>
      'Ayon sa kalendaryo ng pagtatanim, hindi pa panahon ng anihan ng pananim na ito. Mas kaunti ang suplay, kaya karaniwang steady o mas mataas ang presyo.';

  @override
  String priceLastHarvestValue(String kg, String value) {
    return 'Ang huli mong ani ($kg kg) ay nagkakahalaga ng mga ₱$value sa inaasahang presyo.';
  }

  @override
  String get priceDisclaimer =>
      'Tantiya lamang ito mula sa simpleng modelo na gumagamit ng 7-araw na weather forecast at kalendaryo ng pagtatanim. Ang mga kasalukuyang presyo ay halimbawa lamang at hindi opisyal na presyo sa palengke. Kumpirmahin sa Tanggapan ng Pambayang Agrikultura o sa palengke bago magbenta.';

  @override
  String get farmOverview => 'Buod ng bukid';

  @override
  String get overviewCrops => 'Mga pananim';

  @override
  String get overviewCropsSub => 'Aktibong pananim';

  @override
  String get overviewPlantNow => 'Magandang itanim';

  @override
  String get overviewPlantNowSub => 'pananim ngayong buwan';

  @override
  String get next12Hours => 'Susunod na 12 oras';

  @override
  String get adviceTitle => 'Payo sa pagsasaka ngayong araw';

  @override
  String get adviceSubtitle => 'Batay sa kasalukuyang panahon';

  @override
  String get forecast7Days => 'Pagtaya sa 7 araw';

  @override
  String plantInMonth(String month) {
    return 'Magandang itanim ngayong $month';
  }

  @override
  String get noBestCrop =>
      'Walang pananim na nasa pinakamagandang panahon ng pagtatanim ngayong buwan.';

  @override
  String get statusLive => 'KASALUKUYAN';

  @override
  String get statusOffline => 'WALANG INTERNET';

  @override
  String get feelsLike => 'Nararamdaman';

  @override
  String get humidity => 'Halumigmig';

  @override
  String get wind => 'Hangin';

  @override
  String get rainChance => 'Tsansa ng ulan';

  @override
  String todayRange(String min, String max, String rain) {
    return 'Ngayong araw: $min° - $max°   •   Ulan $rain mm';
  }

  @override
  String updatedAt(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Na-update $timeString  (awtomatikong nagre-refresh kada 10 min)';
  }

  @override
  String get homeCropsTitle => 'Mga Pananim sa Pagsanjan';

  @override
  String get homeCropsSub =>
      'Pindutin ang pananim para makita ang pinakamagandang buwan ng pagtatanim.';

  @override
  String get homeCropsNote =>
      'Mga karaniwang tanim sa Laguna. Ang mga buwan ng pagtatanim ay gabay lamang - kumpirmahin sa Tanggapan ng Pambayang Agrikultura.';

  @override
  String get dssTitle => 'Pinakamagandang buwan ng pagtatanim';

  @override
  String get dssSubtitle =>
      'Pagsanjan, Laguna - gabay batay sa kalendaryo ng pagtatanim';

  @override
  String get dssRainNote =>
      'Inaasahan ang maraming ulan ngayong linggo. Suriin ang kanal at daluyan ng tubig bago magtanim.';

  @override
  String get dssBestMonths => 'Pinakamagandang buwan';

  @override
  String get dssPossibleMonths => 'Maaaring buwan';

  @override
  String get dssTip => 'Payo';

  @override
  String get dssDisclaimer =>
      'Ang graph na ito ay gabay lamang batay sa kalendaryo ng pagtatanim sa Pagsanjan, Laguna. Hindi ito pagtaya sa ani o presyo. Mangyaring kumpirmahin sa Tanggapan ng Pambayang Agrikultura.';

  @override
  String get totalLandSize => 'Kabuuan ng sukat ng lupa';

  @override
  String get plantedWhere => 'Ano ang nakatanim at saan';

  @override
  String get cropHistory => 'Kasaysayan ng pananim';

  @override
  String plantedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Itinanim noong $dateString';
  }

  @override
  String harvestedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Naani noong $dateString';
  }

  @override
  String get stillGrowing => 'Lumalaki pa';

  @override
  String get whenToPlant => 'Kailan magandang magtanim?';

  @override
  String get tapMonth =>
      'Pindutin ang buwan upang makita ang magandang itanim.';

  @override
  String get legendBest => 'Pinakamaganda';

  @override
  String get legendPossible => 'Maaari';

  @override
  String get legendAvoid => 'Hindi inirerekomenda';

  @override
  String get myCrop => 'Aking tanim';

  @override
  String get statusBest => 'Pinakamagandang magtanim';

  @override
  String get statusPossible => 'Maaaring magtanim';

  @override
  String get statusAvoid => 'Hindi inirerekomenda ngayon';

  @override
  String bestMonthLabel(String month) {
    return 'Pinakamaganda: $month';
  }

  @override
  String harvestIn(String time) {
    return 'Maaani pagkaraan ng $time';
  }

  @override
  String get plantingDisclaimer =>
      'Ito ay pangkalahatang gabay para sa Laguna. Ang panahon ay maaaring magbago - mangyaring sumangguni rin sa Municipal Agriculture Office.';

  @override
  String get cropPrices => 'Presyo ng mga pananim';

  @override
  String get pricesSubtitle =>
      'Inaasahang presyo batay sa darating na panahon. Sa PHP bawat kg.';

  @override
  String get noPriceData =>
      'Wala pang datos ng presyo para sa iyong mga tanim.';

  @override
  String get expected => 'Inaasahan';

  @override
  String get appSettings => 'Mga Setting ng App';

  @override
  String get appSettingsSub =>
      'Tingnan ang iyong account, humingi ng tulong, at basahin ang patakaran sa pagkapribado.';

  @override
  String get accountDetails => 'Detalye ng Account';

  @override
  String get farmerName => 'Pangalan ng Magsasaka';

  @override
  String get barangay => 'Barangay';

  @override
  String get birthday => 'Kapanganakan';

  @override
  String get landSize => 'Sukat ng Lupa';

  @override
  String get displaySettings => 'Itsura ng App';

  @override
  String get displaySettingsSub => 'Gawing mas madaling basahin ang teksto';

  @override
  String get textSize => 'Laki ng teksto';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Malaki';

  @override
  String get textSizeXLarge => 'Pinakamalaki';

  @override
  String get textSizeSample => 'Halimbawa: Magandang umaga, magsasaka!';

  @override
  String get helpSupport => 'Tulong at Suporta';

  @override
  String get helpSupportSub => 'Kailangan ng tulong sa app o sa inyong bukid?';

  @override
  String get howToUse => 'Paano gamitin ang PAGRI';

  @override
  String get howTo1 =>
      'Home: tingnan ang panahon ngayon, ang 7-araw na pagtaya, payo sa bukid at ang mga pananim sa Pagsanjan.';

  @override
  String get howTo2 =>
      'Aking Bukid: tingnan ang inyong mga taniman, pananim at tala ng ani.';

  @override
  String get howTo3 =>
      'Pindutin ang pananim sa Home para makita ang pinakamagandang buwan ng pagtatanim.';

  @override
  String get howTo4 =>
      'Presyo: tingnan ang inaasahang presyo at kung kailan ibebenta.';

  @override
  String get howTo5 =>
      'Pindutin ang kampana sa taas para mabasa ang inyong mga abiso.';

  @override
  String get contactOffice => 'Tanggapan ng Pambayang Agrikultura';

  @override
  String get contactOfficeSub =>
      'Bumisita sa tanggapan sa Pagsanjan, Laguna para sa pagbabago ng account, ayuda at tulong sa pagsasaka.';

  @override
  String get aboutApp => 'Tungkol sa App';

  @override
  String get appVersion => 'Bersyon 1.0.0 ng PAGRI';

  @override
  String get privacyPolicy => 'Patakaran sa Pagkapribado';

  @override
  String get privacySystemName => 'Sistema ng Agrikultura ng Pagsanjan';

  @override
  String get privacySummary =>
      'Ang PAGRI (Pagsanjan Agricultural Decision Support System) ay nangangalaga sa datos ng bawat rehistradong magsasaka. Ang mga impormasyon tulad ng barangay, sukat ng lupa, at mga pananim ay ginagamit lamang sa pagbibigay ng tumpak na taya ng panahon, presyo sa pamilihan, at tulong mula sa Municipal Agriculture Office.';

  @override
  String get readFullPolicy => 'Basahin ang Buong Patakaran sa Pagkapribado';

  @override
  String get logout => 'Mag-log out';

  @override
  String get logoutConfirm =>
      'Sigurado ka bang gusto mong mag-log out sa iyong PAGRI portal?';

  @override
  String get logoutButton => 'I-log out';

  @override
  String get privacySubtitle =>
      'Sistema ng Suporta sa Pagdedesisyon sa Agrikultura (PAGRI - Pagsanjan, Laguna)';

  @override
  String get policy1Title => '1. Pangongolekta ng Datos';

  @override
  String get policy1Body =>
      'Kinokolekta lamang ng PAGRI ang kinakailangang impormasyon ng magsasaka tulad ng pangalan, barangay, sukat ng lupa, at uri ng mga pananim upang magbigay ng tumpak na pagtaya sa panahon at presyo.';

  @override
  String get policy2Title => '2. Paggamit ng Impormasyon';

  @override
  String get policy2Body =>
      'Ang iyong datos ay ginagamit lamang para sa pagtaya sa panahon mula sa Open-Meteo, pagkwenta ng inaasahang presyo sa pamilihan, at pagtulong sa Municipal Agriculture Office ng Pagsanjan sa pagpaplano sa sektor ng agrikultura.';

  @override
  String get policy3Title => '3. Seguridad at Proteksyon';

  @override
  String get policy3Body =>
      'Protektado ang lahat ng impormasyon ng magsasaka. Hindi kailanman ibinebenta o ibinabahagi ang iyong personal na datos sa mga ikatlong partido para sa komersyal na layunin.';

  @override
  String get policy4Title => '4. Karapatan ng Magsasaka';

  @override
  String get policy4Body =>
      'May karapatan ang magsasaka na tingnan, palitan, o ipabura ang kanyang datos anumang oras sa pamamagitan ng pakikipag-ugnayan sa Municipal Agriculture Office.';

  @override
  String get understand => 'Naiintindihan Ko';

  @override
  String get markAllRead => 'Basahin lahat';

  @override
  String get noNotifications => 'Walang bagong abiso sa kasalukuyan.';

  @override
  String get cropRice => 'Palay';

  @override
  String get cropEggplant => 'Talong';

  @override
  String get cropTomato => 'Kamatis';

  @override
  String get cropStringBeans => 'Sitaw';

  @override
  String get cropBanana => 'Saging';

  @override
  String get cropCoconut => 'Niyog';

  @override
  String get cropAmpalaya => 'Ampalaya';

  @override
  String get cropSquash => 'Kalabasa';

  @override
  String get cropSweetPotato => 'Kamote';

  @override
  String get cropTaro => 'Gabi';

  @override
  String get cropCalamansi => 'Calamansi';

  @override
  String get cropDescBanana =>
      'Namumunga sa buong taon. Itanim sa simula ng tag-ulan at suhayan ang mga puno bago ang bagyo.';

  @override
  String get cropDescRice =>
      'Pangunahing pagkain ng mga Pilipino, itinatanim sa palayan. May tanim sa tag-ulan at tag-araw.';

  @override
  String get cropDescCoconut =>
      'Punong pinagkukunan ng buko, kopra at langis ng niyog.';

  @override
  String get cropDescEggplant =>
      'Paboritong gulay para sa tortang talong at pinakbet. Pinakamagandang tumubo sa mas malamig na tuyong buwan.';

  @override
  String get cropDescAmpalaya =>
      'Mapait na gulay na gumagapang sa balag. Ginagamit sa ginisang ampalaya at pinakbet.';

  @override
  String get cropDescStringBeans =>
      'Mabilis tumubong gulay na gumagapang sa balag o suhay.';

  @override
  String get cropDescSquash =>
      'Gumagapang na halaman na namumunga ng masustansiyang kalabasa. Kinakain din ang dahon at bulaklak. Karaniwan sa pinakbet at ginataan.';

  @override
  String get cropDescTomato =>
      'Kinakain nang sariwa at ginagamit sa sarsa. Ang sobrang ulan ay nagdudulot ng sakit, kaya magtanim pagkatapos ng panahon ng bagyo.';

  @override
  String get cropDescSweetPotato =>
      'Ugat na madaling tumubo at kayang tumagal sa tuyong panahon. Kinakain ang ugat at ang talbos.';

  @override
  String get cropDescTaro =>
      'Ugat na gustong tumubo sa mamasa-masang lupa. Kinakain ang gabi at ang dahon, ginagamit sa laing at sinigang.';

  @override
  String get cropDescCalamansi =>
      'Maliit na punong sitrus. Ang maasim na bunga ay ginagamit sa katas, sawsawan at lutuin. Kailangan ng araw at lupang hindi nababaha.';

  @override
  String get plotHarvested => 'Naani na';

  @override
  String get plotGrowing => 'Lumalaki';

  @override
  String get weatherSunny => 'Maaraw';

  @override
  String get weatherClearNight => 'Maaliwalas';

  @override
  String get weatherPartlyCloudy => 'Medyo maulap';

  @override
  String get weatherCloudy => 'Maulap';

  @override
  String get weatherFoggy => 'Maulap at malabo';

  @override
  String get weatherDrizzle => 'Ambon';

  @override
  String get weatherRain => 'Umuulan';

  @override
  String get weatherThunderstorm => 'Kulog at ulan';

  @override
  String get adviceThunderTitle => 'Banta ng kulog at kidlat';

  @override
  String get adviceThunderMsg =>
      'Umiwas sa bukas na bukirin at isilong ang mga kagamitan at alagang hayop.';

  @override
  String get adviceRainTitle => 'Inaasahan ang ulan ngayong araw';

  @override
  String get adviceRainMsg =>
      'Huwag muna mag-spray o mag-abono ngayong araw dahil maaagos ng ulan. Tiyaking maayos ang daloy ng kanal.';

  @override
  String get adviceHotTitle => 'Napakainit ngayong araw';

  @override
  String get adviceHotMsg =>
      'Magdilig sa maagang umaga o hapon. Lilungan ang mga batang tanim sa tanghaling tapat.';

  @override
  String get adviceWindTitle => 'Malakas na hangin';

  @override
  String get adviceWindMsg =>
      'Suhayan ang mga saging at itali ang mga pasan ng kamatis at sitaw.';

  @override
  String get adviceFieldTitle => 'Magandang panahon sa bukid';

  @override
  String get adviceFieldMsg =>
      'Tuyo ang mga darating na araw - maganda para sa pag-aani, pagpapatuyo ng palay, pag-i-spray, at pag-aabono.';

  @override
  String get adviceNormalTitle => 'Normal na panahon';

  @override
  String get adviceNormalMsg =>
      'Walang espesyal na babala. Magpatuloy sa karaniwang gawain sa bukid.';

  @override
  String get notifWeatherTitle => 'Babala sa Panahon sa Pagsanjan';

  @override
  String get notifWeatherMsg =>
      'Inaasahan ang malakas na ulan sa mga darating na araw. Tiyaking maayos ang daloy ng kanal sa bukid.';

  @override
  String get notifMarketTitle => 'Balita sa Presyo ng Pananim';

  @override
  String get notifMarketMsg =>
      'Inaasahang tataas ng 8% ang presyo ng Kamatis at Talong sa pamilihan batay sa ulan.';

  @override
  String get notifPlantingTitle => 'Takdang Panahon ng Pagtatanim';

  @override
  String get notifPlantingMsg =>
      'Pinakamagandang panahon ngayon upang magtanim ng Palay sa Laguna.';

  @override
  String get notifPestTitle => 'Bantay Peste: Rice Stem Borer sa Laguna';

  @override
  String get notifPestMsg =>
      'May naiulat na paglitaw ng stem borer sa mga kalapit na barangay. Regular na suriin ang inyong palayan.';

  @override
  String get notifSubsidyTitle => 'Ayuda sa Abono mula sa LGU Pagsanjan';

  @override
  String get notifSubsidyMsg =>
      'Kasalukuyang ipinamamahagi ang libreng organikong abono sa Tanggapan ng Pambayang Agrikultura.';

  @override
  String get reasonHeavyRain =>
      'Inaasahan ang malakas na ulan; maaaring bumaba ang supply.';

  @override
  String get reasonDry =>
      'Inaasahan ang panahon ng tagtuyot; may kaunting epekto sa supply.';

  @override
  String get reasonStable => 'Maayos ang panahon; steady ang supply.';

  @override
  String get sellWait =>
      'Maaaring tumaas ang presyo - maghintay ng ilang araw bago magbenta.';

  @override
  String get sellSlight =>
      'Bahagyang pagtaas ang inaasahan - magbenta kapag handa na ang ani.';

  @override
  String get sellSoon =>
      'Maaaring bumaba ang presyo - magbenta agad kung handa na ang ani.';

  @override
  String get guideHarvestRice => '110-120 araw';

  @override
  String get guideTipRice =>
      'Ang tanim sa tag-ulan ay Hunyo-Hulyo. Ang tanim sa tag-araw ay Nobyembre-Disyembre at kailangan ng tuloy-tuloy na patubig.';

  @override
  String get guideHarvestEggplant => '90-120 araw';

  @override
  String get guideTipEggplant =>
      'Pinakamagandang tumubo sa mas malamig na tuyong buwan. Iwasang maglipat-tanim kapag malakas ang ulan.';

  @override
  String get guideHarvestTomato => '90-110 araw';

  @override
  String get guideTipTomato =>
      'Ang sobrang ulan ay nagdudulot ng sakit at pagkalanta. Magtanim pagkatapos ng panahon ng bagyo para sa magandang ani.';

  @override
  String get guideHarvestStringBeans => '60-70 araw';

  @override
  String get guideTipStringBeans =>
      'Mabilis maani. Lagyan ng suhay o balag. Kailangan ng lupang mabilis matuyo.';

  @override
  String get guideHarvestBanana => '9-12 buwan';

  @override
  String get guideTipBanana =>
      'Magtanim sa simula ng tag-ulan upang mabilis mag-ugat ang mga suhi. Suhayan ang mga puno bago ang bagyo.';

  @override
  String get guideHarvestCoconut => '3-6 taon bago mamunga';

  @override
  String get guideTipCoconut =>
      'Itanim ang punla sa simula ng tag-ulan at diligan sa unang tag-araw.';

  @override
  String get guideHarvestAmpalaya => '2-3 buwan matapos itanim';

  @override
  String get guideTipAmpalaya =>
      'Lagyan ng balag. Diligan nang regular pero iwasan ang lupang binabaha.';

  @override
  String get guideHarvestSquash => '3-4 buwan matapos itanim';

  @override
  String get guideTipSquash =>
      'Bigyan ng lugar ang mga baging na kumalat. Iwasang magtanim sa pinakamalakas na ulan.';

  @override
  String get guideHarvestSweetPotato => '3-4 buwan matapos itanim';

  @override
  String get guideTipSweetPotato =>
      'Itanim ang pinagputol na baging sa maluwag na lupa. Iwasan ang bukid na binabaha.';

  @override
  String get guideHarvestTaro => '6-9 buwan matapos itanim';

  @override
  String get guideTipTaro =>
      'Itanim sa mamasa-masang lupa na may tuloy-tuloy na tubig.';

  @override
  String get guideHarvestCalamansi => '1-3 taon bago mamunga';

  @override
  String get guideTipCalamansi =>
      'Pumili ng lugar na maaraw at hindi nababaha. Regular na putulan at abonohan.';

  @override
  String get errorLoad =>
      'Hindi maikonekta. Tiyaking may internet connection at subukang muli.';

  @override
  String get navDss => 'DSS';

  @override
  String get dssMyTitle => 'Gabay sa Desisyon sa Bukid';

  @override
  String get dssMySubtitle =>
      'Ilagay ang tanim mo at makakuha ng payong akma sa bukid mo';

  @override
  String get dssMyDisclaimer =>
      'Ang mga numerong ito ay tantiya at gabay lamang, hindi opisyal na datos o garantiyang forecast. Kumpirmahin sa Tanggapan ng Pambayang Agrikultura bago gumawa ng malalaking desisyon.';

  @override
  String get dssMonthsShort =>
      'Ene,Peb,Mar,Abr,May,Hun,Hul,Ago,Set,Okt,Nob,Dis';

  @override
  String get dssEmptyTitle => 'Idagdag ang una mong tanim';

  @override
  String get dssEmptyBody =>
      'Ilagay ang pananim, laki ng lupa at petsa ng pagtanim. Lalabas dito ang payo sa pagtatanim, inaasahang ani, kita at tamang oras ng pagbebenta.';

  @override
  String get dssAddPlanting => 'Magdagdag ng tanim';

  @override
  String get dssEditPlanting => 'I-edit ang tanim';

  @override
  String get dssAdd => 'Dagdag';

  @override
  String get dssDelete => 'Burahin';

  @override
  String get dssDeleteTitle => 'Burahin ang tanim na ito?';

  @override
  String dssDeleteBody(String crop) {
    return 'Aalisin ang $crop sa listahan mo.';
  }

  @override
  String get dssMyPlantings => 'Mga tanim ko';

  @override
  String get dssCrop => 'Pananim';

  @override
  String get dssLandSize => 'Laki ng lupa';

  @override
  String get dssLandSizeHint => 'Sa ektarya. 1,000 sq m = 0.1 ha';

  @override
  String get dssAreaInvalid => 'Maglagay ng numerong higit sa 0';

  @override
  String get dssPlantedOn => 'Petsa ng pagtanim';

  @override
  String get dssLastYield => 'Huling ani (opsyonal)';

  @override
  String get dssLastYieldHint =>
      'Kabuuang kg sa huling ani mo sa lupang ito. Mas lalapit ang tantiya sa bukid mo.';

  @override
  String get dssDaysGrown => 'Araw mula nang itanim';

  @override
  String dssDaysCount(int n) {
    return '$n araw';
  }

  @override
  String get dssNotYet => 'Hindi pa naitatanim';

  @override
  String get dssExpectedHarvest => 'Inaasahang ani (panahon)';

  @override
  String get dssHarvestYearRound => 'Inaani buong taon';

  @override
  String get dssPlantingAdvisory => 'Payo sa pagtatanim';

  @override
  String get dssPlantingAdvisorySub =>
      'Aling buwan ang pinakamainam sa pananim na ito';

  @override
  String dssFitBest(String crop) {
    return 'Magandang panahon ngayon magtanim ng $crop';
  }

  @override
  String dssFitPossible(String crop) {
    return 'Puwede ngayong magtanim ng $crop, pero hindi ito ang pinakamainam na panahon';
  }

  @override
  String dssFitAvoid(String crop) {
    return 'Hindi magandang panahon ngayon magtanim ng $crop';
  }

  @override
  String get dssLegendBest => 'Pinakamainam';

  @override
  String get dssLegendPossible => 'Puwede';

  @override
  String get dssLegendAvoid => 'Iwasan';

  @override
  String get dssNextBest => 'Susunod na pinakamainam na buwan';

  @override
  String get dssWeatherBasis => 'Batay sa';

  @override
  String get dssWeatherBasisBody =>
      'karaniwang tag-ulan at tag-init sa Laguna. Tingnan ang weather forecast bago magtanim.';

  @override
  String get dssHarvestIncome => 'Ani at kita';

  @override
  String get dssHarvestIncomeSub => 'Tantiya na may saklaw';

  @override
  String get dssExpectedYield => 'Inaasahang ani';

  @override
  String get dssYieldPerYear => 'Ani bawat taon';

  @override
  String get dssExpectedIncome => 'Inaasahang kita';

  @override
  String get dssNoPrice => 'Walang halimbawang presyo para sa pananim na ito';

  @override
  String get dssNoEstimate => 'Wala pang tantiya para sa pananim na ito.';

  @override
  String get dssLow => 'Mababa';

  @override
  String get dssLikely => 'Malamang';

  @override
  String get dssHigh => 'Mataas';

  @override
  String get dssHowComputed => 'Paano kinuwenta';

  @override
  String dssBasisOwn(String ha) {
    return 'Ang huling ani mo kada ektarya, para sa $ha (±15%).';
  }

  @override
  String dssBasisTypical(String ha, String kgHa) {
    return 'Karaniwang ani na mga $kgHa kg kada ektarya, para sa $ha.';
  }

  @override
  String get dssPriceUsed => 'Presyong ginamit';

  @override
  String get dssPriceAdvisory => 'Payo sa presyo';

  @override
  String get dssPriceAdvisorySub => 'Aling buwan karaniwang mataas ang presyo';

  @override
  String dssSellBest(String months) {
    return 'Inaasahang mas mataas ang presyo sa $months';
  }

  @override
  String get dssLegendHighPrice => 'Mas mataas na presyo';

  @override
  String get dssLegendLowPrice => 'Mas mababang presyo';

  @override
  String get dssYourHarvest => 'Ang ani mo';

  @override
  String dssHarvestHighPrice(String month) {
    return 'Malamang aanihin mo sa paligid ng $month, kung kailan karaniwang maganda ang presyo.';
  }

  @override
  String dssHarvestLowPrice(String month) {
    return 'Malamang aanihin mo sa paligid ng $month, kung kailan maraming nag-aani at karaniwang mababa ang presyo.';
  }

  @override
  String dssTipStorable(String months) {
    return 'Tumatagal ang pananim na ito. Kung kaya mong itago nang ligtas, isaalang-alang ang pagbebenta sa $months.';
  }

  @override
  String get dssTipFresh =>
      'Mabilis masira ang pananim na ito, kaya ibenta agad pagkatapos anihin. Magtanong sa mga mamimili ng pinakamagandang presyo at direktang magbenta kung kaya.';

  @override
  String get dssPriceRangeYear => 'Saklaw ng presyo sa buong taon';

  @override
  String dssPriceFlat(String crop) {
    return 'Walang malinaw na buwanang pattern ng presyo para sa $crop sa gabay namin.';
  }

  @override
  String get dssFarmMap => 'Mapa ng bukid ko';

  @override
  String get dssFarmMapSub => 'Lokasyon ng bukid at panahon doon ngayon';

  @override
  String get dssMapHint => 'I-tap ang mapa para ilipat ang pin sa bukid mo.';

  @override
  String get dssResetLocation => 'Ibalik sa gitna ng Pagsanjan';

  @override
  String get dssWeatherHere => 'Panahon sa bukid mo ngayon';

  @override
  String get dssWeatherFailed => 'Hindi ma-load ang panahon dito.';

  @override
  String get dssFeelsLike => 'Pakiramdam';

  @override
  String get dssSummaryTitle => 'DSS';

  @override
  String get dssSummaryEmpty =>
      'Idagdag ang tanim mo sa DSS tab para makakuha ng payo para sa bukid mo';

  @override
  String dssSummaryLine(String kg, String low, String high) {
    return 'Inaasahang ani mga $kg, kita $low hanggang $high.';
  }

  @override
  String dssSummaryLineNoPrice(String kg) {
    return 'Inaasahang ani mga $kg.';
  }

  @override
  String get weatherLightRain => 'Mahinang ulan';

  @override
  String get weatherHeavyRain => 'Malakas na ulan';

  @override
  String get heatBestWork => 'Pinakamainam na oras sa bukid';

  @override
  String get heatNoSafe => 'Iwasan ang matagal na trabaho sa bukid ngayon';

  @override
  String get priceNoMyCrops =>
      'Idagdag ang iyong pananim sa DSS tab para makita rito ang inaasahang presyo nito.';

  @override
  String cropAdvHarvestReadyTitle(String crop) {
    return '$crop: suriin para sa ani';
  }

  @override
  String cropAdvHarvestReadyMsg(String crop) {
    return 'Umabot na ang $crop mo sa karaniwang edad ng ani. Suriin ang tanim at ihanda ang pag-aani at mga mamimili.';
  }

  @override
  String cropAdvHarvestSoonTitle(String crop) {
    return '$crop: malapit na ang ani';
  }

  @override
  String cropAdvHarvestSoonMsg(String crop, int days) {
    return 'Maaaring handa na ang $crop mo sa mga $days araw. Ihanda ang lalagyan, mga manggagawa, at mamimili.';
  }

  @override
  String cropAdvDrainageTitle(String crop) {
    return '$crop: suriin ang kanal';
  }

  @override
  String cropAdvDrainageMsg(String crop) {
    return 'Inaasahan ang malakas na ulan sa susunod na 3 araw. Linisin ang kanal para hindi mabuhay ang tubig sa paligid ng $crop.';
  }

  @override
  String cropAdvHeatTitle(String crop) {
    return '$crop: protektahan sa init';
  }

  @override
  String cropAdvHeatMsg(String crop) {
    return 'Napakainit ngayon. Diligan ang $crop sa maagang umaga o hapon, hindi sa tanghali.';
  }

  @override
  String cropAdvWindTitle(String crop) {
    return '$crop: suhayan ang tanim';
  }

  @override
  String cropAdvWindMsg(String crop) {
    return 'Malakas ang hangin ngayon. Suhayan o itali ang $crop para hindi matumba.';
  }

  @override
  String cropAdvDryTitle(String crop) {
    return '$crop: magandang panahon sa pagpapatuyo';
  }

  @override
  String cropAdvDryMsg(String crop) {
    return 'Tuyo ang mga darating na araw. Maganda para sa pag-aani at pagpapatuyo ng $crop, pati sa pag-i-spray at pag-aabono.';
  }

  @override
  String get notifStormTitle => 'Kulog at kidlat ngayon';

  @override
  String get notifStormMsg =>
      'Umiwas sa bukas na bukirin at isilong ang mga kagamitan at alagang hayop.';

  @override
  String get notifRainTitle => 'Inaasahan ang malakas na ulan';

  @override
  String notifRainMsg(int mm) {
    return 'Mga $mm mm ng ulan sa susunod na 3 araw. Linisin ang kanal para hindi mabuhay ang tubig sa bukid.';
  }

  @override
  String get notifHeatTitle => 'Mapanganib na init ngayon';

  @override
  String notifHeatMsg(int hi) {
    return 'Heat index hanggang $hi°C. Iwasan ang trabaho sa bukid sa tanghali, magpahinga sa lilim at uminom ng tubig.';
  }

  @override
  String notifHarvestReadyTitle(String crop) {
    return '$crop: suriin para sa ani';
  }

  @override
  String notifHarvestReadyMsg(String crop) {
    return 'Umabot na ang $crop mo sa karaniwang edad ng ani. Suriin ang tanim at planuhin ang pag-aani.';
  }

  @override
  String notifHarvestSoonTitle(String crop) {
    return '$crop: malapit na ang ani';
  }

  @override
  String notifHarvestSoonMsg(String crop, int days) {
    return 'Maaaring handa na ang $crop mo sa mga $days araw.';
  }

  @override
  String notifMarketUpTitle(String crop) {
    return 'Maaaring tumaas ang presyo ng $crop';
  }

  @override
  String notifMarketUpMsg(String crop, int percent) {
    return 'Maaaring tumaas ng mga $percent% ang presyo ng $crop sa susunod na 7 araw. Tantiya lamang ito base sa weather forecast.';
  }

  @override
  String notifMarketDownTitle(String crop) {
    return 'Maaaring bumaba ang presyo ng $crop';
  }

  @override
  String notifMarketDownMsg(String crop, int percent) {
    return 'Maaaring bumaba ng mga $percent% ang presyo ng $crop sa susunod na 7 araw. Tantiya lamang ito base sa weather forecast.';
  }

  @override
  String notifPlantingNowTitle(String crop) {
    return 'Magandang panahon para magtanim ng $crop';
  }

  @override
  String notifPlantingNowMsg(String crop) {
    return 'Ang buwang ito ay isa sa pinakamagandang buwan para magtanim ng $crop sa Pagsanjan, Laguna.';
  }

  @override
  String get dssUnitHa => 'Hektarya (ha)';

  @override
  String get dssUnitSqm => 'Metro kuwadrado (m²)';

  @override
  String get dssUnitNote =>
      '1 hektarya = 10,000 m². Puwede mong palitan ang yunit anumang oras.';

  @override
  String get dssTotalLand => 'Kabuuang sukat ng lupa';

  @override
  String get dssTotalLandSub =>
      'Ilagay ang buong sukat ng bukid mo. Hahatiin mo ito sa mga pananim sa \"Add crop\".';

  @override
  String dssTotalTooSmall(String area) {
    return 'Masyadong maliit. $area na ang nagagamit ng mga pananim mo.';
  }

  @override
  String dssExceeds(String area) {
    return 'Sobra. $area na lang ang natitira sa lupa mo.';
  }

  @override
  String dssRemaining(String area) {
    return 'Natitira: $area';
  }

  @override
  String dssLandUsed(String area) {
    return 'Natataniman: $area';
  }

  @override
  String get dssLandSet => 'Ilagay ang sukat';

  @override
  String get dssLandNotSet =>
      'Ilagay ang kabuuang sukat ng lupa para makita kung ilan ang sakop ng bawat pananim.';

  @override
  String get farmUnallocated => 'Hindi pa natataniman';
}
