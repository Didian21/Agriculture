import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/crop_data.dart';
import '../../../core/crop_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_planting.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../services/dss_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/dss_common.dart';
import '../../../widgets/planting_graph.dart';
import '../dss/farm_map_card.dart';
import '../dss/planting_form_sheet.dart';
import '../dss/total_land_sheet.dart';

/// DSS: inilalagay ng magsasaka ang tanim niya, at ang payo ay ayon doon.
class DssTab extends StatelessWidget {
  const DssTab({super.key});

  Future<void> _add(BuildContext context, FarmInputProvider input) async {
    final r = await showPlantingForm(context);
    if (r != null) input.add(r);
  }

  Future<void> _edit(BuildContext context, FarmInputProvider input, FarmPlanting p) async {
    final r = await showPlantingForm(context, existing: p);
    if (r != null) input.update(r);
  }

  Future<void> _delete(BuildContext context, FarmInputProvider input, FarmPlanting p) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.dssDeleteTitle),
        content: Text(t.dssDeleteBody(t.cropLabel(p.crop))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.dssDelete)),
        ],
      ),
    );
    if (ok == true) input.remove(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final input = context.watch<FarmInputProvider>();
    final sel = input.selected;

    return AnimatedTabList(items: [
      TabHeader(title: t.dssMyTitle, subtitle: t.dssMySubtitle),
      const SizedBox(height: 12),
      _LandCard(input: input),
      const SizedBox(height: 12),
      _InputCard(
        input: input,
        onAdd: () => _add(context, input),
        onEdit: (p) => _edit(context, input, p),
        onDelete: (p) => _delete(context, input, p),
      ),
      if (sel != null) ...[
        const SizedBox(height: 18),
        SectionTitle(icon: Icons.event_available_rounded, text: t.dssPlantingAdvisory, subtitle: t.dssPlantingAdvisorySub),
        const SizedBox(height: 10),
        _PlantingAdvisory(planting: sel),
        const SizedBox(height: 18),
        SectionTitle(icon: Icons.agriculture_rounded, text: t.dssHarvestIncome, subtitle: t.dssHarvestIncomeSub),
        const SizedBox(height: 10),
        _HarvestIncome(planting: sel),
        const SizedBox(height: 18),
        SectionTitle(icon: Icons.sell_rounded, text: t.dssPriceAdvisory, subtitle: t.dssPriceAdvisorySub),
        const SizedBox(height: 10),
        _PriceAdvisory(planting: sel),
      ],
      const SizedBox(height: 18),
      SectionTitle(icon: Icons.map_rounded, text: t.dssFarmMap, subtitle: t.dssFarmMapSub),
      const SizedBox(height: 10),
      FarmMapCard(input: input),
      const SizedBox(height: 14),
      Text(t.dssMyDisclaimer, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4)),
      const SizedBox(height: 90),
    ]);
  }
}

// ───────────────────────── Kabuuang lupa ─────────────────────────

