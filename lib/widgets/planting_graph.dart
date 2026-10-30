import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/dss_service.dart';

/// Mahinahong kulay (hindi matingkad) para sa Pinakamainam / Puwede / Iwasan.
Color fitColorOf(PlantFit f) {
  switch (f) {
    case PlantFit.best:
      return AppColors.leaf;
    case PlantFit.possible:
      return const Color(0xFFC9A23F); // malumanay na ginto
    case PlantFit.avoid:
      return const Color(0xFF8FA394); // malabong abo-berde
  }
}

/// Modern at simpleng graph ng 12 buwan: mataas ang kurba = magandang buwan para magtanim.
/// Pindutin o i-drag ang daliri para makita ang bawat buwan.
class PlantingGraph extends StatefulWidget {
  final String crop;
  final int nowMonth;
  final List<String> monthLabels; // 12 maikling pangalan ng buwan
  final String Function(PlantFit) fitLabel;
  final String nowLabel;

  const PlantingGraph({
    super.key,
    required this.crop,
    required this.nowMonth,
    required this.monthLabels,
    required this.fitLabel,
    required this.nowLabel,
  });

  @override
  State<PlantingGraph> createState() => _PlantingGraphState();
}

class _PlantingGraphState extends State<PlantingGraph> {
  int? _sel;
  static const _padRight = 50.0;

  @override
  Widget build(BuildContext context) {
    final fits = [for (var m = 1; m <= 12; m++) DssService.fitFor(widget.crop, m)];
    final sel = _sel ?? widget.nowMonth;
    final selFit = fits[sel - 1];
    final c = fitColorOf(selFit);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Text(
            '${widget.monthLabels[sel - 1]} • ${widget.fitLabel(selFit)}',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: c),
          ),
        ),
        if (sel == widget.nowMonth) ...[
          const SizedBox(width: 8),
          Text(widget.nowLabel, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
        ],
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 130,
        child: LayoutBuilder(builder: (context, box) {
          final chartW = box.maxWidth - _padRight;
          void pick(double dx) {
            final i = (dx / chartW * 12).floor().clamp(0, 11) + 1;
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
              builder: (_, progress, _) => CustomPaint(
                size: Size(box.maxWidth, 130),
                painter: _PlantingPainter(
                  fits: fits,
                  selected: sel,
                  progress: progress,
                  padRight: _padRight,
                  bestLabel: widget.fitLabel(PlantFit.best),
                  possibleLabel: widget.fitLabel(PlantFit.possible),
                  avoidLabel: widget.fitLabel(PlantFit.avoid),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (context, box) {
        final cw = (box.maxWidth - _padRight) / 12;
        return Row(children: [
          for (var m = 1; m <= 12; m++)
            SizedBox(
              width: cw,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  decoration: BoxDecoration(
                    color: m == widget.nowMonth ? AppColors.leaf.withValues(alpha: 0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.monthLabels[m - 1],
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: (m == sel || m == widget.nowMonth) ? FontWeight.w900 : FontWeight.w600,
                      color: m == sel ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ]);
      }),
    ]);
  }
}

class _PlantingPainter extends CustomPainter {
  final List<PlantFit> fits;
  final int selected; // 1-12
  final double progress;
  final double padRight;
  final String bestLabel;
  final String possibleLabel;
  final String avoidLabel;

  _PlantingPainter({
    required this.fits,
    required this.selected,
    required this.progress,
    required this.padRight,
    required this.bestLabel,
    required this.possibleLabel,
    required this.avoidLabel,
  });

  static const _top = 12.0;
  static const _bottom = 8.0;

  static double _score(PlantFit f) {
    switch (f) {
      case PlantFit.best:
        return 1.0;
      case PlantFit.possible:
        return 0.5;
      case PlantFit.avoid:
        return 0.08;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - padRight;
    final h = size.height - _top - _bottom;
    final cw = chartW / 12;
    double yOf(double s) => _top + (1 - s) * h;
    double xOf(int i) => (i + 0.5) * cw;

    // Malalambot na haligi sa likod: berde para sa pinakamainam, ginto para sa puwede.
    for (var i = 0; i < 12; i++) {
      final f = fits[i];
      if (f == PlantFit.avoid) continue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * cw + 1.5, 0, cw - 3, size.height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = fitColorOf(f).withValues(alpha: f == PlantFit.best ? 0.10 : 0.07));
    }

    // Mahinang guhit at pangalan ng antas sa kanan.
    void guide(double s, String label, Color color) {
      final y = yOf(s);
      final p = Paint()
        ..color = AppColors.border
        ..strokeWidth = 1;
      var x = 0.0;
      while (x < chartW) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, chartW), y), p);
        x += 8;
      }
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: padRight - 6);
      tp.paint(canvas, Offset(size.width - padRight + 6, y - tp.height / 2));
    }

    guide(1.0, bestLabel, fitColorOf(PlantFit.best));
    guide(0.5, possibleLabel, fitColorOf(PlantFit.possible));
    guide(0.08, avoidLabel, fitColorOf(PlantFit.avoid));

    // Makinis na kurba.
    final pts = [for (var i = 0; i < 12; i++) Offset(xOf(i), yOf(_score(fits[i])))];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < 11; i++) {
      final mx = (pts[i].dx + pts[i + 1].dx) / 2;
      line.cubicTo(mx, pts[i].dy, mx, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    final plotRect = Rect.fromLTWH(0, _top, chartW, h);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartW * progress + 1, size.height));

    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height - _bottom)
      ..lineTo(pts.first.dx, size.height - _bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.leaf.withValues(alpha: 0.20), AppColors.leaf.withValues(alpha: 0.0)],
        ).createShader(plotRect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fitColorOf(PlantFit.best), fitColorOf(PlantFit.possible), fitColorOf(PlantFit.avoid)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(plotRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // Napiling buwan.
    final sp = pts[selected - 1];
    if (sp.dx <= chartW * progress) {
      canvas.drawLine(
        Offset(sp.dx, sp.dy),
        Offset(sp.dx, size.height - _bottom),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.15)
          ..strokeWidth = 1.5,
      );
      final c = fitColorOf(fits[selected - 1]);
      canvas.drawCircle(sp, 8, Paint()..color = c.withValues(alpha: 0.20));
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

  @override
  bool shouldRepaint(covariant _PlantingPainter old) => old.selected != selected || old.progress != progress;
}