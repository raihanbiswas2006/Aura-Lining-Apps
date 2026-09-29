/// Product Variant Model per PRD Section 8
class ProductVariant {
  final String id;
  final String sku;
  final String attributeName; // e.g., 'Color', 'Material', 'Size'
  final String attributeValue; // e.g., 'Nordic Oak', 'Smoked Walnut'
  final double? priceOverride;
  final int stockQuantity;

  const ProductVariant({
    required this.id,
    required this.sku,
    required this.attributeName,
    required this.attributeValue,
    this.priceOverride,
    required this.stockQuantity,
  });

  ProductVariant copyWith({
    String? id,
    String? sku,
    String? attributeName,
    String? attributeValue,
    double? priceOverride,
    int? stockQuantity,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      attributeName: attributeName ?? this.attributeName,
      attributeValue: attributeValue ?? this.attributeValue,
      priceOverride: priceOverride ?? this.priceOverride,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }

  bool get isLowStock => stockQuantity <= 5 && stockQuantity > 0;
  bool get isOutOfStock => stockQuantity == 0;
}
