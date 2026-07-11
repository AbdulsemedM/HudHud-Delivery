import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/chat/bloc/chat_room_bloc.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_model.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/attachment_picker_sheet.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_context_banner.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_messages_shimmer.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_scroll_to_bottom_fab.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/message_bubble.dart';
import 'package:hudhud_delivery/features/chat/utils/chat_format_utils.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class ChatRoomScreen extends StatelessWidget {
  final int conversationId;
  final int? packageDeliveryId;
  final ChatConversationDetailResult? initialDetail;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    this.packageDeliveryId,
    this.initialDetail,
  });

  @override
  Widget build(BuildContext context) {
    return chatRoomBlocProvider(
      conversationId: conversationId,
      packageDeliveryId: packageDeliveryId,
      initialDetail: initialDetail,
      child: _ChatRoomView(
        conversationId: conversationId,
        packageDeliveryId: packageDeliveryId,
      ),
    );
  }
}

class _ChatRoomView extends StatefulWidget {
  final int conversationId;
  final int? packageDeliveryId;

  const _ChatRoomView({
    required this.conversationId,
    this.packageDeliveryId,
  });

  @override
  State<_ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<_ChatRoomView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _auth = AuthService();
  List<String> _pendingPaths = [];
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 200;
    if (show != _showScrollFab) setState(() => _showScrollFab = show);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  int? get _userId => _auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatTheme = ChatTheme.of(context);

    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
      listener: (context, state) {
        if (state is ChatRoomFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is ChatRoomLoaded && state.editingDraft != null) {
          if (_textController.text != state.editingDraft) {
            _textController.text = state.editingDraft!;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is ChatRoomLoading) {
          return const ChatRoomLoadingScaffold();
        }
        if (state is! ChatRoomLoaded) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.chatLoadError)),
          );
        }

        final conv = state.conversation;
        final isPackageDelivery = widget.packageDeliveryId != null ||
            conv.type == ChatConversationType.packageDelivery;
        final title = conv.counterpartyName(_userId) ??
            conv.displayTitle(currentUserId: _userId);
        final subtitle = conv.type == ChatConversationType.order
            ? conv.metadata['order_number']?.toString() ?? conv.subtitleLine()
            : conv.subtitleLine();

        return Scaffold(
          backgroundColor: chatTheme.wallpaper,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17)),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          body: Column(
            children: [
              ChatContextBanner(
                conversation: conv,
                onTap: conv.conversationableId != null &&
                        conv.type == ChatConversationType.order
                    ? () {
                        pushOrderDetailsById(
                          context,
                          orderId: conv.conversationableId!,
                        );
                      }
                    : null,
              ),
              if (state.editingMessageId != null)
                MaterialBanner(
                  content: Text(l10n.chatEditingMessage),
                  leading: const Icon(Icons.edit_outlined),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _textController.clear();
                        context
                            .read<ChatRoomBloc>()
                            .add(const CancelEditMessageEvent());
                      },
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              Expanded(
                child: state.isLoadingHistory
                    ? const ChatMessagesShimmer()
                    : Stack(
                        children: [
                          _MessageList(
                            messages: state.messages,
                            scrollController: _scrollController,
                            currentUserId: _userId,
                            onRetry: (id) => context
                                .read<ChatRoomBloc>()
                                .add(RetrySendMessageEvent(id)),
                            onLongPress: isPackageDelivery
                                ? null
                                : (message) =>
                                    _showMessageActions(context, message),
                          ),
                          if (_showScrollFab)
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: ChatScrollToBottomFab(
                                onPressed: _scrollToBottom,
                              ),
                            ),
                        ],
                      ),
              ),
              ChatInputBar(
                controller: _textController,
                isSending: state.isSending,
                isEditing: state.editingMessageId != null,
                textOnly: isPackageDelivery,
                pendingAttachmentPaths: _pendingPaths,
                onRemoveAttachment: (i) {
                  setState(() => _pendingPaths.removeAt(i));
                },
                onSendText: () => _handleSend(context, state),
                onAttach: () => _handleAttach(context),
                onAudioRecorded: (path) {
                  context.read<ChatRoomBloc>().add(
                        SendAudioMessageEvent(
                          caption: l10n.chatVoiceMessage,
                          filePath: path,
                        ),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSend(BuildContext context, ChatRoomLoaded state) {
    final bloc = context.read<ChatRoomBloc>();
    if (_pendingPaths.isNotEmpty) {
      bloc.add(
        SendImageMessageEvent(
          caption: _textController.text.trim(),
          filePaths: List.from(_pendingPaths),
        ),
      );
      _textController.clear();
      setState(() => _pendingPaths = []);
      return;
    }
    bloc.add(SendTextMessageEvent(_textController.text));
    if (state.editingMessageId == null) {
      _textController.clear();
    }
  }

  Future<void> _handleAttach(BuildContext context) async {
    final result = await showAttachmentPickerSheet(context);
    if (result == null || !context.mounted) return;
    final bloc = context.read<ChatRoomBloc>();
    final l10n = AppLocalizations.of(context)!;

    switch (result.action) {
      case AttachmentPickerAction.image:
        setState(() => _pendingPaths = result.filePaths);
        break;
      case AttachmentPickerAction.file:
        bloc.add(
          SendFileMessageEvent(
            caption: _textController.text.trim().isEmpty
                ? l10n.chatFile
                : _textController.text.trim(),
            filePaths: result.filePaths,
          ),
        );
        _textController.clear();
        break;
      case AttachmentPickerAction.audio:
        break;
      case AttachmentPickerAction.location:
        var loc = StartupLocationService.cached;
        loc ??= await StartupLocationService.fetchAtStartup();
        if (!context.mounted) return;
        if (loc != null) {
          bloc.add(
            SendLocationMessageEvent(
              caption: l10n.chatLocation,
              latitude: loc.latitude,
              longitude: loc.longitude,
              address: loc.toString(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chatLocation)),
          );
        }
        break;
    }
  }

  void _showMessageActions(BuildContext context, ChatMessageModel message) {
    final l10n = AppLocalizations.of(context)!;
    final isMine = message.isMine(_userId);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(l10n.chatCopy),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.body));
                  Navigator.pop(ctx);
                },
              ),
              if (isMine && message.type == ChatMessageType.text)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(l10n.chatEdit),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<ChatRoomBloc>().add(
                          StartEditMessageEvent(
                            messageId: message.id,
                            currentText: message.body,
                          ),
                        );
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(l10n.chatDelete),
                  onTap: () {
                    Navigator.pop(ctx);
                    context
                        .read<ChatRoomBloc>()
                        .add(DeleteMessageEvent(message.id));
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessageModel> messages;
  final ScrollController scrollController;
  final int? currentUserId;
  final void Function(int tempId) onRetry;
  final void Function(ChatMessageModel message)? onLongPress;

  const _MessageList({
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
    required this.onRetry,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Icon(Icons.chat_bubble_outline, size: 48));
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final reverseIndex = messages.length - 1 - index;
        final message = messages[reverseIndex];
        final prev = reverseIndex > 0 ? messages[reverseIndex - 1] : null;
        final next =
            reverseIndex < messages.length - 1 ? messages[reverseIndex + 1] : null;

        final isMine = message.isMine(currentUserId);
        final groupedWithPrev = prev != null &&
            ChatFormatUtils.shouldGroupMessages(
              ChatMessageGroupInfo(
                senderId: prev.senderId,
                createdAt: prev.createdAt ?? prev.deliveredAt,
              ),
              ChatMessageGroupInfo(
                senderId: message.senderId,
                createdAt: message.createdAt ?? message.deliveredAt,
              ),
            );
        final groupedWithNext = next != null &&
            ChatFormatUtils.shouldGroupMessages(
              ChatMessageGroupInfo(
                senderId: message.senderId,
                createdAt: message.createdAt ?? message.deliveredAt,
              ),
              ChatMessageGroupInfo(
                senderId: next.senderId,
                createdAt: next.createdAt ?? next.deliveredAt,
              ),
            );

        final showDate = _shouldShowDateHeader(message, next);

        return Column(
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ChatFormatUtils.formatDateHeader(
                        message.createdAt ??
                            message.deliveredAt ??
                            DateTime.now(),
                      ),
                      style: ChatTheme.of(context).dateHeaderStyle,
                    ),
                  ),
                ),
              ),
            MessageBubble(
              message: message,
              isMine: isMine,
              isGroupedTop: groupedWithPrev,
              isGroupedBottom: groupedWithNext,
              currentUserId: currentUserId,
              onRetry: message.localStatus == ChatMessageStatus.failed
                  ? () => onRetry(message.id)
                  : null,
              onLongPress:
                  onLongPress != null ? () => onLongPress!(message) : null,
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateHeader(ChatMessageModel current, ChatMessageModel? next) {
    if (next == null) return true;
    final cur = current.createdAt ?? current.deliveredAt;
    final nxt = next.createdAt ?? next.deliveredAt;
    if (cur == null || nxt == null) return false;
    return cur.year != nxt.year || cur.month != nxt.month || cur.day != nxt.day;
  }
}
