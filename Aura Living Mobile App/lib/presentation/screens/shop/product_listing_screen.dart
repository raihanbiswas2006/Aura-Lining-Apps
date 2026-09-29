import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../widgets/product_card.dart';
import 'widgets/filter_sort_sheet.dart';

class ProductListingScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryTitle;
  final String? initialSearchQuery;
  final String? initialTag;
  final void Function(Product product) onProductSelected;

  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.categoryTitle,
    this.initialSearchQuery,
    this.initialTag,
    required this.onProductSelected,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogCubit>().loadCatalog(
            initialCategoryId: widget.categoryId,
            tag: widget.initialTag,
          );
    });
  }

  void _openFilterSheet(BuildContext context, CatalogState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterSortBottomSheet(
        initialFilter: state.filter,
        initialSortBy: state.sortBy,
        availableColors: state.allAvailableColors,
        totalMatchingItems: state.filteredProducts.length,
        onApply: (newFilter, newSortBy) {
          final cubit = context.read<CatalogCubit>();
          cubit.setPriceRange(newFilter.minPrice, newFilter.maxPrice);
          // Apply colors
          for (final c in state.allAvailableColors) {
            final wasSelected = state.filter.selectedColors.contains(c);
            final nowSelected = newFilter.selectedColors.contains(c);
            if (wasSelected != nowSelected) {
              cubit.toggleColor(c);
            }
          }
          cubit.setInStockOnly(newFilter.inStockOnly);
          cubit.setSortBy(newSortBy);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle ??
              (widget.initialSearchQuery != null
                  ? 'Search: "${widget.initialSearchQuery}"'
                  : 'All Pieces'),
        ),
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const ProductGridSkeleton(count: 6);
          }

          final displayProducts = widget.initialSearchQuery != null
              ? state.filteredProducts.where((p) {
                  final q = widget.initialSearchQuery!.toLowerCase();
                  return p.title.toLowerCase().contains(q) ||
                      p.brand.toLowerCase().contains(q) ||
                      p.tags.any((t) => t.toLowerCase().contains(q));
                }).toList()
              : state.filteredProducts;

          final activeFilterCount = state.filter.activeFilterCount;

          return Column(
            children: [
              // Sticky Filter & Sort Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item Count
                    Text(
                      '${displayProducts.length} ${displayProducts.length == 1 ? 'Item' : 'Items'}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Filter & Sort Trigger
                    Row(
                      children: [
                        if (activeFilterCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text(
                                'Clear ($activeFilterCount)',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.warningTerracotta,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.surfaceSecondary,
                              side: const BorderSide(color: AppColors.border),
                              onPressed: () {
                                context.read<CatalogCubit>().resetFilters();
                              },
                            ),
                          ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(90, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(
                            Icons.tune,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          label: Row(
                            children: [
                              Text(
                                'Filter & Sort',
                                style: AppTypography.button.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (activeFilterCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$activeFilterCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onPressed: () => _openFilterSheet(context, state),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Product Grid / Empty State
              Expanded(
                child: displayProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.filter_list_off,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching pieces',
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try clearing some filters or searching for another term.',
                                style: AppTypography.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(140, 42),
                                ),
                                onPressed: () {
                                  context.read<CatalogCubit>().resetFilters();
                                },
                                child: const Text('Reset All Filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async {
                          await context.read<CatalogCubit>().loadCatalog(
                                initialCategoryId: widget.categoryId,
                                tag: widget.initialTag,
                              );
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 18,
                          ),
                          itemCount: displayProducts.length,
                          itemBuilder: (context, index) {
                            final product = displayProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () => widget.onProductSelected(product),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
