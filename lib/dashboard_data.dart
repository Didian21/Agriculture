import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

enum AppLanguage { tagalog, english }

const List<String> monthNamesEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> monthNamesTl = [
  'Enero', 'Pebbrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
  'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre',
];

List<String> getMonthNames(bool isTagalog) => isTagalog ? monthNamesTl : monthNamesEn;

String translateCrop(String crop, bool isTagalog) {
  if (!isTagalog) return crop;
  switch (crop) {
    case 'Rice':
      return 'Palay';
    case 'Eggplant':
      return 'Talong';
    case 'Tomato':
      return 'Kamatis';
    case 'String beans':
      return 'Sitaw';
    case 'Banana':
      return 'Saging';
    default:
      return crop;
  }
}

// ==========================================
// MODELS
// ==========================================

class FarmerProfile {
  final String name;
  final String barangay;
  final double landSizeHectares;
  final List<String> cropTypes;

  const FarmerProfile({
    required this.name,
    required this.barangay,
    required this.landSizeHectares,
    required this.cropTypes,
  });
}

/// One piece of the farmer's land and what is on it.
class FarmPlot {
  final String crop;
  final double hectares;
  final String statusEn;
  final String statusTl;

  const FarmPlot({
    required this.crop,
    required this.hectares,
    required this.statusEn,
    required this.statusTl,
  });

  String status(bool isTagalog) => isTagalog ? statusTl : statusEn;
  String cropName(bool isTagalog) => translateCrop(crop, isTagalog);
}

class CropRecord {
  final String crop;
  final DateTime datePlanted;
  final DateTime? dateHarvested;
  final double yieldKg;

  const CropRecord({
    required this.crop,
    required this.datePlanted,
    this.dateHarvested,
    required this.yieldKg,
  });

  bool get isHarvested => dateHarvested != null;
  String cropName(bool isTagalog) => translateCrop(crop, isTagalog);
}

class WeatherInfo {
  final String labelEn;
  final String labelTl;
  final IconData icon;
  final List<Color> gradient;

  const WeatherInfo(this.labelEn, this.labelTl, this.icon, this.gradient);

  String label(bool isTagalog) => isTagalog ? labelTl : labelEn;
}

WeatherInfo describeWeather(int code, {bool isDay = true}) {
  if (code == 0 || code == 1) {
    return isDay
        ? const WeatherInfo('Sunny', 'Maaraw', Icons.wb_sunny_rounded, [Color(0xFF56CCF2), Color(0xFF2F80ED)])
        : const WeatherInfo('Clear night', 'Maaliwalas', Icons.nights_stay_rounded, [Color(0xFF283E51), Color(0xFF0B1620)]);
  }
  if (code == 2) {
    return const WeatherInfo('Partly cloudy', 'Medyo maulap', Icons.wb_cloudy_rounded, [Color(0xFF6FB1E8), Color(0xFF4A7FBF)]);
  }
  if (code == 3) {
    return const WeatherInfo('Cloudy', 'Maulap', Icons.cloud_rounded, [Color(0xFF8FA6B8), Color(0xFF5C7A99)]);
  }
  if (code == 45 || code == 48) {
    return const WeatherInfo('Foggy', 'Maulap at malabo', Icons.blur_on_rounded, [Color(0xFF9AA9B5), Color(0xFF66798A)]);
  }
  if (code >= 51 && code <= 57) {
    return const WeatherInfo('Light drizzle', 'Ambon', Icons.grain_rounded, [Color(0xFF6C93B5), Color(0xFF3F6486)]);
  }
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
    return const WeatherInfo('Rain', 'Umuulan', Icons.water_drop_rounded, [Color(0xFF5B86A8), Color(0xFF2C4A66)]);
  }
  if (code >= 95) {
    return const WeatherInfo('Thunderstorm', 'Kulog at ulan', Icons.thunderstorm_rounded, [Color(0xFF485563), Color(0xFF29323C)]);
  }
  return const WeatherInfo('Cloudy', 'Maulap', Icons.cloud_rounded, [Color(0xFF8FA6B8), Color(0xFF5C7A99)]);
}

class CurrentWeather {
  final DateTime time;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windKmh;
  final double rainMm;
  final int code;
  final bool isDay;

  const CurrentWeather({
    required this.time,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windKmh,
    required this.rainMm,
    required this.code,
    required this.isDay,
  });

