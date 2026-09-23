import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';

class SaleModel {
  final String id;
  final String saleNumber; // ex: VTE-202609-001
  final DateTime date;
  final String clientId;
  final String clientName;
  final double quantityKg;
  final double pricePerKg; // en DA
  final double totalRevenue; // quantityKg * pricePerKg en DA
  final String? deliveryId;
  final String? deliveryPersonId;
  final double deliveryFee; // en DA
  final double allocatedProductionCost; // Coûts alloués (paille, mycélium, électricité) en DA
  final double netMargin; // totalRevenue - deliveryFee - allocatedProductionCost
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final String notes;
  final String createdBy;
  final DateTime createdAt;

  SaleModel({
    required this.id,
    required this.saleNumber,
    required this.date,
    required this.clientId,
    required this.clientName,
    required this.quantityKg,
    required this.pricePerKg,
    double? totalRevenue,
    this.deliveryId,
    this.deliveryPersonId,
    this.deliveryFee = 0.0,
    this.allocatedProductionCost = 0.0,
    double? netMargin,
    this.paymentStatus = PaymentStatus.paid,
    this.paymentMethod = 'Espèces',
    this.notes = '',
    required this.createdBy,
    required this.createdAt,
  })  : totalRevenue = totalRevenue ??
            MycoCalculations.calculateTotalRevenue(
                quantityKg: quantityKg, pricePerKg: pricePerKg),
        netMargin = netMargin ??
            MycoCalculations.calculateNetMargin(
              totalRevenue: totalRevenue ??
                  MycoCalculations.calculateTotalRevenue(
                      quantityKg: quantityKg, pricePerKg: pricePerKg),
              deliveryFee: deliveryFee,
              allocatedCosts: allocatedProductionCost,
            );

  factory SaleModel.fromMap(Map<String, dynamic> map, String id) {
    return SaleModel(
      id: id,
      saleNumber: map['saleNumber'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      quantityKg: (map['quantityKg'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble(),
      deliveryId: map['deliveryId'] as String?,
      deliveryPersonId: map['deliveryPersonId'] as String?,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      allocatedProductionCost:
          (map['allocatedProductionCost'] as num?)?.toDouble() ?? 0.0,
      netMargin: (map['netMargin'] as num?)?.toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['paymentStatus'] as String? ?? 'paid'),
        orElse: () => PaymentStatus.paid,
      ),
      paymentMethod: map['paymentMethod'] as String? ?? 'Espèces',
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
      'saleNumber': saleNumber,
      'date': date.toIso8601String(),
      'clientId': clientId,
      'clientName': clientName,
      'quantityKg': quantityKg,
      'pricePerKg': pricePerKg,
      'totalRevenue': totalRevenue,
      'deliveryId': deliveryId,
      'deliveryPersonId': deliveryPersonId,
      'deliveryFee': deliveryFee,
      'allocatedProductionCost': allocatedProductionCost,
      'netMargin': netMargin,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
