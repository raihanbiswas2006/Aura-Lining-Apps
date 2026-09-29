import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/order.dart';
import 'orders_controller.dart';
import 'widgets/order_status_modal.dart';
import '../../auth/presentation/auth_controller.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  void _openTransitionModal(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderStatusModal(
        order: order,
        onTransitionCompleted: () {
          ref.invalidate(orderDetailProvider(widget.orderId));
          ref.invalidate(ordersStreamProvider);
        },
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final user = ref.watch(authControllerProvider).user;
    final canUpdateOrders = user?.role.canUpdateOrderStatus ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('#${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Order',
            onPressed: () {
              ref.invalidate(orderDetailProvider(widget.orderId));
            },
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Order #${widget.orderId} not found', style: AppTypography.sectionHeader),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Orders'),
                  ),
                ],
              ),
            );
          }

          final nextAllowed = order.status.allowedNextStatuses;
          final hasNextTransition = nextAllowed.isNotEmpty && canUpdateOrders;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card: Status & Primary Action Button
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Placed on ${AppFormatters.formatDateTime(order.createdAt)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          OrderStatusBadge(status: order.status),
                        ],
                      ),
                      if (hasNextTransition) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Advance to ${nextAllowed.first.label}',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => _openTransitionModal(order),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Customer Note (if present)
                if (order.customerNote != null && order.customerNote!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 20, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Note',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.customerNote!,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Customer & Shipping Address Card
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
                          Icon(Icons.person_outline, size: 18, color: AppColors.primaryOlive),
                          SizedBox(width: 8),
                          Text(
                            'Customer & Delivery Details',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        order.customerName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(order.customerEmail, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Verified', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(order.customerPhone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.call, size: 18, color: AppColors.primaryOlive),
                            tooltip: 'Tap to Call Customer',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Dialing ${order.customerPhone}... (Device intent simulator)'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 8),
                      const Text(
                        'Shipping Destination:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingAddress.fullFormatted,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tracking Info (if available)
                if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.courierPartner ?? 'Courier Partner',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.trackingNumber!,
                              style: AppTypography.monospacedNumber(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.primaryOlive),
                          tooltip: 'Copy Tracking Code',
                          onPressed: () => _copyToClipboard(order.trackingNumber!, 'Tracking Number'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Items Breakdown Table
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ordered Items',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${order.items.length} items',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 10),

                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.surfaceSecondary,
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productTitle,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    if (item.variantAttributes != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.variantAttributes!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity} x ${AppFormatters.formatCurrency(item.unitPrice)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              // Subtotal
                              Text(
                                AppFormatters.formatCurrency(item.subtotal),
                                style: AppTypography.monospacedNumber(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Financial Summary Card
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
                      const Text(
                        'Payment & Financial Summary',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _summaryRow('Subtotal', AppFormatters.formatCurrency(order.subtotal)),
                      if (order.discountAmount > 0)
                        _summaryRow(
                          'Discount (${order.couponCode ?? "Promotion"})',
                          '-${AppFormatters.formatCurrency(order.discountAmount)}',
                          textColor: AppColors.success,
                        ),
                      _summaryRow(
                        'Shipping Fee',
                        order.shippingFee == 0 ? 'FREE' : AppFormatters.formatCurrency(order.shippingFee),
                      ),
                      _summaryRow('Estimated Tax', AppFormatters.formatCurrency(order.estimatedTax)),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            AppFormatters.formatCurrency(order.totalAmount),
                            style: AppTypography.monospacedNumber(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryOlive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 10),

                      // Payment info & Settlement Warning
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment: ${order.paymentMethod}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              if (order.transactionReference != null)
                                Text(
                                  'Ref: ${order.transactionReference}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.paymentStatus == 'Paid'
                                  ? AppColors.successBg
                                  : (order.paymentStatus == 'Refunded' ? AppColors.dangerBg : AppColors.surfaceSecondary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.paymentStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: order.paymentStatus == 'Paid'
                                    ? AppColors.success
                                    : (order.paymentStatus == 'Refunded' ? AppColors.danger : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Payment settlements: VERIFY BEFORE IMPLEMENTATION (Live webhooks in Phase 3).',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Audit History
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
                      const Text(
                        'Operational Activity Log',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...order.statusHistory.reversed.map((log) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryOlive,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          log.status.label,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          AppFormatters.formatDateTime(log.timestamp),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Staff: ${log.staffIdentifier}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    if (log.note != null && log.note!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        log.note!,
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ShimmerLoader(height: 120),
            SizedBox(height: 12),
            ShimmerLoader(height: 160),
            SizedBox(height: 12),
            ShimmerLoader(height: 200),
          ],
        ),
        error: (err, stack) => Center(
          child: Text('Error loading order: $err'),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
