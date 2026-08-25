import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/handyman/data/data_provider/handyman_data_provider.dart';
import 'package:hudhud_delivery/features/handyman/data/repository/handyman_repository.dart';

class RateServiceScreen extends StatefulWidget {
  final int requestId;

  const RateServiceScreen({super.key, required this.requestId});

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  final _commentController = TextEditingController();
  final _providerCommentController = TextEditingController();

  late final HandymanRepository _repository;

  int _rating = 5;
  int? _providerRating;
  bool _isPublic = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = HandymanRepository(
      dataProvider: HandymanDataProvider(apiService: ApiService.instance),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _providerCommentController.dispose();
    super.dispose();
  }

  Color _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorder : AppColors.lightBorder;
  }

  InputDecoration _inputDecoration(BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = _cardBorder(context);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    final result = await _repository.rateServiceRequest(
      widget.requestId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      providerRating: _providerRating,
      providerComment: _providerCommentController.text.trim().isEmpty
          ? null
          : _providerCommentController.text.trim(),
      isPublic: _isPublic,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.ratingThankYou),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? l10n.ratingSubmitFailed),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Widget _starRow({
    required int rating,
    required ValueChanged<int> onChanged,
    double size = 40,
    int? toggleOffValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = toggleOffValue != null
            ? (_providerRating != null && starValue <= _providerRating!)
            : starValue <= rating;

        return IconButton(
          onPressed: () {
            if (toggleOffValue != null) {
              onChanged(_providerRating == starValue ? toggleOffValue : starValue);
            } else {
              onChanged(starValue);
            }
          },
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: AppColors.ratingFilled,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final borderColor = _cardBorder(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.handymanRateServiceTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.handymanHowWasService,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  _starRow(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  TextFormField(
                    controller: _commentController,
                    decoration: _inputDecoration(
                      context,
                      labelText: l10n.commentOptional,
                      hintText: l10n.commentExperienceHint,
                    ).copyWith(alignLabelWithHint: true),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.handymanRateTheHandyman,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceSM),
                  _starRow(
                    rating: _providerRating ?? 0,
                    size: 32,
                    toggleOffValue: 0,
                    onChanged: (value) => setState(() {
                      _providerRating = value == 0 ? null : value;
                    }),
                  ),
                  const SizedBox(height: AppColors.spaceMD),
                  TextFormField(
                    controller: _providerCommentController,
                    decoration: _inputDecoration(
                      context,
                      labelText: l10n.handymanCommentAboutOptional,
                      hintText: l10n.commentHandymanHint,
                    ).copyWith(alignLabelWithHint: true),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.spaceMD,
                vertical: AppColors.spaceSM,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v ?? true),
                    activeColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.handymanRatingPublic,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spaceLG),
            SizedBox(
              width: double.infinity,
              height: AppColors.buttonHeightMD,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        ),
                      )
                    : Text(l10n.handymanSubmitRating),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
