import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level background message handler for Firebase Messaging.
/// This handler must be top-level (outside any class) and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` first.
  await Firebase.initializeApp();
  debugPrint('NotificationService: Handling a background message: ${message.messageId}');
  debugPrint('NotificationTitle: ${message.notification?.title}');
  debugPrint('NotificationBody: ${message.notification?.body}');
}

/// Unified Push Notification Service for Kurye App.
/// Integrates Firebase Cloud Messaging (FCM).
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Initializes notification handling.
  /// Sets up listeners for foreground and background push notification events.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('NotificationService: Received message in foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification!.title}');
          // In a real production app, you might show a local notification overlay here.
        }
      });

      // Handle message opened app events (when clicking notification from system tray)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('NotificationService: App opened from notification: ${message.messageId}');
      });

      _initialized = true;
      debugPrint('NotificationService: Initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService: Failed to initialize. Firebase may not be configured: $e');
    }
  }

  /// Requests notification permissions (required for iOS and Android 13+).
  static Future<bool> requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('NotificationService: User granted push notification permission.');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('NotificationService: User granted provisional push notification permission.');
        return true;
      } else {
        debugPrint('NotificationService: User declined or has not accepted push notification permission.');
        return false;
      }
    } catch (e) {
      debugPrint('NotificationService: Error requesting permissions: $e');
      return false;
    }
  }

  /// Retrieves the device FCM token.
  /// Can be stored in database to send push notifications to this device.
  static Future<String?> getDeviceToken() async {
    try {
      // On web/Android/iOS, request token
      String? token = await _messaging.getToken();
      debugPrint('NotificationService: FCM Device Token: $token');
      return token;
    } catch (e) {
      debugPrint('NotificationService: Error getting FCM device token: $e');
      return null;
    }
  }
}
