import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/coupon.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_cart_repository.dart';

class CartState {
  final List<CartItem> items;
  final Coupon? appliedCoupon;
  final String? couponError;
  final bool isLoading;
  final String? warningMessage;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.couponError,
    this.isLoading = false,
    this.warningMessage,
  });

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  int get itemCount => totalItemCount;

  bool get isEmpty => items.isEmpty;

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get baseShippingCost => subtotal >= 5000.0 ? 0.0 : 120.0;

  double get discountAmount {
    if (appliedCoupon == null) return 0.0;
    return appliedCoupon!.calculateDiscount(subtotal, baseShippingCost);
  }

  double get shippingCost {
    if (appliedCoupon != null && appliedCoupon!.isFreeShipping) {
      return 0.0;
    }
    return baseShippingCost;
  }

  double get estimatedTax {
    final taxableAmount = (subtotal - discountAmount).clamp(0.0, double.infinity);
    return taxableAmount * 0.08; // 8% standard tax
  }

  double get totalAmount {
    final taxableAmount = (subtotal - discountAmount).clamp(0.0, double.infinity);
    return taxableAmount + shippingCost + estimatedTax;
  }

  bool get hasOutOfStockItems =>
      items.any((item) => item.quantity > item.selectedVariant.stockQuantity);

  CartState copyWith({
    List<CartItem>? items,
    Coupon? appliedCoupon,
    bool clearCoupon = false,
    String? couponError,
    bool clearCouponError = false,
    bool? isLoading,
    String? warningMessage,
    bool clearWarning = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      couponError:
          clearCouponError ? null : (couponError ?? this.couponError),
      isLoading: isLoading ?? this.isLoading,
      warningMessage:
          clearWarning ? null : (warningMessage ?? this.warningMessage),
    );
  }
}

class CartCubit extends Cubit<CartState> {
  final ICartRepository _cartRepository;

  CartCubit(this._cartRepository) : super(const CartState());

  Future<void> loadCart() async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _cartRepository.getCart();

      // Check available stock quantities per PRD 6.1
      String? warning;
      final adjustedItems = <CartItem>[];
      for (final item in items) {
        if (item.selectedVariant.stockQuantity <= 0) {
          warning = 'Some items in your cart are currently sold out.';
          adjustedItems.add(item.copyWith(quantity: 0));
        } else if (item.quantity > item.selectedVariant.stockQuantity) {
          warning =
              'Quantity adjusted to available stock (${item.selectedVariant.stockQuantity} remaining).';
          adjustedItems.add(
            item.copyWith(quantity: item.selectedVariant.stockQuantity),
          );
        } else {
          adjustedItems.add(item);
        }
      }

      emit(state.copyWith(
        items: adjustedItems,
        isLoading: false,
        warningMessage: warning,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> addItem(
    Product product,
    ProductVariant variant, {
    int quantity = 1,
  }) async {
    final currentItems = List<CartItem>.from(state.items);
    final lineItemId = '${product.id}_${variant.id}';
    final existingIndex = currentItems.indexWhere((i) => i.id == lineItemId);

    if (existingIndex != -1) {
      final existing = currentItems[existingIndex];
      final newQuantity = (existing.quantity + quantity)
          .clamp(1, variant.stockQuantity);
      currentItems[existingIndex] = existing.copyWith(quantity: newQuantity);
    } else {
      final clampedQuantity = quantity.clamp(1, variant.stockQuantity);
      currentItems.add(CartItem(
        id: lineItemId,
        product: product,
        selectedVariant: variant,
        quantity: clampedQuantity,
      ));
    }

    emit(state.copyWith(items: currentItems));
    await _cartRepository.saveCart(currentItems);

    // Revalidate coupon minimum order if any
    _revalidateCoupon();
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final currentItems = List<CartItem>.from(state.items);
    final index = currentItems.indexWhere((i) => i.id == cartItemId);
    if (index == -1) return;

    final item = currentItems[index];
    if (newQuantity <= 0) {
      currentItems.removeAt(index);
    } else {
      // Capped at variant stockQuantity per PRD 6.1 & AC-2.3
      final clamped = newQuantity.clamp(1, item.selectedVariant.stockQuantity);
      currentItems[index] = item.copyWith(quantity: clamped);
    }

    emit(state.copyWith(items: currentItems));
    await _cartRepository.saveCart(currentItems);

    _revalidateCoupon();
  }

  Future<void> removeItem(String cartItemId) async {
    final currentItems = List<CartItem>.from(state.items);
    currentItems.removeWhere((i) => i.id == cartItemId);

    emit(state.copyWith(items: currentItems));
    await _cartRepository.saveCart(currentItems);

    _revalidateCoupon();
  }

  Future<void> clearCart() async {
    emit(state.copyWith(
      items: [],
      clearCoupon: true,
      clearCouponError: true,
    ));
    await _cartRepository.saveCart([]);
  }

  Future<bool> applyCoupon(String code) async {
    emit(state.copyWith(clearCouponError: true));
    final normalized = code.trim().toUpperCase();

    if (normalized.isEmpty) {
      emit(state.copyWith(couponError: 'Please enter a coupon code'));
      return false;
    }

    final coupon = await _cartRepository.getCoupon(normalized);

    if (coupon == null) {
      emit(state.copyWith(couponError: 'Coupon code does not exist'));
      return false;
    }

    if (state.subtotal < coupon.minimumOrderValue) {
      emit(state.copyWith(
        couponError:
            'Order minimum of ৳${coupon.minimumOrderValue.toInt()} not met for this coupon',
      ));
      return false;
    }

    emit(state.copyWith(
      appliedCoupon: coupon,
      clearCouponError: true,
    ));
    return true;
  }

  void removeCoupon() {
    emit(state.copyWith(clearCoupon: true, clearCouponError: true));
  }

  void _revalidateCoupon() {
    if (state.appliedCoupon != null) {
      if (state.subtotal < state.appliedCoupon!.minimumOrderValue) {
        emit(state.copyWith(
          clearCoupon: true,
          couponError:
              'Coupon removed: order minimum ৳${state.appliedCoupon!.minimumOrderValue.toInt()} no longer met',
        ));
      }
    }
  }
}
