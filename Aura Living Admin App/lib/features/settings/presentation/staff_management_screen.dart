import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/staff_member.dart';
import 'settings_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  void _showInviteStaffModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _InviteStaffSheet(),
    );
  }

  Future<void> _updateStaffRole(StaffMember staff, AdminRole newRole) async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.updateStaffRole(staff.id, newRole);
      ref.invalidate(staffMembersStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} role updated to ${newRole.label}.'),
            backgroundColor: AppColors.primaryOlive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _removeStaff(StaffMember staff) async {
    final confirmed = await showDestructiveConfirmDialog(
      context: context,
      title: 'Remove Staff Member "${staff.name}"?',
      consequenceText:
          'This will revoke all administrative access for ${staff.email}. This action is logged.',
      confirmButtonText: 'Revoke Access',
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(settingsRepositoryProvider);
        await repo.removeStaffMember(staff.id);
        ref.invalidate(staffMembersStreamProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff member ${staff.name} removed.'),
              backgroundColor: AppColors.primaryOlive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isSuperAdmin = user?.role == AdminRole.superAdmin;
    final staffAsync = ref.watch(staffMembersStreamProvider);

    if (!isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff & Permissions')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: EmptyStateView(
              title: 'Access Restricted',
              subtitle: 'Staff team accounts and role assignments can only be configured by Super Administrators.',
              icon: Icons.admin_panel_settings_outlined,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Staff & Team Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite Staff',
            onPressed: _showInviteStaffModal,
          ),
        ],
      ),
      body: staffAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return const EmptyStateView(
              title: 'No Staff Accounts',
              subtitle: 'No administrative staff accounts registered.',
              icon: Icons.people_outline,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final staff = staffList[index];
              final isCurrent = staff.id == user?.id;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryOlive.withOpacity(0.1),
                      child: Text(
                        staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryOlive),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                staff.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOlive.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('You', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primaryOlive)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staff.email,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  staff.role.label,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Added ${AppFormatters.formatDate(staff.addedAt)}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isCurrent) ...[
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                        onSelected: (val) {
                          if (val == 'role_super') {
                            _updateStaffRole(staff, AdminRole.superAdmin);
                          } else if (val == 'role_mgr') {
                            _updateStaffRole(staff, AdminRole.storeManager);
                          } else if (val == 'role_staff') {
                            _updateStaffRole(staff, AdminRole.inventoryStaff);
                          } else if (val == 'remove') {
                            _removeStaff(staff);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            enabled: false,
                            child: Text('Change Role:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                          ),
                          PopupMenuItem(
                            value: 'role_super',
                            child: Text('Make Super Admin', style: TextStyle(fontWeight: staff.role == AdminRole.superAdmin ? FontWeight.w700 : FontWeight.normal)),
                          ),
                          PopupMenuItem(
                            value: 'role_mgr',
                            child: Text('Make Store Manager', style: TextStyle(fontWeight: staff.role == AdminRole.storeManager ? FontWeight.w700 : FontWeight.normal)),
                          ),
                          PopupMenuItem(
                            value: 'role_staff',
                            child: Text('Make Inventory Staff', style: TextStyle(fontWeight: staff.role == AdminRole.inventoryStaff ? FontWeight.w700 : FontWeight.normal)),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.person_remove_outlined, size: 16, color: AppColors.danger),
                                SizedBox(width: 8),
                                Text('Remove Account', style: TextStyle(color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const ShimmerCard(height: 70),
        ),
        error: (err, stack) => Center(child: Text('Error loading staff: $err')),
      ),
    );
  }
}

class _InviteStaffSheet extends ConsumerStatefulWidget {
  const _InviteStaffSheet();

  @override
  ConsumerState<_InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends ConsumerState<_InviteStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  AdminRole _selectedRole = AdminRole.inventoryStaff;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      await repo.inviteStaffMember(
        _emailController.text.trim(),
        _selectedRole,
        _nameController.text.trim(),
      );
      ref.invalidate(staffMembersStreamProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff account invited: ${_emailController.text.trim()}'),
            backgroundColor: AppColors.primaryOlive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Invite Staff Member', style: AppTypography.sectionHeader),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Full Name *',
                hintText: 'e.g., Johan Ekström',
                controller: _nameController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Work Email Address *',
                hintText: 'e.g., johan@auraliving.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid work email' : null,
              ),
              const SizedBox(height: 14),
              const Text('Assigned Role *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<AdminRole>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: AdminRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.label, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Send Staff Invitation',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
