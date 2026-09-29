import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../../core/widgets/aura_text_field.dart';
import '../../../../domain/entities/review.dart';

class WriteReviewSheet extends StatefulWidget {
  final String productId;
  final void Function(Review newReview) onReviewSubmitted;

  const WriteReviewSheet({
    super.key,
    required this.productId,
    required this.onReviewSubmitted,
  });

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final review = Review(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.productId,
      authorName: _nameController.text.trim(),
      rating: _selectedRating,
      comment: _commentController.text.trim(),
      date: DateTime.now(),
      verifiedPurchase: true,
      helpfulCount: 0,
    );

    widget.onReviewSubmitted(review);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your review has been published.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Share Your Experience', style: AppTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rating Stars
              Text('OVERALL RATING', style: AppTypography.overline),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    padding: const EdgeInsets.only(right: 6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      starVal <= _selectedRating ? Icons.star : Icons.star_border,
                      color: AppColors.gold,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starVal;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Name Field
              AuraTextField(
                label: 'YOUR NAME',
                hintText: 'e.g. Elena R.',
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Comment Field
              AuraTextField(
                label: 'REVIEW',
                hintText: 'Describe material quality, feel, assembly, and proportions...',
                controller: _commentController,
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please write at least a few words';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              AuraPrimaryButton(
                label: 'Submit Review',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
