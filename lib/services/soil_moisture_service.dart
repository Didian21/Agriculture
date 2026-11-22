import 'dart:convert';

import 'package:http/http.dart' as http;

enum SoilLevel { dry, moderate, wet, saturated }

/// Halumigmig ng lupa (m3/m3, 0-7 cm) mula sa Open-Meteo. Walang API key.
/// Modelong pagtataya ito ng Open-Meteo, hindi sukat mula sa sensor sa mismong bukid.
class SoilMoisture {
  final double value;
  const SoilMoisture(this.value);

  int get percent => (value * 100).round();

  // Mga hangganan ay tantiya (hindi opisyal); i-verify kung gagamitin sa pananaliksik.
  SoilLevel get level {
    if (value < 0.20) return SoilLevel.dry;
    if (value < 0.32) return SoilLevel.moderate;
    if (value < 0.42) return SoilLevel.wet;
    return SoilLevel.saturated;
  }
}

class SoilMoistureService {
  static final Map<String, (DateTime, double)> _cache = {};

  Future<SoilMoisture?> fetch(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1) < const Duration(hours: 1)) return SoilMoisture(hit.$2);
    try {
      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lon&hourly=soil_moisture_0_to_7cm&forecast_days=1&timezone=Asia%2FManila');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final vals = ((j['hourly'] as Map<String, dynamic>?)?['soil_moisture_0_to_7cm'] as List?) ?? const [];
      if (vals.isEmpty) return null;
      final i = DateTime.now().hour.clamp(0, vals.length - 1);
      final v = (vals[i] as num?)?.toDouble();
      if (v == null) return null;
      _cache[key] = (DateTime.now(), v);
      return SoilMoisture(v);
    } catch (_) {
      return null;
    }
  }
}

String soilLabel(SoilLevel l, bool tl) {
  switch (l) {
    case SoilLevel.dry:
      return tl ? 'Tuyo' : 'Dry';
    case SoilLevel.moderate:
      return tl ? 'Katamtaman' : 'Moderate';
    case SoilLevel.wet:
      return tl ? 'Basa' : 'Wet';
    case SoilLevel.saturated:
      return tl ? 'Basang-basa' : 'Saturated';
  }
}