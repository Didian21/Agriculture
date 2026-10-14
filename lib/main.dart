import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/account_service.dart';
import 'dashboard_data.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountService()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..start()),
      ],
      child: const AgricultureApp(),
    ),
  );
}

class AgricultureApp extends StatelessWidget {
  const AgricultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agriculture System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
          secondary: Colors.lightGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
}
