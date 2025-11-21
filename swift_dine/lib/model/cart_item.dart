import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image; // Changed back to 'image' for HomePage compatibility
  final String? notes;
  final List<String>? customizations;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image, // Changed back to 'image'
    this.notes,
    this.customizations,
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? image,
    String? notes,
    List<String>? customizations,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      notes: notes ?? this.notes,
      customizations: customizations ?? this.customizations,
    );
  }

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image, // Updated to match property name
      'notes': notes,
      'customizations': customizations,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      image: json['image'] ?? json['imageUrl'], // Handle both names for compatibility
      notes: json['notes'],
      customizations: json['customizations'] != null
          ? List<String>.from(json['customizations'])
          : null,
    );
  }
}