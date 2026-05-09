import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/services/firebase_service.dart';

/// Initialises Firebase Cloud Messaging for order status updates.
///
/// Tap-to-navigate:
///   - Cold-start tap   → handled via getInitialMessage() in main.dart
///   - Background tap   → handled via onMessageOpenedApp stream
///   - Foreground push  → shown via local notifications; tap navigates too
///
/// Navigation events are emitted on [onNotificationTap] — subscribe in
/// main.dart and route with GoRouter.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM bg] ${message.messageId} ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// High-importance channel with sound — used for order updates (customers).
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'abeni_order_updates',
    'Order updates',
    description:
        'Status updates for your Abeni Mart orders: processing, out for delivery, delivered.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Max-importance channel for new order alerts (admin/staff).
  static const AndroidNotificationChannel _adminChannel =
      AndroidNotificationChannel(
    'abeni_admin_orders',
    'New order alerts',
    description: 'New order and important store alerts for Abeni Mart admins.',
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
  Future<void> init() async {
    if (_inited) return;
    if (!FirebaseService.isInitialized) return;
    _inited = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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

    // Create both notification channels.
    await androidPlugin?.createNotificationChannel(_orderChannel);
    await androidPlugin?.createNotificationChannel(_adminChannel);

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

    // Use admin channel for new-order alerts, order channel for everything else.
    final type = message.data['type'] as String? ?? '';
    final isAdminAlert = type == 'new_order';
    final channel = isAdminAlert ? _adminChannel : _orderChannel;

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
          sound: null,
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
    if (type == 'new_order') return '/orders';
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
  /// `admins` topic so they receive new-order push notifications.
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
