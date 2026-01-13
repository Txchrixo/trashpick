import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';

class SignupController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final TextEditingController phoneController = TextEditingController();
  final RxBool isLoading = false.obs;

  String? verificationId;

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer votre numéro de téléphone');
      return;
    }

    if (phone.length != 9) {
      Get.snackbar('Erreur', 'Le numéro doit contenir 9 chiffres');
      return;
    }

    isLoading.value = true;

    try {
      final fullPhone = '+237$phone';

      await _authService.verifyPhoneNumber(
        fullPhone,
        onCodeSent: (verificationId) {
          this.verificationId = verificationId;
          isLoading.value = false;
          Get.toNamed('/signup-otp', arguments: {
            'phone': fullPhone,
            'verificationId': verificationId,
          });
        },
        onError: (error) {
          isLoading.value = false;
          Get.snackbar('Erreur', error);
        },
        onAutoVerify: (credential) async {
          isLoading.value = false;
          Get.toNamed('/signup-otp', arguments: {
            'phone': fullPhone,
            'verificationId': null,
            'autoVerified': true,
          });
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Erreur', e.toString());
    }
  }
}
