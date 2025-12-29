import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/navigation_models.dart';
import 'routing_provider.dart';

/// OpenRouteService routing provider
/// Free tier: 2,000 requests/day
/// Get API key at: https://openrouteservice.org/dev/#/signup
class ORSRoutingProvider implements RoutingProvider {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.openrouteservice.org/v2/directions';
  
  String get _apiKey => dotenv.env['ORS_API_KEY'] ?? '';

  @override
  String get name => 'OpenRouteService';

  @override
  String mapProfile(String profile) {
    // ORS uses: foot-walking, cycling-regular, driving-car
    switch (profile) {
      case 'walking':
      case 'foot-walking':
        return 'foot-walking';
      case 'cycling':
      case 'cycling-regular':
        return 'cycling-regular';
      case 'driving':
      case 'driving-car':
        return 'driving-car';
      default:
        return 'foot-walking';
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
    final url = '$_baseUrl/$mappedProfile/geojson';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': _apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'coordinates': [
            [startLng, startLat],
            [endLng, endLat],
          ],
          'instructions': true,
          'language': 'en',
        },
      );

      if (response.data['features'] != null &&
          (response.data['features'] as List).isNotEmpty) {
        return _parseORSResponse(response.data);
      }
    } catch (e) {
      print('[$name] Error fetching route: $e');
    }
    return null;
  }

  /// Parse ORS GeoJSON response to NavigationRoute
  NavigationRoute? _parseORSResponse(Map<String, dynamic> data) {
    try {
      final feature = data['features'][0];
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      final segments = properties['segments'] as List?;

      // Build steps from segments
      final steps = <NavigationStep>[];
      if (segments != null && segments.isNotEmpty) {
        for (final segment in segments) {
          final segmentSteps = segment['steps'] as List? ?? [];
          for (final step in segmentSteps) {
            // Get waypoints for geometry
            final wayPoints = step['way_points'] as List? ?? [0, 0];
            final startIdx = wayPoints.isNotEmpty ? wayPoints[0] as int : 0;
            final endIdx = wayPoints.length > 1 ? wayPoints[1] as int : startIdx;
            
            // Extract step geometry from route coordinates
            final routeCoords = geometry['coordinates'] as List? ?? [];
            final stepGeometry = <List<double>>[];
            for (var i = startIdx; i <= endIdx && i < routeCoords.length; i++) {
              final coord = routeCoords[i];
              if (coord is List && coord.length >= 2) {
                stepGeometry.add([
                  (coord[0] as num).toDouble(),
                  (coord[1] as num).toDouble(),
                ]);
              }
            }
            
            steps.add(NavigationStep(
              instruction: step['instruction']?.toString() ?? '',
              maneuver: _mapORSManeuver(step['type']),
              distance: (step['distance'] ?? 0).toDouble(),
              duration: (step['duration'] ?? 0).toDouble(),
              geometry: stepGeometry,
            ));
          }
        }
      }

      return NavigationRoute(
        distance: (properties['summary']?['distance'] ?? 0).toDouble(),
        duration: (properties['summary']?['duration'] ?? 0).toDouble(),
        geometry: geometry['coordinates'] ?? [],
        steps: steps,
      );
    } catch (e) {
      print('[ORS] Error parsing response: $e');
      return null;
    }
  }

  String _mapORSManeuver(int? type) {
    // ORS maneuver types: https://giscience.github.io/openrouteservice/documentation/routing
    switch (type) {
      case 0: return 'turn left';
      case 1: return 'turn right';
      case 2: return 'turn sharp left';
      case 3: return 'turn sharp right';
      case 4: return 'turn slight left';
      case 5: return 'turn slight right';
      case 6: return 'continue straight';
      case 10: return 'arrive';
      case 11: return 'depart';
      default: return 'continue';
    }
  }
}
