import 'dart:async';

import 'package:flutter/material.dart';

import '../core/crop_data.dart';
import '../core/localization.dart';
import '../models/app_notification.dart';
import '../models/farm_advice.dart';
import '../models/farm_models.dart';
import '../models/farm_planting.dart';
import '../models/planting_guide.dart';
import '../models/price_prediction.dart';
import '../models/weather_models.dart';
import '../services/advice_service.dart';
import '../services/farmer_repository.dart';
import '../services/notification_service.dart';
import '../services/price_insight_service.dart';
import '../services/price_prediction_service.dart';
import '../services/weather_service.dart';

class DashboardProvider extends ChangeNotifier {
  final _repo = FarmerRepository();
  final _weather = WeatherService();
  final _advice = AdviceService();
  final _pricing = PricePredictionService();
  final _notifService = NotificationService();

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

  // Display State - laki ng teksto (1.0 = normal)
  double textScale = 1.0;

  void setTextScale(double v) {
    if (textScale != v) {
      textScale = v;
      notifyListeners();
    }
  }

  bool isLoggedIn = true;
  String currentUsername = '';

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  void login({String? username, String? phone}) {
    isLoggedIn = true;
    if (username != null && username.isNotEmpty) {
      currentUsername = username;
    }
    if (phone != null && phone.isNotEmpty) {
      phoneNumber = phone;
    }
    load();
    notifyListeners();
  }

  // Account Metadata (view only - galing sa admin)
  String phoneNumber = '+63 912 345 6789';
  String birthday = '08/11/2001';

  void updateProfileDetails({
    required String name,
    required String barangay,
    required String phone,
    required String birthday,
    required double landSize,
  }) {
    profile = FarmerProfile(
      name: name,
      barangay: barangay,
      landSizeHectares: landSize,
      cropTypes: profile?.cropTypes ?? ['Rice', 'Eggplant', 'Tomato'],
    );
    phoneNumber = phone;
    this.birthday = birthday;
    notifyListeners();
  }

  // Notifications List State
  List<AppNotification> notifications = [];

  int get unreadNotificationCount => notifications.where((n) => !n.isRead).length;

  // Naaalala kung alin ang nabasa na, kahit gumawa ulit ng bagong listahan ang app.
  final Set<String> _readIds = {};

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.isRead = true;
      _readIds.add(n.id);
    }
    notifyListeners();
  }

  void markNotificationRead(String id) {
    for (final n in notifications) {
      if (n.id == id) {
        n.isRead = true;
        _readIds.add(id);
        break;
      }
    }
    notifyListeners();
  }

  // Data State
  /// Profile ng farmer: galing sa admin (view only). Palitan ang _repo.getProfile() ng API ng admin.
  FarmerProfile? profile;

  /// Wala nang sample na plots/history: ang mga tanim ay inilalagay ng farmer sa DSS
  /// (tingnan ang FarmInputProvider). Iniwan lang na walang laman para hindi masira ang ibang file.
  List<FarmPlot> plots = [];
  List<CropRecord> history = [];

  /// Mga tanim na inilagay ng farmer sa DSS. Ina-update ng syncPlantings().
  List<FarmPlanting> farmPlantings = [];

  /// Mga natatanging pananim ng farmer (ID, hal. 'Rice').
  List<String> get farmCrops => farmPlantings.map((e) => e.crop).toSet().toList();
  List<PlantingGuide> guides = [];
  WeatherBundle? weather;
  List<FarmAdvice> advice = [];
  List<PricePrediction> predictions = [];
  DateTime? lastUpdated;
  bool isLoading = true;
  bool weatherStale = false;
  bool hasError = false; // ang teksto ng error ay nasa ARB (errorLoad)

  List<WeatherDay> get forecast => weather?.daily ?? [];

  /// Tinatawag kapag nagbago ang mga tanim sa DSS, para sumunod ang presyo, payo at mga abiso.
  void syncPlantings(List<FarmPlanting> list) {
    final a = farmPlantings.map((e) => '${e.id}|${e.crop}|${e.plantedOn}|${e.hectares}|${e.lastYieldKg}').join(';');
    final b = list.map((e) => '${e.id}|${e.crop}|${e.plantedOn}|${e.hectares}|${e.lastYieldKg}').join(';');
    if (a == b) return;
    farmPlantings = List.of(list);
    _rebuildDerived();
    notifyListeners();
  }

  /// Mga datos na nakadepende sa panahon at sa mga tanim ng farmer.
  void _rebuildDerived() {
    final w = weather;
    if (w == null) return;
    predictions = _pricing.predict(farmCrops, w.daily);
    final insights = PriceInsightService().build(crops: farmCrops, days: w.daily, guides: guides);
    notifications = _notifService.build(weather: w, plantings: farmPlantings, guides: guides, insights: insights);
    for (final n in notifications) {
      n.isRead = _readIds.contains(n.id);
    }
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
    hasError = false;
    try {
      profile ??= await _repo.getProfile(username: currentUsername);
      guides = _repo.getPlantingGuides();
      // Isang kalendaryo para sa buong app (DSS, My Farm, abiso, presyo).
      for (final g in guides) {
        setCropCalendar(g.crop, g.bestMonths, g.possibleMonths);
      }
      weather = await _weather.fetch();
      advice = _advice.build(weather!);
      _rebuildDerived();

      lastUpdated = DateTime.now();
      weatherStale = false;
    } catch (e, st) {
      // Ipinapakita ang tunay na dahilan sa Run/Debug console (para madaling hanapin ang problema).
      debugPrint('PAGRI load error: $e\n$st');
      if (weather == null) {
        hasError = true;
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