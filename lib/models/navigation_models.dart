class NavigationStep {
  final String instruction;
  final String maneuver;
  final double distance;
  final double duration;
  final List<List<double>> geometry;

  NavigationStep({
    required this.instruction,
    required this.maneuver,
    required this.distance,
    required this.duration,
    required this.geometry,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    final maneuverData = json['maneuver'] as Map<String, dynamic>? ?? {};
    final geometryData = json['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geometryData['coordinates'] as List? ?? [];
    
    return NavigationStep(
      instruction: maneuverData['instruction']?.toString() ?? '',
      maneuver: maneuverData['type']?.toString() ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      geometry: coords
          .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()])
          .toList(),
    );
  }
}

class NavigationRoute {
  final double distance;
  final double duration;
  final List<List<double>> geometry;
  final List<NavigationStep> steps;

  NavigationRoute({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.steps,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    final geometryData = json['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geometryData['coordinates'] as List? ?? [];
    final legs = json['legs'] as List? ?? [];
    final allSteps = <NavigationStep>[];
    
    for (var leg in legs) {
      final legSteps = leg['steps'] as List? ?? [];
      for (var step in legSteps) {
        allSteps.add(NavigationStep.fromJson(step));
      }
    }

    return NavigationRoute(
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      geometry: coords.map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()]).toList(),
      steps: allSteps,
    );
  }
}
