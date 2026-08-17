import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/navigation/dashboard_navigation.dart';

void main() {
  test('goToHome invokes registered handler', () {
    int? selectedTab;
    bool? shouldRefreshHome;

    DashboardNavigation.instance.register(
      ({required int tabIndex, required bool refreshHome}) {
        selectedTab = tabIndex;
        shouldRefreshHome = refreshHome;
      },
    );

    DashboardNavigation.instance.goToHome();
    expect(selectedTab, 0);
    expect(shouldRefreshHome, isTrue);

    DashboardNavigation.instance.unregister();
  });
}
