import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://igmphgapgviazyalnzuq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlnbXBoZ2FwZ3ZpYXp5YWxuenVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NDUzMjgsImV4cCI6MjA3NjUyMTMyOH0.mF5EGjZEg8pDo-4wfFbw94yStPid9IYhQXvg4DhKzpk';

  final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Auth methods that sync with Firebase
  Future<void> syncUserWithSupabase(String uid, String email, String? name) async {
    try {
      await client.from('users').upsert({
        'id': uid,
        'email': email,
        'full_name': name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error syncing user with Supabase: $e');
    }
  }

  // Order methods
  Future<void> syncOrderToSupabase(Map<String, dynamic> orderData) async {
    try {
      await client.from('orders').upsert(orderData);
    } catch (e) {
      print('Error syncing order to Supabase: $e');
    }
  }

  // CORRECTED: Real-time subscriptions with updated syntax
  Stream<Map<String, dynamic>> getOrderUpdates(String userId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((snapshot) {
      // Convert List to single events or handle as needed
      if (snapshot.isNotEmpty) {
        return snapshot.first;
      }
      return {};
    });
  }

  // Alternative: Subscribe to specific order changes
  Stream<Map<String, dynamic>> subscribeToOrder(String orderId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((snapshot) => snapshot.isNotEmpty ? snapshot.first : {});
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching user orders: $e');
      return [];
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await client
          .from('orders')
          .update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
    }
  }
}