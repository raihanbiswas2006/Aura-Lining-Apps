import 'product_variant.dart';

/// Core Product Entity per PRD Section 8
class Product {
  final String id;
  final String title;
  final String slug;
  final String categoryId;
  final String shortDescription;
  final String description;
  final double basePrice;
  final double discountPercentage;
  final List<String> imageUrls;
  final bool hasVariants;
  final List<ProductVariant> variants;
  final int stockQuantity; // Used if hasVariants == false
  final String status; // 'Active' | 'Draft' | 'Archived'
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.title,
    required this.slug,
    required this.categoryId,
    this.shortDescription = '',
    required this.description,
    required this.basePrice,
    this.discountPercentage = 0.0,
    required this.imageUrls,
    this.hasVariants = false,
    this.variants = const [],
    this.stockQuantity = 0,
    this.status = 'Active',
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed discounted price
  double get finalPrice => basePrice * (1 - (discountPercentage / 100));

  /// Aggregated stock count
  int get totalStock {
    if (hasVariants && variants.isNotEmpty) {
      return variants.fold(0, (sum, v) => sum + v.stockQuantity);
    }
    return stockQuantity;
  }

  bool get isLowStock => totalStock > 0 && totalStock <= 5;
  bool get isOutOfStock => totalStock == 0;
  bool get isActive => status.toLowerCase() == 'active';
  bool get isArchived => status.toLowerCase() == 'archived';
  bool get isDraft => status.toLowerCase() == 'draft';

  Product copyWith({
    String? id,
    String? title,
    String? slug,
    String? categoryId,
    String? shortDescription,
    String? description,
    double? basePrice,
    double? discountPercentage,
    List<String>? imageUrls,
    bool? hasVariants,
    List<ProductVariant>? variants,
    int? stockQuantity,
    String? status,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      categoryId: categoryId ?? this.categoryId,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      imageUrls: imageUrls ?? this.imageUrls,
      hasVariants: hasVariants ?? this.hasVariants,
      variants: variants ?? this.variants,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
