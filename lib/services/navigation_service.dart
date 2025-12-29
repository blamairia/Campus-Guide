import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../models/navigation_models.dart';

class NavigationService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  
  String get _accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Fetches a route from Mapbox Directions API
  Future<NavigationRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'walking',
  }) async {
    final url = '$_baseUrl/$profile/$startLng,$startLat;$endLng,$endLat'
        '?alternatives=false'
        '&annotations=distance,duration'
        '&geometries=geojson'
        '&language=en'
        '&overview=full'
        '&steps=true'
        '&voice_instructions=true'
        '&banner_instructions=true'
        '&access_token=$_accessToken';

    try {
      final response = await _dio.get(url);
      if (response.data['routes'] != null && 
          (response.data['routes'] as List).isNotEmpty) {
        return NavigationRoute.fromJson(response.data['routes'][0]);
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return null;
  }

  /// Start streaming location updates
  Stream<Position> startLocationTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    );
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;
      
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }
}
