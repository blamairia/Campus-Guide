import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_navigation/constants/buildings.dart';
import 'package:mapbox_navigation/helpers/directions_handler.dart';
import 'package:mapbox_navigation/main.dart';
import 'package:mapbox_navigation/screens/university_table.dart';

import '../screens/home_management.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
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
    for (int i = 0; i < buildings.length; i++) {
      Map modifiedResponse = await getDirectionsAPIResponse(currentLatlng, i);
      saveDirectionsAPIResponse(i, json.encode(modifiedResponse));
    }
    Future.delayed(
        const Duration(seconds: 1),
        () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeManagement()),
            (route) => false));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(child: Image.asset('assets/image/splash.png')),
    );
  }
}