  WeatherInfo get info => describeWeather(code, isDay: isDay);
}

class HourlyWeather {
  final DateTime time;
  final double temp;
  final int rainChance;
  final int code;
  final bool isDay;

  const HourlyWeather({
    required this.time,
    required this.temp,
    required this.rainChance,
    required this.code,
    required this.isDay,
  });
}

class WeatherDay {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double rainMm;
  final int rainChance;
  final int code;

  const WeatherDay({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.rainMm,
    required this.rainChance,
    required this.code,
  });
}

class WeatherBundle {
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<WeatherDay> daily;
  const WeatherBundle(this.current, this.hourly, this.daily);
}

class FarmAdvice {
  final IconData icon;
  final String titleEn;
  final String titleTl;
  final String messageEn;
  final String messageTl;
  final Color color;

  const FarmAdvice({
    required this.icon,
    required this.titleEn,
    required this.titleTl,
    required this.messageEn,
    required this.messageTl,
    required this.color,
  });

  String title(bool isTagalog) => isTagalog ? titleTl : titleEn;
  String message(bool isTagalog) => isTagalog ? messageTl : messageEn;
}

class AppNotification {
  final String id;
  final IconData icon;
  final String titleEn;
  final String titleTl;
  final String messageEn;
  final String messageTl;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.icon,
    required this.titleEn,
    required this.titleTl,
    required this.messageEn,
    required this.messageTl,
    required this.time,
    this.isRead = false,
  });

  String title(bool isTagalog) => isTagalog ? titleTl : titleEn;
  String message(bool isTagalog) => isTagalog ? messageTl : messageEn;
}

class PricePrediction {
  final String crop;
  final double currentPrice;   // PHP per kg
  final double predictedPrice; // PHP per kg
  final String reasonEn;
  final String reasonTl;

  const PricePrediction({
    required this.crop,
    required this.currentPrice,
    required this.predictedPrice,
    required this.reasonEn,
    required this.reasonTl,
  });

  double get changePercent => (predictedPrice - currentPrice) / currentPrice * 100;

  String cropName(bool isTagalog) => translateCrop(crop, isTagalog);

  String reason(bool isTagalog) => isTagalog ? reasonTl : reasonEn;

  String sellTip(bool isTagalog) {
    if (changePercent >= 5) {
      return isTagalog
          ? 'Maaaring tumaas ang presyo - maghintay ng ilang araw bago magbenta.'
          : 'Price may rise - consider waiting a few days to sell.';
    }
    if (changePercent >= 0) {
      return isTagalog
          ? 'Bahagyang pagtaas ang inaasahan - magbenta kapag handa na ang ani.'
          : 'Slight rise expected - sell when your harvest is ready.';
    }
    return isTagalog
        ? 'Maaaring bumaba ang presyo - magbenta agad kung handa na ang ani.'
        : 'Price may dip - sell soon if your crop is ready.';
  }
}

enum PlantStatus { best, possible, avoid }

class PlantingGuide {
  final String cropEn;
  final String cropTl;
  final IconData icon;
  final Set<int> bestMonths;
  final Set<int> possibleMonths;
  final String harvestTimeEn;
  final String harvestTimeTl;
  final String tipEn;
  final String tipTl;

  const PlantingGuide({
    required this.cropEn,
    required this.cropTl,
    required this.icon,
    required this.bestMonths,
    required this.possibleMonths,
    required this.harvestTimeEn,
    required this.harvestTimeTl,
    required this.tipEn,
    required this.tipTl,
  });

  String crop(bool isTagalog) => isTagalog ? cropTl : cropEn;
  String harvestTime(bool isTagalog) => isTagalog ? harvestTimeTl : harvestTimeEn;
  String tip(bool isTagalog) => isTagalog ? tipTl : tipEn;

  PlantStatus statusFor(int month) {
    if (bestMonths.contains(month)) return PlantStatus.best;
    if (possibleMonths.contains(month)) return PlantStatus.possible;
    return PlantStatus.avoid;
  }

  String nextBestMonthName(int month, bool isTagalog) {
    final names = getMonthNames(isTagalog);
    for (var i = 0; i < 12; i++) {
      final m = ((month - 1 + i) % 12) + 1;
      if (bestMonths.contains(m)) return names[m - 1];
    }
    return '-';
  }
}

// ==========================================
// SERVICES & REPOSITORIES
// ==========================================

