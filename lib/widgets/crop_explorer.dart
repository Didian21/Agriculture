import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/crop_data.dart';
import '../core/crop_info.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/dss_service.dart';
import 'common_widgets.dart';
import 'crop_photo.dart';

/// "Mga Pananim" - grid ng litrato ng bawat commodity. Pindutin para sa buong detalye.
/// Mga litrato: ilagay sa assets/images/crops/ (png, jpg o webp; pangalan hal. eggplant.png).
/// Kung walang litrato, emoji sa kulay ng grupo ang lalabas.
class CropExplorer extends StatefulWidget {
  final VoidCallback? onOpenDss;
  const CropExplorer({super.key, this.onOpenDss});

  @override
  State<CropExplorer> createState() => _CropExplorerState();
}

class _CropExplorerState extends State<CropExplorer> {
  static const _collapsed = 9;
  CropGroup? _filter;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tl = Localizations.localeOf(context).languageCode == 'tl';
    final all = kCropInfo.where((c) => kCropFacts.containsKey(c.id)).toList();
    final list = _filter == null ? all : all.where((c) => c.group == _filter).toList();
    final shown = (_expanded || list.length <= _collapsed) ? list : list.take(_collapsed).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(icon: Icons.grass_rounded, text: t.cropsTitle, subtitle: t.cropsSub),
      SizedBox(
        height: 38,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _FilterChip(label: t.cropsAll, selected: _filter == null, onTap: () => setState(() => _filter = null)),
          for (final g in CropGroup.values)
            _FilterChip(
              label: _groupLabel(t, g),
              selected: _filter == g,
              onTap: () => setState(() {
                _filter = g;
                _expanded = false;
              }),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shown.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, i) {
            final c = shown[i];
            return _CropTile(
              info: c,
              tl: tl,
              onTap: () => _openDetail(context, c),
            );
          },
        ),
      ),
      if (list.length > _collapsed)
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(_expanded ? t.cropsSeeLess : '${t.cropsSeeAll} (${list.length})'),
          ),
        ),
    ]);
  }

  void _openDetail(BuildContext context, CropInfo c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CropDetailSheet(
        info: c,
        onOpenDss: widget.onOpenDss == null
            ? null
            : () {
          Navigator.of(sheetContext).pop();
          widget.onOpenDss!();
        },
      ),
    );
  }
}

