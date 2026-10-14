import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/account_service.dart';
import '../dashboard_data.dart';
import 'admin_dashboard.dart';
import 'dashboard_screen.dart';

enum LoginRole { farmer, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole _selectedRole = LoginRole.farmer;

  final _usernameController = TextEditingController(text: 'farmer1');
  final _passwordController = TextEditingController(text: 'password123');
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(LoginRole role) {
    setState(() {
      _selectedRole = role;
      if (role == LoginRole.admin) {
        _usernameController.text = 'admin';
        _passwordController.text = 'admin123';
      } else {
        _usernameController.text = 'farmer1';
        _passwordController.text = 'password123';
      }
    });
  }

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

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
      // Farmer Login
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final accountService = Provider.of<AccountService>(context, listen: false);

      final farmer = accountService.authenticateFarmer(username, password);
      if (farmer != null || username.isNotEmpty) {
        dashboardProvider.login();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Farmer Credentials')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFarmer = _selectedRole == LoginRole.farmer;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header section
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('Pagri.jpg', width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56, height: 56,
                          color: Colors.green,
                          child: const Icon(Icons.agriculture, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PAGRI',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Municipal Agricultural Office',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // White Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Welcome to PAGRI Portal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
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
                                    color: isFarmer ? Colors.green[800] : Colors.transparent,
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
                      const SizedBox(height: 24),

                      // Input Fields
                      Text(
                        isFarmer ? 'Farmer Username / Phone' : 'Admin Username / ID',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF34495E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            isFarmer ? Icons.person_rounded : Icons.badge_rounded,
                            color: isFarmer ? Colors.green[800] : const Color(0xFF0056B3),
                          ),
                          hintText: isFarmer ? 'Enter username (e.g. farmer1)' : 'Enter admin username',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Password / Passcode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF34495E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.lock_rounded,
                            color: isFarmer ? Colors.green[800] : const Color(0xFF0056B3),
                          ),
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Remember me
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: isFarmer ? Colors.green[800] : const Color(0xFF0056B3),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 13, color: Color(0xFF34495E)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login_rounded, color: Colors.white),
                          label: Text(
                            isFarmer ? 'Login as Farmer' : 'Login as Admin',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFarmer ? Colors.green[800] : const Color(0xFF0056B3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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
