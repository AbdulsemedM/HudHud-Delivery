import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/controllers/service_accent_controller.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/screen/home_screen.dart';
import '../../../settings/presentation/screen/settings_screen.dart';
import '../../../orders/presentation/screen/orders_screen.dart';
import '../../../addresses/presentation/screens/addresses_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  /// Incremented on first frame and every time the user selects the Home tab.
  late final ValueNotifier<int> _homeTabActivation;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _homeTabActivation = ValueNotifier<int>(0);
    _screens = [
      HomeScreenWrapper(homeTabActivation: _homeTabActivation),
      const OrdersScreen(),
      const SettingsScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeTabActivation.value = _homeTabActivation.value + 1;
      _openPendingFcmOrderIfAny();
      _openPendingFcmChatIfAny();
      syncDefaultAddressFromApi();
    });
  }

  void _openPendingFcmOrderIfAny() {
    final id = PendingFcmOrderNavigation.takePending();
    if (id == null) return;
    if (!mounted) return;
    pushOrderDetailsById(context, orderId: id);
  }

  void _openPendingFcmChatIfAny() {
    final id = PendingFcmChatNavigation.takePending();
    if (id == null) return;
    if (!mounted) return;
    pushChatRoomById(context, conversationId: id);
  }

  @override
  void dispose() {
    _homeTabActivation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final indicator = colorScheme.primary.withValues(alpha: 0.14);
    final shadow = colorScheme.shadow.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.12);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.brightness == Brightness.dark
                        ? [
                            colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
                            colorScheme.surfaceContainerHigh.withValues(alpha: 0.82),
                          ]
                        : [
                            colorScheme.surface.withValues(alpha: 0.94),
                            colorScheme.surfaceContainerLowest.withValues(alpha: 0.92),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Theme(
                  data: theme.copyWith(
                    navigationBarTheme: NavigationBarThemeData(
                      height: 68,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      indicatorColor: indicator,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return theme.textTheme.labelMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 11.5,
                          letterSpacing: 0.1,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        );
                      }),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return IconThemeData(
                          size: 24,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        );
                      }),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    height: 68,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: indicator,
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => colorScheme.primary.withValues(
                        alpha: states.contains(WidgetState.pressed) ? 0.08 : 0.0,
                      ),
                    ),
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                      context
                          .read<ServiceAccentController>()
                          .setDashboardIndex(index);
                      if (index == 0) {
                        _homeTabActivation.value =
                            _homeTabActivation.value + 1;
                      }
                    },
                    destinations: [
                      NavigationDestination(
                        icon: Icon(
                          Icons.home_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: Icon(
                          Icons.home_rounded,
                          color: colorScheme.primary,
                        ),
                        label: l10n.navHome,
                      ),
                      NavigationDestination(
                        icon: Icon(
                          Icons.receipt_long_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: Icon(
                          Icons.receipt_long_rounded,
                          color: colorScheme.primary,
                        ),
                        label: l10n.navOrderHistory,
                      ),
                      NavigationDestination(
                        icon: Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        selectedIcon: Icon(
                          Icons.person_rounded,
                          color: colorScheme.primary,
                        ),
                        label: l10n.navProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
