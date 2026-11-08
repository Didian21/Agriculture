import 'dart:convert';

import 'package:http/http.dart' as http;

/// Panahon ng isang araw (Open-Meteo, walang API key).
class DayWx {
  final DateTime date;
  final int code;
  final double maxC;
  final double minC;
  final double rainMm;

  /// true = tantiya batay sa panahon noong nakaraang taon (lampas na sa 16-araw na forecast).
  final bool typical;

  const DayWx({
    required this.date,
    required this.code,
    required this.maxC,
    required this.minC,
    required this.rainMm,
    required this.typical,
  });
}

class _Entry {
  final DateTime at;
  final List<DayWx> data;
  _Entry(this.at, this.data);
}

/// Kinukuha ang panahon mula sa araw ng pagtatanim hanggang sa anihan:
///  - nakalipas na araw  -> totoong naitala (archive / past days)
///  - susunod na 16 araw -> forecast
///  - mas malayo pa      -> panahon noong nakaraang taon sa parehong petsa (tantiya lang)
class HarvestWeatherService {
  static final Map<String, _Entry> _cache = {};
  static const _ttl = Duration(hours: 3);
  static const _vars = 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum';

  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  static String _ymd(DateTime x) =>
      '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

  Future<Map<String, DayWx>> _get(
      String host,
      String path,
      double lat,
      double lon,
      DateTime a,
      DateTime b, {
        required bool typical,
        int yearShift = 0,
      }) async {
    final uri = Uri.parse('https://$host$path?latitude=$lat&longitude=$lon'
        '&start_date=${_ymd(a)}&end_date=${_ymd(b)}&daily=$_vars&timezone=Asia%2FManila');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final d = j['daily'] as Map<String, dynamic>?;
    if (d == null) return {};
    final times = (d['time'] as List?) ?? const [];
    final codes = (d['weather_code'] as List?) ?? const [];
    final maxs = (d['temperature_2m_max'] as List?) ?? const [];
    final mins = (d['temperature_2m_min'] as List?) ?? const [];
    final rains = (d['precipitation_sum'] as List?) ?? const [];
    final out = <String, DayWx>{};
    for (var i = 0; i < times.length; i++) {
      final code = i < codes.length ? (codes[i] as num?)?.toInt() : null;
      if (code == null) continue;
      final dt = DateTime.parse(times[i] as String);
      final date = DateTime(dt.year + yearShift, dt.month, dt.day);
      out[_ymd(date)] = DayWx(
        date: date,
        code: code,
        maxC: i < maxs.length ? (maxs[i] as num?)?.toDouble() ?? 0 : 0,
        minC: i < mins.length ? (mins[i] as num?)?.toDouble() ?? 0 : 0,
        rainMm: i < rains.length ? (rains[i] as num?)?.toDouble() ?? 0 : 0,
        typical: typical,
      );
    }
    return out;
  }

  Future<List<DayWx>> fetch({
    required double lat,
    required double lon,
    required DateTime from,
    required DateTime to,
  }) async {
    final today = _d(DateTime.now());
    final f = _d(from);
    final t = _d(to);
    if (t.isBefore(f)) return const [];

    final key = '$lat,$lon,${_ymd(f)},${_ymd(t)}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) return hit.data;

    const archive = 'archive-api.open-meteo.com';
    const forecast = 'api.open-meteo.com';
    final recentStart = today.subtract(const Duration(days: 90));
    final fcEnd = today.add(const Duration(days: 15));

    final tasks = <Future<Map<String, DayWx>>>[];

    // 1) Mas luma sa 90 araw -> archive
    if (f.isBefore(recentStart)) {
      final cut = recentStart.subtract(const Duration(days: 1));
      final end = t.isBefore(cut) ? t : cut;
      tasks.add(_get(archive, '/v1/archive', lat, lon, f, end, typical: false));
    }
    // 2) Nakalipas na 90 araw hanggang forecast
    final s2 = f.isAfter(recentStart) ? f : recentStart;
    final e2 = t.isBefore(fcEnd) ? t : fcEnd;
    if (!s2.isAfter(e2)) {
      tasks.add(_get(forecast, '/v1/forecast', lat, lon, s2, e2, typical: false));
    }
    // 3) Lampas sa forecast -> panahon noong nakaraang taon
    final afterFc = fcEnd.add(const Duration(days: 1));
    final s3 = f.isAfter(afterFc) ? f : afterFc;
    if (!s3.isAfter(t)) {
      tasks.add(_get(
        archive,
        '/v1/archive',
        lat,
        lon,
        DateTime(s3.year - 1, s3.month, s3.day),
        DateTime(t.year - 1, t.month, t.day),
        typical: true,
        yearShift: 1,
      ));
    }

    if (tasks.isEmpty) return const [];

    var failed = 0;
    final results = await Future.wait(tasks.map((fut) => fut.catchError((Object _) {
      failed++;
      return <String, DayWx>{};
    })));
    if (failed == tasks.length) throw Exception('Walang nakuhang panahon');

    final merged = <String, DayWx>{};
    for (final m in results) {
      merged.addAll(m);
    }
    final list = merged.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    _cache[key] = _Entry(DateTime.now(), list);
    return list;
  }
}