import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class NotFoundScreen extends StatelessWidget {
  final VoidCallback onBackToHome;

  const NotFoundScreen({super.key, required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Piece Not Found'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '404',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 54,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Piece or Collection Unavailable',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The architectural piece or collection you navigated to may have been archived or moved.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onBackToHome,
                child: const Text('Return to Home Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
