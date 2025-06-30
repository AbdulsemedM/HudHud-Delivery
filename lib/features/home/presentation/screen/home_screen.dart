import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/list_of_restaurants_screen.dart';
import '../widgets/home_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserProfileHeader(
                name: 'Samara',
                location: 'XQXH+5RG, Addis Ababa, Ethiopia',
                onLocationTap: () {
                  // Handle location change
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'While You may like to have',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  ServiceCategory(
                    title: 'Groceries',
                    subtitle: 'Order groceries\nfrom your fav\nvendors',
                    imagePath: 'assets/images/groceries.png',
                    backgroundColor: Colors.grey[100]!,
                    onTap: () {
                      // Handle groceries
                    },
                  ),
                  ServiceCategory(
                    title: 'Food',
                    subtitle: 'Order food from\nall over the city.',
                    imagePath: 'assets/images/food.png',
                    backgroundColor: Colors.orange[50]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListOfRestaurantsScreen(),
                        ),
                      );
                    },
                  ),
                  ServiceCategory(
                    title: 'Clothing',
                    subtitle: 'Order clothes\nfrom your fav\nbrands',
                    imagePath: 'assets/images/clothing.png',
                    backgroundColor: Colors.purple[50]!,
                    onTap: () {
                      // Handle clothing
                    },
                  ),
                  ServiceCategory(
                    title: 'Pharmacy',
                    subtitle: 'Need medicines?\nWe can deliver\nthose too.',
                    imagePath: 'assets/images/pharmacy.png',
                    backgroundColor: Colors.grey[100]!,
                    onTap: () {
                      // Handle pharmacy
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SeeAllServicesCard(
                onTap: () {
                  // Handle see all services
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
