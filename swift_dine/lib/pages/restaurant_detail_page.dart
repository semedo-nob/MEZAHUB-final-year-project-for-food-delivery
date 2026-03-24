import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../model/restaurant.dart';
import '../provider/cart_provider.dart';
import '../services/backend_api.dart';
import '../theme/app_colors.dart';

class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailPage({super.key, required this.restaurant});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final id = int.tryParse(widget.restaurant.id);
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid restaurant';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await BackendApi.getRestaurantMenu(id);
      final list = data['categories'] as List<dynamic>? ?? [];
      setState(() {
        _categories = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.restaurant.name,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.restaurant.imageUrl != null && widget.restaurant.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.restaurant.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: AppColors.surfaceVariant(context),
                  child: Icon(Icons.restaurant, size: 64, color: AppColors.primary(context)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.surfaceVariant(context),
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: AppColors.primary(context),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.restaurant.description != null &&
                      widget.restaurant.description!.isNotEmpty) ...[
                    Text(
                      widget.restaurant.description!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.restaurant.cuisineType != null)
                    _detailRow(context, Icons.restaurant_menu, widget.restaurant.cuisineType!),
                  if (widget.restaurant.address != null && widget.restaurant.address!.isNotEmpty)
                    _detailRow(context, Icons.location_on, widget.restaurant.address!),
                  if (widget.restaurant.rating != null)
                    _detailRow(
                      context,
                      Icons.star,
                      '${widget.restaurant.rating!.toStringAsFixed(1)} rating',
                    ),
                  if (widget.restaurant.deliveryTime != null)
                    _detailRow(
                      context,
                      Icons.schedule,
                      '${widget.restaurant.deliveryTime} min delivery',
                    ),
                  if (widget.restaurant.deliveryFee != null)
                    _detailRow(
                      context,
                      Icons.motorcycle,
                      'KSh ${widget.restaurant.deliveryFee!.toStringAsFixed(0)} delivery fee',
                    )
                  else
                    _detailRow(context, Icons.motorcycle, 'Free delivery'),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Could not load menu',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
                          ),
                          TextButton(
                            onPressed: _loadMenu,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_categories.isEmpty)
                    Center(
                      child: Text(
                        'No menu yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    )
                  else
                    ..._categories.map((cat) => _buildCategorySection(context, cat)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, Map<String, dynamic> category) {
    final name = category['name'] as String? ?? 'Menu';
    final items = (category['items'] as List<dynamic>?) ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildMenuItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, dynamic item) {
    final m = Map<String, dynamic>.from(item as Map);
    final id = (m['id'] as num?)?.toInt() ?? 0;
    final name = m['name'] as String? ?? 'Item';
    final price = (m['price'] as num?)?.toDouble() ?? 0.0;
    final description = m['description'] as String?;
    final imageUrl = m['image_url'] as String? ?? '';

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final restaurantId = int.tryParse(widget.restaurant.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Icon(Icons.restaurant, color: AppColors.primary(context)),
                  errorWidget: (_, __, ___) => Icon(Icons.restaurant, color: AppColors.primary(context)),
                ),
              )
            : Icon(Icons.restaurant, color: AppColors.primary(context)),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        subtitle: description != null && description.isNotEmpty
            ? Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KSh ${price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary(context),
              onPressed: () {
                if (restaurantId != null) {
                  cartProvider.setRestaurant(
                    restaurantId: restaurantId,
                    restaurantName: widget.restaurant.name,
                  );
                  cartProvider.addItem(
                    id: id.toString(),
                    name: name,
                    price: price,
                    image: imageUrl,
                    quantity: 1,
                    imageUrl: imageUrl,
                    restaurantId: restaurantId,
                    restaurantName: widget.restaurant.name,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name added to cart'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(milliseconds: 800),
                        action: SnackBarAction(
                          label: 'Cart',
                          textColor: Colors.white,
                          onPressed: () => Navigator.pushNamed(context, '/cart'),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
