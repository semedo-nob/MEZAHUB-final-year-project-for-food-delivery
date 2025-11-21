// lib/pages/home_page.dart
// Harmonized HomePage with 3D Perspective Carousel and custom theming
// Fixed for carousel_slider compatible version
// Fixed: Bottom navigation bar now updates on tab swipe via TabController listener
// Added: Explicit swipe gesture support with custom physics for smoother tab transitions

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../data/menu_item.dart';
import '../model/menu_item.dart';
import '../provider/favourites_provider.dart';
import '../provider/user_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/search_form_field.dart';
import '../widgets/app_drawer.dart';
import '../provider/cart_provider.dart';
import '../provider/menu_provider.dart';
import '../widgets/category_body_page.dart';
import 'notification_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // For older carousel_slider versions, use PageController instead
  final PageController _carouselPageController = PageController(viewportFraction: 0.8);
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  int _currentCarouselIndex = 0;
  int _currentPage = 0;

  // Stubbed categories (replace with your data from data/menu_item.dart)
  static final List<Category> categories = [
    Category(id: 1, name: 'All'),
    Category(id: 2, name: 'Pizza'),
    Category(id: 3, name: 'Burger'),
    // Add more...
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabIndexChanged); // Listener for swipe updates
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _carouselPageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.removeListener(_onTabIndexChanged); // Remove listener
    _tabController.dispose();
    super.dispose();
  }

  void _onTabIndexChanged() {
    if (_tabController.index != _currentPage) {
      setState(() {
        _currentPage = _tabController.index;
      });
    }
  }

  void _onSearchChanged() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    menuProvider.setSearchQuery(_searchController.text);
  }

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        backgroundColor: AppColors.primary(context),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, MenuItem item) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    favoritesProvider.toggleFavorite(item);

    final isFavorite = favoritesProvider.isFavorite(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        backgroundColor: AppColors.primary(context),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _clearAllFilters() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    menuProvider.clearFilters();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.primary(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('MezaHub', style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        )),
        actions: [
          Consumer<MenuProvider>(
            builder: (context, menuProvider, child) {
              final hasActiveFilters = menuProvider.selectedCategoryId != null || menuProvider.searchQuery.isNotEmpty;
              if (hasActiveFilters) {
                return IconButton(
                  icon: Icon(Icons.clear_all, color: theme.iconTheme.color),
                  onPressed: _clearAllFilters,
                  tooltip: 'Clear all filters',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(), // Enhanced swipe physics for smoother gestures
        children: [
          // Home Tab with 3D Carousel
          Consumer<MenuProvider>(
            builder: (context, menuProvider, child) {
              final filteredItems = menuProvider.filteredItems;
              final featuredItems = filteredItems.where((item) => item.featured).toList();
              final popularItems = filteredItems.where((item) => !item.featured).toList();
              final hasActiveFilters = menuProvider.selectedCategoryId != null || menuProvider.searchQuery.isNotEmpty;

              return Column(
                children: [
                  if (hasActiveFilters) _buildActiveFiltersIndicator(menuProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildUserGreeting(),
                          _buildSearchSection(),
                          CategoryBodyPage(),
                          const SizedBox(height: 16),
                          if (hasActiveFilters) _buildResultsCount(filteredItems.length),
                          _buildTrendingHeader(),
                          if (featuredItems.isNotEmpty) _build3DFeaturedCarousel(featuredItems),
                          if (featuredItems.isNotEmpty) _buildCarouselIndicators(featuredItems.length),
                          _buildPopularDishes(popularItems, filteredItems.isEmpty),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Other tabs remain the same...
          // ... (rest of the tab content remains unchanged)
          Center(child: Text('Discover Tab')),
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              if (favoritesProvider.favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start adding your favorite dishes!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoritesProvider.favorites.length,
                itemBuilder: (context, index) {
                  final item = favoritesProvider.favorites[index];
                  return _buildFavoriteItem(item);
                },
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some delicious items to get started!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _tabController.animateTo(0);
                          setState(() => _currentPage = 0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: AppColors.onPrimary(context),
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
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.items[index];
                        return _buildCartItem(item.toJson(), cartProvider);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(top: BorderSide(color: theme.colorScheme.outline)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
                            foregroundColor: AppColors.onPrimary(context),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: Text(
                            'Checkout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary(context).withOpacity(0.1),
                      backgroundImage: userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty
                          ? NetworkImage(userProvider.profileImageUrl!)
                          : null,
                      child: userProvider.profileImageUrl == null || userProvider.profileImageUrl!.isEmpty
                          ? Icon(Icons.person, size: 40, color: AppColors.primary(context))
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Text(
                      userProvider.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to your profile',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.onPrimary(context),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 3D Perspective Carousel for Featured Dishes - Using PageView for compatibility
  Widget _build3DFeaturedCarousel(List<MenuItem> featuredItems) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: PageView.builder(
        controller: _carouselPageController,
        itemCount: featuredItems.length,
        physics: const BouncingScrollPhysics(), // Enhanced swipe physics for carousel
        onPageChanged: (index) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
        itemBuilder: (context, position) {
          return _build3DCarouselItem(featuredItems[position], position);
        },
      ),
    );
  }

  Widget _build3DCarouselItem(MenuItem item, int index) {
    final double scale = index == _currentCarouselIndex ? 1.0 : 0.8;
    final double opacity = index == _currentCarouselIndex ? 1.0 : 0.6;
    final primaryColor = AppColors.primary(context);

    return Consumer2<CartProvider, FavoritesProvider>(
      builder: (context, cartProvider, favoritesProvider, child) {
        final isInCart = cartProvider.isItemInCart(item.id);
        final isFavorite = favoritesProvider.isFavorite(item.id);

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () => _addToCart(context, item),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Stack(
                    children: [
                      // Background Image with Gradient
                      CachedNetworkImage(
                        imageUrl: item.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.outline, size: 50)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(child: Icon(Icons.fastfood, color: primaryColor, size: 50)),
                        ),
                      ),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row - Favorite Button
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => _toggleFavorite(context, item),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),

                            // Bottom Content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 10,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 5,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.8),
                                            blurRadius: 10,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isInCart ? primaryColor : Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isInCart ? Icons.shopping_cart_checkout : Icons.add_shopping_cart,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarouselIndicators(int itemCount) {
    final primaryColor = AppColors.primary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        return Container(
          width: _currentCarouselIndex == index ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentCarouselIndex == index ? primaryColor : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        );
      }),
    );
  }

  // Bottom Navigation Bar and other methods remain the same...
  Widget _buildBottomNavigationBar() {
    return Consumer2<CartProvider, FavoritesProvider>(
      builder: (context, cartProvider, favoritesProvider, child) {
        final cartItemCount = cartProvider.itemCount;
        final favoriteCount = favoritesProvider.favoriteCount;
        final primaryColor = AppColors.primary(context);

        return SalomonBottomBar(
          currentIndex: _currentPage,
          onTap: (index) {
            setState(() => _currentPage = index);
            _tabController.animateTo(index);
          },
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home),
              title: const Text('Home'),
              selectedColor: primaryColor,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.explore),
              title: const Text('Discover'),
              selectedColor: primaryColor,
            ),
            SalomonBottomBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.favorite),
                  if (favoriteCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          favoriteCount > 9 ? '9+' : favoriteCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('Favorites'),
              selectedColor: primaryColor,
            ),
            SalomonBottomBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartItemCount > 9 ? '9+' : cartItemCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('Cart'),
              selectedColor: primaryColor,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person),
              title: const Text('Profile'),
              selectedColor: primaryColor,
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.surface,
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  // ... (rest of the methods remain unchanged)
  Widget _buildActiveFiltersIndicator(MenuProvider menuProvider) {
    final primaryColor = AppColors.primary(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildFilterText(menuProvider),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildFilterText(MenuProvider menuProvider) {
    final filters = [];
    if (menuProvider.selectedCategoryId != null) {
      final category = categories.firstWhere(
            (cat) => cat.id == menuProvider.selectedCategoryId,
        orElse: () => categories.first,
      );
      filters.add(category.name);
    }
    if (menuProvider.searchQuery.isNotEmpty) {
      filters.add('"${menuProvider.searchQuery}"');
    }
    return 'Active filters: ${filters.join(' + ')}';
  }

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'item' : 'items'} found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGreeting() {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final displayName = userProvider.name;
    final primaryColor = AppColors.primary(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userProvider.profileImageUrl != null && userProvider.profileImageUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(userProvider.profileImageUrl!),
                  onBackgroundImageError: (exception, stackTrace) {},
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: primaryColor),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Hi, $displayName!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.waving_hand, color: Colors.amber),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.secondary.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(12),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: AppColors.secondary, size: 28),
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const NotificationsScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SearchFormField(
        controller: _searchController,
        icon: Icons.search,
        onChanged: (value) {},
        onFilter: () {
          if (_searchController.text.isNotEmpty) {}
        },
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        final hasActiveFilters = menuProvider.selectedCategoryId != null || menuProvider.searchQuery.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasActiveFilters ? "Filtered Results" : "Featured Dishes",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (!hasActiveFilters)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "See All",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularDishes(List<MenuItem> popularItems, bool isEmpty) {
    if (isEmpty) {
      return _buildEmptyState();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Popular Dishes",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), // Enhanced horizontal swipe for popular dishes
              itemCount: popularItems.length,
              itemBuilder: (context, index) {
                final item = popularItems[index];
                return _buildMenuCard(item);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearAllFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              foregroundColor: AppColors.onPrimary(context),
            ),
            child: Text(
              'Clear Filters',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(MenuItem item) {
    final primaryColor = AppColors.primary(context);

    return Consumer2<CartProvider, FavoritesProvider>(
      builder: (context, cartProvider, favoritesProvider, child) {
        final isInCart = cartProvider.isItemInCart(item.id);
        final isFavorite = favoritesProvider.isFavorite(item.id);
        final itemQuantity = isInCart ? cartProvider.getItemQuantity(item.id) : 0;

        return GestureDetector(
          onTap: () => _addToCart(context, item),
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: isInCart ? Border.all(
                color: primaryColor,
                width: 2,
              ) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: CachedNetworkImage(
                        imageUrl: item.image,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 100,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.outline),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 100,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Icon(Icons.fastfood, color: primaryColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(context, item),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : primaryColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isInCart ? primaryColor : Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isInCart ? Icons.shopping_cart_checkout : Icons.add_shopping_cart,
                          color: isInCart ? Colors.white : primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                    if (isInCart && itemQuantity > 0)
                      Positioned(
                        top: 8,
                        right: 32,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            itemQuantity.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            item.description,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (item.dietary.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.dietary[0],
                                  style: GoogleFonts.poppins(
                                    color: primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteItem(MenuItem item) {
    final primaryColor = AppColors.primary(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.image,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '\$${item.price.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _toggleFavorite(context, item),
        ),
        onTap: () => _addToCart(context, item),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item['image'],
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          item['name'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '\$${item['price']} × ${item['quantity']}',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: AppColors.primary(context)),
              onPressed: () => cartProvider.removeItem(item['id']),
            ),
            Text(
              item['quantity'].toString(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: AppColors.primary(context)),
              onPressed: () => cartProvider.addItem(
                id: item['id'],
                name: item['name'],
                price: item['price'],
                image: item['image'],
                quantity: 1,
                imageUrl: '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});
}