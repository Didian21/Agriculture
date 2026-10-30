enum PlotStatus { harvested, growing }

class FarmerProfile {
  final String name;
  final String barangay;
  final double landSizeHectares;
  final List<String> cropTypes;

  const FarmerProfile({
    required this.name,
    required this.barangay,
    required this.landSizeHectares,
    required this.cropTypes,
  });
}

/// One piece of the farmer's land and what is on it.
class FarmPlot {
  final String crop; // ID ng pananim, hal. 'Rice'
  final double hectares;
  final PlotStatus status;

  const FarmPlot({
    required this.crop,
    required this.hectares,
    required this.status,
  });
}

class CropRecord {
  final String crop;
  final DateTime datePlanted;
  final DateTime? dateHarvested;
  final double yieldKg;

  const CropRecord({
    required this.crop,
    required this.datePlanted,
    this.dateHarvested,
    required this.yieldKg,
  });

  bool get isHarvested => dateHarvested != null;
}