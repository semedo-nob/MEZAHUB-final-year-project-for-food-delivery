import 'package:flutter/foundation.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  onTheWay,
  delivered,
  cancelled
}

enum PaymentMethod { stripe, mpesa, cash, mobileMoney, card }

enum PaymentStatus { pending, completed, failed, refunded }

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  OrderStatus status;
  final String restaurant;
  final DeliveryAddress deliveryAddress;
  final PaymentMethod paymentMethod;
  PaymentStatus paymentStatus;
  final String? trackingNumber;
  final LocationData? currentLocation;

  // Firebase tracking properties
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? estimatedArrivalMinutes;
  final DateTime? estimatedArrivalTime;
  final List<LocationData>? deliveryPath;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.status,
    required this.restaurant,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    this.trackingNumber,
    this.currentLocation,
    // Firebase tracking properties
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.vehicleType,
    this.vehiclePlate,
    this.estimatedArrivalMinutes,
    this.estimatedArrivalTime,
    this.deliveryPath, DateTime? updatedAt,
  });

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedAmount => 'KSh ${totalAmount.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'status': describeEnum(status),
      'restaurant': restaurant,
      'deliveryAddress': deliveryAddress.toJson(),
      'paymentMethod': describeEnum(paymentMethod),
      'paymentStatus': describeEnum(paymentStatus),
      'trackingNumber': trackingNumber,
      'currentLocation': currentLocation?.toJson(),
      // Firebase tracking properties
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhoto': driverPhoto,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'estimatedArrivalTime': estimatedArrivalTime?.toIso8601String(),
      'deliveryPath': deliveryPath?.map((loc) => loc.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      status: OrderStatus.values.firstWhere((e) => describeEnum(e) == json['status']),
      restaurant: json['restaurant'],
      deliveryAddress: DeliveryAddress.fromJson(json['deliveryAddress']),
      paymentMethod: PaymentMethod.values.firstWhere((e) => describeEnum(e) == json['paymentMethod']),
      paymentStatus: PaymentStatus.values.firstWhere((e) => describeEnum(e) == json['paymentStatus']),
      trackingNumber: json['trackingNumber'],
      currentLocation: json['currentLocation'] != null
          ? LocationData.fromJson(json['currentLocation'])
          : null,
      // Firebase tracking properties
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      driverPhoto: json['driverPhoto'],
      vehicleType: json['vehicleType'],
      vehiclePlate: json['vehiclePlate'],
      estimatedArrivalMinutes: json['estimatedArrivalMinutes']?.toDouble(),
      estimatedArrivalTime: json['estimatedArrivalTime'] != null
          ? DateTime.parse(json['estimatedArrivalTime'])
          : null,
      deliveryPath: json['deliveryPath'] != null
          ? (json['deliveryPath'] as List).map((loc) => LocationData.fromJson(loc)).toList()
          : null,
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final String imageUrl;
  final int quantity;
  final double price;
  final List<String>? customizations;

  const OrderItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    this.customizations,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'customizations': customizations,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      customizations: json['customizations'] != null
          ? List<String>.from(json['customizations'])
          : null,
    );
  }
}

class DeliveryAddress {
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String? additionalInfo;
  final double lat;
  final double lng;

  const DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    this.additionalInfo,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'additionalInfo': additionalInfo,
      'lat': lat,
      'lng': lng,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullName: json['fullName'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      additionalInfo: json['additionalInfo'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class LocationData {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const LocationData({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}