import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/farm_planting.dart';
import '../models/harvest_record.dart';
import '../services/dss_service.dart';
import '../services/supabase_service.dart';

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
  String farmerName = 'Magsasaka ng Pagsanjan';
  String? farmerId;
  String barangay = 'Biñan';
  String locationName = 'Barangay Biñan';

  void setFarmerInfo({String? id, String? name, String? brgy, String? location}) {
    bool nameChanged = false;
    if (id != null && id.isNotEmpty && farmerId != id) {
      farmerId = id;
      nameChanged = true;
    }
    if (name != null && name.isNotEmpty && farmerName != name) {
      farmerName = name;
      nameChanged = true;
    }
    if (brgy != null && brgy.isNotEmpty && barangay != brgy) {
      barangay = brgy;
    }
    if (location != null && location.isNotEmpty && locationName != location) {
      locationName = location;
    }
    if (nameChanged) {
      notifyListeners();
      fetchFarmerCropsFromSupabase();
    }
  }

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
    fetchFarmerCropsFromSupabase();
  }

  Future<void> fetchFarmerCropsFromSupabase() async {
    if (farmerName.isEmpty && (farmerId == null || farmerId!.isEmpty)) return;
    try {
      dynamic query = SupabaseService.client.from('farmer_plantings').select();
      if (farmerId != null && farmerId!.isNotEmpty) {
        query = query.or('farmer_id.eq.$farmerId,farmer_name.eq.$farmerName');
      } else {
        query = query.eq('farmer_name', farmerName);
      }

      final res = await query;
      if (res != null && res is List && res.isNotEmpty) {
        final fetched = <FarmPlanting>[];
        for (var row in res) {
          fetched.add(FarmPlanting(
            id: row['id'] ?? 'P${DateTime.now().millisecondsSinceEpoch}',
            crop: row['crop'] ?? 'Rice',
            hectares: (row['hectares'] as num?)?.toDouble() ?? 1.0,
            plantedOn: row['planted_on'] != null ? DateTime.parse(row['planted_on']) : DateTime.now(),
            lastYieldKg: (row['last_yield_kg'] as num?)?.toDouble(),
            costPhp: (row['cost_php'] as num?)?.toDouble(),
          ));
        }
        if (fetched.isNotEmpty) {
          plantings = fetched;
          if (selectedId == null || !plantings.any((p) => p.id == selectedId)) {
            selectedId = plantings.first.id;
          }
          notifyListeners();
          _save();
        }
      } else {
        // Fallback: Check 'farms' table for this farmer's crops
        dynamic farmsQuery = SupabaseService.client.from('farms').select();
        if (farmerId != null && farmerId!.isNotEmpty) {
          farmsQuery = farmsQuery.or('farmer_id.eq.$farmerId,farmer_name.eq.$farmerName');
        } else {
          farmsQuery = farmsQuery.eq('farmer_name', farmerName);
        }
        final farmRes = await farmsQuery;
        if (farmRes != null && farmRes is List && farmRes.isNotEmpty) {
          final fetchedFarms = <FarmPlanting>[];
          for (var row in farmRes) {
            fetchedFarms.add(FarmPlanting(
              id: row['id'] ?? 'P${DateTime.now().millisecondsSinceEpoch}',
              crop: row['crop_type'] ?? 'Rice',
              hectares: (row['land_area_hectares'] as num?)?.toDouble() ?? 1.0,
              plantedOn: DateTime.now().subtract(const Duration(days: 30)),
            ));
            if (row['latitude'] != null && row['longitude'] != null) {
              lat = (row['latitude'] as num).toDouble();
              lon = (row['longitude'] as num).toDouble();
            }
          }
          if (fetchedFarms.isNotEmpty) {
            plantings = fetchedFarms;
            if (selectedId == null || !plantings.any((p) => p.id == selectedId)) {
              selectedId = plantings.first.id;
            }
            notifyListeners();
            _save();
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase fetch farmer crops error: $e');
    }
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

  Future<void> add(FarmPlanting p) async {
    plantings = [...plantings, p];
    selectedId = p.id;
    _changed();

    // 1. Sync to main farms table
    try {
      final realLocation = (locationName.isNotEmpty && !locationName.startsWith('Pagsanjan Farm'))
          ? locationName
          : 'Barangay $barangay';

      final farmData = <String, dynamic>{
        'id': p.id,
        'farmer_name': farmerName,
        'location_name': realLocation,
        'latitude': lat,
        'longitude': lon,
        'land_area_hectares': p.hectares,
        'tenure_status': 'Owner',
        'crop_type': p.crop,
        'barangay': barangay,
      };
      if (farmerId != null && farmerId!.isNotEmpty) {
        farmData['farmer_id'] = farmerId;
      }
      await SupabaseService.client.from('farms').upsert(farmData);
      debugPrint('Successfully uploaded crop to Supabase farms table: ${p.crop}');
    } catch (e) {
      debugPrint('Supabase farms sync error (add): $e');
    }

    // 2. Sync to farmer_plantings table (if created)
    try {
      final plantingData = <String, dynamic>{
        'id': p.id,
        'farmer_name': farmerName,
        'crop': p.crop,
        'hectares': p.hectares,
        'planted_on': p.plantedOn.toIso8601String(),
        'last_yield_kg': p.lastYieldKg,
        'cost_php': p.costPhp,
        'barangay': barangay,
      };
      if (farmerId != null && farmerId!.isNotEmpty) {
        plantingData['farmer_id'] = farmerId;
      }
      await SupabaseService.client.from('farmer_plantings').upsert(plantingData);
      debugPrint('Successfully uploaded crop to Supabase farmer_plantings table: ${p.crop}');
    } catch (e) {
      debugPrint('Supabase farmer_plantings sync error (add): $e');
    }
  }

  Future<void> update(FarmPlanting p) async {
    plantings = [for (final e in plantings) e.id == p.id ? p : e];
    _changed();

    try {
      await SupabaseService.client.from('farms').update({
        'land_area_hectares': p.hectares,
        'crop_type': p.crop,
        'latitude': lat,
        'longitude': lon,
        'barangay': barangay,
      }).eq('id', p.id);
    } catch (e) {
      debugPrint('Supabase farms sync error (update): $e');
    }

    try {
      await SupabaseService.client.from('farmer_plantings').update({
        'crop': p.crop,
        'hectares': p.hectares,
        'planted_on': p.plantedOn.toIso8601String(),
        'last_yield_kg': p.lastYieldKg,
        'cost_php': p.costPhp,
        'barangay': barangay,
      }).eq('id', p.id);
    } catch (e) {
      debugPrint('Supabase farmer_plantings sync error (update): $e');
    }
  }

  Future<void> remove(String id) async {
    plantings = plantings.where((e) => e.id != id).toList();
    if (selectedId == id) selectedId = plantings.isEmpty ? null : plantings.first.id;
    _changed();

    try {
      await SupabaseService.client.from('farms').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase farms sync error (remove): $e');
    }

    try {
      await SupabaseService.client.from('farmer_plantings').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase farmer_plantings sync error (remove): $e');
    }
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
  Future<void> recordHarvest(String plantingId, HarvestRecord r) async {
    plantings = plantings.where((e) => e.id != plantingId).toList();
    if (selectedId == plantingId) selectedId = plantings.isEmpty ? null : plantings.first.id;
    history = [r, ...history];
    _changed();

    try {
      await SupabaseService.client.from('farms').delete().eq('id', plantingId);
    } catch (e) {
      debugPrint('Supabase farms sync error (harvest): $e');
    }

    try {
      await SupabaseService.client.from('farmer_plantings').delete().eq('id', plantingId);
    } catch (e) {
      debugPrint('Supabase farmer_plantings sync error (harvest): $e');
    }  }

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