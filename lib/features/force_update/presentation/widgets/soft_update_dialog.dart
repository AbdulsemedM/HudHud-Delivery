import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/store_launcher.dart';

/// Dismissible prompt when the install is valid but behind the store latest.
Future<void> showSoftUpdateDialog(
  BuildContext context, {
  required String currentVersion,
  required String latestStoreVersion,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.lightBackground,
        title: Text(dialogContext.l10n.softUpdateTitle),
        content: Text(
          dialogContext.l10n.softUpdateMessage(
            currentVersion,
            latestStoreVersion,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.updateLater),
          ),
          FilledButton(
            onPressed: () async {
              await openAppStoreListing();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text(dialogContext.l10n.updateFromStore),
          ),
        ],
      );
    },
  );
}
