import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../core/crop_data.dart';
import '../models/farmer.dart';
import 'supabase_service.dart';

class AccountService extends ChangeNotifier {
  AccountService() {
    loadFromSupabase();
  }

  Future<void> loadFromSupabase({bool silent = false}) async {
    try {
      final farmersRes = await SupabaseService.client.from('farmers').select();
      if (farmersRes.isNotEmpty) {
        _farmers.clear();
        for (var row in farmersRes) {
          _farmers.add(Farmer(
            id: row['id'] ?? '',
            username: row['username'] ?? '',
            password: row['password'] ?? '',
            profileName: row['profile_name'] ?? '',
            barangay: row['barangay'] ?? 'Biñan',
            contactNumber: row['contact_number'] ?? '',
            organization: row['organization'] ?? '',
            status: row['status'] ?? 'Active',
            records: row['records'] != null ? List<String>.from(row['records']) : [],
          ));
        }
      }

      final farmsRes = await SupabaseService.client.from('farms').select();
      if (farmsRes.isNotEmpty) {
        _farms.clear();
        for (var row in farmsRes) {
          _farms.add(FarmRecord(
            id: row['id'] ?? '',
            farmerId: row['farmer_id'] ?? '',
            farmerName: row['farmer_name'] ?? '',
            locationName: row['location_name'] ?? '',
            latitude: (row['latitude'] as num?)?.toDouble() ?? 14.27,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 121.45,
            landAreaHectares: (row['land_area_hectares'] as num?)?.toDouble() ?? 1.0,
            tenureStatus: row['tenure_status'] ?? 'Owner',
            cropType: row['crop_type'] ?? 'Rice',
            barangay: row['barangay'] ?? 'Biñan',
          ));
        }
      }

      final histRes = await SupabaseService.client.from('historical_records').select();
      if (histRes.isNotEmpty) {
        _historicalRecords.clear();
        for (var row in histRes) {
          _historicalRecords.add(HistoricalDataRecord(
            id: row['id'] ?? '',
            crop: row['crop'] ?? '',
            year: row['year'] ?? 2026,
            month: row['month'] ?? 'January',
            productionMT: (row['production_mt'] as num?)?.toDouble() ?? 0.0,
            pricePerKg: (row['price_per_kg'] as num?)?.toDouble() ?? 0.0,
            uploadedBy: row['uploaded_by'] ?? 'Admin',
            dateUploaded: row['date_uploaded'] != null ? DateTime.parse(row['date_uploaded']) : DateTime.now(),
          ));
        }
      }

      final postsRes = await SupabaseService.client.from('announcements').select();
      if (postsRes.isNotEmpty) {
        _posts.clear();
        for (var row in postsRes) {
          _posts.add({
            'title': row['title'] ?? '',
            'content': row['content'] ?? '',
            'date': row['date'] ?? '',
          });
        }
      }

      notifyListeners();
    } catch (e) {
      if (!silent) debugPrint('Supabase load error (using local default data): $e');
    }
  }

  // Pagsanjan Barangays
  static const List<String> pagsanjanBarangays = [
    'Anibong',
    'Biñan',
    'Buboy',
    'Cabanbanan',
    'Calusiche',
    'Dingin',
    'Lambac',
    'Layug',
    'Magdapio',
    'Maulawin',
    'Poblacion Uno',
    'Poblacion Dos',
    'Sampaloc',
    'San Isidro',
    'Sabang',
  ];

  // 1. FARMERS
  final List<Farmer> _farmers = [
    Farmer(id: 'F001', username: 'juan', password: 'password123', profileName: 'Juan Dela Cruz', barangay: 'Biñan', contactNumber: '09123456789', organization: 'Samahang Magsasaka', status: 'Active', records: ['Harvest Q1: 1,200kg', 'Fertilizer Subsidy Received']),
    Farmer(id: 'F002', username: 'maria', password: 'password123', profileName: 'Maria Santos', barangay: 'Lambac', contactNumber: '09198765432', organization: 'Pagsanjan Farmers Coop', status: 'Active', records: ['Harvest Q1: 950kg']),
    Farmer(id: 'F003', username: 'pedro', password: 'password123', profileName: 'Pedro Reyes', barangay: 'Buboy', contactNumber: '09181112233', organization: 'Upland Growers', status: 'Active', records: ['Seed distribution registered']),
    Farmer(id: 'F004', username: 'ana', password: 'password123', profileName: 'Ana Gonzales', barangay: 'Sabang', contactNumber: '09175554433', organization: 'Vegetable Growers Assoc', status: 'Active', records: ['Organic Farming Training']),
    Farmer(id: 'FP001', username: 'pending_carlos', password: 'password123', profileName: 'Carlos Pendon', barangay: 'Alipit', contactNumber: '09179998877', organization: 'Upland Farmers', status: 'Pending', records: ['New Account Request']),
    Farmer(id: 'FP002', username: 'pending_elena', password: 'password123', profileName: 'Elena Alcantara', barangay: 'Dingin', contactNumber: '09187776655', organization: 'Rural Workers', status: 'Pending', records: ['New Account Request']),
  ];

