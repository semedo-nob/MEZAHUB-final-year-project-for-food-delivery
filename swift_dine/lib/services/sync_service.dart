/// Sync service (no-op). User and orders are managed by backend API + SharedPrefs.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Future<void> initializeSync() async {
    // No-op: auth and orders use backend API
  }

  Future<void> syncOrder(Map<String, dynamic> orderData) async {
    // Orders are created via BackendOrderService
  }

  void subscribeToOrderUpdates(String userId) {
    // Order updates: pull on Orders screen load or use Socket.IO later
  }
}
