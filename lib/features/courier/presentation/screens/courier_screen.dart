import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/notifications_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/icon_box.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import '../../../home/presentation/screen/location_search_screen.dart';
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
  String _currentLocation = '';
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = true;
  String? _deliveriesError;
  Map<String, dynamic>? _activeDelivery;
  bool _isLoadingActiveDelivery = true;
  String _historyFilter = 'all';

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _requestLocationAndUpdate();
    if (!GuestBrowseService().isGuestBrowseMode) {
      _fetchDeliveries();
      _fetchActiveDelivery();
    } else {
      _isLoadingDeliveries = false;
      _isLoadingActiveDelivery = false;
    }
  }

  Future<void> _fetchActiveDelivery() async {
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

  Future<void> _fetchDeliveries() async {
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

  Future<void> _onRefresh() async {
    await _requestLocationAndUpdate();
    if (GuestBrowseService().isGuestBrowseMode) return;
    setState(() {
      _isLoadingDeliveries = true;
      _isLoadingActiveDelivery = true;
      _deliveriesError = null;
    });
    await Future.wait([
      _fetchDeliveries(),
      _fetchActiveDelivery(),
    ]);
  }

  String _formatDeliveryDate(BuildContext context, dynamic value) {
    if (value == null) return '—';
    final str = value.toString();
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final locale = Localizations.localeOf(context).toString();
        return DateFormat.yMMMd(locale).add_jm().format(dt);
      }
    } catch (_) {}
    return str;
  }

  bool _isActiveStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver') ||
        s.contains('complet') ||
        s.contains('cancel')) {
      return false;
    }
    return s.isNotEmpty;
  }

  List<Map<String, dynamic>> _filteredDeliveries() {
    if (_historyFilter == 'all') return _deliveries;
    return _deliveries.where((d) {
      final status =
          (d['current_status'] ?? d['status'])?.toString().toLowerCase() ?? '';
      switch (_historyFilter) {
        case 'active':
          return _isActiveStatus(status);
        case 'completed':
          return status.contains('deliver') || status.contains('complet');
        case 'cancelled':
          return status.contains('cancel');
        default:
          return true;
      }
    }).toList();
  }

  LatLng? _parseLatLng(dynamic lat, dynamic lng) {
    final latVal =
        lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
    final lngVal =
        lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '');
    if (latVal != null && lngVal != null) return LatLng(latVal, lngVal);
    return null;
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

  Future<void> _requestLocationAndUpdate() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });
      final location = await LocationService.getCurrentLocationAddress();
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = context.l10n.locationUnable;
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredDeliveries = _filteredDeliveries();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppColors.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserProfileHeader(
                  location: _currentLocation,
                  isLoadingLocation: _isLoadingLocation,
                  onLocationTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSearchScreen(
                          currentLocation: _currentLocation,
                        ),
                      ),
                    );
                    if (result != null && result['address'] != null) {
                      setState(() {
                        _currentLocation = result['address'] as String;
                      });
                    }
                  },
                  onNotificationsTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => BlocProvider(
                          create: (_) => createNotificationsBloc(),
                          child: const NotificationsScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppColors.sp24),
                SectionHeader(title: l10n.courierWhatToDo),
                const SizedBox(height: AppColors.sp12),
                Row(
                  children: [
                    Expanded(
                      child: _InstantDeliveryCard(
                        l10n: l10n,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const InstantDeliveryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppColors.sp12),
                    Expanded(
                      child: _ScheduleDeliveryCard(
                        l10n: l10n,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ScheduleDeliveryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (!_isLoadingActiveDelivery && _activeDelivery != null) ...[
                  const SizedBox(height: AppColors.sp24),
                  SectionHeader(title: l10n.courierActiveDelivery),
                  const SizedBox(height: AppColors.sp8),
                  _ActiveDeliveryCard(
                    l10n: l10n,
                    delivery: _activeDelivery!,
                    onTap: () => _navigateToTracking(_activeDelivery!),
                  ),
                ],
                const SizedBox(height: AppColors.sp24),
                SectionHeader(
                  title: l10n.history,
                  onSeeAll: () {},
                  seeAllLabel: l10n.actionViewAll,
                ),
                const SizedBox(height: AppColors.sp8),
                _HistoryFilterChips(
                  selectedFilter: _historyFilter,
                  onFilterChanged: (filter) {
                    setState(() => _historyFilter = filter);
                  },
                ),
                const SizedBox(height: AppColors.sp12),
                if (_isLoadingDeliveries)
                  const _DeliveryHistoryShimmer()
                else if (_deliveriesError != null)
                  _CourierLottieState(
                    title: l10n.failedToLoadHistory,
                    subtitle: _deliveriesError!,
                    actionLabel: l10n.actionRetry,
                    onAction: () {
                      setState(() {
                        _isLoadingDeliveries = true;
                        _deliveriesError = null;
                      });
                      _fetchDeliveries();
                    },
                  )
                else if (filteredDeliveries.isEmpty)
                  _CourierLottieState(
                    title: l10n.courierNoHistory,
                    subtitle: l10n.courierHistoryEmptySubtitle,
                  )
                else
                  ...filteredDeliveries.map((d) {
                    final id = d['id'] as int?;
                    final orderId = id != null ? 'DEL-$id' : '—';
                    final recipient = d['receiver_name']?.toString() ?? '—';
                    final location = d['dropoff_location']?.toString() ?? '—';
                    final dateTime =
                        _formatDeliveryDate(context, d['created_at']);
                    final status = (d['current_status'] ?? d['status'])
                            ?.toString() ??
                        '—';
                    return HistoryItem(
                      orderId: orderId,
                      recipient: recipient,
                      location: location,
                      dateTime: dateTime,
                      status: status,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryFilterChips extends StatelessWidget {
  const _HistoryFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final filters = <String, String>{
      'all': l10n.sosStatusAll,
      'active': l10n.sosStatusActive,
      'completed': l10n.tipsStatusCompleted,
      'cancelled': l10n.orderStatusCancelled,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = selectedFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppColors.sp8),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => onFilterChanged(entry.key),
              selectedColor: AppColors.primaryColor.withOpacity(0.15),
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : borderColor,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryColor
                    : theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CourierLottieState extends StatelessWidget {
  const _CourierLottieState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppColors.sp8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.sp24,
        vertical: AppColors.sp32,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.r12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/browse.json',
            width: 160,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppColors.sp16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppColors.sp8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppColors.sp20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryHistoryShimmer extends StatelessWidget {
  const _DeliveryHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final highlightColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppColors.sp4),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.r12),
              ),
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r16),
        child: Ink(
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryDarkColor,
              ],
            ),
            borderRadius: BorderRadius.circular(AppColors.r16),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 4,
                top: 4,
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.bolt,
                    size: 72,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppColors.sp12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
                    ),
                    const SizedBox(height: AppColors.sp8),
                    Text(
                      l10n.courierInstantTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppColors.sp4),
                    Text(
                      l10n.courierInstantSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.85),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _ActiveDeliveryCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Map<String, dynamic> delivery;
  final VoidCallback onTap;

  const _ActiveDeliveryCard({
    required this.l10n,
    required this.delivery,
    required this.onTap,
  });

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return AppColors.pending;
    if (s.contains('confirm')) return AppColors.confirmed;
    if (s.contains('prepar')) return AppColors.preparing;
    if (s.contains('way') || s.contains('transit')) return AppColors.onTheWay;
    if (s.contains('deliver')) return AppColors.delivered;
    if (s.contains('cancel')) return AppColors.cancelled;
    return AppColors.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final id = delivery['id'];
    final orderId = id != null ? 'DEL-$id' : '—';
    final recipient = delivery['receiver_name']?.toString() ?? '—';
    final location = delivery['dropoff_location']?.toString() ?? '—';
    final status =
        (delivery['current_status'] ?? delivery['status'])?.toString() ??
            l10n.courierDeliveryStatusInProgress;
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppColors.r12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      color: AppColors.primaryColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppColors.sp12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconBox(
                                  icon: Icons.local_shipping_outlined,
                                  color: statusColor,
                                ),
                                const SizedBox(width: AppColors.sp12),
                                Expanded(
                                  child: Text(
                                    orderId,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                StatusChip(status: status),
                              ],
                            ),
                            const SizedBox(height: AppColors.sp8),
                            Text(
                              l10n.courierRecipientLine(recipient),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppColors.sp4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppColors.sp4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppColors.sp8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  l10n.courierTrackDeliveryCta,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppColors.sp4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.primaryColor.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r16),
        child: Ink(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppColors.r16),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 4,
                top: 4,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(
                    Icons.timer_outlined,
                    size: 72,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppColors.sp12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(height: AppColors.sp8),
                    Text(
                      l10n.courierScheduleTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppColors.sp4),
                    Text(
                      l10n.courierScheduleSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
