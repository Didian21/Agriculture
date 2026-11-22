import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Malambot na larawan ng bukid (ulap, araw, at berdeng burol) na nasa likod ng buong app.
/// Iginuhit sa code kaya walang kailangang image file at magaan sa phone.
class FieldBackground extends StatelessWidget {
  const FieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: SizedBox.expand(child: CustomPaint(painter: _FieldPainter())),
    );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Langit
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
        ).createShader(rect),
    );

    // Banayad na liwanag ng araw
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.7, -0.85),
          radius: 0.9,
          colors: [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );

    void hill(double baseY, double amp, double freq, double phase, Color top, Color bottom) {
      final path = Path()..moveTo(0, h);
      const steps = 28;
      for (var i = 0; i <= steps; i++) {
        final x = w * i / steps;
        final y = h * baseY + h * amp * math.sin((i / steps) * math.pi * 2 * freq + phase);
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(Rect.fromLTWH(0, h * (baseY - amp), w, h * (1 - baseY + amp))),
      );
    }

    hill(0.48, 0.025, 0.8, 0.4, const Color(0xFFE2E8F0).withValues(alpha: 0.3), const Color(0xFFCBD5E1).withValues(alpha: 0.2));
    hill(0.68, 0.025, 1.1, 2.2, const Color(0xFFDCFCE7).withValues(alpha: 0.4), const Color(0xFFBBF7D0).withValues(alpha: 0.3));
    hill(0.85, 0.020, 0.9, 4.1, const Color(0xFF86EFAC).withValues(alpha: 0.3), const Color(0xFF4ADE80).withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}