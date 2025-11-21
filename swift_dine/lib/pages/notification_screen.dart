import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swift_dine/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    // Order Updates
    NotificationItem(
      id: '1',
      type: NotificationType.orderUpdate,
      title: 'Driver Assigned',
      message: 'Mike is delivering your Burger Palace order',
      subtitle: 'ETA: 15 min • Live Tracking Available',
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
      action: 'track',
      orderId: 'SWIFT-001',
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.orderUpdate,
      title: 'Order Preparing',
      message: 'Pizza Express has started preparing your order',
      subtitle: 'Expected ready time: 8:15 PM',
      time: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      action: 'view',
      orderId: 'SWIFT-002',
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.orderUpdate,
      title: 'Order Delivered',
      message: 'Your Sushi Bar order has been delivered!',
      subtitle: 'Tap to rate your experience',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      action: 'rate',
      orderId: 'SWIFT-003',
    ),

    // Promotions
    NotificationItem(
      id: '4',
      type: NotificationType.promotion,
      title: '25% OFF Your Next Order',
      message: 'Try our new Mediterranean Bowl',
      subtitle: 'Valid until Sunday • Tap to browse',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
      action: 'browse',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.promotion,
      title: 'Free Delivery!',
      message: 'On all orders above KSh 800 this weekend',
      subtitle: 'Use code: FREESWIFT',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      action: 'shop',
    ),

    // System
    NotificationItem(
      id: '6',
      type: NotificationType.system,
      title: 'Login Detected',
      message: 'New sign-in from Nairobi, Kenya',
      subtitle: 'Tap to review account activity',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      action: 'review',
    ),
  ];

  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'orders', 'promotions', 'system'];

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _getFilteredNotifications();
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Badge(
                backgroundColor: AppColors.primary(context),
                textColor: AppColors.onPrimary(context),
                label: Text(unreadCount.toString()),
                child: Icon(Icons.mark_email_read, color: AppColors.textColor(context)),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textColor(context)),
            onSelected: (value) {
              if (value == 'settings') {
                _openNotificationSettings();
              } else if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: AppColors.textColor(context)),
                    const SizedBox(width: 12),
                    Text(
                      'Notification Settings',
                      style: GoogleFonts.poppins(color: AppColors.textColor(context)),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text(
                      'Clear All',
                      style: GoogleFonts.poppins(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(context),

          // Notifications List
          Expanded(
            child: filteredNotifications.isEmpty
                ? _buildEmptyState(context)
                : _buildNotificationsList(filteredNotifications, context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  _getFilterLabel(filter),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.onPrimary(context) : AppColors.textColor(context),
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: AppColors.surfaceVariant(context),
                selectedColor: AppColors.primary(context),
                checkmarkColor: AppColors.onPrimary(context),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all': return 'All';
      case 'orders': return 'Orders';
      case 'promotions': return 'Promotions';
      case 'system': return 'System';
      default: return 'All';
    }
  }

  List<NotificationItem> _getFilteredNotifications() {
    switch (_selectedFilter) {
      case 'orders':
        return _notifications.where((n) => n.type == NotificationType.orderUpdate).toList();
      case 'promotions':
        return _notifications.where((n) => n.type == NotificationType.promotion).toList();
      case 'system':
        return _notifications.where((n) => n.type == NotificationType.system).toList();
      default:
        return _notifications;
    }
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications, BuildContext context) {
    final groupedNotifications = _groupNotificationsByDate(notifications);

    return RefreshIndicator(
      backgroundColor: AppColors.background(context),
      color: AppColors.primary(context),
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          final group = groupedNotifications[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  group['date']!,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),

              // Notifications for this date
              ...group['notifications']!.map((notification) =>
                  _buildNotificationItem(notification, context)
              ).toList(),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(List<NotificationItem> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationItem>> groups = {};

    for (final notification in notifications) {
      final notificationDate = DateTime(
          notification.time.year,
          notification.time.month,
          notification.time.day
      );

      String dateKey;
      if (notificationDate == today) {
        dateKey = 'Today';
      } else if (notificationDate == yesterday) {
        dateKey = 'Yesterday';
      } else if (notificationDate.isAfter(today.subtract(const Duration(days: 7)))) {
        dateKey = 'This Week';
      } else {
        dateKey = '${notification.time.day}/${notification.time.month}/${notification.time.year}';
      }

      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(notification);
    }

    return groups.entries.map((entry) => {
      'date': entry.key,
      'notifications': entry.value,
    }).toList();
  }

  Widget _buildNotificationItem(NotificationItem notification, BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: AppColors.error),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(notification, context);
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: _buildNotificationIcon(notification, context),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                notification.message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (notification.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  notification.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary(context).withOpacity(0.8),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.time),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary(context).withOpacity(0.6),
                ),
              ),
            ],
          ),
          trailing: notification.imageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              notification.imageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fastfood, color: AppColors.textSecondary(context)),
                );
              },
            ),
          )
              : null,
          onTap: () => _handleNotificationTap(notification, context),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationItem notification, BuildContext context) {
    Color iconColor;
    IconData icon;

    switch (notification.type) {
      case NotificationType.orderUpdate:
        iconColor = AppColors.primary(context);
        icon = Icons.delivery_dining;
        break;
      case NotificationType.promotion:
        iconColor = AppColors.success;
        icon = Icons.local_offer;
        break;
      case NotificationType.system:
        iconColor = AppColors.info;
        icon = Icons.info;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${time.day}/${time.month}/${time.year}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 80,
          color: AppColors.textSecondary(context),
        ),
        const SizedBox(height: 20),
        Text(
          _selectedFilter == 'all'
              ? 'No notifications yet'
              : 'No ${_getFilterLabel(_selectedFilter).toLowerCase()} notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            'Order updates, promotions, and important alerts will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedFilter != 'all')
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              foregroundColor: AppColors.onPrimary(context),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'View All Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  // Action Methods
  Future<void> _handleNotificationTap(NotificationItem notification, BuildContext context) async {
    // Mark as read
    setState(() {
      notification.isRead = true;
    });

    // Handle different notification actions
    switch (notification.action) {
      case 'track':
        _showSnackbar('Opening order tracking...', context);
        break;
      case 'view':
        _showSnackbar('Opening order details...', context);
        break;
      case 'rate':
        _showSnackbar('Opening rating screen...', context);
        break;
      case 'browse':
      case 'shop':
        _showSnackbar('Opening restaurants...', context);
        break;
      case 'review':
        _showSnackbar('Opening security settings...', context);
        break;
      default:
        _showSnackbar('Notification tapped', context);
    }
  }

  Future<bool?> _showDeleteConfirmation(NotificationItem notification, BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Delete Notification?',
          style: GoogleFonts.poppins(
            color: AppColors.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove "${notification.title}" from your notifications.',
          style: GoogleFonts.poppins(
            color: AppColors.textColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final notification in _notifications) {
        notification.isRead = true;
      }
    });
    _showSnackbar('All notifications marked as read', context);
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Clear All Notifications?',
          style: GoogleFonts.poppins(
            color: AppColors.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove all your notifications. This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: AppColors.textColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _notifications.clear();
      });
      _showSnackbar('All notifications cleared', context);
    }
  }

  Future<void> _refreshNotifications() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
    _showSnackbar('Notifications updated', context);
  }

  void _openNotificationSettings() {
    _showSnackbar('Opening notification settings...', context);
    // You can navigate to settings page here
  }

  void _showSnackbar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.primary(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Notification Model Classes
enum NotificationType { orderUpdate, promotion, system }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String subtitle;
  final DateTime time;
  bool isRead;
  final String action;
  final String? orderId;
  final String? imageUrl;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.subtitle = '',
    required this.time,
    required this.isRead,
    required this.action,
    this.orderId,
    this.imageUrl,
  });
}