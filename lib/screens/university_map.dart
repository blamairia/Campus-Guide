import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_navigation/helpers/shared_prefs.dart';

class UniversityMap extends StatefulWidget {
  const UniversityMap({Key? key}) : super(key: key);

  @override
  State<UniversityMap> createState() => _UniversityMapState();
}

class _UniversityMapState extends State<UniversityMap> {
  // Mapbox related
  LatLng latlng = getLatLngFromSharedPrefs();
  late CameraPosition _initialCameraPosition;
  late MapboxMapController controller;
  // Carousel related

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(target: latlng, zoom: 15);

    // Calculate the distance and time from data in SharedPreferences

    // Generate the list of carousel widgets

    // initialize map symbols in the same order as carousel widgets
  }

  _addSourceAndLineLayer(int index, bool removeLayer) async {
    // Can animate camera to focus on the item

    // Add a polyLine between source and destination

    // Remove lineLayer and source if it exists

    // Add new source and lineLayer
  }

  _onMapCreated(MapboxMapController controller) async {
    this.controller = controller;
  }

  _onStyleLoadedCallback() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Map'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: MapboxMap(
                initialCameraPosition: _initialCameraPosition,
                accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'],
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
                minMaxZoomPreference: const MinMaxZoomPreference(14, 30),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(_initialCameraPosition),
          );
        },
        child: const Icon(Icons.my_location_outlined),
      ),
    );
  }
}
