import 'dart:async';
import '../domain/dashboard_metrics.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_status.dart';
import '../../products/data/product_repository.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/domain/review.dart';

abstract class MetricsRepository {
  Future<DashboardMetrics> getMetrics();
  Future<DashboardMetrics> getDashboardMetrics();
  Stream<DashboardMetrics> watchMetrics();
}

class MockMetricsRepository implements MetricsRepository {
  final ProductRepository productRepo;
  final OrderRepository orderRepo;
  final ReviewRepository reviewRepo;
  final _metricsStream = StreamController<DashboardMetrics>.broadcast();

  MockMetricsRepository({
    required this.productRepo,
    required this.orderRepo,
    required this.reviewRepo,
  }) {
    productRepo.watchProducts().listen((_) => _recalculate());
    orderRepo.watchOrders().listen((_) => _recalculate());
    reviewRepo.watchReviews().listen((_) => _recalculate());
  }

  void _recalculate() async {
    final metrics = await getMetrics();
    _metricsStream.add(metrics);
  }

  @override
  Stream<DashboardMetrics> watchMetrics() {
    return _metricsStream.stream;
  }

  @override
  Future<DashboardMetrics> getMetrics() async {
    final products = await productRepo.getProducts();
    final orders = await orderRepo.getOrders();
    final reviews = await reviewRepo.getReviews();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Today's revenue from non-cancelled orders
    final todayRevenue = orders
        .where((o) =>
            o.createdAt.isAfter(todayStart) && o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    // Pending orders count
    final pendingOrders =
        orders.where((o) => o.status == OrderStatus.pending).length;

    // Low stock count: products or variants with stock <= 5
    int lowStockCount = 0;
    for (final p in products) {
      if (p.hasVariants) {
        lowStockCount += p.variants.where((v) => v.isLowStock || v.isOutOfStock).length;
      } else if (p.isLowStock || p.isOutOfStock) {
        lowStockCount++;
      }
    }

    // Pending reviews count
    final pendingReviews =
        reviews.where((r) => r.status == ReviewStatus.pending).length;

    // Recent activities (5 system events)
    final recentActivities = [
      ActivityItem(
        id: 'act-01',
        title: 'Order Dispatched',
        subtitle: 'Order #AL-9839 marked as Shipped via DHL',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: 'order',
      ),
      ActivityItem(
        id: 'act-02',
        title: 'Stock Updated',
        subtitle: 'Kanso Ceramic Ribbed Vase updated to 4 units',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        type: 'stock',
      ),
      ActivityItem(
        id: 'act-03',
        title: 'New Customer Review',
        subtitle: 'Klara Blom reviewed Nordic Minimalist Oak Chair (5 stars)',
        timestamp: now.subtract(const Duration(hours: 4)),
        type: 'review',
      ),
      ActivityItem(
        id: 'act-04',
        title: 'Order Processing',
        subtitle: 'Order #AL-9841 moved to Processing by Astrid',
        timestamp: now.subtract(const Duration(hours: 6)),
        type: 'order',
      ),
      ActivityItem(
        id: 'act-05',
        title: 'Promotion Created',
        subtitle: 'Coupon AURA10 active (10% off orders > \$50)',
        timestamp: now.subtract(const Duration(days: 1)),
        type: 'coupon',
      ),
    ];

    return DashboardMetrics(
      todayRevenue: todayRevenue,
      pendingOrdersCount: pendingOrders,
      lowStockCount: lowStockCount,
      pendingReviewsCount: pendingReviews,
      recentActivities: recentActivities,
    );
  }

  @override
  Future<DashboardMetrics> getDashboardMetrics() => getMetrics();
}
