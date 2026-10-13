import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/screens/delivery_details_screen.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/courier_history_empty_state.dart';
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
      final result = await _courierRepository.getUserDeliveries(page: nextPage);
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
    final borderColor = HomeColors.borderOf(context);
    final filtered = _filteredDeliveries;
    final canLoadMore = _currentPage < _lastPage &&
        _selectedFilter == kDeliveryHistoryFilterAll;

    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: HomeColors.backgroundOf(context),
          foregroundColor: HomeColors.textPrimaryOf(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: HomeColors.textPrimaryOf(context),
            size: 26,
          ),
          title: Text(
            l10n.history,
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: HomeColors.orange,
          backgroundColor: HomeColors.surfaceOf(context),
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
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _HistoryFilterChip(
                          label: l10n.orders,
                          icon: Icons.apps_rounded,
                          selected:
                              _selectedFilter == kDeliveryHistoryFilterAll,
                          onTap: () => setState(() =>
                              _selectedFilter = kDeliveryHistoryFilterAll),
                        ),
                        const SizedBox(width: 10),
                        _HistoryFilterChip(
                          label: l10n.courierActiveDelivery,
                          icon: Icons.local_shipping_rounded,
                          selected:
                              _selectedFilter == kDeliveryHistoryFilterActive,
                          onTap: () => setState(() =>
                              _selectedFilter = kDeliveryHistoryFilterActive),
                        ),
                        const SizedBox(width: 10),
                        _HistoryFilterChip(
                          label: l10n.orderStatusDelivered,
                          icon: Icons.check_circle_rounded,
                          selected: _selectedFilter ==
                              kDeliveryHistoryFilterCompleted,
                          onTap: () => setState(() => _selectedFilter =
                              kDeliveryHistoryFilterCompleted),
                        ),
                        const SizedBox(width: 10),
                        _HistoryFilterChip(
                          label: l10n.orderStatusCancelled,
                          icon: Icons.cancel_rounded,
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
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HomeColors.violetTintOf(context),
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 46,
                            color: HomeColors.violetOf(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.35,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _fetchDeliveries,
                          icon: const Icon(Icons.refresh_rounded, size: 24),
                          label: Text(l10n.actionRetry),
                          style: TextButton.styleFrom(
                            foregroundColor: HomeColors.violetOf(context),
                            minimumSize: const Size(48, 48),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(AppColors.spaceMD),
                    child: Center(
                      child: CourierHistoryEmptyState(
                        compact: false,
                      ),
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
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: HomeColors.orange,
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: _loadMore,
                                      icon: const Icon(
                                        Icons.expand_more_rounded,
                                        size: 24,
                                      ),
                                      label: Text(l10n.showMore),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            HomeColors.violetOf(context),
                                        minimumSize: const Size(48, 48),
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
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
                          dateTime: formatDeliveryHistoryDate(d['created_at']),
                          status: resolveDeliveryStatusLabel(d),
                          borderColor: borderColor,
                          onTap: id != null ? () => _openDetails(id) : null,
                        );
                      },
                      childCount: filtered.length + (canLoadMore ? 1 : 0),
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
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = HomeColors.violetOf(context);
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(AppColors.radiusFull);
    final fg = selected ? Colors.white : HomeColors.textPrimaryOf(context);

    return Semantics(
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected ? const [] : AppColors.softShadow(context),
        ),
        child: Material(
          color: selected ? accent : HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: selected || !dark
                ? BorderSide.none
                : BorderSide(color: HomeColors.borderOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
