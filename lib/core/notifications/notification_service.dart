import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level handler required by FCM for background messages.
@pragma('vm:entry-point')
Future<void> handleBackgroundNotification(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'job_status_channel',
    'Job Status Updates',
    description: 'Notifications for job status changes',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    FirebaseMessaging.onBackgroundMessage(handleBackgroundNotification);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  // Requests permission and saves the FCM token to Supabase.
  Future<bool> requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) await _saveFcmToken();
    return granted;
  }

  Future<void> _saveFcmToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('fcm_tokens').upsert(
      {'user_id': userId, 'token': token},
      onConflict: 'user_id, token',
    );

    // Refresh token whenever FCM rotates it.
    _messaging.onTokenRefresh.listen((newToken) async {
      await Supabase.instance.client.from('fcm_tokens').upsert(
        {'user_id': userId, 'token': newToken},
        onConflict: 'user_id, token',
      );
    });
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Saves the user's notification preference to Supabase profiles table.
  Future<void> updateNotificationPreferences({required bool enabled}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'notifications_enabled': enabled}).eq('id', userId);

    if (!enabled) {
      await Supabase.instance.client
          .from('fcm_tokens')
          .delete()
          .eq('user_id', userId);
    } else {
      await _saveFcmToken();
    }
  }

  Future<void> deleteFcmToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('fcm_tokens')
        .delete()
        .eq('user_id', userId);
  }
}
