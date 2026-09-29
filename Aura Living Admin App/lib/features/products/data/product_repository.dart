import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/product.dart';
import '../domain/product_variant.dart';
import '../domain/category.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    String? query,
    String? categoryId,
    String? stockFilter, // 'all', 'in_stock', 'low_stock', 'out_of_stock'
    String? statusFilter, // 'all', 'Active', 'Draft', 'Archived'
  });
  Future<Product?> getProductById(String id);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> quickAdjustStock(String productId, int newQuantity, {String? variantId});
  Future<Product> toggleAvailability(String productId);
  Future<Product> deactivateProduct(String productId);
  Future<bool> hardDeleteProduct(String productId);

  Future<List<Category>> getCategories();
  Future<Category> addCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<bool> deleteCategory(String categoryId);

  Stream<List<Product>> watchProducts();
  Stream<List<Category>> watchCategories();
}

class MockProductRepository implements ProductRepository {
  final _uuid = const Uuid();
  final _productsStream = StreamController<List<Product>>.broadcast();
  final _categoriesStream = StreamController<List<Category>>.broadcast();

  late List<Category> _categories;
  late List<Product> _products;

  MockProductRepository() {
    _seedData();
  }

  void _seedData() {
    _categories = [
      const Category(
        id: 'cat-furniture',
        name: 'Furniture',
        slug: 'furniture',
        icon: 'chair_outlined',
        productCount: 4,
      ),
      const Category(
        id: 'cat-decor',
        name: 'Decor & Objects',
        slug: 'decor',
        icon: 'yard_outlined',
        productCount: 3,
      ),
      const Category(
        id: 'cat-lighting',
        name: 'Lighting',
        slug: 'lighting',
        icon: 'lightbulb_outlined',
        productCount: 2,
      ),
      const Category(
        id: 'cat-textiles',
        name: 'Textiles & Bedding',
        slug: 'textiles',
        icon: 'bed_outlined',
        productCount: 2,
      ),
      const Category(
        id: 'cat-dining',
        name: 'Dining & Kitchen',
        slug: 'dining',
        icon: 'table_restaurant_outlined',
        productCount: 1,
      ),
    ];

    final now = DateTime.now();

    _products = [
      Product(
        id: 'prod-01',
        title: 'Nordic Minimalist Oak Chair',
        slug: 'nordic-minimalist-oak-chair',
        categoryId: 'cat-furniture',
        shortDescription: 'Solid Scandinavian oak dining chair with curved backrest.',
        description: 'Meticulously crafted from FSC-certified Nordic white oak, this dining chair combines organic ergonomics with understated architectural poise. Matte lacquer protective coating preserves the natural tactile grain.',
        basePrice: 28000.0,
        discountPercentage: 15.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: true,
        variants: const [
          ProductVariant(
            id: 'var-01-a',
            sku: 'CHAIR-OAK-NAT',
            attributeName: 'Wood Finish',
            attributeValue: 'Natural White Oak',
            stockQuantity: 18,
          ),
          ProductVariant(
            id: 'var-01-b',
            sku: 'CHAIR-OAK-SMK',
            attributeName: 'Wood Finish',
            attributeValue: 'Smoked Walnut Finish',
            priceOverride: 31000.0,
            stockQuantity: 4, // Low stock <= 5
          ),
          ProductVariant(
            id: 'var-01-c',
            sku: 'CHAIR-OAK-BLK',
            attributeName: 'Wood Finish',
            attributeValue: 'Ebonized Black Oak',
            priceOverride: 29500.0,
            stockQuantity: 0, // Out of stock
          ),
        ],
        status: 'Active',
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      Product(
        id: 'prod-02',
        title: 'Kanso Ceramic Ribbed Vase',
        slug: 'kanso-ceramic-ribbed-vase',
        categoryId: 'cat-decor',
        shortDescription: 'Hand-thrown matte earthenware vase with subtle vertical fluting.',
        description: 'Inspired by Japanese Kanso philosophy. Textured raw stone surface on the exterior with water-resistant glaze interior for dried botanical or fresh floral arrangements.',
        basePrice: 6500.0,
        discountPercentage: 0.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: false,
        stockQuantity: 3, // Low stock <= 5
        status: 'Active',
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Product(
        id: 'prod-03',
        title: 'Travertine Low Coffee Table',
        slug: 'travertine-low-coffee-table',
        categoryId: 'cat-furniture',
        shortDescription: 'Brutalist Roman travertine slab with fluted plinth legs.',
        description: 'Carved from monolithic honed travertine marble with natural porous cavities subtly hand-filled. Clean geometric proportions create a serene centerpiece for living spaces.',
        basePrice: 78000.0,
        discountPercentage: 10.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: false,
        stockQuantity: 7,
        status: 'Active',
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Product(
        id: 'prod-04',
        title: 'Linen Slumber Duvet Set',
        slug: 'linen-slumber-duvet-set',
        categoryId: 'cat-textiles',
        shortDescription: '100% French flax stone-washed breathable linen bed set.',
        description: 'Pre-washed for heirloom softness and temperature-regulating comfort throughout the seasons. Set includes duvet cover and two matching envelope pillowcases.',
        basePrice: 19500.0,
        discountPercentage: 20.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: true,
        variants: const [
          ProductVariant(
            id: 'var-04-a',
            sku: 'LINEN-SET-OAT-Q',
            attributeName: 'Size',
            attributeValue: 'Queen / Oat White',
            stockQuantity: 12,
          ),
          ProductVariant(
            id: 'var-04-b',
            sku: 'LINEN-SET-OAT-K',
            attributeName: 'Size',
            attributeValue: 'King / Oat White',
            priceOverride: 22500.0,
            stockQuantity: 5, // Low stock <= 5
          ),
          ProductVariant(
            id: 'var-04-c',
            sku: 'LINEN-SET-SAG-Q',
            attributeName: 'Size',
            attributeValue: 'Queen / Sage Mist',
            stockQuantity: 8,
          ),
        ],
        status: 'Active',
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Product(
        id: 'prod-05',
        title: 'Muted Brass Arc Pendant Lamp',
        slug: 'muted-brass-arc-pendant-lamp',
        categoryId: 'cat-lighting',
        shortDescription: 'Spun brass shade with matte interior reflector and woven cord.',
        description: 'Delivers warm, anti-glare ambient illumination. Solid brass hardware brushed with an antique oil finish designed to develop a rich organic patina over time.',
        basePrice: 21000.0,
        discountPercentage: 0.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: false,
        stockQuantity: 0, // Out of stock
        status: 'Active',
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Product(
        id: 'prod-06',
        title: 'Cedar & Hinoki Scented Candle',
        slug: 'cedar-hinoki-scented-candle',
        categoryId: 'cat-decor',
        shortDescription: 'Coconut soy wax candle in reusable matte stoneware vessel.',
        description: 'Top notes of smoked Hinoki cypress and dry amber with base chords of Atlas cedar and frankincense. Cotton double-wick provides a clean 60-hour burn.',
        basePrice: 4200.0,
        discountPercentage: 0.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1603006905003-be475563bc59?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: false,
        stockQuantity: 34,
        status: 'Active',
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 12)),
      ),
      Product(
        id: 'prod-07',
        title: 'Solvorn Solid Teak Dining Table',
        slug: 'solvorn-solid-teak-dining-table',
        categoryId: 'cat-dining',
        shortDescription: 'Seats 8 adults comfortably with tapered cylindrical legs.',
        description: 'Reclaimed plantation teak seasoned over 30 years. Chamfered table edge and invisible steel sub-frame reinforcement prevent warping while maintaining an airy silhouette.',
        basePrice: 125000.0,
        discountPercentage: 5.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1615066390971-03e4e1c36ddf?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: false,
        stockQuantity: 2, // Low stock <= 5
        status: 'Active',
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 80)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Product(
        id: 'prod-08',
        title: 'Fjord Wool Lounge Blanket',
        slug: 'fjord-wool-lounge-blanket',
        categoryId: 'cat-textiles',
        shortDescription: '100% Norwegian virgin wool throw with fringed edges.',
        description: 'Woven in western Norway using traditional jacquard looms. Ultra-durable yet soft, with geometric check relief patterns in un-dyed cream and charcoal wool.',
        basePrice: 14000.0,
        discountPercentage: 0.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=600&q=80',
        ],
        hasVariants: false,
        stockQuantity: 15,
        status: 'Draft', // Draft status
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void _notifyProducts() {
    _productsStream.add(List.unmodifiable(_products));
  }

  void _notifyCategories() {
    _categoriesStream.add(List.unmodifiable(_categories));
  }

  @override
  Stream<List<Product>> watchProducts() {
    return _productsStream.stream;
  }

  @override
  Stream<List<Category>> watchCategories() {
    return _categoriesStream.stream;
  }

  @override
  Future<List<Product>> getProducts({
    String? query,
    String? categoryId,
    String? stockFilter,
    String? statusFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    return _products.where((p) {
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
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final newProduct = product.copyWith(
      id: product.id.isEmpty ? 'prod-${_uuid.v4().substring(0, 8)}' : product.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _products.insert(0, newProduct);
    _updateCategoryProductCount(newProduct.categoryId, 1);
    _notifyProducts();
    return newProduct;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw Exception('Product not found: ${product.id}');
    }

    final oldCat = _products[index].categoryId;
    final updated = product.copyWith(updatedAt: DateTime.now());
    _products[index] = updated;

    if (oldCat != updated.categoryId) {
      _updateCategoryProductCount(oldCat, -1);
      _updateCategoryProductCount(updated.categoryId, 1);
    }

    _notifyProducts();
    return updated;
  }

  @override
  Future<void> quickAdjustStock(String productId, int newQuantity, {String? variantId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) throw Exception('Product not found');

    final product = _products[index];
    if (variantId != null && product.hasVariants) {
      final updatedVariants = product.variants.map((v) {
        if (v.id == variantId) {
          return v.copyWith(stockQuantity: newQuantity);
        }
        return v;
      }).toList();
      _products[index] = product.copyWith(
        variants: updatedVariants,
        updatedAt: DateTime.now(),
      );
    } else {
      _products[index] = product.copyWith(
        stockQuantity: newQuantity,
        updatedAt: DateTime.now(),
      );
    }
    _notifyProducts();
  }

  @override
  Future<Product> toggleAvailability(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) throw Exception('Product not found');

    final currentStatus = _products[index].status;
    final newStatus = currentStatus.toLowerCase() == 'active' ? 'Draft' : 'Active';
    final updated = _products[index].copyWith(status: newStatus, updatedAt: DateTime.now());
    _products[index] = updated;
    _notifyProducts();
    return updated;
  }

  @override
  Future<Product> deactivateProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) throw Exception('Product not found');

    final updated = _products[index].copyWith(status: 'Archived', updatedAt: DateTime.now());
    _products[index] = updated;
    _notifyProducts();
    return updated;
  }

  @override
  Future<bool> hardDeleteProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return false;

    final catId = _products[index].categoryId;
    _products.removeAt(index);
    _updateCategoryProductCount(catId, -1);
    _notifyProducts();
    return true;
  }

  @override
  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_categories);
  }

  @override
  Future<Category> addCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newCat = category.copyWith(
      id: category.id.isEmpty ? 'cat-${_uuid.v4().substring(0, 6)}' : category.id,
    );
    _categories.add(newCat);
    _notifyCategories();
    return newCat;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) throw Exception('Category not found');
    _categories[index] = category;
    _notifyCategories();
    return category;
  }

  @override
  Future<bool> deleteCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Guarded: cannot delete if category contains active products per PRD Section 6.4
    final hasProducts = _products.any((p) => p.categoryId == categoryId);
    if (hasProducts) {
      throw Exception('Cannot delete category: contains active catalog products.');
    }

    _categories.removeWhere((c) => c.id == categoryId);
    _notifyCategories();
    return true;
  }

  void _updateCategoryProductCount(String categoryId, int delta) {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx != -1) {
      final updated = _categories[idx].copyWith(
        productCount: (_categories[idx].productCount + delta).clamp(0, 9999),
      );
      _categories[idx] = updated;
      _notifyCategories();
    }
  }
}
