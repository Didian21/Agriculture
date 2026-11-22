import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/farmer.dart';
import '../services/account_service.dart';

class BarangayResolver {
  static List<MapEntry<String, List<LatLng>>>? _cachedPolygons;

  static final Map<String, LatLng> barangayCenters = {
    'Anibong': const LatLng(14.2855, 121.4682),
    'Biñan': const LatLng(14.2750, 121.4580),
    'Buboy': const LatLng(14.2950, 121.4420),
    'Cabanbanan': const LatLng(14.2620, 121.4650),
    'Calusiche': const LatLng(14.2980, 121.4580),
    'Dingin': const LatLng(14.2880, 121.4350),
    'Lambac': const LatLng(14.2680, 121.4420),
    'Layugan': const LatLng(14.2710, 121.4480),
    'Magdapio': const LatLng(14.2650, 121.4380),
    'Maulawin': const LatLng(14.2780, 121.4410),
    'Maytalang I': const LatLng(14.2810, 121.4590),
    'Maytalang II': const LatLng(14.2840, 121.4620),
    'Poblacion Uno': const LatLng(14.2785, 121.4515),
    'Poblacion Dos': const LatLng(14.2760, 121.4530),
    'Sampaloc': const LatLng(14.2910, 121.4510),
    'San Isidro': const LatLng(14.2630, 121.4520),
  };

  static bool _isPointInPoly(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      if ((pi.longitude > point.longitude) != (pj.longitude > point.longitude) &&
          (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / (pj.longitude - pi.longitude) + pi.latitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  static Future<void> ensureLoaded() async {
    if (_cachedPolygons != null && _cachedPolygons!.isNotEmpty) return;
    try {
      final String response = await rootBundle.loadString('assets/MAP/Boundary_Pagsanjan.geojson');
      final data = json.decode(response);
      List<MapEntry<String, List<LatLng>>> parsed = [];

      if (data['features'] != null) {
        for (final feature in data['features']) {
          final geometry = feature['geometry'];
          final properties = feature['properties'] ?? {};
          final rawName = (properties['name'] ?? properties['official_name'] ?? properties['BARANGAY'] ?? properties['NAME_3'] ?? properties['NAME_2'] ?? '').toString().trim();
          final brgyName = AccountService.normalizeBarangay(rawName);

          // Skip municipality-level outer boundary feature so only specific barangay rings match
          if (rawName.isEmpty || rawName == 'Pagsanjan' || rawName.contains('Municipality') || rawName.contains('Bayan ng')) {
            continue;
          }

          if (geometry != null) {
            final type = geometry['type'];
            final coordinates = geometry['coordinates'];

            if (type == 'Polygon') {
              for (int r = 0; r < coordinates.length; r++) {
                final ring = coordinates[r];
                List<LatLng> points = [];
                for (final coord in ring) {
                  points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
                }
                if (points.length >= 3) {
                  parsed.add(MapEntry(brgyName, points));
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
                  if (points.length >= 3) {
                    parsed.add(MapEntry(brgyName, points));
                  }
                }
              }
            }
          }
        }
      }
      _cachedPolygons = parsed;
    } catch (e) {
      debugPrint('Error caching GeoJSON in BarangayResolver: $e');
    }
  }

  static String resolveBarangay(LatLng point) {
    if (_cachedPolygons != null) {
      for (final entry in _cachedPolygons!) {
        if (_isPointInPoly(point, entry.value)) {
          final norm = AccountService.normalizeBarangay(entry.key);
          if (AccountService.pagsanjanBarangays.contains(norm)) {
            return norm;
          }
        }
      }
    }

    String closest = 'Biñan';
    double minDist = double.infinity;
    for (final entry in barangayCenters.entries) {
      final dist = const Distance().as(LengthUnit.Kilometer, point, entry.value);
      if (dist < minDist) {
        minDist = dist;
        closest = entry.key;
      }
    }
    return AccountService.normalizeBarangay(closest);
  }
}

class PagsanjanMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final List<Polygon> extraPolygons;
  final List<Polyline> extraPolylines;
  final void Function(LatLng)? onTap;

  const PagsanjanMapWidget({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const [],
    this.extraPolygons = const [],
    this.extraPolylines = const [],
    this.onTap,
  });

  @override
  State<PagsanjanMapWidget> createState() => _PagsanjanMapWidgetState();
}

class _PagsanjanMapWidgetState extends State<PagsanjanMapWidget> {
  final MapController _mapController = MapController();
  static List<Polygon>? _cachedBoundaryPolygons;
  static List<Marker>? _cachedBarangayLabelMarkers;

  List<Polygon> _polygons = _cachedBoundaryPolygons ?? [];
  List<Marker> _barangayLabelMarkers = _cachedBarangayLabelMarkers ?? [];
  bool _isSatelliteMode = false;

  @override
  void initState() {
    super.initState();
    if (_cachedBoundaryPolygons != null && _cachedBoundaryPolygons!.isNotEmpty) {
      _polygons = _cachedBoundaryPolygons!;
      _barangayLabelMarkers = _cachedBarangayLabelMarkers ?? [];
    }
    _loadBoundaryGeoJson();
  }

  @override
  void didUpdateWidget(covariant PagsanjanMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_polygons.isEmpty) {
      _loadBoundaryGeoJson();
    }
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
      await BarangayResolver.ensureLoaded();
      final String response = await rootBundle.loadString('assets/MAP/Boundary_Pagsanjan.geojson');
      final data = json.decode(response);
      List<Polygon> parsed = [];
      List<Marker> parsedLabels = [];

      if (data['features'] != null) {
        for (final feature in data['features']) {
          final geometry = feature['geometry'];
          final properties = feature['properties'] ?? {};
          final brgyName = (properties['name'] ?? properties['official_name'] ?? properties['BARANGAY'] ?? properties['NAME_3'] ?? properties['NAME_2'] ?? '').toString().trim();

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
                      color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                      borderColor: const Color(0xFF22C55E),
                      borderStrokeWidth: 3.5,
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
                        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                        borderColor: const Color(0xFF22C55E),
                        borderStrokeWidth: 3.5,
                      ),
                    );
                  }
                }
              }
            }

            if (firstRingPoints.isNotEmpty && brgyName.isNotEmpty && brgyName != 'Pagsanjan' && brgyName != 'Municipality of Pagsanjan' && brgyName != 'Bayan ng Pagsanjan') {
              final center = _calculateCentroid(firstRingPoints);
              parsedLabels.add(
                Marker(
                  point: center,
                  width: 120,
                  height: 38,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        brgyName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
      _cachedBoundaryPolygons = parsed;
      _cachedBarangayLabelMarkers = parsedLabels;
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
              if (_polygons.isNotEmpty || widget.extraPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    ..._polygons,
                    ...widget.extraPolygons,
                  ],
                ),
              if (widget.extraPolylines.isNotEmpty)
                PolylineLayer(polylines: widget.extraPolylines),
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
  final List<Polygon> extraPolygons;

  const PagsanjanMapScreen({
    super.key,
    this.markers = const [],
    this.extraPolygons = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagsanjan Official Municipal Boundary Map (Satellite)'),
        backgroundColor: const Color(0xFF0056B3),
        foregroundColor: Colors.white,
      ),
      body: PagsanjanMapWidget(
        initialCenter: const LatLng(14.2790, 121.4550),
        initialZoom: 14.0,
        markers: markers,
        extraPolygons: extraPolygons,
      ),
    );
  }
}