  // 2. FARM RECORDS
  final List<FarmRecord> _farms = [];

  // 3. HISTORICAL DATA (Production & Price)
  final List<HistoricalDataRecord> _historicalRecords = [];

  // 4. MARKET PRICE RECORDS (Tab 2: Vegetable Market & Farmgate Prices)
  final List<MarketPriceRecord> _marketPriceRecords = [
    MarketPriceRecord(
      id: 'MP001',
      vegetable: 'Talong (Eggplant)',
      farmgatePrice: 45.00,
      marketPrice: 70.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Dr. Roberto Mendoza',
    ),
    MarketPriceRecord(
      id: 'MP002',
      vegetable: 'Kamatis (Tomato)',
      farmgatePrice: 50.00,
      marketPrice: 85.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Dr. Roberto Mendoza',
    ),
    MarketPriceRecord(
      id: 'MP003',
      vegetable: 'Ampalaya',
      farmgatePrice: 60.00,
      marketPrice: 90.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Engr. Arnel Cruz',
    ),
  ];

  // 5. CROP PLANTING REQUIREMENTS
  final List<CropPlantingReq> _cropRequirements = [
    CropPlantingReq(
      id: 'CPR001',
      cropName: 'Palay (Rice)',
      cropCategory: 'Rice',
      minTemp: 22.0,
      maxTemp: 32.0,
      minRainfallMm: 150.0,
      maxRainfallMm: 300.0,
      suitableMonths: 'June - November (Wet Season), Dec - April (Dry)',
    ),
    CropPlantingReq(
      id: 'CPR002',
      cropName: 'Saging (Banana)',
      cropCategory: 'Prutas',
      minTemp: 24.0,
      maxTemp: 34.0,
      minRainfallMm: 100.0,
      maxRainfallMm: 250.0,
      suitableMonths: 'Year-round',
    ),
    CropPlantingReq(
      id: 'CPR003',
      cropName: 'Talong (Eggplant)',
      cropCategory: 'Gulay',
      minTemp: 20.0,
      maxTemp: 30.0,
      minRainfallMm: 80.0,
      maxRainfallMm: 180.0,
      suitableMonths: 'October - March',
    ),
    CropPlantingReq(
      id: 'CPR004',
      cropName: 'Kamatis (Tomato)',
      cropCategory: 'Gulay',
      minTemp: 18.0,
      maxTemp: 28.0,
      minRainfallMm: 60.0,
      maxRainfallMm: 150.0,
      suitableMonths: 'November - February',
    ),
  ];

  // 6. ADMIN STAFF ACCOUNTS
  final List<AdminStaff> _adminStaffList = [
    AdminStaff(
      id: 'STAFF001',
      name: 'Dr. Roberto Mendoza',
      username: 'roberto_mao',
      email: 'rmendoza@pagsanjan.gov.ph',
      role: 'Municipal Agriculturist',
      status: 'Active',
    ),
    AdminStaff(
      id: 'STAFF002',
      name: 'Clara Gonzales',
      username: 'clara_admin',
      email: 'cgonzales@pagsanjan.gov.ph',
      role: 'Administrative Staff',
      status: 'Active',
    ),
    AdminStaff(
      id: 'STAFF003',
      name: 'Engr. Arnel Cruz',
      username: 'arnel_tech',
      email: 'acruz@pagsanjan.gov.ph',
      role: 'Agricultural Technician',
      status: 'Active',
      password: 'admin123',
    ),
  ];

  // ACTIVE STAFF SESSION STATE
  AdminStaff? _activeStaff;

  AdminStaff get activeStaff => _activeStaff ?? _adminStaffList.first;
  String get activeUserName => '${activeStaff.name} (${activeStaff.role})';

