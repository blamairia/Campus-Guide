import 'package:mapbox_gl/mapbox_gl.dart';

import '../constants/buildings.dart';

LatLng getLatLngFromDepartmentData(int index) {
  return LatLng(double.parse(buildings[index]['coordinates']['latitude']),
      double.parse(buildings[index]['coordinates']['longitude']));
}
