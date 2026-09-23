import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/myco_calculations.dart';
import '../models/sale_model.dart';

class SalesRepository {
  final FirebaseFirestore? _firestore;
  final List<SaleModel> _localSales = [];
  final _salesController = StreamController<List<SaleModel>>.broadcast();

  SalesRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _localSales.addAll([
      SaleModel(
        id: 'sale_01',
        saleNumber: 'VTE-202609-001',
        date: now.subtract(const Duration(hours: 3)),
        clientId: 'client_01',
        clientName: 'Restaurant Le Cèdre Bleu',
        quantityKg: 8.5,
        pricePerKg: 1200.0, // 8.5 * 1200 = 10 200 DA
        deliveryId: 'deliv_01',
        deliveryPersonId: 'livreur_demo_01',
        deliveryFee: 400.0,
        allocatedProductionCost: 2125.0, // ~250 DA/kg de coût paille+mycélium+énergie
        paymentStatus: PaymentStatus.paid,
        paymentMethod: 'Virement',
        createdBy: 'Directeur d\'Exploitation',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      SaleModel(
        id: 'sale_02',
        saleNumber: 'VTE-202609-002',
        date: now.subtract(const Duration(hours: 1)),
        clientId: 'client_02',
        clientName: 'Pizzeria Bella Vista',
        quantityKg: 5.0,
        pricePerKg: 1100.0, // 5.0 * 1100 = 5 500 DA
        deliveryId: 'deliv_02',
        deliveryPersonId: 'livreur_demo_01',
        deliveryFee: 350.0,
        allocatedProductionCost: 1250.0,
        paymentStatus: PaymentStatus.pending,
        paymentMethod: 'Espèces à la livraison',
        createdBy: 'Directeur d\'Exploitation',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      SaleModel(
        id: 'sale_03',
        saleNumber: 'VTE-202609-003',
        date: now.subtract(const Duration(days: 1)),
        clientId: 'client_03',
        clientName: 'Supermarché Bio Oasis',
        quantityKg: 15.0,
        pricePerKg: 1350.0, // 15.0 * 1350 = 20 250 DA
        deliveryFee: 600.0,
        allocatedProductionCost: 3750.0,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: 'Chèque',
        createdBy: 'Directeur d\'Exploitation',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
    _salesController.add(List.unmodifiable(_localSales));
  }

  Stream<List<SaleModel>> getSalesStream() {
    if (_firestore != null) {
      return _firestore
          .collection('sales')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
              .toList());
    }
    return _salesController.stream;
  }

  Future<SaleModel> recordSale({
    required String clientId,
    required String clientName,
    required double quantityKg,
    required double pricePerKg,
    String? deliveryId,
    String? deliveryPersonId,
    double deliveryFee = 0.0,
    double allocatedProductionCost = 0.0,
    PaymentStatus paymentStatus = PaymentStatus.paid,
    String paymentMethod = 'Espèces',
    String notes = '',
    required String createdBy,
  }) async {
    final now = DateTime.now();
    final saleNumber = 'VTE-${DateFormat('yyyyMM').format(now)}-${(_localSales.length + 1).toString().padLeft(3, '0')}';
    
    final totalRevenue = MycoCalculations.calculateTotalRevenue(
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
    );

    final netMargin = MycoCalculations.calculateNetMargin(
      totalRevenue: totalRevenue,
      deliveryFee: deliveryFee,
      allocatedCosts: allocatedProductionCost,
    );

    final newSale = SaleModel(
      id: 'sale_${now.millisecondsSinceEpoch}',
      saleNumber: saleNumber,
      date: now,
      clientId: clientId,
      clientName: clientName,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      totalRevenue: totalRevenue,
      deliveryId: deliveryId,
      deliveryPersonId: deliveryPersonId,
      deliveryFee: deliveryFee,
      allocatedProductionCost: allocatedProductionCost,
      netMargin: netMargin,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      notes: notes,
      createdBy: createdBy,
      createdAt: now,
    );

    if (_firestore != null) {
      await _firestore.collection('sales').doc(newSale.id).set(newSale.toMap());
    }

    _localSales.insert(0, newSale);
    _salesController.add(List.unmodifiable(_localSales));
    return newSale;
  }

  /// Statistiques financières consolidées pour le Dashboard
  Map<String, dynamic> getFinancialMetrics({DateTime? startDate, DateTime? endDate}) {
    List<SaleModel> filtered = _localSales;
    if (startDate != null) {
      filtered = filtered.where((s) => s.date.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((s) => s.date.isBefore(endDate)).toList();
    }

    final totalRevenue = filtered.fold(0.0, (acc, s) => acc + s.totalRevenue);
    final totalNetMargin = filtered.fold(0.0, (acc, s) => acc + s.netMargin);
    final totalKgSold = filtered.fold(0.0, (acc, s) => acc + s.quantityKg);
    final totalDeliveryFees = filtered.fold(0.0, (acc, s) => acc + s.deliveryFee);

    final averagePricePerKg = totalKgSold > 0 ? totalRevenue / totalKgSold : 0.0;
    final marginRate = totalRevenue > 0 ? (totalNetMargin / totalRevenue) * 100.0 : 0.0;

    return {
      'totalRevenue': totalRevenue,
      'totalNetMargin': totalNetMargin,
      'totalKgSold': totalKgSold,
      'totalDeliveryFees': totalDeliveryFees,
      'averagePricePerKg': averagePricePerKg,
      'marginRate': marginRate,
      'salesCount': filtered.length,
    };
  }
}
