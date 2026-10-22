import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/crop_l10n.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_planting.dart';
import '../../../models/price_insight.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../services/price_insight_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/crop_image.dart';
import '../../../widgets/price_graph.dart';

class PricesTab extends StatefulWidget {
  final DashboardProvider p;
  const PricesTab({super.key, required this.p});

  @override
  State<PricesTab> createState() => _PricesTabState();
}

class _PricesTabState extends State<PricesTab> {
  PlantingGuide? _guideFor(String crop) {
    for (final g in widget.p.guides) {
      if (g.crop == crop) return g;
    }
    return null;
  }

  /// Huling ani (kg) na inilagay ng magsasaka sa DSS para sa pananim na ito.
  double? _lastHarvestKg(FarmInputProvider farm, String crop) {
    FarmPlanting? best;
    for (final e in farm.plantings) {
      if (e.crop != crop || e.lastYieldKg == null || e.lastYieldKg! <= 0) continue;
      if (best == null || e.plantedOn.isAfter(best.plantedOn)) best = e;
    }
    return best?.lastYieldKg;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final p = widget.p;
    final farm = context.watch<FarmInputProvider>();

    final crops = farm.cropIds;
    final insights = PriceInsightService().build(crops: crops, days: p.forecast, guides: p.guides);

    final rising = insights.where((i) => i.changePercent >= 0).length;
    final falling = insights.length - rising;

    return AnimatedTabList(items: [
      TabHeader(title: t.cropPrices, subtitle: t.pricesSubtitle),
      const SizedBox(height: 12),
      if (insights.isNotEmpty)
        Row(children: [
          Expanded(
            child: _SummaryTile(
              icon: Icons.trending_up_rounded,
              color: AppColors.up,
              value: '$rising',
              label: t.priceRising,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              icon: Icons.trending_down_rounded,
              color: AppColors.down,
              value: '$falling',
              label: t.priceFalling,
            ),
          ),
        ]),
      if (insights.isNotEmpty) const SizedBox(height: 12),
      if (insights.isEmpty) Text(crops.isEmpty ? t.priceNoMyCrops : t.noPriceData, style: const TextStyle(color: AppColors.muted, height: 1.4)),
      ...insights.map((i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _PriceCard(insight: i, guide: _guideFor(i.crop), lastHarvest: _lastHarvestKg(farm, i.crop)),
      )),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(t.priceDisclaimer, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35))),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _SummaryTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final PriceInsight insight;
  final PlantingGuide? guide;
  final double? lastHarvest;
  const _PriceCard({required this.insight, required this.guide, required this.lastHarvest});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final i = insight;
    final up = i.changePercent >= 0;
    final color = up ? AppColors.up : AppColors.down;
    final nf = NumberFormat('#,###');
    final today = DateTime.now();

    String dayLabel(int idx) => idx == 0 ? t.now : DateFormat('E', locale).format(today.add(Duration(days: idx)));
    final labels = [for (var k = 0; k < i.series.length; k++) dayLabel(k)];
    final best = i.bestIndex;

    final sellTip = i.changePercent >= 5 ? t.sellWait : (i.changePercent >= 0 ? t.sellSlight : t.sellSoon);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Pangalan at pagbabago
          Row(children: [
            if (guide != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 44, height: 44, child: CropImage(guide: guide!)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(t.cropLabel(i.crop), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            Pill('${up ? '+' : ''}${i.changePercent.toStringAsFixed(1)}%', color,
                icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded),
          ]),
          const SizedBox(height: 12),

          // Ngayon -> Inaasahan
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.now, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              Text('₱${i.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Icon(Icons.arrow_forward_rounded, color: AppColors.muted)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.expected, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: i.currentPrice, end: i.predictedPrice),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text('₱${v.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
              ),
            ]),
          ]),
          const SizedBox(height: 14),

          // Line graph
          Text(t.priceGraphTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 6),
          if (i.series.length >= 2) PriceGraph(values: i.series, labels: labels, color: color),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.swap_vert_rounded,
            text: '${t.priceRange}: ₱${i.minPrice.toStringAsFixed(2)} - ₱${i.maxPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.star_rounded,
            text: '${t.priceHighest}: ${dayLabel(best)} • ₱${i.series[best].toStringAsFixed(2)}',
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bakit nagbabago ang presyo
          Text(t.priceWhyTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 8),
          ...i.factors.map((f) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _FactorRow(insight: i, factor: f))),

          // Halaga ng huling ani
          if (lastHarvest != null) ...[
            const SizedBox(height: 2),
            _InfoRow(
              icon: Icons.payments_rounded,
              text: t.priceLastHarvestValue(
                nf.format(lastHarvest!),
                nf.format(lastHarvest! * i.predictedPrice),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Payo sa pagbebenta
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.sun, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(sellTip, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final PriceInsight insight;
  final PriceFactor factor;
  const _FactorRow({required this.insight, required this.factor});

  String _title(AppLocalizations t) {
    switch (factor.kind) {
      case PriceFactorKind.rain:
        return t.priceFactorRain;
      case PriceFactorKind.heat:
        return t.priceFactorHeat;
      case PriceFactorKind.season:
        return t.priceFactorSeason;
    }
  }

  IconData get _icon {
    switch (factor.kind) {
      case PriceFactorKind.rain:
        return Icons.water_drop_rounded;
      case PriceFactorKind.heat:
        return Icons.device_thermostat_rounded;
      case PriceFactorKind.season:
        return Icons.calendar_month_rounded;
    }
  }

  String _text(AppLocalizations t) {
    switch (factor.kase) {
      case PriceCase.rainHeavy:
        return t.priceRainHeavy(insight.rainTotalMm.round().toString());
      case PriceCase.rainDry:
        return t.priceRainDry(insight.rainTotalMm.round().toString());
      case PriceCase.rainNormal:
        return t.priceRainNormal(insight.rainTotalMm.round().toString());
      case PriceCase.heatHigh:
        return t.priceHeatHigh(insight.maxHeatIndex.round().toString());
      case PriceCase.heatNormal:
        return t.priceHeatNormal;
      case PriceCase.seasonPeak:
        return t.priceSeasonPeak;
      case PriceCase.seasonOff:
        return t.priceSeasonOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final pct = factor.pct;
    final neutral = pct.abs() < 0.05;
    final color = neutral ? AppColors.muted : (pct > 0 ? AppColors.up : AppColors.down);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
        child: Icon(_icon, size: 18, color: AppColors.leaf),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title(t), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 1),
          Text(_text(t), style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.35)),
        ]),
      ),
      const SizedBox(width: 8),
      Text(
        neutral ? '0.0%' : '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppColors.soil),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
    ]);
  }
}