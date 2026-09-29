import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/i_product_repository.dart';
import 'widgets/write_review_sheet.dart';

class ProductReviewsScreen extends StatefulWidget {
  final Product product;

  const ProductReviewsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  late Future<List<Review>> _reviewsFuture;
  int? _selectedStarFilter; // null = all

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = getIt<IProductRepository>().getProductReviews(widget.product.id);
  }

  void _openWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WriteReviewSheet(
        productId: widget.product.id,
        onReviewSubmitted: (newReview) async {
          await getIt<IProductRepository>().addReview(newReview);
          setState(() {
            _loadReviews();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
      ),
      body: FutureBuilder<List<Review>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          final allReviews = snapshot.data ?? [];
          final displayReviews = _selectedStarFilter == null
              ? allReviews
              : allReviews.where((r) => r.rating.toInt() == _selectedStarFilter).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary and Distribution
              _buildRatingSummary(allReviews),
              const SizedBox(height: 24),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${allReviews.length})', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('5 ★', 5),
                    const SizedBox(width: 8),
                    _buildFilterChip('4 ★', 4),
                    const SizedBox(width: 8),
                    _buildFilterChip('3 ★', 3),
                    const SizedBox(width: 8),
                    _buildFilterChip('2 ★', 2),
                    const SizedBox(width: 8),
                    _buildFilterChip('1 ★', 1),
                  ],
                ),
              ),
              const Divider(height: 32),

              // Reviews List
              if (displayReviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No reviews matching this star rating yet.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                )
              else
                ...displayReviews.map((review) => _buildReviewItem(review)),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ElevatedButton(
            onPressed: _openWriteReviewSheet,
            child: const Text('Write a Review'),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummary(List<Review> reviews) {
    final avgRating = reviews.isEmpty
        ? widget.product.rating
        : reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Big number & stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: AppTypography.displayLarge.copyWith(fontSize: 42),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < avgRating.floor()
                        ? Icons.star
                        : (index < avgRating ? Icons.star_half : Icons.star_border),
                    color: AppColors.gold,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on ${reviews.length} reviews',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Rating distribution bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = reviews.where((r) => r.rating.toInt() == star).length;
                final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text('$star', style: AppTypography.bodySmall),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? star) {
    final isSelected = _selectedStarFilter == star;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (_) {
        setState(() {
          _selectedStarFilter = isSelected ? null : star;
        });
      },
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName,
                    style: AppTypography.titleSmall.copyWith(fontSize: 14),
                  ),
                  if (review.verifiedPurchase)
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 13,
                          color: AppColors.accentOlive,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Owner',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.accentOlive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${review.date.day}/${review.date.month}/${review.date.year}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              Text(
                'Helpful (${review.helpfulCount})',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
