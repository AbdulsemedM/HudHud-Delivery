import 'package:flutter/material.dart';
import 'store_detail_screen.dart';

class CategoryStoresScreen extends StatelessWidget {
  final String categoryName;
  final IconData categoryIcon;

  const CategoryStoresScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _CategoryHeader(
              categoryName: categoryName,
              location: 'London Hall',
              time: 'Now',
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
                    // Featured Stores
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _FeaturedStoreCard(
                                  name: 'Gopuff',
                                  logoText: 'gopuff',
                                  logoColor: Colors.blue,
                                  openingTime: 'Opens at 10:00 AM',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StoreDetailScreen(
                                          storeName: 'Gopuff',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _FeaturedStoreCard(
                                  name: '7Eleven',
                                  logoText: '7ELEVEN',
                                  logoColor: Colors.red,
                                  openingTime: 'Opens at 10:00 AM',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StoreDetailScreen(
                                          storeName: '7 Eleven Store',
                                        ),
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
                    // Popular Stores Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Popular Stores',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Store List
                          _StoreListItem(
                            name: 'Begs & Megs',
                            openingTime: 'Opens at 08:00',
                            promoText: 'Spend US\$20, save US\$5',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreDetailScreen(
                                    storeName: 'Begs & Megs',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StoreListItem(
                            name: 'Pick \'n\' Save',
                            openingTime: 'Opens at 08:00',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreDetailScreen(
                                    storeName: 'Pick \'n\' Save',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StoreListItem(
                            name: 'Orange Inn',
                            openingTime: 'Opens at 08:00',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreDetailScreen(
                                    storeName: 'Orange Inn',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StoreListItem(
                            name: 'Vintage Berkeley',
                            openingTime: 'Opens at 08:00',
                            promoText: 'Spend US\$20, save US\$5',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoreDetailScreen(
                                    storeName: 'Vintage Berkeley',
                                  ),
                                ),
                              );
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

class _CategoryHeader extends StatelessWidget {
  final String categoryName;
  final String location;
  final String time;
  final VoidCallback onLocationTap;
  final VoidCallback onTimeTap;
  final VoidCallback onFilterTap;

  const _CategoryHeader({
    required this.categoryName,
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: onFilterTap,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedStoreCard extends StatelessWidget {
  final String name;
  final String logoText;
  final Color logoColor;
  final String openingTime;
  final VoidCallback onTap;

  const _FeaturedStoreCard({
    required this.name,
    required this.logoText,
    required this.logoColor,
    required this.openingTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              logoText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: logoColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              openingTime,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Store Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.store,
                        size: 35,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Store Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    openingTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
            // Favorite Icon
            IconButton(
              icon: const Icon(Icons.favorite_border),
              iconSize: 24,
              color: Colors.grey,
              onPressed: () {
                // TODO: Toggle favorite
              },
            ),
          ],
        ),
      ),
    );
  }
}

