import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
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
      appBar: AppBar(
        title: const Text('All categories'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryGridItem(
            title: category['title'] as String,
            icon: category['icon'] as IconData,
            onTap: () {
              // TODO: Navigate to category
            },
          );
        },
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






