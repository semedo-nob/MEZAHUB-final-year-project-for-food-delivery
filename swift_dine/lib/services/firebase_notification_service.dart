import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static StreamController<Map<String, dynamic>> _notificationStream = StreamController.broadcast();
  static Stream<Map<String, dynamic>> get notificationStream => _notificationStream.stream;

  static bool _isInitialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Notification permission: ${settings.authorizationStatus}');

      // Initialize local notifications for Android
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize for iOS
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );

      // Setup notification channels for Android
      await _setupNotificationChannels();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Get and save device token
      _getAndSaveDeviceToken();

      _isInitialized = true;
      print('Firebase Notification Service Initialized Successfully');

    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  static Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'swiftdine_orders',
      'SwiftDine Order Updates',
      description: 'Notifications for order status and delivery tracking',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(message);

    // Broadcast to stream
    _notificationStream.add({
      'type': 'foreground',
      'data': message.data,
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
    });
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message opened: ${message.messageId}');

    _notificationStream.add({
      'type': 'background',
      'data': message.data,
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'swiftdine_orders',
      'SwiftDine Order Updates',
      channelDescription: 'Order status and delivery tracking notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      autoCancel: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'SwiftDine',
      message.notification?.body ?? 'New update',
      platformChannelSpecifics,
      payload: message.data['type'] ?? 'general',
    );
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    print('Notification tapped with payload: $payload');

    _notificationStream.add({
      'type': 'tap',
      'payload': payload,
    });
  }

  static Future<void> _getAndSaveDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        await _firebaseMessaging.subscribeToTopic('all_users');
        await _firebaseMessaging.subscribeToTopic('swiftdine_app');
        print('Subscribed to general topics');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Order-specific subscription methods
  static Future<void> subscribeToOrder(String orderId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('order_$orderId');
      print('Subscribed to order: $orderId');
    } catch (e) {
      print('Error subscribing to order: $e');
    }
  }

  static Future<void> unsubscribeFromOrder(String orderId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('order_$orderId');
      print('Unsubscribed from order: $orderId');
    } catch (e) {
      print('Error unsubscribing from order: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static void dispose() {
    _notificationStream.close();
  }
}