import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/coupon.dart';
import 'promotions_controller.dart';
import '../../auth/presentation/auth_controller.dart';

class CouponListScreen extends ConsumerWidget {
  const CouponListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsStreamProvider);
    final user = ref.watch(authControllerProvider).user;
    final canManageCoupons = user?.role.canManageCoupons ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: couponsAsync.when(
        data: (coupons) {
          if (coupons.isEmpty) {
            return EmptyStateView(
              title: 'No Active Coupons',
              subtitle: 'No promotional discount codes found in store.',
              icon: Icons.local_offer_outlined,
              actionButtonText: canManageCoupons ? 'Create First Coupon' : null,
              onAction: canManageCoupons ? () => context.push('/moderation/coupons/add') : null,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return _CouponCard(
                coupon: coupon,
                canManage: canManageCoupons,
                onTap: () {
                  if (canManageCoupons) {
                    context.push('/moderation/coupons/edit/${coupon.id}');
                  }
                },
                onToggleActive: (val) async {
                  try {
                    final repo = ref.read(promotionRepositoryProvider);
                    await repo.toggleCouponStatus(coupon.id);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const ShimmerCard(height: 120),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading coupons: $err'),
        ),
      ),
      floatingActionButton: canManageCoupons
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryOlive,
              foregroundColor: Colors.white,
              onPressed: () => context.push('/moderation/coupons/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool canManage;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  const _CouponCard({
    required this.coupon,
    required this.canManage,
    required this.onTap,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = coupon.isExpired;
    final isLimitReached = coupon.isLimitReached;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpired || !coupon.isActive ? AppColors.border : AppColors.primaryOlive.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code, Discount Tag, Status Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOlive.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryOlive.withOpacity(0.2)),
                      ),
                      child: Text(
                        coupon.code,
                        style: AppTypography.monospacedNumber(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOlive,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        coupon.discountDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                if (canManage)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: coupon.isActive,
                      activeColor: AppColors.primaryOlive,
                      onChanged: onToggleActive,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Minimum spend & Expiration details
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  coupon.minimumSpend != null
                      ? 'Min spend: ${AppFormatters.formatCurrency(coupon.minimumSpend!)}'
                      : 'No minimum spend requirement',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (isExpired) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Expired', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
                ] else ...[
                  Text(
                    'Expires: ${AppFormatters.formatDate(coupon.expirationDate)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),

            // Usage Ratio Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Storewide Usage: ${coupon.usageCount} / ${coupon.usageLimit}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
                if (isLimitReached)
                  const Text('Limit Reached', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
