import 'package:flutter/material.dart';
import '../models/farmer.dart';

class AccountService extends ChangeNotifier {
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
    Farmer(
      id: 'F001',
      username: 'juan_dela_cruz',
      password: 'password123',
      profileName: 'Juan Dela Cruz',
      barangay: 'Biñan',
      contactNumber: '09171234567',
      organization: 'Pagsanjan Rice Farmers Coop',
      status: 'Active',
      records: ['Harvest Jan 2026: 4.5 MT', 'Harvest Oct 2025: 4.2 MT'],
    ),
    Farmer(
      id: 'F002',
      username: 'maria_santos',
      password: 'password123',
      profileName: 'Maria Santos',
      barangay: 'Buboy',
      contactNumber: '09189876543',
      organization: 'Anibong Vegetable Planters Assoc.',
      status: 'Active',
      records: ['Vegetables Q1: 1.2 MT'],
    ),
    Farmer(
      id: 'F003',
      username: 'pedro_penduko',
      password: 'password123',
      profileName: 'Pedro Penduko',
      barangay: 'Magdapio',
      contactNumber: '09223334455',
      organization: 'Pagsanjan Fruit Growers',
      status: 'Pending',
      records: [],
    ),
    Farmer(
      id: 'F004',
      username: 'ana_reyes',
      password: 'password123',
      profileName: 'Ana Reyes',
      barangay: 'Lambac',
      contactNumber: '09191112233',
      organization: 'Pagsanjan Rice Farmers Coop',
      status: 'Active',
      records: ['Harvest Feb 2026: 5.0 MT'],
    ),
    Farmer(
      id: 'F005',
      username: 'carlitos_reyes',
      password: 'password123',
      profileName: 'Carlitos Reyes',
      barangay: 'Sampaloc',
      contactNumber: '09175558899',
      organization: 'Sampaloc Agricultural Society',
      status: 'Active',
      records: ['Harvest Jan 2026: 6.1 MT'],
    ),
    Farmer(
      id: 'F006',
      username: 'elena_gomez',
      password: 'password123',
      profileName: 'Elena Gomez',
      barangay: 'Calusiche',
      contactNumber: '09186667788',
      organization: 'Calusiche Growers Assoc.',
      status: 'Active',
      records: ['Harvest Dec 2025: 2.3 MT'],
    ),
    Farmer(
      id: 'F007',
      username: 'ricardo_dizon',
      password: 'password123',
      profileName: 'Ricardo Dizon',
      barangay: 'Dingin',
      contactNumber: '09204445566',
      organization: 'Dingin Planters Coop',
      status: 'Active',
      records: ['Harvest Nov 2025: 3.4 MT'],
    ),
    Farmer(
      id: 'F008',
      username: 'lucia_mendoza',
      password: 'password123',
      profileName: 'Lucia Mendoza',
      barangay: 'Poblacion Uno',
      contactNumber: '09217778899',
      organization: 'Pagsanjan Fruit Growers',
      status: 'Pending',
      records: [],
    ),
  ];

  // 2. FARM RECORDS
  final List<FarmRecord> _farms = [
    FarmRecord(
      id: 'FARM001',
      farmerId: 'F001',
      farmerName: 'Juan Dela Cruz',
      locationName: 'Sitio Riverside, Biñan',
      latitude: 14.2720,
      longitude: 121.4560,
      landAreaHectares: 2.5,
      tenureStatus: 'Owner',
      cropType: 'Rice',
      barangay: 'Biñan',
    ),
    FarmRecord(
      id: 'FARM002',
      farmerId: 'F002',
      farmerName: 'Maria Santos',
      locationName: 'Buboy High Field',
      latitude: 14.2680,
      longitude: 121.4500,
      landAreaHectares: 1.2,
      tenureStatus: 'Tenant',
      cropType: 'Gulay',
      barangay: 'Buboy',
    ),
    FarmRecord(
      id: 'FARM003',
      farmerId: 'F003',
      farmerName: 'Pedro Penduko',
      locationName: 'Magdapio Hill',
      latitude: 14.2620,
      longitude: 121.4620,
      landAreaHectares: 3.0,
      tenureStatus: 'Owner',
      cropType: 'Prutas',
      barangay: 'Magdapio',
    ),
    FarmRecord(
      id: 'FARM004',
      farmerId: 'F004',
      farmerName: 'Ana Reyes',
      locationName: 'Lambac Plain',
      latitude: 14.2780,
      longitude: 121.4480,
      landAreaHectares: 1.8,
      tenureStatus: 'Lease',
      cropType: 'Rice',
      barangay: 'Lambac',
    ),
    FarmRecord(
      id: 'FARM005',
      farmerId: 'F005',
      farmerName: 'Carlitos Reyes',
      locationName: 'Sampaloc Valley',
      latitude: 14.2810,
      longitude: 121.4600,
      landAreaHectares: 3.2,
      tenureStatus: 'Owner',
      cropType: 'Rice',
      barangay: 'Sampaloc',
    ),
    FarmRecord(
      id: 'FARM006',
      farmerId: 'F006',
      farmerName: 'Elena Gomez',
      locationName: 'Calusiche Riverbank',
      latitude: 14.2750,
      longitude: 121.4520,
      landAreaHectares: 1.5,
      tenureStatus: 'Tenant',
      cropType: 'Gulay',
      barangay: 'Calusiche',
    ),
    FarmRecord(
      id: 'FARM007',
      farmerId: 'F007',
      farmerName: 'Ricardo Dizon',
      locationName: 'Dingin Upland',
      latitude: 14.2830,
      longitude: 121.4650,
      landAreaHectares: 2.0,
      tenureStatus: 'Lease',
      cropType: 'Gulay',
      barangay: 'Dingin',
    ),
    FarmRecord(
      id: 'FARM008',
      farmerId: 'F008',
      farmerName: 'Lucia Mendoza',
      locationName: 'Poblacion Orchard',
      latitude: 14.2790,
      longitude: 121.4570,
      landAreaHectares: 0.9,
      tenureStatus: 'Owner',
      cropType: 'Prutas',
      barangay: 'Poblacion Uno',
    ),
  ];

  // 3. HISTORICAL DATA (Production & Price)
  final List<HistoricalDataRecord> _historicalRecords = [
    HistoricalDataRecord(
      id: 'H001',
      crop: 'Rice',
      year: 2025,
      month: 'October',
      productionMT: 450.5,
      pricePerKg: 23.50,
      uploadedBy: 'Dr. Roberto Mendoza',
      dateUploaded: DateTime.now().subtract(const Duration(days: 30)),
    ),
    HistoricalDataRecord(
      id: 'H002',
      crop: 'Prutas (Banana)',
      year: 2025,
      month: 'November',
      productionMT: 120.0,
      pricePerKg: 45.00,
      uploadedBy: 'Dr. Roberto Mendoza',
      dateUploaded: DateTime.now().subtract(const Duration(days: 20)),
    ),
    HistoricalDataRecord(
      id: 'H003',
      crop: 'Gulay (Talong)',
      year: 2025,
      month: 'December',
      productionMT: 85.2,
      pricePerKg: 55.00,
      uploadedBy: 'Clara Gonzales',
      dateUploaded: DateTime.now().subtract(const Duration(days: 10)),
    ),
    HistoricalDataRecord(
      id: 'H004',
      crop: 'Rice',
      year: 2026,
      month: 'January',
      productionMT: 480.0,
      pricePerKg: 24.00,
      uploadedBy: 'Engr. Arnel Cruz',
      dateUploaded: DateTime.now().subtract(const Duration(days: 2)),
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
  final List<ActivityLogItem> _activityLogs = [
    ActivityLogItem(
      id: 'LOG001',
      user: 'Dr. Roberto Mendoza (Municipal Agriculturist)',
      action: 'ADD',
      module: 'Farmer Records',
      details: 'Registered new farmer: Juan Dela Cruz (Biñan)',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ActivityLogItem(
      id: 'LOG002',
      user: 'Clara Gonzales (Administrative Staff)',
      action: 'UPLOAD',
      module: 'Historical Data',
      details: 'Uploaded MAO Rice Production CSV for Jan 2026',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityLogItem(
      id: 'LOG003',
      user: 'Dr. Roberto Mendoza (Municipal Agriculturist)',
      action: 'RETRAIN',
      module: 'Model Management',
      details: 'Retrained ML Model with 1,250 historical data entries',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // 7. ML MODEL STATUS
  MLModelStatus _modelStatus = MLModelStatus(
    mae: 1.24,
    rmse: 1.85,
    mape: 4.2,
    lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    trainedRecordsCount: 1250,
  );

  // 8. OFFICE POSTS
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
  void addFarmer({
    required String username,
    required String password,
    required String profileName,
    required String barangay,
    required String contactNumber,
    required String organization,
    String status = 'Active',
  }) {
    final newId = 'F00${_farmers.length + 1}';
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
  }

  void updateFarmer(String id, {
    required String profileName,
    required String barangay,
    required String contactNumber,
    required String organization,
    required String status,
  }) {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index].profileName = profileName;
      _farmers[index].barangay = barangay;
      _farmers[index].contactNumber = contactNumber;
      _farmers[index].organization = organization;
      _farmers[index].status = status;
      logActivity(activeUserName, 'EDIT', 'Farmer Records', 'Updated farmer info for $profileName');
      notifyListeners();
    }
  }

  void deleteFarmer(String id) {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      final name = _farmers[index].profileName;
      _farmers.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Farmer Records', 'Deleted farmer $name');
      notifyListeners();
    }
  }

  void setFarmerStatus(String id, String newStatus) {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index].status = newStatus;
      logActivity(activeUserName, 'EDIT', 'Farmer Accounts', 'Set account status of ${_farmers[index].profileName} to $newStatus');
      notifyListeners();
    }
  }

  void resetFarmerPassword(String id, String newPassword) {
    final index = _farmers.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farmers[index].password = newPassword;
      logActivity(activeUserName, 'EDIT', 'Farmer Accounts', 'Reset password for ${_farmers[index].profileName}');
      notifyListeners();
    }
  }

  // FARM RECORDS CRUD
  void addFarmRecord({
    required String farmerId,
    required String farmerName,
    required String locationName,
    required double latitude,
    required double longitude,
    required double landAreaHectares,
    required String tenureStatus,
    required String cropType,
    required String barangay,
  }) {
    final newId = 'FARM00${_farms.length + 1}';
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
  }

  void updateFarmRecord(String id, {
    required String locationName,
    required double landAreaHectares,
    required String tenureStatus,
    required String cropType,
    required String barangay,
    required double latitude,
    required double longitude,
  }) {
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
    }
  }

  void deleteFarmRecord(String id) {
    final index = _farms.indexWhere((f) => f.id == id);
    if (index != -1) {
      _farms.removeAt(index);
      logActivity(activeUserName, 'DELETE', 'Farm Records', 'Deleted farm record $id');
      notifyListeners();
    }
  }

  // HISTORICAL DATA CRUD & CLEANING
  void addHistoricalRecord({
    required String crop,
    required int year,
    required String month,
    required double productionMT,
    required double pricePerKg,
    required String uploadedBy,
  }) {
    final newId = 'H00${_historicalRecords.length + 1}';
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

  void addPost(String title, String content) {
    _posts.insert(0, {
      'title': title,
      'content': content,
      'date': 'Today',
    });
    logActivity(activeUserName, 'POST', 'Announcements', 'Created post: $title');
    notifyListeners();
  }
}
