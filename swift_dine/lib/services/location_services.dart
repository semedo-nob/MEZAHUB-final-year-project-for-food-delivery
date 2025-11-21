import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStream;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _geolocator.isLocationServiceEnabled();
  }

  // Check and request location permissions
  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await _geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return permission;
  }

  // Get current position once - CORRECTED
  Future<Position> getCurrentPosition() async {
    await checkAndRequestPermission();

    return await _geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  // Start continuous location tracking
  Future<void> startLocationTracking() async {
    await checkAndRequestPermission();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = _geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        _locationController.add(position);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Unable to get address';
    }
  }

  // Calculate distance between two points in meters
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Calculate bearing between two points
  double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}