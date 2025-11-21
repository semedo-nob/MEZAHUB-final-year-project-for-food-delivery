import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swift_dine/model/order.dart';
import 'package:swift_dine/services/auth_service.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // ✅ CORRECTED: Use 'id' instead of 'uid' for Supabase User
  StreamSubscription<Order> subscribeToOrderUpdates(Function(Order) onOrderUpdate) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id) // ✅ FIXED: user.id instead of user.uid
        .asyncMap((snapshot) {
      if (snapshot.isNotEmpty) {
        final orderData = snapshot.first;
        return _mapToOrder(orderData);
      }
      throw Exception('No order data received');
    })
        .listen(onOrderUpdate);
  }

  // Create a new order
  Future<Order?> createOrder({
    required String restaurant,
    required List<OrderItem> items,
    required double totalAmount,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
  }) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return null;

      // ✅ FIXED: Use user.id instead of user.uid
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_${user.id}';

      // Convert OrderItem list to JSON for storage
      final itemsJson = items.map((item) => item.toJson()).toList();

      final orderData = {
        'id': orderId,
        'user_id': user.id, // ✅ FIXED: user.id instead of user.uid
        'restaurant': restaurant,
        'items': itemsJson,
        'total_amount': totalAmount,
        'status': 'pending',
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      return _mapToOrder(response);
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  // Get user's orders
  Future<List<Order>> getUserOrders() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return [];

      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', user.id) // ✅ FIXED: user.id instead of user.uid
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => _mapToOrder(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return [];
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return false;

      await _supabase
          .from('orders')
          .update({
        'status': _orderStatusToString(newStatus),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .eq('user_id', user.id); // ✅ FIXED: user.id instead of user.uid

      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }

  // Get specific order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return null;

      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .eq('user_id', user.id) // ✅ FIXED: user.id instead of user.uid
          .single();

      return _mapToOrder(response);
    } catch (e) {
      print('❌ Error fetching order: $e');
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return false;

      await _supabase
          .from('orders')
          .update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .eq('user_id', user.id) // ✅ FIXED: user.id instead of user.uid
          .eq('status', 'pending'); // Only allow cancelling pending orders

      return true;
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String orderId, PaymentStatus newStatus) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return false;

      await _supabase
          .from('orders')
          .update({
        'payment_status': _paymentStatusToString(newStatus),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .eq('user_id', user.id); // ✅ FIXED: user.id instead of user.uid

      return true;
    } catch (e) {
      print('❌ Error updating payment status: $e');
      return false;
    }
  }

  // Helper method to map data to Order model
  Order _mapToOrder(Map<String, dynamic> data) {
    // Convert JSON items to OrderItem objects
    final itemsJson = data['items'] as List<dynamic>;
    final orderItems = itemsJson.map((itemJson) {
      return OrderItem.fromJson(itemJson as Map<String, dynamic>);
    }).toList();

    // Extract delivery address data
    final deliveryAddressJson = data['delivery_address'] as Map<String, dynamic>;

    return Order(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      items: orderItems,
      totalAmount: (data['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(data['created_at'] as String),
      status: _stringToOrderStatus(data['status'] as String),
      restaurant: data['restaurant'] as String,
      deliveryAddress: DeliveryAddress(
        fullName: deliveryAddressJson['full_name'] as String? ?? '',
        phone: deliveryAddressJson['phone'] as String? ?? '',
        address: deliveryAddressJson['address'] as String? ?? '',
        city: deliveryAddressJson['city'] as String? ?? '',
        additionalInfo: deliveryAddressJson['additional_info'] as String?,
        lat: (deliveryAddressJson['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (deliveryAddressJson['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      paymentMethod: _stringToPaymentMethod(data['payment_method'] as String),
      paymentStatus: _stringToPaymentStatus(data['payment_status'] as String),
      // Optional fields with null safety
      trackingNumber: data['tracking_number'] as String?,
      driverName: data['driver_name'] as String?,
      driverPhone: data['driver_phone'] as String?,
      driverPhoto: data['driver_photo'] as String?,
      vehicleType: data['vehicle_type'] as String?,
      vehiclePlate: data['vehicle_plate'] as String?,
      estimatedArrivalMinutes: (data['estimated_arrival_minutes'] as num?)?.toDouble(),
      estimatedArrivalTime: data['estimated_arrival_time'] != null
          ? DateTime.parse(data['estimated_arrival_time'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  // Helper: Convert OrderStatus to string for database
  String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.confirmed: return 'confirmed';
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.ready: return 'ready';
      case OrderStatus.onTheWay: return 'on_the_way';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  // Helper: Convert PaymentStatus to string for database
  String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending: return 'pending';
      case PaymentStatus.completed: return 'completed';
      case PaymentStatus.failed: return 'failed';
      case PaymentStatus.refunded: return 'refunded';
    }
  }

  OrderStatus _stringToOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'confirmed': return OrderStatus.confirmed;
      case 'preparing': return OrderStatus.preparing;
      case 'ready': return OrderStatus.ready;
      case 'on_the_way': return OrderStatus.onTheWay;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  PaymentMethod _stringToPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return PaymentMethod.cash;
      case 'card': return PaymentMethod.card;
      case 'mobile_money': return PaymentMethod.mobileMoney;
      case 'stripe': return PaymentMethod.stripe;
      case 'mpesa': return PaymentMethod.mpesa;
      default: return PaymentMethod.cash;
    }
  }

  PaymentStatus _stringToPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return PaymentStatus.pending;
      case 'completed': return PaymentStatus.completed;
      case 'failed': return PaymentStatus.failed;
      case 'refunded': return PaymentStatus.refunded;
      default: return PaymentStatus.pending;
    }
  }

  // Clean up subscriptions
  void disposeSubscription(StreamSubscription<Order> subscription) {
    subscription.cancel();
  }
}