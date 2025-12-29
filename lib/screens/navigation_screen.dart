import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../models/navigation_models.dart';
import '../services/navigation_service.dart';

class NavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;

  const NavigationScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  mapbox.MapboxMap? _mapboxMap;
  final NavigationService _navigationService = NavigationService();
  final FlutterTts _tts = FlutterTts();
  
  NavigationRoute? _route;
  StreamSubscription<geo.Position>? _locationSubscription;
  geo.Position? _currentPosition;
  
  int _currentStepIndex = 0;
  double _distanceRemaining = 0;
  double _durationRemaining = 0;
  bool _isNavigating = false;
  bool _isLoading = true;
  String _currentInstruction = "Calculating route...";

  @override
  void initState() {
    super.initState();
    _initTts();
    _startNavigation();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  Future<void> _startNavigation() async {
    // Get current position
    final position = await _navigationService.getCurrentPosition();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Please enable GPS.')),
        );
      }
      return;
    }
    
    setState(() {
      _currentPosition = position;
    });

    // Fetch route
    final route = await _navigationService.getRoute(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: widget.destinationLat,
      endLng: widget.destinationLng,
    );

    if (route != null && mounted) {
      setState(() {
        _route = route;
        _distanceRemaining = route.distance;
        _durationRemaining = route.duration;
        _currentInstruction = route.steps.isNotEmpty 
            ? route.steps[0].instruction 
            : "Head towards ${widget.destinationName}";
        _isNavigating = true;
        _isLoading = false;
      });

      // Speak first instruction
      await _tts.speak(_currentInstruction);

      // Draw route on map after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _drawRouteOnMap();
      });

      // Start location tracking
      _locationSubscription = _navigationService.startLocationTracking().listen(_onLocationUpdate);
    } else {
      setState(() {
        _isLoading = false;
        _currentInstruction = "Could not calculate route";
      });
    }
  }

  void _onLocationUpdate(geo.Position position) {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = position;
    });

    if (_route == null) return;

    // Update camera to follow user with bearing
    _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude)),
        zoom: 18,
        bearing: position.heading,
        pitch: 60,
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );

    // Check if we need to advance to next step
    _updateNavigationProgress(position);
  }

  void _updateNavigationProgress(geo.Position position) {
    if (_route == null || _route!.steps.isEmpty) return;

    // Calculate distance to destination
    final distanceToDestination = geo.Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    // Check if arrived (within 30 meters)
    if (distanceToDestination < 30) {
      _onArrival();
      return;
    }

    // Check if we need to advance to next step
    if (_currentStepIndex < _route!.steps.length) {
      final currentStep = _route!.steps[_currentStepIndex];
      
      if (currentStep.geometry.isNotEmpty) {
        final stepEnd = currentStep.geometry.last;
        final distanceToStep = geo.Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          stepEnd[1],
          stepEnd[0],
        );

        // If within 20 meters of step end, advance to next step
        if (distanceToStep < 20 && _currentStepIndex < _route!.steps.length - 1) {
          setState(() {
            _currentStepIndex++;
            _currentInstruction = _route!.steps[_currentStepIndex].instruction;
          });
          _tts.speak(_currentInstruction);
        }
      }
    }

    setState(() {
      _distanceRemaining = distanceToDestination;
      _durationRemaining = distanceToDestination / 1.4; // Approx walking speed
    });
  }

  void _onArrival() {
    _tts.speak("You have arrived at ${widget.destinationName}");
    _locationSubscription?.cancel();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text("You've Arrived!"),
          ],
        ),
        content: Text("Welcome to ${widget.destinationName}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _drawRouteOnMap() async {
    if (_route == null || _mapboxMap == null) return;

    try {
      final lineStringData = {
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": _route!.geometry,
        },
        "properties": {}
      };

      // Check if source already exists and remove it
      try {
        await _mapboxMap!.style.removeStyleLayer("route-layer");
        await _mapboxMap!.style.removeStyleSource("route-source");
      } catch (e) {
        // Source doesn't exist, which is fine
      }

      await _mapboxMap!.style.addSource(
        mapbox.GeoJsonSource(id: "route-source", data: jsonEncode(lineStringData)),
      );

      await _mapboxMap!.style.addLayer(
        mapbox.LineLayer(
          id: "route-layer",
          sourceId: "route-source",
          lineColor: Colors.blue.value,
          lineWidth: 6.0,
          lineCap: mapbox.LineCap.ROUND,
          lineJoin: mapbox.LineJoin.ROUND,
        ),
      );
    } catch (e) {
      print('Error drawing route: $e');
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    
    // Center on current position or destination
    if (_currentPosition != null) {
      mapboxMap.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          )),
          zoom: 16,
          pitch: 45,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    }
  }

  void _onStyleLoaded(mapbox.StyleLoadedEventData data) {
    if (_route != null) {
      _drawRouteOnMap();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          mapbox.MapWidget(
            textureView: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            cameraOptions: mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(
                widget.destinationLng,
                widget.destinationLat,
              )),
              zoom: 16,
              pitch: 45,
            ),
            styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Calculating route...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Navigation instruction banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _getManeuverIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentInstruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "To: ${widget.destinationName}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      icon: Icons.straighten,
                      value: _formatDistance(_distanceRemaining),
                      label: "Distance",
                    ),
                    _buildInfoItem(
                      icon: Icons.access_time,
                      value: _formatDuration(_durationRemaining),
                      label: "Time",
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Exit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getManeuverIcon() {
    IconData icon = Icons.arrow_upward;
    if (_currentInstruction.toLowerCase().contains('left')) {
      icon = Icons.turn_left;
    } else if (_currentInstruction.toLowerCase().contains('right')) {
      icon = Icons.turn_right;
    } else if (_currentInstruction.toLowerCase().contains('arrive')) {
      icon = Icons.flag;
    }
    return Icon(icon, color: Colors.white, size: 32);
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.toInt()} m";
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return "${hours}h ${mins}m";
    }
    return "$minutes min";
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
