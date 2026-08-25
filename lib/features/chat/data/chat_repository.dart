import 'package:hudhud_delivery/features/chat/data/chat_data_provider.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversations_list_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_open_conversation_result.dart';
import 'package:hudhud_delivery/features/chat/model/send_chat_message_request.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_conversations_response_parser.dart';
import 'package:hudhud_delivery/features/chat/utils/package_delivery_chat_mapper.dart';

class ChatRepository {
  final ChatDataProvider dataProvider;

  ChatRepository({required this.dataProvider});

  Future<ChatConversationsListResult> getConversations() async {
    final response = await dataProvider.getConversations();
    _ensureSuccess(response, 'Error fetching conversations');
    return ChatConversationsResponseParser.parse(response['data']);
  }

  Future<int> getUnreadCount() async {
    final response = await dataProvider.getUnreadCount();
    _ensureSuccess(response, 'Error fetching unread count');
    final root = response['data'];
    if (root is Map) {
      final count = root['unread_count'];
      if (count is int) return count;
      return int.tryParse(count?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Future<ChatConversationDetailResult> getConversation(int id) async {
    final response = await dataProvider.getConversation(id);
    _ensureSuccess(response, 'Error loading conversation');
    final data = _extractDataMap(response['data']);
    return ChatConversationDetailResult.fromResponseData(data);
  }

  /// Retries GET after create/open when the server may not index the row yet.
  Future<ChatConversationDetailResult> getConversationWithRetry(
    int id, {
    int maxAttempts = 4,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await getConversation(id);
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts - 1) {
          await Future.delayed(delay);
        }
      }
    }
    throw lastError ?? Exception('Error loading conversation');
  }

  Future<ChatOpenConversationResult> getOrCreateOrderConversation(
    int orderId, {
    bool createIfMissing = true,
  }) async {
    var response = await dataProvider.getOrderConversation(orderId);
    if (!_isHttpSuccess(response) && createIfMissing) {
      response = await dataProvider.createOrderConversation(orderId);
    }
    _ensureSuccess(response, 'Error opening order chat');
    return _parseOpenConversation(response['data']);
  }

  Future<ChatOpenConversationResult> createRideConversation(int rideId) async {
    final response = await dataProvider.createRideConversation(rideId);
    _ensureSuccess(response, 'Error opening ride chat');
    return _parseOpenConversation(response['data']);
  }

  Future<ChatOpenConversationResult> createSupportConversation(
    String subject,
  ) async {
    final response = await dataProvider.createSupportConversation(
      subject: subject,
    );
    _ensureSuccess(response, 'Error creating support chat');
    return _parseOpenConversation(response['data']);
  }

  Future<ChatMessageModel> sendMessage(
    int conversationId,
    SendChatMessageRequest request,
  ) async {
    final response = await dataProvider.sendMessage(conversationId, request);
    _ensureSuccess(response, 'Error sending message');
    final data = _extractDataMap(response['data']);
    final messageRaw = _parseSendMessagePayload(data);
    if (messageRaw is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(messageRaw);
    }
    if (messageRaw is Map) {
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(messageRaw));
    }
    throw Exception('Invalid message response');
  }

  Future<void> markConversationRead(int conversationId) async {
    final response = await dataProvider.markConversationRead(conversationId);
    _ensureSuccess(response, 'Error marking conversation read');
  }

  Future<void> rejoinConversation(int conversationId) async {
    final response = await dataProvider.rejoinConversation(conversationId);
    _ensureSuccess(response, 'Error rejoining conversation');
  }

  Future<ChatMessageModel> editMessage(int messageId, String text) async {
    final response = await dataProvider.editMessage(messageId, text);
    _ensureSuccess(response, 'Error editing message');
    final data = _extractDataMap(response['data']);
    final messageRaw = data['data'] ?? data;
    if (messageRaw is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(messageRaw);
    }
    if (messageRaw is Map) {
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(messageRaw));
    }
    throw Exception('Invalid edit response');
  }

  Future<void> deleteMessage(int messageId) async {
    final response = await dataProvider.deleteMessage(messageId);
    _ensureSuccess(response, 'Error deleting message');
  }

  Future<ChatConversationDetailResult> getPackageDeliveryConversation(
    int deliveryId, {
    int maxAttempts = 4,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response =
            await dataProvider.getPackageDeliveryConversation(deliveryId);
        _ensureSuccess(response, 'Error loading package delivery chat');
        final data = _extractDataMap(response['data']);
        final detail = ChatConversationDetailResult.fromResponseData(data);
        return PackageDeliveryChatMapper.enrichDetail(detail, data);
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts - 1) {
          await Future.delayed(delay);
        }
      }
    }
    throw lastError ?? Exception('Error loading package delivery chat');
  }

  Future<void> markPackageDeliveryRead(int deliveryId) async {
    final response = await dataProvider.markPackageDeliveryRead(deliveryId);
    _ensureSuccess(response, 'Error marking package delivery chat read');
  }

  Future<void> rejoinPackageDelivery(int deliveryId) async {
    final response = await dataProvider.rejoinPackageDelivery(deliveryId);
    _ensureSuccess(response, 'Error rejoining conversation');
  }

  Future<ChatMessageModel> sendPackageDeliveryMessage(
    int deliveryId,
    SendChatMessageRequest request,
  ) async {
    final response =
        await dataProvider.sendPackageDeliveryMessage(deliveryId, request);
    _ensureSuccess(response, 'Error sending message');
    final data = _extractDataMap(response['data']);
    final messageRaw = _parseSendMessagePayload(data);
    if (messageRaw is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(messageRaw);
    }
    if (messageRaw is Map) {
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(messageRaw));
    }
    throw Exception('Invalid message response');
  }

  ChatOpenConversationResult _parseOpenConversation(dynamic root) {
    final data = _extractDataMap(root);
    final conversationId = _asInt(data['conversation_id']) ??
        _asInt(
          data['conversation'] is Map
              ? (data['conversation'] as Map)['id']
              : null,
        );
    if (conversationId == null) {
      throw Exception('Missing conversation id');
    }
    ChatConversationModel? conversation;
    final convRaw = data['conversation'];
    if (convRaw is Map<String, dynamic>) {
      conversation = ChatConversationModel.fromJson(convRaw);
    } else if (convRaw is Map) {
      conversation = ChatConversationModel.fromJson(
        Map<String, dynamic>.from(convRaw),
      );
    }
    return ChatOpenConversationResult(
      conversationId: conversationId,
      conversation: conversation,
    );
  }

  dynamic _parseSendMessagePayload(Map<String, dynamic> data) {
    final nested = data['data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    if (data['id'] != null &&
        (data['message'] != null || data['message_id'] != null)) {
      return data;
    }
    return data;
  }

  Map<String, dynamic> _extractDataMap(dynamic root) {
    if (root is Map<String, dynamic>) {
      if (root['data'] is Map) {
        return Map<String, dynamic>.from(root['data'] as Map);
      }
      return root;
    }
    if (root is Map) {
      final map = Map<String, dynamic>.from(root);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    throw Exception('Invalid response');
  }

  bool _isHttpSuccess(Map<String, dynamic> response) {
    final code = response['statusCode'] as int?;
    return code != null && code >= 200 && code < 300;
  }

  void _ensureSuccess(Map<String, dynamic> response, String fallback) {
    if (_isHttpSuccess(response)) {
      final data = response['data'];
      if (data is Map && data['success'] == false) {
        throw Exception(
          _clean(data['message']?.toString() ?? fallback),
        );
      }
      return;
    }
    throw Exception(_clean(response['errorMessage']?.toString() ?? fallback));
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    return message;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
