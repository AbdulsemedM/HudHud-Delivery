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
            //
            // `Icons.schedule`, NOT `schedule_outlined`. Flutter tree-shakes
            // MaterialIcons down to the icons the code actually references, so
            // one new icon rewrites the font asset - and a Shorebird patch
            // cannot carry asset changes. Adding `schedule_outlined` took the
            // app from 313 referenced icons to 314 and turned a same-day patch
            // into a store release:
            //
            //     Your app contains asset changes, which will not be included
            //     in the patch.
            //         base/assets/flutter_assets/fonts/MaterialIcons-Regular.otf
            //
            // `schedule` and `location_off_outlined` are both already in the
            // shipped subset, so this renders a clock either way and the patch
            // publishes. Worth remembering before reaching for a novel icon in
            // anything that needs to ship as a patch.
            coverage.isComingSoon
                ? Icons.schedule
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
