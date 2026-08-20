import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hudhud_delivery/core/config/store_config.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/store_launcher.dart';

/// Blocking screen when the installed binary is below [minimumSupportedVersion].
///
/// Used only for store-required (native/plugin) upgrades — not Shorebird patches.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.minimumSupportedVersion,
    required this.latestStoreVersion,
  });

  final String currentVersion;
  final String minimumSupportedVersion;
  final String latestStoreVersion;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.lightBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.system_update_alt_rounded,
                    size: 72,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update required',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightOnBackground,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A newer version of ${StoreConfig.appDisplayName} is required '
                    'to continue. This update must be installed from the store '
                    '(native / plugin changes cannot be delivered over the air).',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightOnBackground.withValues(
                            alpha: 0.75,
                          ),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Installed: $currentVersion\n'
                    'Minimum: $minimumSupportedVersion\n'
                    'Latest: $latestStoreVersion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnBackground.withValues(
                            alpha: 0.55,
                          ),
                        ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: openAppStoreListing,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(context.l10n.updateFromStore),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
