import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/message_status_icon.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_format_utils.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final sentText = chatTheme.sentTextColor;

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(
              l10n.chatDeleted,
              style: chatTheme.timestampStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final radius = chatTheme.bubbleRadius(
      isMine: isMine,
      isGroupedTop: isGroupedTop,
    );

    Widget bubbleChild = _buildContent(context, chatTheme, l10n, sentText);

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      onTap: message.localStatus == ChatMessageStatus.failed ? onRetry : null,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: isMine ? chatTheme.sentGradient() : null,
          color: isMine ? null : chatTheme.receivedBubble,
          boxShadow: isMine
              ? null
              : [
                  BoxShadow(
                    color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
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
                            ? sentText.withValues(alpha: 0.75)
                            : chatTheme.timestampColor,
                      ),
                    ),
                  ),
                Text(
                  ChatFormatUtils.formatMessageTime(
                    message.createdAt ?? message.deliveredAt,
                  ),
                  style: chatTheme.timestampStyle.copyWith(
                    color: isMine
                        ? sentText.withValues(alpha: 0.8)
                        : chatTheme.timestampColor,
                  ),
                ),
                const SizedBox(width: 4),
                MessageStatusIcon(
                  status: message.deliveryStatus(),
                  isMine: isMine,
                  onBubbleColor: sentText.withValues(alpha: 0.85),
                ),
              ],
            ),
            if (message.localStatus == ChatMessageStatus.failed && onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.chatRetry,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.error.withValues(alpha: 0.85),
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
        bottom: isGroupedBottom ? 2 : 4,
        left: 12,
        right: 12,
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
    AppLocalizations l10n,
    Color sentText,
  ) {
    switch (message.type) {
      case ChatMessageType.image:
        return _ImageContent(message: message, isMine: isMine, sentText: sentText);
      case ChatMessageType.file:
        return _FileContent(
          message: message,
          l10n: l10n,
          isMine: isMine,
          sentText: sentText,
          receivedText: chatTheme.messageTextStyle.color,
        );
      case ChatMessageType.audio:
        return _AudioContent(
          message: message,
          l10n: l10n,
          isMine: isMine,
          sentText: sentText,
          receivedText: chatTheme.messageTextStyle.color,
        );
      case ChatMessageType.location:
        return _LocationContent(
          message: message,
          l10n: l10n,
          isMine: isMine,
          sentText: sentText,
          receivedText: chatTheme.messageTextStyle.color,
        );
      case ChatMessageType.text:
      case ChatMessageType.unknown:
        return Linkify(
          onOpen: (link) => launchUrl(Uri.parse(link.url)),
          text: message.body,
          style: chatTheme.messageTextStyle.copyWith(
            color: isMine ? sentText : chatTheme.messageTextStyle.color,
          ),
          linkStyle: TextStyle(
            color: isMine ? sentText : Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        );
    }
  }
}

class _ImageContent extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final Color sentText;

  const _ImageContent({
    required this.message,
    required this.isMine,
    required this.sentText,
  });

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
        style: TextStyle(color: isMine ? sentText : null),
      );
    }

    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _openViewer(context, urls.first),
          child: CachedNetworkImage(
            imageUrl: urls.first,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
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
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: urls[index],
              fit: BoxFit.cover,
              height: 100,
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

class _FullScreenImage extends StatelessWidget {
  final String url;

  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightOnBackground;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
      ),
      body: InteractiveViewer(
        child: Center(
          child: CachedNetworkImage(imageUrl: url),
        ),
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  final ChatMessageModel message;
  final AppLocalizations l10n;
  final bool isMine;
  final Color? sentText;
  final Color? receivedText;

  const _FileContent({
    required this.message,
    required this.l10n,
    required this.isMine,
    required this.sentText,
    required this.receivedText,
  });

  Color get _textColor => isMine ? sentText! : receivedText!;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.body.isNotEmpty)
          Text(message.body, style: TextStyle(color: _textColor)),
        ...message.attachments.map((a) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.insert_drive_file_rounded, color: _textColor),
            title: Text(
              a.name ?? l10n.chatFile,
              style: TextStyle(color: _textColor, fontSize: 13),
            ),
            subtitle: a.sizeLabel != null
                ? Text(a.sizeLabel!, style: const TextStyle(fontSize: 11))
                : null,
            onTap: a.url != null
                ? () => launchUrl(Uri.parse(a.url!), mode: LaunchMode.externalApplication)
                : null,
          );
        }),
      ],
    );
  }
}

class _AudioContent extends StatelessWidget {
  final ChatMessageModel message;
  final AppLocalizations l10n;
  final bool isMine;
  final Color? sentText;
  final Color? receivedText;

  const _AudioContent({
    required this.message,
    required this.l10n,
    required this.isMine,
    required this.sentText,
    required this.receivedText,
  });

  Color get _textColor => isMine ? sentText! : receivedText!;

  @override
  Widget build(BuildContext context) {
    final url = message.attachments.isNotEmpty
        ? message.attachments.first.url
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mic_rounded, color: _textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message.body.isNotEmpty ? message.body : l10n.chatVoiceMessage,
            style: TextStyle(color: _textColor),
          ),
        ),
        if (url != null)
          IconButton(
            icon: Icon(Icons.play_arrow_rounded, color: _textColor),
            onPressed: () => launchUrl(Uri.parse(url)),
          ),
      ],
    );
  }
}

class _LocationContent extends StatelessWidget {
  final ChatMessageModel message;
  final AppLocalizations l10n;
  final bool isMine;
  final Color? sentText;
  final Color? receivedText;

  const _LocationContent({
    required this.message,
    required this.l10n,
    required this.isMine,
    required this.sentText,
    required this.receivedText,
  });

  Color get _textColor => isMine ? sentText! : receivedText!;

  @override
  Widget build(BuildContext context) {
    final meta = message.metadata ?? {};
    final lat = meta['latitude'];
    final lng = meta['longitude'];
    final address = meta['address']?.toString() ?? message.body;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_on_rounded, size: 48, color: scheme.primary),
        ),
        const SizedBox(height: 8),
        Text(address, style: TextStyle(color: _textColor)),
        if (lat != null && lng != null)
          TextButton(
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
