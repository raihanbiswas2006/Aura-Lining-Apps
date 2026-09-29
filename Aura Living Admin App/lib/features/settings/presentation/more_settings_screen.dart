import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';

class MoreSettingsScreen extends ConsumerWidget {
  const MoreSettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDestructiveConfirmDialog(
      context: context,
      title: 'Sign Out of Operations?',
      consequenceText: 'You will need to sign in again with authorized staff credentials.',
      confirmButtonText: 'Sign Out',
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isSuperAdmin = user?.role == AdminRole.superAdmin;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Store Administration & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active User Overview Card
          if (user != null) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryOlive.withOpacity(0.1),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOlive,
                    ),
                  ),
                ),
                title: Text(user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${user.role.label} • ${user.email}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                onTap: () => context.push('/settings/profile'),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Section 1: Customer & Catalog Operations
          _sectionHeader('COMMERCE OPERATIONS'),
          const SizedBox(height: 6),
          _menuTile(
            context,
            icon: Icons.people_outline,
            title: 'Customer Directory',
            subtitle: 'View registered customers, lifetime spend & past orders',
            onTap: () => context.push('/settings/customers'),
          ),
          const SizedBox(height: 8),
          _menuTile(
            context,
            icon: Icons.category_outlined,
            title: 'Category Taxonomy',
            subtitle: 'Manage catalog categories, icons & product assignments',
            onTap: () => context.push('/products/categories'),
          ),
          const SizedBox(height: 18),

          // Section 2: Store Configuration (Super Admin & Managers)
          _sectionHeader('STORE CONFIGURATION'),
          const SizedBox(height: 6),
          _menuTile(
            context,
            icon: Icons.storefront_outlined,
            title: 'Store Operations Settings',
            subtitle: 'Master store toggle, support contacts & shipping rules',
            onTap: () => context.push('/settings/store'),
          ),
          const SizedBox(height: 8),
          _menuTile(
            context,
            icon: Icons.admin_panel_settings_outlined,
            title: 'Staff Accounts & Roles',
            subtitle: isSuperAdmin
                ? 'Invite staff and configure role permissions'
                : 'Restricted: Super Administrator access only',
            isGuarded: !isSuperAdmin,
            onTap: () => context.push('/settings/staff'),
          ),
          const SizedBox(height: 18),

          // Section 3: Identity & Session
          _sectionHeader('ADMIN PROFILE & SECURITY'),
          const SizedBox(height: 6),
          _menuTile(
            context,
            icon: Icons.badge_outlined,
            title: 'Admin Profile & RBAC Simulator',
            subtitle: 'Active session, role switcher & permission matrix',
            onTap: () => context.push('/settings/profile'),
          ),
          const SizedBox(height: 8),
          _menuTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out of Operations',
            subtitle: 'End active session on this device',
            isDestructive: true,
            onTap: () => _signOut(context, ref),
          ),
          const SizedBox(height: 24),

          // App version footer
          Center(
            child: Column(
              children: [
                Text(
                  'AURA LIVING • ADMIN APP',
                  style: AppTypography.monospacedNumber(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Version 1.0.0-phase2 (Build 2026.09)',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isGuarded = false,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.dangerBg
                : (isGuarded ? AppColors.surfaceSecondary : AppColors.surfaceSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive
                ? AppColors.danger
                : (isGuarded ? AppColors.textMuted : AppColors.primaryOlive),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.danger : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          isDestructive ? Icons.arrow_forward : Icons.chevron_right,
          size: 18,
          color: isDestructive ? AppColors.danger : AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}
