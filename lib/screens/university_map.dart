import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_navigation/constants/departments.dart';
import 'package:mapbox_navigation/helpers/commons.dart';
import 'package:mapbox_navigation/helpers/shared_prefs.dart';
import 'package:mapbox_navigation/widgets/carousel_card.dart';

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
  late List<CameraPosition> _kDdepartementsList;
  List<Map> carouselData = [];

  // Carousel related
  int pageIndex = 0;
  late List<Widget> carouselItems;
  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(target: latlng, zoom: 15);

    // Calculate the distance and time from data in SharedPreferences
    for (int index = 0; index < departments.length; index++) {
      num distance = getDistanceFromSharedPrefs(index) / 1000;
      num duration = getDurationFromSharedPrefs(index) / 60;
      carouselData
          .add({'index': index, 'distance': distance, 'duration': duration});
    }

    carouselData.sort((a, b) => a['duration'] < b['duration'] ? 0 : 1);

    // Generate the list of carousel widgets
    carouselItems = List<Widget>.generate(
      departments.length,
      (index) => carouselCard(
        carouselData[index]['index'],
        carouselData[index]['distance'],
        carouselData[index]['duration'],
      ),
    );

    // initialize map symbols in the same order as carousel widgets
    _kDdepartementsList = List<CameraPosition>.generate(
      departments.length,
      (index) => CameraPosition(
        target: getLatLngFromDepartmentData(carouselData[index]['index']),
        zoom: 15,
      ),
    );
  }

  _addSourceAndLineLayer(int index, bool removeLayer) async {
    // Can animate camera to focus on the item
    controller.animateCamera(
        CameraUpdate.newCameraPosition(_kDdepartementsList[index]));
    // Add a polyLine between source and destination
    Map geometry = getGeometryFromSharedPrefs(
      carouselData[index]['index'],
    );
    final _fills = {
      "type": "FeatureCollection",
      "features": [
        {
          "id": 0,
          "type": "Feature",
          "properties": <String, dynamic>{},
          "geometry": geometry,
        }
      ]
    };

    // Remove lineLayer and source if it exists
    if (removeLayer == true) {
      await controller.removeLayer("lines");
      await controller.removeSource("fills");
    }
    // Add new source and lineLayer
    await controller.addSource("fills", GeojsonSourceProperties(data: _fills));
    await controller.addLineLayer(
        "fills",
        "lines",
        LineLayerProperties(
          lineColor: Colors.green.toHexStringRGB(),
          lineCap: "round",
          lineJoin: "round",
          lineWidth: 2,
        ));
  }

  _onMapCreated(MapboxMapController controller) async {
    this.controller = controller;
  }

  _onStyleLoadedCallback() async {
    for (CameraPosition _kDdepartementsList in _kDdepartementsList) {
      await controller.addSymbol(SymbolOptions.defaultOptions);
    }
    _addSourceAndLineLayer(0, false);
  }

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
              ),
            ),
            CarouselSlider(
              items: carouselItems,
              options: CarouselOptions(
                height: 134,
                viewportFraction: 0.6,
                initialPage: 0,
                enableInfiniteScroll: false,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index, reason) {
                  setState(() {
                    pageIndex = index;
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: getLatLngFromDepartmentData(
                              carouselData[index]['index']),
                          zoom: 15,
                        ),
                      ),
                    );
                  });
                  _addSourceAndLineLayer(index, true);
                  _onStyleLoadedCallback();
                },
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
