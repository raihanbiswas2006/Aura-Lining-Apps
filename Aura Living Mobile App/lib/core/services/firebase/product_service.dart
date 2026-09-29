import 'dart:async';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/category.dart';
import 'firestore_collections.dart';

/// Contract for Product and Catalog Firestore operations
abstract class ProductService {
  Future<List<Product>> getProducts({String? categoryId, String? search});
  Future<Product?> getProductById(String id);
  Stream<List<Product>> watchProducts({String? categoryId});
  Future<List<Product>> getFeaturedProducts();
}

/// Contract for Category collection operations
abstract class CategoryService {
  Future<List<Category>> getCategories();
  Stream<List<Category>> watchCategories();
}

/// Firestore Product Service implementation
class FirestoreProductService implements ProductService {
  final List<Product> _localCache;

  FirestoreProductService({List<Product> seedProducts = const []})
      : _localCache = List.from(seedProducts);

  String get collectionPath => FirestoreCollections.products;

  @override
  Future<List<Product>> getProducts({String? categoryId, String? search}) async {
    // In full Firestore integration:
    // Query query = FirebaseFirestore.instance.collection(FirestoreCollections.products);
    // if (categoryId != null) query = query.where('categoryId', isEqualTo: categoryId);
    // final snapshot = await query.get();
    // return snapshot.docs.map((d) => Product.fromJson(d.data())).toList();

    var list = _localCache;
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase().trim();
      list = list.where((p) =>
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      return _localCache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Product>> watchProducts({String? categoryId}) {
    // In full Firestore integration:
    // return FirebaseFirestore.instance
    //     .collection(FirestoreCollections.products)
    //     .snapshots()
    //     .map(...);
    return Stream.value(_localCache);
  }

  @override
  Future<List<Product>> getFeaturedProducts() async {
    return _localCache.where((p) => p.tags.contains('featured')).toList();
  }
}

/// Firestore Category Service implementation
class FirestoreCategoryService implements CategoryService {
  final List<Category> _localCache;

  FirestoreCategoryService({List<Category> seedCategories = const []})
      : _localCache = List.from(seedCategories);

  String get collectionPath => FirestoreCollections.categories;

  @override
  Future<List<Category>> getCategories() async {
    return _localCache;
  }

  @override
  Stream<List<Category>> watchCategories() {
    return Stream.value(_localCache);
  }
}
