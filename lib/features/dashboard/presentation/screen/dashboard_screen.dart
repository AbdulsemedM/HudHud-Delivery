import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreenWrapper(
        onSwitchToTab: (index) => setState(() => _selectedIndex = index),
      ),
      const CourierScreen(),
      const WalletScreen(),
      const TaxiScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: theme.colorScheme.shadow.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: GNav(
              rippleColor: theme.colorScheme.surfaceContainerHighest,
              hoverColor: theme.colorScheme.surfaceContainer,
              gap: 4,
              activeColor: theme.colorScheme.primary,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              color: theme.colorScheme.onSurfaceVariant,
              textStyle: const TextStyle(fontSize: 11),
              tabs: [
                GButton(
                  icon: Icons.home,
                  text: l10n.navHome,
                ),
                GButton(
                  icon: Icons.local_shipping,
                  text: l10n.navCourier,
                ),
                GButton(
                  icon: Icons.account_balance_wallet,
                  text: l10n.navWallet,
                ),
                GButton(
                  icon: Icons.local_taxi,
                  text: l10n.navTaxi,
                ),
                GButton(
                  icon: Icons.person,
                  text: l10n.navProfile,
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
