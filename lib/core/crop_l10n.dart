import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/planting_guide.dart';

extension CropL10n on AppLocalizations {
  String cropLabel(String id) {
    switch (id) {
      case 'Banana':
        return cropBanana;
      case 'Rice':
        return cropRice;
      case 'Coconut':
        return cropCoconut;
      case 'Eggplant':
        return cropEggplant;
      case 'Ampalaya':
        return cropAmpalaya;
      case 'String beans':
        return cropStringBeans;
      case 'Squash':
        return cropSquash;
      case 'Tomato':
        return cropTomato;
      case 'Sweet potato':
        return cropSweetPotato;
      case 'Taro':
        return cropTaro;
      case 'Calamansi':
        return cropCalamansi;
      default:
        return id;
    }
  }

  String cropAbout(String id) {
    switch (id) {
      case 'Banana':
        return cropDescBanana;
      case 'Rice':
        return cropDescRice;
      case 'Coconut':
        return cropDescCoconut;
      case 'Eggplant':
        return cropDescEggplant;
      case 'Ampalaya':
        return cropDescAmpalaya;
      case 'String beans':
        return cropDescStringBeans;
      case 'Squash':
        return cropDescSquash;
      case 'Tomato':
        return cropDescTomato;
      case 'Sweet potato':
        return cropDescSweetPotato;
      case 'Taro':
        return cropDescTaro;
      case 'Calamansi':
        return cropDescCalamansi;
      default:
        return '';
    }
  }

  String cropHarvest(String id) {
    switch (id) {
      case 'Banana':
        return guideHarvestBanana;
      case 'Rice':
        return guideHarvestRice;
      case 'Coconut':
        return guideHarvestCoconut;
      case 'Eggplant':
        return guideHarvestEggplant;
      case 'Ampalaya':
        return guideHarvestAmpalaya;
      case 'String beans':
        return guideHarvestStringBeans;
      case 'Squash':
        return guideHarvestSquash;
      case 'Tomato':
        return guideHarvestTomato;
      case 'Sweet potato':
        return guideHarvestSweetPotato;
      case 'Taro':
        return guideHarvestTaro;
      case 'Calamansi':
        return guideHarvestCalamansi;
      default:
        return '';
    }
  }

  String cropTip(String id) {
    switch (id) {
      case 'Banana':
        return guideTipBanana;
      case 'Rice':
        return guideTipRice;
      case 'Coconut':
        return guideTipCoconut;
      case 'Eggplant':
        return guideTipEggplant;
      case 'Ampalaya':
        return guideTipAmpalaya;
      case 'String beans':
        return guideTipStringBeans;
      case 'Squash':
        return guideTipSquash;
      case 'Tomato':
        return guideTipTomato;
      case 'Sweet potato':
        return guideTipSweetPotato;
      case 'Taro':
        return guideTipTaro;
      case 'Calamansi':
        return guideTipCalamansi;
      default:
        return '';
    }
  }

  String plantStatusLabel(PlantStatus s) {
    switch (s) {
      case PlantStatus.best:
        return statusBest;
      case PlantStatus.possible:
        return statusPossible;
      case PlantStatus.avoid:
        return statusAvoid;
    }
  }
}

Color plantStatusColor(PlantStatus s) {
  switch (s) {
    case PlantStatus.best:
      return AppColors.leaf;
    case PlantStatus.possible:
      return const Color(0xFFEF8F00);
    case PlantStatus.avoid:
      return Colors.black45;
  }
}

IconData plantStatusIcon(PlantStatus s) {
  switch (s) {
    case PlantStatus.best:
      return Icons.thumb_up_rounded;
    case PlantStatus.possible:
      return Icons.help_outline_rounded;
    case PlantStatus.avoid:
      return Icons.block_rounded;
  }
}

/// Hal. "Okt–Ene" o "Hun–Hul, Nob–Dis".
String monthRangesLabel(PlantingGuide g, String locale) {
  final f = DateFormat.MMM(locale);
  String name(int m) => f.format(DateTime(2000, m));
  return g
      .bestRanges()
      .map((r) => r.$1 == r.$2 ? name(r.$1) : '${name(r.$1)}–${name(r.$2)}')
      .join(', ');
}