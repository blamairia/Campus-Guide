import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
  bool _isLoading = true;
  String _currentInstruction = "Calculating route...";
  String _selectedProfile = 'walking'; // walking, cycling, driving

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
    setState(() {
      _isLoading = true;
      _currentInstruction = "Calculating ${_selectedProfile} route...";
    });

    // Get current position
    geo.Position? position = _currentPosition;
    if (position == null) {
      position = await _navigationService.getCurrentPosition();
    }

    if (position == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentInstruction = "Could not get location.";
        });
      }
      return;
    }
    
    setState(() {
      _currentPosition = position;
    });

    // Update puck for the selected profile
    _updateLocationPuck();

    // Fetch route with selected profile
    final route = await _navigationService.getRoute(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: widget.destinationLat,
      endLng: widget.destinationLng,
      profile: _modeToProfile(_selectedProfile),
    );

    if (route != null && mounted) {
      setState(() {
        _route = route;
        _distanceRemaining = route.distance;
        _durationRemaining = route.duration;
        _currentInstruction = route.steps.isNotEmpty 
            ? route.steps[0].instruction 
            : "Head towards ${widget.destinationName}";
        _isLoading = false;
        _currentStepIndex = 0;
      });

      // Speak first instruction
      await _tts.speak(_currentInstruction);

      // Draw route on map after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _drawRouteOnMap();
        _fitRouteBounds();
      });

      // Start location tracking if not already started
      if (_locationSubscription == null) {
        _locationSubscription = _navigationService.startLocationTracking().listen(_onLocationUpdate);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentInstruction = "Could not calculate route";
        });
      }
    }
  }

  String _modeToProfile(String mode) {
    if (mode == 'driving') return 'driving';
    if (mode == 'cycling') return 'cycling';
    return 'walking';
  }

  Future<void> _updateLocationPuck() async {
    if (_mapboxMap == null) return;

    // Google Maps-style location puck:
    // - Blue dot with white border
    // - Pulsing ring effect
    // - Accuracy ring showing GPS precision
    // - Bearing cone showing direction
    
    const int googleBlue = 0xFF4285F4; // Google's signature blue
    const int googleBluePulse = 0xFF8AB4F8; // Lighter blue for pulse
    const int googleBlueLight = 0x334285F4; // Transparent blue for accuracy
    
    try {
      await _mapboxMap?.location.updateSettings(
        mapbox.LocationComponentSettings(
          enabled: true,
          
          // Pulsing effect (the expanding ring animation)
          pulsingEnabled: true,
          pulsingColor: googleBluePulse,
          pulsingMaxRadius: 80.0,
          
          // Accuracy ring (shows GPS precision)
          showAccuracyRing: true,
          accuracyRingColor: googleBlueLight,
          accuracyRingBorderColor: googleBlue,
          
          // Bearing (direction cone/arrow)
          puckBearingEnabled: true,
          puckBearing: mapbox.PuckBearing.HEADING,
          
          // Use default Mapbox 2D puck (clean blue dot like Google)
          // No custom image = uses Mapbox's built-in blue dot
        ),
      );
    } catch (e) {
      print("Error setting location puck: $e");
    }
  }

  Future<Uint8List> _createPuckImage(IconData icon, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = const Size(128, 128);
    
    // Draw background circle
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, paint);
    
    // Draw border
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, paint);

    // Draw Icon using TextPainter
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 80,
        fontFamily: icon.fontFamily,
        color: color,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onLocationUpdate(geo.Position position) {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = position;
    });

    if (_route == null) return;

    // Advance progress
    _updateNavigationProgress(position);
  }

  void _recenterCamera() {
    if (_currentPosition != null && _mapboxMap != null) {
      _mapboxMap?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          zoom: 17,
          bearing: _currentPosition!.heading,
          pitch: 60,
        ),
        mapbox.MapAnimationOptions(duration: 800),
      );
    }
  }

  void _fitRouteBounds() {
    if (_route == null || _mapboxMap == null) return;
    _recenterCamera();
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

    // Check if arrived (within 20 meters)
    if (distanceToDestination < 20) {
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
      // Adjust duration estimate based on mode roughly
      double speed = 1.4; // walking m/s
      if (_selectedProfile == 'cycling') speed = 5.0;
      if (_selectedProfile == 'driving') speed = 10.0;
      
      _durationRemaining = distanceToDestination / speed;
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
        // Source doesn't exist
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
    // Initial update
    _updateLocationPuck();
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

  void _changeProfile(String newProfile) {
    if (_selectedProfile == newProfile) return;
    setState(() {
      _selectedProfile = newProfile;
    });
    _startNavigation(); // Refetch route
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

          // Top Panel: Instruction + Transport Modes
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instruction Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                      ],
                    ),
                    child: Row(
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
                  ),

                  // Mode Selector
                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                         BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildModeButton(Icons.directions_walk, 'walking'),
                        _buildModeButton(Icons.directions_bike, 'cycling'),
                        _buildModeButton(Icons.directions_car, 'driving'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Control Buttons (Recenter / Overview)
          Positioned(
            right: 16,
            bottom: 180, // Above the bottom panel
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'overview_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.map, color: Colors.blueGrey),
                  onPressed: () {
                     _mapboxMap?.flyTo(
                       mapbox.CameraOptions(
                         center: mapbox.Point(coordinates: mapbox.Position(widget.destinationLng, widget.destinationLat)),
                         zoom: 14,
                         pitch: 0,
                         bearing: 0,
                       ),
                       mapbox.MapAnimationOptions(duration: 500)
                     );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: _recenterCamera,
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // Bottom Info Panel
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
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5)),
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

  Widget _buildModeButton(IconData icon, String mode) {
    final isSelected = _selectedProfile == mode;
    return GestureDetector(
      onTap: () => _changeProfile(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.green.shade800 : Colors.grey,
          size: 20,
        ),
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
