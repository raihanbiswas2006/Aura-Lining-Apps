import 'dart:async';
import 'package:uuid/uuid.dart';
import '../domain/store_settings.dart';
import '../../auth/domain/admin_user.dart';

abstract class SettingsRepository {
  Future<StoreSettings> getStoreSettings();
  Future<StoreSettings> updateStoreSettings(StoreSettings settings);
  Future<List<StaffMember>> getStaffMembers();
  Future<StaffMember> inviteStaffMember(String email, AdminRole role, String name);
  Future<StaffMember> updateStaffRole(String staffId, AdminRole newRole);
  Future<bool> removeStaffMember(String staffId);
  Stream<StoreSettings> watchStoreSettings();
  Stream<List<StaffMember>> watchStaffMembers();
}

class MockSettingsRepository implements SettingsRepository {
  final _uuid = const Uuid();
  final _settingsStream = StreamController<StoreSettings>.broadcast();
  final _staffStream = StreamController<List<StaffMember>>.broadcast();

  late StoreSettings _settings;
  late List<StaffMember> _staff;

  MockSettingsRepository() {
    _settings = const StoreSettings();
    _seedStaff();
  }

  void _seedStaff() {
    final now = DateTime.now();

    _staff = [
      StaffMember(
        id: 'usr-admin-01',
        name: 'Astrid Lindgren',
        email: 'admin@auraliving.com',
        role: AdminRole.superAdmin,
        addedAt: now.subtract(const Duration(days: 365)),
      ),
      StaffMember(
        id: 'usr-mgr-02',
        name: 'Lars Nyström',
        email: 'manager@auraliving.com',
        role: AdminRole.storeManager,
        addedAt: now.subtract(const Duration(days: 180)),
      ),
      StaffMember(
        id: 'usr-stf-03',
        name: 'Freja Jensen',
        email: 'staff@auraliving.com',
        role: AdminRole.inventoryStaff,
        addedAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }

  @override
  Stream<StoreSettings> watchStoreSettings() {
    return _settingsStream.stream;
  }

  @override
  Stream<List<StaffMember>> watchStaffMembers() {
    return _staffStream.stream;
  }

  @override
  Future<StoreSettings> getStoreSettings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _settings;
  }

  @override
  Future<StoreSettings> updateStoreSettings(StoreSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _settings = settings;
    _settingsStream.add(_settings);
    return _settings;
  }

  @override
  Future<List<StaffMember>> getStaffMembers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_staff);
  }

  @override
  Future<StaffMember> inviteStaffMember(String email, AdminRole role, String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final member = StaffMember(
      id: 'usr-stf-${_uuid.v4().substring(0, 6)}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: role,
      addedAt: DateTime.now(),
    );
    _staff.add(member);
    _staffStream.add(List.unmodifiable(_staff));
    return member;
  }

  @override
  Future<StaffMember> updateStaffRole(String staffId, AdminRole newRole) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx == -1) throw Exception('Staff member not found');

    final updated = _staff[idx].copyWith(role: newRole);
    _staff[idx] = updated;
    _staffStream.add(List.unmodifiable(_staff));
    return updated;
  }

  @override
  Future<bool> removeStaffMember(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx == -1) return false;

    _staff.removeAt(idx);
    _staffStream.add(List.unmodifiable(_staff));
    return true;
  }
}
