import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/courier/utils/fare_summary.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Under the estimated fee: the route distance, and - when the order is
/// re-priced on the actual route - that the fee is an estimate.
///
/// Tester report: distance was not clearly presented. The calculation is
/// deliberately NOT shown, to customers or riders (product decision).
class FareSummaryLine extends StatelessWidget {
  const FareSummaryLine({super.key, required this.summary});

  final FareSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = <String>[
      if (summary.distanceKm > 0)
        l10n.fareRouteDistance(formatFareKm(summary.distanceKm)),
      if (summary.isEstimate) l10n.fareEstimateNote,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('fare-summary-line'),
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        parts.join(' · '),
        style: TextStyle(fontSize: 12, color: HomeColors.textMutedOf(context)),
      ),
    );
  }
}
