class ClientModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String address;
  final String city;
  final double presetPricePerKg; // Prix négocié par défaut en DA/kg
  final double totalDue; // Reste à payer / Impayé du client en DA
  final bool isActive;
  final String notes;
  final DateTime createdAt;

  ClientModel({
    required this.id,
    required this.name,
    this.contactPerson = '',
    required this.phone,
    required this.address,
    this.city = '',
    required this.presetPricePerKg,
    this.totalDue = 0.0,
    this.isActive = true,
    this.notes = '',
    required this.createdAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      name: map['name'] as String? ?? '',
      contactPerson: map['contactPerson'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      presetPricePerKg: (map['presetPricePerKg'] as num?)?.toDouble() ?? 0.0,
      totalDue: (map['totalDue'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'address': address,
      'city': city,
      'presetPricePerKg': presetPricePerKg,
      'totalDue': totalDue,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ClientModel copyWith({
    String? name,
    String? contactPerson,
    String? phone,
    String? address,
    String? city,
    double? presetPricePerKg,
    double? totalDue,
    bool? isActive,
    String? notes,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      presetPricePerKg: presetPricePerKg ?? this.presetPricePerKg,
      totalDue: totalDue ?? this.totalDue,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
