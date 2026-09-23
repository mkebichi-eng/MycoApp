import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/delivery_model.dart';

class DeliveriesRepository {
  final FirebaseFirestore? _firestore;
  final List<DeliveryModel> _localDeliveries = [];
  final _deliveriesController = StreamController<List<DeliveryModel>>.broadcast();

  DeliveriesRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _localDeliveries.addAll([
      DeliveryModel(
        id: 'deliv_01',
        deliveryNumber: 'LIV-202609-001',
        saleId: 'sale_01',
        clientId: 'client_01',
        clientName: 'Restaurant Le Cèdre Bleu',
        clientPhone: '+213550112233',
        clientAddress: '14 Rue Didouche Mourad, Alger Centre',
        deliveryPersonId: 'livreur_demo_01',
        deliveryPersonName: 'Yacine Livreur',
        quantityKg: 8.5,
        deliveryFee: 400.0, // 400 DA de forfait course
        status: DeliveryStatus.inTransit,
        scheduledDate: now,
        deliveryNotes: 'Déposer à l\'entrée cuisine arrière.',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      DeliveryModel(
        id: 'deliv_02',
        deliveryNumber: 'LIV-202609-002',
        saleId: 'sale_02',
        clientId: 'client_02',
        clientName: 'Pizzeria Bella Vista',
        clientPhone: '+213661445566',
        clientAddress: '8 Boulevard Colonel Amirouche, Alger',
        deliveryPersonId: 'livreur_demo_01',
        deliveryPersonName: 'Yacine Livreur',
        quantityKg: 5.0,
        deliveryFee: 350.0,
        status: DeliveryStatus.pending,
        scheduledDate: now,
        deliveryNotes: 'Appeler 10 min avant d\'arriver.',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    _deliveriesController.add(List.unmodifiable(_localDeliveries));
  }

  /// Flux de toutes les livraisons (Admin & Responsable)
  Stream<List<DeliveryModel>> getAllDeliveriesStream() {
    if (_firestore != null) {
      return _firestore
          .collection('deliveries')
          .orderBy('scheduledDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DeliveryModel.fromMap(doc.data(), doc.id))
              .toList());
    }
    return _deliveriesController.stream;
  }

  /// Flux restreint pour le livreur connecté (sécurité et ergonomie épurée)
  Stream<List<DeliveryModel>> getDeliveryPersonStream(String deliveryPersonId) {
    if (_firestore != null) {
      return _firestore
          .collection('deliveries')
          .where('deliveryPersonId', isEqualTo: deliveryPersonId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DeliveryModel.fromMap(doc.data(), doc.id))
              .toList());
    }
    return _deliveriesController.stream.map((list) =>
        list.where((d) => d.deliveryPersonId == deliveryPersonId).toList());
  }

  /// Création d'une course de livraison
  Future<DeliveryModel> createDelivery(DeliveryModel delivery) async {
    if (_firestore != null) {
      await _firestore.collection('deliveries').doc(delivery.id).set(delivery.toMap());
    }
    _localDeliveries.insert(0, delivery);
    _deliveriesController.add(List.unmodifiable(_localDeliveries));
    return delivery;
  }

  /// Mise à jour du statut par le livreur en 1 tap (ex: En transit -> Livré)
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required DeliveryStatus status,
    String? notes,
  }) async {
    final now = DateTime.now();
    if (_firestore != null) {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': now.toIso8601String(),
      };
      if (status == DeliveryStatus.delivered) {
        updates['deliveredAt'] = now.toIso8601String();
      }
      if (notes != null) {
        updates['deliveryNotes'] = notes;
      }
      await _firestore.collection('deliveries').doc(deliveryId).update(updates);
    }

    final index = _localDeliveries.indexWhere((d) => d.id == deliveryId);
    if (index != -1) {
      _localDeliveries[index] = _localDeliveries[index].copyWith(
        status: status,
        deliveredAt: status == DeliveryStatus.delivered ? now : null,
        deliveryNotes: notes ?? _localDeliveries[index].deliveryNotes,
        updatedAt: now,
      );
      _deliveriesController.add(List.unmodifiable(_localDeliveries));
    }
  }
}
