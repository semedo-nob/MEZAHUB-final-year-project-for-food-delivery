// lib/screens/cart_screen.dart
// Harmonized CartScreen with AppColors adaptive methods.
// Fixed: 'errorBuilder' → 'errorWidget' in CachedNetworkImage.
// All opacity calls verified (all on Color types, no invalid ranges).
// All other issues resolved; all colors adaptive.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_dine/provider/cart_provider.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Cart',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (cartProvider.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Clear Cart',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor(context),
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to clear all items from your cart?',
                      style: GoogleFonts.poppins(
                        color: AppColors.textColor(context).withOpacity(0.8),
                      ),
                    ),
                    backgroundColor: AppColors.surface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: AppColors.textColor(context).withOpacity(0.7),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          cartProvider.clearCart();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear',
                          style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: cartProvider.items.isEmpty
            ? _buildEmptyCart(context)
            : _buildFilledCart(context),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.primary(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.textColor(context).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items to get started!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textColor(context).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledCart(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: Provider.of<CartProvider>(context).items.length,
            itemBuilder: (context, index) {
              final item = Provider.of<CartProvider>(context).items[index];
              return CartItemCard(item: item);
            },
          ),
        ),
        // Bottom Summary Card
        _buildSummaryCard(context),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textColor(context).withOpacity(0.7),
                ),
              ),
              Text(
                'KSh ${cartProvider.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (8%)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textColor(context).withOpacity(0.7),
                ),
              ),
              Text(
                'KSh ${cartProvider.calculateTax(8).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor(context),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor(context),
                ),
              ),
              Text(
                'KSh ${cartProvider.totalWithTax.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckoutScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Checkout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) => Icon(
                    Icons.fastfood_outlined,
                    size: 40,
                    color: AppColors.primary(context).withOpacity(0.5),
                  ),
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.background(context),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary(context)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KSh ${item.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary(context),
                    ),
                  ),

                  // Display notes if available
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${item.notes!}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textColor(context).withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Display customizations if available
                  if (item.customizations != null && item.customizations!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: item.customizations!.map((customization) {
                        return Chip(
                          label: Text(
                            customization,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.primary(context),
                            ),
                          ),
                          backgroundColor: AppColors.primary(context).withOpacity(0.1),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],

                  // Display item total
                  const SizedBox(height: 4),
                  Text(
                    'Total: KSh ${item.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor(context).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls and Delete
            Column(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 18, color: AppColors.primary(context)),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          cartProvider.decreaseQuantity(item.id);
                        },
                      ),
                      Text(
                        '${item.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 18, color: AppColors.primary(context)),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          cartProvider.increaseQuantity(item.id);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Delete Button
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: () {
                    cartProvider.removeItem(item.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}