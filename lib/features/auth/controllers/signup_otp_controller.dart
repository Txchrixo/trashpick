import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';

class SignupOtpController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController otpController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString phone = ''.obs;

  String? verificationId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    phone.value = args['phone'] ?? '';
    verificationId = args['verificationId'];

    // Si auto-verified (numéros de test)
    if (args['autoVerified'] == true) {
      Future.delayed(Duration.zero, () {
        Get.offNamed('/complete-profile', arguments: {'phone': phone.value});
      });
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }

  Future<void> verifyOTP() async {
    final code = otpController.text.trim();

    if (code.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer le code de vérification');
      return;
    }

    if (code.length != 6) {
      Get.snackbar('Erreur', 'Le code doit contenir 6 chiffres');
      return;
    }

    if (verificationId == null) {
      Get.snackbar('Erreur', 'Session expirée. Veuillez recommencer');
      return;
    }

    isLoading.value = true;

    try {
      await _authService.signInWithSmsCode(verificationId!, code);
      isLoading.value = false;

      // Redirection vers compléter le profil
      Get.offNamed('/complete-profile', arguments: {'phone': phone.value});
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Erreur', e.toString());
    }
  }

  Future<void> resendOTP() async {
    Get.back();
    Get.snackbar('Info', 'Renvoi du code...');
  }
}
