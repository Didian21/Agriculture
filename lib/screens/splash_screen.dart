import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dashboard_data.dart';
import '../main.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        final p = Provider.of<DashboardProvider>(context, listen: false);
        final targetScreen = p.isLoggedIn ? const DashboardScreen() : widget.nextScreen;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secondAnim) => targetScreen,
            transitionsBuilder: (context, anim, secondaryAnim, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paddy,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/pagri_logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.leaf,
                          child: Icon(Icons.eco_rounded, color: Colors.white, size: 60),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PAGRI',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: 3,
                          color: AppColors.leaf,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pagsanjan Agricultural Decision Support System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.leaf,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Pagsanjan, Laguna',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
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
    );
  }
}
