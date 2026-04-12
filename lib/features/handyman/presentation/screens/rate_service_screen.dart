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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.handymanRateServiceTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: theme.colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.dividerColor.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.handymanHowWasService,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starValue),
                  icon: Icon(
                    starValue <= _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: AppColors.ratingFilled,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: l10n.commentOptional,
                hintText: l10n.commentExperienceHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.handymanRateTheHandyman,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () => setState(() {
                    _providerRating = _providerRating == starValue ? null : starValue;
                  }),
                  icon: Icon(
                    _providerRating != null && starValue <= _providerRating!
                        ? Icons.star
                        : Icons.star_border,
                    size: 32,
                    color: AppColors.ratingFilled,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _providerCommentController,
              decoration: InputDecoration(
                labelText: l10n.handymanCommentAboutOptional,
                hintText: l10n.commentHandymanHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v ?? true),
                  activeColor: AppColors.primaryColor,
                ),
                Expanded(
                  child: Text(
                    l10n.handymanRatingPublic,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
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
