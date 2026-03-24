// lib/screens/checkout_screen.dart
// Complete CheckoutScreen with phone number validation, country flags, and codes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_dine/provider/cart_provider.dart';
import 'package:swift_dine/provider/user_provider.dart';
import 'package:swift_dine/model/order.dart';
import 'package:swift_dine/provider/orders_provider.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:swift_dine/pages/live_tracking_screen.dart';
import 'package:swift_dine/services/driver_tracking_service.dart';
import 'package:swift_dine/services/backend_order_service.dart';
import 'package:swift_dine/model/country_code.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.mpesa;
  bool _isProcessing = false;
  Position? _currentPosition;
  String _locationAddress = '';
  bool _isDelivery = true;
  bool _useCurrentLocation = true;
  bool _isGettingLocation = false;

  // Phone number variables
  CountryCode _selectedCountry = countryCodes.first;
  bool _showCountryPicker = false;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final DriverTrackingService _driverService = DriverTrackingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAuth();
    if (_isDelivery) {
      _getCurrentLocation();
    }
  }

  Future<void> _initializeFirebaseAuth() async {
    try {
      await _auth.signInAnonymously();
      print('User signed in anonymously: ${_auth.currentUser?.uid}');
    } catch (e) {
      print('Error signing in anonymously: $e');
    }
  }

  // Phone number validation method - SIMPLIFIED
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters to check length
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Simple length check
    if (digitsOnly.length < 9) {
      return 'Phone number is too short (min 9 digits)';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long (max 15 digits)';
    }

    // Kenya-specific validation - only check if it starts with 7 or 1
    if (_selectedCountry.code == 'KE') {
      if (!digitsOnly.startsWith('7') && !digitsOnly.startsWith('1')) {
        return 'Kenyan numbers must start with 7 or 1';
      }
      if (digitsOnly.length != 9) {
        return 'Kenyan numbers must be 9 digits';
      }
    }

    return null;
  }

