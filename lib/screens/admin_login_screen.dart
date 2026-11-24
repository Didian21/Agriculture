import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/account_service.dart';
import 'admin_dashboard.dart';
import 'technician.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'admin123');

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final accountService = Provider.of<AccountService>(context, listen: false);
    final errorMessage = await accountService.authenticateAdminDetailed(username, password);

    if (!mounted) return;

    if (errorMessage == null) {
      final role = accountService.activeStaff.role.toLowerCase();
      final isTechnician = role.contains('technician') || role.contains('tekniko');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => isTechnician ? const TechnicianScreen() : const AdminDashboard(),
        ),
        (route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (alertCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text('Login Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(errorMessage, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
              onPressed: () => Navigator.pop(alertCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
                  'MAO STAFF PORTAL',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 1.5, color: Color(0xFF0056B3)),
                ),
                const Text(
                  'Municipal Agriculture Office - Pagsanjan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff & Technician Login',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Authorized municipal staff & agricultural technician access.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF0056B3)),
                            labelText: 'Username (admin / arnel_tech)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF0056B3)),
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0056B3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text(
                              'Login',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡 Demo Login Accounts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                              const SizedBox(height: 4),
                              Text('• Admin: admin / admin123', style: TextStyle(fontSize: 11.5, color: Colors.grey[800])),
                              Text('• Technician: arnel_tech / admin123 (Routes directly to Technician UI)', style: TextStyle(fontSize: 11.5, color: Colors.grey[800])),
                            ],
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
