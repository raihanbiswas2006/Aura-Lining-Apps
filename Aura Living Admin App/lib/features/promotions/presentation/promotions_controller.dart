import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/coupon.dart';
import '../../../core/providers/repository_providers.dart';

final couponsStreamProvider = StreamProvider<List<Coupon>>((ref) {
  final promoRepo = ref.watch(promotionRepositoryProvider);
  return promoRepo.watchCoupons();
});

final couponDetailProvider = FutureProvider.family<Coupon?, String>((ref, id) async {
  final promoRepo = ref.watch(promotionRepositoryProvider);
  return promoRepo.getCouponById(id);
});
