import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSplashComplete;

  const SplashScreen({
    super.key,
    required this.authService,
    required this.onSplashComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Transition after 2.5s display duration
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onSplashComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B130E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Splash Image (Full Cover or Centered)
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/splashscreen.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) {
                  return Container(
                    color: const Color(0xFF0B130E),
                    child: Center(
                      child: Image.asset(
                        'assets/images/kisandrive_logo.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Dark Overlay & Branding Footer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // App Brand Title
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      children: [
                        TextSpan(text: 'Kisan', style: TextStyle(color: Color(0xFF22C55E))),
                        TextSpan(text: 'Drive ', style: TextStyle(color: Color(0xFFFACC15))),
                        TextSpan(text: 'ERP', style: TextStyle(color: Colors.white, fontSize: 22, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SaaS Tractor & Agricultural Fleet ERP',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.tealPrimary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
