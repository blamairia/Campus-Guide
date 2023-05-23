import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/main.dart';

import '../screens/home_management.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  List<List<Map>> buildingList = [buildings, buildings2, buildings3];
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    initializeLocationAndSave();
  }

  void initializeLocationAndSave() async {
    // Ensure all permissions are collected for Locations
    Location _location = Location();
    bool? _serviceEnabled;
    PermissionStatus? _permissionGanted;

    _serviceEnabled = await _location.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
    }

    _permissionGanted = await _location.hasPermission();

    if (_permissionGanted == PermissionStatus.denied) {
      _permissionGanted == await _location.requestPermission();
    }
    // Get capture the current user location
    LocationData _locationData = await _location.getLocation();
    LatLng currentLatlng =
        LatLng(_locationData.latitude!, _locationData.longitude!);

    // Store the user location in sharedPreferences
    sharedPreferences.setDouble('latitude', _locationData.latitude!);
    sharedPreferences.setDouble('longitude', _locationData.longitude!);

    // Get and store the directions API response in sharedPreferences

    //  Commented this to prevent it from automatically navigating to HomeManagement
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        itemCount: 3,
        onPageChanged: (int index) {
          setState(() {
            currentPage = index;
          });
        },
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeManagement(
                      buildings: buildingList[index],
                    ),
                  ),
                  (route) => false);
            },
            child: Container(
              color: index == 0
                  ? Color(0xFF678FB4)
                  : index == 1
                      ? Color(0xFF65B0B4)
                      : Color(0xFF9B90BC),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/image/Ag.jpg', height: 300),
                  SizedBox(height: 20),
                  Text(
                    index == 0
                        ? "University Sidi Amar"
                        : index == 1
                            ? "University Bouni"
                            : "University Sidi Achor",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 34.0,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'All universities are sorted by ranking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
