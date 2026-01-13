import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/app_user.dart';
import '../../../models/trash_report.dart';
import '../../../services/firestore_service.dart';

class AdminMapController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final RxList<AppUser> activePickers = <AppUser>[].obs;
  final RxList<TrashReport> activeRequests = <TrashReport>[].obs;
  final RxBool isLoading = true.obs;

  final mapController = MapController();
  final RxList<Marker> markers = <Marker>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMapData();
  }

  Future<void> loadMapData() async {
    isLoading.value = true;
    try {
      // Écouter les pickers actifs
      _firestoreService.listenToPickers().listen((pickersList) {
        activePickers.value =
            pickersList.where((p) => p.status == UserStatus.active).toList();
        _updateMarkers();
      });

      // Écouter les demandes actives
      _firestoreService.listenToActiveTrashReports().listen((reports) {
        activeRequests.value = reports;
        _updateMarkers();
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateMarkers() {
    final newMarkers = <Marker>[];

    // Markers pour les pickers actifs (bleu)
    for (final picker in activePickers) {
      if (picker.latitude != null && picker.longitude != null) {
        newMarkers.add(
          Marker(
            point: LatLng(picker.latitude!, picker.longitude!),
            width: 40,
            height: 40,
            child: const Icon(
              Icons.person_pin,
              color: Colors.blue,
              size: 40,
            ),
          ),
        );
      }
    }

    // Markers pour les demandes actives (rouge/orange selon statut)
    for (final request in activeRequests) {
      newMarkers.add(
        Marker(
          point: LatLng(request.latitude, request.longitude),
          width: 40,
          height: 40,
          child: Icon(
            Icons.delete,
            color: request.status == TrashStatus.pending
                ? Colors.red
                : Colors.orange,
            size: 40,
          ),
        ),
      );
    }

    markers.value = newMarkers;
  }

  void onMapCreated() {
    // Map controller already initialized
  }
}
