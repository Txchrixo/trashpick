import 'package:get/get.dart';
import '../../../models/app_user.dart';
import '../../../models/trash_report.dart';
import '../../../services/firestore_service.dart';

class AdminClientDetailsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final Rx<AppUser?> client = Rx<AppUser?>(null);
  final RxList<TrashReport> clientRequests = <TrashReport>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Récupérer le client depuis les arguments
    if (Get.arguments != null && Get.arguments is AppUser) {
      client.value = Get.arguments as AppUser;
      _loadClientRequests();
    }
  }

  void _loadClientRequests() {
    if (client.value == null) return;

    isLoading.value = true;

    _firestoreService.listenToClientTrashReports(client.value!.id).listen(
      (requests) {
        clientRequests.value = requests;

        if (isLoading.value) {
          isLoading.value = false;
        }
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('Erreur', 'Impossible de charger l\'historique: $e');
      },
    );
  }

  String getStatusText(TrashStatus status) {
    switch (status) {
      case TrashStatus.pending:
        return 'En attente';
      case TrashStatus.inTransit:
        return 'En cours';
      case TrashStatus.completed:
        return 'Terminé';
      case TrashStatus.cancelled:
        return 'Annulé';
    }
  }

  String getRequestSummary(TrashReport request) {
    if (request.status == TrashStatus.completed && request.completedAt != null) {
      final date = request.completedAt!;
      return 'Terminé le ${date.day}/${date.month}/${date.year}';
    } else if (request.status == TrashStatus.inTransit) {
      return 'En cours de récupération';
    } else if (request.isActive) {
      return 'Demande active';
    } else {
      return 'Demande en pause';
    }
  }
}
