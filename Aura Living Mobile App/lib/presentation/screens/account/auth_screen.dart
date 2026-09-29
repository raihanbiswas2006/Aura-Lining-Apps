import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/bangladesh_regions.dart';
import '../../../core/widgets/aura_button.dart';
import '../../../core/widgets/aura_text_field.dart';
import '../../blocs/auth/auth_cubit.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _isPhoneMode = true; // Default to Bangladesh Phone Auth (+880)
  bool _otpSent = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+8801712345678');
  final _otpController = TextEditingController(text: '123456');
  final _emailController = TextEditingController(text: 'raihanbiswas2006@gmail.com');
  final _passwordController = TextEditingController(text: 'secret123');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<AuthCubit>();
    if (_isPhoneMode) {
      if (!_otpSent) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification OTP code sent to ${_phoneController.text.trim()} (Use 123456)'),
            backgroundColor: AppColors.accentForest,
          ),
        );
      } else {
        cubit.signInWithPhone(
          _phoneController.text.trim(),
          _otpController.text.trim(),
        );
      }
    } else {
      if (_isSignUp) {
        cubit.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        cubit.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          widget.onAuthSuccess();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_isSignUp ? 'Create Account' : 'Welcome to Aura Living'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSignUp ? 'Join Aura Living' : 'Sign In',
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isPhoneMode
                          ? 'Authenticate with your Bangladesh mobile number (+880) for instant OTP access.'
                          : 'Enter your credentials to access your order history and saved pieces.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Auth Method Switcher: Phone vs Email
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone_android, size: 16),
                            label: const Text('Mobile (+880)'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _isPhoneMode ? AppColors.primary : AppColors.surface,
                              foregroundColor: _isPhoneMode ? Colors.white : AppColors.textPrimary,
                              side: BorderSide(color: _isPhoneMode ? AppColors.primary : AppColors.border),
                            ),
                            onPressed: () => setState(() {
                              _isPhoneMode = true;
                              _otpSent = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.mail_outline, size: 16),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: !_isPhoneMode ? AppColors.primary : AppColors.surface,
                              foregroundColor: !_isPhoneMode ? Colors.white : AppColors.textPrimary,
                              side: BorderSide(color: !_isPhoneMode ? AppColors.primary : AppColors.border),
                            ),
                            onPressed: () => setState(() {
                              _isPhoneMode = false;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (state is AuthError) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.discountBadge.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.discountBadge),
                        ),
                        child: Text(
                          state.message,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.discountBadge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (_isPhoneMode) ...[
                      // Bangladesh Phone Number Input
                      AuraTextField(
                        label: 'BANGLADESH MOBILE NUMBER *',
                        hintText: '+880 1712-345678 or 017XXXXXXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (!BangladeshRegions.phoneRegex.hasMatch(v.replaceAll(RegExp(r'[\s\-]'), ''))) {
                            return 'Enter a valid BD mobile (+8801XXXXXXXXX or 01XXXXXXXXX)';
                          }
                          return null;
                        },
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        AuraTextField(
                          label: 'SMS VERIFICATION CODE (OTP) *',
                          hintText: '6-digit OTP code (e.g. 123456)',
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.trim().length < 4 ? 'Enter valid OTP' : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AuraPrimaryButton(
                        label: _otpSent ? 'Verify OTP & Continue' : 'Send Bangladesh OTP Code',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                    ] else ...[
                      if (_isSignUp) ...[
                        AuraTextField(
                          label: 'FULL NAME',
                          hintText: 'e.g. Raihan Biswas',
                          controller: _nameController,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      AuraTextField(
                        label: 'EMAIL ADDRESS',
                        hintText: 'raihanbiswas2006@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AuraTextField(
                        label: 'PASSWORD',
                        hintText: '••••••••',
                        isPassword: true,
                        controller: _passwordController,
                        validator: (v) {
                          if (v == null || v.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      AuraPrimaryButton(
                        label: _isSignUp ? 'Create Customer Account' : 'Sign In',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          },
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign In'
                                : "Don't have an account? Create one",
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 36),

                    // Guest checkout option
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.read<AuthCubit>().continueAsGuest();
                        },
                        child: Text(
                          'Continue as Guest',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
