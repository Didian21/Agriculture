import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/dss_catalog.dart';
import '../core/tr.dart';
import '../main.dart';
import '../models/farm_store.dart';
import '../services/crop_calendar.dart';
import 'common_widgets.dart';

IconData _typeIcon(ReminderType t) {
  switch (t) {
    case ReminderType.fertilizer:
      return Icons.grass_rounded;
    case ReminderType.watering:
      return Icons.water_drop_rounded;
    case ReminderType.pest:
      return Icons.bug_report_rounded;
    case ReminderType.harvest:
      return Icons.agriculture_rounded;
  }
}

Color _typeColor(ReminderType t) {
  switch (t) {
    case ReminderType.fertilizer:
      return AppColors.leaf;
    case ReminderType.watering:
      return const Color(0xFF3F8FC4);
    case ReminderType.pest:
      return const Color(0xFFC0792E);
    case ReminderType.harvest:
      return const Color(0xFF8A6D1F);
  }
}

/// "Ngayon", "Bukas", "Sa 3 araw", "Huli ng 2 araw".
String _whenLabel(BuildContext context, DateTime d) {
  final diff = dayOnly(d).difference(dayOnly(DateTime.now())).inDays;
  if (diff == 0) return tr(context, 'Ngayon', 'Today');
  if (diff == 1) return tr(context, 'Bukas', 'Tomorrow');
  if (diff == -1) return tr(context, 'Kahapon', 'Yesterday');
  if (diff > 1) return tr(context, 'Sa $diff araw', 'In $diff days');
  return tr(context, 'Huli ng ${-diff} araw', '${-diff} days late');
}

/// Isang paalala na may checkbox para markahang tapos na.
class ReminderTile extends StatelessWidget {
  final Reminder r;
  final bool done;
  final ValueChanged<bool> onChanged;
  const ReminderTile({super.key, required this.r, required this.done, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final diff = dayOnly(r.date).difference(dayOnly(DateTime.now())).inDays;
    final overdue = diff < 0 && !done;
    final color = _typeColor(r.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!done),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: done ? Colors.black.withValues(alpha: 0.03) : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: overdue ? const Color(0xFFC0503E) : color.withValues(alpha: 0.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Icon(_typeIcon(r.type), size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  r.title(tl),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _whenLabel(context, r.date),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: overdue ? const Color(0xFFC0503E) : color),
                ),
                const SizedBox(height: 2),
                Text(r.detail(tl), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3)),
                if (r.wx(tl) != null && !done)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (r.wxWarn ? const Color(0xFFFFF4D6) : const Color(0xFFE6F1FA)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(r.wxWarn ? Icons.warning_amber_rounded : Icons.wb_cloudy_rounded, size: 16, color: r.wxWarn ? const Color(0xFFB07A00) : const Color(0xFF3F8FC4)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(r.wx(tl)!, style: const TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.ink))),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? AppColors.leaf : AppColors.muted, size: 22),
          ]),
        ),
      ),
    );
  }
}

/// Kalendaryo ng pananim (mga yugto at petsa) at mga paparating na paalala para sa isang tanim.
class CropCalendarCard extends StatefulWidget {
  final FarmProfile profile;
  final RainMap? rain;
  const CropCalendarCard({super.key, required this.profile, this.rain});

  @override
  State<CropCalendarCard> createState() => _CropCalendarCardState();
}

