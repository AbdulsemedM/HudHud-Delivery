import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversations_list_result.dart';

/// Extracts every conversation object from variable HudHud list API shapes.
class ChatConversationsResponseParser {
  ChatConversationsResponseParser._();

  static const _listKeys = [
    'data',
    'conversations',
    'items',
    'results',
    'records',
  ];

  static const _groupedListKeys = [
    'support',
    'order',
    'orders',
    'ride',
    'rides',
    'delivery',
    'taxi',
  ];

  static ChatConversationsListResult parse(dynamic root) {
    final maps = collectConversationMaps(root);
    final conversations = maps.map(ChatConversationModel.fromJson).toList();
    final meta = _extractMeta(root);
    return ChatConversationsListResult(
      conversations: conversations,
      totalUnread: _readTotalUnread(meta, conversations),
    );
  }

  static List<Map<String, dynamic>> collectConversationMaps(dynamic root) {
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addMap(Map<String, dynamic> map) {
      if (!_looksLikeConversation(map)) return;
      final key = _dedupeKey(map);
      if (seen.contains(key)) return;
      seen.add(key);
      results.add(map);
    }

    void walk(dynamic node) {
      if (node == null) return;

      if (node is List) {
        for (final item in node) {
          if (item is Map<String, dynamic>) {
            addMap(item);
          } else if (item is Map) {
            addMap(Map<String, dynamic>.from(item));
          }
        }
        return;
      }

      if (node is! Map) return;
      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node);

      for (final listKey in _listKeys) {
        if (map.containsKey(listKey)) {
          walk(map[listKey]);
        }
      }

      for (final entry in map.entries) {
        final key = entry.key.toLowerCase();
        if (entry.value is! List) continue;
        if (_groupedListKeys.contains(key) ||
            key.endsWith('_conversations')) {
          walk(entry.value);
        }
      }

      if (_looksLikeConversation(map)) {
        addMap(map);
      }
    }

    if (root is Map &&
        root['data'] != null &&
        (root.containsKey('success') || root['data'] is Map || root['data'] is List)) {
      walk(root['data']);
      if (results.isEmpty) {
        walk(root);
      }
    } else {
      walk(root);
    }

    return results;
  }

  static bool _looksLikeConversation(Map<String, dynamic> map) {
    final hasIdentifier =
        map['id'] != null || map['conversation_id'] != null;
    if (!hasIdentifier) return false;

    return map['type'] != null ||
        map['status'] != null ||
        map['metadata'] != null ||
        map['conversationable_type'] != null ||
        map['last_message'] != null ||
        map['last_message_at'] != null;
  }

  static String _dedupeKey(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final slug = map['conversation_id']?.toString() ?? '';
    final type = map['type']?.toString() ?? '';
    return '$type|$id|$slug';
  }

  static Map<String, dynamic>? _extractMeta(dynamic root) {
    if (root is! Map) return null;
    final map = root is Map<String, dynamic>
        ? root
        : Map<String, dynamic>.from(root);

    final direct = map['meta'];
    if (direct is Map<String, dynamic>) return direct;
    if (direct is Map) return Map<String, dynamic>.from(direct);

    final data = map['data'];
    if (data is Map) {
      final nested = data['meta'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }
    return null;
  }

  static int _readTotalUnread(
    Map<String, dynamic>? meta,
    List<ChatConversationModel> conversations,
  ) {
    if (meta != null) {
      final raw = meta['total_unread'];
      if (raw is int) return raw;
      final parsed = int.tryParse(raw?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }
}
