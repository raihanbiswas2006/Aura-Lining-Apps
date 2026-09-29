import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_cart_repository.dart';
import '../../../domain/repositories/i_product_repository.dart';

class WishlistState {
  final Set<String> productIds;
  final List<Product> products;
  final bool isLoading;

  const WishlistState({
    this.productIds = const {},
    this.products = const [],
    this.isLoading = false,
  });

  bool isWishlisted(String productId) => productIds.contains(productId);

  WishlistState copyWith({
    Set<String>? productIds,
    List<Product>? products,
    bool? isLoading,
  }) {
    return WishlistState(
      productIds: productIds ?? this.productIds,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WishlistCubit extends Cubit<WishlistState> {
  final ICartRepository _cartRepository;
  final IProductRepository _productRepository;

  WishlistCubit({
    required ICartRepository cartRepository,
    required IProductRepository productRepository,
  })  : _cartRepository = cartRepository,
        _productRepository = productRepository,
        super(const WishlistState());

  Future<void> loadWishlist() async {
    emit(state.copyWith(isLoading: true));
    try {
      final ids = await _cartRepository.getWishlistProductIds();
      final allProducts = await _productRepository.getProducts();
      final wishlistedProducts =
          allProducts.where((p) => ids.contains(p.id)).toList();

      emit(state.copyWith(
        productIds: ids.toSet(),
        products: wishlistedProducts,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void toggleWishlist(Product product) {
    final currentIds = Set<String>.from(state.productIds);
    final currentProducts = List<Product>.from(state.products);

    if (currentIds.contains(product.id)) {
      currentIds.remove(product.id);
      currentProducts.removeWhere((p) => p.id == product.id);
    } else {
      currentIds.add(product.id);
      if (!currentProducts.any((p) => p.id == product.id)) {
        currentProducts.add(product);
      }
    }

    // Emit instantly to satisfy AC-4.1 (<100ms)
    emit(state.copyWith(
      productIds: currentIds,
      products: currentProducts,
    ));

    // Persist in background
    _cartRepository.saveWishlistProductIds(currentIds.toList());
  }
}
