import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/heat_index.dart';
import '../../../core/l10n_data.dart';
import '../../../core/crop_l10n.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/crop_advice.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../services/crop_advice_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/dss_common.dart';
import '../../../widgets/dss_summary_card.dart';
import '../../../widgets/heat_graph.dart';
import '../../../widgets/weather_icon.dart';

class WeatherTab extends StatelessWidget {
  final DashboardProvider p;
  final VoidCallback? onOpenDss;
  const WeatherTab({super.key, required this.p, this.onOpenDss});

  String _greeting(AppLocalizations t) {
    final h = DateTime.now().hour;
    if (h < 12) return t.greetingMorning;
    if (h < 18) return t.greetingAfternoon;
    return t.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final w = p.weather!;
    final profile = p.profile!;
    final firstName = profile.name.split(' ').first;
    final heat = w.current.heat;

    // Mga oras ng ngayong araw (5 AM - 7 PM) para sa heat timeline.
    final now = w.current.time;
    final todayHours = w.hourlyAll
        .where((e) =>
    e.time.year == now.year &&
        e.time.month == now.month &&
        e.time.day == now.day &&
        e.time.hour >= 5 &&
        e.time.hour <= 19)
        .toList();

    final farm = context.watch<FarmInputProvider>();
    final activeCrops = farm.plantings.length;
    final cropAdvice = CropAdviceService().build(farm.plantings, w);
    final plantNow = p.guides.where((g) => g.statusFor(DateTime.now().month) == PlantStatus.best).length;

    return AnimatedTabList(items: [
      _GreetingHeader(
        title: '${_greeting(t)}, $firstName! 👋',
        subtitle: DateFormat('EEEE, MMMM d', locale).format(DateTime.now()),
        initial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
      ),
      const SizedBox(height: 14),

      // Panahon
      _WeatherCard(w: w, updated: p.lastUpdated, stale: p.weatherStale, place: profile.barangay),
      const SizedBox(height: 20),

      // DSS ng bukid (galing sa inilagay ng magsasaka)
      DssSummaryCard(onOpenDss: onOpenDss),
      const SizedBox(height: 20),

      // Buod ng bukid
      SectionTitle(icon: Icons.dashboard_rounded, text: t.farmOverview),
      Row(children: [
        Expanded(
          child: _OverviewTile(
            label: t.totalLandSize,
            icon: Icons.landscape_rounded,
            value: CountUp(
              value: farm.useSqm ? farm.landTotal * 10000 : farm.landTotal,
              decimals: farm.useSqm ? 0 : 2,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              suffix: farm.useSqm ? ' m²' : ' ha',
            ),
            sub: DssFmt.area(farm.landTotal, sqm: !farm.useSqm),
            subColor: AppColors.leaf,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewTile(
            label: t.overviewCrops,
            icon: Icons.eco_rounded,
            value: CountUp(value: activeCrops.toDouble(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            sub: t.overviewCropsSub,
            subColor: AppColors.leaf,
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: _OverviewTile(
            label: t.heatIndex,
            icon: Icons.device_thermostat_rounded,
            iconColor: heatColor(heat.level),
            value: CountUp(
              value: heat.celsius,
              suffix: '°C',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: heatColor(heat.level)),
            ),
            sub: t.heatLevelName(heat.level),
            subColor: heatColor(heat.level),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewTile(
            label: t.overviewPlantNow,
            icon: Icons.spa_rounded,
            value: CountUp(value: plantNow.toDouble(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            sub: t.overviewPlantNowSub,
            subColor: AppColors.leaf,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      _HeatIndexCard(heat: heat, todayHours: todayHours, now: now),
      const SizedBox(height: 12),
      _ForecastCard(hours: w.hourly, days: w.daily),
      const SizedBox(height: 20),

      // Payo
      SectionTitle(icon: Icons.tips_and_updates_rounded, text: t.adviceTitle, subtitle: t.adviceSubtitle),
      ...cropAdvice.map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _CropAdviceCard(a: a))),
      ...p.advice.map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _AdviceCard(a: a))),
      const SizedBox(height: 10),

      const SizedBox(height: 24),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Pagbati
// ---------------------------------------------------------------------------

class _GreetingHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String initial;
  const _GreetingHeader({required this.title, required this.subtitle, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mint,
          border: Border.all(color: AppColors.leaf, width: 2),
        ),
        child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.leaf)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ]),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Panahon (compact)
// ---------------------------------------------------------------------------

class _WeatherCard extends StatelessWidget {
  final WeatherBundle w;
  final DateTime? updated;
  final bool stale;
  final String place;

  const _WeatherCard({required this.w, required this.updated, required this.stale, required this.place});

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

class _OverviewTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget value;
  final String sub;
  final Color subColor;

  const _OverviewTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.sub,
    required this.subColor,
    this.iconColor = AppColors.leaf,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
            const SizedBox(height: 4),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: subColor)),
          ]),
        ),
        const SizedBox(width: 8),
        IconBubble(icon: icon, color: iconColor, size: 38),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Heat index
// ---------------------------------------------------------------------------

class _HeatIndexCard extends StatelessWidget {
  final HeatIndex heat;
  final List<HourlyWeather> todayHours;
  final DateTime now;
  const _HeatIndexCard({required this.heat, required this.todayHours, required this.now});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = heatColor(heat.level);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.device_thermostat_rounded, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(t.heatIndex, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Text(t.heatLevelName(heat.level), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color)),
          ),
        ]),
        const SizedBox(height: 2),
        Text(t.heatIndexSub, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CountUp(
            value: heat.celsius,
            suffix: '°C',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, height: 1.0),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(t.heatLevelAdvice(heat.level), style: const TextStyle(fontSize: 13, height: 1.35))),
        ]),
        const SizedBox(height: 12),
        _HeatScale(value: heat.celsius),
        if (todayHours.length >= 2) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          HeatGraph(hours: todayHours, now: now),
        ],
        const SizedBox(height: 8),
        Text(t.heatScaleSource, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.3)),
      ]),
    );
  }
}

