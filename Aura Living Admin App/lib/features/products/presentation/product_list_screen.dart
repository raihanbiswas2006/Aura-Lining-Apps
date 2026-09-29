import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';
import '../domain/product.dart';
import 'products_controller.dart';
import 'widgets/stock_adjust_modal.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? initialStockFilter;

  const ProductListScreen({super.key, this.initialStockFilter});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStockFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productFilterProvider.notifier).state = ref
            .read(productFilterProvider)
            .copyWith(stockFilter: widget.initialStockFilter);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(productFilterProvider.notifier).state =
        ref.read(productFilterProvider).copyWith(searchQuery: value);
  }

  void _onCategoryFilter(String categoryId) {
    ref.read(productFilterProvider.notifier).state =
        ref.read(productFilterProvider).copyWith(categoryId: categoryId);
  }

  void _onStockFilter(String filter) {
    ref.read(productFilterProvider.notifier).state =
        ref.read(productFilterProvider).copyWith(stockFilter: filter);
  }

  void _handleDeleteProduct(Product product) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: "Permanently delete '${product.title}'?",
      message:
          'This action cannot be undone and will detach product history from unfulfilled orders.',
      confirmLabel: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed) {
      final repo = ref.read(productRepositoryProvider);
      await repo.hardDeleteProduct(product.id);
      ref.invalidate(productsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permanently deleted '${product.title}'.")),
        );
      }
    }
  }

  void _handleDeactivateProduct(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    await repo.deactivateProduct(product.id);
    ref.invalidate(productsListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Archived '${product.title}'.")),
      );
    }
  }

  void _handleToggleAvailability(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    final updated = await repo.toggleAvailability(product.id);
    ref.invalidate(productsListProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${product.title} is now ${updated.status}.")),
      );
    }
  }

  void _openStockAdjustModal(Product product) {
    StockAdjustModal.show(
      context,
      product: product,
      onSave: (newQty, variantId) async {
        final repo = ref.read(productRepositoryProvider);
        await repo.quickAdjustStock(product.id, newQty, variantId: variantId);
        ref.invalidate(productsListProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final filter = ref.watch(productFilterProvider);
    final productsAsync = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    final canCreate = user?.role.canCreateEditProduct ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Products & Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Category Taxonomy',
            onPressed: () => context.push('/products/categories'),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryOlive,
              foregroundColor: Colors.white,
              elevation: 2,
              onPressed: () => context.push('/products/add'),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Search & Category Filters Bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      hintText: 'Search products, SKU, or tags...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Filters Bar: Stock & Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _stockFilterChip('All Stock', 'all', filter.stockFilter),
                        const SizedBox(width: 6),
                        _stockFilterChip('In Stock', 'in_stock', filter.stockFilter),
                        const SizedBox(width: 6),
                        _stockFilterChip('Low Stock (≤5)', 'low_stock', filter.stockFilter),
                        const SizedBox(width: 6),
                        _stockFilterChip('Out of Stock (0)', 'out_of_stock', filter.stockFilter),
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 20,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 12),

                        // Categories chips
                        categoriesAsync.maybeWhen(
                          data: (categories) => Row(
                            children: [
                              _catFilterChip('All Categories', 'all', filter.categoryId),
                              ...categories.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _catFilterChip(c.name, c.id, filter.categoryId),
                                ),
                              ),
                            ],
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Products List
            Expanded(
              child: productsAsync.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (_, __) => const ListItemSkeleton(),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error loading catalog: $err'),
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Products Found',
                      subtitle: filter.searchQuery.isNotEmpty || filter.stockFilter != 'all'
                          ? 'No items match your active search and filter criteria.'
                          : 'Your store catalog is currently empty.',
                      actionLabel: 'Clear All Filters',
                      onAction: () {
                        _searchController.clear();
                        ref.read(productFilterProvider.notifier).state =
                            const ProductFilterState();
                      },
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryOlive,
                    onRefresh: () async {
                      ref.invalidate(productsListProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _productCard(context, product, user);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockFilterChip(String label, String value, String activeValue) {
    final isSelected = activeValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStockFilter(value),
      selectedColor: AppColors.primaryOlive,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryOlive : AppColors.border,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _catFilterChip(String label, String value, String activeValue) {
    final isSelected = activeValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onCategoryFilter(value),
      selectedColor: AppColors.surfaceSecondary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.primaryOlive : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryOlive : AppColors.border,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _productCard(BuildContext context, Product product, AdminUser? user) {
    final hasDiscount = product.discountPercentage > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.push('/products/${product.id}'),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 56x56 Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.surfaceSecondary,
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              size: 24,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 24,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Center Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        product.title,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Category & Variant count pill
                      Row(
                        children: [
                          Text(
                            product.hasVariants
                                ? '${product.variants.length} Variants'
                                : 'Single SKU',
                            style: AppTypography.caption,
                          ),
                          if (product.isFeatured) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                'Featured',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Price Display: Base price, Discounted price, Discount tag
                      Row(
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              AppFormatters.currency(product.finalPrice),
                              style: AppTypography.monospacedSmall.copyWith(
                                color: AppColors.primaryOlive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppFormatters.currency(product.basePrice),
                              style: AppTypography.caption.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '-${product.discountPercentage.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              AppFormatters.currency(product.basePrice),
                              style: AppTypography.monospacedSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stock Status Chip
                      StatusBadge.stock(
                        product.totalStock,
                        isArchived: product.isArchived,
                        isDraft: product.isDraft,
                      ),
                    ],
                  ),
                ),

                // Trailing kebab menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    switch (val) {
                      case 'edit':
                        if (user?.role.canCreateEditProduct ?? false) {
                          context.push('/products/${product.id}/edit');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Permission Denied: Staff is Read-Only.')),
                          );
                        }
                        break;
                      case 'quick_stock':
                        _openStockAdjustModal(product);
                        break;
                      case 'toggle':
                        _handleToggleAvailability(product);
                        break;
                      case 'archive':
                        _handleDeactivateProduct(product);
                        break;
                      case 'delete':
                        if (user?.role.canHardDeleteProduct ?? false) {
                          _handleDeleteProduct(product);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hard Delete requires Super Admin permissions.'),
                            ),
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (user?.role.canCreateEditProduct ?? false)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Product'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'quick_stock',
                      child: Row(
                        children: [
                          Icon(Icons.tune_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Quick Stock Adjust'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(product.isActive ? 'Set as Draft' : 'Set as Active'),
                        ],
                      ),
                    ),
                    if (user?.role.canDeactivateProduct ?? false)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Archive Product'),
                          ],
                        ),
                      ),
                    if (user?.role.canHardDeleteProduct ?? false)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, size: 16, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Delete Forever', style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
