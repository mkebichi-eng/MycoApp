class InventoryItemModel {
  final String id;
  final String name; // ex: Paille de blé, Alcool 70%, Sacs micro-perforés 5kg
  final String category; // raw_material, spawn, consumable, sanitation
  final double currentStock;
  final String unit; // kg, L, unités, paquets
  final double alertThreshold;
  final double unitCost; // Coût unitaire en DA
  final bool isLowStock;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.alertThreshold,
    this.unitCost = 0.0,
    bool? isLowStock,
    required this.updatedAt,
  }) : isLowStock = isLowStock ?? (currentStock <= alertThreshold);

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String id) {
    final stock = (map['currentStock'] as num?)?.toDouble() ?? 0.0;
    final threshold = (map['alertThreshold'] as num?)?.toDouble() ?? 0.0;

    return InventoryItemModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'consumable',
      currentStock: stock,
      unit: map['unit'] as String? ?? 'unités',
      alertThreshold: threshold,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      isLowStock: map['isLowStock'] as bool? ?? (stock <= threshold),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'unit': unit,
      'alertThreshold': alertThreshold,
      'unitCost': unitCost,
      'isLowStock': isLowStock,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  InventoryItemModel copyWith({
    String? name,
    String? category,
    double? currentStock,
    String? unit,
    double? alertThreshold,
    double? unitCost,
    DateTime? updatedAt,
  }) {
    final updatedQuantity = currentStock ?? this.currentStock;
    final updatedThreshold = alertThreshold ?? this.alertThreshold;

    return InventoryItemModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: updatedQuantity,
      unit: unit ?? this.unit,
      alertThreshold: updatedThreshold,
      unitCost: unitCost ?? this.unitCost,
      isLowStock: updatedQuantity <= updatedThreshold,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
