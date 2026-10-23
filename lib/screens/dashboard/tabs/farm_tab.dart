import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/crop_data.dart';
import '../../../core/crop_l10n.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_planting.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../services/dss_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/crop_image.dart';
import '../../../widgets/dss_common.dart';

/// "My Farm": lahat ng makikita rito ay galing sa mga tanim na inilagay ng magsasaka sa DSS tab.
class FarmTab extends StatelessWidget {
  final DashboardProvider p;
  final VoidCallback? onOpenDss;
  const FarmTab({super.key, required this.p, this.onOpenDss});

  PlantingGuide? _guideFor(String crop) {
    for (final g in p.guides) {
      if (g.crop == crop) return g;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final farm = context.watch<FarmInputProvider>();
    final profile = p.profile!;
    final plantings = farm.plantings;

    // Ang kabuuang lupa ay galing sa inilagay ng farmer sa DSS.
    final totalLand = farm.landTotal;
    var expectedKg = 0.0;
    for (final pl in plantings) {
      expectedKg += DssService.estimate(pl)?.kgMid ?? 0;
    }

    return AnimatedTabList(items: [
      _ProfileCard(profile: profile, crops: farm.cropIds),
      const SizedBox(height: 16),
      _LandCard(total: totalLand, plantings: plantings, sqm: farm.useSqm, onSetUnit: farm.setUseSqm, onOpenDss: onOpenDss),
      const SizedBox(height: 16),
      if (plantings.isNotEmpty) ...[
        Row(children: [
          Expanded(child: _StatTile(icon: Icons.spa_rounded, color: AppColors.fern, value: '${plantings.length}', label: t.plotGrowing)),
          const SizedBox(width: 10),
          Expanded(child: _StatTile(icon: Icons.eco_rounded, color: AppColors.soil, value: '${farm.cropIds.length}', label: t.farmCropsTitle)),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.scale_rounded,
              color: AppColors.leaf,
              value: DssFmt.kg(expectedKg),
              label: t.dssExpectedYield,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        SectionTitle(icon: Icons.eco_rounded, text: t.farmCropsTitle, subtitle: t.farmCropsSub),
        ...plantings.map((pl) {
          final guide = _guideFor(pl.crop);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CropPlotCard(
              planting: pl,
              guide: guide,
              totalHectares: totalLand,
              sqm: farm.useSqm,
              onTap: onOpenDss == null
                  ? null
                  : () {
                farm.select(pl.id);
                onOpenDss!();
              },
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(t.farmEstimateNote, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: onOpenDss,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(t.dssEditPlanting),
          ),
        ),
      ] else
        _EmptyFarm(onAdd: onOpenDss),
      const SizedBox(height: 24),
    ]);
  }
}

class _EmptyFarm extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyFarm({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.spa_rounded, size: 44, color: AppColors.leaf),
        const SizedBox(height: 10),
        Text(t.dssEmptyTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 6),
        Text(t.dssEmptyBody,
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.35, fontSize: 13)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(t.dssAddPlanting)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile + land
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final FarmerProfile profile;
  final List<String> crops;
  const _ProfileCard({required this.profile, required this.crops});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.leaf,
                child: Icon(Icons.agriculture, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.soil),
                    const SizedBox(width: 3),
                    Flexible(child: Text('${profile.barangay}, Pagsanjan, Laguna')),
                  ]),
                ]),
              ),
            ]),
            if (crops.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: crops
                    .map((c) => Chip(
                  avatar: Icon(Icons.eco, size: 16, color: AppColors.forCrop(c)),
                  label: Text(t.cropLabel(c), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  backgroundColor: AppColors.mint,
                  side: BorderSide.none,
                ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LandCard extends StatelessWidget {
  final double total;
  final List<FarmPlanting> plantings;
  final bool sqm;
  final ValueChanged<bool> onSetUnit;
  final VoidCallback? onOpenDss;
  const _LandCard({
    required this.total,
    required this.plantings,
    required this.sqm,
    required this.onSetUnit,
    required this.onOpenDss,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final used = plantings.fold<double>(0, (s, e) => s + e.hectares);
    final free = total - used;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(t.totalLandSize, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: false, label: Text(t.dssUnitHa)),
                ButtonSegment(value: true, label: Text(t.dssUnitSqm)),
              ],
              selected: {sqm},
              onSelectionChanged: (s) => onSetUnit(s.first),
            ),
          ]),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: sqm ? total * 10000 : total),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(sqm ? DssFmt.group(v.round()) : v.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: AppColors.leaf, height: 1.1)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(sqm ? 'm²' : t.hectares, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ]),
          if (total > 0)
            Text(DssFmt.area(total, sqm: !sqm), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          if (total <= 0) ...[
            const SizedBox(height: 6),
            Text(t.dssLandNotSet, style: const TextStyle(color: AppColors.muted, height: 1.35)),
            TextButton.icon(onPressed: onOpenDss, icon: const Icon(Icons.add_rounded, size: 18), label: Text(t.dssLandSet)),
          ],
          if (plantings.isNotEmpty && total > 0) ...[
            const SizedBox(height: 14),
            Container(
              height: 18,
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(9)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Align(alignment: Alignment.centerLeft, widthFactor: v, child: child),
                  child: Row(children: [
                    for (final pl in plantings)
                      Expanded(flex: (pl.hectares * 100000).round().clamp(1, 100000000), child: Container(color: AppColors.forCrop(pl.crop))),
                    if (free > 0.00001) Expanded(flex: (free * 100000).round().clamp(1, 100000000), child: const SizedBox()),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 14, runSpacing: 6, children: [
              for (final pl in plantings)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.forCrop(pl.crop), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('${t.cropLabel(pl.crop)} ${DssFmt.percent(pl.hectares / total * 100)}% · ${DssFmt.area(pl.hectares, sqm: sqm)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              if (free > 0.00001)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.mint, shape: BoxShape.circle, border: Border.all(color: AppColors.border))),
                  const SizedBox(width: 5),
                  Text('${t.farmUnallocated} ${DssFmt.percent(free / total * 100)}% · ${DssFmt.area(free, sqm: sqm)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ]),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detalyadong card ng bawat tanim
// ---------------------------------------------------------------------------

class _CropPlotCard extends StatelessWidget {
  final FarmPlanting planting;
  final PlantingGuide? guide;
  final double totalHectares;
  final bool sqm;
  final VoidCallback? onTap;

  const _CropPlotCard({
    required this.planting,
    required this.guide,
    required this.totalHectares,
    required this.sqm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final crop = planting.crop;
    final color = AppColors.forCrop(crop);
    final percent = totalHectares > 0 ? DssFmt.percent(planting.hectares / totalHectares * 100) : '0';
    final g = guide;
    final facts = factsFor(crop);
    final est = DssService.estimate(planting);
    final days = DateTime.now().difference(planting.plantedOn).inDays;
    final notYet = days < 0;
    final ready = facts != null && facts.hasHarvestDays && days >= facts.minDays!;

    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 84,
                height: 84,
                child: g != null
                    ? CropImage(guide: g)
                    : Container(color: color.withValues(alpha: 0.15), child: Icon(Icons.eco_rounded, color: color, size: 36)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.cropLabel(crop), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 2),
                Text('${DssFmt.area(planting.hectares, sqm: sqm)} • ${t.farmShare(percent)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Pill(
                    notYet ? t.dssNotYet : (ready ? t.farmReadySoon : t.plotGrowing),
                    ready ? AppColors.leaf : AppColors.fern,
                    icon: ready ? Icons.check_circle_rounded : Icons.spa_rounded,
                  ),
                  if (g != null)
                    Builder(builder: (_) {
                      final st = g.statusFor(DateTime.now().month);
                      return Pill(
                        '${t.farmThisMonth}: ${t.plantStatusLabel(st)}',
                        plantStatusColor(st),
                        icon: plantStatusIcon(st),
                      );
                    }),
                ]),
              ]),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ),
          ]),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.event_rounded, text: t.plantedOn(planting.plantedOn)),
          if (facts != null && facts.hasHarvestDays && !notYet) ...[
            const SizedBox(height: 8),
            _GrowthBar(days: days, minDays: facts.minDays!, maxDays: facts.maxDays!),
          ],
          if (est != null) ...[
            if (est.harvestFrom != null && est.harvestTo != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.agriculture_rounded,
                text: t.farmExpectedHarvest(
                  '${DateFormat.MMMd(locale).format(est.harvestFrom!)} - ${DateFormat.MMMd(locale).format(est.harvestTo!)}',
                ),
              ),
            ],
            const SizedBox(height: 10),
            _EstimateBox(est: est),
          ],
          if (g != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_rounded, size: 18, color: AppColors.soil),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.cropTip(crop), style: const TextStyle(fontSize: 12.5, height: 1.35)),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _GrowthBar extends StatelessWidget {
  final int days;
  final int minDays;
  final int maxDays;
  const _GrowthBar({required this.days, required this.minDays, required this.maxDays});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final value = (days / maxDays).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(t.farmDaysGrown(days, maxDays), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        Text('${(value * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.leaf)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 9,
          backgroundColor: AppColors.mint,
          color: days >= minDays ? AppColors.leaf : AppColors.fern,
        ),
      ),
    ]);
  }
}

/// Tantiyang ani at kita ng tanim na ito (galing sa DSS).
class _EstimateBox extends StatelessWidget {
  final HarvestEstimate est;
  const _EstimateBox({required this.est});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(
          child: _Mini(
            label: t.dssExpectedYield,
            value: DssFmt.kg(est.kgMid),
            sub: '${DssFmt.kg(est.kgLow)} - ${DssFmt.kg(est.kgHigh)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: est.incomeMid == null
              ? _Mini(label: t.dssExpectedIncome, value: '-', sub: t.dssNoPrice)
              : _Mini(
            label: t.dssExpectedIncome,
            value: DssFmt.peso(est.incomeMid!),
            sub: '${DssFmt.peso(est.incomeLow!)} - ${DssFmt.peso(est.incomeHigh!)}',
          ),
        ),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _Mini({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.leaf)),
      ),
      Text(sub, style: const TextStyle(fontSize: 10.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
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