  void switchActiveStaff(AdminStaff staff) {
    _activeStaff = staff;
    logActivity(
      '${staff.name} (${staff.role})',
      'SWITCH',
      'Staff Session',
      'Switched active staff session to ${staff.name} (${staff.role})',
    );
    notifyListeners();
  }

  // 7. ACTIVITY LOG
  final List<ActivityLogItem> _activityLogs = [];

  // 8. ML MODEL STATUS
  final MLModelStatus _modelStatus = MLModelStatus(
    mae: 1.24,
    rmse: 1.85,
    mape: 4.2,
    lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    trainedRecordsCount: 1250,
  );

  // 9. OFFICE POSTS
  final List<Map<String, String>> _posts = [
    {
      'title': 'Typhoon Advisory for Farmers',
      'content': 'Please harvest mature crops early due to expected weather disturbance next week.',
      'date': 'Oct 24, 2026',
    },
    {
      'title': 'Subsidized Fertilizer Distribution',
      'content': 'Free organic fertilizer claiming is now open at the Municipal Agriculture Office.',
      'date': 'Oct 22, 2026',
    },
  ];

  // THEME & LANGUAGE STATE
  bool _isDarkMode = false;
  bool _isTagalog = false;

  bool get isDarkMode => _isDarkMode;
  bool get isTagalog => _isTagalog;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleLanguage() {
    _isTagalog = !_isTagalog;
    notifyListeners();
  }

  // GETTERS
  List<Farmer> get farmers => List.unmodifiable(_farmers);
  List<Farmer> get pendingFarmers => _farmers.where((f) => f.status == 'Pending').toList();

