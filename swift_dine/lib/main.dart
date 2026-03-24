import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pages
import 'package:swift_dine/pages/HomeScreen.dart';
import 'package:swift_dine/pages/Login.dart';
import 'package:swift_dine/pages/OnboardingScreen.dart';
import 'package:swift_dine/pages/Register.dart';
import 'package:swift_dine/pages/cart_page.dart';
import 'package:swift_dine/pages/checkout_screen.dart';
import 'package:swift_dine/pages/dicover_page.dart';
import 'package:swift_dine/pages/restaurant_detail_page.dart';
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

// Theme & Models
import 'package:swift_dine/theme/app_theme.dart';
import 'package:swift_dine/model/order.dart';
import 'package:swift_dine/model/restaurant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (notifications, optional storage)
  await Firebase.initializeApp();

  // Initialize services (auth is backend JWT; orders from backend)
  await FirebaseNotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _notificationSubscription;
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
        userProvider.loadUserProfile();
        if (kDebugMode) {
          print('🔑 User authenticated: ${user.email}');
        }
      } else {
        userProvider.logout();
        if (kDebugMode) {
          print('🔓 User signed out');
        }
      }
    });
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
              '/restaurant': (context) {
                final restaurant =
                    ModalRoute.of(context)!.settings.arguments as Restaurant;
                return RestaurantDetailPage(restaurant: restaurant);
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