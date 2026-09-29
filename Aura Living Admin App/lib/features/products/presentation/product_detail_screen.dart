import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import 'products_controller.dart';
import 'widgets/stock_adjust_modal.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          if (user?.role.canCreateEditProduct ?? false)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/products/$productId/edit'),
            ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (products) {
          final product = products.firstWhere(
            (p) => p.id == productId,
            orElse: () => throw Exception('Product not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary Image Banner
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.textMuted),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 40, color: AppColors.textMuted),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Status
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: AppTypography.pageTitle.copyWith(fontSize: 18),
                            ),
                          ),
                          StatusBadge.stock(
                            product.totalStock,
                            isArchived: product.isArchived,
                            isDraft: product.isDraft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SKU / Slug: ${product.slug}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (product.discountPercentage > 0) ...[
                            Text(
                              AppFormatters.currency(product.finalPrice),
                              style: AppTypography.metricCallout.copyWith(
                                fontSize: 24,
                                color: AppColors.primaryOlive,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.currency(product.basePrice),
                              style: AppTypography.bodySmall.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${product.discountPercentage.toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              AppFormatters.currency(product.basePrice),
                              style: AppTypography.metricCallout.copyWith(
                                fontSize: 24,
                                color: AppColors.primaryOlive,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Inventory & Variants Breakdown Card
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
                          Text('Inventory Control', style: AppTypography.sectionHeader),
                          Text(
                            'Total Stock: ${product.totalStock} units',
                            style: AppTypography.dataLabel.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryOlive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (product.hasVariants && product.variants.isNotEmpty) ...[
                        Text(
                          'Variant Breakdown',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: product.variants.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final v = product.variants[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${v.attributeName}: ${v.attributeValue}',
                                        style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                                      ),
                                      Text(
                                        'SKU: ${v.sku}',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                  StatusBadge.stock(v.stockQuantity),
                                ],
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        Text(
                          'Single Stock Item (No variants)',
                          style: AppTypography.bodySmall,
                        ),
                      ],

                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Quick Stock Adjust',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.tune,
                        onPressed: () {
                          StockAdjustModal.show(
                            context,
                            product: product,
                            onSave: (newQty, variantId) async {
                              final repo = ref.read(productRepositoryProvider);
                              await repo.quickAdjustStock(product.id, newQty, variantId: variantId);
                              ref.invalidate(productsListProvider);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description Card
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
                      Text('Product Descriptions', style: AppTypography.sectionHeader),
                      const SizedBox(height: 10),
                      Text('Short Summary:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(product.shortDescription, style: AppTypography.bodySmall),
                      const SizedBox(height: 12),
                      Text('Full Specifications:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(product.description, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons Tray
                Row(
                  children: [
                    if (user?.role.canCreateEditProduct ?? false)
                      Expanded(
                        child: AppButton(
                          text: 'Edit Product',
                          variant: AppButtonVariant.primary,
                          icon: Icons.edit_outlined,
                          onPressed: () => context.push('/products/$productId/edit'),
                        ),
                      ),
                    if (user?.role.canHardDeleteProduct ?? false) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Delete',
                          variant: AppButtonVariant.destructive,
                          icon: Icons.delete_outline,
                          onPressed: () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: "Permanently delete '${product.title}'?",
                              message:
                                  'This action cannot be undone and will detach product history from unfulfilled orders.',
                              confirmLabel: 'Delete Forever',
                            );
                            if (confirmed) {
                              final repo = ref.read(productRepositoryProvider);
                              await repo.hardDeleteProduct(product.id);
                              ref.invalidate(productsListProvider);
                              if (context.mounted) {
                                context.pop();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
