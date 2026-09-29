/// Activity Log entry for dashboard recent feed
class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String type; // 'order', 'stock', 'review', 'product', 'coupon'
  final String? targetId;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.targetId,
  });
}

/// Aggregated Operational Metrics Model per PRD Section 6.2
class DashboardMetrics {
  final double todayRevenue;
  final int pendingOrdersCount;
  final int lowStockCount;
  final int pendingReviewsCount;
  final List<ActivityItem> recentActivities;

  const DashboardMetrics({
    this.todayRevenue = 0.0,
    this.pendingOrdersCount = 0,
    this.lowStockCount = 0,
    this.pendingReviewsCount = 0,
    this.recentActivities = const [],
  });

  DashboardMetrics copyWith({
    double? todayRevenue,
    int? pendingOrdersCount,
    int? lowStockCount,
    int? pendingReviewsCount,
    List<ActivityItem>? recentActivities,
  }) {
    return DashboardMetrics(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      pendingReviewsCount: pendingReviewsCount ?? this.pendingReviewsCount,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
}
