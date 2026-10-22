import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/crop_l10n.dart';
import '../../dashboard_data.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../widgets/crop_graph.dart';
import '../../widgets/crop_image.dart';

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}
/// Ilang mm ng ulan sa loob ng 7 araw ang maituturing na "maraming ulan".
const double kHeavyRainWeekMm = 60;

class CropDetailScreen extends StatelessWidget {
  final PlantingGuide guide;
  final DashboardProvider p;
  const CropDetailScreen({super.key, required this.guide, required this.p});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final short = DateFormat.MMM(locale);
    final long = DateFormat.MMMM(locale);
    final month = DateTime.now().month;
    final status = guide.statusFor(month);
    final labels = [for (var m = 1; m <= 12; m++) short.format(DateTime(2000, m))];
    final rainWeek = p.forecast.take(7).fold<double>(0, (s, d) => s + d.rainMm);
    final nextBest = guide.nextBestMonth(month);
    final possible = (guide.possibleMonths.toList()..sort()).map((m) => labels[m - 1]).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(t.cropLabel(guide.crop), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(aspectRatio: 16 / 10, child: CropImage(guide: guide)),
          ),
          const SizedBox(height: 14),
          Text(t.cropAbout(guide.crop), style: const TextStyle(height: 1.4, fontSize: 14)),
          const SizedBox(height: 14),

          // Graph (DSS)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.show_chart_rounded, color: AppColors.leaf),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.dssTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(t.dssSubtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Pill(t.plantStatusLabel(status), plantStatusColor(status), icon: plantStatusIcon(status)),
                  if (status == PlantStatus.avoid && nextBest != null)
                    Text(
                      t.bestMonthLabel(long.format(DateTime(2000, nextBest))),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                ]),
                if (status != PlantStatus.avoid && rainWeek >= kHeavyRainWeekMm) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.umbrella_rounded, size: 18, color: Color(0xFFEF6C00)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.dssRainNote, style: const TextStyle(fontSize: 12.5, height: 1.3))),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                CropGraph(guide: guide, month: month, labels: labels, nowLabel: t.now),
                const SizedBox(height: 8),
                Wrap(spacing: 14, runSpacing: 6, children: [
                  _LegendDot(AppColors.leaf, t.legendBest),
                  _LegendDot(const Color(0xFFEF8F00), t.legendPossible),
                  _LegendDot(Colors.black38, t.legendAvoid),
                ]),
                const Divider(height: 24),
                Text(t.dssBestMonths, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(monthRangesLabel(guide, locale), style: const TextStyle(fontSize: 14, color: AppColors.leaf, fontWeight: FontWeight.w800)),
                if (possible.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(t.dssPossibleMonths, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(possible, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Ani at payo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 18, color: AppColors.soil),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      t.harvestIn(t.cropHarvest(guide.crop)),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(t.dssTip, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(t.cropTip(guide.crop), style: const TextStyle(height: 1.4)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(t.dssDisclaimer, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendDot(this.color, this.text);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}