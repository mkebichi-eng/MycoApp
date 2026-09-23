import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class MycoCalculations {
  /// Calcule l'Efficacité Biologique (Biological Efficiency - BE en %)
  /// BE = (Poids total de champignons frais récoltés / Poids de paille sèche initiale) * 100
  static double calculateBiologicalEfficiency({
    required double totalHarvestedKg,
    required double drySubstrateKg,
  }) {
    if (drySubstrateKg <= 0) return 0.0;
    final be = (totalHarvestedKg / drySubstrateKg) * 100.0;
    return double.parse(be.toStringAsFixed(2));
  }

  /// Calcule le ratio de blanc de grain (spawn ratio en %)
  /// Ratio = (Poids du mycélium / Poids du substrat humide pasteurisé) * 100
  static double calculateSpawnRatio({
    required double spawnWeightKg,
    required double wetSubstrateKg,
  }) {
    if (wetSubstrateKg <= 0) return 0.0;
    final ratio = (spawnWeightKg / wetSubstrateKg) * 100.0;
    return double.parse(ratio.toStringAsFixed(2));
  }

  /// Calcule le chiffre d'affaires brut d'une vente
  static double calculateTotalRevenue({
    required double quantityKg,
    required double pricePerKg,
  }) {
    if (quantityKg <= 0 || pricePerKg <= 0) return 0.0;
    return double.parse((quantityKg * pricePerKg).toStringAsFixed(2));
  }

  /// Calcule la marge nette réelle
  /// Marge = (Quantité * Prix Client) - Tarif Livreur - Coûts alloués (intrants/énergie)
  static double calculateNetMargin({
    required double totalRevenue,
    required double deliveryFee,
    required double allocatedCosts,
  }) {
    final margin = totalRevenue - deliveryFee - allocatedCosts;
    return double.parse(margin.toStringAsFixed(2));
  }

  /// Vérifie si un article a atteint ou dépassé son seuil d'alerte critique
  static bool isStockLow({
    required double currentQuantity,
    required double alertThreshold,
  }) {
    return currentQuantity <= alertThreshold;
  }

  /// Formatage d'un montant en Dinar Algérien (DA)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(amount)} ${AppConstants.currency}';
  }

  /// Formatage d'un poids en Kilogrammes (kg)
  static String formatWeight(double weightKg) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return '${formatter.format(weightKg)} kg';
  }

  /// Formatage d'un pourcentage
  static String formatPercent(double percent) {
    return '${percent.toStringAsFixed(1)} %';
  }
}
