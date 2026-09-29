import 'dart:async';
import '../domain/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviews({ReviewStatus? statusFilter});
  Future<Review> approveReview(String reviewId);
  Future<Review> rejectReview(String reviewId, String reason);
  Future<bool> deleteReview(String reviewId);
  Stream<List<Review>> watchReviews();
}

class MockReviewRepository implements ReviewRepository {
  final _reviewsStream = StreamController<List<Review>>.broadcast();
  late List<Review> _reviews;

  MockReviewRepository() {
    _seedReviews();
  }

  void _seedReviews() {
    final now = DateTime.now();

    _reviews = [
      Review(
        id: 'rev-01',
        productId: 'prod-01',
        productTitle: 'Nordic Minimalist Oak Chair',
        productThumbnailUrl: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&w=200&q=80',
        reviewerName: 'Klara Blom',
        isVerifiedBuyer: true,
        rating: 5,
        title: 'Exquisite craftsmanship & quiet beauty',
        body: 'The natural oak grain is stunning in our dining room. Incredibly comfortable even during long dinners. Packaged flawlessly.',
        status: ReviewStatus.pending,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      Review(
        id: 'rev-02',
        productId: 'prod-02',
        productTitle: 'Kanso Ceramic Ribbed Vase',
        productThumbnailUrl: 'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=200&q=80',
        reviewerName: 'Felix Berger',
        isVerifiedBuyer: true,
        rating: 4,
        title: 'Subtle textural aesthetic',
        body: 'The ribbed details catch morning light in a very calming way. Slightly smaller than envisioned but heavy and high quality.',
        status: ReviewStatus.pending,
        createdAt: now.subtract(const Duration(hours: 14)),
      ),
      Review(
        id: 'rev-03',
        productId: 'prod-04',
        productTitle: 'Linen Slumber Duvet Set',
        productThumbnailUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=200&q=80',
        reviewerName: 'Astrid E.',
        isVerifiedBuyer: true,
        rating: 5,
        title: 'Unbelievably soft linen',
        body: 'We replaced our Egyptian cotton with this set and will never go back. Gets softer with each wash.',
        status: ReviewStatus.approved,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Review(
        id: 'rev-04',
        productId: 'prod-06',
        productTitle: 'Cedar & Hinoki Scented Candle',
        productThumbnailUrl: 'https://images.unsplash.com/photo-1603006905003-be475563bc59?auto=format&fit=crop&w=200&q=80',
        reviewerName: 'Anonymous Troll',
        isVerifiedBuyer: false,
        rating: 1,
        title: 'Buy cheap shoes at discount-deals.biz!!',
        body: 'Check out our website for guaranteed replica sneakers fast shipping 50% off today only.',
        status: ReviewStatus.rejected,
        rejectionReason: 'Spam',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void _notify() {
    _reviewsStream.add(List.unmodifiable(_reviews));
  }

  @override
  Stream<List<Review>> watchReviews() {
    return _reviewsStream.stream;
  }

  @override
  Future<List<Review>> getReviews({ReviewStatus? statusFilter}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (statusFilter == null) return List.unmodifiable(_reviews);
    return _reviews.where((r) => r.status == statusFilter).toList();
  }

  @override
  Future<Review> approveReview(String reviewId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx == -1) throw Exception('Review not found');

    final updated = _reviews[idx].copyWith(
      status: ReviewStatus.approved,
      rejectionReason: null,
    );
    _reviews[idx] = updated;
    _notify();
    return updated;
  }

  @override
  Future<Review> rejectReview(String reviewId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx == -1) throw Exception('Review not found');

    final updated = _reviews[idx].copyWith(
      status: ReviewStatus.rejected,
      rejectionReason: reason,
    );
    _reviews[idx] = updated;
    _notify();
    return updated;
  }

  @override
  Future<bool> deleteReview(String reviewId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx == -1) return false;
    _reviews.removeAt(idx);
    _notify();
    return true;
  }
}
