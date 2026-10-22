import 'package:flutter/material.dart';

import '../core/crop_data.dart';
import '../core/heat_index.dart';
import '../models/app_notification.dart';
import '../models/farm_planting.dart';
import '../models/planting_guide.dart';
import '../models/price_insight.dart';
import '../models/weather_models.dart';

/// Gumagawa ng mga abiso mula sa tunay na datos: panahon, mga tanim ng farmer, at presyo.
/// Walang gawa-gawang balita. Ang mga anunsyo ng LGU/admin ay idadagdag kapag may API na.
class NotificationService {
  List<AppNotification> build({
    required WeatherBundle weather,
    required List<FarmPlanting> plantings,
    required List<PlantingGuide> guides,
    required List<PriceInsight> insights,
  }) {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6);
    final out = <AppNotification>[];

    // Panahon
    if (weather.current.code >= 95) {
      out.add(AppNotification(type: NotificationType.stormAlert, icon: Icons.thunderstorm_rounded, time: now));
    }
    final rain3 = weather.daily.take(3).fold<double>(0, (s, d) => s + d.rainMm);
    if (rain3 >= 30) {
      out.add(AppNotification(
        type: NotificationType.rainAlert,
        icon: Icons.umbrella_rounded,
        time: now,
        value: rain3.round(),
      ));
    }
    final peak = weather.daily.isEmpty ? null : weather.daily.first.heatPeak;
    if (peak != null && peak.level.index >= HeatLevel.danger.index) {
      out.add(AppNotification(
        type: NotificationType.heatAlert,
        icon: Icons.device_thermostat_rounded,
        time: now,
        value: peak.celsius.round(),
      ));
    }

    // Ani
    final seen = <String>{};
    for (final pl in plantings) {
      final facts = factsFor(pl.crop);
      if (facts == null || !facts.hasHarvestDays) continue;
      final days = now.difference(pl.plantedOn).inDays;
      if (days < 0) continue;
      if (days >= facts.minDays!) {
        if (seen.add('ready-${pl.crop}')) {
          out.add(AppNotification(
            type: NotificationType.harvestReady,
            icon: Icons.agriculture_rounded,
            time: morning,
            crop: pl.crop,
          ));
        }
      } else if (facts.minDays! - days <= 14 && seen.add('soon-${pl.crop}')) {
        out.add(AppNotification(
          type: NotificationType.harvestSoon,
          icon: Icons.event_available_rounded,
          time: morning,
          crop: pl.crop,
          value: facts.minDays! - days,
        ));
      }
    }

    // Presyo (pinakamalaking pagbabago muna, hanggang 3)
    final moving = insights.where((i) => i.changePercent.abs() >= 3).toList()
      ..sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
    for (final i in moving.take(3)) {
      final up = i.changePercent > 0;
      out.add(AppNotification(
        type: up ? NotificationType.marketUp : NotificationType.marketDown,
        icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        time: morning,
        crop: i.crop,
        value: i.changePercent.abs().round(),
      ));
    }

    // Magandang buwan ng pagtatanim para sa mga pananim ng farmer
    final crops = plantings.map((e) => e.crop).toSet();
    for (final g in guides) {
      if (crops.contains(g.crop) && g.statusFor(now.month) == PlantStatus.best) {
        out.add(AppNotification(
          type: NotificationType.plantingNow,
          icon: Icons.calendar_month_rounded,
          time: morning,
          crop: g.crop,
        ));
      }
    }
    return out;
  }
}