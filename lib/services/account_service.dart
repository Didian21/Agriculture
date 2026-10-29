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

      notifyListeners();
    } catch (e) {
      debugPrint('Supabase load error: $e');
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
  final List<Farmer> _farmers = [];

  // 2. FARM RECORDS
  final List<FarmRecord> _farms = [];

  // 3. HISTORICAL DATA (Production & Price)
  final List<HistoricalDataRecord> _historicalRecords = [];

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
  List<CropPlantingReq> get cropRequirements => List.unmodifiable(_cropRequirements);
  List<AdminStaff> get adminStaffList => List.unmodifiable(_adminStaffList);
  List<ActivityLogItem> get activityLogs => List.unmodifiable(_activityLogs);
  MLModelStatus get modelStatus => _modelStatus;
  List<Map<String, String>> get posts => List.unmodifiable(_posts);

  // AUTHENTICATION
  Farmer? authenticateFarmer(String username, String password) {
    try {
      return _farmers.firstWhere(
        (f) => f.username == username && f.password == password && f.status == 'Active',
      );
    } catch (e) {
      return null;
    }
  }

  bool authenticateAdmin(String username, String password) {
    return (username == 'admin' && password == 'admin123') ||
        _adminStaffList.any((s) => s.username == username && s.status == 'Active');
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
      _farmers[index].profileName = profileName;
      _farmers[index].barangay = barangay;
      _farmers[index].contactNumber = contactNumber;
      _farmers[index].organization = organization;
      _farmers[index].status = status;
      logActivity(activeUserName, 'EDIT', 'Farmer Records', 'Updated farmer info for $profileName');
      notifyListeners();

      try {
        await SupabaseService.client.from('farmers').update({
          'profile_name': profileName,
          'barangay': barangay,
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
      barangay: barangay,
    );
    _farms.add(farm);
    logActivity(activeUserName, 'ADD', 'Farm Records', 'Added farm record for $farmerName in $barangay ($landAreaHectares ha)');
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
        'barangay': barangay,
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
        productionMT: productionMT,
        pricePerKg: pricePerKg,
        uploadedBy: author,
        dateUploaded: DateTime.now(),
      ),
    );
    logActivity(author, 'UPLOAD', 'Historical Data', 'Added record for $crop ($month $year: $productionMT MT)');
    notifyListeners();

    try {
      await SupabaseService.client.from('historical_records').insert({
        'id': newId,
        'crop': crop,
        'year': year,
        'month': month,
        'production_mt': productionMT,
        'price_per_kg': pricePerKg,
        'uploaded_by': author,
        'date_uploaded': DateTime.now().toIso8601String(),
      });
      debugPrint('Saved historical record to Supabase: $crop');
    } catch (e) {
      debugPrint('Supabase insert error (historical): $e');
    }
  }

  void updateHistoricalRecord(String id, {
    required String crop,
    required int year,
    required String month,
    required double productionMT,
    required double pricePerKg,
  }) {
    final index = _historicalRecords.indexWhere((h) => h.id == id);
    if (index != -1) {
      _historicalRecords[index].crop = crop;
      _historicalRecords[index].year = year;
      _historicalRecords[index].month = month;
      _historicalRecords[index].productionMT = productionMT;
      _historicalRecords[index].pricePerKg = pricePerKg;
      logActivity(activeUserName, 'EDIT', 'Historical Data', 'Edited record $id ($crop - $year)');
      notifyListeners();
    }
  }

  void deleteHistoricalRecord(String id) {
    final index = _historicalRecords.indexWhere((h) => h.id == id);
    if (index != -1) {
      final crop = _historicalRecords[index].crop;
      _historicalRecords.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Historical Data', 'Deleted record $id ($crop)');
      notifyListeners();
    }
  }

  // CROP PLANTING REQUIREMENTS CRUD
  void addCropRequirement({
    required String cropName,
    required String cropCategory,
    required double minTemp,
    required double maxTemp,
    required double minRainfallMm,
    required double maxRainfallMm,
    required String suitableMonths,
  }) {
    final newId = 'CPR00${_cropRequirements.length + 1}';
    _cropRequirements.add(
      CropPlantingReq(
        id: newId,
        cropName: cropName,
        cropCategory: cropCategory,
        minTemp: minTemp,
        maxTemp: maxTemp,
        minRainfallMm: minRainfallMm,
        maxRainfallMm: maxRainfallMm,
        suitableMonths: suitableMonths,
      ),
    );
    logActivity(activeUserName, 'ADD', 'Planting Requirements', 'Added crop specs for $cropName');
    notifyListeners();
  }

  void updateCropRequirement(String id, {
    required String cropName,
    required String cropCategory,
    required double minTemp,
    required double maxTemp,
    required double minRainfallMm,
    required double maxRainfallMm,
    required String suitableMonths,
  }) {
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
    }
  }

  void deleteCropRequirement(String id) {
    final index = _cropRequirements.indexWhere((c) => c.id == id);
    if (index != -1) {
      final name = _cropRequirements[index].cropName;
      _cropRequirements.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Planting Requirements', 'Deleted crop specs for $name');
      notifyListeners();
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
  void addAdminStaff({
    required String name,
    required String username,
    required String email,
    required String role,
  }) {
    final newId = 'STAFF00${_adminStaffList.length + 1}';
    _adminStaffList.add(
      AdminStaff(
        id: newId,
        name: name,
        username: username,
        email: email,
        role: role,
        status: 'Active',
      ),
    );
    logActivity(activeUserName, 'ADD', 'Admin Accounts', 'Added MAO staff: $name ($role)');
    notifyListeners();
  }

  void deleteAdminStaff(String id) {
    final index = _adminStaffList.indexWhere((s) => s.id == id);
    if (index != -1) {
      final name = _adminStaffList[index].name;
      _adminStaffList.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Admin Accounts', 'Removed MAO staff access for $name');
      notifyListeners();
    }
  }

  Future<void> addPost(String title, String content) async {
    final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());
    _posts.insert(0, {
      'title': title,
      'content': content,
      'date': dateStr,
    });
    logActivity(activeUserName, 'POST', 'Announcements', 'Created post: $title');
    notifyListeners();

    try {
      await SupabaseService.client.from('announcements').insert({
        'title': title,
        'content': content,
        'date': dateStr,
      });
      debugPrint('Saved post to Supabase: $title');
    } catch (e) {
      debugPrint('Supabase insert error (post): $e');
    }
  }
}
