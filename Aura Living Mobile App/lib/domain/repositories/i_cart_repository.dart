import '../entities/cart_item.dart';
import '../entities/coupon.dart';

abstract class ICartRepository {
  Future<List<CartItem>> getCart();
  Future<void> saveCart(List<CartItem> items);
  Future<List<String>> getWishlistProductIds();
  Future<void> saveWishlistProductIds(List<String> productIds);
  Future<Coupon?> getCoupon(String code);
}
