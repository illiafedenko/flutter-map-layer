// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Sample App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController; //controller for Google map
  final LatLng _center = const LatLng(26.3005351, 50.182); //center of the map
  final Set<Polygon> _polygons = <Polygon>{};
  final Set<Marker> _markers = <Marker>{};
  dynamic polygonData;
  dynamic markerData;

  void _showInfo(dynamic info) {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Information"),
            content: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(), // Optional for styling
                columnWidths: const <int, TableColumnWidth>{
                  0: FlexColumnWidth(1.0), // This is for the key column
                  1: FlexColumnWidth(1.0), // This is for the value column
                },
                children: info.entries.map<TableRow>((entry) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(entry.key),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(entry.value.toString()),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print("e");
      print(e);
    }
  }

  Future<dynamic> _loadGeoJsonFromAssets(String path) async {
    String data = await rootBundle.loadString(path);
    return jsonDecode(data)['features'];
  }

  Future<void> _loadPolygonJson() async {
    try {
      final polygonJson = await _loadGeoJsonFromAssets('assets/hex_ex.geojson');
      setState(() {
        polygonData = polygonJson;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadPointJson() async {
    try {
      final markerJson = await _loadGeoJsonFromAssets('assets/poi_ex.geojson');
      setState(() {
        for (int i = 0; i < markerJson.length; i++) {
          _markers.add(
            Marker(
              markerId: MarkerId('marker_$i'),
              position: LatLng(markerJson[i]['properties']['latitude'],
                  markerJson[i]['properties']['longitude']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueCyan, // Predefined color for the marker
              ),
              consumeTapEvents: true,
              onTap: () => {_showInfo(markerJson[i]['properties'])},
            ),
          );
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      for (final feature in polygonData) {
        if (feature['geometry']['type'] == 'Polygon') {
          List<LatLng> polygonCoordinates = [];
          final List<dynamic> coordinates =
              feature['geometry']['coordinates'].first;

          for (final List<dynamic> point in coordinates) {
            polygonCoordinates.add(
              LatLng(point[1], point[0]),
            );
          }
          final Polygon polygon = Polygon(
            polygonId: PolygonId('polygon_${_polygons.length}'),
            points: polygonCoordinates,
            strokeWidth: 2,
            strokeColor: Colors.black,
            fillColor: Colors.green.withOpacity(0.5),
            consumeTapEvents: true,
            onTap: () => _showInfo(feature['properties']),
          );
          setState(() {
            _polygons.add(polygon);
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPolygonJson();
    _loadPointJson();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hexagon & Point Layer App'),
          backgroundColor: Colors.green[700],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 15.0,
          ),
          polygons: _polygons,
          markers: _markers,
        ),
      ),
    );
  }
}
