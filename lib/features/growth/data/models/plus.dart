import 'growth_json.dart';

/// `GET /api/customer/plus` (Phase 3 §5).
class PlusStatus {
  /// True only when parsed from a successful server response.
  final bool loaded;
  final bool enabled;
  final double price;
  final String currency;
  final int periodDays;
  final double freeDeliveryMinBasket;
  final double parcelDiscountPercent;
  final PlusSubscription? subscription;
  final double estimatedSavingsLast30d;

  const PlusStatus({
    required this.loaded,
    this.enabled = false,
    this.price = 0,
    this.currency = 'ETB',
    this.periodDays = 30,
    this.freeDeliveryMinBasket = 0,
    this.parcelDiscountPercent = 0,
    this.subscription,
    this.estimatedSavingsLast30d = 0,
  });

  /// Used whenever the call fails or the user is a guest: Plus stays hidden.
  static const PlusStatus disabled = PlusStatus(loaded: false);

  /// Plus is on and the UI may show entry points.
  bool get available => loaded && enabled;

  /// Member with benefits right now (badge, no upsell).
  bool get isMember => available && (subscription?.isActive ?? false);

  factory PlusStatus.fromJson(Map<String, dynamic> json) {
    final benefits = growthMap(json['benefits']) ?? const {};
    final subJson = growthMap(json['subscription']);
    final savingsRaw = json['estimated_savings_last_30d'];
    final savingsMap = growthMap(savingsRaw);
    final currency =
        (growthString(json['currency']) ?? 'ETB').toUpperCase();
    final periodDays = growthInt(json['period_days'], 30);
    return PlusStatus(
      loaded: true,
      enabled: growthBool(json['enabled']),
      price: growthDouble(json['price']),
      currency: currency,
      periodDays: periodDays > 0 ? periodDays : 30,
      freeDeliveryMinBasket:
          growthDouble(benefits['free_delivery_min_basket']),
      parcelDiscountPercent:
          growthDouble(benefits['parcel_discount_percent']),
      subscription: subJson == null
          ? null
          : PlusSubscription.fromJson(subJson, fallbackCurrency: currency),
      // Accept a bare number or `{amount, currency}`.
      estimatedSavingsLast30d: savingsMap != null
          ? growthDouble(savingsMap['amount'])
          : growthDouble(savingsRaw),
    );
  }

  /// Parses a full `{success, data}` body; [disabled] when not valid.
  static PlusStatus fromResponseBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return disabled;
    try {
      return PlusStatus.fromJson(data);
    } catch (_) {
      return disabled;
    }
  }
}

/// Subscription status values from the contract.
enum PlusSubscriptionStatus { active, cancelled, expired, pastDue, unknown }

PlusSubscriptionStatus parsePlusSubscriptionStatus(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'active':
      return PlusSubscriptionStatus.active;
    case 'cancelled':
    case 'canceled':
      return PlusSubscriptionStatus.cancelled;
    case 'expired':
      return PlusSubscriptionStatus.expired;
    case 'past_due':
    case 'past-due':
    case 'pastdue':
      return PlusSubscriptionStatus.pastDue;
    default:
      return PlusSubscriptionStatus.unknown;
  }
}

class PlusSubscription {
  final PlusSubscriptionStatus status;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final double price;
  final String currency;

  const PlusSubscription({
    required this.status,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.price = 0,
    this.currency = 'ETB',
  });

  bool get isActive => status == PlusSubscriptionStatus.active;
  bool get isPastDue => status == PlusSubscriptionStatus.pastDue;

  /// Active and set to renew → offer "cancel".
  bool get canCancel => isActive && !cancelAtPeriodEnd;

  /// Active but cancelled at period end → offer "resume".
  bool get canResume => isActive && cancelAtPeriodEnd;

  factory PlusSubscription.fromJson(
    Map<String, dynamic> json, {
    String fallbackCurrency = 'ETB',
  }) {
    return PlusSubscription(
      status: parsePlusSubscriptionStatus(growthString(json['status'])),
      currentPeriodEnd: growthDateTime(json['current_period_end']),
      cancelAtPeriodEnd: growthBool(json['cancel_at_period_end']),
      price: growthDouble(json['price']),
      currency: (growthString(json['currency']) ?? fallbackCurrency)
          .toUpperCase(),
    );
  }
}

/// Extra fields of a 422 `INSUFFICIENT_FUNDS` from `POST .../plus/subscribe`
/// (`{required, balance}` in `data`, or at the top level).
class PlusInsufficientFunds {
  final double requiredAmount;
  final double balance;
  final String? currency;

  const PlusInsufficientFunds({
    required this.requiredAmount,
    required this.balance,
    this.currency,
  });

  /// Amount still missing (never negative).
  double get shortfall {
    final d = requiredAmount - balance;
    return d > 0 ? d : 0;
  }

  static PlusInsufficientFunds? tryParse(dynamic body) {
    final root = growthMap(body);
    if (root == null) return null;
    final data = growthMap(root['data']) ?? growthMap(root['errors']);
    Map<String, dynamic>? src;
    if (data != null && data.containsKey('required')) {
      src = data;
    } else if (root.containsKey('required')) {
      src = root;
    }
    if (src == null) return null;
    return PlusInsufficientFunds(
      requiredAmount: growthDouble(src['required']),
      balance: growthDouble(src['balance']),
      currency: growthString(src['currency']),
    );
  }
}

/// `plus` object of the checkout quote: `{"member":true,"applied":true}`.
class CheckoutQuotePlus {
  final bool member;
  final bool applied;

  const CheckoutQuotePlus({required this.member, required this.applied});

  factory CheckoutQuotePlus.fromJson(Map<String, dynamic> json) {
    return CheckoutQuotePlus(
      member: growthBool(json['member']),
      applied: growthBool(json['applied']),
    );
  }
}
