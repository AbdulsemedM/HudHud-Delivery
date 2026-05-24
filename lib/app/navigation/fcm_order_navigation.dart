import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/orders/bloc/orders_bloc.dart';
import 'package:hudhud_delivery/features/orders/data/repositories/orders_repository.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:hudhud_delivery/features/orders/presentation/screen/order_details_screen.dart';

/// When the user is not on an authenticated route yet, store a pending order
/// from an FCM payload and open it after [DashboardScreen] is shown.
class PendingFcmOrderNavigation {
  static int? _orderId;

  static void setPending(int? id) {
    if (id != null) _orderId = id;
  }

  static int? takePending() {
    final v = _orderId;
    _orderId = null;
    return v;
  }
}

/// Pending chat room from FCM when navigator is not ready yet.
class PendingFcmChatNavigation {
  static int? _conversationId;

  static void setPending(int? id) {
    if (id != null) _conversationId = id;
  }

  static int? takePending() {
    final v = _conversationId;
    _conversationId = null;
    return v;
  }
}

/// Resolves FCM [RemoteMessage.data] and local notification payload into an order id.
int? parseOrderIdFromFcmPayload(
  RemoteMessage? message, {
  String? localPayload,
}) {
  final fromMessage = _parseIdFromStringMap(
    message == null
        ? null
        : {
            for (final e in message.data.entries)
              e.key: e.value is String ? e.value as String : e.value.toString()
          },
  );
  if (fromMessage != null) return fromMessage;
  if (localPayload == null || localPayload.isEmpty) return null;
  return _parseIdFromLocalPayload(localPayload);
}

int? _parseIdFromStringMap(Map<String, String>? data) {
  if (data == null || data.isEmpty) return null;
  for (final key in const [
    'order_id',
    'orderId',
    'id',
  ]) {
    if (data.containsKey(key)) {
      final n = int.tryParse(data[key]!);
      if (n != null) return n;
    }
  }
  return null;
}

int? _parseIdFromLocalPayload(String localPayload) {
  try {
    final decoded = jsonDecode(localPayload);
    if (decoded is Map) {
      final m = <String, String>{};
      decoded.forEach((k, v) {
        m[k.toString()] = v is String ? v : v.toString();
      });
      return _parseIdFromStringMap(m);
    }
  } catch (_) {
    // not JSON; try plain int
  }
  return int.tryParse(localPayload.trim());
}

int? parseConversationIdFromFcmPayload(
  RemoteMessage? message, {
  String? localPayload,
}) {
  final fromMessage = _parseConversationIdFromStringMap(
    message == null
        ? null
        : {
            for (final e in message.data.entries)
              e.key: e.value is String ? e.value as String : e.value.toString()
          },
  );
  if (fromMessage != null) return fromMessage;
  if (localPayload == null || localPayload.isEmpty) return null;
  try {
    final decoded = jsonDecode(localPayload);
    if (decoded is Map) {
      final m = <String, String>{};
      decoded.forEach((k, v) {
        m[k.toString()] = v is String ? v : v.toString();
      });
      return _parseConversationIdFromStringMap(m);
    }
  } catch (_) {}
  return null;
}

int? _parseConversationIdFromStringMap(Map<String, String>? data) {
  if (data == null || data.isEmpty) return null;
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

/// Opens chat or order screen from FCM tap.
Future<void> openOrderDetailsFromFcm(
  GlobalKey<NavigatorState> navigatorKey, {
  required RemoteMessage? message,
  String? localPayload,
}) async {
  final chatId =
      parseConversationIdFromFcmPayload(message, localPayload: localPayload);
  if (chatId != null) {
    await openChatRoomFromFcm(navigatorKey, conversationId: chatId);
    return;
  }

  int? id = parseOrderIdFromFcmPayload(message, localPayload: localPayload);
  if (id == null) return;

  final nav = navigatorKey.currentState;
  if (nav == null) {
    PendingFcmOrderNavigation.setPending(id);
    return;
  }

  final authed = await AuthService().isAuthenticated();
  if (!authed) {
    PendingFcmOrderNavigation.setPending(id);
    return;
  }

  if (!nav.mounted) return;
  final ctx = nav.context;
  if (!ctx.mounted) return;
  pushOrderDetailsById(ctx, orderId: id);
}

Future<void> openChatRoomFromFcm(
  GlobalKey<NavigatorState> navigatorKey, {
  required int conversationId,
}) async {
  final nav = navigatorKey.currentState;
  if (nav == null) {
    PendingFcmChatNavigation.setPending(conversationId);
    return;
  }

  final authed = await AuthService().isAuthenticated();
  if (!authed) {
    PendingFcmChatNavigation.setPending(conversationId);
    return;
  }

  if (!nav.mounted) return;
  nav.push(
    MaterialPageRoute<void>(
      builder: (_) => ChatRoomScreen(conversationId: conversationId),
    ),
  );
}

void pushChatRoomById(
  BuildContext context, {
  required int conversationId,
}) {
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatRoomScreen(conversationId: conversationId),
    ),
  );
}

void pushOrderDetailsById(
  BuildContext context, {
  required int orderId,
}) {
  if (!context.mounted) return;
  final nav = Navigator.of(context);
  final repo = context.read<OrdersRepository>();
  nav.push(
    MaterialPageRoute<void>(
      builder: (c) => BlocProvider(
        create: (_) => OrdersBloc(ordersRepository: repo),
        child: OrderDetailsScreen(orderId: orderId),
      ),
    ),
  );
}
