import 'package:flutter_test/flutter_test.dart';
import 'package:myco_app/core/constants/app_constants.dart';
import 'package:myco_app/data/models/delivery_model.dart';

void main() {
  group('Sécurité des Rôles & Intégrité Livreur', () {
    test('Conversion stricte des rôles depuis Firestore string', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('production_manager'), UserRole.productionManager);
      expect(UserRole.fromString('delivery_person'), UserRole.deliveryPerson);
      // Fallback sécurisé en cas de chaîne inattendue : livreur par défaut (moindre privilège)
      expect(UserRole.fromString('unknown_role'), UserRole.deliveryPerson);
    });

    test('Le modèle DeliveryModel ne contient aucun champ de marge ni de coût de revient', () {
      final now = DateTime.now();
      final delivery = DeliveryModel(
        id: 'deliv_test',
        deliveryNumber: 'LIV-001',
        saleId: 'sale_001',
        clientId: 'client_001',
        clientName: 'Resto Test',
        clientPhone: '+213550000000',
        clientAddress: 'Alger Centre',
        deliveryPersonId: 'livreur_01',
        deliveryPersonName: 'Yacine',
        quantityKg: 5.0,
        deliveryFee: 350.0,
        scheduledDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final map = delivery.toMap();

      // Vérification d'étanchéité : aucun prix de vente ni coût n'est exposé au livreur
      expect(map.containsKey('totalRevenue'), isFalse);
      expect(map.containsKey('pricePerKg'), isFalse);
      expect(map.containsKey('netMargin'), isFalse);
      expect(map.containsKey('allocatedProductionCost'), isFalse);
      expect(map['deliveryFee'], 350.0);
    });
  });
}
