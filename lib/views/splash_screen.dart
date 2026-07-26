import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
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
      backgroundColor: AppTheme.lightMintBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo mark ──
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(scale: _logoScale, child: child),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 44,
                  color: AppTheme.white,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── App name & tagline ──
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(position: _textSlide, child: child),
                );
              },
              child: Column(
                children: [
                  const Text(
                    'BIOTRACE',
                    style: TextStyle(
                      fontFamily: 'BerlinSansFB',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Amphibian Data Collection',
                    style: TextStyle(
                      fontFamily: 'BerlinSansFB',
                      fontSize: 12,
                      color: AppTheme.textMuted.withValues(alpha: 0.85),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // ── Subtle loading indicator ──
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Opacity(
                  opacity: _textFade.value,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
