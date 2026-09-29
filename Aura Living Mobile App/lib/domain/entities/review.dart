class Review {
  final String id;
  final String productId;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime date;
  final bool verifiedPurchase;
  final int helpfulCount;
  final List<String> mediaUrls;

  const Review({
    required this.id,
    required this.productId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
    this.verifiedPurchase = true,
    this.helpfulCount = 0,
    this.mediaUrls = const [],
  });

  Review copyWith({
    String? id,
    String? productId,
    String? authorName,
    double? rating,
    String? comment,
    DateTime? date,
    bool? verifiedPurchase,
    int? helpfulCount,
    List<String>? mediaUrls,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      authorName: authorName ?? this.authorName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      verifiedPurchase: verifiedPurchase ?? this.verifiedPurchase,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'authorName': authorName,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
      'verifiedPurchase': verifiedPurchase,
      'helpfulCount': helpfulCount,
      'mediaUrls': mediaUrls,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      productId: json['productId'] as String,
      authorName: json['authorName'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      date: DateTime.parse(json['date'] as String),
      verifiedPurchase: json['verifiedPurchase'] as bool? ?? true,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      mediaUrls: json['mediaUrls'] != null
          ? List<String>.from(json['mediaUrls'] as List)
          : const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
