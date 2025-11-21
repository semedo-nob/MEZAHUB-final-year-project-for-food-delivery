import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:swift_dine/model/order.dart';

class FirebaseTrackingService {
  static final FirebaseTrackingService _instance = FirebaseTrackingService._internal();
  factory FirebaseTrackingService() => _instance;
  FirebaseTrackingService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  DatabaseReference? _locationSubscription;

  // Stream for listening to driver location updates
  Stream<LocationData> getDriverLocationStream(String orderId) {
    return _database
        .child('order_tracking')
        .child(orderId)
        .child('driver_location')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return LocationData(
          lat: (data['lat'] as num).toDouble(),
          lng: (data['lng'] as num).toDouble(),
          timestamp: DateTime.parse(data['timestamp']),
        );
      }
      throw Exception('No location data available');
    });
  }

  // Stream for listening to order status updates
  Stream<OrderStatus> getOrderStatusStream(String orderId) {
    return _database
        .child('orders')
        .child(orderId)
        .child('status')
        .onValue
        .map((event) {
      final statusValue = event.snapshot.value as int?;
      return OrderStatus.values[statusValue ?? 0];
    });
  }

  // Update driver location (for driver app)
  Future<void> updateDriverLocation({
    required String orderId,
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    await _database.child('order_tracking').child(orderId).update({
      'driver_location': {
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
        'driver_id': driverId,
      },
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _database.child('orders').child(orderId).update({
      'status': status.index,
      'status_updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Get order details
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    final snapshot = await _database.child('orders').child(orderId).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // Assign driver to order
  Future<void> assignDriverToOrder({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String vehicleType,
    required String vehiclePlate,
  }) async {
    await _database.child('orders').child(orderId).update({
      'assigned_driver': {
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_type': vehicleType,
        'vehicle_plate': vehiclePlate,
        'assigned_at': DateTime.now().toIso8601String(),
      },
    });
  }

  // Update ETA
  Future<void> updateETA({
    required String orderId,
    required int etaMinutes,
  }) async {
    await _database.child('order_tracking').child(orderId).update({
      'eta_minutes': etaMinutes,
      'estimated_arrival_time': DateTime.now().add(Duration(minutes: etaMinutes)).toIso8601String(),
    });
  }

  // Get current driver location
  Future<LocationData?> getCurrentDriverLocation(String orderId) async {
    final snapshot = await _database
        .child('order_tracking')
        .child(orderId)
        .child('driver_location')
        .get();

    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return LocationData(
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        timestamp: DateTime.parse(data['timestamp']),
      );
    }
    return null;
  }

  // Start listening to order updates
  void startListeningToOrder(String orderId) {
    _locationSubscription = _database.child('order_tracking').child(orderId);
  }

  // Stop listening to order updates
  void stopListening() {
    _locationSubscription?.onValue.drain();
    _locationSubscription = null;
  }

  // Clean up when order is delivered
  Future<void> completeOrderTracking(String orderId) async {
    await _database.child('order_tracking').child(orderId).remove();
  }
}