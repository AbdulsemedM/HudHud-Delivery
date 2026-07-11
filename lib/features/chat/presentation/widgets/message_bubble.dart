import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/message_status_icon.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_format_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final bool isGroupedTop;
  final bool isGroupedBottom;
  final int? currentUserId;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isGroupedTop,
    required this.isGroupedBottom,
    this.currentUserId,
    this.onRetry,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final chatTheme = ChatTheme.of(context);
    final l10n = context.l10n;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final contentColor = isMine ? Colors.white : chatTheme.messageTextStyle.color;

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chatTheme.receivedBubble.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppColors.r12),
              ),
              child: Text(
                l10n.chatDeleted,
                style: chatTheme.timestampStyle.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final radius = chatTheme.bubbleRadius(
      isMine: isMine,
      isGroupedTop: isGroupedTop,
    );

    Widget bubbleChild = _buildContent(context, chatTheme, l10n, contentColor);

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      onTap: message.localStatus == ChatMessageStatus.failed ? onRetry : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: isMine ? chatTheme.sentGradient() : null,
          color: isMine ? null : chatTheme.receivedBubble,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isMine ? 0.08 : 0.04),
              blurRadius: isMine ? 6 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: align,
          children: [
            bubbleChild,
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      l10n.chatEdited,
                      style: chatTheme.timestampStyle.copyWith(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.75)
                            : chatTheme.timestampColor,
                      ),
                    ),
                  ),
                Text(
                  ChatFormatUtils.formatMessageTime(
                    message.createdAt ?? message.deliveredAt,
                  ),
                  style: chatTheme.timestampStyle.copyWith(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.8)
                        : chatTheme.timestampColor,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  MessageStatusIcon(
                    status: message.deliveryStatus(),
                    isMine: isMine,
                  ),
                ],
              ],
            ),
            if (message.localStatus == ChatMessageStatus.failed &&
                onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.chatRetry,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMine ? Colors.red[100] : AppColors.errorColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: isGroupedTop ? 2 : 8,
        bottom: isGroupedBottom ? 2 : 6,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Flexible(child: bubble)],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ChatTheme chatTheme,
    dynamic l10n,
    Color? contentColor,
  ) {
    switch (message.type) {
      case ChatMessageType.image:
        return _ImageContent(message: message, isMine: isMine);
      case ChatMessageType.file:
        return _FileContent(
          message: message,
          l10n: l10n,
          contentColor: contentColor,
        );
      case ChatMessageType.audio:
        return _AudioContent(
          message: message,
          l10n: l10n,
          contentColor: contentColor,
        );
      case ChatMessageType.location:
        return _LocationContent(
          message: message,
          l10n: l10n,
          isMine: isMine,
          contentColor: contentColor,
        );
      case ChatMessageType.text:
      case ChatMessageType.unknown:
        return Linkify(
          onOpen: (link) => launchUrl(Uri.parse(link.url)),
          text: message.body,
          style: chatTheme.messageTextStyle.copyWith(color: contentColor),
          linkStyle: TextStyle(
            color: isMine ? Colors.white : Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }
}

class _ImageContent extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _ImageContent({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final urls = message.attachments
        .map((a) => a.url)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      return Text(
        message.body,
        style: TextStyle(color: isMine ? Colors.white : null),
      );
    }

    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: GestureDetector(
          onTap: () => _openViewer(context, urls.first),
          child: CachedNetworkImage(
            imageUrl: urls.first,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => _ImageShimmer(height: 200),
            errorWidget: (_, __, ___) => _ImageError(isMine: isMine),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: urls.length.clamp(0, 4),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openViewer(context, urls[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.r8),
            child: CachedNetworkImage(
              imageUrl: urls[index],
              fit: BoxFit.cover,
              height: 100,
              placeholder: (_, __) => _ImageShimmer(height: 100),
              errorWidget: (_, __, ___) => _ImageError(isMine: isMine),
            ),
          ),
        );
      },
    );
  }

  void _openViewer(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(url: url),
      ),
    );
  }
}

class _ImageShimmer extends StatelessWidget {
  final double height;

  const _ImageShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceLight,
      highlightColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  final bool isMine;

  const _ImageError({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      color: isMine
          ? Colors.white.withValues(alpha: 0.15)
          : AppColors.surfaceLight,
      child: Icon(
        Icons.broken_image_outlined,
        color: isMine ? Colors.white70 : AppColors.mutedLight,
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;

  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  final ChatMessageModel message;
  final dynamic l10n;
  final Color? contentColor;

  const _FileContent({
    required this.message,
    required this.l10n,
    this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.body.isNotEmpty)
          Text(message.body, style: TextStyle(color: contentColor)),
        ...message.attachments.map((a) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.insert_drive_file_rounded,
              color: contentColor,
            ),
            title: Text(
              a.name ?? l10n.chatFile,
              style: TextStyle(color: contentColor, fontSize: 13),
            ),
            subtitle: a.sizeLabel != null
                ? Text(
                    a.sizeLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      color: contentColor?.withValues(alpha: 0.7),
                    ),
                  )
                : null,
            onTap: a.url != null
                ? () => launchUrl(
                      Uri.parse(a.url!),
                      mode: LaunchMode.externalApplication,
                    )
                : null,
          );
        }),
      ],
    );
  }
}

class _AudioContent extends StatelessWidget {
  final ChatMessageModel message;
  final dynamic l10n;
  final Color? contentColor;

  const _AudioContent({
    required this.message,
    required this.l10n,
    this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = message.attachments.isNotEmpty
        ? message.attachments.first.url
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mic_rounded, color: contentColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message.body.isNotEmpty ? message.body : l10n.chatVoiceMessage,
            style: TextStyle(color: contentColor),
          ),
        ),
        if (url != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.play_circle_fill_rounded, color: contentColor),
            onPressed: () => launchUrl(Uri.parse(url)),
          ),
      ],
    );
  }
}

class _LocationContent extends StatelessWidget {
  final ChatMessageModel message;
  final dynamic l10n;
  final bool isMine;
  final Color? contentColor;

  const _LocationContent({
    required this.message,
    required this.l10n,
    required this.isMine,
    this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    final meta = message.metadata ?? {};
    final lat = meta['latitude'];
    final lng = meta['longitude'];
    final address = meta['address']?.toString() ?? message.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isMine
                ? Colors.white.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppColors.r12),
          ),
          child: Icon(
            Icons.location_on_rounded,
            size: 40,
            color: isMine ? Colors.white : AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(address, style: TextStyle(color: contentColor)),
        if (lat != null && lng != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isMine ? Colors.white : AppColors.primaryColor,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
              );
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Text(l10n.chatOpenMaps),
          ),
      ],
    );
  }
}
