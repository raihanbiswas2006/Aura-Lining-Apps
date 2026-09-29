import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/local_storage_service.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final LocalStorageService _storage;
  UserProfile? _currentUser;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    required LocalStorageService storage,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage {
    _initLocalCache();
  }

  void _initLocalCache() {
    final raw = _storage.getUserRaw();
    if (raw != null) {
      try {
        _currentUser = UserProfile.fromJson(raw);
      } catch (_) {}
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      _currentUser = null;
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentUser = UserProfile.fromJson(data);
        await _storage.saveUserRaw(_currentUser!.toJson());
        return _currentUser;
      }
    } catch (_) {
      // Return cached user if offline
      if (_currentUser != null && _currentUser!.id == firebaseUser.uid) {
        return _currentUser;
      }
    }

    // Default fallback from FirebaseAuth token details
    _currentUser = UserProfile(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'Aura Member',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber,
      isGuest: firebaseUser.isAnonymous,
      addresses: _currentUser?.addresses ?? [],
    );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Authentication failed: No user returned.');
      }

      // Fetch Firestore profile
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _currentUser = UserProfile.fromJson(userDoc.data()!);
      } else {
        _currentUser = UserProfile(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: email.trim(),
          phone: firebaseUser.phoneNumber,
          isGuest: false,
          addresses: [],
        );
        // Persist initial document in Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          ..._currentUser!.toJson(),
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _storage.saveUserRaw(_currentUser!.toJson());
      return _currentUser!;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile> register(String name, String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Registration failed: User could not be created.');
      }

      // Update Firebase Auth display name
      await firebaseUser.updateDisplayName(name);

      _currentUser = UserProfile(
        id: firebaseUser.uid,
        name: name,
        email: email.trim(),
        isGuest: false,
        addresses: [],
      );

      // Create document in Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        ..._currentUser!.toJson(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _storage.saveUserRaw(_currentUser!.toJson());
      return _currentUser!;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile> signInWithPhone(String phone, String otp) async {
    // Phone auth can link or authenticate directly
    _currentUser = UserProfile(
      id: 'phone-${phone.hashCode.abs()}',
      name: 'Aura Member (${phone.length >= 4 ? phone.substring(phone.length - 4) : phone})',
      email: '$phone@auraliving.bd',
      phone: phone,
      isGuest: false,
      addresses: _currentUser?.addresses ?? [],
    );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> continueAsGuest() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final firebaseUser = credential.user;
      _currentUser = UserProfile(
        id: firebaseUser?.uid ?? 'guest-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Guest Shopper',
        email: 'guest@auraliving.bd',
        isGuest: true,
        addresses: [],
      );
      await _storage.saveUserRaw(_currentUser!.toJson());
      return _currentUser!;
    } catch (_) {
      _currentUser = const UserProfile(
        id: 'guest-offline',
        name: 'Guest Shopper',
        email: 'guest@auraliving.bd',
        isGuest: true,
      );
      await _storage.saveUserRaw(_currentUser!.toJson());
      return _currentUser!;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _currentUser = null;
    await _storage.clearUser();
  }

  @override
  Future<UserProfile> addAddress(Address address) async {
    if (_currentUser == null) throw Exception('No active user logged in.');
    final updatedList = List<Address>.from(_currentUser!.addresses)..add(address);
    _currentUser = _currentUser!.copyWith(addresses: updatedList);
    await _saveUserDoc();
    return _currentUser!;
  }

  @override
  Future<UserProfile> updateAddress(Address address) async {
    if (_currentUser == null) throw Exception('No active user logged in.');
    final updatedList = _currentUser!.addresses.map((a) => a.id == address.id ? address : a).toList();
    _currentUser = _currentUser!.copyWith(addresses: updatedList);
    await _saveUserDoc();
    return _currentUser!;
  }

  @override
  Future<UserProfile> deleteAddress(String addressId) async {
    if (_currentUser == null) throw Exception('No active user logged in.');
    final updatedList = _currentUser!.addresses.where((a) => a.id != addressId).toList();
    _currentUser = _currentUser!.copyWith(addresses: updatedList);
    await _saveUserDoc();
    return _currentUser!;
  }

  @override
  Future<UserProfile> setDefaultAddress(String addressId) async {
    if (_currentUser == null) throw Exception('No active user logged in.');
    final updatedList = _currentUser!.addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();
    _currentUser = _currentUser!.copyWith(addresses: updatedList);
    await _saveUserDoc();
    return _currentUser!;
  }

  Future<void> _saveUserDoc() async {
    if (_currentUser == null) return;
    await _storage.saveUserRaw(_currentUser!.toJson());
    if (!_currentUser!.isGuest) {
      try {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'addresses': _currentUser!.addresses.map((a) => a.toJson()).toList(),
        });
      } catch (_) {}
    }
  }

  String _mapAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email. Please check your email or register.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or credentials entered. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password entered is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection issue. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment before trying again.';
      default:
        return e.message ?? 'Authentication error occurred (${e.code}).';
    }
  }
}
