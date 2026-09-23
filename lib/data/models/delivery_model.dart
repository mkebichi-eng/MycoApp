import '../../core/constants/app_constants.dart';

class DeliveryModel {
  final String id;
  final String deliveryNumber; // ex: LIV-202609-001
  final String saleId;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientAddress;
  final String deliveryPersonId;
  final String deliveryPersonName;
  final double quantityKg;
  final double deliveryFee; // Tarif versé au livreur en DA
  final DeliveryStatus status;
  final DateTime scheduledDate;
  final DateTime? deliveredAt;
  final String deliveryNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryModel({
    required this.id,
    required this.deliveryNumber,
    required this.saleId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientAddress,
    required this.deliveryPersonId,
    required this.deliveryPersonName,
    required this.quantityKg,
    required this.deliveryFee,
    this.status = DeliveryStatus.pending,
    required this.scheduledDate,
    this.deliveredAt,
    this.deliveryNotes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryModel.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryModel(
      id: id,
      deliveryNumber: map['deliveryNumber'] as String? ?? '',
      saleId: map['saleId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      clientPhone: map['clientPhone'] as String? ?? '',
      clientAddress: map['clientAddress'] as String? ?? '',
      deliveryPersonId: map['deliveryPersonId'] as String? ?? '',
      deliveryPersonName: map['deliveryPersonName'] as String? ?? '',
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'pending'),
        orElse: () => DeliveryStatus.pending,
      ),
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.tryParse(map['scheduledDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.tryParse(map['deliveredAt'].toString())
          : null,
      deliveryNotes: map['deliveryNotes'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deliveryNumber': deliveryNumber,
      'saleId': saleId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientAddress': clientAddress,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'quantityKg': quantityKg,
      'deliveryFee': deliveryFee,
      'status': status.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'deliveryNotes': deliveryNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DeliveryModel copyWith({
    DeliveryStatus? status,
    DateTime? deliveredAt,
    String? deliveryNotes,
    DateTime? updatedAt,
  }) {
    return DeliveryModel(
      id: id,
      deliveryNumber: deliveryNumber,
      saleId: saleId,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientAddress: clientAddress,
      deliveryPersonId: deliveryPersonId,
      deliveryPersonName: deliveryPersonName,
      quantityKg: quantityKg,
      deliveryFee: deliveryFee,
      status: status ?? this.status,
      scheduledDate: scheduledDate,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
