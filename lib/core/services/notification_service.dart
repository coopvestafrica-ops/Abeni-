import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/services/firebase_service.dart';

/// Top-level FCM background message handler.
///
/// Must be a top-level function (not a class method) and must be registered
/// via [FirebaseMessaging.onBackgroundMessage] BEFORE [runApp] is called.
/// Android FCM automatically shows notifications for messages that contain a
/// `notification` payload. This handler covers data-only messages and ensures
/// the notification channels exist so Android can play sound.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // For messages that carry a notification payload, Android FCM handles
  // display automatically — we just need the channels to exist.
  // For data-only messages we show a local notification manually.
  if (message.notification != null) return;

  // Data-only message in background/terminated state — show manually.
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    const InitializationSettings(android: androidInit),
  );

  final androidPlugin =
      plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // Re-create channels so they definitely exist with sound enabled.
  await androidPlugin?.createNotificationChannel(
      NotificationService.orderChannel);
  await androidPlugin?.createNotificationChannel(
      NotificationService.adminChannel);

  final type = message.data['type'] as String? ?? '';
  final isAdmin =
      type == 'new_order' || type == 'low_stock';
  final channel =
      isAdmin ? NotificationService.adminChannel : NotificationService.orderChannel;

  await plugin.show(
    message.hashCode,
    message.data['title'] as String? ?? 'Abeni Mart',
    message.data['body'] as String? ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: isAdmin ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// High-importance channel with sound — used for order updates (customers).
  /// Exposed as static so the background handler can access them.
  static const AndroidNotificationChannel orderChannel =
      AndroidNotificationChannel(
    'abeni_order_updates_v2',
    'Order updates',
    description:
        'Status updates for your Abeni Mart orders: processing, out for delivery, delivered.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Max-importance channel for new order and stock alerts (admin/staff).
  static const AndroidNotificationChannel adminChannel =
      AndroidNotificationChannel(
    'abeni_admin_orders_v2',
    'Admin alerts',
    description:
        'New order and stock alerts for Abeni Mart admins and staff.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Stream of route paths emitted when the user taps a notification.
  final StreamController<String> _tapRouteController =
      StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _tapRouteController.stream;

  bool _inited = false;

  /// Initialise FCM + local notifications. Safe to call multiple times.
  /// Must be awaited in main() BEFORE runApp().
  Future<void> init() async {
    if (_inited) return;
    if (!FirebaseService.isInitialized) return;
    _inited = true;

    // Note: permission is NOT requested here. It is requested via
    // NotificationPermissionSheet.showIfNeeded() after the home screen is
    // visible so the user sees a friendly explanation before the OS dialog.

    // Show foreground FCM alerts as banners with sound on iOS.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        final route = _routeFromPayload(details.payload);
        if (route != null) _tapRouteController.add(route);
      },
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Delete old channel IDs (without _v2 suffix) to force Android to
    // recreate them with the correct importance + sound settings.
    await androidPlugin?.deleteNotificationChannel('abeni_order_updates');
    await androidPlugin?.deleteNotificationChannel('abeni_admin_orders');

    // Create the versioned channels — Importance.max guarantees heads-up
    // display and sound even when the phone is in DND or screen-off.
    await androidPlugin?.createNotificationChannel(orderChannel);
    await androidPlugin?.createNotificationChannel(adminChannel);

    // Foreground FCM push → show as local notification with sound.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Background / quit tap — app was opened by tapping a notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = _routeFromMessage(message);
      if (route != null) _tapRouteController.add(route);
    });
  }

  /// Call once after the router is ready to handle cold-start taps.
  Future<void> handleInitialMessage() async {
    if (!FirebaseService.isInitialized) return;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      final route = _routeFromMessage(message);
      if (route != null) _tapRouteController.add(route);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    final payload = _routeFromMessage(message);

    final type = message.data['type'] as String? ?? '';
    final isAdminAlert = type == 'new_order' || type == 'low_stock';
    final channel = isAdminAlert ? adminChannel : orderChannel;

    await _local.show(
      message.hashCode,
      notif.title ?? 'Abeni Mart',
      notif.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: isAdminAlert ? Priority.max : Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Derives a GoRouter route path from an FCM message's data payload.
  String? _routeFromMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == 'new_order' || type == 'low_stock') return '/orders';
    final orderId = message.data['orderId'];
    if (orderId != null && (orderId as String).isNotEmpty) return '/orders';
    if (type == 'broadcast') return '/home';
    return null;
  }

  String? _routeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    return payload;
  }

  /// Registers a customer device's FCM token against their Firestore doc.
  Future<void> registerForUser(String userId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _persistToken(userId, token);
      await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
      await FirebaseMessaging.instance.subscribeToTopic('customers');
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _persistToken(userId, t);
      });
    } catch (e) {
      debugPrint('[FCM] registerForUser failed: $e');
    }
  }

  Future<void> unregisterForUser(String userId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('user_$userId');
      await FirebaseMessaging.instance.unsubscribeFromTopic('customers');
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(token)
          .delete();
    } catch (e) {
      debugPrint('[FCM] unregisterForUser failed: $e');
    }
  }

  /// Registers an admin/staff device's FCM token and subscribes to the
  /// `admins` topic so they receive new-order and stock-alert pushes.
  Future<void> registerForAdmin(String userId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _persistToken(userId, token);
      await FirebaseMessaging.instance.subscribeToTopic('admins');
      await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        _persistToken(userId, t);
      });
    } catch (e) {
      debugPrint('[FCM] registerForAdmin failed: $e');
    }
  }

  Future<void> unregisterForAdmin(String userId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('admins');
      await FirebaseMessaging.instance.unsubscribeFromTopic('user_$userId');
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(token)
          .delete();
    } catch (e) {
      debugPrint('[FCM] unregisterForAdmin failed: $e');
    }
  }

  Future<void> _persistToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
    }, SetOptions(merge: true));
  }
}
