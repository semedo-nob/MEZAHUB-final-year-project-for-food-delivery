import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pages
import 'package:swift_dine/pages/HomeScreen.dart';
import 'package:swift_dine/pages/Login.dart';
import 'package:swift_dine/pages/OnboardingScreen.dart';
import 'package:swift_dine/pages/Register.dart';
import 'package:swift_dine/pages/cart_page.dart';
import 'package:swift_dine/pages/checkout_screen.dart';
import 'package:swift_dine/pages/dicover_page.dart';
import 'package:swift_dine/pages/favourites_page.dart';
import 'package:swift_dine/pages/live_tracking_screen.dart';
import 'package:swift_dine/pages/orders.dart';
import 'package:swift_dine/pages/profile.dart';
import 'package:swift_dine/pages/splash_screen.dart';

// Providers
import 'package:swift_dine/provider/favourites_provider.dart';
import 'package:swift_dine/provider/orders_provider.dart';
import 'package:swift_dine/provider/theme_provider.dart';
import 'package:swift_dine/provider/user_provider.dart';
import 'package:swift_dine/provider/cart_provider.dart';
import 'package:swift_dine/provider/menu_provider.dart';

// Services
import 'package:swift_dine/services/firebase_notification_service.dart';
import 'package:swift_dine/services/auth_service.dart';
import 'package:swift_dine/services/order_service.dart';
import 'package:swift_dine/services/sync_service.dart';

// Theme & Models
import 'package:swift_dine/theme/app_theme.dart';
import 'package:swift_dine/model/order.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://igmphgapgviazyalnzuq.supabase.co', // Add your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlnbXBoZ2FwZ3ZpYXp5YWxuenVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NDUzMjgsImV4cCI6MjA3NjUyMTMyOH0.mF5EGjZEg8pDo-4wfFbw94yStPid9IYhQXvg4DhKzpk', // Add your Supabase anon key
  );

  // Initialize services
  await FirebaseNotificationService.initialize();
  await SyncService().initializeSync(); // Initialize sync service

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _notificationSubscription;
  StreamSubscription<Order>? _orderUpdatesSubscription;
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      userProvider.initializeUser(); // This loads from SharedPreferences immediately
      userProvider.startListening();
    _setupNotificationListener();
    _setupAuthListener(); // ✅ Single unified auth listener
    _initializeUserProfile();
  }
    );}

  // ✅ Initialize user profile when app starts
  void _initializeUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.initializeUser();
    });
  }

  // ✅ SINGLE UNIFIED AUTH LISTENER - Handles both profile AND orders
  void _setupAuthListener() {
    _authService.userStream.listen((user) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (user != null) {
        // ✅ User logged in - handle BOTH profile AND orders
        userProvider.loadUserProfile();
        _subscribeToOrderUpdates();
        if (kDebugMode) {
          print('🔑 User authenticated: ${user.email}');
          print('📊 Loading user profile and order subscriptions...');
        }
      } else {
        // ✅ User logged out - handle BOTH profile AND orders
        userProvider.logout();
        _unsubscribeFromOrderUpdates();
        if (kDebugMode) {
          print('🔓 User signed out - clearing profile and unsubscribing from orders');
        }
      }
    });
  }

  void _subscribeToOrderUpdates() {
    try {
      _orderUpdatesSubscription = _orderService.subscribeToOrderUpdates((updatedOrder) {
        // Update orders provider when order changes
        final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
        ordersProvider.updateOrder(updatedOrder);

        print('🔄 Order updated via real-time: ${updatedOrder.id} - ${updatedOrder.status}');
      });
      print('✅ Subscribed to real-time order updates');
    } catch (e) {
      print('❌ Error subscribing to order updates: $e');
    }
  }

  void _unsubscribeFromOrderUpdates() {
    _orderUpdatesSubscription?.cancel();
    _orderUpdatesSubscription = null;
    print('🔕 Unsubscribed from order updates');
  }

  void _setupNotificationListener() {
    _notificationSubscription = FirebaseNotificationService.notificationStream.listen(
          (notification) {
        _handleNotification(notification);
      },
    );
  }

  void _handleNotification(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'];

    print('📱 Notification received - Type: $type, Data: $data');

    if (type == 'tap') {
      _handleNotificationTap(notification['payload']);
    } else if (type == 'order_update') {
      _handleOrderUpdateNotification(data);
    }
  }

  void _handleOrderUpdateNotification(Map<String, dynamic>? data) {
    if (data == null) return;

    final orderId = data['order_id'];
    final status = data['status'];

    print('📦 Order update notification: $orderId - $status');

    // Update orders provider with new status
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    ordersProvider.updateOrderStatus(orderId, _stringToOrderStatus(status));
  }

  // Helper method to convert string to OrderStatus
  OrderStatus _stringToOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'confirmed': return OrderStatus.confirmed;
      case 'preparing': return OrderStatus.preparing;
      case 'ready': return OrderStatus.ready;
      case 'on_the_way': return OrderStatus.onTheWay;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    print('👆 Notification tapped with payload: $payload');

    // Parse payload and navigate accordingly
    try {
      final payloadData = Map<String, dynamic>.from(payload as Map);
      final type = payloadData['type'];

      switch (type) {
        case 'order_update':
          final orderId = payloadData['order_id'];
          _navigateToOrderTracking(orderId);
          break;
        case 'new_order':
          _navigateToOrdersScreen();
          break;
        case 'promotion':
          _navigateToDiscover();
          break;
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  void _navigateToOrderTracking(String orderId) {
    // You might need to fetch the order first, then navigate
    print('📍 Navigating to order tracking: $orderId');
    // Implementation depends on your navigation structure
  }

  void _navigateToOrdersScreen() {
    print('📍 Navigating to orders screen');
    // Implementation depends on your navigation structure
  }

  void _navigateToDiscover() {
    print('📍 Navigating to discover screen');
    // Implementation depends on your navigation structure
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _orderUpdatesSubscription?.cancel();
    FirebaseNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),

        // Add service providers if needed
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<OrderService>(create: (_) => OrderService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SwiftDine',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboard': (context) => const OnboardingScreen(),
              '/home': (context) => const HomePage(),
              '/login': (context) => const LoginScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/favourites': (context) => const FavoritesPage(),
              '/profile': (context) => const ProfileScreen(),
              '/discover': (context) => const DiscoverPage(),
              '/register': (context) => const SignUpScreen(),
              '/cart': (context) => const CartScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/tracking': (context) {
                final order = ModalRoute.of(context)!.settings.arguments as Order;
                return LiveTrackingScreen(order: order);
              },
            },
            // Enhanced error handling
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0), // Prevent text scaling issues
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}