/// Kabuuang sukat ng lupa ng farmer, kung ilan na ang nahati sa mga pananim, at ang natitira.
class _LandCard extends StatelessWidget {
  final FarmInputProvider input;
  const _LandCard({required this.input});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sqm = input.useSqm;
    final total = input.totalHectares;
    final used = input.usedHectares;
    final rem = input.remainingHectares();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.landscape_rounded, color: AppColors.leaf),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.dssTotalLand,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              TextButton.icon(
                onPressed: () => showTotalLandSheet(context),
                icon: Icon(total == null ? Icons.add_rounded : Icons.edit_rounded, size: 18),
                label: Text(total == null ? t.dssLandSet : t.edit),
              ),
            ],
          ),
          if (total == null)
            Text(t.dssLandNotSet, style: const TextStyle(color: AppColors.muted, height: 1.35))
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(DssFmt.area(total, sqm: sqm),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.leaf)),
                ),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: [
                    ButtonSegment(value: false, label: Text(t.dssUnitHa)),
                    ButtonSegment(value: true, label: Text(t.dssUnitSqm)),
                  ],
                  selected: {sqm},
                  onSelectionChanged: (s) => input.setUseSqm(s.first),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final p in input.plantings)
                      Expanded(
                        flex: (p.hectares * 100000).round().clamp(1, 100000000),
                        child: Container(color: AppColors.forCrop(p.crop)),
                      ),
                    Expanded(
                      flex: ((rem ?? 0) * 100000).round().clamp(0, 100000000),
                      child: Container(color: AppColors.mint),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(t.dssLandUsed(DssFmt.area(used, sqm: sqm)),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                Text(t.dssRemaining(DssFmt.area(rem ?? 0, sqm: sqm)),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.leaf)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Input ─────────────────────────

class _InputCard extends StatelessWidget {
  final FarmInputProvider input;
  final VoidCallback onAdd;
  final void Function(FarmPlanting) onEdit;
  final void Function(FarmPlanting) onDelete;

  const _InputCard({required this.input, required this.onAdd, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final list = input.plantings;
    final sel = input.selected;

    if (list.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const IconBubble(icon: Icons.edit_note_rounded, size: 54),
            const SizedBox(height: 12),
            Text(t.dssEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(t.dssEmptyBody, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(t.dssAddPlanting)),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.dssMyPlantings,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 18), label: Text(t.dssAdd)),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in list)
                ChoiceChip(
                  label: Text('${t.cropLabel(p.crop)} · ${DssFmt.area(p.hectares, sqm: input.useSqm)}'),
                  selected: sel?.id == p.id,
                  onSelected: (_) => input.select(p.id),
                ),
            ],
          ),
          if (sel != null) ...[
            const SizedBox(height: 12),
            _SelectedSummary(p: sel, sqm: input.useSqm),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => onEdit(sel),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(t.edit),
                ),
                TextButton.icon(
                  onPressed: () => onDelete(sel),
                  style: TextButton.styleFrom(foregroundColor: AppColors.down),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(t.dssDelete),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  final FarmPlanting p;
  final bool sqm;
  const _SelectedSummary({required this.p, required this.sqm});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final grown = DateTime.now().difference(p.plantedOn).inDays;
    final est = DssService.estimate(p);
    final harvest = (est?.harvestFrom != null && est?.harvestTo != null)
        ? '${DssFmt.date(est!.harvestFrom!)} – ${DssFmt.date(est.harvestTo!)}'
        : t.dssHarvestYearRound;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _row(Icons.square_foot_rounded, t.dssLandSize, DssFmt.area(p.hectares, sqm: sqm)),
          const SizedBox(height: 6),
          _row(Icons.event_rounded, t.dssPlantedOn, DssFmt.date(p.plantedOn)),
          const SizedBox(height: 6),
          _row(Icons.timelapse_rounded, t.dssDaysGrown, grown < 0 ? t.dssNotYet : t.dssDaysCount(grown)),
          const SizedBox(height: 6),
          _row(Icons.agriculture_rounded, t.dssExpectedHarvest, harvest),
        ],
      ),
    );
  }

  Widget _row(IconData i, String k, String v) => Row(
    children: [
      Icon(i, size: 18, color: AppColors.leaf),
      const SizedBox(width: 8),
      Expanded(child: Text(k, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
    ],
  );
}

// ───────────────────────── 1. Planting advisory ─────────────────────────

Color _fitColor(PlantFit f) => fitColorOf(f);

String _fitLabel(AppLocalizations t, PlantFit f) => switch (f) {
  PlantFit.best => t.dssLegendBest,
  PlantFit.possible => t.dssLegendPossible,
  PlantFit.avoid => t.dssLegendAvoid,
};

class _PlantingAdvisory extends StatelessWidget {
  final FarmPlanting planting;
  const _PlantingAdvisory({required this.planting});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final crop = planting.crop;
    final now = DateTime.now().month;
    final fit = DssService.fitFor(crop, now);
    final next = DssService.nextBestMonths(crop, now, count: 2);
    final facts = factsFor(crop)!;

    final headline = switch (fit) {
      PlantFit.best => t.dssFitBest(t.cropLabel(crop)),
      PlantFit.possible => t.dssFitPossible(t.cropLabel(crop)),
      PlantFit.avoid => t.dssFitAvoid(t.cropLabel(crop)),
    };

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fit == PlantFit.best ? Icons.check_circle_rounded : (fit == PlantFit.possible ? Icons.info_rounded : Icons.error_outline_rounded),
                color: _fitColor(fit),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(headline, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink))),
            ],
          ),
          const SizedBox(height: 4),
          Text(t.cropAbout(crop), style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.35)),
          const SizedBox(height: 12),
          PlantingGraph(
            crop: crop,
            nowMonth: now,
            monthLabels: t.monthsShort,
            fitLabel: (f) => _fitLabel(t, f),
            nowLabel: t.now,
          ),
          const Divider(height: 22),
          if (facts.bestMonths.isNotEmpty)
            _line(Icons.thumb_up_alt_rounded, t.dssBestMonths, t.monthList(facts.bestMonths.toList()..sort())),
          if (next.isNotEmpty && fit != PlantFit.best) ...[
            const SizedBox(height: 6),
            _line(Icons.upcoming_rounded, t.dssNextBest, t.monthList(next)),
          ],
          const SizedBox(height: 6),
          _line(Icons.cloud_queue_rounded, t.dssWeatherBasis, t.dssWeatherBasisBody),
        ],
      ),
    );
  }
}

