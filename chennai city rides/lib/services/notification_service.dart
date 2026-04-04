import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Request permissions (especially for Android 13+)
      // Using a timeout to ensure this doesn't hang the background thread indefinitely.
      // We don't return a manual object to avoid version-specific compile errors.
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      ).timeout(const Duration(seconds: 8));

      // 2. Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // 3. Setup Listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showForegroundNotification(message.notification!);
        }
      });

      _fcm.onTokenRefresh.listen((token) {
        _saveTokenToDatabase(token);
      });

      // 4. Initial token retrieval (Parallel / Non-blocking)
      _fcm.getToken().then((token) {
        if (token != null) {
          _saveTokenToDatabase(token);
        }
      }).catchError((e) {
        debugPrint("FCM Token Error: $e");
        return null;
      });

    } catch (e) {
      debugPrint("Notification Service initialization skipped or timed out: $e");
    }
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  static void _showForegroundNotification(RemoteNotification notification) {
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_updates',
          'Trip Updates',
          channelDescription: 'Notifications for trip allotments and updates',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
