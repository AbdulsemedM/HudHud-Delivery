import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:latlong2/latlong.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import '../../../home/presentation/screen/location_search_screen.dart';
import '../../../settings/presentation/screen/notifications_screen.dart';
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
  final AuthService _authService = AuthService();
  late final CourierRepository _courierRepository;
  UserModel? _currentUser;
  String _currentLocation = '';
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = true;
  String? _deliveriesError;
  Map<String, dynamic>? _activeDelivery;
  bool _isLoadingActiveDelivery = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _courierRepository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _loadUserData();
    _requestLocationAndUpdate();
    _fetchDeliveries();
    _fetchActiveDelivery();
  }

  List<Map<String, dynamic>> get _filteredDeliveries {
    if (_selectedFilter == 'all') return _deliveries;
    return _deliveries.where((d) {
      final status =
          (d['current_status'] ?? d['status'])?.toString().toLowerCase() ?? '';
      switch (_selectedFilter) {
        case 'active':
          return !status.contains('deliver') &&
              !status.contains('cancel') &&
              status.isNotEmpty;
        case 'completed':
          return status.contains('deliver') || status.contains('complete');
        case 'cancelled':
          return status.contains('cancel');
        default:
          return true;
      }
    }).toList();
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

  Future<void> _loadUserData() async {
    final user = await _authService.getStoredUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserProfileHeader(
                name: _currentUser?.name ?? l10n.userDefault,
                location: _currentLocation,
                isLoadingLocation: _isLoadingLocation,
                user: _currentUser,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppColors.spaceLG),
              Text(
                l10n.courierWhatToDo,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
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
                  const SizedBox(width: 12),
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
                const SizedBox(height: AppColors.spaceLG),
                _ActiveDeliveryBanner(
                  l10n: l10n,
                  delivery: _activeDelivery!,
                  onTap: () => _navigateToTracking(_activeDelivery!),
                ),
              ],
              const SizedBox(height: AppColors.spaceLG),
              SectionHeader(
                title: l10n.history,
                actionLabel: l10n.actionViewAll,
                onAction: () {},
              ),
              const SizedBox(height: AppColors.spaceMD),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.orders,
                      selected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.courierActiveDelivery,
                      selected: _selectedFilter == 'active',
                      onTap: () => setState(() => _selectedFilter = 'active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.orderStatusDelivered,
                      selected: _selectedFilter == 'completed',
                      onTap: () =>
                          setState(() => _selectedFilter = 'completed'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.orderStatusCancelled,
                      selected: _selectedFilter == 'cancelled',
                      onTap: () =>
                          setState(() => _selectedFilter = 'cancelled'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spaceMD),
              if (_isLoadingDeliveries)
                const ShimmerListView(itemCount: 3)
              else if (_deliveriesError != null)
                Column(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppColors.spaceMD),
                    Text(
                      _deliveriesError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _isLoadingDeliveries = true);
                        _fetchDeliveries();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.actionRetry),
                    ),
                  ],
                )
              else if (_filteredDeliveries.isEmpty)
                Column(
                  children: [
                    Lottie.asset('assets/animations/browse.json', width: 200),
                    const SizedBox(height: AppColors.spaceMD),
                    Text(
                      l10n.courierNoHistory,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.courierHistoryEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                ..._filteredDeliveries.map((d) {
                  final id = d['id'] as int?;
                  final orderId = id != null ? 'DEL-$id' : '—';
                  final recipient = d['receiver_name']?.toString() ?? '—';
                  final location = d['dropoff_location']?.toString() ?? '—';
                  final dateTime = _formatDeliveryDate(d['created_at']);
                  final status =
                      (d['current_status'] ?? d['status'])?.toString() ?? '—';
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
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : scheme.onSurfaceVariant,
      ),
      backgroundColor: scheme.surface,
      selectedColor: AppColors.primaryColor,
      side: BorderSide(
        color: selected ? AppColors.primaryColor : scheme.outline.withValues(alpha: 0.4),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  size: 32,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    l10n.courierScheduleTitle,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.courierScheduleSubtitle,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
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

class _ActiveDeliveryBanner extends StatelessWidget {
  final AppLocalizations l10n;
  final Map<String, dynamic> delivery;
  final VoidCallback onTap;

  const _ActiveDeliveryBanner({
    required this.l10n,
    required this.delivery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = delivery['id'];
    final orderId = id != null ? 'DEL-$id' : '—';
    final status =
        (delivery['current_status'] ?? delivery['status'])?.toString() ??
            l10n.courierDeliveryStatusInProgress;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppColors.radiusLG),
                ),
                gradient: LinearGradient(
                  colors: [
                    scheme.surfaceContainerHighest,
                    scheme.surfaceContainerHigh,
                  ],
                ),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryColor,
                size: 48,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          orderId,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == 1 ? 10 : 8,
                        height: index == 1 ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= 1
                              ? AppColors.primaryColor
                              : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    final statusColor = StatusChip.colorForStatus(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
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
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        recipient,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        dateTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
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
