import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';

// Restaurant Model (keep your existing model)
class Restaurant {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final String deliveryFee;
  final List<String> categories;
  final bool isOpen;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.categories,
    required this.isOpen,
  });
}

// Mock restaurant data (keep your existing data)
final List<Restaurant> restaurants = [
  Restaurant(
    id: '1',
    name: 'Burger Palace',
    description: 'Gourmet burgers and crispy fries',
    image: 'https://images.pexels.com/photos/1633578/pexels-photo-1633578.jpeg',
    rating: 4.5,
    reviewCount: 124,
    deliveryTime: '25-35 min',
    deliveryFee: '\$2.99',
    categories: ['Burgers', 'American', 'Fast Food'],
    isOpen: true,
  ),
  Restaurant(
    id: '2',
    name: 'Tokyo Sushi',
    description: 'Fresh sushi and Japanese cuisine',
    image: 'https://images.pexels.com/photos/1052189/pexels-photo-1052189.jpeg',
    rating: 4.8,
    reviewCount: 89,
    deliveryTime: '30-40 min',
    deliveryFee: '\$3.99',
    categories: ['Sushi', 'Japanese', 'Asian'],
    isOpen: true,
  ),
  Restaurant(
    id: '3',
    name: 'Italian Corner',
    description: 'Authentic Italian pasta and pizza',
    image: 'https://images.pexels.com/photos/315755/pexels-photo-315755.jpeg',
    rating: 4.6,
    reviewCount: 156,
    deliveryTime: '20-30 min',
    deliveryFee: '\$1.99',
    categories: ['Italian', 'Pizza', 'Pasta'],
    isOpen: true,
  ),
  Restaurant(
    id: '4',
    name: 'Green Garden',
    description: 'Healthy salads and vegetarian options',
    image: 'https://images.pexels.com/photos/1510690/pexels-photo-1510690.jpeg',
    rating: 4.4,
    reviewCount: 67,
    deliveryTime: '15-25 min',
    deliveryFee: '\$2.49',
    categories: ['Healthy', 'Vegetarian', 'Salads'],
    isOpen: true,
  ),
  Restaurant(
    id: '5',
    name: 'Spice Route',
    description: 'Authentic Indian and Thai cuisine',
    image: 'https://images.pexels.com/photos/2474658/pexels-photo-2474658.jpeg',
    rating: 4.7,
    reviewCount: 203,
    deliveryTime: '35-45 min',
    deliveryFee: '\$3.49',
    categories: ['Indian', 'Thai', 'Spicy'],
    isOpen: false,
  ),
];

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> restaurantCategories = [
    'All',
    'Burgers',
    'Sushi',
    'Italian',
    'Healthy',
    'Indian',
    'Thai',
    'Pizza',
    'Asian',
  ];

  List<Restaurant> get filteredRestaurants {
    if (_selectedCategory == 'All') return restaurants;
    return restaurants.where((restaurant) =>
        restaurant.categories.contains(_selectedCategory)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Discover Restaurants',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
      ),
      body: Column(
        children: [
          // Search Bar - Using your theme's input decoration
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(
                color: AppColors.textColor(context),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.textSecondary(context),
                ),
                prefixIcon: Icon(Icons.search,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight),
                filled: true,
                fillColor: AppColors.surfaceVariant(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      width: 2
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Categories Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: restaurantCategories.length,
              itemBuilder: (context, index) {
                final category = restaurantCategories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == restaurantCategories.length - 1 ? 16 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary(context)
                            : AppColors.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary(context)
                              : AppColors.border(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? AppColors.onPrimary(context)
                                : AppColors.textSecondary(context),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Restaurants List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = filteredRestaurants[index];
                return _buildRestaurantCard(restaurant, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface(context),
      elevation: isDark ? 4 : 2,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${restaurant.name}'),
              backgroundColor: AppColors.primary(context),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: restaurant.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        Icons.restaurant,
                        color: AppColors.textSecondary(context)
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        Icons.restaurant,
                        color: AppColors.primary(context)
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Restaurant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: restaurant.isOpen
                                ? Colors.green.withOpacity(isDark ? 0.2 : 0.1)
                                : Colors.red.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            restaurant.isOpen ? 'OPEN' : 'CLOSED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: restaurant.isOpen ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      restaurant.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Restaurant Info Row
                    _buildRestaurantInfoRow(restaurant, context),

                    const SizedBox(height: 8),

                    // Categories
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: restaurant.categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.primary(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoRow(Restaurant restaurant, BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 160,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Rating
          _buildInfoItem(
            icon: Icons.star,
            value: '${restaurant.rating}',
            color: Colors.amber,
            context: context,
          ),

          // Review Count
          Text(
            '(${restaurant.reviewCount})',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),

          // Delivery time
          _buildInfoItem(
            icon: Icons.access_time,
            value: restaurant.deliveryTime,
            color: AppColors.textSecondary(context),
            context: context,
          ),

          // Delivery fee
          _buildInfoItem(
            icon: Icons.delivery_dining,
            value: restaurant.deliveryFee,
            color: AppColors.textSecondary(context),
            context: context,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required Color color,
    required BuildContext context,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}