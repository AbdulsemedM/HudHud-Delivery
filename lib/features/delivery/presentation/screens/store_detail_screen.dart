import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeName;
  final String? storeImage;

  const StoreDetailScreen({
    super.key,
    required this.storeName,
    this.storeImage,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  String _selectedTab = 'Featured';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.storeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stores and produ...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Category Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CategoryTab(
                    label: 'Featured',
                    isSelected: _selectedTab == 'Featured',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Featured';
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    label: 'Categories',
                    isSelected: _selectedTab == 'Categories',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Categories';
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    label: 'Orders',
                    isSelected: _selectedTab == 'Orders',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Orders';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promotional Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Background image placeholder
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/categories.jpg',
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                  );
                                },
                              ),
                            ),
                            // Overlay text
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'ETB 0 Delivery Fee with selected yogurt products',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Fruits & Vegetables Section
                    _ProductSection(
                      title: 'Fruits & Vegetables',
                      products: [
                        _Product(
                          name: 'Organic Banana',
                          price: 20,
                          quantity: '1 banana',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                        _Product(
                          name: 'Medium Hass Avocado',
                          price: 40,
                          quantity: '1 avocado',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                        _Product(
                          name: 'Large Hot House Tomato',
                          price: 104,
                          quantity: '1 tomato',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Beverages Section
                    _ProductSection(
                      title: 'Beverages',
                      products: [
                        _Product(
                          name: 'Coca-Cola Zero Sugar Cola Soda',
                          price: 80,
                          quantity: '12 x 12 fl oz',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                        _Product(
                          name: 'Simply Pulp Free Orange Juice',
                          price: 549,
                          quantity: '52 fl oz',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                        _Product(
                          name: 'Signature Refresh Purified Water',
                          price: 439,
                          quantity: '24 x 16 fl oz',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Frozen Foods Section
                    _ProductSection(
                      title: 'Frozen Foods',
                      products: [
                        _Product(
                          name: 'T.G.I. Friday\'s Boneless Chicken Bites',
                          price: 1044,
                          quantity: '15 oz',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                        _Product(
                          name: 'Apple and Maple Frozen Sausages',
                          price: 769,
                          quantity: '55 fl oz',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                        _Product(
                          name: 'Top Ramen Frozen Noodles',
                          price: 849,
                          quantity: '52 fl oz',
                          imageUrl: 'assets/images/categories.jpg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.primaryColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final String title;
  final List<_Product> products;

  const _ProductSection({
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to see all products in this category
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'see all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < products.length - 1 ? 12 : 0,
                  ),
                  child: _ProductCard(product: product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Product {
  final String name;
  final int price;
  final String quantity;
  final String imageUrl;

  _Product({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });
}

class _ProductCard extends StatelessWidget {
  final _Product product;

  const _ProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  product.imageUrl,
                  width: 150,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              // Add to cart button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Add to cart
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'ETB ${product.price}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.quantity,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

