import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/harvest_weather_service.dart';
import 'weather_icon.dart';

/// Panahon bawat araw mula sa pagtatanim hanggang anihan.
/// Berde = nakalipas na araw, may marka ang mga araw ng anihan.
class HarvestWeatherStrip extends StatefulWidget {
  final DateTime plantedOn;
  final DateTime? harvestFrom;
  final DateTime? harvestTo;
  final double lat;
  final double lon;

  /// Maikling buod (petsa ng tanim, araw na, inaasahang ani).
  final String summary;

  /// Sariling pamagat (hal. para sa 2-buwang outlook sa Weather tab).
  final String? title;

  /// true = walang sariling kahon (ilalagay sa loob ng ibang card).
  final bool bare;

  const HarvestWeatherStrip({
    super.key,
    required this.plantedOn,
    required this.harvestFrom,
    required this.harvestTo,
    required this.lat,
    required this.lon,
    required this.summary,
    this.title,
    this.bare = false,
  });

  /// 2-buwang outlook mula ngayon: tumpak ang unang 16 araw, tantiya ang susunod.
  HarvestWeatherStrip.outlook({
    super.key,
    required this.lat,
    required this.lon,
    required this.title,
    this.summary = '',
    int days = 60,
  })  : plantedOn = DateTime.now(),
        harvestFrom = null,
        harvestTo = DateTime.now().add(Duration(days: days - 1)),
        bare = true;

  @override
  State<HarvestWeatherStrip> createState() => _HarvestWeatherStripState();
}

class _HarvestWeatherStripState extends State<HarvestWeatherStrip> {
  static const double _cellW = 60;
  static const Color _harvestColor = Color(0xFFD9A441);

  final _service = HarvestWeatherService();
  final _ctl = ScrollController();
  late DateTime _from;
  late DateTime _to;
  late Future<List<DayWx>> _future;
  bool _scrolled = false;

  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _computeRange() {
    final today = _d(DateTime.now());
    if (widget.harvestTo != null) {
      _from = _d(widget.plantedOn);
      _to = _d(widget.harvestTo!);
      if (_to.isBefore(_from)) _to = _from;
      if (_to.difference(_from).inDays > 220) _to = _from.add(const Duration(days: 220));
    } else {
      // Pananim na walang takdang anihan: dalawang linggo bago at pagkatapos ng ngayon.
      final planted = _d(widget.plantedOn);
      final back = today.subtract(const Duration(days: 14));
      _from = planted.isAfter(back) ? planted : back;
      _to = today.add(const Duration(days: 15));
    }
  }

  Future<List<DayWx>> _load() =>
      _service.fetch(lat: widget.lat, lon: widget.lon, from: _from, to: _to);

