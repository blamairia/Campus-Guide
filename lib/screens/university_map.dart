import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:ubmap/helpers/commons.dart';
import 'package:ubmap/helpers/directions_handler.dart';
import 'package:ubmap/helpers/shared_prefs.dart';
import 'package:ubmap/widgets/carousel_card.dart';

class UniversityMap extends StatefulWidget {
  const UniversityMap({Key? key, required this.buildings}) : super(key: key);
  final List<Map> buildings;

  @override
  State<UniversityMap> createState() => _UniversityMapState();
}

class _UniversityMapState extends State<UniversityMap> {
  List<Widget> carouselItems = [];
  LatLng latLng = getLatLngFromSharedPrefs();
  late CameraPosition _initialCameraPosition;
  late MapboxMapController controller;
  late List<CameraPosition> _kbuildingsList;
  List<Map> carouselData = [];
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(target: latLng, zoom: 15);
    _kbuildingsList = List<CameraPosition>.generate(
        widget.buildings.length,
        (index) => CameraPosition(
            target: getLatLngFromDepartmentData(index), zoom: 15));
    getInitialDirectionsData();
  }

  Future<void> getInitialDirectionsData() async {
    for (int index = 0; index < widget.buildings.length; index++) {
      carouselData.add({'index': index, 'distance': 0, 'duration': 0});
    }

    setState(() {
      carouselItems = List<Widget>.generate(
        widget.buildings.length,
        (index) => carouselCard(
          widget.buildings[index],
          carouselData[index]['distance'],
          carouselData[index]['duration'],
        ),
      );
    });

    Map modifiedResponse =
        await getDirectionsAPIResponse(latLng, widget.buildings[0][0]);
    saveDirectionsAPIResponse(
        widget.buildings[0][0], json.encode(modifiedResponse));

    num distance = getDistanceFromSharedPrefs(widget.buildings[0][0]) / 1000;
    num duration = getDurationFromSharedPrefs(widget.buildings[0][0]) / 60;

    setState(() {
      carouselData[0] = {
        'index': widget.buildings[0][0],
        'distance': distance,
        'duration': duration
      };
      carouselItems[0] = carouselCard(
        widget.buildings[0],
        carouselData[0]['distance'],
        carouselData[0]['duration'],
      );
    });

    _addSourceAndLineLayer(0, false);
  }

  void _onFloatingButtonPressed() async {
    if (carouselData[pageIndex]['distance'] == 0) {
      Map modifiedResponse = await getDirectionsAPIResponse(latLng, pageIndex);
      saveDirectionsAPIResponse(pageIndex, json.encode(modifiedResponse));

      setState(() {
        carouselData[pageIndex]['distance'] =
            getDistanceFromSharedPrefs(pageIndex) / 1000;
        carouselData[pageIndex]['duration'] =
            getDurationFromSharedPrefs(pageIndex) / 60;

        carouselItems[pageIndex] = carouselCard(
          widget.buildings[pageIndex],
          carouselData[pageIndex]['distance'],
          carouselData[pageIndex]['duration'],
        );
      });
    }

    controller.animateCamera(
        CameraUpdate.newCameraPosition(_kbuildingsList[pageIndex]));
    _addSourceAndLineLayer(pageIndex, true);
  }

  void _updateCarouselData(int index) async {
    Map modifiedResponse = await getDirectionsAPIResponse(latLng, index);
    saveDirectionsAPIResponse(index, json.encode(modifiedResponse));

    setState(() {
      carouselData[index]['distance'] =
          getDistanceFromSharedPrefs(index) / 1000;
      carouselData[index]['duration'] = getDurationFromSharedPrefs(index) / 60;

      carouselItems[index] = carouselCard(
        widget.buildings[index],
        carouselData[index]['distance'],
        carouselData[index]['duration'],
      );
    });
  }

  _addSourceAndLineLayer(int index, bool removeLayer) async {
    if (controller == null) return;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(_kbuildingsList[index]));

    Map geometry = getGeometryFromSharedPrefs(carouselData[index]['index']);

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

    if (removeLayer == true) {
      await controller.removeLayer("lines");
      await controller.removeSource("fills");
    }

    if (controller.fills!.isNotEmpty) {
      await controller.removeLayer("lines");
      await controller.removeSource("fills");
    }

    await controller.addSource("fills", GeojsonSourceProperties(data: _fills));
    await controller.addLineLayer(
      "fills",
      "lines",
      LineLayerProperties(
        lineColor: Colors.blue.toHexStringRGB(),
        lineCap: "round",
        lineJoin: "round",
        lineWidth: 3,
      ),
    );
  }

  _onMapCreated(MapboxMapController controller) async {
    this.controller = controller;
  }

  _onStyleLoadedCallback() async {
    for (CameraPosition _kDepartment in _kbuildingsList) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: _kDepartment.target,
          iconSize: 0.1,
          iconImage: "assets/icon/skyscraper.png",
          textField: widget.buildings[_kbuildingsList.indexOf(_kDepartment)]
              ['name'],
          textSize: 12.5,
          textOffset: const Offset(0, 0.8),
          textAnchor: 'top',
          textColor: '#000000',
          textHaloBlur: 1,
          textHaloColor: '#ffffff',
          textHaloWidth: 0.8,
        ),
      );
    }
    _addSourceAndLineLayer(0, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Building Map'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MapboxMap(
                accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'],
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
                minMaxZoomPreference: const MinMaxZoomPreference(14, 17),
                styleString: "mapbox://styles/mapbox/satellite-v9",
                onStyleLoadedCallback: _onStyleLoadedCallback,
              ),
            ),
            if (carouselItems.isNotEmpty)
              CarouselSlider(
                items: carouselItems,
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height / 7.5,
                  viewportFraction: 0.7,
                  initialPage: 0,
                  enableInfiniteScroll: false,
                  scrollDirection: Axis.horizontal,
                  onPageChanged:
                      (int index, CarouselPageChangedReason reason) async {
                    setState(() {
                      pageIndex = index;
                      controller.animateCamera(CameraUpdate.newCameraPosition(
                          _kbuildingsList[pageIndex]));
                      _addSourceAndLineLayer(pageIndex, true);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingButtonPressed,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
