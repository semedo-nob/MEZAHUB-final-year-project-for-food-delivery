import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../data/menu_item.dart';
import '../model/menu_item.dart';
import '../provider/favourites_provider.dart';
import '../theme/app_colors.dart';
import '../provider/cart_provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String? _selectedCategoryId;

  void _addToCart(BuildContext context, MenuItem item) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(
      id: item.id,
      name: item.name,
      price: item.price,
      image: item.image,
      quantity: 1,
      imageUrl: '',
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        backgroundColor: AppColors.primary(context),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, MenuItem item) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    favoritesProvider.toggleFavorite(item);
  }

  List<MenuItem> _getFilteredFavorites(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final allFavorites = favoritesProvider.favorites; // Changed from favoriteItems to favorites

    if (_selectedCategoryId == null) {
      return allFavorites;
    }

    return allFavorites.where((item) => item.category == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textColor(context)),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              if (favoritesProvider.favoriteCount > 0) {
                return IconButton(
                  icon: Icon(Icons.delete_sweep, color: AppColors.textColor(context)),
                  onPressed: () {
                    _showClearFavoritesDialog(context);
                  },
                  tooltip: 'Clear all favorites',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final favoriteCount = favoritesProvider.favoriteCount;
          final filteredFavorites = _getFilteredFavorites(context);

          if (favoriteCount == 0) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Category filter for favorites
              _buildFavoritesCategoryFilter(context),

              // Results count
              if (_selectedCategoryId != null) _buildResultsCount(context, filteredFavorites.length),

              // Favorites list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFavorites.length,
                  itemBuilder: (context, index) {
                    final item = filteredFavorites[index];
                    return _buildFavoriteItemCard(context, item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesCategoryFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Category',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 4),
                // "All" option
                _buildCategoryChip(context, null, 'All', _selectedCategoryId == null),
                const SizedBox(width: 8),
                // Category options
                ...categories.map((category) {
                  return Row(
                    children: [
                      _buildCategoryChip(
                          context,
                          category.id,
                          category.name,
                          _selectedCategoryId == category.id
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                }),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String? categoryId, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary(context) : AppColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary(context) : AppColors.border(context),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isSelected ? AppColors.onPrimary(context) : AppColors.textColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '$count ${count == 1 ? 'favorite' : 'favorites'}',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFavoriteItemCard(BuildContext context, MenuItem item) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.isFavorite(item.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surface(context),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Item Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.surfaceVariant(context),
                        child: Icon(Icons.fastfood, color: AppColors.textSecondary(context)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.surfaceVariant(context),
                        child: Icon(Icons.fastfood, color: AppColors.primary(context)),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Item Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.primary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Add to cart + remove
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCart(context, item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
                            foregroundColor: AppColors.onPrimary(context),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                          label: Text(
                            'Add',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      IconButton(
                        onPressed: () {
                          if (isFavorite) _toggleFavorite(context, item);
                        },
                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                        tooltip: 'Remove from favorites',
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.textSecondary(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any menu item\nto add it to your favorites',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.onPrimary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Browse Menu',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearFavoritesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          title: Text(
            'Clear All Favorites?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textColor(context),
            ),
          ),
          content: Text(
            'This will remove all items from your favorites list.',
            style: GoogleFonts.poppins(
              color: AppColors.textColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
                favoritesProvider.clearFavorites();
                Navigator.of(context).pop();
              },
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(
                  color: AppColors.primary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}