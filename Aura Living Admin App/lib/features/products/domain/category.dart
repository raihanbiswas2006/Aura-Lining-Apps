/// Category model per PRD Section 6.4 & 8
class Category {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.productCount = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    String? icon,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      productCount: productCount ?? this.productCount,
    );
  }
}
