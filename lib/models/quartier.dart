import 'package:cloud_firestore/cloud_firestore.dart';

class Quartier {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int clientCount; // Nombre de clients dans ce quartier
  final int pickerCount; // Nombre de pickers dans ce quartier

  Quartier({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.clientCount = 0,
    this.pickerCount = 0,
  });

  // Total des utilisateurs (clients + pickers)
  int get userCount => clientCount + pickerCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'clientCount': clientCount,
      'pickerCount': pickerCount,
    };
  }

  factory Quartier.fromMap(Map<String, dynamic> map) {
    // Support for old data: if clientCount/pickerCount don't exist, use userCount or 0
    final hasNewFormat = map.containsKey('clientCount') || map.containsKey('pickerCount');
    final oldUserCount = map['userCount'] as int? ?? 0;

    return Quartier(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      clientCount: hasNewFormat ? (map['clientCount'] as int? ?? 0) : oldUserCount,
      pickerCount: hasNewFormat ? (map['pickerCount'] as int? ?? 0) : 0,
    );
  }

  Quartier copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? clientCount,
    int? pickerCount,
  }) {
    return Quartier(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      clientCount: clientCount ?? this.clientCount,
      pickerCount: pickerCount ?? this.pickerCount,
    );
  }
}
