import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDestructiveConfirmDialog(
      context: context,
      title: 'Sign Out of Operations?',
      consequenceText: 'You will need to sign in again to access store operations.',
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Admin Profile & RBAC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User identity card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryOlive.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOlive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOlive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.role.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOlive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Session started: ${AppFormatters.formatDateTime(user.lastLoginAt)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Demo Role Switcher Chip Tray for Testing PRD Matrix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryOlive.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 18, color: AppColors.primaryOlive),
                      SizedBox(width: 8),
                      Text(
                        'Demo Role Simulator (QA Testing)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryOlive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Instantly switch active role to verify client-side permission gates and UI restrictions per PRD Section 3:',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _roleChip(context, ref, 'Super Admin', AdminRole.superAdmin, user.role),
                      _roleChip(context, ref, 'Store Manager', AdminRole.storeManager, user.role),
                      _roleChip(context, ref, 'Inventory Staff', AdminRole.inventoryStaff, user.role),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Permissions Matrix Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Role Permissions Matrix (Current User)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _permRow('Dashboard Full Analytics', user.role.canViewAnalytics),
                  _permRow('Create & Edit Products', user.role.canManageCatalog),
                  _permRow('Hard Delete Products', user.role.canDeleteProducts),
                  _permRow('Inventory Stock Adjustments', user.role.canAdjustInventory),
                  _permRow('Advance Order Status', user.role.canUpdateOrderStatus),
                  _permRow('Cancel & Refund Orders', user.role.canCancelOrders),
                  _permRow('Customer PII Visibility', user.role.canViewCustomerPII),
                  _permRow('Customer Review Moderation', user.role.canModerateReviews),
                  _permRow('Manage Coupon Promotions', user.role.canManageCoupons),
                  _permRow('Store Settings & Staff Accounts', user.role.canManageStoreSettings),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign out button
            AppButton(
              text: 'Sign Out of Operations Console',
              variant: ButtonVariant.destructive,
              icon: Icons.logout,
              onPressed: () => _signOut(context, ref),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(BuildContext context, WidgetRef ref, String label, AdminRole role, AdminRole currentRole) {
    final isSelected = role == currentRole;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryOlive,
      backgroundColor: AppColors.surfaceSecondary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(color: isSelected ? AppColors.primaryOlive : AppColors.border),
      onSelected: (selected) {
        if (selected) {
          ref.read(authControllerProvider.notifier).switchRoleForTesting(role);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${role.label}. UI gates updated.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _permRow(String label, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Row(
            children: [
              Icon(
                isGranted ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isGranted ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                isGranted ? 'Allowed' : 'Blocked',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGranted ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