  Future<void> approveFarmer(String id) async {
    final idx = _farmers.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final f = _farmers[idx];
      _farmers[idx] = Farmer(
        id: f.id,
        username: f.username,
        password: f.password,
        profileName: f.profileName,
        barangay: f.barangay,
        contactNumber: f.contactNumber,
        organization: f.organization,
        status: 'Active',
        records: f.records,
      );
      logActivity(activeUserName, 'APPROVE', 'Account Approvals', 'Approved pending account for ${f.profileName}');
      notifyListeners();
    }
  }

  Future<void> rejectFarmer(String id) async {
    final idx = _farmers.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final f = _farmers[idx];
      _farmers.removeAt(idx);
      logActivity(activeUserName, 'REJECT', 'Account Approvals', 'Declined pending account for ${f.profileName}');
      notifyListeners();
    }
  }
  List<FarmRecord> get farms => List.unmodifiable(_farms);
  List<HistoricalDataRecord> get historicalRecords => List.unmodifiable(_historicalRecords);
  List<MarketPriceRecord> get marketPriceRecords => List.unmodifiable(_marketPriceRecords);
  List<CropPlantingReq> get cropRequirements => List.unmodifiable(_cropRequirements);
  List<AdminStaff> get adminStaffList => List.unmodifiable(_adminStaffList);
  List<ActivityLogItem> get activityLogs => List.unmodifiable(_activityLogs);
  MLModelStatus get modelStatus => _modelStatus;
  Map<String, double> get supabasePriceForecasts => Map.unmodifiable(_supabasePriceForecasts);
  Map<String, String> get supabaseForecastModels => Map.unmodifiable(_supabaseForecastModels);
  List<Map<String, String>> get posts => List.unmodifiable(_posts);

  // AUTHENTICATION
  static String normalizeBarangay(String name) {
    return name.trim();
  }

  Farmer? authenticateFarmer(String username, String password) {
    try {
      return _farmers.firstWhere(
        (f) => f.username == username && f.password == password && f.status == 'Active',
      );
    } catch (e) {
      return null;
    }
  }

  Future<Farmer?> authenticateFarmerAsync(String username, String password) async {
    return authenticateFarmer(username, password);
  }

  bool authenticateAdmin(String username, String password) {
    if (username == 'admin' && (password == 'admin123' || _adminStaffList.any((s) => s.username == 'admin' && s.password == password))) {
      return true;
    }
    return _adminStaffList.any((s) => s.username == username && s.password == password && s.status == 'Active');
  }

  Future<bool> authenticateAdminAsync(String username, String password) async {
    if (authenticateAdmin(username, password)) {
      try {
        _activeStaff = _adminStaffList.firstWhere(
          (s) => s.username == username && (s.password == password || (username == 'admin' && password == 'admin123')),
        );
      } catch (_) {
        _activeStaff = _adminStaffList.first;
      }
      notifyListeners();
      return true;
    }
    try {
      final res = await SupabaseService.client
          .from('admin_staff')
          .select()
          .eq('username', username)
          .eq('password', password)
          .eq('status', 'Active')
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (res != null) {
        final staff = AdminStaff(
          id: res['id'] ?? '',
          name: res['name'] ?? 'MAO Staff',
          username: res['username'] ?? '',
          email: res['email'] ?? '',
          role: res['role'] ?? 'Administrative Staff',
          status: res['status'] ?? 'Active',
          password: res['password'] ?? password,
        );
        if (!_adminStaffList.any((s) => s.id == staff.id)) {
          _adminStaffList.add(staff);
        }
        _activeStaff = staff;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Supabase admin auth error: $e');
    }
    return authenticateAdmin(username, password);
  }

  // LOGGING HELPER
  void logActivity(String user, String action, String module, String details) {
    _activityLogs.insert(
      0,
      ActivityLogItem(
        id: 'LOG${DateTime.now().millisecondsSinceEpoch}',
        user: user,
        action: action,
        module: module,
        details: details,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // FARMERS CRUD & ACCOUNTS
  Future<String> addFarmer({
    String? id,
    required String username,
    required String password,
    required String profileName,
    required String barangay,
    required String contactNumber,
    required String organization,
    String status = 'Active',
  }) async {
    final newId = id ?? 'F${DateTime.now().millisecondsSinceEpoch}';
    final farmer = Farmer(
      id: newId,
      username: username,
      password: password,
      profileName: profileName,
      barangay: barangay,
      contactNumber: contactNumber,
      organization: organization,
      status: status,
    );
    _farmers.add(farmer);
    logActivity(activeUserName, 'ADD', 'Farmer Records', 'Added farmer $profileName ($barangay)');
    notifyListeners();

    try {
      await SupabaseService.client.from('farmers').insert({
        'id': newId,
        'username': username,
        'password': password,
        'profile_name': profileName,
        'barangay': barangay,
        'contact_number': contactNumber,
        'organization': organization,
        'status': status,
        'records': [],
      });
      debugPrint('Saved farmer to Supabase: $profileName (ID: $newId)');
    } catch (e) {
      debugPrint('Supabase insert error (farmer): $e');
    }
    return newId;
  }

  Future<void> updateFarmer(String id, {
    required String profileName,
    required String barangay,
    required String contactNumber,
    required String organization,
    required String status,
  }) async {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index] = Farmer(
        id: id,
        username: _farmers[index].username,
        password: _farmers[index].password,
        profileName: profileName,
        barangay: barangay,
        contactNumber: contactNumber,
        organization: organization,
        status: status,
        records: _farmers[index].records,
      );
      logActivity(activeUserName, 'UPDATE', 'Farmer Records', 'Updated farmer $profileName');
      notifyListeners();
    }
  }

  Future<void> deleteFarmer(String id) async {
    _farmers.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  Future<void> setFarmerStatus(String id, String status) async {
    final idx = _farmers.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final f = _farmers[idx];
      _farmers[idx] = Farmer(
        id: f.id,
        username: f.username,
        password: f.password,
        profileName: f.profileName,
        barangay: f.barangay,
        contactNumber: f.contactNumber,
        organization: f.organization,
        status: status,
        records: f.records,
      );
      notifyListeners();
    }
  }

  Future<void> resetFarmerPassword(String id, String newPassword) async {
    final idx = _farmers.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final f = _farmers[idx];
      _farmers[idx] = Farmer(
        id: f.id,
        username: f.username,
        password: newPassword,
        profileName: f.profileName,
        barangay: f.barangay,
        contactNumber: f.contactNumber,
        organization: f.organization,
        status: f.status,
        records: f.records,
      );
      notifyListeners();
    }
  }

  // FARM RECORDS CRUD
  Future<void> addFarmRecord({
    required String farmerId,
    required String farmerName,
    required String locationName,
    required double latitude,
    required double longitude,
    required double landAreaHectares,
    required String tenureStatus,
    required String cropType,
    required String barangay,
    List<LatLng> boundaryPoints = const [],
  }) async {
    _farms.add(FarmRecord(
      id: 'FARM${DateTime.now().millisecondsSinceEpoch}',
      farmerId: farmerId,
      farmerName: farmerName,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      landAreaHectares: landAreaHectares,
      tenureStatus: tenureStatus,
      cropType: cropType,
      barangay: barangay,
    ));
    notifyListeners();
  }

  Future<void> deleteFarmRecord(String id) async {
    _farms.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  // HISTORICAL RECORDS CRUD
  Future<void> addHistoricalRecord({
    required String crop,
    required int year,
    required String month,
    required double productionMT,
    required double pricePerKg,
    required String uploadedBy,
    String barangay = 'ALL',
  }) async {
    _historicalRecords.add(HistoricalDataRecord(
      id: 'HIST${DateTime.now().millisecondsSinceEpoch}',
      crop: crop,
      year: year,
      month: month,
      barangay: barangay,
      productionMT: productionMT,
      pricePerKg: pricePerKg,
      uploadedBy: uploadedBy,
      dateUploaded: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> deleteHistoricalRecord(String id) async {
    _historicalRecords.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // MARKET PRICE RECORDS CRUD
  Future<void> addMarketPriceRecord({
    required String vegetable,
    required double farmgatePrice,
    required double marketPrice,
    required DateTime date,
    required String marketLocation,
    required String uploadedBy,
  }) async {
    _marketPriceRecords.add(MarketPriceRecord(
      id: 'MP${DateTime.now().millisecondsSinceEpoch}',
      vegetable: vegetable,
      farmgatePrice: farmgatePrice,
      marketPrice: marketPrice,
      date: date,
      marketLocation: marketLocation,
      uploadedBy: uploadedBy,
    ));
    notifyListeners();

    try {
      // 1. Insert into market_farmgate_prices table in Supabase
      await SupabaseService.client.from('market_farmgate_prices').insert({
        'id': newId,
        'vegetable': vegetable,
        'farmgate_price': farmgatePrice,
        'market_price': marketPrice,
        'date': date.toIso8601String(),
        'market_location': marketLocation,
        'uploaded_by': author,
      });
    } catch (e) {
      debugPrint('Supabase insert error (market_farmgate_prices): $e');
    }

    try {
      // 2. Also sync to historical_records table for unified historical data analytics & ML model training
      final monthName = DateFormat('MMMM').format(date);
      final histId = 'HIST_$newId';
      await SupabaseService.client.from('historical_records').insert({
        'id': histId,
        'crop': vegetable,
        'year': date.year,
        'month': monthName,
        'production_mt': 0.0,
        'price_per_kg': farmgatePrice,
        'uploaded_by': author,
      });
    } catch (e) {
      debugPrint('Supabase sync insert error (historical_records from market price): $e');
    }
  }

  Future<void> deleteMarketPriceRecord(String id) async {
    _marketPriceRecords.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ADMIN STAFF CRUD
  Future<void> addAdminStaff({
    required String name,
    required String username,
    required String email,
    required String role,
  }) async {
    _adminStaffList.add(AdminStaff(
      id: 'STAFF${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: username,
      email: email,
      role: role,
      status: 'Active',
    ));
    notifyListeners();
  }

  Future<void> deleteAdminStaff(String id) async {
    _adminStaffList.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // POSTS / ANNOUNCEMENTS
  Future<void> addPost(
      String title,
      String content, {
        String category = 'General Advisory',
        String scheduleTime = 'Immediate',
        String eventDate = '',
      }) async {
    final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());
    _posts.insert(0, {
      'title': title,
      'content': content,
      'category': category,
      'scheduleTime': scheduleTime,
      'eventDate': eventDate,
      'date': dateStr,
    });
    logActivity(activeUserName, 'ADD', 'Announcements', 'Posted announcement: $title');
    notifyListeners();

    try {
      await SupabaseService.client.from('announcements').insert({
        'title': title,
        'content': content,
        'category': category,
        'schedule_time': scheduleTime,
        'event_date': eventDate,
        'date': dateStr,
      });
    } catch (e) {
      debugPrint('Supabase insert error (announcement): $e');
    }
  }

  Future<void> deletePost(String idOrTitle) async {
    _posts.removeWhere((p) => (p['id'] == idOrTitle) || (p['title'] == idOrTitle));
    logActivity(activeUserName, 'DELETE', 'Announcements', 'Deleted announcement: $idOrTitle');
    notifyListeners();

    try {
      await SupabaseService.client.from('announcements').delete().eq('title', idOrTitle);
    } catch (e) {
      debugPrint('Supabase delete error (announcement): $e');
    }
  }
}
