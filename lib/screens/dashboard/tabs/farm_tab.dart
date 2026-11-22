import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/dss_catalog.dart';
import '../../../core/tr.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farmer.dart' hide FarmRecord;
import '../../../models/farm_record.dart';
import '../../../models/farm_store.dart';
import '../../../models/pagsanjan_boundary.dart';
import '../../../services/account_service.dart';
import '../../../services/crop_calendar.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/crop_calendar_card.dart';
import '../../../widgets/crop_photo.dart';
import '../../../widgets/crop_switcher.dart';
import '../../../widgets/farm_polygon_map.dart';
import '../../../widgets/harvest_weather_strip.dart';

/// Aking Bukid: view lang. Mapa ng bukid (iginuhit sa DSS), uri ng lupa, pananim at panahon hanggang anihan.
class FarmTab extends StatefulWidget {
  final DashboardProvider p;
  const FarmTab({super.key, required this.p});

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  final _store = FarmStore.instance;
  late final Future<PagsanjanBoundary?> _boundary = PagsanjanBoundary.load();
  int _sec = 0; // 0 yugto, 1 panahon, 2 gamit ng lupa

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _store, builder: (context, _) => _content(context));
  }

  Widget _content(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final farm = _store.current;

    final accountService = Provider.of<AccountService>(context, listen: false);
    final farmerUsername = widget.p.currentUsername ?? '';
    final farmer = accountService.farmers.firstWhere(
      (f) => f.username.toLowerCase() == farmerUsername.toLowerCase(),
      orElse: () => Farmer(id: '', username: farmerUsername, password: '', profileName: 'Farmer', barangay: 'Biñan'),
    );

    final dynamic supabaseFarm = accountService.farms.cast<dynamic>().firstWhere(
      (f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName,
      orElse: () => null,
    );

    final ha = farm.areaHa;
    final name = dssCropName(farm.crop, tl) + (farm.variety != null ? ' (${farm.variety})' : '');

    return AnimatedTabList(items: [
      TabHeader(
        title: t.navFarm,
        subtitle: tr(context, 'Mapa at kalagayan ng inyong sakahan', 'Map and condition of your farm'),
      ),
      const SizedBox(height: 12),
      FutureBuilder<PagsanjanBoundary?>(
        future: _boundary,
        builder: (context, bs) => FarmPolygonMap(
          farm: farm,
          outerLandBoundary: (supabaseFarm != null && supabaseFarm.boundaryPoints != null && supabaseFarm.boundaryPoints.isNotEmpty) ? supabaseFarm.boundaryPoints : farm.polygon,
          boundary: bs.data,
        ),
      ),
      const SizedBox(height: 14),

      const CropSwitcher(),
      // Pananim at uri ng lupa (galing sa DSS; view lang dito)
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 48, height: 48, child: CropPhoto(cropId: farm.crop, emojiSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr(context, 'Pananim', 'Crop'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w800)),
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text(t.plantedOn(farm.plantedOn), style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ]),
            ),
            if (farm.stage != null) Pill(stageLabel(farm.stage!, tl), AppColors.leaf),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.terrain_rounded,
                label: tr(context, 'Uri ng lupa', 'Soil type'),
                value: farm.soil == null ? tr(context, 'Hindi pa napili', 'Not chosen yet') : soilName(farm.soil!, tl),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                icon: Icons.landscape_rounded,
                label: t.landSize,
                value: '${ha.toStringAsFixed(2)} ha',
              ),
            ),
          ]),
          if (farm.isSample) ...[
            const SizedBox(height: 10),
            Text(
              tr(context, 'Halimbawa pa lang ito. Ilagay ang inyong bukid sa DSS para mapalitan.',
                  'This is only a sample. Enter your farm in DSS to replace it.'),
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 14),

      // Mga seksyon (isa lang ang nakikita sa bawat pagkakataon)
      _sectionChips(context),
      const SizedBox(height: 12),
      _sectionBody(context, farm, t, locale),
      const SizedBox(height: 24),
    ]);
  }

  Widget _sectionChips(BuildContext context) {
    final items = [
      (Icons.timeline_rounded, tr(context, 'Yugto', 'Stages')),
      (Icons.cloud_rounded, tr(context, 'Panahon', 'Weather')),
      (Icons.pie_chart_rounded, tr(context, 'Gamit ng lupa', 'Land use')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(items[i].$1, size: 18, color: _sec == i ? const Color(0xFF166534) : const Color(0xFF0F172A)),
              label: Text(
                items[i].$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _sec == i ? const Color(0xFF166534) : const Color(0xFF0F172A),
                ),
              ),
              selected: _sec == i,
              showCheckmark: false,
              selectedColor: const Color(0xFFDCFCE7),
              backgroundColor: const Color(0xFFF0FDF4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _sec == i ? const Color(0xFF166534) : const Color(0xFF86EFAC),
                  width: 1.5,
                ),
              ),
              onSelected: (_) => setState(() => _sec = i),
            ),
          ),
      ]),
    );
  }

  Widget _sectionBody(BuildContext context, FarmRecord farm, AppLocalizations t, String locale) {
    switch (_sec) {
      case 0:
        final prof = _store.profile;
        if (prof == null) {
          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Text(tr(context, 'Magdagdag ng tanim sa DSS para lumabas dito ang mga yugto at petsa.', 'Add a crop in DSS to see its stages and dates here.'),
                style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.35)),
          );
        }
        final w = widget.p.weather;
        return CropCalendarCard(
          profile: prof,
          rain: w == null ? null : {for (final d in w.daily) dayOnly(d.date): DayRain(d.rainMm, d.rainChance)},
        );
      case 1:
        return GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: HarvestWeatherStrip(
            plantedOn: farm.plantedOn,
            harvestFrom: farm.harvestFrom,
            harvestTo: farm.harvestTo,
            lat: farm.center.latitude,
            lon: farm.center.longitude,
            title: t.farmWxTitle,
            bare: true,
            summary: [
              t.plantedOn(farm.plantedOn),
              if (farm.totalDays != null) t.farmDaysGrown(farm.daysGrown, farm.totalDays!),
              if (farm.harvestFrom != null && farm.harvestTo != null)
                t.farmExpectedHarvest('${DateFormat.MMMd(locale).format(farm.harvestFrom!)} - ${DateFormat.MMMd(locale).format(farm.harvestTo!)}'),
            ].join('\n'),
          ),
        );
      default:
        return _LandUseCard(store: _store);
    }
  }
}

