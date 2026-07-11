import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/chat_room_screen.dart';

Future<void> openOrderChat(BuildContext context, int orderId) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final repo = createChatRepository();
    final result = await repo.getOrCreateOrderConversation(orderId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: result.conversationId,
          initialDetail: result.conversation != null
              ? ChatConversationDetailResult.fromOpenResult(result)
              : null,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

Future<void> openRideChat(BuildContext context, int rideId) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final repo = createChatRepository();
    final result = await repo.createRideConversation(rideId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: result.conversationId,
          initialDetail: result.conversation != null
              ? ChatConversationDetailResult.fromOpenResult(result)
              : null,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

Future<void> openPackageDeliveryChat(
  BuildContext context,
  int deliveryId,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final repo = createChatRepository();
    final detail = await repo.getPackageDeliveryConversation(deliveryId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: detail.conversation.id,
          packageDeliveryId: deliveryId,
          initialDetail: detail,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

Future<void> openChatRoom(BuildContext context, int conversationId) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatRoomScreen(conversationId: conversationId),
    ),
  );
}
