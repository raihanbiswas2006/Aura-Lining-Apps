import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/review.dart';
import '../../../core/providers/repository_providers.dart';

final reviewStatusFilterProvider = StateProvider<ReviewStatus?>((ref) => ReviewStatus.pending);

final reviewsStreamProvider = StreamProvider<List<Review>>((ref) {
  final reviewRepo = ref.watch(reviewRepositoryProvider);
  return reviewRepo.watchReviews();
});

final filteredReviewsProvider = Provider<AsyncValue<List<Review>>>((ref) {
  final reviewsAsync = ref.watch(reviewsStreamProvider);
  final statusFilter = ref.watch(reviewStatusFilterProvider);

  return reviewsAsync.whenData((reviews) {
    if (statusFilter == null) return reviews;
    return reviews.where((r) => r.status == statusFilter).toList();
  });
});