class PagsanjanMapBoundaryPickerScreen extends StatefulWidget {
  final LatLng initialCenter;
  final List<LatLng> initialBoundary;
  final List<FarmRecord> existingFarms;
  final Color primaryColor;

  const PagsanjanMapBoundaryPickerScreen({
    super.key,
    required this.initialCenter,
    this.initialBoundary = const [],
    this.existingFarms = const [],
    this.primaryColor = const Color(0xFF166534),
  });

  @override
  State<PagsanjanMapBoundaryPickerScreen> createState() => _PagsanjanMapBoundaryPickerScreenState();
}

class _PagsanjanMapBoundaryPickerScreenState extends State<PagsanjanMapBoundaryPickerScreen> {
  late final List<LatLng> _boundaryPoints = List.from(widget.initialBoundary);

  double _calcAreaSqM(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    const double radius = 6378137.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final lat1 = p1.latitude * math.pi / 180.0;
      final lat2 = p2.latitude * math.pi / 180.0;
      final lon1 = p1.longitude * math.pi / 180.0;
      final lon2 = p2.longitude * math.pi / 180.0;
      area += (lon2 - lon1) * (2.0 + math.sin(lat1) + math.sin(lat2));
    }
    return (area * radius * radius / 2.0).abs();
  }

  bool _doPolygonsOverlap(List<LatLng> poly1, List<LatLng> poly2) {
    if (poly1.length < 3 || poly2.length < 3) return false;
    bool isPointInPoly(LatLng point, List<LatLng> poly) {
      bool inside = false;
      int j = poly.length - 1;
      for (int i = 0; i < poly.length; i++) {
        final pi = poly[i];
        final pj = poly[j];
        if ((pi.longitude > point.longitude) != (pj.longitude > point.longitude) &&
            (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / (pj.longitude - pi.longitude) + pi.latitude)) {
          inside = !inside;
        }
        j = i;
      }
      return inside;
    }
    for (final p in poly1) {
      if (isPointInPoly(p, poly2)) return true;
    }
    for (final p in poly2) {
      if (isPointInPoly(p, poly1)) return true;
    }
    return false;
  }

  FarmRecord? _findOverlappingFarm(List<LatLng> pts) {
    if (pts.length < 3) return null;
    for (final farm in widget.existingFarms) {
      if (farm.boundaryPoints.length >= 3) {
        if (_doPolygonsOverlap(pts, farm.boundaryPoints)) {
          return farm;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sqM = _calcAreaSqM(_boundaryPoints);
    final ha = sqM / 10000.0;
    final nf = NumberFormat('#,###');
    final overlappingFarm = _findOverlappingFarm(_boundaryPoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('I-set ang Boundary ng Sakahan'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_boundaryPoints.isNotEmpty)
            IconButton(
              tooltip: 'I-undo',
              icon: const Icon(Icons.undo_rounded),
              onPressed: () => setState(() => _boundaryPoints.removeLast()),
            ),
          if (_boundaryPoints.isNotEmpty)
            IconButton(
              tooltip: 'Linisin',
              icon: const Icon(Icons.clear_all_rounded),
              onPressed: () => setState(() => _boundaryPoints.clear()),
            ),
        ],
      ),
      body: Stack(
        children: [
          PagsanjanMapWidget(
            initialCenter: widget.initialCenter,
            initialZoom: 15.5,
            extraPolygons: [
              ...widget.existingFarms.where((f) => f.boundaryPoints.length >= 3).map((f) => Polygon(
                points: f.boundaryPoints,
                color: Colors.red.withValues(alpha: 0.15),
                borderColor: Colors.redAccent,
                borderStrokeWidth: 2.0,
              )),
              if (_boundaryPoints.length >= 3)
                Polygon(
                  points: _boundaryPoints,
                  color: overlappingFarm != null
                      ? Colors.red.withValues(alpha: 0.4)
                      : const Color(0xFF0284C7).withValues(alpha: 0.3),
                  borderColor: overlappingFarm != null ? Colors.red : widget.primaryColor,
                  borderStrokeWidth: 3.5,
                ),
            ],
            extraPolylines: _boundaryPoints.length >= 2
                ? [
                    Polyline(
                      points: _boundaryPoints.length >= 3
                          ? [..._boundaryPoints, _boundaryPoints.first]
                          : _boundaryPoints,
                      color: overlappingFarm != null ? Colors.red : widget.primaryColor,
                      strokeWidth: 3.5,
                    ),
                  ]
                : [],
            markers: [
              ..._boundaryPoints.asMap().entries.map((e) => Marker(
                    point: e.value,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )),
            ],
            onTap: (point) => setState(() => _boundaryPoints.add(point)),
          ),

          // Banner Status
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              color: overlappingFarm != null ? const Color(0xFFFEF2F2) : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      overlappingFarm != null ? Icons.error_outline_rounded : Icons.touch_app_rounded,
                      color: overlappingFarm != null ? const Color(0xFFDC2626) : widget.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        overlappingFarm != null
                            ? '⚠️ SUMASAGASA SA IBA: Naki-overlap sa sakahan ni ${overlappingFarm.farmerName} (${overlappingFarm.barangay})!'
                            : _boundaryPoints.length < 3
                            ? 'Mag-tap ng 3 o higit pang punto sa mapa para iguhit ang boundary.'
                            : '🌾 Na-mapang Sukat: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: overlappingFarm != null
                              ? const Color(0xFF991B1B)
                              : _boundaryPoints.length >= 3 ? const Color(0xFF16A34A) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (overlappingFarm != null || _boundaryPoints.length < 3) ? Colors.grey : widget.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  _boundaryPoints.length < 3
                      ? 'Kailangan ng 3 puntos'
                      : overlappingFarm != null
                      ? 'Bawal mag-overlap sa iba'
                      : 'I-confirm ang Boundary',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: (overlappingFarm != null || _boundaryPoints.length < 3)
                    ? null
                    : () => Navigator.pop(context, _boundaryPoints),
              ),
            ),
          ),
        ],
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
