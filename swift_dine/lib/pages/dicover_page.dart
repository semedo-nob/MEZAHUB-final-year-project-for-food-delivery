import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../model/restaurant.dart';
import '../provider/favourites_provider.dart';
import '../services/backend_api.dart';
import '../theme/app_colors.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverCategoryChip {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  const _DiscoverCategoryChip({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  static const List<_DiscoverCategoryChip> _categoryChips = [
    _DiscoverCategoryChip(
      id: 'all',
      name: 'All',
      icon: Icons.explore,
      color: Color(0xFF6366F1),
    ),
    _DiscoverCategoryChip(
      id: 'pizza',
      name: 'Pizza',
      icon: Icons.local_pizza,
      color: Color(0xFFF97316),
    ),
    _DiscoverCategoryChip(
      id: 'burger',
      name: 'Burger',
      icon: Icons.lunch_dining,
      color: Color(0xFFEF4444),
    ),
    _DiscoverCategoryChip(
      id: 'sushi',
      name: 'Sushi',
      icon: Icons.set_meal,
      color: Color(0xFF10B981),
    ),
    _DiscoverCategoryChip(
      id: 'drinks',
      name: 'Drinks',
      icon: Icons.local_cafe,
      color: Color(0xFF8B5CF6),
    ),
    _DiscoverCategoryChip(
      id: 'desserts',
      name: 'Desserts',
      icon: Icons.cake,
      color: Color(0xFFEC4899),
    ),
  ];

  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  String? _selectedCategoryId = 'all';
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _filterRestaurants();
    });
  }

  Future<void> _loadRestaurants() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await BackendApi.getRestaurants();
      if (!mounted) return;
      final list = data
          .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      setState(() {
        _restaurants = list;
        _filteredRestaurants = list;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterRestaurants() {
    if (!mounted) return;
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredRestaurants = _restaurants.where((r) {
        final matchesQuery = query.isEmpty ||
            r.name.toLowerCase().contains(query) ||
            (r.cuisineType?.toLowerCase().contains(query) ?? false);

        final matchesCategory = _selectedCategoryId == 'all' ||
            (r.cuisineType?.toLowerCase().contains(
              _categoryChips
                  .firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => _categoryChips.first,
                  )
                  .name
                  .toLowerCase(),
            ) ?? false);

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String id) {
    setState(() => _selectedCategoryId = id);
    _filterRestaurants();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary(context);
    final surfaceColor = AppColors.surface(context);
    final textColor = AppColors.textColor(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ✅ Modern Minimal Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find your next favorite meal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border(context).withOpacity(0.1),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        // TODO: Open filters
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Search Bar - More Compact
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border(context).withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search restaurants...',
                    hintStyle: GoogleFonts.poppins(
                      color: secondaryTextColor.withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: secondaryTextColor,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterRestaurants();
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ✅ Category Chips - Redesigned with better visuals
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categoryChips.length,
                itemBuilder: (context, index) {
                  final chip = _categoryChips[index];
                  final isSelected = _selectedCategoryId == chip.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(chip.name),
                      avatar: isSelected
                          ? Icon(chip.icon, size: 16, color: Colors.white)
                          : Icon(chip.icon,
                          size: 16, color: chip.color.withOpacity(0.8)),
                      showCheckmark: false,
                      backgroundColor: surfaceColor,
                      selectedColor: chip.color,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : textColor,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.border(context).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      onSelected: (_) => _selectCategory(chip.id),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ✅ Results Count (if not loading and no error)
          if (!_isLoading && _error == null && _filteredRestaurants.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${_filteredRestaurants.length} restaurants found',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ✅ Restaurant Grid
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2,
              ),
            ),
          )
              : _error != null
              ? _buildErrorState(primaryColor, textColor, secondaryTextColor)
              : _filteredRestaurants.isEmpty
              ? _buildEmptyState(secondaryTextColor, textColor)
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final restaurant = _filteredRestaurants[index];
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        (index / _filteredRestaurants.length) * 0.5,
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: _buildRestaurantCard(restaurant),
                  );
                },
                childCount: _filteredRestaurants.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor, Color textColor, Color secondaryTextColor) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRestaurants,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor, Color textColor) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: secondaryTextColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No restaurants found',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppColors.surface(context);
    final textColor = AppColors.textColor(context);
    final secondaryTextColor = AppColors.textSecondary(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavoriteRestaurant(restaurant.id);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/restaurant', arguments: restaurant);
      },
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border(context).withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Image Section - More Compact
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Image.network(
                      restaurant.imageUrl ??
                          'https://via.placeholder.com/300x200?text=Restaurant',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant(context),
                        child: Icon(
                          Icons.restaurant,
                          size: 32,
                          color: AppColors.primary(context).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                // ✅ Favorite Button - Smaller
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (isFavorite) {
                        favoritesProvider.removeFavoriteRestaurant(restaurant.id);
                      } else {
                        favoritesProvider.addFavoriteRestaurant(restaurant.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.error : secondaryTextColor,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                // ✅ Delivery Time Chip - Smaller
                if (restaurant.deliveryTime != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.deliveryTime} min',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // ✅ Restaurant Info - More Compact
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 10,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                restaurant.rating!.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // ✅ Cuisine Type
                  Text(
                    restaurant.cuisineType ?? 'Various',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ✅ Delivery Fee
                  Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 11,
                        color: AppColors.primary(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.deliveryFee != null
                              ? 'KSh ${restaurant.deliveryFee!.toStringAsFixed(0)} delivery'
                              : 'Free delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}