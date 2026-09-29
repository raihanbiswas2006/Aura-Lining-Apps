import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_living/data/datasources/local_storage_service.dart';
import 'package:aura_living/data/repositories_impl/mock_cart_repository.dart';
import 'package:aura_living/data/repositories_impl/mock_product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Repository Unit Tests', () {
    late MockProductRepository productRepo;
    late MockCartRepository cartRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      productRepo = MockProductRepository();
    });

    test('fetches categories successfully', () async {
      final categories = await productRepo.getCategories();
      expect(categories.isNotEmpty, true);
      expect(categories.any((c) => c.slug == 'furniture'), true);
      expect(categories.any((c) => c.slug == 'lighting'), true);
    });

    test('fetches products and queries by ID', () async {
      final products = await productRepo.getProducts();
      expect(products.isNotEmpty, true);

      final firstProduct = products.first;
      final fetched = await productRepo.getProductById(firstProduct.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, firstProduct.title);
    });

    test('filters products by category and in-stock', () async {
      final furnitureProducts = await productRepo.getProducts(
        categoryId: 'furniture',
      );
      expect(furnitureProducts.isNotEmpty, true);

      final inStockOnly = await productRepo.getProducts(
        inStockOnly: true,
      );
      expect(inStockOnly.every((p) => !p.isSoldOut), true);
    });

    test('filters products by color and price range', () async {
      final filtered = await productRepo.getProducts(
        minPrice: 50.0,
        maxPrice: 200.0,
        colors: ['Natural Washi', 'Matte Black'],
      );
      expect(
        filtered.every((p) => p.price >= 50.0 && p.price <= 200.0),
        true,
      );
    });

    test('tests coupons validation and discount computation', () async {
      final prefs = await SharedPreferences.getInstance();
      cartRepo = MockCartRepository(LocalStorageService(prefs));

      final aura10 = await cartRepo.getCoupon('AURA10');
      expect(aura10, isNotNull);
      expect(aura10!.calculateDiscount(200.0, 15.0), 20.0);

      final freeship = await cartRepo.getCoupon('FREESHIP');
      expect(freeship, isNotNull);
      expect(freeship!.calculateDiscount(100.0, 15.0), 15.0);

      final minimalist = await cartRepo.getCoupon('MINIMALIST');
      expect(minimalist, isNotNull);
      // Below min order $150
      expect(minimalist!.calculateDiscount(100.0, 15.0), 0.0);
      // At or above $150
      expect(minimalist.calculateDiscount(160.0, 15.0), 20.0);
    });
  });
}
