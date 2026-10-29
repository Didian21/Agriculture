import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_data.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'providers/farm_input_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/farmer_login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/account_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (_) {}
  runApp(const FarmerApp());
}

class FarmerApp extends StatelessWidget {
  const FarmerApp({super.key});

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
          title: 'Pagri',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: Locale(p.isTagalog ? 'tl' : 'en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(nextScreen: FarmerLoginScreen(p: p)),
            '/': (context) => FarmerLoginScreen(p: p),
            '/dashboard': (context) => const DashboardScreen(),
          },
        ),
      ),
    );
  }
}
