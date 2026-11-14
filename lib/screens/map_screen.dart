import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BarangayResolver {
  static final Map<String, LatLng> barangayCenters = {
    'Anibong': const LatLng(14.2855, 121.4682),
    'Biñan': const LatLng(14.2750, 121.4580),
    'Buboy': const LatLng(14.2950, 121.4420),
    'Cabanbanan': const LatLng(14.2620, 121.4650),
    'Calusiche': const LatLng(14.2980, 121.4580),
    'Dingin': const LatLng(14.2880, 121.4350),
    'Lambac': const LatLng(14.2680, 121.4420),
    'Layug': const LatLng(14.2710, 121.4480),
    'Magdapio': const LatLng(14.2650, 121.4380),
    'Maulawin': const LatLng(14.2780, 121.4410),
    'Pinagsanjan': const LatLng(14.2720, 121.4520),
    'Poblacion Uno': const LatLng(14.2785, 121.4515),
    'Poblacion Dos': const LatLng(14.2760, 121.4530),
    'Sabang': const LatLng(14.2820, 121.4460),
    'Sampaloc': const LatLng(14.2910, 121.4510),
    'San Isidro': const LatLng(14.2630, 121.4520),
  };

  static String resolveBarangay(LatLng point) {
    String closest = 'Biñan';
    double minDist = double.infinity;
    for (final entry in barangayCenters.entries) {
      final dist = const Distance().as(LengthUnit.Kilometer, point, entry.value);
      if (dist < minDist) {
        minDist = dist;
        closest = entry.key;
      }
    }
    return closest;
  }
}

class PagsanjanMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final void Function(LatLng)? onTap;

  const PagsanjanMapWidget({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const [],
    this.onTap,
  });

  @override
  State<PagsanjanMapWidget> createState() => _PagsanjanMapWidgetState();
}

class _PagsanjanMapWidgetState extends State<PagsanjanMapWidget> {
  final MapController _mapController = MapController();
  List<Polygon> _polygons = [];
  List<Marker> _barangayLabelMarkers = [];

  @override
  void initState() {
    super.initState();
    _loadBoundaryGeoJson();
  }

  @override
  void didUpdateWidget(covariant PagsanjanMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCenter != widget.initialCenter || oldWidget.initialZoom != widget.initialZoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.initialCenter, widget.initialZoom);
      });
    }
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(14.2790, 121.4550);
    double sumLat = 0;
    double sumLng = 0;
    for (final p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  Future<void> _loadBoundaryGeoJson() async {
    try {
      final String response = await rootBundle.loadString('assets/MAP/Boundary_Pagsanjan.geojson');
      final data = json.decode(response);
      List<Polygon> parsed = [];
      List<Marker> parsedLabels = [];

      if (data['features'] != null) {
        for (final feature in data['features']) {
          final geometry = feature['geometry'];
          final properties = feature['properties'] ?? {};
          final brgyName = properties['name'] ?? properties['official_name'] ?? '';
          if (brgyName.isEmpty) continue;

          if (geometry != null) {
            final type = geometry['type'];
            final coordinates = geometry['coordinates'];
            List<LatLng> firstRingPoints = [];

            if (type == 'Polygon') {
              for (int r = 0; r < coordinates.length; r++) {
                final ring = coordinates[r];
                List<LatLng> points = [];
                for (final coord in ring) {
                  points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
                }
                if (points.isNotEmpty) {
                  if (r == 0) firstRingPoints = points;
                  parsed.add(
                    Polygon(
                      points: points,
                      color: Colors.transparent, // Transparent interior to reveal satellite imagery
                      borderColor: const Color(0xFF22C55E), // Neon green boundary outline matching screenshot
                      borderStrokeWidth: 3.0,
                    ),
                  );
                }
              }
            } else if (type == 'MultiPolygon') {
              for (int p = 0; p < coordinates.length; p++) {
                final polygonCoords = coordinates[p];
                for (int r = 0; r < polygonCoords.length; r++) {
                  final ring = polygonCoords[r];
                  List<LatLng> points = [];
                  for (final coord in ring) {
                    points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
                  }
                  if (points.isNotEmpty) {
                    if (p == 0 && r == 0) firstRingPoints = points;
                    parsed.add(
                      Polygon(
                        points: points,
                        color: Colors.transparent,
                        borderColor: const Color(0xFF22C55E),
                        borderStrokeWidth: 3.0,
                      ),
                    );
                  }
                }
              }
            }

            if (firstRingPoints.isNotEmpty) {
              final center = _calculateCentroid(firstRingPoints);
              parsedLabels.add(
                Marker(
                  point: center,
                  width: 130,
                  height: 44,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85), // Dark styled badge matching screenshot
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Text(
                        brgyName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White bold text matching screenshot
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _polygons = parsed;
          _barangayLabelMarkers = parsedLabels;
        });
      }
    } catch (e) {
      debugPrint('Error loading Boundary_Pagsanjan.geojson in PagsanjanMapWidget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMarkers = [..._barangayLabelMarkers, ...widget.markers];
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 12.5,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(14.1000, 121.2500),
                  const LatLng(14.4500, 121.6000),
                ),
              ),
              onTap: (tapPosition, point) {
                if (widget.onTap != null) widget.onTap!(point);
              },
            ),
            children: [
              // Satellite Imagery Tile Layer (Esri World Imagery)
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.agriculture',
              ),
              if (_polygons.isNotEmpty)
                PolygonLayer(polygons: _polygons),
              if (allMarkers.isNotEmpty)
                MarkerLayer(markers: allMarkers),
            ],
          ),
          // ZOOM IN / ZOOM OUT FLOATING BUTTONS
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in_${DateTime.now().millisecondsSinceEpoch}',
                  backgroundColor: const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom In (+)',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 1);
                  },
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out_${DateTime.now().millisecondsSinceEpoch}',
                  backgroundColor: const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom Out (-)',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 1);
                  },
                  child: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
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
        title: const Text('Pagsanjan Official Municipal Boundary Map (Satellite)'),
        backgroundColor: const Color(0xFF0056B3),
      ),
      body: PagsanjanMapWidget(
        initialCenter: const LatLng(14.2790, 121.4550),
        initialZoom: 14.0,
        markers: markers,
      ),
    );
  }
}

class BoundaryPagsanjanScreen extends StatefulWidget {
  const BoundaryPagsanjanScreen({super.key});

  @override
  BoundaryPagsanjanScreenState createState() => BoundaryPagsanjanScreenState();
}

class BoundaryPagsanjanScreenState extends State<BoundaryPagsanjanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagsanjan Official Municipal Boundary Map (Satellite)'),
        backgroundColor: const Color(0xFF0056B3),
      ),
      body: const PagsanjanMapWidget(
        initialCenter: LatLng(14.2790, 121.4550),
        initialZoom: 13.5,
      ),
    );
  }
}
