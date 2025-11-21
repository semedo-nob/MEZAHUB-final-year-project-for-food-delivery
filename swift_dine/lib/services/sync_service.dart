import 'package:firebase_auth/firebase_auth.dart';
import './supabase_service.dart';
import './local_database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<void> initializeSync() async {
    await _supabaseService.initialize();
    await _syncOnAppStart();
  }

  Future<void> _syncOnAppStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Sync user profile
      await _supabaseService.syncUserWithSupabase(
        user.uid,
        user.email!,
        user.displayName,
      );

      // Sync unsynced orders
      await _syncPendingOrders(user.uid);
    }
  }

  Future<void> syncOrder(Map<String, dynamic> orderData) async {
    // Save locally first
    await _localDb.insertOrder(orderData);

    // Try to sync to Supabase
    try {
      await _supabaseService.syncOrderToSupabase(orderData);
      await _localDb.markOrderAsSynced(orderData['id']);
    } catch (e) {
      print('Failed to sync order online, stored locally: $e');
    }
  }

  Future<void> _syncPendingOrders(String userId) async {
    final unsyncedOrders = await _localDb.getUnsyncedOrders();

    for (final order in unsyncedOrders) {
      try {
        await _supabaseService.syncOrderToSupabase(order);
        await _localDb.markOrderAsSynced(order['id']);
      } catch (e) {
        print('Failed to sync order ${order['id']}: $e');
      }
    }
  }

  // Real-time updates from Supabase
  void subscribeToOrderUpdates(String userId) {
    _supabaseService.getOrderUpdates(userId);
  }
}