import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/helpers/distance_utils.dart';
import 'package:ubmap/widgets/carousel_card.dart';
import 'package:ubmap/screens/navigation_screen.dart';
import 'package:ubmap/services/navigation_service.dart';

class UniversityMap extends StatefulWidget {
  const UniversityMap({super.key, required this.buildings});
  final List<Map> buildings;

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
    
    // Create circle annotation manager for markers
    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
  }

  void _onStyleLoaded(mapbox.StyleLoadedEventData data) async {
    if (_mapboxMap == null) return;
    
    // Add building markers
    await _addBuildingMarkers();
    
    // Enable location component
    _mapboxMap!.location.updateSettings(mapbox.LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));
  }

  Future<void> _addBuildingMarkers() async {
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
          color = Colors.blue.value;
          break;
        case BuildingType.amphitheatre:
          color = Colors.purple.value;
          break;
        case BuildingType.library:
          color = Colors.green.value;
          break;
        case BuildingType.admin:
          color = Colors.orange.value;
          break;
        case BuildingType.bloc:
          color = Colors.teal.value;
          break;
        case BuildingType.research:
          color = Colors.indigo.value;
          break;
        default:
          color = Colors.red.value;
      }
      
      await _circleAnnotationManager!.create(
        mapbox.CircleAnnotationOptions(
          geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          circleRadius: 10.0,
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
        title: const Text('Campus Map'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            Container(
              height: 50,
              color: Colors.green.shade700,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                color: Colors.grey.shade900,
                child: CarouselSlider.builder(
                  itemCount: _filteredBuildings.length,
                  itemBuilder: (context, index, realIndex) {
                    if (index >= _buildingData.length) return const SizedBox();
                    return GestureDetector(
                      onTap: () => _startNavigation(index),
                      child: carouselCard(
                        _filteredBuildings[index],
                        _buildingData[index]['distance'] / 1000, // km
                        _buildingData[index]['duration'],
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 100,
                    viewportFraction: 0.85,
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
        onPressed: _centerOnUser,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(BuildingType? type, String label) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _applyFilter(type),
        backgroundColor: Colors.green.shade600,
        selectedColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade700 : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        checkmarkColor: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
