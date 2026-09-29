import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/coupon.dart';

abstract class PromotionRepository {
  Future<List<Coupon>> getCoupons();
  Future<Coupon?> getCouponById(String id);
  Future<Coupon> createCoupon(Coupon coupon);
  Future<Coupon> updateCoupon(Coupon coupon);
  Future<Coupon> toggleCouponStatus(String couponId);
  Future<bool> deleteCoupon(String couponId);
  Stream<List<Coupon>> watchCoupons();
}

class MockPromotionRepository implements PromotionRepository {
  final _uuid = const Uuid();
  final _couponsStream = StreamController<List<Coupon>>.broadcast();
  late List<Coupon> _coupons;

  MockPromotionRepository() {
    _seedCoupons();
  }

  void _seedCoupons() {
    final now = DateTime.now();

    _coupons = [
      Coupon(
        id: 'cpn-01',
        code: 'AURA10',
        discountType: DiscountType.percentage,
        discountValue: 10.0,
        minimumSpend: 5000.0,
        expirationDate: now.add(const Duration(days: 60)),
        usageLimit: 500,
        usageCount: 142,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Coupon(
        id: 'cpn-02',
        code: 'WELCOME1000',
        discountType: DiscountType.fixedAmount,
        discountValue: 1000.0,
        minimumSpend: 15000.0,
        expirationDate: now.add(const Duration(days: 90)),
        usageLimit: 1000,
        usageCount: 310,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Coupon(
        id: 'cpn-03',
        code: 'SPRING25',
        discountType: DiscountType.percentage,
        discountValue: 25.0,
        minimumSpend: 10000.0,
        expirationDate: now.subtract(const Duration(days: 10)), // Expired
        usageLimit: 200,
        usageCount: 200,
        isActive: false,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }

  void _notify() {
    _couponsStream.add(List.unmodifiable(_coupons));
  }

  @override
  Stream<List<Coupon>> watchCoupons() {
    return _couponsStream.stream;
  }

  @override
  Future<List<Coupon>> getCoupons() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_coupons);
  }

  @override
  Future<Coupon?> getCouponById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _coupons.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Coupon> createCoupon(Coupon coupon) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // Check code uniqueness per PRD Section 6.7
    final cleanCode = coupon.code.trim().toUpperCase();
    final duplicate = _coupons.any((c) => c.code.toUpperCase() == cleanCode);
    if (duplicate) {
      throw Exception('Coupon code "$cleanCode" already exists. Code must be unique.');
    }

    final newCoupon = coupon.copyWith(
      id: coupon.id.isEmpty ? 'cpn-${_uuid.v4().substring(0, 6)}' : coupon.id,
      code: cleanCode,
      createdAt: DateTime.now(),
    );

    _coupons.insert(0, newCoupon);
    _notify();
    return newCoupon;
  }

  @override
  Future<Coupon> updateCoupon(Coupon coupon) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _coupons.indexWhere((c) => c.id == coupon.id);
    if (idx == -1) throw Exception('Coupon not found');

    final cleanCode = coupon.code.trim().toUpperCase();
    final duplicate = _coupons.any(
      (c) => c.id != coupon.id && c.code.toUpperCase() == cleanCode,
    );
    if (duplicate) {
      throw Exception('Coupon code "$cleanCode" already exists. Code must be unique.');
    }

    _coupons[idx] = coupon.copyWith(code: cleanCode);
    _notify();
    return _coupons[idx];
  }

  @override
  Future<Coupon> toggleCouponStatus(String couponId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _coupons.indexWhere((c) => c.id == couponId);
    if (idx == -1) throw Exception('Coupon not found');

    final updated = _coupons[idx].copyWith(isActive: !_coupons[idx].isActive);
    _coupons[idx] = updated;
    _notify();
    return updated;
  }

  @override
  Future<bool> deleteCoupon(String couponId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _coupons.indexWhere((c) => c.id == couponId);
    if (idx == -1) return false;
    _coupons.removeAt(idx);
    _notify();
    return true;
  }
}
