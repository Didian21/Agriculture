// Mga bahagi ng panahon na ginagamit sa Home: babala, kasalukuyang panahon, pagtaya, at heat index.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/heat_index.dart';
import '../core/tr.dart';
import '../dashboard_data.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/weather_alert_service.dart';
import 'common_widgets.dart';
import 'weather_icon.dart';

class WeatherCard extends StatelessWidget {
  final WeatherBundle w;
  final DateTime? updated;
  final bool stale;
  final String place;

  const WeatherCard({super.key, required this.w, required this.updated, required this.stale, required this.place});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode != 'tl';
    final tl = lookupAppLocalizations(const Locale('tl')); // pangalawang label (Tagalog) para sa English
    final c = w.current;
    final info = c.info;
    final glyph = glyphFor(c.code, isDay: c.isDay);
    final today = w.daily.first;

    final summary = t.todayRange(
      today.tempMin.round().toString(),
      today.tempMax.round().toString(),
      today.rainMm.toStringAsFixed(1),
    );
    final updatedLine = updated != null ? '\n${t.updatedAt(updated!)}' : '';

    return GlassCard(
      tint: Color.lerp(Colors.white, info.gradient.first, 0.22),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, color: AppColors.leaf, size: 15),
          const SizedBox(width: 4),
          Expanded(
            child: Text('$place, Pagsanjan',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5), overflow: TextOverflow.ellipsis),
          ),
          _LiveDot(color: stale ? Colors.orangeAccent : AppColors.up),
          const SizedBox(width: 6),
          Text(stale ? t.statusOffline : t.statusLive,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _Floating(
            child: WeatherIcon(glyph: glyph, size: 72, animated: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CountUp(value: c.temp, suffix: '°', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.0)),
              const SizedBox(height: 2),
              Text(t.glyphLabel(glyph), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              if (isEnglish) Text(tl.glyphLabel(glyph), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
          Expanded(
            flex: 6,
            child: Column(children: [
              _StatLine(Icons.thermostat_rounded, t.feelsLike, '${c.feelsLike.round()}°'),
              _StatLine(Icons.water_drop_rounded, t.humidity, '${c.humidity}%'),
              _StatLine(Icons.air_rounded, t.wind, '${c.windKmh.round()} km/h'),
              _StatLine(Icons.umbrella_rounded, t.rainChance, '${today.rainChance}%'),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text(summary + updatedLine, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
      ]),
    );
  }
}

class _StatLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatLine(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.leaf),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Buod ng bukid
// ---------------------------------------------------------------------------

class HeatIndexCard extends StatelessWidget {
  final HeatIndex heat;
  const HeatIndexCard({super.key, required this.heat});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = heatColor(heat.level);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(t.heatIndex, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.muted)),
          const Spacer(),
          Text(t.heatLevelName(heat.level), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: color)),
        ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CountUp(
            value: heat.celsius,
            suffix: '°C',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color, height: 1.0),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(t.heatLevelAdvice(heat.level), style: const TextStyle(fontSize: 12.5, height: 1.35))),
        ]),
        const SizedBox(height: 12),
        _HeatScale(value: heat.celsius),
      ]),
    );
  }
}

/// Manipis na kulay na guhit na may marker sa kasalukuyang heat index.
class _HeatScale extends StatelessWidget {
  final double value;
  const _HeatScale({required this.value});

  static const _min = 24.0;
  static const _max = 56.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      double x(double v) => (math.min(math.max(v, _min), _max) - _min) / (_max - _min) * w;

      Widget seg(HeatLevel l, int flex) => Expanded(flex: flex, child: Container(color: heatColor(l).withValues(alpha: 0.55)));

