import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// User-friendly error banner with actionable recovery options
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onContactSupport;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onRetry != null || onContactSupport != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (onRetry != null)
                        InkWell(
                          onTap: onRetry,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
                            child: Text(
                              'Try Again',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      if (onContactSupport != null)
                        InkWell(
                          onTap: onContactSupport,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'Contact Technical Support',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
