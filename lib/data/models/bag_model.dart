import '../../core/constants/app_constants.dart';

class FlushHarvest {
  final int flushNumber; // 1, 2, 3
  final DateTime date;
  final double weightKg;
  final String harvesterId;

  FlushHarvest({
    required this.flushNumber,
    required this.date,
    required this.weightKg,
    required this.harvesterId,
  });

  factory FlushHarvest.fromMap(Map<String, dynamic> map) {
    return FlushHarvest(
      flushNumber: (map['flushNumber'] as num?)?.toInt() ?? 1,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      harvesterId: map['harvesterId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flushNumber': flushNumber,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'harvesterId': harvesterId,
    };
  }
}

class ContaminationRecord {
  final bool isContaminated;
  final DateTime? detectedAt;
  final ContaminationType? type;
  final String declaredBy;
  final String notes;

  ContaminationRecord({
    this.isContaminated = false,
    this.detectedAt,
    this.type,
    this.declaredBy = '',
    this.notes = '',
  });

  factory ContaminationRecord.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ContaminationRecord();
    return ContaminationRecord(
      isContaminated: map['isContaminated'] as bool? ?? false,
      detectedAt: map['detectedAt'] != null
          ? DateTime.tryParse(map['detectedAt'].toString())
          : null,
      type: map['type'] != null
          ? ContaminationType.values.firstWhere(
              (e) => e.name == map['type'],
              orElse: () => ContaminationType.other,
            )
          : null,
      declaredBy: map['declaredBy'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isContaminated': isContaminated,
      'detectedAt': detectedAt?.toIso8601String(),
      'type': type?.name,
      'declaredBy': declaredBy,
      'notes': notes,
    };
  }
}

class BagModel {
  final String id;
  final String qrCode; // ex: MYCO-BAG-10293
  final String batchId;
  final String batchCode;
  final String strain;
  final double weightKg;
  final String roomLocation; // ex: Salle Incubation 1, Chambre Fruitière B
  final BagStatus status;
  final DateTime spawningDate;
  final int incubationDays;
  final DateTime? fruitingDate;
  final List<FlushHarvest> harvests;
  final double totalHarvestedKg;
  final double biologicalEfficiencyPercent;
  final ContaminationRecord contamination;
  final DateTime updatedAt;

  BagModel({
    required this.id,
    required this.qrCode,
    required this.batchId,
    required this.batchCode,
    required this.strain,
    this.weightKg = 5.0,
    this.roomLocation = 'Salle Incubation',
    this.status = BagStatus.incubating,
    required this.spawningDate,
    this.incubationDays = 18,
    this.fruitingDate,
    this.harvests = const [],
    this.totalHarvestedKg = 0.0,
    this.biologicalEfficiencyPercent = 0.0,
    ContaminationRecord? contamination,
    required this.updatedAt,
  }) : contamination = contamination ?? ContaminationRecord();

  factory BagModel.fromMap(Map<String, dynamic> map, String id) {
    final rawHarvests = map['harvests'] as List<dynamic>? ?? [];
    final parsedHarvests = rawHarvests
        .map((h) => FlushHarvest.fromMap(h as Map<String, dynamic>))
        .toList();

    return BagModel(
      id: id,
      qrCode: map['qrCode'] as String? ?? '',
      batchId: map['batchId'] as String? ?? '',
      batchCode: map['batchCode'] as String? ?? '',
      strain: map['strain'] as String? ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 5.0,
      roomLocation: map['roomLocation'] as String? ?? 'Salle Incubation',
      status: BagStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'incubating'),
        orElse: () => BagStatus.incubating,
      ),
      spawningDate: map['spawningDate'] != null
          ? DateTime.tryParse(map['spawningDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      incubationDays: (map['incubationDays'] as num?)?.toInt() ?? 18,
      fruitingDate: map['fruitingDate'] != null
          ? DateTime.tryParse(map['fruitingDate'].toString())
          : null,
      harvests: parsedHarvests,
      totalHarvestedKg: (map['totalHarvestedKg'] as num?)?.toDouble() ?? 0.0,
      biologicalEfficiencyPercent:
          (map['biologicalEfficiencyPercent'] as num?)?.toDouble() ?? 0.0,
      contamination: ContaminationRecord.fromMap(
          map['contamination'] as Map<String, dynamic>?),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qrCode': qrCode,
      'batchId': batchId,
      'batchCode': batchCode,
      'strain': strain,
      'weightKg': weightKg,
      'roomLocation': roomLocation,
      'status': status.name,
      'spawningDate': spawningDate.toIso8601String(),
      'incubationDays': incubationDays,
      'fruitingDate': fruitingDate?.toIso8601String(),
      'harvests': harvests.map((h) => h.toMap()).toList(),
      'totalHarvestedKg': totalHarvestedKg,
      'biologicalEfficiencyPercent': biologicalEfficiencyPercent,
      'contamination': contamination.toMap(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BagModel copyWith({
    BagStatus? status,
    String? roomLocation,
    DateTime? fruitingDate,
    List<FlushHarvest>? harvests,
    double? totalHarvestedKg,
    double? biologicalEfficiencyPercent,
    ContaminationRecord? contamination,
    DateTime? updatedAt,
  }) {
    return BagModel(
      id: id,
      qrCode: qrCode,
      batchId: batchId,
      batchCode: batchCode,
      strain: strain,
      weightKg: weightKg,
      roomLocation: roomLocation ?? this.roomLocation,
      status: status ?? this.status,
      spawningDate: spawningDate,
      incubationDays: incubationDays,
      fruitingDate: fruitingDate ?? this.fruitingDate,
      harvests: harvests ?? this.harvests,
      totalHarvestedKg: totalHarvestedKg ?? this.totalHarvestedKg,
      biologicalEfficiencyPercent:
          biologicalEfficiencyPercent ?? this.biologicalEfficiencyPercent,
      contamination: contamination ?? this.contamination,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