class FarmerRepository {
  Future<FarmerProfile> getProfile() async => const FarmerProfile(
    name: 'Wency Babaan',
    barangay: 'Barangay Sampaloc',
    landSizeHectares: 2.5,
    cropTypes: ['Rice', 'Eggplant', 'Tomato'],
  );

  Future<List<FarmPlot>> getPlots() async => const [
    FarmPlot(crop: 'Rice', hectares: 1.2, statusEn: 'Harvested', statusTl: 'Naani na'),
    FarmPlot(crop: 'Eggplant', hectares: 0.7, statusEn: 'Harvested', statusTl: 'Naani na'),
    FarmPlot(crop: 'Tomato', hectares: 0.6, statusEn: 'Growing', statusTl: 'Lumalaki'),
  ];

  Future<List<CropRecord>> getCropHistory() async => [
    CropRecord(crop: 'Rice', datePlanted: DateTime(2025, 6, 10), dateHarvested: DateTime(2025, 10, 5), yieldKg: 5200),
    CropRecord(crop: 'Eggplant', datePlanted: DateTime(2025, 11, 2), dateHarvested: DateTime(2026, 1, 20), yieldKg: 1800),
    CropRecord(crop: 'Tomato', datePlanted: DateTime(2026, 8, 15), yieldKg: 0),
  ];

  List<PlantingGuide> getPlantingGuides() => const [
    PlantingGuide(
      cropEn: 'Rice',
      cropTl: 'Palay',
      icon: Icons.grass,
      bestMonths: {6, 7, 11, 12},
      possibleMonths: {5, 8, 1},
      harvestTimeEn: '110-120 days',
      harvestTimeTl: '110-120 araw',
      tipEn: 'Wet season crop starts June-July. Dry season crop starts Nov-Dec and needs steady irrigation.',
      tipTl: 'Ang tanim sa tag-ulan ay Hunyo-Hulyo. Ang tanim sa tag-araw ay Nobyembre-Disyembre at kailangan ng tuloy-tuloy na patubig.',
    ),
    PlantingGuide(
      cropEn: 'Eggplant',
      cropTl: 'Talong',
      icon: Icons.eco,
      bestMonths: {10, 11, 12, 1},
      possibleMonths: {2, 9},
      harvestTimeEn: '90-120 days',
      harvestTimeTl: '90-120 araw',
      tipEn: 'Grows best in the cooler dry months. Avoid transplanting during heavy rain.',
      tipTl: 'Pinakamagandang tumubo sa mas malamig na tuyong buwan. Iwasang maglipat-tanim kapag malakas ang ulan.',
    ),
    PlantingGuide(
      cropEn: 'Tomato',
      cropTl: 'Kamatis',
      icon: Icons.local_florist,
      bestMonths: {10, 11, 12},
      possibleMonths: {1, 2, 9},
      harvestTimeEn: '90-110 days',
      harvestTimeTl: '90-110 araw',
      tipEn: 'Too much rain causes disease and rotting. Plant after the typhoon season for best yield.',
      tipTl: 'Ang sobrang ulan ay nagdudulot ng sakit at pagkalanta. Magtanim pagkatapos ng panahon ng bagyo para sa magandang ani.',
    ),
    PlantingGuide(
      cropEn: 'String beans',
      cropTl: 'Sitaw',
      icon: Icons.spa,
      bestMonths: {10, 11, 12, 1},
      possibleMonths: {2, 4, 5, 9},
      harvestTimeEn: '60-70 days',
      harvestTimeTl: '60-70 araw',
      tipEn: 'Fast crop. Provide trellis or stakes. Needs well-drained soil.',
      tipTl: 'Mabilis maani. Lagyan ng suhay o balag. Kailangan ng lupang mabilis matuyo.',
    ),
    PlantingGuide(
      cropEn: 'Banana',
      cropTl: 'Saging',
      icon: Icons.park,
      bestMonths: {5, 6, 7},
      possibleMonths: {4, 8, 9},
      harvestTimeEn: '9-12 months',
      harvestTimeTl: '9-12 buwan',
      tipEn: 'Plant at the start of the rainy season so suckers root well. Prop plants before typhoons.',
      tipTl: 'Magtanim sa simula ng tag-ulan upang mabilis mag-ugat ang mga suhi. Suhayan ang mga puno bago ang bagyo.',
    ),
  ];
}

