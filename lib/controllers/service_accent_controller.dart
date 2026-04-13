import 'package:flutter/foundation.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';

/// Drives app [ThemeData] primary/accent while the user is on the Home dashboard tab
/// and a service strip mode is active. Order History / Profile use the default theme.
class ServiceAccentController extends ChangeNotifier {
  HomeServiceMode _homeServiceMode = HomeServiceMode.foodGroceries;
  int _dashboardIndex = 0;

  HomeServiceMode get homeServiceMode => _homeServiceMode;
  int get dashboardIndex => _dashboardIndex;

  /// True when bottom nav is on Home (index 0).
  bool get isOnHomeTab => _dashboardIndex == 0;

  /// When true, [MyApp] applies a seeded theme from [homeServiceMode].
  bool get shouldApplyServiceAccent => isOnHomeTab;

  void updateHomeServiceMode(HomeServiceMode mode) {
    if (_homeServiceMode == mode) return;
    _homeServiceMode = mode;
    if (isOnHomeTab) notifyListeners();
  }

  void setDashboardIndex(int index) {
    if (_dashboardIndex == index) return;
    _dashboardIndex = index;
    notifyListeners();
  }
}
