import 'dart:convert';
import 'dart:math' as math;
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
  final List<Polygon> extraPolygons;
  final void Function(LatLng)? onTap;

  const PagsanjanMapWidget({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const [],
    this.extraPolygons = const [],
    this.onTap,
  });

  @override
  State<PagsanjanMapWidget> createState() => _PagsanjanMapWidgetState();
}

class _PagsanjanMapWidgetState extends State<PagsanjanMapWidget> {
  final MapController _mapController = MapController();
  List<Polygon> _polygons = [];
  List<Marker> _barangayLabelMarkers = [];
  bool _isSatelliteMode = false;

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
        if (mounted) {
          try {
            _mapController.move(widget.initialCenter, widget.initialZoom);
          } catch (e) {
            debugPrint('MapController move notice: $e');
          }
        }
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
                      color: const Color(0xFFDBEAFE),
                      borderColor: const Color(0xFF0056B3),
                      borderStrokeWidth: 2.5,
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
                        color: const Color(0xFFDBEAFE),
                        borderColor: const Color(0xFF0056B3),
                        borderStrokeWidth: 2.5,
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
                  width: 120,
                  height: 40,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF0056B3), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        brgyName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0056B3),
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
      color: const Color(0xFFF1F5F9),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 11.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(14.2000, 121.3600),
                  const LatLng(14.3600, 121.5500),
                ),
              ),
              onTap: (tapPosition, point) {
                if (widget.onTap != null) widget.onTap!(point);
              },
            ),
            children: [
              if (_isSatelliteMode) ...[
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.agriculture',
                  maxZoom: 18,
                  maxNativeZoom: 18,
                ),
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.agriculture',
                  maxZoom: 18,
                  maxNativeZoom: 18,
                ),
              ] else ...[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.agriculture',
                  maxZoom: 18,
                  maxNativeZoom: 18,
                ),
              ],
              if (_polygons.isNotEmpty || widget.extraPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    ..._polygons.map((p) => Polygon(
                      points: p.points,
                      color: _isSatelliteMode
                          ? Colors.blue.withValues(alpha: 0.12)
                          : const Color(0xFFDBEAFE).withValues(alpha: 0.35),
                      borderColor: _isSatelliteMode ? Colors.amberAccent : const Color(0xFF0056B3),
                      borderStrokeWidth: _isSatelliteMode ? 3.0 : 2.8,
                    )),
                    ...widget.extraPolygons,
                  ],
                ),
              if (allMarkers.isNotEmpty)
                MarkerLayer(markers: allMarkers),
            ],
          ),
          // SATELLITE & ZOOM FLOATING BUTTONS
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SATELLITE / STREET MAP TOGGLE
                FloatingActionButton.small(
                  heroTag: 'map_mode_toggle_${identityHashCode(this)}',
                  backgroundColor: _isSatelliteMode ? const Color(0xFF0284C7) : const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  tooltip: _isSatelliteMode ? 'Switch to Street Map' : 'Switch to Satellite View',
                  onPressed: () {
                    setState(() {
                      _isSatelliteMode = !_isSatelliteMode;
                    });
                  },
                  child: Icon(
                    _isSatelliteMode ? Icons.map_rounded : Icons.satellite_alt_rounded,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in_${identityHashCode(this)}',
                  backgroundColor: const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom In (+)',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    if (currentZoom < 18.0) {
                      final newZoom = math.min(18.0, currentZoom + 1.0);
                      _mapController.move(_mapController.camera.center, newZoom);
                    }
                  },
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out_${identityHashCode(this)}',
                  backgroundColor: const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom Out (-)',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    if (currentZoom > 11.0) {
                      final newZoom = math.max(11.0, currentZoom - 1.0);
                      _mapController.move(_mapController.camera.center, newZoom);
                    }
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
        title: const Text('Pagsanjan Official Municipal Boundary Map'),
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
        title: const Text('Pagsanjan Official Municipal Boundary Map'),
        backgroundColor: const Color(0xFF0056B3),
      ),
      body: const PagsanjanMapWidget(
        initialCenter: LatLng(14.2790, 121.4550),
        initialZoom: 13.5,
      ),
    );
  }
}
