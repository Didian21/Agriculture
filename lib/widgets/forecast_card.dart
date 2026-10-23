import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Hourly + 7-day weather forecast straight from Open-Meteo (no API key needed).
// Usage:   const ForecastCard()                       -> Pagsanjan town center
//          ForecastCard(lat: 14.28, lng: 121.46)     -> a specific farm
// Needs:   flutter pub add http
// ---------------------------------------------------------------------------

const int kHoursToShow = 24; // change to 48 for two days of hourly weather

class ForecastHour {
  final DateTime time;
  final int? code;
  final double? temp, rainChance, rainMm;
  ForecastHour({required this.time, this.code, this.temp, this.rainChance, this.rainMm});
}

class ForecastDay {
  final DateTime date;
  final int? code;
  final double? tMax, tMin, rainMm, rainChance, windMax;
  ForecastDay({
    required this.date,
    this.code,
    this.tMax,
    this.tMin,
    this.rainMm,
    this.rainChance,
    this.windMax,
  });
}

class Forecast {
  final double? temp, humidity, wind, rain;
  final int? code;
  final List<ForecastHour> hours;
  final List<ForecastDay> days;
  Forecast({
    this.temp,
    this.humidity,
    this.wind,
    this.rain,
    this.code,
    required this.hours,
    required this.days,
  });
}

class ForecastService {
  static Future<Forecast> fetch({double lat = 14.2727, double lng = 121.4557}) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'current': 'temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,weather_code',
      'hourly': 'temperature_2m,precipitation_probability,precipitation,weather_code',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,'
          'precipitation_probability_max,wind_speed_10m_max',
      'timezone': 'Asia/Manila',
      'forecast_days': '7',
    });

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Weather service error (${res.statusCode})');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final cur = (j['current'] ?? {}) as Map<String, dynamic>;
    final d = (j['daily'] ?? {}) as Map<String, dynamic>;
    final h = (j['hourly'] ?? {}) as Map<String, dynamic>;

    double? n(dynamic v) => (v as num?)?.toDouble();
    List dl(String k) => (d[k] ?? []) as List;
    List hl(String k) => (h[k] ?? []) as List;

    // ---- hourly: start from the current hour, keep the next kHoursToShow hours
    final curTime = cur['time'] is String ? DateTime.parse(cur['time'] as String) : null;
    final start = curTime == null
        ? null
        : DateTime(curTime.year, curTime.month, curTime.day, curTime.hour);
    final hTimes = hl('time');
    final hours = <ForecastHour>[];
    for (var i = 0; i < hTimes.length && hours.length < kHoursToShow; i++) {
      final t = DateTime.parse(hTimes[i] as String);
      if (start != null && t.isBefore(start)) continue;
      hours.add(ForecastHour(
        time: t,
        code: (hl('weather_code')[i] as num?)?.toInt(),
        temp: n(hl('temperature_2m')[i]),
        rainChance: n(hl('precipitation_probability')[i]),
        rainMm: n(hl('precipitation')[i]),
      ));
    }

    // ---- daily
    final dTimes = dl('time');
    final days = <ForecastDay>[
      for (var i = 0; i < dTimes.length; i++)
        ForecastDay(
          date: DateTime.parse(dTimes[i] as String),
          code: (dl('weather_code')[i] as num?)?.toInt(),
          tMax: n(dl('temperature_2m_max')[i]),
          tMin: n(dl('temperature_2m_min')[i]),
          rainMm: n(dl('precipitation_sum')[i]),
          rainChance: n(dl('precipitation_probability_max')[i]),
          windMax: n(dl('wind_speed_10m_max')[i]),
        ),
    ];

    return Forecast(
      temp: n(cur['temperature_2m']),
      humidity: n(cur['relative_humidity_2m']),
      wind: n(cur['wind_speed_10m']),
      rain: n(cur['precipitation']),
      code: (cur['weather_code'] as num?)?.toInt(),
      hours: hours,
      days: days,
    );
  }
}

// WMO weather code -> text + icon
(String, IconData) describe(int? code) {
  switch (code) {
    case 0:
      return ('Clear sky', Icons.wb_sunny);
    case 1:
    case 2:
      return ('Partly cloudy', Icons.wb_cloudy);
    case 3:
      return ('Overcast', Icons.cloud);
    case 45:
    case 48:
      return ('Fog', Icons.cloud);
    case 51:
    case 53:
    case 55:
      return ('Drizzle', Icons.grain);
    case 61:
    case 63:
    case 65:
    case 80:
    case 81:
    case 82:
      return ('Rain', Icons.water_drop);
    case 95:
    case 96:
    case 99:
      return ('Thunderstorm', Icons.thunderstorm);
    default:
      return ('--', Icons.help_outline);
  }
}

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _hourLabel(DateTime t) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h12 ${t.hour < 12 ? 'AM' : 'PM'}';
}

class ForecastCard extends StatefulWidget {
  final double lat, lng;
  const ForecastCard({super.key, this.lat = 14.2727, this.lng = 121.4557});

  @override
  State<ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<ForecastCard> {
  late Future<Forecast> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ForecastService.fetch(lat: widget.lat, lng: widget.lng);
  }

  String _num(double? v, [int digits = 0]) => v == null ? '--' : v.toStringAsFixed(digits);

  Widget _hourTile(BuildContext context, ForecastHour hr, bool isNow) {
    final (_, icon) = describe(hr.code);
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNow ? Theme.of(context).colorScheme.primary : Colors.black26,
          width: isNow ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(isNow ? 'Now' : _hourLabel(hr.time),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Icon(icon, size: 24),
          Text('${_num(hr.temp)}°', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${_num(hr.rainChance)}%',
              style: const TextStyle(fontSize: 11, color: Colors.blue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Forecast>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError || snap.data == null) {
              return Column(
                children: [
                  const Text('Could not load the weather forecast.'),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Try again'),
                  ),
                ],
              );
            }
            final f = snap.data!;
            final (text, icon) = describe(f.code);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- right now
                Row(
                  children: [
                    Icon(icon, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_num(f.temp, 1)} °C  $text',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text('Humidity ${_num(f.humidity)}%  •  '
                              'Wind ${_num(f.wind)} km/h  •  Rain ${_num(f.rain, 1)} mm'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () => setState(_load),
                    ),
                  ],
                ),

                // ---- hour by hour
                const Divider(height: 24),
                const Text('Hour by hour', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: f.hours.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _hourTile(context, f.hours[i], i == 0),
                  ),
                ),

                // ---- next 7 days
                const Divider(height: 24),
                const Text('7-day forecast', style: TextStyle(fontWeight: FontWeight.bold)),
                ...f.days.map((day) {
                  final (_, dIcon) = describe(day.code);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(dIcon),
                    title: Text('${_dayNames[day.date.weekday - 1]} ${day.date.day}'),
                    subtitle: Text(
                        'Rain chance ${_num(day.rainChance)}%  •  ${_num(day.rainMm, 1)} mm'),
                    trailing: Text('${_num(day.tMin)}° / ${_num(day.tMax)}°'),
                  );
                }),
                const SizedBox(height: 4),
                const Text('Weather data: Open-Meteo.com',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            );
          },
        ),
      ),
    );
  }
}
