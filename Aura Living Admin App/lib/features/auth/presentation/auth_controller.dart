import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/admin_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

class AuthState {
  final AdminUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AdminUser? user,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signInWithEmailPassword(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = state.copyWith(
      clearUser: true,
      isLoading: false,
      clearError: true,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Switch user helper for quick demonstration of permission matrices
  Future<void> switchDemoRole(AdminRole role) async {
    String email;
    switch (role) {
      case AdminRole.superAdmin:
        email = 'admin@auraliving.com';
        break;
      case AdminRole.storeManager:
        email = 'manager@auraliving.com';
        break;
      case AdminRole.inventoryStaff:
        email = 'staff@auraliving.com';
        break;
    }
    await signIn(email, 'password123');
  }

  Future<void> switchRoleForTesting(AdminRole role) => switchDemoRole(role);
}

final authControllerProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
