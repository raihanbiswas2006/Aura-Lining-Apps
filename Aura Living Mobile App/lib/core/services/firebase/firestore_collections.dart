/// Central Firestore Collections and Document Naming Constants
/// Matching Aura Living Web & Cloud Firestore Schema
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String orders = 'orders';
  static const String coupons = 'coupons';
  static const String reviews = 'reviews';
  static const String banners = 'banners';
  static const String settings = 'settings';
  static const String notifications = 'notifications';

  // Sub-collections
  static const String userAddresses = 'addresses';
  static const String userWishlist = 'wishlist';
  static const String orderTimeline = 'timeline';
}
