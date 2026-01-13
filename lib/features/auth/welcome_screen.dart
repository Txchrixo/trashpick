import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Fond vert foncé
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo avec fond vert
              Container(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/logo-trash-pick.png',
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // Titre
              Text(
                'TrashPicker',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.accent, // Jaune doré
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Sous-titre
              Text(
                'Simplifiez la gestion de vos déchets',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                'Demandez une collecte en quelques clics et suivez votre demande en temps réel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Bouton Commencer
              ElevatedButton(
                onPressed: () {
                  Get.toNamed('/auth-choice');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent, // Jaune doré
                  foregroundColor: AppColors.primary, // Texte vert foncé
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Commencer',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
