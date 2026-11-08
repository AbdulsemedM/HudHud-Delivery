import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import '../../data/growth_repository.dart';
import '../../data/models/rewards_summary.dart';

/// Points balance, value, how-it-works and history
/// (`GET /api/customer/rewards/summary`).
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key, this.repository});

  final GrowthRepository? repository;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final GrowthRepository _repo =
      widget.repository ?? GrowthRepository.create();
  RewardsSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _repo.fetchRewardsSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProfilePage(
      title: l10n.growthRewardsTitle,
      body: RefreshIndicator(
        color: AuthScreenColors.orange,
        onRefresh: _load,
        child: _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading && _summary == null) {
      return const Center(
        child: CircularProgressIndicator(color: AuthScreenColors.orange),
      );
    }
    final summary = _summary;
    if (summary == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.stars_rounded,
            size: 56,
            color: AuthScreenColors.textMutedOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? l10n.growthRewardsLoadError,
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _BalanceCard(summary: summary),
        const SizedBox(height: 16),
        _HowItWorksCard(summary: summary),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            l10n.growthRewardsHistory.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AuthScreenColors.textMutedOf(context),
            ),
          ),
        ),
        if (summary.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.growthRewardsHistoryEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AuthScreenColors.textMutedOf(context),
              ),
            ),
          )
        else
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < summary.history.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AuthScreenColors.surfaceBorderOf(context),
                    ),
                  _HistoryTile(entry: summary.history[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    final radius = BorderRadius.circular(20);
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
        child: child,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final RewardsSummary summary;

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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.growthPointsCount(summary.points),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.growthRewardsWorth(formatEtbAmount(summary.value)),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.summary});

  final RewardsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.growthRewardsHowItWorks,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AuthScreenColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            line(Icons.shopping_bag_rounded, l10n.growthRewardsEarnLine),
            line(
              Icons.swap_horiz_rounded,
              l10n.growthRewardsRateLine(
                summary.redeemPoints,
                formatEtbAmount(summary.redeemValue),
              ),
            ),
            line(
              Icons.local_shipping_rounded,
              l10n.growthRewardsUseLine(summary.minRedeemPoints),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final RewardsHistoryEntry entry;

  String _typeLabel(AppLocalizations l10n) {
    switch (entry.type) {
      case 'redeemed':
        return l10n.growthRewardsTypeRedeemed;
      case 'restored':
        return l10n.growthRewardsTypeRestored;
      case 'expired':
        return l10n.growthRewardsTypeExpired;
      default:
        return l10n.growthRewardsTypeEarned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final debit = entry.isDebit;
    final color = debit ? AppColors.errorColor : AppColors.successColor;
    final created = entry.createdAt;
    final subtitle = [
      if (entry.note != null) entry.note!,
      if (created != null)
        DateFormat('dd MMM yyyy').format(created.toLocal()),
    ].join(' · ');
    return ListTile(
      minVerticalPadding: 12,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          debit ? Icons.remove_rounded : Icons.add_rounded,
          color: color,
        ),
      ),
      title: Text(
        _typeLabel(l10n),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AuthScreenColors.textPrimaryOf(context),
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AuthScreenColors.textMutedOf(context)),
            ),
      trailing: Text(
        '${debit ? '−' : '+'}${entry.points}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
