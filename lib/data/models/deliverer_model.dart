class DelivererModel {
  final String id;
  final String name;
  final String phone;
  final String vehicle; // Moto, Scooter, Kangoo, etc.
  final String address;
  final double defaultFee; // Tarif de course de base en DA
  final bool isActive;
  final DateTime createdAt;

  DelivererModel({
    required this.id,
    required this.name,
    required this.phone,
    this.vehicle = 'Moto rapide',
    this.address = 'Alger',
    this.defaultFee = 350.0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'vehicle': vehicle,
      'address': address,
      'defaultFee': defaultFee,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DelivererModel.fromMap(Map<String, dynamic> map, String id) {
    return DelivererModel(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      vehicle: map['vehicle'] as String? ?? 'Moto rapide',
      address: map['address'] as String? ?? 'Alger',
      defaultFee: (map['defaultFee'] as num?)?.toDouble() ?? 350.0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DelivererModel copyWith({
    String? name,
    String? phone,
    String? vehicle,
    String? address,
    double? defaultFee,
    bool? isActive,
  }) {
    return DelivererModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      address: address ?? this.address,
      defaultFee: defaultFee ?? this.defaultFee,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
