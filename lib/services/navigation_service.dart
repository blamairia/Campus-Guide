import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../models/navigation_models.dart';
import 'routing_provider.dart';
import 'mapbox_routing_provider.dart';
import 'ors_routing_provider.dart';

/// Navigation service with pluggable routing provider support
/// Supports: Mapbox (default), OpenRouteService
class NavigationService {
  late final RoutingProvider _routingProvider;
  
  NavigationService({RoutingProvider? provider}) {
    if (provider != null) {
      _routingProvider = provider;
    } else {
      // Auto-select based on env config
      final providerName = dotenv.env['ROUTING_PROVIDER']?.toLowerCase() ?? 'mapbox';
      _routingProvider = _createProvider(providerName);
    }
  }
  
  /// Create provider by name
  RoutingProvider _createProvider(String name) {
    switch (name) {
      case 'ors':
      case 'openrouteservice':
        return ORSRoutingProvider();
      case 'mapbox':
      default:
        return MapboxRoutingProvider();
    }
  }
  
  /// Get current provider name
  String get providerName => _routingProvider.name;

  /// Fetches a route using the configured provider
  Future<NavigationRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'walking',
  }) async {
    return _routingProvider.getRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      profile: profile,
    );
  }
  
  /// Fetches route with fallback to alternate provider
  Future<NavigationRoute?> getRouteWithFallback({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'walking',
  }) async {
    // Try primary provider
    var route = await getRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      profile: profile,
    );
    
    if (route != null) return route;
    
    // Fallback to alternate provider
    final fallbackProvider = _routingProvider is MapboxRoutingProvider
        ? ORSRoutingProvider()
        : MapboxRoutingProvider();
    
    print('[Navigation] Primary failed, trying ${fallbackProvider.name}');
    
    return fallbackProvider.getRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      profile: profile,
    );
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
