import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─── One Tent design tokens (kept local so this file has no theme import) ──
const Color _kMaroon = Color(0xFF4A1000);
// ─────────────────────────────────────────────────────────────────────────

/// Routes that ARE the "bottom" of navigation — pressing back here goes
/// through the tap-again-to-exit flow. `/home` is the normal case; the
/// pre-login screens are here too because `go('/home')` from them would only
/// redirect straight back.
const Set<String> _exitFromHereRoutes = {
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/forgot-password',
  '/verify-email',
  '/home',
};

/// How long the second back press has to land to actually exit the app.
const Duration _kExitWindow = Duration(seconds: 2);

DateTime? _lastExitTapAt;

/// The tap-again-to-exit gate. First back press shows a hint and returns
/// false (stay in the app); a second press within [_kExitWindow] returns
/// true (exit). Shared by every entry point so the two presses count
/// together no matter which screen fired them.
bool confirmExitByDoubleTap(BuildContext context) {
  final now = DateTime.now();
  if (_lastExitTapAt != null && now.difference(_lastExitTapAt!) <= _kExitWindow) {
    _lastExitTapAt = null;
    return true;
  }
  _lastExitTapAt = now;
  _showExitHint(context);
  return false;
}

void _showExitHint(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Press back again to exit'),
        duration: _kExitWindow,
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kMaroon,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

/// Wraps a screen so the **Android system back button / back gesture**
/// (edge swipe) does one of two things, never an immediate app exit:
///
///  * On any inner screen → jump straight to the Home screen (`/home`).
///  * On the Home screen (or a pre-login root screen) → show "Press back
///    again to exit"; a second press within two seconds closes the app.
///
/// On-screen AppBar back arrows keep working exactly as before — they call
/// `context.pop()` directly, which is not routed through this handler.
///
/// Applied centrally in the router config, so no screen needs its own
/// back-button code. (The Android manifest must also set
/// `android:enableOnBackInvokedCallback="true"` for the edge-swipe gesture
/// to reach this handler instead of finishing the Activity.)
class AppBackScope extends StatelessWidget {
  const AppBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // The location of *this* route (the screen the wrapper is on), not
        // router.currentConfiguration — after a context.push() the latter
        // still reports the last go() location (e.g. '/home'), which made a
        // pushed screen like /tent/:id wrongly trigger the exit prompt.
        final location = GoRouterState.of(context).uri.path;

        if (_exitFromHereRoutes.contains(location)) {
          if (confirmExitByDoubleTap(context)) {
            await SystemNavigator.pop();
          }
          return;
        }

        // Everything else — a non-Home bottom-nav tab, or any pushed inner
        // screen however deep — returns to Home in a single step.
        if (context.mounted) GoRouter.of(context).go('/home');
      },
      child: child,
    );
  }
}
