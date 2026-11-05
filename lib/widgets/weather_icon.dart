import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Mas detalyadong uri ng panahon para sa mga icon (mas marami kaysa sa WeatherKind).
enum WeatherGlyph {
  clearDay,
  clearNight,
  partlyCloudyDay,
  partlyCloudyNight,
  cloudy,
  fog,
  drizzle,
  lightRain,
  rain,
  heavyRain,
  thunderstorm,
}

/// Kinukuha ang uri ng icon mula sa weather code ng Open-Meteo (WMO).
WeatherGlyph glyphFor(int code, {bool isDay = true}) {
  if (code == 0 || code == 1) return isDay ? WeatherGlyph.clearDay : WeatherGlyph.clearNight;
  if (code == 2) return isDay ? WeatherGlyph.partlyCloudyDay : WeatherGlyph.partlyCloudyNight;
  if (code == 3) return WeatherGlyph.cloudy;
  if (code == 45 || code == 48) return WeatherGlyph.fog;
  if (code >= 51 && code <= 57) return WeatherGlyph.drizzle;
  if (code == 61 || code == 80) return WeatherGlyph.lightRain;
  if (code == 63 || code == 81 || code == 66) return WeatherGlyph.rain;
  if (code == 65 || code == 82 || code == 67) return WeatherGlyph.heavyRain;
  if (code >= 95) return WeatherGlyph.thunderstorm;
  return WeatherGlyph.cloudy;
}

extension GlyphL10n on AppLocalizations {
  String glyphLabel(WeatherGlyph g) {
    switch (g) {
      case WeatherGlyph.clearDay:
        return weatherSunny;
      case WeatherGlyph.clearNight:
        return weatherClearNight;
      case WeatherGlyph.partlyCloudyDay:
      case WeatherGlyph.partlyCloudyNight:
        return weatherPartlyCloudy;
      case WeatherGlyph.cloudy:
        return weatherCloudy;
      case WeatherGlyph.fog:
        return weatherFoggy;
      case WeatherGlyph.drizzle:
        return weatherDrizzle;
      case WeatherGlyph.lightRain:
        return weatherLightRain;
      case WeatherGlyph.rain:
        return weatherRain;
      case WeatherGlyph.heavyRain:
        return weatherHeavyRain;
      case WeatherGlyph.thunderstorm:
        return weatherThunderstorm;
    }
  }
}

/// Makulay at detalyadong weather icon (iginuhit sa code, walang kailangang larawan).
/// `animated: true` = dahan-dahang umiikot ang sinag ng araw, bumabagsak ang ulan,
/// at bahagyang gumagalaw ang ulap. Gamitin lang sa malaking icon para magaan ang app.
class WeatherIcon extends StatefulWidget {
  final WeatherGlyph glyph;
  final double size;
  final bool animated;

  const WeatherIcon({super.key, required this.glyph, this.size = 48, this.animated = false});

  @override
  State<WeatherIcon> createState() => _WeatherIconState();
}

