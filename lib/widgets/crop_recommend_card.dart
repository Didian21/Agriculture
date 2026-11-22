import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/dss_catalog.dart';
import '../core/dss_recommend.dart';
import '../core/tr.dart';
import '../main.dart';
import 'common_widgets.dart';
import 'crop_photo.dart';

/// Mungkahi ng Pananim: niraranggo ang mga pananim ayon sa lupa, tubig, panahon, lawak at pamilihan.
class CropRecommendCard extends StatefulWidget {
  final SoilType soil;
  final Drainage drain;
  final WaterSupply water;
  final double? areaHa;
  final DateTime plantedOn;
  final String? selected;
  final ValueChanged<String> onPick;
  const CropRecommendCard({
    super.key,
    required this.soil,
    required this.drain,
    required this.water,
    required this.areaHa,
    required this.plantedOn,
    required this.selected,
    required this.onPick,
  });

  @override
  State<CropRecommendCard> createState() => _CropRecommendCardState();
}

class _CropRecommendCardState extends State<CropRecommendCard> {
  String? _open;
  bool _all = false;

  static const _labelTl = {'soil': 'Lupa', 'drain': 'Agos ng tubig', 'water': 'Suplay ng tubig', 'season': 'Panahon', 'area': 'Lawak', 'market': 'Pamilihan at tubo'};
  static const _labelEn = {'soil': 'Soil', 'drain': 'Drainage', 'water': 'Water supply', 'season': 'Season', 'area': 'Land size', 'market': 'Market and profit'};

  Color _lvl(RecLevel l) => l == RecLevel.good ? AppColors.leaf : (l == RecLevel.fair ? const Color(0xFFC0792E) : const Color(0xFFC0503E));

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final nf = NumberFormat.decimalPattern(locale);
    String peso(double v) => '${v < 0 ? '-' : ''}₱${nf.format(v.abs().round())}';
    final recs = CropRecommender.rank(
      soil: widget.soil,
      drain: widget.drain,
      water: widget.water,
      areaHa: widget.areaHa,
      plantedOn: widget.plantedOn,
    );
    var top = (_all ? recs : recs.take(5)).toList();
    final sel = widget.selected;
    if (sel != null && !top.any((r) => r.crop.id == sel)) {
      final extra = recs.where((r) => r.crop.id == sel);
      if (extra.isNotEmpty) top = [...top, extra.first];
    }
    final area = widget.areaHa;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded, color: AppColors.leaf, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tr(context, 'Mungkahi ng Pananim', 'Crop Recommendation'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            tr(context, 'Batay sa lupa, tubig, panahon sa Pagsanjan, lawak, demand at tantiyang tubo. Dito ka pipili ng pananim.',
                'Based on soil, water, Pagsanjan weather, land size, demand and estimated profit. Pick your crop here.'),
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < top.length; i++) _item(context, top[i], recs.indexOf(top[i]), tl, peso, area),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _all = !_all),
              icon: Icon(_all ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text(_all
                  ? tr(context, 'Ipakita ang top 5 lang', 'Show top 5 only')
                  : tr(context, 'Ipakita ang lahat ng ${recs.length} pananim', 'Show all ${recs.length} crops')),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context,
                'Gabay lamang ito. Tantiya ang mga puntos, gastos at presyo. Kumpirmahin sa Municipal Agriculture Office (MAO) ng Pagsanjan bago magtanim.',
                'This is a guide only. Scores, costs and prices are estimates. Confirm with the Pagsanjan Municipal Agriculture Office (MAO) before planting.'),
            style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
          ),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, CropRec r, int i, bool tl, String Function(double) peso, double? area) {
    final open = _open == r.crop.id;
    final picked = widget.selected == r.crop.id;
    final scoreColor = r.score >= 75 ? AppColors.leaf : (r.score >= 55 ? const Color(0xFFC0792E) : const Color(0xFFC0503E));
    final perYear = r.crop.perennial ? tr(context, ' / taon', ' / yr') : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: picked ? AppColors.leaf : Colors.black.withValues(alpha: 0.08), width: picked ? 1.6 : 1),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _open = open ? null : r.crop.id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CropPhoto(cropId: r.crop.id, emojiSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${i + 1}. ${tl ? r.crop.nameTl : r.crop.nameEn}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (r.score / 100).clamp(0.0, 1.0),
                      minHeight: 7,
                      color: scoreColor,
                      backgroundColor: scoreColor.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tr(context, 'Tantiyang tubo', 'Est. profit')}: ${peso(r.netPerHa)}/ha$perYear',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('${r.score.round()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scoreColor)),
              Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.muted),
            ]),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final f in r.factors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(Icons.circle, size: 9, color: _lvl(f.level)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${(tl ? _labelTl : _labelEn)[f.key]}: ', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                          TextSpan(text: f.note(tl), style: const TextStyle(color: AppColors.muted)),
                        ]),
                        style: const TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ]),
                ),
              if (area != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    tr(context, 'Para sa ${area.toStringAsFixed(2)} ha: ~${peso(r.netPerHa * area)}$perYear', 'For ${area.toStringAsFixed(2)} ha: ~${peso(r.netPerHa * area)}$perYear'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => widget.onPick(r.crop.id),
                  icon: Icon(picked ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 18),
                  label: Text(picked ? tr(context, 'Napili na', 'Selected') : tr(context, 'Piliin ang pananim na ito', 'Choose this crop')),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}