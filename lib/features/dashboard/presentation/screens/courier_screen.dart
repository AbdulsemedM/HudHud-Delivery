import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_widget.dart';
import '../../../home/presentation/screen/location_search_screen.dart';
import '../../../courier/presentation/screens/instant_delivery_screen.dart';
import '../../../courier/presentation/screens/schedule_delivery_screen.dart';

class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _requestLocationAndUpdate();
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50), // Dark grey
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
              const SizedBox(height: 24),
              // Deals Section
              DealsSection(
                onClaim: () {
                  // Handle claim deal
                },
              ),
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
              HistoryItem(
                orderId: 'ORDB1234',
                recipient: 'Paul Pogba',
                location: 'Maryland bustop, Anthony Ikeja',
                dateTime: '12 January 2020, 2:43pm',
                status: 'Completed',
              ),
              HistoryItem(
                orderId: 'ORDB1234',
                recipient: 'Paul Pogba',
                location: 'Maryland bustop, Anthony Ikeja',
                dateTime: '12 January 2020, 2:43pm',
                status: 'Completed',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Instant Delivery Card
class _InstantDeliveryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _InstantDeliveryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1), // Orange-tinted
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // Background lightning bolt
            Positioned(
              right: 10,
              top: 10,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.bolt,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bolt,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant Delivery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Courier takes only your package and delivers instantly.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// Schedule Delivery Card
class _ScheduleDeliveryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ScheduleDeliveryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // Background clock
            Positioned(
              right: 10,
              top: 10,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.access_time,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.access_time,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Delivery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Courier comes to pick up on your specified date and time.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

