import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/delivery/data/mock_popular_orders.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';
import 'category_stores_screen.dart';

class DeliveryFeedScreen extends StatefulWidget {
  const DeliveryFeedScreen({super.key});

  @override
  State<DeliveryFeedScreen> createState() => _DeliveryFeedScreenState();
}

class _DeliveryFeedScreenState extends State<DeliveryFeedScreen> {
  String _selectedLocation = 'London Hall';
  String _selectedTime = 'Now';

  List<VendorModel> _vendors = [];
  bool _vendorsLoading = true;
  String? _vendorsError;
  late final VendorsRepository _vendorsRepository;

  @override
  void initState() {
    super.initState();
    _vendorsRepository = VendorsRepository(
      vendorsDataProvider: VendorsDataProvider(apiService: ApiService.instance),
    );
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _vendorsLoading = true;
      _vendorsError = null;
    });
    try {
      final list = await _vendorsRepository.getVendors(page: 1);
      setState(() {
        _vendors = list;
        _vendorsLoading = false;
      });
    } catch (e) {
      setState(() {
        _vendorsError = e.toString();
        _vendorsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _DeliveryHeader(
              location: _selectedLocation,
              time: _selectedTime,
              onLocationTap: () {
                // TODO: Show location picker
              },
              onTimeTap: () {
                // TODO: Show time picker
              },
              onFilterTap: () {
                // TODO: Show filter options
              },
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Categories
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large Category Cards
                          Row(
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  title: 'Grocery',
                                  icon: Icons.shopping_basket,
                                  isLarge: true,
                                  hasPromo: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryStoresScreen(
                                          categoryName: 'Grocery',
                                          categoryIcon: Icons.shopping_basket,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  title: 'American',
                                  icon: Icons.fastfood,
                                  isLarge: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryStoresScreen(
                                          categoryName: 'American',
                                          categoryIcon: Icons.fastfood,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Small Category Cards
                          Row(
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  title: 'Convenience',
                                  icon: Icons.shopping_bag,
                                  isLarge: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryStoresScreen(
                                          categoryName: 'Convenience stores',
                                          categoryIcon: Icons.shopping_bag,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  title: 'Alcohol',
                                  icon: Icons.local_drink,
                                  isLarge: false,
                                  onTap: () {
                                    // TODO: Navigate to alcohol category
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  title: 'Pet Supplies',
                                  icon: Icons.pets,
                                  isLarge: false,
                                  onTap: () {
                                    // TODO: Navigate to pet supplies category
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  title: 'More',
                                  icon: Icons.more_horiz,
                                  isLarge: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllCategoriesScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Popular Orders Section (mock data). order.vendorId is vendor shop id.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popular Orders',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...mockPopularOrders.map((order) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _RestaurantCard(
                                  name: order.name,
                                  rating: order.rating,
                                  deliveryFee: order.deliveryFee,
                                  deliveryTime: order.deliveryTime,
                                  promoText: order.promoText,
                                  imageUrl: order.imageUrl,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StoreDetailScreen(
                                          storeName: order.name,
                                          storeImage: order.imageUrl,
                                          vendorId: order.vendorId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    // Popular Stores Section
                    if (!_vendorsLoading && _vendorsError == null && _vendors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Popular Stores',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._vendors.take(8).map((v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _StoreListItem(
                                    name: v.name,
                                    openingTime: 'Opens at 08:00',
                                    promoText: null,
                                    imageUrl: v.avatar.isNotEmpty
                                        ? v.avatar
                                        : 'assets/images/categories.jpg',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StoreDetailScreen(
                                            storeName: v.name,
                                            storeImage: v.avatar.isNotEmpty
                                                ? v.avatar
                                                : null,
                                            vendorId: v.id,
                                            vendor: v,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHeader extends StatelessWidget {
  final String location;
  final String time;
  final VoidCallback onLocationTap;
  final VoidCallback onTimeTap;
  final VoidCallback onFilterTap;

  const _DeliveryHeader({
    required this.location,
    required this.time,
    required this.onLocationTap,
    required this.onTimeTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTimeTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$time • $location',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: onFilterTap,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLarge;
  final bool hasPromo;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    this.isLarge = false,
    this.hasPromo = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLarge ? 120 : 100,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            if (hasPromo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Promo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isLarge ? 40 : 32,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
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

class _RestaurantCard extends StatelessWidget {
  final String name;
  final double rating;
  final int deliveryFee;
  final String deliveryTime;
  final String? promoText;
  final String imageUrl;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.name,
    required this.rating,
    required this.deliveryFee,
    required this.deliveryTime,
    this.promoText,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.restaurant,
                                size: 50,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.restaurant,
                                size: 50,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                ),
                if (promoText != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promoText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ETB $deliveryFee Delivery Fee • $deliveryTime',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

class _StoreListItem extends StatelessWidget {
  final String name;
  final String openingTime;
  final String? promoText;
  final String imageUrl;
  final VoidCallback onTap;

  const _StoreListItem({
    required this.name,
    required this.openingTime,
    this.promoText,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.store,
                              size: 35,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.store,
                              size: 35,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    openingTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (promoText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      promoText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
