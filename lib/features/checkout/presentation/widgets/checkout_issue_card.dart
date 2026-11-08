import 'package:flutter/material.dart';

/// Why checkout cannot place the order right now (store closed / busy, a
/// sold-out item, an address outside the city …) with one fix-it action.
class CheckoutIssueCard extends StatelessWidget {
  const CheckoutIssueCard({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('checkout_issue_card'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colorScheme.onErrorContainer, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const ValueKey('checkout_issue_action'),
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onErrorContainer,
                    minimumSize: const Size(48, 44),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: Text(actionLabel!),
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
