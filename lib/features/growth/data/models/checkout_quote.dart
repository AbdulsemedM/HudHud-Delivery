import 'growth_json.dart';
import 'plus.dart';

/// Server-side price breakdown from `POST /api/customer/checkout/quote`.
///
/// Display only — order creation recomputes every number server-side.
class CheckoutQuote {
  final double subtotal;
  final double deliveryFee;
  final double deliveryFeeBeforeDiscounts;
  final CheckoutQuoteFreeDelivery freeDelivery;
  final CheckoutQuoteCoupon? coupon;
  final CheckoutQuotePoints points;
  final double total;
  final String currency;

  /// Phase 3: `{"member":bool,"applied":bool}`; null when absent.
  final CheckoutQuotePlus? plus;

  const CheckoutQuote({
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryFeeBeforeDiscounts,
    required this.freeDelivery,
    required this.coupon,
    required this.points,
    required this.total,
    required this.currency,
    this.plus,
  });

  /// HudHud Plus made the delivery free on this quote.
  bool get plusApplied => plus != null && plus!.applied;

  /// Delivery fee was reduced (free delivery, coupon or points).
  bool get deliveryFeeDiscounted =>
      deliveryFeeBeforeDiscounts > deliveryFee + 0.009;

  /// Delivery fee is zero only because of a discount.
  bool get isDeliveryFree =>
      deliveryFee <= 0.009 && deliveryFeeBeforeDiscounts > 0.009;

  double get couponDiscount =>
      coupon != null && coupon!.valid ? coupon!.discountAmount : 0;

  double get pointsDiscount => points.discountAmount;

  factory CheckoutQuote.fromJson(Map<String, dynamic> json) {
    final fee = growthDouble(json['delivery_fee']);
    final couponJson = growthMap(json['coupon']);
    return CheckoutQuote(
      // Backend also returns `items_discount` (per-product sale prices) and
      // computes total = subtotal - items_discount - coupon + delivery_fee.
      // Show the net subtotal so the displayed lines add up to the total.
      subtotal: growthDouble(json['subtotal']) -
          growthDouble(json['items_discount']),
      deliveryFee: fee,
      deliveryFeeBeforeDiscounts:
          growthDouble(json['delivery_fee_before_discounts'], fee),
      freeDelivery: CheckoutQuoteFreeDelivery.fromJson(
        growthMap(json['free_delivery']) ?? const {},
      ),
      coupon:
          couponJson == null ? null : CheckoutQuoteCoupon.fromJson(couponJson),
      points: CheckoutQuotePoints.fromJson(
        growthMap(json['points']) ?? const {},
      ),
      total: growthDouble(json['total']),
      currency: growthString(json['currency']) ?? 'ETB',
      plus: growthMap(json['plus']) == null
          ? null
          : CheckoutQuotePlus.fromJson(growthMap(json['plus'])!),
    );
  }

  /// Parses a full `{success, data}` body; `null` when not a valid quote.
  static CheckoutQuote? tryParseResponseBody(dynamic body) {
    final data = growthEnvelopeData(body);
    if (data == null) return null;
    if (!data.containsKey('total') || !data.containsKey('subtotal')) {
      return null;
    }
    try {
      return CheckoutQuote.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}

class CheckoutQuoteFreeDelivery {
  final bool enabled;
  final double threshold;
  final bool applied;
  final double remaining;

  const CheckoutQuoteFreeDelivery({
    required this.enabled,
    required this.threshold,
    required this.applied,
    required this.remaining,
  });

  /// Show the "add X more" hint.
  bool get showHint => enabled && !applied && remaining > 0.009;

  /// 0..1 progress toward the threshold.
  double get progress {
    if (threshold <= 0) return applied ? 1 : 0;
    final done = (threshold - remaining) / threshold;
    if (done.isNaN) return 0;
    return done.clamp(0.0, 1.0).toDouble();
  }

  factory CheckoutQuoteFreeDelivery.fromJson(Map<String, dynamic> json) {
    return CheckoutQuoteFreeDelivery(
      enabled: growthBool(json['enabled']),
      threshold: growthDouble(json['threshold']),
      applied: growthBool(json['applied']),
      remaining: growthDouble(json['remaining']),
    );
  }
}

class CheckoutQuoteCoupon {
  final String code;
  final bool valid;
  final double discountAmount;
  final bool freeDelivery;
  final String? message;

  const CheckoutQuoteCoupon({
    required this.code,
    required this.valid,
    required this.discountAmount,
    required this.freeDelivery,
    this.message,
  });

  factory CheckoutQuoteCoupon.fromJson(Map<String, dynamic> json) {
    return CheckoutQuoteCoupon(
      code: growthString(json['code']) ?? '',
      valid: growthBool(json['valid']),
      discountAmount: growthDouble(json['discount_amount']),
      freeDelivery: growthBool(json['free_delivery']),
      message: growthString(json['message']),
    );
  }
}

class CheckoutQuotePoints {
  final int balance;
  final int requested;
  final int redeemed;
  final double discountAmount;
  final int maxRedeemable;

  const CheckoutQuotePoints({
    required this.balance,
    required this.requested,
    required this.redeemed,
    required this.discountAmount,
    required this.maxRedeemable,
  });

  factory CheckoutQuotePoints.fromJson(Map<String, dynamic> json) {
    return CheckoutQuotePoints(
      balance: growthInt(json['balance']),
      requested: growthInt(json['requested']),
      redeemed: growthInt(json['redeemed']),
      discountAmount: growthDouble(json['discount_amount']),
      maxRedeemable: growthInt(json['max_redeemable']),
    );
  }
}

/// ETB value of [points] at the configured redeem rate
/// (`redeemValue` ETB per `redeemPoints` points).
double pointsToEtb(int points, {required int redeemPoints, required double redeemValue}) {
  if (points <= 0 || redeemPoints <= 0 || redeemValue <= 0) return 0;
  return (points ~/ redeemPoints) * redeemValue;
}
