import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import 'auth_controller.dart';

typedef AdminLoginScreen = LoginScreen;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@auraliving.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    // Dismiss soft keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  void _fillAccount(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    ref.read(authControllerProvider.notifier).clearError();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Aura Living Header & Badge
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOlive,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'AL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AURA LIVING',
                      textAlign: TextAlign.center,
                      style: AppTypography.pageTitle.copyWith(
                        letterSpacing: 2.0,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOlive.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.primaryOlive.withOpacity(0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Store Operations',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryOlive,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card Surface for Inputs
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign In',
                            style: AppTypography.sectionHeader.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your assigned operational credentials to access store consoles.',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 20),

                          if (authState.errorMessage != null) ...[
                            ErrorBanner(
                              message: authState.errorMessage!,
                              onRetry: () => ref
                                  .read(authControllerProvider.notifier)
                                  .clearError(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Work Email Input
                          AppTextField(
                            controller: _emailController,
                            label: 'Work Email',
                            hintText: 'admin@auraliving.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            validator: AppValidators.validateEmail,
                            onChanged: (_) =>
                                ref.read(authControllerProvider.notifier).clearError(),
                          ),
                          const SizedBox(height: 16),

                          // Password Input
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: '••••••••',
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: AppValidators.validatePassword,
                            onFieldSubmitted: (_) => _submit(),
                            onChanged: (_) =>
                                ref.read(authControllerProvider.notifier).clearError(),
                          ),
                          const SizedBox(height: 22),

                          // Submit Button
                          AppButton(
                            text: 'Sign In to Operations',
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Role Switcher Tray for testing/evaluation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Demo Accounts (1-Tap Fill):',
                            style: AppTypography.dataLabel.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _demoChip(
                                label: 'Super Admin',
                                email: 'admin@auraliving.com',
                                roleColor: AppColors.primaryOlive,
                              ),
                              _demoChip(
                                label: 'Store Manager',
                                email: 'manager@auraliving.com',
                                roleColor: AppColors.info,
                              ),
                              _demoChip(
                                label: 'Inventory Staff',
                                email: 'staff@auraliving.com',
                                roleColor: AppColors.warning,
                              ),
                              _demoChip(
                                label: 'Non-Admin (Blocked)',
                                email: 'customer@example.com',
                                roleColor: AppColors.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer security notice
                    Text(
                      'Requires assigned staff role. Unauthorized access attempts are logged and reported.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip({
    required String label,
    required String email,
    required Color roleColor,
  }) {
    final isSelected = _emailController.text == email;

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      backgroundColor: isSelected ? roleColor : AppColors.surfaceSecondary,
      side: BorderSide(
        color: isSelected ? roleColor : AppColors.border,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => _fillAccount(email, 'password123'),
    );
  }
}
