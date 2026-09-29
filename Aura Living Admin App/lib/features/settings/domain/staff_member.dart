import '../../auth/domain/admin_user.dart';

/// Staff Member Model for Super Admin management per PRD Section 6.8
class StaffMember {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final DateTime addedAt;
  final bool isActive;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.addedAt,
    this.isActive = true,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    AdminRole? role,
    DateTime? addedAt,
    bool? isActive,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
