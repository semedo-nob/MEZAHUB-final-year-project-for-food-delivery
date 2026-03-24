import 'package:flutter/foundation.dart';
import '../model/menu_item.dart';

class FavoritesProvider with ChangeNotifier {
  final List<MenuItem> _favoriteItems = [];
  final Set<String> _favoriteRestaurantIds = {};

  List<MenuItem> get favorites => _favoriteItems; // Changed from favoriteItems to match HomePage
  int get favoriteCount => _favoriteItems.length; // Added for HomePage compatibility

  bool isFavorite(String itemId) {
    return _favoriteItems.any((item) => item.id == itemId);
  }

  bool isFavoriteRestaurant(String restaurantId) => _favoriteRestaurantIds.contains(restaurantId);

  void addFavoriteRestaurant(String restaurantId) {
    if (_favoriteRestaurantIds.add(restaurantId)) notifyListeners();
  }

  void removeFavoriteRestaurant(String restaurantId) {
    if (_favoriteRestaurantIds.remove(restaurantId)) notifyListeners();
  }

  void addToFavorites(MenuItem item) {
    if (!isFavorite(item.id)) {
      _favoriteItems.add(item.copyWith(isFavourite: true));
      notifyListeners();
    }
  }

  void removeFromFavorites(String itemId) {
    _favoriteItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void toggleFavorite(MenuItem item) {
    if (isFavorite(item.id)) {
      removeFromFavorites(item.id);
    } else {
      addToFavorites(item);
    }
  }

  void clearFavorites() {
    _favoriteItems.clear();
    notifyListeners();
  }

  List<MenuItem> getFavoritesByCategory(String categoryId) {
    return _favoriteItems.where((item) => item.category == categoryId).toList();
  }
}