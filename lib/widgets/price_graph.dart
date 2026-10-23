import 'package:flutter/material.dart';

/// Line graph ng inaasahang presyo (PHP kada kg).
/// Ang unang halaga ay ang kasalukuyang presyo (may putol-putol na guhit bilang batayan).
class PriceGraph extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;

  const PriceGraph({super.key, required this.values, required this.labels, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => CustomPaint(
          painter: _PricePainter(values: values, labels: labels, color: color, progress: v),
        ),
      ),
    );
  }
}

class _PricePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double progress;

  _PricePainter({required this.values, required this.labels, required this.color, required this.progress});

  static const double _left = 40, _right = 14, _top = 18, _bottom = 24;

  void _text(Canvas canvas, String s, Offset at,
      {double size = 10, Color c = const Color(0xFF5F7A66), FontWeight w = FontWeight.w500, bool center = false, bool rightAlign = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: c, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (center) dx -= tp.width / 2;
    if (rightAlign) dx -= tp.width;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final w = size.width - _left - _right;
    final h = size.height - _top - _bottom;

    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    var span = hi - lo;
    if (span < 1.0) {
      final mid = (hi + lo) / 2;
      lo = mid - 0.5;
      hi = mid + 0.5;
      span = 1.0;
    }
    lo -= span * 0.15;
    hi += span * 0.15;

    double x(int i) => _left + w * i / (values.length - 1);
    double y(double v) => _top + h * (1 - (v - lo) / (hi - lo));

    // Grid at presyo sa kaliwa
    final grid = Paint()
      ..color = const Color(0xFFD3E6CB)
      ..strokeWidth = 1;
    final decimals = (hi - lo) < 6 ? 1 : 0;
    for (var k = 0; k <= 3; k++) {
      final v = lo + (hi - lo) * k / 3;
      final yy = y(v);
      canvas.drawLine(Offset(_left, yy), Offset(size.width - _right, yy), grid);
      _text(canvas, '₱${v.toStringAsFixed(decimals)}', Offset(_left - 6, yy), rightAlign: true, size: 9.5);
    }

    // Batayan: kasalukuyang presyo (putol-putol)
    final base = Paint()
      ..color = const Color(0xFF5F7A66)
      ..strokeWidth = 1.2;
    final by = y(values.first);
    for (double dx = _left; dx < size.width - _right; dx += 8) {
      canvas.drawLine(Offset(dx, by), Offset((dx + 4).clamp(0, size.width - _right), by), base);
    }

    // Linya at lilim
    final count = ((values.length - 1) * progress).floor();
    final frac = ((values.length - 1) * progress) - count;
    final pts = <Offset>[for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i]))];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i <= count; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    Offset tip = pts[count];
    if (count < values.length - 1) {
      final a = pts[count], b = pts[count + 1];
      tip = Offset(a.dx + (b.dx - a.dx) * frac, a.dy + (b.dy - a.dy) * frac);
      path.lineTo(tip.dx, tip.dy);
    }

    final area = Path.from(path)
      ..lineTo(tip.dx, size.height - _bottom)
      ..lineTo(pts.first.dx, size.height - _bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(_left, _top, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Mga tuldok at label ng araw
    for (var i = 0; i < pts.length; i++) {
      final isLast = i == pts.length - 1;
      if (i <= count) {
        canvas.drawCircle(pts[i], isLast ? 5.5 : 3.5, Paint()..color = isLast ? color : Colors.white);
        if (!isLast) {
          canvas.drawCircle(
            pts[i],
            3.5,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
      if (i < labels.length) {
        _text(canvas, labels[i], Offset(x(i), size.height - _bottom + 13), center: true, size: 9.5);
      }
    }

    // Halaga sa dulo
    if (progress >= 1) {
      final last = pts.last;
      _text(canvas, '₱${values.last.toStringAsFixed(2)}', Offset(last.dx, last.dy - 13),
          rightAlign: true, size: 11, c: color, w: FontWeight.w900);
    }
  }

  @override
  bool shouldRepaint(covariant _PricePainter old) =>
      old.progress != progress || old.color != color || old.values != values || old.labels != labels;
}