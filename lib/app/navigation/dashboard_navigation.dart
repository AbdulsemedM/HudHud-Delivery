/// Lets nested flows return to a dashboard tab and optionally refresh home content.
class DashboardNavigation {
  DashboardNavigation._();

  static final DashboardNavigation instance = DashboardNavigation._();

  void Function({required int tabIndex, required bool refreshHome})? _goToTab;

  void register(
    void Function({required int tabIndex, required bool refreshHome}) handler,
  ) {
    _goToTab = handler;
  }

  void unregister() {
    _goToTab = null;
  }

  void goToHome({bool refreshHome = true}) {
    _goToTab?.call(tabIndex: 0, refreshHome: refreshHome);
  }
}
