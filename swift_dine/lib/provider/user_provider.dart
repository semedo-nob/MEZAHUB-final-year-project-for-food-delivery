import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swift_dine/services/auth_service.dart';
import 'dart:async';
import 'package:swift_dine/utils/shared_prefs_manager.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SharedPrefsManager _sharedPrefs = SharedPrefsManager();

  String? _userName;
  String? _email;
  String? _phoneNumber;
  String? _profileImageUrl;
  String? _userId;

  StreamSubscription<User?>? _authSubscription;

  // Getters
  String? get userName => _userName;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  String? get profileImageUrl => _profileImageUrl;
  String? get userId => _userId;

  String get name => _userName ?? "Guest User";
  String get emailDisplay => _email ?? "guest@example.com";
  String get phone => _phoneNumber ?? "+254 700 000 000";
  String? get profileImagePath => _profileImageUrl;

  bool get isLoggedIn => _userId != null;

  // -------------------- SETTERS --------------------
  void setUserName(String? name) {
    _userName = name;
    notifyListeners();
  }

  void setEmail(String? email) {
    _email = email;
    notifyListeners();
  }

  void setPhoneNumber(String? phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  void setProfileImageUrl(String? url) {
    _profileImageUrl = url;
    notifyListeners();
  }

  // -------------------- AUTH METHODS --------------------
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        await initializeUser();
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('❌ Sign in failed: $e');
      rethrow;
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (user != null) {
        await initializeUser();
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('❌ Sign up failed: $e');
      rethrow;
    }
  }

  // -------------------- PROFILE MANAGEMENT --------------------
  Future<void> loadUserProfile() async {
    try {
      // 1. FIRST try to load from SharedPreferences (instant)
      final prefsData = await _sharedPrefs.getUserProfile();

      if (prefsData['userId'] != null) {
        _userId = prefsData['userId'];
        _userName = prefsData['name'];
        _email = prefsData['email'];
        _phoneNumber = prefsData['phone'];
        _profileImageUrl = prefsData['avatarUrl'];
        notifyListeners();

        if (kDebugMode) {
          print('✅ User profile loaded from SharedPreferences: $_userName');
        }
      }

      // 2. THEN try to sync with Supabase (background refresh)
      final user = _authService.getCurrentUser();
      if (user != null) {
        final response = await _authService.getUserProfile();
        if (response != null) {
          _userId = user.id;
          _userName = response['full_name'];
          _email = response['email'];
          _phoneNumber = response['phone'];
          _profileImageUrl = response['avatar_url'];
          notifyListeners();

          // Update SharedPreferences with fresh data
          await _sharedPrefs.saveUserProfile(
            name: _userName!,
            email: _email!,
            phone: _phoneNumber!,
            userId: user.id,
            avatarUrl: _profileImageUrl,
          );

          if (kDebugMode) {
            print('✅ User profile synced from Supabase: $_userName');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading user profile: $e');
      }
    }
  }

  Future<void> initializeUser() async {
    // Load immediately from SharedPreferences
    final prefsData = await _sharedPrefs.getUserProfile();
    if (prefsData['userId'] != null) {
      _userId = prefsData['userId'];
      _userName = prefsData['name'];
      _email = prefsData['email'];
      _phoneNumber = prefsData['phone'];
      _profileImageUrl = prefsData['avatarUrl'];
      notifyListeners();
    }

    // Then sync with backend
    await loadUserProfile();
  }

  // -------------------- UPDATE METHODS --------------------
  Future<void> updateName(String newName) async {
    try {
      _userName = newName;
      notifyListeners();

      await _authService.updateUserProfile(
        fullName: newName,
        phone: _phoneNumber ?? '',
        avatarUrl: _profileImageUrl,
      );

      // Update SharedPreferences
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _sharedPrefs.saveUserProfile(
          name: newName,
          email: _email!,
          phone: _phoneNumber!,
          userId: user.id,
          avatarUrl: _profileImageUrl,
        );
      }

      if (kDebugMode) print('✅ Name updated everywhere: $newName');
    } catch (e) {
      if (kDebugMode) print('❌ Name update failed: $e');
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      _email = newEmail;
      notifyListeners();

      await _authService.updateUserProfile(
        fullName: _userName ?? '',
        phone: _phoneNumber ?? '',
        avatarUrl: _profileImageUrl,
      );

      // Update SharedPreferences
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _sharedPrefs.saveUserProfile(
          name: _userName!,
          email: newEmail,
          phone: _phoneNumber!,
          userId: user.id,
          avatarUrl: _profileImageUrl,
        );
      }

      if (kDebugMode) print('✅ Email updated: $newEmail');
    } catch (e) {
      if (kDebugMode) print('❌ Email update failed: $e');
      rethrow;
    }
  }

  Future<void> updatePhone(String newPhone) async {
    try {
      _phoneNumber = newPhone;
      notifyListeners();

      await _authService.updateUserProfile(
        fullName: _userName ?? '',
        phone: newPhone,
        avatarUrl: _profileImageUrl,
      );

      // Update SharedPreferences
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _sharedPrefs.saveUserProfile(
          name: _userName!,
          email: _email!,
          phone: newPhone,
          userId: user.id,
          avatarUrl: _profileImageUrl,
        );
      }

      if (kDebugMode) print('✅ Phone updated: $newPhone');
    } catch (e) {
      if (kDebugMode) print('❌ Phone update failed: $e');
      rethrow;
    }
  }

  Future<void> updateProfileImage(String? imagePath) async {
    try {
      _profileImageUrl = imagePath;
      notifyListeners();

      await _authService.updateUserProfile(
        fullName: _userName ?? '',
        phone: _phoneNumber ?? '',
        avatarUrl: imagePath,
      );

      // Update SharedPreferences with the new image
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _sharedPrefs.saveUserProfile(
          name: _userName ?? 'User',
          email: _email ?? '',
          phone: _phoneNumber ?? '+254700000000',
          userId: user.id,
          avatarUrl: imagePath,
        );
      }

      if (kDebugMode) print('✅ Profile image updated everywhere: $imagePath');
    } catch (e) {
      if (kDebugMode) print('❌ Profile image update failed: $e');
      rethrow;
    }
  }

  // Pick and upload image
  Future<void> pickAndUpdateProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Show loading state immediately
        _profileImageUrl = null;
        notifyListeners();

        final String? imageUrl = await _authService.uploadProfileImage(image.path);

        if (imageUrl != null) {
          await updateProfileImage(imageUrl);
          if (kDebugMode) print('✅ Profile image updated: $imageUrl');
        } else {
          throw Exception('Failed to upload image');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error picking/updating image: $e');

      // Reload the original image on error
      await loadUserProfile();
      rethrow;
    }
  }

  // -------------------- AUTH LISTENER --------------------
  void startListening() {
    _authSubscription = _authService.userStream.listen((user) async {
      if (user != null) {
        await _syncUserData(user);
      } else {
        _clearUserData();
        if (kDebugMode) print('✅ User logged out, provider cleared');
      }
    });
  }

  Future<void> _syncUserData(User user) async {
    await _authService.syncUserData(user);
    await loadUserProfile();
  }

  void _clearUserData() {
    _userId = null;
    _userName = null;
    _email = null;
    _phoneNumber = null;
    _profileImageUrl = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _clearUserData();
    await _authService.signOut();
  }

  // -------------------- LOGIN / UPDATE --------------------
  void login({
    required String name,
    required String email,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    _userName = name;
    _email = email;
    _phoneNumber = phoneNumber;
    _profileImageUrl = profileImageUrl;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    if (name != null) _userName = name;
    if (email != null) _email = email;
    if (phoneNumber != null) _phoneNumber = phoneNumber;
    if (profileImageUrl != null) _profileImageUrl = profileImageUrl;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}