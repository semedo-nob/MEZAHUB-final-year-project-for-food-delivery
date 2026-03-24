import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:swift_dine/services/backend_api.dart';
import 'package:swift_dine/utils/shared_prefs_manager.dart';

/// Lightweight app user (replaces Supabase User). Backed by backend JWT + SharedPrefs.
class AppUser {
  final String id;
  final String? email;
  final String? name;
  final String? phone;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    this.email,
    this.name,
    this.phone,
    this.avatarUrl,
  });
}

/// Auth using backend API (JWT) + optional Firebase Storage for profile images.
/// No Supabase.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();

  Stream<AppUser?> get userStream => _userController.stream;

  AppUser? _cachedUser;

  /// Returns current user from SharedPrefs when we have a valid session (token + userId).
  Future<AppUser?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    final token = await SharedPrefsManager().getAccessToken();
    if (token == null || token.isEmpty) return null;
    final prefs = await SharedPrefsManager().getUserProfile();
    final userId = prefs['userId'];
    if (userId == null || userId.isEmpty) return null;
    _cachedUser = AppUser(
      id: userId,
      email: prefs['email'],
      name: prefs['name'],
      phone: prefs['phone'],
      avatarUrl: prefs['avatarUrl'],
    );
    return _cachedUser;
  }

  /// Sign up via backend; saves tokens and profile to SharedPrefs.
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final data = await BackendApi.register(
      name: fullName,
      email: email,
      password: password,
      role: 'customer',
      phone: null,
    );
    final userMap = data['user'] as Map<String, dynamic>?;
    if (userMap == null) return null;
    final id = userMap['id']?.toString() ?? '';
    final name = userMap['name'] as String? ?? fullName;
    final phone = userMap['phone'] as String? ?? '';
    await SharedPrefsManager().saveUserProfile(
      name: name,
      email: email,
      phone: phone.isEmpty ? '+254700000000' : phone,
      userId: id,
      avatarUrl: null,
    );
    _cachedUser = AppUser(id: id, email: email, name: name, phone: phone);
    _userController.add(_cachedUser);
    return _cachedUser;
  }

  /// Sign in via backend; saves tokens and profile to SharedPrefs.
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final data = await BackendApi.login(email, password);
    Map<String, dynamic>? userMap = data['user'] as Map<String, dynamic>?;
    if (userMap == null) {
      try {
        final profile = await BackendApi.getProfile();
        userMap = profile;
      } catch (_) {
        return null;
      }
    }
    if (userMap == null) return null;
    final id = userMap['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    final name = userMap['name'] as String? ?? email;
    final phone = userMap['phone'] as String? ?? '+254700000000';
    await SharedPrefsManager().saveUserProfile(
      name: name,
      email: email,
      phone: phone,
      userId: id,
      avatarUrl: userMap['profile_image'] as String?,
    );
    _cachedUser = AppUser(
      id: id,
      email: email,
      name: name,
      phone: phone,
      avatarUrl: userMap['profile_image'] as String?,
    );
    _userController.add(_cachedUser);
    return _cachedUser;
  }

  /// Sign out: clear tokens and profile, emit null.
  Future<void> signOut() async {
    await SharedPrefsManager().clearUserProfile();
    await SharedPrefsManager().clearTokens();
    _cachedUser = null;
    _userController.add(null);
  }

  /// Sync profile from backend and save to SharedPrefs; emit updated user.
  Future<void> syncUserData(AppUser user) async {
    try {
      final profile = await BackendApi.getProfile();
      final id = profile['id']?.toString() ?? user.id;
      final name = profile['name'] as String? ?? user.name;
      final email = profile['email'] as String? ?? user.email;
      final phone = profile['phone'] as String? ?? user.phone;
      final avatarUrl = profile['profile_image'] as String? ?? user.avatarUrl;
      await SharedPrefsManager().saveUserProfile(
        name: name ?? 'User',
        email: email ?? '',
        phone: phone ?? '+254700000000',
        userId: id,
        avatarUrl: avatarUrl,
      );
      _cachedUser = AppUser(
        id: id,
        email: email,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      _userController.add(_cachedUser);
    } catch (_) {
      // Offline or token expired; keep existing prefs
    }
  }

  /// Get profile from local storage (and optionally refresh from backend).
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = await getCurrentUser();
    if (user == null) return null;
    final prefs = await SharedPrefsManager().getUserProfile();
    return {
      'id': user.id,
      'email': prefs['email'],
      'full_name': prefs['name'],
      'phone': prefs['phone'],
      'avatar_url': prefs['avatarUrl'],
    };
  }

  /// Update profile on backend and locally.
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    await BackendApi.updateProfile(name: fullName, phone: phone, profileImage: avatarUrl);
    final user = await getCurrentUser();
    if (user != null) {
      await SharedPrefsManager().saveUserProfile(
        name: fullName,
        email: user.email ?? '',
        phone: phone,
        userId: user.id,
        avatarUrl: avatarUrl,
      );
      _cachedUser = AppUser(
        id: user.id,
        email: user.email,
        name: fullName,
        phone: phone,
        avatarUrl: avatarUrl ?? user.avatarUrl,
      );
      _userController.add(_cachedUser);
    }
  }

  /// Upload profile image to Firebase Storage and return public URL.
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(imagePath));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  void close() {
    // Intentionally left as a no-op.
    //
    // AuthService is a singleton; closing its stream would break listeners
    // across the app lifetime.
  }
}