// Method to format phone number - NON-INTERFERING
  String _formatPhoneNumber(String input) {
    // Don't format if empty
    if (input.isEmpty) return input;

    // Remove all non-digit characters
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');

    // Only format Kenyan numbers when they reach certain lengths
    if (_selectedCountry.code == 'KE') {
      if (digits.length >= 4 && digits.length <= 6) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      } else if (digits.length > 6) {
        // Format as XXX XXX XXX but don't restrict beyond 9 digits
        final part1 = digits.substring(0, 3);
        final part2 = digits.substring(3, 6);
        final part3 = digits.length > 9 ? digits.substring(6, 9) : digits.substring(6);
        return '$part1 $part2 $part3';
      }
    }

    return digits;
  }


  // Method to show country picker
  void _showCountrySelection() {
    setState(() {
      _showCountryPicker = !_showCountryPicker;
    });
  }

  // Method to select country
  void _selectCountry(CountryCode country) {
    setState(() {
      _selectedCountry = country;
      _showCountryPicker = false;
    });
  }

  // Widget for country picker dropdown
  Widget _buildCountryPicker() {
    if (!_showCountryPicker) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListView.builder(
        itemCount: countryCodes.length,
        itemBuilder: (context, index) {
          final country = countryCodes[index];
          return ListTile(
            leading: Text(
              country.flag,
              style: const TextStyle(fontSize: 20),
            ),
            title: Text(
              country.name,
              style: GoogleFonts.poppins(),
            ),
            subtitle: Text(
              country.dialCode,
              style: GoogleFonts.poppins(),
            ),
            trailing: _selectedCountry.code == country.code
                ? Icon(Icons.check, color: AppColors.primary(context))
                : null,
            onTap: () => _selectCountry(country),
          );
        },
      ),
    );
  }

  // Updated phone number field widget
  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number *',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: AppColors.textColor(context),
          ),
        ),
        const SizedBox(height: 8),

        // Country code selector
        GestureDetector(
          onTap: _showCountrySelection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCountry.flag,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCountry.dialCode,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCountryPicker ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: AppColors.textColor(context).withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Country picker dropdown
        _buildCountryPicker(),

        const SizedBox(height: 8),

        // Phone number input field
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Enter phone number',
            hintText: _selectedCountry.code == 'KE' ? '712 345 678' : 'Enter your phone number',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surfaceVariant(context),
            prefixText: _selectedCountry.dialCode + ' ',
            prefixStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: AppColors.textColor(context),
            ),
            errorMaxLines: 2,
          ),
          keyboardType: TextInputType.phone,
          validator: _validatePhoneNumber,
          onChanged: (value) {
            // Format the phone number as user types
            final formatted = _formatPhoneNumber(value);
            if (formatted != value) {
              _phoneController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
        ),

        // Phone number format hint
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Format: ${_selectedCountry.dialCode} XXX XXX XXX',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textColor(context).withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!_useCurrentLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentPosition = position;
          _locationAddress = '${placemark.street}, ${placemark.locality}';
          _addressController.text = _locationAddress;
          _cityController.text = placemark.locality ?? 'Nairobi';
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Position _createPosition(double latitude, double longitude) {
    return Position(
      longitude: longitude,
      latitude: latitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<void> _searchLocation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Location'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('In a full implementation, this would open a map search interface.'),
            SizedBox(height: 16),
            Text('For demo purposes, we\'ll use a sample location.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentPosition = _createPosition(-1.2921, 36.8219);
                _addressController.text = 'Kenyatta Avenue, Nairobi CBD';
                _cityController.text = 'Nairobi';
                _useCurrentLocation = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Use Sample Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isDelivery && _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your delivery location')),
      );
      return;
    }

    if (_isDelivery && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your delivery address')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

      // For delivery: use the user's exact current location at order time (refresh GPS)
      Position? orderTimePosition;
      if (_isDelivery) {
        try {
          orderTimePosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (_) {
          orderTimePosition = _currentPosition; // fallback to last known
        }
        if (orderTimePosition == null) {
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to get your current location. Enable location and try again.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      // Format phone number for storage (remove spaces and combine with country code)
      final formattedPhone = _selectedCountry.dialCode +
          _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      final deliveryAddress = _isDelivery
          ? DeliveryAddress(
        fullName: _fullNameController.text,
        phone: formattedPhone,
        address: _addressController.text,
        city: _cityController.text,
        additionalInfo: _additionalInfoController.text.isEmpty
            ? null
            : _additionalInfoController.text,
        lat: orderTimePosition!.latitude,
        lng: orderTimePosition!.longitude,
      )
          : DeliveryAddress(
        fullName: _fullNameController.text,
        phone: formattedPhone,
        address: 'Store Pickup',
        city: _cityController.text.isEmpty ? 'Nairobi' : _cityController.text,
        additionalInfo: 'Customer will pick up order',
        lat: -1.2921,
        lng: 36.8219,
      );

      final rid = cartProvider.restaurantId;
      final rName = cartProvider.restaurantName ?? 'Restaurant';

      // Backend path: cart has restaurant from Discover → place order via API
      // Guest checkout allowed: user provides details at checkout; payment gate can be enforced later.
      if (rid != null) {
        await _simulatePaymentProcess();
        final isGuest = !Provider.of<UserProvider>(context, listen: false).isLoggedIn;
        final newOrder = await BackendOrderService().createOrder(
          restaurantId: rid,
          restaurantName: rName,
          items: cartProvider.items.map((cartItem) => OrderItem(
            id: cartItem.id,
            name: cartItem.name,
            imageUrl: cartItem.image,
            quantity: cartItem.quantity,
            price: cartItem.price,
          )).toList(),
          totalAmount: _isDelivery ? cartProvider.totalAmount + 100 : cartProvider.totalAmount,
          deliveryAddress: deliveryAddress,
          paymentMethod: _selectedPaymentMethod,
          isGuest: isGuest,
        );
        if (newOrder == null) {
          if (mounted) {
            final message = BackendOrderService.lastOrderError ?? 'Order failed. Check connection and try again.';
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        newOrder.paymentStatus = PaymentStatus.completed;
        await ordersProvider.addOrder(newOrder);
        cartProvider.clearCart();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${newOrder.id} placed! ${_isDelivery ? 'Track it in Orders.' : 'Ready for pickup.'}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          if (_isDelivery) {
            _showTrackingPopup(context, newOrder);
          } else {
            Navigator.pushReplacementNamed(context, '/orders');
          }
        }
        return;
      }

      // Fallback: no restaurant (e.g. cart from Home mock data) – create local-only order
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      final newOrder = Order(
        id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        items: cartProvider.items.map((cartItem) => OrderItem(
          id: cartItem.id,
          name: cartItem.name,
          imageUrl: cartItem.image,
          quantity: cartItem.quantity,
          price: cartItem.price,
        )).toList(),
        totalAmount: _isDelivery ? cartProvider.totalAmount + 100 : cartProvider.totalAmount,
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        restaurant: rName,
        deliveryAddress: deliveryAddress,
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: PaymentStatus.pending,
        trackingNumber: 'TRK${DateTime.now().millisecondsSinceEpoch}',
        currentLocation: _isDelivery ? LocationData(
          lat: -1.2921,
          lng: 36.8219,
          timestamp: DateTime.now(),
        ) : null,
        driverName: null,
        driverPhone: null,
        driverPhoto: null,
        vehicleType: null,
        vehiclePlate: null,
        estimatedArrivalMinutes: null,
        estimatedArrivalTime: null,
        deliveryPath: null,
      );

      await _simulatePaymentProcess();
      newOrder.paymentStatus = PaymentStatus.completed;
      newOrder.status = _isDelivery ? OrderStatus.confirmed : OrderStatus.ready;
      await _saveOrderToFirebase(newOrder);
      await ordersProvider.addOrder(newOrder);
      if (_isDelivery) _startFirebaseOrderTracking(newOrder);
      cartProvider.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed! ${_isDelivery ? 'Your food will be delivered soon!' : 'Ready for pickup!'}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        if (_isDelivery) {
          _showTrackingPopup(context, newOrder);
        } else {
          Navigator.pushReplacementNamed(context, '/orders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Save order to Firebase Realtime Database with authentication
  Future<void> _saveOrderToFirebase(Order order) async {
    try {
      final user = _auth.currentUser;

      // Prepare order data with user information for Firebase rules
      final orderData = {
        'id': order.id,
        'userId': order.userId,
        'customer_id': order.userId,
        'items': order.items.map((item) => item.toJson()).toList(),
        'totalAmount': order.totalAmount,
        'createdAt': order.createdAt.toIso8601String(),
        'status': order.status.toString().split('.').last,
        'restaurant': order.restaurant,
        'deliveryAddress': order.deliveryAddress.toJson(),
        'paymentMethod': order.paymentMethod.toString().split('.').last,
        'paymentStatus': order.paymentStatus.toString().split('.').last,
        'trackingNumber': order.trackingNumber,
        'currentLocation': order.currentLocation?.toJson(),
        // Firebase tracking properties
        'driverName': order.driverName,
        'driverPhone': order.driverPhone,
        'driverPhoto': order.driverPhoto,
        'vehicleType': order.vehicleType,
        'vehiclePlate': order.vehiclePlate,
        'estimatedArrivalMinutes': order.estimatedArrivalMinutes,
        'estimatedArrivalTime': order.estimatedArrivalTime?.toIso8601String(),
        'created_by': user?.uid ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _database.child('orders').child(order.id).set(orderData);
      print('✅ Order saved to Firebase: ${order.id}');
    } catch (e) {
      print('❌ Error saving order to Firebase: $e');
      rethrow;
    }
  }

  // Start Firebase order tracking simulation
  void _startFirebaseOrderTracking(Order order) {
    // Start driver tracking
    _driverService.startTracking(
      orderId: order.id,
      driverId: 'driver_123',
    );

    // Simulate driver assignment
    Future.delayed(const Duration(seconds: 5), () {
      _driverService.assignDriverToOrder(
        orderId: order.id,
        driverId: 'driver_123',
        driverName: order.driverName!,
        driverPhone: order.driverPhone!,
        vehicleType: order.vehicleType!,
        vehiclePlate: order.vehiclePlate!,
      );

      // Start driver location simulation
      _simulateDriverMovement(order.id);
    });
  }

  // Simulate driver movement with authentication
  void _simulateDriverMovement(String orderId) {
    final user = _auth.currentUser;

    final locations = [
      {'lat': -1.2921, 'lng': 36.8219}, // Restaurant
      {'lat': -1.2930, 'lng': 36.8225},
      {'lat': -1.2940, 'lng': 36.8230},
      {'lat': -1.2950, 'lng': 36.8240},
      {'lat': _currentPosition!.latitude, 'lng': _currentPosition!.longitude}, // Customer
    ];

    for (int i = 0; i < locations.length; i++) {
      Future.delayed(Duration(seconds: 10 * (i + 1)), () {
        // Update driver location in Firebase
        final trackingData = {
          'driver_location': {
            'lat': locations[i]['lat'],
            'lng': locations[i]['lng'],
            'timestamp': DateTime.now().toIso8601String(),
            'driver_id': 'driver_123',
            'customer_id': user?.uid ?? orderId,
          },
          'last_updated': DateTime.now().toIso8601String(),
          'updated_by': user?.uid ?? 'system',
        };

        _database.child('order_tracking').child(orderId).update(trackingData)
            .then((_) => print('✅ Driver location updated: ${i + 1}/${locations.length}'))
            .catchError((e) => print('❌ Error updating driver location: $e'));

        // Update order status progressively
        if (i == 1) {
          _updateOrderStatusSafely(orderId, 'preparing');
        }
        if (i == 2) {
          _updateOrderStatusSafely(orderId, 'onTheWay');
        }
        if (i == locations.length - 1) {
          _updateOrderStatusSafely(orderId, 'delivered');
        }
      });
    }
  }

  Future<void> _updateOrderStatusSafely(String orderId, String status) async {
    try {
      await _driverService.updateOrderStatus(orderId: orderId, status: status);
      print('✅ Order status updated to: $status');
    } catch (e) {
      print('❌ Error updating order status: $e');
    }
  }

  void _showTrackingPopup(BuildContext context, Order newOrder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.track_changes, color: AppColors.primary(context), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Track Your Order',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Icon(Icons.delivery_dining, size: 60, color: AppColors.primary(context)),
                  const SizedBox(height: 16),
                  Text(
                    'Your order is being prepared!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Would you like to track your delivery in real-time?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textColor(context).withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary(context).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Order ID: ${newOrder.id}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primary(context),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/orders');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppColors.primary(context).withOpacity(0.3)),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.poppins(
                              color: AppColors.textColor(context).withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveTrackingScreen(order: newOrder),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Track Order',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _simulatePaymentProcess() async {
    await Future.delayed(const Duration(seconds: 2));

    switch (_selectedPaymentMethod) {
      case PaymentMethod.mpesa:
        await Future.delayed(const Duration(seconds: 3));
        break;
      case PaymentMethod.stripe:
        await Future.delayed(const Duration(seconds: 2));
        break;
      case PaymentMethod.cash:
        await Future.delayed(const Duration(seconds: 1));
        break;
      case PaymentMethod.mobileMoney:
        throw UnimplementedError();
      case PaymentMethod.card:
        throw UnimplementedError();
    }
  }

  // All UI builder methods harmonized with AppColors
  Widget _buildPaymentMethodCard(PaymentMethod method, String title, String subtitle, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: AppColors.primary(context).withOpacity(isSelected ? 0.1 : 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary(context) : AppColors.border(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary(context) : Theme.of(context).iconTheme.color),
        title: Text(title, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.primary(context) : AppColors.textColor(context),
        )),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(
          fontSize: 12,
          color: isSelected ? AppColors.primary(context) : AppColors.textColor(context).withOpacity(0.7),
        )),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppColors.primary(context))
            : null,
        onTap: () => setState(() => _selectedPaymentMethod = method),
      ),
    );
  }

  Widget _buildDeliveryOptionCard(String title, String subtitle, IconData icon, bool isDelivery) {
    final isSelected = _isDelivery == isDelivery;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: AppColors.primary(context).withOpacity(isSelected ? 0.1 : 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary(context) : AppColors.border(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary(context) : Theme.of(context).iconTheme.color),
        title: Text(title, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.primary(context) : AppColors.textColor(context),
        )),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(
          fontSize: 12,
          color: isSelected ? AppColors.primary(context) : AppColors.textColor(context).withOpacity(0.7),
        )),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppColors.primary(context))
            : null,
        onTap: () {
          setState(() {
            _isDelivery = isDelivery;
            if (_isDelivery && _useCurrentLocation && _currentPosition == null) {
              _getCurrentLocation();
            }
          });
        },
      ),
    );
  }

  Widget _buildLocationMethodCard(String title, String subtitle, IconData icon, bool useCurrentLocation) {
    final isSelected = _useCurrentLocation == useCurrentLocation;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: AppColors.primary(context).withOpacity(isSelected ? 0.1 : 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary(context) : AppColors.border(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary(context) : Theme.of(context).iconTheme.color),
        title: Text(title, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.primary(context) : AppColors.textColor(context),
        )),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(
          fontSize: 12,
          color: isSelected ? AppColors.primary(context) : AppColors.textColor(context).withOpacity(0.7),
        )),
        trailing: isSelected
            ? _isGettingLocation
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary(context)),
        )
            : Icon(Icons.check_circle, color: AppColors.primary(context))
            : null,
        onTap: () {
          setState(() {
            _useCurrentLocation = useCurrentLocation;
            if (_useCurrentLocation && _currentPosition == null) {
              _getCurrentLocation();
            }
          });
        },
      ),
    );
  }

  Widget _buildProcessingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 8, color: AppColors.primary(context)),
          ),
          const SizedBox(height: 20),
          Text('Processing Payment...', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            'Please wait while we process your ${_selectedPaymentMethod == PaymentMethod.mpesa ? 'M-Pesa' : 'card'} payment',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textColor(context).withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.background(context),
        elevation: 0,
      ),
      body: _isProcessing
          ? _buildProcessingUI()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery/Pickup Option Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.delivery_dining, color: AppColors.primary(context)),
                          const SizedBox(width: 8),
                          Text('Order Type',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDeliveryOptionCard(
                        'Delivery',
                        'Get your food delivered to your location',
                        Icons.delivery_dining,
                        true,
                      ),
                      const SizedBox(height: 16),
                      _buildDeliveryOptionCard(
                        'Pickup',
                        'Come pick up your order at the store',
                        Icons.store,
                        false,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Customer Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: AppColors.primary(context)),
                          const SizedBox(width: 8),
                          Text('Customer Information',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.surfaceVariant(context),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Updated Phone Number Field with Country Code
                      _buildPhoneNumberField(),
                    ],
                  ),
                ),
              ),

              // Delivery Address Section (Only for delivery)
              if (_isDelivery) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: AppColors.primary(context)),
                            const SizedBox(width: 8),
                            Text('Delivery Location',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Location Method Selection
                        Text('Choose how to set your location:',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _buildLocationMethodCard(
                          'Use Current Location',
                          'Automatically detect your current location',
                          Icons.my_location,
                          true,
                        ),
                        const SizedBox(height: 16),
                        _buildLocationMethodCard(
                          'Search Location',
                          'Manually search for your delivery address',
                          Icons.search,
                          false,
                        ),
                        const SizedBox(height: 16),

                        // Address Input Fields
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Address *',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.surfaceVariant(context),
                            suffixIcon: _useCurrentLocation
                                ? (_isGettingLocation
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary(context),
                              ),
                            )
                                : IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _getCurrentLocation,
                            ))
                                : IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _searchLocation,
                            ),
                          ),
                          readOnly: _useCurrentLocation,
                          validator: (value) => value!.isEmpty ? 'Please enter delivery address' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City *',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.surfaceVariant(context),
                          ),
                          validator: (value) => value!.isEmpty ? 'Please enter your city' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _additionalInfoController,
                          decoration: InputDecoration(
                            labelText: 'Additional Info (Optional)',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.surfaceVariant(context),
                            hintText: 'e.g., Apartment number, landmarks, etc.',
                          ),
                          maxLines: 2,
                        ),

                        // Location Status
                        if (_currentPosition != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary(context).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.primary(context), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location set: ${_addressController.text}',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Payment Method Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment, color: AppColors.primary(context)),
                          const SizedBox(width: 8),
                          Text('Payment Method',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentMethodCard(
                        PaymentMethod.mpesa,
                        'M-Pesa',
                        'Pay via M-Pesa STK Push',
                        Icons.phone_android,
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodCard(
                        PaymentMethod.stripe,
                        'Credit/Debit Card',
                        'Pay with Stripe',
                        Icons.credit_card,
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethodCard(
                        PaymentMethod.cash,
                        _isDelivery ? 'Cash on Delivery' : 'Pay at Store',
                        _isDelivery ? 'Pay when you receive your order' : 'Pay when you pick up your order',
                        Icons.money,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Summary',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                      const SizedBox(height: 12),
                      ...Provider.of<CartProvider>(context).items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('${item.name} x${item.quantity}'),
                            ),
                            Text('KSh ${(item.price * item.quantity).toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('Subtotal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                          Text('KSh ${Provider.of<CartProvider>(context).totalAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_isDelivery) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text('Delivery Fee', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                            Text('KSh 100.00'),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        children: [
                          Expanded(child: Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16))),
                          Text(
                            'KSh ${_isDelivery ? (Provider.of<CartProvider>(context).totalAmount + 100).toStringAsFixed(2) : Provider.of<CartProvider>(context).totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text('Processing...', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ],
                  )
                      : Text(
                    _isDelivery ? 'Place Delivery Order' : 'Place Pickup Order',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}