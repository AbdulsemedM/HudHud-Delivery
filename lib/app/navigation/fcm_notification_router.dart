import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:hudhud_delivery/app/notifications/notification_events.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/forgot_password/presentation/screen/forgot_password_identifier_screen.dart';
import 'fcm_order_navigation.dart';

/// Deferred FCM navigation when the navigator is not ready or user is unauthenticated.
class PendingFcmNavigation {
  static Map<String, String>? _payload;

  static void setPending(Map<String, String> payload) {
    if (payload.isNotEmpty) _payload = Map<String, String>.from(payload);
  }

  static Map<String, String>? takePending() {
    final v = _payload;
    _payload = null;
    return v;
  }
}

/// Dashboard bottom-nav tab to select after navigation (0 = home, 1 = orders, 2 = settings).
class PendingFcmDashboardTab {
  static int? _tabIndex;

  static void setPending(int index) {
    _tabIndex = index;
  }

  static int? takePending() {
    final v = _tabIndex;
    _tabIndex = null;
    return v;
  }
}

/// Parses FCM [RemoteMessage.data] or a local notification JSON payload.
Map<String, String> parseFcmPayloadMap(
  RemoteMessage? message, {
  String? localPayload,
}) {
  if (message != null && message.data.isNotEmpty) {
    return {
      for (final e in message.data.entries)
        e.key: e.value is String ? e.value as String : e.value.toString(),
    };
  }
  if (localPayload == null || localPayload.isEmpty) return {};
  try {
    final decoded = jsonDecode(localPayload);
    if (decoded is Map) {
      return {
        for (final e in decoded.entries)
          e.key.toString(): e.value is String ? e.value as String : e.value.toString(),
      };
    }
  } catch (_) {}
  return {};
}

/// Opens the appropriate screen from an FCM notification tap.
Future<void> openNotificationFromFcm(
  GlobalKey<NavigatorState> navigatorKey, {
  RemoteMessage? message,
  String? localPayload,
  Map<String, String>? payloadMap,
}) async {
  final data = payloadMap ?? parseFcmPayloadMap(message, localPayload: localPayload);
  if (data.isEmpty) return;

  final nav = navigatorKey.currentState;
  if (nav == null) {
    PendingFcmNavigation.setPending(data);
    return;
  }

  final authed = await AuthService().isAuthenticated();
  if (!authed) {
    PendingFcmNavigation.setPending(data);
    return;
  }

  if (!nav.mounted) return;
  final ctx = nav.context;
  if (!ctx.mounted) return;

  await _routeFromPayload(ctx, navigatorKey, data);
}

/// Replays any notification deferred until the dashboard is ready.
Future<void> flushPendingFcmNavigation(
  GlobalKey<NavigatorState> navigatorKey,
) async {
  final pending = PendingFcmNavigation.takePending();
  if (pending == null) return;
  await openNotificationFromFcm(navigatorKey, payloadMap: pending);
}

Future<void> _routeFromPayload(
  BuildContext context,
  GlobalKey<NavigatorState> navigatorKey,
  Map<String, String> data,
) async {
  final event = normalizeEvent(data['event']);

  // Chat messages take priority when conversation keys are present.
  final chatId = _parseConversationId(data);
  if (chatId != null) {
    await openChatRoomFromFcm(navigatorKey, conversationId: chatId);
    return;
  }

  if (event.isNotEmpty) {
    if (isCustomerOrderEvent(event)) {
      final orderId = parseOrderIdFromPayload(data);
      if (orderId != null) {
        pushOrderDetailsById(context, orderId: orderId);
        return;
      }
      PendingFcmDashboardTab.setPending(1);
      return;
    }

    if (isOtpNavigationEvent(event)) {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordIdentifierScreen(),
        ),
      );
      return;
    }

    if (event == NotificationEvents.phoneVerification) {
      PendingFcmDashboardTab.setPending(2);
      return;
    }

    if (isSecurityEvent(event)) {
      PendingFcmDashboardTab.setPending(2);
      return;
    }
  }

  // Legacy payloads without a standardised event field.
  final legacyOrderId = parseOrderIdFromPayload(data);
  if (legacyOrderId != null) {
    pushOrderDetailsById(context, orderId: legacyOrderId);
    return;
  }

  // Advisory screen hint fallback.
  _routeByScreenHint(data['screen']);
}

void _routeByScreenHint(String? screen) {
  final hint = screen?.trim().toLowerCase();
  if (hint == null || hint.isEmpty) return;

  switch (hint) {
    case NotificationScreens.orderDetails:
      // No order id — fall through to orders list.
      PendingFcmDashboardTab.setPending(1);
      break;
    case NotificationScreens.orders:
      PendingFcmDashboardTab.setPending(1);
      break;
    case NotificationScreens.home:
      PendingFcmDashboardTab.setPending(0);
      break;
    case NotificationScreens.settings:
      PendingFcmDashboardTab.setPending(2);
      break;
    default:
      break;
  }
}

int? _parseConversationId(Map<String, String> data) {
  final type = data['type']?.toLowerCase();
  if (type != null &&
      type != 'chat' &&
      type != 'message' &&
      !data.containsKey('conversation_id') &&
      !data.containsKey('conversationId')) {
    return null;
  }
  for (final key in const [
    'conversation_id',
    'conversationId',
    'chat_id',
  ]) {
    if (data.containsKey(key)) {
      final n = int.tryParse(data[key]!);
      if (n != null) return n;
    }
  }
  return null;
}

/// Routes an in-app notification list item using the same logic as FCM taps.
Future<void> openNotificationFromPayloadMap(
  GlobalKey<NavigatorState> navigatorKey,
  Map<String, String> payload,
) =>
    openNotificationFromFcm(navigatorKey, payloadMap: payload);
