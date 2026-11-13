import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/localized_date.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../cancellation_policy_controller.dart';
import '../data/cancellation_models.dart';
import 'cancellation_block_sheet.dart';
import 'cancellation_widgets.dart';

/// Profile → "Cancellation record": points, thresholds, fine, pause, rules.
class CancellationStandingScreen extends StatefulWidget {
  const CancellationStandingScreen({super.key});

  @override
  State<CancellationStandingScreen> createState() =>
      _CancellationStandingScreenState();
}

class _CancellationStandingScreenState
    extends State<CancellationStandingScreen> {
  final _controller = CancellationPolicyController.instance;
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _reload();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    await _controller.refresh(force: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _payFine(CancellationFine fine) async {
    setState(() => _paying = true);
    await payCancellationFine(context, fine);
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final standing = _controller.standing ?? CancellationStanding.disabled;
    return Scaffold(
      backgroundColor: HomeColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(l10n.cpStandingTitle),
        backgroundColor: HomeColors.backgroundOf(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading && _controller.standing == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _StatusCard(standing: standing),
                  if (standing.fine != null) ...[
                    const SizedBox(height: 14),
                    _FineCard(
                      fine: standing.fine!,
                      paying: _paying,
                      onPay: () => _payFine(standing.fine!),
                    ),
                  ],
                  if (standing.isSuspended) ...[
                    const SizedBox(height: 14),
                    _InfoCard(
                      icon: Icons.block_rounded,
                      color: AppColors.errorColor,
                      text: standing.suspendedUntil == null
                          ? l10n.cpSuspendedBodyNoDate
                          : l10n.cpSuspendedBody(
                              context.formatDateTime(standing.suspendedUntil),
                            ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    l10n.cpHowItWorks,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RuleRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.successColor,
                    text: l10n.cpRuleFree,
                  ),
                  _RuleRow(
                    icon: Icons.add_circle_rounded,
                    color: AppColors.warningColor,
                    text: l10n.cpStandingExplainer(
                      standing.pointsPerLateCancel,
                    ),
                  ),
                  _RuleRow(
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.errorColor,
                    text: l10n.cpWarnFineAt(standing.fineThreshold),
                  ),
                  _RuleRow(
                    icon: Icons.block_rounded,
                    color: AppColors.errorColor,
                    text: l10n.cpWarnBanAt(standing.banThreshold),
                  ),
                  _RuleRow(
                    icon: Icons.hourglass_bottom_rounded,
                    color: AppColors.infoColor,
                    text: l10n.cpPointsExpire(standing.decayDays),
                  ),
                  _RuleRow(
                    icon: Icons.inventory_2_rounded,
                    color: HomeColors.textMutedOf(context),
                    text: l10n.cpRuleNoCancelAfterPickup,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.standing});

  final CancellationStanding standing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = cancellationStatusColor(standing.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  cancellationStatusIcon(standing.status),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cancellationStatusTitle(context, standing.status),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CancellationPointsMeter(
            points: standing.points,
            fineThreshold: standing.fineThreshold,
            banThreshold: standing.banThreshold,
          ),
          if (standing.nextDecayAt != null && standing.nextDecayPoints > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 18,
                  color: HomeColors.textMutedOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.cpNextExpiry(
                      standing.nextDecayPoints,
                      context.formatDateTime(standing.nextDecayAt),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: HomeColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FineCard extends StatelessWidget {
  const _FineCard({
    required this.fine,
    required this.paying,
    required this.onPay,
  });

  final CancellationFine fine;
  final bool paying;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.cpFineDueBody(
              formatMoneyAmount(fine.amount, currency: fine.currency),
            ),
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: paying ? null : onPay,
              icon: paying
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
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.4,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: HomeColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
