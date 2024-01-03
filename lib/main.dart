import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(26.3005351, 50.182);
  final Set<Polygon> _polygons = <Polygon>{};
  dynamic polygonData;

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

  Future<void> fetchData(VoidCallback onDone) async {
    // Simulate fetching data from the network
    final response = await http.get(Uri.parse(
        'http://34.72.17.139:8080/geoserver/map_layers_m/wms?service=WMS&version=1.1.0&request=GetMap&layers=map_layers_m%3Aeast_dist_gs&bbox=47.005306243896484%2C25.90535545349121%2C50.24072265625%2C28.50123405456543&width=768&height=616&srs=EPSG%3A4326&styles=&format=geojson'));

    if (response.statusCode == 200) {
      dynamic datas = jsonDecode(utf8.decode(response.bodyBytes))['features'];
      setState(() {
        polygonData = datas;
        onDone(); // Call the provided callback after setting the state
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(() {
      // This will run after the fetchData logic completes and the state is set.
      if (_center != null && mapController != null) {
        _onMapCreated(mapController!);
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Ensure the data has been fetched before creating polygons
    if (polygonData != null) {
      createPolygons();
    }
  }

  void createPolygons() {
    setState(() {
      for (final feature in polygonData) {
        if (feature['geometry']['type'] == 'Polygon') {
          List<LatLng> polygonCoordinates = [];
          final List<dynamic> coordinates =
              feature['geometry']['coordinates'].first;

          for (final List<dynamic> point in coordinates) {
            polygonCoordinates.add(
              LatLng(point[1].toDouble(), point[0].toDouble()),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hexagon & Point Layer App'),
        backgroundColor: Colors.green[700],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 9,
        ),
        polygons: _polygons,
      ),
    );
  }
}
