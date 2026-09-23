import '../../core/constants/app_constants.dart';

class UserProfileModel {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return UserProfileModel(
      uid: id,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role.id,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? displayName,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
