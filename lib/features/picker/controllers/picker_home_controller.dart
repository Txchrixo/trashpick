import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/app_user.dart';
import '../../../models/trash_report.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/location_service.dart';
import '../../../core/app_colors.dart';

class PickerHomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);
  final RxList<TrashReport> pendingTrashReports = <TrashReport>[].obs;
  final RxList<TrashReportWithDistance> trashReportsWithDistance =
      <TrashReportWithDistance>[].obs;
  final RxBool isLoading = true.obs; // IMPORTANT: Commencer avec true pour afficher le loader au démarrage
  final RxString quartierFilter = ''.obs;
  final RxList<String> availableQuartiers = <String>[].obs;

  // Cache pour stocker les informations des clients (foyer)
  final RxMap<String, String> clientFoyerCache = <String, String>{}.obs;

  final mapController = MapController();
  final Rx<LatLng?> pickerLocation = Rx<LatLng?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadQuartiers();
    // loadPendingTrashReports is now called from _loadUserData when user data is available
  }

  void _loadQuartiers() {
    _firestoreService.listenToActiveQuartiers().listen((quartiersList) {
      // Dédupliquer les quartiers par nom
      final uniqueNames = <String>{};
      for (var quartier in quartiersList) {
        uniqueNames.add(quartier.name);
      }
      availableQuartiers.value = uniqueNames.toList();
    });
  }

  Future<void> _loadUserData() async {
    final userId = _authService.userId;
    if (userId != null) {
      _firestoreService.listenToUser(userId).listen((user) {
        currentUser.value = user;
        if (user != null && user.latitude != null && user.longitude != null) {
          pickerLocation.value = LatLng(user.latitude!, user.longitude!);
          _moveCamera();
        }
        // Load pending trash reports after user data is loaded
        loadPendingTrashReports();
      });
    }
  }

  Future<void> loadPendingTrashReports() async {
    final user = currentUser.value;

    // Par défaut, charger les demandes du quartier du picker
    // (ou toutes les demandes s'il n'a pas de quartier)
    if (user?.quartier != null) {
      // CRITICAL: Normalize quartier to lowercase for consistent matching
      final normalizedQuartier = user!.quartier!.toLowerCase();
      print('🔍 Picker quartier: "$normalizedQuartier" (searching for pending trash in picker zone)');
      _firestoreService
          .listenToPendingTrashInZone(normalizedQuartier)
          .listen((reports) async {
        print('📋 Pending trash in picker zone $normalizedQuartier: ${reports.length} reports');
        for (var report in reports) {
          print('  - Report ${report.id}: quartier="${report.quartier}", isActive=${report.isActive}, status=${report.status.name}');
        }
        pendingTrashReports.value = reports;
        await _calculateDistances();
        isLoading.value = false; // Arrêter le loading après le premier chargement
      });
    } else {
      print('⚠️ Picker has no quartier, loading all pending trash');
      _loadAllPendingTrash();
    }
  }

  Future<void> _calculateDistances() async {
    final List<TrashReportWithDistance> withDistances = [];

    // Charger tous les foyers manquants EN PARALLÈLE (beaucoup plus rapide)
    final missingClientIds = pendingTrashReports
        .where((report) => !clientFoyerCache.containsKey(report.clientId))
        .map((report) => report.clientId)
        .toSet()
        .toList();

    if (missingClientIds.isNotEmpty) {
      print('⏳ Chargement de ${missingClientIds.length} foyers en parallèle...');
      await Future.wait(
        missingClientIds.map((clientId) => _loadClientFoyer(clientId)),
      );
    }

    // Calculer les distances et créer la liste
    for (final report in pendingTrashReports) {
      double distance = 0.0;

      // Calculer la distance seulement si on a la position du picker
      if (pickerLocation.value != null) {
        distance = await _locationService.getDistanceBetween(
          pickerLocation.value!.latitude,
          pickerLocation.value!.longitude,
          report.latitude,
          report.longitude,
        );
      }

      withDistances.add(TrashReportWithDistance(
        report: report,
        distance: distance,
      ));
    }

    // Trier par distance (0.0 si pas de position = en premier)
    withDistances.sort((a, b) => a.distance.compareTo(b.distance));
    trashReportsWithDistance.value = withDistances;

    print('✅ ${withDistances.length} demandes ajoutées à trashReportsWithDistance');
  }

  /// Charge le foyer du client et le met en cache
  Future<void> _loadClientFoyer(String clientId) async {
    try {
      final clientDoc = await _firestoreService.getUser(clientId);
      if (clientDoc != null) {
        // Récupérer le champ custom 'foyer' depuis Firestore
        final userDocRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(clientId)
            .get();
        final foyer = userDocRef.data()?['foyer'] as String? ?? 'Foyer inconnu';
        clientFoyerCache[clientId] = foyer;
      }
    } catch (e) {
      print('❌ Erreur chargement foyer client $clientId: $e');
      clientFoyerCache[clientId] = 'Foyer inconnu';
    }
  }

  void setQuartierFilter(String? quartier) {
    final selectedQuartier = quartier ?? '';
    quartierFilter.value = selectedQuartier;

    // Afficher le loading pendant le chargement
    isLoading.value = true;

    // Si "Tous les quartiers" est sélectionné, charger TOUTES les demandes
    if (selectedQuartier.isEmpty) {
      _loadAllPendingTrash();
    } else {
      // Sinon, charger seulement les demandes du quartier spécifique sélectionné
      _loadPendingTrashInSpecificZone(selectedQuartier);
    }
  }

  // Charge TOUTES les demandes en attente (tous quartiers confondus)
  void _loadAllPendingTrash() {
    print('🌍 Chargement de TOUTES les demandes en attente (tous quartiers)');
    _firestoreService.listenToAllPendingTrash().listen((reports) async {
      print('📋 Total pending trash (all zones): ${reports.length} reports');
      for (var report in reports) {
        print('  - Report ${report.id}: quartier="${report.quartier}", isActive=${report.isActive}, status=${report.status.name}');
      }
      pendingTrashReports.value = reports;
      await _calculateDistances();
      isLoading.value = false; // Arrêter le loading après calcul
    });
  }

  // Charge les demandes d'un quartier spécifique (utilisé par le filtre)
  void _loadPendingTrashInSpecificZone(String quartier) {
    final normalizedQuartier = quartier.toLowerCase();
    print('🔍 Filtre quartier: "$normalizedQuartier" (recherche demandes dans ce quartier)');
    _firestoreService
        .listenToPendingTrashInZone(normalizedQuartier)
        .listen((reports) async {
      print('📋 Pending trash in filtered zone $normalizedQuartier: ${reports.length} reports');
      for (var report in reports) {
        print('  - Report ${report.id}: quartier="${report.quartier}", isActive=${report.isActive}, status=${report.status.name}');
      }
      pendingTrashReports.value = reports;
      await _calculateDistances();
      isLoading.value = false; // Arrêter le loading après calcul
    });
  }

  void clearFilter() {
    quartierFilter.value = '';
    isLoading.value = true; // Afficher le loading
    // Recharger toutes les demandes quand on efface le filtre
    _loadAllPendingTrash();
  }

  void onMapCreated() {
    _moveCamera();
  }

  void _moveCamera() {
    if (pickerLocation.value != null) {
      mapController.move(pickerLocation.value!, 13.0);
    }
  }

  List<Marker> getMarkers(Function(TrashReport) onTap) {
    final markers = <Marker>[];

    if (pickerLocation.value != null) {
      markers.add(
        Marker(
          point: pickerLocation.value!,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              // Optionnel: afficher un tooltip ou dialog avec les infos du picker
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.blue,
              size: 40,
            ),
          ),
        ),
      );
    }

    for (final report in pendingTrashReports) {
      markers.add(
        Marker(
          point: LatLng(report.latitude, report.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => onTap(report),
            child: const Icon(
              Icons.delete,
              color: Colors.orange,
              size: 40,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> assignTrashToPicker(String trashId) async {
    final userId = _authService.userId;
    if (userId == null) return;

    isLoading.value = true;

    try {
      await _firestoreService.assignPickerToTrash(trashId, userId);
      Get.snackbar(
        'Succès',
        'Trash assigné avec succès',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsCompleted(String trashId, {double? rating}) async {
    final userId = _authService.userId;
    if (userId == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      return;
    }

    isLoading.value = true;

    try {
      // CRITICAL: Passer le pickerId pour qu'il soit enregistré dans la BD
      await _firestoreService.markTrashCompleted(
        trashId,
        pickerId: userId,
        rating: rating,
      );
      Get.back();
      Get.snackbar(
        'Succès',
        'Trash marqué comme récupéré',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}

class TrashReportWithDistance {
  final TrashReport report;
  final double distance;

  TrashReportWithDistance({
    required this.report,
    required this.distance,
  });
}
