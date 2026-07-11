import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/restaurant_screen.dart';
import 'package:hudhud_delivery/core/widgets/custom_text_field.dart';

class SearchRestaurantBar extends StatelessWidget {
  const SearchRestaurantBar({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomTextFieldStyles.searchField(
      hintText: 'Search restaurants by name',
    );
  }
}

class HotPicksSection extends StatelessWidget {
  const HotPicksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hot Picks in your area',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              RestaurantCircleCard(
                imageAsset: 'assets/images/cook_nature.jpg',
                name: 'Cook Nature',
                rating: 4.3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RestaurantScreen()),
                  );
                },
              ),
              RestaurantCircleCard(
                imageAsset: 'assets/images/taco_bell.png',
                name: 'Taco Bell',
                rating: 4.3,
              ),
              RestaurantCircleCard(
                imageAsset: 'assets/images/food_point.jpg',
                name: 'Food Point',
                rating: 4.3,
              ),
              RestaurantCircleCard(
                imageAsset: 'assets/images/kalzbrgr.png',
                name: 'Kalzbrgr',
                rating: 4.3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RestaurantCircleCard extends StatelessWidget {
  final String imageAsset;
  final String name;
  final double rating;
  final Function()? onTap;

  const RestaurantCircleCard({
    super.key,
    required this.imageAsset,
    required this.name,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const Icon(
                  Icons.star,
                  color: Colors.orange,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantListItem extends StatelessWidget {
  final String imageAsset;
  final String name;
  final double rating;
  final double avgPrice;
  final int deliveryTime;

  const RestaurantListItem({
    super.key,
    required this.imageAsset,
    required this.name,
    required this.rating,
    required this.avgPrice,
    required this.deliveryTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ETB ${avgPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      ' • Avg Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      ' • $deliveryTime Mins Delivery',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