  @override
  void initState() {
    super.initState();
    _computeRange();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HarvestWeatherStrip old) {
    super.didUpdateWidget(old);
    if (!_sameDay(old.plantedOn, widget.plantedOn) ||
        !_sameDay(old.harvestTo, widget.harvestTo) ||
        old.lat != widget.lat ||
        old.lon != widget.lon) {
      _computeRange();
      _scrolled = false;
      setState(() => _future = _load());
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  /// Ligtas na basahin ang scroll position: may clients na pero wala pang layout = null-check error.
  bool get _ready => _ctl.hasClients && _ctl.position.hasContentDimensions;

  void _scrollBy(double delta) {
    if (!_ready) return;
    final target = (_ctl.offset + delta).clamp(0.0, _ctl.position.maxScrollExtent);
    _ctl.animateTo(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  void _scrollToToday(int count) {
    if (_scrolled) return;
    _scrolled = true;
    final today = _d(DateTime.now());
    final idx = today.difference(_from).inDays.clamp(0, count - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ready) return;
      final target = (idx * _cellW - 90).clamp(0.0, _ctl.position.maxScrollExtent);
      _ctl.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasHarvest = widget.harvestTo != null;
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.cloud_rounded, size: 18, color: AppColors.soil),
        const SizedBox(width: 6),
        Expanded(
          child: Text(widget.title ?? (hasHarvest ? t.farmWxTitle : t.farmWxNoHarvest),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
        ),
      ]),
      if (widget.summary.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(widget.summary, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
      ],
      const SizedBox(height: 8),
      FutureBuilder<List<DayWx>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 96,
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
            );
          }
          if (snap.hasError || snap.data == null) {
            return SizedBox(
              height: 96,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.farmWxLoadFail, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  TextButton(
                    onPressed: () => setState(() {
                      _scrolled = false;
                      _future = _load();
                    }),
                    child: Text(t.farmWxRetry),
                  ),
                ]),
              ),
            );
          }
          return _buildStrip(context, t, snap.data!);
        },
      ),
    ]);
    if (widget.bare) return body;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: body,
    );
  }

  Widget _buildStrip(BuildContext context, AppLocalizations t, List<DayWx> data) {
    final locale = Localizations.localeOf(context).languageCode;
    final today = _d(DateTime.now());
    final count = _to.difference(_from).inDays + 1;
    final byDay = <String, DayWx>{for (final w in data) DateFormat('yyyy-MM-dd').format(w.date): w};
    final hFrom = widget.harvestFrom == null ? null : _d(widget.harvestFrom!);
    final hTo = widget.harvestTo == null ? null : _d(widget.harvestTo!);
    final hasTypical = data.any((w) => w.typical);
    _scrollToToday(count);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 98,
        child: Stack(children: [
          ScrollConfiguration(
            // Para gumana ang pag-drag gamit ang mouse (Chrome) at trackpad, hindi lang daliri.
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            }),
            child: ListView.builder(
              controller: _ctl,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemExtent: _cellW,
              itemCount: count,
              itemBuilder: (context, i) {
                final date = _from.add(Duration(days: i));
                final w = byDay[DateFormat('yyyy-MM-dd').format(date)];
                final isToday = date == today;
                final isPast = date.isBefore(today);
                final isHarvest = hFrom != null && hTo != null && !date.isBefore(hFrom) && !date.isAfter(hTo);
                return _DayCell(
                  label: isToday ? t.farmWxToday : DateFormat.MMMd(locale).format(date),
                  wx: w,
                  isPast: isPast,
                  isToday: isToday,
                  isHarvest: isHarvest,
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, child) {
              final has = _ready;
              final off = has ? _ctl.offset : 0.0;
              final max = has ? _ctl.position.maxScrollExtent : 1.0;
              return Stack(children: [
                if (off > 4)
                  Positioned(left: 0, top: 0, bottom: 0, child: _ArrowBtn(left: true, onTap: () => _scrollBy(-_cellW * 5))),
                if (!has || off < max - 4)
                  Positioned(right: 0, top: 0, bottom: 0, child: _ArrowBtn(left: false, onTap: () => _scrollBy(_cellW * 5))),
              ]);
            },
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 4, children: [
        if (_from.isBefore(today))
          _Legend(color: AppColors.leaf.withValues(alpha: 0.28), border: AppColors.leaf, label: t.farmWxPast),
        _Legend(color: Colors.white, border: AppColors.border, label: t.farmWxForecast),
        if (hasTypical)
          _Legend(color: Colors.white.withValues(alpha: 0.35), border: AppColors.border, label: t.farmWxTypical),
        if (hFrom != null) _Legend(color: _harvestColor, border: _harvestColor, label: t.farmWxHarvest, icon: Icons.agriculture_rounded),
      ]),
      if (hasTypical) ...[
        const SizedBox(height: 4),
        Text(t.farmWxNote, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.3)),
      ],
    ]);
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final DayWx? wx;
  final bool isPast;
  final bool isToday;
  final bool isHarvest;

  const _DayCell({
    required this.label,
    required this.wx,
    required this.isPast,
    required this.isToday,
    required this.isHarvest,
  });

  @override
  Widget build(BuildContext context) {
    final w = wx;
    final typical = w?.typical ?? false;
    Color bg;
    Color border;
    double borderW = 1;
    if (isToday) {
      bg = AppColors.leaf.withValues(alpha: 0.30);
      border = AppColors.leaf;
      borderW = 2;
    } else if (isPast) {
      bg = AppColors.leaf.withValues(alpha: 0.16);
      border = AppColors.leaf.withValues(alpha: 0.45);
    } else if (typical) {
      bg = Colors.white.withValues(alpha: 0.32);
      border = AppColors.border.withValues(alpha: 0.7);
    } else {
      bg = Colors.white.withValues(alpha: 0.8);
      border = AppColors.border;
    }
    final rain = w?.rainMm ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: borderW),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                        color: isToday ? AppColors.leaf : AppColors.ink)),
              ),
              if (w != null)
                Opacity(
                  opacity: typical ? 0.6 : 1,
                  child: WeatherIcon(glyph: glyphFor(w.code), size: 28),
                )
              else
                const SizedBox(height: 28, child: Center(child: Text('-', style: TextStyle(color: AppColors.muted)))),
              Text(
                w == null ? '' : '${w.maxC.round()}°',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontStyle: typical ? FontStyle.italic : FontStyle.normal,
                    color: AppColors.ink),
              ),
              SizedBox(
                height: 12,
                child: Text(
                  rain >= 0.5 ? '${rain.round()} mm' : '',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF2E7DB5), fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),
        ),
        if (isHarvest)
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Color(0xFFD9A441), shape: BoxShape.circle),
              child: const Icon(Icons.agriculture_rounded, size: 10, color: Colors.white),
            ),
          ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;
  final IconData? icon;
  const _Legend({required this.color, required this.border, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: icon != null ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: icon != null ? null : BorderRadius.circular(4),
          border: Border.all(color: border),
        ),
        child: icon != null ? Icon(icon, size: 9, color: Colors.white) : null,
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ]);
  }
}

class _ArrowBtn extends StatelessWidget {
  final bool left;
  final VoidCallback onTap;
  const _ArrowBtn({required this.left, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: Color(0x261B5E20), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Icon(left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: AppColors.leaf, size: 22),
        ),
      ),
    );
  }
}