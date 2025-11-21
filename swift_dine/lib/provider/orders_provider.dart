import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/order.dart';
import '../services/order_notification_manager.dart';

class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;

  List<Order> get orders => _orders;
  bool get loading => _loading;

  Future<void> loadOrders() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getStringList('user_orders') ?? [];

      _orders = ordersJson.map((json) => Order.fromJson(jsonDecode(json))).toList();
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Initialize notification tracking for active orders
      await _initializeOrderTracking();

      if (kDebugMode) {
        print('Loaded ${_orders.length} orders from storage');
        print('Active trackable orders: ${getActiveDeliveries().length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeOrderTracking() async {
    int trackingCount = 0;
    for (final order in _orders) {
      if (_shouldTrackOrder(order.status)) {
        await OrderNotificationManager.startOrderTracking(order);
        trackingCount++;
        if (kDebugMode) {
          print('Started tracking notifications for order: ${order.id}');
        }
      }
    }
    if (kDebugMode && trackingCount > 0) {
      print('Initialized tracking for $trackingCount orders');
    }
  }

  bool _shouldTrackOrder(OrderStatus status) {
    return status == OrderStatus.onTheWay ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready;
  }

  Future<void> addOrder(Order order) async {
    _orders.insert(0, order);
    await _saveOrders();

    // Start tracking notifications for new order if applicable
    if (_shouldTrackOrder(order.status)) {
      await OrderNotificationManager.startOrderTracking(order);
      if (kDebugMode) {
        print('Started tracking new order: ${order.id}');
      }
    }

    // Send initial order confirmation notification
    await OrderNotificationManager.handleStatusChange(
      orderId: order.id,
      oldStatus: OrderStatus.pending,
      newStatus: order.status,
      restaurant: order.restaurant,
      driverName: order.driverName,
      estimatedMinutes: order.estimatedArrivalMinutes?.toInt(),
    );

    if (kDebugMode) {
      print('Order added with notification: ${order.id}');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      final oldStatus = oldOrder.status;

      final updatedOrder = Order(
        id: oldOrder.id,
        userId: oldOrder.userId,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        createdAt: oldOrder.createdAt,
        status: newStatus,
        restaurant: oldOrder.restaurant,
        deliveryAddress: oldOrder.deliveryAddress,
        paymentMethod: oldOrder.paymentMethod,
        paymentStatus: oldOrder.paymentStatus,
        trackingNumber: oldOrder.trackingNumber,
        currentLocation: oldOrder.currentLocation,
        driverName: oldOrder.driverName,
        driverPhone: oldOrder.driverPhone,
        driverPhoto: oldOrder.driverPhoto,
        vehicleType: oldOrder.vehicleType,
        vehiclePlate: oldOrder.vehiclePlate,
        estimatedArrivalMinutes: oldOrder.estimatedArrivalMinutes,
        estimatedArrivalTime: oldOrder.estimatedArrivalTime,
        deliveryPath: oldOrder.deliveryPath,
      );

      _orders[index] = updatedOrder;
      await _saveOrders();

      // Handle notification tracking based on status change
      await _handleStatusChangeTracking(orderId, oldStatus, newStatus, updatedOrder);

      if (kDebugMode) {
        print('Order status updated: $orderId from $oldStatus to $newStatus');
      }
    }
  }

  // Enhanced method with notification support
  Future<void> updateOrderStatusWithNotification({
    required String orderId,
    required OrderStatus newStatus,
    String? driverName,
    int? estimatedMinutes,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      final oldStatus = oldOrder.status;

      // Send notification for status change
      await OrderNotificationManager.handleStatusChange(
        orderId: orderId,
        oldStatus: oldStatus,
        newStatus: newStatus,
        restaurant: oldOrder.restaurant,
        driverName: driverName ?? oldOrder.driverName,
        estimatedMinutes: estimatedMinutes ?? oldOrder.estimatedArrivalMinutes?.toInt(),
      );

      final updatedOrder = Order(
        id: oldOrder.id,
        userId: oldOrder.userId,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        createdAt: oldOrder.createdAt,
        status: newStatus,
        restaurant: oldOrder.restaurant,
        deliveryAddress: oldOrder.deliveryAddress,
        paymentMethod: oldOrder.paymentMethod,
        paymentStatus: oldOrder.paymentStatus,
        trackingNumber: oldOrder.trackingNumber,
        currentLocation: oldOrder.currentLocation,
        driverName: driverName ?? oldOrder.driverName,
        driverPhone: oldOrder.driverPhone,
        driverPhoto: oldOrder.driverPhoto,
        vehicleType: oldOrder.vehicleType,
        vehiclePlate: oldOrder.vehiclePlate,
        estimatedArrivalMinutes: estimatedMinutes?.toDouble() ?? oldOrder.estimatedArrivalMinutes,
        estimatedArrivalTime: oldOrder.estimatedArrivalTime,
        deliveryPath: oldOrder.deliveryPath,
      );

      _orders[index] = updatedOrder;
      await _saveOrders();

      // Handle notification tracking
      await _handleStatusChangeTracking(orderId, oldStatus, newStatus, updatedOrder);

      if (kDebugMode) {
        print('Order status updated with notification: $orderId -> $newStatus');
      }
    }
  }

  Future<void> _handleStatusChangeTracking(
      String orderId,
      OrderStatus oldStatus,
      OrderStatus newStatus,
      Order order
      ) async {
    // Start tracking if order becomes trackable
    if (!_shouldTrackOrder(oldStatus) && _shouldTrackOrder(newStatus)) {
      await OrderNotificationManager.startOrderTracking(order);
      if (kDebugMode) {
        print('Started tracking for order: $orderId');
      }
    }
    // Stop tracking if order is completed
    else if (_shouldTrackOrder(oldStatus) &&
        (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled)) {
      await OrderNotificationManager.stopOrderTracking(order);
      if (kDebugMode) {
        print('Stopped tracking for order: $orderId');
      }
    }
  }

  Future<void> updateOrderLocation(String orderId, LocationData location) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];

      final updatedOrder = Order(
        id: oldOrder.id,
        userId: oldOrder.userId,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        createdAt: oldOrder.createdAt,
        status: oldOrder.status,
        restaurant: oldOrder.restaurant,
        deliveryAddress: oldOrder.deliveryAddress,
        paymentMethod: oldOrder.paymentMethod,
        paymentStatus: oldOrder.paymentStatus,
        trackingNumber: oldOrder.trackingNumber,
        currentLocation: location,
        driverName: oldOrder.driverName,
        driverPhone: oldOrder.driverPhone,
        driverPhoto: oldOrder.driverPhoto,
        vehicleType: oldOrder.vehicleType,
        vehiclePlate: oldOrder.vehiclePlate,
        estimatedArrivalMinutes: oldOrder.estimatedArrivalMinutes,
        estimatedArrivalTime: oldOrder.estimatedArrivalTime,
        deliveryPath: oldOrder.deliveryPath,
      );

      _orders[index] = updatedOrder;
      await _saveOrders();

      // Send location update notification if order is being tracked
      if (_shouldTrackOrder(oldOrder.status) && oldOrder.driverName != null) {
        // Calculate ETA based on new location
        final remainingMinutes = _calculateRemainingTime(location, oldOrder.deliveryAddress);
        if (remainingMinutes != null) {
          if (kDebugMode) {
            print('Location updated for order $orderId - ETA: ${remainingMinutes.toStringAsFixed(0)} minutes');
          }
          // In real app, you'd send this to your notification service
        }
      }

      if (kDebugMode) {
        print('Order location updated: $orderId');
      }
    }
  }

  double? _calculateRemainingTime(LocationData currentLocation, DeliveryAddress destination) {
    final distance = _calculateDistance(
      currentLocation.lat,
      currentLocation.lng,
      destination.lat,
      destination.lng,
    );

    // Assume average speed of 30 km/h = 8.33 m/s
    if (distance > 0) {
      return (distance / 8333.33 * 60); // Convert to minutes
    }
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth's radius in meters

    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  Future<void> updateOrderPaymentStatus(String orderId, PaymentStatus newPaymentStatus) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];

      final updatedOrder = Order(
        id: oldOrder.id,
        userId: oldOrder.userId,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        createdAt: oldOrder.createdAt,
        status: oldOrder.status,
        restaurant: oldOrder.restaurant,
        deliveryAddress: oldOrder.deliveryAddress,
        paymentMethod: oldOrder.paymentMethod,
        paymentStatus: newPaymentStatus,
        trackingNumber: oldOrder.trackingNumber,
        currentLocation: oldOrder.currentLocation,
        driverName: oldOrder.driverName,
        driverPhone: oldOrder.driverPhone,
        driverPhoto: oldOrder.driverPhoto,
        vehicleType: oldOrder.vehicleType,
        vehiclePlate: oldOrder.vehiclePlate,
        estimatedArrivalMinutes: oldOrder.estimatedArrivalMinutes,
        estimatedArrivalTime: oldOrder.estimatedArrivalTime,
        deliveryPath: oldOrder.deliveryPath,
      );

      _orders[index] = updatedOrder;
      await _saveOrders();

      // Send payment status notification if needed
      if (newPaymentStatus == PaymentStatus.completed) {
        if (kDebugMode) {
          print('Payment completed for order: $orderId');
        }
      } else if (newPaymentStatus == PaymentStatus.failed) {
        if (kDebugMode) {
          print('Payment failed for order: $orderId');
        }
      }
    }
  }

  // Enhanced method to update order with Firebase tracking data
  Future<void> updateOrderWithTrackingData({
    required String orderId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    String? vehicleType,
    String? vehiclePlate,
    double? estimatedArrivalMinutes,
    DateTime? estimatedArrivalTime,
    List<LocationData>? deliveryPath,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];

      // Send delivery update notification when driver is first assigned
      final isNewDriverAssignment = driverName != null && oldOrder.driverName == null;

      final updatedOrder = Order(
        id: oldOrder.id,
        userId: oldOrder.userId,
        items: oldOrder.items,
        totalAmount: oldOrder.totalAmount,
        createdAt: oldOrder.createdAt,
        status: oldOrder.status,
        restaurant: oldOrder.restaurant,
        deliveryAddress: oldOrder.deliveryAddress,
        paymentMethod: oldOrder.paymentMethod,
        paymentStatus: oldOrder.paymentStatus,
        trackingNumber: oldOrder.trackingNumber,
        currentLocation: oldOrder.currentLocation,
        driverName: driverName ?? oldOrder.driverName,
        driverPhone: driverPhone ?? oldOrder.driverPhone,
        driverPhoto: driverPhoto ?? oldOrder.driverPhoto,
        vehicleType: vehicleType ?? oldOrder.vehicleType,
        vehiclePlate: vehiclePlate ?? oldOrder.vehiclePlate,
        estimatedArrivalMinutes: estimatedArrivalMinutes ?? oldOrder.estimatedArrivalMinutes,
        estimatedArrivalTime: estimatedArrivalTime ?? oldOrder.estimatedArrivalTime,
        deliveryPath: deliveryPath ?? oldOrder.deliveryPath,
      );

      _orders[index] = updatedOrder;
      await _saveOrders();

      // Send notification for new driver assignment
      if (isNewDriverAssignment && driverName != null) {
        await OrderNotificationManager.handleStatusChange(
          orderId: orderId,
          oldStatus: oldOrder.status,
          newStatus: OrderStatus.onTheWay,
          restaurant: oldOrder.restaurant,
          driverName: driverName,
          estimatedMinutes: estimatedArrivalMinutes?.toInt(),
        );

        // Start tracking if not already tracking
        if (!_shouldTrackOrder(oldOrder.status)) {
          await OrderNotificationManager.startOrderTracking(updatedOrder);
        }

        if (kDebugMode) {
          print('Driver assigned to order: $orderId - $driverName');
        }
      }

      if (kDebugMode) {
        print('Order tracking data updated: $orderId');
      }
    }
  }

  // Helper method to save orders to SharedPreferences
  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = _orders.map((order) => jsonEncode(order.toJson())).toList();
      await prefs.setStringList('user_orders', ordersJson);
      notifyListeners();

      if (kDebugMode) {
        print('Orders saved to storage: ${_orders.length} orders');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving orders: $e');
      }
      rethrow;
    }
  }

  // Clear all orders
  Future<void> clearAllOrders() async {
    final List<Order> removedOrders = List.from(_orders);

    // Stop tracking all orders before clearing
    for (final order in _orders) {
      if (_shouldTrackOrder(order.status)) {
        await OrderNotificationManager.stopOrderTracking(order);
      }
    }

    _orders.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_orders');

      if (kDebugMode) {
        print('All orders cleared and tracking stopped');
      }
    } catch (e) {
      // Restore orders if saving fails
      _orders.addAll(removedOrders);
      notifyListeners();
      rethrow;
    }
  }

  // Clear completed orders (delivered and cancelled)
  Future<void> clearCompletedOrders() async {
    final List<Order> completedOrders = _orders.where((order) =>
    order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled
    ).toList();

    // Stop tracking completed orders
    for (final order in completedOrders) {
      await OrderNotificationManager.stopOrderTracking(order);
    }

    _orders.removeWhere((order) =>
    order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled
    );
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = _orders.map((order) => jsonEncode(order.toJson())).toList();
      await prefs.setStringList('user_orders', ordersJson);

      if (kDebugMode) {
        print('Completed orders cleared: ${completedOrders.length} orders');
      }
    } catch (e) {
      // Restore orders if saving fails
      _orders.addAll(completedOrders);
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      rethrow;
    }
  }

  // Clear orders by specific status
  Future<void> clearOrdersByStatus(List<OrderStatus> statuses) async {
    final List<Order> removedOrders = _orders.where((order) => statuses.contains(order.status)).toList();

    // Stop tracking orders being removed
    for (final order in removedOrders) {
      if (_shouldTrackOrder(order.status)) {
        await OrderNotificationManager.stopOrderTracking(order);
      }
    }

    _orders.removeWhere((order) => statuses.contains(order.status));
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = _orders.map((order) => jsonEncode(order.toJson())).toList();
      await prefs.setStringList('user_orders', ordersJson);

      if (kDebugMode) {
        print('Orders cleared by status: ${removedOrders.length} orders');
      }
    } catch (e) {
      // Restore orders if saving fails
      _orders.addAll(removedOrders);
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      rethrow;
    }
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Order not found: $orderId');
      }
      return null;
    }
  }

  List<Order> getActiveDeliveries() {
    return _orders.where((order) =>
    order.status == OrderStatus.onTheWay ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready
    ).toList();
  }

  // Get orders that are currently being tracked with driver info
  List<Order> getTrackedOrders() {
    return _orders.where((order) =>
    order.status == OrderStatus.onTheWay &&
        order.driverName != null &&
        order.currentLocation != null
    ).toList();
  }

  // Get order statistics
  Map<String, int> getOrderStatistics() {
    return {
      'total': _orders.length,
      'pending': getOrdersByStatus(OrderStatus.pending).length,
      'preparing': getOrdersByStatus(OrderStatus.preparing).length,
      'onTheWay': getOrdersByStatus(OrderStatus.onTheWay).length,
      'delivered': getOrdersByStatus(OrderStatus.delivered).length,
      'cancelled': getOrdersByStatus(OrderStatus.cancelled).length,
    };
  }

  // Check if order can be tracked
  bool isOrderTrackable(String orderId) {
    final order = getOrderById(orderId);
    return order != null && _shouldTrackOrder(order.status);
  }

  // Manually start tracking an order
  Future<void> startTrackingOrder(String orderId) async {
    final order = getOrderById(orderId);
    if (order != null && _shouldTrackOrder(order.status)) {
      await OrderNotificationManager.startOrderTracking(order);
      if (kDebugMode) {
        print('Manually started tracking for order: $orderId');
      }
    } else {
      if (kDebugMode) {
        print('Order $orderId cannot be tracked or not found');
      }
    }
  }

  // Manually stop tracking an order
  Future<void> stopTrackingOrder(String orderId) async {
    final order = getOrderById(orderId);
    if (order != null) {
      await OrderNotificationManager.stopOrderTracking(order);
      if (kDebugMode) {
        print('Manually stopped tracking for order: $orderId');
      }
    } else {
      if (kDebugMode) {
        print('Order $orderId not found');
      }
    }
  }

  // Get orders that need notification tracking
  List<Order> getOrdersNeedingTracking() {
    return _orders.where((order) => _shouldTrackOrder(order.status)).toList();
  }

  // Check if any orders are currently being tracked
  bool get hasActiveTrackedOrders {
    return getTrackedOrders().isNotEmpty;
  }


  // Add this method to handle real-time order updates from Supabase
  Future<void> updateOrder(Order updatedOrder) async {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);

    if (index != -1) {
      final oldOrder = _orders[index];
      final oldStatus = oldOrder.status;
      final newStatus = updatedOrder.status;

      // Update the order in the list
      _orders[index] = updatedOrder;

      // Handle notification tracking based on status change
      await _handleStatusChangeTracking(updatedOrder.id, oldStatus, newStatus, updatedOrder);

      // Save to local storage
      await _saveOrders();

      if (kDebugMode) {
        print('🔄 Order updated via provider: ${updatedOrder.id} - $oldStatus → $newStatus');
      }
    } else {
      // If order doesn't exist, add it (for real-time new orders)
      _orders.insert(0, updatedOrder);
      await _saveOrders();

      // Start tracking if applicable
      if (_shouldTrackOrder(updatedOrder.status)) {
        await OrderNotificationManager.startOrderTracking(updatedOrder);
      }

      if (kDebugMode) {
        print('🆕 New order added via provider: ${updatedOrder.id}');
      }
    }

    notifyListeners();
  }
  // Get count of trackable orders
  int get trackableOrdersCount {
    return getActiveDeliveries().length;
  }
}