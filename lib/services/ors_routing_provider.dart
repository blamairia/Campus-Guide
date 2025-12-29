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

    print('[$name] Requesting route: ($startLat, $startLng) -> ($endLat, $endLng)');
    print('[$name] URL: $url');
    print('[$name] Profile: $mappedProfile');
    print('[$name] API Key: ${_apiKey.isNotEmpty ? "SET (${_apiKey.length} chars)" : "MISSING!"}');

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

      print('[$name] Response status: ${response.statusCode}');
      print('[$name] Response type: ${response.data.runtimeType}');
      
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        print('[$name] Has features: ${data.containsKey('features')}');
        
        if (data['features'] != null) {
          final features = data['features'] as List;
          print('[$name] Features count: ${features.length}');
          
          if (features.isNotEmpty) {
            return _parseORSResponse(data);
          }
        } else if (data['error'] != null) {
          print('[$name] API Error: ${data['error']}');
        }
      }
    } on DioException catch (e) {
      print('[$name] DioException: ${e.type}');
      print('[$name] Status: ${e.response?.statusCode}');
      print('[$name] Response: ${e.response?.data}');
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
      
      // Parse route geometry coordinates
      final rawCoords = geometry['coordinates'] as List? ?? [];
      final routeGeometry = <List<double>>[];
      for (final coord in rawCoords) {
        if (coord is List && coord.length >= 2) {
          routeGeometry.add([
            (coord[0] as num).toDouble(),
            (coord[1] as num).toDouble(),
          ]);
        }
      }
      
      print('[ORS] Route has ${routeGeometry.length} coordinates');

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
            final stepGeometry = <List<double>>[];
            for (var i = startIdx; i <= endIdx && i < routeGeometry.length; i++) {
              stepGeometry.add(routeGeometry[i]);
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
      
      print('[ORS] Parsed ${steps.length} navigation steps');

      final route = NavigationRoute(
        distance: (properties['summary']?['distance'] ?? 0).toDouble(),
        duration: (properties['summary']?['duration'] ?? 0).toDouble(),
        geometry: routeGeometry,
        steps: steps,
      );
      
      print('[ORS] Route: ${route.distance}m, ${route.duration}s');
      return route;
    } catch (e, stackTrace) {
      print('[ORS] Error parsing response: $e');
      print('[ORS] Stack: $stackTrace');
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