/// Kulay na scale na may marker sa kasalukuyang heat index.
class _HeatScale extends StatelessWidget {
  final double value;
  const _HeatScale({required this.value});

  static const _min = 24.0;
  static const _max = 56.0;
  static const _stops = [27.0, 33.0, 42.0, 52.0];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      double x(double v) => (math.min(math.max(v, _min), _max) - _min) / (_max - _min) * w;

      Widget seg(HeatLevel l, int flex) => Expanded(flex: flex, child: Container(color: heatColor(l)));

      return SizedBox(
        height: 40,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(children: [
                seg(HeatLevel.normal, 3),
                seg(HeatLevel.caution, 6),
                seg(HeatLevel.extremeCaution, 9),
                seg(HeatLevel.danger, 10),
                seg(HeatLevel.extremeDanger, 4),
              ]),
            ),
          ),
          for (final s in _stops)
            Positioned(
              left: x(s) - 12,
              top: 22,
              width: 24,
              child: Text('${s.toInt()}',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: _min, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Positioned(
              left: x(v) - 8,
              top: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 3),
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

class _ForecastCard extends StatefulWidget {
  final List<HourlyWeather> hours;
  final List<WeatherDay> days;
  const _ForecastCard({required this.hours, required this.days});

  @override
  State<_ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<_ForecastCard> {
  bool _week = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final Widget list = _week
        ? ListView.separated(
      key: const ValueKey('week'),
      scrollDirection: Axis.horizontal,
      itemCount: widget.days.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => _DayItem(day: widget.days[i], isToday: i == 0, locale: locale, todayLabel: t.today),
    )
        : ListView.separated(
      key: const ValueKey('hours'),
      scrollDirection: Axis.horizontal,
      itemCount: widget.hours.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
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
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: false, label: Text(t.hourlyTab)),
              ButtonSegment(value: true, label: Text(t.weeklyTab)),
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

class _AdviceCard extends StatelessWidget {
  final FarmAdvice a;
  const _AdviceCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBubble(icon: a.icon, color: a.color, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.farmAdviceTitle(a.type), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 2),
            Text(t.farmAdviceMessage(a.type), style: const TextStyle(height: 1.35, color: AppColors.muted)),
          ]),
        ),
      ]),
    );
  }
}

class _CropAdviceCard extends StatelessWidget {
  final CropAdvice a;
  const _CropAdviceCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final name = t.cropLabel(a.crop);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBubble(icon: a.icon, color: a.color, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.cropAdviceTitle(a, name), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 2),
            Text(t.cropAdviceMessage(a, name), style: const TextStyle(height: 1.35, color: AppColors.muted)),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Animations
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