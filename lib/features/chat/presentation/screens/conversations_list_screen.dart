import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/chat/bloc/conversations_bloc.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_open_conversation_result.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/support_chat_start_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/theme/chat_theme.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_empty_state.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/conversation_list_tile.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return conversationsBlocProvider(
      child: const _ConversationsListBody(),
    );
  }
}

class _ConversationsListBody extends StatefulWidget {
  const _ConversationsListBody();

  @override
  State<_ConversationsListBody> createState() => _ConversationsListBodyState();
}

class _ConversationsListBodyState extends State<_ConversationsListBody> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRoom(
    int conversationId, {
    ChatConversationDetailResult? initialDetail,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: conversationId,
          initialDetail: initialDetail,
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<ConversationsBloc>().add(const RefreshConversationsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chatTheme = ChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ConversationsBloc, ConversationsState>(
      listener: (context, state) {
        if (state is SupportConversationCreated) {
          _openRoom(
            state.openResult.conversationId,
            initialDetail: ChatConversationDetailResult.fromOpenResult(
              state.openResult,
            ),
          );
        }
        if (state is ConversationsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: chatTheme.wallpaper,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0.5,
            backgroundColor: chatTheme.composerBackground,
            title: Row(
              children: [
                Text(
                  l10n.chatTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (state is ConversationsLoaded && state.totalUnread > 0) ...[
                  const SizedBox(width: 10),
                  ChatUnreadBadge(count: state.totalUnread),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      context.read<ConversationsBloc>().add(
                            const SearchConversationsEvent(''),
                          );
                    }
                  });
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final open = await Navigator.of(context)
                  .push<ChatOpenConversationResult>(
                MaterialPageRoute(
                  builder: (_) => const SupportChatStartScreen(),
                ),
              );
              if (open != null && context.mounted) {
                _openRoom(
                  open.conversationId,
                  initialDetail:
                      ChatConversationDetailResult.fromOpenResult(open),
                );
              }
            },
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(l10n.chatNewSupport),
          ),
          body: Column(
            children: [
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.chatSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkInputFill
                          : AppColors.lightInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppColors.rFull),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (q) => context
                        .read<ConversationsBloc>()
                        .add(SearchConversationsEvent(q)),
                  ),
                ),
              Expanded(child: _buildBody(context, state, l10n)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConversationsState state,
    AppLocalizations l10n,
  ) {
    if (state is ConversationsLoading) {
      return const _ShimmerList();
    }
    if (state is ConversationsFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                onPressed: () => context
                    .read<ConversationsBloc>()
                    .add(const LoadConversationsEvent()),
                child: Text(l10n.actionTryAgain),
              ),
            ],
          ),
        ),
      );
    }
    if (state is ConversationsLoaded) {
      if (state.filtered.isEmpty) {
        return ChatEmptyState(
          onContactSupport: () async {
            final open = await Navigator.of(context)
                .push<ChatOpenConversationResult>(
              MaterialPageRoute(
                builder: (_) => const SupportChatStartScreen(),
              ),
            );
            if (open != null && context.mounted) {
              _openRoom(
                open.conversationId,
                initialDetail:
                    ChatConversationDetailResult.fromOpenResult(open),
              );
            }
          },
          onViewOrders: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          },
        );
      }
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          context.read<ConversationsBloc>().add(const RefreshConversationsEvent());
          await context.read<ConversationsBloc>().stream.firstWhere(
                (s) => s is ConversationsLoaded && !s.isRefreshing,
              );
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.filtered.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 86,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
          itemBuilder: (context, index) {
            final c = state.filtered[index];
            final bloc = context.read<ConversationsBloc>();
            return ConversationListTile(
              conversation: c,
              currentUserId: bloc.currentUserId,
              onTap: () => _openRoom(
                c.id,
                initialDetail: ChatConversationDetailResult(
                  conversation: c,
                  messages: const [],
                ),
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final baseColor =
        isDark ? scheme.surfaceContainerHigh : AppColors.surfaceLight;
    final highlightColor = isDark ? scheme.surfaceContainerHighest : Colors.white;
    final placeholder =
        isDark ? scheme.surfaceContainerHighest : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: placeholder),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: placeholder,
                              borderRadius:
                                  BorderRadius.circular(AppColors.r8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        Container(
                          width: 36,
                          height: 10,
                          decoration: BoxDecoration(
                            color: placeholder,
                            borderRadius: BorderRadius.circular(AppColors.r8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: placeholder,
                        borderRadius: BorderRadius.circular(AppColors.r8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
