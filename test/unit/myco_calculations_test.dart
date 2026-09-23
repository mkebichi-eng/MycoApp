import 'package:flutter_test/flutter_test.dart';
import 'package:myco_app/core/utils/myco_calculations.dart';

void main() {
  group('MycoCalculations - Tests Unitaires Agronomie & Finances Mycologiques', () {
    test('Calcul de l\'Efficacité Biologique (BE %) pour les pleurotes', () {
      // 50 kg de paille sèche ont produit 37.5 kg de champignons frais
      final be = MycoCalculations.calculateBiologicalEfficiency(
        totalHarvestedKg: 37.5,
        drySubstrateKg: 50.0,
      );
      // BE = (37.5 / 50.0) * 100 = 75.0 %
      expect(be, 75.0);
    });

    test('Calcul du ratio de blanc d\'ensemencement (Spawn Ratio %)', () {
      // 7 kg de mycélium sur 160 kg de paille humide
      final ratio = MycoCalculations.calculateSpawnRatio(
        spawnWeightKg: 7.0,
        wetSubstrateKg: 160.0,
      );
      // Ratio = (7 / 160) * 100 = 4.375 -> 4.38 %
      expect(ratio, 4.38);
    });

    test('Calcul du chiffre d\'affaires brut en DA', () {
      // 8.5 kg vendus à 1 200 DA/kg
      final revenue = MycoCalculations.calculateTotalRevenue(
        quantityKg: 8.5,
        pricePerKg: 1200.0,
      );
      expect(revenue, 10200.0);
    });

    test('Calcul de la Marge Nette en Dinar Algérien (DA)', () {
      // Vente brute : 10 200 DA
      // Frais livreur assigné : 400 DA
      // Coûts de revient alloués (intrants + énergie) : 2 125 DA
      final netMargin = MycoCalculations.calculateNetMargin(
        totalRevenue: 10200.0,
        deliveryFee: 400.0,
        allocatedCosts: 2125.0,
      );
      // Marge = 10 200 - 400 - 2 125 = 7 675 DA
      expect(netMargin, 7675.0);
    });

    test('Détection automatique du seuil d\'alerte de stock critique', () {
      // Seuil d'alerte : 50 unités
      expect(
        MycoCalculations.isStockLow(currentQuantity: 45.0, alertThreshold: 50.0),
        isTrue,
      );
      expect(
        MycoCalculations.isStockLow(currentQuantity: 50.0, alertThreshold: 50.0),
        isTrue,
      );
      expect(
        MycoCalculations.isStockLow(currentQuantity: 55.0, alertThreshold: 50.0),
        isFalse,
      );
    });

    test('Formatage monétaire en Dinar Algérien (DA)', () {
      final formatted = MycoCalculations.formatCurrency(1250.0);
      expect(formatted.contains('DA'), isTrue);
    });
  });
}
