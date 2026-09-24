import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/myco_calculations.dart';
import '../models/expense_model.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_movement_model.dart';

class InventoryRepository {
  final FirebaseFirestore? _firestore;
  final List<InventoryItemModel> _localItems = [];
  final List<InventoryMovementModel> _localMovements = [];
  final List<ExpenseModel> _localExpenses = [];
  final _itemsController = StreamController<List<InventoryItemModel>>.broadcast();
  final _movementsController = StreamController<List<InventoryMovementModel>>.broadcast();
  final _expensesController = StreamController<List<ExpenseModel>>.broadcast();

  InventoryRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _localItems.addAll([
      InventoryItemModel(
        id: 'item_straw',
        name: 'Paille de blé hachée',
        category: 'raw_material',
        currentStock: 180.0,
        unit: 'kg',
        alertThreshold: 50.0,
        unitCost: 35.0, // 35 DA/kg
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      InventoryItemModel(
        id: 'item_spawn',
        name: 'Blanc de Pleurote HK35 (Seigle mycélié)',
        category: 'spawn',
        currentStock: 14.0,
        unit: 'kg',
        alertThreshold: 10.0,
        unitCost: 650.0, // 650 DA/kg
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      InventoryItemModel(
        id: 'item_bags',
        name: 'Sacs de culture micro-perforés 5kg',
        category: 'consumable',
        currentStock: 45.0,
        unit: 'unités',
        alertThreshold: 50.0, // ALERTE CRITIQUE : 45 <= 50 !
        unitCost: 25.0,
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      InventoryItemModel(
        id: 'item_alcohol',
        name: 'Alcool à 70° (Désinfection tables/outils)',
        category: 'sanitation',
        currentStock: 12.0,
        unit: 'Litres',
        alertThreshold: 5.0,
        unitCost: 450.0,
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      InventoryItemModel(
        id: 'item_disinfectant',
        name: 'Produit décontamination sol/chambre',
        category: 'sanitation',
        currentStock: 3.5,
        unit: 'Litres',
        alertThreshold: 4.0, // ALERTE CRITIQUE : 3.5 <= 4.0 !
        unitCost: 1200.0,
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ]);

    _localMovements.add(
      InventoryMovementModel(
        id: 'mvt_001',
        itemId: 'item_straw',
        itemName: 'Paille de blé hachée',
        type: MovementType.stockOut,
        quantity: 50.0,
        previousStock: 230.0,
        newStock: 180.0,
        reason: 'Pasteurisation Lot LOT-2026-09-01 (Fût 200L)',
        referenceBatchId: 'LOT-2026-09-01',
        performedBy: 'Karim Responsable',
        timestamp: now.subtract(const Duration(days: 20)),
      ),
    _localExpenses.addAll([
      ExpenseModel(
        id: 'exp_01',
        label: 'Achat paille de blé hachée',
        amount: 4500.0,
        category: 'Matière première (Paille/Blanc)',
        quantity: 300.0,
        unit: 'kg',
        unitPrice: 15.0,
        isStockable: true,
        stockItemId: 'item_straw',
        supplier: 'Ferme Blida',
        date: now.subtract(const Duration(days: 9)),
      ),
      ExpenseModel(
        id: 'exp_02',
        label: 'Alcool à 70° & désinfectant',
        amount: 2625.0,
        category: 'Sanitation & Hygiène',
        quantity: 5.0,
        unit: 'Litres',
        unitPrice: 525.0,
        isStockable: true,
        stockItemId: 'item_alcohol',
        supplier: 'Pharmacie Pro',
        date: now.subtract(const Duration(days: 6)),
      ),
      ExpenseModel(
        id: 'exp_03',
        label: 'Carburant livraison Alger Centre',
        amount: 1200.0,
        category: 'Transport & Carburant',
        quantity: 1.0,
        unit: 'forfait',
        unitPrice: 1200.0,
        isStockable: false,
        stockItemId: null,
        supplier: 'Naftal',
        date: now.subtract(const Duration(days: 3)),
      ),
    ]);

    _itemsController.add(List.unmodifiable(_localItems));
    _movementsController.add(List.unmodifiable(_localMovements));
    _expensesController.add(List.unmodifiable(_localExpenses));
  }

  Stream<List<InventoryItemModel>> getItemsStream() {
    if (_firestore != null) {
      return _firestore.collection('inventory_items').snapshots().map((snapshot) =>
          snapshot.docs
              .map((doc) => InventoryItemModel.fromMap(doc.data(), doc.id))
              .toList());
    }
    return _itemsController.stream;
  }

  Stream<List<InventoryMovementModel>> getMovementsStream({String? itemId}) {
    if (_firestore != null) {
      Query query = _firestore.collection('inventory_movements');
      if (itemId != null) {
        query = query.where('itemId', isEqualTo: itemId);
      }
      return query.orderBy('timestamp', descending: true).snapshots().map((snapshot) =>
          snapshot.docs
              .map((doc) => InventoryMovementModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList());
    }
    return _movementsController.stream.map((list) {
      if (itemId == null) return list;
      return list.where((m) => m.itemId == itemId).toList();
    });
  }

  /// Liste des articles en état critique sous le seuil d'alerte
  List<InventoryItemModel> getLowStockAlerts() {
    return _localItems.where((i) => i.isLowStock).toList();
  }

  /// Enregistrement d'un mouvement de stock (Entrée ou Sortie)
  Future<void> recordMovement({
    required String itemId,
    required MovementType type,
    required double quantity,
    required String reason,
    String? referenceBatchId,
    required String performedBy,
  }) async {
    final index = _localItems.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Article de stock introuvable.');

    final item = _localItems[index];
    final previousStock = item.currentStock;
    double newStock = previousStock;

    if (type == MovementType.stockIn) {
      newStock += quantity;
    } else {
      newStock -= quantity;
      if (newStock < 0) newStock = 0;
    }

    final isLow = MycoCalculations.isStockLow(
      currentQuantity: newStock,
      alertThreshold: item.alertThreshold,
    );

    final updatedItem = item.copyWith(
      currentStock: newStock,
      updatedAt: DateTime.now(),
    );

    final movement = InventoryMovementModel(
      id: 'mvt_${DateTime.now().millisecondsSinceEpoch}',
      itemId: item.id,
      itemName: item.name,
      type: type,
      quantity: quantity,
      previousStock: previousStock,
      newStock: newStock,
      reason: reason,
      referenceBatchId: referenceBatchId,
      performedBy: performedBy,
      timestamp: DateTime.now(),
    );

    _localItems[index] = updatedItem;
    _localMovements.insert(0, movement);

    _itemsController.add(List.unmodifiable(_localItems));
    _movementsController.add(List.unmodifiable(_localMovements));

    if (_firestore != null) {
      await _firestore.collection('inventory_items').doc(itemId).update({
        'currentStock': newStock,
        'isLowStock': isLow,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _firestore
          .collection('inventory_movements')
          .doc(movement.id)
          .set(movement.toMap());
    }
  }

  Future<void> addItem(InventoryItemModel item) async {
    if (_firestore != null) {
      await _firestore.collection('inventory_items').doc(item.id).set(item.toMap());
    }
    _localItems.add(item);
    _itemsController.add(List.unmodifiable(_localItems));
  }

  Future<void> deleteItem(String id) async {
    if (_firestore != null) {
      await _firestore.collection('inventory_items').doc(id).delete();
    }
    _localItems.removeWhere((i) => i.id == id);
    _itemsController.add(List.unmodifiable(_localItems));
  }

  Stream<List<ExpenseModel>> getExpensesStream() {
    return _expensesController.stream;
  }

  List<ExpenseModel> getLocalExpenses() => List.unmodifiable(_localExpenses);

  Future<void> addExpense(ExpenseModel expense) async {
    _localExpenses.insert(0, expense);
    _expensesController.add(List.unmodifiable(_localExpenses));

    // Si lié à un article en stock, mettre à jour le stock automatiquement
    if (expense.isStockable && expense.stockItemId != null && expense.quantity > 0) {
      final itemIndex = _localItems.indexWhere((i) => i.id == expense.stockItemId);
      if (itemIndex != -1) {
        await recordMovement(
          itemId: expense.stockItemId!,
          type: MovementType.stockIn,
          quantity: expense.quantity,
          reason: 'Achat d\'approvisionnement : ${expense.label}',
          performedBy: 'Responsable Approvisionnement',
        );

        if (expense.unitPrice > 0) {
          final item = _localItems[itemIndex];
          _localItems[itemIndex] = item.copyWith(
            unitCost: expense.unitPrice,
            updatedAt: DateTime.now(),
          );
          _itemsController.add(List.unmodifiable(_localItems));
        }
      }
    }
  }

  Future<void> deleteExpense(String id, {bool revertStock = false}) async {
    final expIndex = _localExpenses.indexWhere((e) => e.id == id);
    if (expIndex == -1) return;

    final exp = _localExpenses[expIndex];
    if (revertStock && exp.isStockable && exp.stockItemId != null && exp.quantity > 0) {
      final itemIndex = _localItems.indexWhere((i) => i.id == exp.stockItemId);
      if (itemIndex != -1) {
        await recordMovement(
          itemId: exp.stockItemId!,
          type: MovementType.stockOut,
          quantity: exp.quantity,
          reason: 'Annulation achat / Dépense supprimée : ${exp.label}',
          performedBy: 'Responsable',
        );
      }
    }

    _localExpenses.removeAt(expIndex);
    _expensesController.add(List.unmodifiable(_localExpenses));
  }
}

