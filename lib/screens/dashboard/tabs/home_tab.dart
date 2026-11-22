import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/dss_catalog.dart';
import '../../../core/tr.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_record.dart';
import '../../../models/farm_store.dart';
import '../../../services/crop_calendar.dart';
import '../../../services/dss_planner.dart';
import '../../../services/soil_moisture_service.dart';
import '../../../services/weather_alert_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/crop_calendar_card.dart';
import '../../../widgets/crop_photo.dart';
import '../../../widgets/crop_switcher.dart';
import '../../../widgets/harvest_weather_strip.dart';
import '../../../widgets/weather_sections.dart';

/// Home: pagbati, mabilis na kalagayan (panahon at lupa), kasalukuyang tanim, at mga pananim.
class HomeTab extends StatefulWidget {
  final DashboardProvider p;
  final VoidCallback? onOpenDss;
  const HomeTab({super.key, required this.p, this.onOpenDss});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  FarmRecord get _farm => FarmStore.instance.current;
  late final Future<SoilMoisture?> _soil = SoilMoistureService().fetch(_farm.center.latitude, _farm.center.longitude);
  late final Future<List<AdminAdvisory>> _admin = AdvisoryRepository().fetch();

  @override
  void initState() {
    super.initState();
    FarmStore.instance.addListener(_onFarm);
    FarmStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onFarm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FarmStore.instance.removeListener(_onFarm);
    super.dispose();
  }

  String _greeting(AppLocalizations t) {
    final h = DateTime.now().hour;
    if (h < 12) return t.greetingMorning;
    if (h < 18) return t.greetingAfternoon;
    return t.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = widget.p;
    final w = p.weather!;
    final profile = p.profile!;
    final firstName = profile.name.split(' ').first;

    final farm = _farm;

    final rain = {for (final d in w.daily) dayOnly(d.date): DayRain(d.rainMm, d.rainChance)};

    return AnimatedTabList(items: [
      _Greeting(
        title: '${_greeting(t)}, $firstName!',
        place: '${profile.barangay}, Pagsanjan, Laguna',
        initial: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
      ),
      const SizedBox(height: 14),

      // NGAYON: babala at mga gawain
      AlertSection(alerts: WeatherAlertService().fromForecast(w), admin: _admin),
      const SizedBox(height: 12),
      ReminderSummaryCard(maxItems: 3, rain: rain),
      WeatherCard(w: w, updated: p.lastUpdated, stale: p.weatherStale, place: profile.barangay),
      const SizedBox(height: 16),

      // TANIM KO
      SectionTitle(icon: Icons.agriculture_rounded, text: tr(context, 'Tanim ko', 'My crop')),
      const CropSwitcher(),
      FutureBuilder<SoilMoisture?>(
        future: _soil,
        builder: (context, snap) {
          final loading = snap.connectionState != ConnectionState.done;
          if (farm.isSample) {
            return Column(children: [
              _EmptyCropCard(onOpenDss: widget.onOpenDss),
              const SizedBox(height: 12),
              _FieldStatus(w: w, soil: snap.data, soilLoading: loading, farm: farm),
            ]);
          }
          return _ActiveCropCard(
            farm: farm,
            onOpenDss: widget.onOpenDss,
            field: _FieldStatus(w: w, soil: snap.data, soilLoading: loading, farm: farm, bare: true),
          );
        },
      ),
      const SizedBox(height: 16),

      // PANAHON
      SectionTitle(icon: Icons.cloud_rounded, text: tr(context, 'Panahon', 'Weather')),
      _WeatherPanel(
        w: w,
        outlook: GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: HarvestWeatherStrip.outlook(
            lat: farm.center.latitude,
            lon: farm.center.longitude,
            title: t.weatherOutlookTitle,
            summary: t.weatherOutlookSub,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

/// Mga chip para sa detalye ng panahon: isa lang ang nakikita sa bawat pagkakataon.
class _WeatherPanel extends StatefulWidget {
  final WeatherBundle w;
  final Widget outlook;
  const _WeatherPanel({required this.w, required this.outlook});

  @override
  State<_WeatherPanel> createState() => _WeatherPanelState();
}

class _WeatherPanelState extends State<_WeatherPanel> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.insights_rounded, tr(context, 'Forecast', 'Forecast')),
      (Icons.thermostat_rounded, tr(context, 'Init', 'Heat')),
      (Icons.date_range_rounded, tr(context, 'Outlook', 'Outlook')),
    ];
    final w = widget.w;
    final Widget body = _i == 0
        ? ForecastCard(hours: w.hourly, days: w.daily)
        : _i == 1
        ? HeatIndexCard(heat: w.current.heat)
        : widget.outlook;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var k = 0; k < items.length; k++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _i = k),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _i == k ? const Color(0xFF166534) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _i == k ? const Color(0xFF166534) : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: _i == k
                        ? [BoxShadow(color: const Color(0xFF166534).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                        : const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[k].$1, size: 16, color: _i == k ? Colors.white : const Color(0xFF166534)),
                      const SizedBox(width: 6),
                      Text(
                        items[k].$2,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: _i == k ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(_i), child: body)),
    ]);
  }
}

