import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  final String apiKey;
  final Dio _dio = Dio();

  DirectionsService({required this.apiKey});

  Future<Directions?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        return Directions.fromMap(response.data);
      }
    } catch (e) {
      print('Directions API error: $e');
    }
    return null;
  }

  List<LatLng> decodePolyline(String encodedPolyline) {
    final PolylinePoints polylinePoints = PolylinePoints(apiKey: '');
    final List<PointLatLng> result = PolylinePoints.decodePolyline(encodedPolyline);
    return result.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  // Calculate distance between two points in meters
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

class Directions {
  final List<LatLng> polylinePoints;
  final int distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;

  Directions({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
  });

  factory Directions.fromMap(Map<String, dynamic> map) {
    if (map['status'] != 'OK') {
      throw Exception('Directions API returned status: ${map['status']}');
    }

    final data = map['routes'][0];
    final legs = data['legs'][0];
    final distance = legs['distance'];
    final duration = legs['duration'];
    final overviewPolyline = data['overview_polyline']['points'];

    // Create a temporary service instance to decode polyline
    final tempService = DirectionsService(apiKey: 'AIzaSyDOYi-TCfyS-rXti6SvQmQkvmMzfzgY9Lc');
    final polylinePoints = tempService.decodePolyline(overviewPolyline);

    return Directions(
      polylinePoints: polylinePoints,
      distanceMeters: distance['value'],
      durationSeconds: duration['value'],
      distanceText: distance['text'],
      durationText: duration['text'],
    );
  }
}