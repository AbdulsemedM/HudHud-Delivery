import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/growth/market_controller.dart';
import 'package:hudhud_delivery/features/vendors/data/models/store_status.dart';
import 'package:hudhud_delivery/features/vendors/presentation/widgets/store_status_widgets.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Localized copy for the API error codes the customer app explains in its
/// own words (store closed / busy, sold out, unpaid balance, one-city
/// rule). Returns null for any other error so callers keep their own text.
///
/// [itemName] names the sold-out product when the caller can look it up
/// from [ApiErrorResult.productId] (e.g. from the cart).
String? localizedKnownApiError(
  AppLocalizations l10n,
  ApiErrorResult error, {
  String? itemName,
  DateTime? now,
}) {
  if (error.isStoreUnavailable) {
    return storeUnavailableMessage(
      l10n,
      StoreStatus.tryParse(error.storeStatus),
      busy: error.isStorePaused,
      now: now,
    );
  }
  if (error.isItemSoldOut) {
    final name = itemName?.trim();
    return name == null || name.isEmpty
        ? l10n.p12ErrItemSoldOut
        : l10n.p12ErrItemSoldOutNamed(name);
  }
  if (error.isOutstandingDues) {
    final amount = error.amount;
    if (amount == null || amount <= 0) return l10n.p12CashBlockedByDues;
    return l10n.p12ErrOutstandingDues(
      formatMoneyAmount(amount, currency: error.currency),
    );
  }
  switch (error.code) {
    case kCityOutsideCode:
      return l10n.p12ErrCityOutside;
    case kCityCrossMarketCode:
      return l10n.p12ErrCityCross;
    case kCityMarketMismatchCode:
      final city = cityNameForMarket(error.marketCode);
      return city == null
          ? l10n.p12ErrCityMismatchGeneric
          : l10n.p12ErrCityMismatch(city);
  }
  return null;
}

/// Display name of a market code from the loaded markets list.
String? cityNameForMarket(String? code) {
  if (code == null || code.isEmpty) return null;
  final name = MarketController.instance?.marketFor(code)?.name.trim();
  return name == null || name.isEmpty ? null : name;
}

/// Kind of transport / server failure behind an error without a known code.
enum ApiFailureKind { network, timeout, sessionExpired, server, other }

/// Classifies a failure from its HTTP status and the ApiService message
/// (`ApiService._handleDioError` gives no status for transport errors).
ApiFailureKind classifyApiFailure({int? statusCode, String? message}) {
  if (statusCode == 401) return ApiFailureKind.sessionExpired;
  if (statusCode == 500 || statusCode == 502 || statusCode == 504) {
    return ApiFailureKind.server;
  }
  if (statusCode == null || statusCode == 0) {
    final lower = (message ?? '').toLowerCase();
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return ApiFailureKind.timeout;
    }
    if (lower.contains('connection') ||
        lower.contains('internet') ||
        lower.contains('socket') ||
        lower.contains('network')) {
      return ApiFailureKind.network;
    }
  }
  return ApiFailureKind.other;
}

/// One localized sentence for any failed call: a known code first, then
/// network / timeout / session / server failures, then the server's own
/// [message], then [fallback].
String localizedApiErrorMessage(
  AppLocalizations l10n, {
  String? code,
  int? statusCode,
  dynamic data,
  String? message,
  String? fallback,
  String? itemName,
  DateTime? now,
}) {
  final parsed = parseApiErrorResult(
    data is Map ? data : (message ?? ''),
    statusCode: statusCode,
  );
  final error = (code != null && code.isNotEmpty && parsed.code != code)
      ? ApiErrorResult(
          message: parsed.message,
          code: code,
          statusCode: statusCode,
          amount: parsed.amount,
          currency: parsed.currency,
          productId: parsed.productId,
          marketCode: parsed.marketCode,
          storeStatus: parsed.storeStatus,
        )
      : parsed;
  final known =
      localizedKnownApiError(l10n, error, itemName: itemName, now: now);
  if (known != null) return known;
  switch (classifyApiFailure(statusCode: statusCode, message: message)) {
    case ApiFailureKind.network:
      return l10n.p12ErrNetwork;
    case ApiFailureKind.timeout:
      return l10n.p12ErrTimeout;
    case ApiFailureKind.sessionExpired:
      return l10n.p12ErrSessionExpired;
    case ApiFailureKind.server:
      return l10n.p12ErrServer;
    case ApiFailureKind.other:
      break;
  }
  final text = message?.trim();
  if (text != null && text.isNotEmpty) return text;
  return fallback ?? l10n.p12ErrServer;
}
