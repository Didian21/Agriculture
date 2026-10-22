import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/account_service.dart';
import 'dashboard_data.dart';
import 'screens/login_screen.dart';
import 'screens/thank_you_screen.dart';

void main() {
  runApp(const AgricultureApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class AgricultureApp extends StatelessWidget {
  const AgricultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final service = AccountService();
          service.addFarmer(
            username: 'farmer1',
            password: 'pass',
            profileName: 'Juan dela Cruz',
            barangay: 'Biñan',
            contactNumber: '09171234567',
            organization: 'Pagsanjan Rice Farmers Coop',
          );
          service.addFarmer(
            username: 'farmer2',
            password: 'pass',
            profileName: 'Maria Santos',
            barangay: 'Buboy',
            contactNumber: '09189876543',
            organization: 'Anibong Vegetable Planters Assoc.',
          );
          return service;
        }),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<AccountService>(
        builder: (context, accountService, child) {
          final isDark = accountService.isDarkMode;
          return MaterialApp(
            title: 'PAGRI - Pagsanjan Agriculture System',
            debugShowCheckedModeBanner: false,
            scrollBehavior: MyCustomScrollBehavior(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1B5E20),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF0F4F9),
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(const Color(0xFF0056B3).withValues(alpha: 0.6)),
                radius: const Radius.circular(8),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1B5E20),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0A111E),
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(const Color(0xFF38BDF8).withValues(alpha: 0.6)),
                radius: const Radius.circular(8),
              ),
            ),
            home: const LoginScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/thank_you': (_) => const ThankYouScreen(),
            },
          );
        },
      ),
    );
  }
}
