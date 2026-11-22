import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../core/dss_catalog.dart';

/// Yugto ng pananim (batay sa araw mula nang itanim kumpara sa karaniwang tagal bago maani).
enum CropStage { seedling, vegetative, reproductive, ripening, harvestReady }

String stageLabel(CropStage s, bool tl) {
  switch (s) {
    case CropStage.seedling:
      return tl ? 'Punla (Seedling)' : 'Seedling';
    case CropStage.vegetative:
      return tl ? 'Paglaki ng dahon (Vegetative)' : 'Vegetative stage';
    case CropStage.reproductive:
      return tl ? 'Pamumulaklak (Reproductive)' : 'Reproductive stage';
    case CropStage.ripening:
      return tl ? 'Paghinog (Ripening)' : 'Ripening';
    case CropStage.harvestReady:
      return tl ? 'Handa nang anihin' : 'Ready to harvest';
  }
}

/// Talaan ng sakahan ng farmer: pananim, petsa ng pagtatanim, hangganan ng bukid at tahanan.
/// Sa ngayon, [SampleFarm] ang ginagamit. Kapag may datos na mula sa admin (Supabase),
/// papalitan lang ang pinagmulan ng FarmRecord; hindi na kailangang baguhin ang mga screen.
class FarmRecord {
  final String crop; // ID sa crop_data.dart, hal. 'Rice'
  final String? variety; // hal. 'RC 216'
  final DateTime plantedOn;
  final List<LatLng> polygon;
  final LatLng home;
  final double areaHaRecorded;
  final bool isSample;
  final SoilType? soil;

  /// Sariling petsa ng pag-aani na itinakda ng farmer (kung wala, kinukuwenta mula sa pananim).
  final DateTime? harvestOn;

  const FarmRecord({
    required this.crop,
    this.variety,
    required this.plantedOn,
    required this.polygon,
    required this.home,
    required this.areaHaRecorded,
    this.isSample = false,
    this.soil,
    this.harvestOn,
  });

  FarmRecord copyWith({
    List<LatLng>? polygon,
    LatLng? home,
    String? crop,
    DateTime? plantedOn,
    double? areaHaRecorded,
    bool? isSample,
    SoilType? soil,
    DateTime? harvestOn,
  }) =>
      FarmRecord(
        crop: crop ?? this.crop,
        variety: crop != null ? null : variety,
        plantedOn: plantedOn ?? this.plantedOn,
        polygon: polygon ?? this.polygon,
        home: home ?? this.home,
        areaHaRecorded: areaHaRecorded ?? this.areaHaRecorded,
        isSample: isSample ?? this.isSample,
        soil: soil ?? this.soil,
        harvestOn: harvestOn ?? this.harvestOn,
      );

  /// Lawak ng lupa (ha) na inilagay ng farmer sa DSS.
  double get areaHa => areaHaRecorded;

  /// Sukat ng iginuhit na hugis sa mapa (ha). 0 kung wala pang hugis.
  double get polygonHa => polygon.length >= 3 ? polygonAreaHa(polygon) : 0;

  LatLng get center {
    if (polygon.isEmpty) return home;
    var la = 0.0, lo = 0.0;
    for (final p in polygon) {
      la += p.latitude;
      lo += p.longitude;
    }
    return LatLng(la / polygon.length, lo / polygon.length);
  }

  int get daysGrown {
    final now = DateTime.now();
    final a = DateTime(plantedOn.year, plantedOn.month, plantedOn.day);
    final b = DateTime(now.year, now.month, now.day);
    return b.difference(a).inDays.clamp(0, 100000);
  }

  /// Tinatayang kabuuang araw bago maani (null kung taon ang hinihintay, hal. niyog).
  int? get totalDays {
    final d = cropDays(crop);
    if (d == null) return null;
    return ((d.$1 + d.$2) / 2).round();
  }

  DateTime? get harvestFrom {
    final d = cropDays(crop);
    if (d == null) return null;
    return plantedOn.add(Duration(days: d.$1));
  }

  DateTime? get harvestTo {
    final d = cropDays(crop);
    if (d == null) return null;
    return plantedOn.add(Duration(days: d.$2));
  }

  /// Gitna ng inaasahang panahon ng ani (o ang petsang itinakda ng farmer).
  DateTime? get harvestMid {
    if (harvestOn != null) return harvestOn;
    final a = harvestFrom, b = harvestTo;
    if (a == null || b == null) return null;
    return a.add(Duration(days: b.difference(a).inDays ~/ 2));
  }

  /// Progreso 0..1 (null kung walang tantiyang tagal).
  double? get progress {
    final t = totalDays;
    if (t == null || t == 0) return null;
    return (daysGrown / t).clamp(0.0, 1.0);
  }

  CropStage? get stage {
    final t = totalDays;
    if (t == null || t == 0) return null;
    final f = daysGrown / t;
    if (f < 0.17) return CropStage.seedling;
    if (f < 0.45) return CropStage.vegetative;
    if (f < 0.70) return CropStage.reproductive;
    if (f < 1.0) return CropStage.ripening;
    return CropStage.harvestReady;
  }
}

/// Sukat ng polygon sa hektarya (approximate, para sa maliliit na bukid).
double polygonAreaHa(List<LatLng> pts) {
  if (pts.length < 3) return 0;
  final lat0 = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
  const mPerDegLat = 111320.0;
  final mPerDegLon = 111320.0 * math.cos(lat0 * math.pi / 180);
  final xy = [for (final p in pts) (p.longitude * mPerDegLon, p.latitude * mPerDegLat)];
  var a = 0.0;
  for (var i = 0; i < xy.length; i++) {
    final p = xy[i];
    final q = xy[(i + 1) % xy.length];
    a += p.$1 * q.$2 - q.$1 * p.$2;
  }
  return a.abs() / 2 / 10000;
}

/// HALIMBAWANG bukid (Mang Juan, Sampaloc) para makita ang layout.
/// Hindi totoong lokasyon. Papalitan ng totoong rekord mula sa admin.
class SampleFarm {
  static FarmRecord get current {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return FarmRecord(
      crop: 'Rice',
      variety: 'RC 216',
      plantedOn: today.subtract(const Duration(days: 35)),
      polygon: const [
        LatLng(14.268479, 121.457425),
        LatLng(14.268533, 121.458612),
        LatLng(14.269575, 121.458556),
        LatLng(14.269629, 121.457462),
      ],
      home: const LatLng(14.269000, 121.457000),
      areaHaRecorded: 1.5,
      isSample: true,
    );
  }
}