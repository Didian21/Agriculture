import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // Pagsanjan, Laguna (default farm coordinates)
  static const double defaultLat = 14.2717;
  static const double defaultLon = 121.4553;
  static const String weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String timezone = 'Asia/Manila';

  /// Save your logo here and list it under `assets:` in pubspec.yaml
  static const String logoAsset = 'assets/images/pagri_logo.png';
}

class AppColors {
  static const leaf = Color(0xFF1B5E20); // primary deep green
  static const fern = Color(0xFF43A047); // secondary
  static const lime = Color(0xFFA5D63F); // logo light green
  static const mint = Color(0xFFE8F5E9); // card tint
  static const paddy = Color(0xFFF4F9F1); // page background
  static const soil = Color(0xFF8D6E63); // accent
  static const ink = Color(0xFF1F2A1F); // text
  static const sun = Color(0xFFFFB300);
  static const rain = Color(0xFF1E88E5);

  static Color forCrop(String crop) {
    switch (crop) {
      case 'Rice':
      case 'Palay':
        return const Color(0xFFC0A02B);
      case 'Eggplant':
      case 'Talong':
        return const Color(0xFF7B4FA3);
      case 'Tomato':
      case 'Kamatis':
        return const Color(0xFFE5533D);
      case 'String beans':
      case 'Sitaw':
        return const Color(0xFF2E9E5B);
      case 'Banana':
      case 'Saging':
        return const Color(0xFFE6A700);
      default:
        return fern;
    }
  }
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.leaf,
        primary: AppColors.leaf,
        secondary: AppColors.fern,
        surface: Colors.white,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paddy,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.leaf,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.leaf : Colors.black54,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected) ? AppColors.leaf : Colors.black45,
        )),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD7E8D4)),
        ),
      ),
    );
  }
}

/// Shows the PAGRI logo; falls back to a leaf icon if the asset is missing.
class PagriLogo extends StatelessWidget {
  final double height;
  const PagriLogo({super.key, this.height = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.logoAsset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => CircleAvatar(
        radius: height / 2,
        backgroundColor: AppColors.fern,
        child: Icon(Icons.eco, color: Colors.white, size: height * 0.6),
      ),
    );
  }
}
