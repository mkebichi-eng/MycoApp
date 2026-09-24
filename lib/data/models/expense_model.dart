class ExpenseModel {
  final String id;
  final String label;
  final double amount;
  final String category;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String? supplier;
  final bool isStockable;
  final String? stockItemId;
  final DateTime date;

  const ExpenseModel({
    required this.id,
    required this.label,
    required this.amount,
    required this.category,
    this.quantity = 1.0,
    this.unit = 'unités',
    this.unitPrice = 0.0,
    this.supplier,
    this.isStockable = false,
    this.stockItemId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'isStockable': isStockable,
      'stockItemId': stockItemId,
      'date': date.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      label: map['label'] as String? ?? 'Dépense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Autre charge',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] as String? ?? 'unités',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      supplier: map['supplier'] as String?,
      isStockable: map['isStockable'] as bool? ?? false,
      stockItemId: map['stockItemId'] as String?,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
    );
  }
}
