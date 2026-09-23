import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';

class ClientsRepository {
  final FirebaseFirestore? _firestore;
  final List<ClientModel> _localClients = [];
  final _clientsController = StreamController<List<ClientModel>>.broadcast();

  ClientsRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _localClients.addAll([
      ClientModel(
        id: 'client_01',
        name: 'Restaurant Le Cèdre Bleu',
        contactPerson: 'Chef Youssef',
        phone: '+213550112233',
        address: '14 Rue Didouche Mourad',
        city: 'Alger',
        presetPricePerKg: 1200.0, // 1 200 DA/kg
        notes: 'Commande fixe de 10 kg chaque mardi matin.',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      ClientModel(
        id: 'client_02',
        name: 'Pizzeria Bella Vista',
        contactPerson: 'Sofiane',
        phone: '+213661445566',
        address: '8 Boulevard Colonel Amirouche',
        city: 'Alger',
        presetPricePerKg: 1100.0, // 1 100 DA/kg
        notes: 'Préfère les petits chapeaux fermes pour pizzas.',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      ClientModel(
        id: 'client_03',
        name: 'Supermarché Bio Oasis',
        contactPerson: 'Mme Meriem',
        phone: '+213770778899',
        address: 'Centre Commercial El Qods, Chéraga',
        city: 'Chéraga',
        presetPricePerKg: 1350.0, // 1 350 DA/kg barquettes
        notes: 'Livraison en barquettes perforées de 250g.',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ]);
    _clientsController.add(List.unmodifiable(_localClients));
  }

  Stream<List<ClientModel>> getClientsStream() {
    if (_firestore != null) {
      return _firestore
          .collection('clients')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
              .toList());
    }
    return _clientsController.stream;
  }

  Future<ClientModel?> getClientById(String id) async {
    if (_firestore != null) {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ClientModel.fromMap(doc.data()!, doc.id);
      }
    }
    try {
      return _localClients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ClientModel> addClient(ClientModel client) async {
    if (_firestore != null) {
      await _firestore.collection('clients').doc(client.id).set(client.toMap());
    }
    _localClients.add(client);
    _clientsController.add(List.unmodifiable(_localClients));
    return client;
  }

  Future<void> updateClient(ClientModel client) async {
    if (_firestore != null) {
      await _firestore.collection('clients').doc(client.id).update(client.toMap());
    }
    final index = _localClients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _localClients[index] = client;
      _clientsController.add(List.unmodifiable(_localClients));
    }
  }

  Future<void> deleteClient(String id) async {
    if (_firestore != null) {
      // Désactivation logique pour garder l'intégrité de l'historique
      await _firestore.collection('clients').doc(id).update({'isActive': false});
    }
    _localClients.removeWhere((c) => c.id == id);
    _clientsController.add(List.unmodifiable(_localClients));
  }
}
