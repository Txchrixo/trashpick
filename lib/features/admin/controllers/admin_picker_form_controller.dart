import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/app_user.dart';
import '../../../models/quartier.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/app_colors.dart';

class AdminPickerFormController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxString selectedQuartier = ''.obs;
  final RxList<Quartier> quartiers = <Quartier>[].obs;

  AppUser? pickerToEdit;

  @override
  void onInit() {
    super.onInit();
    _loadQuartiers();
    // Si on édite un picker existant
    if (Get.arguments != null && Get.arguments is AppUser) {
      pickerToEdit = Get.arguments as AppUser;
      _fillFormWithPickerData();
    }
  }

  void _loadQuartiers() {
    _firestoreService.listenToActiveQuartiers().listen((data) {
      // Dédupliquer les quartiers par nom (au cas où il y aurait des doublons)
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
    phoneController.dispose();
    passwordController.dispose();
    addressController.dispose();
    super.onClose();
  }

  void _fillFormWithPickerData() {
    if (pickerToEdit != null) {
      nameController.text = pickerToEdit!.name;
      phoneController.text = pickerToEdit!.phone.replaceAll('+237', '');
      selectedQuartier.value = pickerToEdit!.quartier ?? '';
      addressController.text = pickerToEdit!.address ?? '';
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> savePicker() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final quartier = selectedQuartier.value.toLowerCase();
    final address = addressController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer le nom');
      return;
    }

    if (phone.isEmpty || phone.length != 9) {
      Get.snackbar('Erreur', 'Numéro de téléphone invalide (9 chiffres)');
      return;
    }

    // Mot de passe obligatoire uniquement pour création
    if (pickerToEdit == null && password.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer un mot de passe');
      return;
    }

    if (password.isNotEmpty && password.length < 6) {
      Get.snackbar('Erreur', 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    isLoading.value = true;

    try {
      final fullPhone = '+237$phone';

      if (pickerToEdit == null) {
        // CRÉATION
        final userCredential = await _authService.createUserWithEmailPassword(
          fullPhone,
          password,
        );

        final newPicker = AppUser(
          id: userCredential.user!.uid,
          phone: fullPhone,
          name: name,
          role: UserRole.picker,
          quartier: quartier.isEmpty ? null : quartier,
          address: address.isEmpty ? null : address,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: UserStatus.active,
        );

        print('✅ Création picker dans Firestore: ${newPicker.id}');
        await _firestoreService.createUser(newPicker);
        print('✅ Picker créé avec succès dans Firestore');

        Get.back();
        Get.snackbar(
          'Succès',
          'Picker ${newPicker.name} créé avec succès',
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
        );
      } else {
        // ÉDITION
        await _firestoreService.updateUser(pickerToEdit!.id, {
          'name': name,
          'quartier': quartier.isEmpty ? null : quartier,
          'address': address.isEmpty ? null : address,
          'updatedAt': DateTime.now(),
        });

        // Si un nouveau mot de passe est fourni
        if (password.isNotEmpty) {
          // Note: Nécessite que l'admin soit connecté en tant que ce picker
          // ou utiliser Admin SDK côté serveur
          Get.snackbar(
            'Info',
            'Le changement de mot de passe nécessite que le picker se connecte',
          );
        }

        Get.back();
        Get.snackbar(
          'Succès',
          'Picker mis à jour',
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
