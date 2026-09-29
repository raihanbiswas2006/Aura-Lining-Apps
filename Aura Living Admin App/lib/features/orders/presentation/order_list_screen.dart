import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/order.dart';
import '../domain/order_status.dart';
import 'orders_controller.dart';
import 'widgets/order_status_modal.dart';
import '../../auth/presentation/auth_controller.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<OrderStatus?> _tabs = const [
    null, // All
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final selected = _tabs[_tabController.index];
        ref.read(orderFilterProvider.notifier).update(
              (state) => state.copyWith(statusFilter: selected, clearStatusFilter: selected == null),
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openStatusModal(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderStatusModal(
        order: order,
        onTransitionCompleted: () {
          ref.invalidate(ordersStreamProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrdersAsync = ref.watch(filteredOrdersProvider);
    final user = ref.watch(authControllerProvider).user;
    final canUpdateOrders = user?.role.canUpdateOrderStatus ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Order Operations'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primaryOlive,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryOlive,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'All Orders'),
                Tab(text: 'Pending'),
                Tab(text: 'Confirmed'),
                Tab(text: 'Processing'),
                Tab(text: 'Handed to Courier'),
                Tab(text: 'Delivered'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search order ID (#AL-), customer, city...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(orderFilterProvider.notifier).update(
                                      (s) => s.copyWith(searchQuery: ''),
                                    );
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(orderFilterProvider.notifier).update(
                            (s) => s.copyWith(searchQuery: val.trim()),
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Orders List
          Expanded(
            child: filteredOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return EmptyStateView(
                    title: 'No Orders Found',
                    subtitle: 'There are no orders matching the selected filter criteria.',
                    icon: Icons.receipt_long_outlined,
                    actionButtonText: 'Reset Filters',
                    onAction: () {
                      _searchController.clear();
                      _tabController.animateTo(0);
                      ref.read(orderFilterProvider.notifier).update(
                            (s) => const OrderFilterState(),
                          );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      canUpdate: canUpdateOrders,
                      onTap: () {
                        context.push('/orders/detail/${order.id}');
                      },
                      onQuickTransition: () => _openStatusModal(order),
                    );
                  },
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const ShimmerCard(height: 140),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error loading orders: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool canUpdate;
  final VoidCallback onTap;
  final VoidCallback onQuickTransition;

  const _OrderCard({
    required this.order,
    required this.canUpdate,
    required this.onTap,
    required this.onQuickTransition,
  });

  @override
  Widget build(BuildContext context) {
    // Generate items summary string
    final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.productTitle}').join(', ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID, Time & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${AppFormatters.formatDateTime(order.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),

            // Customer Name & Area
            Row(
              children: [
                const Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${order.shippingAddress.city}, ${order.shippingAddress.state})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Items Summary
            Text(
              itemsSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Bottom Row: Total Amount & Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(order.totalAmount),
                      style: AppTypography.monospacedNumber(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (canUpdate && order.status.allowedNextStatuses.isNotEmpty) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.update, size: 14, color: AppColors.primaryOlive),
                        label: const Text(
                          'Update Status',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryOlive, fontWeight: FontWeight.w600),
                        ),
                        onPressed: onQuickTransition,
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
