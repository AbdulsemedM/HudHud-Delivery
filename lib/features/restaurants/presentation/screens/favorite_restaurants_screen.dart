import 'package:flutter/material.dart';

class FavoriteRestaurantsScreen extends StatelessWidget {
  const FavoriteRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> favoriteRestaurants = [
      {
        'name': 'Cook Nature',
        'imageUrl': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
      },
      {
        'name': 'Taco Bell',
        'imageUrl': 'assets/images/taco_bell.png',
        'rating': 4.3,
      },
      {
        'name': 'Food Point',
        'imageUrl': 'assets/images/food_point.jpg',
        'rating': 4.3,
      },
      {
        'name': 'Kalzbrgr',
        'imageUrl': 'assets/images/kalzbrgr.png',
        'rating': 4.3,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'GO BACK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search restaurants by name',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Your Favorite Restaurants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Favorite Restaurants List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: favoriteRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = favoriteRestaurants[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        // Restaurant Image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(restaurant['imageUrl']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Restaurant Name
                        Expanded(
                          child: Text(
                            restaurant['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Rating
                        Row(
                          children: [
                            Text(
                              restaurant['rating'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Favorite Icon
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 24,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
