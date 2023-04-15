import 'package:mapbox_gl/mapbox_gl.dart';

import '../constants/departments.dart';

LatLng getLatLngFromDepartmentData(int index) {
  return LatLng(double.parse(departments[index]['coordinates']['latitude']),
      double.parse(departments[index]['coordinates']['longitude']));
}
