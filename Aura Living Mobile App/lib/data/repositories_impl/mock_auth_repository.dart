import 'dart:math';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/local_storage_service.dart';

class MockAuthRepository implements IAuthRepository {
  final LocalStorageService _storage;
  UserProfile? _currentUser;

  MockAuthRepository(this._storage) {
    _loadUser();
  }

  void _loadUser() {
    final raw = _storage.getUserRaw();
    if (raw != null) {
      _currentUser = UserProfile.fromJson(raw);
    } else {
      // Default initial mock user localized for Bangladesh
      _currentUser = const UserProfile(
        id: 'user-001',
        name: 'Raihan Biswas',
        email: 'raihanbiswas2006@gmail.com',
        phone: '+8801712345678',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        isGuest: false,
        addresses: [
          Address(
            id: 'addr-001',
            fullName: 'Raihan Biswas',
            addressLine1: 'House 42, Road 11, Block D',
            addressLine2: 'Apt 4B, Banani',
            city: 'Dhaka',
            division: 'Dhaka',
            district: 'Dhaka',
            thana: 'Banani',
            postalCode: '1213',
            country: 'Bangladesh',
            phone: '+8801712345678',
            isDefault: true,
          ),
          Address(
            id: 'addr-002',
            fullName: 'Raihan Biswas (Design Studio)',
            addressLine1: 'Level 5, Road 27, Dhanmondi',
            city: 'Dhaka',
            division: 'Dhaka',
            district: 'Dhaka',
            thana: 'Dhanmondi',
            postalCode: '1209',
            country: 'Bangladesh',
            phone: '+8801712345678',
            isDefault: false,
          ),
        ],
      );
      _storage.saveUserRaw(_currentUser!.toJson());
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = UserProfile(
      id: 'user-${Random().nextInt(9000) + 1000}',
      name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
      email: email,
      phone: '+8801712345678',
      isGuest: false,
      addresses: _currentUser?.addresses ?? [],
    );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> signInWithPhone(String phone, String otp) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = UserProfile(
      id: 'user-phone-${Random().nextInt(9000) + 1000}',
      name: 'Aura Member (${phone.substring(phone.length - 4)})',
      email: '$phone@auraliving.bd',
      phone: phone,
      isGuest: false,
      addresses: _currentUser?.addresses ?? [],
    );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = UserProfile(
      id: 'user-${Random().nextInt(9000) + 1000}',
      name: name,
      email: email,
      phone: '+8801712345678',
      isGuest: false,
      addresses: [],
    );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> continueAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = const UserProfile(
      id: 'guest-user',
      name: 'Guest Shopper',
      email: 'guest@aura-living.com',
      isGuest: true,
      addresses: [],
    );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    await _storage.clearUser();
  }

  @override
  Future<UserProfile> addAddress(Address address) async {
    final currentList = List<Address>.from(_currentUser?.addresses ?? []);
    if (address.isDefault) {
      for (var i = 0; i < currentList.length; i++) {
        currentList[i] = currentList[i].copyWith(isDefault: false);
      }
    }
    currentList.add(address);
    _currentUser = _currentUser?.copyWith(addresses: currentList) ??
        UserProfile(
          id: 'user-temp',
          name: 'Customer',
          email: '',
          addresses: currentList,
        );
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> updateAddress(Address address) async {
    final currentList = List<Address>.from(_currentUser?.addresses ?? []);
    final index = currentList.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      if (address.isDefault) {
        for (var i = 0; i < currentList.length; i++) {
          currentList[i] = currentList[i].copyWith(isDefault: false);
        }
      }
      currentList[index] = address;
    }
    _currentUser = _currentUser?.copyWith(addresses: currentList);
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> deleteAddress(String addressId) async {
    final currentList = List<Address>.from(_currentUser?.addresses ?? []);
    currentList.removeWhere((a) => a.id == addressId);
    _currentUser = _currentUser?.copyWith(addresses: currentList);
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }

  @override
  Future<UserProfile> setDefaultAddress(String addressId) async {
    final currentList = List<Address>.from(_currentUser?.addresses ?? []);
    for (var i = 0; i < currentList.length; i++) {
      currentList[i] = currentList[i].copyWith(
        isDefault: currentList[i].id == addressId,
      );
    }
    _currentUser = _currentUser?.copyWith(addresses: currentList);
    await _storage.saveUserRaw(_currentUser!.toJson());
    return _currentUser!;
  }
}
