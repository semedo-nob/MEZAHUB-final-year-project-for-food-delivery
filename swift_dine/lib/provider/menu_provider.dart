import 'package:flutter/foundation.dart';
import '../data/menu_item.dart';
import '../model/menu_item.dart';

class MenuProvider with ChangeNotifier {
  String? _selectedCategoryId;
  String _searchQuery = '';
  List<MenuItem> _filteredItems = menuItems;

  // Getters
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  List<MenuItem> get filteredItems => _filteredItems;

  List<MenuItem> get featuredItems => menuItems.where((item) => item.featured).toList();
  List<MenuItem> get popularItems => menuItems.where((item) => !item.featured).toList();

  // Filter by category
  void filterByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  // Search
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Apply all active filters
  void _applyFilters() {
    List<MenuItem> result = menuItems;

    // Apply category filter
    if (_selectedCategoryId != null) {
      result = result.where((item) => item.category == _selectedCategoryId).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((item) =>
      item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.dietary.any((diet) => diet.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    _filteredItems = result;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _filteredItems = menuItems;
    notifyListeners();
  }

  // Get items by category
  List<MenuItem> getItemsByCategory(String categoryId) {
    return menuItems.where((item) => item.category == categoryId).toList();
  }

  // Get categories with item counts
  List<Map<String, dynamic>> getCategoriesWithCounts() {
    return categories.map((category) {
      final count = menuItems.where((item) => item.category == category.id).length;
      return {
        'category': category,
        'itemCount': count,
      };
    }).toList();
  }
}