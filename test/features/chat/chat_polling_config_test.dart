import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_polling_config.dart';

void main() {
  group('ChatPollingConfig', () {
    test('uses API-recommended intervals', () {
      expect(ChatPollingConfig.openConversationInterval.inSeconds, 4);
      expect(ChatPollingConfig.conversationListInterval.inSeconds, 20);
      expect(ChatPollingConfig.unreadBadgeInterval.inSeconds, 45);
    });
  });

  group('package delivery chat API paths', () {
    test('use preferred chat/ prefix', () {
      expect(
        ApiConstants.packageDeliveryConversation,
        'chat/package-delivery/{deliveryId}/conversation',
      );
      expect(
        ApiConstants.packageDeliveryMessage,
        'chat/package-delivery/{deliveryId}/messages',
      );
      expect(
        ApiConstants.packageDeliveryRead,
        'chat/package-delivery/{deliveryId}/mark-read',
      );
      expect(
        ApiConstants.packageDeliveryConversations,
        'chat/package-delivery/conversations',
      );
      expect(
        ApiConstants.packageDeliveryUnreadCount,
        'chat/package-delivery/unread-count',
      );
    });
  });
}
