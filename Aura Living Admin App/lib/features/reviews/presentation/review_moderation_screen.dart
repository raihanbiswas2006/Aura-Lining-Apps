import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/review.dart';
import 'reviews_controller.dart';
import '../../auth/presentation/auth_controller.dart';

class ReviewModerationScreen extends ConsumerStatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  ConsumerState<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends ConsumerState<ReviewModerationScreen> {
  final List<String> _rejectionReasons = const [
    'Inappropriate Language',
    'Spam or Promotional',
    'Irrelevant to Product',
    'Unverified Claim / Competitor Sabotage',
    'Privacy / Personal Information',
  ];

  Future<void> _approveReview(Review review) async {
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.approveReview(review.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review by "${review.reviewerName}" approved.'),
            backgroundColor: AppColors.primaryOlive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showRejectReasonSheet(Review review) {
    String selectedReason = _rejectionReasons.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Rejection Reason', style: AppTypography.sectionHeader),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Rejecting will hide this review from customer platforms.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: InputDecoration(
                    labelText: 'Moderation Reason',
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: _rejectionReasons.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() => selectedReason = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Confirm Rejection',
                  variant: ButtonVariant.destructive,
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final repo = ref.read(reviewRepositoryProvider);
                      await repo.rejectReview(review.id, selectedReason);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Review rejected: $selectedReason'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDestructiveConfirmDialog(
      context: context,
      title: 'Permanently Delete Review?',
      consequenceText:
          'This action cannot be undone and will permanently remove this customer feedback from the database.',
      confirmButtonText: 'Delete Forever',
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(reviewRepositoryProvider);
        await repo.deleteReview(review.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review permanently deleted.'),
              backgroundColor: AppColors.primaryOlive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(reviewStatusFilterProvider);
    final reviewsAsync = ref.watch(filteredReviewsProvider);
    final user = ref.watch(authControllerProvider).user;
    final canModerate = user?.role.canModerateReviews ?? false;

    return Column(
      children: [
        // Status filter chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _filterChip('Pending', ReviewStatus.pending, currentFilter),
              const SizedBox(width: 8),
              _filterChip('Approved', ReviewStatus.approved, currentFilter),
              const SizedBox(width: 8),
              _filterChip('Rejected', ReviewStatus.rejected, currentFilter),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Reviews list
        Expanded(
          child: reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return EmptyStateView(
                  title: 'No ${currentFilter?.label ?? "Reviews"} in Queue',
                  subtitle: currentFilter == ReviewStatus.pending
                      ? 'All incoming customer reviews have been moderated.'
                      : 'No reviews found under this moderation status.',
                  icon: Icons.rate_review_outlined,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _ReviewCard(
                    review: review,
                    canModerate: canModerate,
                    onApprove: () => _approveReview(review),
                    onReject: () => _showRejectReasonSheet(review),
                    onDelete: () => _deleteReview(review),
                  );
                },
              );
            },
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const ShimmerCard(height: 180),
            ),
            error: (err, stack) => Center(
              child: Text('Error loading reviews: $err'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, ReviewStatus status, ReviewStatus? current) {
    final isSelected = current == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryOlive,
      backgroundColor: AppColors.surfaceSecondary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(color: isSelected ? AppColors.primaryOlive : AppColors.border),
      onSelected: (selected) {
        if (selected) {
          ref.read(reviewStatusFilterProvider.notifier).state = status;
        }
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool canModerate;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.canModerate,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 36,
                  height: 36,
                  color: AppColors.surfaceSecondary,
                  child: Image.network(
                    review.productThumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 16, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: const Color(0xFFF59E0B),
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '${review.rating}/5',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canModerate)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete Permanently', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Reviewer Info
          Row(
            children: [
              Text(
                review.reviewerName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (review.isVerifiedBuyer) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 10, color: AppColors.success),
                      SizedBox(width: 2),
                      Text('Verified Buyer', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                AppFormatters.formatRelativeTime(review.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title & Body
          Text(
            review.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            review.body,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),

          // Rejection reason banner if rejected
          if (review.status == ReviewStatus.rejected && review.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    'Rejection Reason: ${review.rejectionReason}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ],

          // Actions if canModerate & in pending state
          if (canModerate && review.status == ReviewStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onReject,
                    child: const Text(
                      'Reject / Hide',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: AppColors.primaryOlive,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onApprove,
                    child: const Text(
                      'Approve Review',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
