import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/farm_planting.dart';
import '../models/harvest_record.dart';
import '../services/dss_service.dart';

/// Hawak ang mga inilagay ng magsasaka: mga tanim at lokasyon ng bukid.
/// Nase-save sa telepono (shared_preferences) kaya nandoon pa rin pagbukas ulit ng app.
class FarmInputProvider extends ChangeNotifier {
  static const _key = 'pagri_farm_input_v1';

  List<FarmPlanting> plantings = [];

  /// Kasaysayan ng mga naaning tanim (talaan ng ani).
  List<HarvestRecord> history = [];
  String? selectedId;
  /// Kabuuang sukat ng lupa (sa HEKTARYA) na inilagay ng magsasaka. Null = hindi pa nalalagay.
  double? totalHectares;

  /// Ipakita ang sukat sa metro kuwadrado (m²) sa halip na hektarya. Hektarya pa rin ang tunay na laman.
  bool useSqm = false;

  double lat = AppConstants.defaultLat;
  double lon = AppConstants.defaultLon;
  bool loaded = false;

  FarmPlanting? get selected {
    if (plantings.isEmpty) return null;
    for (final p in plantings) {
      if (p.id == selectedId) return p;
    }
    return plantings.first;
  }

  /// Kabuuang sukat na nahati na sa mga pananim.
  double get usedHectares => plantings.fold<double>(0, (s, e) => s + e.hectares);

  /// Kabuuang sukat ng lupa para sa buong app: ang inilagay ng farmer, o ang kabuuan ng mga tanim kung wala pa.
  double get landTotal {
    final t = totalHectares;
    if (t == null) return usedHectares;
    return t < usedHectares ? usedHectares : t;
  }

  /// Natitirang lupa na hindi pa natataniman. Null kung walang kabuuang sukat.
  double? remainingHectares({String? excludeId}) {
    final t = totalHectares;
    if (t == null) return null;
    final others = plantings.where((e) => e.id != excludeId).fold<double>(0, (s, e) => s + e.hectares);
    final r = t - others;
    return r < 0 ? 0 : r;
  }

  /// Mga natatanging pananim na inilagay ng magsasaka.
  List<String> get cropIds => plantings.map((e) => e.crop).toSet().toList();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        plantings = [
          for (final e in (m['plantings'] as List? ?? const [])) FarmPlanting.fromJson(e as Map<String, dynamic>),
        ];
        history = [
          for (final e in (m['history'] as List? ?? const [])) HarvestRecord.fromJson(e as Map<String, dynamic>),
        ];
        selectedId = m['selectedId'] as String?;
        totalHectares = (m['totalHa'] as num?)?.toDouble();
        useSqm = m['useSqm'] as bool? ?? false;
        lat = (m['lat'] as num?)?.toDouble() ?? lat;
        lon = (m['lon'] as num?)?.toDouble() ?? lon;
      }
    } catch (_) {
      // Kung hindi mabasa, magsimula na lang sa wala.
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'plantings': plantings.map((e) => e.toJson()).toList(),
          'history': history.map((e) => e.toJson()).toList(),
          'selectedId': selectedId,
          'totalHa': totalHectares,
          'useSqm': useSqm,
          'lat': lat,
          'lon': lon,
        }),
      );
    } catch (_) {}
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void add(FarmPlanting p) {
    plantings = [...plantings, p];
    selectedId = p.id;
    _changed();
  }

  void update(FarmPlanting p) {
    plantings = [for (final e in plantings) e.id == p.id ? p : e];
    _changed();
  }

  void remove(String id) {
    plantings = plantings.where((e) => e.id != id).toList();
    if (selectedId == id) selectedId = plantings.isEmpty ? null : plantings.first.id;
    _changed();
  }

  /// Karaniwang ani kada ektarya ng farmer para sa pananim na ito, mula sa sarili niyang mga ani. Null kung wala pa.
  double? historyKgPerHa(String crop) {
    final list = history.where((e) => e.crop == crop && e.kgPerHa > 0).toList();
    if (list.isEmpty) return null;
    return list.fold<double>(0, (s, e) => s + e.kgPerHa) / list.length;
  }

  /// Tantiyang ani at kita ng isang tanim, gamit ang sariling talaan ng farmer kung mayroon.
  HarvestEstimate? estimateFor(FarmPlanting p) => DssService.estimate(p, historyKgPerHa: historyKgPerHa(p.crop));

  /// Pinakabagong naitalang ani (kg) para sa pananim, o null.
  double? lastRecordedYieldKg(String crop) {
    HarvestRecord? best;
    for (final r in history) {
      if (r.crop != crop) continue;
      if (best == null || r.harvestedOn.isAfter(best.harvestedOn)) best = r;
    }
    return best?.yieldKg;
  }

  double get totalIncome => history.fold<double>(0, (s, e) => s + e.income);
  double get totalYieldKg => history.fold<double>(0, (s, e) => s + e.yieldKg);

  /// Kabuuang tubo ng mga ani na may nailagay na gastos.
  double get totalProfit => history.fold<double>(0, (s, e) => s + (e.profit ?? 0));
  bool get hasProfitRecords => history.any((e) => e.profit != null);

  /// Itala ang ani: aalisin ang tanim sa aktibo (babalik sa natitirang lupa ang sukat nito) at ilalagay sa kasaysayan.
  void recordHarvest(String plantingId, HarvestRecord r) {
    plantings = plantings.where((e) => e.id != plantingId).toList();
    if (selectedId == plantingId) selectedId = plantings.isEmpty ? null : plantings.first.id;
    history = [r, ...history];
    _changed();
  }

  void removeRecord(String id) {
    history = history.where((e) => e.id != id).toList();
    _changed();
  }

  void setTotal(double? ha) {
    totalHectares = ha;
    _changed();
  }

  void setUseSqm(bool v) {
    if (useSqm == v) return;
    useSqm = v;
    _changed();
  }

  void select(String id) {
    selectedId = id;
    _changed();
  }

  void setLocation(double newLat, double newLon) {
    lat = newLat;
    lon = newLon;
    _changed();
  }

  void resetLocation() => setLocation(AppConstants.defaultLat, AppConstants.defaultLon);
}