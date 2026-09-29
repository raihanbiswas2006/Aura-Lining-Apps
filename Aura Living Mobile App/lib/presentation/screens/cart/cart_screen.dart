import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/aura_button.dart';
import '../../../domain/entities/cart_item.dart';
import '../../blocs/cart/cart_cubit.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback onProceedToCheckout;
  final VoidCallback onExplore;

  const CartScreen({
    super.key,
    required this.onProceedToCheckout,
    required this.onExplore,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    await context.read<CartCubit>().applyCoupon(code);
    setState(() => _isApplyingCoupon = false);
    _couponController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shopping Bag'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context.read<CartCubit>().clearCart();
                },
                child: Text(
                  'Clear',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warningTerracotta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Stock adjustment warning banner if any (PRD 6.1)
              if (state.warningMessage != null)
                Container(
                  width: double.infinity,
                  color: AppColors.warningTerracotta.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.warningTerracotta,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.warningMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warningTerracotta,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Items List & Summary
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Line Items
                    ...state.items.map((item) => _buildCartItemTile(context, item)),
                    const SizedBox(height: 16),

                    // Coupon Input & Applied Badge
                    _buildCouponSection(context, state),
                    const SizedBox(height: 24),

                    // Cost Breakdown
                    _buildCostSummary(state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Sticky Bottom Checkout Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Amount', style: AppTypography.bodySmall),
                              Text(
                                CurrencyFormatter.format(state.totalAmount),
                                style: AppTypography.displaySmall.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          AuraPrimaryButton(
                            width: 190,
                            label: 'Checkout',
                            onPressed: state.hasOutOfStockItems
                                ? null
                                : widget.onProceedToCheckout,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 38,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Cart is Empty',
              style: AppTypography.displaySmall.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover pieces designed to elevate your everyday living spaces.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
              ),
              onPressed: widget.onExplore,
              child: const Text('Explore Catalog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemTile(BuildContext context, CartItem item) {
    final variant = item.selectedVariant;
    final maxStock = variant.stockQuantity;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.warningTerracotta,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<CartCubit>().removeItem(item.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppColors.surfaceSecondary,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                variant.imageUrls.isNotEmpty
                    ? variant.imageUrls.first
                    : item.product.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: AppTypography.titleSmall.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    variant.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(item.totalPrice),
                        style: AppTypography.price.copyWith(fontSize: 14),
                      ),

                      // Stepper (capped at stockQuantity per QA-06)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                context.read<CartCubit>().updateQuantity(
                                      item.id,
                                      item.quantity - 1,
                                    );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.remove, size: 14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${item.quantity}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              // Stepper + disables when at max stock (AC-2.3, QA-06)
                              onTap: item.quantity < maxStock
                                  ? () {
                                      context.read<CartCubit>().updateQuantity(
                                            item.id,
                                            item.quantity + 1,
                                          );
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.add,
                                  size: 14,
                                  color: item.quantity < maxStock
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context, CartState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 16),
              const SizedBox(width: 8),
              Text('PROMO OR VOUCHER CODE', style: AppTypography.overline),
            ],
          ),
          const SizedBox(height: 10),

          if (state.appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentOlive.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accentOlive.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.accentOlive),
                      const SizedBox(width: 6),
                      Text(
                        '${state.appliedCoupon!.code} Applied',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentOlive,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      context.read<CartCubit>().removeCoupon();
                    },
                    child: const Icon(Icons.close, size: 16, color: AppColors.accentOlive),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _couponController,
                      style: AppTypography.bodyMedium,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'e.g. AURA10, MINIMALIST',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: _isApplyingCoupon ? null : _applyCoupon,
                    child: _isApplyingCoupon
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],

          if (state.couponError != null) ...[
            const SizedBox(height: 6),
            Text(
              state.couponError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warningTerracotta,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostSummary(CartState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER SUMMARY', style: AppTypography.overline),
          const SizedBox(height: 12),

          _buildSummaryRow('Subtotal', CurrencyFormatter.format(state.subtotal)),
          if (state.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Discount (${state.appliedCoupon?.code})',
              '-${CurrencyFormatter.format(state.discountAmount)}',
              isGreen: true,
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Shipping',
            state.shippingCost == 0.0
                ? 'FREE'
                : CurrencyFormatter.format(state.shippingCost),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Estimated Tax', CurrencyFormatter.format(state.estimatedTax)),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            CurrencyFormatter.format(state.totalAmount),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isGreen = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTypography.titleSmall
              : AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: isBold
              ? AppTypography.price.copyWith(fontSize: 16)
              : AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isGreen ? AppColors.accentOlive : AppColors.textPrimary,
                ),
        ),
      ],
    );
  }
}