Widget _line(IconData i, String k, String v) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Icon(i, size: 18, color: AppColors.leaf),
    const SizedBox(width: 8),
    Expanded(
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
          TextSpan(text: v, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
        ]),
        style: const TextStyle(height: 1.35),
      ),
    ),
  ],
);

/// 12 patayong bar (isa kada buwan). Mas mataas ang bar kapag mas magandang buwan.
class _MonthStrip extends StatelessWidget {
  final Color Function(int month) builder;
  final int highlight;
  final List<String> labels;
  final double Function(int month)? heightOf;

  const _MonthStrip({required this.builder, required this.highlight, required this.labels, this.heightOf});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var m = 1; m <= 12; m++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: heightOf?.call(m) ?? 1),
                    duration: Duration(milliseconds: 350 + m * 40),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      height: 54 * v.clamp(0.12, 1.0),
                      decoration: BoxDecoration(
                        color: builder(m),
                        borderRadius: BorderRadius.circular(6),
                        border: m == highlight ? Border.all(color: AppColors.ink, width: 2) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[m - 1],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: m == highlight ? FontWeight.w900 : FontWeight.w600,
                      color: m == highlight ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── 2. Harvest & income ─────────────────────────

class _HarvestIncome extends StatelessWidget {
  final FarmPlanting planting;
  const _HarvestIncome({required this.planting});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sqm = context.watch<FarmInputProvider>().useSqm;
    final e = DssService.estimate(planting);
    if (e == null) {
      return GlassCard(padding: const EdgeInsets.all(14), child: Text(t.dssNoEstimate));
    }
    final perYear = !(factsFor(planting.crop)?.hasHarvestDays ?? true);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Big(
                  icon: Icons.scale_rounded,
                  label: perYear ? t.dssYieldPerYear : t.dssExpectedYield,
                  value: DssFmt.kg(e.kgMid),
                  range: '${DssFmt.kg(e.kgLow)} – ${DssFmt.kg(e.kgHigh)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: e.hasPrice
                    ? _Big(
                  icon: Icons.payments_rounded,
                  label: t.dssExpectedIncome,
                  value: DssFmt.peso(e.incomeMid!),
                  range: '${DssFmt.peso(e.incomeLow!)} – ${DssFmt.peso(e.incomeHigh!)}',
                )
                    : _Big(icon: Icons.payments_rounded, label: t.dssExpectedIncome, value: '—', range: t.dssNoPrice),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RangeBar(low: e.kgLow, mid: e.kgMid, high: e.kgHigh),
          const SizedBox(height: 12),
          _line(Icons.calculate_rounded, t.dssHowComputed,
              e.usesOwnYield ? t.dssBasisOwn(DssFmt.area(planting.hectares, sqm: sqm)) : t.dssBasisTypical(DssFmt.area(planting.hectares, sqm: sqm), e.kgPerHaMid.round().toString())),
          if (e.hasPrice) ...[
            const SizedBox(height: 6),
            _line(Icons.sell_rounded, t.dssPriceUsed, '${DssFmt.pesoKg(e.priceLow!)} – ${DssFmt.pesoKg(e.priceHigh!)} / kg'),
          ],
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  final IconData icon;
  final String label, value, range;
  const _Big({required this.icon, required this.label, required this.value, required this.range});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.leaf),
            const SizedBox(width: 5),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted))),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
          const SizedBox(height: 2),
          Text(range, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final double low, mid, high;
  const _RangeBar({required this.low, required this.mid, required this.high});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final span = (high - low) <= 0 ? 1.0 : (high - low);
    final pos = ((mid - low) / span).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 18,
          child: LayoutBuilder(builder: (_, c) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(colors: [AppColors.sun, AppColors.lime, AppColors.leaf]),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pos),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Positioned(
                    left: (c.maxWidth - 18) * v,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${t.dssLow}\n${DssFmt.kg(low)}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
            Text('${t.dssLikely}\n${DssFmt.kg(mid)}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w900)),
            Text('${t.dssHigh}\n${DssFmt.kg(high)}',
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────── 3. Price advisory ─────────────────────────

class _PriceAdvisory extends StatelessWidget {
  final FarmPlanting planting;
  const _PriceAdvisory({required this.planting});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final crop = planting.crop;
    final idx = DssService.priceIndex(crop);
    final sell = DssService.bestSellMonths(crop);
    final facts = factsFor(crop)!;
    final flat = idx.every((v) => (v - 100).abs() < 0.01);
    final now = DateTime.now().month;
    final prices = DssService.monthlyPrices(crop);

    if (flat) {
      return GlassCard(padding: const EdgeInsets.all(14), child: Text(t.dssPriceFlat(t.cropLabel(crop))));
    }

    final harvestMonth = facts.hasHarvestDays
        ? (planting.plantedOn.add(Duration(days: ((facts.minDays! + facts.maxDays!) ~/ 2))).month)
        : now;
    final harvestHigh = idx[harvestMonth - 1] >= 100;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.up),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.dssSellBest(t.monthList(sell)),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MonthStrip(
            builder: (m) => sell.contains(m) ? AppColors.up : (idx[m - 1] >= 100 ? AppColors.fern : AppColors.border),
            highlight: now,
            labels: t.monthsShort,
            heightOf: (m) => ((idx[m - 1] - 85) / 30).clamp(0.12, 1.0),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _dot(AppColors.up, t.dssLegendHighPrice),
              _dot(AppColors.border, t.dssLegendLowPrice),
            ],
          ),
          const Divider(height: 22),
          _line(
            Icons.agriculture_rounded,
            t.dssYourHarvest,
            harvestHigh ? t.dssHarvestHighPrice(t.monthShort(harvestMonth)) : t.dssHarvestLowPrice(t.monthShort(harvestMonth)),
          ),
          if (!harvestHigh) ...[
            const SizedBox(height: 6),
            _line(Icons.lightbulb_rounded, t.dssTip, facts.storable ? t.dssTipStorable(t.monthList(sell)) : t.dssTipFresh),
          ],
          if (prices != null) ...[
            const SizedBox(height: 6),
            _line(Icons.sell_rounded, t.dssPriceRangeYear,
                '${DssFmt.pesoKg(prices.reduce((a, b) => a < b ? a : b))} – ${DssFmt.pesoKg(prices.reduce((a, b) => a > b ? a : b))} / kg'),
          ],
        ],
      ),
    );
  }

  Widget _dot(Color c, String s) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(s, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ],
  );
}