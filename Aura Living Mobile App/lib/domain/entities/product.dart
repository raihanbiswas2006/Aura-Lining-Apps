class ProductVariant {
  final String id;
  final String sku;
  final String title;
  final Map<String, String> attributes;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final List<String> imageUrls;

  const ProductVariant({
    required this.id,
    required this.sku,
    required this.title,
    required this.attributes,
    required this.price,
    this.compareAtPrice,
    required this.stockQuantity,
    required this.imageUrls,
  });

  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 3;

  ProductVariant copyWith({
    String? id,
    String? sku,
    String? title,
    Map<String, String>? attributes,
    double? price,
    double? compareAtPrice,
    int? stockQuantity,
    List<String>? imageUrls,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      title: title ?? this.title,
      attributes: attributes ?? this.attributes,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'title': title,
      'attributes': attributes,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'stockQuantity': stockQuantity,
      'imageUrls': imageUrls,
    };
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      sku: json['sku'] as String,
      title: json['title'] as String,
      attributes: Map<String, String>.from(json['attributes'] as Map),
      price: (json['price'] as num).toDouble(),
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      stockQuantity: json['stockQuantity'] as int,
      imageUrls: List<String>.from(json['imageUrls'] as List),
    );
  }
}

class Product {
  final String id;
  final String title;
  final String brand;
  final String description;
  final String categoryId;
  final List<String> tags;
  final List<ProductVariant> variants;
  final double rating;
  final int reviewCount;
  final Map<String, String> specifications;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.brand,
    required this.description,
    required this.categoryId,
    required this.tags,
    required this.variants,
    required this.rating,
    required this.reviewCount,
    required this.specifications,
    required this.createdAt,
  });

  // Conveniences
  ProductVariant get defaultVariant =>
      variants.firstWhere((v) => v.isInStock, orElse: () => variants.first);

  double get price => defaultVariant.price;
  double? get compareAtPrice => defaultVariant.compareAtPrice;

  int get totalStock =>
      variants.fold(0, (sum, variant) => sum + variant.stockQuantity);

  bool get isSoldOut => totalStock == 0;

  String get thumbnail {
    if (defaultVariant.imageUrls.isNotEmpty) {
      return defaultVariant.imageUrls.first;
    }
    for (final v in variants) {
      if (v.imageUrls.isNotEmpty) return v.imageUrls.first;
    }
    return '';
  }

  List<String> get allImages {
    final images = <String>[];
    for (final v in variants) {
      for (final url in v.imageUrls) {
        if (!images.contains(url)) {
          images.add(url);
        }
      }
    }
    return images;
  }

  // Available colors extracted from variant attributes
  List<String> get availableColors {
    final colors = <String>{};
    for (final v in variants) {
      if (v.attributes.containsKey('Color')) {
        colors.add(v.attributes['Color']!);
      }
    }
    return colors.toList();
  }

  // Available sizes extracted from variant attributes
  List<String> get availableSizes {
    final sizes = <String>{};
    for (final v in variants) {
      if (v.attributes.containsKey('Size')) {
        sizes.add(v.attributes['Size']!);
      }
    }
    return sizes.toList();
  }

  Product copyWith({
    String? id,
    String? title,
    String? brand,
    String? description,
    String? categoryId,
    List<String>? tags,
    List<ProductVariant>? variants,
    double? rating,
    int? reviewCount,
    Map<String, String>? specifications,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      variants: variants ?? this.variants,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'brand': brand,
      'description': description,
      'categoryId': categoryId,
      'tags': tags,
      'variants': variants.map((v) => v.toJson()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      brand: json['brand'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      tags: List<String>.from(json['tags'] as List),
      variants: (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      specifications: Map<String, String>.from(json['specifications'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
