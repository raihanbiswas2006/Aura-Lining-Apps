class Category {
  final String id;
  final String title;
  final String slug;
  final String? imageUrl;
  final String? parentCategoryId;

  const Category({
    required this.id,
    required this.title,
    required this.slug,
    this.imageUrl,
    this.parentCategoryId,
  });

  Category copyWith({
    String? id,
    String? title,
    String? slug,
    String? imageUrl,
    String? parentCategoryId,
  }) {
    return Category(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      imageUrl: imageUrl ?? this.imageUrl,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'imageUrl': imageUrl,
      'parentCategoryId': parentCategoryId,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      imageUrl: json['imageUrl'] as String?,
      parentCategoryId: json['parentCategoryId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
