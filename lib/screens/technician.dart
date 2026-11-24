import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../dashboard_data.dart';
import '../models/farmer.dart';
import '../services/account_service.dart';
import 'map_screen.dart';

class TechnicianVisit {
  final String id;
  final String farmerId;
  final String farmerName;
  final String barangay;
  final String cropType;
  final DateTime scheduledDate;
  final String purpose;
  String findings;
  String status; // 'Scheduled', 'Completed', 'Cancelled'

  TechnicianVisit({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.barangay,
    required this.cropType,
    required this.scheduledDate,
    required this.purpose,
    this.findings = '',
    this.status = 'Scheduled',
  });
}

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

  @override
  State<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen> {
  int _selectedIndex = 0; // 0 = Field Visits, 1 = Farm Monitoring, 2 = Interactive Map, 3 = DSS Advisory
  String _searchQuery = '';
  String _selectedBarangayFilter = 'All';
  String _selectedAssociationFilter = 'All';

  // Technician Live Real Device GPS Location State
  LatLng _technicianGpsLocation = const LatLng(14.2750, 121.4530);
  bool _isGpsEnabled = false;
  StreamSubscription<Position>? _gpsStreamSubscription;

  // Interactive Map State
  bool _showRegisteredPins = true;
  bool _showMapSidePanel = true;
  LatLng _mapCenter = const LatLng(14.2790, 121.4550);
  double _mapZoom = 13.5;
  final MapController _techMapController = MapController();

  // Field Visits Data State
  final List<TechnicianVisit> _manualVisits = [];

  // Selected Crop for DSS Advisory
  String _dssSelectedCrop = 'Rice';
  String _dssSelectedStage = 'Vegetative Stage';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AccountService>(context, listen: false).loadFromSupabase();
      }
    });
  }

  @override
  void dispose() {
    _gpsStreamSubscription?.cancel();
    super.dispose();
  }

  // Dynamically get visits combining database farmers & manual visits
  List<TechnicianVisit> _getEffectiveVisits(AccountService service) {
    final list = <TechnicianVisit>[];

    // 1. Add manual visits that are still pending
    for (final v in _manualVisits) {
      if (v.status != 'Completed') {
        list.add(v);
      }
    }

    // 2. Add pending visit tasks ONLY for farmers who have unmapped farm lots
    for (int i = 0; i < service.farmers.length; i++) {
      final farmer = service.farmers[i];
      final farmerFarms = service.farms.where((f) => f.farmerId == farmer.id || f.farmerName.toLowerCase() == farmer.profileName.toLowerCase()).toList();

      final unmappedLots = farmerFarms.isEmpty || farmerFarms.any((f) => f.boundaryPoints.isEmpty);
      final missingSoil = farmerFarms.isNotEmpty && farmerFarms.any((f) => f.boundaryPoints.isNotEmpty && (f.soilType.isEmpty || f.soilType == 'N/A'));

      if (unmappedLots || missingSoil) {
        final existing = list.any((v) => v.farmerId == farmer.id || v.farmerName.toLowerCase() == farmer.profileName.toLowerCase());
        if (!existing) {
          final cropStr = farmerFarms.isNotEmpty ? farmerFarms.map((f) => f.cropType).toSet().join(', ') : 'Rice';
          final specificMissing = service.isTagalog
              ? (unmappedLots ? '⚠️ Kulang: Boundary Mapping' : '⚠️ Kulang: Uri ng Lupa (Soil Type)')
              : (unmappedLots ? '⚠️ Missing: Boundary Mapping' : '⚠️ Missing: Soil Type');

          list.add(
            TechnicianVisit(
              id: 'V_${farmer.id}',
              farmerId: farmer.id,
              farmerName: farmer.profileName,
              barangay: farmer.barangay,
              cropType: cropStr,
              scheduledDate: DateTime.now().add(Duration(days: i % 5)),
              purpose: specificMissing,
              status: 'Scheduled',
              findings: '',
            ),
          );
        }
      }
    }

    return list;
  }

  List<String> _getUniqueDatabaseCrops(AccountService service) {
    final set = <String>{};
    for (final farm in service.farms) {
      final crop = farm.cropType.trim();
      if (crop.isNotEmpty && crop != 'N/A') {
        for (final item in crop.split(',')) {
          final clean = item.trim();
          if (clean.isNotEmpty) set.add(clean);
        }
      }
    }
    for (final h in service.historicalRecords) {
      final crop = h.crop.trim();
      if (crop.isNotEmpty) set.add(crop);
    }
    for (final m in service.marketPriceRecords) {
      final veg = m.vegetable.trim();
      if (veg.isNotEmpty) set.add(veg);
    }
    final list = set.toList()..sort();
    if (list.isEmpty) {
      return ['Rice', 'Talong (Eggplant)', 'Kamatis (Tomato)', 'Saging (Banana)', 'Sitaw (Yardlong Bean)'];
    }
    return list;
  }

  double calculatePolygonAreaSqM(List<LatLng> points) {
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
    area = (area * radius * radius / 2.0).abs();
    return area;
  }

  double calculatePolygonAreaHectares(List<LatLng> points) {
    return calculatePolygonAreaSqM(points) / 10000.0;
  }

  LatLng calculatePolygonCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(14.2790, 121.4550);
    double sumLat = 0;
    double sumLng = 0;
    for (final p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

  bool doLineSegmentsIntersect(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
    double ccw(LatLng a, LatLng b, LatLng c) {
      return (c.longitude - a.longitude) * (b.latitude - a.latitude) - (b.longitude - a.longitude) * (c.latitude - a.latitude);
    }
    final ccw1 = ccw(p1, p2, p3);
    final ccw2 = ccw(p1, p2, p4);
    final ccw3 = ccw(p3, p4, p1);
    final ccw4 = ccw(p3, p4, p2);
    if (((ccw1 > 0 && ccw2 < 0) || (ccw1 < 0 && ccw2 > 0)) &&
        ((ccw3 > 0 && ccw4 < 0) || (ccw3 < 0 && ccw4 > 0))) {
      return true;
    }
    return false;
  }

  bool doPolygonsOverlap(List<LatLng> poly1, List<LatLng> poly2) {
    if (poly1.length < 3 || poly2.length < 3) return false;
    for (int i = 0; i < poly1.length; i++) {
      final a = poly1[i];
      final b = poly1[(i + 1) % poly1.length];
      for (int j = 0; j < poly2.length; j++) {
        final c = poly2[j];
        final d = poly2[(j + 1) % poly2.length];
        if (doLineSegmentsIntersect(a, b, c, d)) return true;
      }
    }
    for (final p in poly1) {
      if (isPointInPolygon(p, poly2)) return true;
    }
    for (final p in poly2) {
      if (isPointInPolygon(p, poly1)) return true;
    }
    return false;
  }

  FarmRecord? findOverlappingFarm(List<LatLng> newPoly, List<FarmRecord> allFarms, {String? excludeFarmId, String? excludeFarmerId, String? excludeFarmerName}) {
    if (newPoly.length < 3) return null;
    for (final farm in allFarms) {
      if (excludeFarmId != null && farm.id == excludeFarmId) continue;
      if (excludeFarmerId != null && (farm.farmerId == excludeFarmerId || farm.farmerName.toLowerCase() == (excludeFarmerName ?? '').toLowerCase())) {
        continue; // Allow same owner's other parcels without flagging overlap error
      }
      if (farm.boundaryPoints.length >= 3) {
        if (doPolygonsOverlap(newPoly, farm.boundaryPoints)) return farm;
      }
    }
    return null;
  }

  LatLng _movePoint(MapController mapController, LatLng from, Offset delta) {
    try {
      final camera = mapController.camera;
      final screenPoint = camera.latLngToScreenPoint(from);
      final newScreenPoint = math.Point(screenPoint.x + delta.dx, screenPoint.y + delta.dy);
      return camera.pointToLatLng(newScreenPoint);
    } catch (_) {
      return from;
    }
  }

  void _addOrInsertPoint(LatLng p, List<LatLng> boundaryPoints) {
    if (boundaryPoints.length < 3) {
      boundaryPoints.add(p);
      return;
    }
    final k = math.cos(p.latitude * math.pi / 180);
    double distanceSqToSegment(LatLng a, LatLng b) {
      final ax = a.longitude * k, ay = a.latitude;
      final bx = b.longitude * k, by = b.latitude;
      final px = p.longitude * k, py = p.latitude;
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
      final cx = ax + t * dx, cy = ay + t * dy;
      return (px - cx) * (px - cx) + (py - cy) * (py - cy);
    }
    var bestIndex = 0;
    var minDistanceSq = double.infinity;
    for (var i = 0; i < boundaryPoints.length; i++) {
      final distSq = distanceSqToSegment(boundaryPoints[i], boundaryPoints[(i + 1) % boundaryPoints.length]);
      if (distSq < minDistanceSq) {
        minDistanceSq = distSq;
        bestIndex = i;
      }
    }
    boundaryPoints.insert(bestIndex + 1, p);
  }

  Marker _buildDraggableHandle(
    int i,
    LatLng point,
    MapController mapController,
    StateSetter setMapState,
    List<LatLng> boundaryPoints,
    Function(bool) setDraggingState,
  ) {
    return Marker(
      key: ValueKey('drag_handle_$i'),
      point: point,
      width: 52,
      height: 52,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => setDraggingState(true),
        onPointerUp: (_) => setDraggingState(false),
        onPointerCancel: (_) => setDraggingState(false),
        onPointerMove: (event) {
          try {
            final camera = mapController.camera;
            final currentScreenPoint = camera.latLngToScreenPoint(boundaryPoints[i]);
            final newScreenPoint = math.Point(
              currentScreenPoint.x + event.delta.dx,
              currentScreenPoint.y + event.delta.dy,
            );
            final newLatLng = camera.pointToLatLng(newScreenPoint);
            setMapState(() {
              boundaryPoints[i] = newLatLng;
            });
          } catch (_) {}
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            if (boundaryPoints.length <= 3) return;
            setMapState(() {
              boundaryPoints.removeAt(i);
            });
          },
          child: Container(
            width: 52,
            height: 52,
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0056B3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildTechnicianGpsMarker() {
    return Marker(
      point: _technicianGpsLocation,
      width: 48,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.my_location_rounded, color: Color(0xFF0056B3), size: 24),
        ),
      ),
    );
  }

  void _showEditFarmBoundaryDialog(BuildContext context, AccountService service, FarmRecord farm, bool isTagalog) {
    FarmRecord currentFarm = farm;
    final List<LatLng> boundaryPoints = List.from(currentFarm.boundaryPoints);
    String selectedSoilType = currentFarm.soilType.isNotEmpty ? currentFarm.soilType : 'Clay Loam';
    bool dialogGpsEnabled = _isGpsEnabled;
    bool isDraggingMarker = false;

    final soilTypes = ['Clay Loam', 'Sandy Loam', 'Clay', 'Loam', 'Silty Clay Loam'];
    final farmerFarms = service.farms.where((f) => f.farmerId == farm.farmerId || f.farmerName.toLowerCase() == farm.farmerName.toLowerCase()).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final mapController = MapController();
          final sqM = calculatePolygonAreaSqM(boundaryPoints);
          final ha = calculatePolygonAreaHectares(boundaryPoints);
          final nf = NumberFormat('#,###');
          final overlappingFarm = findOverlappingFarm(
            boundaryPoints,
            service.farms,
            excludeFarmId: currentFarm.id,
            excludeFarmerId: currentFarm.farmerId,
            excludeFarmerName: currentFarm.farmerName,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            backgroundColor: const Color(0xFFF8FAFC),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0056B3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.polyline_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTagalog ? 'I-plot ang Boundary & Uri ng Lupa - ${currentFarm.farmerName}' : 'Plot Farm Boundary & Soil Type - ${currentFarm.farmerName}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 650,
              height: 570,
              child: Column(
                children: [
                  if (farmerFarms.length >= 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: const Color(0xFFEFF6FF),
                      child: Row(
                        children: [
                          const Icon(Icons.holiday_village_rounded, color: Color(0xFF0056B3), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isTagalog ? 'Pumili ng Lupa ni ${currentFarm.farmerName}:' : 'Select Farm Lot:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0056B3)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: currentFarm.id,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: farmerFarms.map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text('${f.cropType} (${f.landAreaHectares} ha) - ${f.locationName}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )).toList(),
                              onChanged: (selectedId) {
                                if (selectedId != null && selectedId != currentFarm.id) {
                                  final newSelectedFarm = farmerFarms.firstWhere((f) => f.id == selectedId);
                                  setDialogState(() {
                                    currentFarm = newSelectedFarm;
                                    boundaryPoints.clear();
                                    boundaryPoints.addAll(newSelectedFarm.boundaryPoints);
                                    selectedSoilType = newSelectedFarm.soilType.isNotEmpty ? newSelectedFarm.soilType : 'Clay Loam';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFF1F5F9),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            boundaryPoints.length < 3
                                ? (isTagalog ? 'I-tap ang mapa para iguhit ang boundary (3+ puntos). I-drag ang mga puntos para mag-adjust.' : 'Tap map to draw boundary (3+ points). Drag points to adjust.')
                                : (isTagalog ? '🌾 Sukat: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²) • ✋ I-drag ang mga puntos (1, 2, 3...) para baguhin ang boundary!' : '🌾 Area: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²) • ✋ Drag handles (1, 2, 3...) to adjust boundary!'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: boundaryPoints.length >= 3 ? const Color(0xFF16A34A) : const Color(0xFF0284C7)),
                          ),
                        ),
                        if (boundaryPoints.isNotEmpty) ...[
                          IconButton(
                            tooltip: isTagalog ? 'I-undo ang Huling Punto' : 'Undo Last Point',
                            icon: const Icon(Icons.undo_rounded, color: Color(0xFF0056B3)),
                            onPressed: () {
                              setDialogState(() {
                                if (boundaryPoints.isNotEmpty) {
                                  boundaryPoints.removeLast();
                                }
                              });
                            },
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            onPressed: () => setDialogState(() => boundaryPoints.clear()),
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: Text(isTagalog ? 'Linisin' : 'Clear'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: soilTypes.contains(selectedSoilType) ? selectedSoilType : 'Clay Loam',
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Uri ng Lupa (Soil Type)' : 'Soil Type Classification',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setDialogState(() => selectedSoilType = val ?? 'Clay Loam'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: dialogGpsEnabled ? const Color(0xFF16A34A) : const Color(0xFF0056B3),
                            side: BorderSide(color: dialogGpsEnabled ? const Color(0xFF16A34A) : const Color(0xFF0056B3)),
                          ),
                          onPressed: () async {
                            try {
                              Position pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
                              setDialogState(() {
                                dialogGpsEnabled = true;
                                _technicianGpsLocation = LatLng(pos.latitude, pos.longitude);
                                _addOrInsertPoint(_technicianGpsLocation, boundaryPoints);
                              });
                            } catch (_) {
                              setDialogState(() {
                                dialogGpsEnabled = true;
                                _addOrInsertPoint(_mapCenter, boundaryPoints);
                              });
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: Text(isTagalog ? 'Gamitin ang GPS' : 'Use GPS Pin'),
                        ),
                      ],
                    ),
                  ),
                  if (overlappingFarm != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFFFEF2F2),
                      child: Text(
                        '⚠️ OVERLAP: Naka-overlap sa sakahan ni ${overlappingFarm.farmerName}!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                    ),
                  Expanded(
                    child: PagsanjanMapWidget(
                      initialCenter: farm.latitude != 0 ? LatLng(farm.latitude, farm.longitude) : const LatLng(14.2790, 121.4550),
                      initialZoom: 16.5,
                      mapController: mapController,
                      isDraggingMarker: isDraggingMarker,
                      extraPolygons: [
                        ...service.farms.where((f) => f.id != farm.id && f.boundaryPoints.length >= 3).map((f) {
                          final isSameOwner = f.farmerId == farm.farmerId || f.farmerName.toLowerCase() == farm.farmerName.toLowerCase();
                          return Polygon(
                            points: f.boundaryPoints,
                            color: isSameOwner
                                ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                                : Colors.red.withValues(alpha: 0.15),
                            borderColor: isSameOwner ? const Color(0xFF16A34A) : Colors.redAccent,
                            borderStrokeWidth: 2.5,
                          );
                        }),
                        if (boundaryPoints.length >= 3)
                          Polygon(
                            points: boundaryPoints,
                            color: overlappingFarm != null ? Colors.red.withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.35),
                            borderColor: overlappingFarm != null ? Colors.red : const Color(0xFF0056B3),
                            borderStrokeWidth: 3.0,
                          ),
                      ],
                      extraPolylines: boundaryPoints.length >= 2
                          ? [
                              Polyline(
                                points: boundaryPoints.length >= 3 ? [...boundaryPoints, boundaryPoints.first] : boundaryPoints,
                                color: overlappingFarm != null ? Colors.red : const Color(0xFF0056B3),
                                strokeWidth: 3.5,
                              )
                            ]
                          : [],
                      markers: [
                        if (dialogGpsEnabled) _buildTechnicianGpsMarker(),
                        for (int i = 0; i < boundaryPoints.length; i++)
                          _buildDraggableHandle(i, boundaryPoints[i], mapController, setDialogState, boundaryPoints, (dragging) => isDraggingMarker = dragging),
                      ],
                      onTap: (point) {
                        if (isDraggingMarker) return;
                        try {
                          final camera = mapController.camera;
                          final tapScreen = camera.latLngToScreenPoint(point);
                          for (final p in boundaryPoints) {
                            final pScreen = camera.latLngToScreenPoint(p);
                            final dx = tapScreen.x - pScreen.x;
                            final dy = tapScreen.y - pScreen.y;
                            if (dx * dx + dy * dy < 30 * 30) {
                              return; // Tapped near an existing handle - do not add point!
                            }
                          }
                        } catch (_) {}

                        setDialogState(() {
                          _addOrInsertPoint(point, boundaryPoints);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isTagalog ? 'Kanselahin' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (overlappingFarm != null || boundaryPoints.length < 3) ? Colors.grey : const Color(0xFF0056B3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(isTagalog ? 'I-save ang Lupa at Uri ng Lupa' : 'Save Farm & Soil Type', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: (overlappingFarm != null || boundaryPoints.length < 3)
                    ? null
                    : () async {
                        await BarangayResolver.ensureLoaded();
                        final centroid = calculatePolygonCentroid(boundaryPoints);
                        final computedHa = calculatePolygonAreaHectares(boundaryPoints);
                        final rawBrgy = BarangayResolver.resolveBarangay(centroid);
                        final detectedBrgy = AccountService.normalizeBarangay(rawBrgy);

                        await service.updateFarmRecord(
                          currentFarm.id,
                          locationName: currentFarm.locationName.isEmpty ? 'Farm Lot, Brgy. $detectedBrgy, Pagsanjan' : currentFarm.locationName,
                          landAreaHectares: computedHa > 0 ? double.parse(computedHa.toStringAsFixed(2)) : currentFarm.landAreaHectares,
                          tenureStatus: currentFarm.tenureStatus,
                          cropType: currentFarm.cropType,
                          barangay: detectedBrgy,
                          latitude: centroid.latitude,
                          longitude: centroid.longitude,
                          boundaryPoints: boundaryPoints,
                          soilType: selectedSoilType,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Matagumpay na na-update ang sakahan at uri ng lupa ($selectedSoilType) ni ${currentFarm.farmerName}!'
                                    : 'Successfully updated farm and soil type ($selectedSoilType) for ${currentFarm.farmerName}!',
                              ),
                              backgroundColor: const Color(0xFF0056B3),
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AccountService>(context);
    final isDark = service.isDarkMode;
    final isTagalog = service.isTagalog;

    final cardBg = isDark ? const Color(0xFF121E31) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBorder = isDark ? const Color(0xFF1E2E4A) : const Color(0xFFD0E1F9);
    const primaryAccent = Color(0xFF0056B3);

    final titleStr = isTagalog ? 'Portal ng Technician (MAO)' : 'Agricultural Technician Portal';
    final subtitleStr = isTagalog ? 'Tanggapan ng Agrikultura ng Pagsanjan' : 'Municipal Agriculture Office (MAO)';

    Widget bodyWidget;
    switch (_selectedIndex) {
      case 0:
        bodyWidget = _buildFieldVisitsView(service, isTagalog, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 1:
        bodyWidget = _buildMonitoringView(service, isTagalog, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 2:
        bodyWidget = _buildInteractiveMapView(service, isTagalog, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 3:
        bodyWidget = _buildDssAdvisoryView(service, isTagalog, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      default:
        bodyWidget = _buildFieldVisitsView(service, isTagalog, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A111E) : const Color(0xFFF0F4F9),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? const Color(0xFF081427) : const Color(0xFF0056B3),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'Pagri.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.agriculture_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titleStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(subtitleStr, style: const TextStyle(fontSize: 11, color: Color(0xFFBFDBFE))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () async {
              await service.loadFromSupabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTagalog ? 'Na-sync na ang pinakabagong datos mula sa mga magsasaka at admin!' : 'Synchronized latest data from farmers & admin!'),
                    backgroundColor: const Color(0xFF0056B3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: Text(isTagalog ? 'I-sync' : 'Sync', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.language_rounded, size: 18),
            label: Text(isTagalog ? '🇵🇭 Tagalog' : '🇺🇸 English', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () {
              service.toggleLanguage();
              try {
                final p = Provider.of<DashboardProvider>(context, listen: false);
                p.setLanguage(service.isTagalog ? AppLanguage.tagalog : AppLanguage.english);
              } catch (_) {}
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Theme Toggle',
            onPressed: () => service.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/thank_you'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: const Color(0xFF0056B3).withValues(alpha: 0.18),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.assignment_ind_outlined),
            selectedIcon: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF0056B3)),
            label: isTagalog ? 'Pagbisita sa Bukid' : 'Field Visits',
          ),
          NavigationDestination(
            icon: const Icon(Icons.nature_people_outlined),
            selectedIcon: const Icon(Icons.nature_people_rounded, color: Color(0xFF0056B3)),
            label: isTagalog ? 'Pagsubaybay sa Tanim' : 'Farm Monitoring',
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded, color: Color(0xFF0056B3)),
            label: isTagalog ? 'Interaktibong Mapa' : 'Interactive Map',
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            selectedIcon: const Icon(Icons.psychology_rounded, color: Color(0xFF0056B3)),
            label: isTagalog ? 'Payo at DSS Advisory' : 'Crop & DSS Advisory',
          ),
        ],
      ),
      body: bodyWidget,
    );
  }

  // ==========================================
  // MODULE 1: FIELD VISITS (PAGBISITA SA BUKID)
  // ==========================================
  Widget _buildFieldVisitsView(
    AccountService service,
    bool isTagalog,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final effectiveVisits = _getEffectiveVisits(service);
    final filteredVisits = effectiveVisits.where((v) {
      final isPending = v.status != 'Completed';
      final matchesBrgy = _selectedBarangayFilter == 'All' || v.barangay.toLowerCase() == _selectedBarangayFilter.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty || v.farmerName.toLowerCase().contains(query) || v.purpose.toLowerCase().contains(query);
      return isPending && matchesBrgy && matchesQuery;
    }).toList();

    final pendingVisitsCount = filteredVisits.length;
    final coveredBarangaysCount = filteredVisits.map((v) => v.barangay).toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TECHNICIAN FIELDWORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    isTagalog ? 'Pagbisita sa Sakahan (Field Visits)' : 'Field Visits & Inspection Logs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _showScheduleVisitDialog(context, service, isTagalog),
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: Text(
                  isTagalog ? 'Mag-iskedyul ng Pagbisita' : 'Schedule Field Visit',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SUMMARY CARDS
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: isTagalog ? 'Pending na Pagbisita' : 'Pending Field Visits',
                  value: '$pendingVisitsCount',
                  icon: Icons.event_note_rounded,
                  color: const Color(0xFFD97706),
                  cardBg: cardBg,
                  textColor: textColor,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: isTagalog ? 'Mga Barangay na Bisitahin' : 'Barangays to Visit',
                  value: '$coveredBarangaysCount',
                  icon: Icons.map_rounded,
                  color: const Color(0xFF0056B3),
                  cardBg: cardBg,
                  textColor: textColor,
                  cardBorder: cardBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FILTERS
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isTagalog ? 'Magsaliksik ng magsasaka sa database...' : 'Search farmer name from database...',
                    hintStyle: TextStyle(color: subtextColor, fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 18),
                    filled: true,
                    fillColor: cardBg,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBarangayFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    isDense: true,
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FIELD VISITS TABLE FROM SUPABASE & SYSTEM
          if (filteredVisits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  isTagalog ? 'Walang nahanap na iskedyul ng pagbisita.' : 'No field visits scheduled yet.',
                  style: TextStyle(color: subtextColor),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                    dataRowMaxHeight: 68,
                    columnSpacing: 16,
                    columns: [
                      DataColumn(label: Text(isTagalog ? 'Magsasaka' : 'Farmer Name', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Barangay' : 'Barangay', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Tanim' : 'Crop Type', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Petsa ng Pagbisita' : 'Scheduled Date', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Layunin' : 'Purpose', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Status' : 'Status', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Mga Aksyon' : 'Actions', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                    ],
                    rows: filteredVisits.map((visit) {
                      final isCompleted = visit.status == 'Completed';
                      final farmerFarm = service.farms.firstWhere(
                        (f) => f.farmerId == visit.farmerId || f.farmerName.toLowerCase() == visit.farmerName.toLowerCase(),
                        orElse: () => FarmRecord(
                          id: 'AUTO_${visit.farmerId}',
                          farmerId: visit.farmerId,
                          farmerName: visit.farmerName,
                          locationName: 'Sitio ${visit.barangay}',
                          latitude: 14.2790,
                          longitude: 121.4550,
                          landAreaHectares: 2.0,
                          tenureStatus: 'Owner',
                          cropType: visit.cropType,
                          barangay: visit.barangay,
                          soilType: 'Clay Loam',
                        ),
                      );
                      final isUnmapped = farmerFarm.boundaryPoints.isEmpty;

                      return DataRow(
                        color: isCompleted
                            ? null
                            : WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF)),
                        cells: [
                          DataCell(
                            InkWell(
                              onTap: () => _showVisitDetailsDialog(context, visit, service, isTagalog),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: (isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                                    foregroundColor: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                    child: Icon(isCompleted ? Icons.check_circle_rounded : Icons.event_available_rounded, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(visit.farmerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text('Brgy. ${visit.barangay}', style: TextStyle(fontSize: 12, color: textColor))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(visit.cropType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat('MMM dd, yyyy · hh:mm a').format(visit.scheduledDate),
                              style: TextStyle(fontSize: 11.5, color: subtextColor),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Text(
                                visit.purpose,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                visit.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            isUnmapped
                                ? ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.polyline_rounded, size: 16),
                                    label: Text(
                                      isTagalog ? '✏️ I-plot ang Mapa' : '✏️ Plot Map',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    onPressed: () => _showEditFarmBoundaryDialog(context, service, farmerFarm, isTagalog),
                                  )
                                : ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0056B3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.map_rounded, size: 16),
                                    label: Text(
                                      isTagalog ? '📍 Tingnan sa Mapa' : '📍 View Map',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    onPressed: () => _showVisitMapDetailModal(context, service, visit, isTagalog),
                                  ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showScheduleVisitDialog(BuildContext context, AccountService service, bool isTagalog) {
    String selectedFarmerId = service.farmers.isNotEmpty ? service.farmers.first.id : '';
    final purposeCtrl = TextEditingController(text: 'Pest Inspection & Soil Check');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final farmer = service.farmers.firstWhere((f) => f.id == selectedFarmerId, orElse: () => service.farmers.first);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.event_note_rounded, color: Color(0xFF0056B3)),
                const SizedBox(width: 8),
                Text(isTagalog ? 'I-iskedyul ang Pagbisita' : 'Schedule Field Visit'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedFarmerId,
                    decoration: InputDecoration(
                      labelText: isTagalog ? 'Pumili ng Magsasaka mula sa Database' : 'Select Farmer from Database',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: service.farmers.map((f) => DropdownMenuItem(value: f.id, child: Text('${f.profileName} (${f.barangay})'))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedFarmerId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeCtrl,
                    decoration: InputDecoration(
                      labelText: isTagalog ? 'Layunin ng Pagbisita' : 'Purpose of Visit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isTagalog ? 'Petsa ng Pagbisita:' : 'Scheduled Date:'),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) setDialogState(() => selectedDate = picked);
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTagalog ? 'Kanselahin' : 'Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
                onPressed: () {
                  final farm = service.farms.firstWhere((f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName, orElse: () => service.farms.first);
                  setState(() {
                    _manualVisits.insert(
                      0,
                      TechnicianVisit(
                        id: 'V_${DateTime.now().millisecondsSinceEpoch}',
                        farmerId: farmer.id,
                        farmerName: farmer.profileName,
                        barangay: farmer.barangay,
                        cropType: farm.cropType,
                        scheduledDate: selectedDate,
                        purpose: purposeCtrl.text.trim().isEmpty ? 'General Field Inspection' : purposeCtrl.text.trim(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isTagalog ? 'Nai-iskedyul na ang pagbisita!' : 'Field visit scheduled successfully!'), backgroundColor: const Color(0xFF0056B3)),
                  );
                },
                child: Text(isTagalog ? 'I-save ang Iskedyul' : 'Save Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddFindingsDialog(BuildContext context, TechnicianVisit visit, bool isTagalog) {
    final findingsCtrl = TextEditingController(text: visit.findings);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTagalog ? 'I-record ang Natuklasan sa Bukid' : 'Log Field Visit Findings'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: findingsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isTagalog ? 'Mga Natuklasan at Payo ng Technician' : 'Technician Observations & Advice',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTagalog ? 'Kanselahin' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                visit.findings = findingsCtrl.text.trim();
                visit.status = 'Completed';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isTagalog ? 'Na-markahan na bilang Completed!' : 'Marked as Completed!'), backgroundColor: const Color(0xFF16A34A)),
              );
            },
            child: Text(isTagalog ? 'I-mark bilang Completed' : 'Complete Visit'),
          ),
        ],
      ),
    );
  }

  void _showVisitDetailsDialog(BuildContext context, TechnicianVisit visit, AccountService service, bool isTagalog) {
    final farmer = service.farmers.firstWhere(
      (f) => f.id == visit.farmerId || f.profileName.toLowerCase() == visit.farmerName.toLowerCase(),
      orElse: () => Farmer(
        id: visit.farmerId,
        username: 'farmer',
        password: '',
        profileName: visit.farmerName,
        barangay: visit.barangay,
        contactNumber: 'N/A',
        organization: 'Independent',
      ),
    );

    final farm = service.farms.firstWhere(
      (f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName,
      orElse: () => FarmRecord(
        id: 'AUTO',
        farmerId: farmer.id,
        farmerName: farmer.profileName,
        locationName: 'Sitio ${farmer.barangay}',
        latitude: 14.2790,
        longitude: 121.4550,
        landAreaHectares: 1.5,
        tenureStatus: 'Owner',
        cropType: visit.cropType,
        barangay: farmer.barangay,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: Color(0xFF0056B3), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(visit.farmerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  Text('${isTagalog ? "Detalye ng Bisita" : "Field Visit Details"} • Brgy. ${visit.barangay}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTagalog ? '👤 Impormasyon ng Magsasaka:' : '👤 Farmer Information:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0056B3))),
                      const SizedBox(height: 6),
                      Text('• Pangalan: ${farmer.profileName}', style: const TextStyle(fontSize: 13)),
                      Text('• Username: @${farmer.username}', style: const TextStyle(fontSize: 13)),
                      Text('• Kontak: ${farmer.contactNumber}', style: const TextStyle(fontSize: 13)),
                      Text('• Asosasyon: ${farmer.organization}', style: const TextStyle(fontSize: 13)),
                      Text('• Barangay: ${farmer.barangay}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTagalog ? '🌾 Impormasyon ng Sakahan:' : '🌾 Farm Information:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A))),
                      const SizedBox(height: 6),
                      Text('• Lokasyon: ${farm.locationName}', style: const TextStyle(fontSize: 13)),
                      Text('• Tanim: ${farm.cropType}', style: const TextStyle(fontSize: 13)),
                      Text('• Laki ng Lupa: ${farm.landAreaHectares} ha', style: const TextStyle(fontSize: 13)),
                      Text('• Katayuan sa Lupa: ${farm.tenureStatus}', style: const TextStyle(fontSize: 13)),
                      Text('• Uri ng Lupa: ${farm.soilType}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTagalog ? '📋 Iskedyul at Layunin:' : '📋 Schedule & Purpose:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706))),
                      const SizedBox(height: 6),
                      Text('• Petsa: ${DateFormat('MMM dd, yyyy · hh:mm a').format(visit.scheduledDate)}', style: const TextStyle(fontSize: 13)),
                      Text('• Layunin: ${visit.purpose}', style: const TextStyle(fontSize: 13)),
                      Text('• Status: ${visit.status}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (visit.findings.isNotEmpty)
                        Text('• Natuklasan: ${visit.findings}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTagalog ? 'Isara' : 'Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
            icon: const Icon(Icons.polyline_rounded, size: 16),
            label: Text(isTagalog ? 'I-plot ang Boundary' : 'Plot Boundary'),
            onPressed: () {
              Navigator.pop(ctx);
              _showEditFarmBoundaryDialog(context, service, farm, isTagalog);
            },
          ),
        ],
      ),
    );
  }

  void _showAddFarmLotDialog(BuildContext context, AccountService service, Farmer farmer, bool isTagalog) {
    final locationCtrl = TextEditingController(text: 'Farm Lot 2, Brgy. ${farmer.barangay}');
    final areaCtrl = TextEditingController(text: '1.5');
    String selectedCrop = 'Rice';
    String selectedTenure = 'Owner';
    String selectedBrgy = farmer.barangay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_location_alt_rounded, color: Color(0xFF0056B3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTagalog ? 'Magdagdag ng Bagong Lupa kay ${farmer.profileName}' : 'Add New Farm Lot for ${farmer.profileName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: isTagalog ? 'Lokasyon ng Lupa' : 'Farm Lot Location/Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: areaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Laki (Hectares)' : 'Land Area (Hectares)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: AccountService.pagsanjanBarangays.contains(selectedBrgy) ? selectedBrgy : AccountService.pagsanjanBarangays.first,
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setDialogState(() => selectedBrgy = val ?? farmer.barangay),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCrop,
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Pananim' : 'Crop Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['Rice', 'Talong (Eggplant)', 'Kamatis (Tomato)', 'Corn', 'Banana', 'Vegetables']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedCrop = val ?? 'Rice'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedTenure,
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Tenure' : 'Tenure Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['Owner', 'Tenant', 'Lease']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedTenure = val ?? 'Owner'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isTagalog ? 'Kanselahin' : 'Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(isTagalog ? 'I-save ang Bagong Lupa' : 'Save New Lot'),
              onPressed: () async {
                final haVal = double.tryParse(areaCtrl.text.trim()) ?? 1.0;
                await service.addFarmRecord(
                  farmerId: farmer.id,
                  farmerName: farmer.profileName,
                  locationName: locationCtrl.text.trim().isEmpty ? 'Farm Lot, Brgy. $selectedBrgy' : locationCtrl.text.trim(),
                  latitude: 14.2790,
                  longitude: 121.4550,
                  landAreaHectares: haVal,
                  tenureStatus: selectedTenure,
                  cropType: selectedCrop,
                  barangay: selectedBrgy,
                  boundaryPoints: [],
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTagalog
                            ? 'Matagumpay na naidagdag ang panibagong sakahan/lupa kay ${farmer.profileName}!'
                            : 'Successfully added new farm lot for ${farmer.profileName}!',
                      ),
                      backgroundColor: const Color(0xFF0056B3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }



  void _showFarmMapDetailModal(BuildContext context, AccountService service, Farmer farmer, List<FarmRecord> farmerFarms, bool isTagalog) {
    FarmRecord selectedFarm = farmerFarms.isNotEmpty
        ? farmerFarms.first
        : FarmRecord(
            id: 'AUTO_${farmer.id}',
            farmerId: farmer.id,
            farmerName: farmer.profileName,
            locationName: 'Sitio ${farmer.barangay}',
            latitude: 14.2790,
            longitude: 121.4550,
            landAreaHectares: 1.5,
            tenureStatus: 'Owner',
            cropType: 'Rice',
            barangay: farmer.barangay,
            soilType: 'Clay Loam',
          );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isMultiLot = farmerFarms.length >= 2;
          final totalHa = farmerFarms.fold(0.0, (sum, f) => sum + f.landAreaHectares);
          final mapMarkers = <Marker>[
            Marker(
              point: LatLng(selectedFarm.latitude, selectedFarm.longitude),
              width: 44,
              height: 48,
              child: const Icon(Icons.location_on_rounded, color: Color(0xFF0056B3), size: 36),
            ),
          ];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            backgroundColor: const Color(0xFFF8FAFC),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0056B3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isTagalog ? "Mapa ng Sakahan ni" : "Farm Map -"} ${farmer.profileName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Brgy. ${farmer.barangay} • ${farmerFarms.length} Farm Lot(s) • Total: ${totalHa.toStringAsFixed(1)} ha',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFBFDBFE)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 680,
              height: 560,
              child: Column(
                children: [
                  if (isMultiLot)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: const Color(0xFFEFF6FF),
                      child: Row(
                        children: [
                          const Icon(Icons.holiday_village_rounded, color: Color(0xFF0056B3), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isTagalog ? 'Pumili ng Lupa na Tingnan:' : 'Select Farm Lot:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0056B3)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedFarm.id,
                              isExpanded: true,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: farmerFarms.map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text('${f.cropType} (${f.landAreaHectares} ha) - ${f.locationName}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )).toList(),
                              onChanged: (selectedId) {
                                if (selectedId != null) {
                                  setModalState(() {
                                    selectedFarm = farmerFarms.firstWhere((f) => f.id == selectedId);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: PagsanjanMapWidget(
                      initialCenter: selectedFarm.latitude != 0 ? LatLng(selectedFarm.latitude, selectedFarm.longitude) : const LatLng(14.2790, 121.4550),
                      initialZoom: 16.5,
                      markers: mapMarkers,
                      extraPolygons: [
                        if (selectedFarm.boundaryPoints.length >= 3)
                          Polygon(
                            points: selectedFarm.boundaryPoints,
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            borderColor: const Color(0xFF0056B3),
                            borderStrokeWidth: 3.0,
                          ),
                      ],
                      extraPolylines: selectedFarm.boundaryPoints.length >= 2
                          ? [
                              Polyline(
                                points: selectedFarm.boundaryPoints.length >= 3 ? [...selectedFarm.boundaryPoints, selectedFarm.boundaryPoints.first] : selectedFarm.boundaryPoints,
                                color: const Color(0xFF0056B3),
                                strokeWidth: 3.5,
                              )
                            ]
                          : [],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🌾 ${selectedFarm.cropType} (${selectedFarm.landAreaHectares} ha)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3)),
                              ),
                              Text(
                                'Soil: ${selectedFarm.soilType.isEmpty ? "Clay Loam" : selectedFarm.soilType} • Location: ${selectedFarm.locationName}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056B3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.polyline_rounded, size: 16),
                          label: Text(
                            isTagalog ? '✏️ Iguhit / Edit Boundary' : '✏️ Draw / Edit Boundary',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showEditFarmBoundaryDialog(context, service, selectedFarm, isTagalog);
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                          label: Text(isTagalog ? '➕ Dagdag Lupa' : '➕ Add Lot', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddFarmLotDialog(context, service, farmer, isTagalog);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVisitMapDetailModal(BuildContext context, AccountService service, TechnicianVisit visit, bool isTagalog) {
    final farmer = service.farmers.firstWhere(
      (f) => f.id == visit.farmerId || f.profileName.toLowerCase() == visit.farmerName.toLowerCase(),
      orElse: () => Farmer(
        id: visit.farmerId,
        username: 'farmer',
        password: '',
        profileName: visit.farmerName,
        barangay: visit.barangay,
        contactNumber: 'N/A',
        organization: 'Independent',
      ),
    );

    final farmerFarm = service.farms.firstWhere(
      (f) => f.farmerId == visit.farmerId || f.farmerName.toLowerCase() == visit.farmerName.toLowerCase(),
      orElse: () => FarmRecord(
        id: 'AUTO_${visit.farmerId}',
        farmerId: visit.farmerId,
        farmerName: visit.farmerName,
        locationName: 'Sitio ${visit.barangay}',
        latitude: 14.2790,
        longitude: 121.4550,
        landAreaHectares: 2.0,
        tenureStatus: 'Owner',
        cropType: visit.cropType,
        barangay: visit.barangay,
        soilType: 'Clay Loam',
      ),
    );

    final isCompleted = visit.status == 'Completed';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        backgroundColor: const Color(0xFFF8FAFC),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF0056B3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_note_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isTagalog ? "Iskedyul ng Pagbisita kay" : "Field Visit Map -"} ${visit.farmerName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Brgy. ${visit.barangay} • ${visit.cropType} • ${DateFormat('MMM dd, yyyy · hh:mm a').format(visit.scheduledDate)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFBFDBFE)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 680,
          height: 560,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFEFF6FF),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0056B3), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${isTagalog ? "Layunin" : "Purpose"}: ${visit.purpose}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0056B3)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        visit.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PagsanjanMapWidget(
                  initialCenter: farmerFarm.latitude != 0 ? LatLng(farmerFarm.latitude, farmerFarm.longitude) : const LatLng(14.2790, 121.4550),
                  initialZoom: 16.5,
                  markers: [
                    Marker(
                      point: LatLng(farmerFarm.latitude, farmerFarm.longitude),
                      width: 44,
                      height: 48,
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFF0056B3), size: 36),
                    ),
                  ],
                  extraPolygons: [
                    if (farmerFarm.boundaryPoints.length >= 3)
                      Polygon(
                        points: farmerFarm.boundaryPoints,
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        borderColor: const Color(0xFF0056B3),
                        borderStrokeWidth: 3.0,
                      ),
                  ],
                  extraPolylines: farmerFarm.boundaryPoints.length >= 2
                      ? [
                          Polyline(
                            points: farmerFarm.boundaryPoints.length >= 3 ? [...farmerFarm.boundaryPoints, farmerFarm.boundaryPoints.first] : farmerFarm.boundaryPoints,
                            color: const Color(0xFF0056B3),
                            strokeWidth: 3.5,
                          )
                        ]
                      : [],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👤 ${farmer.profileName} (📞 ${farmer.contactNumber})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3)),
                          ),
                          Text(
                            '🌾 ${farmerFarm.cropType} (${farmerFarm.landAreaHectares} ha) • Soil: ${farmerFarm.soilType.isEmpty ? "Clay Loam" : farmerFarm.soilType}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.polyline_rounded, size: 16),
                      label: Text(
                        isTagalog ? '✏️ Iguhit / Edit Boundary' : '✏️ Draw / Edit Boundary',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditFarmBoundaryDialog(context, service, farmerFarm, isTagalog);
                      },
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(
                          isTagalog ? '✅ I-mark Completed' : '✅ Mark Completed',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddFindingsDialog(context, visit, isTagalog);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODULE 2: FARMER & FARM/PLANTING MONITORING
  // ==========================================
  Widget _buildMonitoringView(
    AccountService service,
    bool isTagalog,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final farmers = service.farmers.where((f) {
      final matchesBrgy = _selectedBarangayFilter == 'All' || f.barangay.toLowerCase() == _selectedBarangayFilter.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty || f.profileName.toLowerCase().contains(query) || f.organization.toLowerCase().contains(query);

      final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName.toLowerCase() == f.profileName.toLowerCase()).toList();
      final hasMappedFarm = farmerFarms.isNotEmpty && farmerFarms.any((farm) => farm.boundaryPoints.isNotEmpty);

      return matchesBrgy && matchesQuery && hasMappedFarm;
    }).toList();

    farmers.sort((a, b) {
      final aFarms = service.farms.where((f) => f.farmerId == a.id || f.farmerName == a.profileName).toList();
      final bFarms = service.farms.where((f) => f.farmerId == b.id || f.farmerName == b.profileName).toList();

      final aNeedsPlot = aFarms.isEmpty || aFarms.any((f) => f.boundaryPoints.isEmpty);
      final bNeedsPlot = bFarms.isEmpty || bFarms.any((f) => f.boundaryPoints.isEmpty);

      if (aNeedsPlot && !bNeedsPlot) return -1;
      if (!aNeedsPlot && bNeedsPlot) return 1;
      return a.profileName.compareTo(b.profileName);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATABASE CROP MONITORING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    isTagalog ? 'Pagsubaybay sa Magsasaka at Tanim' : 'Farmer & Farm/Planting Monitoring',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SEARCH & BARANGAY FILTER
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isTagalog ? 'Magsaliksik ng magsasaka sa database...' : 'Search farmer name or association from database...',
                    hintStyle: TextStyle(color: subtextColor, fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 18),
                    filled: true,
                    fillColor: cardBg,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBarangayFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    isDense: true,
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // MONITORING TABLE FROM SUPABASE DATABASE
          if (farmers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  isTagalog ? 'Walang nahanap na magsasaka sa database.' : 'No farmers found in database.',
                  style: TextStyle(color: subtextColor),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                    dataRowMaxHeight: 68,
                    columnSpacing: 18,
                    columns: [
                      DataColumn(label: Text(isTagalog ? 'Magsasaka' : 'Farmer Name', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Barangay & Asosasyon' : 'Barangay & Association', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Tanim & Sukat (ha)' : 'Crops & Area (ha)', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Uri ng Lupa' : 'Soil Type', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Boundary Status' : 'Boundary Status', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                      DataColumn(label: Text(isTagalog ? 'Mga Aksyon' : 'Actions', style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent))),
                    ],
                    rows: farmers.map((farmer) {
                      final farmerFarms = service.farms.where((f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName).toList();
                      final isMultiLotOwner = farmerFarms.length >= 2;
                      final totalHa = farmerFarms.fold(0.0, (sum, f) => sum + f.landAreaHectares);

                      final farm = farmerFarms.isNotEmpty
                          ? farmerFarms.first
                          : FarmRecord(
                              id: 'AUTO_${farmer.id}',
                              farmerId: farmer.id,
                              farmerName: farmer.profileName,
                              locationName: 'Sitio ${farmer.barangay}',
                              latitude: 14.2790,
                              longitude: 121.4550,
                              landAreaHectares: 1.5,
                              tenureStatus: 'Owner',
                              cropType: 'Rice',
                              barangay: farmer.barangay,
                              soilType: 'Clay Loam',
                            );

                      final isUnmapped = farmerFarms.isEmpty || farmerFarms.any((f) => f.boundaryPoints.isEmpty);

                      return DataRow(
                        color: isUnmapped
                            ? WidgetStateProperty.all(isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFFEF3C7))
                            : null,
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isMultiLotOwner ? const Color(0xFF7C3AED) : primaryAccent,
                                  foregroundColor: Colors.white,
                                  child: Text(farmer.profileName.isNotEmpty ? farmer.profileName[0] : 'F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(farmer.profileName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                        if (isMultiLotOwner) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              '🏡 Multi-Farm (${farmerFarms.length} Lots)',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('📞 ${farmer.contactNumber}', style: TextStyle(fontSize: 11, color: subtextColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Brgy. ${farmer.barangay}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textColor)),
                                Text(farmer.organization, style: TextStyle(fontSize: 11, color: subtextColor)),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isMultiLotOwner ? farmerFarms.map((f) => f.cropType).toSet().join(', ') : farm.cropType,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF16A34A)),
                                ),
                                Text(
                                  isMultiLotOwner
                                      ? 'Kabuuang Sukat: ${totalHa.toStringAsFixed(1)} ha (${farmerFarms.length} Lots)'
                                      : '${farm.landAreaHectares} ha (${farm.tenureStatus})',
                                  style: TextStyle(fontSize: 11, color: subtextColor),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(farm.soilType.isEmpty ? 'Clay Loam' : farm.soilType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
                            ),
                          ),
                          DataCell(
                            isUnmapped
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                                        const SizedBox(width: 4),
                                        Text(isTagalog ? 'Kailangan i-plot' : 'Needs Boundary Plotting', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                      ],
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 4),
                                        Text(isTagalog ? 'Na-plot na' : 'Mapped', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                      ],
                                    ),
                                  ),
                          ),
                          DataCell(
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0056B3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: Text(
                                isTagalog ? '📍 Tingnan sa Mapa' : '📍 View Map',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () => _showFarmMapDetailModal(context, service, farmer, farmerFarms, isTagalog),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 3: INTERACTIVE MAP (MAPANG INTERAKTIBO)
  // ==========================================
  Widget _buildInteractiveMapView(
    AccountService service,
    bool isTagalog,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final List<FarmRecord> displayedFarms = [];
    final mapMarkers = <Marker>[];
    final activeFarmers = service.activeFarmers;
    final activeFarms = service.activeFarms;

    for (int index = 0; index < activeFarmers.length; index++) {
      final farmer = activeFarmers[index];
      final normBrgy = AccountService.normalizeBarangay(farmer.barangay);
      final matchesBarangay = _selectedBarangayFilter == 'All' ||
          normBrgy.toLowerCase() == AccountService.normalizeBarangay(_selectedBarangayFilter).toLowerCase();
      final matchesOrg = _selectedAssociationFilter == 'All' ||
          farmer.organization.trim().toLowerCase() == _selectedAssociationFilter.trim().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          farmer.profileName.toLowerCase().contains(query) ||
          farmer.organization.toLowerCase().contains(query) ||
          normBrgy.toLowerCase().contains(query);

      if (!matchesBarangay || !matchesOrg || !matchesQuery) continue;

      FarmRecord originalFarm = activeFarms.firstWhere(
        (f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName,
        orElse: () => FarmRecord(
          id: 'FARM_AUTO_${farmer.id}',
          farmerId: farmer.id,
          farmerName: farmer.profileName,
          locationName: 'Sitio $normBrgy',
          latitude: 14.2790,
          longitude: 121.4550,
          landAreaHectares: 2.0,
          tenureStatus: 'Owner',
          cropType: 'Rice',
          barangay: normBrgy,
          soilType: 'Clay Loam',
        ),
      );

      displayedFarms.add(originalFarm);

      if (_showRegisteredPins) {
        mapMarkers.add(_buildFarmMarker(originalFarm, () {
          LatLng center = LatLng(originalFarm.latitude, originalFarm.longitude);
          if (originalFarm.boundaryPoints.length >= 3) {
            center = calculatePolygonCentroid(originalFarm.boundaryPoints);
          }
          setState(() {
            _mapCenter = center;
            _mapZoom = 17.5;
            _showMapSidePanel = false;
          });
        }));
      }
    }

    final farmBoundaryPolygons = <Polygon>[];
    for (final farm in activeFarms) {
      if (farm.tenureStatus.toLowerCase().contains('hired')) continue;
      List<LatLng> polyPoints = farm.boundaryPoints;
      if (polyPoints.length < 3 && farm.latitude != 0 && farm.longitude != 0) {
        final sideM = math.sqrt(farm.landAreaHectares * 10000);
        final latOffset = (sideM / 2) / 111320.0;
        final lonOffset = (sideM / 2) / (111320.0 * math.cos(farm.latitude * math.pi / 180.0));

        polyPoints = [
          LatLng(farm.latitude - latOffset, farm.longitude - lonOffset),
          LatLng(farm.latitude - latOffset, farm.longitude + lonOffset),
          LatLng(farm.latitude + latOffset, farm.longitude + lonOffset),
          LatLng(farm.latitude + latOffset, farm.longitude - lonOffset),
        ];
      }

      if (polyPoints.length >= 3) {
        final cropLower = farm.cropType.toLowerCase();
        Color polyColor;
        Color borderColor;

        if (cropLower.contains('rice') || cropLower.contains('palay')) {
          polyColor = Color(0xFF15803D).withValues(alpha: 0.35);
          borderColor = const Color(0xFF166534);
        } else if (cropLower.contains('gulay') || cropLower.contains('veg')) {
          polyColor = Color(0xFF0284C7).withValues(alpha: 0.35);
          borderColor = const Color(0xFF0284C7);
        } else if (cropLower.contains('prutas') || cropLower.contains('fruit')) {
          polyColor = Color(0xFFD97706).withValues(alpha: 0.35);
          borderColor = const Color(0xFFD97706);
        } else {
          polyColor = Color(0xFF0056B3).withValues(alpha: 0.35);
          borderColor = const Color(0xFF0056B3);
        }

        farmBoundaryPolygons.add(
          Polygon(
            points: polyPoints,
            color: polyColor,
            borderColor: borderColor,
            borderStrokeWidth: 3.5,
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GIS & WEATHER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(
                    isTagalog ? 'Interaktibong Mapa ng mga Sakahan' : 'Interactive Farmland Map',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: PagsanjanMapWidget(
                        initialCenter: _mapCenter,
                        initialZoom: _mapZoom,
                        mapController: _techMapController,
                        markers: mapMarkers,
                        extraPolygons: farmBoundaryPolygons,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 16,
                    top: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PagsanjanMapScreen(
                            markers: mapMarkers,
                            extraPolygons: farmBoundaryPolygons,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.fullscreen),
                      label: Text(isTagalog ? 'Full Screen' : 'Full Screen'),
                    ),
                  ),

                  if (!_showMapSidePanel)
                    Positioned(
                      left: 16,
                      top: 16,
                      child: FloatingActionButton.extended(
                        heroTag: 'tech_show_map_panel_btn',
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        onPressed: () => setState(() => _showMapSidePanel = true),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(isTagalog ? 'Maghanap at I-filter' : 'Search & Filter'),
                      ),
                    ),

                  if (_showMapSidePanel)
                    Positioned(
                      left: 16,
                      top: 16,
                      bottom: 16,
                      width: 320,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isTagalog ? 'Mga Pin ng Rehistradong Sakahan' : 'Registered Farmland Pins',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0056B3), fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0056B3)),
                                  tooltip: isTagalog ? 'I-hide ang Panel' : 'Hide Panel',
                                  onPressed: () => setState(() => _showMapSidePanel = false),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isTagalog ? 'Ipakita ang Pin' : 'Show Pins',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: _showRegisteredPins,
                                  activeThumbColor: const Color(0xFF0056B3),
                                  onChanged: (val) => setState(() => _showRegisteredPins = val),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(color: textColor, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: isTagalog ? 'Maghanap ng sakahan...' : 'Search farm or farmer...',
                                hintStyle: TextStyle(color: subtextColor, fontSize: 11),
                                prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: cardBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),

                            DropdownButtonFormField<String>(
                              initialValue: _selectedBarangayFilter,
                              dropdownColor: cardBg,
                              style: TextStyle(color: textColor, fontSize: 12),
                              decoration: InputDecoration(
                                labelText: isTagalog ? 'Filter Barangay (Auto-Zoom)' : 'Filter Barangay (Auto-Zoom)',
                                labelStyle: TextStyle(color: subtextColor, fontSize: 11),
                                isDense: true,
                                filled: true,
                                fillColor: cardBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (val) {
                                final brgy = val ?? 'All';
                                setState(() {
                                  _selectedBarangayFilter = brgy;
                                  if (brgy == 'All') {
                                    _mapCenter = const LatLng(14.2790, 121.4550);
                                    _mapZoom = 13.5;
                                  } else {
                                    _mapCenter = _barangayCenterMap[brgy] ?? const LatLng(14.2790, 121.4550);
                                    _mapZoom = 15.8;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),

                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: (['All', 'Not Associated', ...service.getUniqueOrganizations()].contains(_selectedAssociationFilter))
                                  ? _selectedAssociationFilter
                                  : 'All',
                              dropdownColor: cardBg,
                              style: TextStyle(color: textColor, fontSize: 12),
                              decoration: InputDecoration(
                                labelText: isTagalog ? 'Filter Asosasyon' : 'Filter Association',
                                labelStyle: TextStyle(color: subtextColor, fontSize: 11),
                                isDense: true,
                                filled: true,
                                fillColor: cardBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: ['All', 'Not Associated', ...service.getUniqueOrganizations()].map((org) => DropdownMenuItem(
                                value: org,
                                child: Text(org, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12)),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedAssociationFilter = val ?? 'All'),
                            ),
                            const SizedBox(height: 10),

                            Expanded(
                              child: displayedFarms.isEmpty
                                  ? Center(
                                child: Text(
                                  isTagalog ? 'Walang sakahang nahanap' : 'No farms found',
                                  style: TextStyle(fontSize: 12, color: subtextColor),
                                ),
                              )
                                  : ListView.builder(
                                itemCount: displayedFarms.length,
                                itemBuilder: (context, index) {
                                  final farm = displayedFarms[index];
                                  return Card(
                                    color: isDark ? const Color(0xFF1E2E4A) : Colors.white,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF0056B3), size: 18),
                                      ),
                                      title: Text(farm.farmerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                      subtitle: Text('${farm.cropType} • Brgy. ${farm.barangay}', style: TextStyle(color: subtextColor, fontSize: 11)),
                                      onTap: () {
                                        LatLng center = LatLng(farm.latitude, farm.longitude);
                                        if (farm.boundaryPoints.length >= 3) {
                                          center = calculatePolygonCentroid(farm.boundaryPoints);
                                        }
                                        setState(() {
                                          _mapCenter = center;
                                          _mapZoom = 17.5;
                                          _showMapSidePanel = false;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildFarmMarker(FarmRecord farm, VoidCallback onTap) {
    Color primaryBlue = const Color(0xFF0056B3);
    IconData cropIcon = Icons.location_on_rounded;

    final cropLower = farm.cropType.toLowerCase();
    if (cropLower.contains('rice') || cropLower.contains('palay')) {
      primaryBlue = const Color(0xFF1E3A8A);
      cropIcon = Icons.grass_rounded;
    } else if (cropLower.contains('gulay') || cropLower.contains('veg')) {
      primaryBlue = const Color(0xFF0284C7);
      cropIcon = Icons.eco_rounded;
    } else if (cropLower.contains('prutas') || cropLower.contains('fruit')) {
      primaryBlue = const Color(0xFF2563EB);
      cropIcon = Icons.apple_rounded;
    }

    return Marker(
      point: LatLng(farm.latitude, farm.longitude),
      width: 44,
      height: 48,
      child: Tooltip(
        message: 'Owner: ${farm.farmerName}\nCrop: ${farm.cropType} (${farm.landAreaHectares} ha)',
        preferBelow: false,
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, primaryBlue.withValues(alpha: 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Icon(cropIcon, color: Colors.white, size: 18),
              ),
              ClipPath(
                clipper: _TriangleClipper(),
                child: Container(width: 8, height: 6, color: primaryBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODULE 4: CROP & DSS ADVISORY
  // ==========================================
  Widget _buildDssAdvisoryView(
    AccountService service,
    bool isTagalog,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final availableCrops = _getUniqueDatabaseCrops(service);
    if (!availableCrops.contains(_dssSelectedCrop)) {
      _dssSelectedCrop = availableCrops.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DECISION SUPPORT SYSTEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    isTagalog ? 'Payo sa Tanim at DSS Advisory' : 'Crop & DSS Advisory Engine',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DSS GENERATOR FORM CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Color(0xFF0056B3), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isTagalog ? 'Gumawa ng Payo sa Tanim (Technician Advisory)' : 'Generate Technical Crop Recommendation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _dssSelectedCrop,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Pananim mula sa Database' : 'Target Crop from Database',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: availableCrops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _dssSelectedCrop = val ?? availableCrops.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _dssSelectedStage,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Yugto ng Tanim' : 'Growth Stage',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['Early Planting / Seedling', 'Vegetative Stage', 'Flowering / Tillering', 'Harvest-Ready']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) => setState(() => _dssSelectedStage = val ?? 'Vegetative Stage'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // DYNAMIC DSS ADVISORY RESULT CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'DSS Recommendation for $_dssSelectedCrop ($_dssSelectedStage):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDssRecommendationText(_dssSelectedCrop, _dssSelectedStage, isTagalog),
                        style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : const Color(0xFF1E293B), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056B3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      service.addPost(
                        'Technical Advisory: $_dssSelectedCrop',
                        _getDssRecommendationText(_dssSelectedCrop, _dssSelectedStage, isTagalog),
                        category: 'General Advisory',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isTagalog ? 'Naipost na ang Payo sa Tanim para sa lahat ng magsasaka!' : 'Technical advisory broadcasted to all farmers!',
                          ),
                          backgroundColor: const Color(0xFF0056B3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      isTagalog ? 'I-broadcast ang Payong Ito sa Magsasaka' : 'Broadcast Advisory to Farmers',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDssRecommendationText(String crop, String stage, bool isTagalog) {
    final lowerCrop = crop.toLowerCase();
    if (lowerCrop.contains('rice') || lowerCrop.contains('palay')) {
      if (stage.contains('Vegetative')) {
        return isTagalog
            ? '🌿 Pataba: Maglagay ng Nitrogen (Urea 46-0-0) sa sukat na 2-3 bags/ha. Panatilihin ang antas ng tubig sa 3-5 cm. Monitorin ang posibleng brown planthopper.'
            : '🌿 Fertilizer: Apply Nitrogen (Urea 46-0-0) at 2-3 bags/ha. Maintain 3-5 cm shallow water level. Monitor for early stem borer and planthopper.';
      } else {
        return isTagalog
            ? '🌾 Katamtamang patubig bago ang ani. Iwasan ang labis na abono para sa magandang timbang ng palay.'
            : '🌾 Moderate irrigation prior to harvest. Avoid excessive nitrogen to ensure proper grain filling.';
      }
    } else if (lowerCrop.contains('talong') || lowerCrop.contains('eggplant')) {
      return isTagalog
          ? '🍆 Abono: Complete (14-14-14) tuwing 14 araw. Mag-spray ng organic neem-based extract laban sa fruit and shoot borer.'
          : '🍆 Fertilizer: Apply Complete (14-14-14) every 14 days. Apply botanical pesticides to manage fruit & shoot borer.';
    } else {
      return isTagalog
          ? '🌱 Panatilihin ang sapat na drainage at basang lupa para sa $crop. Maglagay ng organic compost o complete fertilizer.'
          : '🌱 Ensure adequate soil drainage and moisture for $crop. Apply organic compost or complete fertilizer.';
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color textColor,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            radius: 20,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

Map<String, LatLng> _barangayCenterMap = {
  'Anibong': LatLng(14.2855, 121.4682),
  'Biñan': LatLng(14.2750, 121.4580),
  'Buboy': LatLng(14.2950, 121.4420),
  'Cabanbanan': LatLng(14.2620, 121.4650),
  'Calusiche': LatLng(14.2980, 121.4580),
  'Dingin': LatLng(14.2880, 121.4350),
  'Lambac': LatLng(14.2680, 121.4420),
  'Layug': LatLng(14.2710, 121.4480),
  'Magdapio': LatLng(14.2650, 121.4380),
  'Maulawin': LatLng(14.2780, 121.4410),
  'Pinagsanjan': LatLng(14.2720, 121.4520),
  'Uno': LatLng(14.2785, 121.4515),
  'Dos': LatLng(14.2760, 121.4530),
  'Poblacion Uno': LatLng(14.2785, 121.4515),
  'Poblacion Dos': LatLng(14.2760, 121.4530),
  'Sabang': LatLng(14.2820, 121.4460),
  'Sampaloc': LatLng(14.2910, 121.4510),
  'San Isidro': LatLng(14.2630, 121.4520),
};
