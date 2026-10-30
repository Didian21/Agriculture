/// Tanim na inilagay mismo ng magsasaka (pananim, sukat ng lupa, petsa, dami ng ani).
class FarmPlanting {
  final String id;
  final String crop; // ID ng pananim, hal. 'Rice', 'String beans'
  final double hectares;
  final DateTime plantedOn;

  /// Dami ng ani (kg) mula sa huling ani - opsyonal. Ginagamit ng DSS para mas tumpak ang tantiya.
  final double? lastYieldKg;

  const FarmPlanting({
    required this.id,
    required this.crop,
    required this.hectares,
    required this.plantedOn,
    this.lastYieldKg,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop': crop,
    'hectares': hectares,
    'plantedOn': plantedOn.toIso8601String(),
    'lastYieldKg': lastYieldKg,
  };

  factory FarmPlanting.fromJson(Map<String, dynamic> j) => FarmPlanting(
    id: j['id'] as String,
    crop: j['crop'] as String,
    hectares: (j['hectares'] as num).toDouble(),
    plantedOn: DateTime.parse(j['plantedOn'] as String),
    lastYieldKg: (j['lastYieldKg'] as num?)?.toDouble(),
  );
}