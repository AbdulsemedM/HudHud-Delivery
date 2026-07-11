import 'package:intl/intl.dart';

class ChatFormatUtils {
  ChatFormatUtils._();

  static String formatListTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final local = dateTime.toLocal();
    if (_isSameDay(local, now)) {
      return DateFormat.jm().format(local);
    }
    if (_isSameDay(local, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat.E().format(local);
    }
    return DateFormat.MMMd().format(local);
  }

  static String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat.jm().format(dateTime.toLocal());
  }

  static String formatDateHeader(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    if (_isSameDay(local, now)) return 'Today';
    if (_isSameDay(local, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat.yMMMMd().format(local);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool shouldGroupMessages(
    ChatMessageGroupInfo? previous,
    ChatMessageGroupInfo current, {
    int maxMinutes = 2,
  }) {
    if (previous == null) return false;
    if (previous.senderId != current.senderId) return false;
    final prevTime = previous.createdAt;
    final curTime = current.createdAt;
    if (prevTime == null || curTime == null) return true;
    return curTime.difference(prevTime).inMinutes.abs() <= maxMinutes;
  }
}

class ChatMessageGroupInfo {
  final int senderId;
  final DateTime? createdAt;

  const ChatMessageGroupInfo({
    required this.senderId,
    this.createdAt,
  });
}
