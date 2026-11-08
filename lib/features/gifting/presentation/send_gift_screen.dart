import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../../growth/data/models/market.dart';
import '../gift_session.dart';

/// Phase 6 diaspora gifting, step 1: explain the flow and pick the
/// recipient's city. Then the customer browses that city's restaurants and
/// checks out as usual, with the gift section switched on.
class SendGiftScreen extends StatefulWidget {
  const SendGiftScreen({super.key, required this.markets});

  /// Gift markets ([giftMarkets]); Hargeisa first.
  final List<Market> markets;

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  Market? _selected;

  @override
  void initState() {
    super.initState();
    final current = GiftSession.instance.market;
    _selected = current != null &&
            widget.markets.any((m) => m.code == current.code)
        ? widget.markets.firstWhere((m) => m.code == current.code)
        : (widget.markets.isEmpty ? null : widget.markets.first);
  }

  void _continue() {
    final market = _selected;
    if (market == null) return;
    GiftSession.instance.start(market);
    final title = context.l10n.p9GiftModeBanner(market.name);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AllCategoriesScreen(
          discoveryLatitude: market.defaultLat,
          discoveryLongitude: market.defaultLng,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ink = HomeColors.textPrimaryOf(context);
    final secondary = HomeColors.textSecondaryOf(context);
    return Scaffold(
      backgroundColor: HomeColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(l10n.p9GiftSendTitle),
        backgroundColor: HomeColors.surfaceOf(context),
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.orangeTint,
                child: Icon(
                  Icons.card_giftcard_rounded,
                  size: 38,
                  color: AppColors.brandOrange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.p9GiftIntroBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.45, color: secondary),
            ),
            const SizedBox(height: 20),
            _Step(icon: Icons.sms_outlined, text: l10n.p9GiftHowItWorksSms),
            const SizedBox(height: 10),
            _Step(
              icon: Icons.credit_card_rounded,
              text: l10n.p9GiftHowItWorksPay,
            ),
            const SizedBox(height: 28),
            Text(
              l10n.p9GiftChooseMarket,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final market in widget.markets)
                  ChoiceChip(
                    key: ValueKey('gift-market-${market.code}'),
                    label: Text(market.name),
                    selected: _selected?.code == market.code,
                    onSelected: (_) => setState(() => _selected = market),
                    selectedColor: AppColors.brandOrange.withValues(alpha: 0.18),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _selected == null ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.restaurant_rounded),
                label: Text(l10n.p9GiftChooseRestaurant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.brandOrange, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
