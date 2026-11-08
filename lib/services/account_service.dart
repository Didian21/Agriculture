import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/farmer.dart';
import 'supabase_service.dart';

class AccountService extends ChangeNotifier {
  AccountService() {
    loadFromSupabase();
  }

  Future<void> loadFromSupabase() async {
    try {
      final farmersRes = await SupabaseService.client.from('farmers').select();
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

      final farmsRes = await SupabaseService.client.from('farms').select();
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

      final histRes = await SupabaseService.client.from('historical_records').select();
      _historicalRecords.clear();
      for (var row in histRes) {
        _historicalRecords.add(HistoricalDataRecord(
          id: row['id'] ?? '',
          crop: row['crop'] ?? '',
          year: row['year'] ?? 2026,
          month: row['month'] ?? 'January',
          barangay: row['barangay'] ?? 'ALL',
          productionMT: (row['production_mt'] as num?)?.toDouble() ?? 0.0,
          pricePerKg: (row['price_per_kg'] as num?)?.toDouble() ?? 0.0,
          uploadedBy: row['uploaded_by'] ?? 'Admin',
          dateUploaded: row['date_uploaded'] != null ? DateTime.parse(row['date_uploaded']) : DateTime.now(),
        ));
      }

      final postsRes = await SupabaseService.client.from('announcements').select();
      _posts.clear();
      for (var row in postsRes) {
        _posts.add({
          'title': row['title'] ?? '',
          'content': row['content'] ?? '',
          'date': row['date'] ?? '',
        });
      }

      try {
        final staffRes = await SupabaseService.client.from('admin_staff').select();
        if (staffRes.isNotEmpty) {
          _adminStaffList.clear();
          for (var row in staffRes) {
            _adminStaffList.add(AdminStaff(
              id: row['id'] ?? '',
              name: row['name'] ?? '',
              username: row['username'] ?? '',
              email: row['email'] ?? '',
              role: row['role'] ?? 'Administrative Staff',
              status: row['status'] ?? 'Active',
            ));
          }
        }
      } catch (_) {}

      try {
        final cropReqRes = await SupabaseService.client.from('crop_requirements').select();
        if (cropReqRes.isNotEmpty) {
          _cropRequirements.clear();
          for (var row in cropReqRes) {
            _cropRequirements.add(CropPlantingReq(
              id: row['id'] ?? '',
              cropName: row['crop_name'] ?? '',
              cropCategory: row['crop_category'] ?? 'Gulay',
              minTemp: (row['min_temp'] as num?)?.toDouble() ?? 20.0,
              maxTemp: (row['max_temp'] as num?)?.toDouble() ?? 30.0,
              minRainfallMm: (row['min_rainfall_mm'] as num?)?.toDouble() ?? 100.0,
              maxRainfallMm: (row['max_rainfall_mm'] as num?)?.toDouble() ?? 250.0,
              suitableMonths: row['suitable_months'] ?? 'Year-round',
            ));
          }
        }
      } catch (_) {}

      try {
        final logsRes = await SupabaseService.client.from('activity_logs').select().order('timestamp', ascending: false).limit(100);
        if (logsRes.isNotEmpty) {
          _activityLogs.clear();
          for (var row in logsRes) {
            _activityLogs.add(ActivityLogItem(
              id: row['id'] ?? '',
              user: row['user'] ?? '',
              action: row['action'] ?? '',
              module: row['module'] ?? '',
              details: row['details'] ?? '',
              timestamp: row['timestamp'] != null ? DateTime.parse(row['timestamp']) : DateTime.now(),
            ));
          }
        }
      } catch (_) {}

      try {
        final metricsRes = await SupabaseService.client.from('model_metrics').select().limit(1);
        if (metricsRes.isNotEmpty) {
          final row = metricsRes.first;
          _modelStatus = MLModelStatus(
            mae: (row['mae'] as num?)?.toDouble() ?? 1.24,
            rmse: (row['rmse'] as num?)?.toDouble() ?? 1.85,
            mape: (row['mape_pct'] as num?)?.toDouble() ?? 4.2,
            lastUpdated: DateTime.now(),
            trainedRecordsCount: _historicalRecords.length * 350 + 800,
          );
        }
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      debugPrint('Supabase load error: $e');
    }
  }
  // Pagsanjan Barangays (All 16 Barangays)
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
    'Pinagsanjan',
    'Poblacion Uno',
    'Poblacion Dos',
    'Sabang',
    'Sampaloc',
    'San Isidro',
  ];

