import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:swift_dine/utils/shared_prefs_manager.dart';

import 'backend_api.dart';

/// Auth service that keeps Firebase Auth for sign-in UX,
/// but syncs users and tokens with the MEZAHUB backend.
class BackendAuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  fb.User? get currentUser => _firebaseAuth.currentUser;

  Future<fb.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      // Register in backend as customer by default.
      await BackendApi.register(
        name: fullName,
        email: email,
        password: password,
        role: 'customer',
      );
      await SharedPrefsManager().saveUserProfile(
        name: fullName,
        email: email,
        phone: '+254700000000',
        userId: user.uid,
        avatarUrl: null,
      );
    }
    return user;
  }

  Future<fb.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await BackendApi.login(email, password);
      await SharedPrefsManager().saveUserProfile(
        name: user.displayName ?? 'User',
        email: email,
        phone: '+254700000000',
        userId: user.uid,
        avatarUrl: user.photoURL,
      );
    }
    return user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await SharedPrefsManager().clearTokens();
    await SharedPrefsManager().clearUserProfile();
  }
}

