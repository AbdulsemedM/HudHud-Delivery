import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
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
          content: Text(result['message'] as String? ?? 'Thank you for your rating!'),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Failed to submit rating'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Rate Service',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.lightTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.lightBorder.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was the service?',
              style: TextStyle(
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
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Rate the handyman',
              style: TextStyle(
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
              decoration: const InputDecoration(
                labelText: 'Comment about handyman (optional)',
                hintText: 'e.g. Very professional and courteous',
                border: OutlineInputBorder(),
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
                const Expanded(
                  child: Text(
                    'Make my rating public',
                    style: TextStyle(fontSize: 14),
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
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
