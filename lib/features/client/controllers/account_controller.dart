import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/app_user.dart';
import '../../../models/quartier.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';

class AccountController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController foyerController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxString selectedQuartier = ''.obs;
  final RxList<Quartier> quartiers = <Quartier>[].obs;

  AppUser? currentUser;

  @override
  void onInit() {
    super.onInit();
    _loadQuartiers();
    loadUserData();
  }

  void _loadQuartiers() {
    _firestoreService.listenToActiveQuartiers().listen((data) {
      // Dédupliquer les quartiers par nom
      final Map<String, Quartier> uniqueQuartiers = {};
      for (var quartier in data) {
        uniqueQuartiers[quartier.name] = quartier;
      }
      quartiers.value = uniqueQuartiers.values.toList();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    foyerController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    isLoading.value = true;

    try {
      final userId = _authService.userId;
      if (userId != null) {
        currentUser = await _firestoreService.getUser(userId);

        if (currentUser != null) {
          nameController.text = currentUser!.name;
          selectedQuartier.value = currentUser!.quartier ?? '';
          addressController.text = currentUser!.address ?? '';
          phoneController.text = currentUser!.phone;

          // Charger le champ foyer custom
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            foyerController.text = userDoc.data()?['foyer'] ?? '';
          }
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSaving.value = true;

    try {
      final userId = _authService.userId;
      if (userId == null) {
        throw 'Utilisateur non connecté';
      }

      await _firestoreService.updateUser(userId, {
        'name': nameController.text.trim(),
        'quartier': selectedQuartier.value.toLowerCase(),
        'address': addressController.text.trim(),
        'foyer': foyerController.text.trim(),
      });

      isSaving.value = false;

      Get.snackbar(
        'Succès',
        'Profil mis à jour avec succès',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      isSaving.value = false;
      Get.snackbar('Erreur', e.toString());
    }
  }

  void showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController =
        TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    final RxBool obscureCurrent = true.obs;
    final RxBool obscureNew = true.obs;
    final RxBool obscureConfirm = true.obs;

    void disposeControllers() {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }

    Get.dialog(
      PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            disposeControllers();
          }
        },
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Changer le mot de passe',
            style: AppTextStyles.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mot de passe actuel
                Obx(() => TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent.value,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              obscureCurrent.value = !obscureCurrent.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),

                const SizedBox(height: 16),

                // Nouveau mot de passe
                Obx(() => TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew.value,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => obscureNew.value = !obscureNew.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),

                const SizedBox(height: 16),

                // Confirmer nouveau mot de passe
                Obx(() => TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm.value,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              obscureConfirm.value = !obscureConfirm.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                disposeControllers();
                Get.back();
              },
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentPasswordController.text;
                final newPass = newPasswordController.text;
                final confirm = confirmPasswordController.text;

                await _changePassword(current, newPass, confirm);
                disposeControllers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Changer',
                style: TextStyle(color: AppColors.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    String current,
    String newPassword,
    String confirm,
  ) async {
    if (current.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs');
      return;
    }

    if (newPassword.length < 6) {
      Get.snackbar(
        'Erreur',
        'Le nouveau mot de passe doit contenir au moins 6 caractères',
      );
      return;
    }

    if (newPassword != confirm) {
      Get.snackbar('Erreur', 'Les mots de passe ne correspondent pas');
      return;
    }

    try {
      // Réauthentifier l'utilisateur avec le mot de passe actuel
      final phone = currentUser?.phone ?? '';
      await _authService.signInWithPhonePassword(phone, current);

      // Changer le mot de passe
      await _authService.updatePassword(newPassword);

      Get.back();
      Get.snackbar(
        'Succès',
        'Mot de passe modifié avec succès',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }
}
