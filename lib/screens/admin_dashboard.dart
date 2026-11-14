import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;

import '../models/farmer.dart';
import '../services/account_service.dart';
import '../services/supabase_service.dart';
import '../services/weather_service.dart';
import '../models/weather_models.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_map/flutter_map.dart';
import 'map_screen.dart';

class AdminLocale {
  final bool isTagalog;
  AdminLocale(this.isTagalog);

  String get adminTitle => isTagalog ? 'Portal ng Agrikultura (Admin)' : 'MAO Admin Portal';
  String get officeSubtitle => isTagalog ? 'Tanggapan ng Agrikultura ng Pagsanjan' : 'Municipal Agriculture Office (MAO)';
  String get location => 'Pagsanjan, Laguna';

  // Nav Items (WITHOUT NUMBERS)
  String get navDashboard => isTagalog ? 'Buod ng Dashboard' : 'Dashboard Summary';
  String get navFarmers => isTagalog ? 'Mga Magsasaka at Sakahan' : 'Farmer & Farm Records';
  String get navHistorical => isTagalog ? 'Nakaraang Datos' : 'Historical Data';
  String get navMap => isTagalog ? 'Mapang Interaktibo' : 'Interactive Map';
  String get navAccounts => isTagalog ? 'Mga Akawnt ng Farmer' : 'Farmer Accounts';
  String get navAdminStaff => isTagalog ? 'Mga Admin at Staff' : 'Admin Accounts';
  String get navActivityLog => isTagalog ? 'Talaan ng Kilos (Log)' : 'Activity Log';
  String get navLogout => isTagalog ? 'Mag-logout (Exit)' : 'Logout';

  // Dashboard Overview
  String get execSummary => isTagalog ? 'BUOD NG PAMAMAHALA' : 'EXECUTIVE SUMMARY';
  String get agriOverview => isTagalog ? 'Pangkalahatang Tanaw sa Agrikultura' : 'Agricultural Overview';
  String get exportPdf => isTagalog ? 'Export PDF' : 'Export PDF';
  String get exportExcel => isTagalog ? 'Export Excel' : 'Export Excel';
  String get filterTitle => isTagalog ? 'Mga Filter (Barangay, Tanim, Panahon)' : 'Filters (Barangay, Crop, Period)';
  String get kpiFarmers => isTagalog ? 'Rehistradong Magsasaka' : 'Registered Farmers';
  String get kpiFarmArea => isTagalog ? 'Kabuuan ng Lupaing Sakahan' : 'Total Farm Area';
  String get farmersPerBarangay => isTagalog ? 'Bilang ng Magsasaka Bawat Barangay' : 'Farmers per Barangay';
  String get areaPerCrop => isTagalog ? 'Lupaing Sakahan Bawat Uri ng Tanim' : 'Farm Area per Crop Type';
  String get historicalTrends => isTagalog ? 'Nakaraang Trend sa Ani at Presyo (MAO)' : 'Historical Production & Price Trends (MAO)';

  // Weather
  String get weatherTitle => isTagalog ? 'Ulat ng Panahon sa Agrikultura' : 'Pagsanjan Agricultural Weather';
  String get liveUpdated => isTagalog ? 'BAGO AT LIVE' : 'LIVE UPDATED';
  String get weatherForecast => isTagalog ? '5-Araw na Ulat ng Panahon sa Sakahan' : '5-Day Agricultural Weather Forecast';
  String get weatherAdvisory => isTagalog ? '🌾 Payo: Angkop ang panahon para sa pagpapataba' : '🌾 Advisory: Favorable for fertilizer application';

  // Farmer & Farm Records
  String get farmerDirTitle => isTagalog ? 'Direktoryo ng mga Magsasaka at Sakahan' : 'Farmer & Farm Records Management';
  String get addFarmer => isTagalog ? 'Magdagdag ng Magsasaka' : 'Add Farmer';
  String get addFarmRecord => isTagalog ? 'Magdagdag ng Sakahan' : 'Add Farm';
  String get searchFarmerPlaceholder => isTagalog ? 'Magsaliksik ng pangalan, username, o samahan...' : 'Search farmer name, username, or association...';

  // Historical Data
  String get historicalTitle => isTagalog ? 'Mga Nakaraang Rekord ng MAO' : 'Historical Production & Price Data';
  String get uploadMaoRecord => isTagalog ? 'Mag-upload ng Rekord' : 'Upload MAO Record';

  // Interactive Map
  String get mapTitle => isTagalog ? 'Interaktibong Mapa ng mga Sakahan' : 'Interactive Farm Map (Pagsanjan)';
  String get registeredPins => isTagalog ? 'Mga Pin ng Rehistradong Sakahan' : 'Registered Farm Pins';

  // Farmer Accounts
  String get accountsTitle => isTagalog ? 'Pamamahala ng mga Akawnt ng Farmer' : 'Farmer Accounts Management';

  // Admin Staff
  String get adminStaffTitle => isTagalog ? 'Mga Akawnt ng Admin at Tungkulin' : 'Admin Accounts & Staff Roles';
  String get addStaff => isTagalog ? 'Magdagdag ng Staff' : 'Add MAO Staff';

  // Activity Log
  String get activityLogTitle => isTagalog ? 'Talaan ng Kilos sa Sistema (Audit)' : 'Activity Log (System Audit Trail)';
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // 0..6 for the 7 main modules
  int _historicalTableIndex = 0; // 0 = MAO Production Dataset, 1 = Vegetable Market & Farmgate Prices
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filters for Dashboard Summary
  String _selectedCropFilter = 'All';
  String _selectedBarangayFilter = 'All';
  String _selectedTimePeriodFilter = 'All';

  // Interactive Map State
  bool _showRegisteredPins = true;
  bool _showMapSidePanel = true;
  LatLng _mapCenter = const LatLng(14.2790, 121.4550);
  double _mapZoom = 13.5;

  WeatherBundle? _liveWeather;

