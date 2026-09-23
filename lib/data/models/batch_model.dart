import '../../core/constants/app_constants.dart';

class BatchModel {
  final String id;
  final String batchCode; // ex: LOT-2026-09-01
  final DateTime pasteurizationDate;
  final double strawDryWeightKg;
  final double strawWetWeightKg;
  final String spawnStrain; // ex: Pleurote Gris HK35
  final double spawnWeightKg;
  final double spawnRatioPercent;
  final int totalBagsPlanned;
  final int totalBagsCreated;
  final BatchStatus status;
  final String notes;
  final String createdBy;
  final DateTime createdAt;

  BatchModel({
    required this.id,
    required this.batchCode,
    required this.pasteurizationDate,
    required this.strawDryWeightKg,
    required this.strawWetWeightKg,
    required this.spawnStrain,
    required this.spawnWeightKg,
    required this.spawnRatioPercent,
    required this.totalBagsPlanned,
    this.totalBagsCreated = 0,
    this.status = BatchStatus.preparation,
    this.notes = '',
    required this.createdBy,
    required this.createdAt,
  });

  factory BatchModel.fromMap(Map<String, dynamic> map, String id) {
    return BatchModel(
      id: id,
      batchCode: map['batchCode'] as String? ?? '',
      pasteurizationDate: map['pasteurizationDate'] != null
          ? DateTime.tryParse(map['pasteurizationDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      strawDryWeightKg: (map['strawDryWeightKg'] as num?)?.toDouble() ?? 0.0,
      strawWetWeightKg: (map['strawWetWeightKg'] as num?)?.toDouble() ?? 0.0,
      spawnStrain: map['spawnStrain'] as String? ?? '',
      spawnWeightKg: (map['spawnWeightKg'] as num?)?.toDouble() ?? 0.0,
      spawnRatioPercent: (map['spawnRatioPercent'] as num?)?.toDouble() ?? 0.0,
      totalBagsPlanned: (map['totalBagsPlanned'] as num?)?.toInt() ?? 0,
      totalBagsCreated: (map['totalBagsCreated'] as num?)?.toInt() ?? 0,
      status: BatchStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'preparation'),
        orElse: () => BatchStatus.preparation,
      ),
      notes: map['notes'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchCode': batchCode,
      'pasteurizationDate': pasteurizationDate.toIso8601String(),
      'strawDryWeightKg': strawDryWeightKg,
      'strawWetWeightKg': strawWetWeightKg,
      'spawnStrain': spawnStrain,
      'spawnWeightKg': spawnWeightKg,
      'spawnRatioPercent': spawnRatioPercent,
      'totalBagsPlanned': totalBagsPlanned,
      'totalBagsCreated': totalBagsCreated,
      'status': status.name,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BatchModel copyWith({
    int? totalBagsCreated,
    BatchStatus? status,
    String? notes,
  }) {
    return BatchModel(
      id: id,
      batchCode: batchCode,
      pasteurizationDate: pasteurizationDate,
      strawDryWeightKg: strawDryWeightKg,
      strawWetWeightKg: strawWetWeightKg,
      spawnStrain: spawnStrain,
      spawnWeightKg: spawnWeightKg,
      spawnRatioPercent: spawnRatioPercent,
      totalBagsPlanned: totalBagsPlanned,
      totalBagsCreated: totalBagsCreated ?? this.totalBagsCreated,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
