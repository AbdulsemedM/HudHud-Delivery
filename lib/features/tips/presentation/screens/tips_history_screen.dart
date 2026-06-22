import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/tips/bloc/tips_bloc.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_item_model.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_result.dart';
import 'package:hudhud_delivery/features/tips/tips_bloc_provider.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class TipsHistoryScreen extends StatelessWidget {
  const TipsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return tipsBlocProvider(child: const _TipsHistoryBody());
  }
}

class _TipsHistoryBody extends StatefulWidget {
  const _TipsHistoryBody();

  @override
  State<_TipsHistoryBody> createState() => _TipsHistoryBodyState();
}

class _TipsHistoryBodyState extends State<_TipsHistoryBody> {
  final _scrollController = ScrollController();
  String? _statusFilter = 'completed';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<TipsBloc>().add(LoadTipsHistoryEvent(status: _statusFilter));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TipsBloc>().add(const LoadMoreTipsHistoryEvent());
    }
  }

  void _reload({String? status}) {
    setState(() => _statusFilter = status);
    context.read<TipsBloc>().add(LoadTipsHistoryEvent(status: status));
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _recipientLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'vendor':
        return l10n.tipsRecipientVendor;
      case 'both':
        return l10n.tipsRecipientBoth;
      default:
        return l10n.tipsRecipientDriver;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tipsHistoryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.tipsStatusCompleted),
                  selected: _statusFilter == 'completed',
                  onSelected: (_) => _reload(status: 'completed'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.tipsStatusAll),
                  selected: _statusFilter == null,
                  onSelected: (_) => _reload(status: null),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<TipsBloc, TipsState>(
              listener: (context, state) {
                if (state is TipsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is TipsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TipsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.tipsLoadError),
                          const SizedBox(height: 8),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                _reload(status: _statusFilter),
                            child: Text(l10n.actionRetry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is! TipsLoaded) {
                  return const SizedBox.shrink();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _reload(status: _statusFilter);
                    await context.read<TipsBloc>().stream.firstWhere(
                          (s) => s is TipsLoaded || s is TipsError,
                        );
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _StatsHeader(stats: state.stats, l10n: l10n),
                      ),
                      if (state.history.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              l10n.tipsHistoryEmpty,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= state.history.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _TipHistoryTile(
                                item: state.history[index],
                                dateLabel: _formatDate(
                                  state.history[index].paidAt ??
                                      state.history[index].createdAt,
                                ),
                                recipientLabel: _recipientLabel(
                                  state.history[index].recipientType,
                                  l10n,
                                ),
                              );
                            },
                            childCount: state.history.length +
                                (state.isLoadingMore ? 1 : 0),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final TipHistoryStats stats;
  final AppLocalizations l10n;

  const _StatsHeader({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: l10n.tipsStatsTotal,
              value: '${stats.totalTipsGiven}',
              theme: theme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBox(
              label: l10n.tipsStatsAmount,
              value: stats.totalAmountTipped.toString(),
              theme: theme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBox(
              label: l10n.tipsStatsAverage,
              value: stats.averageTip.toString(),
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatBox({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _TipHistoryTile extends StatelessWidget {
  final TipHistoryItemModel item;
  final String dateLabel;
  final String recipientLabel;

  const _TipHistoryTile({
    required this.item,
    required this.dateLabel,
    required this.recipientLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderNumber = item.order?.orderNumber ?? '#${item.orderId}';
    return ListTile(
      title: Text(
        orderNumber,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text('$recipientLabel · ${item.paymentStatus}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ETB ${item.amount}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(dateLabel, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
