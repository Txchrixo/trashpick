import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/trash_report.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/app_colors.dart';

class PickerHistoryController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();

  final RxList<TrashReport> allRequests = <TrashReport>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;

    try {
      final userId = _authService.userId;
      if (userId != null) {
        _firestoreService.listenToPickerTrashReports(userId).listen(
          (requests) {
            // Sort by date descending
            requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            allRequests.value = requests;
            isLoading.value = false;
          },
          onError: (e) {
            isLoading.value = false;
            Get.snackbar('Erreur', 'Impossible de charger l\'historique: $e');
          },
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Erreur', 'Impossible de charger l\'historique: $e');
    }
  }

  // Active requests (in transit)
  List<TrashReport> get activeRequests {
    return allRequests.where((request) {
      return request.status == TrashStatus.inTransit;
    }).toList();
  }

  // Completed requests
  List<TrashReport> get completedRequests {
    return allRequests.where((request) {
      return request.status == TrashStatus.completed;
    }).toList();
  }

  String getStatusText(TrashStatus status) {
    switch (status) {
      case TrashStatus.pending:
        return 'En attente';
      case TrashStatus.inTransit:
        return 'En cours';
      case TrashStatus.completed:
        return 'Complété';
      case TrashStatus.cancelled:
        return 'Annulé';
    }
  }

  Color getStatusColor(TrashStatus status) {
    switch (status) {
      case TrashStatus.pending:
        return AppColors.warning;
      case TrashStatus.inTransit:
        return AppColors.secondary;
      case TrashStatus.completed:
        return AppColors.success;
      case TrashStatus.cancelled:
        return AppColors.textSecondary;
    }
  }
}
