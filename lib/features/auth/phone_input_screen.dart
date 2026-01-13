import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = Get.find<AuthService>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your phone number',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      return;
    }

    if (!phone.startsWith('+')) {
      Get.snackbar(
        'Error',
        'Phone number must start with country code (e.g., +237)',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
      return;
    }

    setState(() => _isLoading = true);

    await _authService.verifyPhoneNumber(
      phone,
      onCodeSent: (verificationId) {
        setState(() => _isLoading = false);
        Get.to(() => OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phone,
            ));
      },
      onError: (error) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Error',
          error,
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
      },
      onAutoVerify: (credential) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Success',
          'Auto-verified successfully',
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.phone_android,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to TrashPicker',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your phone number to get started',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+237 6XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                        ),
                      )
                    : Text(
                        'Send OTP',
                        style: AppTextStyles.button,
                      ),
              ),
              const Spacer(),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
