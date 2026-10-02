import 'package:flutter_test/flutter_test.dart';
import 'package:aura_living_admin/core/utils/formatters.dart';
import 'package:aura_living_admin/core/utils/validators.dart';
import 'package:aura_living_admin/features/auth/domain/admin_user.dart';
import 'package:aura_living_admin/features/auth/data/auth_repository.dart';
import 'package:aura_living_admin/features/products/domain/product.dart';
import 'package:aura_living_admin/features/products/domain/product_variant.dart';
import 'package:aura_living_admin/features/products/data/product_repository.dart';
import 'package:aura_living_admin/features/orders/domain/order_status.dart';
import 'package:aura_living_admin/features/orders/data/order_repository.dart';
import 'package:aura_living_admin/features/reviews/domain/review.dart';
import 'package:aura_living_admin/features/reviews/data/review_repository.dart';
import 'package:aura_living_admin/features/promotions/data/promotion_repository.dart';
import 'package:aura_living_admin/features/dashboard/data/metrics_repository.dart';

void main() {
  group('AC-01: Authentication & RBAC Security Gate Tests', () {
    late MockAuthRepository authRepo;

    setUp(() {
      authRepo = MockAuthRepository();
    });

    test('Valid Super Admin credentials authenticate successfully', () async {
      final user = await authRepo.signIn('admin@auraliving.com', 'password123');
      expect(user, isNotNull);
      expect(user.role, equals(AdminRole.superAdmin));
      expect(user.role.canManageStoreSettings, isTrue);
      expect(user.role.canDeleteProducts, isTrue);
      expect(user.role.canManageCatalog, isTrue);
    });

    test('Valid Store Manager credentials authenticate with manager role', () async {
      final user = await authRepo.signIn('manager@auraliving.com', 'password123');
      expect(user, isNotNull);
      expect(user.role, equals(AdminRole.storeManager));
      expect(user.role.canManageCatalog, isTrue);
      expect(user.role.canDeleteProducts, isFalse); // Soft deactivate only
      expect(user.role.canManageStoreSettings, isFalse);
    });

    test('Valid Inventory Staff credentials authenticate with staff role', () async {
      final user = await authRepo.signIn('staff@auraliving.com', 'password123');
      expect(user, isNotNull);
      expect(user.role, equals(AdminRole.inventoryStaff));
      expect(user.role.canAdjustInventory, isTrue);
      expect(user.role.canUpdateOrderStatus, isTrue);
      expect(user.role.canManageCatalog, isFalse);
      expect(user.role.canModerateReviews, isFalse);
      expect(user.role.canViewCustomerPII, isFalse);
    });

    test('Non-admin customer account is rejected with Access Denied exception', () async {
      expect(
        () async => await authRepo.signIn('customer@example.com', 'password123'),
        throwsA(predicate((e) =>
            e.toString().contains('Access Denied: Account does not possess administrative privileges'))),
      );
    });

    test('Invalid credentials throw descriptive authentication exception', () async {
      expect(
        () async => await authRepo.signIn('admin@auraliving.com', 'wrongpassword'),
        throwsA(predicate((e) =>
            e.toString().contains('Invalid administrative credentials'))),
      );
    });

    test('Email and Password format validators enforce constraints', () {
      expect(AppValidators.validateEmail(''), equals('Email address is required'));
      expect(AppValidators.validateEmail('invalid-email'), equals('Please enter a valid email address'));
      expect(AppValidators.validateEmail('admin@auraliving.com'), isNull);

      expect(AppValidators.validatePassword(''), equals('Password is required'));
      expect(AppValidators.validatePassword('short'), equals('Password must be at least 8 characters'));
      expect(AppValidators.validatePassword('validpassword123'), isNull);
    });
  });

  group('AC-02: Dashboard Metrics & Aggregation Integrity', () {
    late MockProductRepository productRepo;
    late MockOrderRepository orderRepo;
    late MockReviewRepository reviewRepo;
    late MockMetricsRepository metricsRepo;

    setUp(() {
      productRepo = MockProductRepository();
      orderRepo = MockOrderRepository();
      reviewRepo = MockReviewRepository();
      metricsRepo = MockMetricsRepository(
        productRepo: productRepo,
        orderRepo: orderRepo,
        reviewRepo: reviewRepo,
      );
    });

    test('Accurately aggregates revenue, pending orders, low stock, and pending reviews', () async {
      final metrics = await metricsRepo.getDashboardMetrics();
      expect(metrics.todayRevenue, greaterThanOrEqualTo(0));
      expect(metrics.pendingOrdersCount, greaterThan(0));
      expect(metrics.lowStockCount, greaterThan(0));
      expect(metrics.pendingReviewsCount, greaterThan(0));
      expect(metrics.recentActivities, isNotEmpty);
    });
  });

  group('AC-03: Product Creation & Final Price Formula', () {
    test('Calculated final price accurately reflects discount percentage formula', () {
      final productWithDiscount = Product(
        id: 'test-01',
        title: 'Lounge Chair',
        slug: 'lounge-chair',
        categoryId: 'cat-furniture',
        description: 'Test chair',
        basePrice: 200.0,
        discountPercentage: 15.0,
        imageUrls: const ['https://example.com/img.jpg'],
        hasVariants: false,
        variants: const [],
        stockQuantity: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Base: 200.0 * (1 - 0.15) = 170.0
      expect(productWithDiscount.finalPrice, equals(170.0));
      expect(productWithDiscount.discountPercentage, equals(15.0));

      final productZeroDiscount = productWithDiscount.copyWith(discountPercentage: 0.0);
      expect(productZeroDiscount.finalPrice, equals(200.0));
    });

    test('Discount validator enforces 0-90% range constraints', () {
      expect(AppValidators.validateDiscount(''), isNull);
      expect(AppValidators.validateDiscount('-5'), equals('Discount cannot be negative'));
      expect(AppValidators.validateDiscount('95'), equals('Discount cannot exceed 90%'));
      expect(AppValidators.validateDiscount('15'), isNull);
    });
  });

  group('AC-04: Variant & Stock Controls and Thresholds', () {
    test('Low Stock (<= 5) and Out of Stock (0) status classifications', () {
      final inStockProduct = Product(
        id: 'prod-in-stock',
        title: 'In Stock Item',
        slug: 'in-stock-item',
        categoryId: 'cat-furniture',
        description: 'Description',
        basePrice: 50.0,
        discountPercentage: 0.0,
        imageUrls: const ['img.jpg'],
        hasVariants: false,
        variants: const [],
        stockQuantity: 24,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(inStockProduct.totalStock, equals(24));
      expect(inStockProduct.isLowStock, isFalse);
      expect(inStockProduct.isOutOfStock, isFalse);

      final lowStockProduct = inStockProduct.copyWith(stockQuantity: 4);
      expect(lowStockProduct.isLowStock, isTrue);
      expect(lowStockProduct.isOutOfStock, isFalse);

      final outOfStockProduct = inStockProduct.copyWith(stockQuantity: 0);
      expect(outOfStockProduct.isLowStock, isFalse);
      expect(outOfStockProduct.isOutOfStock, isTrue);
    });

    test('Variant stock quantities aggregate correctly to totalStock', () {
      const variant1 = ProductVariant(
        id: 'var-1',
        sku: 'SKU-A',
        attributeName: 'Color',
        attributeValue: 'White Oak',
        stockQuantity: 3,
      );
      const variant2 = ProductVariant(
        id: 'var-2',
        sku: 'SKU-B',
        attributeName: 'Color',
        attributeValue: 'Smoked Walnut',
        stockQuantity: 2,
      );

      final multiVariantProduct = Product(
        id: 'prod-multi',
        title: 'Multi Variant Chair',
        slug: 'multi-variant-chair',
        categoryId: 'cat-furniture',
        description: 'Description',
        basePrice: 100.0,
        discountPercentage: 0.0,
        imageUrls: const ['img.jpg'],
        hasVariants: true,
        variants: const [variant1, variant2],
        stockQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(multiVariantProduct.totalStock, equals(5));
      expect(multiVariantProduct.isLowStock, isTrue); // 5 <= 5
    });

    test('MockProductRepository quickAdjustStock updates inventory', () async {
      final repo = MockProductRepository();
      final products = await repo.getProducts();
      final target = products.firstWhere((p) => !p.hasVariants);

      await repo.quickAdjustStock(target.id, 3);
      final updated = await repo.getProductById(target.id);
      expect(updated?.stockQuantity, equals(3));
      expect(updated?.isLowStock, isTrue);
    });
  });

  group('AC-05: Destructive Action Safety & Product Deletion Guard', () {
    test('Guarded category deletion blocks deletion if category contains active products', () async {
      final repo = MockProductRepository();
      // cat-furniture contains 4 seeded active products
      expect(
        () async => await repo.deleteCategory('cat-furniture'),
        throwsA(predicate((e) =>
            e.toString().contains('Cannot delete category: contains active catalog products'))),
      );
    });

    test('Deactivate product sets status to Archived instead of deleting', () async {
      final repo = MockProductRepository();
      final products = await repo.getProducts();
      final first = products.first;

      final deactivated = await repo.deactivateProduct(first.id);
      expect(deactivated.status, equals('Archived'));

      final retrieved = await repo.getProductById(first.id);
      expect(retrieved?.status, equals('Archived'));
    });

    test('Hard delete permanently removes product from catalog', () async {
      final repo = MockProductRepository();
      final products = await repo.getProducts();
      final first = products.first;

      final success = await repo.hardDeleteProduct(first.id);
      expect(success, isTrue);

      final retrieved = await repo.getProductById(first.id);
      expect(retrieved, isNull);
    });
  });

  group('AC-06: Order Lifecycle Progression & Transition Constraints', () {
    late MockOrderRepository orderRepo;

    setUp(() {
      orderRepo = MockOrderRepository();
    });

    test('Permitted status transition from Pending to Processing', () async {
      final order = await orderRepo.transitionOrderStatus(
        orderId: 'AL-9842', // seeded as Pending
        newStatus: OrderStatus.processing,
        staffIdentifier: 'Astrid (Super Admin)',
      );
      expect(order.status, equals(OrderStatus.processing));
      expect(order.statusHistory.last.status, equals(OrderStatus.processing));
    });

    test('Illegal status transition throws validation exception (Pending directly to Delivered)', () async {
      expect(
        () async => await orderRepo.transitionOrderStatus(
          orderId: 'AL-9842',
          newStatus: OrderStatus.delivered,
          staffIdentifier: 'Astrid (Super Admin)',
        ),
        throwsA(predicate((e) => e.toString().contains('Invalid status transition'))),
      );
    });

    test('Transitioning to Shipped without tracking number is strictly rejected', () async {
      expect(
        () async => await orderRepo.transitionOrderStatus(
          orderId: 'AL-9841', // seeded as Processing
          newStatus: OrderStatus.shipped,
          trackingNumber: '', // Empty tracking number
          staffIdentifier: 'Astrid (Super Admin)',
        ),
        throwsA(predicate((e) => e.toString().contains('Tracking Reference number is mandatory'))),
      );
    });

    test('Transitioning to Shipped with valid tracking number succeeds', () async {
      final order = await orderRepo.transitionOrderStatus(
        orderId: 'AL-9841',
        newStatus: OrderStatus.shipped,
        trackingNumber: 'TRK-UPS-12345678',
        courierPartner: 'UPS Ground',
        staffIdentifier: 'Astrid (Super Admin)',
      );
      expect(order.status, equals(OrderStatus.shipped));
      expect(order.trackingNumber, equals('TRK-UPS-12345678'));
    });

    test('Cancelling an order without reason is rejected', () async {
      expect(
        () async => await orderRepo.transitionOrderStatus(
          orderId: 'AL-9842',
          newStatus: OrderStatus.cancelled,
          cancellationReason: '',
          staffIdentifier: 'Astrid (Super Admin)',
        ),
        throwsA(predicate((e) => e.toString().contains('Cancellation reason is required'))),
      );
    });

    test('Cancelling an order with reason marks status as cancelled and payment refunded', () async {
      final order = await orderRepo.transitionOrderStatus(
        orderId: 'AL-9842',
        newStatus: OrderStatus.cancelled,
        cancellationReason: 'Stock Discrepancy',
        staffIdentifier: 'Astrid (Super Admin)',
      );
      expect(order.status, equals(OrderStatus.cancelled));
      expect(order.cancellationReason, equals('Stock Discrepancy'));
      expect(order.paymentStatus, equals('Refunded'));
    });
  });

  group('AC-07: Review Moderation Queue & Actions', () {
    late MockReviewRepository reviewRepo;

    setUp(() {
      reviewRepo = MockReviewRepository();
    });

    test('Approving a pending review updates status to approved', () async {
      final approved = await reviewRepo.approveReview('rev-01');
      expect(approved.status, equals(ReviewStatus.approved));
    });

    test('Rejecting a pending review updates status and attaches rejection reason', () async {
      final rejected = await reviewRepo.rejectReview('rev-02', 'Spam or Promotional');
      expect(rejected.status, equals(ReviewStatus.rejected));
      expect(rejected.rejectionReason, equals('Spam or Promotional'));
    });

    test('Deleting a review permanently removes it from queue', () async {
      final success = await reviewRepo.deleteReview('rev-01');
      expect(success, isTrue);

      final reviews = await reviewRepo.getReviews();
      expect(reviews.any((r) => r.id == 'rev-01'), isFalse);
    });
  });

  group('AC-08 & Coupon Validation: Form Formatters & Coupon Limits', () {
    late MockPromotionRepository promoRepo;

    setUp(() {
      promoRepo = MockPromotionRepository();
    });

    test('Coupon code validator enforces uppercase alphanumeric format', () {
      expect(AppValidators.validateCouponCode(''), equals('Coupon code is required'));
      expect(AppValidators.validateCouponCode('inv@lid!'), equals('Code must only contain letters, numbers, or dashes'));
      expect(AppValidators.validateCouponCode('SPRING25'), isNull);
    });

    test('Toggle coupon active status mutates isActive boolean', () async {
      final toggled = await promoRepo.toggleCouponStatus('cpn-01');
      expect(toggled.isActive, isFalse);

      final toggledBack = await promoRepo.toggleCouponStatus('cpn-01');
      expect(toggledBack.isActive, isTrue);
    });

    test('Formatters correctly format currency and order numbers', () {
      expect(AppFormatters.formatCurrency(168.73), equals('৳168.73'));
      expect(AppFormatters.formatCurrency(0.0), equals('৳0'));
      expect(AppFormatters.formatOrderId('AL-9842'), equals('#AL-9842'));
      expect(AppFormatters.formatOrderId('#AL-9842'), equals('#AL-9842'));
    });
  });
}
