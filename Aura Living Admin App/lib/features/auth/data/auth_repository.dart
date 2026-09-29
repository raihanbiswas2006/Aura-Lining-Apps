import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/admin_user.dart';

abstract class AuthRepository {
  Future<AdminUser?> getCurrentUser();
  Future<AdminUser> signInWithEmailPassword(String email, String password);
  Future<AdminUser> signIn(String email, String password);
  Future<void> signOut();
  Stream<AdminUser?> authStateChanges();
}

class MockAuthRepository implements AuthRepository {
  static const String _sessionUserKey = 'aura_admin_session_user';
  final _authStreamController = StreamController<AdminUser?>.broadcast();
  AdminUser? _currentUser;

  // Pre-configured staff accounts
  static final List<Map<String, dynamic>> _mockAccounts = [
    {
      'email': 'raihanbiswas2006@gmail.com',
      'password': 'password123',
      'user': AdminUser(
        id: 'usr-admin-raihan',
        name: 'Raihan Biswas',
        email: 'raihanbiswas2006@gmail.com',
        role: AdminRole.superAdmin,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        lastLoginAt: DateTime.now(),
      ),
      'isAdmin': true,
    },
    {
      'email': 'admin@auraliving.bd',
      'password': 'password123',
      'user': AdminUser(
        id: 'usr-admin-01',
        name: 'Raihan Biswas',
        email: 'admin@auraliving.bd',
        role: AdminRole.superAdmin,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        lastLoginAt: DateTime.now(),
      ),
      'isAdmin': true,
    },
    {
      'email': 'manager@auraliving.com',
      'password': 'password123',
      'user': AdminUser(
        id: 'usr-mgr-02',
        name: 'Lars Nyström',
        email: 'manager@auraliving.com',
        role: AdminRole.storeManager,
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
        lastLoginAt: DateTime.now(),
      ),
      'isAdmin': true,
    },
    {
      'email': 'staff@auraliving.com',
      'password': 'password123',
      'user': AdminUser(
        id: 'usr-stf-03',
        name: 'Freja Jensen',
        email: 'staff@auraliving.com',
        role: AdminRole.inventoryStaff,
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
        lastLoginAt: DateTime.now(),
      ),
      'isAdmin': true,
    },
    {
      'email': 'customer@example.com',
      'password': 'password123',
      'user': null,
      'isAdmin': false,
    },
  ];

  MockAuthRepository() {
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_sessionUserKey);
      if (userDataStr != null) {
        final map = jsonDecode(userDataStr) as Map<String, dynamic>;
        _currentUser = AdminUser(
          id: map['id'],
          name: map['name'],
          email: map['email'],
          role: AdminRole.values.firstWhere(
            (r) => r.name == map['role'],
            orElse: () => AdminRole.superAdmin,
          ),
          avatarUrl: map['avatarUrl'],
          lastLoginAt: DateTime.tryParse(map['lastLoginAt'] ?? '') ?? DateTime.now(),
        );
        _authStreamController.add(_currentUser);
      }
    } catch (_) {
      // Ignored if prefs not accessible
    }
  }

  @override
  Future<AdminUser?> getCurrentUser() async {
    if (_currentUser == null) {
      await _initSession();
    }
    return _currentUser;
  }

  @override
  Stream<AdminUser?> authStateChanges() {
    return _authStreamController.stream;
  }

  @override
  Future<AdminUser> signInWithEmailPassword(String email, String password) async {
    // Artificial operational latency (simulate network call)
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    final account = _mockAccounts.firstWhere(
      (acc) => (acc['email'] as String).toLowerCase() == normalizedEmail,
      orElse: () => throw Exception('Invalid administrative credentials.'),
    );

    if (account['password'] != password) {
      throw Exception('Invalid administrative credentials.');
    }

    final bool isAdmin = account['isAdmin'] as bool;
    if (!isAdmin || account['user'] == null) {
      throw Exception('Access Denied: Account does not possess administrative privileges.');
    }

    final user = (account['user'] as AdminUser).copyWith(
      lastLoginAt: DateTime.now(),
    );

    _currentUser = user;
    _authStreamController.add(user);

    // Save session in SharedPreferences for restart survival
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionUserKey,
        jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'role': user.role.name,
          'avatarUrl': user.avatarUrl,
          'lastLoginAt': user.lastLoginAt.toIso8601String(),
        }),
      );
    } catch (_) {}

    return user;
  }

  @override
  Future<AdminUser> signIn(String email, String password) => signInWithEmailPassword(email, password);

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStreamController.add(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserKey);
    } catch (_) {}
  }
}