class _WeatherIconState extends State<WeatherIcon> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: c == null
            ? CustomPaint(painter: _GlyphPainter(widget.glyph, 0))
            : AnimatedBuilder(
          animation: c,
          builder: (_, __) => CustomPaint(painter: _GlyphPainter(widget.glyph, c.value)),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final WeatherGlyph g;
  final double t; // 0..1 (umuulit bawat 4 segundo)

  _GlyphPainter(this.g, this.t);

  static const _rainBlue = Color(0xFF2E9BF5);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width); // gumagamit ng unit square (0..1)
    final bob = math.sin(t * 2 * math.pi) * 0.012;

    switch (g) {
      case WeatherGlyph.clearDay:
        _sun(canvas, const Offset(0.5, 0.5), 0.2, rayIn: 1.35, rayOut: 1.85);
        break;
      case WeatherGlyph.clearNight:
        _moon(canvas, const Offset(0.5, 0.5), 0.26);
        _stars(canvas, const [Offset(0.18, 0.22), Offset(0.8, 0.3), Offset(0.74, 0.78)]);
        break;
      case WeatherGlyph.partlyCloudyDay:
        _sun(canvas, const Offset(0.36, 0.36), 0.15, rayIn: 1.35, rayOut: 1.8);
        _cloud(canvas, 0.2, 0.36 + bob, 0.74, const Color(0xFFFFFFFF), const Color(0xFFD3E2F0));
        break;
      case WeatherGlyph.partlyCloudyNight:
        _moon(canvas, const Offset(0.36, 0.34), 0.17);
        _stars(canvas, const [Offset(0.7, 0.18), Offset(0.14, 0.62)]);
        _cloud(canvas, 0.2, 0.36 + bob, 0.74, const Color(0xFFF3F7FB), const Color(0xFFC3D3E4));
        break;
      case WeatherGlyph.cloudy:
        _cloud(canvas, 0.06, 0.14 - bob, 0.62, const Color(0xFFCAD6E0), const Color(0xFF9FB3C4));
        _cloud(canvas, 0.22, 0.3 + bob, 0.74, const Color(0xFFFFFFFF), const Color(0xFFCFDDEA));
        break;
      case WeatherGlyph.fog:
        _cloud(canvas, 0.14, 0.08 + bob, 0.72, const Color(0xFFEFF3F7), const Color(0xFFC3D0DC));
        final slide = math.sin(t * 2 * math.pi) * 0.025;
        final fogPaint = Paint()
          ..color = const Color(0xFF9FB3C4)
          ..strokeWidth = 0.055
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(0.2 + slide, 0.66), Offset(0.8 + slide, 0.66), fogPaint);
        canvas.drawLine(Offset(0.28 - slide, 0.78), Offset(0.88 - slide, 0.78), fogPaint);
        canvas.drawLine(Offset(0.2 + slide, 0.9), Offset(0.7 + slide, 0.9), fogPaint);
        break;
      case WeatherGlyph.drizzle:
        _cloud(canvas, 0.12, 0.1 + bob, 0.76, const Color(0xFFF5F8FB), const Color(0xFFC9D7E4));
        _drops(canvas, x0: 0.26, x1: 0.78, y0: 0.62, y1: 0.95, count: 4, len: 0.07, width: 0.03, speed: 2, alpha: 0.75);
        break;
      case WeatherGlyph.lightRain:
        _cloud(canvas, 0.12, 0.1 + bob, 0.76, const Color(0xFFF1F5F9), const Color(0xFFBBCAD9));
        _drops(canvas, x0: 0.26, x1: 0.78, y0: 0.62, y1: 0.97, count: 4, len: 0.11, width: 0.036, speed: 2);
        break;
      case WeatherGlyph.rain:
        _cloud(canvas, 0.12, 0.08 + bob, 0.76, const Color(0xFFE2E9F0), const Color(0xFFA9BCCD));
        _drops(canvas, x0: 0.22, x1: 0.82, y0: 0.6, y1: 0.98, count: 6, len: 0.14, width: 0.04, speed: 3);
        break;
      case WeatherGlyph.heavyRain:
        _cloud(canvas, 0.1, 0.06 + bob, 0.8, const Color(0xFFA9B8C6), const Color(0xFF6F8497));
        _drops(canvas, x0: 0.18, x1: 0.84, y0: 0.56, y1: 0.99, count: 8, len: 0.17, width: 0.045, speed: 4);
        break;
      case WeatherGlyph.thunderstorm:
        _cloud(canvas, 0.1, 0.06 + bob, 0.8, const Color(0xFF9AA9B8), const Color(0xFF5F7285));
        _drops(canvas, x0: 0.16, x1: 0.34, y0: 0.6, y1: 0.97, count: 2, len: 0.12, width: 0.04, speed: 3);
        _drops(canvas, x0: 0.7, x1: 0.88, y0: 0.6, y1: 0.97, count: 2, len: 0.12, width: 0.04, speed: 3);
        final f = (t * 2) % 1.0;
        final flash = (f > 0.1 && f < 0.16) || (f > 0.22 && f < 0.27);
        _bolt(canvas, flash);
        break;
    }
    canvas.restore();
  }

  // --- Araw -----------------------------------------------------------------
  void _sun(Canvas c, Offset ctr, double r, {double rayIn = 1.3, double rayOut = 1.8}) {
    final rot = t * math.pi / 4; // 8 sinag => tuloy-tuloy ang pag-ulit
    final ray = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = r * 0.26
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = rot + i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(ctr + d * (r * rayIn), ctr + d * (r * rayOut), ray);
    }
    c.drawCircle(ctr, r * 1.14, Paint()..color = const Color(0x2EFFC107));
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFFF9800)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: ctr, radius: r)),
    );
  }

  // --- Buwan at mga bituin -------------------------------------------------
  void _moon(Canvas c, Offset ctr, double r) {
    final full = Path()..addOval(Rect.fromCircle(center: ctr, radius: r));
    final cut = Path()..addOval(Rect.fromCircle(center: ctr + Offset(r * 0.62, -r * 0.4), radius: r * 0.86));
    final moon = Path.combine(PathOperation.difference, full, cut);
    c.drawCircle(ctr, r * 1.2, Paint()..color = const Color(0x1FFFE082));
    c.drawPath(
      moon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F)],
        ).createShader(Rect.fromCircle(center: ctr, radius: r)),
    );
  }

  void _stars(Canvas c, List<Offset> pts) {
    for (var i = 0; i < pts.length; i++) {
      final tw = 0.55 + 0.45 * math.sin(t * 2 * math.pi + i * 1.7);
      final p = Paint()..color = const Color(0xFFFFE082).withValues(alpha: tw);
      final o = pts[i];
      const s = 0.03;
      final path = Path()
        ..moveTo(o.dx, o.dy - s * 1.5)
        ..lineTo(o.dx + s * 0.4, o.dy - s * 0.4)
        ..lineTo(o.dx + s * 1.5, o.dy)
        ..lineTo(o.dx + s * 0.4, o.dy + s * 0.4)
        ..lineTo(o.dx, o.dy + s * 1.5)
        ..lineTo(o.dx - s * 0.4, o.dy + s * 0.4)
        ..lineTo(o.dx - s * 1.5, o.dy)
        ..lineTo(o.dx - s * 0.4, o.dy - s * 0.4)
        ..close();
      c.drawPath(path, p);
    }
  }

  // --- Ulap -------------------------------------------------------------------
  Path _cloudPath(double x, double y, double w) {
    final h = w * 0.62;
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + h * 0.45, w, h * 0.55),
        Radius.circular(h * 0.275),
      ));
    final b1 = Path()..addOval(Rect.fromCircle(center: Offset(x + w * 0.31, y + h * 0.5), radius: w * 0.19));
    final b2 = Path()..addOval(Rect.fromCircle(center: Offset(x + w * 0.57, y + h * 0.4), radius: w * 0.26));
    final b3 = Path()..addOval(Rect.fromCircle(center: Offset(x + w * 0.79, y + h * 0.6), radius: w * 0.16));
    var p = Path.combine(PathOperation.union, base, b1);
    p = Path.combine(PathOperation.union, p, b2);
    p = Path.combine(PathOperation.union, p, b3);
    return p;
  }

  void _cloud(Canvas c, double x, double y, double w, Color top, Color bottom) {
    final path = _cloudPath(x, y, w);
    final h = w * 0.62;
    c.drawPath(path.shift(const Offset(0, 0.02)), Paint()..color = const Color(0x22000000));
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Rect.fromLTWH(x, y, w, h)),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012
        ..color = bottom.withValues(alpha: 0.9),
    );
  }

  // --- Ulan -------------------------------------------------------------------
  void _drops(
      Canvas c, {
        required double x0,
        required double x1,
        required double y0,
        required double y1,
        required int count,
        required double len,
        required double width,
        required double speed,
        double alpha = 1,
      }) {
    final paint = Paint()
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final fx = count == 1 ? (x0 + x1) / 2 : x0 + (x1 - x0) * i / (count - 1);
      final prog = (t * speed + i * 0.37) % 1.0;
      final y = y0 + (y1 - y0 - len) * prog;
      final fade = (0.35 + 0.65 * math.sin(prog * math.pi)) * alpha;
      paint.color = _rainBlue.withValues(alpha: fade.clamp(0.0, 1.0));
      c.drawLine(Offset(fx, y), Offset(fx - len * 0.3, y + len), paint);
    }
  }

  // --- Kidlat -----------------------------------------------------------------
  void _bolt(Canvas c, bool flash) {
    final path = Path()
      ..moveTo(0.54, 0.52)
      ..lineTo(0.4, 0.76)
      ..lineTo(0.5, 0.76)
      ..lineTo(0.44, 0.98)
      ..lineTo(0.66, 0.68)
      ..lineTo(0.55, 0.68)
      ..lineTo(0.62, 0.52)
      ..close();
    if (flash) {
      c.drawCircle(const Offset(0.52, 0.72), 0.3, Paint()..color = const Color(0x33FFEB3B));
    }
    c.drawPath(path, Paint()..color = flash ? const Color(0xFFFFEB3B) : const Color(0xFFFFC107));
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.014
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFF8F00),
    );
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.g != g || old.t != t;
}