  Future<void> _fetchLiveWeather() async {
    try {
      final bundle = await WeatherService().fetch(lat: 14.2717, lon: 121.4553);
      if (mounted) {
        setState(() {
          _liveWeather = bundle;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live weather: $e');
    }
  }

  String _getBasicWeatherTerm(int code) {
    if (code == 0) return 'Sunny';
    if (code >= 1 && code <= 3) return 'Cloudy';
    if (code >= 51 && code <= 67 || code >= 80 && code <= 82) return 'Rainy';
    if (code >= 95) return 'Stormy';
    return 'Cloudy';
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_rounded;
    if (code >= 51 && code <= 67 || code >= 80 && code <= 82) return Icons.grain_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_queue_rounded;
  }

  static final Map<String, LatLng> _barangayCenterMap = {
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

  LatLng _getBarangayCenter(String barangay, List<FarmRecord> allFarms) {
    if (barangay == 'All') {
      return const LatLng(14.2790, 121.4550);
    }
    final normBrgy = AccountService.normalizeBarangay(barangay);
    final brgyFarms = allFarms.where((f) => AccountService.normalizeBarangay(f.barangay) == normBrgy).toList();
    if (brgyFarms.isNotEmpty) {
      double sumLat = 0;
      double sumLon = 0;
      for (final f in brgyFarms) {
        sumLat += f.latitude;
        sumLon += f.longitude;
      }
      return LatLng(sumLat / brgyFarms.length, sumLon / brgyFarms.length);
    }
    return _barangayCenterMap[normBrgy] ?? const LatLng(14.2790, 121.4550);
  }

  List<String> _parseCsvLine(String line) {
    String delimiter = ',';
    if (line.contains(';') && !line.contains(',')) {
      delimiter = ';';
    } else if (line.contains('\t') && !line.contains(',') && !line.contains(';')) {
      delimiter = '\t';
    }
    return line.split(delimiter).map((p) => p.trim().replaceAll('"', '').replaceAll("'", "")).toList();
  }

  bool _matchesCrop(String cropType, String selectedCrop) {
    if (selectedCrop == 'All') return true;
    final c = cropType.toLowerCase();
    final s = selectedCrop.toLowerCase();
    if (c.contains(s)) return true;
    if (s == 'rice' && (c.contains('palay') || c.contains('rice'))) return true;
    if (s == 'gulay' && (c.contains('gulay') || c.contains('vegetable') || c.contains('talong') || c.contains('kamatis'))) return true;
    if (s == 'prutas' && (c.contains('prutas') || c.contains('fruit') || c.contains('saging') || c.contains('banana') || c.contains('mangga'))) return true;
    return false;
  }

  Future<String> _readFileSafely(File file) async {
    try {
      return await file.readAsString(encoding: utf8);
    } catch (_) {
      try {
        return await file.readAsString(encoding: latin1);
      } catch (e) {
        return '';
      }
    }
  }

  Future<String> _extractTextFromPdfFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final content = latin1.decode(bytes, allowInvalid: true);

      final regExp = RegExp(r'\(([^)]+)\)\s*Tj');
      final matches = regExp.allMatches(content);

      final sb = StringBuffer();
      for (final m in matches) {
        final text = m.group(1) ?? '';
        final cleanText = text.replaceAll(r'\(', '(').replaceAll(r'\)', ')').replaceAll(r'\\', '\\');
        sb.writeln(cleanText);
      }

      if (sb.isEmpty) {
        final lines = content.split('\n');
        for (final l in lines) {
          if (l.contains('|') || l.contains(',') || l.contains('\t')) {
            sb.writeln(l);
          }
        }
      }

      return sb.toString();
    } catch (e) {
      debugPrint('PDF extraction error: $e');
      return '';
    }
  }

  bool _parsePdfRowAndImport(String line, bool isHistorical, AccountService service, int index) {
    if (!line.contains('|')) return false;
    final parts = line.split('|').map((p) => p.trim()).toList();
    if (parts.length < 3) return false;

    final firstCol = parts[0].toLowerCase();
    if (firstCol.contains('no') || firstCol.contains('report') || firstCol.contains('generated') || firstCol.contains('pagsanjan') || firstCol.contains('smart') || firstCol.contains('agricultural')) {
      return false;
    }

    if (isHistorical) {
      if (parts.length >= 5) {
        final crop = parts[1];
        final year = int.tryParse(parts[2]) ?? DateTime.now().year;
        final month = parts[3];
        String barangay = 'ALL';
        double prod = 0.0;
        double price = 0.0;

        if (parts.length >= 6) {
          if (double.tryParse(parts[4].replaceAll('MT', '').trim()) != null) {
            prod = double.tryParse(parts[4].replaceAll('MT', '').trim()) ?? 0.0;
            price = double.tryParse(parts[5].replaceAll('P', '').replaceAll('PHP', '').trim()) ?? 0.0;
          } else {
            barangay = parts[4];
            prod = double.tryParse(parts[5].replaceAll('MT', '').trim()) ?? 0.0;
            price = parts.length > 6 ? double.tryParse(parts[6].replaceAll('P', '').replaceAll('PHP', '').trim()) ?? 0.0 : 0.0;
          }
        } else {
          prod = double.tryParse(parts[4].replaceAll('MT', '').trim()) ?? 0.0;
        }

        if (crop.isNotEmpty && prod >= 0) {
          final isDuplicate = service.historicalRecords.any((h) =>
          h.crop.toLowerCase() == crop.toLowerCase() &&
              h.year == year &&
              h.month.toLowerCase() == month.toLowerCase() &&
              h.barangay.toLowerCase() == barangay.toLowerCase());
          if (!isDuplicate) {
            service.addHistoricalRecord(
              crop: crop,
              year: year,
              month: month,
              barangay: barangay,
              productionMT: prod,
              pricePerKg: price,
              uploadedBy: service.activeUserName,
            );
            return true;
          }
        }
      }
    } else {
      if (parts.length >= 5) {
        final name = parts[1];
        if (name.isEmpty || name.toLowerCase() == 'farmer name' || name.toLowerCase() == 'n/a') return false;

        final location = parts.length > 2 ? parts[2] : 'Sitio Pagsanjan';
        final crop = parts.length > 3 ? parts[3] : 'Rice';
        final area = parts.length > 4 ? double.tryParse(parts[4].replaceAll('ha', '').trim()) ?? 2.0 : 2.0;

        final existing = service.farmers.any((f) => f.profileName.trim().toLowerCase() == name.toLowerCase());
        if (!existing) {
          final farmerId = 'F${DateTime.now().millisecondsSinceEpoch}_$index';
          final username = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
          service.addFarmer(
            id: farmerId,
            username: username,
            password: 'password123',
            profileName: name,
            barangay: 'Biñan',
            contactNumber: '09171234567',
            organization: 'Independent',
          );
          service.addFarmRecord(
            farmerId: farmerId,
            farmerName: name,
            locationName: location,
            latitude: 14.2717,
            longitude: 121.4553,
            landAreaHectares: area,
            tenureStatus: 'Owner',
            cropType: crop,
            barangay: 'Biñan',
          );
          return true;
        }
      }
    }
    return false;
  }

  Marker _buildBlueFarmMarker(FarmRecord farm, VoidCallback onTap) {
    Color primaryBlue;
    IconData cropIcon;

    final cropLower = farm.cropType.toLowerCase();
    if (cropLower.contains('rice') || cropLower.contains('palay')) {
      primaryBlue = const Color(0xFF1E3A8A); // Deep Royal Blue
      cropIcon = Icons.grass_rounded;
    } else if (cropLower.contains('gulay') || cropLower.contains('veg')) {
      primaryBlue = const Color(0xFF0284C7); // Ocean Cyan Blue
      cropIcon = Icons.eco_rounded;
    } else if (cropLower.contains('prutas') || cropLower.contains('fruit')) {
      primaryBlue = const Color(0xFF2563EB); // Electric Blue
      cropIcon = Icons.apple_rounded;
    } else {
      primaryBlue = const Color(0xFF0056B3); // Municipal Blue
      cropIcon = Icons.location_on_rounded;
    }

    return Marker(
      point: LatLng(farm.latitude, farm.longitude),
      width: 44,
      height: 48,
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
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Icon(cropIcon, color: Colors.white, size: 18),
            ),
            ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 8,
                height: 6,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final ScrollController _kpiScrollController = ScrollController();
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _histTable1ScrollController = ScrollController();
  final ScrollController _histTable2ScrollController = ScrollController();
  final ScrollController _dashHistScrollController = ScrollController();
  final ScrollController _farmersBrgyScrollController = ScrollController();
  final ScrollController _cropAreaBrgyScrollController = ScrollController();

  int _table1Page = 0;
  int _table2Page = 0;
  static const int _pageSize = 10;

  String _mlCropSearchQuery = '';
  int _mlCropPage = 0;
  static const int _mlPageSize = 6;

  int _dashHistPage = 0;

  String _farmerSortField = 'Name';
  bool _farmerSortAscending = true;
  String _selectedAssociationFilter = 'All';

  List<String> getUniqueOrganizations(AccountService service) {
    final set = <String>{};
    for (final f in service.farmers) {
      final org = f.organization.trim();
      if (org.isNotEmpty &&
          org != 'Choose Association' &&
          org != 'Pumili ng Samahan' &&
          org != 'Not Associated' &&
          org != 'Walang Samahan' &&
          org != 'Independent') {
        set.add(org);
      }
    }
    final list = set.toList()..sort();
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
        if (doLineSegmentsIntersect(a, b, c, d)) {
          return true;
        }
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

  FarmRecord? findOverlappingFarm(List<LatLng> newPoly, List<FarmRecord> allFarms, {String? excludeFarmId}) {
    if (newPoly.length < 3) return null;
    for (final farm in allFarms) {
      if (excludeFarmId != null && farm.id == excludeFarmId) continue;
      if (farm.boundaryPoints.length >= 3) {
        if (doPolygonsOverlap(newPoly, farm.boundaryPoints)) {
          return farm;
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AccountService>(context, listen: false).loadFromSupabase();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kpiScrollController.dispose();
    _sidebarScrollController.dispose();
    _histTable1ScrollController.dispose();
    _histTable2ScrollController.dispose();
    _dashHistScrollController.dispose();
    _farmersBrgyScrollController.dispose();
    _cropAreaBrgyScrollController.dispose();
    super.dispose();
  }

  String _generateValidPdfContent(String title, String bodyText) {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final safeTitle = title.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');

    final lines = bodyText.replaceAll('\r', '').split('\n').take(30).toList();
    final bodyLinesBuffer = StringBuffer();
    for (final l in lines) {
      if (l.trim().isEmpty) continue;
      final safeLine = l.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      bodyLinesBuffer.writeln('($safeLine) Tj T*');
    }

    final streamText = '''BT
/F1 14 Tf
16 TL
50 740 Td
($safeTitle) Tj T*
/F1 9 Tf
12 TL
(Generated on: $now | Pagsanjan MAO System) Tj T*
0 -10 Td
${bodyLinesBuffer.toString().trim()}
ET''';

    final streamBytesLength = streamText.length;

    final header = '%PDF-1.4\n';

    final obj1 = '''1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
''';

    final obj2 = '''2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
''';

    final obj3 = '''3 0 obj
<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
''';

    final obj4Header = '4 0 obj\n<< /Length $streamBytesLength >>\nstream\n';
    final obj4Footer = '\nendstream\nendobj\n';

    final offset1 = header.length;
    final offset2 = offset1 + obj1.length;
    final offset3 = offset2 + obj2.length;
    final offset4 = offset3 + obj3.length;
    final offsetXref = offset4 + obj4Header.length + streamBytesLength + obj4Footer.length;

    String formatOffset(int offset) => offset.toString().padLeft(10, '0');

    final xref = '''xref
0 5
0000000000 65535 f 
${formatOffset(offset1)} 00000 n 
${formatOffset(offset2)} 00000 n 
${formatOffset(offset3)} 00000 n 
${formatOffset(offset4)} 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
$offsetXref
%%EOF''';

    return '$header$obj1$obj2$obj3$obj4Header$streamText$obj4Footer$xref';
  }

  String _generateExportContent(String moduleName, String format, AccountService service) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final isCsv = format.toLowerCase().contains('excel') || format.toLowerCase().contains('csv');
    final mod = moduleName.toLowerCase();
    final operatorName = service.activeUserName.isNotEmpty ? service.activeUserName : 'MAO Admin';

    if (isCsv) {
      final sb = StringBuffer();
      sb.writeln('================================================================================');
      sb.writeln('PAGSANJAN AGRICULTURAL SYSTEM - MUNICIPAL AGRICULTURE OFFICE (MAO)');
      sb.writeln('Smart Farming. Brighter Tomorrow.');
      sb.writeln('================================================================================');
      sb.writeln('AGRICULTURAL REPORT');
      sb.writeln('Report Type    : ${moduleName.toUpperCase()}');
      sb.writeln('Generated Date : $dateStr');
      sb.writeln('Generated By   : $operatorName');
      sb.writeln('--------------------------------------------------------------------------------');
      sb.writeln('');

      if (mod.contains('farmer') && mod.contains('farm')) {
        sb.writeln('No.,Farmer Name,Barangay,Crop Type,Area (ha),Status,Contact,Organization');
        int i = 1;
        for (final f in service.farmers) {
          final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName).toList();
          if (farmerFarms.isEmpty) {
            sb.writeln('$i,"${f.profileName}","${f.barangay}","N/A",0.0,"${f.status}","${f.contactNumber}","${f.organization}"');
            i++;
          } else {
            for (final farm in farmerFarms) {
              sb.writeln('$i,"${f.profileName}","${farm.barangay}","${farm.cropType}",${farm.landAreaHectares},"${f.status}","${f.contactNumber}","${f.organization}"');
              i++;
            }
          }
        }
      } else if (mod.contains('account')) {
        if (mod.contains('admin')) {
          sb.writeln('No.,Staff Name,Username,Email Address,Role,Status');
          int i = 1;
          for (final s in service.adminStaffList) {
            sb.writeln('$i,"${s.name}",${s.username},${s.email},"${s.role}",${s.status}');
            i++;
          }
        } else {
          sb.writeln('No.,Farmer Name,Username,Barangay,Contact Number,Organization,Status');
          int i = 1;
          for (final f in service.farmers) {
            sb.writeln('$i,"${f.profileName}",${f.username},${f.barangay},${f.contactNumber},"${f.organization}",${f.status}');
            i++;
          }
        }
      } else if (mod.contains('historical')) {
        sb.writeln('No.,Crop,Year,Month,Barangay,Production (MT),Price per Kg (PHP),Uploaded By');
        int i = 1;
        for (final h in service.historicalRecords) {
          sb.writeln('$i,${h.crop},${h.year},${h.month},"${h.barangay}",${h.productionMT},${h.pricePerKg},"${h.uploadedBy}"');
          i++;
        }
      } else if (mod.contains('map')) {
        sb.writeln('No.,Farmer Name,Barangay,Land Area (ha),Crop Type');
        int i = 1;
        for (final farm in service.farms) {
          sb.writeln('$i,"${farm.farmerName}","${farm.barangay}",${farm.landAreaHectares},"${farm.cropType}"');
          i++;
        }
      } else if (mod.contains('activity') || mod.contains('log')) {
        sb.writeln('No.,Timestamp,Operator,Module,Action,Details');
        int i = 1;
        for (final l in service.activityLogs) {
          sb.writeln('$i,"${DateFormat('yyyy-MM-dd HH:mm').format(l.timestamp)}",${l.user},${l.module},${l.action},"${l.details}"');
          i++;
        }
      } else {
        sb.writeln('No.,Metric Title,Value,Description');
        sb.writeln('1,Registered Farmers,${service.farmers.length},Active Agricultural Directory');
        final totalArea = service.farms.fold(0.0, (sum, item) => sum + item.landAreaHectares);
        sb.writeln('2,Total Farm Area (ha),${totalArea.toStringAsFixed(1)},Pagsanjan Registered Farmlands');
      }
      return sb.toString();
    } else {
      // PDF FORMAT MATCHING THE REQUESTED REPORT TEMPLATE
      final textSb = StringBuffer();
      textSb.writeln('================================================================================');
      textSb.writeln(' PAGSANJAN AGRICULTURAL SYSTEM');
      textSb.writeln(' Smart Farming. Brighter Tomorrow.');
      textSb.writeln('================================================================================');
      textSb.writeln(' AGRICULTURAL REPORT');
      textSb.writeln(' Report Type    : ${moduleName.toUpperCase()}');
      textSb.writeln(' Generated Date : $dateStr');
      textSb.writeln(' Generated By   : $operatorName');
      textSb.writeln('--------------------------------------------------------------------------------');

      if (mod.contains('farmer') && mod.contains('farm')) {
        textSb.writeln(' No. | Farmer Name        | Farm Location       | Crop Type      | Area | Status');
        textSb.writeln('--------------------------------------------------------------------------------');
        int i = 1;
        for (final f in service.farmers) {
          final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName).toList();
          if (farmerFarms.isEmpty) {
            textSb.writeln(' ${i.toString().padLeft(3)} | ${f.profileName.padRight(18)} | ${'N/A'.padRight(19)} | ${'N/A'.padRight(14)} | ${'0.0'.padRight(4)} | ${f.status}');
            i++;
          } else {
            for (final farm in farmerFarms) {
              textSb.writeln(' ${i.toString().padLeft(3)} | ${f.profileName.padRight(18)} | ${farm.locationName.padRight(19)} | ${farm.cropType.padRight(14)} | ${farm.landAreaHectares.toStringAsFixed(1).padRight(4)} | ${f.status}');
              i++;
            }
          }
        }
      } else if (mod.contains('historical')) {
        textSb.writeln(' No. | Crop Name          | Year | Month     | Barangay    | Prod (MT) | Price/kg');
        textSb.writeln('--------------------------------------------------------------------------------');
        int i = 1;
        for (final h in service.historicalRecords) {
          textSb.writeln(' ${i.toString().padLeft(3)} | ${h.crop.padRight(18)} | ${h.year} | ${h.month.padRight(9)} | ${h.barangay.padRight(11)} | ${h.productionMT.toStringAsFixed(1).padRight(9)} | P${h.pricePerKg.toStringAsFixed(2)}');
          i++;
        }
      } else if (mod.contains('map')) {
        textSb.writeln(' No. | Farmer Name        | Sitio Location      | Barangay    | Area (ha)');
        textSb.writeln('--------------------------------------------------------------------------------');
        int i = 1;
        for (final farm in service.farms) {
          textSb.writeln(' ${i.toString().padLeft(3)} | ${farm.farmerName.padRight(18)} | ${farm.locationName.padRight(19)} | ${farm.barangay.padRight(11)} | ${farm.landAreaHectares.toStringAsFixed(1)}');
          i++;
        }
      } else if (mod.contains('activity') || mod.contains('log')) {
        textSb.writeln(' No. | Timestamp       | Operator   | Module     | Action');
        textSb.writeln('--------------------------------------------------------------------------------');
        int i = 1;
        for (final l in service.activityLogs) {
          textSb.writeln(' ${i.toString().padLeft(3)} | ${DateFormat('MM-dd HH:mm').format(l.timestamp).padRight(15)} | ${l.user.padRight(10)} | ${l.module.padRight(10)} | ${l.action}');
          i++;
        }
      } else {
        textSb.writeln(' No. | Summary Metric     | Value / Details');
        textSb.writeln('--------------------------------------------------------------------------------');
        int i = 1;
        textSb.writeln(' ${i.toString().padLeft(3)} | Registered Farmers  | ${service.farmers.length} Active Records');
        i++;
        final totalArea = service.farms.fold(0.0, (sum, item) => sum + item.landAreaHectares);
        textSb.writeln(' ${i.toString().padLeft(3)} | Total Farm Area     | ${totalArea.toStringAsFixed(1)} Hectares');
      }

      return _generateValidPdfContent('PAGSANJAN MAO REPORT: ${moduleName.toUpperCase()}', textSb.toString());
    }
  }

  Future<String?> _saveContentToUserDirectory(String fileName, String content, String selectedFolder) async {
    try {
      String baseDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
        baseDir = '$userProfile\\$selectedFolder';
      } else {
        baseDir = Directory.systemTemp.path;
      }
      final dir = Directory(baseDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final filePath = '$baseDir\\$fileName';
      final file = File(filePath);
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _generateStyledPdfBytes(String moduleName, AccountService service) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final operatorName = service.activeUserName.isNotEmpty ? service.activeUserName : 'MAO Admin';
    final mod = moduleName.toLowerCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Pagsanjan Agricultural System', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.green800)),
                    pw.Text('Smart Farming. Brighter Tomorrow.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: pdf_lib.PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text('MAO OFFICIAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.green800)),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdf_lib.PdfColors.green700, thickness: 2),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('AGRICULTURAL REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.green900, letterSpacing: 1.2)),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Pagsanjan Municipal Agriculture Office (MAO)', style: pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey600)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey600)),
          ],
        ),
        build: (context) {
          List<List<String>> tableData = [];
          List<String> headers = [];

          if (mod.contains('farmer') && mod.contains('farm')) {
            headers = ['No.', 'Farmer Name', 'Barangay', 'Crop Type', 'Area (ha)', 'Status'];
            int i = 1;
            for (final f in service.farmers) {
              final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName).toList();
              if (farmerFarms.isEmpty) {
                tableData.add(['$i', f.profileName, f.barangay, 'N/A', '0.0', f.status]);
                i++;
              } else {
                for (final farm in farmerFarms) {
                  tableData.add(['$i', f.profileName, farm.barangay, farm.cropType, farm.landAreaHectares.toStringAsFixed(1), f.status]);
                  i++;
                }
              }
            }
          } else if (mod.contains('historical')) {
            headers = ['No.', 'Crop', 'Year', 'Month', 'Barangay', 'Production (MT)', 'Price/kg (PHP)'];
            int i = 1;
            for (final h in service.historicalRecords) {
              tableData.add(['$i', h.crop, '${h.year}', h.month, h.barangay, h.productionMT.toString(), 'P${h.pricePerKg.toStringAsFixed(2)}']);
              i++;
            }
          } else if (mod.contains('account')) {
            if (mod.contains('admin')) {
              headers = ['No.', 'Staff Name', 'Username', 'Email', 'Role', 'Status'];
              int i = 1;
              for (final s in service.adminStaffList) {
                tableData.add(['$i', s.name, s.username, s.email, s.role, s.status]);
                i++;
              }
            } else {
              headers = ['No.', 'Farmer Name', 'Username', 'Barangay', 'Contact', 'Status'];
              int i = 1;
              for (final f in service.farmers) {
                tableData.add(['$i', f.profileName, f.username, f.barangay, f.contactNumber, f.status]);
                i++;
              }
            }
          } else if (mod.contains('map')) {
            headers = ['No.', 'Farmer Name', 'Barangay', 'Area (ha)', 'Crop Type'];
            int i = 1;
            for (final farm in service.farms) {
              tableData.add(['$i', farm.farmerName, farm.barangay, farm.landAreaHectares.toStringAsFixed(1), farm.cropType]);
              i++;
            }
          } else if (mod.contains('activity') || mod.contains('log')) {
            headers = ['No.', 'Timestamp', 'Operator', 'Module', 'Action', 'Details'];
            int i = 1;
            for (final l in service.activityLogs) {
              tableData.add(['$i', DateFormat('MM-dd HH:mm').format(l.timestamp), l.user, l.module, l.action, l.details]);
              i++;
            }
          } else {
            headers = ['No.', 'Metric Title', 'Value', 'Description'];
            tableData.add(['1', 'Registered Farmers', service.farmers.length.toString(), 'Active Agricultural Directory']);
            final totalArea = service.farms.fold(0.0, (sum, item) => sum + item.landAreaHectares);
            tableData.add(['2', 'Total Farm Area (ha)', totalArea.toStringAsFixed(1), 'Pagsanjan Registered Farmlands']);
          }

          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: pdf_lib.PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: pdf_lib.PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Report Type    : ${moduleName.toUpperCase()}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated Date : $dateStr', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated By   : $operatorName', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: tableData,
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.green700, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.green800),
              cellHeight: 24,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
              },
              oddRowDecoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey50),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  void _triggerExport(BuildContext context, String fullType, bool isTagalog) async {
    final service = Provider.of<AccountService>(context, listen: false);
    final parts = fullType.split('(');
    final moduleName = parts[0].trim();
    final format = parts.length > 1 ? parts[1].replaceAll(')', '').trim() : 'CSV';
    final isPdf = format.toLowerCase().contains('pdf');
    final ext = isPdf ? 'pdf' : 'csv';
    final fileName = 'PAGSANJAN_MAO_${moduleName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    if (isPdf) {
      try {
        final pdfBytes = await _generateStyledPdfBytes(moduleName, service);
        String baseDir;
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
          baseDir = '$userProfile\\Downloads';
        } else {
          baseDir = Directory.systemTemp.path;
        }
        final filePath = '$baseDir\\$fileName';
        await File(filePath).writeAsBytes(pdfBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTagalog
                    ? 'Matagumpay na nai-save ang styled PDF report sa Downloads: $fileName'
                    : 'Successfully saved styled PDF report to Downloads: $fileName',
              ),
              backgroundColor: const Color(0xFF0056B3),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generating PDF: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    String chosenFolder = 'Downloads';
    final content = _generateExportContent(moduleName, format, service);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded, color: isPdf ? Colors.redAccent : const Color(0xFF0284C7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTagalog ? 'Export & Save File ($ext)' : 'Export & Save File ($ext)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTagalog
                      ? 'Pumili kung saang folder sa iyong computer ilalagay ang idodownload na .$ext file:'
                      : 'Choose which directory in your device to save the exported .$ext file:',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: chosenFolder,
                  decoration: InputDecoration(
                    labelText: isTagalog ? 'Pumili ng Folder/Directory' : 'Select Destination Directory',
                    prefixIcon: const Icon(Icons.folder_special_rounded, color: Color(0xFF0056B3)),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Downloads', child: Text('Downloads Folder (C:\\Users\\...\\Downloads)')),
                    DropdownMenuItem(value: 'Documents', child: Text('Documents Folder (C:\\Users\\...\\Documents)')),
                    DropdownMenuItem(value: 'Desktop', child: Text('Desktop Folder (C:\\Users\\...\\Desktop)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => chosenFolder = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text('File Name: $fileName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
              onPressed: () async {
                final savedPath = await _saveContentToUserDirectory(fileName, content, chosenFolder);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        savedPath != null
                            ? (isTagalog
                            ? 'Matagumpay na nai-save ang $fileName sa: $savedPath'
                            : 'Successfully saved $fileName to: $savedPath')
                            : (isTagalog
                            ? 'Nai-save ang file na $fileName!'
                            : 'File $fileName saved!'),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(isTagalog ? 'I-download sa Selected Folder' : 'Download to Selected Folder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickFileWithSystemExplorer() async {
    try {
      if (Platform.isWindows) {
        const psScript = r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Filter = "All Files (*.*)|*.*"
$dlg.Title = "Pagsanjan MAO - Select File to Import"
$dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host $dlg.FileName
}
''';
        final utf16Units = psScript.codeUnits;
        final utf16Bytes = <int>[];
        for (final unit in utf16Units) {
          utf16Bytes.add(unit & 0xFF);
          utf16Bytes.add((unit >> 8) & 0xFF);
        }
        final b64 = base64.encode(utf16Bytes);

        final result = await Process.run('powershell', ['-NoProfile', '-EncodedCommand', b64]);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim();
          if (path.isNotEmpty && await File(path).exists()) {
            return path;
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
    return null;
  }

  void _showImportDialog(
      BuildContext context,
      String moduleName,
      AccountService service,
      AdminLocale locale, {
        String? initialPath,
        String? initialContent,
      }) {
    final isTagalog = locale.isTagalog;
    String selectedSourceDir = 'Downloads';
    final fileNameCtrl = TextEditingController(text: initialPath ?? '');
    final csvCtrl = TextEditingController(text: initialContent ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.upload_file_rounded, color: Color(0xFF0056B3)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTagalog ? 'Mag-import ng File - $moduleName' : 'Import File - $moduleName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTagalog
                      ? 'I-click ang button sa ibaba upang buksan ang File Explorer ng iyong computer at pumili ng file:'
                      : 'Click the button below to open File Explorer and choose a file from your device:',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),

                // BLANK EXCEL/CSV TEMPLATE DOWNLOAD BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0056B3),
                      side: const BorderSide(color: Color(0xFF0056B3)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final isHistorical = moduleName.toLowerCase().contains('historical');
                      final templateCsv = isHistorical
                          ? 'Crop,Year,Month,Barangay,Production (KG)\n'
                          'Rice,2026,January,Biñan,480000\n'
                          'Prutas (Banana),2025,November,Anibong,120000\n'
                          'Gulay (Talong),2025,December,Buboy,85000\n'
                          : 'Full Personal Name,Username,Barangay,Contact Number,Organization Membership,Tenure Status,Primary Crop Type,Land Area (Hectares)\n'
                          'Juan Dela Cruz,juan_dela_cruz,Biñan,09171234567,Pagsanjan Farmers Coop,Owner,Rice,2.5\n'
                          'Maria Santos,maria_santos,Buboy,09189876543,Anibong Planters,Tenant,Gulay,1.2\n'
                          'Pedro Reyes,pedro_reyes,Calusiche,09191112233,Not Associated,Hired Farmworkers,Rice,2.0\n';

                      final targetFileName = isHistorical ? 'pagsanjan_historical_data_template.csv' : 'pagsanjan_farmers_blank_template.csv';

                      try {
                        String userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
                        String downloadsPath = '$userProfile\\Downloads\\$targetFileName';
                        final file = File(downloadsPath);
                        await file.writeAsString(templateCsv);

                        setDialogState(() {
                          fileNameCtrl.text = downloadsPath;
                          csvCtrl.text = templateCsv;
                        });

                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Matagumpay na na-save ang blank template sa Downloads folder: $targetFileName'
                                    : 'Saved blank template to Downloads folder: $targetFileName',
                              ),
                              backgroundColor: const Color(0xFF0056B3),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          csvCtrl.text = templateCsv;
                        });
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Na-load ang blank template sa preview! Maari mo itong kopyahin.'
                                    : 'Loaded blank template in preview!',
                              ),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      moduleName.toLowerCase().contains('historical')
                          ? (isTagalog ? '📄 Kumuha ng Blank Excel/CSV Template para sa Historical Data' : '📄 Get Blank Historical Data Template')
                          : (isTagalog ? '📄 Kumuha ng Blank Excel/CSV Template para sa Farmer Details' : '📄 Get Blank Excel/CSV Farmer Template'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // NATIVE FILE EXPLORER BROWSE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx); // Close dialog first to avoid blur/freeze
                      final pickedPath = await _pickFileWithSystemExplorer();
                      if (pickedPath != null && pickedPath.isNotEmpty) {
                        final file = File(pickedPath);
                        if (await file.exists()) {
                          String content;
                          if (pickedPath.toLowerCase().endsWith('.pdf')) {
                            content = await _extractTextFromPdfFile(file);
                          } else {
                            content = await _readFileSafely(file);
                          }
                          if (context.mounted) {
                            _showImportDialog(context, moduleName, service, locale, initialPath: pickedPath, initialContent: content);
                          }
                        }
                      } else {
                        if (context.mounted) {
                          _showImportDialog(context, moduleName, service, locale);
                        }
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded, size: 20),
                    label: Text(
                      isTagalog ? '📁 Pumili ng File sa File Explorer (Browse)' : '📁 Choose File in File Explorer (Browse)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        isTagalog ? 'o manwal na pumili sa folder' : 'or manually select from directory',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSourceDir,
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Folder' : 'Folder',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Downloads', child: Text('Downloads')),
                          DropdownMenuItem(value: 'Documents', child: Text('Documents')),
                          DropdownMenuItem(value: 'Desktop', child: Text('Desktop')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedSourceDir = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: fileNameCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Pangalan ng File / Path' : 'File Name / Path',
                          hintText: 'mga_magsasaka.csv',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final folder = selectedSourceDir;
                      final fname = fileNameCtrl.text.trim();
                      if (fname.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              isTagalog
                                  ? 'Mangyaring pumili ng file sa File Explorer o maglagay ng pangalan ng file.'
                                  : 'Please choose a file via File Explorer or enter a file name.',
                            ),
                            backgroundColor: Colors.orange.shade800,
                          ),
                        );
                        return;
                      }

                      try {
                        String fullPath = fname;
                        if (!fname.contains('\\') && !fname.contains('/')) {
                          String userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
                          fullPath = '$userProfile\\$folder\\$fname';
                        }
                        final file = File(fullPath);
                        if (await file.exists()) {
                          final textContent = await _readFileSafely(file);
                          setDialogState(() {
                            fileNameCtrl.text = fullPath;
                            csvCtrl.text = textContent;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTagalog
                                      ? 'Matagumpay na nabasa ang file mula sa: $fullPath'
                                      : 'Successfully read file from: $fullPath',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTagalog
                                      ? 'Hindi nahanap ang file sa $fullPath.'
                                      : 'File not found at $fullPath.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Nagkaroon ng error sa pagbasa ng file: $e'
                                    : 'Error reading file: $e',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.file_present_rounded, size: 16),
                    label: Text(isTagalog ? 'Kargahin ang File mula sa Path' : 'Load File from Specified Path'),
                  ),
                ),
                if (fileNameCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileNameCtrl.text,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
              onPressed: () async {
                final rawText = csvCtrl.text.trim();
                if (rawText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTagalog
                            ? 'Walang kargang file! Mangyaring mag-upload muna ng file sa File Explorer.'
                            : 'No file loaded! Please choose a file via File Explorer first.',
                      ),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                  return;
                }

                final isHistorical = moduleName.toLowerCase().contains('historical');
                final lines = rawText.split('\n');
                int importedCount = 0;
                int skippedCount = 0;

                for (final line in lines) {
                  final trimmedLine = line.trim();
                  if (trimmedLine.isEmpty) continue;

                  if (trimmedLine.contains('|')) {
                    final success = _parsePdfRowAndImport(trimmedLine, isHistorical, service, importedCount);
                    if (success) {
                      importedCount++;
                    } else {
                      skippedCount++;
                    }
                    continue;
                  }

                  // Skip header lines or export report title lines
                  if (trimmedLine.toLowerCase().startsWith('crop') ||
                      trimmedLine.toLowerCase().startsWith('full personal name') ||
                      trimmedLine.toLowerCase().startsWith('no.') ||
                      trimmedLine.toLowerCase().contains('official export report') ||
                      trimmedLine.toLowerCase().contains('agricultural report') ||
                      trimmedLine.toLowerCase().contains('generated on') ||
                      trimmedLine.toLowerCase().contains('pagsanjan') ||
                      trimmedLine.toLowerCase().contains('smart farming') ||
                      trimmedLine.toLowerCase().contains('pagsanjan agricultural')) {
                    continue;
                  }

                  final parts = _parseCsvLine(trimmedLine);

                  if (isHistorical) {
                    int offset = parts.length >= 5 && double.tryParse(parts[0]) != null && parts[0].length <= 3 ? 1 : 0;
                    if (parts.length >= (4 + offset)) {
                      final crop = parts[0 + offset].trim();
                      final year = int.tryParse(parts[1 + offset].trim()) ?? 0;
                      final month = parts[2 + offset].trim();

                      String barangay = 'ALL';
                      double prod = -1.0;
                      double price = 0.0;

                      if (parts.length >= (6 + offset)) {
                        barangay = parts[3 + offset].trim();
                        prod = double.tryParse(parts[4 + offset].trim()) ?? -1.0;
                        price = double.tryParse(parts[5 + offset].trim()) ?? 0.0;
                      } else {
                        prod = double.tryParse(parts[3 + offset].trim()) ?? -1.0;
                        price = parts.length > (4 + offset) ? (double.tryParse(parts[4 + offset].trim()) ?? 0.0) : 0.0;
                      }

                      // Validate incomplete data
                      if (crop.isEmpty || year <= 0 || month.isEmpty || prod < 0) {
                        skippedCount++;
                        continue;
                      }

                      // Check duplicate in historical records
                      final isDuplicate = service.historicalRecords.any((h) =>
                      h.crop.toLowerCase() == crop.toLowerCase() &&
                          h.year == year &&
                          h.month.toLowerCase() == month.toLowerCase() &&
                          h.barangay.toLowerCase() == barangay.toLowerCase());

                      if (isDuplicate) {
                        skippedCount++;
                        continue;
                      }

                      service.addHistoricalRecord(
                        crop: crop,
                        year: year,
                        month: month,
                        barangay: barangay,
                        productionMT: prod,
                        pricePerKg: price,
                        uploadedBy: service.activeUserName,
                      );
                      importedCount++;
                    } else {
                      skippedCount++;
                    }
                  } else {
                    int offset = parts.length >= 7 && double.tryParse(parts[0]) != null && parts[0].length <= 3 ? 1 : 0;
                    if (parts.length >= (2 + offset)) {
                      final name = parts[0 + offset].trim();
                      final user = parts[1 + offset].trim();
                      final barangay = parts.length > (2 + offset) && parts[2 + offset].trim().isNotEmpty ? parts[2 + offset].trim() : 'Biñan';
                      final contact = parts.length > (3 + offset) && parts[3 + offset].trim().isNotEmpty ? parts[3 + offset].trim() : '09171234567';
                      final org = parts.length > (4 + offset) && parts[4 + offset].trim().isNotEmpty ? parts[4 + offset].trim() : 'Not Associated';
                      
                      String tenure = 'Owner';
                      String crop = 'Rice';
                      double land = 2.0;

                      if (parts.length >= (8 + offset)) {
                        tenure = parts[5 + offset].trim().isNotEmpty ? parts[5 + offset].trim() : 'Owner';
                        crop = parts[6 + offset].trim().isNotEmpty ? parts[6 + offset].trim() : 'Rice';
                        land = double.tryParse(parts[7 + offset].trim()) ?? 2.0;
                      } else if (parts.length >= (7 + offset)) {
                        crop = parts[5 + offset].trim().isNotEmpty ? parts[5 + offset].trim() : 'Rice';
                        land = double.tryParse(parts[6 + offset].trim()) ?? 2.0;
                      }

                      // Validate incomplete data (Name and Username strictly required)
                      if (name.isEmpty || user.isEmpty) {
                        skippedCount++;
                        continue;
                      }

                      final contactDigits = contact.replaceAll(RegExp(r'\D'), '');

                      // Check duplicate: Name, Username, or Contact
                      final existingFarmer = service.farmers.any((f) =>
                      f.profileName.trim().toLowerCase() == name.toLowerCase() ||
                          f.username.trim().toLowerCase() == user.toLowerCase() ||
                          (contactDigits.isNotEmpty && f.contactNumber.replaceAll(RegExp(r'\D'), '') == contactDigits));

                      if (existingFarmer) {
                        skippedCount++;
                        continue;
                      }

                      final farmerId = 'F${DateTime.now().millisecondsSinceEpoch}_$importedCount';
                      await service.addFarmer(
                        id: farmerId,
                        username: user,
                        password: 'password123',
                        profileName: name,
                        barangay: barangay,
                        contactNumber: contactDigits.isEmpty ? '09171234567' : contactDigits,
                        organization: org,
                      );
                      await service.addFarmRecord(
                        farmerId: farmerId,
                        farmerName: name,
                        locationName: 'Sitio $barangay',
                        latitude: 14.2717,
                        longitude: 121.4553,
                        landAreaHectares: land,
                        tenureStatus: tenure,
                        cropType: crop,
                        barangay: barangay,
                      );
                      importedCount++;
                    } else {
                      skippedCount++;
                    }
                  }
                }

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isTagalog
                          ? 'Matagumpay na na-import ang $importedCount bagong rekord! ($skippedCount na duplicate o kulang ang data ang na-filter out).'
                          : 'Successfully imported $importedCount new records! ($skippedCount duplicate or incomplete records were skipped).',
                    ),
                    backgroundColor: const Color(0xFF0056B3),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(isTagalog ? 'I-process at I-import' : 'Process & Import'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildExportImportButtons(BuildContext context, String moduleName, AdminLocale locale, AccountService service, {bool showImport = true, bool allowPdf = false}) {
    final isTagalog = locale.isTagalog;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // DIRECT EXCEL / CSV EXPORT BUTTON
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056B3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () => _triggerExport(context, '$moduleName (Excel/CSV)', isTagalog),
          icon: const Icon(Icons.table_chart_rounded, size: 18),
          label: Text(
            isTagalog ? 'I-export sa Excel' : 'Export Excel',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),

        // SINGLE DIRECT IMPORT BUTTON
        if (showImport)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: () {
              _showImportDialog(context, moduleName, service, locale);
            },
            icon: const Icon(Icons.file_upload_rounded, size: 18),
            label: Text(
              isTagalog ? 'I-import ang CSV' : 'Import CSV',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(locale.isTagalog ? 'Kumpirmahin ang Logout' : 'Confirm Logout'),
          ],
        ),
        content: Text(
          locale.isTagalog
              ? 'Sigurado ka bang gusto mong mag-logout sa Admin Portal?'
              : 'Are you sure you want to log out of the Admin Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/thank_you');
            },
            child: Text(locale.isTagalog ? 'Mag-logout' : 'Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AccountService>(context);
    final isDark = service.isDarkMode;
    final isTagalog = service.isTagalog;
    final locale = AdminLocale(isTagalog);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;

    // SHADES OF BLUE COLOR PALETTE
    final bgColor = isDark ? const Color(0xFF0A111E) : const Color(0xFFF0F4F9);
    final sidebarBg = isDark ? const Color(0xFF081427) : const Color(0xFFE3F2FD);
    final cardBg = isDark ? const Color(0xFF121E31) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBorder = isDark ? const Color(0xFF1E2E4A) : const Color(0xFFD0E1F9);
    final primaryAccent = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0056B3);
    final secondaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);

    final sidebarContent = Container(
      width: 275,
      color: sidebarBg,
      child: Scrollbar(
        controller: _sidebarScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _sidebarScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Branding Widget
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                        : [const Color(0xFF0056B3), const Color(0xFF0A2540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF93C5FD), size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.adminTitle,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.location,
                            style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ACTIVE STAFF OPERATOR CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFF90CAF9)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFF60A5FA),
                      foregroundColor: Colors.white,
                      child: Text(
                        service.activeStaff.name.isNotEmpty ? service.activeStaff.name[0] : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.activeStaff.name,
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            service.activeStaff.role,
                            style: TextStyle(color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0056B3), fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: isDark ? Colors.white12 : const Color(0xFF90CAF9), height: 1),
              ),
              const SizedBox(height: 8),

              // Nav Items List (0 to 6 unified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _buildNavItem(icon: Icons.dashboard_rounded, label: locale.navDashboard, index: 0, isDark: isDark),
                    _buildNavItem(icon: Icons.badge_rounded, label: locale.navFarmers, index: 1, isDark: isDark),
                    _buildNavItem(icon: Icons.history_edu_rounded, label: locale.navHistorical, index: 2, isDark: isDark),
                    _buildNavItem(icon: Icons.map_rounded, label: locale.navMap, index: 3, isDark: isDark),
                    _buildNavItem(icon: Icons.manage_accounts_rounded, label: locale.navAccounts, index: 4, isDark: isDark),
                    _buildNavItem(icon: Icons.supervisor_account_rounded, label: locale.navAdminStaff, index: 5, isDark: isDark),
                    _buildNavItem(icon: Icons.receipt_long_rounded, label: locale.navActivityLog, index: 6, isDark: isDark),
                    _buildNavItem(icon: Icons.psychology_rounded, label: isTagalog ? 'Machine Learning' : 'Machine Learning', index: 7, isDark: isDark),
                  ],
                ),
              ),

              // SETTINGS / ACTIONS BELOW ACTIVITY LOG
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: isDark ? Colors.white12 : const Color(0xFF90CAF9), height: 1),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    // Language toggle
                    _buildSidebarAction(
                      icon: Icons.language_rounded,
                      label: isTagalog ? '🇵🇭 Tagalog' : '🇺🇸 English',
                      trailingIcon: Icons.swap_horiz_rounded,
                      iconColor: primaryAccent,
                      textColor: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      onTap: () => service.toggleLanguage(),
                    ),
                    // Dark / light mode toggle
                    _buildSidebarAction(
                      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      label: isDark
                          ? (isTagalog ? 'Light Mode' : 'Switch to Light Mode')
                          : (isTagalog ? 'Dark Mode' : 'Switch to Dark Mode'),
                      iconColor: isDark ? Colors.amber : const Color(0xFF0056B3),
                      textColor: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      onTap: () => service.toggleTheme(),
                    ),
                    // Announcement
                    _buildSidebarAction(
                      icon: Icons.campaign_rounded,
                      label: isTagalog ? 'Gumawa ng Anunsyo' : 'Post Announcement',
                      iconColor: primaryAccent,
                      textColor: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      onTap: () => _showCreatePostDialog(context, service, locale),
                    ),
                    _buildSidebarAction(
                      icon: Icons.article_rounded,
                      label: isTagalog ? 'Pamahalaan ang Anunsyo' : 'Manage Announcements',
                      iconColor: primaryAccent,
                      textColor: isDark ? Colors.white70 : const Color(0xFF0F172A),
                      onTap: () => _showManagePostsDialog(context, service, locale),
                    ),
                    // Logout
                    _buildSidebarAction(
                      icon: Icons.logout_rounded,
                      label: locale.navLogout,
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                      onTap: () => _confirmLogout(context, locale),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    Widget mainContentArea;
    switch (_selectedIndex) {
      case 0:
        mainContentArea = _buildDashboardSummaryView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent, secondaryBlue);
        break;
      case 1:
        mainContentArea = _buildFarmerRecordsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 2:
        mainContentArea = _buildHistoricalDataView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 3:
        mainContentArea = _buildInteractiveMapView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 4:
        mainContentArea = _buildFarmerAccountsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 5:
        mainContentArea = _buildAdminAccountsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 6:
        mainContentArea = _buildActivityLogView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 7:
        mainContentArea = _buildMachineLearningView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      default:
        mainContentArea = _buildDashboardSummaryView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent, secondaryBlue);
    }

    // TOP HEADER: logo + title only (controls moved to the sidebar)
    final topHeader = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('Pagri.jpg', width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Color(0xFF0056B3))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale.adminTitle,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                locale.officeSubtitle,
                style: TextStyle(color: subtextColor, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );

    final fullBody = Column(
      children: [
        topHeader,
        Expanded(child: mainContentArea),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sidebarContent,
            Expanded(child: fullBody),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: sidebarBg,
          foregroundColor: Colors.white,
          title: Text(locale.adminTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _confirmLogout(context, locale),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: sidebarBg,
          child: sidebarContent,
        ),
        body: fullBody,
      );
    }
  }

  Widget _buildSidebarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color iconColor,
    required Color textColor,
    IconData? trailingIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 13),
        ),
        trailing: trailingIcon != null ? Icon(trailingIcon, size: 16, color: iconColor) : null,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isDark}) {
    final isSelected = _selectedIndex == index;
    final activeBg = isDark ? const Color(0xFF2563EB).withValues(alpha: 0.25) : const Color(0xFF0056B3).withValues(alpha: 0.15);
    final activeText = isDark ? const Color(0xFF60A5FA) : const Color(0xFF0056B3);
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF0F172A);
    final inactiveIcon = isDark ? Colors.white60 : const Color(0xFF0056B3);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: activeText.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? activeText : inactiveIcon, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeText : inactiveText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // ==========================================
  // MODULE 1: DASHBOARD SUMMARY
  // ==========================================
  Widget _buildDashboardSummaryView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      Color secondaryBlue,
      ) {
    final farmers = service.farmers;
    final farms = service.farms;
    final historical = service.historicalRecords;

    final filteredFarms = farms.where((f) {
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay.trim().toLowerCase() == _selectedBarangayFilter.trim().toLowerCase();
      final matchesCrop = _matchesCrop(f.cropType, _selectedCropFilter);
      return matchesBarangay && matchesCrop;
    }).toList();

    final filteredFarmers = farmers.where((f) {
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay.trim().toLowerCase() == _selectedBarangayFilter.trim().toLowerCase();
      if (!matchesBarangay) return false;
      if (_selectedCropFilter == 'All') return true;
      final farmerFarms = farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName);
      return farmerFarms.any((farm) => _matchesCrop(farm.cropType, _selectedCropFilter));
    }).toList();

    final filteredHistorical = historical.where((h) {
      final matchesBarangay = _selectedBarangayFilter == 'All' ||
          h.barangay.trim().toLowerCase() == _selectedBarangayFilter.trim().toLowerCase() ||
          h.barangay.toUpperCase() == 'ALL';
      final matchesCrop = _matchesCrop(h.crop, _selectedCropFilter);
      if (!matchesBarangay || !matchesCrop) return false;
      if (_selectedTimePeriodFilter == 'All') return true;
      if (_selectedTimePeriodFilter == '2026') return h.year == 2026;
      if (_selectedTimePeriodFilter == '2025') return h.year == 2025;
      final m = h.month.toLowerCase();
      if (_selectedTimePeriodFilter == 'Wet Season') {
        return m.contains('may') || m.contains('jun') || m.contains('jul') || m.contains('aug') || m.contains('sep') || m.contains('oct');
      }
      if (_selectedTimePeriodFilter == 'Dry Season') {
        return m.contains('nov') || m.contains('dec') || m.contains('jan') || m.contains('feb') || m.contains('mar') || m.contains('apr');
      }
      return true;
    }).toList();

    final totalDashHist = filteredHistorical.length;
    final maxDashHistPages = (totalDashHist / 10).ceil();
    final safeDashHistPage = maxDashHistPages > 0 ? math.min(_dashHistPage, maxDashHistPages - 1) : 0;
    final startDashHist = safeDashHistPage * 10;
    final endDashHist = math.min(startDashHist + 10, totalDashHist);
    final paginatedDashHistorical = totalDashHist > 0 ? filteredHistorical.sublist(startDashHist, endDashHist) : <HistoricalDataRecord>[];

    final totalFarmersCount = filteredFarmers.length;
    final totalFarmArea = filteredFarms.fold(0.0, (sum, item) => sum + item.landAreaHectares);

    final Map<String, int> farmersPerBarangay = {};
    final Map<String, double> areaPerBarangay = {};
    final Map<String, Map<String, double>> cropAreaPerBarangay = {};

    for (final b in AccountService.pagsanjanBarangays) {
      farmersPerBarangay[b] = 0;
      areaPerBarangay[b] = 0.0;
      cropAreaPerBarangay[b] = {};
    }

    for (final f in filteredFarmers) {
      final normBrgy = AccountService.normalizeBarangay(f.barangay);
      farmersPerBarangay[normBrgy] = (farmersPerBarangay[normBrgy] ?? 0) + 1;
    }

    final Map<String, double> areaPerCrop = {};
    for (final farm in filteredFarms) {
      final normBrgy = AccountService.normalizeBarangay(farm.barangay);
      areaPerBarangay[normBrgy] = (areaPerBarangay[normBrgy] ?? 0.0) + farm.landAreaHectares;
      areaPerCrop[farm.cropType] = (areaPerCrop[farm.cropType] ?? 0.0) + farm.landAreaHectares;

      final brgyCrops = cropAreaPerBarangay[normBrgy] ?? {};
      brgyCrops[farm.cropType] = (brgyCrops[farm.cropType] ?? 0.0) + farm.landAreaHectares;
      cropAreaPerBarangay[normBrgy] = brgyCrops;
    }

    return SingleChildScrollView(
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
                  Text(locale.execSummary, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent, letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  Text(locale.agriOverview, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildExportImportButtons(context, 'Full Executive Summary', locale, service, showImport: false),
            ],
          ),
          const SizedBox(height: 18),

          // Filter Controls Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: isDark ? [] : const [BoxShadow(color: Color(0x0A0056B3), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt_rounded, size: 18, color: primaryAccent),
                    const SizedBox(width: 6),
                    Text(locale.filterTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBarangayFilter,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCropFilter,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Crop Type',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', 'Rice', 'Prutas', 'Gulay'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedCropFilter = val ?? 'All'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTimePeriodFilter,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: locale.isTagalog ? 'Panahon' : 'Period',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', '2026', '2025', 'Wet Season', 'Dry Season'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _selectedTimePeriodFilter = val ?? 'All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Cards Summary Row with 2 Wider KPI Cards (Registered Farmers & Total Farm Area) & Scrollbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121E31) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1E2E4A) : const Color(0xFF90CAF9)),
            ),
            child: Scrollbar(
              controller: _kpiScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _kpiScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 380,
                      child: _buildKpiCard(
                        title: locale.kpiFarmers,
                        value: '$totalFarmersCount',
                        subtitle: locale.location,
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF0056B3),
                        cardBg: cardBg,
                        textColor: textColor,
                        cardBorder: cardBorder,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 380,
                      child: _buildKpiCard(
                        title: locale.kpiFarmArea,
                        value: '${totalFarmArea.toStringAsFixed(1)} ha',
                        subtitle: 'Active Land',
                        icon: Icons.landscape_rounded,
                        color: const Color(0xFF0284C7),
                        cardBg: cardBg,
                        textColor: textColor,
                        cardBorder: cardBorder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Weather Card
          _buildWeatherCard(locale, isDark, cardBg, textColor, primaryAccent),
          const SizedBox(height: 20),

          // Data Breakdown Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(locale.farmersPerBarangay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: primaryAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: const Text('16 Barangays', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (farmersPerBarangay.isEmpty)
                        Text('No records found', style: TextStyle(color: subtextColor))
                      else
                        SizedBox(
                          height: 320,
                          child: Scrollbar(
                            controller: _farmersBrgyScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            child: ListView(
                              controller: _farmersBrgyScrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: farmersPerBarangay.entries.map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(entry.key, style: TextStyle(fontSize: 13, color: textColor))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: primaryAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                      child: Text('${entry.value} ${locale.isTagalog ? "magsasaka" : "farmers"}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(locale.areaPerCrop, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: const Text('16 Barangays', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (areaPerBarangay.isEmpty)
                        Text('No records found', style: TextStyle(color: subtextColor))
                      else
                        SizedBox(
                          height: 320,
                          child: Scrollbar(
                            controller: _cropAreaBrgyScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            child: ListView(
                              controller: _cropAreaBrgyScrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                ...areaPerBarangay.entries.map((entry) {
                                  final brgyCrops = cropAreaPerBarangay[entry.key] ?? {};
                                  final topCrop = brgyCrops.isNotEmpty
                                      ? brgyCrops.entries.reduce((a, b) => a.value > b.value ? a : b).key
                                      : 'Rice';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(entry.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                                              Text(
                                                '${locale.isTagalog ? "Pangunahing tanim" : "Primary Crop"}: $topCrop',
                                                style: TextStyle(fontSize: 11, color: subtextColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${entry.value.toStringAsFixed(1)} ha',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    locale.isTagalog ? 'Kabuuan Bawat Uri ng Tanim:' : 'Total Area per Crop Type:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryAccent),
                                  ),
                                ),
                                ...areaPerCrop.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(entry.key, style: TextStyle(fontSize: 12, color: textColor))),
                                      Text('${entry.value.toStringAsFixed(1)} ha', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                                    ],
                                  ),
                                )),
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
          const SizedBox(height: 20),

          // Historical Production & Price Trends
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(locale.historicalTrends, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                ),
                if (filteredHistorical.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Text('No historical records match the selected filters.', style: TextStyle(color: subtextColor, fontSize: 13)),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Scrollbar(
                      controller: _dashHistScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _dashHistScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Crop', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Period', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Barangay', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Production (KG)', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Uploaded By', style: TextStyle(color: subtextColor))),
                          ],
                          rows: paginatedDashHistorical.map((h) {
                            final prodKg = h.productionMT >= 100 ? h.productionMT : (h.productionMT * 1000);
                            final nf = NumberFormat('#,###');
                            return DataRow(
                              cells: [
                                DataCell(Text(h.crop, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                                DataCell(Text('${h.month} ${h.year}', style: TextStyle(color: textColor))),
                                DataCell(Text(h.barangay, style: TextStyle(color: textColor))),
                                DataCell(Text('${nf.format(prodKg.round())} kg', style: TextStyle(color: textColor))),
                                DataCell(Text(h.uploadedBy, style: TextStyle(color: textColor))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  _buildPaginationBar(
                    currentPage: safeDashHistPage,
                    totalItems: totalDashHist,
                    pageSize: 10,
                    onPageChanged: (newPage) => setState(() => _dashHistPage = newPage),
                    isDark: isDark,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    primaryAccent: primaryAccent,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // FARMER ASSOCIATIONS & ORGANIZATIONS DIRECTORY
          Builder(builder: (context) {
            final assocMap = <String, List<Farmer>>{};
            for (final f in service.farmers) {
              final org = f.organization.trim().isEmpty ? 'Not Associated' : f.organization.trim();
              assocMap.putIfAbsent(org, () => []).add(f);
            }

            final uniqueOrgs = assocMap.keys.where((k) => k != 'Not Associated' && k != 'Independent').toList()..sort();

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: Color(0xFF0284C7), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            locale.isTagalog ? 'Mga Samahan at Asosasyon ng Magsasaka' : 'Farmer Associations Directory',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '${uniqueOrgs.length} ${locale.isTagalog ? "Samahan" : "Associations"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (assocMap.isEmpty)
                    Text(locale.isTagalog ? 'Walang nahanap na samahan' : 'No associations found', style: TextStyle(color: subtextColor))
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final org in assocMap.keys)
                          Container(
                            width: 320,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: org == 'Not Associated' || org == 'Independent'
                                            ? Colors.grey.withValues(alpha: 0.15)
                                            : primaryAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        org == 'Not Associated' || org == 'Independent' ? Icons.person_off_rounded : Icons.groups_rounded,
                                        color: org == 'Not Associated' || org == 'Independent' ? Colors.grey : primaryAccent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            org,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${assocMap[org]!.length} ${locale.isTagalog ? "kasaping magsasaka" : "member farmers"}',
                                            style: TextStyle(fontSize: 11, color: subtextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Text(
                                  locale.isTagalog ? 'Mga Kasapi:' : 'Members:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtextColor),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: assocMap[org]!.take(5).map((f) => Chip(
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    avatar: CircleAvatar(
                                      backgroundColor: primaryAccent.withValues(alpha: 0.2),
                                      child: Text(f.profileName.isNotEmpty ? f.profileName[0].toUpperCase() : 'F', style: TextStyle(fontSize: 10, color: primaryAccent)),
                                    ),
                                    label: Text(f.profileName, style: TextStyle(fontSize: 11, color: textColor)),
                                    backgroundColor: cardBg,
                                    side: BorderSide(color: cardBorder),
                                  )).toList(),
                                ),
                                if (assocMap[org]!.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '+ ${assocMap[org]!.length - 5} ${locale.isTagalog ? "iba pa" : "more members"}',
                                      style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: primaryAccent),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 7: MACHINE LEARNING & AI
  // ==========================================
  Widget _buildMachineLearningView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    return SingleChildScrollView(
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
                  Text('MACHINE LEARNING & AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent, letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  Text(
                    locale.isTagalog ? 'Machine Learning Predictions & Accuracy' : 'Machine Learning Price Predictions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Machine Learning Predictions', locale, service, showImport: false, allowPdf: false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ML PREDICTIONS CARD
          _buildMlFarmgatePricePredictionCard(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent),
        ],
      ),
    );
  }

  Widget _buildMlFarmgatePricePredictionCard(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final status = service.modelStatus;
    final isTagalog = locale.isTagalog;
    final forecasts = service.supabasePriceForecasts;
    final forecastModels = service.supabaseForecastModels;

    double getUploadedFarmgatePrice(String cropName, String lookupKey, double fallback) {
      final cleanKey = lookupKey.toLowerCase().trim();
      final cleanName = cropName.toLowerCase().trim();
      final shortKey = cleanName.split(' ')[0].split('(')[0].trim();

      for (final m in service.marketPriceRecords) {
        final veg = m.vegetable.toLowerCase().trim();
        if (veg == cleanKey || veg == cleanName || veg.contains(shortKey) || cleanName.contains(veg)) {
          if (m.farmgatePrice > 0) return m.farmgatePrice;
        }
      }

      for (final h in service.historicalRecords) {
        final c = h.crop.toLowerCase().trim();
        if (c == cleanKey || c == cleanName || c.contains(shortKey) || cleanName.contains(c)) {
          if (h.pricePerKg > 0) return h.pricePerKg;
        }
      }

      return fallback;
    }

    double getUploadedMarketPrice(String cropName, String lookupKey, double fallback) {
      final cleanKey = lookupKey.toLowerCase().trim();
      final cleanName = cropName.toLowerCase().trim();
      final shortKey = cleanName.split(' ')[0].split('(')[0].trim();

      for (final m in service.marketPriceRecords) {
        final veg = m.vegetable.toLowerCase().trim();
        if (veg == cleanKey || veg == cleanName || veg.contains(shortKey) || cleanName.contains(veg)) {
          if (m.marketPrice > 0) return m.marketPrice;
        }
      }

      final fg = getUploadedFarmgatePrice(cropName, lookupKey, fallback);
      return double.parse((fg * 1.4).toStringAsFixed(2));
    }

    // Build dynamic set of ALL crops present in the database
    final Set<String> dbCropNames = {};
    for (final m in service.marketPriceRecords) {
      if (m.vegetable.trim().isNotEmpty) dbCropNames.add(m.vegetable.trim());
    }
    for (final h in service.historicalRecords) {
      if (h.crop.trim().isNotEmpty) dbCropNames.add(h.crop.trim());
    }
    for (final k in forecasts.keys) {
      if (k.trim().isNotEmpty) dbCropNames.add(k.trim());
    }

    // Default standard list if DB is initializing
    final defaultCrops = [
      'Rice', 'Talong (Eggplant)', 'Kamatis (Tomato)', 'Sitaw (Yardlong Bean)',
      'Ampalaya (Bitter Gourd)', 'Saging (Banana)', 'Okra', 'Pechay (Tagalog)',
      'Kalabasa (Squash)', 'Labanos (Radish)', 'Carrot', 'Patatas (Potato)'
    ];

    if (dbCropNames.isEmpty) {
      dbCropNames.addAll(defaultCrops);
    }

    Color getCropColor(String crop) {
      final lc = crop.toLowerCase();
      if (lc.contains('rice') || lc.contains('palay')) return const Color(0xFFC0A02B);
      if (lc.contains('talong') || lc.contains('eggplant')) return const Color(0xFF7B4FA3);
      if (lc.contains('kamatis') || lc.contains('tomato')) return const Color(0xFFE5533D);
      if (lc.contains('sitaw') || lc.contains('bean')) return const Color(0xFF2E9E5B);
      if (lc.contains('ampalaya') || lc.contains('bitter')) return const Color(0xFF16A34A);
      if (lc.contains('saging') || lc.contains('banana') || lc.contains('saba') || lc.contains('lakatan')) return const Color(0xFFE6A700);
      if (lc.contains('okra')) return const Color(0xFF65A30D);
      if (lc.contains('pechay') || lc.contains('petchay')) return const Color(0xFF0D9488);
      if (lc.contains('kalabasa') || lc.contains('squash')) return const Color(0xFFD97706);
      return const Color(0xFF0284C7);
    }

    IconData getCropIcon(String crop) {
      final lc = crop.toLowerCase();
      if (lc.contains('rice') || lc.contains('palay')) return Icons.grass_rounded;
      if (lc.contains('saging') || lc.contains('banana') || lc.contains('coconut') || lc.contains('niyog')) return Icons.park_rounded;
      return Icons.eco_rounded;
    }

    final filteredCropNames = dbCropNames.where((cropName) {
      if (_mlCropSearchQuery.trim().isEmpty) return true;
      return cropName.toLowerCase().contains(_mlCropSearchQuery.trim().toLowerCase());
    }).toList();

    final totalMlItems = filteredCropNames.length;
    final maxMlPages = (totalMlItems / _mlPageSize).ceil();
    final safeMlPage = maxMlPages > 0 ? math.min(_mlCropPage, maxMlPages - 1) : 0;
    final startMl = safeMlPage * _mlPageSize;
    final endMl = math.min(startMl + _mlPageSize, totalMlItems);
    final paginatedCropNames = totalMlItems > 0 ? filteredCropNames.sublist(startMl, endMl) : <String>[];

    final cropPredictions = paginatedCropNames.map((cropName) {
      return {
        'crop': cropName,
        'lookupKey': cropName,
        'icon': getCropIcon(cropName),
        'color': getCropColor(cropName),
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: isDark ? [] : const [BoxShadow(color: Color(0x0A0056B3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTagalog ? '🤖 ML Prediksyon ng Presyo sa Bukid (dss_pagsanjan_ml.py)' : '🤖 ML Farmgate Price Predictions (dss_pagsanjan_ml.py)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTagalog ? 'Pinatatakbo ng dss_pagsanjan_ml.py • ARIMA, ElasticNet, RandomForest & Gaussian Process' : 'Powered by dss_pagsanjan_ml.py • ARIMA, ElasticNet, RandomForest & Gaussian Process',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      onChanged: (val) => setState(() {
                        _mlCropSearchQuery = val;
                        _mlCropPage = 0;
                      }),
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isTagalog ? 'Magsaliksik ng pananim...' : 'Search crop...',
                        hintStyle: TextStyle(color: subtextColor, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _mlCropSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setState(() {
                                  _mlCropSearchQuery = '';
                                  _mlCropPage = 0;
                                }),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      'ML Accuracy: ${(100 - status.mape).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                Text('MAE: ±₱${status.mae.toStringAsFixed(2)}/kg', style: TextStyle(fontSize: 12, color: subtextColor)),
                Text('RMSE: ${status.rmse.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: subtextColor)),
                Text('Trained Records: ${status.trainedRecordsCount}', style: TextStyle(fontSize: 12, color: subtextColor)),
                Text('Last Run: ${DateFormat('MMM d, h:mm a').format(status.lastUpdated)}', style: TextStyle(fontSize: 12, color: subtextColor)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final crossAxisCount = isWide ? 3 : (constraints.maxWidth > 550 ? 2 : 1);

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: cropPredictions.map((item) {
                  final double width = (constraints.maxWidth - (14 * (crossAxisCount - 1))) / crossAxisCount;

                  final key = (item['lookupKey'] as String?) ?? '';
                  final cropName = (item['crop'] as String?) ?? '';
                  final fallbackFg = (item['currentFarmgate'] as num?)?.toDouble() ?? 35.0;
                  final fallbackMkt = (item['marketRetail'] as num?)?.toDouble() ?? (fallbackFg * 1.4);

                  final currentPrice = getUploadedFarmgatePrice(cropName, key, fallbackFg);
                  final marketPrice = getUploadedMarketPrice(cropName, key, fallbackMkt);

                  final predictedPrice = forecasts[key] ?? forecasts[cropName] ?? (item['defaultPredicted'] as num?)?.toDouble() ?? (currentPrice * 1.05);
                  final modelName = forecastModels[key] ?? (item['defaultDriver'] as String?) ?? 'dss_pagsanjan_ml (Ensemble)';

                  final diff = predictedPrice - currentPrice;
                  final pct = currentPrice > 0 ? (diff / currentPrice) * 100 : 0.0;
                  final isUp = diff >= 0;
                  final trendStr = '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%';
                  final itemColor = item['color'] as Color;

                  return Container(
                    width: width,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF132338) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: itemColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: itemColor.withValues(alpha: 0.15),
                              child: Icon(item['icon'] as IconData, size: 16, color: itemColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['crop'] as String,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isUp ? const Color(0xFF16A34A) : Colors.redAccent).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 14,
                                    color: isUp ? const Color(0xFF16A34A) : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    trendStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isUp ? const Color(0xFF16A34A) : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTagalog ? 'Kasalukuyang Bukid' : 'Current Farmgate',
                                  style: TextStyle(fontSize: 11, color: subtextColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₱${currentPrice.toStringAsFixed(2)}/kg',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: subtextColor.withValues(alpha: 0.5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isTagalog ? 'Prediksyon sa Bukid' : 'Predicted Farmgate',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₱${predictedPrice.toStringAsFixed(2)}/kg',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTagalog ? 'Presyo sa Palengke:' : 'Market Retail Price:',
                                style: TextStyle(fontSize: 11, color: subtextColor),
                              ),
                              Text(
                                '₱${marketPrice.toStringAsFixed(2)}/kg',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined, size: 13, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'dss_pagsanjan_ml.py ($modelName)',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: subtextColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildPaginationBar(
            currentPage: safeMlPage,
            totalItems: totalMlItems,
            pageSize: _mlPageSize,
            onPageChanged: (newPage) => setState(() => _mlCropPage = newPage),
            isDark: isDark,
            textColor: textColor,
            subtextColor: subtextColor,
            primaryAccent: const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(AdminLocale locale, bool isDark, Color cardBg, Color textColor, Color primaryAccent) {
    final forecast = [
      {'temp': '30°C', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber, 'condition': 'Sunny'},
      {'temp': '28°C', 'icon': Icons.grain_rounded, 'color': Colors.lightBlueAccent, 'condition': 'Light Rain'},
      {'temp': '29°C', 'icon': Icons.cloud_rounded, 'color': Colors.grey, 'condition': 'Partly Cloudy'},
      {'temp': '31°C', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber, 'condition': 'Clear Sky'},
      {'temp': '27°C', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent, 'condition': 'Showers'},
    ];

    // Forecast days with real upcoming dates
    final ictDays = List.generate(forecast.length, (i) {
      final d = DateTime.now().add(Duration(days: i + 1));
      return <String, Object>{
        ...forecast[i],
        'day': DateFormat('E').format(d),
        'date': DateFormat('MMM d').format(d),
      };
    });

    // Current conditions (placeholder values; replace with _liveWeather fields
    // once you know the WeatherBundle property names)
    const currentTemp = '29°C';
    const currentCond = 'Partly Cloudy';
    const currentHumidity = '76%';
    const currentRain = '0.0 mm';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF0056B3), const Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_cloudy_rounded, color: Color(0xFF93C5FD), size: 30),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.weatherTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${locale.location} (14.2717° N, 121.4553° E) • Open-Meteo Live', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(locale.liveUpdated, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(currentTemp, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentCond, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('Real-time meteorological live feed', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 16,
                children: [
                  _buildWeatherInfoBadge(Icons.water_drop_rounded, 'Humidity', currentHumidity),
                  _buildWeatherInfoBadge(Icons.thunderstorm_rounded, 'Rainfall', currentRain),
                  _buildWeatherInfoBadge(Icons.eco_rounded, 'Soil Temp', '26.5°C'),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 26),

          // 7-DAY FORECAST WITH DATES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(locale.weatherForecast, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(12)),
                child: Text(locale.weatherAdvisory, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ictDays.map((f) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(f['day'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text(f['date'] as String, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                    const SizedBox(height: 2),
                    Icon(f['icon'] as IconData, color: f['color'] as Color, size: 20),
                    const SizedBox(height: 2),
                    Text(f['temp'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(f['condition'] as String, style: const TextStyle(color: Colors.white70, fontSize: 9), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 14),

          // MOST FAVORABLE CROP NEXT MONTH ADVISORY BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: Color(0xFF86EFAC), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isTagalog ? '🌱 Paboritong Itanim sa Susunod na Buwan:' : '🌱 Most Favorable Crop to Plant Next Month:',
                        style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locale.isTagalog
                            ? 'Gulay (Espesipikong Variety: Talong [Ilocano Long] & Okra [Emerald]) • Angkop sa 30-day soil moisture at inaasahang ulan.'
                            : 'Vegetables (Specific Variety: Eggplant [Ilocano Long] & Okra [Emerald]) • Ideal for upcoming 30-day soil moisture & expected rainfall.',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // WEEK 2 TO WEEK 4 MONTHLY OUTLOOK
          Text(
            locale.isTagalog ? '30-Araw na Ulat (Week 2 - Week 4 Outlook)' : '30-Day Extended Outlook (Week 2 - Week 4)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMonthForecastWeek('Week 2', '30°C', locale.isTagalog ? 'Bahagyang Maulap' : 'Partly Cloudy', Icons.cloud_queue_rounded, Colors.lightBlueAccent),
              _buildMonthForecastWeek('Week 3', '28°C', locale.isTagalog ? 'Mahinang Ulan' : 'Moderate Rain', Icons.grain_rounded, Colors.blueAccent),
              _buildMonthForecastWeek('Week 4', '29°C', locale.isTagalog ? 'Angkop na Tubig' : 'Ideal Growth', Icons.eco_rounded, Colors.greenAccent),
            ].map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthForecastWeek(String weekLabel, String temp, String condition, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(weekLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(temp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(condition, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoBadge(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF93C5FD), size: 18),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color textColor,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            radius: 22,
            child: Icon(icon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 2: UNIFIED FARMER & FARM RECORDS
  // ==========================================
  Widget _buildFarmerRecordsView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      ) {
    final farmers = service.farmers.where((f) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = f.profileName.toLowerCase().contains(query) ||
          f.username.toLowerCase().contains(query) ||
          f.organization.toLowerCase().contains(query);
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay.trim().toLowerCase() == _selectedBarangayFilter.trim().toLowerCase();
      final matchesAssoc = _selectedAssociationFilter == 'All' || f.organization.trim().toLowerCase() == _selectedAssociationFilter.trim().toLowerCase();
      return matchesQuery && matchesBarangay && matchesAssoc;
    }).toList();

    farmers.sort((a, b) {
      int comparison = 0;
      switch (_farmerSortField) {
        case 'Barangay':
          comparison = a.barangay.compareTo(b.barangay);
          break;
        case 'Status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'Organization':
          comparison = a.organization.compareTo(b.organization);
          break;
        case 'Username':
          comparison = a.username.compareTo(b.username);
          break;
        case 'Name':
        default:
          comparison = a.profileName.toLowerCase().compareTo(b.profileName.toLowerCase());
          break;
      }
      return _farmerSortAscending ? comparison : -comparison;
    });

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
                  Text('DIRECTORY & LANDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.farmerDirTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Farmer and Farm Records', locale, service, showImport: false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: locale.searchFarmerPlaceholder,
                    hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBarangayFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    labelStyle: TextStyle(color: subtextColor, fontSize: 11.5),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedAssociationFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: locale.isTagalog ? 'Samahan' : 'Association',
                    labelStyle: TextStyle(color: subtextColor, fontSize: 11.5),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: ['All', 'Not Associated', ...getUniqueOrganizations(service)]
                      .map((org) => DropdownMenuItem(value: org, child: Text(org, overflow: TextOverflow.ellipsis, maxLines: 1)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedAssociationFilter = val ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: farmers.length,
              itemBuilder: (context, index) {
                final farmer = farmers[index];
                final farmerFarms = service.farms.where((f) {
                  final fid = f.farmerId.trim().toLowerCase();
                  final fname = f.farmerName.trim().toLowerCase();
                  final pid = farmer.id.trim().toLowerCase();
                  final pname = farmer.profileName.trim().toLowerCase();
                  final puname = farmer.username.trim().toLowerCase();

                  return (fid.isNotEmpty && (fid == pid || fid == puname)) ||
                      (fname.isNotEmpty && (fname == pname || fname == puname));
                }).toList();

                final allFarmerCrops = <String>{
                  ...farmer.records,
                  ...farmerFarms.map((f) => f.cropType),
                }.where((c) => c.trim().isNotEmpty).toList();

                return Card(
                  color: cardBg,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cardBorder),
                  ),
                  elevation: isDark ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Farmer Personal Details Header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryAccent.withValues(alpha: 0.15),
                              foregroundColor: primaryAccent,
                              radius: 22,
                              child: Text(farmer.profileName.isNotEmpty ? farmer.profileName[0] : 'F', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(farmer.profileName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: farmer.status == 'Active' ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(farmer.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: farmer.status == 'Active' ? Colors.green : Colors.orange)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Username: @${farmer.username} • Barangay: ${farmer.barangay} • Contact: ${farmer.contactNumber}', style: TextStyle(fontSize: 12, color: subtextColor)),
                                  Text('Organization: ${farmer.organization}', style: TextStyle(fontSize: 12, color: subtextColor)),
                                  if (allFarmerCrops.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          locale.isTagalog ? 'Mga Na-save na Tanim: ' : 'All Saved Crops: ',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                        ),
                                        ...allFarmerCrops.map((c) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF16A34A)),
                                              const SizedBox(width: 4),
                                              Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                                  tooltip: 'Edit Farmer',
                                  onPressed: () => _showEditFarmerDialog(context, service, farmer),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF0284C7), size: 20),
                                  tooltip: 'Add Farm Record for Farmer',
                                  onPressed: () => _showAddFarmForFarmerDialog(context, service, farmer),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: 'Delete Farmer',
                                  onPressed: () => _confirmDeleteFarmer(context, service, farmer, locale),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Associated Farm Records Section (Directly Inside Farmer Card)
                        Row(
                          children: [
                            Icon(Icons.landscape_rounded, size: 16, color: primaryAccent),
                            const SizedBox(width: 6),
                            Text(
                              locale.isTagalog ? 'Mga Rekord ng Sakahan (${farmerFarms.length})' : 'Associated Farm Records (${farmerFarms.length})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (farmerFarms.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  locale.isTagalog ? 'Walang nakatalagang sakahan.' : 'No associated farm records yet.',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: subtextColor),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _showAddFarmForFarmerDialog(context, service, farmer),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: Text(locale.isTagalog ? 'Magdagdag ng Sakahan' : 'Add Farm', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        else
                          ...farmerFarms.map((farm) => Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0A111E) : Colors.blue.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? const Color(0xFF1E3A8A) : Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Farmer: ${farmer.profileName}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryAccent),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '• Crop: ${farm.cropType}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('${farm.landAreaHectares} ha', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(farm.tenureStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Location: ${farm.locationName}, Barangay ${farm.barangay} • GPS: [${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}]',
                                        style: TextStyle(fontSize: 11, color: subtextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  tooltip: 'Delete Farm Record',
                                  onPressed: () => _confirmDeleteFarmRecord(context, service, farm, locale),
                                ),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFarmerDialog(BuildContext context, AccountService service) {
    final isTagalog = service.isTagalog;
    final scrollCtrl = ScrollController();
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final customOrgCtrl = TextEditingController();
    final empSearchCtrl = TextEditingController();
    final addressCtrl = TextEditingController(); // Complete Address
    final landAreaCtrl = TextEditingController(); // Empty start
    final latCtrl = TextEditingController(); // Empty start
    final lonCtrl = TextEditingController(); // Empty start
    final specificCropCtrl = TextEditingController();
    final List<String> specificCropsList = [];
    final List<LatLng> boundaryPoints = [];
    String selectedBrgy = 'Biñan';
    String selectedTenure = 'Owner';

    final existingOrgs = getUniqueOrganizations(service);
    String selectedOrg = 'Choose Association';
    bool isAddingCustomOrg = false;

    // Field-level error messages
    String? nameErrorText;
    String? userErrorText;
    String? contactErrorText;
    String? addressErrorText;
    String? cropsErrorText;
    String? gpsErrorText;
    String? dialogErrorBanner; // Visible top banner inside dialog!

    final primaryCropOptions = isTagalog
        ? [
      {'key': 'Rice', 'label': '🌾 Palay (Rice)'},
      {'key': 'Gulay', 'label': '🥬 Gulay (Vegetables)'},
      {'key': 'Prutas', 'label': '🍎 Prutas (Fruits)'},
    ]
        : [
      {'key': 'Rice', 'label': '🌾 Rice'},
      {'key': 'Gulay', 'label': '🥬 Vegetables'},
      {'key': 'Prutas', 'label': '🍎 Fruits'},
    ];

    final Set<String> selectedPrimaryCrops = <String>{}; // Empty start

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          content: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLUE HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0056B3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTagalog ? 'Magdagdag ng Magsasaka at Sakahan' : 'Add New Farmer & Farm Record',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PROMINENT RED ERROR ALERT BANNER AT TOP OF DIALOG FORM
                        if (dialogErrorBanner != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dialogErrorBanner!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF991B1B)),
                                  onPressed: () {
                                    setDialogState(() {
                                      dialogErrorBanner = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // SECTION 1: FARMER ACCOUNT INFO
                        Row(
                          children: [
                            const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF0056B3)),
                            const SizedBox(width: 6),
                            Text(
                              isTagalog ? 'IMPORMASYON NG AKAWNT NG MAGSASAKA' : 'FARMER ACCOUNT INFORMATION',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Buong Pangalan' : 'Full Personal Name',
                            errorText: nameErrorText,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (_) {
                            if (nameErrorText != null) {
                              setDialogState(() {
                                nameErrorText = null;
                                dialogErrorBanner = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: userCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  errorText: userErrorText,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (_) {
                                  if (userErrorText != null) {
                                    setDialogState(() {
                                      userErrorText = null;
                                      dialogErrorBanner = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: passCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedBrgy,
                                decoration: InputDecoration(
                                  labelText: 'Barangay',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                onChanged: (val) => selectedBrgy = val ?? 'Biñan',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: contactCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                decoration: InputDecoration(
                                  labelText: isTagalog ? 'Numero ng Kontak (Opsyonal)' : 'Contact Number (Optional)',
                                  hintText: '09123456789',
                                  errorText: contactErrorText,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  helperText: isTagalog ? 'Opsyonal: Saktong 11 numero kung lalagyan (hal. 09123456789)' : 'Optional: 11 digits if provided (e.g. 09123456789)',
                                ),
                                onChanged: (val) {
                                  final digitsOnly = val.replaceAll(RegExp(r'\D'), '');
                                  setDialogState(() {
                                    if (digitsOnly.isNotEmpty && digitsOnly.length != 11) {
                                      contactErrorText = isTagalog
                                          ? 'Dapat 11 numero (${digitsOnly.length}/11)'
                                          : 'Must be 11 digits (${digitsOnly.length}/11)';
                                    } else {
                                      contactErrorText = null;
                                    }
                                    dialogErrorBanner = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedOrg,
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Samahan / Asosasyon' : 'Association / Organization',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Choose Association',
                              child: Text(isTagalog ? 'Pumili ng Samahan (Choose Association)' : 'Choose Association', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            DropdownMenuItem(
                              value: 'Not Associated',
                              child: Text(isTagalog ? 'Walang Samahan (Not Associated)' : 'Not Associated', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            ...existingOrgs.map((org) => DropdownMenuItem(
                              value: org,
                              child: Text(org, overflow: TextOverflow.ellipsis, maxLines: 1),
                            )),
                            DropdownMenuItem(
                              value: 'ADD_NEW',
                              child: Text(
                                isTagalog ? '➕ Magdagdag ng Bagong Samahan' : '➕ Add New Association',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedOrg = val ?? 'Choose Association';
                              isAddingCustomOrg = (selectedOrg == 'ADD_NEW');
                            });
                          },
                        ),
                        if (isAddingCustomOrg) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: customOrgCtrl,
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Pangalan ng Bagong Samahan' : 'New Association Name',
                              hintText: 'e.g. Pagsanjan Organic Farmers Coop',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],

                        const Divider(height: 28, thickness: 1.2),

                        // SECTION 2: FARM INFORMATION
                        Row(
                          children: [
                            const Icon(Icons.agriculture_rounded, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              isTagalog ? 'IMPORMASYON NG SAKAHAN AT TANIM' : 'FARM LAND & CROP INFORMATION',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // MULTI-SELECT PRIMARY CROP TYPES (BLUE CHIPS)
                        Text(
                          isTagalog
                              ? 'Mga Pangunahing Tanim (Pumili ng isa o higit pa):'
                              : 'Primary Crop Types (Select all that apply):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: primaryCropOptions.map((cropOpt) {
                            final key = cropOpt['key']!;
                            final label = cropOpt['label']!;
                            final isSelected = selectedPrimaryCrops.contains(key);
                            return FilterChip(
                              selected: isSelected,
                              label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selectedColor: const Color(0xFFDBEAFE),
                              checkmarkColor: const Color(0xFF1E40AF),
                              labelStyle: TextStyle(color: isSelected ? const Color(0xFF1E40AF) : Colors.black87),
                              side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
                              onSelected: (bool selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedPrimaryCrops.add(key);
                                  } else {
                                    selectedPrimaryCrops.remove(key);
                                  }
                                  cropsErrorText = null;
                                  dialogErrorBanner = null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (cropsErrorText != null) ...[
                          const SizedBox(height: 4),
                          Text(cropsErrorText!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                        const SizedBox(height: 12),

                        // SPECIFIC CROP VARIETIES INPUT
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTagalog
                                  ? 'TIYAK NA URI O VARIETY NG TANIM (SPECIFIC TYPES)'
                                  : 'SPECIFIC CROP TYPES & VARIETIES (OPTIONAL)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: specificCropCtrl,
                                    decoration: InputDecoration(
                                      labelText: isTagalog
                                          ? 'I-type ang tanim (hal. Mangga, Saging, Talong, NSIC Rc 222)'
                                          : 'Type specific crop (e.g. Mango, Banana, Eggplant, NSIC Rc 222)',
                                      hintText: isTagalog ? 'I-type at i-press ang (+)' : 'Type and press (+)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onSubmitted: (val) {
                                      final trimmed = val.trim();
                                      if (trimmed.isNotEmpty && !specificCropsList.contains(trimmed)) {
                                        setDialogState(() {
                                          specificCropsList.add(trimmed);
                                          specificCropCtrl.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
                                  onPressed: () {
                                    final trimmed = specificCropCtrl.text.trim();
                                    if (trimmed.isNotEmpty && !specificCropsList.contains(trimmed)) {
                                      setDialogState(() {
                                        specificCropsList.add(trimmed);
                                        specificCropCtrl.clear();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                                  tooltip: isTagalog ? 'Idagdag' : 'Add',
                                ),
                              ],
                            ),
                            if (specificCropsList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: specificCropsList.map((item) {
                                  return Chip(
                                    avatar: const Icon(Icons.eco_rounded, size: 14, color: Color(0xFF1E40AF)),
                                    label: Text(
                                      item,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                                    ),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    deleteIcon: const Icon(Icons.cancel, size: 16, color: Color(0xFF1E40AF)),
                                    onDeleted: () {
                                      setDialogState(() {
                                        specificCropsList.remove(item);
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: landAreaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: isTagalog ? 'Laki ng Lupa (hektarya)' : 'Land Area (ha)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedTenure,
                                decoration: InputDecoration(
                                  labelText: isTagalog ? 'Katayuan sa Lupa' : 'Tenure Status',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: ['Owner', 'Tenant', 'Lease', 'CLT', 'Hired Farmworkers'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedTenure = val ?? 'Owner';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (selectedTenure == 'Hired Farmworkers') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: empSearchCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Maghanap ng Employer (Pangalan o Barangay)' : 'Search Employer (Name or Barangay)',
                              hintText: isTagalog ? 'I-type ang pangalan ng employer...' : 'Type employer name...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFEFF6FF),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                              suffixIcon: empSearchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setDialogState(() {
                                          empSearchCtrl.clear();
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Pumili ng Employer (Owner/Tenant/Lease/CLT)' : 'Select Employer (Owner/Tenant/Lease/CLT)',
                              hintText: isTagalog ? 'Sino ang may-ari/tenant/nagpaupa?' : 'Who hired this farmworker?',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFEFF6FF),
                              prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0284C7)),
                            ),
                            items: service.farmers
                                .where((f) {
                                  if (f.profileName.trim().isEmpty) return false;
                                  final q = empSearchCtrl.text.trim().toLowerCase();
                                  final matchesQuery = q.isEmpty ||
                                      f.profileName.toLowerCase().contains(q) ||
                                      f.username.toLowerCase().contains(q) ||
                                      f.barangay.toLowerCase().contains(q);
                                  if (!matchesQuery) return false;

                                  final fFarm = service.farms.firstWhere(
                                    (farm) => farm.farmerId == f.id || farm.farmerName == f.profileName,
                                    orElse: () => FarmRecord(
                                      id: '',
                                      farmerId: f.id,
                                      farmerName: f.profileName,
                                      locationName: 'Sitio ${f.barangay}',
                                      latitude: 14.2790,
                                      longitude: 121.4550,
                                      landAreaHectares: 2.0,
                                      tenureStatus: 'Owner',
                                      cropType: 'Rice',
                                      barangay: f.barangay,
                                    ),
                                  );
                                  final tenure = fFarm.tenureStatus.toLowerCase();
                                  return tenure == 'owner' || tenure == 'tenant' || tenure == 'lease' || tenure == 'clt' || tenure.contains('owner') || tenure.contains('tenant') || tenure.contains('lease');
                                })
                                .map((f) {
                                  final fFarm = service.farms.firstWhere(
                                    (farm) => farm.farmerId == f.id || farm.farmerName == f.profileName,
                                    orElse: () => FarmRecord(
                                      id: '',
                                      farmerId: f.id,
                                      farmerName: f.profileName,
                                      locationName: 'Sitio ${f.barangay}',
                                      latitude: 14.2790,
                                      longitude: 121.4550,
                                      landAreaHectares: 2.0,
                                      tenureStatus: 'Owner',
                                      cropType: 'Rice',
                                      barangay: f.barangay,
                                    ),
                                  );
                                  return DropdownMenuItem(
                                    value: f.id,
                                    child: Text(
                                      '${f.profileName} (${fFarm.tenureStatus} · ${f.barangay})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: (empId) {
                              if (empId != null) {
                                setDialogState(() {
                                  final empFarmer = service.farmers.firstWhere((f) => f.id == empId, orElse: () => service.farmers.first);
                                  final empFarm = service.farms.firstWhere(
                                    (farm) => farm.farmerId == empId || farm.farmerName == empFarmer.profileName,
                                    orElse: () => FarmRecord(
                                      id: 'AUTO_FARM',
                                      farmerId: empFarmer.id,
                                      farmerName: empFarmer.profileName,
                                      locationName: 'Sitio ${empFarmer.barangay}',
                                      latitude: 14.2790,
                                      longitude: 121.4550,
                                      landAreaHectares: 2.0,
                                      tenureStatus: 'Owner',
                                      cropType: 'Rice',
                                      barangay: empFarmer.barangay,
                                    ),
                                  );

                                  landAreaCtrl.text = empFarm.landAreaHectares.toStringAsFixed(1);
                                  selectedBrgy = empFarm.barangay;
                                  addressCtrl.text = empFarm.locationName.trim().isNotEmpty
                                      ? empFarm.locationName
                                      : 'House #${empFarmer.id.substring(math.max(0, empFarmer.id.length - 3))}, Brgy. ${empFarm.barangay}, Pagsanjan';
                                  latCtrl.text = empFarm.latitude.toStringAsFixed(5);
                                  lonCtrl.text = empFarm.longitude.toStringAsFixed(5);
                                });
                              }
                            },
                          ),
                        ],

                        const SizedBox(height: 10),
                        // COMPLETE ADDRESS INPUT FIELD
                        TextField(
                          controller: addressCtrl,
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Kumpletong Address / Lokasyon ng Sakahan' : 'Complete Address / Farm Location',
                            hintText: isTagalog ? 'hal. House #12, Sitio Layugan, Brgy. Biñan, Pagsanjan' : 'e.g. House #12, Sitio Layugan, Brgy. Biñan, Pagsanjan',
                            errorText: addressErrorText,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.home_work_rounded, color: Color(0xFF0056B3)),
                          ),
                          onChanged: (_) {
                            if (addressErrorText != null) {
                              setDialogState(() {
                                addressErrorText = null;
                                dialogErrorBanner = null;
                              });
                            }
                          },
                        ),

                        const Divider(height: 28, thickness: 1.2),

                        // SECTION 3: GPS COORDINATES & MAP PICKER (READ ONLY LAT/LON)
                        Row(
                          children: [
                            const Icon(Icons.map_rounded, size: 18, color: Color(0xFF0056B3)),
                            const SizedBox(width: 6),
                            Text(
                              isTagalog ? 'GPS KOORDINADA NG SAKAHAN (MULA SA MAPA)' : 'FARM GPS COORDINATES (FROM MAP)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Latitude (°N)',
                                  hintText: isTagalog ? 'Lalabas kapag pumili sa mapa' : 'Auto-filled on map pick',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  prefixIcon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF0056B3)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: lonCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Longitude (°E)',
                                  hintText: isTagalog ? 'Lalabas kapag pumili sa mapa' : 'Auto-filled on map pick',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  prefixIcon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF0056B3)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (gpsErrorText != null) ...[
                          const SizedBox(height: 4),
                          Text(gpsErrorText!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0056B3),
                              side: const BorderSide(color: Color(0xFF0056B3), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final currentLat = double.tryParse(latCtrl.text) ?? 14.2790;
                              final currentLon = double.tryParse(lonCtrl.text) ?? 121.4550;

                              showDialog(
                                context: context,
                                builder: (mapCtx) => StatefulBuilder(
                                  builder: (mapCtx, setMapState) {
                                    final sqM = calculatePolygonAreaSqM(boundaryPoints);
                                    final ha = calculatePolygonAreaHectares(boundaryPoints);
                                    final nf = NumberFormat('#,###');
                                    final overlappingFarm = findOverlappingFarm(boundaryPoints, service.farms);

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
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                              child: const Icon(Icons.polyline_rounded, color: Colors.white, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                isTagalog ? 'I-set ang Boundary at Sukat ng Sakahan' : 'Set Farm Land Boundary & Area',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                                              onPressed: () => Navigator.pop(mapCtx),
                                            ),
                                          ],
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: 620,
                                        height: 520,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              color: const Color(0xFFEFF6FF),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 18),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      boundaryPoints.length < 3
                                                          ? (isTagalog ? 'Mag-tap ng 3 o higit pang punto sa mapa para iguhit ang boundary.' : 'Tap 3 or more points on map to draw farm boundary.')
                                                          : (isTagalog ? '🌾 Na-mapang Sukat: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²)' : '🌾 Mapped Area: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²)'),
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: boundaryPoints.length >= 3 ? const Color(0xFF16A34A) : const Color(0xFF0369A1),
                                                      ),
                                                    ),
                                                  ),
                                                  if (boundaryPoints.isNotEmpty) ...[
                                                    TextButton.icon(
                                                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                                      onPressed: () {
                                                        setMapState(() {
                                                          boundaryPoints.removeLast();
                                                        });
                                                      },
                                                      icon: const Icon(Icons.undo_rounded, size: 16),
                                                      label: Text(isTagalog ? 'I-undo' : 'Undo'),
                                                    ),
                                                    TextButton.icon(
                                                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                                                      onPressed: () {
                                                        setMapState(() {
                                                          boundaryPoints.clear();
                                                        });
                                                      },
                                                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                                                      label: Text(isTagalog ? 'Linisin' : 'Clear'),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (overlappingFarm != null)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                color: const Color(0xFFFEF2F2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        isTagalog
                                                            ? '⚠️ SUMASAGASA SA IBA: Ang boundary na ito ay naki-overlap sa sakahan ni ${overlappingFarm.farmerName} (${overlappingFarm.barangay})!'
                                                            : '⚠️ BOUNDARY OVERLAP: This boundary overlaps with the registered farm of ${overlappingFarm.farmerName} (${overlappingFarm.barangay})!',
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Expanded(
                                              child: PagsanjanMapWidget(
                                                initialCenter: LatLng(currentLat, currentLon),
                                                initialZoom: 15,
                                                extraPolygons: [
                                                  ...service.farms.where((f) => f.boundaryPoints.length >= 3).map((f) => Polygon(
                                                    points: f.boundaryPoints,
                                                    color: Colors.red.withValues(alpha: 0.15),
                                                    borderColor: Colors.redAccent,
                                                    borderStrokeWidth: 2.0,
                                                  )),
                                                  if (boundaryPoints.length >= 3)
                                                    Polygon(
                                                      points: boundaryPoints,
                                                      color: overlappingFarm != null
                                                          ? Colors.red.withValues(alpha: 0.4)
                                                          : const Color(0xFF0284C7).withValues(alpha: 0.3),
                                                      borderColor: overlappingFarm != null ? Colors.red : const Color(0xFF0056B3),
                                                      borderStrokeWidth: 3.0,
                                                    ),
                                                ],
                                                markers: [
                                                  ...boundaryPoints.asMap().entries.map((e) => Marker(
                                                        point: e.value,
                                                        width: 24,
                                                        height: 24,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF0056B3),
                                                            shape: BoxShape.circle,
                                                            border: Border.all(color: Colors.white, width: 2),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '${e.key + 1}',
                                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                                      )),
                                                ],
                                                onTap: (point) {
                                                  setMapState(() {
                                                    boundaryPoints.add(point);
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(mapCtx),
                                          child: Text(isTagalog ? 'Kanselahin' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: overlappingFarm != null ? Colors.grey : const Color(0xFF0056B3),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          ),
                                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                                          label: Text(isTagalog ? 'I-confirm ang Boundary' : 'Confirm Farm Boundary', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: (overlappingFarm != null || boundaryPoints.length < 3)
                                              ? null
                                              : () {
                                                  final centroid = calculatePolygonCentroid(boundaryPoints);
                                                  final computedHa = calculatePolygonAreaHectares(boundaryPoints);
                                                  final detectedBrgy = BarangayResolver.resolveBarangay(centroid);

                                                  setDialogState(() {
                                                    latCtrl.text = centroid.latitude.toStringAsFixed(5);
                                                    lonCtrl.text = centroid.longitude.toStringAsFixed(5);
                                                    selectedBrgy = detectedBrgy;
                                                    if (computedHa > 0) {
                                                      landAreaCtrl.text = computedHa.toStringAsFixed(2);
                                                    }
                                                    gpsErrorText = null;
                                                    dialogErrorBanner = null;
                                                    if (addressCtrl.text.trim().isEmpty) {
                                                      addressCtrl.text = 'Brgy. $detectedBrgy, Pagsanjan';
                                                    }
                                                  });
                                                  Navigator.pop(mapCtx);
                                                },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_rounded),
                            label: Text(
                              isTagalog ? '🗺️ Pumili sa Mapa & I-set ang Boundary ng Lupa' : '🗺️ Pick Location & Set Farm Land Boundary',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM ACTION BUTTONS
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          setDialogState(() {
                            dialogErrorBanner = null;
                            nameErrorText = null;
                            userErrorText = null;
                            contactErrorText = null;
                            addressErrorText = null;
                            cropsErrorText = null;
                            gpsErrorText = null;
                          });

                          final nameVal = nameCtrl.text.trim();
                          final userVal = userCtrl.text.trim();

                          // 1. Basic empty check for Name
                          if (nameVal.isEmpty) {
                            setDialogState(() {
                              nameErrorText = isTagalog ? 'Kailangang lagyan ang Buong Pangalan!' : 'Full Personal Name is required!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ MALI SA FORM: Pakilagay ang Buong Pangalan sa pulang field!'
                                  : '⚠️ FORM ERROR: Please enter Full Personal Name in the highlighted field!';
                            });
                            scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // 2. Basic empty check for Username
                          if (userVal.isEmpty) {
                            setDialogState(() {
                              userErrorText = isTagalog ? 'Kailangang lagyan ang Username!' : 'Username is required!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ MALI SA FORM: Pakilagay ang Username sa pulang field!'
                                  : '⚠️ FORM ERROR: Please enter Username in the highlighted field!';
                            });
                            scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // 3. Validate Contact Number (OPTIONAL)
                          final contactDigits = contactCtrl.text.replaceAll(RegExp(r'\D'), '');
                          if (contactDigits.isNotEmpty && contactDigits.length != 11) {
                            setDialogState(() {
                              contactErrorText = isTagalog
                                  ? 'Kung lalagyan, kailangang saktong 11 numero (hal. 09123456789)!'
                                  : 'If provided, must be exactly 11 digits (e.g. 09123456789)!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ MALI SA CONTACT NUMBER: Kung lalagyan, kailangang saktong 11 numero (halimbawa: 09123456789)!'
                                  : '⚠️ CONTACT NUMBER ERROR: If provided, must be 11 digits (e.g. 09123456789)!';
                            });
                            scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // 4. DUPLICATE CHECK: Name
                          final existingName = service.farmers.any((f) => f.profileName.trim().toLowerCase() == nameVal.toLowerCase());
                          if (existingName) {
                            setDialogState(() {
                              nameErrorText = isTagalog
                                  ? 'May umiiral nang magsasaka na may ganitong pangalan!'
                                  : 'A farmer with this name already exists!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ HINDI MAIPAGPATULOY: May umiiral nang magsasaka na may pangalang "$nameVal"!'
                                  : '⚠️ CANNOT PROCEED: A farmer with the name "$nameVal" already exists!';
                            });
                            scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // 5. DUPLICATE CHECK: Username
                          final existingUser = service.farmers.any((f) => f.username.trim().toLowerCase() == userVal.toLowerCase());
                          if (existingUser) {
                            setDialogState(() {
                              userErrorText = isTagalog
                                  ? 'Ang username na ito ay nakarehistro na sa ibang magsasaka!'
                                  : 'Username is already taken by an existing farmer!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ HINDI MAIPAGPATULOY: Ang username na "@$userVal" ay nakarehistro na!'
                                  : '⚠️ CANNOT PROCEED: Username "@$userVal" is already taken!';
                            });
                            scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // 6. DUPLICATE CHECK: Contact Number (Only if provided)
                          if (contactDigits.isNotEmpty) {
                            final existingContact = service.farmers.any((f) =>
                                f.contactNumber.replaceAll(RegExp(r'\D'), '').isNotEmpty &&
                                f.contactNumber.replaceAll(RegExp(r'\D'), '') == contactDigits);
                            if (existingContact) {
                              setDialogState(() {
                                contactErrorText = isTagalog
                                    ? 'May umiiral nang magsasaka na may ganitong numero!'
                                    : 'A farmer with this contact number already exists!';
                                dialogErrorBanner = isTagalog
                                    ? '⚠️ HINDI MAIPAGPATULOY: May umiiral nang magsasaka na may Contact Number ($contactDigits)!'
                                    : '⚠️ CANNOT PROCEED: A farmer with this contact number ($contactDigits) already exists!';
                              });
                              scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                              return;
                            }
                          }

                          // 7. DUPLICATE CHECK: Address / Location (Exempt Hired Farmworkers)
                          final locInput = addressCtrl.text.trim().toLowerCase();
                          if (locInput.isNotEmpty && selectedTenure != 'Hired Farmworkers') {
                            final existingAddress = service.farmers.any((f) =>
                            f.barangay.toLowerCase() == selectedBrgy.toLowerCase() &&
                                service.farms.any((farm) => (farm.farmerId == f.id || farm.farmerName == f.profileName) && farm.locationName.trim().toLowerCase() == locInput));
                            if (existingAddress) {
                              setDialogState(() {
                                addressErrorText = isTagalog
                                    ? 'May rehistradong magsasaka na sa parehong address!'
                                    : 'A farmer is already registered at this same address!';
                                dialogErrorBanner = isTagalog
                                    ? '⚠️ HINDI MAIPAGPATULOY: May umiiral nang magsasaka sa parehong address ($locInput, Brgy. $selectedBrgy)!'
                                    : '⚠️ CANNOT PROCEED: A farmer is already registered at this address ($locInput, Brgy. $selectedBrgy)!';
                              });
                              scrollCtrl.animateTo(250, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                              return;
                            }
                          }

                          // 8. PRIMARY CROPS CHECK
                          if (selectedPrimaryCrops.isEmpty) {
                            setDialogState(() {
                              cropsErrorText = isTagalog
                                  ? 'Pumili ng kahit isang Primary Crop Type!'
                                  : 'Please select at least one Primary Crop Type!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ MALI SA CROPS: Pumili ng kahit isang Primary Crop Type sa mga pagpipilian sa ibaba!'
                                  : '⚠️ CROP SELECTION ERROR: Please select at least one Primary Crop Type below!';
                            });
                            scrollCtrl.animateTo(200, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // 9. GPS COORDINATES CHECK
                          if (latCtrl.text.trim().isEmpty || lonCtrl.text.trim().isEmpty) {
                            setDialogState(() {
                              gpsErrorText = isTagalog
                                  ? 'Pumili ng lokasyon sa mapa para makuha ang GPS Coordinates!'
                                  : 'Please pick a location on the map!';
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ MALI SA MAPA: Pumili ng lokasyon sa mapa para makuha ang GPS Coordinates!'
                                  : '⚠️ MAP ERROR: Please pick a location on the map to set GPS coordinates!';
                            });
                            scrollCtrl.animateTo(400, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            return;
                          }

                          // Auto-add any pending text in specificCropCtrl
                          final pendingSpecific = specificCropCtrl.text.trim();
                          if (pendingSpecific.isNotEmpty && !specificCropsList.contains(pendingSpecific)) {
                            specificCropsList.add(pendingSpecific);
                          }

                          final primaryCropsStr = selectedPrimaryCrops.join(', ');
                          final specificVarietiesStr = specificCropsList.isNotEmpty
                              ? specificCropsList.join(', ')
                              : primaryCropsStr;

                          final finalOrg = selectedOrg == 'ADD_NEW'
                              ? (customOrgCtrl.text.trim().isEmpty ? 'Not Associated' : customOrgCtrl.text.trim())
                              : (selectedOrg == 'Choose Association' ? 'Not Associated' : selectedOrg);

                          final farmerId = await service.addFarmer(
                            username: userVal,
                            password: passCtrl.text.isEmpty ? 'password123' : passCtrl.text,
                            profileName: nameVal,
                            barangay: selectedBrgy,
                            contactNumber: contactDigits.isEmpty ? 'N/A' : contactDigits,
                            organization: finalOrg,
                          );

                          final farmLocName = selectedTenure == 'Hired Farmworkers'
                              ? '${addressCtrl.text.trim().isEmpty ? "Sitio $selectedBrgy" : addressCtrl.text.trim()} (Hired Worker: $nameVal)'
                              : (addressCtrl.text.trim().isEmpty ? 'Sitio $selectedBrgy' : addressCtrl.text.trim());

                          // 1. Primary Crop Category saved in farms table in Supabase
                          await service.addFarmRecord(
                            farmerId: farmerId,
                            farmerName: nameVal,
                            locationName: farmLocName,
                            latitude: double.tryParse(latCtrl.text) ?? 14.2790,
                            longitude: double.tryParse(lonCtrl.text) ?? 121.4550,
                            landAreaHectares: double.tryParse(landAreaCtrl.text) ?? 1.0,
                            tenureStatus: selectedTenure,
                            cropType: primaryCropsStr,
                            barangay: selectedBrgy,
                            boundaryPoints: boundaryPoints,
                          );

                          // 2. Specific Crop Type & Varieties saved directly into farmer_plantings table in Supabase
                          try {
                            final plantingId = 'PL_${DateTime.now().millisecondsSinceEpoch}';
                            await SupabaseService.client.from('farmer_plantings').insert({
                              'id': plantingId,
                              'farmer_id': farmerId,
                              'farmer_name': nameVal,
                              'crop': specificVarietiesStr,
                              'hectares': double.tryParse(landAreaCtrl.text) ?? 1.0,
                              'planted_on': DateTime.now().toIso8601String(),
                              'barangay': selectedBrgy,
                            });
                          } catch (e) {
                            debugPrint('Error inserting specific crop & variety into farmer_plantings: $e');
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Matagumpay na naidagdag ang magsasaka at ang kaniyang sakahan sa Supabase!'
                                    : 'Successfully added farmer and farm record to Supabase!',
                              ),
                              backgroundColor: const Color(0xFF0056B3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(isTagalog ? 'I-save ang Magsasaka' : 'Save Farmer Record'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditFarmerDialog(BuildContext context, AccountService service, Farmer farmer) {
    final isTagalog = service.isTagalog;
    final nameCtrl = TextEditingController(text: farmer.profileName);
    final contactCtrl = TextEditingController(text: farmer.contactNumber);
    final customOrgCtrl = TextEditingController();
    String selectedBrgy = farmer.barangay;
    String selectedStatus = farmer.status;
    String? contactErrorText;

    final existingOrgs = getUniqueOrganizations(service);
    String selectedOrg = farmer.organization.trim().isEmpty || farmer.organization == 'Independent'
        ? 'Not Associated'
        : farmer.organization;

    if (selectedOrg != 'Choose Association' && selectedOrg != 'Not Associated' && !existingOrgs.contains(selectedOrg)) {
      existingOrgs.add(selectedOrg);
    }
    bool isAddingCustomOrg = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLUE HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0056B3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTagalog
                              ? 'Baguhin ang Rekord ng Magsasaka (@${farmer.username})'
                              : 'Edit Farmer Record (@${farmer.username})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION HEADER
                        Row(
                          children: [
                            const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF0056B3)),
                            const SizedBox(width: 6),
                            Text(
                              isTagalog ? 'IMPORMASYON NG MAGSASAKA' : 'FARMER PROFILE DETAILS',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Buong Pangalan' : 'Full Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedBrgy,
                                decoration: InputDecoration(
                                  labelText: 'Barangay',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                onChanged: (val) => selectedBrgy = val ?? farmer.barangay,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                decoration: InputDecoration(
                                  labelText: isTagalog ? 'Katayuan (Status)' : 'Account Status',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: ['Active', 'Pending', 'Deactivated'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => selectedStatus = val ?? farmer.status,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: contactCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Numero ng Kontak (Opsyonal)' : 'Contact Number (Optional)',
                            errorText: contactErrorText,
                            helperText: isTagalog ? 'Opsyonal: Saktong 11 numero kung lalagyan (hal. 09123456789)' : 'Optional: 11 digits if provided (e.g. 09123456789)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                          ),
                          onChanged: (val) {
                            final digitsOnly = val.replaceAll(RegExp(r'\D'), '');
                            setDialogState(() {
                              if (digitsOnly.isNotEmpty && digitsOnly.length != 11) {
                                contactErrorText = isTagalog
                                    ? 'Dapat saktong 11 numero (${digitsOnly.length}/11)'
                                    : 'Must be exactly 11 digits (${digitsOnly.length}/11)';
                              } else {
                                contactErrorText = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: (existingOrgs.contains(selectedOrg) || selectedOrg == 'Not Associated' || selectedOrg == 'Choose Association') ? selectedOrg : 'Not Associated',
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Samahan / Asosasyon' : 'Association / Organization',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.groups_rounded, size: 20),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'Choose Association',
                              child: Text(isTagalog ? 'Pumili ng Samahan (Choose Association)' : 'Choose Association', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            DropdownMenuItem(
                              value: 'Not Associated',
                              child: Text(isTagalog ? 'Walang Samahan (Not Associated)' : 'Not Associated', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            ...existingOrgs.map((org) => DropdownMenuItem(
                              value: org,
                              child: Text(org, overflow: TextOverflow.ellipsis, maxLines: 1),
                            )),
                            DropdownMenuItem(
                              value: 'ADD_NEW',
                              child: Text(
                                isTagalog ? '➕ Magdagdag ng Bagong Samahan' : '➕ Add New Association',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedOrg = val ?? 'Choose Association';
                              isAddingCustomOrg = (selectedOrg == 'ADD_NEW');
                            });
                          },
                        ),
                        if (isAddingCustomOrg) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: customOrgCtrl,
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Pangalan ng Bagong Samahan' : 'New Association Name',
                              hintText: 'e.g. Pagsanjan Organic Farmers Coop',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ACTIONS FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          isTagalog ? 'Kanselahin' : 'Cancel',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          isTagalog ? 'I-update ang Rekord' : 'Update Farmer Record',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final contactDigits = contactCtrl.text.replaceAll(RegExp(r'\D'), '');
                          if (contactDigits.isNotEmpty && contactDigits.length != 11) {
                            setDialogState(() {
                              contactErrorText = isTagalog
                                  ? 'Kung lalagyan, kailangang saktong 11 numero!'
                                  : 'If provided, must be 11 digits!';
                            });
                            return;
                          }

                          final finalOrg = selectedOrg == 'ADD_NEW'
                              ? (customOrgCtrl.text.trim().isEmpty ? 'Not Associated' : customOrgCtrl.text.trim())
                              : (selectedOrg == 'Choose Association' ? 'Not Associated' : selectedOrg);

                          service.updateFarmer(
                            farmer.id,
                            profileName: nameCtrl.text.trim(),
                            barangay: selectedBrgy,
                            contactNumber: contactDigits.isEmpty ? 'N/A' : contactDigits,
                            organization: finalOrg,
                            status: selectedStatus,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Matagumpay na na-update ang rekord ng magsasaka!'
                                    : 'Farmer record updated successfully!',
                              ),
                              backgroundColor: const Color(0xFF0056B3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFarmForFarmerDialog(BuildContext context, AccountService service, Farmer farmer) {
    final isTagalog = service.isTagalog;
    final addressCtrl = TextEditingController(); // Complete Address
    final areaCtrl = TextEditingController(); // Empty start
    final latCtrl = TextEditingController(); // Empty start
    final lonCtrl = TextEditingController(); // Empty start
    final specificCropCtrl = TextEditingController();
    final empSearchCtrl = TextEditingController();
    final List<String> specificCropsList = [];
    final List<LatLng> boundaryPoints = [];
    String selectedTenure = 'Owner';
    String selectedBrgy = farmer.barangay;
    String? dialogErrorBanner;

    final primaryCropOptions = isTagalog
        ? [
      {'key': 'Rice', 'label': '🌾 Palay (Rice)'},
      {'key': 'Gulay', 'label': '🥬 Gulay (Vegetables)'},
      {'key': 'Prutas', 'label': '🍎 Prutas (Fruits)'},
    ]
        : [
      {'key': 'Rice', 'label': '🌾 Rice'},
      {'key': 'Gulay', 'label': '🥬 Vegetables'},
      {'key': 'Prutas', 'label': '🍎 Fruits'},
    ];

    final Set<String> selectedPrimaryCrops = <String>{}; // Empty start

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLUE HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0056B3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTagalog
                              ? 'Magdagdag ng Sakahan para kay ${farmer.profileName}'
                              : 'Add Farm Record for ${farmer.profileName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogErrorBanner != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dialogErrorBanner!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF991B1B)),
                                  onPressed: () {
                                    setDialogState(() {
                                      dialogErrorBanner = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // COMPLETE ADDRESS FIELD
                        TextField(
                          controller: addressCtrl,
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Kumpletong Address / Lokasyon ng Sakahan' : 'Complete Address / Farm Location',
                            hintText: isTagalog ? 'hal. House #12, Sitio Layugan, Brgy. Biñan, Pagsanjan' : 'e.g. House #12, Sitio Layugan, Brgy. Biñan, Pagsanjan',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.home_work_rounded, color: Color(0xFF0056B3)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedBrgy,
                                decoration: InputDecoration(
                                  labelText: 'Barangay',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                onChanged: (val) => selectedBrgy = val ?? farmer.barangay,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: areaCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: isTagalog ? 'Laki ng Lupa (hektarya)' : 'Land Area (ha)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTenure,
                          decoration: InputDecoration(
                            labelText: isTagalog ? 'Katayuan sa Lupa' : 'Land Tenure Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: ['Owner', 'Tenant', 'Lease', 'CLT', 'Hired Farmworkers'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedTenure = val ?? 'Owner';
                            });
                          },
                        ),
                        if (selectedTenure == 'Hired Farmworkers') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: empSearchCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Maghanap ng Employer (Pangalan o Barangay)' : 'Search Employer (Name or Barangay)',
                              hintText: isTagalog ? 'I-type ang pangalan ng employer...' : 'Type employer name...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFEFF6FF),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                              suffixIcon: empSearchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setDialogState(() {
                                          empSearchCtrl.clear();
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isTagalog ? 'Pumili ng Employer (Owner/Tenant/Lease/CLT)' : 'Select Employer (Owner/Tenant/Lease/CLT)',
                              hintText: isTagalog ? 'Sino ang may-ari/tenant/nagpaupa?' : 'Who hired this farmworker?',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFEFF6FF),
                              prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0284C7)),
                            ),
                            items: service.farmers
                                .where((f) {
                                  if (f.profileName.trim().isEmpty) return false;
                                  final q = empSearchCtrl.text.trim().toLowerCase();
                                  final matchesQuery = q.isEmpty ||
                                      f.profileName.toLowerCase().contains(q) ||
                                      f.username.toLowerCase().contains(q) ||
                                      f.barangay.toLowerCase().contains(q);
                                  if (!matchesQuery) return false;

                                  final fFarm = service.farms.firstWhere(
                                    (farm) => farm.farmerId == f.id || farm.farmerName == f.profileName,
                                    orElse: () => FarmRecord(
                                      id: '',
                                      farmerId: f.id,
                                      farmerName: f.profileName,
                                      locationName: 'Sitio ${f.barangay}',
                                      latitude: 14.2790,
                                      longitude: 121.4550,
                                      landAreaHectares: 2.0,
                                      tenureStatus: 'Owner',
                                      cropType: 'Rice',
                                      barangay: f.barangay,
                                    ),
                                  );
                                  final tenure = fFarm.tenureStatus.toLowerCase();
                                  return tenure == 'owner' || tenure == 'tenant' || tenure == 'lease' || tenure == 'clt' || tenure.contains('owner') || tenure.contains('tenant') || tenure.contains('lease');
                                })
                                .map((f) {
                                  final fFarm = service.farms.firstWhere(
                                    (farm) => farm.farmerId == f.id || farm.farmerName == f.profileName,
                                    orElse: () => FarmRecord(
                                      id: '',
                                      farmerId: f.id,
                                      farmerName: f.profileName,
                                      locationName: 'Sitio ${f.barangay}',
                                      latitude: 14.2790,
                                      longitude: 121.4550,
                                      landAreaHectares: 2.0,
                                      tenureStatus: 'Owner',
                                      cropType: 'Rice',
                                      barangay: f.barangay,
                                    ),
                                  );
                                  return DropdownMenuItem(
                                    value: f.id,
                                    child: Text(
                                      '${f.profileName} (${fFarm.tenureStatus} · ${f.barangay})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: (empId) {
                              if (empId != null) {
                                setDialogState(() {
                                  final empFarmer = service.farmers.firstWhere((f) => f.id == empId, orElse: () => service.farmers.first);
                                  final empFarm = service.farms.firstWhere(
                                    (farm) => farm.farmerId == empId || farm.farmerName == empFarmer.profileName,
                                    orElse: () => FarmRecord(
                                      id: 'AUTO_FARM',
                                      farmerId: empFarmer.id,
                                      farmerName: empFarmer.profileName,
                                      locationName: 'Sitio ${empFarmer.barangay}',
                                      latitude: 14.2790,
                                      longitude: 121.4550,
                                      landAreaHectares: 2.0,
                                      tenureStatus: 'Owner',
                                      cropType: 'Rice',
                                      barangay: empFarmer.barangay,
                                    ),
                                  );

                                  areaCtrl.text = empFarm.landAreaHectares.toStringAsFixed(1);
                                  selectedBrgy = empFarm.barangay;
                                  addressCtrl.text = empFarm.locationName.trim().isNotEmpty
                                      ? empFarm.locationName
                                      : 'House #${empFarmer.id.substring(math.max(0, empFarmer.id.length - 3))}, Brgy. ${empFarm.barangay}, Pagsanjan';
                                  latCtrl.text = empFarm.latitude.toStringAsFixed(5);
                                  lonCtrl.text = empFarm.longitude.toStringAsFixed(5);
                                });
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 14),

                        // MULTI-SELECT PRIMARY CROP TYPES
                        Text(
                          isTagalog
                              ? 'Mga Pangunahing Tanim (Pumili ng isa o higit pa):'
                              : 'Primary Crop Types (Select all that apply):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: primaryCropOptions.map((cropOpt) {
                            final key = cropOpt['key']!;
                            final label = cropOpt['label']!;
                            final isSelected = selectedPrimaryCrops.contains(key);
                            return FilterChip(
                              selected: isSelected,
                              label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selectedColor: const Color(0xFFDBEAFE),
                              checkmarkColor: const Color(0xFF1E40AF),
                              labelStyle: TextStyle(color: isSelected ? const Color(0xFF1E40AF) : Colors.black87),
                              side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
                              onSelected: (bool selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedPrimaryCrops.add(key);
                                  } else {
                                    selectedPrimaryCrops.remove(key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // SPECIFIC CROP VARIETIES INPUT
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTagalog
                                  ? 'TIYAK NA URI O VARIETY NG TANIM (SPECIFIC TYPES)'
                                  : 'SPECIFIC CROP TYPES & VARIETIES (OPTIONAL)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: specificCropCtrl,
                                    decoration: InputDecoration(
                                      labelText: isTagalog
                                          ? 'I-type ang tanim (hal. Mangga, Saging, Talong)'
                                          : 'Type specific crop (e.g. Mango, Banana, Eggplant)',
                                      hintText: isTagalog ? 'I-type at i-press (+)' : 'Type and press (+)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onSubmitted: (val) {
                                      final trimmed = val.trim();
                                      if (trimmed.isNotEmpty && !specificCropsList.contains(trimmed)) {
                                        setDialogState(() {
                                          specificCropsList.add(trimmed);
                                          specificCropCtrl.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
                                  onPressed: () {
                                    final trimmed = specificCropCtrl.text.trim();
                                    if (trimmed.isNotEmpty && !specificCropsList.contains(trimmed)) {
                                      setDialogState(() {
                                        specificCropsList.add(trimmed);
                                        specificCropCtrl.clear();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                                ),
                              ],
                            ),
                            if (specificCropsList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: specificCropsList.map((item) {
                                  return Chip(
                                    avatar: const Icon(Icons.eco_rounded, size: 14, color: Color(0xFF1E40AF)),
                                    label: Text(
                                      item,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                                    ),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    deleteIcon: const Icon(Icons.cancel, size: 16, color: Color(0xFF1E40AF)),
                                    onDeleted: () {
                                      setDialogState(() {
                                        specificCropsList.remove(item);
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),

                        const Divider(height: 28, thickness: 1.2),

                        // READ-ONLY GPS COORDINATES + MAP PICKER
                        Text(
                          isTagalog ? 'GPS KOORDINADA NG SAKAHAN (MULA SA MAPA)' : 'FARM GPS COORDINATES (FROM MAP)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Latitude (°N)',
                                  hintText: isTagalog ? 'Lalabas sa mapa' : 'Auto-filled on map pick',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  prefixIcon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF0056B3)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: lonCtrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Longitude (°E)',
                                  hintText: isTagalog ? 'Lalabas sa mapa' : 'Auto-filled on map pick',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  prefixIcon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF0056B3)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0056B3),
                              side: const BorderSide(color: Color(0xFF0056B3), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final currentLat = double.tryParse(latCtrl.text) ?? 14.2790;
                              final currentLon = double.tryParse(lonCtrl.text) ?? 121.4550;

                              showDialog(
                                context: context,
                                builder: (mapCtx) => StatefulBuilder(
                                  builder: (mapCtx, setMapState) {
                                    final sqM = calculatePolygonAreaSqM(boundaryPoints);
                                    final ha = calculatePolygonAreaHectares(boundaryPoints);
                                    final nf = NumberFormat('#,###');
                                    final overlappingFarm = findOverlappingFarm(boundaryPoints, service.farms);

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
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                              child: const Icon(Icons.polyline_rounded, color: Colors.white, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                isTagalog ? 'I-set ang Boundary at Sukat ng Sakahan' : 'Set Farm Land Boundary & Area',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                                              onPressed: () => Navigator.pop(mapCtx),
                                            ),
                                          ],
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: 620,
                                        height: 520,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              color: const Color(0xFFEFF6FF),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 18),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      boundaryPoints.length < 3
                                                          ? (isTagalog ? 'Mag-tap ng 3 o higit pang punto sa mapa para iguhit ang boundary.' : 'Tap 3 or more points on map to draw farm boundary.')
                                                          : (isTagalog ? '🌾 Na-mapang Sukat: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²)' : '🌾 Mapped Area: ${ha.toStringAsFixed(2)} ha (${nf.format(sqM.round())} m²)'),
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: boundaryPoints.length >= 3 ? const Color(0xFF16A34A) : const Color(0xFF0369A1),
                                                      ),
                                                    ),
                                                  ),
                                                  if (boundaryPoints.isNotEmpty) ...[
                                                    TextButton.icon(
                                                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                                      onPressed: () {
                                                        setMapState(() {
                                                          boundaryPoints.removeLast();
                                                        });
                                                      },
                                                      icon: const Icon(Icons.undo_rounded, size: 16),
                                                      label: Text(isTagalog ? 'I-undo' : 'Undo'),
                                                    ),
                                                    TextButton.icon(
                                                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                                                      onPressed: () {
                                                        setMapState(() {
                                                          boundaryPoints.clear();
                                                        });
                                                      },
                                                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                                                      label: Text(isTagalog ? 'Linisin' : 'Clear'),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (overlappingFarm != null)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                color: const Color(0xFFFEF2F2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        isTagalog
                                                            ? '⚠️ SUMASAGASA SA IBA: Ang boundary na ito ay naki-overlap sa sakahan ni ${overlappingFarm.farmerName} (${overlappingFarm.barangay})!'
                                                            : '⚠️ BOUNDARY OVERLAP: This boundary overlaps with the registered farm of ${overlappingFarm.farmerName} (${overlappingFarm.barangay})!',
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Expanded(
                                              child: PagsanjanMapWidget(
                                                initialCenter: LatLng(currentLat, currentLon),
                                                initialZoom: 15,
                                                extraPolygons: [
                                                  ...service.farms.where((f) => f.boundaryPoints.length >= 3).map((f) => Polygon(
                                                    points: f.boundaryPoints,
                                                    color: Colors.red.withValues(alpha: 0.15),
                                                    borderColor: Colors.redAccent,
                                                    borderStrokeWidth: 2.0,
                                                  )),
                                                  if (boundaryPoints.length >= 3)
                                                    Polygon(
                                                      points: boundaryPoints,
                                                      color: overlappingFarm != null
                                                          ? Colors.red.withValues(alpha: 0.4)
                                                          : const Color(0xFF0284C7).withValues(alpha: 0.3),
                                                      borderColor: overlappingFarm != null ? Colors.red : const Color(0xFF0056B3),
                                                      borderStrokeWidth: 3.0,
                                                    ),
                                                ],
                                                markers: [
                                                  ...boundaryPoints.asMap().entries.map((e) => Marker(
                                                        point: e.value,
                                                        width: 24,
                                                        height: 24,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF0056B3),
                                                            shape: BoxShape.circle,
                                                            border: Border.all(color: Colors.white, width: 2),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '${e.key + 1}',
                                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                                      )),
                                                ],
                                                onTap: (point) {
                                                  setMapState(() {
                                                    boundaryPoints.add(point);
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(mapCtx),
                                          child: Text(isTagalog ? 'Kanselahin' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: overlappingFarm != null ? Colors.grey : const Color(0xFF0056B3),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          ),
                                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                                          label: Text(isTagalog ? 'I-confirm ang Boundary' : 'Confirm Farm Boundary', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          onPressed: (overlappingFarm != null || boundaryPoints.length < 3)
                                              ? null
                                              : () {
                                                  final centroid = calculatePolygonCentroid(boundaryPoints);
                                                  final computedHa = calculatePolygonAreaHectares(boundaryPoints);
                                                  final detectedBrgy = BarangayResolver.resolveBarangay(centroid);

                                                  setDialogState(() {
                                                    latCtrl.text = centroid.latitude.toStringAsFixed(5);
                                                    lonCtrl.text = centroid.longitude.toStringAsFixed(5);
                                                    selectedBrgy = detectedBrgy;
                                                    if (computedHa > 0) {
                                                      areaCtrl.text = computedHa.toStringAsFixed(2);
                                                    }
                                                    if (addressCtrl.text.trim().isEmpty) {
                                                      addressCtrl.text = 'Brgy. $detectedBrgy, Pagsanjan';
                                                    }
                                                  });
                                                  Navigator.pop(mapCtx);
                                                },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_rounded),
                            label: Text(
                              isTagalog ? '🗺️ Pumili sa Mapa & I-set ang Boundary ng Lupa' : '🗺️ Pick Location & Set Farm Land Boundary',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM ACTION BUTTONS
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            dialogErrorBanner = null;
                          });

                          if (selectedPrimaryCrops.isEmpty) {
                            setDialogState(() {
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ Pumili ng kahit isang Primary Crop Type!'
                                  : '⚠️ Please select at least one Primary Crop Type!';
                            });
                            return;
                          }

                          if (latCtrl.text.trim().isEmpty || lonCtrl.text.trim().isEmpty) {
                            setDialogState(() {
                              dialogErrorBanner = isTagalog
                                  ? '⚠️ Pumili ng lokasyon sa mapa para makuha ang GPS Coordinates!'
                                  : '⚠️ Please pick a location on the map to set GPS coordinates!';
                            });
                            return;
                          }

                          final pendingSpecific = specificCropCtrl.text.trim();
                          if (pendingSpecific.isNotEmpty && !specificCropsList.contains(pendingSpecific)) {
                            specificCropsList.add(pendingSpecific);
                          }

                          final primaryCropsStr = selectedPrimaryCrops.join(', ');
                          final finalCropType = specificCropsList.isNotEmpty
                              ? '$primaryCropsStr (${specificCropsList.join(', ')})'
                              : primaryCropsStr;

                          service.addFarmRecord(
                            farmerId: farmer.id,
                            farmerName: farmer.profileName,
                            locationName: addressCtrl.text.trim().isEmpty ? 'Sitio $selectedBrgy' : addressCtrl.text.trim(),
                            latitude: double.tryParse(latCtrl.text) ?? 14.2717,
                            longitude: double.tryParse(lonCtrl.text) ?? 121.4553,
                            landAreaHectares: double.tryParse(areaCtrl.text) ?? 1.0,
                            tenureStatus: selectedTenure,
                            cropType: finalCropType,
                            barangay: selectedBrgy,
                            boundaryPoints: boundaryPoints,
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(isTagalog ? 'I-save ang Sakahan' : 'Save Farm Record'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteFarmer(BuildContext context, AccountService service, Farmer farmer, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locale.isTagalog ? 'Kumpirmahin ang Pagbura' : 'Confirm Account Deletion',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.isTagalog
                  ? 'Sigurado ka bang gusto mong burahin ang account ni ${farmer.profileName}?'
                  : 'Are you sure you want to permanently delete ${farmer.profileName}\'s farmer account?',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.isTagalog
                          ? 'Babala: Hindi na maibabalik ang account na ito at mabubura rin ang lahat ng kaniyang mga rekord sa Supabase.'
                          : 'Warning: This action cannot be undone. All profile data and associated farm records will be permanently removed from Supabase.',
                      style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteFarmer(farmer.id);
              await service.loadFromSupabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permanently deleted account for ${farmer.profileName}'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(locale.isTagalog ? 'Oo, Burahin Na' : 'Permanently Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFarmRecord(BuildContext context, AccountService service, FarmRecord farm, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locale.isTagalog ? 'Kumpirmahin ang Pagbura' : 'Confirm Farm Deletion',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          locale.isTagalog
              ? 'Sigurado ka bang gusto mong burahin ang sakahan na ${farm.locationName} (${farm.barangay})?'
              : 'Are you sure you want to permanently delete the farm record for ${farm.locationName} in ${farm.barangay}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteFarmRecord(farm.id);
              await service.loadFromSupabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted farm record for ${farm.locationName}'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(locale.isTagalog ? 'Oo, Burahin Na' : 'Permanently Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHistoricalRecord(BuildContext context, AccountService service, HistoricalDataRecord record, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locale.isTagalog ? 'Kumpirmahin ang Pagbura' : 'Confirm Record Deletion',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          locale.isTagalog
              ? 'Sigurado ka bang gusto mong burahin ang historical record para sa ${record.crop} (${record.month} ${record.year})?'
              : 'Are you sure you want to delete the historical record for ${record.crop} (${record.month} ${record.year})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              service.deleteHistoricalRecord(record.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted record for ${record.crop}'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(locale.isTagalog ? 'Oo, Burahin Na' : 'Permanently Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAdminStaff(BuildContext context, AccountService service, AdminStaff staff, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locale.isTagalog ? 'Kumpirmahin ang Pagbura' : 'Confirm Staff Access Removal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          locale.isTagalog
              ? 'Sigurado ka bang gusto mong alisin ang access ni ${staff.name} (${staff.role})?'
              : 'Are you sure you want to remove admin access for ${staff.name} (${staff.role})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              service.deleteAdminStaff(staff.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed admin access for ${staff.name}'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(locale.isTagalog ? 'Oo, Alisin Na' : 'Permanently Remove Access'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 3: HISTORICAL DATA
  // ==========================================
  Widget _buildHistoricalDataView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      ) {
    final records = service.historicalRecords;
    final marketPrices = service.marketPriceRecords;

    final totalRecords = records.length;
    final totalPages1 = (totalRecords / _pageSize).ceil();
    final safePage1 = totalPages1 > 0 ? math.min(_table1Page, totalPages1 - 1) : 0;
    final start1 = safePage1 * _pageSize;
    final end1 = math.min(start1 + _pageSize, totalRecords);
    final paginatedRecords = totalRecords > 0 ? records.sublist(start1, end1) : <HistoricalDataRecord>[];

    final totalMarketPrices = marketPrices.length;
    final totalPages2 = (totalMarketPrices / _pageSize).ceil();
    final safePage2 = totalPages2 > 0 ? math.min(_table2Page, totalPages2 - 1) : 0;
    final start2 = safePage2 * _pageSize;
    final end2 = math.min(start2 + _pageSize, totalMarketPrices);
    final paginatedMarketPrices = totalMarketPrices > 0 ? marketPrices.sublist(start2, end2) : <MarketPriceRecord>[];

    return SingleChildScrollView(
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
                  Text('MAO DATASET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.historicalTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Historical Data', locale, service, showImport: false, allowPdf: false),
                  if (_historicalTableIndex == 0)
                    ElevatedButton.icon(
                      onPressed: () => _showUploadCsvDialog(context, service),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_rounded),
                      label: Text(locale.uploadMaoRecord, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _showAddMarketPriceDialog(context, service),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_rounded),
                      label: Text(locale.isTagalog ? 'Magdagdag ng Presyo' : 'Add Market Price', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TABLE SELECTION TOGGLE (2 TABLES)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(locale.isTagalog ? '1. Rekord ng Produksyon at Presyo (MAO)' : '1. Production & Price Dataset'),
                  icon: const Icon(Icons.table_chart_rounded),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(locale.isTagalog ? '2. Presyo sa Palengke at Bukid (Gulay)' : '2. Vegetable Market & Farmgate Prices'),
                  icon: const Icon(Icons.storefront_rounded),
                ),
              ],
              selected: {_historicalTableIndex},
              onSelectionChanged: (set) => setState(() => _historicalTableIndex = set.first),
            ),
          ),
          const SizedBox(height: 16),

          // TABLE 1: PRODUCTION & PRICE DATASET
          if (_historicalTableIndex == 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132338) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Color(0xFF0284C7), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        locale.isTagalog ? '💡 Prediksyon ng Presyo at Market Trends (Price Forecasting)' : '💡 Price Prediction & Market Trend Analytics',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildPredictionChip('Rice', service, isDark, textColor, subtextColor),
                      _buildPredictionChip('Gulay', service, isDark, textColor, subtextColor),
                      _buildPredictionChip('Prutas', service, isDark, textColor, subtextColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Scrollbar(
                      controller: _histTable1ScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _histTable1ScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Crop', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Year', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Month', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Barangay', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Production (KG)', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Uploaded By', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text('Actions', style: TextStyle(color: subtextColor))),
                          ],
                          rows: paginatedRecords.map((r) {
                            final prodKg = r.productionMT >= 100 ? r.productionMT : (r.productionMT * 1000);
                            final nf = NumberFormat('#,###');
                            return DataRow(
                              cells: [
                                DataCell(Text(r.crop, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                                DataCell(Text('${r.year}', style: TextStyle(color: textColor))),
                                DataCell(Text(r.month, style: TextStyle(color: textColor))),
                                DataCell(Text(r.barangay, style: TextStyle(color: textColor))),
                                DataCell(Text('${nf.format(prodKg.round())} kg', style: TextStyle(color: textColor))),
                                DataCell(Text(r.uploadedBy, style: TextStyle(color: textColor))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _confirmDeleteHistoricalRecord(context, service, r, locale),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  _buildPaginationBar(
                    currentPage: safePage1,
                    totalItems: totalRecords,
                    pageSize: _pageSize,
                    onPageChanged: (newPage) => setState(() => _table1Page = newPage),
                    isDark: isDark,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    primaryAccent: primaryAccent,
                  ),
                ],
              ),
            ),
          ] else ...[
            // TABLE 2: VEGETABLE MARKET & FARMGATE PRICES WITH DATES
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Scrollbar(
                      controller: _histTable2ScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _histTable2ScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(locale.isTagalog ? 'Gulay / Pananim' : 'Vegetable / Crop', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Presyo sa Bukid (Farmgate)' : 'Farmgate Price (₱/kg)', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Presyo sa Palengke (Market)' : 'Market Price (₱/kg)', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Tubo / Spread' : 'Spread', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Petsa' : 'Date', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Lokasyon ng Palengke' : 'Market Location', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Nag-upload' : 'Uploaded By', style: TextStyle(color: subtextColor))),
                            DataColumn(label: Text(locale.isTagalog ? 'Aksyon' : 'Actions', style: TextStyle(color: subtextColor))),
                          ],
                          rows: paginatedMarketPrices.map((m) {
                            final spread = m.marketPrice - m.farmgatePrice;
                            final spreadPct = m.farmgatePrice > 0 ? (spread / m.farmgatePrice) * 100 : 0.0;
                            return DataRow(
                              cells: [
                                DataCell(Text(m.vegetable, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                                DataCell(Text('₱${m.farmgatePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF16A34A)))),
                                DataCell(Text('₱${m.marketPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0284C7)))),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text('+₱${spread.toStringAsFixed(2)} (${spreadPct.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                                )),
                                DataCell(Text(DateFormat('MMM dd, yyyy').format(m.date), style: TextStyle(color: textColor))),
                                DataCell(Text(m.marketLocation, style: TextStyle(color: textColor))),
                                DataCell(Text(m.uploadedBy, style: TextStyle(color: textColor))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _confirmDeleteMarketPriceRecord(context, service, m, locale),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  _buildPaginationBar(
                    currentPage: safePage2,
                    totalItems: totalMarketPrices,
                    pageSize: _pageSize,
                    onPageChanged: (newPage) => setState(() => _table2Page = newPage),
                    isDark: isDark,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    primaryAccent: primaryAccent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalItems,
    required int pageSize,
    required ValueChanged<int> onPageChanged,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required Color primaryAccent,
  }) {
    if (totalItems <= 0) return const SizedBox.shrink();

    final totalPages = (totalItems / pageSize).ceil();
    final startItem = (currentPage * pageSize) + 1;
    final endItem = math.min((currentPage + 1) * pageSize, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132338) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startItem-$endItem of $totalItems items',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtextColor),
          ),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                tooltip: 'Previous Page',
              ),
              ...List.generate(totalPages, (index) {
                if (totalPages > 7) {
                  if (index != 0 && index != totalPages - 1 && (index < currentPage - 1 || index > currentPage + 1)) {
                    if (index == currentPage - 2 || index == currentPage + 2) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text('...', style: TextStyle(color: subtextColor, fontSize: 12)),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }

                final isSelected = index == currentPage;
                return InkWell(
                  onTap: () => onPageChanged(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? null : Border.all(color: subtextColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUploadProductionCsvDialog(BuildContext context, AccountService service) {
    final csvContentCtrl = TextEditingController(
      text: 'crop,year,month,barangay,production_kg,uploader_farmer\n'
            'Rice,2026,June,Biñan,480000,Juan Dela Cruz\n'
            'Talong (Eggplant),2026,June,Anibong,150000,Maria Santos\n'
            'Kamatis (Tomato),2026,June,Buboy,120000,Pedro Reyes\n'
            'Sitaw (Yardlong Bean),2026,June,Calusiche,95000,Ana Ramos\n'
            'Ampalaya (Bitter Gourd),2026,June,Dingin,85000,Juan Dela Cruz\n'
            'Saging (Banana),2026,June,Lambac,210000,Maria Santos',
    );
    final fileNameCtrl = TextEditingController();
    String selectedUploader = service.farmers.isNotEmpty ? service.farmers.first.profileName : service.activeUserName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.table_chart_rounded, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 12),
              Text(
                service.isTagalog ? 'Import Rekord ng Produksyon (CSV)' : 'Import Production Dataset (CSV)',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
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
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Text(
                              'CSV Layout / Structure Format:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Columns: crop, year, month, barangay, production_kg, uploader_farmer\n'
                          'Example:\n'
                          'Rice, 2026, June, Biñan, 480000, Juan Dela Cruz',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // DOWNLOAD CSV TEMPLATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        const templateCsv = 'crop,year,month,barangay,production_kg,uploader_farmer\n'
                            'Rice,2026,June,Biñan,480000,Juan Dela Cruz\n'
                            'Talong (Eggplant),2026,June,Anibong,150000,Maria Santos\n'
                            'Kamatis (Tomato),2026,June,Buboy,120000,Pedro Reyes\n'
                            'Sitaw (Yardlong Bean),2026,June,Calusiche,95000,Ana Ramos\n'
                            'Ampalaya (Bitter Gourd),2026,June,Dingin,85000,Juan Dela Cruz\n'
                            'Saging (Banana),2026,June,Lambac,210000,Maria Santos\n';
                        const targetFileName = 'pagsanjan_production_dataset_template.csv';

                        try {
                          String userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
                          String downloadsPath = '$userProfile\\Downloads\\$targetFileName';
                          final file = File(downloadsPath);
                          await file.writeAsString(templateCsv);

                          setDialogState(() {
                            fileNameCtrl.text = downloadsPath;
                            csvContentCtrl.text = templateCsv;
                          });

                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  service.isTagalog
                                      ? 'Matagumpay na na-save ang blank template sa Downloads folder: $targetFileName'
                                      : 'Saved blank template to Downloads folder: $targetFileName',
                                ),
                                backgroundColor: const Color(0xFF0284C7),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            csvContentCtrl.text = templateCsv;
                          });
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        service.isTagalog ? '📄 Kumuha ng Blank CSV Template (Download Template)' : '📄 Download Blank Production Dataset CSV Template',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // BROWSE FILE EXPLORER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final pickedPath = await _pickFileWithSystemExplorer();
                        if (pickedPath != null && pickedPath.isNotEmpty) {
                          final file = File(pickedPath);
                          if (await file.exists()) {
                            final content = await _readFileSafely(file);
                            setDialogState(() {
                              fileNameCtrl.text = pickedPath;
                              csvContentCtrl.text = content;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(
                        service.isTagalog ? '📁 Pumili ng .CSV File sa File Explorer (Browse)' : '📁 Choose .CSV File in File Explorer (Browse)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    service.isTagalog ? 'Default na Magsasaka / Uploader User' : 'Default Farmer / Uploader User',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUploader,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    items: [
                      DropdownMenuItem(value: service.activeUserName, child: Text('${service.activeUserName} (Staff)')),
                      ...service.farmers.map((f) => DropdownMenuItem(value: f.profileName, child: Text('${f.profileName} (${f.barangay})'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedUploader = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  Text(
                    service.isTagalog ? 'Dataset Preview / CSV Content Text:' : 'Dataset Preview / CSV Content Text:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: csvContentCtrl,
                    maxLines: 8,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                      hintText: 'Paste CSV rows here...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(service.isTagalog ? 'Kanselahin' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(service.isTagalog ? 'I-import ang CSV' : 'Process & Import CSV', style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final text = csvContentCtrl.text.trim();
                if (text.isEmpty) return;

                final lines = text.split('\n');
                int successCount = 0;

                for (var line in lines) {
                  final trimmed = line.trim();
                  if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('crop')) continue;

                  final parts = trimmed.split(',');
                  if (parts.isNotEmpty) {
                    final crop = parts[0].trim();
                    if (crop.isEmpty) continue;

                    final yr = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 2026 : 2026;
                    final m = parts.length > 2 ? parts[2].trim() : 'June';
                    final brgy = parts.length > 3 ? parts[3].trim() : 'ALL';
                    final prodKg = parts.length > 4 ? double.tryParse(parts[4].trim()) ?? 0.0 : 0.0;
                    final uploader = parts.length > 5 && parts[5].trim().isNotEmpty ? parts[5].trim() : selectedUploader;

                    service.addHistoricalRecord(
                      crop: crop,
                      year: yr,
                      month: m,
                      barangay: brgy,
                      productionMT: prodKg >= 1000 ? (prodKg / 1000) : prodKg,
                      pricePerKg: 0.0,
                      uploadedBy: uploader,
                    );
                    successCount++;
                  }
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      service.isTagalog
                          ? 'Matagumpay na na-import ang $successCount na rekord ng produksyon!'
                          : 'Successfully imported $successCount production records!',
                    ),
                    backgroundColor: const Color(0xFF0284C7),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadMarketPriceCsvDialog(BuildContext context, AccountService service) {
    final csvContentCtrl = TextEditingController(
      text: 'vegetable,farmgate_price,market_price,date,market_location\n'
            'Ampalaya (Bitter Gourd),60.00,90.00,2026-06-15,Pagsanjan Public Market\n'
            'Talong (Eggplant),45.00,70.00,2026-06-15,Pagsanjan Public Market\n'
            'Kamatis (Tomato),50.00,85.00,2026-06-15,Pagsanjan Public Market\n'
            'Sitaw (Yardlong Bean),45.00,75.00,2026-06-15,Pagsanjan Public Market\n'
            'Saging (Saba),35.00,55.00,2026-06-15,Pagsanjan Public Market',
    );
    final defaultLocationCtrl = TextEditingController(text: 'Pagsanjan Public Market');
    final fileNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0056B3).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.file_upload_rounded, color: Color(0xFF0056B3)),
              ),
              const SizedBox(width: 12),
              Text(
                service.isTagalog ? 'Import Presyo sa Palengke at Bukid (CSV)' : 'Import Market & Farmgate Prices (CSV)',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
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
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Text(
                              'CSV Layout / Structure Format:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Columns: vegetable, farmgate_price, market_price, date (YYYY-MM-DD), market_location\n'
                          'Example:\n'
                          'Talong (Eggplant), 45.00, 70.00, 2026-06-15, Pagsanjan Public Market',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // DOWNLOAD CSV TEMPLATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        const templateCsv = 'vegetable,farmgate_price,market_price,date,market_location\n'
                            'Ampalaya (Bitter Gourd),60.00,90.00,2026-06-15,Pagsanjan Public Market\n'
                            'Talong (Eggplant),45.00,70.00,2026-06-15,Pagsanjan Public Market\n'
                            'Kamatis (Tomato),50.00,85.00,2026-06-15,Pagsanjan Public Market\n'
                            'Sitaw (Yardlong Bean),45.00,75.00,2026-06-15,Pagsanjan Public Market\n'
                            'Saging (Saba),35.00,55.00,2026-06-15,Pagsanjan Public Market\n'
                            'Okra,35.00,55.00,2026-06-15,Pagsanjan Public Market\n'
                            'Pechay (Tagalog),40.00,65.00,2026-06-15,Pagsanjan Public Market\n';
                        const targetFileName = 'pagsanjan_market_farmgate_prices_template.csv';

                        try {
                          String userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
                          String downloadsPath = '$userProfile\\Downloads\\$targetFileName';
                          final file = File(downloadsPath);
                          await file.writeAsString(templateCsv);

                          setDialogState(() {
                            fileNameCtrl.text = downloadsPath;
                            csvContentCtrl.text = templateCsv;
                          });

                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  service.isTagalog
                                      ? 'Matagumpay na na-save ang blank template sa Downloads folder: $targetFileName'
                                      : 'Saved blank template to Downloads folder: $targetFileName',
                                ),
                                backgroundColor: const Color(0xFF0284C7),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            csvContentCtrl.text = templateCsv;
                          });
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        service.isTagalog ? '📄 Kumuha ng Blank CSV Template (Download Template)' : '📄 Download Blank Market Prices CSV Template',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // BROWSE FILE EXPLORER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final pickedPath = await _pickFileWithSystemExplorer();
                        if (pickedPath != null && pickedPath.isNotEmpty) {
                          final file = File(pickedPath);
                          if (await file.exists()) {
                            final content = await _readFileSafely(file);
                            setDialogState(() {
                              fileNameCtrl.text = pickedPath;
                              csvContentCtrl.text = content;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(
                        service.isTagalog ? '📁 Pumili ng .CSV File sa File Explorer (Browse)' : '📁 Choose .CSV File in File Explorer (Browse)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    service.isTagalog ? 'Default na Lokasyon ng Palengke' : 'Default Market Location',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: defaultLocationCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    service.isTagalog ? 'Dataset Preview / CSV Content Text:' : 'Dataset Preview / CSV Content Text:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: csvContentCtrl,
                    maxLines: 7,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                      hintText: 'Paste CSV rows here...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(service.isTagalog ? 'Kanselahin' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056B3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(service.isTagalog ? 'I-import ang CSV' : 'Process & Import CSV', style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final text = csvContentCtrl.text.trim();
                if (text.isEmpty) return;

                final lines = text.split('\n');
                int successCount = 0;
                final defaultLoc = defaultLocationCtrl.text.trim().isEmpty ? 'Pagsanjan Public Market' : defaultLocationCtrl.text.trim();

                for (var line in lines) {
                  final trimmed = line.trim();
                  if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('vegetable')) continue;

                  final parts = trimmed.split(',');
                  if (parts.isNotEmpty) {
                    final veg = parts[0].trim();
                    if (veg.isEmpty) continue;

                    final fg = parts.length > 1 ? double.tryParse(parts[1].trim()) ?? 0.0 : 0.0;
                    final mp = parts.length > 2 ? double.tryParse(parts[2].trim()) ?? (fg * 1.4) : (fg * 1.4);
                    DateTime parsedDate = DateTime.now();
                    if (parts.length > 3) {
                      final dStr = parts[3].trim();
                      try {
                        parsedDate = DateTime.parse(dStr);
                      } catch (_) {}
                    }
                    final loc = parts.length > 4 && parts[4].trim().isNotEmpty ? parts[4].trim() : defaultLoc;

                    service.addMarketPriceRecord(
                      vegetable: veg,
                      farmgatePrice: fg,
                      marketPrice: mp,
                      date: parsedDate,
                      marketLocation: loc,
                      uploadedBy: service.activeUserName,
                    );
                    successCount++;
                  }
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      service.isTagalog
                          ? 'Matagumpay na na-import ang $successCount na rekord ng presyo!'
                          : 'Successfully imported $successCount vegetable market price records!',
                    ),
                    backgroundColor: const Color(0xFF0056B3),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMarketPriceDialog(BuildContext context, AccountService service) {
    final vegCtrl = TextEditingController(text: 'Talong (Eggplant)');
    final farmgateCtrl = TextEditingController(text: '45.00');
    final marketCtrl = TextEditingController(text: '70.00');
    final locationCtrl = TextEditingController(text: 'Pagsanjan Public Market');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLUE HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0056B3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          service.isTagalog ? 'Magdagdag ng Presyo sa Palengke & Bukid' : 'Add Market & Farmgate Price Record',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: vegCtrl,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Pangalan ng Gulay' : 'Vegetable Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: farmgateCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: service.isTagalog ? 'Presyo sa Bukid (₱/kg)' : 'Farmgate Price (₱/kg)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: marketCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: service.isTagalog ? 'Presyo sa Palengke (₱/kg)' : 'Market Price (₱/kg)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: locationCtrl,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Lokasyon ng Palengke' : 'Market Location',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(service.isTagalog ? 'Petsa ng Obserbasyon: ' : 'Observation Date: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0056B3),
                                side: const BorderSide(color: Color(0xFF0056B3)),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ACTIONS FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          service.isTagalog ? 'Kanselahin' : 'Cancel',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          service.isTagalog ? 'I-save ang Presyo' : 'Save Price Record',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final veg = vegCtrl.text.trim();
                          final fg = double.tryParse(farmgateCtrl.text) ?? 0.0;
                          final mp = double.tryParse(marketCtrl.text) ?? 0.0;
                          if (veg.isNotEmpty) {
                            service.addMarketPriceRecord(
                              vegetable: veg,
                              farmgatePrice: fg,
                              marketPrice: mp,
                              date: selectedDate,
                              marketLocation: locationCtrl.text.trim().isEmpty ? 'Pagsanjan Public Market' : locationCtrl.text.trim(),
                              uploadedBy: service.activeUserName,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(service.isTagalog ? 'Matagumpay na naidagdag ang presyo!' : 'Market price record added successfully!'),
                                backgroundColor: const Color(0xFF0056B3),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMarketPriceRecord(BuildContext context, AccountService service, MarketPriceRecord record, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.isTagalog ? 'Burahin ang Presyo?' : 'Delete Market Price Record?'),
        content: Text(locale.isTagalog ? 'Sigurado ka bang gusto mong burahin ang rekord para sa ${record.vegetable}?' : 'Are you sure you want to delete the record for ${record.vegetable}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              service.deleteMarketPriceRecord(record.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.isTagalog ? 'Nabura na ang rekord' : 'Record deleted')));
            },
            child: Text(locale.isTagalog ? 'Burahin' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionChip(String cropCategory, AccountService service, bool isDark, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cropCategory == 'Rice' ? Icons.grass_rounded : cropCategory == 'Prutas' ? Icons.park_rounded : Icons.eco_rounded,
            size: 18,
            color: const Color(0xFF0284C7),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cropCategory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
              Text('Inaasahang Presyo: Stable (+3.2%)', style: TextStyle(fontSize: 11, color: subtextColor)),
            ],
          ),
        ],
      ),
    );
  }

  void _showUploadCsvDialog(BuildContext context, AccountService service) {
    final cropCtrl = TextEditingController(text: 'Rice');
    final yearCtrl = TextEditingController(text: '2026');
    final monthCtrl = TextEditingController(text: 'February');
    String selectedBrgy = 'ALL';
    final prodCtrl = TextEditingController(text: '500000');
    String selectedUploader = service.farmers.isNotEmpty ? service.farmers.first.profileName : service.activeUserName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLUE HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0056B3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_chart_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          service.isTagalog ? 'Magdagdag ng Rekord ng Produksyon' : 'Add Production Record',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Validated input format for data cleaning:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: cropCtrl,
                          decoration: InputDecoration(
                            labelText: 'Crop Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: yearCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Year',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: monthCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Month',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedBrgy,
                          decoration: InputDecoration(
                            labelText: 'Barangay',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: ['ALL', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setDialogState(() => selectedBrgy = val ?? 'ALL'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: prodCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Produksyon (Kilograms / KG)' : 'Production (Kilograms / KG)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: selectedUploader,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Magsasaka / Uploader User' : 'Farmer / Uploader User',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(value: service.activeUserName, child: Text('${service.activeUserName} (Staff)')),
                            ...service.farmers.map((f) => DropdownMenuItem(value: f.profileName, child: Text('${f.profileName} (${f.barangay})'))),
                          ],
                          onChanged: (val) => setDialogState(() => selectedUploader = val ?? service.activeUserName),
                        ),
                      ],
                    ),
                  ),
                ),

                // ACTIONS FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          service.isTagalog ? 'Kanselahin' : 'Cancel',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          service.isTagalog ? 'I-save ang Rekord' : 'Save Record',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final inputVal = double.tryParse(prodCtrl.text) ?? 500000.0;
                          service.addHistoricalRecord(
                            crop: cropCtrl.text,
                            year: int.tryParse(yearCtrl.text) ?? 2026,
                            month: monthCtrl.text,
                            barangay: selectedBrgy,
                            productionMT: inputVal >= 1000 ? (inputVal / 1000) : inputVal,
                            pricePerKg: 0.0,
                            uploadedBy: selectedUploader,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(service.isTagalog ? 'Na-save na ang rekord ng produksyon!' : 'Production record saved!'),
                              backgroundColor: const Color(0xFF0056B3),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MODULE 4: INTERACTIVE MAP
  // ==========================================
  Widget _buildInteractiveMapView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      ) {
    final List<FarmRecord> displayedFarms = [];
    final mapMarkers = <Marker>[];
    final Map<String, int> barangayPinCounts = {};

    for (int index = 0; index < service.farmers.length; index++) {
      final farmer = service.farmers[index];
      final normBrgy = AccountService.normalizeBarangay(farmer.barangay);
      final matchesBarangay = _selectedBarangayFilter == 'All' ||
          normBrgy.toLowerCase() == AccountService.normalizeBarangay(_selectedBarangayFilter).toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          farmer.profileName.toLowerCase().contains(query) ||
          farmer.username.toLowerCase().contains(query) ||
          normBrgy.toLowerCase().contains(query);

      if (!matchesBarangay || !matchesQuery) continue;

      final pinNumInBrgy = barangayPinCounts[normBrgy] ?? 0;
      barangayPinCounts[normBrgy] = pinNumInBrgy + 1;

      final center = _getBarangayCenter(normBrgy, service.farms);
      double angle = pinNumInBrgy * (2 * math.pi / 6);
      double radius = pinNumInBrgy == 0 ? 0.0 : (0.0022 + (pinNumInBrgy ~/ 6) * 0.0015);

      final pinLat = center.latitude + (radius * math.cos(angle));
      final pinLng = center.longitude + (radius * math.sin(angle));

      FarmRecord originalFarm = service.farms.firstWhere(
            (f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName,
        orElse: () => FarmRecord(
          id: 'FARM_AUTO_${farmer.id}',
          farmerId: farmer.id,
          farmerName: farmer.profileName,
          locationName: 'Sitio $normBrgy',
          latitude: pinLat,
          longitude: pinLng,
          landAreaHectares: 2.0,
          tenureStatus: 'Owner',
          cropType: 'Rice',
          barangay: normBrgy,
        ),
      );

      final distinctFarm = FarmRecord(
        id: originalFarm.id,
        farmerId: farmer.id,
        farmerName: farmer.profileName,
        locationName: originalFarm.locationName,
        latitude: pinLat,
        longitude: pinLng,
        landAreaHectares: originalFarm.landAreaHectares,
        tenureStatus: originalFarm.tenureStatus,
        cropType: originalFarm.cropType,
        barangay: normBrgy,
      );

      displayedFarms.add(distinctFarm);

      if (_showRegisteredPins) {
        mapMarkers.add(_buildBlueFarmMarker(distinctFarm, () {
          _showFarmWeatherModal(context, distinctFarm, locale, cardBg, textColor);
        }));
      }
    }

    final farmBoundaryPolygons = <Polygon>[];
    for (final farm in service.farms) {
      if (farm.boundaryPoints.length >= 3) {
        final cropLower = farm.cropType.toLowerCase();
        Color polyColor;
        Color borderColor;

        if (cropLower.contains('rice') || cropLower.contains('palay')) {
          polyColor = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
          borderColor = const Color(0xFF1E3A8A);
        } else if (cropLower.contains('gulay') || cropLower.contains('veg')) {
          polyColor = const Color(0xFF0284C7).withValues(alpha: 0.35);
          borderColor = const Color(0xFF0284C7);
        } else if (cropLower.contains('prutas') || cropLower.contains('fruit')) {
          polyColor = const Color(0xFF2563EB).withValues(alpha: 0.35);
          borderColor = const Color(0xFF2563EB);
        } else {
          polyColor = const Color(0xFF0056B3).withValues(alpha: 0.35);
          borderColor = const Color(0xFF0056B3);
        }

        farmBoundaryPolygons.add(
          Polygon(
            points: farm.boundaryPoints,
            color: polyColor,
            borderColor: borderColor,
            borderStrokeWidth: 3.0,
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
                  Text(locale.mapTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
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
                  // MAIN MAP DISPLAY WITH BLUE SHADE MARKERS & AUTO-ZOOM TO BARANGAY
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: PagsanjanMapWidget(
                        initialCenter: _mapCenter,
                        initialZoom: _mapZoom,
                        markers: mapMarkers,
                        extraPolygons: farmBoundaryPolygons,
                      ),
                    ),
                  ),

                  // FULL SCREEN BUTTON
                  Positioned(
                    right: 16,
                    top: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PagsanjanMapScreen(
                            markers: mapMarkers,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.fullscreen),
                      label: const Text('Full Screen'),
                    ),
                  ),

                  // FLOATING SEARCH/FILTER BUTTON WHEN PANEL IS HIDDEN
                  if (!_showMapSidePanel)
                    Positioned(
                      left: 20,
                      top: 20,
                      child: FloatingActionButton.extended(
                        heroTag: 'show_map_panel_btn',
                        backgroundColor: const Color(0xFF0056B3),
                        foregroundColor: Colors.white,
                        onPressed: () => setState(() => _showMapSidePanel = true),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(locale.isTagalog ? 'Maghanap at I-filter' : 'Search & Filter'),
                      ),
                    ),

                  // SIDE OVERLAY PANEL FOR FARMERS & MAP FILTERS
                  if (_showMapSidePanel)
                    Positioned(
                      left: 20,
                      top: 20,
                      bottom: 20,
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
                                    locale.registeredPins,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0056B3)),
                                  tooltip: locale.isTagalog ? 'I-hide ang Panel' : 'Hide Panel',
                                  onPressed: () => setState(() => _showMapSidePanel = false),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  locale.isTagalog ? 'Ipakita ang Pin' : 'Show Pins',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subtextColor),
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
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(color: textColor, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: locale.isTagalog ? 'Maghanap ng sakahan...' : 'Search farm or farmer...',
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

                            // BARANGAY DROPDOWN FILTER WITH AUTO-ZOOM TO SELECTED BARANGAY
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBarangayFilter,
                              dropdownColor: cardBg,
                              style: TextStyle(color: textColor, fontSize: 12),
                              decoration: InputDecoration(
                                labelText: locale.isTagalog ? 'Filter Barangay (Auto-Zoom)' : 'Filter Barangay (Auto-Zoom)',
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
                                    _mapCenter = _getBarangayCenter(brgy, service.farms);
                                    _mapZoom = 15.8; // Auto zoom in directly to the barangay!
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),

                            // FARMER LIST ITEMS
                            Expanded(
                              child: displayedFarms.isEmpty
                                  ? Center(
                                child: Text(
                                  locale.isTagalog ? 'Walang sakahang nahanap' : 'No farms found',
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
                                        // Auto zoom map to the selected farmer's farm area
                                        setState(() {
                                          _mapCenter = LatLng(farm.latitude, farm.longitude);
                                          _mapZoom = 16.0;
                                        });
                                        _showFarmWeatherModal(context, farm, locale, cardBg, textColor);
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

  void _showFarmWeatherModal(
      BuildContext context,
      FarmRecord farm,
      AdminLocale locale,
      Color cardBg,
      Color textColor,
      ) {
    final isTagalog = locale.isTagalog;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        backgroundColor: cardBg,
        content: SizedBox(
          width: 580,
          height: 640,
          child: Column(
            children: [
              // BLUE HEADER BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0056B3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.farmerName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            '${farm.locationName}, Brgy. ${farm.barangay}, Pagsanjan',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FARM DETAILS CARD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF0056B3), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isTagalog ? 'IMPORMASYON NG SAKAHAN' : 'FARM LAND DETAILS',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _infoRow(Icons.eco_rounded, isTagalog ? 'Mga Tanim' : 'Crop Types', farm.cropType),
                            const SizedBox(height: 8),
                            _infoRow(Icons.square_foot_rounded, isTagalog ? 'Laki ng Lupa' : 'Land Size', '${farm.landAreaHectares} Ha (${(farm.landAreaHectares * 10000).round()} m²)'),
                            const SizedBox(height: 8),
                            _infoRow(Icons.badge_rounded, isTagalog ? 'Katayuan sa Lupa' : 'Tenure Status', farm.tenureStatus),
                            const SizedBox(height: 8),
                            _infoRow(Icons.my_location_rounded, isTagalog ? 'GPS Coordinates' : 'GPS Coordinates', '${farm.latitude.toStringAsFixed(5)}° N, ${farm.longitude.toStringAsFixed(5)}° E'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // DEDICATED MINI-MAP PREVIEW OF FARM AREA
                      Text(
                        isTagalog ? '🗺️ MAPA NG AREA NG SAKAHAN' : '🗺️ FARM AREA LOCATION MAP',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: PagsanjanMapWidget(
                            initialCenter: LatLng(farm.latitude, farm.longitude),
                            initialZoom: 16.0,
                            markers: [
                              _buildBlueFarmMarker(farm, () {}),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // REAL-TIME WEATHER & AGRIBUSINESS ADVISORY
                      Text(
                        isTagalog ? '🌾 ULAT NG PANAHON SA SAKAHAN' : '🌾 FARM REAL-TIME WEATHER & ADVISORY',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isTagalog
                                            ? 'Kasalukuyang Panahon sa Brgy. ${farm.barangay}'
                                            : 'Current Farm Weather at Brgy. ${farm.barangay}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                                      ),
                                      const Text(
                                        '29°C • Humidity: 76% • Wind: 12 km/h',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFF93C5FD)),
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isTagalog
                                        ? 'Payo sa Sakahan: Maganda ang panahon ngayong araw para sa pagpapataba at patubig sa pananim na ${farm.cropType}.'
                                        : 'Agri Advisory: Ideal weather conditions today for fertilizing and irrigating ${farm.cropType} crops.',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  // ==========================================
  // MODULE 5: FARMER ACCOUNTS
  // ==========================================
  Widget _buildFarmerAccountsView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      ) {
    final farmers = service.farmers.where((f) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          f.profileName.toLowerCase().contains(query) ||
          f.username.toLowerCase().contains(query) ||
          f.organization.toLowerCase().contains(query);
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay.trim().toLowerCase() == _selectedBarangayFilter.trim().toLowerCase();
      final matchesAssoc = _selectedAssociationFilter == 'All' || f.organization.trim().toLowerCase() == _selectedAssociationFilter.trim().toLowerCase();
      return matchesQuery && matchesBarangay && matchesAssoc;
    }).toList();

    farmers.sort((a, b) {
      int comparison = 0;
      switch (_farmerSortField) {
        case 'Barangay':
          comparison = a.barangay.compareTo(b.barangay);
          break;
        case 'Status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'Organization':
          comparison = a.organization.compareTo(b.organization);
          break;
        case 'Username':
          comparison = a.username.compareTo(b.username);
          break;
        case 'Name':
        default:
          comparison = a.profileName.toLowerCase().compareTo(b.profileName.toLowerCase());
          break;
      }
      return _farmerSortAscending ? comparison : -comparison;
    });

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
                  Text('ACCOUNTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.accountsTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Farmer Accounts', locale, service, showImport: true),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFarmerDialog(context, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(locale.addFarmer, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: locale.searchFarmerPlaceholder,
                    hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 135,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBarangayFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    labelStyle: TextStyle(color: subtextColor, fontSize: 11.5),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedAssociationFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: locale.isTagalog ? 'Samahan' : 'Association',
                    labelStyle: TextStyle(color: subtextColor, fontSize: 11.5),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: ['All', 'Not Associated', ...getUniqueOrganizations(service)]
                      .map((org) => DropdownMenuItem(value: org, child: Text(org, overflow: TextOverflow.ellipsis, maxLines: 1)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedAssociationFilter = val ?? 'All'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 135,
                child: DropdownButtonFormField<String>(
                  initialValue: _farmerSortField,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 12.5),
                  decoration: InputDecoration(
                    labelText: locale.isTagalog ? 'I-sort ayon sa' : 'Sort By',
                    labelStyle: TextStyle(color: subtextColor, fontSize: 11.5),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Name', child: Text(locale.isTagalog ? 'Pangalan' : 'Name')),
                    DropdownMenuItem(value: 'Barangay', child: Text(locale.isTagalog ? 'Barangay' : 'Barangay')),
                    DropdownMenuItem(value: 'Status', child: Text(locale.isTagalog ? 'Status' : 'Status')),
                    DropdownMenuItem(value: 'Organization', child: Text(locale.isTagalog ? 'Samahan' : 'Organization')),
                    DropdownMenuItem(value: 'Username', child: Text(locale.isTagalog ? 'Username' : 'Username')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _farmerSortField = val);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: _farmerSortAscending
                    ? (locale.isTagalog ? 'Pataas (A to Z)' : 'Sort Ascending (A to Z)')
                    : (locale.isTagalog ? 'Pababang (Z to A)' : 'Sort Descending (Z to A)'),
                child: InkWell(
                  onTap: () => setState(() => _farmerSortAscending = !_farmerSortAscending),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Icon(
                      _farmerSortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: primaryAccent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: farmers.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final farmer = farmers[index];
                  final isPending = farmer.status == 'Pending';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPending ? Colors.orange.withValues(alpha: 0.2) : primaryAccent.withValues(alpha: 0.15),
                      foregroundColor: isPending ? Colors.orange : primaryAccent,
                      child: Icon(isPending ? Icons.pending_actions_rounded : Icons.person_rounded),
                    ),
                    title: Text('${farmer.profileName} (@${farmer.username})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Status: ${farmer.status} • Barangay: ${farmer.barangay}', style: TextStyle(color: subtextColor)),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (isPending)
                          ElevatedButton(
                            onPressed: () => service.setFarmerStatus(farmer.id, 'Active'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                          tooltip: 'Edit Farmer',
                          onPressed: () => _showEditFarmerDialog(context, service, farmer),
                        ),
                        OutlinedButton(
                          onPressed: () => _showResetPasswordDialog(context, service, farmer),
                          child: const Text('Reset Pass'),
                        ),
                        IconButton(
                          icon: Icon(farmer.status == 'Deactivated' ? Icons.check_circle_rounded : Icons.block_rounded, color: farmer.status == 'Deactivated' ? Colors.green : Colors.orange),
                          tooltip: farmer.status == 'Deactivated' ? 'Activate Account' : 'Deactivate Account',
                          onPressed: () => service.setFarmerStatus(farmer.id, farmer.status == 'Deactivated' ? 'Active' : 'Deactivated'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                          tooltip: 'Delete Farmer Account',
                          onPressed: () => _confirmDeleteFarmer(context, service, farmer, locale),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AccountService service, Farmer farmer) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for ${farmer.profileName}'),
        content: TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'New Password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text.isNotEmpty) {
                service.resetFarmerPassword(farmer.id, passCtrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully!')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 6: ADMIN ACCOUNTS
  // ==========================================
  Widget _buildAdminAccountsView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      ) {
    final staff = service.adminStaffList;

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
                  Text('MAO STAFF ACCESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.adminStaffTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStaffDialog(context, service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: Text(locale.addStaff, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: staff.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final s = staff[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      foregroundColor: primaryAccent,
                      child: const Icon(Icons.badge_rounded),
                    ),
                    title: Text('${s.name} (${s.role})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Username: ${s.username} • Email: ${s.email}', style: TextStyle(color: subtextColor)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteAdminStaff(context, service, s, locale),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, AccountService service) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'admin123');
    String selectedRole = 'Agricultural Technician';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: const Color(0xFFF8FAFC),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLUE HEADER BANNER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0056B3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          service.isTagalog ? 'Magdagdag ng MAO Staff Account' : 'Add MAO Staff Account',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // SCROLLABLE FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION HEADER
                        Row(
                          children: [
                            const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF0056B3)),
                            const SizedBox(width: 6),
                            Text(
                              service.isTagalog ? 'IMPORMASYON NG STAFF' : 'STAFF ACCOUNT INFORMATION',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Buong Pangalan ng Staff' : 'Staff Full Name',
                            hintText: 'e.g. Juan Dela Cruz',
                            prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: userCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'e.g. juandela',
                                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: passCtrl,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
                                    onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: emailCtrl,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Email Address' : 'Email Address',
                            hintText: 'e.g. jdelacruz@pagsanjan.gov.ph',
                            prefixIcon: const Icon(Icons.email_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: InputDecoration(
                            labelText: service.isTagalog ? 'Posisyon / Role' : 'Role / Position',
                            prefixIcon: const Icon(Icons.work_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: ['Municipal Agriculturist', 'Administrative Staff', 'Agricultural Technician'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) => setDialogState(() => selectedRole = val ?? 'Agricultural Technician'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ACTIONS FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          service.isTagalog ? 'Kanselahin' : 'Cancel',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          service.isTagalog ? 'I-save ang Staff' : 'Save Staff Account',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) {
                            service.addAdminStaff(
                              name: nameCtrl.text,
                              username: userCtrl.text,
                              email: emailCtrl.text.isEmpty ? '${userCtrl.text}@pagsanjan.gov.ph' : emailCtrl.text,
                              role: selectedRole,
                              password: passCtrl.text.isEmpty ? 'admin123' : passCtrl.text,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(service.isTagalog ? 'Naidagdag na ang bagong MAO Staff!' : 'MAO staff account added successfully!'),
                                backgroundColor: const Color(0xFF0056B3),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODULE 7: ACTIVITY LOG
  // ==========================================
  Widget _buildActivityLogView(
      AccountService service,
      AdminLocale locale,
      bool isDark,
      Color cardBg,
      Color textColor,
      Color subtextColor,
      Color cardBorder,
      Color primaryAccent,
      ) {
    final logs = service.activityLogs;

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
                  Text('AUDIT TRAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.activityLogTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildExportImportButtons(context, 'Activity Log Audit', locale, service),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  Color actionColor;
                  switch (log.action) {
                    case 'ADD':
                    case 'UPLOAD':
                      actionColor = const Color(0xFF0284C7);
                      break;
                    case 'EDIT':
                    case 'POST':
                      actionColor = const Color(0xFF0056B3);
                      break;
                    case 'DELETE':
                      actionColor = Colors.redAccent;
                      break;
                    case 'RETRAIN':
                      actionColor = const Color(0xFF4F46E5);
                      break;
                    case 'SWITCH':
                      actionColor = Colors.orange;
                      break;
                    default:
                      actionColor = Colors.grey;
                  }

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(log.action, style: TextStyle(fontWeight: FontWeight.bold, color: actionColor, fontSize: 11)),
                    ),
                    title: Text(log.details, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    subtitle: Text('By: ${log.user} • Module: ${log.module}', style: TextStyle(color: subtextColor)),
                    trailing: Text(DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp), style: TextStyle(fontSize: 11, color: subtextColor)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DIALOG FOR ANNOUNCEMENT POSTS
  void _showCreatePostDialog(BuildContext context, AccountService service, AdminLocale locale) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedCategory = 'General Advisory';
    bool isScheduled = false;
    DateTime scheduleDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay scheduleTime = const TimeOfDay(hour: 9, minute: 0);

    // Optional Event Start Date Calendar Picker
    bool hasEventDate = false;
    DateTime eventDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay eventTime = const TimeOfDay(hour: 8, minute: 30);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Color(0xFF0056B3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(locale.isTagalog ? 'Gumawa ng Opisyal na Anunsyo' : 'Create Official Announcement'),
              ),
              IconButton(
                icon: const Icon(Icons.article_rounded, color: Color(0xFF0056B3)),
                tooltip: locale.isTagalog ? 'Tingnan ang Lahat ng Post' : 'View All Posts',
                onPressed: () {
                  Navigator.pop(context);
                  _showManagePostsDialog(context, service, locale);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: locale.isTagalog ? 'Kategorya ng Anunsyo' : 'Announcement Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'General Advisory', child: Text(locale.isTagalog ? 'Pangkalahatang Payo (General Advisory)' : 'General Advisory')),
                    DropdownMenuItem(value: 'Weather Advisory', child: Text(locale.isTagalog ? 'Ulat ng Panahon at Bagyo (Weather)' : 'Weather Advisory')),
                    DropdownMenuItem(value: 'Market Price Update', child: Text(locale.isTagalog ? 'Balita sa Presyo sa Pamilihan (Market Price)' : 'Market Price Update')),
                    DropdownMenuItem(value: 'Farmers Meeting & Training', child: Text(locale.isTagalog ? 'Pulong o Pagsasanay ng Magsasaka (Meeting/Training)' : 'Farmers Meeting & Training')),
                    DropdownMenuItem(value: 'Subsidy & Distribution', child: Text(locale.isTagalog ? 'Distribusyon ng Binhi / Abono (Subsidy)' : 'Subsidy & Fertilizer Distribution')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedCategory = val ?? 'General Advisory'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: locale.isTagalog ? 'Pamagat ng Anunsyo' : 'Announcement Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: locale.isTagalog ? 'Detalyadong Nilalaman ng Mensahe' : 'Detailed Content / Message',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // OPTIONAL EVENT START DATE & TIME CALENDAR
                Row(
                  children: [
                    Checkbox(
                      value: hasEventDate,
                      onChanged: (val) => setDialogState(() => hasEventDate = val ?? false),
                    ),
                    Expanded(
                      child: Text(
                        locale.isTagalog
                            ? 'May Petsa/Oras ng Simula ng Event o Pulong (Opsyonal Calendar)'
                            : 'Set Event Start Date & Time (Optional Calendar)',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (hasEventDate) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: eventDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setDialogState(() => eventDate = pickedDate);
                              }
                            },
                            icon: const Icon(Icons.event_rounded, size: 16, color: Color(0xFF0284C7)),
                            label: Text(DateFormat('MMM dd, yyyy').format(eventDate), style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: eventTime,
                              );
                              if (pickedTime != null) {
                                setDialogState(() => eventTime = pickedTime);
                              }
                            },
                            icon: const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF0284C7)),
                            label: Text(eventTime.format(context), style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // SCHEDULE POST PUBLICATION FOR LATER
                Row(
                  children: [
                    Checkbox(
                      value: isScheduled,
                      onChanged: (val) => setDialogState(() => isScheduled = val ?? false),
                    ),
                    Text(
                      locale.isTagalog ? 'I-iskedyul ang Pag-publish (Schedule Post)' : 'Schedule Post Publication for Later',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
                if (isScheduled) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: scheduleDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setDialogState(() => scheduleDate = pickedDate);
                            }
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(DateFormat('MMM dd, yyyy').format(scheduleDate)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: scheduleTime,
                            );
                            if (pickedTime != null) {
                              setDialogState(() => scheduleTime = pickedTime);
                            }
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(scheduleTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                  final scheduleStr = isScheduled
                      ? '${DateFormat('MMM dd, yyyy').format(scheduleDate)} ${scheduleTime.format(context)}'
                      : 'Immediate';
                  final eventStr = hasEventDate
                      ? '${DateFormat('MMM dd, yyyy').format(eventDate)} ${eventTime.format(context)}'
                      : '';
                  service.addPost(
                    titleCtrl.text,
                    contentCtrl.text,
                    category: selectedCategory,
                    scheduleTime: scheduleStr,
                    eventDate: eventStr,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isScheduled
                            ? (locale.isTagalog ? 'Naka-iskedyul na ang anunsyo!' : 'Announcement scheduled successfully!')
                            : (locale.isTagalog ? 'Naipost na ang anunsyo sa lahat ng magsasaka!' : 'Announcement posted successfully to all farmers!'),
                      ),
                      backgroundColor: const Color(0xFF0056B3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(locale.isTagalog ? 'I-broadcast (Post)' : 'Broadcast Post'),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG TO VIEW AND DELETE ANNOUNCEMENT POSTS
  void _showManagePostsDialog(BuildContext context, AccountService service, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final posts = service.posts;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Color(0xFF0056B3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale.isTagalog ? 'Mga Naipost na Anunsyo (${posts.length})' : 'Office Announcements & Posts (${posts.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 550,
              height: 450,
              child: posts.isEmpty
                  ? Center(
                      child: Text(
                        locale.isTagalog ? 'Walang pang naipost na anunsyo.' : 'No announcements posted yet.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: posts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = posts[index];
                        final title = p['title'] ?? 'No Title';
                        final content = p['content'] ?? '';
                        final category = p['category'] ?? 'General Advisory';
                        final date = p['date'] ?? '';
                        final eventDate = p['eventDate'] ?? '';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0056B3).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    date,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: locale.isTagalog ? 'Burahin ang Post' : 'Delete Post',
                                    onPressed: () {
                                      _confirmDeletePost(context, service, p, locale, () {
                                        setDialogState(() {});
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (eventDate.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${locale.isTagalog ? "Simula ng Event: " : "Event Start: "}$eventDate',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(locale.isTagalog ? 'Isara' : 'Close'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreatePostDialog(context, service, locale);
                },
                icon: const Icon(Icons.add_comment_rounded, size: 16),
                label: Text(locale.isTagalog ? 'Gumawa ng Bagong Post' : 'Create New Post'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, AccountService service, Map<String, String> post, AdminLocale locale, VoidCallback onDeleted) {
    final title = post['title'] ?? '';
    final idOrTitle = post['id']?.isNotEmpty == true ? post['id']! : title;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locale.isTagalog ? 'Burahin ang Anunsyo?' : 'Delete Announcement?'),
          content: Text(
            locale.isTagalog
                ? 'Sigurado ka bang gusto mong burahin ang anunsyo na "$title"?'
                : 'Are you sure you want to delete the announcement "$title"?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () {
                service.deletePost(idOrTitle);
                Navigator.pop(context);
                onDeleted();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(locale.isTagalog ? 'Nabura na ang anunsyo.' : 'Announcement deleted successfully.')),
                );
              },
              child: Text(locale.isTagalog ? 'Burahin' : 'Delete'),
            ),
          ],
        ),
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