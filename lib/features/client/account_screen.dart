import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import 'controllers/account_controller.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountController());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Mon compte'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Informations personnelles',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 24),

                // Nom complet
                TextFormField(
                  controller: controller.nameController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Nom du foyer
                TextFormField(
                  controller: controller.foyerController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Nom du foyer / lieu',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom du foyer';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Quartier
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedQuartier.value.isEmpty
                      ? null
                      : controller.selectedQuartier.value,
                  decoration: InputDecoration(
                    labelText: 'Quartier / Zone',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: controller.quartiers.map((quartier) {
                    return DropdownMenuItem<String>(
                      value: quartier.name,
                      child: Text(quartier.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    controller.selectedQuartier.value = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner votre quartier';
                    }
                    return null;
                  },
                )),

                const SizedBox(height: 16),

                // Adresse
                TextFormField(
                  controller: controller.addressController,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Adresse détaillée',
                    prefixIcon: const Icon(Icons.map),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre adresse';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Téléphone (non modifiable)
                TextFormField(
                  controller: controller.phoneController,
                  enabled: false,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.divider.withValues(alpha: 0.1),
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton Enregistrer
                Obx(() => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Enregistrer',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.textWhite,
                              ),
                            ),
                    )),

                const SizedBox(height: 32),

                Text(
                  'Sécurité',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton changer mot de passe
                OutlinedButton.icon(
                  onPressed: controller.showChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Changer le mot de passe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }
}
