import 'package:latlong2/latlong.dart';

import 'farm_record.dart';
export 'farm_record.dart';

class TechnicianFieldLogRecord {
  final String id;
  final String date;
  final String barangay;
  final String farmerName;
  final String cropType;
  final String category;
  final String valueOrVolume;
  final String unitOrPrice;
  String statusOrFindings;
  String status;
  final String technicianName;
  final DateTime createdAt;

  TechnicianFieldLogRecord({
    required this.id,
    required this.date,
    required this.barangay,
    required this.farmerName,
    required this.cropType,
    required this.category,
    required this.valueOrVolume,
    required this.unitOrPrice,
    required this.statusOrFindings,
    required this.status,
    required this.technicianName,
    required this.createdAt,
  });
}

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
  String? birthdate; // e.g. '1990-01-01'
  String? pendingEditJson; // Requested profile edits awaiting Admin approval
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
    this.birthdate = '1990-01-01',
    this.pendingEditJson,
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
  String soilType;

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
    this.soilType = 'Clay Loam',
  });
}

class HistoricalDataRecord {
  final String id;
  int year;
  String? associationName;
  String cropName;
  String? cropVariety;
  String? cropType;
  String? season;
  String? plantingDate;
  String? firstHarvestDate;
  String? lastHarvestDate;
  String? harvestFrequency;
  double? harvestDurationMonths;
  int harvestVolumePieces;
  double farmgatePricePhp;
  double estimatedGrossValuePhp;

  // Backward compatibility getters for UI tables & DSS
  String get crop => cropName;
  String get association => associationName ?? 'PAGRI / MAO';
  String get month {
    if (firstHarvestDate != null && firstHarvestDate!.length >= 7) {
      final dt = DateTime.tryParse(firstHarvestDate!);
      if (dt != null) {
        const monthsList = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        return monthsList[dt.month - 1];
      }
    }
    return 'May';
  }
  double get productionMT => harvestVolumePieces > 0 ? (harvestVolumePieces / 1000.0) : 0.0;
  double get harvestVolumeKg => harvestVolumePieces.toDouble();
  double get pricePerKg => farmgatePricePhp;
  double get grossValuePhp => estimatedGrossValuePhp;
  String get harvestDate => firstHarvestDate ?? plantingDate ?? '';
  String get barangay => 'ALL';
  String get uploadedBy => 'MAO Admin';
  DateTime get dateUploaded => DateTime.now();

  HistoricalDataRecord({
    required this.id,
    required this.year,
    this.associationName,
    required this.cropName,
    this.cropVariety,
    this.cropType,
    this.season,
    this.plantingDate,
    this.firstHarvestDate,
    this.lastHarvestDate,
    this.harvestFrequency,
    this.harvestDurationMonths,
    required this.harvestVolumePieces,
    required this.farmgatePricePhp,
    required this.estimatedGrossValuePhp,
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

