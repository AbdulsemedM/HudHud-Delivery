import 'package:flutter/material.dart';

import 'package:hudhud_delivery/features/growth/data/models/city_coverage.dart';

/// "We do not deliver here yet", in the server's own words.
///
/// The wording is never rebuilt on the device. `CityCoverage.message` already
/// distinguishes a city that is coming soon from somewhere nowhere near us,
/// and names the city; a second copy of that logic here would drift from the
/// first, and the two would disagree about what the customer is told.
///
/// Shown from every screen that commits to a location, so it lives here
/// rather than being written twice.
class OutOfAreaSheet extends StatelessWidget {
  const OutOfAreaSheet({super.key, required this.coverage});

  final CityCoverage coverage;

  static Future<void> show(BuildContext context, CityCoverage coverage) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => OutOfAreaSheet(coverage: coverage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            // A city we are about to open and a place we have never served
            // are different news, so they do not get the same icon.
            coverage.isComingSoon
                ? Icons.schedule_outlined
                : Icons.location_off_outlined,
            color: Colors.orange.shade800,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            coverage.message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (coverage.openCities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'We currently deliver in ${coverage.openCities.join(', ')}.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Pick another location'),
            ),
          ),
        ],
      ),
    );
  }
}
