import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:ubmap/constants/app_theme.dart';
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/helpers/distance_utils.dart';
import 'package:ubmap/widgets/carousel_card.dart';
import 'package:ubmap/screens/navigation_screen.dart';
import 'package:ubmap/services/navigation_service.dart';

class UniversityMap extends StatefulWidget {
  const UniversityMap({
    super.key, 
    required this.buildings, 
    this.onMenuPressed,
  });
  
  final List<Map> buildings;
  final VoidCallback? onMenuPressed;

  @override
  State<UniversityMap> createState() => _UniversityMapState();
}

class _UniversityMapState extends State<UniversityMap> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.CircleAnnotationManager? _circleAnnotationManager;
  final NavigationService _navigationService = NavigationService();
  
  List<Map> _filteredBuildings = [];
  List<Map> _buildingData = [];
  int _pageIndex = 0;
  double? _userLat;
  double? _userLng;
  BuildingType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _filteredBuildings = List.from(widget.buildings);
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Get user location
    final position = await _navigationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    }
    
    // Calculate distances using Haversine (instant, no API calls)
    _calculateDistances();
  }

  void _calculateDistances() {
    _buildingData = [];
    
    for (int i = 0; i < _filteredBuildings.length; i++) {
      final building = _filteredBuildings[i];
      final lat = double.parse(building['coordinates']['latitude'].toString().trim());
      final lng = double.parse(building['coordinates']['longitude'].toString().trim());
      
      double distance = 0;
      double duration = 0;
      
      if (_userLat != null && _userLng != null) {
        distance = haversineDistance(_userLat!, _userLng!, lat, lng);
        duration = estimateWalkingMinutes(distance);
      }
      
      _buildingData.add({
        'index': i,
        'distance': distance,
        'duration': duration,
        'lat': lat,
        'lng': lng,
      });
    }
    
    if (mounted) setState(() {});
  }

  void _applyFilter(BuildingType? type) {
    setState(() {
      _selectedFilter = type;
      if (type == null) {
        _filteredBuildings = List.from(widget.buildings);
      } else {
        _filteredBuildings = widget.buildings
            .where((b) => b['type'] == type)
            .toList();
      }
      _pageIndex = 0;
    });
    _calculateDistances();
    
    // Re-add markers for filtered buildings
    if (_mapboxMap != null) {
      _addBuildingMarkers();
    }
  }

  void _startNavigation(int index) {
    if (index >= _filteredBuildings.length) return;
    
    final building = _filteredBuildings[index];
    final lat = double.parse(building['coordinates']['latitude'].toString().trim());
    final lng = double.parse(building['coordinates']['longitude'].toString().trim());
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: building['name'],
        ),
      ),
    );
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Create circle annotation manager for markers FIRST
    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    
    // Add markers immediately after manager is ready
    await _addBuildingMarkers();
  }

  void _onStyleLoaded(mapbox.StyleLoadedEventData data) async {
    if (_mapboxMap == null) return;
    
    // We don't rely only on this for markers anymore because manager might not be ready
    // But we can re-add if needed, checking for manager existence
    if (_circleAnnotationManager != null) {
       await _addBuildingMarkers();
    }
    
    // Enable location component
    _mapboxMap!.location.updateSettings(mapbox.LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));
  }

  Future<void> _addBuildingMarkers() async {
    if (_mapboxMap == null) return;
    
    try {
      // Remove existing markers layer and source
      try {
        await _mapboxMap!.style.removeStyleLayer("building-markers-layer");
        await _mapboxMap!.style.removeStyleSource("building-markers-source");
      } catch (e) {
        // Layer/source doesn't exist yet
      }
      
      // Create GeoJSON features for all buildings with color property
      final features = <Map<String, dynamic>>[];
      
      for (int i = 0; i < _filteredBuildings.length; i++) {
        final building = _filteredBuildings[i];
        final lat = double.parse(building['coordinates']['latitude'].toString().trim());
        final lng = double.parse(building['coordinates']['longitude'].toString().trim());
        
        // Get color based on type
        String colorHex = "#EF4444"; // Default red
        final type = building['type'] as BuildingType?;
        switch (type) {
          case BuildingType.department:
            colorHex = "#1976D2"; // Blue
            break;
          case BuildingType.amphitheatre:
            colorHex = "#7B1FA2"; // Purple
            break;
          case BuildingType.library:
            colorHex = "#2E7D32"; // Green (AppTheme.primary)
            break;
          case BuildingType.admin:
            colorHex = "#F57C00"; // Orange
            break;
          case BuildingType.bloc:
            colorHex = "#00796B"; // Teal
            break;
          case BuildingType.research:
            colorHex = "#303F9F"; // Indigo
            break;
          default:
            colorHex = "#EF4444"; // Red
        }
        
        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [lng, lat],
          },
          "properties": {
            "id": building['id'],
            "name": building['name'],
            "color": colorHex,
          },
        });
      }
      
      final geojsonData = {
        "type": "FeatureCollection",
        "features": features,
      };
      
      // Add GeoJSON source
      await _mapboxMap!.style.addSource(
        mapbox.GeoJsonSource(
          id: "building-markers-source",
          data: jsonEncode(geojsonData),
        ),
      );
      
      // Add circle layer with basic properties first
      await _mapboxMap!.style.addLayer(
        mapbox.CircleLayer(
          id: "building-markers-layer",
          sourceId: "building-markers-source",
          circleRadius: 8.0,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ),
      );
      
      // Apply zoom-based expression for circle-radius using setStyleLayerProperty
      // Markers shrink significantly when zoomed out, disappear at very low zoom
      // Zoom 10 = 0px (invisible), Zoom 12 = 2px (tiny), Zoom 15 = 6px, Zoom 18 = 12px
      await _mapboxMap!.style.setStyleLayerProperty(
        "building-markers-layer",
        "circle-radius",
        '["interpolate", ["linear"], ["zoom"], 10, 0, 12, 2, 14, 4, 16, 8, 18, 12]',
      );
      
      // Also scale stroke width with zoom
      await _mapboxMap!.style.setStyleLayerProperty(
        "building-markers-layer",
        "circle-stroke-width",
        '["interpolate", ["linear"], ["zoom"], 10, 0, 12, 0.5, 14, 1, 16, 1.5, 18, 2]',
      );
      
      // Fade out opacity at low zoom levels for cleaner look
      await _mapboxMap!.style.setStyleLayerProperty(
        "building-markers-layer",
        "circle-opacity",
        '["interpolate", ["linear"], ["zoom"], 10, 0, 12, 0.5, 14, 0.8, 15, 1]',
      );
      
      // Apply data-driven color from the "color" property in GeoJSON
      await _mapboxMap!.style.setStyleLayerProperty(
        "building-markers-layer",
        "circle-color",
        '["get", "color"]',
      );
      
      print("Markers added with aggressive zoom scaling");
    } catch (e) {
      print("Error adding markers with layer: $e");
      // Fallback to annotation manager if layer approach fails
      await _addBuildingMarkersWithAnnotations();
    }
  }
  
  /// Fallback marker implementation using annotations
  Future<void> _addBuildingMarkersWithAnnotations() async {
    if (_circleAnnotationManager == null) return;
    
    // Clear existing markers
    await _circleAnnotationManager!.deleteAll();
    
    for (int i = 0; i < _filteredBuildings.length; i++) {
      final building = _filteredBuildings[i];
      final lat = double.parse(building['coordinates']['latitude'].toString().trim());
      final lng = double.parse(building['coordinates']['longitude'].toString().trim());
      
      // Color based on type
      int color = Colors.red.value;
      final type = building['type'] as BuildingType?;
      switch (type) {
        case BuildingType.department:
          color = const Color(0xFF1976D2).value;
          break;
        case BuildingType.amphitheatre:
          color = const Color(0xFF7B1FA2).value;
          break;
        case BuildingType.library:
          color = const Color(0xFF388E3C).value;
          break;
        case BuildingType.admin:
          color = const Color(0xFFF57C00).value;
          break;
        case BuildingType.bloc:
          color = const Color(0xFF00796B).value;
          break;
        case BuildingType.research:
          color = const Color(0xFF303F9F).value;
          break;
        default:
          color = const Color(0xFFEF4444).value;
      }
      
      await _circleAnnotationManager!.create(
        mapbox.CircleAnnotationOptions(
          geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          circleRadius: 8.0,
          circleColor: color,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 2.0,
        ),
      );
    }
  }

  void _onCarouselPageChanged(int index, CarouselPageChangedReason reason) {
    if (index >= _buildingData.length) return;
    
    setState(() {
      _pageIndex = index;
    });
    
    final data = _buildingData[index];
    
    _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(data['lng'], data['lat'])),
        zoom: 17,
      ),
      mapbox.MapAnimationOptions(duration: 500),
    );
  }

  void _centerOnUser() async {
    final position = await _navigationService.getCurrentPosition();
    if (position != null && _mapboxMap != null) {
      _mapboxMap!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude)),
          zoom: 16,
        ),
        mapbox.MapAnimationOptions(duration: 500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get initial camera center
    mapbox.Position initialCenter = mapbox.Position(7.718, 36.812);
    if (_filteredBuildings.isNotEmpty) {
      final firstBuilding = _filteredBuildings[0];
      final lat = double.parse(firstBuilding['coordinates']['latitude'].toString().trim());
      final lng = double.parse(firstBuilding['coordinates']['longitude'].toString().trim());
      initialCenter = mapbox.Position(lng, lat);
    }
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
        title: Row(
          children: [
            const Icon(Icons.map, color: AppTheme.primary, size: 24),
            const SizedBox(width: AppTheme.spacingSm),
            const Text('Campus Map', style: AppTheme.headingMedium),
          ],
        ),
        backgroundColor: AppTheme.bgSurface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                border: Border(
                  bottom: BorderSide(color: AppTheme.divider, width: 1),
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                children: [
                  _buildFilterChip(null, 'All'),
                  _buildFilterChip(BuildingType.department, 'Depts'),
                  _buildFilterChip(BuildingType.amphitheatre, 'Amphis'),
                  _buildFilterChip(BuildingType.library, 'Libraries'),
                  _buildFilterChip(BuildingType.admin, 'Admin'),
                  _buildFilterChip(BuildingType.bloc, 'Blocs'),
                  _buildFilterChip(BuildingType.research, 'Research'),
                ],
              ),
            ),
            // Map
            Expanded(
              child: mapbox.MapWidget(
                textureView: true,
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: _onStyleLoaded,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(coordinates: initialCenter),
                  zoom: 15,
                ),
                styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
              ),
            ),
            // Carousel
            if (_filteredBuildings.isNotEmpty && _buildingData.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CarouselSlider.builder(
                  itemCount: _filteredBuildings.length,
                  itemBuilder: (context, index, realIndex) {
                    if (index >= _buildingData.length) return const SizedBox();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _startNavigation(index);
                      },
                      child: carouselCard(
                        _filteredBuildings[index],
                        _buildingData[index]['distance'] / 1000, // km
                        _buildingData[index]['duration'],
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 96, // Matches card height (80) + vertical margins (16)
                    viewportFraction: 0.88,
                    initialPage: 0,
                    enableInfiniteScroll: false,
                    onPageChanged: _onCarouselPageChanged,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _centerOnUser();
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.my_location, color: AppTheme.textOnPrimary),
      ),
    );
  }

  Widget _buildFilterChip(BuildingType? type, String label) {
    final isSelected = _selectedFilter == type ||
        (type == null && _selectedFilter == null);
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _applyFilter(type);
          },
          borderRadius: AppTheme.borderRadiusFull,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: AppTheme.chipDecoration(isSelected: isSelected),
            child: Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
