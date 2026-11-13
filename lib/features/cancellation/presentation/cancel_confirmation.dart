import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/localized_date.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import '../cancellation_policy_controller.dart';
import '../data/cancellation_models.dart';
import '../data/cancellation_repository.dart';
import 'cancellation_widgets.dart';

enum CancelSubject { delivery, order }

enum CancelDecisionKind {
  /// Customer backed out, or the server said no (already explained).
  abort,

  /// No penalty applies (rules off, older backend, or a free cancel):
  /// the caller shows its usual confirm dialog.
  legacy,

  /// Customer accepted the penalty in our dialog: cancel now and send
  /// [CancelDecision.acceptPenaltyPoints].
  confirmed,
}

class CancelDecision {
  final CancelDecisionKind kind;

  /// Send as `accept_penalty_points` (0 for a previewed free cancel, null
  /// when no preview ran).
  final int? acceptPenaltyPoints;
  final CancellationPreview? preview;

  const CancelDecision._(this.kind, {this.acceptPenaltyPoints, this.preview});

  static const abort = CancelDecision._(CancelDecisionKind.abort);
  static const legacyNoPreview = CancelDecision._(CancelDecisionKind.legacy);
}

/// Runs the cancellation preview before a customer cancel.
///
/// [load] fetches the preview (`previewDelivery` / `previewOrder`).
Future<CancelDecision> previewAndConfirmCancellation(
  BuildContext context, {
  required CancelSubject subject,
  required Future<CancellationPreviewResult> Function(
    CancellationRepository repository,
  ) load,
  CancellationRepository? repository,
}) async {
  final controller = CancellationPolicyController.instance;
  await controller.refresh();
  if (!controller.penaltyEnabled || !context.mounted) {
    return CancelDecision.legacyNoPreview;
  }

  final repo = repository ?? CancellationRepository();
  final result = await _withProgress(context, load(repo));
  if (!context.mounted) return CancelDecision.abort;

  if (result.unsupported) return CancelDecision.legacyNoPreview;
  final l10n = context.l10n;
  final preview = result.preview;
  if (preview == null) {
    _snack(context, result.errorMessage ?? l10n.cpCannotCancelGeneric);
    return CancelDecision.abort;
  }
  if (!preview.canCancel) {
    final picked = (preview.reasonCode ?? '').toUpperCase().contains('PICKED');
    _snack(
      context,
      picked
          ? l10n.cpCannotCancelPickedUp
          : (preview.message ?? l10n.cpCannotCancelGeneric),
    );
    return CancelDecision.abort;
  }
  if (preview.isFree) {
    return CancelDecision._(
      CancelDecisionKind.legacy,
      acceptPenaltyPoints: 0,
      preview: preview,
    );
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => CancellationPenaltyDialog(preview: preview, subject: subject),
  );
  if (ok != true) return CancelDecision.abort;
  return CancelDecision._(
    CancelDecisionKind.confirmed,
    acceptPenaltyPoints: preview.penaltyPoints,
    preview: preview,
  );
}

/// Extra line for the "cancelled" snack bar when points were added (null
/// when the cancel was free). Also refreshes the cached standing.
String? cancellationOutcomeMessage(
  AppLocalizations l10n,
  CancellationPenaltyOutcome? outcome, {
  String Function(DateTime)? formatDate,
}) {
  CancellationPolicyController.instance.refresh(force: true);
  if (outcome == null) return null;
  final parts = <String>[
    l10n.cpCancelledWithPoints(outcome.pointsAdded, outcome.pointsTotal),
  ];
  final fine = outcome.fine;
  if (outcome.consequence == CancellationConsequence.fine && fine != null) {
    parts.add(
      l10n.cpFineIssued(formatMoneyAmount(fine.amount, currency: fine.currency)),
    );
  } else if (outcome.consequence == CancellationConsequence.suspension &&
      outcome.suspendedUntil != null) {
    final until = outcome.suspendedUntil!;
    parts.add(
      l10n.cpSuspendedUntil(formatDate?.call(until) ?? until.toString()),
    );
  }
  return parts.join('\n');
}

/// Context-aware wrapper around [cancellationOutcomeMessage].
String? cancellationOutcomeMessageOf(
  BuildContext context,
  CancellationPenaltyOutcome? outcome,
) =>
    cancellationOutcomeMessage(
      context.l10n,
      outcome,
      formatDate: (d) => context.formatDateTime(d),
    );

/// The "Cancel and get penalty points?" dialog.
class CancellationPenaltyDialog extends StatelessWidget {
  const CancellationPenaltyDialog({
    super.key,
    required this.preview,
    required this.subject,
  });

  final CancellationPreview preview;
  final CancelSubject subject;

  String _consequenceText(AppLocalizations l10n) {
    switch (preview.consequence) {
      case CancellationConsequence.fine:
        final amount = preview.fineAmount;
        return amount == null || amount <= 0
            ? l10n.cpWillFineNoAmount(preview.fineThreshold)
            : l10n.cpWillFine(
                preview.fineThreshold,
                formatMoneyAmount(amount, currency: preview.currency),
              );
      case CancellationConsequence.suspension:
        final days = preview.suspensionDays;
        return days == null || days <= 0
            ? l10n.cpWillSuspendNoDays(preview.banThreshold)
            : l10n.cpWillSuspend(preview.banThreshold, days);
      case CancellationConsequence.none:
        return preview.pointsAfter < preview.fineThreshold
            ? l10n.cpWarnFineAt(preview.fineThreshold)
            : l10n.cpWarnBanAt(preview.banThreshold);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final severe = preview.consequence != CancellationConsequence.none;
    final body = subject == CancelSubject.order
        ? l10n.cpPenaltyBodyOrder(preview.penaltyPoints)
        : l10n.cpPenaltyBodyDelivery(preview.penaltyPoints);
    return AlertDialog(
      backgroundColor: HomeColors.surfaceElevatedOf(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 40,
        color: severe ? AppColors.errorColor : AppColors.warningColor,
      ),
      title: Text(
        l10n.cpPenaltyTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: HomeColors.textPrimaryOf(context),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: HomeColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            CancellationPointsMeter(
              points: preview.pointsBefore,
              pointsAfter: preview.pointsAfter,
              fineThreshold: preview.fineThreshold,
              banThreshold: preview.banThreshold,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (severe ? AppColors.errorColor : AppColors.warningColor)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _consequenceText(l10n),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: severe ? FontWeight.w700 : FontWeight.w500,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowDirection: VerticalDirection.up,
      actions: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              subject == CancelSubject.order
                  ? l10n.cpKeepOrder
                  : l10n.cpKeepDelivery,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.cpCancelAnyway,
              style: const TextStyle(
                color: AppColors.errorColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<T> _withProgress<T>(BuildContext context, Future<T> future) async {
  var shown = false;
  var done = false;
  // Only show a spinner if the call is slow, to avoid a flash.
  final timer = Future<void>.delayed(const Duration(milliseconds: 250), () {
    if (done || !context.mounted) return;
    shown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  });
  try {
    return await future;
  } finally {
    done = true;
    await timer;
    if (shown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: AppColors.errorColor),
  );
}