/// Kapag wala pang tanim ang farmer: malinaw na paanyayang magsimula.
class _EmptyCropCard extends StatelessWidget {
  final VoidCallback? onOpenDss;
  const _EmptyCropCard({this.onOpenDss});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: const Icon(Icons.eco_rounded, color: AppColors.leaf, size: 30),
        ),
        const SizedBox(height: 12),
        Text(tr(context, 'Wala ka pang tanim', 'No crop yet'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text(
          tr(context, 'Magdagdag ng tanim sa DSS para makita rito ang yugto, anihan, at mga paalala.',
              'Add a crop in DSS to see its stage, harvest and reminders here.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOpenDss,
            style: FilledButton.styleFrom(backgroundColor: AppColors.leaf, padding: const EdgeInsets.symmetric(vertical: 13)),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr(context, 'Magsimula: magdagdag ng tanim', 'Get started: add a crop')),
          ),
        ),
      ]),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String title;
  final String place;
  final String initial;
  const _Greeting({required this.title, required this.place, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mint,
          border: Border.all(color: AppColors.leaf, width: 2),
        ),
        child: Text(initial, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.leaf)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.leaf),
            const SizedBox(width: 3),
            Expanded(child: Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
          ]),
        ]),
      ),
    ]);
  }
}

String _rainLabel(double mm, bool tl) {
  if (mm < 1) return tl ? 'Walang ulan' : 'No rain';
  if (mm < 10) return tl ? 'Mahinang ulan' : 'Light rain';
  if (mm < 30) return tl ? 'Katamtamang ulan' : 'Moderate rain';
  if (mm < 60) return tl ? 'Malakas na ulan' : 'Heavy rain';
  return tl ? 'Napakalakas na ulan' : 'Very heavy rain';
}

class _FieldStatus extends StatelessWidget {
  final WeatherBundle w;
  final SoilMoisture? soil;
  final bool soilLoading;
  final FarmRecord farm;
  final bool bare;
  const _FieldStatus({required this.w, required this.soil, required this.soilLoading, required this.farm, this.bare = false});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final today = w.daily.first;

    final isRice = farm.crop == 'Rice';
    String? soilNote;
    if (soil != null && isRice) {
      soilNote = soil!.value >= 0.30
          ? (tl ? 'Sapat ang halumigmig ng lupa para sa palay.' : 'Soil moisture is enough for rice.')
          : (tl ? 'Kulang ang halumigmig ng lupa para sa palay; tingnan ang patubig.' : 'Soil moisture is low for rice; check irrigation.');
    }

    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr(context, 'Kalagayan ng bukid ngayon', 'Field conditions today'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.muted)),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: _StatTile(
            icon: Icons.water_drop_rounded,
            color: AppColors.rain,
            label: tr(context, 'Ulan ngayon', 'Rain today'),
            value: '${today.rainMm.toStringAsFixed(today.rainMm < 10 ? 1 : 0)} mm',
            sub: _rainLabel(today.rainMm, tl),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.grass_rounded,
            color: AppColors.fern,
            label: tr(context, 'Halumigmig ng lupa', 'Soil moisture'),
            value: soil != null ? '${soil!.percent}%' : (soilLoading ? '...' : '--'),
            sub: soil != null ? soilLabel(soil!.level, tl) : (soilLoading ? tr(context, 'Kinukuha', 'Loading') : tr(context, 'Walang datos', 'No data')),
          ),
        ),
      ]),
      if (soilNote != null) ...[
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(soilNote, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3))),
        ]),
      ],
    ]);
    if (bare) return content;
    return GlassCard(padding: const EdgeInsets.all(14), child: content);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;
  const _StatTile({required this.icon, required this.color, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted))),
        ]),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink))),
        const SizedBox(height: 2),
        Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, height: 1.2)),
      ]),
    );
  }
}

