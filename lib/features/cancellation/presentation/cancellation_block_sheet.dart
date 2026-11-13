import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/api_error_result.dart';
import 'package:hudhud_delivery/core/utils/localized_date.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/core/widgets/call_support_button.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/wallet/presentation/screens/add_funds_screen.dart';

import '../cancellation_policy_controller.dart';
import '../data/cancellation_models.dart';
import '../data/cancellation_repository.dart';
import 'cancellation_standing_screen.dart';

/// Shows the fine / suspension sheet when a booking or order was refused by
/// the cancellation-penalty rules. Returns true when [error] was such a
/// refusal (the caller should stop its own error handling).
Future<bool> handleCancellationBlockError(
  BuildContext context,
  ApiErrorResult error,
) async {
  if (!error.isCancellationBlock) return false;
  // The standing changed server-side; refresh it for banners / buttons.
  CancellationPolicyController.instance.refresh(force: true);
  if (error.isCancellationFineUnpaid) {
    final fine = error.fineId != null && (error.amount ?? 0) > 0
        ? CancellationFine(
            id: error.fineId!,
            amount: error.amount!,
            currency: error.currency ?? 'ETB',
          )
        : CancellationPolicyController.instance.standing?.fine;
    await showCancellationFineSheet(context, fine: fine);
  } else {
    await showCancellationSuspendedSheet(
      context,
      until: error.suspendedUntil ??
          CancellationPolicyController.instance.standing?.suspendedUntil,
    );
  }
  return true;
}

/// "You can't book right now — pay your fine" sheet.
/// Returns true when the fine was paid.
Future<bool> showCancellationFineSheet(
  BuildContext context, {
  CancellationFine? fine,
}) async {
  final paid = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: HomeColors.surfaceElevatedOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FineSheet(fine: fine),
  );
  return paid == true;
}

/// "Account paused until …" sheet.
Future<void> showCancellationSuspendedSheet(
  BuildContext context, {
  DateTime? until,
}) {
  final l10n = context.l10n;
  final body = until == null
      ? l10n.cpSuspendedBodyNoDate
      : l10n.cpSuspendedBody(context.formatDateTime(until));
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HomeColors.surfaceElevatedOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SheetFrame(
      icon: Icons.block_rounded,
      color: AppColors.errorColor,
      title: l10n.cpStandingSuspended,
      body: body,
      actions: [
        const CallSupportButton(),
        const SizedBox(height: 8),
        _ViewRecordButton(parentContext: sheetContext),
      ],
    ),
  );
}

/// Pays [fine] from the wallet; offers a top-up when the wallet is short.
/// Shows its own snack bars. Returns true when the fine is paid.
Future<bool> payCancellationFine(
  BuildContext context,
  CancellationFine fine, {
  CancellationRepository? repository,
}) async {
  final repo = repository ?? CancellationRepository();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  var result = await repo.payFine(fine.id);
  if (!result.ok && result.error?.isInsufficientBalance == true) {
    if (!context.mounted) return false;
    final error = result.error!;
    final shortBy = (error.deficit != null && error.deficit! > 0)
        ? error.deficit!
        : fine.amount - (error.balance ?? 0);
    final topUp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cpStandingFineDue),
        content: Text(l10n.cpTopUpToPayFine),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.cpTopUp),
          ),
        ],
      ),
    );
    if (topUp != true || !context.mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFundsScreen(
          defaultCurrency: fine.currency,
          initialAmount: shortBy > 0 ? shortBy : fine.amount,
        ),
      ),
    );
    if (!context.mounted) return false;
    // Topping up may already collect the fine (like customer dues); check
    // before charging again.
    final standing =
        await CancellationPolicyController.instance.refresh(force: true);
    if (standing != null && !standing.hasFine) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.cpFinePaid),
        backgroundColor: AppColors.successColor,
      ));
      return true;
    }
    result = await repo.payFine(fine.id);
  }
  CancellationPolicyController.instance.refresh(force: true);
  if (result.ok) {
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.cpFinePaid),
      backgroundColor: AppColors.successColor,
    ));
    return true;
  }
  messenger.showSnackBar(SnackBar(
    content: Text(
      result.error?.displayMessage ?? result.message ?? l10n.actionTryAgain,
    ),
    backgroundColor: AppColors.errorColor,
  ));
  return false;
}

class _FineSheet extends StatefulWidget {
  const _FineSheet({this.fine});

  final CancellationFine? fine;

  @override
  State<_FineSheet> createState() => _FineSheetState();
}

class _FineSheetState extends State<_FineSheet> {
  bool _paying = false;
  CancellationFine? _fine;

  @override
  void initState() {
    super.initState();
    _fine = widget.fine;
    if (_fine == null) _loadFine();
  }

  Future<void> _loadFine() async {
    final standing =
        await CancellationPolicyController.instance.refresh(force: true);
    if (mounted) setState(() => _fine = standing?.fine);
  }

  Future<void> _pay() async {
    final fine = _fine;
    if (fine == null) return;
    setState(() => _paying = true);
    final paid = await payCancellationFine(context, fine);
    if (!mounted) return;
    setState(() => _paying = false);
    if (paid) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fine = _fine;
    final amount = fine == null
        ? null
        : formatMoneyAmount(fine.amount, currency: fine.currency);
    return _SheetFrame(
      icon: Icons.receipt_long_rounded,
      color: AppColors.errorColor,
      title: l10n.cpBlockedTitle,
      body: amount == null ? l10n.cpStandingFineDue : l10n.cpFineDueBody(amount),
      actions: [
        SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: fine == null || _paying ? null : _pay,
            icon: _paying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.account_balance_wallet_rounded),
            label: Text(
              l10n.cpPayFine,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ViewRecordButton(parentContext: context),
      ],
    );
  }
}

class _ViewRecordButton extends StatelessWidget {
  const _ViewRecordButton({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          final navigator = Navigator.of(parentContext);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const CancellationStandingScreen(),
            ),
          );
        },
        child: Text(context.l10n.cpViewRecord),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HomeColors.borderOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: HomeColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 20),
            ...actions,
          ],
        ),
      ),
    );
  }
}
