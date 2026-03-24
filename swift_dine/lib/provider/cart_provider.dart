import 'package:flutter/foundation.dart';
import '../model/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  int? _restaurantId;
  String? _restaurantName;

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  int? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;

  // For HomePage compatibility - returns List<Map<String, dynamic>>
  List<Map<String, dynamic>> get itemsAsMap => _items.map((item) => item.toJson()).toList();

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice); // Changed from totalPrice to match HomePage

  bool get isCartEmpty => _items.isEmpty;

  /// Set restaurant for backend checkout (when adding from restaurant detail).
  void setRestaurant({required int restaurantId, required String restaurantName}) {
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;
    notifyListeners();
  }

  // Updated addItem method to match HomePage usage
  void addItem({
    required String id,
    required String name,
    required double price,
    required String image, // Changed to match HomePage parameter
    int quantity = 1,
    String? notes,
    List<String>? customizations,
    required String imageUrl, // Keep for backward compatibility but mark as required
    int? restaurantId,
    String? restaurantName,
  }) {
    if (_items.isEmpty && restaurantId != null) {
      _restaurantId = restaurantId;
      _restaurantName = restaurantName ?? 'Restaurant';
    }
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      // Item exists, update quantity
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      // Add new item - use 'image' parameter for the image field
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        quantity: quantity,
        image: image, // Use the 'image' parameter
        notes: notes,
        customizations: customizations,
      ));
    }
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String id, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(id);
      return;
    }

    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
      notifyListeners();
    }
  }

  // Increase quantity by 1
  void increaseQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  // Decrease quantity by 1
  void decreaseQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity - 1,
        );
      } else {
        removeItem(id);
      }
      notifyListeners();
    }
  }

  // Update item notes
  void updateNotes(String id, String notes) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(notes: notes);
      notifyListeners();
    }
  }

  // Add customization
  void addCustomization(String id, String customization) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final currentCustomizations = _items[index].customizations ?? [];
      _items[index] = _items[index].copyWith(
        customizations: [...currentCustomizations, customization],
      );
      notifyListeners();
    }
  }

  // Clear entire cart
  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }

  // Check if item is in cart
  bool isItemInCart(String id) {
    return _items.any((item) => item.id == id);
  }

  // Get item quantity
  int getItemQuantity(String id) {
    try {
      final item = _items.firstWhere((item) => item.id == id);
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  // Calculate tax
  double calculateTax(double taxRate) {
    return totalAmount * (taxRate / 100);
  }

  // Calculate total with tax
  double get totalWithTax {
    return totalAmount + calculateTax(8); // 8% tax
  }

  // Helper method to get cart items as Map for HomePage compatibility
  Map<String, dynamic> getItemAsMap(String id) {
    try {
      final item = _items.firstWhere((item) => item.id == id);
      return item.toJson();
    } catch (e) {
      return {};
    }
  }
}