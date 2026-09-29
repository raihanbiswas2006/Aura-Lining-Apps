import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import '../domain/category.dart';
import '../../../core/providers/repository_providers.dart';

class ProductFilterState {
  final String searchQuery;
  final String categoryId;
  final String stockFilter; // 'all', 'in_stock', 'low_stock', 'out_of_stock'
  final String statusFilter; // 'all', 'Active', 'Draft', 'Archived'

  const ProductFilterState({
    this.searchQuery = '',
    this.categoryId = 'all',
    this.stockFilter = 'all',
    this.statusFilter = 'all',
  });

  ProductFilterState copyWith({
    String? searchQuery,
    String? categoryId,
    String? stockFilter,
    String? statusFilter,
  }) {
    return ProductFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId ?? this.categoryId,
      stockFilter: stockFilter ?? this.stockFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final productFilterProvider = StateProvider<ProductFilterState>((ref) {
  return const ProductFilterState();
});

final productsListProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final filter = ref.watch(productFilterProvider);

  return repo.getProducts(
    query: filter.searchQuery,
    categoryId: filter.categoryId == 'all' ? null : filter.categoryId,
    stockFilter: filter.stockFilter == 'all' ? null : filter.stockFilter,
    statusFilter: filter.statusFilter == 'all' ? null : filter.statusFilter,
  );
});

final categoriesListProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getCategories();
});
