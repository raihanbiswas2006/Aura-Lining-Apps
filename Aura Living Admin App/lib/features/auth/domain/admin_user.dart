/// Administrative roles per PRD Section 3
enum AdminRole {
  superAdmin('Super Admin'),
  storeManager('Store Manager'),
  inventoryStaff('Inventory Staff');

  final String label;
  const AdminRole(this.label);

  bool get canManageSettings => this == AdminRole.superAdmin;
  bool get canManageStoreSettings => canManageSettings;
  bool get canManageStaff => this == AdminRole.superAdmin;
  bool get canCreateEditProduct => this == AdminRole.superAdmin || this == AdminRole.storeManager;
  bool get canManageCatalog => canCreateEditProduct;
  bool get canHardDeleteProduct => this == AdminRole.superAdmin;
  bool get canDeleteProducts => canHardDeleteProduct;
  bool get canDeactivateProduct => this == AdminRole.superAdmin || this == AdminRole.storeManager;
  bool get canAdjustStock => true;
  bool get canAdjustInventory => canAdjustStock;
  bool get canUpdateOrderStatus => true;
  bool get canCancelRefundOrder => this == AdminRole.superAdmin || this == AdminRole.storeManager;
  bool get canCancelOrders => canCancelRefundOrder;
  bool get canViewFullCustomerDetails => this == AdminRole.superAdmin || this == AdminRole.storeManager;
  bool get canViewCustomerPII => canViewFullCustomerDetails;
  bool get canModerateReviews => this == AdminRole.superAdmin || this == AdminRole.storeManager;
  bool get canManageCoupons => this == AdminRole.superAdmin || this == AdminRole.storeManager;
  bool get canViewAnalytics => this == AdminRole.superAdmin || this == AdminRole.storeManager;
}

/// Administrative User Entity
class AdminUser {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final String? avatarUrl;
  final DateTime lastLoginAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.lastLoginAt,
  });

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    AdminRole? role,
    String? avatarUrl,
    DateTime? lastLoginAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