class WeatherService {
  Future<WeatherBundle> fetch({
    double lat = AppConstants.defaultLat,
    double lon = AppConstants.defaultLon,
  }) async {
    final uri = Uri.parse(AppConstants.weatherBaseUrl).replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day',
      'hourly': 'temperature_2m,precipitation_probability,weather_code,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
      'timezone': AppConstants.timezone,
      'forecast_days': '7',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Weather service error (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;

    final c = json['current'] as Map<String, dynamic>;
    final now = DateTime.parse(c['time'] as String);
    final current = CurrentWeather(
      time: now,
      temp: (c['temperature_2m'] as num).toDouble(),
      feelsLike: (c['apparent_temperature'] as num).toDouble(),
      humidity: (c['relative_humidity_2m'] as num).round(),
      windKmh: (c['wind_speed_10m'] as num).toDouble(),
      rainMm: (c['precipitation'] as num).toDouble(),
      code: (c['weather_code'] as num).toInt(),
      isDay: (c['is_day'] as num) == 1,
    );

    final h = json['hourly'] as Map<String, dynamic>;
    final hTimes = List<String>.from(h['time']);
    final startOfHour = DateTime(now.year, now.month, now.day, now.hour);
    final hourly = <HourlyWeather>[];
    for (var i = 0; i < hTimes.length && hourly.length < 12; i++) {
      final t = DateTime.parse(hTimes[i]);
      if (t.isBefore(startOfHour)) continue;
      hourly.add(HourlyWeather(
        time: t,
        temp: (h['temperature_2m'][i] as num).toDouble(),
        rainChance: ((h['precipitation_probability'][i] as num?) ?? 0).round(),
        code: (h['weather_code'][i] as num).toInt(),
        isDay: (h['is_day'][i] as num) == 1,
      ));
    }

    final d = json['daily'] as Map<String, dynamic>;
    final dates = List<String>.from(d['time']);
    final daily = List.generate(
      dates.length,
          (i) => WeatherDay(
        date: DateTime.parse(dates[i]),
        tempMax: (d['temperature_2m_max'][i] as num).toDouble(),
        tempMin: (d['temperature_2m_min'][i] as num).toDouble(),
        rainMm: ((d['precipitation_sum'][i] as num?) ?? 0).toDouble(),
        rainChance: ((d['precipitation_probability_max'][i] as num?) ?? 0).round(),
        code: (d['weather_code'][i] as num).toInt(),
      ),
    );

    return WeatherBundle(current, hourly, daily);
  }
}

class AdviceService {
  List<FarmAdvice> build(WeatherBundle w) {
    final out = <FarmAdvice>[];
    final today = w.daily.first;
    final next3 = w.daily.take(3).toList();
    final next3Rain = next3.fold<double>(0, (s, d) => s + d.rainMm);

    if (w.current.code >= 95) {
      out.add(const FarmAdvice(
        icon: Icons.warning_amber_rounded,
        titleEn: 'Thunderstorm risk',
        titleTl: 'Banta ng kulog at kidlat',
        messageEn: 'Stay out of open fields and keep tools and animals under shelter.',
        messageTl: 'Umiwas sa bukas na bukirin at isilong ang mga kagamitan at alagang hayop.',
        color: Color(0xFFD84315),
      ));
    }
    if (today.rainChance >= 60 || today.rainMm >= 5) {
      out.add(const FarmAdvice(
        icon: Icons.umbrella_rounded,
        titleEn: 'Rain is likely today',
        titleTl: 'Inaasahan ang ulan ngayong araw',
        messageEn: 'Do not spray or fertilize today - rain will wash it away. Check that your canals drain well.',
        messageTl: 'Huwag muna mag-spray o mag-abono ngayong araw dahil maaagos ng ulan. Tiyaking maayos ang daloy ng kanal.',
        color: AppColors.rain,
      ));
    }
    if (today.tempMax >= 34) {
      out.add(const FarmAdvice(
        icon: Icons.thermostat_rounded,
        titleEn: 'Very hot today',
        titleTl: 'Napakainit ngayong araw',
        messageEn: 'Water early morning or late afternoon. Shade young seedlings during midday.',
        messageTl: 'Magdilig sa maagang umaga o hapon. Lilungan ang mga batang tanim sa tanghaling tapat.',
        color: Color(0xFFEF6C00),
      ));
    }
    if (w.current.windKmh >= 30) {
      out.add(const FarmAdvice(
        icon: Icons.air_rounded,
        titleEn: 'Strong wind',
        titleTl: 'Malakas na hangin',
        messageEn: 'Secure banana plants with props and tie up tomato and bean stakes.',
        messageTl: 'Suhayan ang mga saging at itali ang mga pasan ng kamatis at sitaw.',
        color: Color(0xFF546E7A),
      ));
    }
    if (next3Rain < 3 && today.rainChance < 40) {
      out.add(const FarmAdvice(
        icon: Icons.agriculture_rounded,
        titleEn: 'Good days for field work',
        titleTl: 'Magandang panahon sa bukid',
        messageEn: 'Dry days ahead - good for harvesting, drying palay, spraying and fertilizing.',
        messageTl: 'Tuyo ang mga darating na araw - maganda para sa pag-aani, pagpapatuyo ng palay, pag-i-spray, at pag-aabono.',
        color: AppColors.fern,
      ));
    }
    if (out.isEmpty) {
      out.add(const FarmAdvice(
        icon: Icons.check_circle_rounded,
        titleEn: 'Normal weather',
        titleTl: 'Normal na panahon',
        messageEn: 'No special warnings. Continue your regular farm work.',
        messageTl: 'Walang espesyal na babala. Magpatuloy sa karaniwang gawain sa bukid.',
        color: AppColors.fern,
      ));
    }
    return out;
  }
}

class PricePredictionService {
  static const Map<String, double> _currentPrices = {
    'Rice': 46.0,
    'Eggplant': 60.0,
    'Tomato': 55.0,
    'String beans': 70.0,
    'Banana': 40.0,
  };

