import 'package:flutter/material.dart';

import '../dashboard_data.dart';

enum AlertLevel { info, watch, warning }

class WeatherAlert {
  final AlertLevel level;
  final IconData icon;
  final String titleTl, titleEn, bodyTl, bodyEn;

  /// Pinagmulan ng babala, hal. "Forecast (Open-Meteo)" o "PAGASA, ipinost ng MAO".
  final String source;

  const WeatherAlert({
    required this.level,
    required this.icon,
    required this.titleTl,
    required this.titleEn,
    required this.bodyTl,
    required this.bodyEn,
    required this.source,
  });

  String title(bool tl) => tl ? titleTl : titleEn;
  String body(bool tl) => tl ? bodyTl : bodyEn;
}

/// Mga babalang kusang nabubuo mula sa weather forecast (Open-Meteo).
/// HINDI ito opisyal na babala ng PAGASA. Para sa opisyal na babala, ang admin/MAO ang magpo-post (tingnan sa ibaba).
class WeatherAlertService {
  static const _src = 'Forecast (Open-Meteo)';

  List<WeatherAlert> fromForecast(WeatherBundle w) {
    final out = <WeatherAlert>[];
    final days = w.daily;
    final now = w.current.time;
    final until = now.add(const Duration(hours: 48));

    // Ulan sa susunod na 2 araw
    var rain48 = 0.0;
    for (var i = 0; i < days.length && i < 2; i++) {
      rain48 += days[i].rainMm;
    }
    final stormSoon = w.hourlyAll.any((h) => h.time.isAfter(now) && h.time.isBefore(until) && h.code >= 95);

    if (stormSoon) {
      out.add(const WeatherAlert(
        level: AlertLevel.warning,
        icon: Icons.thunderstorm_rounded,
        titleTl: 'Banta ng kulog at kidlat',
        titleEn: 'Thunderstorm risk',
        bodyTl: 'Inaasahan ang kulog at kidlat sa susunod na 48 oras. Umiwas sa bukas na bukirin at isilong ang mga kagamitan at alagang hayop.',
        bodyEn: 'Thunderstorms are expected in the next 48 hours. Stay out of open fields and keep tools and animals under shelter.',
        source: _src,
      ));
    }
    if (rain48 >= 100) {
      out.add(WeatherAlert(
        level: AlertLevel.warning,
        icon: Icons.water_rounded,
        titleTl: 'Napakalakas na pag-ulan',
        titleEn: 'Very heavy rain',
        bodyTl: 'Mga ${rain48.round()} mm ng ulan ang inaasahan sa susunod na 48 oras. Linisin ang mga kanal ng inyong sakahan at ihanda ang pilapil.',
        bodyEn: 'About ${rain48.round()} mm of rain is expected in the next 48 hours. Clear your farm canals and check the dikes.',
        source: _src,
      ));
    } else if (rain48 >= 40) {
      out.add(WeatherAlert(
        level: AlertLevel.watch,
        icon: Icons.umbrella_rounded,
        titleTl: 'Malakas na pag-ulan',
        titleEn: 'Heavy rain',
        bodyTl: 'Mga ${rain48.round()} mm ng ulan ang inaasahan sa susunod na 48 oras. Pinapayuhan ang paglilinis ng mga kanal sa inyong sakahan.',
        bodyEn: 'About ${rain48.round()} mm of rain is expected in the next 48 hours. Please clear the canals on your farm.',
        source: _src,
      ));
    }

    // Init (heat index ayon sa antas ng PAGASA: 42 pataas = Panganib)
    final heatNow = days.isEmpty ? 0.0 : (days.first.heatPeak?.celsius ?? days.first.tempMax);
    if (heatNow >= 42) {
      out.add(WeatherAlert(
        level: AlertLevel.warning,
        icon: Icons.local_fire_department_rounded,
        titleTl: 'Mapanganib na init ngayon',
        titleEn: 'Dangerous heat today',
        bodyTl: 'Aabot sa ${heatNow.round()}°C ang heat index. Iwasan ang trabaho sa bukid sa tanghali, magpahinga sa lilim at uminom ng tubig.',
        bodyEn: 'Heat index may reach ${heatNow.round()}°C. Avoid field work at midday, rest in the shade and drink water.',
        source: _src,
      ));
    }

    // Hangin
    if (w.current.windKmh >= 40) {
      out.add(WeatherAlert(
        level: AlertLevel.watch,
        icon: Icons.air_rounded,
        titleTl: 'Malakas na hangin',
        titleEn: 'Strong wind',
        bodyTl: 'Mga ${w.current.windKmh.round()} km/h ang hangin ngayon. Suhayan o itali ang mga tanim na madaling matumba.',
        bodyEn: 'Wind is about ${w.current.windKmh.round()} km/h. Support or tie plants that can fall over.',
        source: _src,
      ));
    }

    out.sort((a, b) => b.level.index.compareTo(a.level.index));
    return out;
  }
}

/// Advisory na ipinost ng admin/MAO (halimbawa, kopya ng babala ng PAGASA).
/// Walang nakakabit na database sa ngayon, kaya walang lalabas na admin advisory.
/// Kapag handa na ang Supabase, itakda ang `AdvisoryRepository.source` sa isang function na kumukuha ng
/// mga row ng table `advisories` (title, message, source, active, created_at). Hindi na kailangang galawin ang screen.
class AdminAdvisory {
  final String title;
  final String message;
  final String source;
  final DateTime? createdAt;
  const AdminAdvisory({required this.title, required this.message, required this.source, this.createdAt});
}

class AdvisoryRepository {
  /// Ikabit dito ang tagakuha ng datos (hal. Supabase). Default: walang advisory.
  static Future<List<AdminAdvisory>> Function() source = () async => const <AdminAdvisory>[];

  static (DateTime, List<AdminAdvisory>)? _cache;

  Future<List<AdminAdvisory>> fetch() async {
    final c = _cache;
    if (c != null && DateTime.now().difference(c.$1) < const Duration(minutes: 10)) return c.$2;
    try {
      final list = await source().timeout(const Duration(seconds: 10));
      _cache = (DateTime.now(), list);
      return list;
    } catch (_) {
      return const [];
    }
  }
}