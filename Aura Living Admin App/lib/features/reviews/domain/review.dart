enum ReviewStatus {
  pending('Pending Approval'),
  approved('Approved'),
  rejected('Rejected / Flagged');

  final String label;
  const ReviewStatus(this.label);
}

/// Customer Review Entity per PRD Section 6.6 & 8
class Review {
  final String id;
  final String productId;
  final String productTitle;
  final String productThumbnailUrl;
  final String reviewerName;
  final bool isVerifiedBuyer;
  final int rating; // 1 to 5
  final String title;
  final String body;
  final ReviewStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productThumbnailUrl,
    required this.reviewerName,
    this.isVerifiedBuyer = true,
    required this.rating,
    required this.title,
    required this.body,
    this.status = ReviewStatus.pending,
    this.rejectionReason,
    required this.createdAt,
  });

  Review copyWith({
    String? id,
    String? productId,
    String? productTitle,
    String? productThumbnailUrl,
    String? reviewerName,
    bool? isVerifiedBuyer,
    int? rating,
    String? title,
    String? body,
    ReviewStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productThumbnailUrl: productThumbnailUrl ?? this.productThumbnailUrl,
      reviewerName: reviewerName ?? this.reviewerName,
      isVerifiedBuyer: isVerifiedBuyer ?? this.isVerifiedBuyer,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
