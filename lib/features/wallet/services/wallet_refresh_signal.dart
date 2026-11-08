import 'package:flutter/foundation.dart';

/// App-wide "wallet balance may have changed" signal (e.g. an order was
/// cancelled and refunded to the HudHud wallet). Screens that show the
/// balance listen and reload; nothing else is cached here.
class WalletRefreshSignal {
  WalletRefreshSignal._();

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void notify() => changes.value++;
}
