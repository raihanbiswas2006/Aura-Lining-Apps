import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'app_button.dart';

/// Clean minimalist empty state view per PRD Section 7.3
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final String? actionButtonText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionButtonText,
    this.onAction,
  });

  String? get _effectiveActionLabel => actionLabel ?? actionButtonText;

  @override
  Widget build(BuildContext context) {
    final label = _effectiveActionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionHeader.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted.copyWith(height: 1.4),
            ),
            if (label != null && onAction != null) ...[
              const SizedBox(height: 20),
              AppButton(
                text: label,
                variant: AppButtonVariant.secondary,
                width: 160,
                height: 40,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
