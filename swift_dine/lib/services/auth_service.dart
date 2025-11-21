import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:swift_dine/utils/shared_prefs_manager.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  Database? _database;

  // -------------------- DATABASE --------------------
  Future<void> _initDatabase() async {
    if (_database != null) return;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'swift_dine.db'),
      onCreate: (db, version) => db.execute(
        'CREATE TABLE user_profile(id TEXT PRIMARY KEY, email TEXT, full_name TEXT, phone TEXT, avatar_url TEXT, created_at TEXT, updated_at TEXT)',
      ),
      version: 1,
    );
  }

  // -------------------- AUTH --------------------
  // Email & Password Sign Up - UPDATED
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        await _saveUserToLocal(response.user!, fullName: fullName);
        await _createUserProfileInSupabase(response.user!, fullName: fullName);

        // ✅ NEW: Save to SharedPreferences for instant access
        await SharedPrefsManager().saveUserProfile(
          name: fullName,
          email: email,
          phone: '+254700000000',
          userId: response.user!.id,
          avatarUrl: null,
        );

        print('✅ User registered and saved to all storage layers');
      }

      return response.user;
    } catch (e) {
      print('❌ Supabase Sign up error: $e');
      rethrow;
    }
  }

// Update syncUserData method
  Future<void> syncUserData(User user) async {
    try {
      await _initDatabase();
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final userData = response != null
          ? Map<String, dynamic>.from(response)
          : {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? 'New User',
        'phone': user.phone ?? '+254700000000',
        'avatar_url': user.userMetadata?['avatar_url'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').upsert(userData);
      await _database!.insert(
        'user_profile',
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // ✅ NEW: Also save to SharedPreferences
      await SharedPrefsManager().saveUserProfile(
        name: userData['full_name'],
        email: userData['email'],
        phone: userData['phone'],
        userId: user.id,
        avatarUrl: userData['avatar_url'],
      );

      print('✅ User data synced to all storage layers: ${user.id}');
    } catch (e) {
      print('❌ Error syncing user data: $e');
      await _saveUserToLocal(user);
    }
  }

// Update signOut method
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearLocalUserData();
      // ✅ NEW: Clear SharedPreferences
      await SharedPrefsManager().clearUserProfile();
      print('✅ User signed out and all data cleared');
    } catch (e) {
      print('❌ Sign out failed: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) await syncUserData(response.user!);
      return response.user;
    } catch (e) {
      print('❌ Sign-in error: $e');
      rethrow;
    }
  }

  // -------------------- PROFILE --------------------
  Future<void> _createUserProfileInSupabase(User user, {String? fullName}) async {
    try {
      final userData = {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': fullName ?? 'New User',
        'phone': user.phone ?? '+254700000000',
        'avatar_url': user.userMetadata?['avatar_url'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from('users').upsert(userData);
      print('✅ User profile created in Supabase: ${user.id}');
    } catch (e) {
      print('❌ Error creating Supabase profile: $e');
    }
  }

  Future<void> _saveUserToLocal(User user, {String? fullName}) async {
    await _initDatabase();
    final userData = {
      'id': user.id,
      'email': user.email ?? '',
      'full_name': fullName ?? 'New User',
      'phone': user.phone ?? '+254700000000',
      'avatar_url': user.userMetadata?['avatar_url'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _database!.insert(
      'user_profile',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ User saved locally: ${user.id}');
  }



  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      await _initDatabase();
      final user = getCurrentUser();
      if (user == null) return null;
      final result = await _database!.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('❌ Local profile fetch error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('Not authenticated');
      final updateData = {
        'id': user.id,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from('users').upsert(updateData);
      await _initDatabase();
      await _database!.update(
        'user_profile',
        updateData,
        where: 'id = ?',
        whereArgs: [user.id],
      );
      print('✅ Profile updated (Supabase + Local)');
    } catch (e) {
      print('❌ Profile update failed: $e');
      rethrow;
    }
  }

  // -------------------- IMAGE UPLOAD --------------------
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(imagePath);

      // ✅ FIX: Properly await the upload and handle the response
      await _supabase.storage
          .from('profile-images')
          .upload(fileName, file, fileOptions: const FileOptions(
          upsert: true, // Allow overwriting existing files
          contentType: 'image/jpeg'
      ));

      // ✅ FIX: Get the public URL correctly
      final imageUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      print('✅ Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('❌ Image upload failed: $e');

      // ✅ FIX: More detailed error logging
      if (e is StorageException) {
        print('Storage error: ${e.message}');
      } else if (e is AuthException) {
        print('Auth error: ${e.message}');
      }

      return null;
    }
  }

  // -------------------- AUTH STATE --------------------
  Stream<User?> get userStream =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  User? getCurrentUser() => _supabase.auth.currentUser;



  Future<void> _clearLocalUserData() async {
    await _initDatabase();
    await _database!.delete('user_profile');
    print('✅ Local data cleared');
  }

  Future<void> close() async => _database?.close();
}
