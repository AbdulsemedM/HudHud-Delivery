import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../home/presentation/screen/home_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../settings/presentation/screen/settings_screen.dart';
import '../../../courier/presentation/screens/courier_screen.dart';
import '../../../taxi/presentation/screens/taxi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenWrapper(),
    const CourierScreen(),
    const WalletScreen(),
    const TaxiScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 4,
              activeColor: Colors.orange,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.orange.withOpacity(0.1),
              color: Colors.grey[600]!,
              textStyle: const TextStyle(fontSize: 11),
              tabs: const [
                GButton(
                  icon: Icons.home,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.local_shipping,
                  text: 'Courier',
                ),
                GButton(
                  icon: Icons.account_balance_wallet,
                  text: 'Wallet',
                ),
                GButton(
                  icon: Icons.local_taxi,
                  text: 'Taxi',
                ),
                GButton(
                  icon: Icons.person,
                  text: 'Profile',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
