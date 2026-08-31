import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/repositories.dart';

/// Runs entirely outside the widget tree — FCM delivers background messages
/// to a separate isolate, so this must be a top-level (or static) function,
/// never a method on an instance.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here beyond letting the system show its own notification
  // (FCM does that automatically for a "notification" payload when the app
  // isn't in the foreground) — this handler exists so tapping it while the
  // app was fully closed still reports the tap via getInitialMessage().
}

/// Routes a tapped notification to the right screen based on the `type`
/// field the backend sends (see internal/notify — "booking", "payment",
/// "refund", "account", "news", "wishlist", "event").
String _routeForType(String? type) {
  switch (type) {
    case 'booking':
    case 'payment':
      return '/my-bookings';
    case 'refund':
      return '/my-bookings';
    case 'account':
      return '/passport-upload';
    case 'news':
      return '/news';
    case 'wishlist':
      return '/wishlist';
    case 'event':
      return '/kumbh-calendar';
    default:
      return '/notifications';
  }
}

/// Push notifications, end to end: permission, FCM token registration with
/// the backend, a local-notification fallback for foreground messages (FCM
/// doesn't auto-show a banner while the app is open), and tap-to-navigate
/// for background/terminated launches.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _notifRepo = NotificationRepository();
  final _localNotifs = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  GoRouter? _router;

  Future<void> init(GoRouter router) async {
    _router = router;
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocalNotifications();
    await _registerToken();
    messaging.onTokenRefresh.listen((_) => _registerToken());

    // Foreground: FCM delivers the message but shows nothing on screen by
    // itself — show it via flutter_local_notifications so it's visible the
    // same way a background push would be.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Background tap (app was backgrounded, not closed).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Terminated tap (app was fully closed and launched by the tap).
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final type = response.payload;
        if (_router != null) _router!.push(_routeForType(type));
      },
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'one_tent_default',
        'One Tent',
        description: 'Booking, payment, and stay updates',
        importance: Importance.high,
      );
      await _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifs.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'one_tent_default',
          'One Tent',
          channelDescription: 'Booking, payment, and stay updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['type'] as String?,
    );
  }

  void _handleTap(RemoteMessage message) {
    if (_router == null) return;
    _router!.push(_routeForType(message.data['type'] as String?));
  }

  Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';
      await _notifRepo.saveToken(token, platform: platform);
    } catch (e) {
      // Non-fatal — the guest just won't get pushes until the next
      // successful registration attempt (e.g. next app open).
      debugPrint('PushService: failed to register FCM token: $e');
    }
  }
}