  List<PricePrediction> predict(List<String> crops, List<WeatherDay> forecast) {
    final avgRain = forecast.isEmpty
        ? 0.0
        : forecast.map((d) => d.rainMm).reduce((a, b) => a + b) / forecast.length;

    return crops.where(_currentPrices.containsKey).map((crop) {
      final now = _currentPrices[crop]!;
      double factor;
      String reasonEn;
      String reasonTl;
      if (avgRain > 10) {
        factor = 1.08;
        reasonEn = 'Heavy rain expected; supply may drop.';
        reasonTl = 'Inaasahan ang malakas na ulan; maaaring bumaba ang supply.';
      } else if (avgRain < 2) {
        factor = 1.03;
        reasonEn = 'Dry spell expected; mild supply pressure.';
        reasonTl = 'Inaasahan ang panahon ng tagtuyot; may kaunting epekto sa supply.';
      } else {
        factor = 0.98;
        reasonEn = 'Stable weather; supply steady.';
        reasonTl = 'Maayos ang panahon; steady ang supply.';
      }
      return PricePrediction(
        crop: crop,
        currentPrice: now,
        predictedPrice: double.parse((now * factor).toStringAsFixed(2)),
        reasonEn: reasonEn,
        reasonTl: reasonTl,
      );
    }).toList();
  }
}

// ==========================================
// STATE PROVIDER
// ==========================================

class DashboardProvider extends ChangeNotifier {
  final _repo = FarmerRepository();
  final _weather = WeatherService();
  final _advice = AdviceService();
  final _pricing = PricePredictionService();

  Timer? _timer;

  // Language State
  AppLanguage currentLanguage = AppLanguage.tagalog; // Default to Tagalog

  bool get isTagalog => currentLanguage == AppLanguage.tagalog;

  void setLanguage(AppLanguage lang) {
    if (currentLanguage != lang) {
      currentLanguage = lang;
      notifyListeners();
    }
  }

  // Auth & Session State
  bool isLoggedIn = true;

  // Notification Settings State
  bool notifyWeatherAlerts = true;
  bool notifyPriceAlerts = true;
  bool notifyPlantingReminders = true;
  bool notifyDailyAdvisory = true;

  // Account Metadata
  String phoneNumber = '+63 912 345 6789';

  // Notifications List State
  List<AppNotification> notifications = [];

  int get unreadNotificationCount => notifications.where((n) => !n.isRead).length;

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markNotificationRead(String id) {
    for (final n in notifications) {
      if (n.id == id) {
        n.isRead = true;
        break;
      }
    }
    notifyListeners();
  }

