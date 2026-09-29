import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/stock_badge.dart';
import '../../domain/entities/product.dart';
import '../blocs/cart/cart_cubit.dart';
import '../blocs/wishlist/wishlist_cubit.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showQuickAdd;
  final VoidCallback? onQuickAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showQuickAdd = true,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final defaultVar = product.defaultVariant;
    final hasDiscount = defaultVar.compareAtPrice != null &&
        defaultVar.compareAtPrice! > defaultVar.price;
    final discountPercent = hasDiscount
        ? (((defaultVar.compareAtPrice! - defaultVar.price) /
                    defaultVar.compareAtPrice!) *
                100)
            .round()
        : 0;

    return Semantics(
      label: '${product.title}, ${CurrencyFormatter.format(product.price)}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with 4:5 aspect ratio
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: AppColors.surfaceSecondary,
                        child: Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surfaceSecondary,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceSecondary,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Discount tag (top left)
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.discountBadge,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Wishlist heart toggle button (top right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: BlocBuilder<WishlistCubit, WishlistState>(
                        builder: (context, state) {
                          final isFav = state.isWishlisted(product.id);
                          return Semantics(
                            label: isFav
                                ? 'Remove ${product.title} from wishlist'
                                : 'Add ${product.title} to wishlist',
                            button: true,
                            child: Material(
                              color: Colors.white.withOpacity(0.9),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  context
                                      .read<WishlistCubit>()
                                      .toggleWishlist(product);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                    color: isFav
                                        ? AppColors.discountBadge
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Quick add bar (bottom of image)
                    if (showQuickAdd && !product.isSoldOut)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Material(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: onQuickAdd ?? () {
                              context.read<CartCubit>().addItem(
                                    product,
                                    product.defaultVariant,
                                  );
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added ${product.title} to bag',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'View Cart',
                                    textColor: AppColors.accentOlive,
                                    onPressed: () {
                                      // handled via parent or shell
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Quick Add',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand / Category Tag
                    Text(
                      product.brand.toUpperCase(),
                      style: AppTypography.overline.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Title
                    Text(
                      product.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Price & Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(product.price),
                              style: AppTypography.price.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 4),
                              Text(
                                CurrencyFormatter.format(
                                  defaultVar.compareAtPrice!,
                                ),
                                style: AppTypography.priceOld.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Stock indicator
                        StockBadge(
                          stockQuantity: defaultVar.stockQuantity,
                          isCompact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
