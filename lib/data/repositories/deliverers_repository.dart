import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deliverer_model.dart';

class DeliverersRepository {
  final FirebaseFirestore? _firestore;
  final List<DelivererModel> _localDeliverers = [];
  final _deliverersController = StreamController<List<DelivererModel>>.broadcast();

  DeliverersRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _localDeliverers.addAll([
      DelivererModel(
        id: 'deliv_karim',
        name: 'Karim Meziani',
        phone: '+213551001122',
        vehicle: 'Moto rapide',
        address: '14 Rue Didouche Mourad, Alger',
        defaultFee: 350.0,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      DelivererModel(
        id: 'deliv_yacine',
        name: 'Yacine Dahmani',
        phone: '+213662223344',
        vehicle: 'Kangoo (Gros volume)',
        address: 'Centre Commercial El Qods, Chéraga',
        defaultFee: 500.0,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      DelivererModel(
        id: 'deliv_amine',
        name: 'Amine Benali',
        phone: '+213773334455',
        vehicle: 'Scooter urbain',
        address: 'Coopérative El Feth, Kouba',
        defaultFee: 300.0,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ]);
    _deliverersController.add(List.unmodifiable(_localDeliverers));
  }

  Stream<List<DelivererModel>> getDeliverersStream() {
    if (_firestore != null) {
      return _firestore
          .collection('deliverers')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DelivererModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
    return _deliverersController.stream;
  }

  Future<void> addDeliverer({
    required String name,
    required String phone,
    String vehicle = 'Moto rapide',
    String address = 'Alger',
    double defaultFee = 350.0,
  }) async {
    final newDeliverer = DelivererModel(
      id: 'deliv_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      vehicle: vehicle,
      address: address,
      defaultFee: defaultFee,
      createdAt: DateTime.now(),
    );

    if (_firestore != null) {
      await _firestore.collection('deliverers').doc(newDeliverer.id).set(newDeliverer.toMap());
    } else {
      _localDeliverers.insert(0, newDeliverer);
      _deliverersController.add(List.unmodifiable(_localDeliverers));
    }
  }

  Future<void> updateDeliverer({
    required String id,
    String? name,
    String? phone,
    String? vehicle,
    String? address,
    double? defaultFee,
  }) async {
    if (_firestore != null) {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (vehicle != null) updates['vehicle'] = vehicle;
      if (address != null) updates['address'] = address;
      if (defaultFee != null) updates['defaultFee'] = defaultFee;
      await _firestore.collection('deliverers').doc(id).update(updates);
    } else {
      final index = _localDeliverers.indexWhere((d) => d.id === id);
      if (index != -1) {
        _localDeliverers[index] = _localDeliverers[index].copyWith(
          name: name,
          phone: phone,
          vehicle: vehicle,
          address: address,
          defaultFee: defaultFee,
        );
        _deliverersController.add(List.unmodifiable(_localDeliverers));
      }
    }
  }

  Future<void> deleteDeliverer(String id) async {
    if (_firestore != null) {
      await _firestore.collection('deliverers').doc(id).update({'isActive': false});
    } else {
      _localDeliverers.removeWhere((d) => d.id == id);
      _deliverersController.add(List.unmodifiable(_localDeliverers));
    }
  }
}
