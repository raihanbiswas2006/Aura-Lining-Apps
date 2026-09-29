import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyCart = 'aura_cart_v1';
  static const String _keyWishlist = 'aura_wishlist_v1';
  static const String _keyRecentSearches = 'aura_recent_searches_v1';
  static const String _keyUser = 'aura_user_v1';
  static const String _keyOrders = 'aura_orders_v1';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Cart
  List<Map<String, dynamic>> getCartRaw() {
    final str = _prefs.getString(_keyCart);
    if (str == null || str.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCartRaw(List<Map<String, dynamic>> items) async {
    await _prefs.setString(_keyCart, jsonEncode(items));
  }

  // Wishlist
  List<String> getWishlistIds() {
    return _prefs.getStringList(_keyWishlist) ?? [];
  }

  Future<void> saveWishlistIds(List<String> ids) async {
    await _prefs.setStringList(_keyWishlist, ids);
  }

  // Recent Searches
  List<String> getRecentSearches() {
    return _prefs.getStringList(_keyRecentSearches) ??
        ['lounge chair', 'linen', 'minimalist lamp', 'ceramic'];
  }

  Future<void> addRecentSearch(String query) async {
    final current = getRecentSearches();
    current.remove(query);
    current.insert(0, query);
    if (current.length > 10) {
      current.removeLast();
    }
    await _prefs.setStringList(_keyRecentSearches, current);
  }

  Future<void> removeRecentSearch(String query) async {
    final current = getRecentSearches();
    current.remove(query);
    await _prefs.setStringList(_keyRecentSearches, current);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_keyRecentSearches);
  }

  // User Session
  Map<String, dynamic>? getUserRaw() {
    final str = _prefs.getString(_keyUser);
    if (str == null || str.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(str) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserRaw(Map<String, dynamic> user) async {
    await _prefs.setString(_keyUser, jsonEncode(user));
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }

  // Orders
  List<Map<String, dynamic>> getOrdersRaw() {
    final str = _prefs.getString(_keyOrders);
    if (str == null || str.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrdersRaw(List<Map<String, dynamic>> orders) async {
    await _prefs.setString(_keyOrders, jsonEncode(orders));
  }
}
