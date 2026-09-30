import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/orders/data/order_repository.dart';
import '../../features/reviews/data/review_repository.dart';
import '../../features/promotions/data/promotion_repository.dart';
import '../../features/customers/data/customer_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/dashboard/data/metrics_repository.dart';

import '../../features/products/data/firestore_product_repository.dart';
import '../../features/orders/data/firestore_order_repository.dart';
import '../services/firebase/firestore_admin_service.dart';

final firestoreAdminServiceProvider = Provider<FirestoreAdminService>((ref) {
  return FirestoreAdminService();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirestoreProductRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirestoreOrderRepository();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return MockReviewRepository();
});

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return MockPromotionRepository();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return MockCustomerRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});

final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final orderRepo = ref.watch(orderRepositoryProvider);
  final reviewRepo = ref.watch(reviewRepositoryProvider);

  return MockMetricsRepository(
    productRepo: productRepo,
    orderRepo: orderRepo,
    reviewRepo: reviewRepo,
  );
});
