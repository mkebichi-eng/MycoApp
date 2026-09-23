enum MovementType {
  stockIn,
  stockOut,
  waste,
  adjustment;

  String get label {
    switch (this) {
      case MovementType.stockIn:
        return 'Entrée / Approvisionnement';
      case MovementType.stockOut:
        return 'Sortie / Utilisation production';
      case MovementType.waste:
        return 'Perte / Péremption / Casse';
      case MovementType.adjustment:
        return 'Ajustement d\'inventaire';
    }
  }
}

class InventoryMovementModel {
  final String id;
  final String itemId;
  final String itemName;
  final MovementType type;
  final double quantity;
  final double previousStock;
  final double newStock;
  final String reason; // ex: Pasteurisation Lot LOT-2026-09-01
  final String? referenceBatchId;
  final String performedBy;
  final DateTime timestamp;

  InventoryMovementModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    this.referenceBatchId,
    required this.performedBy,
    required this.timestamp,
  });

  factory InventoryMovementModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryMovementModel(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      type: MovementType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'stockOut'),
        orElse: () => MovementType.stockOut,
      ),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      previousStock: (map['previousStock'] as num?)?.toDouble() ?? 0.0,
      newStock: (map['newStock'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] as String? ?? '',
      referenceBatchId: map['referenceBatchId'] as String?,
      performedBy: map['performedBy'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'referenceBatchId': referenceBatchId,
      'performedBy': performedBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
