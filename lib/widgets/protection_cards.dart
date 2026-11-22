import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/dss_catalog.dart';
import '../core/dss_protection.dart';
import '../core/dss_recommend.dart';
import '../core/tr.dart';
import '../main.dart';
import '../services/dss_planner.dart';
import 'common_widgets.dart';

/// Rekomendasyon ng abono: uri, tinatayang dami, iskedyul ayon sa yugto ng paglaki, at pagsasaayos ayon sa lupa at tubig.
class FertilizerAdviceCard extends StatelessWidget {
  final DssPlan plan;
  final Drainage drain;
  final WaterSupply water;
  const FertilizerAdviceCard({super.key, required this.plan, required this.drain, required this.water});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final nf = NumberFormat.decimalPattern(locale);
    final area = nf.format(double.parse(plan.areaHa.toStringAsFixed(2)));

    // Kabuuang dami bawat uri ng abono
    final totals = <FertProduct, double>{};
    for (final a in plan.fert) {
      totals[a.product] = (totals[a.product] ?? 0) + a.bags;
    }
    final adjust = fertAdjustments(plan.crop, plan.soil, drain, water);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.grass_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr(context, 'Rekomendasyon ng abono', 'Fertilizer recommendation'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          tr(context, 'Para sa buong $area ha ng ${plan.crop.nameTl}. 1 sako = 50 kg. Tantiya ito at gabay lamang.',
              'For the whole $area ha of ${plan.crop.nameEn}. 1 bag = 50 kg. This is an estimate and a guide only.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 12),

        // Uri at kabuuang dami
        Text(plan.perennial ? tr(context, 'Uri at dami bawat taon', 'Type and amount per year') : tr(context, 'Uri at kabuuang dami', 'Type and total amount'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in totals.entries)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fertName(e.key, tl), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                Text(
                  '${e.value.toStringAsFixed(e.value >= 10 ? 0 : 1)} ${tr(context, 'sako', 'bags')} · ${nf.format((e.value * 50).round())} kg',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.leaf),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: 14),

        // Iskedyul
        Text(tr(context, 'Iskedyul ng paglalagay', 'Application schedule'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 8),
        for (final a in plan.fert)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 82,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Text(
                    a.date == null ? tr(context, 'Taunan', 'Yearly') : DateFormat.MMMd(locale).format(a.date!),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.leaf),
                  ),
                  Text(
                    a.date == null ? '' : (a.day == 0 ? tr(context, 'pagtatanim', 'planting') : tr(context, '${a.day} araw', 'day ${a.day}')),
                    style: const TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stageLabel(plan.crop, a.date == null ? -1 : a.day, tl),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
                  Text(fertName(a.product, tl), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  Text(
                    '${a.bags.toStringAsFixed(a.bags >= 10 ? 0 : 1)} ${tr(context, 'sako', 'bags')} (${nf.format(a.kg.round())} kg)',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(a.note(tl), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3)),
                ]),
              ),
            ]),
          ),

        if (plan.crop.id == 'Rice')
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
            child: Text(
              tr(context, 'Tip: Para hindi masayang ang urea, huwag mag-abono bago umulan at mag-abono sa hapon (pagkalipas ng 3 PM), sa tubig na 2-5 cm ang lalim.',
                  'Tip: To avoid wasting urea, do not fertilize right before rain and apply in the afternoon (after 3 PM) in 2-5 cm of water.'),
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),

        // Pagsasaayos ayon sa kondisyon
        Text(tr(context, 'Ayon sa kondisyon ng inyong lupa', 'For your soil conditions'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 6),
        for (final n in adjust)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 6, color: AppColors.muted)),
              const SizedBox(width: 8),
              Expanded(child: Text(tl ? n.$1 : n.$2, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35))),
            ]),
          ),
      ]),
    );
  }
}

/// Posibleng peste at sakit, paraan ng pagbabantay, natural na kontrol, at halimbawang opsyon sa pestisidyo (huling paraan).
class PestAdviceCard extends StatelessWidget {
  final DssPlan plan;
  const PestAdviceCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final threats = kThreats[plan.crop.id] ?? const <Threat>[];

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bug_report_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr(context, 'Peste at sakit na dapat bantayan', 'Pests and diseases to watch'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          tr(context, 'Suriin ang bukid 1-2 beses isang linggo. Unahin ang natural at pang-iwas na paraan; kemikal ang huling paraan.',
              'Check the field 1-2 times a week. Use natural and preventive methods first; chemicals are the last resort.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 6),
        for (final t in threats)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              leading: Icon(t.disease ? Icons.coronavirus_rounded : Icons.pest_control_rounded, size: 20, color: t.disease ? const Color(0xFFC0792E) : AppColors.leaf),
              title: Text(tl ? t.nameTl : t.nameEn, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              subtitle: Text(t.disease ? tr(context, 'Sakit', 'Disease') : tr(context, 'Peste', 'Pest'), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              children: [
                _line(context, tr(context, 'Mga palatandaan', 'Signs'), tl ? t.signTl : t.signEn),
                _line(context, tr(context, 'Natural at pang-iwas', 'Natural and preventive'), tl ? t.cultTl : t.cultEn),
                if (t.options.isNotEmpty) ...[
                  Text(tr(context, 'Halimbawang opsyon sa pestisidyo (huling paraan)', 'Example pesticide options (last resort)'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final o in t.options)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(10)),
                        child: Text(o, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, 'Aktibong sangkap ang nakalista, hindi brand. Hanapin ang produktong rehistrado sa FPA para sa pananim at pesteng ito, at sundin ang label.',
                        'These are active ingredients, not brands. Look for an FPA-registered product for this crop and pest, and follow the label.'),
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                  ),
                ] else
                  Text(
                    tr(context, 'Walang inirerekomendang kemikal na pang-dalawahan dito. Sumangguni sa MAO.', 'No routine chemical is recommended here. Ask the MAO.'),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
                  ),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _line(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 2),
      Text(body, style: const TextStyle(fontSize: 12.5, height: 1.4)),
    ]),
  );
}

/// Mga paalala sa kaligtasan at tamang paggamit ng kemikal sa pagsasaka.
class SafetyCard extends StatelessWidget {
  const SafetyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9CF86)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.health_and_safety_rounded, color: Color(0xFFB07A00), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr(context, 'Paalala sa kaligtasan', 'Safety reminders'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
        ]),
        const SizedBox(height: 8),
        for (final t in kSafetyTips)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFFB07A00))),
              const SizedBox(width: 8),
              Expanded(child: Text(tl ? t.$1 : t.$2, style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.ink))),
            ]),
          ),
      ]),
    );
  }
}