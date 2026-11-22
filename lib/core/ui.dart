import 'package:flutter/material.dart';

import '../main.dart';

/// Iisang sukat ng espasyo sa buong app.
class AppSpace {
  static const double xs = 4, s = 8, m = 12, l = 16, xl = 24;
}

/// Iisang bilog ng mga sulok.
class AppRadius {
  static const double card = 20, chip = 14, tile = 14;
}

/// Iisang estilo ng teksto: pamagat ng pahina, seksyon, card, katawan, tala, at malalaking numero.
class AppText {
  static const pageTitle = TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.15);
  static const section = TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A));
  static const cardTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A));
  static const body = TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF0F172A), fontWeight: FontWeight.w500);
  static const small = TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xFF334155), fontWeight: FontWeight.w600);
  static const label = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B));
  static const number = TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1);
}

/// Iisang kahulugan ng kulay ng katayuan: berde = maganda, dilaw = mag-ingat, pula = babala, asul = impormasyon.
class StatusColor {
  static const good = AppColors.leaf;
  static const warn = Color(0xFFC0792E);
  static const bad = Color(0xFFC0503E);
  static const info = Color(0xFF3F8FC4);
}

class AppUi {
  /// Mas malalaking tapahan (hindi bababa sa 48 px) para sa chip, buton, at switch.
  static Widget wrap(BuildContext context, Widget child) {
    final base = Theme.of(context);
    const minBtn = Size(48, 48);
    return Theme(
      data: base.copyWith(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        chipTheme: base.chipTheme.copyWith(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: minBtn)),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: minBtn)),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: minBtn)),
        segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(minimumSize: minBtn)),
      ),
      child: child,
    );
  }
}