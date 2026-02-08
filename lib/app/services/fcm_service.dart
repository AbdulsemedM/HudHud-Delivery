import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

/// Handles FCM initialization, token, and message callbacks (foreground, background, opened).
class FcmService {
  FcmService._();
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;

  static const String _channelId = 'hudhud_delivery_channel';
  static const String _channelName = 'HudHud Delivery';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback when a new FCM token is available (e.g. to send to your backend).
  void Function(String token)? onTokenRefresh;

  /// Callback when user taps a notification. [message] is set when opened from FCM;
  /// [localPayload] is set when opened from a foreground local notification.
  void Function(RemoteMessage? message, {String? localPayload})?
      onNotificationTap;

  /// Initialize Firebase and FCM. Call once from main().
  static Future<FcmService> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
    } on FirebaseException catch (e) {
      if (!e.code.contains('duplicate-app')) rethrow;
      // Native iOS auto-initializes from GoogleService-Info.plist; ignore.
    }
    await _instance._init();
    return _instance;
  }

  /// Call after init (e.g. in SplashScreen when navigator is ready) to handle
  /// the notification that launched the app from terminated state.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Future<void> _init() async {
    await _setupLocalNotifications();
    await _requestPermissions();
    await _setForegroundPresentationOptions();
    _subscribeToTokenRefresh();
    _subscribeToMessageHandlers();
    try {
      _fcmToken = await _messaging.getToken();
    } catch (e, st) {
      // FCM often fails on emulators (Firebase Installations Service unavailable).
      // App continues without push; token will work on real devices with Google Play.
      if (kDebugMode) {
        debugPrint('FCM getToken failed (emulator?): $e');
        debugPrint('$st');
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Notifications for HudHud Delivery',
        importance: Importance.high,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      onNotificationTap?.call(null, localPayload: payload);
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Optional: prompt user in-app to enable in system settings
    }
    if (Platform.isIOS) return;
    final plugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.requestNotificationsPermission();
  }

  Future<void> _setForegroundPresentationOptions() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _subscribeToTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      onTokenRefresh?.call(token);
    });
  }

  void _subscribeToMessageHandlers() {
    // Foreground: show via local notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // User tapped notification (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message);
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications for HudHud Delivery',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Notification',
      notification.body,
      details,
      payload: message.messageId,
    );
  }

  /// Get current FCM token (e.g. to send to your backend after login).
  /// Returns null if FCM is unavailable (e.g. on emulator without Google Play).
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    try {
      _fcmToken = await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken failed: $e');
    }
    return _fcmToken;
  }

  /// Subscribe to a topic (e.g. 'driver_orders', 'driver_<id>').
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Delete token (e.g. on logout). Next getToken() will create a new one.
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
  }
}

/// Top-level handler for background messages. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } on FirebaseException catch (e) {
    if (!e.code.contains('duplicate-app')) rethrow;
  }
  // Optional: handle data-only messages or update local state
}
