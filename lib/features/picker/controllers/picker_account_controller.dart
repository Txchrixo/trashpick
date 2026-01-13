import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/app_user.dart';
import '../../../models/quartier.dart';
import '../../../core/app_colors.dart';

class PickerAccountController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
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
}
