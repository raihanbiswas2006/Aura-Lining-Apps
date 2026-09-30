import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore;
  final List<Product> _localCache;

  FirestoreProductService({
    FirebaseFirestore? firestore,
    List<Product> seedProducts = const [],
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localCache = List.from(seedProducts);

  String get collectionPath => FirestoreCollections.products;

  @override
  Future<List<Product>> getProducts({String? categoryId, String? search}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(FirestoreCollections.products);
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        var list = snapshot.docs.map((d) => Product.fromJson(d.data())).toList();
        if (search != null && search.trim().isNotEmpty) {
          final q = search.toLowerCase().trim();
          list = list.where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q)).toList();
        }
        return list;
      }
    } catch (_) {}

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
      final doc = await _firestore.collection(FirestoreCollections.products).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Product.fromJson(doc.data()!);
      }
    } catch (_) {}

    try {
      return _localCache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Product>> watchProducts({String? categoryId}) {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(FirestoreCollections.products);
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      return query.snapshots().map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((d) => Product.fromJson(d.data())).toList();
        }
        return _localCache;
      });
    } catch (_) {
      return Stream.value(_localCache);
    }
  }

  @override
  Future<List<Product>> getFeaturedProducts() async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.products)
          .where('isFeatured', isEqualTo: true)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => Product.fromJson(d.data())).toList();
      }
    } catch (_) {}

    return _localCache.where((p) => p.tags.contains('featured')).toList();
  }
}

/// Firestore Category Service implementation
class FirestoreCategoryService implements CategoryService {
  final FirebaseFirestore _firestore;
  final List<Category> _localCache;

  FirestoreCategoryService({
    FirebaseFirestore? firestore,
    List<Category> seedCategories = const [],
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localCache = List.from(seedCategories);

  String get collectionPath => FirestoreCollections.categories;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(FirestoreCollections.categories).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => Category.fromJson(d.data())).toList();
      }
    } catch (_) {}

    return _localCache;
  }

  @override
  Stream<List<Category>> watchCategories() {
    try {
      return _firestore.collection(FirestoreCollections.categories).snapshots().map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((d) => Category.fromJson(d.data())).toList();
        }
        return _localCache;
      });
    } catch (_) {
      return Stream.value(_localCache);
    }
  }
}
