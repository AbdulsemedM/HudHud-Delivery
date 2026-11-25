/// "Send a package" was tapped on the home screen: open the sending flow.
///
/// Tester report: the tile only switched tabs, and the customer then had to
/// find "Add Delivery" to start. The courier screen listens and opens the
/// same flow "Add Delivery" opens - unless a delivery is in progress, in
/// which case the tap just shows the tab so the customer sees that delivery
/// rather than landing in a new booking. Same shape as CourierHomeRefresh.
class CourierSendRequest {
  CourierSendRequest._();

  static final CourierSendRequest instance = CourierSendRequest._();

  final _listeners = <void Function()>{};

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void request() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }
}
