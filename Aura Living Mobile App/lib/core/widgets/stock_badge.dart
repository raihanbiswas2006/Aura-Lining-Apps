import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class StockBadge extends StatelessWidget {
  final int stockQuantity;
  final bool isCompact;

  const StockBadge({
    super.key,
    required this.stockQuantity,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (stockQuantity <= 0) {
      return _buildBadge(
        color: AppColors.warningTerracotta,
        text: isCompact ? 'Sold Out' : 'Currently Sold Out — Join Waitlist',
        isAlert: true,
      );
    } else if (stockQuantity <= 3) {
      return _buildBadge(
        color: AppColors.gold,
        text: isCompact
            ? 'Only $stockQuantity left'
            : 'Hurry! Only $stockQuantity units remaining',
        isAlert: false,
      );
    } else {
      return _buildBadge(
        color: AppColors.successGreen,
        text: isCompact ? 'In Stock' : 'In Stock — Ready to ship',
        isAlert: false,
      );
    }
  }

  Widget _buildBadge({
    required Color color,
    required String text,
    required bool isAlert,
  }) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
