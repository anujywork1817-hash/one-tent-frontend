import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

// ─── One Tent Design Tokens ───────────────────────────────────────────────
const Color _kInk   = Color(0xFF0D0401);
const Color _kGold  = Color(0xFFD4891A);
const Color _kCream = Color(0xFFF5E6C8);
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardPage {
  final String image;
  final String title;
  final String subtitle;
  const _OnboardPage(
      {required this.image, required this.title, required this.subtitle});
}

// Full-bleed real photography per page rather than an icon-in-a-circle —
// every image here is a real asset already used elsewhere in the app (the
// Home hero shot, a capsule-tent interior, the Mela calendar banner), not a
// stand-in for one.
const _pages = [
  _OnboardPage(
    image: 'assets/images/kumbh_hero.jpg',
    title: 'Welcome to Kumbh Mela',
    subtitle:
        'The world\'s largest spiritual gathering. Experience the sacred confluence of rivers and ancient traditions.',
  ),
  _OnboardPage(
    image: 'assets/images/tent_gallery_1.png',
    title: 'Capsule Tent Stays',
    subtitle:
        'Book modern, comfortable capsule tents right at the Mela grounds. Choose from Single, Double, and Luxury options.',
  ),
  _OnboardPage(
    image: 'assets/images/calendar_banner.jpg',
    title: 'Easy Booking',
    subtitle:
        'Browse available tents, pick your dates, and confirm your stay in minutes. Your spiritual journey awaits.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

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
      backgroundColor: _kInk,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _PageContent(page: _pages[i]),
          ),

          // Skip
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Skip',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _page == i
                            ? _kGold
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _page == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_page == _pages.length - 1)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Already have an account? Sign in',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13),
                    ),
                  )
                else
                  const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(page.image, fit: BoxFit.cover),

        // Scrim — clear over the top two-thirds of the photo, solid enough
        // at the bottom for the text and controls to stay legible over any
        // image, not a flat tint over the whole frame.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0x99000000),
                Color(0xF20D0401),
              ],
              stops: [0.0, 0.55, 0.85],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 190),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ).animate().fadeIn(duration: 400.ms).scaleX(
                    begin: 0, alignment: Alignment.centerLeft, curve: Curves.easeOut),
                const SizedBox(height: 16),
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _kCream,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ).animate().fadeIn(delay: 100.ms, duration: 450.ms).slideY(
                    begin: 0.15, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 12),
                Text(
                  page.subtitle,
                  style: TextStyle(
                    color: _kCream.withValues(alpha: 0.82),
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 220.ms, duration: 450.ms).slideY(
                    begin: 0.15, end: 0, curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
