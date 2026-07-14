import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/chat/bloc/conversations_bloc.dart';
import 'package:hudhud_delivery/features/chat/chat_bloc_provider.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';
import 'package:hudhud_delivery/features/chat/model/chat_open_conversation_result.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/screens/support_chat_start_screen.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/chat_empty_state.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/conversation_list_tile.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
        return ProfileDarkPage(
          titleWidget: Row(
            children: [
              Text(
                l10n.chatTitle,
                style: const TextStyle(
                  color: AuthScreenColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state is ConversationsLoaded && state.totalUnread > 0) ...[
                const SizedBox(width: 8),
                ChatUnreadBadge(count: state.totalUnread),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
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
            backgroundColor: AuthScreenColors.orange,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.support_agent_rounded),
            label: Text(l10n.chatNewSupport),
          ),
          body: Column(
            children: [
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AuthScreenColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.chatSearchHint,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AuthScreenColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AuthScreenColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AuthScreenColors.surfaceBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AuthScreenColors.orange,
                          width: 1.5,
                        ),
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
      return _ShimmerList();
    }
    if (state is ConversationsFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.message,
              style: const TextStyle(color: AuthScreenColors.textPrimary),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context
                  .read<ConversationsBloc>()
                  .add(const LoadConversationsEvent()),
              style: FilledButton.styleFrom(
                backgroundColor: AuthScreenColors.orange,
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.actionTryAgain),
            ),
          ],
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
        onRefresh: () async {
          context
              .read<ConversationsBloc>()
              .add(const RefreshConversationsEvent());
          await context.read<ConversationsBloc>().stream.firstWhere(
                (s) => s is ConversationsLoaded && !s.isRefreshing,
              );
        },
        child: ListView.separated(
          itemCount: state.filtered.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 86,
            color: AuthScreenColors.surfaceBorder,
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
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuthScreenColors.surface,
      highlightColor: AuthScreenColors.surfaceBorder,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AuthScreenColors.surfaceBorder,
          ),
          title: SizedBox(
            height: 14,
            child: ColoredBox(color: AuthScreenColors.surfaceBorder),
          ),
          subtitle: SizedBox(
            height: 12,
            child: ColoredBox(color: AuthScreenColors.surfaceBorder),
          ),
        ),
      ),
    );
  }
}
