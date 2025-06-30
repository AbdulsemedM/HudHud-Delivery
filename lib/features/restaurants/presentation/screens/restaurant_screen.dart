import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
            // const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }
}