      return SizedBox(
        height: 14,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 0,
            right: 0,
            top: 4,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(children: [
                seg(HeatLevel.normal, 3),
                seg(HeatLevel.caution, 6),
                seg(HeatLevel.extremeCaution, 9),
                seg(HeatLevel.danger, 10),
                seg(HeatLevel.extremeDanger, 4),
              ]),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: _min, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => Positioned(
              left: x(v) - 7,
              top: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2.5),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

/// Maliit na heat index label para sa oras/araw na tile.
class _HeatMini extends StatelessWidget {
  final HeatIndex? heat;
  final bool onAccent;
  const _HeatMini({required this.heat, required this.onAccent});

  @override
  Widget build(BuildContext context) {
    final h = heat;
    if (h == null) return const SizedBox(height: 12);
    final c = onAccent ? Colors.white : heatColor(h.level);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.device_thermostat_rounded, size: 11, color: c),
      Text('${h.celsius.round()}°', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Forecast (oras-oras / 7 araw)
// ---------------------------------------------------------------------------

class ForecastCard extends StatefulWidget {
  final List<HourlyWeather> hours;
  final List<WeatherDay> days;
  const ForecastCard({super.key, required this.hours, required this.days});

  @override
  State<ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<ForecastCard> {
  bool _week = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final Widget list = _week
        ? ListView.separated(
      key: const ValueKey('week'),
      scrollDirection: Axis.horizontal,
      itemCount: widget.days.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (_, i) => _DayItem(day: widget.days[i], isToday: i == 0, locale: locale, todayLabel: t.today),
    )
        : ListView.separated(
      key: const ValueKey('hours'),
      scrollDirection: Axis.horizontal,
      itemCount: widget.hours.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (_, i) => _HourItem(hour: widget.hours[i], isFirst: i == 0, locale: locale, nowLabel: t.now),
    );

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.insights_rounded, color: AppColors.leaf),
          const SizedBox(width: 8),
          Text(t.forecastTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return const Color(0xFF166534);
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return const Color(0xFF1E293B);
              }),
              side: WidgetStateProperty.all(const BorderSide(color: Color(0xFF166534), width: 1.5)),
            ),
            segments: [
              ButtonSegment(
                value: false,
                label: Text(t.hourlyTab, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ButtonSegment(
                value: true,
                label: Text(t.weeklyTab, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
            selected: {_week},
            onSelectionChanged: (s) => setState(() => _week = s.first),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SizedBox(key: ValueKey(_week), height: 130, child: list),
        ),
      ]),
    );
  }
}

class _HourItem extends StatelessWidget {
  final HourlyWeather hour;
  final bool isFirst;
  final String locale;
  final String nowLabel;
  const _HourItem({required this.hour, required this.isFirst, required this.locale, required this.nowLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isFirst ? AppColors.accentDark : AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFirst ? AppColors.leaf : AppColors.border),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(isFirst ? nowLabel : DateFormat('h a', locale).format(hour.time),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isFirst ? Colors.white : AppColors.muted)),
        WeatherIcon(glyph: glyphFor(hour.code, isDay: hour.isDay), size: 30),
        Text('${hour.temp.round()}°', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.water_drop, size: 10, color: isFirst ? Colors.white70 : AppColors.rain),
          const SizedBox(width: 2),
          Text('${hour.rainChance}%', style: const TextStyle(fontSize: 10)),
        ]),
        _HeatMini(heat: hour.heat, onAccent: isFirst),
      ]),
    );
  }
}

class _DayItem extends StatelessWidget {
  final WeatherDay day;
  final bool isToday;
  final String locale;
  final String todayLabel;
  const _DayItem({required this.day, required this.isToday, required this.locale, required this.todayLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppColors.accentDark : AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isToday ? AppColors.leaf : AppColors.border),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(isToday ? todayLabel : DateFormat('EEE d', locale).format(day.date),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isToday ? Colors.white : AppColors.muted)),
        WeatherIcon(glyph: glyphFor(day.code), size: 30),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${day.tempMax.round()}°', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text('${day.tempMin.round()}°', style: TextStyle(fontSize: 11, color: isToday ? Colors.white70 : AppColors.muted)),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.water_drop, size: 10, color: isToday ? Colors.white70 : AppColors.rain),
          const SizedBox(width: 2),
          Text('${day.rainChance}%', style: const TextStyle(fontSize: 10)),
        ]),
        _HeatMini(heat: day.heatPeak, onAccent: isToday),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Payo sa pagsasaka
// ---------------------------------------------------------------------------

class _Floating extends StatefulWidget {
  final Widget child;
  const _Floating({required this.child});

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(offset: Offset(0, math.sin(_c.value * 2 * math.pi) * 4), child: child),
      child: widget.child,
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(width: 9, height: 9, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}


/// Segmented control sa Home tab (Panahon | Mga Pananim).

// ---------------------------------------------------------------------------
// Mga babala
// ---------------------------------------------------------------------------

Color _alertColor(AlertLevel l) {
  switch (l) {
    case AlertLevel.warning:
      return const Color(0xFFD35400);
    case AlertLevel.watch:
      return const Color(0xFFE0A100);
    case AlertLevel.info:
      return AppColors.leaf;
  }
}

class AlertSection extends StatelessWidget {
  final List<WeatherAlert> alerts;
  final Future<List<AdminAdvisory>> admin;
  const AlertSection({super.key, required this.alerts, required this.admin});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    return FutureBuilder<List<AdminAdvisory>>(
      future: admin,
      builder: (context, snap) {
        final posted = snap.data ?? const <AdminAdvisory>[];
        final cards = <Widget>[
          for (final a in posted)
            _AlertCard(
              color: _alertColor(AlertLevel.warning),
              icon: Icons.campaign_rounded,
              title: a.title,
              body: a.message,
              source: a.source,
            ),
          for (final a in alerts)
            _AlertCard(color: _alertColor(a.level), icon: a.icon, title: a.title(tl), body: a.body(tl), source: a.source),
        ];
        if (cards.isEmpty) {
          return _AlertCard(
            color: AppColors.leaf,
            icon: Icons.check_circle_rounded,
            title: tr(context, 'Walang babala ngayon', 'No warnings right now'),
            body: tr(context, 'Normal ang panahon sa susunod na 48 oras ayon sa forecast.', 'The forecast shows normal weather for the next 48 hours.'),
            source: 'Forecast (Open-Meteo)',
          );
        }
        return Column(children: [
          for (var i = 0; i < cards.length; i++) Padding(padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : 10), child: cards[i]),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tr(context, 'Ang mga babalang galing sa forecast ay tantiya lamang. Para sa opisyal na babala, tingnan ang PAGASA.',
                  'Warnings from the forecast are estimates only. For official warnings, check PAGASA.'),
              style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
            ),
          ),
        ]);
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String source;
  const _AlertCard({required this.color, required this.icon, required this.title, required this.body, required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, color, 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(source, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}