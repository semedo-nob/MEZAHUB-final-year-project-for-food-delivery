import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swift_dine/model/order.dart';
import 'package:swift_dine/theme/app_colors.dart';
import 'package:swift_dine/services/firebase_notification_service.dart';
import 'package:swift_dine/services/order_notification_manager.dart';

class LiveTrackingScreen extends StatefulWidget {
  final Order order;

  const LiveTrackingScreen({super.key, required this.order});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _driverPosition;
  LatLng? _restaurantPosition;
  LatLng? _customerPosition;

  String _eta = 'Calculating...';
  double _progress = 0.0;

  // Mock driver movement simulation
  Timer? _driverTimer;
  int _simulationStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _startDriverSimulation();
    _startOrderTracking();
  }

  Future<void> _startOrderTracking() async {
    await FirebaseNotificationService.subscribeToOrder(widget.order.id);
    await OrderNotificationManager.startOrderTracking(widget.order);
  }

  void _initializeTracking() {
    // Set restaurant position (fixed)
    _restaurantPosition = const LatLng(-1.2921, 36.8219);

    // Set customer position from order
    _customerPosition = LatLng(
      widget.order.deliveryAddress.lat,
      widget.order.deliveryAddress.lng,
    );

    // Set initial driver position (start from restaurant)
    _driverPosition = _restaurantPosition;

    _updateMarkers();
    _updatePolylines();
    _calculateProgress();
  }

  void _startDriverSimulation() {
    _driverTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_driverPosition != null && _customerPosition != null) {
        _simulateDriverMovement();
      }
    });
  }

  void _simulateDriverMovement() {
    if (_driverPosition == null || _customerPosition == null) return;

    setState(() {
      _simulationStep++;

      final double progress = min(1.0, _simulationStep / 10);
      _driverPosition = LatLng(
        _restaurantPosition!.latitude + (_customerPosition!.latitude - _restaurantPosition!.latitude) * progress,
        _restaurantPosition!.longitude + (_customerPosition!.longitude - _restaurantPosition!.longitude) * progress,
      );

      _updateMarkers();
      _updatePolylines();
      _calculateProgress();
      _updateETA();

      if (_simulationStep == 5) {
        _sendProgressNotification('Your driver is halfway there! 🚗');
      } else if (_simulationStep == 8) {
        _sendProgressNotification('Your driver is almost there! 🏠');
      }
    });

    if (_simulationStep >= 10) {
      _driverTimer?.cancel();
      _sendDeliveryCompleteNotification();
      _stopOrderTracking();
    }
  }

  Future<void> _sendProgressNotification(String message) async {
    print('Progress notification: $message');
  }

  Future<void> _sendDeliveryCompleteNotification() async {
    print('Delivery complete notification for order: ${widget.order.id}');
  }

  Future<void> _stopOrderTracking() async {
    await OrderNotificationManager.stopOrderTracking(widget.order);
  }

  void _updateMarkers() {
    _markers.clear();

    if (_restaurantPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: _restaurantPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (_customerPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_driverPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
  }

  void _updatePolylines() {
    _polylines.clear();

    if (_driverPosition != null && _customerPosition != null && _restaurantPosition != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppColors.primary(context),
          width: 4,
          points: [_restaurantPosition!, _driverPosition!, _customerPosition!],
        ),
      );
    }
  }

  void _calculateProgress() {
    if (_driverPosition == null || _restaurantPosition == null || _customerPosition == null) {
      setState(() => _progress = 0.0);
      return;
    }

    final totalDistance = _calculateDistance(
      _restaurantPosition!.latitude,
      _restaurantPosition!.longitude,
      _customerPosition!.latitude,
      _customerPosition!.longitude,
    );

    final completedDistance = _calculateDistance(
      _restaurantPosition!.latitude,
      _restaurantPosition!.longitude,
      _driverPosition!.latitude,
      _driverPosition!.longitude,
    );

    if (totalDistance > 0) {
      setState(() {
        _progress = (completedDistance / totalDistance).clamp(0.0, 1.0);
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void _updateETA() {
    if (_driverPosition != null && _customerPosition != null) {
      final remainingDistance = _calculateDistance(
        _driverPosition!.latitude,
        _driverPosition!.longitude,
        _customerPosition!.latitude,
        _customerPosition!.longitude,
      );
      final remainingTimeMinutes = (remainingDistance / 8333.33 * 60).toInt();
      setState(() {
        _eta = '${max(1, remainingTimeMinutes)} min';
      });
    }
  }

  void _closeTracking() {
    _stopOrderTracking();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _driverTimer?.cancel();
    _stopOrderTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = _progress.isNaN ? 0.0 : _progress;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              // Map controller is available if needed for future features
            },
            initialCameraPosition: CameraPosition(
              target: _restaurantPosition ?? const LatLng(-1.2921, 36.8219),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _circleIconButton(
                    context,
                    icon: Icons.arrow_back,
                    onTap: _closeTracking,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Track your order',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.18,
            maxChildSize: 0.55,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary(context).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary(context).withOpacity(0.2),
                          child: Icon(Icons.delivery_dining, color: AppColors.primary(context)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.deliveryAddress.fullName,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.order.deliveryAddress.phone,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _circleIconButton(context, icon: Icons.chat_bubble_outline, onTap: () {}),
                        const SizedBox(width: 8),
                        _circleIconButton(context, icon: Icons.phone, onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${widget.order.id}',
                              style: GoogleFonts.poppins(
                                color: AppColors.textColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pickup: ${widget.order.restaurant}',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary(context).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: AppColors.primary(context)),
                              const SizedBox(width: 6),
                              Text(
                                _eta,
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Deliver To',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order.deliveryAddress.address,
                      style: GoogleFonts.poppins(
                        color: AppColors.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: AppColors.onPrimary(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Live Tracking',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Driver is ${((1 - safeProgress) * _calculateDistance(
                          _restaurantPosition?.latitude ?? 0,
                          _restaurantPosition?.longitude ?? 0,
                          _customerPosition?.latitude ?? 0,
                          _customerPosition?.longitude ?? 0,
                        ) / 1000).toStringAsFixed(1)} km away",
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textColor(context),
        ),
      ),
    );
  }
}