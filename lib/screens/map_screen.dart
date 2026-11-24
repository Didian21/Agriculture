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
  final MapController? mapController;

  const PagsanjanMapWidget({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const [],
    this.extraPolygons = const [],
    this.extraPolylines = const [],
    this.onTap,
    this.mapController,
  });

  @override
  State<PagsanjanMapWidget> createState() => _PagsanjanMapWidgetState();
}

class _PagsanjanMapWidgetState extends State<PagsanjanMapWidget> {
  late final MapController _mapController;
  static List<Polygon>? _cachedBoundaryPolygons;
  static List<Marker>? _cachedBarangayLabelMarkers;

  bool _isSatelliteMode = true;
  List<Polygon> _polygons = _cachedBoundaryPolygons ?? [];
  List<Marker> _barangayLabelMarkers = _cachedBarangayLabelMarkers ?? [];

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
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
              // Dynamic Map Tile Layer (Satellite vs OpenStreetMap Street Map)
              TileLayer(
                urlTemplate: _isSatelliteMode
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
          // ZOOM FLOATING BUTTONS
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ZOOM IN BUTTON
                FloatingActionButton.small(
                  heroTag: 'map_zoom_shortcut_${identityHashCode(this)}',
                  backgroundColor: const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  tooltip: 'Zoom In',
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    if (currentZoom < 18.0) {
                      final newZoom = math.min(18.0, currentZoom + 1.0);
                      _mapController.move(_mapController.camera.center, newZoom);
                    }
                  },
                  child: const Icon(Icons.zoom_in_rounded, size: 20),
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
  final List<List<LatLng>> initialPlots;
  final List<FarmRecord> existingFarms;
  final Color primaryColor;

  const PagsanjanMapBoundaryPickerScreen({
    super.key,
    required this.initialCenter,
    this.initialBoundary = const [],
    this.initialPlots = const [],
    this.existingFarms = const [],
    this.primaryColor = const Color(0xFF166534),
  });

  @override
  State<PagsanjanMapBoundaryPickerScreen> createState() => _PagsanjanMapBoundaryPickerScreenState();
}

class _PagsanjanMapBoundaryPickerScreenState extends State<PagsanjanMapBoundaryPickerScreen> {
  late final List<List<LatLng>> _plots = () {
    if (widget.initialPlots.isNotEmpty) {
      return widget.initialPlots.map((p) => List<LatLng>.from(p)).toList();
    }
    if (widget.initialBoundary.isNotEmpty) {
      return [List<LatLng>.from(widget.initialBoundary)];
    }
    return [<LatLng>[]];
  }();
  int _activePlotIndex = 0;
  final TextEditingController _targetAreaCtrl = TextEditingController();
  bool _isHectaresUnit = true;

