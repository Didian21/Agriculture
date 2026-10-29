import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BarangayFeature {
  final String name;
  final List<List<LatLng>> polygons;

  BarangayFeature({required this.name, required this.polygons});
}

class BarangayResolver {
  static final List<BarangayFeature> _barangays = [];

  static Future<void> load() async {
    if (_barangays.isNotEmpty) return;
    try {
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/pagsanjanmapcipped.geojson');
      } catch (_) {
        jsonString = await rootBundle.loadString('assets/Map/pagsanjanmapcipped.geojson');
      }
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];

      for (var f in features) {
        final rawName = f['properties']?['NAME_3'] as String? ?? '';
        final cleanName = _normalizeName(rawName);
        if (cleanName.isEmpty) continue;

        final geom = f['geometry'];
        final type = geom['type'];
        final coords = geom['coordinates'];
        List<List<LatLng>> polyList = [];

        if (type == 'Polygon') {
          for (var ring in coords) {
            polyList.add((ring as List).map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList());
          }
        } else if (type == 'MultiPolygon') {
          for (var poly in coords) {
            for (var ring in poly) {
              polyList.add((ring as List).map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList());
            }
          }
        }
        _barangays.add(BarangayFeature(name: cleanName, polygons: polyList));
      }
    } catch (_) {}
  }

  static String _normalizeName(String raw) {
    switch (raw) {
      case 'BarangayI':
        return 'Poblacion Uno';
      case 'BarangayII':
        return 'Poblacion Dos';
      case 'SanIsidro':
        return 'San Isidro';
      case 'Layugan':
        return 'Layug';
      case 'Pinagsanjan':
        return 'Magdapio';
      default:
        return raw;
    }
  }

  static String resolveBarangay(LatLng point) {
    for (var brgy in _barangays) {
      for (var poly in brgy.polygons) {
        if (_pointInPolygon(point, poly)) {
          return brgy.name;
        }
      }
    }
    // Fallback distance check if tapped on exact border
    double minDistance = double.infinity;
    String closestName = 'Biñan';
    const distance = Distance();
    for (var brgy in _barangays) {
      for (var poly in brgy.polygons) {
        if (poly.isNotEmpty) {
          final center = poly.first;
          final dist = distance.as(LengthUnit.Meter, point, center);
          if (dist < minDistance) {
            minDistance = dist;
            closestName = brgy.name;
          }
        }
      }
    }
    return closestName;
  }

  static bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude > point.longitude) != (polygon[j].longitude > point.longitude) &&
          (point.latitude < (polygon[j].latitude - polygon[i].latitude) * (point.longitude - polygon[i].longitude) / (polygon[j].longitude - polygon[i].longitude) + polygon[i].latitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}

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
  final MapController _mapController = MapController();
  final LatLng pagsanjanCenter = const LatLng(14.2790, 121.4550);
  bool isLoading = true;

  List<Polygon> mapPolygons = [];
  List<Polyline> mapPolylines = [];

  @override
  void initState() {
    super.initState();
    _loadPagsanjanBoundary();
  }

  @override
  void didUpdateWidget(covariant PagsanjanMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCenter != null && widget.initialCenter != oldWidget.initialCenter) {
      _mapController.move(widget.initialCenter!, widget.initialZoom);
    }
  }

  Future<void> _loadPagsanjanBoundary() async {
    try {
      await BarangayResolver.load();
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
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter ?? pagsanjanCenter,
        initialZoom: widget.initialZoom,
        onTap: widget.onTap != null
            ? (_, point) {
                _mapController.move(point, _mapController.camera.zoom);
                widget.onTap!(point);
              }
            : null,
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
  final List<Marker> markers;
  const PagsanjanMapScreen({super.key, this.markers = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagsanjan Boundary Map'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: PagsanjanMapWidget(markers: markers),
    );
  }
}
