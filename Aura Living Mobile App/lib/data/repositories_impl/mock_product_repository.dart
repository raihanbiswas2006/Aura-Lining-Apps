import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/mock/mock_categories.dart';
import '../datasources/mock/mock_products.dart';
import '../datasources/mock/mock_reviews.dart';

class MockProductRepository implements IProductRepository {
  final List<Product> _products = List.from(mockProducts);
  final List<Category> _categories = List.from(mockCategories);
  final List<Review> _reviews = List.from(mockReviews);

  @override
  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_categories);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    try {
      return _categories.firstWhere((c) => c.id == id || c.slug == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? tag,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    List<String>? colors,
    bool? inStockOnly,
    String? sortBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));

    var result = List<Product>.from(_products);

    // Filter by Category
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      final matchedCat = _categories.firstWhere(
        (c) => c.id == categoryId || c.slug == categoryId,
        orElse: () => Category(id: categoryId, title: '', slug: categoryId),
      );

      // Include child categories if any
      final childCategoryIds = _categories
          .where((c) => c.parentCategoryId == matchedCat.id)
          .map((c) => c.id)
          .toSet();
      childCategoryIds.add(matchedCat.id);
      childCategoryIds.add(matchedCat.slug);

      result = result.where((p) {
        return childCategoryIds.contains(p.categoryId) ||
            p.categoryId == categoryId ||
            p.tags.contains(matchedCat.slug);
      }).toList();
    }

    // Filter by Tag
    if (tag != null && tag.isNotEmpty) {
      result = result.where((p) => p.tags.contains(tag)).toList();
    }

    // Filter by Search Query
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((p) {
        final inTitle = p.title.toLowerCase().contains(q);
        final inBrand = p.brand.toLowerCase().contains(q);
        final inDesc = p.description.toLowerCase().contains(q);
        final inTags = p.tags.any((t) => t.toLowerCase().contains(q));
        final inVariants = p.variants.any((v) =>
            v.title.toLowerCase().contains(q) ||
            v.attributes.values.any((val) => val.toLowerCase().contains(q)));
        return inTitle || inBrand || inDesc || inTags || inVariants;
      }).toList();
    }

    // Filter by Price Range
    if (minPrice != null) {
      result = result.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      result = result.where((p) => p.price <= maxPrice).toList();
    }

    // Filter by Color
    if (colors != null && colors.isNotEmpty) {
      result = result.where((p) {
        return p.availableColors.any((c) => colors.contains(c));
      }).toList();
    }

    // Filter by In-Stock Only
    if (inStockOnly == true) {
      result = result.where((p) => !p.isSoldOut).toList();
    }

    // Sort
    switch (sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'featured':
      default:
        // Keep catalog curation order
        break;
    }

    return result;
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getSuggestedSearchTerms(String query) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final suggestions = <String>{};
    for (final p in _products) {
      if (p.title.toLowerCase().contains(q)) {
        suggestions.add(p.title);
      }
      for (final tag in p.tags) {
        if (tag.toLowerCase().contains(q)) {
          suggestions.add(tag);
        }
      }
      for (final color in p.availableColors) {
        if (color.toLowerCase().contains(q)) {
          suggestions.add('$color furniture');
        }
      }
    }
    return suggestions.take(5).toList();
  }

  @override
  Future<List<Review>> getProductReviews(String productId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return _reviews.where((r) => r.productId == productId).toList();
  }

  @override
  Future<void> addReview(Review review) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _reviews.insert(0, review);

    // Update product rating and review count
    final index = _products.indexWhere((p) => p.id == review.productId);
    if (index != -1) {
      final product = _products[index];
      final prodReviews = _reviews.where((r) => r.productId == product.id).toList();
      final totalRating = prodReviews.fold(0.0, (sum, r) => sum + r.rating);
      final newAvg = totalRating / prodReviews.length;

      _products[index] = product.copyWith(
        rating: double.parse(newAvg.toStringAsFixed(1)),
        reviewCount: prodReviews.length,
      );
    }
  }
}
