import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/i_auth_repository.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserProfile user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  UserProfile? get currentUser {
    final s = state;
    if (s is Authenticated) return s.user;
    return null;
  }

  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(email, password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(String name, String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(name, email, password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithPhone(String phone, String otp) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithPhone(phone, otp);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> continueAsGuest() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.continueAsGuest();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> addAddress(Address address) async {
    try {
      final user = await _authRepository.addAddress(address);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      final user = await _authRepository.updateAddress(address);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      final user = await _authRepository.deleteAddress(addressId);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      final user = await _authRepository.setDefaultAddress(addressId);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
