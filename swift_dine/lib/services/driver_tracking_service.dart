import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DriverTrackingService {
  static final DriverTrackingService _instance = DriverTrackingService._internal();
  factory DriverTrackingService() => _instance;
  DriverTrackingService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  String? _currentOrderId;
  String? _currentDriverId;

  // Start tracking with Geolocator
  Future<void> startTracking({
    required String orderId,
    required String driverId,
  }) async {
    _currentOrderId = orderId;
    _currentDriverId = driverId;

    // Check and request location permissions
    await _checkLocationPermissions();

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
          (Position position) {
        _sendLocationUpdate(position);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );

    _isTracking = true;
    print('Driver tracking started for order: $orderId');
  }

  // Check and request location permissions
  Future<void> _checkLocationPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
    }
  }

  // Stop tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _currentOrderId = null;
    _currentDriverId = null;
    print('Driver tracking stopped');
  }

  // Send location update to Firebase
  void _sendLocationUpdate(Position position) {
    if (_currentOrderId != null && _currentDriverId != null) {
      _updateDriverLocationInFirebase(
        orderId: _currentOrderId!,
        driverId: _currentDriverId!,
        lat: position.latitude,
        lng: position.longitude,
      );
    }
  }

  // Update driver location in Firebase
  Future<void> _updateDriverLocationInFirebase({
    required String orderId,
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _database.child('order_tracking').child(orderId).update({
        'driver_location': {
          'lat': lat,
          'lng': lng,
          'timestamp': DateTime.now().toIso8601String(),
          'driver_id': driverId,
        },
        'last_updated': DateTime.now().toIso8601String(),
      });
      print('Driver location updated: $lat, $lng');
    } catch (e) {
      print('Error updating driver location: $e');
    }
  }

  // Update order status in Firebase
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await _database.child('orders').child(orderId).update({
        'status': status,
        'status_updated_at': DateTime.now().toIso8601String(),
      });
      print('Order status updated to: $status');
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // Assign driver to order in Firebase
  Future<void> assignDriverToOrder({
    required String orderId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String vehicleType,
    required String vehiclePlate,
  }) async {
    try {
      await _database.child('orders').child(orderId).update({
        'assigned_driver': {
          'driver_id': driverId,
          'driver_name': driverName,
          'driver_phone': driverPhone,
          'vehicle_type': vehicleType,
          'vehicle_plate': vehiclePlate,
          'assigned_at': DateTime.now().toIso8601String(),
        },
        'status': 'assigned',
      });
      print('Driver assigned to order: $orderId');
    } catch (e) {
      print('Error assigning driver: $e');
    }
  }

  // Get current driver position
  Future<Position?> getCurrentDriverPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Check if tracking is active
  bool get isTracking => _isTracking;

  // Get current order ID
  String? get currentOrderId => _currentOrderId;

  // Get current driver ID
  String? get currentDriverId => _currentDriverId;

  // Dispose resources
  void dispose() {
    _positionStream?.cancel();
  }
}