String _groupLabel(AppLocalizations t, CropGroup g) {
  switch (g) {
    case CropGroup.veg:
      return t.cropsGroupVeg;
    case CropGroup.fruit:
      return t.cropsGroupFruit;
    case CropGroup.root:
      return t.cropsGroupRoot;
    case CropGroup.grain:
      return t.cropsGroupGrain;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.leaf : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.leaf : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _CropTile extends StatelessWidget {
  final CropInfo info;
  final bool tl;
  final VoidCallback onTap;
  const _CropTile({required this.info, required this.tl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.leaf.withValues(alpha: 0.14), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.5),
            child: Stack(fit: StackFit.expand, children: [
              CropPhoto(cropId: info.id, emojiSize: 38),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
                  color: Colors.white.withValues(alpha: 0.82),
                  child: Text(
                    info.name(tl),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Detalye

double? _incomeMidPerHa(String id) {
  final f = kCropFacts[id];
  final p = f?.basePrice;
  if (f == null || p == null) return null;
  return f.midKgHa * p;
}

/// Nasa pinakamataas na ika-apat ba ang tantiyang kita kada ektarya?
bool _isTopIncome(String id) {
  final mine = _incomeMidPerHa(id);
  if (mine == null) return false;
  final all = [for (final k in kCropFacts.keys) _incomeMidPerHa(k)].whereType<double>().toList()..sort();
  if (all.isEmpty) return false;
  final cut = all[(all.length * 0.75).floor().clamp(0, all.length - 1)];
  return mine >= cut;
}

class _CropDetailSheet extends StatelessWidget {
  final CropInfo info;
  final VoidCallback? onOpenDss;
  const _CropDetailSheet({required this.info, this.onOpenDss});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tl = locale == 'tl';
    final f = factsFor(info.id) ?? kCropFacts[info.id]!;
    final nowMonth = DateTime.now().month;
    final nf = NumberFormat.decimalPattern(locale);
    String month(int m) => DateFormat.MMM(locale).format(DateTime(2024, m));
    final unit = _unitLabel(t, f.unit);

    // Presyo
    final real = f.monthlyPrice != null;
    final prices = f.monthlyPrice?.whereType<double>().toList() ?? <double>[];
    double? pMin, pMax;
    if (prices.isNotEmpty) {
      pMin = prices.reduce((a, b) => a < b ? a : b);
      pMax = prices.reduce((a, b) => a > b ? a : b);
    }
    final avg = f.basePrice;
    final sell = real ? DssService.bestSellMonths(info.id) : <int>[];

    // Mga payo (kusang nabubuo mula sa datos)
    final insights = <(IconData, String)>[];
    if (f.bestMonths.contains(nowMonth)) {
      insights.add((Icons.spa_rounded, t.cropInsPlantNow));
    } else if (f.bestMonths.isNotEmpty) {
      var next = nowMonth;
      for (var k = 1; k <= 12; k++) {
        final m = ((nowMonth - 1 + k) % 12) + 1;
        if (f.bestMonths.contains(m)) {
          next = m;
          break;
        }
      }
      insights.add((Icons.event_rounded, '${t.cropInsNextPlant} ${month(next)}.'));
    }
    if (f.minDays != null && f.minDays! <= 45) insights.add((Icons.bolt_rounded, t.cropInsFast));
    if (prices.length >= 2 && pMin != null && pMax != null && pMin > 0) {
      insights.add(pMax / pMin <= 1.6
          ? (Icons.horizontal_rule_rounded, t.cropInsPriceStable)
          : (Icons.show_chart_rounded, t.cropInsPriceVolatile));
    }
    if (_isTopIncome(info.id)) insights.add((Icons.trending_up_rounded, t.cropInsIncomeHigh));
    if (f.storable) insights.add((Icons.inventory_2_rounded, t.cropInsStorable));

    final incomeMid = avg == null ? null : f.midKgHa * avg;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7FCF4), Color(0xFFE3F1DF)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24)],
          ),
          child: Stack(children: [
            ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(height: 190, child: CropPhoto(cropId: info.id, emojiSize: 78)),
                ),
                const SizedBox(height: 14),
                Text(info.name(tl), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('${t.cropAlsoCalled}: ${info.altName(tl)}', style: const TextStyle(fontSize: 13.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _Pill(text: _groupLabel(t, info.group), color: cropGroupColor(info.group)),
                  if (f.storable) _Pill(text: t.cropStorable, color: AppColors.leaf),
                ]),
                const SizedBox(height: 10),
                Text(info.desc(tl), style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink)),
                const SizedBox(height: 14),

                // Pinakamagandang panahon
                _Block(
                  icon: Icons.calendar_month_rounded,
                  title: t.cropSecBestTime,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _MonthStrip(best: f.bestMonths, possible: f.possibleMonths, now: nowMonth, label: month),
                    const SizedBox(height: 8),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      _Dot(color: AppColors.leaf, label: t.cropBest),
                      _Dot(color: AppColors.leaf.withValues(alpha: 0.3), label: t.cropPossible),
                    ]),
                    if (f.bestMonths.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${t.cropBest}: ${(f.bestMonths.toList()..sort()).map(month).join(', ')}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                  ]),
                ),

                // Tagal bago maani
                _Block(
                  icon: Icons.timelapse_rounded,
                  title: t.cropSecHarvest,
                  child: f.hasHarvestDays
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${f.minDays}-${f.maxDays} ${t.cropDaysWord}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    Text(
                      '≈ ${_approxMonths(f.minDays!, f.maxDays!)} ${t.cropMonthsWord}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700),
                    ),
                  ])
                      : Text(t.cropHarvestYearly, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink)),
                ),

                // Ani
                _Block(
                  icon: Icons.scale_rounded,
                  title: t.cropSecYield,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${nf.format(f.midKgHa)} $unit',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    Text('${nf.format(f.lowKgHa)} - ${nf.format(f.highKgHa)} $unit  •  ${t.cropPerHa}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  ]),
                ),

                // Presyo
                _Block(
                  icon: Icons.sell_rounded,
                  title: t.cropSecPrice,
                  child: avg == null
                      ? Text(t.cropNoPrice, style: const TextStyle(fontSize: 14, color: AppColors.muted))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (real && pMin != null && pMax != null)
                      Text('₱${_p(pMin)} - ₱${_p(pMax)} / $unit',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink))
                    else
                      Text('≈ ₱${_p(avg)} / $unit',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(real ? t.cropPriceReal : t.cropPriceEstimate,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                    if (sell.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${t.cropBestSell}: ${sell.map(month).join(', ')}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ],
                    if (incomeMid != null) ...[
                      const SizedBox(height: 8),
                      Text('${t.cropIncomeHa}: ≈ ₱${nf.format((incomeMid / 1000).round() * 1000)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.leaf)),
                    ],
                  ]),
                ),

                // Gabay
                _Block(
                  icon: Icons.menu_book_rounded,
                  title: t.cropSecGuide,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final tip in info.tips(tl)) _Bullet(icon: Icons.check_circle_rounded, text: tip),
                  ]),
                ),

                // Bakit subukan
                _Block(
                  icon: Icons.lightbulb_rounded,
                  title: t.cropSecDiversify,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final i in insights) _Bullet(icon: i.$1, text: i.$2),
                    const SizedBox(height: 4),
                    Text(t.cropDiversifyNote, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(t.cropEstNote, style: const TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.muted)),
              ],
            ),
            if (onOpenDss != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    onPressed: onOpenDss,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.insights_rounded),
                    label: Text(t.cropTryDss, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  static String _p(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  static int _approxMonths(int a, int b) => (((a + b) / 2) / 30).round().clamp(1, 99);
}

String _unitLabel(AppLocalizations t, String unit) {
  switch (unit) {
    case 'tali':
      return t.cropUnitTali;
    case 'pc':
      return t.cropUnitPc;
    default:
      return t.cropUnitKg;
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
    );
  }
}

class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Block({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.leaf),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.muted))),
          ]),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 16, color: AppColors.leaf)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.ink))),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _MonthStrip extends StatelessWidget {
  final Set<int> best;
  final Set<int> possible;
  final int now;
  final String Function(int) label;
  const _MonthStrip({required this.best, required this.possible, required this.now, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var m = 1; m <= 12; m++)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: best.contains(m)
                  ? AppColors.leaf
                  : possible.contains(m)
                  ? AppColors.leaf.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: m == now ? AppColors.ink : AppColors.border, width: m == now ? 2 : 1),
            ),
            child: Text(
              label(m).characters.take(3).toString(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: best.contains(m) ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
    ]);
  }
}