import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsManager {
  static final SharedPrefsManager _instance = SharedPrefsManager._internal();
  factory SharedPrefsManager() => _instance;
  SharedPrefsManager._internal();

  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userAvatarKey = 'user_avatar';
  static const String _userIdKey = 'user_id';

  Future<void> saveUserProfile({
    required String name,
    required String email,
    required String phone,
    required String userId,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userPhoneKey, phone);
    await prefs.setString(_userIdKey, userId);
    if (avatarUrl != null) {
      await prefs.setString(_userAvatarKey, avatarUrl);
    }
  }

  Future<Map<String, String?>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
      'phone': prefs.getString(_userPhoneKey),
      'avatarUrl': prefs.getString(_userAvatarKey),
      'userId': prefs.getString(_userIdKey),
    };
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userAvatarKey);
    await prefs.remove(_userIdKey);
  }

  Future<bool> hasUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null;
  }
}