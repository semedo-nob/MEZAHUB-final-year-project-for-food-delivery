import 'dart:convert';

import 'package:swift_dine/model/order.dart';

import 'backend_api.dart';

/// Order service that talks to the MEZAHUB Flask backend instead of Supabase.
class BackendOrderService {
  static String? _lastOrderError;

  /// Last error message from a failed createOrder (e.g. backend error or "Unauthorized").
  static String? get lastOrderError => _lastOrderError;

  /// Fetch current user's orders from the backend.
  Future<List<Order>> getUserOrders() async {
    try {
      final list = await BackendApi.getOrders();
      return list
          .map((e) => _orderFromBackend(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Backend getOrders error: $e');
      return [];
    }
  }

  /// Create an order in the backend and map it to the local [Order] model.
  /// [items] are sent as menu_item_id + quantity; [items] order items must have id = menu item id.
  /// Set [isGuest] to true when the user is not logged in so no token is sent (avoids "token expired").
  Future<Order?> createOrder({
    required String restaurantName,
    required int restaurantId,
    required List<OrderItem> items,
    required double totalAmount,
    required DeliveryAddress deliveryAddress,
    required PaymentMethod paymentMethod,
    bool isGuest = false,
  }) async {
    if (items.isEmpty) return null;

    _lastOrderError = null;
    try {
      final backendItems = items.map((item) {
        final menuItemId = int.tryParse(item.id) ?? 0;
        return {'menu_item_id': menuItemId, 'quantity': item.quantity};
      }).toList();

      // Full delivery text: address, city, and optional notes (location accessed by app is included).
      final fullAddress = [
        deliveryAddress.address,
        deliveryAddress.city.isNotEmpty ? deliveryAddress.city : null,
        if (deliveryAddress.additionalInfo != null && deliveryAddress.additionalInfo!.isNotEmpty) 'Note: ${deliveryAddress.additionalInfo}',
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      final backendOrder = await BackendApi.createOrder(
        restaurantId: restaurantId,
        deliveryAddress: fullAddress.isNotEmpty ? fullAddress : deliveryAddress.address,
        items: backendItems,
        paymentMethod: _paymentMethodToString(paymentMethod),
        contactName: deliveryAddress.fullName,
        contactPhone: deliveryAddress.phone,
        latitude: deliveryAddress.lat != 0 ? deliveryAddress.lat : null,
        longitude: deliveryAddress.lng != 0 ? deliveryAddress.lng : null,
        specialInstructions: deliveryAddress.additionalInfo,
        useAuth: !isGuest,
      );

      return Order(
        id: backendOrder['id'].toString(),
        userId: backendOrder['customer_id']?.toString() ?? 'backend',
        items: items,
        totalAmount: (backendOrder['total_amount'] as num).toDouble(),
        createdAt: DateTime.now(),
        status: _stringToOrderStatus(backendOrder['status'] as String),
        restaurant: restaurantName,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        paymentStatus: PaymentStatus.pending,
        trackingNumber: null,
        currentLocation: null,
        driverName: null,
        driverPhone: null,
        driverPhoto: null,
        vehicleType: null,
        vehiclePlate: null,
        estimatedArrivalMinutes: null,
        estimatedArrivalTime: null,
        deliveryPath: null,
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ Backend order creation error: $e');
      _lastOrderError = _parseBackendErrorMessage(e);
      return null;
    }
  }

  /// Extract user-facing message from backend error (e.g. "Failed to create order: {...}").
  static String _parseBackendErrorMessage(Object e) {
    final s = e.toString();
    // BackendApi throws "Failed to create order: <body>"
    const prefix = 'Exception: Failed to create order: ';
    if (s.startsWith(prefix)) {
      final body = s.substring(prefix.length).trim();
      try {
        final map = jsonDecode(body) as Map<String, dynamic>;
        if (map['error'] != null) return map['error'] as String;
        if (map['message'] != null) return map['message'] as String;
        if (map['msg'] != null) return map['msg'] as String;
      } catch (_) {}
      if (body.toLowerCase().contains('unauthorized') ||
          body.contains('401') ||
          body.toLowerCase().contains('missing authorization')) {
        return 'Please log in to place an order.';
      }
      if (body.toLowerCase().contains('forbidden') || body.contains('403')) {
        return 'You do not have permission to place orders.';
      }
    }
    return 'Order failed. Check connection and try again.';
  }

  /// Map backend order JSON (snake_case) to app [Order].
  Order _orderFromBackend(Map<String, dynamic> b) {
    final itemsJson = b['items'] as List<dynamic>? ?? [];
    final orderItems = itemsJson.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final mid = m['menu_item_id'] ?? 0;
      final q = (m['quantity'] as num?)?.toInt() ?? 1;
      final price = (m['unit_price'] as num?)?.toDouble() ?? 0.0;
      return OrderItem(
        id: mid.toString(),
        name: 'Item #$mid',
        imageUrl: '',
        quantity: q,
        price: price,
      );
    }).toList();

    final deliveryAddress = DeliveryAddress(
      fullName: '',
      phone: '',
      address: b['delivery_address'] as String? ?? '',
      city: '',
      additionalInfo: null,
      lat: 0,
      lng: 0,
    );

    return Order(
      id: (b['id'] as num).toString(),
      userId: (b['customer_id'] as num).toString(),
      items: orderItems,
      totalAmount: (b['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.now(),
      status: _stringToOrderStatus(b['status'] as String? ?? 'pending'),
      restaurant: 'Restaurant #${b['restaurant_id']}',
      deliveryAddress: deliveryAddress,
      paymentMethod: _stringToPaymentMethod(b['payment_method'] as String? ?? 'cash'),
      paymentStatus: _stringToPaymentStatus(b['payment_status'] as String? ?? 'pending'),
      trackingNumber: null,
      currentLocation: null,
      driverName: null,
      driverPhone: null,
      driverPhoto: null,
      vehicleType: null,
      vehiclePlate: null,
      estimatedArrivalMinutes: null,
      estimatedArrivalTime: null,
      deliveryPath: null,
    );
  }

  PaymentMethod _stringToPaymentMethod(String s) {
    switch (s.toLowerCase()) {
      case 'mpesa':
        return PaymentMethod.mpesa;
      case 'card':
        return PaymentMethod.card;
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'stripe':
        return PaymentMethod.stripe;
      default:
        return PaymentMethod.cash;
    }
  }

  PaymentStatus _stringToPaymentStatus(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return 'stripe';
      case PaymentMethod.mpesa:
        return 'mpesa';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.card:
        return 'card';
    }
  }

  OrderStatus _stringToOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      default:
        return OrderStatus.cancelled;
    }
  }
}

