import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Phase 1 (800ms) + Phase 2 (800ms) + Hold (1000ms) = 2600ms total
    Future.delayed(const Duration(milliseconds: 2600), () { 
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 60,
              height: 60,
            ).animate()
             .slideY(begin: 1.5, end: 0, duration: 800.ms, curve: Curves.easeOutBack)
             .fadeIn(duration: 800.ms),
             
            const SizedBox(width: 12),
            
            Image.asset(
              'assets/brand_text.png',
              height: 40,
            ).animate(delay: 800.ms)
             .slideX(begin: -0.2, end: 0, duration: 800.ms, curve: Curves.easeOutCubic)
             .fadeIn(duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
