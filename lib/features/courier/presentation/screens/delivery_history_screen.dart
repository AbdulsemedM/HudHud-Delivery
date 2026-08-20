import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/delivery_details_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/delivery_history_card.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_history_filter.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/home_widget.dart';

/// Full delivery history with status filters.
class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  late final CourierRepository _courierRepository;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedFilter = kDeliveryHistoryFilterAll;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _fetchDeliveries();
  }

  List<Map<String, dynamic>> get _filteredDeliveries {
    if (_selectedFilter == kDeliveryHistoryFilterAll) return _deliveries;
    return _deliveries.where((d) {
      return matchesDeliveryHistoryFilter(
        resolveDeliveryStatus(d),
        _selectedFilter,
      );
    }).toList();
  }

  Future<void> _fetchDeliveries({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final result = await _courierRepository.getUserDeliveries(page: 1);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _deliveries = result['deliveries'] as List<Map<String, dynamic>>;
          _currentPage = result['currentPage'] as int? ?? 1;
          _lastPage = result['lastPage'] as int? ?? 1;
          _error = null;
        } else {
          _deliveries = [];
          _error = result['message'] as String?;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deliveries = [];
        _isLoading = false;
        _error = context.l10n.failedToLoadHistory;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final result =
          await _courierRepository.getUserDeliveries(page: nextPage);
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        if (result['success'] == true) {
          final more = result['deliveries'] as List<Map<String, dynamic>>;
          _deliveries = [..._deliveries, ...more];
          _currentPage = result['currentPage'] as int? ?? nextPage;
          _lastPage = result['lastPage'] as int? ?? _lastPage;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _openDetails(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailsScreen(deliveryId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const borderColor = HomeColors.border;
    final filtered = _filteredDeliveries;
    final canLoadMore = _currentPage < _lastPage &&
        _selectedFilter == kDeliveryHistoryFilterAll;

    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.background,
        appBar: AppBar(
          backgroundColor: HomeColors.background,
          foregroundColor: HomeColors.textPrimary,
          elevation: 0,
          title: Text(l10n.history),
        ),
        body: RefreshIndicator(
          color: HomeColors.violet,
          backgroundColor: HomeColors.surface,
          onRefresh: () => _fetchDeliveries(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.spaceMD,
                    AppColors.spaceSM,
                    AppColors.spaceMD,
                    AppColors.spaceMD,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _HistoryFilterChip(
                          label: l10n.orders,
                          selected:
                              _selectedFilter == kDeliveryHistoryFilterAll,
                          onTap: () => setState(() =>
                              _selectedFilter = kDeliveryHistoryFilterAll),
                        ),
                        const SizedBox(width: 8),
                        _HistoryFilterChip(
                          label: l10n.courierActiveDelivery,
                          selected: _selectedFilter ==
                              kDeliveryHistoryFilterActive,
                          onTap: () => setState(() =>
                              _selectedFilter = kDeliveryHistoryFilterActive),
                        ),
                        const SizedBox(width: 8),
                        _HistoryFilterChip(
                          label: l10n.orderStatusDelivered,
                          selected: _selectedFilter ==
                              kDeliveryHistoryFilterCompleted,
                          onTap: () => setState(() => _selectedFilter =
                              kDeliveryHistoryFilterCompleted),
                        ),
                        const SizedBox(width: 8),
                        _HistoryFilterChip(
                          label: l10n.orderStatusCancelled,
                          selected: _selectedFilter ==
                              kDeliveryHistoryFilterCancelled,
                          onTap: () => setState(() => _selectedFilter =
                              kDeliveryHistoryFilterCancelled),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(AppColors.spaceMD),
                    child: ShimmerListView(itemCount: 6),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spaceMD),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: HomeColors.textMuted,
                        ),
                        const SizedBox(height: AppColors.spaceMD),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HomeColors.textSecondary,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: _fetchDeliveries,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.actionRetry),
                          style: TextButton.styleFrom(
                            foregroundColor: HomeColors.violet,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spaceMD),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HomeColors.violet.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 56,
                            color: HomeColors.violet.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: AppColors.spaceLG),
                        Text(
                          l10n.courierNoHistory,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: HomeColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.courierHistoryEmptySubtitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: HomeColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.spaceMD,
                    0,
                    AppColors.spaceMD,
                    AppColors.spaceLG,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: _isLoadingMore
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: HomeColors.violet,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _loadMore,
                                      style: TextButton.styleFrom(
                                        foregroundColor: HomeColors.orange,
                                      ),
                                      child: Text(l10n.showMore),
                                    ),
                            ),
                          );
                        }

                        final d = filtered[index];
                        final id = d['id'] as int?;
                        return DeliveryHistoryCard(
                          orderId: id != null ? 'DEL-$id' : '—',
                          recipient: d['receiver_name']?.toString() ?? '—',
                          location: d['dropoff_location']?.toString() ?? '—',
                          dateTime:
                              formatDeliveryHistoryDate(d['created_at']),
                          status: resolveDeliveryStatusLabel(d),
                          borderColor: borderColor,
                          onTap: id != null ? () => _openDetails(id) : null,
                        );
                      },
                      childCount:
                          filtered.length + (canLoadMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : HomeColors.textMuted,
      ),
      backgroundColor: HomeColors.surface,
      selectedColor: HomeColors.violet,
      side: BorderSide(
        color: selected ? HomeColors.violet : HomeColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
    );
  }
}