  // Data State
  FarmerProfile? profile;
  List<FarmPlot> plots = [];
  List<CropRecord> history = [];
  List<PlantingGuide> guides = [];
  WeatherBundle? weather;
  List<FarmAdvice> advice = [];
  List<PricePrediction> predictions = [];
  DateTime? lastUpdated;
  bool isLoading = true;
  bool weatherStale = false;
  String? error;

  List<WeatherDay> get forecast => weather?.daily ?? [];

  void setNotifyWeather(bool val) {
    notifyWeatherAlerts = val;
    notifyListeners();
  }

  void setNotifyPrice(bool val) {
    notifyPriceAlerts = val;
    notifyListeners();
  }

  void setNotifyPlanting(bool val) {
    notifyPlantingReminders = val;
    notifyListeners();
  }

  void setNotifyDailyAdvisory(bool val) {
    notifyDailyAdvisory = val;
    notifyListeners();
  }

  void updateAccount({required String name, required String barangay, required double landSize}) {
    if (profile != null) {
      profile = FarmerProfile(
        name: name,
        barangay: barangay,
        landSizeHectares: landSize,
        cropTypes: profile!.cropTypes,
      );
      notifyListeners();
    }
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  void login() {
    isLoggedIn = true;
    notifyListeners();
  }

  void start() {
    load();
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => load(silent: true));
  }

  Future<void> load({bool silent = false}) async {
    if (!silent && weather == null) {
      isLoading = true;
      notifyListeners();
    }
    error = null;
    try {
      profile ??= await _repo.getProfile();
      plots = await _repo.getPlots();
      history = await _repo.getCropHistory();
      guides = _repo.getPlantingGuides();
      weather = await _weather.fetch();
      advice = _advice.build(weather!);
      predictions = _pricing.predict(profile!.cropTypes, weather!.daily);

      // Build live notifications for the farmer
      notifications = [
        AppNotification(
          id: '1',
          icon: Icons.thunderstorm_rounded,
          titleEn: 'Weather Alert for Pagsanjan',
          titleTl: 'Babala sa Panahon sa Pagsanjan',
          messageEn: 'Heavy rain expected in the coming days. Ensure proper canal drainage for your crops.',
          messageTl: 'Inaasahan ang malakas na ulan sa mga darating na araw. Tiyaking maayos ang daloy ng kanal sa bukid.',
          time: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        AppNotification(
          id: '2',
          icon: Icons.trending_up_rounded,
          titleEn: 'Market Price Update',
          titleTl: 'Balita sa Presyo ng Pananim',
          messageEn: 'Tomato and Eggplant market prices show a potential 8% increase based on rain forecasts.',
          messageTl: 'Inaasahang tataas ng 8% ang presyo ng Kamatis at Talong sa pamilihan batay sa ulan.',
          time: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: '3',
          icon: Icons.calendar_month_rounded,
          titleEn: 'Planting Season Window',
          titleTl: 'Takdang Panahon ng Pagtatanim',
          messageEn: 'Optimal planting window for Rice (Palay) is open this month in Laguna.',
          messageTl: 'Pinakamagandang panahon ngayon upang magtanim ng Palay sa Laguna.',
          time: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        AppNotification(
          id: '4',
          icon: Icons.pest_control_rounded,
          titleEn: 'Pest Alert: Rice Stem Borer',
          titleTl: 'Bantay Peste: Rice Stem Borer sa Laguna',
          messageEn: 'Farmers in surrounding barangays reported minor stem borer activity. Monitor your paddies.',
          messageTl: 'May naiulat na paglitaw ng stem borer sa mga kalapit na barangay. Regular na suriin ang inyong palayan.',
          time: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AppNotification(
          id: '5',
          icon: Icons.card_giftcard_rounded,
          titleEn: 'Municipal Agri Subsidy',
          titleTl: 'Ayuda sa Abono mula sa LGU Pagsanjan',
          messageEn: 'Organic fertilizer distribution is ongoing at the Municipal Agriculture Office.',
          messageTl: 'Kasalukuyang ipinamamahagi ang libreng organikong abono sa Tanggapan ng Pambayang Agrikultura.',
          time: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      lastUpdated = DateTime.now();
      weatherStale = false;
    } catch (e) {
      if (weather == null) {
        error = isTagalog
            ? 'Hindi maikonekta. Tiyaking may internet connection at subukang muli.'
            : 'Could not load data. Check your internet connection and try again.';
      } else {
        weatherStale = true;
      }
    }
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
