import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/controllers/service_accent_controller.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
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
      if (!GuestBrowseService().isGuestBrowseMode) {
        _openPendingFcmOrderIfAny();
        _openPendingFcmChatIfAny();
        syncDefaultAddressFromApi();
      }
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

  static const Color _navInactive = AuthScreenColors.textMuted;
  static const Color _navActive = AuthScreenColors.orange;
  static final Color _navIndicator = AuthScreenColors.orange.withValues(alpha: 0.22);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Material(
        color: AuthScreenColors.background,
        child: SafeArea(
          top: false,
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                height: 68,
                elevation: 0,
                backgroundColor: AuthScreenColors.background,
                indicatorColor: _navIndicator,
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
                    color: selected ? _navActive : _navInactive,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 24,
                    color: selected ? _navActive : _navInactive,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 68,
              elevation: 0,
              backgroundColor: AuthScreenColors.background,
              surfaceTintColor: Colors.transparent,
              indicatorColor: _navIndicator,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => AuthScreenColors.orange.withValues(
                  alpha: states.contains(WidgetState.pressed) ? 0.08 : 0.0,
                ),
              ),
              onDestinationSelected: (index) async {
                if (GuestBrowseService().isGuestBrowseMode && index != 0) {
                  final l10n = AppLocalizations.of(context)!;
                  await showGuestSignInRequiredDialog(
                    context,
                    title: l10n.guestSignInRequiredTitle,
                    message: index == 1
                        ? l10n.guestOrdersSignIn
                        : l10n.guestProfileSignIn,
                  );
                  return;
                }
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
                  icon: const Icon(Icons.home_outlined, color: _navInactive),
                  selectedIcon: const Icon(Icons.home_rounded, color: _navActive),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                    color: _navInactive,
                  ),
                  selectedIcon: const Icon(
                    Icons.receipt_long_rounded,
                    color: _navActive,
                  ),
                  label: l10n.navOrderHistory,
                ),
                NavigationDestination(
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    color: _navInactive,
                  ),
                  selectedIcon: const Icon(
                    Icons.person_rounded,
                    color: _navActive,
                  ),
                  label: l10n.navProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