/// Gamit ng lupa: lawak ng bawat tanim kumpara sa kabuuang lupa.
class _LandUseCard extends StatelessWidget {
  final FarmStore store;
  const _LandUseCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final profiles = store.profiles;
    final total = store.totalHa;
    final used = store.usedHa();
    final base = (total != null && total > 0) ? total : (used > 0 ? used : 1.0);
    final left = total == null ? null : (total - used);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pie_chart_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(tr(context, 'Gamit ng lupa', 'Land use'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
          Text(total == null ? '${used.toStringAsFixed(2)} ha' : '${used.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} ha',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
        ]),
        const SizedBox(height: 12),
        if (profiles.isEmpty)
          Text(tr(context, 'Wala pang tanim. Magdagdag sa DSS.', 'No crops yet. Add one in DSS.'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted))
        else
          for (final p in profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 38, height: 38, child: CropPhoto(cropId: p.crop, emojiSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(dssCropName(p.crop, tl), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800))),
                      Text('${p.areaHa.toStringAsFixed(2)} ha', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (p.areaHa / base).clamp(0.0, 1.0),
                        minHeight: 7,
                        color: AppColors.leaf,
                        backgroundColor: AppColors.leaf.withValues(alpha: 0.14),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
        if (left != null) ...[
          const Divider(height: 18),
          Row(children: [
            Icon(left < -0.01 ? Icons.warning_amber_rounded : Icons.landscape_rounded, size: 18, color: left < -0.01 ? const Color(0xFFC0503E) : AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                left < -0.01
                    ? tr(context, 'Lampas ng ${(-left).toStringAsFixed(2)} ha sa kabuuang lupa.', 'Over the total land by ${(-left).toStringAsFixed(2)} ha.')
                    : tr(context, 'Natitirang lupa: ${left.toStringAsFixed(2)} ha', 'Land left: ${left.toStringAsFixed(2)} ha'),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: AppColors.leaf),
          const SizedBox(width: 5),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ]),
    );
  }
}