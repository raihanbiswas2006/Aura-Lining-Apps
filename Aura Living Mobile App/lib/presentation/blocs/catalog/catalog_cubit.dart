import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_product_repository.dart';

class CatalogFilter {
  final double minPrice;
  final double maxPrice;
  final List<String> selectedColors;
  final bool inStockOnly;
  final String? categoryId;

  const CatalogFilter({
    this.minPrice = 0.0,
    this.maxPrice = 1000.0,
    this.selectedColors = const [],
    this.inStockOnly = false,
    this.categoryId,
  });

  int get activeFilterCount {
    var count = 0;
    if (minPrice > 0.0 || maxPrice < 1000.0) count++;
    if (selectedColors.isNotEmpty) count += selectedColors.length;
    if (inStockOnly) count++;
    return count;
  }

  CatalogFilter copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? selectedColors,
    bool? inStockOnly,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return CatalogFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedColors: selectedColors ?? this.selectedColors,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class CatalogState {
  final List<Category> categories;
  final List<Product> products;
  final List<Product> filteredProducts;
  final String? activeCategoryId;
  final String? activeTag;
  final String sortBy; // "featured", "price_asc", "price_desc", "newest", "rating"
  final CatalogFilter filter;
  final bool isLoading;
  final String? error;

  const CatalogState({
    this.categories = const [],
    this.products = const [],
    this.filteredProducts = const [],
    this.activeCategoryId,
    this.activeTag,
    this.sortBy = 'featured',
    this.filter = const CatalogFilter(),
    this.isLoading = false,
    this.error,
  });

  List<String> get allAvailableColors {
    final colors = <String>{};
    for (final p in products) {
      colors.addAll(p.availableColors);
    }
    return colors.toList()..sort();
  }

  CatalogState copyWith({
    List<Category>? categories,
    List<Product>? products,
    List<Product>? filteredProducts,
    String? activeCategoryId,
    bool clearActiveCategory = false,
    String? activeTag,
    bool clearActiveTag = false,
    String? sortBy,
    CatalogFilter? filter,
    bool? isLoading,
    String? error,
  }) {
    return CatalogState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      activeCategoryId: clearActiveCategory
          ? null
          : (activeCategoryId ?? this.activeCategoryId),
      activeTag:
          clearActiveTag ? null : (activeTag ?? this.activeTag),
      sortBy: sortBy ?? this.sortBy,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CatalogCubit extends Cubit<CatalogState> {
  final IProductRepository _productRepository;

  CatalogCubit(this._productRepository) : super(const CatalogState());

  Future<void> loadCatalog({String? initialCategoryId, String? tag}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final categories = await _productRepository.getCategories();
      final products = await _productRepository.getProducts(
        categoryId: initialCategoryId,
        tag: tag,
      );

      final filter = state.filter.copyWith(categoryId: initialCategoryId);

      emit(state.copyWith(
        categories: categories,
        products: products,
        filteredProducts: products,
        activeCategoryId: initialCategoryId,
        activeTag: tag,
        filter: filter,
        isLoading: false,
      ));

      _applyFiltersAndSort();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectCategory(String? categoryId) {
    emit(state.copyWith(
      activeCategoryId: categoryId,
      clearActiveCategory: categoryId == null || categoryId == 'all',
      clearActiveTag: true,
      filter: state.filter.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null || categoryId == 'all',
      ),
    ));
    _fetchAndFilter();
  }

  void selectTag(String? tag) {
    emit(state.copyWith(
      activeTag: tag,
      clearActiveTag: tag == null,
    ));
    _fetchAndFilter();
  }

  void setPriceRange(double min, double max) {
    emit(state.copyWith(
      filter: state.filter.copyWith(minPrice: min, maxPrice: max),
    ));
    _applyFiltersAndSort();
  }

  void toggleColor(String color) {
    final currentColors = List<String>.from(state.filter.selectedColors);
    if (currentColors.contains(color)) {
      currentColors.remove(color);
    } else {
      currentColors.add(color);
    }
    emit(state.copyWith(
      filter: state.filter.copyWith(selectedColors: currentColors),
    ));
    _applyFiltersAndSort();
  }

  void setInStockOnly(bool value) {
    emit(state.copyWith(
      filter: state.filter.copyWith(inStockOnly: value),
    ));
    _applyFiltersAndSort();
  }

  void setSortBy(String sortBy) {
    emit(state.copyWith(sortBy: sortBy));
    _applyFiltersAndSort();
  }

  void resetFilters() {
    emit(state.copyWith(
      filter: CatalogFilter(categoryId: state.activeCategoryId),
      sortBy: 'featured',
    ));
    _applyFiltersAndSort();
  }

  Future<void> _fetchAndFilter() async {
    emit(state.copyWith(isLoading: true));
    try {
      final products = await _productRepository.getProducts(
        categoryId: state.activeCategoryId,
        tag: state.activeTag,
      );
      emit(state.copyWith(products: products, isLoading: false));
      _applyFiltersAndSort();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _applyFiltersAndSort() {
    var result = List<Product>.from(state.products);
    final filter = state.filter;

    // Price range
    result = result
        .where((p) => p.price >= filter.minPrice && p.price <= filter.maxPrice)
        .toList();

    // Colors
    if (filter.selectedColors.isNotEmpty) {
      result = result
          .where((p) => p.availableColors.any((c) => filter.selectedColors.contains(c)))
          .toList();
    }

    // In-stock only
    if (filter.inStockOnly) {
      result = result.where((p) => !p.isSoldOut).toList();
    }

    // Sort
    switch (state.sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'featured':
      default:
        // Default order
        break;
    }

    emit(state.copyWith(filteredProducts: result));
  }
}
