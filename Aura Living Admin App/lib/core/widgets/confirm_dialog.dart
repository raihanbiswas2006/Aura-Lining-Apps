import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'app_button.dart';

/// Modal dialog for destructive actions per PRD Section 7.2
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete Forever',
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
    required this.onConfirm,
  });

  /// Static helper to display modal confirmation dialog
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete Forever',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Text(
          title,
          style: AppTypography.sectionHeader.copyWith(
            fontSize: 17,
            color: isDestructive ? AppColors.danger : AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: cancelLabel,
                  variant: AppButtonVariant.secondary,
                  height: 42,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: confirmLabel,
                  variant: isDestructive
                      ? AppButtonVariant.destructive
                      : AppButtonVariant.primary,
                  height: 42,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// Helper function for modal destructive confirmation
Future<bool?> showDestructiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String consequenceText,
  String confirmButtonText = 'Delete Forever',
  String cancelButtonText = 'Cancel',
}) {
  return ConfirmDialog.show(
    context,
    title: title,
    message: consequenceText,
    confirmLabel: confirmButtonText,
    cancelLabel: cancelButtonText,
    isDestructive: true,
  );
}
