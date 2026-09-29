import '../../domain/entities/cart_item.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/i_cart_repository.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/mock/mock_coupons.dart';

class MockCartRepository implements ICartRepository {
  final LocalStorageService _storage;

  MockCartRepository(this._storage);

  @override
  Future<List<CartItem>> getCart() async {
    final rawList = _storage.getCartRaw();
    return rawList.map((m) => CartItem.fromJson(m)).toList();
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    final rawList = items.map((i) => i.toJson()).toList();
    await _storage.saveCartRaw(rawList);
  }

  @override
  Future<List<String>> getWishlistProductIds() async {
    return _storage.getWishlistIds();
  }

  @override
  Future<void> saveWishlistProductIds(List<String> productIds) async {
    await _storage.saveWishlistIds(productIds);
  }

  @override
  Future<Coupon?> getCoupon(String code) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final normalized = code.trim().toUpperCase();
    try {
      return mockCoupons.firstWhere((c) => c.code == normalized);
    } catch (_) {
      return null;
    }
  }
}
