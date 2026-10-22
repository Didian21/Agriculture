import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/admin_dashboard.dart';
import 'screens/farmer_dashboard.dart';
import 'screens/login_screen.dart';
import 'models/farmer.dart';
import 'services/account_service.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final service = AccountService();
          service.addFarmer(username: 'farmer1', password: 'pass', profileName: 'Juan dela Cruz');
          service.addFarmer(username: 'farmer2', password: 'pass', profileName: 'Maria Santos');
          return service;
        }),
      ],
      child: MaterialApp(
        title: 'Agriculture Design Preview',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        home: const PreviewScreen(),
      ),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design Previews - Choose Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
              icon: const Icon(Icons.login),
              label: const Text('Preview Login Screen'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Preview Admin Dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              icon: const Icon(Icons.person),
              label: const Text('Preview Farmer Dashboard'),
              onPressed: () {
                final sampleFarmer = Farmer(
                  username: 'farmer1',
                  password: 'pass',
                  profileName: 'Juan dela Cruz',
                  records: ['Harvest Jan: 500kg', 'Harvest Feb: 450kg'],
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FarmerDashboard(farmer: sampleFarmer)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
