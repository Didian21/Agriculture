import 'package:flutter/material.dart';

import '../main.dart';
import '../dashboard_data.dart';

/// Line graph ng pagiging angkop ng bawat buwan para magtanim.
class CropGraph extends StatelessWidget {
  final PlantingGuide guide;
  final int month; // kasalukuyang buwan (1-12)
  final List<String> labels; // 12 pangalan ng buwan
  final String nowLabel;

  const CropGraph({
    super.key,
    required this.guide,
    required this.month,
    required this.labels,
    required this.nowLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(painter: _GraphPainter(guide, month, labels, nowLabel)),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final PlantingGuide guide;
  final int month;
  final List<String> labels;
  final String nowLabel;

  _GraphPainter(this.guide, this.month, this.labels, this.nowLabel);

  static const _left = 10.0;
  static const _right = 10.0;
  static const _top = 28.0;
  static const _bottom = 26.0;

  Color _dotColor(int m) {
    switch (guide.statusFor(m)) {
      case PlantStatus.best:
        return AppColors.leaf;
      case PlantStatus.possible:
        return const Color(0xFFEF8F00);
      case PlantStatus.avoid:
        return Colors.black38;
    }
  }

  void _text(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _left - _right;
    final h = size.height - _top - _bottom;
    final base = _top + h;
    final colW = w / 12;

    Offset pt(int m) => Offset(
      _left + (m - 0.5) / 12 * w,
      _top + h * (1 - guide.scoreFor(m) / 100),
    );

    // Kulay sa likod ng mga pinakamagandang buwan
    final band = Paint()..color = AppColors.leaf.withValues(alpha: 0.07);
    for (var m = 1; m <= 12; m++) {
      if (guide.bestMonths.contains(m)) {
        canvas.drawRect(Rect.fromLTWH(_left + (m - 1) * colW, _top, colW, h), band);
      }
    }

    // Mga guhit sa likod
    final grid = Paint()
      ..color = const Color(0xFFE0E8DD)
      ..strokeWidth = 1;
    for (final f in [0.0, 0.5, 1.0]) {
      final y = _top + h * f;
      canvas.drawLine(Offset(_left, y), Offset(_left + w, y), grid);
    }

    // Linya
    final path = Path()..moveTo(pt(1).dx, pt(1).dy);
    for (var m = 2; m <= 12; m++) {
      final a = pt(m - 1);
      final b = pt(m);
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final area = Path.from(path)
      ..lineTo(pt(12).dx, base)
      ..lineTo(pt(1).dx, base)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.leaf.withValues(alpha: 0.25),
            AppColors.leaf.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, _top, size.width, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.leaf
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Putol-putol na guhit sa kasalukuyang buwan
    final now = pt(month);
    final dash = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var y = _top; y < base; y += 8) {
      final y2 = y + 4 > base ? base : y + 4;
      canvas.drawLine(Offset(now.dx, y), Offset(now.dx, y2), dash);
    }

    // Mga tuldok
    for (var m = 1; m <= 12; m++) {
      canvas.drawCircle(pt(m), 4.5, Paint()..color = _dotColor(m));
    }
    canvas.drawCircle(now, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      now,
      8,
      Paint()
        ..color = AppColors.leaf
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(now, 4.5, Paint()..color = _dotColor(month));

    // Label ng "Ngayon"
    final nowX = now.dx.clamp(24.0, size.width - 24.0);
    _text(
      canvas,
      nowLabel,
      Offset(nowX, 10),
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.leaf),
    );

    // Mga buwan sa ibaba
    for (var m = 1; m <= 12; m++) {
      final isNow = m == month;
      _text(
        canvas,
        labels[m - 1],
        Offset(pt(m).dx, base + 14),
        TextStyle(
          fontSize: 9.5,
          fontWeight: isNow ? FontWeight.w900 : FontWeight.w600,
          color: isNow ? AppColors.leaf : Colors.black54,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}