class _ActiveCropCard extends StatelessWidget {
  final FarmRecord farm;
  final VoidCallback? onOpenDss;
  final Widget? field;
  const _ActiveCropCard({required this.farm, this.onOpenDss, this.field});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final stage = farm.stage;
    final progress = farm.progress;
    final total = farm.totalDays;
    final mid = farm.harvestMid;
    final name = dssCropName(farm.crop, tl) + (farm.variety != null ? ' (${farm.variety})' : '');
    final prof = FarmStore.instance.profile;
    final dc = dssCropFor(farm.crop);
    final plan = (prof != null && dc != null && prof.areaHa > 0)
        ? DssPlan.build(crop: dc, soil: prof.soil, areaHa: prof.areaHa, plantedOn: prof.plantedOn, harvestOn: prof.harvestOn, userPrice: prof.price)
        : null;
    final nf = NumberFormat.decimalPattern(locale);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(tr(context, 'Kasalukuyang tanim', 'Current crop'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.muted)),
          ),
          if (farm.isSample) const _SampleTag(),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 68, height: 68, child: CropPhoto(cropId: farm.crop, emojiSize: 34)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 6),
              if (stage != null) Pill(stageLabel(stage, tl), AppColors.leaf, icon: Icons.spa_rounded),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        if (progress != null && total != null) ...[
          Row(children: [
            Expanded(
              child: Text(
                tl ? '${farm.daysGrown} araw mula nang itanim' : '${farm.daysGrown} days since planting',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            Text(tl ? 'ng ~$total araw' : 'of ~$total days', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: AppColors.leaf.withValues(alpha: 0.14),
                valueColor: const AlwaysStoppedAnimation(AppColors.leaf),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _InfoLine(
          icon: Icons.event_available_rounded,
          label: tr(context, 'Estima ng anihan', 'Estimated harvest'),
          value: mid != null ? DateFormat.yMMMM(locale).format(mid) : (plan?.perennial == true ? (plan!.bearing ? tr(context, 'Namumunga na', 'Already bearing') : DateFormat.yMMMM(locale).format(plan.firstHarvest!)) : tr(context, 'Buong taon', 'Year-round')),
        ),
        const SizedBox(height: 14),
        if (field != null) ...[
          const Divider(height: 1),
          const SizedBox(height: 12),
          field!,
          const SizedBox(height: 14),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.satellite_alt_rounded, size: 20, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan != null ? tr(context, 'Tantiyang ani (DSS)', 'Estimated yield (DSS)') : tr(context, 'Pagtantiya ng ani', 'Yield prediction'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(
                    plan != null
                        ? '${nf.format(plan.yMid.round())} ${plan.unit == 'pc' ? tr(context, 'niyog', 'nuts') : 'kg'}'
                        : tr(context, 'Wala pang datos', 'No data yet'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  plan != null
                      ? tr(context, 'Batay sa lawak at karaniwang ani. Hindi pa kasama ang satellite.',
                      'Based on land size and typical yield. Satellite is not included yet.')
                      : tr(context, 'Ilagay ang inyong bukid sa DSS para lumabas ang tantiya.', 'Enter your farm in DSS to see an estimate.'),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
                ),
              ]),
            ),
          ]),
        ),
        if (farm.isSample && onOpenDss != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onOpenDss,
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: Text(tr(context, 'Ilagay ang aking bukid sa DSS', 'Enter my farm in DSS')),
            ),
          ),
        ],
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoLine({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.leaf),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w700))),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
    ]);
  }
}

class _SampleTag extends StatelessWidget {
  const _SampleTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: const Text('SAMPLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFFB45309))),
    );
  }
}