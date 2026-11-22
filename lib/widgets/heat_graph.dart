import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/heat_index.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/weather_models.dart';

/// Moderno at minimal na graph ng heat index kada oras ngayong araw.
/// Pindutin o i-drag ang daliri sa graph para makita ang oras at heat index.
class HeatGraph extends StatefulWidget {
  final List<HourlyWeather> hours;
  final DateTime now;
  const HeatGraph({super.key, required this.hours, required this.now});

  @override
  State<HeatGraph> createState() => _HeatGraphState();
}

class _HeatGraphState extends State<HeatGraph> {
  int? _sel;

  int get _peakIndex {
    var best = 0;
    for (var i = 1; i < widget.hours.length; i++) {
      if (widget.hours[i].heat.celsius > widget.hours[best].heat.celsius) best = i;
    }
    return best;
  }

  int get _nowIndex {
    final i = widget.hours.indexWhere((h) => h.time.hour == widget.now.hour);
    return i >= 0 ? i : _peakIndex;
  }

  /// Pinakamahabang tuloy-tuloy na oras na hindi pa "Extreme caution" pataas.
  ({DateTime from, DateTime to})? _safeWindow() {
    int? bestStart;
    var bestLen = 0;
    int? curStart;
    for (var i = 0; i <= widget.hours.length; i++) {
      final ok = i < widget.hours.length && widget.hours[i].heat.level.index <= HeatLevel.caution.index;
      if (ok) {
        curStart ??= i;
      } else if (curStart != null) {
        final len = i - curStart;
        if (len > bestLen) {
          bestLen = len;
          bestStart = curStart;
        }
        curStart = null;
      }
    }
    if (bestStart == null) return null;
    return (
    from: widget.hours[bestStart].time,
    to: widget.hours[bestStart + bestLen - 1].time.add(const Duration(hours: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final hours = widget.hours;
    String fmt(DateTime d) => DateFormat('h a', locale).format(d);

    final sel = (_sel ?? _nowIndex).clamp(0, hours.length - 1);
    final cur = hours[sel];
    final curColor = heatColor(cur.heat.level);
    final peak = hours[_peakIndex];
    final peakColor = heatColor(peak.heat.level);
    final win = _safeWindow();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.heatTimeline, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${cur.heat.celsius.round()}°C',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: curColor, height: 1.0)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${sel == _nowIndex && _sel == null ? t.now : fmt(cur.time)} • ${t.heatLevelName(cur.heat.level)}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      const SizedBox(height: 6),
      SizedBox(
        height: 150,
        child: LayoutBuilder(builder: (context, box) {
          void pick(double dx) {
            final n = hours.length;
            final i = (dx / box.maxWidth * (n - 1)).round().clamp(0, n - 1);
            if (i != _sel) setState(() => _sel = i);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, progress, __) => CustomPaint(
                size: Size(box.maxWidth, 150),
                painter: _HeatGraphPainter(
                  values: [for (final h in hours) h.heat.celsius],
                  selected: sel,
                  progress: progress,
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 2),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(fmt(hours.first.time), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        Text(fmt(hours[hours.length ~/ 2].time), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        Text(fmt(hours.last.time), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.local_fire_department_rounded,
            color: peakColor,
            title: t.heatHottest,
            value: '${fmt(peak.time)} • ${peak.heat.celsius.round()}°C',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoChip(
            icon: Icons.agriculture_rounded,
            color: AppColors.leaf,
            title: t.heatBestWork,
            value: win == null ? t.heatNoSafe : '${fmt(win.from)} – ${fmt(win.to)}',
          ),
        ),
      ]),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  const _InfoChip({required this.icon, required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 10.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

class _HeatGraphPainter extends CustomPainter {
  final List<double> values;
  final int selected;
  final double progress;
  _HeatGraphPainter({required this.values, required this.selected, required this.progress});

  static const _padTop = 10.0;
  static const _padBottom = 6.0;
  static const _padRight = 24.0;
  static const _thresholds = [52.0, 42.0, 33.0, 27.0];

  static Color _colorAbove(double v) {
    if (v >= 52) return heatColor(HeatLevel.extremeDanger);
    if (v >= 42) return heatColor(HeatLevel.danger);
    if (v >= 33) return heatColor(HeatLevel.extremeCaution);
    if (v >= 27) return heatColor(HeatLevel.caution);
    return heatColor(HeatLevel.normal);
  }

  static Color _colorBelow(double v) => _colorAbove(v - 0.01);

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;

    var lo = (values.reduce(math.min) - 2).floorToDouble();
    var hi = (values.reduce(math.max) + 2).ceilToDouble();
    if (hi - lo < 8) {
      final mid = (hi + lo) / 2;
      lo = mid - 4;
      hi = mid + 4;
    }

    final chartW = size.width - _padRight;
    final chartH = size.height - _padTop - _padBottom;
    double xAt(int i) => i * chartW / (n - 1);
    double yAt(double v) => _padTop + (hi - v) / (hi - lo) * chartH;

    // Mahinang guhit ng mga antas (dashed) + maliit na numero sa kanan.
    for (final th in _thresholds) {
      if (th <= lo || th >= hi) continue;
      final y = yAt(th);
      final p = Paint()
        ..color = _colorAbove(th).withValues(alpha: 0.35)
        ..strokeWidth = 1;
      var x = 0.0;
      while (x < chartW) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, chartW), y), p);
        x += 8;
      }
      final tp = TextPainter(
        text: TextSpan(text: '${th.toInt()}', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height / 2));
    }

    // Makinis na kurba.
    final pts = [for (var i = 0; i < n; i++) Offset(xAt(i), yAt(values[i]))];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < n - 1; i++) {
      final mx = (pts[i].dx + pts[i + 1].dx) / 2;
      line.cubicTo(mx, pts[i].dy, mx, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    // Kulay ng guhit ayon sa taas ng heat index.
    final colors = <Color>[_colorAbove(hi)];
    final stops = <double>[0.0];
    for (final th in _thresholds) {
      if (th <= lo || th >= hi) continue;
      final f = (hi - th) / (hi - lo);
      final a = math.max(stops.last, f - 0.03);
      final b = math.min(1.0, math.max(a, f + 0.03));
      colors.add(_colorAbove(th));
      stops.add(a);
      colors.add(_colorBelow(th));
      stops.add(b);
    }
    colors.add(_colorAbove(lo));
    stops.add(1.0);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromLTWH(0, _padTop, chartW, chartH));

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartW * progress + 1, size.height));

    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height - _padBottom)
      ..lineTo(pts.first.dx, size.height - _padBottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _colorAbove(values.reduce(math.max)).withValues(alpha: 0.22),
            _colorAbove(values.reduce(math.max)).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, _padTop, chartW, chartH)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // Napiling oras: manipis na patayong guhit at bilog.
    final sp = pts[selected];
    if (xAtVisible(sp.dx, chartW * progress)) {
      canvas.drawLine(
        Offset(sp.dx, sp.dy),
        Offset(sp.dx, size.height - _padBottom),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.15)
          ..strokeWidth = 1.5,
      );
      final c = _colorAbove(values[selected]);
      canvas.drawCircle(sp, 7, Paint()..color = c.withValues(alpha: 0.20));
      canvas.drawCircle(sp, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        sp,
        5,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  bool xAtVisible(double x, double limit) => x <= limit;

  @override
  bool shouldRepaint(covariant _HeatGraphPainter old) =>
      old.selected != selected || old.progress != progress || old.values != values;
}