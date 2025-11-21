import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:swift_dine/model/order.dart';
import 'package:swift_dine/provider/orders_provider.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:swift_dine/pages/live_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = ['All', 'Pending', 'Preparing', 'On the Way', 'Delivered'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _ordersForTab(String tab, List<Order> allOrders) {
    List<Order> filteredOrders;

    switch (tab) {
      case 'Pending':
        filteredOrders = allOrders.where((order) =>
        order.status == OrderStatus.pending || order.status == OrderStatus.confirmed).toList();
        break;
      case 'Preparing':
        filteredOrders = allOrders.where((order) => order.status == OrderStatus.preparing).toList();
        break;
      case 'On the Way':
        filteredOrders = allOrders.where((order) => order.status == OrderStatus.onTheWay).toList();
        break;
      case 'Delivered':
        filteredOrders = allOrders.where((order) => order.status == OrderStatus.delivered).toList();
        break;
      default: // 'All'
        filteredOrders = allOrders;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        final query = _searchQuery.toLowerCase();
        return order.id.toLowerCase().contains(query) ||
            order.restaurant.toLowerCase().contains(query) ||
            order.items.any((item) => item.name.toLowerCase().contains(query));
      }).toList();
    }

    return filteredOrders;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showClearOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Clear Orders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildClearOption(
              context,
              Icons.delete_sweep_rounded,
              'Clear All Orders',
              'Remove all your order history',
              AppColors.error,
                  () => _clearAllOrders(context),
            ),
            const SizedBox(height: 12),
            _buildClearOption(
              context,
              Icons.check_circle_outline,
              'Clear Completed Orders',
              'Remove delivered and cancelled orders',
              AppColors.success,
                  () => _clearCompletedOrders(context),
            ),
            const SizedBox(height: 12),
            _buildClearOption(
              context,
              Icons.cancel_outlined,
              'Clear Cancelled Orders',
              'Remove only cancelled orders',
              AppColors.warning,
                  () => _clearCancelledOrders(context),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary(context),
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearOption(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      color: AppColors.surface(context),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.textColor(context),
        )),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textSecondary(context),
        )),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }

  void _clearAllOrders(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Clear All Orders',
          style: GoogleFonts.poppins(color: AppColors.textColor(context)),
        ),
        content: Text(
          'This will permanently remove all your order history. This action cannot be undone.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                await ordersProvider.clearAllOrders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All orders cleared successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear orders'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _clearCompletedOrders(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Clear Completed Orders',
          style: GoogleFonts.poppins(color: AppColors.textColor(context)),
        ),
        content: Text(
          'This will remove all delivered and cancelled orders from your history.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                await ordersProvider.clearCompletedOrders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Completed orders cleared successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear completed orders'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: Text('Clear Completed'),
          ),
        ],
      ),
    );
  }

  void _clearCancelledOrders(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Clear Cancelled Orders',
          style: GoogleFonts.poppins(color: AppColors.textColor(context)),
        ),
        content: Text(
          'This will remove all cancelled orders from your history.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                await ordersProvider.clearOrdersByStatus([OrderStatus.cancelled]);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cancelled orders cleared successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear cancelled orders'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: Text('Clear Cancelled'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: _isSearching
            ? IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor(context)),
          onPressed: _toggleSearch,
        )
            : IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search orders, restaurants...',
            hintStyle: GoogleFonts.poppins(
              color: AppColors.textSecondary(context),
            ),
            border: InputBorder.none,
          ),
          style: GoogleFonts.poppins(
            color: AppColors.textColor(context),
          ),
        )
            : Text(
          'Orders',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isSearching && ordersProvider.orders.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.textColor(context)),
              onPressed: () => _showClearOptions(context),
              tooltip: 'Clear Orders',
            ),
            IconButton(
              icon: Icon(Icons.search_rounded, color: AppColors.textColor(context)),
              onPressed: _toggleSearch,
            ),
          ] else if (!_isSearching && ordersProvider.orders.isEmpty)
            IconButton(
              icon: Icon(Icons.search_rounded, color: AppColors.textColor(context)),
              onPressed: _toggleSearch,
            )
          else if (_isSearching)
              IconButton(
                icon: Icon(Icons.clear_rounded, color: AppColors.textColor(context)),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
        ],
      ),
      body: Column(
        children: [
          // Search results indicator
          if (_searchQuery.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Search results for "$_searchQuery"',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: Text(
                      'Clear',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.border(context)),
          ],

          // Tabs row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final isSelected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      _pageController.animateToPage(i,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary(context) : AppColors.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.border(context)),
                      ),
                      child: Center(
                        child: Text(
                          _tabs[i],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isSelected ? AppColors.onPrimary(context) : AppColors.textColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          Divider(height: 0, color: AppColors.border(context)),

          // Orders List
          Expanded(
            child: ordersProvider.loading
                ? _buildLoadingShimmer()
                : PageView.builder(
              controller: _pageController,
              itemCount: _tabs.length,
              onPageChanged: (page) => setState(() => _selectedIndex = page),
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final orders = _ordersForTab(tab, ordersProvider.orders);

                if (orders.isEmpty) {
                  return _buildEmptyState(tab, theme);
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => OrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (_, __) => const _OrderCardShimmer(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }

  Widget _buildEmptyState(String tab, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.receipt_long_rounded,
          size: 64,
          color: AppColors.textSecondary(context),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No orders found for "$_searchQuery"'
                : 'No $tab orders yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear Search',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// OrderCard with Theme Integration
class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.onTheWay:
        return Colors.deepOrange;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return Icons.access_time_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.ready:
        return Icons.assignment_turned_in_rounded;
      case OrderStatus.onTheWay:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);

    if (orderDay == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (orderDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  bool _canTrackOrder(Order order) {
    return order.status == OrderStatus.onTheWay ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready;
  }

  void _openLiveTracking(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(order: order),
      ),
    );
  }

  void _onCardTap(BuildContext context, Order order) {
    if (_canTrackOrder(order)) {
      _openLiveTracking(context, order);
    } else {
      _viewOrderDetails(context, order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTrack = _canTrackOrder(order);

    return GestureDetector(
      onTap: () => _onCardTap(context, order),
      child: Card(
        elevation: 2,
        color: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatOrderDate(order.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(getStatusIcon(order.status), size: 14, color: getStatusColor(order.status)),
                        const SizedBox(width: 6),
                        Text(
                          getStatusText(order.status),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: getStatusColor(order.status),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Restaurant and amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.restaurant,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textColor(context).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.formattedAmount,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Order items preview
              _OrderItemsPreview(order: order),

              // Enhanced Tracking Information
              if (canTrack) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary(context).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          order.status == OrderStatus.onTheWay
                              ? Icons.delivery_dining
                              : Icons.restaurant,
                          color: AppColors.primary(context),
                          size: 20
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.status == OrderStatus.onTheWay
                                  ? 'Driver is on the way - Tap card to track live'
                                  : order.status == OrderStatus.preparing
                                  ? 'Restaurant is preparing - Tap card to track'
                                  : 'Order is ready - Tap card to track delivery',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (order.currentLocation != null && order.status == OrderStatus.onTheWay)
                              Text(
                                'Last updated: ${_formatTimestamp(order.currentLocation!.timestamp)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.touch_app,
                        color: AppColors.primary(context),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewOrderDetails(context, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary(context),
                        side: BorderSide(color: AppColors.primary(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (order.status == OrderStatus.delivered)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _reorder(context, order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Reorder',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(color: AppColors.textColor(context)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order ID: ${order.id}',
                style: GoogleFonts.poppins(color: AppColors.textColor(context)),
              ),
              Text(
                'Date: ${_formatOrderDate(order.createdAt)}',
                style: GoogleFonts.poppins(color: AppColors.textColor(context)),
              ),
              Text(
                'Status: ${getStatusText(order.status)}',
                style: GoogleFonts.poppins(color: AppColors.textColor(context)),
              ),
              Text(
                'Total: ${order.formattedAmount}',
                style: GoogleFonts.poppins(color: AppColors.textColor(context)),
              ),
              if (order.deliveryAddress.address.contains('Store Pickup'))
                Text(
                  'Type: Pickup',
                  style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                )
              else
                Text(
                  'Type: Delivery',
                  style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                ),
              const SizedBox(height: 16),
              Text(
                'Items:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor(context),
                ),
              ),
              ...order.items.map((item) =>
                  Text(
                    '• ${item.name} x${item.quantity} - KSh ${item.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                  )
              ),
              if (_canTrackOrder(order)) ...[
                const SizedBox(height: 16),
                Text(
                  'Tracking:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor(context),
                  ),
                ),
                if (order.status == OrderStatus.onTheWay && order.currentLocation != null) ...[
                  Text(
                    'Last location update: ${_formatTimestamp(order.currentLocation!.timestamp)}',
                    style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                  ),
                  Text(
                    'Latitude: ${order.currentLocation!.lat.toStringAsFixed(4)}',
                    style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                  ),
                  Text(
                    'Longitude: ${order.currentLocation!.lng.toStringAsFixed(4)}',
                    style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openLiveTracking(context, order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: AppColors.onPrimary(context),
                    ),
                    child: Text('Open Live Tracking'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: AppColors.textSecondary(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _reorder(BuildContext context, Order order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${order.items.length} items to cart'),
        backgroundColor: AppColors.primary(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Order Items Preview
class _OrderItemsPreview extends StatelessWidget {
  final Order order;

  const _OrderItemsPreview({required this.order});

  bool _canTrackOrder(Order order) {
    return order.status == OrderStatus.onTheWay ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready;
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = order.items.take(3).toList();
    final remainingItems = order.items.length - displayedItems.length;

    return Row(
      children: [
        Row(
          children: [
            for (int i = 0; i < displayedItems.length; i++)
              Container(
                margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.background(context),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: displayedItems[i].imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceVariant(context),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceVariant(context),
                      child: Icon(Icons.fastfood_rounded, color: AppColors.textSecondary(context)),
                    ),
                  ),
                ),
              ),
            if (remainingItems > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.background(context),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingItems',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap card to ${_canTrackOrder(order) ? 'track order' : 'view details'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Shimmer placeholder
class _OrderCardShimmer extends StatelessWidget {
  const _OrderCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant(context),
      highlightColor: AppColors.surface(context),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(height: 16, width: 80, color: Colors.white),
                  const Spacer(),
                  Container(height: 24, width: 80, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12, width: 120, color: Colors.white),
                  Container(height: 14, width: 60, color: Colors.white),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Container(
                          margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 60, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(height: 12, width: 100, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Container(height: 44, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 44, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}