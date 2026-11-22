import 'package:flutter/material.dart';

import '../dashboard_data.dart';
import '../models/farm_record.dart';
import 'soil_moisture_service.dart';

enum AdviceLevel { warn, tip, good }

class AgriAdvice {
  final AdviceLevel level;
  final IconData icon;
  final String titleTl, titleEn, bodyTl, bodyEn;
  const AgriAdvice({
    required this.level,
    required this.icon,
    required this.titleTl,
    required this.titleEn,
    required this.bodyTl,
    required this.bodyEn,
  });
  String title(bool tl) => tl ? titleTl : titleEn;
  String body(bool tl) => tl ? bodyTl : bodyEn;
}

/// Mga payo na nabubuo gamit ang MGA PATAKARAN (rule-based) mula sa weather forecast, halumigmig ng lupa
/// at yugto ng pananim. Wala pang machine learning o satellite NDVI dito.
class AgriAdvisoryService {
  List<AgriAdvice> build({required FarmRecord farm, required WeatherBundle w, SoilMoisture? soil}) {
    final out = <AgriAdvice>[];
    final days = w.daily;
    final stage = farm.stage;
    final isRice = farm.crop == 'Rice';
    final cropTl = isRice ? 'palayan' : 'tanim';
    final cropEn = isRice ? 'rice field' : 'crop';

    final today = days.isNotEmpty ? days[0] : null;
    final tomorrow = days.length > 1 ? days[1] : null;
    final rain48 = (today?.rainMm ?? 0) + (tomorrow?.rainMm ?? 0);
    final rain7 = days.fold<double>(0, (s, d) => s + d.rainMm);

    // "Bukas" o "ngayon" ba ang ulan
    final rainTomorrow = tomorrow != null && (tomorrow.rainMm >= 5 || tomorrow.rainChance >= 60);
    final rainToday = today != null && (today.rainMm >= 5 || today.rainChance >= 60);
    final rainSoon = rainTomorrow || rainToday;
    final rainWhenTl = rainToday ? 'ngayong araw' : 'bukas';
    final rainWhenEn = rainToday ? 'today' : 'tomorrow';

    final fertStage = stage == CropStage.vegetative || stage == CropStage.reproductive;

    if (fertStage && rainSoon) {
      out.add(AgriAdvice(
        level: AdviceLevel.warn,
        icon: Icons.grass_rounded,
        titleTl: 'Huwag munang mag-abono ngayon',
        titleEn: 'Hold off on fertilizing now',
        bodyTl:
        'Inaasahan ang pag-ulan $rainWhenTl (mga ${rain48.round()} mm sa 2 araw). Kapag naglagay ka ng urea o iba pang abono ngayon, maaari itong maanod ng ulan at masayang. Maghintay ng mga tuyong araw bago mag-abono.',
        bodyEn:
        'Rain is expected $rainWhenEn (about ${rain48.round()} mm in 2 days). Fertilizer such as urea applied now can be washed away and wasted. Wait for dry days before fertilizing.',
      ));
    } else if (fertStage && rain48 < 3) {
      out.add(const AgriAdvice(
        level: AdviceLevel.good,
        icon: Icons.grass_rounded,
        titleTl: 'Magandang araw para mag-abono',
        titleEn: 'A good time to fertilize',
        bodyTl: 'Tuyo ang susunod na 2 araw. Puwedeng ituloy ang pag-aabono ayon sa rekomendasyon ng Tanggapan ng Pambayang Agrikultura o ng soil test mo.',
        bodyEn: 'The next 2 days are dry. You can go ahead with fertilizing as recommended by the Municipal Agriculture Office or your soil test.',
      ));
    }

    if (rain48 >= 40) {
      out.add(AgriAdvice(
        level: AdviceLevel.warn,
        icon: Icons.water_rounded,
        titleTl: 'Linisin ang kanal at suriin ang pilapil',
        titleEn: 'Clear canals and check the dikes',
        bodyTl: 'Mga ${rain48.round()} mm ng ulan sa susunod na 2 araw. Linisin ang kanal at tingnan ang pilapil para hindi umapaw o mabaha ang $cropTl.',
        bodyEn: 'About ${rain48.round()} mm of rain in the next 2 days. Clear the canals and check the dikes so your $cropEn does not overflow or flood.',
      ));
    }

    if (today != null && (today.heatPeak?.celsius ?? today.tempMax) >= 42) {
      out.add(const AgriAdvice(
        level: AdviceLevel.warn,
        icon: Icons.local_fire_department_rounded,
        titleTl: 'Iwasan ang trabaho sa tanghali',
        titleEn: 'Avoid midday field work',
        bodyTl: 'Napakataas ng heat index ngayon. Magtrabaho sa maagang umaga o hapon, magpahinga sa lilim at uminom ng maraming tubig.',
        bodyEn: 'The heat index is very high today. Work in the early morning or late afternoon, rest in the shade and drink plenty of water.',
      ));
    }

    final soilValue = soil?.value;
    if (rain7 < 10 && soilValue != null && soilValue < 0.30) {
      out.add(AgriAdvice(
        level: AdviceLevel.tip,
        icon: Icons.opacity_rounded,
        titleTl: 'Tuyo ang lupa, kailangan ng tubig',
        titleEn: 'Dry soil, water is needed',
        bodyTl: isRice
            ? 'Kakaunti ang ulan sa susunod na 7 araw at tuyo ang lupa. Panatilihin ang sapat na tubig sa palayan, lalo na sa pamumulaklak.'
            : 'Kakaunti ang ulan sa susunod na 7 araw at tuyo ang lupa. Diligan ang mga tanim sa maagang umaga o hapon.',
        bodyEn: isRice
            ? 'Little rain is expected in the next 7 days and the soil is dry. Keep enough water in the field, especially during flowering.'
            : 'Little rain is expected in the next 7 days and the soil is dry. Water your plants in the early morning or late afternoon.',
      ));
    }

    if ((stage == CropStage.ripening || stage == CropStage.harvestReady) && rainSoon) {
      out.add(const AgriAdvice(
        level: AdviceLevel.tip,
        icon: Icons.agriculture_rounded,
        titleTl: 'Planuhin ang pag-aani at pagpapatuyo',
        titleEn: 'Plan the harvest and drying',
        bodyTl: 'Malapit na ang anihan at may ulan sa susunod na araw. Ihanda ang lugar at tarpaulin sa pagpapatuyo at ayusin ang oras ng pag-aani.',
        bodyEn: 'Harvest is near and rain is expected soon. Prepare a drying area and tarpaulin, and plan the harvest time.',
      ));
    }

    if (fertStage && w.current.humidity >= 85 && w.current.temp <= 32) {
      out.add(const AgriAdvice(
        level: AdviceLevel.tip,
        icon: Icons.biotech_rounded,
        titleTl: 'Bantayan ang sakit ng tanim',
        titleEn: 'Watch for plant disease',
        bodyTl: 'Mahalumigmig ang panahon kaya mas madaling kumalat ang sakit (hal. blast sa palay). Suriin ang mga dahon at lumapit sa MAO kung may kakaibang batik.',
        bodyEn: 'Humid weather makes disease (e.g. rice blast) spread more easily. Check the leaves and ask the MAO if you see unusual spots.',
      ));
    }

    if ((stage == CropStage.reproductive || stage == CropStage.ripening) && w.current.windKmh >= 40) {
      out.add(const AgriAdvice(
        level: AdviceLevel.warn,
        icon: Icons.air_rounded,
        titleTl: 'Baka mahiga ang tanim sa hangin',
        titleEn: 'Plants may lodge in the wind',
        bodyTl: 'Malakas ang hangin at namumunga na ang tanim. Alisin ang labis na tubig kung kailangan at ihanda ang maagang pag-aani kung malapit na.',
        bodyEn: 'The wind is strong and the crop is heading or ripening. Drain excess water if needed and consider an early harvest if it is close.',
      ));
    }

    if (out.isEmpty) {
      out.add(const AgriAdvice(
        level: AdviceLevel.good,
        icon: Icons.wb_sunny_rounded,
        titleTl: 'Normal ang panahon',
        titleEn: 'Normal weather',
        bodyTl: 'Walang espesyal na babala. Ituloy ang karaniwang gawain sa bukid.',
        bodyEn: 'No special warnings. Continue your regular farm work.',
      ));
    }

    out.sort((a, b) => a.level.index.compareTo(b.level.index));
    return out;
  }
}