import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/back_navigation.dart';
import '../providers/providers.dart';
import '../data/models/models.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/bookings/booking_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/tents/tent_detail_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/passport/passport_upload_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/bookings/qr_code_screen.dart';
import '../screens/profile/edit_profile_screen.dart';   // ← new
import '../screens/support/help_support_screen.dart';
import '../screens/support/ai_chat_screen.dart';
import '../screens/support/review_screen.dart';
import '../screens/support/rate_app_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/about/kumbh_history_screen.dart';
import '../screens/events/kumbh_calendar_screen.dart';
import '../screens/offers/offers_screen.dart';

/// A subtle fade + rise used for every pushed screen, so navigation feels
/// like one connected motion instead of a hard cut. 220ms is fast enough to
/// never feel like it's in the way.
///
/// Every screen is wrapped in [AppBackScope] so the Android system back
/// button / edge-swipe always routes to Home first (and, on Home, through
/// the tap-again-to-exit gate) rather than closing the app.
///
/// NOTE: the five bottom-nav routes used to share one hardcoded page key so
/// switching tabs felt instant instead of pushing a new route. That turned
/// out to be the root cause of three separate bugs (GoRouterState reporting
/// the wrong path, "back does nothing" on a tab, and finally the system
/// back button bypassing PopScope entirely and closing the app) — sharing
/// one page identity across five different locations put GoRouter into a
/// configuration it isn't designed for. Each route now gets its own real,
/// distinct page again; tab switches show the normal transition instead of
/// being instant, which is a small price for back navigation actually
/// working.
CustomTransitionPage<void> _page(Widget child) =>
    CustomTransitionPage(
      child: AppBackScope(child: child),
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );

class AppRouter {
  final AuthProvider authProvider;
  AppRouter(this.authProvider);

  late final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading       = authProvider.isLoading;
      final loc             = state.uri.toString();
      final publicRoutes    = [
        '/splash', '/login', '/register',
        '/onboarding', '/forgot-password',
      ];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));

      if (isLoading)                                         return null;
      if (!isAuthenticated && !isPublic)                     return '/login';
      if (isAuthenticated && (loc == '/login' || loc == '/register')) {
        return '/home';
      }

      // Email verification is compulsory — no "skip" escape hatch. Any
      // authenticated-but-unverified visitor is routed to /verify-email on
      // every navigation, including a restored session after the app was
      // fully closed and reopened, until they actually verify.
      final needsVerification = isAuthenticated &&
          !isPublic &&
          !(authProvider.visitor?.emailVerified ?? true);
      if (needsVerification && loc != '/verify-email') {
        return '/verify-email';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/',        redirect: (_, __) => '/splash'),
      GoRoute(path: '/splash',
          builder: (_, __) => const AppBackScope(child: SplashScreen())),
      GoRoute(path: '/onboarding',
          builder: (_, __) => const AppBackScope(child: OnboardingScreen())),
      GoRoute(path: '/login',
          builder: (_, __) => const AppBackScope(child: LoginScreen())),
      GoRoute(path: '/register',
          builder: (_, __) => const AppBackScope(child: RegisterScreen())),
      GoRoute(path: '/forgot-password',
          builder: (_, __) =>
              const AppBackScope(child: ForgotPasswordScreen())),
      GoRoute(path: '/verify-email',
          builder: (_, __) => const AppBackScope(child: VerifyEmailScreen())),

      // ── Main shell with bottom nav ──────────────────────
      GoRoute(path: '/home',
          pageBuilder: (_, __) => _page(const MainScaffold(initialIndex: 0))),
      GoRoute(path: '/search',
          pageBuilder: (_, __) => _page(const MainScaffold(initialIndex: 1))),
      GoRoute(path: '/my-bookings',
          pageBuilder: (_, __) => _page(const MainScaffold(initialIndex: 2))),
      GoRoute(path: '/news',
          pageBuilder: (_, __) => _page(const MainScaffold(initialIndex: 3))),
      GoRoute(path: '/profile',
          pageBuilder: (_, __) => _page(const MainScaffold(initialIndex: 4))),

      // ── Detail screens ──────────────────────────────────
      GoRoute(
        path: '/tent/:id',
        pageBuilder: (_, state) {
          final tent = state.extra as CapsuleTent?;
          if (tent == null) {
            return _page(const Scaffold(
                body: Center(child: Text('Tent not found'))));
          }
          return _page(TentDetailScreen(tent: tent));
        },
      ),
      GoRoute(
        path: '/book',
        pageBuilder: (_, state) {
          final tent = state.extra as CapsuleTent?;
          if (tent == null) {
            return _page(const Scaffold(
                body: Center(child: Text('Tent not found'))));
          }
          return _page(BookingScreen(tent: tent));
        },
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (_, state) {
          final booking = state.extra as TentBooking?;
          if (booking == null) {
            return _page(const Scaffold(
                body: Center(child: Text('Booking not found'))));
          }
          return _page(PaymentScreen(booking: booking));
        },
      ),
      GoRoute(
        path: '/booking-detail/:id',
        pageBuilder: (_, state) {
          final booking = state.extra as TentBooking?;
          if (booking == null) {
            return _page(const Scaffold(
                body: Center(child: Text('Booking not found'))));
          }
          return _page(BookingDetailScreen(booking: booking));
        },
      ),
      GoRoute(
        path: '/booking-qr/:id',
        pageBuilder: (_, state) {
          final booking = state.extra as TentBooking?;
          if (booking == null) {
            return _page(const Scaffold(
                body: Center(child: Text('Booking not found'))));
          }
          return _page(QRCodeScreen(booking: booking));
        },
      ),
      GoRoute(
        path: '/passport-upload',
        pageBuilder: (_, __) => _page(const PassportUploadScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, __) => _page(const NotificationsScreen()),
      ),

      // ── Edit Profile ─────────────────────────────────── ← new
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (_, __) => _page(const EditProfileScreen()),
      ),
      GoRoute(
        path: '/help-support',
        pageBuilder: (_, __) => _page(const HelpSupportScreen()),
      ),
      GoRoute(
        path: '/ai-chat',
        pageBuilder: (_, __) => _page(const AiChatScreen()),
      ),
      GoRoute(
        path: '/review',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final bookingId = extra?['bookingId'] as String?;
          if (bookingId == null) {
            return _page(const Scaffold(
                body: Center(child: Text('Booking not found'))));
          }
          return _page(ReviewScreen(
            bookingId: bookingId,
            tentName: extra?['tentName'] as String? ?? 'Your stay',
          ));
        },
      ),
      GoRoute(
        path: '/rate-app',
        pageBuilder: (_, __) => _page(const RateAppScreen()),
      ),
      GoRoute(
        path: '/wishlist',
        pageBuilder: (_, __) => _page(const WishlistScreen()),
      ),
      GoRoute(
        path: '/kumbh-history',
        pageBuilder: (_, __) => _page(const KumbhHistoryScreen()),
      ),
      GoRoute(
        path: '/kumbh-calendar',
        pageBuilder: (_, __) => _page(const KumbhCalendarScreen()),
      ),
      GoRoute(
        path: '/offers',
        pageBuilder: (_, __) => _page(const OffersScreen()),
      ),

    ],
  );
}  