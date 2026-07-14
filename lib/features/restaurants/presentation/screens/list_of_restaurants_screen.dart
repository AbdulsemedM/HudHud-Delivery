import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/favorite_restaurants_screen.dart';
import '../widgets/restaurants_widget.dart';

class ListOfRestaurantsScreen extends StatelessWidget {
  const ListOfRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> restaurants = [
      {
        'name': 'Cook Nature',
        'imageAsset': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
        'avgPrice': 25.0,
        'deliveryTime': 25,
      },
      {
        'name': 'Cook Nature',
        'imageAsset': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
        'avgPrice': 25.0,
        'deliveryTime': 25,
      },
      {
        'name': 'Cook Nature',
        'imageAsset': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
        'avgPrice': 25.0,
        'deliveryTime': 25,
      },
      {
        'name': 'Cook Nature',
        'imageAsset': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
        'avgPrice': 25.0,
        'deliveryTime': 25,
      },
      {
        'name': 'Cook Nature',
        'imageAsset': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
        'avgPrice': 25.0,
        'deliveryTime': 25,
      },
      {
        'name': 'Cook Nature',
        'imageAsset': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
        'avgPrice': 25.0,
        'deliveryTime': 25,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          'GO BACK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SearchRestaurantBar(),
                      const SizedBox(height: 12),
                      const HotPicksSection(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Restaurants',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FavoriteRestaurantsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'See Favorites',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return RestaurantListItem(
                            imageAsset: restaurant['imageAsset'],
                            name: restaurant['name'],
                            rating: restaurant['rating'],
                            avgPrice: restaurant['avgPrice'],
                            deliveryTime: restaurant['deliveryTime'],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
