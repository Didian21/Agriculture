import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dss_catalog.dart';
import 'farm_record.dart';

/// Isang tanim ng farmer (pananim, lupa, lawak, petsa) mula sa DSS. Maaaring higit sa isa ang tanim ng farmer.
class FarmProfile {
  final String id;
  final String crop;
  final SoilType soil;
  final double areaHa;
  final DateTime plantedOn;
  final DateTime? harvestOn;
  final double? price;
  const FarmProfile({
    required this.id,
    required this.crop,
    required this.soil,
    required this.areaHa,
    required this.plantedOn,
    this.harvestOn,
    this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop': crop,
    'soil': soil.name,
    'areaHa': areaHa,
    'plantedOn': plantedOn.toIso8601String(),
    'harvestOn': harvestOn?.toIso8601String(),
    'price': price,
  };

  static FarmProfile? fromJson(Map<String, dynamic> m) {
    try {
      return FarmProfile(
        id: (m['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
        crop: m['crop'] as String,
        soil: SoilType.values.firstWhere((e) => e.name == m['soil'], orElse: () => SoilType.unknown),
        areaHa: (m['areaHa'] as num).toDouble(),
        plantedOn: DateTime.parse(m['plantedOn'] as String),
        harvestOn: m['harvestOn'] == null ? null : DateTime.parse(m['harvestOn'] as String),
        price: (m['price'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Hawak ang bukid ng farmer: ang listahan ng mga tanim mula sa DSS (pananim, lupa, lawak, petsa)
/// at ang hugis (polygon) at tahanan na iginuhit. Naka-save sa telepono.
/// Kapag may Supabase na, ang save/load lang dito ang papalitan.
class FarmStore extends ChangeNotifier {
  FarmStore._();
  static final FarmStore instance = FarmStore._();

  static const _shapeKey = 'farm_shape_v1';
  static const _oldProfileKey = 'farm_profile_v1'; // dating iisang tanim (inililipat sa listahan)
  static const _profilesKey = 'farm_profiles_v2';
  static const _activeKey = 'farm_active_v2';
  static const _totalKey = 'farm_total_ha_v1';

  List<LatLng>? _polygon;
  LatLng? _home;
  final List<FarmProfile> _profiles = [];
  String? _activeId;
  double? _manualTotalHa;
  bool _loaded = false;

  bool get isCustom => _polygon != null;
  List<FarmProfile> get profiles => List.unmodifiable(_profiles);
  bool get hasProfile => _profiles.isNotEmpty;

  /// Ang piniling tanim (ito ang ipinapakita sa Home, Aking Bukid at Payo).
  FarmProfile? get profile {
    if (_profiles.isEmpty) return null;
    for (final p in _profiles) {
      if (p.id == _activeId) return p;
    }
    return _profiles.first;
  }

  /// Kabuuang lupa (ha) na hahatiin sa mga tanim: ang sukat ng iginuhit na hugis, o ang inilagay na numero.
  /// Null kung wala pa.
  double? get totalHa {
    if (_polygon != null) {
      final a = polygonAreaHa(_polygon!);
      if (a > 0) return a;
    }
    return _manualTotalHa;
  }

  /// Inilagay na kabuuang lupa (ginagamit kung walang iginuhit na hugis).
  double? get manualTotalHa => _manualTotalHa;

  Future<void> setManualTotalHa(double? v) async {
    _manualTotalHa = (v == null || v <= 0) ? null : v;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      if (_manualTotalHa == null) {
        await sp.remove(_totalKey);
      } else {
        await sp.setDouble(_totalKey, _manualTotalHa!);
      }
    } catch (_) {}
  }

  /// Kabuuang lawak (ha) ng lahat ng tanim, maliban sa [exceptId].
  double usedHa({String? exceptId}) =>
      _profiles.where((p) => p.id != exceptId).fold<double>(0, (s, p) => s + p.areaHa);

  FarmRecord recordFor(FarmProfile? p) {
    var r = SampleFarm.current.copyWith(polygon: _polygon, home: _home);
    if (p != null) {
      r = r.copyWith(
        crop: p.crop,
        plantedOn: p.plantedOn,
        areaHaRecorded: p.areaHa,
        soil: p.soil,
        harvestOn: p.harvestOn,
        isSample: false,
      );
    }
    return r;
  }

  FarmRecord get current => recordFor(profile);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_shapeKey);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        LatLng ll(dynamic v) => LatLng((v[0] as num).toDouble(), (v[1] as num).toDouble());
        final poly = [for (final v in (m['poly'] as List)) ll(v)];
        if (poly.length >= 3) {
          _polygon = poly;
          _home = m['home'] == null ? null : ll(m['home']);
        }
      }
      final list = sp.getString(_profilesKey);
      if (list != null) {
        for (final v in (jsonDecode(list) as List)) {
          final p = FarmProfile.fromJson(v as Map<String, dynamic>);
          if (p != null) _profiles.add(p);
        }
      } else {
        final old = sp.getString(_oldProfileKey);
        if (old != null) {
          final p = FarmProfile.fromJson(jsonDecode(old) as Map<String, dynamic>);
          if (p != null) _profiles.add(p);
        }
      }
      _activeId = sp.getString(_activeKey);
      _manualTotalHa = sp.getDouble(_totalKey);
      notifyListeners();
    } catch (_) {
      // Kung may problema sa pagbasa, gamitin lang ang halimbawa.
    }
  }

  Future<void> _persist() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_profilesKey, jsonEncode([for (final p in _profiles) p.toJson()]));
      if (_activeId == null) {
        await sp.remove(_activeKey);
      } else {
        await sp.setString(_activeKey, _activeId!);
      }
    } catch (_) {}
  }

  /// Magdagdag ng bagong tanim, o palitan kung may parehong id. Ito na ang magiging piniling tanim.
  Future<void> saveProfile(FarmProfile p) async {
    final i = _profiles.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      _profiles[i] = p;
    } else {
      _profiles.add(p);
    }
    _activeId = p.id;
    notifyListeners();
    await _persist();
  }

  Future<void> removeProfile(String id) async {
    _profiles.removeWhere((e) => e.id == id);
    if (_activeId == id) _activeId = _profiles.isEmpty ? null : _profiles.first.id;
    notifyListeners();
    await _persist();
  }

  Future<void> setActive(String id) async {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
    await _persist();
  }

  Future<void> save(List<LatLng> polygon, LatLng home) async {
    _polygon = List.of(polygon);
    _home = home;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        _shapeKey,
        jsonEncode({
          'poly': [for (final p in polygon) [p.latitude, p.longitude]],
          'home': [home.latitude, home.longitude],
        }),
      );
    } catch (_) {}
  }

  Future<void> reset() async {
    _polygon = null;
    _home = null;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_shapeKey);
    } catch (_) {}
  }
}