import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local_storage_service.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_product_repository.dart';

class SearchState {
  final String query;
  final List<String> recentSearches;
  final List<String> popularSearches;
  final List<String> suggestedTerms;
  final List<Product> matchingProducts;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.recentSearches = const [],
    this.popularSearches = const [
      'Lounge Chair',
      'Ceramic Vase',
      'French Linen',
      'Travertine',
      'Floor Lamp',
      'Dining Bench',
    ],
    this.suggestedTerms = const [],
    this.matchingProducts = const [],
    this.isLoading = false,
  });

  bool get isZeroState => query.trim().isEmpty;

  SearchState copyWith({
    String? query,
    List<String>? recentSearches,
    List<String>? popularSearches,
    List<String>? suggestedTerms,
    List<Product>? matchingProducts,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      popularSearches: popularSearches ?? this.popularSearches,
      suggestedTerms: suggestedTerms ?? this.suggestedTerms,
      matchingProducts: matchingProducts ?? this.matchingProducts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchCubit extends Cubit<SearchState> {
  final IProductRepository _productRepository;
  final LocalStorageService _storage;
  Timer? _debounceTimer;

  SearchCubit({
    required IProductRepository productRepository,
    required LocalStorageService storage,
  })  : _productRepository = productRepository,
        _storage = storage,
        super(const SearchState()) {
    loadRecentSearches();
  }

  void loadRecentSearches() {
    final recent = _storage.getRecentSearches();
    emit(state.copyWith(recentSearches: recent));
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      emit(state.copyWith(
        query: '',
        suggestedTerms: [],
        matchingProducts: [],
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(query: query, isLoading: true));

    // Debounce 300ms per PRD SCR-005
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final suggestions =
          await _productRepository.getSuggestedSearchTerms(query);
      final products = await _productRepository.getProducts(
        searchQuery: query,
      );

      if (!isClosed) {
        emit(state.copyWith(
          suggestedTerms: suggestions,
          matchingProducts: products,
          isLoading: false,
        ));
      }
    });
  }

  Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await _storage.addRecentSearch(trimmed);
    loadRecentSearches();
  }

  Future<void> removeRecentSearch(String query) async {
    await _storage.removeRecentSearch(query);
    loadRecentSearches();
  }

  Future<void> clearRecentSearches() async {
    await _storage.clearRecentSearches();
    loadRecentSearches();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
