import 'package:swift_dine/model/order.dart';
import 'package:swift_dine/services/firebase_notification_service.dart';

class OrderNotificationManager {
  // Subscribe to order updates when tracking starts
  static Future<void> startOrderTracking(Order order) async {
    try {
      await FirebaseNotificationService.subscribeToOrder(order.id);
      print('🔔 Started tracking notifications for order: ${order.id}');
    } catch (e) {
      print('❌ Error starting order tracking: $e');
    }
  }

  // Unsubscribe when order is delivered or cancelled
  static Future<void> stopOrderTracking(Order order) async {
    try {
      await FirebaseNotificationService.unsubscribeFromOrder(order.id);
      print('🔕 Stopped tracking notifications for order: ${order.id}');
    } catch (e) {
      print('❌ Error stopping order tracking: $e');
    }
  }

  // Handle order status changes with proper error handling
  static Future<void> handleStatusChange({
    required String orderId,
    required OrderStatus oldStatus,
    required OrderStatus newStatus,
    required String restaurant,
    String? driverName,
    int? estimatedMinutes,
  }) async {
    print('🔄 Order status changed: $orderId from $oldStatus to $newStatus');

    try {
      // Start/stop tracking based on status
      if (_shouldTrackOrder(newStatus)) {
        final tempOrder = Order(
          id: orderId,
          userId: '',
          items: [],
          totalAmount: 0,
          createdAt: DateTime.now(),
          status: newStatus,
          restaurant: restaurant,
          deliveryAddress: DeliveryAddress(
            fullName: '',
            phone: '',
            address: '',
            city: '',
            lat: 0,
            lng: 0,
          ),
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.completed,
        );
        await startOrderTracking(tempOrder);
      } else if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
        final tempOrder = Order(
          id: orderId,
          userId: '',
          items: [],
          totalAmount: 0,
          createdAt: DateTime.now(),
          status: newStatus,
          restaurant: restaurant,
          deliveryAddress: DeliveryAddress(
            fullName: '',
            phone: '',
            address: '',
            city: '',
            lat: 0,
            lng: 0,
          ),
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.completed,
        );
        await stopOrderTracking(tempOrder);
      }
    } catch (e) {
      print('❌ Error handling status change: $e');
    }
  }

  static bool _shouldTrackOrder(OrderStatus status) {
    return status == OrderStatus.onTheWay ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready ||
        status == OrderStatus.confirmed;
  }
}