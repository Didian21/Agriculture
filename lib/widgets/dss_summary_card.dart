import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/crop_l10n.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/farm_input_provider.dart';
import '../services/dss_service.dart';
import 'common_widgets.dart';
import 'dss_common.dart';

/// Maliit na buod ng DSS na puwedeng ilagay sa Home / Aking Bukid / Presyo.
/// Nagbabago agad kapag binago ng magsasaka ang inilagay niya sa DSS tab.
class DssSummaryCard extends StatelessWidget {
  final VoidCallback? onOpenDss;
  const DssSummaryCard({super.key, this.onOpenDss});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sel = context.watch<FarmInputProvider>().selected;

    if (sel == null) {
      return GlassCard(
        onTap: onOpenDss,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const IconBubble(icon: Icons.add_chart_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(t.dssSummaryEmpty, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      );
    }

    final now = DateTime.now().month;
    final fit = DssService.fitFor(sel.crop, now);
    final est = DssService.estimate(sel);
    final sell = DssService.bestSellMonths(sel.crop);

    final color = switch (fit) {
      PlantFit.best => AppColors.leaf,
      PlantFit.possible => AppColors.sun,
      PlantFit.avoid => AppColors.down,
    };
    final fitText = switch (fit) {
      PlantFit.best => t.dssLegendBest,
      PlantFit.possible => t.dssLegendPossible,
      PlantFit.avoid => t.dssLegendAvoid,
    };

    return GlassCard(
      onTap: onOpenDss,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.insights_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${t.dssSummaryTitle}: ${t.cropLabel(sel.crop)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: AppColors.ink)),
              ),
              Pill(fitText, color),
            ],
          ),
          const SizedBox(height: 10),
          if (est != null)
            Text(
              est.hasPrice
                  ? t.dssSummaryLine(DssFmt.kg(est.kgMid), DssFmt.peso(est.incomeLow!), DssFmt.peso(est.incomeHigh!))
                  : t.dssSummaryLineNoPrice(DssFmt.kg(est.kgMid)),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35),
            ),
          const SizedBox(height: 4),
          if (!(DssService.priceIndex(sel.crop).every((v) => (v - 100).abs() < 0.01)))
            Text(t.dssSellBest(t.monthList(sell)), style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}