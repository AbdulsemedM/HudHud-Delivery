import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

/// Handles FCM initialization, token, and message callbacks (foreground, background, opened).
///
/// Custom notification sound: native `notification_sound` on Android (res/raw) and
/// `notification_sound.caf` in the iOS app bundle. Do not play the clip from Dart for FCM.
///
/// Backend FCM payload (required for background/killed OS-delivered notifications):
/// ```json
/// {
///   "notification": { "title": "...", "body": "..." },
///   "android": {
///     "notification": {
///       "channel_id": "hudhud_delivery_channel_v4",
///       "sound": "notification_sound"
///     }
///   },
///   "apns": {
///     "payload": {
///       "aps": { "sound": "notification_sound.caf" }
///     }
///   }
/// }
/// ```
/// Data-only messages are shown by the app with the same native sound (client fallback).
class FcmService {
  FcmService._();
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;

  /// v4: native channel registered in MainActivity before Flutter starts.
  /// v3 may have been auto-created by FCM with default sound; v2 had playSound: false.
  static const String channelId = 'hudhud_delivery_channel_v4';
  static const List<String> legacyChannelIds = [
    'hudhud_delivery_channel_v2',
    'hudhud_delivery_channel_v3',
  ];
  static const String channelName = 'HudHud Delivery';
  static const String androidSoundResource = 'notification_sound';
  static const String iosSoundFile = 'notification_sound.caf';

  static const AndroidNotificationChannel androidChannel =
      AndroidNotificationChannel(
    channelId,
    channelName,
    description: 'Notifications for HudHud Delivery',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(androidSoundResource),
  );

  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: 'Notifications for HudHud Delivery',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(androidSoundResource),
  );

  static const DarwinNotificationDetails _iosNotificationDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: iosSoundFile,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
    iOS: _iosNotificationDetails,
  );

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
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      for (final legacyId in legacyChannelIds) {
        await androidPlugin?.deleteNotificationChannel(legacyId);
      }
      await androidPlugin?.createNotificationChannel(androidChannel);
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
    // Foreground banners use flutter_local_notifications (with native sound).
    // Disable FCM system presentation sound to avoid double playback.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  void _subscribeToTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      onTokenRefresh?.call(token);
    });
  }

  void _subscribeToMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message);
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await showFcmLocalNotification(
      localNotifications: _localNotifications,
      message: message,
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

/// Shows a local notification with the HudHud native sound clip.
Future<void> showFcmLocalNotification({
  required FlutterLocalNotificationsPlugin localNotifications,
  required RemoteMessage message,
}) async {
  final (title, body) = _fcmNotificationContent(message);
  final dataJson = message.data.isEmpty
      ? '{}'
      : jsonEncode(
          {for (final e in message.data.entries) e.key: e.value.toString()},
        );
  await localNotifications.show(
    message.hashCode,
    title,
    body,
    FcmService._notificationDetails,
    payload: dataJson,
  );
}

(String title, String? body) _fcmNotificationContent(RemoteMessage message) {
  final notification = message.notification;
  if (notification != null) {
    return (notification.title ?? 'Notification', notification.body);
  }
  final data = message.data;
  final title = data['title'] ??
      data['notification_title'] ??
      data['subject'] ??
      'Notification';
  final body = data['body'] ?? data['notification_body'] ?? data['message'];
  return (title.toString(), body?.toString());
}

Future<void> _ensureBackgroundLocalNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(initSettings);
  if (Platform.isAndroid) {
    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    for (final legacyId in FcmService.legacyChannelIds) {
      await androidPlugin?.deleteNotificationChannel(legacyId);
    }
    await androidPlugin?.createNotificationChannel(FcmService.androidChannel);
  }
}

/// Top-level handler for background messages. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } on FirebaseException catch (e) {
    if (!e.code.contains('duplicate-app')) rethrow;
  }
  WidgetsFlutterBinding.ensureInitialized();

  // Notification-payload messages are displayed by the OS (sound from backend payload).
  if (message.notification != null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await _ensureBackgroundLocalNotifications(plugin);
  await showFcmLocalNotification(
    localNotifications: plugin,
    message: message,
  );
}
