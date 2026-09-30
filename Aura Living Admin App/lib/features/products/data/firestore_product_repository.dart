import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../domain/product.dart';
import '../domain/product_variant.dart';
import '../domain/category.dart';
import 'product_repository.dart';

/// Live Firestore Product Repository for Aura Living Admin
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;
  final MockProductRepository _fallbackRepo = MockProductRepository();
  final _uuid = const Uuid();

  FirestoreProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Product>> watchProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _fallbackRepo.getProductsSync();
      }
      return snapshot.docs.map((doc) => _mapDocToProduct(doc.id, doc.data())).toList();
    }).handleError((_) => _fallbackRepo.getProductsSync());
  }

  @override
  Stream<List<Category>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _fallbackRepo.getCategoriesSync();
      }
      return snapshot.docs.map((doc) => _mapDocToCategory(doc.id, doc.data())).toList();
    }).handleError((_) => _fallbackRepo.getCategoriesSync());
  }

  @override
  Future<List<Product>> getProducts({
    String? query,
    String? categoryId,
    String? stockFilter,
    String? statusFilter,
  }) async {
    try {
      final snapshot = await _firestore.collection('products').get();
      if (snapshot.docs.isEmpty) {
        return await _fallbackRepo.getProducts(
          query: query,
          categoryId: categoryId,
          stockFilter: stockFilter,
          statusFilter: statusFilter,
        );
      }

      var products = snapshot.docs.map((doc) => _mapDocToProduct(doc.id, doc.data())).toList();

      return products.where((p) {
        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          final matchTitle = p.title.toLowerCase().contains(q);
          final matchSku = p.slug.toLowerCase().contains(q) ||
              p.variants.any((v) => v.sku.toLowerCase().contains(q));
          if (!matchTitle && !matchSku) return false;
        }

        if (categoryId != null && categoryId != 'all' && categoryId.isNotEmpty) {
          if (p.categoryId != categoryId) return false;
        }

        if (stockFilter != null && stockFilter != 'all') {
          if (stockFilter == 'in_stock' && p.totalStock <= 5) return false;
          if (stockFilter == 'low_stock' && (!p.isLowStock)) return false;
          if (stockFilter == 'out_of_stock' && (!p.isOutOfStock)) return false;
        }

        if (statusFilter != null && statusFilter != 'all') {
          if (p.status.toLowerCase() != statusFilter.toLowerCase()) return false;
        }

        return true;
      }).toList();
    } catch (_) {
      return await _fallbackRepo.getProducts(
        query: query,
        categoryId: categoryId,
        stockFilter: stockFilter,
        statusFilter: statusFilter,
      );
    }
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return _mapDocToProduct(doc.id, doc.data()!);
      }
    } catch (_) {}
    return await _fallbackRepo.getProductById(id);
  }

  @override
  Future<Product> createProduct(Product product) async {
    final id = product.id.isEmpty ? 'prod-${_uuid.v4().substring(0, 8)}' : product.id;
    final now = DateTime.now();
    final newProduct = product.copyWith(
      id: id,
      createdAt: now,
      updatedAt: now,
    );

    final data = _mapProductToMap(newProduct);
    try {
      await _firestore.collection('products').doc(id).set(data);
    } catch (_) {}

    return newProduct;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    final data = _mapProductToMap(updated);

    try {
      await _firestore.collection('products').doc(product.id).set(data, SetOptions(merge: true));
    } catch (_) {}

    return updated;
  }

  @override
  Future<void> quickAdjustStock(String productId, int newQuantity, {String? variantId}) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null) {
        final product = _mapDocToProduct(doc.id, doc.data()!);
        if (variantId != null && product.hasVariants) {
          final updatedVariants = product.variants.map((v) {
            if (v.id == variantId) return v.copyWith(stockQuantity: newQuantity);
            return v;
          }).toList();
          await updateProduct(product.copyWith(variants: updatedVariants));
        } else {
          await _firestore.collection('products').doc(productId).update({
            'stock': newQuantity,
            'stockQuantity': newQuantity,
            'totalStock': newQuantity,
            'inStock': newQuantity > 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {
      await _fallbackRepo.quickAdjustStock(productId, newQuantity, variantId: variantId);
    }
  }

  @override
  Future<Product> toggleAvailability(String productId) async {
    final product = await getProductById(productId);
    if (product == null) throw Exception('Product not found: $productId');

    final newStatus = product.status.toLowerCase() == 'active' ? 'Draft' : 'Active';
    final updated = product.copyWith(status: newStatus, updatedAt: DateTime.now());

    try {
      await _firestore.collection('products').doc(productId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return updated;
  }

  @override
  Future<Product> deactivateProduct(String productId) async {
    final product = await getProductById(productId);
    if (product == null) throw Exception('Product not found: $productId');

    final updated = product.copyWith(status: 'Archived', updatedAt: DateTime.now());

    try {
      await _firestore.collection('products').doc(productId).update({
        'status': 'Archived',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return updated;
  }

  @override
  Future<bool> hardDeleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      return true;
    } catch (_) {
      return await _fallbackRepo.hardDeleteProduct(productId);
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => _mapDocToCategory(doc.id, doc.data())).toList();
      }
    } catch (_) {}
    return await _fallbackRepo.getCategories();
  }

  @override
  Future<Category> addCategory(Category category) async {
    final id = category.id.isEmpty ? 'cat-${_uuid.v4().substring(0, 6)}' : category.id;
    final newCat = category.copyWith(id: id);

    try {
      await _firestore.collection('categories').doc(id).set({
        'id': id,
        'name': newCat.name,
        'title': newCat.name,
        'slug': newCat.slug,
        'icon': newCat.icon,
        'productCount': newCat.productCount,
      });
    } catch (_) {}

    return newCat;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    try {
      await _firestore.collection('categories').doc(category.id).set({
        'id': category.id,
        'name': category.name,
        'title': category.name,
        'slug': category.slug,
        'icon': category.icon,
        'productCount': category.productCount,
      }, SetOptions(merge: true));
    } catch (_) {}

    return category;
  }

  @override
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      return true;
    } catch (_) {
      return await _fallbackRepo.deleteCategory(categoryId);
    }
  }

  Product _mapDocToProduct(String id, Map<String, dynamic> data) {
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(data['updatedAt']) ?? DateTime.now();
    }

    final rawImages = data['imageUrls'] ?? data['images'] ?? [];
    final List<String> imageUrls = (rawImages is List)
        ? rawImages.map((e) => e.toString()).toList()
        : [];

    final rawVariants = data['variants'] as List<dynamic>? ?? [];
    final variants = rawVariants.map((v) {
      final vm = v as Map<String, dynamic>;
      return ProductVariant(
        id: vm['id'] ?? '',
        sku: vm['sku'] ?? '',
        attributeName: vm['attributeName'] ?? 'Finish',
        attributeValue: vm['attributeValue'] ?? vm['title'] ?? 'Standard',
        priceOverride: (vm['priceOverride'] as num?)?.toDouble() ?? (vm['price'] as num?)?.toDouble(),
        stockQuantity: (vm['stockQuantity'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return Product(
      id: id,
      title: data['title'] ?? data['name'] ?? '',
      slug: data['slug'] ?? '',
      categoryId: data['categoryId'] ?? 'cat-living',
      shortDescription: data['shortDescription'] ?? '',
      description: data['description'] ?? '',
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      imageUrls: imageUrls,
      hasVariants: data['hasVariants'] as bool? ?? variants.isNotEmpty,
      variants: variants,
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? (data['stock'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'Active',
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> _mapProductToMap(Product product) {
    return {
      'id': product.id,
      'title': product.title,
      'name': product.title,
      'slug': product.slug,
      'categoryId': product.categoryId,
      'shortDescription': product.shortDescription,
      'description': product.description,
      'basePrice': product.basePrice,
      'price': product.basePrice,
      'discountPercentage': product.discountPercentage,
      'imageUrls': product.imageUrls,
      'images': product.imageUrls,
      'hasVariants': product.hasVariants,
      'variants': product.variants.map((v) => {
        'id': v.id,
        'sku': v.sku,
        'attributeName': v.attributeName,
        'attributeValue': v.attributeValue,
        'priceOverride': v.priceOverride,
        'stockQuantity': v.stockQuantity,
      }).toList(),
      'stockQuantity': product.stockQuantity,
      'stock': product.totalStock,
      'totalStock': product.totalStock,
      'inStock': product.totalStock > 0,
      'status': product.status,
      'isFeatured': product.isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Category _mapDocToCategory(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? data['title'] ?? '',
      slug: data['slug'] ?? '',
      icon: data['icon'] ?? 'chair_outlined',
      productCount: (data['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}

extension MockProductRepositoryExtension on MockProductRepository {
  List<Product> getProductsSync() {
    return [
      Product(
        id: 'prod-001',
        title: 'Nordic Lounge Chair',
        slug: 'nordic-lounge-chair',
        categoryId: 'cat-living',
        shortDescription: 'Solid European oak lounge chair with Italian wool bouclé.',
        description: 'Engineered with honest materials and refined proportions.',
        basePrice: 34900.0,
        discountPercentage: 0.0,
        imageUrls: const [
          'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1000&q=80',
        ],
        stockQuantity: 10,
        status: 'Active',
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<Category> getCategoriesSync() {
    return const [
      Category(
        id: 'cat-living',
        name: 'Living Room',
        slug: 'living',
        icon: 'chair_outlined',
        productCount: 4,
      ),
      Category(
        id: 'cat-dining',
        name: 'Dining',
        slug: 'dining',
        icon: 'table_restaurant_outlined',
        productCount: 3,
      ),
    ];
  }
}
