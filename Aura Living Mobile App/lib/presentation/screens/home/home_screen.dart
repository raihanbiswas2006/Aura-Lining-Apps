import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../blocs/wishlist/wishlist_cubit.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  final void Function(Product product) onProductSelected;
  final void Function(Category category) onCategorySelected;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenWishlist;
  final void Function(String tag, String title) onCollectionSelected;

  const HomeScreen({
    super.key,
    required this.onProductSelected,
    required this.onCategorySelected,
    required this.onOpenSearch,
    required this.onOpenCart,
    required this.onOpenWishlist,
    required this.onCollectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: false,
        title: Text(
          'AURA LIVING',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: onOpenSearch,
            tooltip: 'Search collections',
          ),
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              final count = state.productIds.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 22),
                    onPressed: onOpenWishlist,
                    tooltip: 'Wishlist',
                  ),
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.discountBadge,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              final count = state.totalItemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    onPressed: onOpenCart,
                    tooltip: 'Shopping Bag',
                  ),
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const ProductGridSkeleton(count: 6);
          }

          final featuredProducts = state.products
              .where((p) => p.tags.contains('featured'))
              .toList();
          final newArrivals = state.products
              .where((p) => p.tags.contains('new-arrival'))
              .toList();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await context.read<CatalogCubit>().loadCatalog();
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Announcement Bar from web storefront
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  child: Center(
                    child: Text(
                      'COMPLIMENTARY DELIVERY ACROSS BANGLADESH OVER ৳5,000 • DEMO ENVIRONMENT',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.surface,
                        fontSize: 9.5,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                // Hero Editorial Carousel / Banner
                _buildHeroBanner(context),
                const SizedBox(height: 24),

                // Quick Category Rail
                _buildCategoryRail(context, state.categories),
                const SizedBox(height: 32),

                // Curated Grid Section 1: Staff Curations / Featured
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SEASONAL CURATION', style: AppTypography.overline),
                          const SizedBox(height: 2),
                          Text('Enduring Essentials', style: AppTypography.titleLarge),
                        ],
                      ),
                      TextButton(
                        onPressed: () => onCollectionSelected('featured', 'Enduring Essentials'),
                        child: Text(
                          'View All',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: featuredProducts.take(4).length,
                    itemBuilder: (context, index) {
                      final product = featuredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => onProductSelected(product),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Secondary Editorial Lookbook Card
                _buildLookbookCard(context),
                const SizedBox(height: 32),

                // Curated Grid Section 2: New Arrivals
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FRESH ATELIER DROPS', style: AppTypography.overline),
                          const SizedBox(height: 2),
                          Text('New Arrivals', style: AppTypography.titleLarge),
                        ],
                      ),
                      TextButton(
                        onPressed: () => onCollectionSelected('new-arrival', 'New Arrivals'),
                        child: Text(
                          'View All',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: newArrivals.take(4).length,
                    itemBuilder: (context, index) {
                      final product = newArrivals[index];
                      return ProductCard(
                        product: product,
                        onTap: () => onProductSelected(product),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceSecondary,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1200&q=85',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceSecondary),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AUTUMN EQUINOX EDIT 2026',
                    style: AppTypography.overline.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Living Spaces\nReimagined',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Curated furniture and architectural lighting engineered with warm minimalist modernism.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(160, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => onCollectionSelected('living', 'Autumn Living Collection'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Collection',
                        style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRail(BuildContext context, List<Category> categories) {
    final rootCategories = categories
        .where((c) => c.parentCategoryId == null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('EXPLORE DISCIPLINES', style: AppTypography.overline),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 106,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: rootCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cat = rootCategories[index];
              return GestureDetector(
                onTap: () => onCategorySelected(cat),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceSecondary,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: cat.imageUrl != null
                          ? Image.network(
                              cat.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.category,
                                color: AppColors.textMuted,
                              ),
                            )
                          : const Icon(Icons.category),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.title,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLookbookCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EDITORIAL ESSAY', style: AppTypography.overline),
          const SizedBox(height: 6),
          Text(
            'The Tactile Haven',
            style: AppTypography.displaySmall.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore our curations in raw volcanic stoneware, unbleached Flanders flax, and Roman travertine. Made to bring calm rhythm to your interior landscape.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 40),
            ),
            onPressed: () => onCollectionSelected('textiles', 'Organic Linens & Textiles'),
            child: const Text('Read & Shop Curation'),
          ),
        ],
      ),
    );
  }
}
