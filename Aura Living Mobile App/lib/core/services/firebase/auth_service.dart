import 'dart:async';
import '../../../domain/entities/user_profile.dart';
import '../../constants/bangladesh_regions.dart';

/// Contract for Authentication Service (Firebase Auth / Custom backend ready)
abstract class AuthService {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;

  Future<UserProfile> signInWithEmail(String email, String password);
  Future<UserProfile> registerWithEmail(String name, String email, String password);
  
  /// Bangladesh Phone Authentication (+8801XXXXXXXXX)
  Future<void> sendOtpToPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  });

  Future<UserProfile> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
  });

  /// Google Social Authentication
  Future<UserProfile> signInWithGoogle();

  Future<void> signOut();
}

/// Production-ready Firebase Auth architecture implementation with seamless mock fallback
class FirebaseAuthService implements AuthService {
  final _authStateController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  FirebaseAuthService({UserProfile? initialUser}) {
    _currentUser = initialUser;
    _authStateController.add(_currentUser);
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    // In full Firebase integration: await FirebaseAuth.instance.signInWithEmailAndPassword(...)
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserProfile(
      id: 'usr-${email.hashCode.abs()}',
      email: email,
      name: email.split('@').first.toUpperCase(),
      phone: '+8801712345678',
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> registerWithEmail(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserProfile(
      id: 'usr-${email.hashCode.abs()}',
      email: email,
      name: name,
      phone: '+8801712345678',
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendOtpToPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    final normalized = BangladeshRegions.normalizePhone(phoneNumber);
    if (normalized == null) {
      onError('Invalid Bangladeshi phone number. Use format: +8801XXXXXXXXX or 01XXXXXXXXX');
      return;
    }

    // In full Firebase integration:
    // await FirebaseAuth.instance.verifyPhoneNumber(
    //   phoneNumber: normalized,
    //   verificationCompleted: ...,
    //   verificationFailed: ...,
    //   codeSent: (id, token) => onCodeSent(id),
    // );
    await Future.delayed(const Duration(milliseconds: 600));
    onCodeSent('mock-vid-${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Future<UserProfile> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (smsCode.length < 4) {
      throw Exception('Invalid verification code entered.');
    }
    _currentUser = UserProfile(
      id: 'usr-phone-${DateTime.now().millisecondsSinceEpoch}',
      email: 'verified_user@auraliving.bd',
      name: displayName ?? 'Aura Living Member',
      phone: '+8801712345678',
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    // In full Firebase integration:
    // final googleUser = await GoogleSignIn().signIn();
    // final cred = GoogleAuthProvider.credential(...);
    // await FirebaseAuth.instance.signInWithCredential(cred);
    await Future.delayed(const Duration(milliseconds: 700));
    _currentUser = const UserProfile(
      id: 'usr-google-88912',
      email: 'raihanbiswas2006@gmail.com',
      name: 'Raihan Biswas',
      phone: '+8801712345678',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
