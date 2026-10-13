import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/courier/data/data_provider/courier_data_provider.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';
import 'package:hudhud_delivery/features/courier/presentation/theme/courier_theme.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

class RateDeliveryScreen extends StatefulWidget {
  final int deliveryId;

  const RateDeliveryScreen({super.key, required this.deliveryId});

  @override
  State<RateDeliveryScreen> createState() => _RateDeliveryScreenState();
}

class _RateDeliveryScreenState extends State<RateDeliveryScreen> {
  final _commentController = TextEditingController();
  late final CourierRepository _repository;

  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = CourierRepository(
      courierDataProvider: CourierDataProvider(
        apiService: ApiService.instance,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final result = await _repository.rateDelivery(
      deliveryId: widget.deliveryId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Thank you for your feedback!',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Could not submit rating',
        ),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  /// Face that mirrors the selected rating — readable without text.
  IconData get _moodIcon {
    switch (_rating) {
      case 1:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        return Icons.sentiment_neutral_rounded;
      case 4:
        return Icons.sentiment_satisfied_rounded;
      default:
        return Icons.sentiment_very_satisfied_rounded;
    }
  }

  Widget _starRow() {
    final emptyColor = HomeColors.isDark(context)
        ? HomeColors.borderOf(context)
        : AppColors.ratingEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = starValue <= _rating;
        return Semantics(
          button: true,
          selected: filled,
          label: '$starValue',
          child: InkResponse(
            onTap: () => setState(() => _rating = starValue),
            radius: 30,
            child: SizedBox(
              width: 56,
              height: 60,
              child: AnimatedScale(
                scale: filled ? 1.0 : 0.88,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  Icons.star_rounded,
                  size: 50,
                  color: filled ? AppColors.ratingFilled : emptyColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final inputRadius = BorderRadius.circular(16);

    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: HomeColors.backgroundOf(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 26),
            color: HomeColors.textPrimaryOf(context),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Rate delivery',
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Driver tile
                      _SurfaceCard(
                        radius: BorderRadius.circular(20),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: HomeColors.violetTintOf(context),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.delivery_dining_rounded,
                                size: 28,
                                color: HomeColors.violetOf(context),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tipsRecipientDriver,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: HomeColors.textPrimaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Delivery #${widget.deliveryId}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: HomeColors.textMutedOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Rating card
                      _SurfaceCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(12, 24, 12, 20),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                key: ValueKey<int>(_rating),
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.ratingFilled
                                      .withValues(alpha: dark ? 0.18 : 0.14),
                                ),
                                child: Icon(
                                  _moodIcon,
                                  size: 54,
                                  color: AppColors.ratingFilled,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How was your delivery?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: HomeColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _starRow(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_rating / 5',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: HomeColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commentController,
                        minLines: 3,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 16,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.commentOptional,
                          hintText: l10n.commentExperienceHint,
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 44),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: HomeColors.violetOf(context),
                            ),
                          ),
                          filled: true,
                          fillColor: HomeColors.surfaceOf(context),
                          border: OutlineInputBorder(
                            borderRadius: inputRadius,
                            borderSide: BorderSide(
                              color: HomeColors.borderOf(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: inputRadius,
                            borderSide: BorderSide(
                              color: HomeColors.borderOf(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: inputRadius,
                            borderSide: BorderSide(
                              color: HomeColors.violetOf(context),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _PrimaryButton(
                  label: 'Submit rating',
                  icon: Icons.send_rounded,
                  loading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card surface: soft shadow in light mode, 1px border in dark mode.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.radius,
    required this.padding,
  });

  final Widget child;
  final BorderRadius radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: HomeColors.surfaceOf(context),
          borderRadius: radius,
          border: dark ? Border.all(color: HomeColors.borderOf(context)) : null,
        ),
        child: child,
      ),
    );
  }
}

/// The screen's single orange call to action (56px, radius 18).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final active = onPressed != null || loading;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: active && !HomeColors.isDark(context)
            ? [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: active
              ? HomeColors.orange
              : HomeColors.orange.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
