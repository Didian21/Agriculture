import 'package:flutter/material.dart';

import '../../../core/tr.dart';
import '../../../dashboard_data.dart';
import '../../../main.dart';
import '../../../models/farm_record.dart';
import '../../../models/farm_store.dart';
import '../../../services/agri_advisory_service.dart';
import '../../../services/crop_calendar.dart';
import '../../../services/soil_moisture_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/crop_calendar_card.dart';
import '../../../widgets/crop_switcher.dart';

/// Payo: mga mungkahi para sa linggong ito (rule-based mula sa forecast, lupa at yugto ng tanim).
class AdvisoryTab extends StatefulWidget {
  final DashboardProvider p;
  const AdvisoryTab({super.key, required this.p});

  @override
  State<AdvisoryTab> createState() => _AdvisoryTabState();
}

class _AdvisoryTabState extends State<AdvisoryTab> {
  FarmRecord get _farm => FarmStore.instance.current;
  late final Future<SoilMoisture?> _soil = SoilMoistureService().fetch(_farm.center.latitude, _farm.center.longitude);

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

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final w = widget.p.weather!;

    return FutureBuilder<SoilMoisture?>(
      future: _soil,
      builder: (context, snap) {
        final advice = AgriAdvisoryService().build(farm: _farm, w: w, soil: snap.data);
        final main = advice.first;
        final rest = advice.skip(1).toList();

        return AnimatedTabList(items: [
          TabHeader(
            title: tr(context, 'Payo sa pagsasaka', 'Farm advice'),
            subtitle: tr(context, 'Mga mungkahi para sa inyong tanim ngayong linggo', 'Suggestions for your crop this week'),
          ),
          const SizedBox(height: 12),
          const CropSwitcher(),
          _MainAdviceCard(a: main, tl: tl),
          const SizedBox(height: 14),
          ReminderSummaryCard(
            ahead: 7,
            titleTl: 'Mga gawain ngayong linggo',
            titleEn: 'Tasks this week',
            rain: {for (final d in w.daily) dayOnly(d.date): DayRain(d.rainMm, d.rainChance)},
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 18),
            SectionTitle(icon: Icons.tips_and_updates_rounded, text: tr(context, 'Iba pang payo', 'More advice')),
            for (final a in rest) Padding(padding: const EdgeInsets.only(bottom: 10), child: _AdviceTile(a: a, tl: tl)),
          ],
          const SizedBox(height: 8),
          _HowBuilt(),
          const SizedBox(height: 24),
        ]);
      },
    );
  }
}

Color _levelColor(AdviceLevel l) {
  switch (l) {
    case AdviceLevel.warn:
      return const Color(0xFFE67E22);
    case AdviceLevel.tip:
      return const Color(0xFF2E86C1);
    case AdviceLevel.good:
      return AppColors.leaf;
  }
}

class _MainAdviceCard extends StatelessWidget {
  final AgriAdvice a;
  final bool tl;
  const _MainAdviceCard({required this.a, required this.tl});

  @override
  Widget build(BuildContext context) {
    final c = _levelColor(a.level);
    return GlassCard(
      tint: Color.lerp(Colors.white, c, 0.10),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFFF1C40F)),
          const SizedBox(width: 6),
          Text(tr(context, 'Payo para sa linggong ito', 'Advice for this week'),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.muted, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(a.icon, color: c, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(a.title(tl), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2))),
        ]),
        const SizedBox(height: 12),
        Text(a.body(tl), style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.ink)),
      ]),
    );
  }
}

class _AdviceTile extends StatelessWidget {
  final AgriAdvice a;
  final bool tl;
  const _AdviceTile({required this.a, required this.tl});

  @override
  Widget build(BuildContext context) {
    final c = _levelColor(a.level);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(a.icon, color: c, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title(tl), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(a.body(tl), style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.ink)),
          ]),
        ),
      ]),
    );
  }
}

class _HowBuilt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr(
              context,
              'Ang mga payong ito ay nabubuo mula sa weather forecast, halumigmig ng lupa at yugto ng inyong tanim. Gabay lamang ito at hindi opisyal. Kumpirmahin sa Tanggapan ng Pambayang Agrikultura bago gumawa ng malaking desisyon.',
              'This advice is generated from the weather forecast, soil moisture and the stage of your crop. It is a guide only, not official. Please confirm with the Municipal Agriculture Office before making big decisions.',
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
          ),
        ),
      ]),
    );
  }
}