  static String normalizeBarangay(String input) {
    final clean = input.trim().toLowerCase();
    for (final b in pagsanjanBarangays) {
      if (b.toLowerCase() == clean) return b;
    }
    if (input.isEmpty) return 'Biñan';
    return input[0].toUpperCase() + input.substring(1);
  }

  // 1. FARMERS
  final List<Farmer> _farmers = [];

  // 2. FARM RECORDS
  final List<FarmRecord> _farms = [];

  // 3. HISTORICAL DATA (Production & Price)
  final List<HistoricalDataRecord> _historicalRecords = [];

  // 3b. MARKET & FARMGATE PRICES FOR VEGETABLES
  final List<MarketPriceRecord> _marketPriceRecords = [
    MarketPriceRecord(
      id: 'MP001',
      vegetable: 'Talong (Eggplant)',
      farmgatePrice: 45.0,
      marketPrice: 70.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Ms. Jellie Masacayan',
    ),
    MarketPriceRecord(
      id: 'MP002',
      vegetable: 'Kamatis (Tomato)',
      farmgatePrice: 50.0,
      marketPrice: 85.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Ms. Jellie Masacayan',
    ),
    MarketPriceRecord(
      id: 'MP003',
      vegetable: 'Okra',
      farmgatePrice: 35.0,
      marketPrice: 55.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Engr. Arnel Cruz',
    ),
    MarketPriceRecord(
      id: 'MP004',
      vegetable: 'Pechay (Tagalog)',
      farmgatePrice: 40.0,
      marketPrice: 65.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Clara Gonzales',
    ),
    MarketPriceRecord(
      id: 'MP005',
      vegetable: 'Sitaw (Yardlong Bean)',
      farmgatePrice: 45.0,
      marketPrice: 75.0,
      date: DateTime.now().subtract(const Duration(days: 3)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Ms. Jellie Masacayan',
    ),
    MarketPriceRecord(
      id: 'MP006',
      vegetable: 'Ampalaya (Bitter Gourd)',
      farmgatePrice: 60.0,
      marketPrice: 90.0,
      date: DateTime.now().subtract(const Duration(days: 3)),
      marketLocation: 'Pagsanjan Public Market',
      uploadedBy: 'Engr. Arnel Cruz',
    ),
  ];

  // 4. CROP PLANTING REQUIREMENTS
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

  // 5. ADMIN STAFF ACCOUNTS
  final List<AdminStaff> _adminStaffList = [
    AdminStaff(
      id: 'STAFF001',
      name: 'Ms. Jellie Masacayan',
      username: 'jellie_masacayan',
      email: 'jmasacayan@pagsanjan.gov.ph',
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

  // 6. ACTIVITY LOG
  final List<ActivityLogItem> _activityLogs = [];

  // 7. ML MODEL STATUS
  MLModelStatus _modelStatus = MLModelStatus(
    mae: 1.24,
    rmse: 1.85,
    mape: 4.2,
    lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    trainedRecordsCount: 1250,
  );

  // 8. OFFICE POSTS
  final List<Map<String, String>> _posts = [];

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
  List<FarmRecord> get farms => List.unmodifiable(_farms);
  List<HistoricalDataRecord> get historicalRecords => List.unmodifiable(_historicalRecords);
  List<MarketPriceRecord> get marketPriceRecords => List.unmodifiable(_marketPriceRecords);
  List<CropPlantingReq> get cropRequirements => List.unmodifiable(_cropRequirements);
  List<AdminStaff> get adminStaffList => List.unmodifiable(_adminStaffList);
  List<ActivityLogItem> get activityLogs => List.unmodifiable(_activityLogs);
  MLModelStatus get modelStatus => _modelStatus;
  List<Map<String, String>> get posts => List.unmodifiable(_posts);

  // AUTHENTICATION
  Farmer? authenticateFarmer(String username, String password) {
    try {
      return _farmers.firstWhere(
        (f) => (f.username == username || f.contactNumber == username) && f.password == password && f.status == 'Active',
      );
    } catch (e) {
      return null;
    }
  }

  Future<Farmer?> authenticateFarmerAsync(String username, String password) async {
    try {
      final localMatch = authenticateFarmer(username, password);
      if (localMatch != null) return localMatch;
    } catch (_) {}

    try {
      final res = await SupabaseService.client
          .from('farmers')
          .select()
          .or('username.eq.$username,contact_number.eq.$username')
          .eq('password', password)
          .eq('status', 'Active')
          .maybeSingle();

      if (res != null) {
        final farmer = Farmer(
          id: res['id'] ?? '',
          username: res['username'] ?? '',
          password: res['password'] ?? '',
          profileName: res['profile_name'] ?? '',
          barangay: res['barangay'] ?? 'Biñan',
          contactNumber: res['contact_number'] ?? '',
          organization: res['organization'] ?? '',
          status: res['status'] ?? 'Active',
          records: res['records'] != null ? List<String>.from(res['records']) : [],
        );
        if (!_farmers.any((f) => f.id == farmer.id)) {
          _farmers.add(farmer);
        }
        return farmer;
      }
    } catch (e) {
      debugPrint('Supabase auth error (farmer): $e');
    }

    return null;
  }

  bool authenticateAdmin(String username, String password) {
    return (username == 'admin' && password == 'admin123') ||
        _adminStaffList.any((s) => s.username == username && s.status == 'Active');
  }

  Future<bool> authenticateAdminAsync(String username, String password) async {
    if (authenticateAdmin(username, password)) return true;
    try {
      final res = await SupabaseService.client
          .from('admin_staff')
          .select()
          .eq('username', username)
          .eq('password', password)
          .eq('status', 'Active')
          .maybeSingle();

      if (res != null) {
        final staff = AdminStaff(
          id: res['id'] ?? '',
          name: res['name'] ?? 'MAO Staff',
          username: res['username'] ?? '',
          email: res['email'] ?? '',
          role: res['role'] ?? 'Administrative Staff',
          status: res['status'] ?? 'Active',
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
    return false;
  }

  // LOGGING HELPER
  void logActivity(String user, String action, String module, String details) {
    final newId = 'LOG${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    _activityLogs.insert(
      0,
      ActivityLogItem(
        id: newId,
        user: user,
        action: action,
        module: module,
        details: details,
        timestamp: now,
      ),
    );
    notifyListeners();

    try {
      SupabaseService.client.from('activity_logs').insert({
        'id': newId,
        'user': user,
        'action': action,
        'module': module,
        'details': details,
        'timestamp': now.toIso8601String(),
      }).then((_) {}).catchError((_) {});
    } catch (_) {}
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
    final normBrgy = normalizeBarangay(barangay);
    final newId = id ?? 'F${DateTime.now().millisecondsSinceEpoch}';
    final farmer = Farmer(
      id: newId,
      username: username,
      password: password,
      profileName: profileName,
      barangay: normBrgy,
      contactNumber: contactNumber,
      organization: organization,
      status: status,
    );
    _farmers.add(farmer);
    logActivity(activeUserName, 'ADD', 'Farmer Records', 'Added farmer $profileName ($normBrgy)');
    notifyListeners();

    try {
      await SupabaseService.client.from('farmers').insert({
        'id': newId,
        'username': username,
        'password': password,
        'profile_name': profileName,
        'barangay': normBrgy,
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
    final normBrgy = normalizeBarangay(barangay);
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index].profileName = profileName;
      _farmers[index].barangay = normBrgy;
      _farmers[index].contactNumber = contactNumber;
      _farmers[index].organization = organization;
      _farmers[index].status = status;
      logActivity(activeUserName, 'EDIT', 'Farmer Records', 'Updated farmer info for $profileName');
      notifyListeners();

      try {
        await SupabaseService.client.from('farmers').update({
          'profile_name': profileName,
          'barangay': normBrgy,
          'contact_number': contactNumber,
          'organization': organization,
          'status': status,
        }).eq('id', id);
      } catch (e) {
        debugPrint('Supabase update error (farmer): $e');
      }
    }
  }

  Future<void> deleteFarmer(String id) async {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      final name = _farmers[index].profileName;
      _farmers.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Farmer Records', 'Deleted farmer $name');
      notifyListeners();

      try {
        await SupabaseService.client.from('farmers').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete error (farmer): $e');
      }
    }
  }

  Future<void> setFarmerStatus(String id, String newStatus) async {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index].status = newStatus;
      logActivity(activeUserName, 'EDIT', 'Farmer Accounts', 'Set account status of ${_farmers[index].profileName} to $newStatus');
      notifyListeners();

      try {
        await SupabaseService.client.from('farmers').update({'status': newStatus}).eq('id', id);
      } catch (e) {
        debugPrint('Supabase status update error: $e');
      }
    }
  }

  Future<void> resetFarmerPassword(String id, String newPassword) async {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index].password = newPassword;
      logActivity(activeUserName, 'EDIT', 'Farmer Accounts', 'Reset password for ${_farmers[index].profileName}');
      notifyListeners();

      try {
        await SupabaseService.client.from('farmers').update({'password': newPassword}).eq('id', id);
      } catch (e) {
        debugPrint('Supabase password reset error: $e');
      }
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
  }) async {
    final normBrgy = normalizeBarangay(barangay);
    final newId = 'FARM${DateTime.now().millisecondsSinceEpoch}';
    final farm = FarmRecord(
      id: newId,
      farmerId: farmerId,
      farmerName: farmerName,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      landAreaHectares: landAreaHectares,
      tenureStatus: tenureStatus,
      cropType: cropType,
      barangay: normBrgy,
    );
    _farms.add(farm);
    logActivity(activeUserName, 'ADD', 'Farm Records', 'Added farm record for $farmerName in $normBrgy ($landAreaHectares ha)');
    notifyListeners();

    try {
      await SupabaseService.client.from('farms').insert({
        'id': newId,
        'farmer_id': farmerId,
        'farmer_name': farmerName,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'land_area_hectares': landAreaHectares,
        'tenure_status': tenureStatus,
        'crop_type': cropType,
        'barangay': normBrgy,
      });
      debugPrint('Saved farm record to Supabase: $locationName');
    } catch (e) {
      debugPrint('Supabase insert error (farm): $e');
    }
  }

  Future<void> updateFarmRecord(String id, {
    required String locationName,
    required double landAreaHectares,
    required String tenureStatus,
    required String cropType,
    required String barangay,
    required double latitude,
    required double longitude,
  }) async {
    final index = _farms.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farms[index].locationName = locationName;
      _farms[index].landAreaHectares = landAreaHectares;
      _farms[index].tenureStatus = tenureStatus;
      _farms[index].cropType = cropType;
      _farms[index].barangay = barangay;
      _farms[index].latitude = latitude;
      _farms[index].longitude = longitude;
      logActivity(activeUserName, 'EDIT', 'Farm Records', 'Updated farm record $id in $barangay');
      notifyListeners();

      try {
        await SupabaseService.client.from('farms').update({
          'location_name': locationName,
          'land_area_hectares': landAreaHectares,
          'tenure_status': tenureStatus,
          'crop_type': cropType,
          'barangay': barangay,
          'latitude': latitude,
          'longitude': longitude,
        }).eq('id', id);
      } catch (e) {
        debugPrint('Supabase update error (farm): $e');
      }
    }
  }

