import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../../checkout/data/data_provider/checkout_data_provider.dart';
import '../gift_phone.dart';

/// Home entry for diaspora gifting ("Send a gift").
class GiftEntryBanner extends StatelessWidget {
  const GiftEntryBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.p9GiftSendTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.p9GiftBannerSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: HomeColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: HomeColors.textMutedOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sending a gift to Hargeisa" strip shown at the top of checkout.
class GiftModeBanner extends StatelessWidget {
  const GiftModeBanner({
    super.key,
    required this.marketName,
    required this.onStop,
  });

  final String marketName;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.brandOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.brandOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.p9GiftModeBanner(marketName),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
          TextButton(onPressed: onStop, child: Text(l10n.p9GiftStop)),
        ],
      ),
    );
  }
}

/// Recipient name / phone / optional message for a gift order.
///
/// Controllers belong to the caller (checkout) so the values survive
/// rebuilds; [phonePlan] drives the dial prefix, hint and validation.
class GiftRecipientForm extends StatelessWidget {
  const GiftRecipientForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.messageController,
    required this.phonePlan,
    this.nameError,
    this.phoneError,
    this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final GiftPhonePlan phonePlan;
  final String? nameError;
  final String? phoneError;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = HomeColors.textMutedOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('gift-recipient-name'),
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          maxLength: CheckoutDataProvider.giftRecipientNameMaxLength,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            labelText: l10n.p9GiftRecipientName,
            errorText: nameError,
            counterText: '',
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('gift-recipient-phone'),
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            labelText: l10n.p9GiftRecipientPhone,
            hintText: l10n.p9GiftRecipientPhoneHint(phonePlan.exampleNational),
            errorText: phoneError,
            prefixIcon: const Icon(Icons.phone_iphone_rounded),
            prefixText: '${phonePlan.dialPrefix} ',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('gift-message'),
          controller: messageController,
          minLines: 2,
          maxLines: 4,
          maxLength: CheckoutDataProvider.giftMessageMaxLength,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            labelText: l10n.p9GiftMessageLabel,
            hintText: l10n.p9GiftMessageHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 4),
        _GiftNote(icon: Icons.sms_outlined, text: l10n.p9GiftHowItWorksSms),
        const SizedBox(height: 6),
        _GiftNote(
          icon: Icons.location_on_outlined,
          text: l10n.p9GiftAddressHint,
        ),
        const SizedBox(height: 6),
        _GiftNote(
          icon: Icons.money_off_rounded,
          text: l10n.p9GiftHowItWorksPay,
          color: muted,
        ),
      ],
    );
  }
}

class _GiftNote extends StatelessWidget {
  const _GiftNote({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? HomeColors.textSecondaryOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, height: 1.35, color: c),
          ),
        ),
      ],
    );
  }
}

/// Shown above the payment result after a gift order: explains the SMS
/// with the tracking link and the 4-digit delivery code.
class GiftPlacedBanner extends StatelessWidget {
  const GiftPlacedBanner({super.key, required this.recipientName});

  final String recipientName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.brandOrange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.p9GiftPlacedTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.p9GiftPlacedBody(recipientName),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: HomeColors.textSecondaryOf(context),
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

/// Small "Gift for Amina" label for order lists and headers.
class GiftForLabel extends StatelessWidget {
  const GiftForLabel({super.key, required this.name, this.color});

  final String name;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandOrange;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.card_giftcard_rounded, size: 14, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.p9GiftForName(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ),
      ],
    );
  }
}
