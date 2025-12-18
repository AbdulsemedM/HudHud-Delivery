import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/list_of_restaurants_screen.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import '../../bloc/home_bloc.dart';
import '../widgets/home_widget.dart';
import '../../data/repository/home_repository.dart';
import '../../data/data_provider/home_data_provider.dart';
import 'location_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        homeRepository: HomeRepository(
          homeDataProvider: HomeDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      )..add(GetCategoriesEvent()),
      child: const HomeScreen(),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
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

      // Get street address instead of coordinates
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
                  final selectedAddress = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationSearchScreen(
                        currentLocation: _currentLocation,
                      ),
                    ),
                  );

                  if (selectedAddress != null) {
                    setState(() {
                      _currentLocation = selectedAddress;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Order Tracking Card
              OrderTrackingCard(
                riderName: _currentUser?.name ?? 'Tafari',
                message: 'Your courier rider Dickson is getting ready to collect your courier request this may take 5-8mins we will notify you once he collects the package.',
                onViewMap: () {
                  // Handle view map
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
              // Service Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  ServiceCard(
                    title: 'Delivery',
                    subtitle: 'Order groceries from your favourite vendors.',
                    icon: Icons.shopping_bag,
                    color: AppColors.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListOfRestaurantsScreen(),
                        ),
                      );
                    },
                  ),
                  ServiceCard(
                    title: 'Courier',
                    subtitle: 'Order courier services for pickup and drop off.',
                    icon: Icons.local_shipping,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to courier screen
                    },
                  ),
                  ServiceCard(
                    title: 'Taxi',
                    subtitle: 'Request taxi at affordable rates from anywhere.',
                    icon: Icons.local_taxi,
                    color: Colors.yellow[700]!,
                    onTap: () {
                      // Navigate to taxi screen
                    },
                  ),
                  ServiceCard(
                    title: 'Services',
                    subtitle: 'Request handy men for casual services at home.',
                    icon: Icons.handyman,
                    color: Colors.green,
                    onTap: () {
                      // Navigate to services screen
                    },
                  ),
                ],
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
