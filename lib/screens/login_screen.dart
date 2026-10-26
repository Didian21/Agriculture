import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dashboard_data.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/account_service.dart';
import 'admin_dashboard.dart';
import 'dashboard/dashboard_screen.dart';

enum LoginRole { farmer, admin }

class LoginScreen extends StatefulWidget {
  final DashboardProvider p;
  const LoginScreen({super.key, required this.p});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole _selectedRole = LoginRole.farmer;
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _switchRole(LoginRole role) {
    setState(() {
      _selectedRole = role;
      if (role == LoginRole.admin) {
        _phoneCtrl.text = 'admin';
        _pinCtrl.text = 'admin123';
      } else {
        _phoneCtrl.clear();
        _pinCtrl.clear();
      }
    });
  }

  void _login() {
    final username = _phoneCtrl.text.trim();
    final password = _pinCtrl.text.trim();

    if (_selectedRole == LoginRole.admin) {
      final accountService = Provider.of<AccountService>(context, listen: false);
      if (accountService.authenticateAdmin(username, password)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Admin Username or Password')),
        );
      }
    } else {
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
    final isFarmer = _selectedRole == LoginRole.farmer;

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
                  'PAGRI',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: 2, color: AppColors.leaf),
                ),
                Text(
                  t.portalTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black54),
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
                          isFarmer ? t.signInHint : 'Enter admin credentials to manage municipal records.',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),

                        // Role Selector Tabs (Farmer / Admin)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _switchRole(LoginRole.farmer),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isFarmer ? AppColors.leaf : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.agriculture_rounded,
                                          size: 18,
                                          color: isFarmer ? Colors.white : Colors.black54,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Farmer',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isFarmer ? Colors.white : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _switchRole(LoginRole.admin),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !isFarmer ? const Color(0xFF0056B3) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings_rounded,
                                          size: 18,
                                          color: !isFarmer ? Colors.white : Colors.black54,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Admin',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: !isFarmer ? Colors.white : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: isFarmer ? TextInputType.phone : TextInputType.text,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              isFarmer ? Icons.phone_rounded : Icons.badge_rounded,
                              color: isFarmer ? AppColors.leaf : const Color(0xFF0056B3),
                            ),
                            labelText: isFarmer ? t.phoneNumber : 'Admin Username',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          keyboardType: isFarmer ? TextInputType.number : TextInputType.text,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              color: isFarmer ? AppColors.leaf : const Color(0xFF0056B3),
                            ),
                            labelText: isFarmer ? t.pinLabel : 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: isFarmer ? AppColors.accentDark : const Color(0xFF0056B3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              isFarmer ? t.signIn : 'Login as Admin',
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
