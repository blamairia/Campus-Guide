import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/main.dart';
import 'package:ubmap/services/navigation_service.dart';

import '../screens/home_management.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  List<List<Map>> buildingList = [buildings, buildings2, buildings3];
  int currentPage = 0;
  final NavigationService _navigationService = NavigationService();
  bool _isLoading = true;
  String _statusText = "Initializing...";

  @override
  void initState() {
    super.initState();
    initializeLocationAndSave();
  }

  void initializeLocationAndSave() async {
    setState(() {
      _statusText = "Requesting location permission...";
    });
    
    // Request permission
    final hasPermission = await _navigationService.requestLocationPermission();
    
    if (!hasPermission) {
      setState(() {
        _statusText = "Location permission required";
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _statusText = "Getting your location...";
    });
    
    // Get current position
    final position = await _navigationService.getCurrentPosition();
    
    if (position != null) {
      // Store the user location in sharedPreferences
      sharedPreferences.setDouble('latitude', position.latitude);
      sharedPreferences.setDouble('longitude', position.longitude);
    }
    
    setState(() {
      _isLoading = false;
      _statusText = "Select a campus";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            itemCount: 3,
            onPageChanged: (int index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: _isLoading ? null : () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeManagement(
                        buildings: buildingList[index],
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: index == 0
                          ? [const Color(0xFF678FB4), const Color(0xFF4A6FA1)]
                          : index == 1
                              ? [const Color(0xFF65B0B4), const Color(0xFF4A9A9E)]
                              : [const Color(0xFF9B90BC), const Color(0xFF7A6FA5)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset('assets/image/Ag.jpg', height: 250),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        index == 0
                            ? "University Sidi Amar"
                            : index == 1
                                ? "University Bouni"
                                : "University Sidi Achor",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 28.0,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Tap to explore buildings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentPage == i ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Status bar
          if (_isLoading)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _statusText,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
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
}
