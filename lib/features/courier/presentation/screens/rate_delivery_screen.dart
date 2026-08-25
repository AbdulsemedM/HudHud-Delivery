import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
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

  Widget _starRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = starValue <= _rating;
        return IconButton(
          onPressed: () => setState(() => _rating = starValue),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 40,
            color: AppColors.ratingFilled,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CourierTheme.wrap(
      context,
      child: Scaffold(
        backgroundColor: HomeColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: HomeColors.surfaceOf(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: HomeColors.textPrimaryOf(context),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Rate delivery',
            style: TextStyle(
              color: HomeColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppColors.spaceMD),
                decoration: BoxDecoration(
                  color: HomeColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                  border: Border.all(color: HomeColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your delivery?',
                      style: TextStyle(
                        color: HomeColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Delivery #${widget.deliveryId}',
                      style: TextStyle(
                        color: HomeColors.textSecondaryOf(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _starRow(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Comment (optional)',
                        filled: true,
                        fillColor: HomeColors.surfaceElevatedOf(context),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusLG),
                          borderSide: BorderSide(color: HomeColors.borderOf(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusLG),
                          borderSide: BorderSide(color: HomeColors.borderOf(context)),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spaceLG),
              SizedBox(
                height: AppColors.buttonHeightMD,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: HomeColors.violet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit rating',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