class _CropCalendarCardState extends State<CropCalendarCard> {
  Set<String> _done = {};
  List<Reminder> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CropCalendarCard old) {
    super.didUpdateWidget(old);
    final a = old.profile, b = widget.profile;
    if (!sameRain(old.rain, widget.rain)) _load();
    if (a.id != b.id || a.crop != b.crop || a.plantedOn != b.plantedOn || a.harvestOn != b.harvestOn || a.areaHa != b.areaHa || a.soil != b.soil) _load();
  }

  Future<void> _load() async {
    final done = await ReminderStore.loadDone();
    final cond = await ReminderStore.loadConditions();
    final prefs = await ReminderStore.loadPrefs();
    if (!mounted) return;
    setState(() {
      _done = done;
      final base = CropCalendar.reminders(widget.profile, now: DateTime.now(), drain: cond.$1, water: cond.$2, pastDays: 3, ahead: 14)
          .where((r) => prefs.types.contains(r.type))
          .toList();
      _items = prefs.weatherNotes ? CropCalendar.applyWeather(base, widget.rain ?? const {}) : base;
    });
  }

  void _toggle(Reminder r, bool v) {
    setState(() => v ? _done.add(r.key) : _done.remove(r.key));
    ReminderStore.setDone(r.key, v);
  }

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final crop = dssCropFor(widget.profile.crop);
    if (crop == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final stages = CropCalendar.stages(crop, widget.profile.plantedOn, harvestOn: widget.profile.harvestOn);
    final fmt = DateFormat.MMMd(locale);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calendar_month_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr(context, 'Kalendaryo ng pananim', 'Crop calendar'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          tr(context, 'Awtomatikong yugto mula pagtatanim hanggang pag-aani para sa ${crop.nameTl}. Tantiya ang mga petsa.',
              'Automatic stages from planting to harvest for ${crop.nameEn}. Dates are estimates.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < stages.length; i++) _stageRow(context, stages[i], i == stages.length - 1, now, tl, fmt),
        const SizedBox(height: 8),
        Text(tr(context, 'Mga paparating na paalala', 'Upcoming reminders'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(
          tr(context, 'Abono, pagdidilig, pagbabantay sa peste at pag-aani (susunod na 2 linggo). Pindutin para markahang tapos.',
              'Fertilizer, watering, pest scouting and harvest (next 2 weeks). Tap to mark as done.'),
          style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          Text(tr(context, 'Walang nakatakdang gawain sa susunod na 2 linggo.', 'Nothing scheduled in the next 2 weeks.'),
              style: const TextStyle(fontSize: 12, color: AppColors.muted))
        else
          for (final r in _items) ReminderTile(r: r, done: _done.contains(r.key), onChanged: (v) => _toggle(r, v)),
      ]),
    );
  }

  Widget _stageRow(BuildContext context, CalStage s, bool last, DateTime now, bool tl, DateFormat fmt) {
    final done = s.isDone(now);
    final current = s.isCurrent(now);
    final color = current ? AppColors.leaf : (done ? AppColors.leaf.withValues(alpha: 0.55) : AppColors.muted);
    final dates = s.milestone || s.start == s.end ? fmt.format(s.start) : '${fmt.format(s.start)} - ${fmt.format(s.end)}';
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 22,
          child: Column(children: [
            const SizedBox(height: 3),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || current ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
              child: done && !current ? const Icon(Icons.check, size: 9, color: Colors.white) : null,
            ),
            if (!last) Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.35))),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(s.name(tl), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: current ? AppColors.leaf : AppColors.ink)),
                ),
                if (current)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.leaf, borderRadius: BorderRadius.circular(10)),
                    child: Text(tr(context, 'Ngayon', 'Now'), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
              ]),
              Text(dates, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
              if (current) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s.progress(now),
                    minHeight: 6,
                    color: AppColors.leaf,
                    backgroundColor: AppColors.leaf.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.hint(tl), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Buod ng mga paalala para sa Home: lahat ng tanim, mga nakatakda sa loob ng 3 araw (o huli na).
class ReminderSummaryCard extends StatefulWidget {
  final RainMap? rain;
  final int ahead;
  final String? titleTl, titleEn;
  final int? maxItems; // kung may limit, may buton na "Tingnan lahat"
  const ReminderSummaryCard({super.key, this.rain, this.ahead = 3, this.titleTl, this.titleEn, this.maxItems});

  @override
  State<ReminderSummaryCard> createState() => _ReminderSummaryCardState();
}

class _ReminderSummaryCardState extends State<ReminderSummaryCard> {
  final _store = FarmStore.instance;
  Set<String> _done = {};
  List<Reminder> _items = [];

  void _onStore() => _load();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    ReminderStore.changes.addListener(_onStore);
    _load();
  }

  @override
  void didUpdateWidget(covariant ReminderSummaryCard old) {
    super.didUpdateWidget(old);
    if (!sameRain(old.rain, widget.rain) || old.ahead != widget.ahead) _load();
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    ReminderStore.changes.removeListener(_onStore);
    super.dispose();
  }

  Future<void> _load() async {
    final done = await ReminderStore.loadDone();
    final cond = await ReminderStore.loadConditions();
    final prefs = await ReminderStore.loadPrefs();
    if (!mounted) return;
    final now = DateTime.now();
    final all = <Reminder>[];
    for (final p in _store.profiles) {
      all.addAll(CropCalendar.reminders(p, now: now, drain: cond.$1, water: cond.$2, pastDays: 3, ahead: widget.ahead));
    }
    all.sort((a, b) => a.date.compareTo(b.date));
    setState(() {
      _done = done;
      final f = all.where((r) => prefs.types.contains(r.type)).toList();
      _items = prefs.weatherNotes ? CropCalendar.applyWeather(f, widget.rain ?? const {}) : f;
    });
  }

  void _toggle(Reminder r, bool v) {
    setState(() => v ? _done.add(r.key) : _done.remove(r.key));
    ReminderStore.setDone(r.key, v);
  }

  void _openAll() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(tr(ctx, 'Lahat ng paalala', 'All reminders'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                for (final r in _items)
                  ReminderTile(
                    r: r,
                    done: _done.contains(r.key),
                    onChanged: (v) {
                      _toggle(r, v);
                      setSheet(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _items.where((r) => !_done.contains(r.key)).length;
    if (_items.isEmpty) return const SizedBox.shrink();
    // Una ang hindi pa tapos; may limit kung hiniling
    final ordered = [..._items.where((r) => !_done.contains(r.key)), ..._items.where((r) => _done.contains(r.key))];
    final limit = widget.maxItems;
    final shown = limit == null ? ordered : ordered.take(limit).toList();
    final hidden = ordered.length - shown.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.leaf, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.titleTl == null ? tr(context, 'Mga paalala', 'Reminders') : tr(context, widget.titleTl!, widget.titleEn ?? widget.titleTl!), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: open == 0 ? AppColors.leaf.withValues(alpha: 0.15) : const Color(0xFFC0792E), borderRadius: BorderRadius.circular(12)),
              child: Text(
                open == 0 ? tr(context, 'Tapos na lahat', 'All done') : tr(context, '$open na gawain', '$open to do'),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: open == 0 ? AppColors.leaf : Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(tr(context, 'Nakatakda ngayon, sa loob ng ${widget.ahead} araw, o huli na. May kasamang babala sa panahon. Pindutin para markahang tapos.', 'Due today, within ${widget.ahead} days, or late. Includes weather warnings. Tap to mark as done.'),
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3)),
          const SizedBox(height: 10),
          for (final r in shown) ReminderTile(r: r, done: _done.contains(r.key), onChanged: (v) => _toggle(r, v)),
          if (hidden > 0)
            Center(
              child: TextButton.icon(
                onPressed: _openAll,
                icon: const Icon(Icons.list_rounded, size: 18),
                label: Text(tr(context, 'Tingnan lahat (${ordered.length})', 'See all (${ordered.length})')),
              ),
            ),
        ]),
      ),
    );
  }
}