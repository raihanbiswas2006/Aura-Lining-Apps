import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/orders/domain/order_status.dart';

enum StatusBadgeType {
  success, // In-Stock, Delivered, Active, Approved
  warning, // Low-Stock, Pending
  danger,  // Out-of-Stock, Cancelled, Rejected, Archived
  neutral, // Draft, Processing
  info,    // Shipped, In-Transit
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool isPill;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.isPill = false,
  });

  /// Factory helper for Stock Status:
  /// > 5: Success (In Stock: 24)
  /// 1 - 5: Warning (Low Stock: 3)
  /// 0: Danger (Out of Stock)
  factory StatusBadge.stock(int quantity, {bool isArchived = false, bool isDraft = false}) {
    if (isArchived) {
      return const StatusBadge(label: 'Archived', type: StatusBadgeType.danger);
    }
    if (isDraft) {
      return const StatusBadge(label: 'Draft', type: StatusBadgeType.neutral);
    }
    if (quantity == 0) {
      return const StatusBadge(label: 'Out of Stock', type: StatusBadgeType.danger);
    }
    if (quantity <= 5) {
      return StatusBadge(label: 'Low Stock: $quantity', type: StatusBadgeType.warning);
    }
    return StatusBadge(label: 'In Stock: $quantity', type: StatusBadgeType.success);
  }

  /// Factory helper for Order Status
  factory StatusBadge.order(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const StatusBadge(label: 'Delivered', type: StatusBadgeType.success, isPill: true);
      case 'shipped':
      case 'handed to courier':
        return const StatusBadge(label: 'Handed to Courier', type: StatusBadgeType.info, isPill: true);
      case 'confirmed':
        return const StatusBadge(label: 'Confirmed', type: StatusBadgeType.info, isPill: true);
      case 'processing':
        return const StatusBadge(label: 'Processing', type: StatusBadgeType.neutral, isPill: true);
      case 'pending':
        return const StatusBadge(label: 'Pending', type: StatusBadgeType.warning, isPill: true);
      case 'cancelled':
        return const StatusBadge(label: 'Cancelled', type: StatusBadgeType.danger, isPill: true);
      case 'returned':
        return const StatusBadge(label: 'Returned', type: StatusBadgeType.danger, isPill: true);
      default:
        return StatusBadge(label: status, type: StatusBadgeType.neutral, isPill: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;

    switch (type) {
      case StatusBadgeType.success:
        fg = AppColors.success;
        bg = AppColors.successBg;
        break;
      case StatusBadgeType.warning:
        fg = AppColors.warning;
        bg = AppColors.warningBg;
        break;
      case StatusBadgeType.danger:
        fg = AppColors.danger;
        bg = AppColors.dangerBg;
        break;
      case StatusBadgeType.neutral:
        fg = AppColors.neutral;
        bg = AppColors.neutralBg;
        break;
      case StatusBadgeType.info:
        fg = AppColors.info;
        bg = AppColors.infoBg;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPill ? 10 : 8,
        vertical: isPill ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isPill ? 100 : 4),
        border: Border.all(
          color: fg.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// OrderStatusBadge dedicated widget for OrderStatus enum values
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge.order(status.label);
  }
}
