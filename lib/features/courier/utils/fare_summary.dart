/// What the customer sees under the estimated fee: the route distance and,
/// when the order is re-priced on the actual route, that the fee is an
/// estimate. Tester report: distance was not clearly presented.
///
/// Deliberately no calculation (product decision), so nothing about rates or
/// fee lines is read here, and the server no longer sends them.
class FareSummary {
  const FareSummary({required this.distanceKm, this.isEstimate = false});

  /// The route distance (`estimated_distance`), not the billable distance:
  /// the pricing engine rounds short trips up to a minimum, and "2 km" under
  /// a 0.8 km trip would be wrong.
  final double distanceKm;

  /// `final_price_basis == actual_route`: re-priced at completion.
  final bool isEstimate;

  /// From the raw estimate response (flat or under `data`). Null when there
  /// is nothing worth showing.
  static FareSummary? fromEstimateResponse(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw['data'] is Map && raw['estimated_distance'] == null
        ? raw['data'] as Map
        : raw;
    final summary = FareSummary(
      distanceKm: _toDouble(map['estimated_distance']) ?? 0,
      isEstimate: map['final_price_basis']?.toString() == 'actual_route',
    );
    return summary.distanceKm > 0 || summary.isEstimate ? summary : null;
  }
}

/// "3", "6.2": distances read better without trailing zeros.
String formatFareKm(double v) {
  final rounded = (v * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1);
}

double? _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
