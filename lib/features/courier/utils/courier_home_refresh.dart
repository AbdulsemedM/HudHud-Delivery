/// Notifies [CourierScreen] to reload active delivery and history.
class CourierHomeRefresh {
  CourierHomeRefresh._();

  static final CourierHomeRefresh instance = CourierHomeRefresh._();

  final _listeners = <void Function()>{};

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void notifyRefresh() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }
}
