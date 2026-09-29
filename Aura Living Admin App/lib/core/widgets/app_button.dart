import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

enum AppButtonVariant { primary, secondary, destructive, text }
typedef ButtonVariant = AppButtonVariant;

/// Universal AppButton adhering to 44x44 minimum touch target,
/// with loading spinners and disabled tap prevention.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = isEnabled ? AppColors.primaryOlive : AppColors.primaryOlive.withValues(alpha: 0.5);
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.surface;
        fgColor = isEnabled ? AppColors.textPrimary : AppColors.textMuted;
        borderSide = const BorderSide(color: AppColors.border, width: 1);
        break;
      case AppButtonVariant.destructive:
        bgColor = isEnabled ? AppColors.danger : AppColors.danger.withValues(alpha: 0.5);
        fgColor = Colors.white;
        break;
      case AppButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = isEnabled ? AppColors.primaryOlive : AppColors.textMuted;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.buttonText.copyWith(color: fgColor),
          ),
        ],
      );
    } else {
      content = Text(
        text,
        style: AppTypography.buttonText.copyWith(color: fgColor),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: borderSide,
        ),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Center(child: content),
        ),
      ),
    );
  }
}
