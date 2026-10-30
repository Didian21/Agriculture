import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'dashboard_data.dart';
import 'l10n/app_localizations.dart';
import 'providers/farm_input_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/thank_you_screen.dart';
import 'services/account_service.dart';
import 'services/supabase_service.dart';

class AppConstants {
  // Pagsanjan, Laguna (default farm coordinates)
  static const double defaultLat = 14.2717;
  static const double defaultLon = 121.4553;
  static const String weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String timezone = 'Asia/Manila';

  /// Save your logo here and list it under `assets:` in pubspec.yaml
  static const String logoAsset = 'assets/images/pagri_logo.png';
}

/// Magaan at malambot na berdeng tema ng PAGRI (light, frosted-glass).
class AppColors {
  // Background at mga card
  static const bg0 = Color(0xFFD3E9CC); // ibaba ng background (mas matingkad na sage)
  static const bg1 = Color(0xFFF1F9EC); // taas ng background (halos puti)
  static const surface = Color(0xFFF8FCF5); // dialog, sheet, nav
  static const surfaceHi = Color(0xFFFFFFFF); // maliwanag na dulo ng card
  static const navBg = Color(0xFFF8FCF5); // bottom navigation
  static const border = Color(0xFFD3E6CE); // manipis na guhit ng card

  // Accent
  static const leaf = Color(0xFF2E7D32); // pangunahing berde - mga icon at highlight
  static const accentDark = Color(0xFF2E7D32); // pindutan na may puting teksto
  static const fern = Color(0xFF43A047); // pangalawang berde
  static const lime = Color(0xFF7CB342); // light green (logo)

  // Mga lumang pangalan
  static const mint = Color(0xFFE3F1DF); // panloob na kahon / tint
  static const paddy = Color(0xFFEFF7EB); // background
  static const soil = Color(0xFF8D6E63); // accent (kayumanggi)
  static const ink = Color(0xFF17391F); // pangunahing teksto (madilim na berde)
  static const muted = Color(0xFF5E7C64); // pangalawang teksto
  static const sun = Color(0xFFF9A825);
  static const rain = Color(0xFF1E88E5);

  // Pagtaas / pagbaba
  static const up = Color(0xFF2E7D32);
  static const down = Color(0xFFC62828);

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
      case 'Coconut':
      case 'Niyog':
        return const Color(0xFF8D6E4A);
      case 'Ampalaya':
        return const Color(0xFF4CAF50);
      case 'Squash':
      case 'Kalabasa':
        return const Color(0xFFEF8F1E);
      case 'Sweet potato':
      case 'Kamote':
        return const Color(0xFFB5568A);
      case 'Taro':
      case 'Gabi':
        return const Color(0xFF7E6BC4);
      case 'Calamansi':
        return const Color(0xFF9CB820);
      default:
        return fern;
    }
  }
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.leaf,
      onPrimary: Colors.white,
      secondary: AppColors.fern,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg1,
      canvasColor: AppColors.surface,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.leaf.withValues(alpha: 0.14),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.leaf : AppColors.muted,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected) ? AppColors.leaf : AppColors.muted,
        )),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xCCFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.leaf, textColor: AppColors.ink),
      iconTheme: const IconThemeData(color: AppColors.ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.leaf,
        linearTrackColor: AppColors.mint,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentDark,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.leaf,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.leaf),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? AppColors.accentDark : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.muted),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.mint,
        labelStyle: TextStyle(color: AppColors.ink),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.leaf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.leaf, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      errorBuilder: (context, error, stackTrace) => CircleAvatar(
        radius: height / 2,
        backgroundColor: AppColors.fern,
        child: Icon(Icons.eco, color: Colors.white, size: height * 0.6),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (_) {}
  runApp(const AgricultureApp());
}

class AgricultureApp extends StatelessWidget {
  const AgricultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountService()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..start()),
        ChangeNotifierProvider(create: (_) => FarmInputProvider()..load()),
      ],
      child: Consumer<DashboardProvider>(
        builder: (context, p, child) => MaterialApp(
          title: 'PAGRI - Pagsanjan Agriculture',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale(p.isTagalog ? 'tl' : 'en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(p.textScale)),
            child: child!,
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(nextScreen: LoginScreen(p: p)),
            '/': (context) => LoginScreen(p: p),
            '/dashboard': (context) => const DashboardScreen(),
            '/thank_you': (context) => const ThankYouScreen(),
          },
        ),
      ),
    );
  }
}
