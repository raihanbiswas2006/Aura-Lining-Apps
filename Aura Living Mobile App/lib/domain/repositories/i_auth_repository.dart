import '../entities/address.dart';
import '../entities/user_profile.dart';

abstract class IAuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> register(String name, String email, String password);
  Future<UserProfile> signInWithPhone(String phone, String otp);
  Future<UserProfile> continueAsGuest();
  Future<void> signOut();
  Future<UserProfile> addAddress(Address address);
  Future<UserProfile> updateAddress(Address address);
  Future<UserProfile> deleteAddress(String addressId);
  Future<UserProfile> setDefaultAddress(String addressId);
}
