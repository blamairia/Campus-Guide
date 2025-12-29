import 'dart:math';

/// Haversine formula to calculate distance between two coordinates
/// Returns distance in meters
double haversineDistance(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  const earthRadius = 6371000; // meters
  
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * pi / 180;

/// Estimate walking time based on distance
/// Assumes average walking speed of 5 km/h (83.33 m/min)
double estimateWalkingMinutes(double distanceMeters) {
  const walkingSpeedMetersPerMin = 83.33;
  return distanceMeters / walkingSpeedMetersPerMin;
}

/// Format distance for display
String formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '${meters.toInt()} m';
}

/// Format duration for display
String formatDuration(double minutes) {
  if (minutes >= 60) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '${hours}h ${mins}m';
  }
  return '${minutes.round()} min';
}
