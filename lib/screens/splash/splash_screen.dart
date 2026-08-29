

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kMaroon     = Color(0xFF4A1000);
const Color _kGold       = Color(0xFFD4891A);
const Color _kGoldLight  = Color(0xFFE8A830);
const Color _kCream      = Color(0xFFF2EAE0);
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    while (auth.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    if (auth.isAuthenticated) {
      context.go('/home');
      return;
    }

    final seen = await _storage.read(key: 'onboarding_done');
    if (!mounted) return;
    if (seen == null) {
      await _storage.write(key: 'onboarding_done', value: 'true');
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kMaroon,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background photo ───────────────────────────────────────────────
          Image.asset('assets/images/splash_bg.jpg', fit: BoxFit.cover),

          // Maroon scrim: the photo is bright and busy in the middle, which is
          // exactly where the app name and loader sit — this keeps them legible
          // without washing the image out.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kMaroon.withValues(alpha: 0.75),
                  _kMaroon.withValues(alpha: 0.55),
                  _kMaroon.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Temple icon badge
                Container(
                  width: 114,
                  height: 114,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kCream,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _kGold.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kGold.withValues(alpha: 0.18),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.5, 0.5)),

                const SizedBox(height: 30),

                // App name
                Text(
                  'One Tent',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: _kCream,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 10),

                // Gold accent divider
                Container(
                  width: 52,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate().fadeIn(delay: 450.ms).scaleX(
                      begin: 0,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 12),

                Text(
                  'Visitor Portal',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _kCream.withValues(alpha: 0.65),
                        letterSpacing: 1.4,
                      ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 60),

                // Loading indicator in gold
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: _kGoldLight,
                    strokeWidth: 2.5,
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 16),

                Text(
                  'Nashik, Maharashtra',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _kCream.withValues(alpha: 0.40),
                        letterSpacing: 0.8,
                      ),
                ).animate().fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}