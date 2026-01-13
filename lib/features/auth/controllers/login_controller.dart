import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/app_user.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Routing central basé sur le rôle
  void _handlePostLoginRouting(AppUser user) {
    switch (user.role) {
      case UserRole.admin:
        Get.offAllNamed('/admin-home');
        break;
      case UserRole.picker:
        Get.offAllNamed('/picker-home');
        break;
      case UserRole.client:
        Get.offAllNamed('/client-home');
        break;
    }
  }

  Future<void> login() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer votre numéro de téléphone');
      return;
    }

    if (phone.length != 9) {
      Get.snackbar('Erreur', 'Le numéro doit contenir 9 chiffres');
      return;
    }

    if (password.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer votre mot de passe');
      return;
    }

    isLoading.value = true;

    try {
      final fullPhone = '+237$phone';

      // Login avec phone + password
      await _authService.signInWithPhonePassword(fullPhone, password);

      // Vérifier le rôle de l'utilisateur
      final userId = _authService.userId;
      if (userId != null) {
        final user = await _firestoreService.getUser(userId);

        if (user == null) {
          await _authService.signOut();
          isLoading.value = false;
          Get.snackbar('Erreur', 'Profil utilisateur introuvable');
          return;
        }

        isLoading.value = false;

        // Redirection selon le rôle
        _handlePostLoginRouting(user);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Erreur', e.toString());
    }
  }
}
