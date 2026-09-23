import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/bag_model.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/delivery_model.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/inventory_movement_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/deliveries_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/production_repository.dart';
import '../../data/repositories/sales_repository.dart';

// Repositories Singletons
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository();
});

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository();
});

final deliveriesRepositoryProvider = Provider<DeliveriesRepository>((ref) {
  return DeliveriesRepository();
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository();
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

// Stream Providers
final authStateProvider = StreamProvider<UserProfileModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final batchesStreamProvider = StreamProvider<List<BatchModel>>((ref) {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.getBatchesStream();
});

final bagsStreamProvider = StreamProvider<List<BagModel>>((ref) {
  final repo = ref.watch(productionRepositoryProvider);
  return repo.getBagsStream();
});

final clientsStreamProvider = StreamProvider<List<ClientModel>>((ref) {
  final repo = ref.watch(clientsRepositoryProvider);
  return repo.getClientsStream();
});

final allDeliveriesStreamProvider = StreamProvider<List<DeliveryModel>>((ref) {
  final repo = ref.watch(deliveriesRepositoryProvider);
  return repo.getAllDeliveriesStream();
});

final myDeliveriesStreamProvider = StreamProvider<List<DeliveryModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final repo = ref.watch(deliveriesRepositoryProvider);
  final userId = user?.uid ?? 'livreur_demo_01';
  return repo.getDeliveryPersonStream(userId);
});

final salesStreamProvider = StreamProvider<List<SaleModel>>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.getSalesStream();
});

final inventoryItemsStreamProvider = StreamProvider<List<InventoryItemModel>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getItemsStream();
});

final inventoryMovementsStreamProvider =
    StreamProvider<List<InventoryMovementModel>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getMovementsStream();
});

// Alertes de stock bas
final lowStockAlertsProvider = Provider<List<InventoryItemModel>>((ref) {
  final items = ref.watch(inventoryItemsStreamProvider).value ?? [];
  return items.where((i) => i.isLowStock).toList();
});

// Statistiques consolidées
final productionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(productionRepositoryProvider);
  // Observer les sacs pour forcer le recalcul si un sac change
  ref.watch(bagsStreamProvider);
  return repo.getProductionStats();
});

final financialMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  ref.watch(salesStreamProvider);
  return repo.getFinancialMetrics();
});
