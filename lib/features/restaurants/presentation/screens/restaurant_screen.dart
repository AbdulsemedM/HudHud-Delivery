import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/complete_order_screen.dart';
import '../widgets/restaurant_widget.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  bool _showVegOnly = true;
  int _selectedCategoryIndex = 0;
  final Map<String, int> _cartItems = {};

  final List<String> _categories = [
    'Beef & Lamb',
    'Seafood',
    'Appetizers',
    'Dinner',
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'name': 'Cookie Sandwich',
      'description': 'Shortbread, chocolate turtle cookies, and red velvet.',
      'imageUrl': 'assets/images/cookie_sandwich.png',
      'price': 7.4,
    },
    {
      'name': 'Combo Burger',
      'description': 'Shortbread, chocolate turtle cookies, and red velvet.',
      'imageUrl': 'assets/images/combo_burger.png',
      'price': 7.4,
    },
    {
      'name': 'Combo Sandwich',
      'description': 'Shortbread, chocolate turtle cookies, and red velvet.',
      'imageUrl': 'assets/images/combo_sandwich.png',
      'price': 7.4,
    },
    {
      'name': 'Combo Burger',
      'description': 'Shortbread, chocolate turtle cookies, and red velvet.',
      'imageUrl': 'assets/images/combo_burger.png',
      'price': 7.4,
    },
  ];

  void _toggleVegOnly(bool value) {
    setState(() {
      _showVegOnly = value;
    });
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  void _addToCart(String itemName) {
    setState(() {
      _cartItems[itemName] = (_cartItems[itemName] ?? 0) + 1;
    });
  }

  void _removeFromCart(String itemName) {
    setState(() {
      _cartItems.remove(itemName);
    });
  }

  void _incrementQuantity(String itemName) {
    setState(() {
      _cartItems[itemName] = (_cartItems[itemName] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String itemName) {
    setState(() {
      if (_cartItems[itemName] == 1) {
        _cartItems.remove(itemName);
      } else {
        _cartItems[itemName] = _cartItems[itemName]! - 1;
      }
    });
  }

  int get _totalItems =>
      _cartItems.values.fold(0, (sum, quantity) => sum + quantity);

  double get _totalPrice {
    double total = 0;
    _cartItems.forEach((itemName, quantity) {
      final item = _menuItems.firstWhere((item) => item['name'] == itemName);
      total += (item['price'] as double) * quantity;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RestaurantHeader(
                  imageUrl: 'assets/images/restaurant.jpg',
                  restaurantLogo: 'assets/images/cook_nature.jpg',
                  onBackPressed: () => Navigator.pop(context),
                ),
                RestaurantInfo(
                  name: 'Cook Nature',
                  rating: 4.3,
                  reviews: 200,
                  avgPrice: 25,
                  deliveryTime: 25,
                  onFavoritePressed: () {},
                ),
                VegFoodToggle(
                  value: _showVegOnly,
                  onChanged: _toggleVegOnly,
                ),
                const SizedBox(height: 16),
                MenuCategories(
                  categories: _categories,
                  selectedIndex: _selectedCategoryIndex,
                  onCategorySelected: _selectCategory,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final itemName = item['name'] as String;
                    final quantity = _cartItems[itemName] ?? 0;
                    final isAdded = quantity > 0;

                    return MenuItem(
                      name: itemName,
                      description: item['description'] as String,
                      imageUrl: item['imageUrl'] as String,
                      price: item['price'] as double,
                      isAdded: isAdded,
                      quantity: quantity,
                      onAddPressed: () => _addToCart(itemName),
                      onRemovePressed: () => _removeFromCart(itemName),
                      onIncrementPressed: () => _incrementQuantity(itemName),
                      onDecrementPressed: () => _decrementQuantity(itemName),
                    );
                  },
                ),
                // Add extra padding at bottom for cart bar
                if (_totalItems > 0) const SizedBox(height: 80),
              ],
            ),
          ),
          if (_totalItems > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'TOTAL ITEMS: $_totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'ETB${_totalPrice.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CompleteOrderScreen()));
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Go to Checkout',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
