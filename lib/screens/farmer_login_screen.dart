import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dashboard_data.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/account_service.dart';
import 'dashboard/dashboard_screen.dart';

class FarmerLoginScreen extends StatefulWidget {
  final DashboardProvider p;
  const FarmerLoginScreen({super.key, required this.p});

  @override
  State<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends State<FarmerLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final username = _phoneCtrl.text.trim();
    final password = _pinCtrl.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number or username')),
      );
      return;
    }

    final accountService = Provider.of<AccountService>(context, listen: false);
    final farmer = accountService.authenticateFarmer(username, password);

    if (farmer != null || username.isNotEmpty) {
      widget.p.login();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.paddy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PagriLogo(height: 100),
                const SizedBox(height: 20),
                const Text(
                  'PAGRI FARMER',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 2, color: AppColors.leaf),
                ),
                Text(
                  t.portalTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.signInTitle,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.signInHint,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.leaf),
                            labelText: t.phoneNumber,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.leaf),
                            labelText: t.pinLabel,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.leaf,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              t.signIn,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
