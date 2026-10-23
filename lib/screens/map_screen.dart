import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PagsanjanMapWidget extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final Function(LatLng point)? onTap;

  const PagsanjanMapWidget({
    super.key,
    this.initialCenter,
    this.initialZoom = 13.5,
    this.markers = const [],
    this.onTap,
  });

  @override
  State<PagsanjanMapWidget> createState() => _PagsanjanMapWidgetState();
}

class _PagsanjanMapWidgetState extends State<PagsanjanMapWidget> {
  final LatLng pagsanjanCenter = const LatLng(14.2790, 121.4550);
  bool isLoading = true;

  List<Polygon> mapPolygons = [];
  List<Polyline> mapPolylines = [];

  @override
  void initState() {
    super.initState();
    _loadPagsanjanBoundary();
  }

  Future<void> _loadPagsanjanBoundary() async {
    try {
      List<Polygon> tempPolygons = [];
      List<Polyline> tempPolylines = [];

      // Load ONLY the clipped Pagsanjan boundary GeoJSON
      await _processGeoJsonFile('pagsanjanmapcipped.geojson', tempPolygons, tempPolylines);

      if (mounted) {
        setState(() {
          mapPolygons = tempPolygons;
          mapPolylines = tempPolylines;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _processGeoJsonFile(
      String fileName,
      List<Polygon> polygonsList,
      List<Polyline> polylinesList,
      ) async {
    try {
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/$fileName');
      } catch (_) {
        try {
          jsonString = await rootBundle.loadString('assets/Map/$fileName');
        } catch (_) {
          jsonString = await rootBundle.loadString('pagsanjanmapcipped.geojson');
        }
      }
      Map<String, dynamic> geoJsonData = json.decode(jsonString);

      for (var feature in geoJsonData['features']) {
        var geometry = feature['geometry'];
        var type = geometry['type'];
        var coordinates = geometry['coordinates'];

        if (type == 'Polygon') {
          for (var ring in coordinates) {
            List<LatLng> points = ring.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
            polygonsList.add(
              Polygon(
                points: points,
                color: Colors.green.withValues(alpha: 0.12),
                borderColor: const Color(0xFF1B5E20),
                borderStrokeWidth: 2.0,
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
                  color: Colors.green.withValues(alpha: 0.12),
                  borderColor: const Color(0xFF1B5E20),
                  borderStrokeWidth: 2.0,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: widget.initialCenter ?? pagsanjanCenter,
        initialZoom: widget.initialZoom,
        onTap: widget.onTap != null ? (_, point) => widget.onTap!(point) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.agriculture',
        ),
        PolygonLayer(polygons: mapPolygons),
        PolylineLayer(polylines: mapPolylines),
        if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
      ],
    );
  }
}

class PagsanjanMapScreen extends StatelessWidget {
  const PagsanjanMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagsanjan Boundary Map'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: const PagsanjanMapWidget(),
    );
  }
}
