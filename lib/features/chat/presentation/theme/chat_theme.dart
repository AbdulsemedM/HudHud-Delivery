import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class ChatTheme {
  final bool isDark;
  final Color sentBubbleStart;
  final Color sentBubbleEnd;
  final Color receivedBubble;
  final Color wallpaper;
  final Color composerBackground;
  final Color timestampColor;
  final Color unreadBadge;
  final TextStyle messageTextStyle;
  final TextStyle timestampStyle;
  final TextStyle dateHeaderStyle;

  const ChatTheme({
    required this.isDark,
    required this.sentBubbleStart,
    required this.sentBubbleEnd,
    required this.receivedBubble,
    required this.wallpaper,
    required this.composerBackground,
    required this.timestampColor,
    required this.unreadBadge,
    required this.messageTextStyle,
    required this.timestampStyle,
    required this.dateHeaderStyle,
  });

  factory ChatTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    if (isDark) {
      return ChatTheme(
        isDark: true,
        sentBubbleStart: AppColors.primaryColor.withValues(alpha: 0.85),
        sentBubbleEnd: AppColors.primaryDarkColor,
        receivedBubble: const Color(0xFF2A2A2A),
        wallpaper: const Color(0xFF0E0E0E),
        composerBackground: const Color(0xFF151515).withValues(alpha: 0.92),
        timestampColor: AppColors.darkTextSecondary,
        unreadBadge: AppColors.secondaryColor,
        messageTextStyle: TextStyle(
          fontSize: 15.5,
          height: 1.35,
          color: scheme.onSurface,
        ),
        timestampStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.darkTextSecondary,
        ),
        dateHeaderStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
        ),
      );
    }
    return ChatTheme(
      isDark: false,
      sentBubbleStart: AppColors.primaryColor,
      sentBubbleEnd: AppColors.primaryLightColor,
      receivedBubble: const Color(0xFFF0F2F5),
      wallpaper: AppColors.lightBackground,
      composerBackground: AppColors.lightSurface.withValues(alpha: 0.95),
      timestampColor: AppColors.lightTextSecondary,
      unreadBadge: AppColors.secondaryColor,
      messageTextStyle: const TextStyle(
        fontSize: 15.5,
        height: 1.35,
        color: AppColors.lightTextPrimary,
      ),
      timestampStyle: const TextStyle(
        fontSize: 11,
        color: AppColors.lightTextSecondary,
      ),
      dateHeaderStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextSecondary,
      ),
    );
  }

  BorderRadius bubbleRadius({required bool isMine, required bool isGroupedTop}) {
    const r = 18.0;
    const small = 6.0;
    if (isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(r),
        topRight: Radius.circular(isGroupedTop ? small : r),
        bottomLeft: const Radius.circular(r),
        bottomRight: const Radius.circular(small),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(isGroupedTop ? small : r),
      topRight: const Radius.circular(r),
      bottomLeft: const Radius.circular(small),
      bottomRight: const Radius.circular(r),
    );
  }

  LinearGradient sentGradient() {
    return LinearGradient(
      colors: [sentBubbleStart, sentBubbleEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
