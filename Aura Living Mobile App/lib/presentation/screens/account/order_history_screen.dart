import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/i_order_repository.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String? initialStatus;

  const OrderHistoryScreen({super.key, this.initialStatus});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Order>> _ordersFuture;

  final List<String> _tabs = ['All', 'Processing', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = getIt<IOrderRepository>().getOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.accentOlive;
      case 'processing':
        return AppColors.gold;
      case 'shipped':
        return AppColors.accentForest;
      case 'cancelled':
        return AppColors.warningTerracotta;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          final allOrders = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final status = tab.toLowerCase();
              final filtered = status == 'all'
                  ? allOrders
                  : allOrders
                      .where((o) => o.fulfillmentStatus.toLowerCase() == status)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text('No $tab Orders', style: AppTypography.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'You have no orders in this category yet.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  _loadOrders();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildOrderCard(context, order);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: AppTypography.titleSmall.copyWith(fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.fulfillmentStatus).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(order.fulfillmentStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    order.fulfillmentStatus.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(order.fulfillmentStatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} • ${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            // Item Thumbnails
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.items.length,
                separatorBuilder: (context, idx) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final it = order.items[idx];
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.surfaceSecondary,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      it.selectedVariant.imageUrls.isNotEmpty
                          ? it.selectedVariant.imageUrls.first
                          : it.product.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 20),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 20),

            // Bottom Total & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(order.totalAmount),
                  style: AppTypography.price.copyWith(fontSize: 15),
                ),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16),
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
