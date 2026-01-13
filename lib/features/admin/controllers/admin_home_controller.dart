import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/app_user.dart';
import '../../../models/quartier.dart';
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';

class AdminHomeController extends GetxController with GetSingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = Get.find<AuthService>();

  // Tab Controller - Initialisé dans onInit mais accessible immédiatement
  late final TabController tabController;

  // Listes complètes
  final RxList<AppUser> allPickers = <AppUser>[].obs;
  final RxList<AppUser> allClients = <AppUser>[].obs;
  final RxBool isLoading = false.obs;

  // Recherche et filtres - Pickers
  final TextEditingController pickerSearchController = TextEditingController();
  final RxString pickerSearchQuery = ''.obs;
  final RxString pickerQuartierFilter = ''.obs;
  final RxBool pickerActiveOnlyFilter = false.obs;

  // Recherche et filtres - Clients
  final TextEditingController clientSearchController = TextEditingController();
  final RxString clientSearchQuery = ''.obs;
  final RxString clientQuartierFilter = ''.obs;
  final RxBool clientActiveOnlyFilter = false.obs;

  // Stats
  final RxInt totalPickers = 0.obs;
  final RxInt activePickers = 0.obs;
  final RxInt totalClients = 0.obs;
  final RxInt clientsWithActiveRequests = 0.obs;
  final RxInt totalActiveRequests = 0.obs;

  // Map pour stocker si chaque client a une demande active
  final RxMap<String, bool> clientHasActiveRequest = <String, bool>{}.obs;

  // Quartiers disponibles
  final RxList<String> availableQuartiers = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 5, vsync: this);

    _loadPickers();
    _loadClients();
    _loadStats();
    _loadQuartiers();

    // Écouter les changements de recherche
    pickerSearchController.addListener(() {
      pickerSearchQuery.value = pickerSearchController.text.toLowerCase();
    });
    clientSearchController.addListener(() {
      clientSearchQuery.value = clientSearchController.text.toLowerCase();
    });
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

  @override
  void onClose() {
    tabController.dispose();
    pickerSearchController.dispose();
    clientSearchController.dispose();
    super.onClose();
  }

  void _loadPickers() {
    isLoading.value = true;

    _firestoreService.listenToPickers().listen(
      (pickersList) {
        allPickers.value = pickersList;
        totalPickers.value = pickersList.length;
        activePickers.value =
            pickersList.where((p) => p.status == UserStatus.active).length;

        if (isLoading.value) {
          isLoading.value = false;
        }
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('Erreur', 'Impossible de charger les pickers: $e');
      },
    );
  }

  void _loadClients() {
    _firestoreService.listenToClients().listen(
      (clientsList) {
        allClients.value = clientsList;
        totalClients.value = clientsList.length;
      },
      onError: (e) {
        Get.snackbar('Erreur', 'Impossible de charger les clients: $e');
      },
    );
  }

  void _loadStats() {
    _firestoreService.listenToActiveTrashReports().listen(
      (reports) {
        totalActiveRequests.value = reports.length;
        final uniqueClients = reports.map((r) => r.clientId).toSet();
        clientsWithActiveRequests.value = uniqueClients.length;

        // Mettre à jour map clients avec demande active
        clientHasActiveRequest.clear();
        for (final report in reports) {
          clientHasActiveRequest[report.clientId] = true;
        }
      },
      onError: (e) {
        Get.snackbar('Erreur', 'Impossible de charger les statistiques: $e');
      },
    );
  }

  // Pickers filtrés
  List<AppUser> get filteredPickers {
    var filtered = allPickers.where((picker) {
      // Filtre actifs uniquement
      if (pickerActiveOnlyFilter.value && picker.status != UserStatus.active) {
        return false;
      }

      // Filtre quartier
      if (pickerQuartierFilter.value.isNotEmpty) {
        if (picker.quartier != pickerQuartierFilter.value) {
          return false;
        }
      }

      // Recherche
      if (pickerSearchQuery.value.isNotEmpty) {
        final query = pickerSearchQuery.value;
        return picker.name.toLowerCase().contains(query) ||
            picker.phone.toLowerCase().contains(query) ||
            (picker.quartier?.toLowerCase().contains(query) ?? false) ||
            (picker.address?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();

    return filtered;
  }

  // Clients filtrés
  List<AppUser> get filteredClients {
    var filtered = allClients.where((client) {
      // Filtre clients avec demande active uniquement
      if (clientActiveOnlyFilter.value) {
        if (clientHasActiveRequest[client.id] != true) {
          return false;
        }
      }

      // Filtre quartier
      if (clientQuartierFilter.value.isNotEmpty) {
        if (client.quartier != clientQuartierFilter.value) {
          return false;
        }
      }

      // Recherche
      if (clientSearchQuery.value.isNotEmpty) {
        final query = clientSearchQuery.value;
        return client.name.toLowerCase().contains(query) ||
            client.phone.toLowerCase().contains(query) ||
            (client.quartier?.toLowerCase().contains(query) ?? false) ||
            (client.address?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();

    return filtered;
  }

  bool hasActiveRequest(String clientId) {
    return clientHasActiveRequest[clientId] == true;
  }

  // Méthodes de filtre - Pickers
  void togglePickerActiveFilter() {
    pickerActiveOnlyFilter.value = !pickerActiveOnlyFilter.value;
  }

  void setPickerQuartierFilter(String? quartier) {
    pickerQuartierFilter.value = quartier ?? '';
  }

  void clearPickerFilters() {
    pickerSearchController.clear();
    pickerQuartierFilter.value = '';
    pickerActiveOnlyFilter.value = false;
  }

  // Méthodes de filtre - Clients
  void toggleClientActiveFilter() {
    clientActiveOnlyFilter.value = !clientActiveOnlyFilter.value;
  }

  void setClientQuartierFilter(String? quartier) {
    clientQuartierFilter.value = quartier ?? '';
  }

  void clearClientFilters() {
    clientSearchController.clear();
    clientQuartierFilter.value = '';
    clientActiveOnlyFilter.value = false;
  }

  // Actions
  Future<void> togglePickerStatus(AppUser picker) async {
    try {
      final newStatus = picker.status == UserStatus.active
          ? UserStatus.inactive
          : UserStatus.active;

      await _firestoreService.updateUser(picker.id, {
        'status': newStatus.name,
      });

      Get.snackbar(
        'Succès',
        'Statut du picker ${picker.name} mis à jour',
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier le statut: $e');
    }
  }

  Future<void> deletePicker(String pickerId) async {
    try {
      await _firestoreService.deleteUser(pickerId);
      Get.snackbar('Succès', 'Picker supprimé');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer le picker: $e');
    }
  }

  void viewClientDetails(AppUser client) {
    Get.toNamed('/admin-client-details', arguments: client);
  }

  void viewPickerDetails(AppUser picker) {
    Get.toNamed('/admin-picker-details', arguments: picker);
  }

  // Navigation depuis analytics
  void navigateToPickersTab({bool activeOnly = false}) {
    tabController.animateTo(1); // Index du tab Pickers
    if (activeOnly) {
      pickerActiveOnlyFilter.value = true;
    }
  }

  void navigateToClientsTab({bool activeOnly = false}) {
    tabController.animateTo(2); // Index du tab Clients
    if (activeOnly) {
      clientActiveOnlyFilter.value = true;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    Get.offAllNamed('/auth-choice');
  }
}
