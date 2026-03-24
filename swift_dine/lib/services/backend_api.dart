import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swift_dine/config/api_config.dart';
import 'package:swift_dine/utils/shared_prefs_manager.dart';

/// HTTP client for the MEZAHUB Flask backend.
class BackendApi {
  /// Set in main.dart from [kBackendBaseUrl] or override for physical device (your machine IP).
  static String baseUrl = kBackendBaseUrl;

  static String get _baseUrl => baseUrl;

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final token = auth ? await SharedPrefsManager().getAccessToken() : null;

    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: mergedHeaders);
      case 'POST':
        return http.post(uri, headers: mergedHeaders, body: body);
      case 'PATCH':
        return http.patch(uri, headers: mergedHeaders, body: body);
      case 'PUT':
        return http.put(uri, headers: mergedHeaders, body: body);
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }
  }

  // ---------- AUTH ----------

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _request(
      'POST',
      '/auth/login',
      auth: false,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw Exception('Login failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await SharedPrefsManager().saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final res = await _request(
      'POST',
      '/auth/register',
      auth: false,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Register failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await SharedPrefsManager().saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return data;
  }

  /// Get current user profile (requires JWT).
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _request('GET', '/auth/profile');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch profile: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Update profile (name, phone). Optional avatar_url if backend supports it.
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (profileImage != null) body['profile_image'] = profileImage;
    final res = await _request('PUT', '/auth/profile', body: jsonEncode(body));
    if (res.statusCode != 200) {
      throw Exception('Failed to update profile: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------- RESTAURANTS ----------

  static Future<List<dynamic>> getRestaurants() async {
    final res = await _request('GET', '/restaurants', auth: false);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch restaurants: ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  // ---------- ORDERS ----------

  /// List orders for the current user (customer: own orders; uses JWT).
  static Future<List<dynamic>> getOrders({int page = 1, int perPage = 50}) async {
    final res = await _request('GET', '/orders?page=$page&per_page=$perPage');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch orders: ${res.body}');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// Create order. [items] must be non-empty list of {menu_item_id, quantity}.
  /// Contact and location: [contactName], [contactPhone], full [deliveryAddress] string,
  /// [latitude], [longitude], [specialInstructions] are all sent and stored on the backend.
  /// Set [useAuth] to false for guest checkout so no (possibly expired) token is sent.
  static Future<Map<String, dynamic>> createOrder({
    required int restaurantId,
    required String deliveryAddress,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'cash',
    String? contactName,
    String? contactPhone,
    double? latitude,
    double? longitude,
    String? specialInstructions,
    bool useAuth = true,
  }) async {
    if (items.isEmpty) throw ArgumentError('items must not be empty');
    final body = <String, dynamic>{
      'restaurant_id': restaurantId,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'items': items,
    };
    if (contactName != null && contactName.isNotEmpty) body['guest_name'] = contactName;
    if (contactPhone != null && contactPhone.isNotEmpty) body['guest_phone'] = contactPhone;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (specialInstructions != null && specialInstructions.isNotEmpty) body['special_instructions'] = specialInstructions;
    final res = await _request(
      'POST',
      '/orders',
      body: jsonEncode(body),
      auth: useAuth,
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create order: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final res = await _request('GET', '/orders/$orderId/track');
    if (res.statusCode != 200) {
      throw Exception('Failed to track order: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------- RESTAURANT MENU ----------

  /// Get restaurant menu (categories and items). Public, no auth required.
  static Future<Map<String, dynamic>> getRestaurantMenu(int restaurantId) async {
    final res = await _request('GET', '/restaurants/$restaurantId/menu', auth: false);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch menu: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