  List<LatLng> get _currentBoundaryPoints => _plots[_activePlotIndex];

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

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return widget.initialCenter;
    double sumLat = 0;
    double sumLng = 0;
    for (final p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  void _generatePlotForTargetArea(double targetValue, bool isHa) {
    final targetSqM = isHa ? (targetValue * 10000.0) : targetValue;
    if (targetSqM <= 0) return;

    final center = _currentBoundaryPoints.isNotEmpty
        ? _calculateCentroid(_currentBoundaryPoints)
        : widget.initialCenter;

    final sideM = math.sqrt(targetSqM);
    final latOffset = (sideM / 2.0) / 111320.0;
    final lonOffset = (sideM / 2.0) / (111320.0 * math.cos(center.latitude * math.pi / 180.0));

    setState(() {
      _currentBoundaryPoints.clear();
      _currentBoundaryPoints.addAll([
        LatLng(center.latitude - latOffset, center.longitude - lonOffset),
        LatLng(center.latitude - latOffset, center.longitude + lonOffset),
        LatLng(center.latitude + latOffset, center.longitude + lonOffset),
        LatLng(center.latitude + latOffset, center.longitude - lonOffset),
      ]);
    });
  }

  void _showPresetAreaModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.square_foot_rounded, color: Color(0xFF166534)),
              SizedBox(width: 8),
              Text('I-set ang Sukat (ha / m²)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Hektarya (ha)')),
                  ButtonSegment(value: false, label: Text('Sq. Meters (m²)')),
                ],
                selected: {_isHectaresUnit},
                onSelectionChanged: (s) => setModalState(() => _isHectaresUnit = s.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _targetAreaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _isHectaresUnit ? 'Target Area sa Hektarya (ha)' : 'Target Area sa Square Meters (m²)',
                  hintText: _isHectaresUnit ? 'halimbawa: 1.5' : 'halimbawa: 15000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: _isHectaresUnit ? 'ha' : 'm²',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kanselahin', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('I-apply sa Mapa', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final val = double.tryParse(_targetAreaCtrl.text.trim()) ?? 0.0;
                if (val > 0) {
                  _generatePlotForTargetArea(val, _isHectaresUnit);
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sqM = _calcAreaSqM(_currentBoundaryPoints);
    final ha = sqM / 10000.0;
    final nf = NumberFormat('#,###');
    final overlappingFarm = _findOverlappingFarm(_currentBoundaryPoints);

    return Scaffold(
      appBar: AppBar(
        title: Text(_plots.length > 1 ? 'I-set ang Boundary (Lote ${_activePlotIndex + 1}/${_plots.length})' : 'I-set ang Boundary ng Sakahan'),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'I-set ang Sukat (ha / m²)',
            icon: const Icon(Icons.aspect_ratio_rounded),
            onPressed: _showPresetAreaModal,
          ),
          if (_currentBoundaryPoints.isNotEmpty)
            IconButton(
              tooltip: 'I-undo',
              icon: const Icon(Icons.undo_rounded),
              onPressed: () => setState(() => _currentBoundaryPoints.removeLast()),
            ),
          if (_currentBoundaryPoints.isNotEmpty)
            IconButton(
              tooltip: 'Linisin',
              icon: const Icon(Icons.clear_all_rounded),
              onPressed: () => setState(() => _currentBoundaryPoints.clear()),
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
              for (int pIdx = 0; pIdx < _plots.length; pIdx++)
                if (_plots[pIdx].length >= 3)
                  Polygon(
                    points: _plots[pIdx],
                    color: (pIdx == _activePlotIndex && overlappingFarm != null)
                        ? Colors.red.withValues(alpha: 0.4)
                        : (pIdx == _activePlotIndex ? const Color(0xFF0284C7).withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.2)),
                    borderColor: (pIdx == _activePlotIndex && overlappingFarm != null) ? Colors.red : (pIdx == _activePlotIndex ? widget.primaryColor : Colors.green),
                    borderStrokeWidth: pIdx == _activePlotIndex ? 3.5 : 2.0,
                  ),
            ],
            extraPolylines: [
              for (int pIdx = 0; pIdx < _plots.length; pIdx++)
                if (_plots[pIdx].length >= 2)
                  Polyline(
                    points: _plots[pIdx].length >= 3 ? [..._plots[pIdx], _plots[pIdx].first] : _plots[pIdx],
                    color: (pIdx == _activePlotIndex && overlappingFarm != null) ? Colors.red : (pIdx == _activePlotIndex ? widget.primaryColor : Colors.green),
                    strokeWidth: pIdx == _activePlotIndex ? 3.5 : 2.0,
                  ),
            ],
            markers: [
              ..._currentBoundaryPoints.asMap().entries.map((e) {
                final index = e.key;
                final currentPt = e.value;
                return Marker(
                  point: currentPt,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      final latShift = -details.delta.dy * (360.0 / (256.0 * math.pow(2, 15.5)));
                      final lngShift = details.delta.dx * (360.0 / (256.0 * math.pow(2, 15.5) * math.cos(currentPt.latitude * math.pi / 180.0)));
                      setState(() {
                        _currentBoundaryPoints[index] = LatLng(
                          currentPt.latitude + latShift,
                          currentPt.longitude + lngShift,
                        );
                      });
                    },
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: widget.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            onTap: (point) => setState(() => _currentBoundaryPoints.add(point)),
          ),

          // MULTI-PLOT TABS BAR (When farmer has multiple separate land parcels)
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int pIdx = 0; pIdx < _plots.length; pIdx++) ...[
                    ChoiceChip(
                      selected: _activePlotIndex == pIdx,
                      avatar: Icon(Icons.landscape_rounded, size: 16, color: _activePlotIndex == pIdx ? Colors.white : widget.primaryColor),
                      label: Text('Lote ${pIdx + 1}${_plots[pIdx].length >= 3 ? ' (${(_calcAreaSqM(_plots[pIdx]) / 10000.0).toStringAsFixed(2)} ha)' : ''}'),
                      selectedColor: widget.primaryColor,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, color: _activePlotIndex == pIdx ? Colors.white : Colors.black87),
                      onSelected: (_) => setState(() => _activePlotIndex = pIdx),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ActionChip(
                    avatar: const Icon(Icons.add_location_alt_rounded, size: 16, color: Color(0xFF166534)),
                    label: const Text('➕ Magdagdag pa ng Lote', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    backgroundColor: const Color(0xFFDCFCE7),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    onPressed: () {
                      setState(() {
                        _plots.add([]);
                        _activePlotIndex = _plots.length - 1;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Status & Area Banner
          Positioned(
            left: 16,
            right: 16,
            top: 68,
            child: Card(
              color: overlappingFarm != null ? const Color(0xFFFEF2F2) : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      overlappingFarm != null ? Icons.error_outline_rounded : Icons.touch_app_rounded,
                      color: overlappingFarm != null ? const Color(0xFFDC2626) : widget.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        overlappingFarm != null
                            ? '⚠️ SUMASAGASA SA IBA: Naki-overlap sa sakahan ni ${overlappingFarm.farmerName} (${overlappingFarm.barangay})!'
                            : _currentBoundaryPoints.length < 3
                            ? 'Mag-tap sa mapa para i-set ang punto, o i-click ang 📐 button sa itaas para i-set ang ha/m².'
                            : '🌾 Lote ${_activePlotIndex + 1} Sukat: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: overlappingFarm != null
                              ? const Color(0xFF991B1B)
                              : _currentBoundaryPoints.length >= 3 ? const Color(0xFF16A34A) : const Color(0xFF0369A1),
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
                  backgroundColor: (overlappingFarm != null || _currentBoundaryPoints.length < 3) ? Colors.grey : widget.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 22),
                label: Text(
                  _currentBoundaryPoints.length < 3
                      ? 'Kailangan ng 3 puntos sa mapa'
                      : overlappingFarm != null
                      ? 'Bawal mag-overlap sa ibang sakahan'
                      : 'I-confirm ang Boundary (Lote ${_activePlotIndex + 1})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: (overlappingFarm != null || _currentBoundaryPoints.length < 3)
                    ? null
                    : () {
                        final validPlots = _plots.where((p) => p.length >= 3).toList();
                        Navigator.pop(context, validPlots);
                      },
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
