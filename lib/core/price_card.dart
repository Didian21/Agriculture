import 'package:flutter/material.dart';

import '../core/mao_prices.dart';
import '../core/tr.dart';
import '../core/ui.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';

const _monthsTl = ['Mayo', 'Hun', 'Hul', 'Ago', 'Set', 'Okt', 'Nob'];
const _monthsEn = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
const _fullTl = ['', 'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];
const _fullEn = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// Presyo ng MAO ng napiling pananim: presyo ngayon, presyo kada buwan, pinakamagandang buwan ng bentahan,
/// at presyo sa buwan ng anihan. Walang laman ang card kung walang record ang pananim.
class PriceAdviceCard extends StatelessWidget {
  final String cropId;
  final String cropNameTl, cropNameEn;
  final int? harvestMonth; // buwan ng inaasahang anihan (1-12)
  final double? usedPrice; // presyong kasalukuyang ginagamit sa kuwenta
  final ValueChanged<double>? onUse; // gamitin ang presyo ng buwan ng ani sa kuwenta

  const PriceAdviceCard({
    super.key,
    required this.cropId,
    required this.cropNameTl,
    required this.cropNameEn,
    this.harvestMonth,
    this.usedPrice,
    this.onUse,
  });

  String _peso(double v) => '₱${v == v.roundToDouble() ? v.round() : v.toStringAsFixed(1)}';

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final series = maoSeriesFor(cropId);
    final name = tl ? cropNameTl : cropNameEn;

    if (series == null) {
      return EmptyState(
        icon: Icons.sell_outlined,
        title: tr(context, 'Wala pang presyo ng MAO para sa $name', 'No MAO price yet for $name'),
        body: tr(context, 'Wala ang pananim na ito sa record ng MAO. Tantiyang presyo ang ginagamit sa kuwenta. Maaari mong ilagay ang presyo sa inyong lugar sa tab na Buod.',
            'This crop is not in the MAO record. An estimated price is used in the calculation. You can enter your local price in the Summary tab.'),
      );
    }

    final unit = series.unit == 'pc' ? tr(context, 'piraso', 'piece') : 'kg';
    final now = DateTime.now().month;
    final nowData = series.at(now);
    final showMonth = nowData != null ? now : series.latestMonth;
    final shown = showMonth == null ? null : series.at(showMonth);
    final best = series.bestMonth;
    final hm = harvestMonth;
    final harvestData = hm == null ? null : series.at(hm);
    final all = [for (final m in series.months) if (m != null) m.median];
    final maxV = all.isEmpty ? 1.0 : all.reduce((a, b) => a > b ? a : b);
    final full = tl ? _fullTl : _fullEn;
    final short = tl ? _monthsTl : _monthsEn;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.l),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sell_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(tr(context, 'Presyo ng $name (MAO)', '$name price (MAO)'), style: AppText.cardTitle)),
        ]),
        const SizedBox(height: 4),
        Text(tr(context, 'Presyo sa bukid (farmgate) ayon sa record ng MAO Pagsanjan. Bawat $unit.', 'Farmgate price from the Pagsanjan MAO record. Per $unit.'), style: AppText.small),
        const SizedBox(height: AppSpace.m),

        // Presyo ngayon (o pinakabago)
        if (shown != null && showMonth != null)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_peso(shown.median), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.leaf, height: 1)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  nowData != null
                      ? tr(context, '/$unit nitong ${full[showMonth]}', '/$unit this ${full[showMonth]}')
                      : tr(context, '/$unit, pinakabagong tala (${full[showMonth]})', '/$unit, latest record (${full[showMonth]})'),
                  style: AppText.small,
                ),
              ),
            ),
          ]),
        if (shown != null && shown.weeks > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr(context, 'Saklaw: ${_peso(shown.low)} - ${_peso(shown.high)} · ${shown.weeks} lingguhang tala', 'Range: ${_peso(shown.low)} - ${_peso(shown.high)} · ${shown.weeks} weekly records'),
              style: AppText.small,
            ),
          ),
        const SizedBox(height: AppSpace.l),

        // Presyo kada buwan
        Text(tr(context, 'Presyo kada buwan', 'Price by month'), style: AppText.label),
        const SizedBox(height: AppSpace.s),
        SizedBox(
          height: 132,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < series.months.length; i++) ...[
              Expanded(child: _bar(context, series.months[i], MaoSeries.firstMonth + i, short[i], maxV, best, hm)),
              if (i < series.months.length - 1) const SizedBox(width: 6),
            ],
          ]),
        ),
        const SizedBox(height: AppSpace.s),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _legend(AppColors.leaf, tr(context, 'Pinakamataas', 'Highest')),
          _legend(AppColors.leaf.withValues(alpha: 0.35), tr(context, 'Iba pang buwan', 'Other months')),
          _legend(null, tr(context, 'Buwan ng anihan', 'Harvest month'), outline: true),
        ]),
        const SizedBox(height: AppSpace.l),

        // Buod
        if (best != null)
          _line(
            Icons.trending_up_rounded,
            tr(context, 'Pinakamataas ang presyo nitong ${full[best]}: ${_peso(series.at(best)!.median)}/$unit.', 'The price is highest in ${full[best]}: ${_peso(series.at(best)!.median)}/$unit.'),
          ),
        if (hm != null)
          _line(
            Icons.agriculture_rounded,
            harvestData != null
                ? tr(context, 'Sa inaasahang anihan (${full[hm]}), ang presyo ng MAO ay ${_peso(harvestData.median)}/$unit.', 'At the expected harvest (${full[hm]}), the MAO price is ${_peso(harvestData.median)}/$unit.')
                : tr(context, 'Walang record ang MAO para sa ${full[hm]}, kaya tantiya ang presyo sa anihan.', 'The MAO has no record for ${full[hm]}, so the harvest price is an estimate.'),
            warn: harvestData == null,
          ),
        if (series.monthsWithData < 7)
          _line(Icons.info_outline_rounded, tr(context, 'Mayroon lang ${series.monthsWithData} sa 7 buwan (Mayo-Nobyembre).', 'Only ${series.monthsWithData} of 7 months (May-November) have records.'), warn: true),
        if (series.unit == 'pc')
          _line(Icons.warning_amber_rounded,
              tr(context, 'Kaunti at magkakalayo ang tala ng niyog (halimbawa ₱7 at ₱25 sa iisang buwan). Kumpirmahin sa MAO bago gamitin.', 'Coconut records are few and far apart (for example ₱7 and ₱25 in one month). Confirm with the MAO before using.'),
              warn: true),

        if (onUse != null && harvestData != null) ...[
          const SizedBox(height: AppSpace.s),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onUse!(harvestData.median),
              icon: Icon(usedPrice == harvestData.median ? Icons.check_circle_rounded : Icons.calculate_rounded, size: 18),
              label: Text(usedPrice == harvestData.median
                  ? tr(context, 'Ginagamit sa kuwenta', 'Used in the calculation')
                  : tr(context, 'Gamitin ang ${_peso(harvestData.median)} sa kuwenta', 'Use ${_peso(harvestData.median)} in the calculation')),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.s),
        Text(
          tr(context, 'Median ito ng lingguhang presyo, Mayo-Nobyembre. Hindi ito garantiya ng presyo sa araw ng bentahan. Magkakaiba ang presyo sa bawat taon.',
              'This is the median of weekly prices, May-November. It is not a guarantee of the price on the day you sell. Prices differ from year to year.'),
          style: AppText.small,
        ),
      ]),
    );
  }

  Widget _bar(BuildContext context, MaoMonth? m, int month, String label, double maxV, int? best, int? hm) {
    final isBest = best == month;
    final isHarvest = hm == month;
    const area = 84.0;
    final h = m == null ? 0.0 : (m.median / maxV * area).clamp(6.0, area);
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(m == null ? '–' : _peso(m.median),
          maxLines: 1,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: m == null ? AppColors.muted : AppColors.ink)),
      const SizedBox(height: 3),
      Container(
        height: m == null ? 6 : h,
        decoration: BoxDecoration(
          color: m == null ? AppColors.border : (isBest ? AppColors.leaf : AppColors.leaf.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(6),
          border: isHarvest ? Border.all(color: AppColors.ink, width: 2) : null,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: isHarvest ? FontWeight.w900 : FontWeight.w600, color: AppColors.muted)),
    ]);
  }

  Widget _legend(Color? c, String text, {bool outline = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
            border: outline ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: AppText.small),
      ]);

  Widget _line(IconData icon, String text, {bool warn = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: warn ? StatusColor.warn : AppColors.leaf),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 13))),
        ]),
      );
}
