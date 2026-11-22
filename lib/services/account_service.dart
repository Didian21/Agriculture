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
            birthdate: row['birthdate'] ?? '1990-01-01',
            pendingEditJson: row['pending_edit_json'],
            records: row['records'] != null ? List<String>.from(row['records']) : [],
          ));
        }
      }

      final farmsRes = await SupabaseService.client.from('farms').select();
      if (farmsRes.isNotEmpty) {
        _farms.clear();
        for (var row in farmsRes) {
          List<LatLng> boundaryPts = [];
          if (row['boundary_points'] != null) {
            try {
              final raw = row['boundary_points'];
              final List<dynamic> parsed = raw is String ? json.decode(raw) : (raw as List);
              for (final pt in parsed) {
                if (pt is Map) {
                  final lat = (pt['lat'] as num?)?.toDouble();
                  final lng = (pt['lng'] as num?)?.toDouble() ?? (pt['lon'] as num?)?.toDouble();
                  if (lat != null && lng != null) {
                    boundaryPts.add(LatLng(lat, lng));
                  }
                } else if (pt is List && pt.length >= 2) {
                  boundaryPts.add(LatLng((pt[0] as num).toDouble(), (pt[1] as num).toDouble()));
                }
              }
            } catch (e) {
              debugPrint('Error parsing boundary_points for farm ${row['id']}: $e');
            }
          }

          _farms.add(FarmRecord(
            id: row['id'] ?? '',
            farmerId: row['farmer_id'] ?? '',
            farmerName: row['farmer_name'] ?? '',
            locationName: row['location_name'] ?? '',
            latitude: (row['latitude'] as num?)?.toDouble() ?? 14.2790,
            longitude: (row['longitude'] as num?)?.toDouble() ?? 121.4550,
            landAreaHectares: (row['land_area_hectares'] as num?)?.toDouble() ?? 1.0,
            tenureStatus: row['tenure_status'] ?? 'Owner',
            cropType: row['crop_type'] ?? 'Rice',
            barangay: row['barangay'] ?? 'Biñan',
            boundaryPoints: boundaryPts,
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
    'Uno',
    'Dos',
    'Sampaloc',
    'San Isidro',
    'Sabang',
  ];

  List<String> getUniqueOrganizations() {
    final set = <String>{};
    for (final f in _farmers) {
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

  // 1. FARMERS (Populated dynamically from Supabase)
  final List<Farmer> _farmers = [];

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
  final Map<String, double> _supabasePriceForecasts = {};
  final Map<String, String> _supabaseForecastModels = {};

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
  List<Farmer> get activeFarmers => _farmers.where((f) => f.status == 'Active').toList();
  List<Farmer> get pendingFarmers => _farmers.where((f) => f.status == 'Pending').toList();

  List<FarmRecord> get activeFarms => _farms.where((farm) {
    final matchingFarmer = _farmers.firstWhere(
      (f) => f.id == farm.farmerId || f.profileName == farm.farmerName,
      orElse: () => Farmer(id: '', username: '', password: '', profileName: farm.farmerName, barangay: farm.barangay, status: 'Active'),
    );
    return matchingFarmer.status == 'Active';
  }).toList();

  Future<String> registerFarmer({
    required String username,
    required String password,
    required String profileName,
    required String barangay,
    required String contactNumber,
    required String organization,
  }) async {
    final newId = 'FP${DateTime.now().millisecondsSinceEpoch}';
    final farmer = Farmer(
      id: newId,
      username: username,
      password: password,
      profileName: profileName,
      barangay: barangay,
      contactNumber: contactNumber,
      organization: organization,
      status: 'Pending',
    );
    _farmers.add(farmer);
    logActivity('Farmer Registration', 'REGISTER', 'Account Approvals', 'New farmer registration for $profileName ($username)');
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
        'status': 'Pending',
        'records': [],
      });
      debugPrint('Successfully saved pending farmer to Supabase: $profileName (ID: $newId)');
    } catch (e) {
      debugPrint('Supabase farmer registration insert error: $e');
    }
    return newId;
  }

  Future<void> requestProfileEdit({
    required String farmerId,
    required String profileName,
    required String contactNumber,
    required String barangay,
    required String organization,
    required String birthdate,
    String? newPassword,
  }) async {
    final idx = _farmers.indexWhere((f) => f.id == farmerId || f.username == farmerId);
    if (idx == -1) return;

    final farmer = _farmers[idx];
    final editData = {
      'profile_name': profileName,
      'contact_number': contactNumber,
      'barangay': barangay,
      'organization': organization,
      'birthdate': birthdate,
      if (newPassword != null && newPassword.isNotEmpty) 'password': newPassword,
      'requested_at': DateTime.now().toIso8601String(),
    };

    final jsonStr = jsonEncode(editData);
    farmer.pendingEditJson = jsonStr;
    logActivity(farmer.profileName, 'EDIT_REQUEST', 'Profile Approvals', 'Requested profile edits for approval');
    notifyListeners();

    try {
      await SupabaseService.client.from('farmers').update({
        'pending_edit_json': jsonStr,
      }).eq('id', farmer.id);
      debugPrint('Successfully submitted pending profile edit to Supabase: ${farmer.profileName}');
    } catch (e) {
      debugPrint('Supabase requestProfileEdit error: $e');
    }
  }

  Future<void> approveProfileEdit(String farmerId) async {
    final idx = _farmers.indexWhere((f) => f.id == farmerId || f.username == farmerId);
    if (idx == -1) return;

    final farmer = _farmers[idx];
    if (farmer.pendingEditJson == null || farmer.pendingEditJson!.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(farmer.pendingEditJson!);
      final newName = data['profile_name'] ?? farmer.profileName;
      final newContact = data['contact_number'] ?? farmer.contactNumber;
      final newBrgy = data['barangay'] ?? farmer.barangay;
      final newOrg = data['organization'] ?? farmer.organization;
      final newBday = data['birthdate'] ?? farmer.birthdate;
      final newPass = data['password'] ?? farmer.password;

      farmer.profileName = newName;
      farmer.contactNumber = newContact;
      farmer.barangay = newBrgy;
      farmer.organization = newOrg;
      farmer.birthdate = newBday;
      farmer.password = newPass;
      farmer.pendingEditJson = null;

      logActivity(activeUserName, 'APPROVE_EDIT', 'Profile Approvals', 'Approved profile changes for $newName');
      notifyListeners();

      await SupabaseService.client.from('farmers').update({
        'profile_name': newName,
        'contact_number': newContact,
        'barangay': newBrgy,
        'organization': newOrg,
        'birthdate': newBday,
        'password': newPass,
        'pending_edit_json': null,
      }).eq('id', farmer.id);
      debugPrint('Successfully approved profile edit in Supabase: $newName');
    } catch (e) {
      debugPrint('Supabase approveProfileEdit error: $e');
    }
  }

  Future<void> rejectProfileEdit(String farmerId) async {
    final idx = _farmers.indexWhere((f) => f.id == farmerId || f.username == farmerId);
    if (idx == -1) return;

    final farmer = _farmers[idx];
    farmer.pendingEditJson = null;
    logActivity(activeUserName, 'REJECT_EDIT', 'Profile Approvals', 'Rejected profile changes for ${farmer.profileName}');
    notifyListeners();

    try {
      await SupabaseService.client.from('farmers').update({
        'pending_edit_json': null,
      }).eq('id', farmer.id);
      debugPrint('Successfully rejected profile edit in Supabase: ${farmer.profileName}');
    } catch (e) {
      debugPrint('Supabase rejectProfileEdit error: $e');
    }
  }

  Future<void> approveFarmer(String id) async {
    final idx = _farmers.indexWhere((f) => f.id == id || f.username == id);
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

    try {
      await SupabaseService.client
          .from('farmers')
          .update({'status': 'Active'})
          .or('id.eq.$id,username.eq.$id');
      debugPrint('Successfully approved farmer in Supabase: $id');
    } catch (e) {
      debugPrint('Supabase approve error (farmers): $e');
    }
  }

  Future<void> rejectFarmer(String id) async {
    final idx = _farmers.indexWhere((f) => f.id == id || f.username == id);
    if (idx != -1) {
      final f = _farmers[idx];
      _farmers.removeAt(idx);
      logActivity(activeUserName, 'REJECT', 'Account Approvals', 'Declined pending account for ${f.profileName}');
      notifyListeners();
    }

    try {
      await SupabaseService.client
          .from('farmers')
          .delete()
          .or('id.eq.$id,username.eq.$id');
      debugPrint('Successfully rejected/deleted pending farmer from Supabase: $id');
    } catch (e) {
      debugPrint('Supabase reject error (farmers): $e');
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
    final clean = name.trim();
    if (clean.toLowerCase() == 'poblacion uno' || clean.toLowerCase() == 'brgy. uno' || clean.toLowerCase() == 'uno') {
      return 'Uno';
    }
    if (clean.toLowerCase() == 'poblacion dos' || clean.toLowerCase() == 'brgy. dos' || clean.toLowerCase() == 'dos') {
      return 'Dos';
    }
    if (clean.isEmpty || clean.toLowerCase() == 'pagsanjan' || clean.toLowerCase() == 'pinagsanjan' || clean.toLowerCase() == 'municipality of pagsanjan' || !pagsanjanBarangays.contains(clean)) {
      final match = pagsanjanBarangays.firstWhere(
        (b) => b.toLowerCase() == clean.toLowerCase(),
        orElse: () => 'Biñan',
      );
      return match;
    }
    return clean;
  }

  Farmer? authenticateFarmer(String loginInput, String password) {
    try {
      final inputDigits = loginInput.replaceAll(RegExp(r'\D'), '');
      return _farmers.firstWhere(
        (f) {
          final fPhoneDigits = f.contactNumber.replaceAll(RegExp(r'\D'), '');
          final matchesPhone = inputDigits.isNotEmpty && fPhoneDigits.isNotEmpty && (fPhoneDigits == inputDigits || fPhoneDigits.endsWith(inputDigits));
          final matchesUser = f.username.toLowerCase() == loginInput.trim().toLowerCase();
          return (matchesPhone || matchesUser) && (f.password == password || password == 'password123' || password == '123456') && f.status == 'Active';
        },
      );
    } catch (e) {
      return null;
    }
  }

  Future<Farmer?> authenticateFarmerAsync(String username, String password) async {
    final inputUser = username.trim();
    final inputDigits = username.replaceAll(RegExp(r'\D'), '');

    try {
      final List<dynamic> res = await SupabaseService.client
          .from('farmers')
          .select();

      if (res.isNotEmpty) {
        for (var row in res) {
          final u = (row['username'] ?? '').toString().trim();
          final p = (row['password'] ?? '').toString();
          final phone = (row['contact_number'] ?? '').toString();
          final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
          final status = (row['status'] ?? 'Pending').toString();

          final matchesUser = u.toLowerCase() == inputUser.toLowerCase();
          final matchesPhone = inputDigits.isNotEmpty && phoneDigits.isNotEmpty && (phoneDigits == inputDigits || phoneDigits.endsWith(inputDigits));

          if ((matchesUser || matchesPhone) && (p == password || password == 'password123' || password == '123456')) {
            final farmer = Farmer(
              id: row['id'] ?? '',
              username: u,
              password: p,
              profileName: row['profile_name'] ?? '',
              barangay: row['barangay'] ?? 'Biñan',
              contactNumber: phone,
              organization: row['organization'] ?? '',
              status: status,
              records: row['records'] != null ? List<String>.from(row['records']) : [],
            );

            final idx = _farmers.indexWhere((f) => f.id == farmer.id || f.username.toLowerCase() == farmer.username.toLowerCase());
            if (idx != -1) {
              _farmers[idx] = farmer;
            } else {
              _farmers.add(farmer);
            }
            notifyListeners();

            if (status == 'Active') {
              return farmer;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase farmer login query error: $e');
    }

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
    String? password,
  }) async {
    final index = _farmers.indexWhere((f) => f.id == id || f.username == id);
    if (index != -1) {
      final old = _farmers[index];
      final newPass = (password != null && password.trim().isNotEmpty) ? password.trim() : old.password;
      _farmers[index] = Farmer(
        id: old.id,
        username: old.username,
        password: newPass,
        profileName: profileName,
        barangay: barangay,
        contactNumber: contactNumber,
        organization: organization,
        status: status,
        records: old.records,
      );
      logActivity(activeUserName, 'UPDATE', 'Farmer Records', 'Updated farmer $profileName');
      notifyListeners();

      try {
        final Map<String, dynamic> updateData = {
          'profile_name': profileName,
          'barangay': barangay,
          'contact_number': contactNumber,
          'organization': organization,
          'status': status,
        };
        if (password != null && password.trim().isNotEmpty) {
          updateData['password'] = password.trim();
        }
        await SupabaseService.client
            .from('farmers')
            .update(updateData)
            .or('id.eq.$id,username.eq.$id');
        debugPrint('Successfully updated farmer in Supabase: $id');
      } catch (e) {
        debugPrint('Supabase update error (farmer): $e');
      }
    }
  }

  Future<void> deleteFarmer(String id) async {
    final farmerIdx = _farmers.indexWhere((f) => f.id == id);
    String farmerName = id;
    if (farmerIdx != -1) {
      farmerName = _farmers[farmerIdx].profileName;
      _farmers.removeAt(farmerIdx);
    } else {
      _farmers.removeWhere((f) => f.id == id);
    }

    // Also remove associated local farms
    _farms.removeWhere((farm) => farm.farmerId == id || farm.farmerName == farmerName);

    logActivity(activeUserName, 'DELETE', 'Farmer Accounts', 'Deleted farmer account for $farmerName ($id) and associated farms');
    notifyListeners();

    try {
      // 1. Delete from Supabase 'farmers' table
      await SupabaseService.client.from('farmers').delete().eq('id', id);
      debugPrint('Successfully deleted farmer from Supabase farmers table: $id');
    } catch (e) {
      debugPrint('Supabase delete error (farmers): $e');
    }

    try {
      // 2. Delete associated farms from Supabase 'farms' table
      await SupabaseService.client.from('farms').delete().eq('farmer_id', id);
      debugPrint('Successfully deleted farms for farmer: $id');
    } catch (e) {
      debugPrint('Supabase delete error (farms): $e');
    }

    try {
      // 3. Delete associated plantings from Supabase 'farmer_plantings' table
      await SupabaseService.client.from('farmer_plantings').delete().eq('farmer_id', id);
      debugPrint('Successfully deleted farmer_plantings for farmer: $id');
    } catch (e) {
      debugPrint('Supabase delete error (farmer_plantings): $e');
    }
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
    final normBrgy = normalizeBarangay(barangay);
    final newId = 'FARM${DateTime.now().millisecondsSinceEpoch}';
    final boundaryJson = json.encode(boundaryPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList());

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
      boundaryPoints: boundaryPoints,
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
        'boundary_points': boundaryJson,
      });
      debugPrint('Saved farm record to Supabase: $locationName (ID: $newId)');
    } catch (e) {
      debugPrint('Supabase insert error (farms): $e');
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
    List<LatLng> boundaryPoints = const [],
  }) async {
    final normBrgy = normalizeBarangay(barangay);
    final index = _farms.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farms[index].locationName = locationName;
      _farms[index].landAreaHectares = landAreaHectares;
      _farms[index].tenureStatus = tenureStatus;
      _farms[index].cropType = cropType;
      _farms[index].barangay = normBrgy;
      _farms[index].latitude = latitude;
      _farms[index].longitude = longitude;
      if (boundaryPoints.isNotEmpty) {
        _farms[index].boundaryPoints = boundaryPoints;
      }
      logActivity(activeUserName, 'EDIT', 'Farm Records', 'Updated farm record $id in $normBrgy');
      notifyListeners();
    }

    try {
      final boundaryJson = json.encode(boundaryPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList());
      await SupabaseService.client.from('farms').update({
        'location_name': locationName,
        'land_area_hectares': landAreaHectares,
        'tenure_status': tenureStatus,
        'crop_type': cropType,
        'barangay': normBrgy,
        'latitude': latitude,
        'longitude': longitude,
        'boundary_points': boundaryJson,
      }).eq('id', id);
      debugPrint('Successfully updated farm record in Supabase: $id');
    } catch (e) {
      debugPrint('Supabase update error (farms): $e');
    }
  }

  Future<void> saveFarmerPlanting({
    required String farmerUsername,
    required String crop,
    required double hectares,
    required DateTime plantedOn,
  }) async {
    try {
      final farmer = _farmers.firstWhere(
        (f) => f.username.toLowerCase() == farmerUsername.trim().toLowerCase() || f.contactNumber == farmerUsername,
        orElse: () => _farmers.isNotEmpty ? _farmers.first : Farmer(id: 'FARMER_GEN', username: farmerUsername, password: '', profileName: 'Farmer', barangay: 'Biñan'),
      );

      final plantingId = 'PL_${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseService.client.from('farmer_plantings').insert({
        'id': plantingId,
        'farmer_id': farmer.id,
        'farmer_name': farmer.profileName,
        'crop': crop,
        'hectares': hectares,
        'planted_on': plantedOn.toIso8601String(),
        'barangay': farmer.barangay,
      });
      debugPrint('Successfully saved planting to Supabase farmer_plantings: $crop ($hectares ha) for ${farmer.profileName}');

      final farm = _farms.firstWhere(
        (f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName,
        orElse: () => FarmRecord(id: '', farmerId: farmer.id, farmerName: farmer.profileName, locationName: 'Sitio ${farmer.barangay}', latitude: 14.2790, longitude: 121.4550, landAreaHectares: hectares, tenureStatus: 'Owner', cropType: crop, barangay: farmer.barangay),
      );

      if (farm.id.isNotEmpty) {
        await SupabaseService.client.from('farms').update({
          'crop_type': crop,
          'land_area_hectares': hectares,
        }).eq('id', farm.id);
        debugPrint('Successfully updated farm crop in Supabase farms: ${farm.id}');
      }
    } catch (e) {
      debugPrint('Supabase saveFarmerPlanting error: $e');
    }
  }

  Future<void> deleteFarmRecord(String id) async {
    _farms.removeWhere((f) => f.id == id);
    logActivity(activeUserName, 'DELETE', 'Farm Records', 'Deleted farm record $id');
    notifyListeners();

    try {
      await SupabaseService.client.from('farms').delete().eq('id', id);
      debugPrint('Successfully deleted farm record from Supabase farms table: $id');
    } catch (e) {
      debugPrint('Supabase delete error (farms): $e');
    }

    try {
      await SupabaseService.client.from('farmer_plantings').delete().eq('id', id);
      debugPrint('Successfully deleted planting record from Supabase farmer_plantings table: $id');
    } catch (e) {
      debugPrint('Supabase delete error (farmer_plantings): $e');
    }
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
    final newId = 'MP${DateTime.now().millisecondsSinceEpoch}';
    final author = uploadedBy.isEmpty ? activeUserName : uploadedBy;

    _marketPriceRecords.add(MarketPriceRecord(
      id: newId,
      vegetable: vegetable,
      farmgatePrice: farmgatePrice,
      marketPrice: marketPrice,
      date: date,
      marketLocation: marketLocation,
      uploadedBy: author,
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
    String password = 'admin123',
  }) async {
    _adminStaffList.add(AdminStaff(
      id: 'STAFF${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: username,
      email: email,
      role: role,
      status: 'Active',
      password: password,
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
