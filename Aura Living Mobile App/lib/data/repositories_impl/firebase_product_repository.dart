import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/mock/mock_categories.dart';
import '../datasources/mock/mock_products.dart';
import '../datasources/mock/mock_reviews.dart';

class FirebaseProductRepository implements IProductRepository {
  final FirebaseFirestore _firestore;
  final List<Product> _fallbackProducts = List.from(mockProducts);
  final List<Category> _fallbackCategories = List.from(mockCategories);
  final List<Review> _fallbackReviews = List.from(mockReviews);

  FirebaseProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => Category.fromJson(d.data())).toList();
      }
    } catch (_) {}
    return List.unmodifiable(_fallbackCategories);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection('categories').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Category.fromJson(doc.data()!);
      }
    } catch (_) {}

    try {
      return _fallbackCategories.firstWhere((c) => c.id == id || c.slug == id);
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
    List<Product> products = [];
    try {
      final snapshot = await _firestore.collection('products').get();
      if (snapshot.docs.isNotEmpty) {
        products = snapshot.docs.map((d) => Product.fromJson(d.data())).toList();
      }
    } catch (_) {}

    if (products.isEmpty) {
      products = List.from(_fallbackProducts);
    }

    var result = List<Product>.from(products);

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      result = result.where((p) => p.categoryId == categoryId).toList();
    }

    if (tag != null && tag.isNotEmpty) {
      result = result.where((p) => p.tags.contains(tag)).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        p.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }

    if (minPrice != null) {
      result = result.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      result = result.where((p) => p.price <= maxPrice).toList();
    }

    if (inStockOnly == true) {
      result = result.where((p) => !p.isSoldOut).toList();
    }

    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          result.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          result.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          result.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'newest':
          result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'featured':
        default:
          break;
      }
    }

    return result;
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Product.fromJson(doc.data()!);
      }
    } catch (_) {}

    try {
      return _fallbackProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getSuggestedSearchTerms(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final suggestions = <String>{};
    for (final p in _fallbackProducts) {
      if (p.title.toLowerCase().contains(q)) {
        suggestions.add(p.title);
      }
      for (final tag in p.tags) {
        if (tag.toLowerCase().contains(q)) {
          suggestions.add(tag);
        }
      }
    }
    return suggestions.take(5).toList();
  }

  @override
  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
      }
    } catch (_) {}

    return _fallbackReviews.where((r) => r.productId == productId).toList();
  }

  @override
  Future<void> addReview(Review review) async {
    try {
      await _firestore.collection('reviews').doc(review.id).set(review.toJson());
    } catch (_) {}
    _fallbackReviews.insert(0, review);
  }
}
