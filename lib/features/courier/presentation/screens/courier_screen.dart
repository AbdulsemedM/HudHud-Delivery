import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/active_delivery_card.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_history_filter.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:latlong2/latlong.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import 'delivery_details_screen.dart';
import 'delivery_tracking_screen.dart';
import 'instant_delivery_screen.dart';
import 'schedule_delivery_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  late final CourierRepository _courierRepository;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = true;
  String? _deliveriesError;
  Map<String, dynamic>? _activeDelivery;
  bool _isLoadingActiveDelivery = true;
  String _selectedFilter = kDeliveryHistoryFilterAll;
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
    _fetchDeliveries();
    _fetchActiveDelivery();
  }

  @override
  void dispose() {
    CourierHomeRefresh.instance.removeListener(_homeRefreshListener);
    super.dispose();
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
            _deliveriesError = null;
          } else {
            _deliveries = [];
            _deliveriesError = result['message'] as String?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deliveries = [];
          _isLoadingDeliveries = false;
          _deliveriesError = context.l10n.failedToLoadHistory;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchActiveDelivery(refresh: true),
      _fetchDeliveries(refresh: true),
    ]);
  }

  String _formatDeliveryDate(dynamic value) {
    if (value == null) return '—';
    final str = value.toString();
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        return '${dt.day} ${_monthName(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return str;
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  LatLng? _parseLatLng(dynamic lat, dynamic lng) {
    return parseDeliveryLatLng(lat, lng);
  }

  void _navigateToTracking(Map<String, dynamic> delivery) {
    final pickupPos = _parseLatLng(
      delivery['pickup_latitude'],
      delivery['pickup_longitude'],
    );
    final dropoffPos = _parseLatLng(
      delivery['dropoff_latitude'],
      delivery['dropoff_longitude'],
    );
    final deliveryId = delivery['id'] as int?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryTrackingScreen(
          deliveryId: deliveryId,
          pickupLocation: delivery['pickup_location']?.toString() ?? '',
          deliveryLocation: delivery['dropoff_location']?.toString() ?? '',
          pickupPosition: pickupPos,
          deliveryPosition: dropoffPos,
          selectedVehicle: delivery['vehicle_type']?.toString() ?? 'motorbike',
          itemType: delivery['package_type']?.toString() ?? '',
          quantity: delivery['package_weight']?.toString() ?? '1',
          whoPays: 'me',
          paymentType: delivery['payment_method']?.toString() ?? 'cash',
          recipientName: delivery['receiver_name']?.toString() ?? '',
          recipientPhone: delivery['receiver_phone']?.toString() ?? '',
        ),
      ),
    );
  }

  Widget _buildCreateDeliveryRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _InstantDeliveryCard(
            l10n: l10n,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InstantDeliveryScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ScheduleDeliveryCard(
            l10n: l10n,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScheduleDeliveryScreen(),
                ),
              );
            },
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
                const SizedBox(height: AppColors.spaceLG),
                Text(
                  l10n.courierWhatToDo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppColors.spaceMD),
                _buildCreateDeliveryRow(l10n),
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
              Text(
                l10n.history,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.orders,
                      selected: _selectedFilter == kDeliveryHistoryFilterAll,
                      onTap: () => setState(
                          () => _selectedFilter = kDeliveryHistoryFilterAll),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.courierActiveDelivery,
                      selected:
                          _selectedFilter == kDeliveryHistoryFilterActive,
                      onTap: () => setState(() =>
                          _selectedFilter = kDeliveryHistoryFilterActive),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.orderStatusDelivered,
                      selected:
                          _selectedFilter == kDeliveryHistoryFilterCompleted,
                      onTap: () => setState(() =>
                          _selectedFilter = kDeliveryHistoryFilterCompleted),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.orderStatusCancelled,
                      selected:
                          _selectedFilter == kDeliveryHistoryFilterCancelled,
                      onTap: () => setState(() =>
                          _selectedFilter = kDeliveryHistoryFilterCancelled),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              if (_isLoadingDeliveries)
                const ShimmerListView(itemCount: 3)
              else if (_deliveriesError != null)
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: HomeColors.textMuted,
                      ),
                      const SizedBox(height: AppColors.spaceMD),
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
              else if (_filteredDeliveries.isEmpty)
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HomeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.courierHistoryEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: HomeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredDeliveries.map((d) {
                  final id = d['id'] as int?;
                  final orderId = id != null ? 'DEL-$id' : '—';
                  final recipient = d['receiver_name']?.toString() ?? '—';
                  final location = d['dropoff_location']?.toString() ?? '—';
                  final dateTime = _formatDeliveryDate(d['created_at']);
                  final status = resolveDeliveryStatusLabel(d);
                  return _DeliveryHistoryCard(
                    orderId: orderId,
                    recipient: recipient,
                    location: location,
                    dateTime: dateTime,
                    status: status,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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
            color: HomeColors.violet,
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

class _DeliveryHistoryCard extends StatelessWidget {
  final String orderId;
  final String recipient;
  final String location;
  final String dateTime;
  final String status;
  final Color borderColor;
  final VoidCallback? onTap;

  const _DeliveryHistoryCard({
    required this.orderId,
    required this.recipient,
    required this.location,
    required this.dateTime,
    required this.status,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusChip.colorForStatus(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          child: Container(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: HomeColors.textPrimary,
                            ),
                      ),
                      Text(
                        recipient,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HomeColors.textMuted,
                            ),
                      ),
                      Text(
                        dateTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HomeColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
