/// Talaan ng naaning tanim (inilagay ng farmer): totoong ani, presyo ng bentahan at gastos.
class HarvestRecord {
  final String id;
  final String crop; // ID ng pananim, hal. 'Rice'
  final double hectares;
  final DateTime plantedOn;
  final DateTime harvestedOn;
  final double yieldKg;
  final double pricePerKg;

  /// Gastos sa produksyon (PHP). Null kung hindi inilagay.
  final double? costPhp;

  const HarvestRecord({
    required this.id,
    required this.crop,
    required this.hectares,
    required this.plantedOn,
    required this.harvestedOn,
    required this.yieldKg,
    required this.pricePerKg,
    this.costPhp,
  });

  /// Totoong kita = ani x presyo.
  double get income => yieldKg * pricePerKg;

  /// Totoong tubo = kita bawas gastos. Null kung walang gastos.
  double? get profit => costPhp == null ? null : income - costPhp!;

  /// Ani kada ektarya.
  double get kgPerHa => hectares > 0 ? yieldKg / hectares : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop': crop,
    'hectares': hectares,
    'plantedOn': plantedOn.toIso8601String(),
    'harvestedOn': harvestedOn.toIso8601String(),
    'yieldKg': yieldKg,
    'pricePerKg': pricePerKg,
    'costPhp': costPhp,
  };

  factory HarvestRecord.fromJson(Map<String, dynamic> j) => HarvestRecord(
    id: j['id'] as String,
    crop: j['crop'] as String,
    hectares: (j['hectares'] as num).toDouble(),
    plantedOn: DateTime.parse(j['plantedOn'] as String),
    harvestedOn: DateTime.parse(j['harvestedOn'] as String),
    yieldKg: (j['yieldKg'] as num).toDouble(),
    pricePerKg: (j['pricePerKg'] as num).toDouble(),
    costPhp: (j['costPhp'] as num?)?.toDouble(),
  );
}