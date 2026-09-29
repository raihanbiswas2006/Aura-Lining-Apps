import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/status_badge.dart';
import 'customers_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  String _redact(String val, bool isStaff) {
    if (!isStaff) return val;
    if (val.contains('@')) {
      final parts = val.split('@');
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    }
    if (val.length > 6) {
      return '${val.substring(0, 3)}***${val.substring(val.length - 2)}';
    }
    return '***';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ordersAsync = ref.watch(customerOrdersProvider(customerId));
    final user = ref.watch(authControllerProvider).user;
    final isStaff = user?.role == AdminRole.inventoryStaff;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Customer Profile'),
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }

          final avgOrderVal = customer.totalOrdersCount > 0
              ? customer.lifetimeSpend / customer.totalOrdersCount
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Customer Identity Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryOlive.withOpacity(0.1),
                        child: Text(
                          customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOlive,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _redact(customer.email, isStaff),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _redact(customer.phone, isStaff),
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Customer since ${AppFormatters.formatDate(customer.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Lifetime Metrics Grid (3 cols)
                Row(
                  children: [
                    Expanded(
                      child: _metricBox('Total Orders', '${customer.totalOrdersCount}'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricBox('Lifetime Spend', AppFormatters.formatCurrency(customer.lifetimeSpend)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricBox('Average Order', AppFormatters.formatCurrency(avgOrderVal)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Default Address Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryOlive),
                          SizedBox(width: 6),
                          Text(
                            'Default Shipping Address',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isStaff
                            ? '${customer.defaultAddress.city}, ${customer.defaultAddress.state}, ${customer.defaultAddress.country}'
                            : customer.defaultAddress.fullFormatted,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Privacy Compliance Box per PRD Section 6.8
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Privacy Compliance: Customer payment cards and credentials are never stored or accessible to administrative personnel.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order History List
                const Text(
                  'Order History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                ordersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('No orders on record for this customer.', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            title: Row(
                              children: [
                                Text(
                                  '#${order.id}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                OrderStatusBadge(status: order.status),
                              ],
                            ),
                            subtitle: Text(
                              AppFormatters.formatDateTime(order.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatCurrency(order.totalAmount),
                                  style: AppTypography.monospacedNumber(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                            onTap: () {
                              context.push('/orders/detail/${order.id}');
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const ShimmerCard(height: 100),
                  error: (e, _) => Text('Error loading customer orders: $e'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _metricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.monospacedNumber(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
