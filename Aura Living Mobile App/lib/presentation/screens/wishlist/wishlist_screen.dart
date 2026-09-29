import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/wishlist/wishlist_cubit.dart';
import '../../widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  final void Function(Product product) onProductSelected;
  final VoidCallback onExplore;

  const WishlistScreen({
    super.key,
    required this.onProductSelected,
    required this.onExplore,
  });

  void _showVariantSelectorSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Variant', style: AppTypography.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Choose a colorway and proportion for ${product.title}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              ...product.variants.map((v) {
                final isOutOfStock = v.stockQuantity <= 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !isOutOfStock,
                  title: Text(v.title, style: AppTypography.titleSmall),
                  subtitle: Text(
                    isOutOfStock ? 'Sold Out' : CurrencyFormatter.format(v.price),
                    style: AppTypography.bodySmall.copyWith(
                      color: isOutOfStock ? AppColors.warningTerracotta : AppColors.textPrimary,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: isOutOfStock
                        ? null
                        : () {
                            context.read<CartCubit>().addItem(product, v);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${v.title} to bag'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                    child: Text(isOutOfStock ? 'Sold Out' : 'Add'),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Pieces'),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state.products.isEmpty) {
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
                          Icons.favorite_border,
                          size: 38,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Saved Pieces',
                      style: AppTypography.displaySmall.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save items you love to review them anytime or purchase them later.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180, 48),
                      ),
                      onPressed: onExplore,
                      child: const Text('Start Exploring'),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
            ),
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return ProductCard(
                product: product,
                onTap: () => onProductSelected(product),
                onQuickAdd: product.variants.length > 1
                    ? () => _showVariantSelectorSheet(context, product)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
