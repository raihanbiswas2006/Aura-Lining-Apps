import '../../../domain/entities/coupon.dart';

const List<Coupon> mockCoupons = [
  Coupon(
    code: 'AURA10',
    discountType: 'percentage',
    value: 10.0,
    minimumOrderValue: 0.0,
  ),
  Coupon(
    code: 'FREESHIP',
    discountType: 'free_shipping',
    value: 0.0,
    minimumOrderValue: 5000.0,
  ),
  Coupon(
    code: 'MINIMALIST',
    discountType: 'fixed',
    value: 1000.0,
    minimumOrderValue: 15000.0,
  ),
];
