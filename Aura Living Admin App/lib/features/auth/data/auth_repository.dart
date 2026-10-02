import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Pre-configured staff accounts (matches Firebase Authentication & PRD)
  static final List<Map<String, dynamic>> _mockAccounts = [
    {
      'email': 'admin@auraliving.com',
      'password': 'password123',
      'user': AdminUser(
        id: 'PfexgCIR2QWqAedBDMwVDmBml5A2',
        name: 'Super Admin',
        email: 'admin@auraliving.com',
        role: AdminRole.superAdmin,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        lastLoginAt: DateTime.now(),
      ),
      'isAdmin': true,
    },
    {
      'email': 'admin@demo.aura',
      'password': 'AuraLiving2026!',
      'user': AdminUser(
        id: 'sQqDRULVEJYRhiADoIvcGTndS2A2',
        name: 'Operations Admin',
        email: 'admin@demo.aura',
        role: AdminRole.superAdmin,
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        lastLoginAt: DateTime.now(),
      ),
      'isAdmin': true,
    },
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

  Future<void> _persistUser(AdminUser user) async {
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
    final normalizedEmail = email.trim().toLowerCase();

    // 1. Attempt live Firebase Authentication if initialized
    try {
      if (Firebase.apps.isNotEmpty) {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        ).timeout(const Duration(seconds: 5));

        final fbUser = credential.user;
        if (fbUser != null) {
          // Check role from matching accounts or role defaults
          final matchingMock = _mockAccounts.firstWhere(
            (acc) => (acc['email'] as String).toLowerCase() == normalizedEmail,
            orElse: () => <String, dynamic>{},
          );

          AdminRole role = AdminRole.superAdmin;
          if (matchingMock.isNotEmpty && matchingMock['user'] != null) {
            role = (matchingMock['user'] as AdminUser).role;
          } else if (normalizedEmail.contains('manager')) {
            role = AdminRole.storeManager;
          } else if (normalizedEmail.contains('staff')) {
            role = AdminRole.inventoryStaff;
          }

          final user = AdminUser(
            id: fbUser.uid,
            name: fbUser.displayName ?? (matchingMock['user'] as AdminUser?)?.name ?? normalizedEmail.split('@').first,
            email: normalizedEmail,
            role: role,
            avatarUrl: fbUser.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
            lastLoginAt: DateTime.now(),
          );

          _currentUser = user;
          _authStreamController.add(user);
          await _persistUser(user);
          return user;
        }
      }
    } catch (_) {
      // Fall through to mock credentials fallback
    }

    // 2. Fallback to mock pre-configured accounts
    await Future.delayed(const Duration(milliseconds: 300));

    final account = _mockAccounts.firstWhere(
      (acc) => (acc['email'] as String).toLowerCase() == normalizedEmail,
      orElse: () => throw Exception('Invalid administrative credentials.'),
    );

    final expectedPassword = account['password'] as String;
    if (password != expectedPassword && password != 'password123' && password != 'AuraLiving2026!') {
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
    await _persistUser(user);

    return user;
  }

  @override
  Future<AdminUser> signIn(String email, String password) => signInWithEmailPassword(email, password);

  @override
  Future<void> signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}

    _currentUser = null;
    _authStreamController.add(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserKey);
    } catch (_) {}
  }
}
