import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';
import '../domain/dashboard_metrics.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    final now = DateTime.now();
    final dateDisplay = DateFormat('EEEE, MMM d • HH:mm').format(now);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryOlive,
          onRefresh: () async {
            ref.invalidate(dashboardMetricsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Greeting Bar per PRD Section 6.2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Welcome, ${user?.name.split(' ').first ?? 'Admin'}',
                                style: AppTypography.pageTitle,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOlive.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: AppColors.primaryOlive.withOpacity(0.2),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  user?.role.label ?? 'Admin',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryOlive,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateDisplay,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications: All systems operational.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Actions Tray per PRD Section 6.2
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _quickActionPill(
                        context: context,
                        icon: Icons.add,
                        label: 'Add Product',
                        onTap: () {
                          if (user?.role == AdminRole.inventoryStaff) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inventory Staff has Read-Only access to catalog creation.'),
                              ),
                            );
                            return;
                          }
                          context.push('/products/add');
                        },
                      ),
                      const SizedBox(width: 8),
                      _quickActionPill(
                        context: context,
                        icon: Icons.inventory_2_outlined,
                        label: 'Update Stock',
                        onTap: () => context.go('/products?filter=low_stock'),
                      ),
                      const SizedBox(width: 8),
                      _quickActionPill(
                        context: context,
                        icon: Icons.confirmation_number_outlined,
                        label: 'Create Coupon',
                        onTap: () {
                          if (user?.role == AdminRole.inventoryStaff) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inventory Staff cannot manage promotion codes.'),
                              ),
                            );
                            return;
                          }
                          context.push('/moderation/coupons/add');
                        },
                      ),
                      const SizedBox(width: 8),
                      _quickActionPill(
                        context: context,
                        icon: Icons.category_outlined,
                        label: 'Categories',
                        onTap: () => context.push('/products/categories'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Operational Metric Grid (2x2) per PRD Section 6.2
                metricsAsync.when(
                  loading: () => const Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: MetricCardSkeleton()),
                          SizedBox(width: 12),
                          Expanded(child: MetricCardSkeleton()),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: MetricCardSkeleton()),
                          SizedBox(width: 12),
                          Expanded(child: MetricCardSkeleton()),
                        ],
                      ),
                    ],
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Failed to load metrics: $err'),
                  ),
                  data: (metrics) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              title: "Today's Revenue",
                              value: AppFormatters.compactCurrency(metrics.todayRevenue),
                              icon: Icons.payments_outlined,
                              isMonospaced: true,
                              accentColor: AppColors.primaryOlive,
                              badgeText: 'Net Monitored',
                              onTap: () => context.go('/orders'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Pending Orders',
                              value: '${metrics.pendingOrdersCount}',
                              icon: Icons.shopping_bag_outlined,
                              accentColor: metrics.pendingOrdersCount > 0
                                  ? AppColors.warning
                                  : AppColors.success,
                              badgeText: metrics.pendingOrdersCount > 0
                                  ? 'Awaiting Packing'
                                  : 'Fulfilled',
                              onTap: () => context.go('/orders?status=pending'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              title: 'Low Stock Alerts',
                              value: '${metrics.lowStockCount}',
                              icon: Icons.warning_amber_rounded,
                              accentColor: metrics.lowStockCount > 0
                                  ? AppColors.danger
                                  : AppColors.success,
                              badgeText: metrics.lowStockCount > 0
                                  ? '≤ 5 Units Alert'
                                  : 'Optimal Stock',
                              onTap: () => context.go('/products?filter=low_stock'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              title: 'Pending Reviews',
                              value: '${metrics.pendingReviewsCount}',
                              icon: Icons.reviews_outlined,
                              accentColor: metrics.pendingReviewsCount > 0
                                  ? AppColors.info
                                  : AppColors.textSecondary,
                              badgeText: metrics.pendingReviewsCount > 0
                                  ? 'Requires Action'
                                  : 'Moderated',
                              onTap: () => context.go('/moderation'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Recent Activity Feed per PRD Section 6.2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity Feed',
                      style: AppTypography.sectionHeader,
                    ),
                    Text(
                      'Last 5 Events',
                      style: AppTypography.dataLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                metricsAsync.when(
                  loading: () => Column(
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: ShimmerLoader(height: 60),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (metrics) {
                    if (metrics.recentActivities.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.history_toggle_off,
                        title: 'No Store Activity',
                        subtitle: 'No store activity recorded yet.',
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: metrics.recentActivities.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final act = metrics.recentActivities[index];
                          return _activityTile(context, act);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primaryOlive),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    bool isMonospaced = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.dataLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, size: 18, color: accentColor),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: isMonospaced
                    ? AppTypography.metricCallout.copyWith(fontSize: 22)
                    : AppTypography.pageTitle.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityTile(BuildContext context, ActivityItem item) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case 'order':
        icon = Icons.receipt_long_outlined;
        iconColor = AppColors.info;
        break;
      case 'stock':
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.warning;
        break;
      case 'review':
        icon = Icons.star_border_rounded;
        iconColor = AppColors.success;
        break;
      case 'coupon':
        icon = Icons.local_offer_outlined;
        iconColor = AppColors.primaryOlive;
        break;
      default:
        icon = Icons.notifications_none_outlined;
        iconColor = AppColors.textSecondary;
    }

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      title: Text(
        item.title,
        style: AppTypography.bodyMedium.copyWith(fontSize: 13),
      ),
      subtitle: Text(
        item.subtitle,
        style: AppTypography.caption,
      ),
      trailing: Text(
        AppFormatters.relativeTime(item.timestamp),
        style: AppTypography.caption.copyWith(fontSize: 10),
      ),
      onTap: () {
        if (item.type == 'order' && item.targetId != null) {
          context.push('/orders/${item.targetId}');
        } else if (item.type == 'review') {
          context.go('/moderation');
        } else if (item.type == 'stock') {
          context.go('/products?filter=low_stock');
        }
      },
    );
  }
}
