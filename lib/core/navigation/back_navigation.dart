import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─── One Tent design tokens (kept local so this file has no theme import) ──
const Color _kMaroon = Color(0xFF4A1000);
// ─────────────────────────────────────────────────────────────────────────

/// Pre-login root routes where a back press should offer to exit the app —
/// `go('/home')` from any of these would only redirect straight back, so
/// there's nothing else useful back can do. Uses the quick tap-again gate;
/// `/home` itself gets a real confirmation dialog instead (see below).
const Set<String> _exitFromHereRoutes = {
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/forgot-password',
  '/verify-email',
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

/// Guards against a second dialog stacking on top of the first if back is
/// somehow pressed again before the first one resolves.
bool _exitDialogOpen = false;

/// The Home screen's "Are you sure you want to exit?" confirmation. Returns
/// true only if the guest taps Exit.
Future<bool> confirmExitDialog(BuildContext context) async {
  if (_exitDialogOpen) return false;
  _exitDialogOpen = true;
  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Exit One Tent?',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: _kMaroon),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(fontSize: 14.5, color: Color(0xFF7A4A30)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('[ExitDialog] Cancel button tapped');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF7A4A30), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4891A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              debugPrint('[ExitDialog] Exit button tapped');
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    debugPrint('[ExitDialog] resolved result=$result');
    return result ?? false;
  } finally {
    _exitDialogOpen = false;
  }
}

/// The GoRouter instance, stashed here once at startup so the native-back
/// channel handler below (which has no BuildContext of its own — it's
/// invoked directly from Android, not from a widget) can still read the
/// current route and pop/navigate.
GoRouter? _appRouter;

void registerAppRouterForNativeBack(GoRouter router) {
  _appRouter = router;
}

/// Talks to MainActivity.kt's native `OnBackPressedCallback`. Both the
/// Android back button AND the edge-swipe gesture funnel through Android's
/// unified OnBackPressedDispatcher, which this custom channel forwards
/// straight into Dart — bypassing Flutter's own `flutter/navigation` /
/// `popRoute` plumbing entirely.
///
/// That plumbing turned out to be unreliable here on FlutterFragmentActivity
/// (required by razorpay_flutter): confirmed live on-device, PopScope's
/// onPopInvokedWithResult never fired for the root-level "nothing to pop"
/// case at all, and forwarding through `popRoute` produced a runaway loop of
/// tens of thousands of calls for a single gesture once predictive back was
/// disabled to work around that. A dedicated channel + explicit debounce on
/// the Kotlin side sidesteps both problems: one channel call per real back
/// press/swipe, handled directly against the router's own state.
const MethodChannel _nativeBackChannel = MethodChannel('app/back');

bool _initializedNativeBackChannel = false;

void initNativeBackChannel() {
  if (_initializedNativeBackChannel) return;
  _initializedNativeBackChannel = true;
  _nativeBackChannel.setMethodCallHandler((call) async {
    if (call.method == 'pressed') {
      await _handleNativeBackPress();
    }
    return null;
  });
}

Future<void> _handleNativeBackPress() async {
  final router = _appRouter;
  if (router == null) return;
  final navigatorState = router.routerDelegate.navigatorKey.currentState;
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (navigatorState == null || context == null) return;

  // Something pushed on top (a detail screen, a dialog's own route, etc.) —
  // pop exactly one, same as normal back always did.
  if (navigatorState.canPop()) {
    navigatorState.pop();
    return;
  }

  final location = router.routerDelegate.currentConfiguration.uri.path;
  debugPrint('[NativeBack] pressed at root: location=$location');

  if (location == '/home') {
    if (await confirmExitDialog(context)) {
      await _exitApp();
    }
    return;
  }

  if (_exitFromHereRoutes.contains(location)) {
    if (confirmExitByDoubleTap(context)) {
      await _exitApp();
    }
    return;
  }

  // A non-Home bottom-nav tab sitting at its own root → drop to Home.
  if (context.mounted) router.go('/home');
}

/// SystemNavigator.pop() only moves a single-activity Android app's Activity
/// to the back (not finish/kill it) — indistinguishable from "nothing
/// happened" to a user tapping "Exit". This talks to MainActivity.kt's
/// "app/exit" channel instead, which actually finishes and kills the process.
const MethodChannel _exitChannel = MethodChannel('app/exit');

Future<void> _exitApp() async {
  debugPrint('[NativeBack] exiting app now');
  try {
    await _exitChannel.invokeMethod('exit');
  } catch (e) {
    debugPrint('[NativeBack] app/exit channel failed ($e), falling back to SystemNavigator.pop()');
    await SystemNavigator.pop();
  }
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

/// Applied to every route by the router config. It leaves normal back
/// navigation completely alone — whenever the Navigator has something to pop
/// (a screen pushed on top of another) `canPop` is `true`, so the Android
/// back button and the edge-swipe gesture pop one screen at a time through
/// the real history, predictive-back animation and all, exactly like a
/// default Flutter app. It also stays out of the way of a screen that
/// registers its own [PopScope] (e.g. the payment screen).
///
/// It acts only when there is **nothing left to pop** — i.e. at a root
/// route:
///
///  * `/home` → an "Are you sure you want to exit?" dialog (Cancel / Exit).
///  * a pre-login screen → "Press back again to exit"; a second press
///    within two seconds closes the app.
///  * a non-Home bottom-nav tab's root (`/search`, `/my-bookings`, `/news`,
///    `/profile`) → switch to the Home tab.
///
/// On-screen AppBar back arrows are unaffected either way — they call
/// `context.pop()` directly, which never routes through here.
///
/// (The Android manifest also sets `android:enableOnBackInvokedCallback="true"`
/// so the edge-swipe gesture is delivered to Flutter rather than finishing
/// the Activity.)
class AppBackScope extends StatelessWidget {
  const AppBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The single reliable signal here: does the app's (only) Navigator have
    // a route to pop? True  → this screen was pushed on top of something, so
    //                         let the framework / that screen handle back.
    //                 False → we're at a root; the handler below takes over.
    //
    // NOTE: this is deliberately NOT based on GoRouterState.of(context) —
    // the five bottom-nav routes share one page key, which makes that state
    // report the wrong path for the non-Home tabs. Reading it made every
    // tab look "not top level", so canPop was always true and the handler
    // never ran — back appeared to do nothing.
    final canPop = Navigator.of(context).canPop();
    final buildLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    debugPrint('[AppBackScope] build: canPop=$canPop location=$buildLocation');

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        debugPrint('[AppBackScope] onPopInvoked: didPop=$didPop');
        if (didPop) return; // the framework popped a screen — nothing to do

        // A screen is on top of this one (its own PopScope blocked the pop):
        // not our job — let it handle its own back.
        final stillCanPop = Navigator.of(context).canPop();
        debugPrint('[AppBackScope] onPopInvoked: stillCanPop=$stillCanPop');
        if (stillCanPop) return;

        // We're at a root route. currentConfiguration is accurate here
        // because no push has happened since the last go() to this tab.
        final location =
            GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
        debugPrint('[AppBackScope] onPopInvoked: location=$location');

        if (location == '/home') {
          if (await confirmExitDialog(context)) {
            await SystemNavigator.pop();
          }
          return;
        }

        if (_exitFromHereRoutes.contains(location)) {
          if (confirmExitByDoubleTap(context)) {
            await SystemNavigator.pop();
          }
          return;
        }

        // A non-Home bottom-nav tab sitting at its own root → drop to Home.
        if (context.mounted) GoRouter.of(context).go('/home');
      },
      child: child,
    );
  }
}
