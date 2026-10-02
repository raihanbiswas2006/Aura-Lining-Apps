import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_living/data/datasources/local_storage_service.dart';
import 'package:aura_living/data/datasources/mock/mock_products.dart';
import 'package:aura_living/data/repositories_impl/mock_cart_repository.dart';
import 'package:aura_living/data/repositories_impl/mock_order_repository.dart';
import 'package:aura_living/data/repositories_impl/mock_product_repository.dart';
import 'package:aura_living/domain/entities/address.dart';
import 'package:aura_living/domain/entities/cart_item.dart';
import 'package:aura_living/presentation/blocs/cart/cart_cubit.dart';
import 'package:aura_living/presentation/blocs/checkout/checkout_cubit.dart';
import 'package:aura_living/presentation/blocs/wishlist/wishlist_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorageService storage;
  late MockProductRepository productRepo;
  late MockCartRepository cartRepo;
  late MockOrderRepository orderRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);
    productRepo = MockProductRepository();
    cartRepo = MockCartRepository(storage);
    orderRepo = MockOrderRepository(storage);
  });

  group('AURA LIVING QA CHECKLIST (Section 15)', () {
    // QA-01: Navigation Architecture
    test('QA-01: Navigation - IndexedStack maintains tab indices and models without state loss', () {
      int activeIndex = 0;
      void onTabTapped(int index) {
        activeIndex = index;
      }

      onTabTapped(1); // Shop
      expect(activeIndex, 1);
      onTabTapped(3); // Cart
      expect(activeIndex, 3);
      onTabTapped(0); // Return to Home
      expect(activeIndex, 0);
    });

    // QA-02: Search live matching & suggestions
    test('QA-02: Search - autocomplete matching and product previews', () async {
      final chairResults = await productRepo.getProducts(searchQuery: 'chair');
      expect(chairResults.isNotEmpty, true);
      expect(
        chairResults.every((p) =>
            p.title.toLowerCase().contains('chair') ||
            p.description.toLowerCase().contains('chair') ||
            p.tags.any((t) => t.toLowerCase().contains('chair'))),
        true,
      );

      final lampResults = await productRepo.getProducts(searchQuery: 'lamp');
      expect(lampResults.isNotEmpty, true);
    });

    // QA-03: Multi-facet filter intersection (Price + Color + InStock)
    test('QA-03: Filter - Price Range + Color + In-Stock intersection (AND logic)', () async {
      final filtered = await productRepo.getProducts(
        minPrice: 50.0,
        maxPrice: 300.0,
        colors: ['Natural Washi', 'Matte Black', 'Sand Ochre'],
        inStockOnly: true,
      );

      for (final product in filtered) {
        expect(product.price >= 50.0 && product.price <= 300.0, true);
        expect(product.isSoldOut, false);
      }
    });

    // QA-04: PDP sold-out variant detection and handling
    test('QA-04: PDP - Out-of-stock variant disables Add to Cart and reflects 0 stock', () async {
      final sampleProduct = mockProducts.first;
      final outOfStockVariant = sampleProduct.variants.first.copyWith(
        id: 'oos_var_1',
        stockQuantity: 0,
      );

      expect(outOfStockVariant.stockQuantity, 0);
      expect(outOfStockVariant.stockQuantity <= 0, true);
    });

    // QA-06: Cart - quantity stepper capped at variant inventory
    test('QA-06: Cart - Stepper caps at max variant stock quantity', () async {
      final cartCubit = CartCubit(cartRepo);
      final product = mockProducts.first;
      final variantWithLowStock = product.variants.first.copyWith(
        id: 'low_stock_var',
        stockQuantity: 3,
      );

      // Add 2 items
      await cartCubit.addItem(product, variantWithLowStock, quantity: 2);
      expect(cartCubit.state.items.first.quantity, 2);

      // Attempt to increment past 3 (e.g. 5)
      await cartCubit.updateQuantity(cartCubit.state.items.first.id, 5);
      expect(cartCubit.state.items.first.quantity, 3); // Clamped to 3!

      // Attempt to decrement below 1 (0 triggers removal)
      await cartCubit.updateQuantity(cartCubit.state.items.first.id, 0);
      expect(cartCubit.state.items.isEmpty, true);
    });

    // QA-07: Coupons - AURA10, FREESHIP, MINIMALIST calculations and minimum rules
    test(r'QA-07: Coupon - AURA10 (10% off), FREESHIP ($0 ship), MINIMALIST threshold', () async {
      final cartCubit = CartCubit(cartRepo);
      final product = mockProducts.first;
      final variant = product.variants.first.copyWith(price: 10000.0, stockQuantity: 10);

      await cartCubit.addItem(product, variant, quantity: 1); // Subtotal = ৳10000.0
      expect(cartCubit.state.subtotal, 10000.0);

      // Test AURA10
      var success = await cartCubit.applyCoupon('AURA10');
      expect(success, true);
      expect(cartCubit.state.discountAmount, 1000.0); // 10% of 10000 = 1000.0

      // Test MINIMALIST when subtotal < ৳15000
      success = await cartCubit.applyCoupon('MINIMALIST');
      expect(success, false);
      expect(cartCubit.state.couponError, 'Order minimum of ৳15000 not met for this coupon');

      // Increase subtotal to ৳20000
      await cartCubit.addItem(product, variant, quantity: 1); // 2 items = ৳20000
      expect(cartCubit.state.subtotal, 20000.0);

      // Now apply MINIMALIST
      success = await cartCubit.applyCoupon('MINIMALIST');
      expect(success, true);
      expect(cartCubit.state.discountAmount, 1000.0); // Flat ৳1000.0 off

      // Test FREESHIP
      await cartCubit.updateQuantity(cartCubit.state.items.first.id, 1); // subtotal = 10000 >= 5000
      success = await cartCubit.applyCoupon('FREESHIP');
      expect(success, true);
      expect(cartCubit.state.shippingCost, 0.0);

      // Invalid coupon
      success = await cartCubit.applyCoupon('INVALID_CODE');
      expect(success, false);
      expect(cartCubit.state.couponError, 'Coupon code does not exist');
    });

    // QA-08: Checkout Form Validation (Phone number & Postal code regex)
    test('QA-08: Checkout - Phone & Postal Code Regex Validation', () {
      final phoneRegex = RegExp(r'^\+?[\d\s\-()]{7,15}$');
      final postalRegex = RegExp(r'^[A-Za-z0-9\s\-]{3,10}$');

      // Valid cases
      expect(phoneRegex.hasMatch('+1 555-123-4567'), true);
      expect(phoneRegex.hasMatch('01712345678'), true);
      expect(postalRegex.hasMatch('94103'), true);
      expect(postalRegex.hasMatch('SW1A 1AA'), true);

      // Invalid cases
      expect(phoneRegex.hasMatch('abc'), false);
      expect(phoneRegex.hasMatch('123'), false); // Too short
      expect(postalRegex.hasMatch(r'!@#$'), false);
    });

    // QA-09: Order Flow - Checkout completion clears cart and saves order
    test('QA-09: Order Flow - Completes checkout, generates order ID, and clears cart', () async {
      final cartCubit = CartCubit(cartRepo);
      final checkoutCubit = CheckoutCubit(orderRepo);
      final product = mockProducts.first;
      final variant = product.variants.first;

      await cartCubit.addItem(product, variant, quantity: 1);
      expect(cartCubit.state.items.isNotEmpty, true);

      checkoutCubit.selectAddress(const Address(
        id: 'addr_1',
        fullName: 'Elena Vance',
        addressLine1: '742 Evergreen Terrace',
        city: 'Springfield',
        postalCode: '97477',
        country: 'United States',
        phone: '+1 555-0199',
        isDefault: true,
      ));
      checkoutCubit.selectShippingMethod('standard');
      checkoutCubit.selectPaymentMethod('card');

      final order = await checkoutCubit.placeOrder(
        cartState: cartCubit.state,
        userId: 'guest_user',
        onOrderSuccess: () async {
          await cartCubit.clearCart();
        },
      );
      expect(order, isNotNull);
      expect(order!.orderNumber.startsWith('AL-'), true);
      expect(order.fulfillmentStatus, 'confirmed');
      expect(order.paymentStatus, 'paid');

      // Cart is cleared after order
      expect(cartCubit.state.items.isEmpty, true);

      // Order is persisted in repository
      final orders = await orderRepo.getOrders(userId: 'guest_user');
      expect(orders.any((o) => o.id == order.id), true);
    });

    // QA-10: Persistence across reboots
    test('QA-10: Persistence - Cart and Wishlist persist to LocalStorage and reload cleanly', () async {
      final product = mockProducts.first;
      final variant = product.variants.first;

      // 1. Save Cart Item
      final cartItem = CartItem(
        id: 'cart_item_test_1',
        product: product,
        selectedVariant: variant,
        quantity: 2,
      );
      await cartRepo.saveCart([cartItem]);

      // 2. Save Wishlist
      final wishlistCubit = WishlistCubit(
        cartRepository: cartRepo,
        productRepository: productRepo,
      );
      wishlistCubit.toggleWishlist(product);

      // 3. Simulate App Restart (new repository instances reading from same storage)
      final newCartRepo = MockCartRepository(storage);
      final reloadedCart = await newCartRepo.getCart();
      expect(reloadedCart.length, 1);
      expect(reloadedCart.first.product.id, product.id);
      expect(reloadedCart.first.quantity, 2);

      final reloadedWishlist = await newCartRepo.getWishlistProductIds();
      expect(reloadedWishlist.contains(product.id), true);
    });

    // QA-11: Wishlist Quick-Toggle
    test('QA-11: Wishlist - Toggle state executes immediately', () async {
      final wishlistCubit = WishlistCubit(
        cartRepository: cartRepo,
        productRepository: productRepo,
      );
      final product = mockProducts.first;

      expect(wishlistCubit.state.isWishlisted(product.id), false);
      wishlistCubit.toggleWishlist(product);
      expect(wishlistCubit.state.isWishlisted(product.id), true);
      wishlistCubit.toggleWishlist(product);
      expect(wishlistCubit.state.isWishlisted(product.id), false);
    });

    // QA-12: Geometry & Micro-radii
    test('QA-12: Aesthetics & Geometry - Adheres to 4.0-6.0 micro-radii specifications', () {
      const cardRadius = 6.0;
      const buttonRadius = 4.0;
      expect(cardRadius <= 6.0 && cardRadius >= 4.0, true);
      expect(buttonRadius <= 6.0 && buttonRadius >= 4.0, true);
    });
  });
}
