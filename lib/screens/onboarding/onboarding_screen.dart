import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kMaroon     = Color(0xFF4A1000);
const Color _kMaroonMid  = Color(0xFF6B1A00);
const Color _kMaroonDeep = Color(0xFF3A0C00);
const Color _kGold       = Color(0xFFD4891A);
const Color _kGoldLight  = Color(0xFFE8A830);
const Color _kCream      = Color(0xFFF2EAE0);
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.temple_hindu,
      title: 'Welcome to Kumbh Mela',
      subtitle:
          'The world\'s largest spiritual gathering. Experience the sacred confluence of rivers and ancient traditions.',
      gradientStart: _kMaroon,
      gradientEnd: _kMaroonMid,
    ),
    _OnboardPage(
      icon: Icons.cabin,
      title: 'Capsule Tent Stays',
      subtitle:
          'Book modern, comfortable capsule tents right at the Mela grounds. Choose from Regular, Luxury, and Premium options.',
      gradientStart: _kMaroonMid,
      gradientEnd: _kMaroonDeep,
    ),
    _OnboardPage(
      icon: Icons.book_online,
      title: 'Easy Booking',
      subtitle:
          'Browse available tents, pick your dates, and confirm your stay in minutes. Your spiritual journey awaits.',
      gradientStart: _kMaroonDeep,
      gradientEnd: _kMaroon,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      context.go('/register');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _PageContent(page: _pages[i]),
          ),

          // Skip button
          Positioned(
            top: 56,
            right: 24,
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: _kCream.withValues(alpha: 0.70),
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i
                            ? _kGold
                            : _kGold.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGold,
                        foregroundColor: _kMaroon,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _page == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _kMaroon,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_page == _pages.length - 1)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                        color: _kCream.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [page.gradientStart, page.gradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Gold shimmer line across middle
          Positioned(
            top: MediaQuery.of(context).size.height * 0.52,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 160,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kGold.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 160),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon badge
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: _kGold.withValues(alpha: 0.50),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kGold.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(page.icon, size: 64, color: _kGold),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.6, 0.6)),

                  const SizedBox(height: 32),

                  // Gold accent bar
                  Container(
                    width: 44,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _kGoldLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().fadeIn(delay: 150.ms).scaleX(
                        begin: 0,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 20),

                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _kCream,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 16),

                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _kCream.withValues(alpha: 0.78),
                          height: 1.6,
                        ),
                  ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}