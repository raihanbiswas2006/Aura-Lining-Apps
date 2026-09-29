import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/aura_button.dart';
import '../../../domain/entities/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;
  final VoidCallback onContinueShopping;
  final VoidCallback onViewOrders;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.onContinueShopping,
    required this.onViewOrders,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onContinueShopping();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Order Confirmed'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              // Animated Checkmark Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.accentForest,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Thank You For Your Order',
                style: AppTypography.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order Reference: #${order.orderNumber}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.accentOlive,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A confirmation receipt has been generated. Your artisanal pieces are now being carefully inspected at our studio.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Order Summary Card
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
                    Text('SHIPMENT DETAILS', style: AppTypography.overline),
                    const SizedBox(height: 10),
                    Text(
                      order.shippingAddress.fullName,
                      style: AppTypography.titleSmall.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.shippingAddress.formattedAddress,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.shippingAddress.phone,
                      style: AppTypography.bodySmall,
                    ),
                    const Divider(height: 24),

                    Text('DELIVERY METHOD', style: AppTypography.overline),
                    const SizedBox(height: 6),
                    Text(
                      order.shippingMethod,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const Divider(height: 24),

                    Text('ITEMS ORDERED (${order.itemCount})', style: AppTypography.overline),
                    const SizedBox(height: 10),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}× ${item.product.title} (${item.selectedVariant.title})',
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount Paid', style: AppTypography.titleSmall),
                        Text(
                          CurrencyFormatter.format(order.totalAmount),
                          style: AppTypography.price.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action CTAs
              AuraPrimaryButton(
                label: 'View Order in Profile',
                onPressed: onViewOrders,
              ),
              const SizedBox(height: 12),
              AuraOutlineButton(
                label: 'Continue Shopping',
                onPressed: onContinueShopping,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
