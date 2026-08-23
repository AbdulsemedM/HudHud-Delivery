import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/active_delivery_card.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/courier_history_empty_state.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/delivery_history_card.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_access_gate.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_live_job_screen.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import 'delivery_details_screen.dart';
import 'delivery_history_screen.dart';
import 'instant_delivery_screen.dart';
import 'schedule_delivery_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  static const _homeHistoryPreviewCount = 5;

  late final CourierRepository _courierRepository;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = true;
  String? _deliveriesError;
  Map<String, dynamic>? _activeDelivery;
  bool _isLoadingActiveDelivery = true;
  int _deliveriesLastPage = 1;
  late final void Function() _homeRefreshListener;

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _homeRefreshListener = () => _refreshData();
    CourierHomeRefresh.instance.addListener(_homeRefreshListener);
    if (GuestBrowseService().isGuestBrowseMode) {
      _isLoadingDeliveries = false;
      _isLoadingActiveDelivery = false;
    } else {
      _fetchDeliveries();
      _fetchActiveDelivery();
    }
  }

  @override
  void dispose() {
    CourierHomeRefresh.instance.removeListener(_homeRefreshListener);
    super.dispose();
  }

  List<Map<String, dynamic>> get _recentDeliveries {
    if (_deliveries.length <= _homeHistoryPreviewCount) {
      return _deliveries;
    }
    return _deliveries.take(_homeHistoryPreviewCount).toList();
  }

  bool get _hasMoreHistory =>
      _deliveries.length > _homeHistoryPreviewCount || _deliveriesLastPage > 1;

  Future<void> _fetchActiveDelivery({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() => _isLoadingActiveDelivery = true);
    }
    try {
      final result = await _courierRepository.getUserActiveDelivery();
      if (mounted) {
        setState(() {
          _isLoadingActiveDelivery = false;
          if (result['success'] == true && result['delivery'] != null) {
            _activeDelivery = result['delivery'] as Map<String, dynamic>?;
          } else {
            _activeDelivery = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActiveDelivery = false;
          _activeDelivery = null;
        });
      }
    }
  }

  Future<void> _fetchDeliveries({bool refresh = false}) async {
    if (!refresh && mounted) {
      setState(() => _isLoadingDeliveries = true);
    }
    try {
      final result = await _courierRepository.getUserDeliveries(page: 1);
      if (mounted) {
        setState(() {
          _isLoadingDeliveries = false;
          if (result['success'] == true) {
            _deliveries = result['deliveries'] as List<Map<String, dynamic>>;
            _deliveriesLastPage = result['lastPage'] as int? ?? 1;
            _deliveriesError = null;
          } else {
            _deliveries = [];
            _deliveriesLastPage = 1;
            _deliveriesError = result['message'] as String?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveries = [];
          _deliveriesLastPage = 1;
          _isLoadingDeliveries = false;
          _deliveriesError = context.l10n.failedToLoadHistory;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (GuestBrowseService().isGuestBrowseMode) {
      if (mounted) {
        setState(() {
          _deliveries = [];
          _activeDelivery = null;
          _deliveriesError = null;
          _isLoadingDeliveries = false;
          _isLoadingActiveDelivery = false;
        });
      }
      return;
    }
    // Show loading (including guest → signed-in refetch after login).
    await Future.wait([
      _fetchActiveDelivery(),
      _fetchDeliveries(),
    ]);
  }

  void _navigateToTracking(Map<String, dynamic> delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => courierLiveJobScreenFromDelivery(delivery),
      ),
    );
  }

  void _openFullHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryHistoryScreen(),
      ),
    );
  }

  Future<void> _openInstantDelivery() async {
    if (!await requireCourierSendAccess(context)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InstantDeliveryScreen(),
      ),
    );
  }

  Future<void> _openScheduleDelivery() async {
    if (!await requireCourierSendAccess(context)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduleDeliveryScreen(),
      ),
    );
  }

  Widget _buildCreateDeliveryRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _InstantDeliveryCard(
            l10n: l10n,
            onTap: _openInstantDelivery,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ScheduleDeliveryCard(
            l10n: l10n,
            onTap: _openScheduleDelivery,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const borderColor = HomeColors.border;
    final hasActive =
        !_isLoadingActiveDelivery && _activeDelivery != null;

    return Scaffold(
      backgroundColor: HomeColors.background,
      floatingActionButton: hasActive
          ? FloatingActionButton.extended(
              heroTag: 'courier_instant_delivery_fab',
              backgroundColor: AuthScreenColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.courierAddDelivery),
              onPressed: _openInstantDelivery,
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: HomeColors.violet,
          backgroundColor: HomeColors.surface,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppColors.spaceMD),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasActive) ...[
                Text(
                  l10n.courierActiveDelivery,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppColors.spaceMD),
                ActiveDeliveryCard(
                  delivery: _activeDelivery!,
                  onTrack: () => _navigateToTracking(_activeDelivery!),
                ),
              ] else ...[
                Text(
                  l10n.courierWhatToDo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppColors.spaceMD),
                _buildCreateDeliveryRow(l10n),
              ],
              const SizedBox(height: AppColors.spaceLG),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.history,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_hasMoreHistory)
                    TextButton(
                      onPressed: _openFullHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: AuthScreenColors.orange,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.showMore),
                    ),
                ],
              ),
              const SizedBox(height: AppColors.spaceMD),
              if (_isLoadingDeliveries)
                const ShimmerListView(itemCount: 3)
              else if (_deliveriesError != null)
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        _deliveriesError!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: HomeColors.textSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _isLoadingDeliveries = true);
                          _fetchDeliveries();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.actionRetry),
                        style: TextButton.styleFrom(
                          foregroundColor: HomeColors.violet,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_recentDeliveries.isEmpty)
                CourierHistoryEmptyState(
                  compact: true,
                  onPrimaryAction: hasActive ? null : _openInstantDelivery,
                  primaryActionLabel: l10n.courierInstantTitle,
                )
              else
                ..._recentDeliveries.map((d) {
                  final id = d['id'] as int?;
                  return DeliveryHistoryCard(
                    orderId: id != null ? 'DEL-$id' : '—',
                    recipient: d['receiver_name']?.toString() ?? '—',
                    location: d['dropoff_location']?.toString() ?? '—',
                    dateTime: formatDeliveryHistoryDate(d['created_at']),
                    status: resolveDeliveryStatusLabel(d),
                    borderColor: borderColor,
                    onTap: id != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DeliveryDetailsScreen(deliveryId: id),
                              ),
                            );
                          }
                        : null,
                  );
                }),
              const SizedBox(height: 80),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _InstantDeliveryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _InstantDeliveryCard({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            color: AuthScreenColors.orange,
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white70,
                  size: 32,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.courierInstantTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.courierInstantSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleDeliveryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _ScheduleDeliveryCard({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: HomeColors.border),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.schedule_rounded,
                  color: HomeColors.violet.withValues(alpha: 0.55),
                  size: 32,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.courierScheduleTitle,
                    style: const TextStyle(
                      color: HomeColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.courierScheduleSubtitle,
                    style: const TextStyle(
                      color: HomeColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
