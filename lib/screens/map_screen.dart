import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PagsanjanMapScreen extends StatefulWidget {
  const PagsanjanMapScreen({super.key});

  @override
  State<PagsanjanMapScreen> createState() => _PagsanjanMapScreenState();
}

class _PagsanjanMapScreenState extends State<PagsanjanMapScreen> {
  final LatLng pagsanjanCenter = const LatLng(14.2790, 121.4173);
  bool isLoading = true;

  List<Polygon> mapPolygons = [];
  List<Polyline> mapPolylines = [];

  @override
  void initState() {
    super.initState();
    _loadAllGeoJsonFiles();
  }

  Future<void> _loadAllGeoJsonFiles() async {
    try {
      List<Polygon> tempPolygons = [];
      List<Polyline> tempPolylines = [];

      // 1. Load Landuse (Polygons)
      await _processGeoJsonFile('pagsanan_landuse.geojson', tempPolygons, tempPolylines, isPolygon: true);

      // 2. Load Waterways (Lines)
      await _processGeoJsonFile('pagsanjan_waterway.geojson', tempPolygons, tempPolylines, isPolygon: false, color: Colors.blue, width: 2.0);

      // 3. Load Roadways (Lines)
      await _processGeoJsonFile('pagsanjanroadway.geojson', tempPolygons, tempPolylines, isPolygon: false, color: Colors.orange, width: 2.0);

      setState(() {
        mapPolygons = tempPolygons;
        mapPolylines = tempPolylines;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading geojson: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _processGeoJsonFile(
      String fileName,
      List<Polygon> polygonsList,
      List<Polyline> polylinesList,
      {required bool isPolygon, Color color = Colors.blue, double width = 2.0}
      ) async {
    try {
      String jsonString = await rootBundle.loadString('assets/$fileName');
      Map<String, dynamic> geoJsonData = json.decode(jsonString);

      for (var feature in geoJsonData['features']) {
        var geometry = feature['geometry'];
        var type = geometry['type'];
        var coordinates = geometry['coordinates'];

        if (isPolygon) {
          if (type == 'Polygon') {
            for (var ring in coordinates) {
              List<LatLng> points = ring.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
              polygonsList.add(
                Polygon(
                  points: points,
                  color: Colors.green.withValues(alpha: 0.2),
                  borderColor: Colors.green.shade800,
                  borderStrokeWidth: 1.5,
                ),
              );
            }
          } else if (type == 'MultiPolygon') {
            for (var polygon in coordinates) {
              for (var ring in polygon) {
                List<LatLng> points = ring.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
                polygonsList.add(
                  Polygon(
                    points: points,
                    color: Colors.green.withValues(alpha: 0.2),
                    borderColor: Colors.green.shade800,
                    borderStrokeWidth: 1.5,
                  ),
                );
              }
            }
          }
        } else {
          // Para sa Lines (Waterways & Roads)
          if (type == 'LineString') {
            List<LatLng> points = coordinates.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
            polylinesList.add(
              Polyline(points: points, color: color, strokeWidth: width),
            );
          } else if (type == 'MultiLineString') {
            for (var line in coordinates) {
              List<LatLng> points = line.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
              polylinesList.add(
                Polyline(points: points, color: color, strokeWidth: width),
              );
            }
          }
        }
      }
    } catch (e) {
      print("Skipping or error in $fileName: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagsanjan DSS Map'),
        backgroundColor: const Color(0xFF004080),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          initialCenter: pagsanjanCenter,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.agriculture',
          ),
          PolygonLayer(polygons: mapPolygons),
          PolylineLayer(polylines: mapPolylines),
        ],
      ),
    );
  }
}