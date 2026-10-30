import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Mga payo na nakabase sa mismong pananim ng farmer (galing sa DSS) at sa panahon.
enum CropAdviceType { harvestReady, harvestSoon, drainage, heatWater, windSupport, dryDays }

class CropAdvice {
  final CropAdviceType type;
  final String crop; // ID ng pananim, hal. 'Rice'
  final IconData icon;
  final Color color;

  /// Araw (para sa harvestSoon: ilang araw na lang).
  final int days;

  const CropAdvice({
    required this.type,
    required this.crop,
    required this.icon,
    required this.color,
    this.days = 0,
  });
}

/// Teksto ng payo (galing sa ARB). [cropName] ay naisalin nang pangalan ng pananim.
extension CropAdviceL10n on AppLocalizations {
  String cropAdviceTitle(CropAdvice a, String cropName) {
    switch (a.type) {
      case CropAdviceType.harvestReady:
        return cropAdvHarvestReadyTitle(cropName);
      case CropAdviceType.harvestSoon:
        return cropAdvHarvestSoonTitle(cropName);
      case CropAdviceType.drainage:
        return cropAdvDrainageTitle(cropName);
      case CropAdviceType.heatWater:
        return cropAdvHeatTitle(cropName);
      case CropAdviceType.windSupport:
        return cropAdvWindTitle(cropName);
      case CropAdviceType.dryDays:
        return cropAdvDryTitle(cropName);
    }
  }

  String cropAdviceMessage(CropAdvice a, String cropName) {
    switch (a.type) {
      case CropAdviceType.harvestReady:
        return cropAdvHarvestReadyMsg(cropName);
      case CropAdviceType.harvestSoon:
        return cropAdvHarvestSoonMsg(cropName, a.days);
      case CropAdviceType.drainage:
        return cropAdvDrainageMsg(cropName);
      case CropAdviceType.heatWater:
        return cropAdvHeatMsg(cropName);
      case CropAdviceType.windSupport:
        return cropAdvWindMsg(cropName);
      case CropAdviceType.dryDays:
        return cropAdvDryMsg(cropName);
    }
  }
}