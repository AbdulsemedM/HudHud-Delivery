import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'category_stores_screen.dart';

class DeliveryFeedScreen extends StatefulWidget {
  const DeliveryFeedScreen({super.key});

  @override
  State<DeliveryFeedScreen> createState() => _DeliveryFeedScreenState();
}

class _DeliveryFeedScreenState extends State<DeliveryFeedScreen> {
  String _selectedLocation = 'London Hall';
  String _selectedTime = 'Now';
  bool _showAllCategories = false;

  final List<Map<String, dynamic>> _allCategories = const [
    {'title': 'Convenience', 'icon': Icons.shopping_bag},
    {'title': 'Alcohol', 'icon': Icons.local_drink},
    {'title': 'Pet Supplies', 'icon': Icons.pets},
    {'title': 'Flowers', 'icon': Icons.local_florist},
    {'title': 'Grocery', 'icon': Icons.shopping_basket},
    {'title': 'American', 'icon': Icons.fastfood},
    {'title': 'Speciality', 'icon': Icons.restaurant_menu},
    {'title': 'Takeout', 'icon': Icons.inventory_2},
    {'title': 'Asian', 'icon': Icons.ramen_dining},
    {'title': 'Ice Cream', 'icon': Icons.icecream},
    {'title': 'Halal', 'icon': Icons.set_meal},
    {'title': 'Retails', 'icon': Icons.store},
    {'title': 'Carribean', 'icon': Icons.dinner_dining},
    {'title': 'Indian', 'icon': Icons.rice_bowl},
    {'title': 'French', 'icon': Icons.restaurant},
    {'title': 'Fast Foods', 'icon': Icons.lunch_dining},
    {'title': 'Burger', 'icon': Icons.fastfood},
    {'title': 'Ride', 'icon': Icons.directions_car},
    {'title': 'Chinese', 'icon': Icons.ramen_dining},
    {'title': 'Dessert', 'icon': Icons.cake},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                                    setState(() {
                                      _showAllCategories = !_showAllCategories;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // All Categories Section (when expanded)
                    if (_showAllCategories) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All categories',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _allCategories.length,
                              itemBuilder: (context, index) {
                                final category = _allCategories[index];
                                return _CategoryGridItem(
                                  title: category['title'] as String,
                                  icon: category['icon'] as IconData,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryStoresScreen(
                                          categoryName:
                                              category['title'] as String,
                                          categoryIcon:
                                              category['icon'] as IconData,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                    // Popular Orders Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Popular Orders',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Restaurant Listings
                          _RestaurantCard(
                            name: 'Adenine Kitchen',
                            rating: 4.4,
                            deliveryFee: 120,
                            deliveryTime: '10-25 min',
                            promoText: '5 orders until ETB 800 reward',
                            imageUrl:
                                'assets/images/categories.jpg', // Placeholder
                            onTap: () {
                              // TODO: Navigate to restaurant details
                            },
                          ),
                          const SizedBox(height: 16),
                          _RestaurantCard(
                            name: 'Cardinal Chips',
                            rating: 4.3,
                            deliveryFee: 120,
                            deliveryTime: '10-25 min',
                            imageUrl:
                                'assets/images/categories.jpg', // Placeholder
                            onTap: () {
                              // TODO: Navigate to restaurant details
                            },
                          ),
                          const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Delivery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Color(0xFF2C3E50),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLarge ? 120 : 100,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
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
                      color: const Color(0xFF2C3E50),
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

class _CategoryGridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryGridItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  child: Image.asset(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.grey,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        iconSize: 20,
                        color: Colors.grey,
                        onPressed: () {
                          // TODO: Toggle favorite
                        },
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ETB $deliveryFee Delivery Fee • $deliveryTime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
