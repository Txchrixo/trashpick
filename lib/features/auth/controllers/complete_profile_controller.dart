import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/app_user.dart';
import '../../../models/quartier.dart';

class CompleteProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController foyerController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxString phone = ''.obs;
  final RxString selectedQuartier = ''.obs;
  final RxList<Quartier> quartiers = <Quartier>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    phone.value = args['phone'] ?? '';
    _loadQuartiers();
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  Future<void> completeProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final userId = _authService.userId;
      if (userId == null) {
        throw 'Utilisateur non connecté';
      }

      final password = passwordController.text.trim();

      // Lier le credential email/password au user Firebase
      await _authService.linkPasswordCredential(phone.value, password);

      // Créer le document user dans Firestore
      final user = AppUser(
        id: userId,
        phone: phone.value,
        name: nameController.text.trim(),
        role: UserRole.client, // Toujours CLIENT par défaut
        address: addressController.text.trim(),
        quartier: selectedQuartier.value.toLowerCase(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: UserStatus.active,
      );

      await _firestoreService.createUser(user);

      // Ajouter le champ foyer custom
      await _firestoreService.updateUser(userId, {
        'foyer': foyerController.text.trim(),
      });

      isLoading.value = false;

      Get.snackbar(
        'Succès',
        'Compte créé avec succès',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );

      // Redirection vers le dashboard client
      Get.offAllNamed('/client-home');
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Erreur', e.toString());
    }
  }
}
