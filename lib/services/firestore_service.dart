import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/trash_report.dart';
import '../models/quartier.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String usersCollection = 'users';
  static const String trashReportsCollection = 'trash_reports';
  static const String quartiersCollection = 'quartiers';

  // User operations
  Future<void> createUser(AppUser user) async {
    await _firestore.collection(usersCollection).doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection(usersCollection).doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Stream<AppUser?> listenToUser(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromMap(snapshot.data()!);
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore.collection(usersCollection).doc(userId).update(updates);
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection(usersCollection).doc(userId).delete();
  }

  Stream<List<AppUser>> listenToPickers() {
    return _firestore
        .collection(usersCollection)
        .where('role', isEqualTo: 'picker')
        .snapshots()
        .map((snapshot) {
      final pickers = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
      // Tri manuel par date
      pickers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pickers;
    });
  }

  Stream<List<AppUser>> listenToClients() {
    return _firestore
        .collection(usersCollection)
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) {
      final clients = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
      // Tri manuel par date
      clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return clients;
    });
  }

  // Trash Report operations
  Future<String> createTrashReport(TrashReport report) async {
    final docRef = _firestore.collection(trashReportsCollection).doc();
    final reportWithId = report.copyWith(id: docRef.id);
    await docRef.set(reportWithId.toMap());
    return docRef.id;
  }

  Future<TrashReport?> getTrashReport(String trashId) async {
    final doc =
        await _firestore.collection(trashReportsCollection).doc(trashId).get();
    if (!doc.exists) return null;
    return TrashReport.fromMap(doc.data()!);
  }

  Stream<TrashReport?> listenToTrashReport(String trashId) {
    return _firestore
        .collection(trashReportsCollection)
        .doc(trashId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return TrashReport.fromMap(snapshot.data()!);
    });
  }

  Stream<List<TrashReport>> listenToPendingTrashInZone(String quartier) {
    return _firestore
        .collection(trashReportsCollection)
        .where('quartier', isEqualTo: quartier)
        .where('status', isEqualTo: TrashStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrashReport.fromMap(doc.data()))
          .where((report) => report.isActive) // CRITICAL: Only active requests
          .toList();
    });
  }

  Stream<List<TrashReport>> listenToAllPendingTrash() {
    return _firestore
        .collection(trashReportsCollection)
        .where('status', isEqualTo: TrashStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrashReport.fromMap(doc.data()))
          .where((report) => report.isActive) // CRITICAL: Only active requests
          .toList();
    });
  }

  Stream<List<TrashReport>> listenToActiveTrashReports() {
    return _firestore
        .collection(trashReportsCollection)
        .where('status', whereIn: [
          TrashStatus.pending.name,
          TrashStatus.inTransit.name,
        ])
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => TrashReport.fromMap(doc.data()))
          .where((report) => report.isActive) // CRITICAL: Filter by isActive
          .toList();
      // Tri manuel par date
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Stream<List<TrashReport>> listenToClientTrashReports(String clientId) {
    // No orderBy to avoid composite index requirement
    // Sorting will be done manually in the controller
    return _firestore
        .collection(trashReportsCollection)
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrashReport.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<TrashReport>> listenToPickerTrashReports(String pickerId) {
    // No orderBy to avoid composite index requirement
    // Sorting will be done manually in the controller
    return _firestore
        .collection(trashReportsCollection)
        .where('pickerId', isEqualTo: pickerId)
        .where('status', whereIn: [
          TrashStatus.inTransit.name,
          TrashStatus.completed.name
        ])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrashReport.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> assignPickerToTrash(String trashId, String pickerId) async {
    await _firestore.collection(trashReportsCollection).doc(trashId).update({
      'pickerId': pickerId,
      'status': TrashStatus.inTransit.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markTrashCompleted(String trashId, {String? pickerId, double? rating}) async {
    final updates = {
      'status': TrashStatus.completed.name,
      'isActive': false,
      'completedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
    // S'assurer que le pickerId est bien enregistré
    if (pickerId != null) {
      updates['pickerId'] = pickerId;
    }
    if (rating != null) {
      updates['rating'] = rating;
    }
    await _firestore.collection(trashReportsCollection).doc(trashId).update(updates);
  }

  Future<void> cancelTrashReport(String trashId) async {
    await _firestore.collection(trashReportsCollection).doc(trashId).update({
      'status': TrashStatus.cancelled.name,
      'isActive': false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateTrashReport(
      String trashId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(trashReportsCollection)
        .doc(trashId)
        .update(updates);
  }

  // ========== LOGIQUE INTELLIGENTE DE DEMANDE ==========

  /// Récupère la demande réutilisable actuelle du client (non complétée)
  Future<TrashReport?> getCurrentReusableRequest(String clientId) async {
    final snapshot = await _firestore
        .collection(trashReportsCollection)
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: [
          TrashStatus.pending.name,
          TrashStatus.inTransit.name,
        ])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return TrashReport.fromMap(snapshot.docs.first.data());
  }

  /// Active la demande de récupération
  Future<String> activatePickupRequest({
    required String clientId,
    required double latitude,
    required double longitude,
    String? quartier,
    String? clientNotes,
    List<String>? photosUrls,
  }) async {
    // CRITICAL: Normalize quartier to lowercase for consistent matching
    final normalizedQuartier = quartier?.toLowerCase();

    final existingRequest = await getCurrentReusableRequest(clientId);

    if (existingRequest != null) {
      print('🔄 Réutilisation demande: ${existingRequest.id}');
      print('   Quartier: "${normalizedQuartier}", isActive: true, status: ${existingRequest.status.name}');

      await _firestore
          .collection(trashReportsCollection)
          .doc(existingRequest.id)
          .update({
        'isActive': true,
        'latitude': latitude,
        'longitude': longitude,
        'quartier': normalizedQuartier,
        'clientNotes': clientNotes,
        'photosUrls': photosUrls ?? existingRequest.photosUrls,
        'updatedAt': Timestamp.now(),
      });

      return existingRequest.id;
    } else {
      print('✨ Nouvelle demande client: $clientId');
      print('   Quartier: "${normalizedQuartier}", isActive: true, status: pending');

      final docRef = _firestore.collection(trashReportsCollection).doc();
      final newRequest = TrashReport(
        id: docRef.id,
        clientId: clientId,
        latitude: latitude,
        longitude: longitude,
        quartier: normalizedQuartier,
        clientNotes: clientNotes,
        photosUrls: photosUrls ?? [],
        status: TrashStatus.pending,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newRequest.toMap());
      return docRef.id;
    }
  }

  /// Désactive la demande (toggle OFF)
  Future<void> deactivatePickupRequest(String requestId) async {
    print('⏸️ Désactivation demande: $requestId');

    await _firestore.collection(trashReportsCollection).doc(requestId).update({
      'isActive': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Écoute la demande active du client
  Stream<TrashReport?> listenToClientActiveRequest(String clientId) {
    return _firestore
        .collection(trashReportsCollection)
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: [
          TrashStatus.pending.name,
          TrashStatus.inTransit.name,
        ])
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      // Filter by isActive and return the first active request
      final activeRequests = snapshot.docs
          .map((doc) => TrashReport.fromMap(doc.data()))
          .where((report) => report.isActive)
          .toList();

      return activeRequests.isNotEmpty ? activeRequests.first : null;
    });
  }

  // ========== QUARTIER OPERATIONS ==========

  /// Crée un nouveau quartier
  Future<void> createQuartier(Quartier quartier) async {
    await _firestore
        .collection(quartiersCollection)
        .doc(quartier.id)
        .set(quartier.toMap());
  }

  /// Récupère tous les quartiers actifs
  Future<List<Quartier>> getActiveQuartiers() async {
    final snapshot = await _firestore
        .collection(quartiersCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => Quartier.fromMap(doc.data()))
        .toList();
  }

  /// Écoute tous les quartiers (pour l'admin)
  Stream<List<Quartier>> listenToQuartiers() {
    return _firestore
        .collection(quartiersCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Quartier.fromMap(doc.data()))
          .toList();
    });
  }

  /// Écoute uniquement les quartiers actifs (pour les filtres)
  Stream<List<Quartier>> listenToActiveQuartiers() {
    return _firestore
        .collection(quartiersCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Quartier.fromMap(doc.data()))
          .toList();
    });
  }

  /// Met à jour un quartier
  Future<void> updateQuartier(String quartierId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(quartiersCollection)
        .doc(quartierId)
        .update(updates);
  }

  /// Vérifie si un quartier peut être supprimé (pas d'utilisateurs)
  Future<bool> canDeleteQuartier(String quartierName) async {
    final usersSnapshot = await _firestore
        .collection(usersCollection)
        .where('quartier', isEqualTo: quartierName)
        .limit(1)
        .get();

    return usersSnapshot.docs.isEmpty;
  }

  /// Supprime un quartier (seulement si pas d'utilisateurs)
  Future<void> deleteQuartier(String quartierId, String quartierName) async {
    final canDelete = await canDeleteQuartier(quartierName);

    if (!canDelete) {
      throw 'Impossible de supprimer ce quartier car des utilisateurs y sont enregistrés';
    }

    await _firestore.collection(quartiersCollection).doc(quartierId).delete();
  }

  /// Compte le nombre de clients par quartier
  Future<int> countClientsInQuartier(String quartierName) async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('quartier', isEqualTo: quartierName)
        .where('role', isEqualTo: 'client')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Compte le nombre de pickers par quartier
  Future<int> countPickersInQuartier(String quartierName) async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('quartier', isEqualTo: quartierName)
        .where('role', isEqualTo: 'picker')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Compte le nombre total d'utilisateurs par quartier
  Future<int> countUsersInQuartier(String quartierName) async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('quartier', isEqualTo: quartierName)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Met à jour les compteurs d'utilisateurs pour tous les quartiers
  Future<void> updateQuartiersUserCount() async {
    final quartiers = await _firestore.collection(quartiersCollection).get();

    for (final doc in quartiers.docs) {
      final quartier = Quartier.fromMap(doc.data());
      final clientCount = await countClientsInQuartier(quartier.name);
      final pickerCount = await countPickersInQuartier(quartier.name);

      await updateQuartier(quartier.id, {
        'clientCount': clientCount,
        'pickerCount': pickerCount,
      });
    }
  }
}
