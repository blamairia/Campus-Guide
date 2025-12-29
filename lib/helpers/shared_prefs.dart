import 'dart:convert';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:ubmap/main.dart';

mapbox.Position getPositionFromSharedPrefs() {
  final lat = sharedPreferences.getDouble('latitude') ?? 36.812;
  final lng = sharedPreferences.getDouble('longitude') ?? 7.718;
  return mapbox.Position(lng, lat);
}

void saveUserLocation(double lat, double lng) {
  sharedPreferences.setDouble('latitude', lat);
  sharedPreferences.setDouble('longitude', lng);
}

Map getDecodedResponseFromSharedPrefs(int index) {
  String key = 'building--$index';
  final stored = sharedPreferences.getString(key);
  if (stored == null) return {};
  return json.decode(stored);
}

num getDistanceFromSharedPrefs(int index) {
  final response = getDecodedResponseFromSharedPrefs(index);
  return response['distance'] ?? 0;
}

num getDurationFromSharedPrefs(int index) {
  final response = getDecodedResponseFromSharedPrefs(index);
  return response['duration'] ?? 0;
}

Map getGeometryFromSharedPrefs(int index) {
  final response = getDecodedResponseFromSharedPrefs(index);
  return response['geometry'] ?? {};
}

mapbox.Position getCurrentPositionFromSharedPrefs() {
  return getPositionFromSharedPrefs();
}

String getCurrentAddressFromSharedPrefs() {
  return sharedPreferences.getString('current-address') ?? '';
}
