import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/helpers/directions_handler.dart';
import 'package:ubmap/main.dart';
import 'package:ubmap/screens/university_table.dart';

import '../screens/home_management.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildUniversityCard("University 1", 'assets/image/Ag.jpg', buildings),
          buildUniversityCard(
              "University 2", 'assets/image/Ag.jpg', buildings2),
          buildUniversityCard(
              "University 3", 'assets/image/Ag.jpg', buildings3),
        ],
      ),
    );
  }

  Widget buildUniversityCard(String title, String image, List<Map> buildings) {
    return GestureDetector(
        onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeManagement(
                buildings: buildings,
              ),
            ),
            (route) => false),
        child: Card(
          child: ListTile(
            leading: Image.asset('$image'),
            title: Text(title),
            onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeManagement(
                    buildings: buildings,
                  ),
                ),
                (route) => false),
          ),
        ));
  }
}
