import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

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
        title: Text('#${order.orderNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placed on ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(order.fulfillmentStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Vertical Tracking Timeline
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHIPMENT PROGRESS', style: AppTypography.overline),
                const SizedBox(height: 16),
                ...order.timeline.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final event = entry.value;
                  final isLast = idx == order.timeline.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline indicator column
                      Column(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: event.isCompleted
                                  ? AppColors.primary
                                  : AppColors.surface,
                              border: Border.all(
                                color: event.isCompleted
                                    ? AppColors.primary
                                    : AppColors.borderDark,
                                width: 2,
                              ),
                            ),
                            child: event.isCompleted
                                ? const Center(
                                    child: Icon(Icons.check, size: 10, color: Colors.white),
                                  )
                                : null,
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 38,
                              color: event.isCompleted
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Timeline details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.statusTitle,
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 13,
                                  color: event.isCompleted
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.description,
                                style: AppTypography.bodySmall.copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')} • ${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Items in Order
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORDERED PIECES (${order.itemCount})', style: AppTypography.overline),
                const SizedBox(height: 14),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surfaceSecondary,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            item.selectedVariant.imageUrls.isNotEmpty
                                ? item.selectedVariant.imageUrls.first
                                : item.product.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title,
                                style: AppTypography.titleSmall.copyWith(fontSize: 13),
                              ),
                              Text(
                                '${item.selectedVariant.title} • Qty: ${item.quantity}',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: AppTypography.price.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shipping and Billing Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DELIVERY & BILLING', style: AppTypography.overline),
                const SizedBox(height: 10),
                Text(order.shippingAddress.fullName, style: AppTypography.titleSmall),
                Text(order.shippingAddress.formattedAddress, style: AppTypography.bodySmall),
                Text(order.shippingAddress.phone, style: AppTypography.bodySmall),
                const Divider(height: 20),
                Text('Shipping Method: ${order.shippingMethod}', style: AppTypography.bodySmall),
                Text('Payment Status: ${order.paymentStatus.toUpperCase()}', style: AppTypography.bodySmall),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Charged', style: AppTypography.titleSmall),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: AppTypography.price.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
