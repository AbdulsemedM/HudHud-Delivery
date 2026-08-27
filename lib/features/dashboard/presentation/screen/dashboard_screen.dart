import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/app_navigator.dart';
import 'package:hudhud_delivery/app/navigation/dashboard_navigation.dart';
import 'package:hudhud_delivery/app/navigation/fcm_notification_router.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/fcm_service.dart';
import 'package:hudhud_delivery/controllers/service_accent_controller.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
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
      _handleFcmLaunchNavigation();
      syncDefaultAddressFromApi();
    });
    DashboardNavigation.instance.register(_onDashboardNavigationRequest);
  }

  void _onDashboardNavigationRequest({
    required int tabIndex,
    required bool refreshHome,
  }) {
    if (!mounted) return;
    setState(() => _selectedIndex = tabIndex.clamp(0, _screens.length - 1));
    context.read<ServiceAccentController>().setDashboardIndex(_selectedIndex);
    if (refreshHome && tabIndex == 0) {
      _homeTabActivation.value = _homeTabActivation.value + 1;
    }
  }

  Future<void> _handleFcmLaunchNavigation() async {
    final navKey = AppNavigator.navigatorKey;
    if (navKey != null) {
      final initialMessage = await FcmService().getInitialMessage();
      if (initialMessage != null) {
        await openNotificationFromFcm(navKey, message: initialMessage);
      }
      await flushPendingFcmNavigation(navKey);
      _openPendingFcmOrderIfAny();
      _openPendingFcmChatIfAny();
    } else {
      _openPendingFcmOrderIfAny();
      _openPendingFcmChatIfAny();
    }
    _applyPendingDashboardTab();
  }

  void _applyPendingDashboardTab() {
    final tabIndex = PendingFcmDashboardTab.takePending();
    if (tabIndex == null) return;
    if (!mounted) return;
    setState(() => _selectedIndex = tabIndex.clamp(0, _screens.length - 1));
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
    DashboardNavigation.instance.unregister();
    _homeTabActivation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navInactive = AuthScreenColors.textMutedOf(context);
    final navActive = AuthScreenColors.orange;
    final navIndicator = AuthScreenColors.orange.withValues(alpha: 0.22);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Material(
        color: AuthScreenColors.backgroundOf(context),
        child: SafeArea(
          top: false,
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                height: 68,
                elevation: 0,
                backgroundColor: AuthScreenColors.backgroundOf(context),
                indicatorColor: navIndicator,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11.5,
                    letterSpacing: 0.1,
                    color: selected ? navActive : navInactive,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 24,
                    color: selected ? navActive : navInactive,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 68,
              elevation: 0,
              backgroundColor: AuthScreenColors.backgroundOf(context),
              surfaceTintColor: Colors.transparent,
              indicatorColor: navIndicator,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => AuthScreenColors.orange.withValues(
                  alpha: states.contains(WidgetState.pressed) ? 0.08 : 0.0,
                ),
              ),
              onDestinationSelected: (index) async {
                setState(() => _selectedIndex = index);
                context
                    .read<ServiceAccentController>()
                    .setDashboardIndex(index);
                if (index == 0) {
                  _homeTabActivation.value = _homeTabActivation.value + 1;
                }
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: navInactive),
                  selectedIcon: Icon(Icons.home_rounded, color: navActive),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    color: navInactive,
                  ),
                  selectedIcon: Icon(
                    Icons.receipt_long_rounded,
                    color: navActive,
                  ),
                  label: l10n.navMyDeliveries,
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.person_outline_rounded,
                    color: navInactive,
                  ),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                    color: navActive,
                  ),
                  label: l10n.navMe,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
