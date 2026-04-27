import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/services/firebase_service.dart';

/// Initialises Firebase Cloud Messaging for order status updates.
///
/// What this handles:
/// - Background message handler registration (top-level function required).
/// - Notification permission request.
/// - A Local Notifications channel so FCM messages arriving while the app
///   is in the foreground are still surfaced to the user.
/// - Storing the device's FCM token on the Firestore user document so the
///   backend can target individual customers with order-status updates
///   ("processing", "out-for-delivery", "delivered").
/// - Topic subscription per user so the backend can publish to a topic
///   instead of maintaining a token list if it prefers.
///
/// To send a notification from the server, publish a message with a `data`
/// payload containing either `orderId` + `status`, or rely on FCM's own
/// `notification.title` / `notification.body` fields.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep background work minimal — the system already renders the
  // notification for us when the `notification` field is present.
  debugPrint('[FCM bg] ${message.messageId} ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'abeni_order_updates',
    'Order updates',
    description:
        'Status updates for your Abeni Mart orders: processing, out for delivery, delivered.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _inited = false;

  /// Initialise FCM + local notifications. Safe to call multiple times.
  Future<void> init() async {
    if (_inited) return;
    if (!FirebaseService.isInitialized) return;
    _inited = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Permission — iOS requires an explicit ask; Android 13+ too.
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Make foreground notifications actually render on iOS.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications channel (Android) so foreground messages surface.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

    // Show foreground pushes using the local plugin.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    await _local.show(
      message.hashCode,
      notif.title ?? 'Abeni Mart',
      notif.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannel.id,
          _orderChannel.name,
          channelDescription: _orderChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['orderId']?.toString(),
    );
  }

  /// Registers the device's FCM token against the Firestore user document and
  /// subscribes the user to their personal topic so the backend can target
  /// this customer. Called after login.
  Future<void> registerForUser(String userId) async {
    if (!FirebaseService.isInitialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _persistToken(userId, token);
      await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
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
