import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/wallet/presentation/screens/wallet_topup_page.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import '../../data/growth_repository.dart';
import '../../data/models/plus.dart';
import '../../plus_controller.dart';
import '../widgets/plus_widgets.dart';

/// HudHud Plus: benefits, price, subscribe / cancel / resume
/// (`/api/customer/plus*`, Phase 3 §5).
class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key, this.repository});

  final GrowthRepository? repository;

  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  late final GrowthRepository _repo =
      widget.repository ?? GrowthRepository.create();
  PlusStatus _status = PlusController.instance.status;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await PlusController.instance.refresh(force: true);
    if (!mounted) return;
    setState(() {
      _status = PlusController.instance.status;
      _loading = false;
    });
  }

  String _money(double amount) =>
      formatMoneyAmount(amount, currency: _status.currency);

  String _date(DateTime d) => DateFormat('dd MMM yyyy').format(d.toLocal());

  Future<void> _subscribe() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _repo.subscribePlus();
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    if (result.ok) {
      AuthSnackBar.success(context, l10n.p3PlusSubscribed);
      await _load();
      return;
    }
    if (result.isInsufficientFunds) {
      await _offerTopUp(result.insufficientFunds);
      return;
    }
    AuthSnackBar.error(context, result.message ?? l10n.p3PlusActionFailed);
    if (result.code == 'FEATURE_DISABLED') await _load();
  }

  Future<void> _offerTopUp(PlusInsufficientFunds? funds) async {
    final l10n = context.l10n;
    final shortfall = funds?.shortfall ?? 0;
    final amount = shortfall > 0 ? shortfall : _status.price;
    final topUp = await AuthModal.confirm(
      context: context,
      title: l10n.p3PlusInsufficientTitle,
      message: l10n.p3PlusInsufficientMessage(_money(amount)),
      confirmLabel: l10n.p3PlusTopUp,
      cancelLabel: l10n.actionCancel,
    );
    if (topUp != true || !mounted) return;
    final funded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WalletTopUpPage(
          defaultCurrency: funds?.currency ?? _status.currency,
          initialAmount: amount > 0 ? amount : null,
        ),
      ),
    );
    if (!mounted) return;
    if (funded == true) await _load();
  }

  Future<void> _cancel() async {
    if (_busy) return;
    final l10n = context.l10n;
    final confirmed = await AuthModal.confirm(
      context: context,
      title: l10n.p3PlusCancelConfirmTitle,
      message: l10n.p3PlusCancelConfirmMessage,
      confirmLabel: l10n.p3PlusCancel,
      cancelLabel: l10n.actionCancel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await _runAction(_repo.cancelPlus, l10n.p3PlusCancelled);
  }

  Future<void> _resume() async {
    if (_busy) return;
    await _runAction(_repo.resumePlus, context.l10n.p3PlusResumed);
  }

  Future<void> _runAction(
    Future<PlusActionResult> Function() call,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    final result = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) {
      AuthSnackBar.success(context, successMessage);
    } else {
      AuthSnackBar.error(
        context,
        result.message ?? context.l10n.p3PlusActionFailed,
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProfilePage(
      title: l10n.p3PlusTitle,
      body: RefreshIndicator(
        color: AuthScreenColors.orange,
        onRefresh: _load,
        child: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading && !_status.loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AuthScreenColors.orange),
      );
    }
    if (!_status.available) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.workspace_premium_rounded,
            size: 56,
            color: AuthScreenColors.textMutedOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            _status.loaded ? l10n.p3PlusUnavailable : l10n.p3PlusLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AuthScreenColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.actionRetry),
            ),
          ),
        ],
      );
    }

    final status = _status;
    final sub = status.subscription;
    final member = status.isMember;
    final subPrice = sub == null ? 0.0 : sub.price;
    final price = subPrice > 0 ? subPrice : status.price;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeroCard(
          status: status,
          priceLabel: l10n.p3PlusPricePerPeriod(
            _money(price),
            status.periodDays,
          ),
          statusLine: _statusLine(l10n, sub),
        ),
        if (sub != null && sub.isPastDue) ...[
          const SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.error_outline_rounded,
            color: AppColors.errorColor,
            text: l10n.p3PlusPastDue,
          ),
        ],
        if (member && status.estimatedSavingsLast30d > 0.009) ...[
          const SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.savings_rounded,
            color: AppColors.successColor,
            text: l10n.p3PlusSavings(_money(status.estimatedSavingsLast30d)),
          ),
        ],
        const SizedBox(height: 16),
        _BenefitsCard(
          status: status,
          minBasketLabel: _money(status.freeDeliveryMinBasket),
        ),
        const SizedBox(height: 24),
        _actionButton(l10n, sub),
        const SizedBox(height: 10),
        Text(
          l10n.p3PlusPaidFromWallet,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AuthScreenColors.textMutedOf(context),
          ),
        ),
      ],
    );
  }

  String? _statusLine(AppLocalizations l10n, PlusSubscription? sub) {
    if (sub == null) return null;
    final end = sub.currentPeriodEnd;
    if (sub.isActive) {
      if (end == null) return l10n.p3PlusActive;
      return sub.cancelAtPeriodEnd
          ? l10n.p3PlusEndsOn(_date(end))
          : l10n.p3PlusRenewsOn(_date(end));
    }
    return null;
  }

  Widget _actionButton(AppLocalizations l10n, PlusSubscription? sub) {
    final Widget child = _busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : Text(
            sub != null && sub.canCancel
                ? l10n.p3PlusCancel
                : sub != null && sub.canResume
                    ? l10n.p3PlusResume
                    : l10n.p3PlusSubscribe,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          );

    final VoidCallback? onPressed;
    if (_busy) {
      onPressed = null;
    } else if (sub != null && sub.canCancel) {
      onPressed = _cancel;
    } else if (sub != null && sub.canResume) {
      onPressed = _resume;
    } else {
      onPressed = _subscribe;
    }

    if (sub != null && sub.canCancel) {
      return SizedBox(
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorColor,
            side: const BorderSide(color: AppColors.errorColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.errorColor,
                  ),
                )
              : child,
        ),
      );
    }
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.status,
    required this.priceLabel,
    required this.statusLine,
  });

  final PlusStatus status;
  final String priceLabel;
  final String? statusLine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandHeroGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.p3PlusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (status.isMember) const PlusBadge(onDark: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.p3PlusTagline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            priceLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (statusLine != null) ...[
            const SizedBox(height: 4),
            Text(
              statusLine!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.status, required this.minBasketLabel});

  final PlusStatus status;
  final String minBasketLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = AuthScreenColors.isDark(context);
    final radius = BorderRadius.circular(20);
    final textColor = AuthScreenColors.textSecondaryOf(context);
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: AuthScreenColors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
    final percent = status.parcelDiscountPercent;
    final percentLabel = percent == percent.roundToDouble()
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: AuthScreenColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: AuthScreenColors.surfaceBorderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.p3PlusBenefitsTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AuthScreenColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
              line(
                Icons.local_shipping_rounded,
                status.freeDeliveryMinBasket > 0.009
                    ? l10n.p3PlusBenefitFreeDelivery(minBasketLabel)
                    : l10n.p3PlusBenefitFreeDeliveryAll,
              ),
              if (percent > 0)
                line(
                  Icons.inventory_2_rounded,
                  l10n.p3PlusBenefitParcelDiscount(percentLabel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
