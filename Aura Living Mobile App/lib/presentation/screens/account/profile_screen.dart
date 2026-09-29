import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../blocs/auth/auth_cubit.dart';
import 'auth_screen.dart';
import 'order_history_screen.dart';
import 'saved_addresses_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onNavigateToWishlist;

  const ProfileScreen({
    super.key,
    required this.onNavigateToWishlist,
  });

  void _openAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          onAuthSuccess: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state is Authenticated ? state.user : null;
          final isGuest = user == null || user.isGuest;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.surfaceSecondary,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 32,
                              color: AppColors.textSecondary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGuest ? 'Guest Shopper' : user.name,
                            style: AppTypography.titleMedium.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isGuest ? 'Sign in for full access' : user.email,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isGuest)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => _openAuth(context),
                        child: const Text('Sign In'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu Group 1: Commerce
              Text('MY COMMERCE', style: AppTypography.overline),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      subtitle: 'Track active and past deliveries',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      subtitle: 'Manage delivery addresses',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SavedAddressesScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildMenuItem(
                      icon: Icons.favorite_border,
                      title: 'Saved Pieces (Wishlist)',
                      subtitle: 'Your curated personal wishlist',
                      onTap: onNavigateToWishlist,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu Group 2: Preferences & Brand
              Text('PREFERENCES & ATELIER', style: AppTypography.overline),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications & Order Alerts',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications set to default (Transactional only)'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildMenuItem(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Mindful Data Policy',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Privacy Policy'),
                            content: const Text(
                              'Aura Living respects mindful minimalism in all dimensions—including data. We collect only what is strictly necessary to deliver handcrafted goods safely to your home.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildMenuItem(
                      icon: Icons.eco_outlined,
                      title: 'Artisanal Sustainability Commitment',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Our Ethos'),
                            content: const Text(
                              'Every piece in our catalog is crafted using FSC-certified wood, natural mineral stone, and OEKO-TEX European textiles designed to endure across generations.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Understood'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!isGuest)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warningTerracotta,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  onPressed: () {
                    context.read<AuthCubit>().signOut();
                  },
                ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTypography.bodySmall)
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
