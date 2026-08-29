import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KumbhApp());
}

// Flutter's default ScrollBehavior only lets touch drag a scrollable —
// mouse click-and-drag is excluded on purpose (so a mouse click doesn't
// accidentally start a drag on desktop/web). That's exactly why the tent
// photo gallery (a PageView) only responded to tapping its dots and not to
// dragging on the web build: a real phone's touch input was never the
// problem, a mouse/trackpad testing it was. Adding mouse (and trackpad,
// which reports as touch/mouse depending on the browser) here makes every
// swipeable widget in the app — not just the gallery — draggable by mouse
// too, on web and desktop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class KumbhApp extends StatelessWidget {
  const KumbhApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider     = AuthProvider();
    final tentProvider     = TentProvider();
    final wishlistProvider = WishlistProvider();
    final supportProvider  = SupportProvider();
    final router = AppRouter(authProvider).router;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: tentProvider),
        ChangeNotifierProvider.value(value: wishlistProvider),
        ChangeNotifierProvider.value(value: supportProvider),
      ],
      child: MaterialApp.router(
        title: 'One Tent',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        scrollBehavior: _AppScrollBehavior(),
        routerConfig: router,
      ),
    );
  }
}