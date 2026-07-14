import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton placeholders for the chat message list while history loads.
class ChatMessagesShimmer extends StatelessWidget {
  const ChatMessagesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final baseColor =
        isDark ? scheme.surfaceContainerHigh : Colors.grey.shade300;
    final highlightColor =
        isDark ? scheme.surfaceContainerHighest : Colors.grey.shade100;
    final bubbleColor =
        isDark ? scheme.surfaceContainerHighest : Colors.white;
    final sentBubbleColor = isDark
        ? scheme.primary.withValues(alpha: 0.35)
        : scheme.primary.withValues(alpha: 0.18);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          _BubbleRow(
            alignEnd: true,
            widthFactor: 0.52,
            color: sentBubbleColor,
          ),
          const SizedBox(height: 10),
          _BubbleRow(
            alignEnd: false,
            widthFactor: 0.64,
            color: bubbleColor,
          ),
          const SizedBox(height: 10),
          _BubbleRow(
            alignEnd: true,
            widthFactor: 0.38,
            color: sentBubbleColor,
          ),
          const SizedBox(height: 10),
          _BubbleRow(
            alignEnd: false,
            widthFactor: 0.48,
            color: bubbleColor,
          ),
          const SizedBox(height: 10),
          _BubbleRow(
            alignEnd: true,
            widthFactor: 0.58,
            color: sentBubbleColor,
          ),
          const SizedBox(height: 10),
          _BubbleRow(
            alignEnd: false,
            widthFactor: 0.42,
            color: bubbleColor,
          ),
        ],
      ),
    );
  }
}

class ChatRoomLoadingScaffold extends StatelessWidget {
  const ChatRoomLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final chatTheme = ChatTheme.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final baseColor =
        isDark ? scheme.surfaceContainerHigh : Colors.grey.shade300;
    final highlightColor =
        isDark ? scheme.surfaceContainerHighest : Colors.grey.shade100;
    final placeholder =
        isDark ? scheme.surfaceContainerHighest : Colors.white;

    return Scaffold(
      backgroundColor: chatTheme.wallpaper,
      appBar: AppBar(
        title: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 140,
                decoration: BoxDecoration(
                  color: placeholder,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 96,
                decoration: BoxDecoration(
                  color: placeholder,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const Expanded(child: ChatMessagesShimmer()),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 56,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: placeholder,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleRow extends StatelessWidget {
  const _BubbleRow({
    required this.alignEnd,
    required this.widthFactor,
    required this.color,
  });

  final bool alignEnd;
  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bubbleWidth = maxWidth.isFinite
            ? maxWidth * widthFactor
            : MediaQuery.sizeOf(context).width * 0.78 * widthFactor;

        return Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              width: bubbleWidth,
              height: alignEnd ? 40 : 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(alignEnd ? 16 : 4),
                  bottomRight: Radius.circular(alignEnd ? 4 : 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
