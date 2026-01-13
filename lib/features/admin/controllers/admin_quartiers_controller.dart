import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/quartier.dart';
import '../../../services/firestore_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';

class AdminQuartiersController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  final RxList<Quartier> quartiers = <Quartier>[].obs;
  final RxBool isLoading = true.obs;

  final TextEditingController quartierNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadQuartiers();
  }

  @override
  void onClose() {
    quartierNameController.dispose();
    super.onClose();
  }

  void _loadQuartiers() {
    isLoading.value = true;

    // Load quartiers and users in parallel for better performance
    _firestoreService.listenToQuartiers().listen(
      (quartiersData) async {
        // Fetch all users once (clients + pickers)
        final clientsSnapshot = await _firestoreService
            .listenToClients()
            .first;
        final pickersSnapshot = await _firestoreService
            .listenToPickers()
            .first;

        // Count users by quartier locally (much faster than multiple DB queries)
        final Map<String, int> clientCounts = {};
        final Map<String, int> pickerCounts = {};

        for (var client in clientsSnapshot) {
          if (client.quartier != null) {
            clientCounts[client.quartier!] =
                (clientCounts[client.quartier!] ?? 0) + 1;
          }
        }

        for (var picker in pickersSnapshot) {
          if (picker.quartier != null) {
            pickerCounts[picker.quartier!] =
                (pickerCounts[picker.quartier!] ?? 0) + 1;
          }
        }

        // Update quartiers with counts
        final updatedQuartiers = quartiersData.map((quartier) {
          return quartier.copyWith(
            clientCount: clientCounts[quartier.name] ?? 0,
            pickerCount: pickerCounts[quartier.name] ?? 0,
          );
        }).toList();

        quartiers.value = updatedQuartiers;
        isLoading.value = false;
      },
      onError: (e) {
        isLoading.value = false;
        Get.snackbar('Erreur', 'Impossible de charger les quartiers: $e');
      },
    );
  }

  Future<void> refreshQuartiers() async {
    await _firestoreService.updateQuartiersUserCount();
  }

  Future<void> addQuartier() async {
    final name = quartierNameController.text.trim().toLowerCase();

    if (name.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer un nom de quartier');
      return;
    }

    // Check for duplicates (already normalized to lowercase)
    final exists = quartiers.any(
      (q) => q.name == name,
    );

    if (exists) {
      Get.snackbar('Erreur', 'Ce quartier existe déjà');
      return;
    }

    try {
      final quartier = Quartier(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        clientCount: 0,
        pickerCount: 0,
      );

      await _firestoreService.createQuartier(quartier);

      quartierNameController.clear();

      Get.snackbar(
        'Succès',
        'Quartier ajouté avec succès',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'ajouter le quartier: $e');
    }
  }

  void showEditDialog(Quartier quartier) {
    final TextEditingController editController =
        TextEditingController(text: quartier.name);

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Modifier le quartier',
          style: AppTextStyles.h3,
        ),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            labelText: 'Nom du quartier',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              editController.dispose();
              Get.back();
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = editController.text.trim().toLowerCase();

              if (newName.isEmpty) {
                Get.snackbar('Erreur', 'Le nom ne peut pas être vide');
                return;
              }

              // Check for duplicates (excluding current, already normalized)
              final exists = quartiers.any(
                (q) =>
                    q.id != quartier.id &&
                    q.name == newName,
              );

              if (exists) {
                Get.snackbar('Erreur', 'Ce nom est déjà utilisé');
                return;
              }

              try {
                // If name changed, we need to update all users with old quartier name
                if (newName != quartier.name && quartier.userCount > 0) {
                  Get.snackbar(
                    'Attention',
                    'Impossible de modifier le nom d\'un quartier avec des utilisateurs',
                    backgroundColor: AppColors.warning,
                    colorText: AppColors.textWhite,
                  );
                  editController.dispose();
                  Get.back();
                  return;
                }

                await _firestoreService.updateQuartier(
                  quartier.id,
                  {'name': newName},
                );

                editController.dispose();
                Get.back();

                Get.snackbar(
                  'Succès',
                  'Quartier modifié avec succès',
                  backgroundColor: AppColors.success,
                  colorText: AppColors.textWhite,
                );
              } catch (e) {
                Get.snackbar('Erreur', 'Impossible de modifier le quartier: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Modifier',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> toggleQuartierStatus(Quartier quartier) async {
    try {
      await _firestoreService.updateQuartier(
        quartier.id,
        {'isActive': !quartier.isActive},
      );

      Get.snackbar(
        'Succès',
        quartier.isActive
            ? 'Quartier désactivé'
            : 'Quartier activé',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier le statut: $e');
    }
  }

  void showDeleteConfirmation(Quartier quartier) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Confirmer la suppression',
          style: AppTextStyles.h3,
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le quartier "${quartier.name}" ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await deleteQuartier(quartier);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteQuartier(Quartier quartier) async {
    try {
      await _firestoreService.deleteQuartier(quartier.id, quartier.name);

      Get.snackbar(
        'Succès',
        'Quartier supprimé avec succès',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }
}
