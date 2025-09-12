import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/list_of_restaurants_screen.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/location_service.dart';
import 'package:hudhud_delivery/app/services/greeting_utils.dart';
import 'package:hudhud_delivery/models/user_model.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import '../../bloc/home_bloc.dart';
import '../widgets/home_widget.dart';
import '../../data/repository/home_repository.dart';
import '../../data/data_provider/home_data_provider.dart';
import '../../model/category_model.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'map_location_screen.dart';
import 'location_search_screen.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../categories/bloc/categories_bloc.dart';
import '../../../categories/data/repository/categories_repository.dart';
import '../../../categories/data/data_provider/categories_data_provider.dart';

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

  Color _getCategoryColor(String colorString) {
    // Parse color from string or provide default colors
    switch (colorString.toLowerCase()) {
      case 'orange':
        return Colors.orange[50]!;
      case 'purple':
        return Colors.purple[50]!;
      case 'blue':
        return Colors.blue[50]!;
      case 'green':
        return Colors.green[50]!;
      case 'red':
        return Colors.red[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 24),
              const Text(
                'While You may like to have',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is GetCategoriesLoadingState) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: 6, // Show 6 shimmer placeholders
                      itemBuilder: (context, index) {
                        return const ServiceCategoryShimmer();
                      },
                    );
                  } else if (state is GetCategoriesSuccessState) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: state.categories.length,
                      itemBuilder: (context, index) {
                        final category = state.categories[index];
                        return ServiceCategory(
                          title: category.name ?? '',
                          subtitle: category.description ?? '',
                          imagePath: category.image_path ??
                              'assets/images/categories.png',
                          backgroundColor:
                              _getCategoryColor(category.color ?? ''),
                          onTap: () {
                            if (category.name!.toLowerCase().contains('food') ||
                                category.name!
                                    .toLowerCase()
                                    .contains('restaurant')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ListOfRestaurantsScreen(),
                                ),
                              );
                            } else {
                              // Navigate to categories screen for other categories
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                     create: (context) => CategoriesBloc(
                                       CategoriesRepository(
                                         categoriesDataProvider: CategoriesDataProvider(
                                           apiService: ApiService.instance,
                                         ),
                                       ),
                                     ),
                                    child: CategoriesScreen(
                                      categoryId: category.id ?? 0,
                                      categoryName: category.name ?? 'Category',
                                      categoryImage: category.image_path ?? 'assets/images/categories.png',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  } else if (state is GetCategoriesErrorState) {
                    return Center(
                      child: Column(
                        children: [
                          Text(
                            'Error loading categories: ${state.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<HomeBloc>()
                                  .add(GetCategoriesEvent());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              SeeAllServicesCard(
                onTap: () {
                  // Handle see all services
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
