import 'package:flutter/material.dart';

import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';

import 'data/growth_repository.dart';
import 'market_controller.dart';

/// Switches the customer's city to [marketCode] (CITY_MARKET_MISMATCH
/// "Switch your city" action). Signed-in customers go through
/// `PUT /api/customer/market` first, exactly like the settings picker.
/// Returns true when the city changed.
Future<bool> switchCustomerMarket(
  BuildContext context,
  String marketCode,
) async {
  final controller = MarketController.instance;
  final market = controller?.marketFor(marketCode);
  if (controller == null || market == null) return false;
  if (controller.selectedCode == market.code) return true;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  if (!await AuthService().isAuthenticated()) {
    await controller.select(market);
    return true;
  }
  final result =
      await GrowthRepository.create().updateCustomerMarket(market.code);
  if (result.ok) {
    await controller.select(market);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.p3MarketChanged(market.name))),
    );
    return true;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.isBlocked
            ? l10n.p3MarketChangeBlocked
            : (result.message ?? l10n.p3MarketChangeFailed),
      ),
    ),
  );
  return false;
}
