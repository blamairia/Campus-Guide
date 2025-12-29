import '../models/navigation_models.dart';

/// Abstract interface for routing providers
/// Allows switching between Mapbox, OpenRouteService, or other APIs
abstract class RoutingProvider {
  /// Provider name for display/logging
  String get name;
  
  /// Get a route between two points
  Future<NavigationRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'walking',
  });
  
  /// Convert generic profile to provider-specific profile
  String mapProfile(String profile);
}

/// Supported routing providers
enum RoutingProviderType {
  mapbox,
  openRouteService,
}
