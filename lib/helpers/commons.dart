import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../constants/buildings.dart';

mapbox.Position getPositionFromBuildingData(int index) {
  final building = buildings[index];
  final lat = double.parse(building['coordinates']['latitude'].toString().trim());
  final lng = double.parse(building['coordinates']['longitude'].toString().trim());
  return mapbox.Position(lng, lat);
}

mapbox.Point getPointFromBuildingData(int index) {
  return mapbox.Point(coordinates: getPositionFromBuildingData(index));
}
