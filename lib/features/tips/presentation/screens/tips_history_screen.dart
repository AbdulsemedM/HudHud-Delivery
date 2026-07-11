import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/tips/bloc/tips_bloc.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_item_model.dart';
import 'package:hudhud_delivery/features/tips/model/tip_history_result.dart';
import 'package:hudhud_delivery/features/tips/tips_bloc_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

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

  String _recipientLabel(String type) {
    final l10n = context.l10n;
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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.tipsHistoryTitle),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.sp16,
              AppColors.sp12,
              AppColors.sp16,
              0,
            ),
            child: _TipsFilterChips(
              selectedStatus: _statusFilter,
              onStatusChanged: (status) => _reload(status: status),
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
                  return const _TipsHistoryShimmer();
                }
                if (state is TipsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppColors.sp24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconBox(
                            icon: Icons.error_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: AppColors.sp16),
                          Text(
                            l10n.tipsLoadError,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppColors.sp8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppColors.sp16),
                          FilledButton(
                            onPressed: () => _reload(status: _statusFilter),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppColors.r12),
                              ),
                            ),
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
                        child: _StatsHeader(stats: state.stats),
                      ),
                      if (state.history.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _TipsEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppColors.sp16,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= state.history.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(AppColors.sp16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final item = state.history[index];
                                return _TipHistoryCard(
                                  item: item,
                                  dateLabel: _formatDate(
                                    item.paidAt ?? item.createdAt,
                                  ),
                                  recipientLabel:
                                      _recipientLabel(item.recipientType),
                                );
                              },
                              childCount: state.history.length +
                                  (state.isLoadingMore ? 1 : 0),
                            ),
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

class _TipsFilterChips extends StatelessWidget {
  const _TipsFilterChips({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = <({String? value, String label})>[
      (value: 'completed', label: l10n.tipsStatusCompleted),
      (value: null, label: l10n.tipsStatusAll),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppColors.sp8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedStatus == filter.value;

          return FilterChip(
            label: Text(filter.label),
            selected: isSelected,
            showCheckmark: false,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryColor
                  : theme.colorScheme.onSurface,
            ),
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            selectedColor: AppColors.primaryColor.withOpacity(0.12),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.5)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.rFull),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) => onStatusChanged(filter.value),
          );
        },
      ),
    );
  }
}

class _TipsHistoryShimmer extends StatelessWidget {
  const _TipsHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.grey.shade300;
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade100;
    final placeholder = isDark ? AppColors.surfaceDark : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.all(AppColors.sp16),
        children: [
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  height: 72,
                  margin: const EdgeInsets.only(right: AppColors.sp8),
                  decoration: BoxDecoration(
                    color: placeholder,
                    borderRadius: BorderRadius.circular(AppColors.r12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppColors.sp16),
          ...List.generate(
            4,
            (_) => Container(
              height: 96,
              margin: const EdgeInsets.only(bottom: AppColors.sp12),
              decoration: BoxDecoration(
                color: placeholder,
                borderRadius: BorderRadius.circular(AppColors.r12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.sp32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/browse.json',
              width: 160,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppColors.sp16),
            Text(
              l10n.tipsHistoryEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppColors.sp8),
            Text(
              l10n.tipsAddTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final TipHistoryStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppColors.sp16),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(
              label: l10n.tipsStatsTotal,
              value: '${stats.totalTipsGiven}',
              icon: Icons.volunteer_activism_outlined,
            ),
          ),
          const SizedBox(width: AppColors.sp8),
          Expanded(
            child: _StatBox(
              label: l10n.tipsStatsAmount,
              value: stats.totalAmountTipped.toString(),
              icon: Icons.payments_outlined,
            ),
          ),
          const SizedBox(width: AppColors.sp8),
          Expanded(
            child: _StatBox(
              label: l10n.tipsStatsAverage,
              value: stats.averageTip.toString(),
              icon: Icons.trending_up_rounded,
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
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppColors.sp12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.r12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          IconBox(icon: icon, color: AppColors.primaryColor),
          const SizedBox(height: AppColors.sp8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppColors.sp4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipHistoryCard extends StatelessWidget {
  final TipHistoryItemModel item;
  final String dateLabel;
  final String recipientLabel;

  const _TipHistoryCard({
    required this.item,
    required this.dateLabel,
    required this.recipientLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final orderNumber = item.order?.orderNumber ?? '#${item.orderId}';
    final status = item.paymentStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: AppColors.sp12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.r12),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppColors.sp12),
        child: Row(
          children: [
            IconBox(
              icon: Icons.volunteer_activism_outlined,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: AppColors.sp12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderNumber,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipientLabel,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.l10n.taxiFareAmount(item.amount.toString()),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: AppColors.sp8),
                StatusChip(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
