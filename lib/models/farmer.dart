import 'package:latlong2/latlong.dart';

class Farmer {
  final String id;
  final String username;
  String password;
  String profileName;
  String barangay;
  String contactNumber;
  String organization;
  String status; // 'Active', 'Pending', 'Deactivated'
  String? employerName; // Landowner / Employer for Hired Farmworkers
  final List<String> records;

  Farmer({
    required this.id,
    required this.username,
    required this.password,
    required this.profileName,
    this.barangay = 'Biñan',
    this.contactNumber = '09171234567',
    this.organization = 'Pagsanjan Farmers Association',
    this.status = 'Active',
    this.employerName,
    this.records = const [],
  });
}

class FarmRecord {
  final String id;
  final String farmerId;
  final String farmerName;
  String locationName;
  double latitude;
  double longitude;
  double landAreaHectares;
  String tenureStatus; // 'Owner', 'Tenant', 'Lease', 'CLT', 'Hired Farmworkers'
  String cropType; // 'Rice', 'Prutas', 'Gulay'
  String barangay;
  String? landownerId;
  String? landownerName;
  List<LatLng> boundaryPoints;

  FarmRecord({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.landAreaHectares,
    required this.tenureStatus,
    required this.cropType,
    required this.barangay,
    this.landownerId,
    this.landownerName,
    this.boundaryPoints = const [],
  });
}

class HistoricalDataRecord {
  final String id;
  String crop;
  int year;
  String month;
  String barangay;
  double productionMT; // Metric Tons
  double pricePerKg; // PHP
  String uploadedBy;
  DateTime dateUploaded;

  HistoricalDataRecord({
    required this.id,
    required this.crop,
    required this.year,
    required this.month,
    this.barangay = 'ALL',
    required this.productionMT,
    required this.pricePerKg,
    required this.uploadedBy,
    required this.dateUploaded,
  });
}

class CropPlantingReq {
  final String id;
  String cropName;
  String cropCategory; // 'Rice', 'Prutas', 'Gulay'
  double minTemp;
  double maxTemp;
  double minRainfallMm;
  double maxRainfallMm;
  String suitableMonths;

  CropPlantingReq({
    required this.id,
    required this.cropName,
    required this.cropCategory,
    required this.minTemp,
    required this.maxTemp,
    required this.minRainfallMm,
    required this.maxRainfallMm,
    required this.suitableMonths,
  });
}

class AdminStaff {
  final String id;
  String name;
  String username;
  String email;
  String role; // 'Municipal Agriculturist', 'Administrative Staff', 'Agricultural Technician', 'Main Admin'
  String status; // 'Active', 'Inactive'
  String password;

  AdminStaff({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.status = 'Active',
    this.password = 'admin123',
  });
}

class ActivityLogItem {
  final String id;
  final String user;
  final String action; // 'ADD', 'EDIT', 'DELETE', 'RETRAIN', 'EXPORT'
  final String module;
  final String details;
  final DateTime timestamp;

  ActivityLogItem({
    required this.id,
    required this.user,
    required this.action,
    required this.module,
    required this.details,
    required this.timestamp,
  });
}

class MLModelStatus {
  double mae;
  double rmse;
  double mape;
  DateTime lastUpdated;
  int trainedRecordsCount;
  bool isTraining;

  MLModelStatus({
    required this.mae,
    required this.rmse,
    required this.mape,
    required this.lastUpdated,
    required this.trainedRecordsCount,
    this.isTraining = false,
  });
}

class MarketPriceRecord {
  final String id;
  String vegetable;
  double farmgatePrice; // PHP per kg
  double marketPrice; // PHP per kg
  DateTime date;
  String marketLocation; // Barangay or Market Name
  String uploadedBy;

  MarketPriceRecord({
    required this.id,
    required this.vegetable,
    required this.farmgatePrice,
    required this.marketPrice,
    required this.date,
    this.marketLocation = 'Pagsanjan Public Market',
    required this.uploadedBy,
  });
}

