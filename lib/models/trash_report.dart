import 'package:cloud_firestore/cloud_firestore.dart';

enum TrashStatus { pending, inTransit, completed, cancelled }

enum WasteCategory { organic, recyclable, general, hazardous }

class TrashReport {
  final String id;
  final String clientId;
  final String? pickerId;
  final TrashStatus status;
  final bool isActive; // Toggle actif/inactif par le client
  final List<String> photosUrls;
  final String? clientNotes;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final WasteCategory wasteCategory;
  final double? rating;
  final String? quartier;

  TrashReport({
    required this.id,
    required this.clientId,
    this.pickerId,
    this.status = TrashStatus.pending,
    this.isActive = true,
    this.photosUrls = const [],
    this.clientNotes,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.wasteCategory = WasteCategory.general,
    this.rating,
    this.quartier,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'pickerId': pickerId,
      'status': status.name,
      'isActive': isActive,
      'photosUrls': photosUrls,
      'clientNotes': clientNotes,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'wasteCategory': wasteCategory.name,
      'rating': rating,
      'quartier': quartier,
    };
  }

  factory TrashReport.fromMap(Map<String, dynamic> map) {
    return TrashReport(
      id: map['id'] as String,
      clientId: map['clientId'] as String,
      pickerId: map['pickerId'] as String?,
      status: TrashStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TrashStatus.pending,
      ),
      isActive: map['isActive'] as bool? ?? true,
      photosUrls: List<String>.from(map['photosUrls'] as List? ?? []),
      clientNotes: map['clientNotes'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      wasteCategory: WasteCategory.values.firstWhere(
        (e) => e.name == map['wasteCategory'],
        orElse: () => WasteCategory.general,
      ),
      rating: map['rating'] as double?,
      quartier: map['quartier'] as String?,
    );
  }

  TrashReport copyWith({
    String? id,
    String? clientId,
    String? pickerId,
    TrashStatus? status,
    bool? isActive,
    List<String>? photosUrls,
    String? clientNotes,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    WasteCategory? wasteCategory,
    double? rating,
    String? quartier,
  }) {
    return TrashReport(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      pickerId: pickerId ?? this.pickerId,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      photosUrls: photosUrls ?? this.photosUrls,
      clientNotes: clientNotes ?? this.clientNotes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      wasteCategory: wasteCategory ?? this.wasteCategory,
      rating: rating ?? this.rating,
      quartier: quartier ?? this.quartier,
    );
  }
}