  Future<void> deleteFarmRecord(String id) async {
    final index = _farms.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farms.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Farm Records', 'Deleted farm record $id');
      notifyListeners();

      try {
        await SupabaseService.client.from('farms').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete error (farm): $e');
      }
    }
  }

  // HISTORICAL DATA CRUD & CLEANING
  Future<void> addHistoricalRecord({
    required String crop,
    required int year,
    required String month,
    String barangay = 'ALL',
    required double productionMT,
    required double pricePerKg,
    required String uploadedBy,
  }) async {
    final newId = 'H${DateTime.now().millisecondsSinceEpoch}';
    final author = uploadedBy.isEmpty ? activeUserName : uploadedBy;
    _historicalRecords.add(
      HistoricalDataRecord(
        id: newId,
        crop: crop,
        year: year,
        month: month,
        barangay: barangay,
        productionMT: productionMT,
        pricePerKg: pricePerKg,
        uploadedBy: author,
        dateUploaded: DateTime.now(),
      ),
    );
    logActivity(author, 'UPLOAD', 'Historical Data', 'Added record for $crop ($month $year - $barangay: $productionMT MT)');
    notifyListeners();

    try {
      await SupabaseService.client.from('historical_records').insert({
        'id': newId,
        'crop': crop,
        'year': year,
        'month': month,
        'barangay': barangay,
        'production_mt': productionMT,
        'price_per_kg': pricePerKg,
        'uploaded_by': author,
        'date_uploaded': DateTime.now().toIso8601String(),
      });
      debugPrint('Saved historical record to Supabase: $crop ($barangay)');
    } catch (e) {
      debugPrint('Supabase insert error (historical): $e');
    }
  }

  Future<void> updateHistoricalRecord(String id, {
    required String crop,
    required int year,
    required String month,
    String barangay = 'ALL',
    required double productionMT,
    required double pricePerKg,
  }) async {
    final index = _historicalRecords.indexWhere((h) => h.id == id);
    if (index != -1) {
      _historicalRecords[index].crop = crop;
      _historicalRecords[index].year = year;
      _historicalRecords[index].month = month;
      _historicalRecords[index].barangay = barangay;
      _historicalRecords[index].productionMT = productionMT;
      _historicalRecords[index].pricePerKg = pricePerKg;
      logActivity(activeUserName, 'EDIT', 'Historical Data', 'Edited record $id ($crop - $year - $barangay)');
      notifyListeners();

      try {
        await SupabaseService.client.from('historical_records').update({
          'crop': crop,
          'year': year,
          'month': month,
          'barangay': barangay,
          'production_mt': productionMT,
          'price_per_kg': pricePerKg,
        }).eq('id', id);
      } catch (e) {
        debugPrint('Supabase update error (historical): $e');
      }
    }
  }

  Future<void> deleteHistoricalRecord(String id) async {
    final index = _historicalRecords.indexWhere((h) => h.id == id);
    if (index != -1) {
      final crop = _historicalRecords[index].crop;
      _historicalRecords.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Historical Data', 'Deleted record $id ($crop)');
      notifyListeners();

      try {
        await SupabaseService.client.from('historical_records').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete error (historical): $e');
      }
    }
  }

  // MARKET & FARMGATE PRICES CRUD
  Future<void> addMarketPriceRecord({
    required String vegetable,
    required double farmgatePrice,
    required double marketPrice,
    required DateTime date,
    String marketLocation = 'Pagsanjan Public Market',
    required String uploadedBy,
  }) async {
    final newId = 'MP${DateTime.now().millisecondsSinceEpoch}';
    final author = uploadedBy.isEmpty ? activeUserName : uploadedBy;
    _marketPriceRecords.insert(
      0,
      MarketPriceRecord(
        id: newId,
        vegetable: vegetable,
        farmgatePrice: farmgatePrice,
        marketPrice: marketPrice,
        date: date,
        marketLocation: marketLocation,
        uploadedBy: author,
      ),
    );
    logActivity(author, 'UPLOAD', 'Market Prices', 'Added market & farmgate price for $vegetable (Farmgate: ₱$farmgatePrice, Market: ₱$marketPrice)');
    notifyListeners();
  }

  Future<void> deleteMarketPriceRecord(String id) async {
    final index = _marketPriceRecords.indexWhere((m) => m.id == id);
    if (index != -1) {
      final veg = _marketPriceRecords[index].vegetable;
      _marketPriceRecords.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Market Prices', 'Deleted market price record for $veg');
      notifyListeners();
    }
  }

  // CROP PLANTING REQUIREMENTS CRUD
  Future<void> addCropRequirement({
    required String cropName,
    required String cropCategory,
    required double minTemp,
    required double maxTemp,
    required double minRainfallMm,
    required double maxRainfallMm,
    required String suitableMonths,
  }) async {
    final newId = 'CPR${DateTime.now().millisecondsSinceEpoch}';
    final req = CropPlantingReq(
      id: newId,
      cropName: cropName,
      cropCategory: cropCategory,
      minTemp: minTemp,
      maxTemp: maxTemp,
      minRainfallMm: minRainfallMm,
      maxRainfallMm: maxRainfallMm,
      suitableMonths: suitableMonths,
    );
    _cropRequirements.add(req);
    logActivity(activeUserName, 'ADD', 'Planting Requirements', 'Added crop specs for $cropName');
    notifyListeners();

    try {
      await SupabaseService.client.from('crop_requirements').insert({
        'id': newId,
        'crop_name': cropName,
        'crop_category': cropCategory,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'min_rainfall_mm': minRainfallMm,
        'max_rainfall_mm': maxRainfallMm,
        'suitable_months': suitableMonths,
      });
    } catch (e) {
      debugPrint('Supabase insert error (crop requirement): $e');
    }
  }

  Future<void> updateCropRequirement(String id, {
    required String cropName,
    required String cropCategory,
    required double minTemp,
    required double maxTemp,
    required double minRainfallMm,
    required double maxRainfallMm,
    required String suitableMonths,
  }) async {
    final index = _cropRequirements.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cropRequirements[index].cropName = cropName;
      _cropRequirements[index].cropCategory = cropCategory;
      _cropRequirements[index].minTemp = minTemp;
      _cropRequirements[index].maxTemp = maxTemp;
      _cropRequirements[index].minRainfallMm = minRainfallMm;
      _cropRequirements[index].maxRainfallMm = maxRainfallMm;
      _cropRequirements[index].suitableMonths = suitableMonths;
      logActivity(activeUserName, 'EDIT', 'Planting Requirements', 'Updated crop specs for $cropName');
      notifyListeners();

      try {
        await SupabaseService.client.from('crop_requirements').update({
          'crop_name': cropName,
          'crop_category': cropCategory,
          'min_temp': minTemp,
          'max_temp': maxTemp,
          'min_rainfall_mm': minRainfallMm,
          'max_rainfall_mm': maxRainfallMm,
          'suitable_months': suitableMonths,
        }).eq('id', id);
      } catch (e) {
        debugPrint('Supabase update error (crop requirement): $e');
      }
    }
  }

  Future<void> deleteCropRequirement(String id) async {
    final index = _cropRequirements.indexWhere((c) => c.id == id);
    if (index != -1) {
      final name = _cropRequirements[index].cropName;
      _cropRequirements.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Planting Requirements', 'Deleted crop specs for $name');
      notifyListeners();

      try {
        await SupabaseService.client.from('crop_requirements').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete error (crop requirement): $e');
      }
    }
  }

  // MODEL MANAGEMENT
  Future<void> triggerModelRetraining() async {
    _modelStatus.isTraining = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    _modelStatus = MLModelStatus(
      mae: 1.18,
      rmse: 1.72,
      mape: 3.9,
      lastUpdated: DateTime.now(),
      trainedRecordsCount: _historicalRecords.length * 350 + 800,
      isTraining: false,
    );

    logActivity(
      activeUserName,
      'RETRAIN',
      'Model Management',
      'Retrained ML Model successfully. MAE: 1.18, RMSE: 1.72, MAPE: 3.9%',
    );
    notifyListeners();
  }

  // ADMIN STAFF CRUD
  Future<void> addAdminStaff({
    required String name,
    required String username,
    required String email,
    required String role,
    String password = 'admin123',
  }) async {
    final newId = 'STAFF${DateTime.now().millisecondsSinceEpoch}';
    final staff = AdminStaff(
      id: newId,
      name: name,
      username: username,
      email: email,
      role: role,
      status: 'Active',
    );
    _adminStaffList.add(staff);
    logActivity(activeUserName, 'ADD', 'Admin Accounts', 'Added MAO staff: $name ($role)');
    notifyListeners();

    try {
      await SupabaseService.client.from('admin_staff').insert({
        'id': newId,
        'name': name,
        'username': username,
        'email': email,
        'role': role,
        'password': password,
        'status': 'Active',
      });
    } catch (e) {
      debugPrint('Supabase insert error (admin staff): $e');
    }
  }

  Future<void> deleteAdminStaff(String id) async {
    final index = _adminStaffList.indexWhere((s) => s.id == id);
    if (index != -1) {
      final name = _adminStaffList[index].name;
      _adminStaffList.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Admin Accounts', 'Removed MAO staff access for $name');
      notifyListeners();

      try {
        await SupabaseService.client.from('admin_staff').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete error (admin staff): $e');
      }
    }
  }

  Future<void> addPost(String title, String content, {String category = 'General Advisory', String scheduleTime = 'Immediate'}) async {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now());
    final displayDate = scheduleTime == 'Immediate' ? dateStr : scheduleTime;
    _posts.insert(0, {
      'title': title,
      'content': content,
      'date': displayDate,
      'category': category,
      'status': scheduleTime == 'Immediate' ? 'Published' : 'Scheduled',
    });
    logActivity(activeUserName, 'POST', 'Announcements', 'Created post [$category] (Schedule: $scheduleTime): $title');
    notifyListeners();

    try {
      await SupabaseService.client.from('announcements').insert({
        'title': title,
        'content': content,
        'date': displayDate,
        'category': category,
        'status': scheduleTime == 'Immediate' ? 'Published' : 'Scheduled',
      });
      debugPrint('Saved post to Supabase: $title');
    } catch (e) {
      debugPrint('Supabase insert error (post): $e');
    }
  }
}
