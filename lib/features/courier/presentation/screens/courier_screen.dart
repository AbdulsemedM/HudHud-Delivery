import 'package:flutter/material.dart';
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
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoadingDeliveries = true;
  String? _deliveriesError;
  Map<String, dynamic>? _activeDelivery;
  bool _isLoadingActiveDelivery = true;

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
          _deliveriesError = 'Failed to load history';
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
          _currentLocation = 'Unable to get location';
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserProfileHeader(
                name: _currentUser?.name ?? 'User',
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
              ),
              const SizedBox(height: 24),
              // What would you like to do section
              Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              // Instant Delivery Card
              _InstantDeliveryCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InstantDeliveryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Schedule Delivery Card
              _ScheduleDeliveryCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleDeliveryScreen(),
                    ),
                  );
                },
              ),
              if (!_isLoadingActiveDelivery && _activeDelivery != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Active Delivery',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _ActiveDeliveryCard(
                  delivery: _activeDelivery!,
                  onTap: () => _navigateToTracking(_activeDelivery!),
                ),
              ],
              const SizedBox(height: 24),
              // History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle view all
                    },
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // History Items
              if (_isLoadingDeliveries)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_deliveriesError != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _deliveriesError!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_deliveries.isEmpty)
                Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : Colors.grey)
                              .withOpacity(isDark ? 0.35 : 0.08),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: scheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No delivery history',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your past deliveries will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._deliveries.map((d) {
                  final id = d['id'] as int?;
                  final orderId = id != null ? 'DEL-$id' : '—';
                  final recipient = d['receiver_name']?.toString() ?? '—';
                  final location = d['dropoff_location']?.toString() ?? '—';
                  final dateTime = _formatDeliveryDate(d['created_at']);
                  final status =
                      (d['current_status'] ?? d['status'])?.toString() ?? '—';
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
    );
  }
}

// Instant Delivery Card - matches design: light orange card, black title, faded bolt decoration
class _InstantDeliveryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _InstantDeliveryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? scheme.surfaceVariant : const Color(0xFFFFF4ED);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg, // Soft light orange / peach (light), surfaceVariant (dark)
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.35 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Faded decorative lightning bolt - upper right, desaturated
              Positioned(
                right: 8,
                top: 4,
                child: Opacity(
                  opacity: 0.35,
                  child: Icon(
                    Icons.bolt,
                    size: 104,
                    color: AppColors.primaryColor.withOpacity(0.7),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    color: scheme.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Instant Delivery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Courier takes only your package and delivers instantly.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
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

// Active Delivery Card
class _ActiveDeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onTap;

  const _ActiveDeliveryCard({
    required this.delivery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final id = delivery['id'];
    final orderId = id != null ? 'DEL-$id' : '—';
    final recipient = delivery['receiver_name']?.toString() ?? '—';
    final location = delivery['dropoff_location']?.toString() ?? '—';
    final status =
        (delivery['current_status'] ?? delivery['status'])?.toString() ??
            'In progress';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recipient: $recipient',
              style: TextStyle(fontSize: 14, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 13, color: scheme.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Track delivery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 18, color: scheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Schedule Delivery Card - matches design: white card, black title, faded stopwatch decoration
class _ScheduleDeliveryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ScheduleDeliveryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Faded decorative stopwatch - upper right, light gray
              Positioned(
                right: 8,
                top: 4,
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.timer_outlined,
                    size: 104,
                    color: scheme.onSurfaceVariant.withOpacity(0.55),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: scheme.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Schedule Delivery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Courier comes to pick up on your specified date and time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
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
