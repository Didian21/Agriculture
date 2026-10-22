import 'package:flutter/material.dart';

enum PlantStatus { best, possible, avoid }

class PlantingGuide {
  final String crop; // ID ng pananim, hal. 'Rice'
  final IconData icon; // gamit kapag wala pang larawan
  final Color color;
  final String image; // path ng larawan sa assets
  final Set<int> bestMonths;
  final Set<int> possibleMonths;

  const PlantingGuide({
    required this.crop,
    required this.icon,
    required this.color,
    required this.image,
    required this.bestMonths,
    required this.possibleMonths,
  });

  PlantStatus statusFor(int month) {
    if (bestMonths.contains(month)) return PlantStatus.best;
    if (possibleMonths.contains(month)) return PlantStatus.possible;
    return PlantStatus.avoid;
  }

  /// Antas ng pagiging angkop (0-100) para sa line graph.
  int scoreFor(int month) {
    switch (statusFor(month)) {
      case PlantStatus.best:
        return 100;
      case PlantStatus.possible:
        return 60;
      case PlantStatus.avoid:
        return 15;
    }
  }

  /// Numero ng susunod na pinakamagandang buwan (1-12), o null kung wala.
  int? nextBestMonth(int month) {
    for (var i = 0; i < 12; i++) {
      final m = ((month - 1 + i) % 12) + 1;
      if (bestMonths.contains(m)) return m;
    }
    return null;
  }

  /// Mga tuloy-tuloy na saklaw ng pinakamagandang buwan, hal. (10, 1) = Okt hanggang Ene.
  List<(int, int)> bestRanges() {
    if (bestMonths.length == 12) return [(1, 12)];
    final out = <(int, int)>[];
    for (final m in bestMonths) {
      final prev = m == 1 ? 12 : m - 1;
      if (bestMonths.contains(prev)) continue;
      var e = m;
      while (bestMonths.contains(e == 12 ? 1 : e + 1)) {
        e = e == 12 ? 1 : e + 1;
      }
      out.add((m, e));
    }
    out.sort((a, b) => a.$1.compareTo(b.$1));
    return out;
  }
}