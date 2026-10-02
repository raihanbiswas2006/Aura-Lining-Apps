import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/mock/mock_categories.dart';
import '../datasources/mock/mock_products.dart';
import '../datasources/mock/mock_reviews.dart';

class FirebaseProductRepository implements IProductRepository {
  final FirebaseFirestore? _firestoreOverride;
  final List<Product> _fallbackProducts = List.from(mockProducts);
  final List<Category> _fallbackCategories = List.from(mockCategories);
  final List<Review> _fallbackReviews = List.from(mockReviews);

  FirebaseFirestore? get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseProductRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  @override
  Future<List<Category>> getCategories() async {
    final db = _firestore;
    if (db != null) {
      try {
        final snapshot = await db.collection('categories').get().timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((d) => Category.fromJson(d.data())).toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_fallbackCategories);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final db = _firestore;
    if (db != null) {
      try {
        final doc = await db.collection('categories').doc(id).get().timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return Category.fromJson(doc.data()!);
        }
      } catch (_) {}
    }

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
    final db = _firestore;
    if (db != null) {
      try {
        final snapshot = await db.collection('products').get().timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          products = snapshot.docs.map((d) => Product.fromJson(d.data())).toList();
        }
      } catch (_) {}
    }

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
    final db = _firestore;
    if (db != null) {
      try {
        final doc = await db.collection('products').doc(id).get().timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return Product.fromJson(doc.data()!);
        }
      } catch (_) {}
    }

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
    final db = _firestore;
    if (db != null) {
      try {
        final snapshot = await db
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get()
            .timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((d) => Review.fromJson(d.data())).toList();
        }
      } catch (_) {}
    }

    return _fallbackReviews.where((r) => r.productId == productId).toList();
  }

  @override
  Future<void> addReview(Review review) async {
    final db = _firestore;
    if (db != null) {
      try {
        await db.collection('reviews').doc(review.id).set(review.toJson()).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    _fallbackReviews.insert(0, review);
  }
}
