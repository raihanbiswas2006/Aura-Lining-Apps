import '../../../domain/entities/review.dart';

final List<Review> mockReviews = [
  Review(
    id: 'rev-001',
    productId: 'prod-001',
    authorName: 'Elena Rostova',
    rating: 5.0,
    comment:
        'The bouclé texture is exquisite and the oak joinery is flawless. It anchors our living room with calm architectural elegance. Shipping was seamless and packaging was completely recyclable.',
    date: DateTime(2026, 9, 12),
    verifiedPurchase: true,
    helpfulCount: 14,
  ),
  Review(
    id: 'rev-002',
    productId: 'prod-001',
    authorName: 'Marcus Vance',
    rating: 5.0,
    comment:
        'Substantial weight and incredible ergonomics. The proportions feel tailored. Definitely worth the investment.',
    date: DateTime(2026, 9, 02),
    verifiedPurchase: true,
    helpfulCount: 8,
  ),
  Review(
    id: 'rev-003',
    productId: 'prod-001',
    authorName: 'Sofia Lindqvist',
    rating: 4.0,
    comment:
        'Stunning chair. Bouclé takes gentle grooming if you have pets, but the aesthetic is unmatched.',
    date: DateTime(2026, 8, 22),
    verifiedPurchase: true,
    helpfulCount: 5,
  ),
  Review(
    id: 'rev-004',
    productId: 'prod-002',
    authorName: 'Liam Chen',
    rating: 5.0,
    comment:
        'The diffuse warm glow transformed our evening routine. Assembly took less than 3 minutes.',
    date: DateTime(2026, 9, 10),
    verifiedPurchase: true,
    helpfulCount: 9,
  ),
  Review(
    id: 'rev-005',
    productId: 'prod-003',
    authorName: 'Amara Davies',
    rating: 5.0,
    comment:
        'Pure luxury. The French flax is soft right out of the box and gets even better after the first wash.',
    date: DateTime(2026, 9, 18),
    verifiedPurchase: true,
    helpfulCount: 12,
  ),
  Review(
    id: 'rev-006',
    productId: 'prod-004',
    authorName: 'David K.',
    rating: 5.0,
    comment:
        'The raw ash finish has wonderful wabi-sabi character. Perfect pedestal for dried stems.',
    date: DateTime(2026, 8, 14),
    verifiedPurchase: true,
    helpfulCount: 3,
  ),
];
