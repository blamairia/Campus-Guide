import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/navigation_models.dart';
import 'routing_provider.dart';

/// Mapbox Directions API routing provider
class MapboxRoutingProvider implements RoutingProvider {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  
  String get _accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  @override
  String get name => 'Mapbox';

  @override
  String mapProfile(String profile) {
    // Mapbox uses: walking, cycling, driving
    switch (profile) {
      case 'walking':
      case 'foot-walking':
        return 'walking';
      case 'cycling':
      case 'cycling-regular':
        return 'cycling';
      case 'driving':
      case 'driving-car':
        return 'driving';
      default:
        return 'walking';
    }
  }

  @override
  Future<NavigationRoute?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'walking',
  }) async {
    final mappedProfile = mapProfile(profile);
    final url = '$_baseUrl/$mappedProfile/$startLng,$startLat;$endLng,$endLat'
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
      print('[$name] Error fetching route: $e');
    }
    return null;
  }
}
