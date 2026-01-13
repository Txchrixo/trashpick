import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, picker, admin }

enum UserStatus { active, inactive, suspended }

class AppUser {
  final String id;
  final String phone;
  final String name;
  final UserRole role;
  final String? address;
  final String? quartier;
  final double? latitude;
  final double? longitude;
  final String? alternativePhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserStatus status;

  AppUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.address,
    this.quartier,
    this.latitude,
    this.longitude,
    this.alternativePhone,
    required this.createdAt,
    required this.updatedAt,
    this.status = UserStatus.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role.name,
      'address': address,
      'quartier': quartier,
      'latitude': latitude,
      'longitude': longitude,
      'alternativePhone': alternativePhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.name,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      phone: map['phone'] as String,
      name: map['name'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      address: map['address'] as String?,
      quartier: map['quartier'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      alternativePhone: map['alternativePhone'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
    );
  }

  AppUser copyWith({
    String? id,
    String? phone,
    String? name,
    UserRole? role,
    String? address,
    String? quartier,
    double? latitude,
    double? longitude,
    String? alternativePhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStatus? status,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      address: address ?? this.address,
      quartier: quartier ?? this.quartier,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
